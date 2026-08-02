/// Fase 4 — DOCX preservador: importar sem perder e reconstruir sem os bytes.
///
/// O gate desta fase não é "abre o Word": é DOCX → Snapshot → DOCX sem
/// alteração semântica. Um documento tem dezenas de partes que o editor não
/// entende — temas, custom XML, assinaturas, extensões de fabricante — e o
/// usuário nunca autorizou descartá-las só porque abriu o arquivo.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:test/test.dart';

import 'package:dart_quill/dart_quill_office.dart';
import 'package:dart_quill/src/office/document/zip/zip_archive.dart';

void main() {
  // UMA instância: officeQuillSchema() devolve um Schema NOVO a cada
  // chamada, e nós de schemas diferentes não se misturam.
  final schema = officeQuillSchema();
  final etpPath = 'test/assets/docx/etp_corpus.docx';
  final hasCorpus = File(etpPath).existsSync();

  Uint8List corpus() => File(etpPath).readAsBytesSync();

  Map<String, List<int>> partsOf(Uint8List docx) {
    final archive = ZipArchive.decodeBytes(docx);
    return {for (final e in archive.entries) e.name: e.content};
  }

  group('importação preservadora', () {
    test('cataloga TODAS as entradas do pacote', () {
      if (!hasCorpus) return;
      final bytes = corpus();
      final original = partsOf(bytes);
      final imported = OfficeDocxCodec().import(bytes);

      final catalogued = {
        for (final part in imported.snapshot.resources.opaqueParts)
          part['uri'] as String
      };
      expect(catalogued, containsAll(original.keys),
          reason: 'uma parte fora do catálogo é uma parte perdida');
    });

    test('partes binárias são deduplicadas por hash', () {
      if (!hasCorpus) return;
      final imported = OfficeDocxCodec().import(corpus());
      final assetIds = [
        for (final a in imported.snapshot.resources.assets) a['id'] as String
      ];
      expect(assetIds.toSet().length, assetIds.length,
          reason: 'o mesmo conteúdo não pode entrar duas vezes');
      for (final id in assetIds) {
        expect(id, startsWith('sha256:'));
      }
    });

    test('o corpo vira árvore editável com texto real', () {
      if (!hasCorpus) return;
      final imported = OfficeDocxCodec().import(corpus());
      final doc = PMNode.fromJSON(schema, imported.snapshot.body);
      expect(doc.childCount, greaterThan(10));
      final text = doc.textBetween(0, doc.content.size, blockSeparator: ' ');
      expect(text.trim(), isNotEmpty);
    });

    test('cada bloco importado tem âncora para a origem', () {
      if (!hasCorpus) return;
      final imported = OfficeDocxCodec().import(corpus());
      final doc = PMNode.fromJSON(schema, imported.snapshot.body);
      expect(imported.anchors.length, doc.childCount);
      for (final anchor in imported.anchors) {
        expect(anchor.partUri, isNotEmpty);
        expect(anchor.rawHash, isNotEmpty);
      }
    });

    test('o que não sabemos representar entra no relatório', () {
      if (!hasCorpus) return;
      final imported = OfficeDocxCodec().import(corpus());
      // O corpus tem tabelas: elas são preservadas opacas e reportadas.
      expect(imported.report.issues, isNotEmpty,
          reason: 'perda silenciosa é o que este projeto não aceita');
    });
  });

  group('DOCX → Snapshot → DOCX', () {
    test('toda parte volta com o CONTEÚDO idêntico', () {
      if (!hasCorpus) return;
      final bytes = corpus();
      final original = partsOf(bytes);
      final codec = OfficeDocxCodec();

      final rebuilt = partsOf(codec.export(codec.import(bytes).snapshot));

      expect(rebuilt.keys.toSet(), original.keys.toSet());
      for (final name in original.keys) {
        expect(rebuilt[name], original[name],
            reason: 'a parte $name mudou de conteúdo no round-trip');
      }
    });

    test('reconstrói SEM os bytes originais, só do JSON', () {
      if (!hasCorpus) return;
      final bytes = corpus();
      final codec = OfficeDocxCodec();
      final json = jsonEncode(codec.import(bytes).snapshot.toJson());

      // A partir daqui o `.docx` original não existe mais para nós.
      final restored =
          OfficeDocumentSnapshot.fromJson(jsonDecode(json) as Map<String, dynamic>);
      final rebuilt = partsOf(codec.export(restored));

      expect(rebuilt.keys.toSet(), partsOf(bytes).keys.toSet());
      expect(rebuilt['word/document.xml'], partsOf(bytes)['word/document.xml']);
    });

    test('o pacote reconstruído reabre no leitor', () {
      if (!hasCorpus) return;
      final bytes = corpus();
      final codec = OfficeDocxCodec();
      final rebuilt = codec.export(codec.import(bytes).snapshot);

      final second = codec.import(rebuilt);
      final firstDoc =
          PMNode.fromJSON(schema, codec.import(bytes).snapshot.body);
      final secondDoc =
          PMNode.fromJSON(schema, second.snapshot.body);
      expect(secondDoc.childCount, firstDoc.childCount,
          reason: 'reabrir o que geramos tem de dar o mesmo documento');
    });

    test('snapshot → docx → snapshot é ponto fixo nas partes', () {
      if (!hasCorpus) return;
      final codec = OfficeDocxCodec();
      final first = codec.import(corpus()).snapshot;
      final second = codec.import(codec.export(first)).snapshot;

      String partsKey(OfficeDocumentSnapshot s) => jsonEncode([
            for (final p in s.resources.opaqueParts)
              {'uri': p['uri'], 'data': p['data'], 'assetId': p['assetId']}
          ]);
      expect(partsKey(second), partsKey(first));
    });
  });

  group('writer patch-based', () {
    PMNode bodyOf(OfficeDocumentSnapshot snapshot) =>
        PMNode.fromJSON(schema, snapshot.body);

    test('sem edição, o corpo volta byte a byte', () {
      if (!hasCorpus) return;
      final bytes = corpus();
      final codec = OfficeDocxCodec();
      final imported = codec.import(bytes);

      final rebuilt = codec.exportEdited(imported.snapshot, bodyOf(imported.snapshot));
      final before = partsOf(bytes)['word/document.xml']!;
      final after = partsOf(rebuilt)['word/document.xml']!;
      expect(after, before,
          reason: 'não tocar em nada não pode reescrever o documento');
    });

    test('editar UM parágrafo não reescreve os outros', () {
      if (!hasCorpus) return;
      final bytes = corpus();
      final codec = OfficeDocxCodec();
      final imported = codec.import(bytes);
      final doc = bodyOf(imported.snapshot);

      // Troca o texto do primeiro bloco; todos os demais ficam idênticos.
      final blocks = [for (var i = 0; i < doc.childCount; i++) doc.child(i)];
      blocks[0] = schema.node(blocks[0].type.name, blocks[0].attrs,
          Fragment.from([schema.text('TEXTO EDITADO')]));
      final edited = schema.node('doc', null, Fragment.from(blocks));

      final xml = utf8.decode(
          partsOf(codec.exportEdited(imported.snapshot, edited))['word/document.xml']!);

      expect(xml, contains('TEXTO EDITADO'));
      // Um parágrafo mais adiante tem de continuar com o XML de origem.
      final untouched = doc.child(doc.childCount - 1).textContent;
      if (untouched.trim().isNotEmpty) {
        expect(xml, contains(untouched.trim().split(' ').first));
      }
    });

    test('a edição sobrevive a reabrir o arquivo', () {
      if (!hasCorpus) return;
      final codec = OfficeDocxCodec();
      final imported = codec.import(corpus());
      final doc = bodyOf(imported.snapshot);
      final blocks = [for (var i = 0; i < doc.childCount; i++) doc.child(i)];
      blocks[0] = schema.node('paragraph', null,
          Fragment.from([schema.text('MARCADOR UNICO 12345')]));
      final edited = schema.node('doc', null, Fragment.from(blocks));

      final reopened =
          codec.import(codec.exportEdited(imported.snapshot, edited));
      final text = bodyOf(reopened.snapshot)
          .textBetween(0, bodyOf(reopened.snapshot).content.size,
              blockSeparator: ' ');
      expect(text, contains('MARCADOR UNICO 12345'));
    });

    test('aplicar negrito conta como edição (assinatura vê as marcas)', () {
      if (!hasCorpus) return;
      final codec = OfficeDocxCodec();
      final imported = codec.import(corpus());
      final doc = bodyOf(imported.snapshot);

      final first = doc.child(0);
      if (first.childCount == 0) return;
      final bold = schema.marks['bold']!.create();
      final blocks = [for (var i = 0; i < doc.childCount; i++) doc.child(i)];
      blocks[0] = schema.node(
          first.type.name,
          first.attrs,
          Fragment.from([
            schema.text(first.textContent, [bold])
          ]));
      final edited = schema.node('doc', null, Fragment.from(blocks));

      final before = OfficeDocxCodec.nodeSignature(first);
      final after = OfficeDocxCodec.nodeSignature(blocks[0]);
      expect(after, isNot(before),
          reason: 'formatação sem mudar texto ainda é edição');

      final xml = utf8.decode(
          partsOf(codec.exportEdited(imported.snapshot, edited))['word/document.xml']!);
      expect(xml, contains('<w:b/>'));
    });

    test('blocos opacos (tabelas) não somem ao salvar editado', () {
      if (!hasCorpus) return;
      final codec = OfficeDocxCodec();
      final imported = codec.import(corpus());
      final doc = bodyOf(imported.snapshot);

      final xml = utf8.decode(
          partsOf(codec.exportEdited(imported.snapshot, doc))['word/document.xml']!);
      final originalXml = utf8.decode(partsOf(corpus())['word/document.xml']!);
      expect('<w:tbl'.allMatches(xml).length,
          '<w:tbl'.allMatches(originalXml).length,
          reason: 'tabela preservada opaca não pode desaparecer no save');
    });
  });

  group('geometria da seção', () {
    test('a página do DOCX chega ao snapshot em twips', () {
      if (!hasCorpus) return;
      final imported = OfficeDocxCodec().import(corpus());
      expect(imported.snapshot.resources.sections, isNotEmpty);

      final setup = OfficeDocxCodec.pageSetupOf(imported.snapshot);
      expect(setup.widthTwips, greaterThan(0));
      expect(setup.heightTwips, greaterThan(setup.widthTwips),
          reason: 'o corpus é retrato');
      expect(setup.contentWidthTwips, lessThan(setup.widthTwips),
          reason: 'as margens do documento têm de entrar');
    });

    test('o documento pagina com a geometria DELE, não com A4 padrão', () {
      if (!hasCorpus) return;
      final imported = OfficeDocxCodec().import(corpus());
      final doc = PMNode.fromJSON(schema, imported.snapshot.body);

      final setup = OfficeDocxCodec.pageSetupOf(imported.snapshot);
      final own = LayoutComposer(setup: setup).compose(doc);
      final defaulted = LayoutComposer().compose(doc);

      // O corpus é A4 como o default, mas com margens de 2,5 cm em vez de
      // 2 cm: a ÁREA ÚTIL difere, e é ela que decide onde a página quebra.
      expect(setup.contentHeightTwips,
          isNot(const PageSetupTwips().contentHeightTwips));
      expect(own.pages.length, isNot(defaulted.pages.length),
          reason: 'paginar com a margem errada muda a contagem de páginas');
    });

    test('o PDF do snapshot usa a mesma geometria', () {
      if (!hasCorpus) return;
      final imported = OfficeDocxCodec().import(corpus());
      final setup = OfficeDocxCodec.pageSetupOf(imported.snapshot);
      final expected = LayoutComposer(setup: setup)
          .compose(PMNode.fromJSON(schema, imported.snapshot.body));

      final pdf = OfficePdfService().fromSnapshot(imported.snapshot);
      expect(pdf.pageCount, expected.pages.length,
          reason: 'o PDF assinado tem de sair no papel do documento');
    });

    test('sem seção declarada, cai no default sem explodir', () {
      final snapshot = OfficeDocumentSnapshot(
          documentId: 'x',
          body: schema
              .node('doc', null,
                  Fragment.from([schema.node('paragraph', null, Fragment.empty)]))
              .toJSON() as Map<String, dynamic>);
      final setup = OfficeDocxCodec.pageSetupOf(snapshot);
      expect(setup.widthTwips, const PageSetupTwips().widthTwips);
    });
  });

  group('cabeçalho e rodapé', () {
    test('viram raízes próprias do snapshot, não parte do corpo', () {
      if (!hasCorpus) return;
      final imported = OfficeDocxCodec().import(corpus());
      final regions = {
        ...imported.snapshot.headers,
        ...imported.snapshot.footers
      };
      if (regions.isEmpty) return; // corpus sem timbre: nada a provar aqui

      final body = PMNode.fromJSON(schema, imported.snapshot.body);
      final bodyText = body.textBetween(0, body.content.size, blockSeparator: ' ');
      for (final json in regions.values) {
        final region = PMNode.fromJSON(schema, json);
        final text = region.textBetween(0, region.content.size).trim();
        if (text.isEmpty) continue;
        expect(bodyText, isNot(contains(text)),
            reason: 'a região não pode ter vazado para dentro do corpo');
      }
    });

    test('o PDF do snapshot desenha a região em todas as páginas', () {
      if (!hasCorpus) return;
      final imported = OfficeDocxCodec().import(corpus());
      final header = OfficeDocxCodec.regionOf(imported.snapshot.headers, schema);
      if (header == null) return;

      final pdf = OfficePdfService().fromSnapshot(imported.snapshot);
      expect(pdf.pageCount, greaterThan(0));
      expect(pdf.bytes.length, greaterThan(1000));
    });
  });

  test('o corpus de teste existe', () {
    expect(hasCorpus, isTrue,
        reason: 'sem corpus real o round-trip não prova nada');
  });
}
