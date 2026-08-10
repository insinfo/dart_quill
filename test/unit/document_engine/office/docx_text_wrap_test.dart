/// Disposição do texto no ROUND-TRIP DOCX.
///
/// A UI só pode oferecer a troca de modo se ela chegar ao arquivo. Aqui se
/// prova as duas pontas: o DrawingML vira `wrapMode` na importação, e a
/// troca do usuário reescreve `wp:wrap*`/`@behindDoc` sem reserializar a
/// caixa (a forma, o preenchimento e o `w:txbxContent` continuam de pé).
@TestOn('vm')
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:dart_quill/dart_quill_office.dart';
import 'package:dart_quill/src/office/document/zip/zip_archive.dart';
import 'package:test/test.dart';

void main() {
  final schema = officeQuillSchema();
  const corpusPath = 'test/assets/docx/etp_corpus.docx';
  final hasCorpus = File(corpusPath).existsSync();

  Uint8List corpus() => Uint8List.fromList(File(corpusPath).readAsBytesSync());

  PMNode? findTextBox(PMNode node) {
    if (node.type.name == 'textBox') return node;
    for (var i = 0; i < node.childCount; i++) {
      final found = findTextBox(node.child(i));
      if (found != null) return found;
    }
    return null;
  }

  PMNode withWrapMode(PMNode node, String mode) {
    if (node.type.name == 'textBox') {
      return node.type.create(
        {...node.attrs, 'wrapMode': mode},
        node.content,
        node.marks,
      );
    }
    if (node.childCount == 0) return node;
    return node.copy(Fragment.from([
      for (var i = 0; i < node.childCount; i++)
        withWrapMode(node.child(i), mode),
    ]));
  }

  String headerXmlWith(Uint8List docx, String needle) {
    final archive = ZipArchive.decodeBytes(docx);
    for (final name in archive.entries.map((entry) => entry.name)) {
      if (!name.startsWith('word/header')) continue;
      final xml = archive.readString(name) ?? '';
      if (xml.contains(needle)) return xml;
    }
    return '';
  }

  test('importação lê o modo de wrap do DrawingML', () {
    if (!hasCorpus) {
      markTestSkipped('corpus versionado ausente');
      return;
    }
    final codec = OfficeDocxCodec(schema: schema);
    final imported = codec.import(corpus(), includePackageResources: false);
    final variants =
        OfficeDocxCodec.regionVariantsOf(imported.snapshot.headers, schema);
    PMNode? box;
    for (final region in variants.values) {
      box = findTextBox(region);
      if (box != null) break;
    }
    if (box == null) {
      markTestSkipped('o corpus versionado não tem caixa de texto');
      return;
    }
    final raw = box.attrs['word'].toString();
    // O corpus real traz `wp:wrapNone` com `behindDoc="0"`, que é o único
    // par que o DrawingML usa para dizer "na frente do texto".
    expect(raw, contains('<wp:wrapNone'));
    expect(raw, contains('behindDoc="0"'));
    expect(box.attrs['wrapMode'], 'inFrontOfText');
    expect(box.attrs['wrapDistLeft'], isA<int>(),
        reason: 'a folga objeto↔texto vem em twips para o compositor');
  });

  test('trocar o modo reescreve o wp:wrap sem reserializar a caixa', () {
    if (!hasCorpus) {
      markTestSkipped('corpus versionado ausente');
      return;
    }
    final bytes = corpus();
    final codec = OfficeDocxCodec(schema: schema);
    final imported = codec.import(bytes, includePackageResources: false);
    final variants =
        OfficeDocxCodec.regionVariantsOf(imported.snapshot.headers, schema);
    String? variantKey;
    PMNode? region;
    PMNode? box;
    for (final entry in variants.entries) {
      final found = findTextBox(entry.value);
      if (found != null) {
        variantKey = entry.key;
        region = entry.value;
        box = found;
        break;
      }
    }
    if (box == null) {
      markTestSkipped('o corpus versionado não tem caixa de texto');
      return;
    }
    // Um trecho contíguo do miolo: o `textContent` do documento interno
    // concatena parágrafos e nunca apareceria assim no XML.
    final innerText = PMNode.fromJSON(schema, box.attrs['textBoxDoc'] as Map)
        .child(0)
        .textContent;
    expect(innerText, isNotEmpty);

    final exported = codec.exportEditedFromDocx(
      bytes,
      imported.snapshot.sourceMap,
      PMNode.fromJSON(schema, imported.snapshot.body),
      headers: {variantKey!: withWrapMode(region!, 'square')},
    );

    final xml = headerXmlWith(exported, '<wp:wrapSquare');
    expect(xml, isNotEmpty, reason: 'a troca tem de chegar ao arquivo');
    expect(xml, isNot(contains('<wp:wrapNone')));
    expect(xml, contains('behindDoc="0"'));
    expect(xml, contains(innerText),
        reason: 'o miolo da caixa não pode ter sido perdido na cirurgia');
    expect(xml, contains('<wps:spPr'),
        reason: 'a forma preservada (D1) continua no arquivo');

    // E o arquivo reaberto entrega o modo novo ao compositor.
    final reopened = codec.import(exported, includePackageResources: false);
    final reopenedBox = findTextBox(OfficeDocxCodec.regionVariantsOf(
        reopened.snapshot.headers, schema)[variantKey]!)!;
    expect(reopenedBox.attrs['wrapMode'], 'square');
  });

  test('atrás do texto grava behindDoc=1 com wrapNone', () {
    if (!hasCorpus) {
      markTestSkipped('corpus versionado ausente');
      return;
    }
    final bytes = corpus();
    final codec = OfficeDocxCodec(schema: schema);
    final imported = codec.import(bytes, includePackageResources: false);
    final variants =
        OfficeDocxCodec.regionVariantsOf(imported.snapshot.headers, schema);
    String? variantKey;
    PMNode? region;
    for (final entry in variants.entries) {
      if (findTextBox(entry.value) != null) {
        variantKey = entry.key;
        region = entry.value;
        break;
      }
    }
    if (region == null) {
      markTestSkipped('o corpus versionado não tem caixa de texto');
      return;
    }
    final exported = codec.exportEditedFromDocx(
      bytes,
      imported.snapshot.sourceMap,
      PMNode.fromJSON(schema, imported.snapshot.body),
      headers: {variantKey!: withWrapMode(region, 'behindText')},
    );
    final xml = headerXmlWith(exported, 'behindDoc="1"');
    expect(xml, isNotEmpty);
    expect(xml, contains('<wp:wrapNone'));

    final reopened = codec.import(exported, includePackageResources: false);
    final reopenedBox = findTextBox(OfficeDocxCodec.regionVariantsOf(
        reopened.snapshot.headers, schema)[variantKey]!)!;
    expect(reopenedBox.attrs['wrapMode'], 'behindText');
  });

  test('modo comprimido leva um wrapPolygon, exigido pelo schema OOXML', () {
    if (!hasCorpus) {
      markTestSkipped('corpus versionado ausente');
      return;
    }
    final bytes = corpus();
    final codec = OfficeDocxCodec(schema: schema);
    final imported = codec.import(bytes, includePackageResources: false);
    final variants =
        OfficeDocxCodec.regionVariantsOf(imported.snapshot.headers, schema);
    String? variantKey;
    PMNode? region;
    for (final entry in variants.entries) {
      if (findTextBox(entry.value) != null) {
        variantKey = entry.key;
        region = entry.value;
        break;
      }
    }
    if (region == null) {
      markTestSkipped('o corpus versionado não tem caixa de texto');
      return;
    }
    final exported = codec.exportEditedFromDocx(
      bytes,
      imported.snapshot.sourceMap,
      PMNode.fromJSON(schema, imported.snapshot.body),
      headers: {variantKey!: withWrapMode(region, 'tight')},
    );
    final xml = headerXmlWith(exported, '<wp:wrapTight');
    expect(xml, isNotEmpty);
    expect(xml, contains('<wp:wrapPolygon'));

    final reopened = codec.import(exported, includePackageResources: false);
    final reopenedBox = findTextBox(OfficeDocxCodec.regionVariantsOf(
        reopened.snapshot.headers, schema)[variantKey]!)!;
    expect(reopenedBox.attrs['wrapMode'], 'tight');
  });

  test('salvar sem trocar o modo não mexe no XML da caixa', () {
    if (!hasCorpus) {
      markTestSkipped('corpus versionado ausente');
      return;
    }
    final bytes = corpus();
    final codec = OfficeDocxCodec(schema: schema);
    final imported = codec.import(bytes, includePackageResources: false);
    final variants =
        OfficeDocxCodec.regionVariantsOf(imported.snapshot.headers, schema);
    String? variantKey;
    PMNode? region;
    for (final entry in variants.entries) {
      if (findTextBox(entry.value) != null) {
        variantKey = entry.key;
        region = entry.value;
        break;
      }
    }
    if (region == null) {
      markTestSkipped('o corpus versionado não tem caixa de texto');
      return;
    }
    final exported = codec.exportEditedFromDocx(
      bytes,
      imported.snapshot.sourceMap,
      PMNode.fromJSON(schema, imported.snapshot.body),
      headers: {variantKey!: region},
    );
    expect(headerXmlWith(exported, '<wp:wrapSquare'), isEmpty,
        reason: 'abrir e salvar não pode inventar uma disposição nova');
    expect(headerXmlWith(exported, '<wp:wrapNone'), isNotEmpty);
  });
}
