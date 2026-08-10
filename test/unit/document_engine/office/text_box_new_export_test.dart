/// F9 — a caixa de texto CRIADA no editor tem de chegar ao arquivo.
///
/// A caixa importada era carimbada: o writer devolvia o DrawingML que veio do
/// DOCX. Uma caixa nova não tem carimbo nenhum, e o ramo de exportação
/// simplesmente PULAVA o nó — o usuário inseria a caixa, escrevia dentro,
/// salvava e reabria sem ela. O que estes testes protegem é a ponta inteira:
/// o `mc:AlternateContent` gerado é XML válido, o pacote passa pelo
/// [DocxValidator], e reabrir o arquivo devolve uma CAIXA (não uma imagem,
/// não um parágrafo solto).
@TestOn('vm')
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:test/test.dart';

import 'package:dart_quill/dart_quill_office.dart';
import 'package:dart_quill/src/office/ce_xml.dart';
import 'package:dart_quill/src/office/document/docx/validator.dart';
import 'package:dart_quill/src/office/document/zip/zip_archive.dart';

void main() {
  // UMA instância: officeQuillSchema() devolve um Schema NOVO a cada
  // chamada, e nós de schemas diferentes não se misturam.
  final schema = officeQuillSchema();
  final etpPath = 'test/assets/docx/etp_corpus.docx';
  final hasCorpus = File(etpPath).existsSync();

  PMNode paragraph(String text) => schema.node('paragraph', null,
      text.isEmpty ? Fragment.empty : Fragment.from([schema.text(text)]));

  PMNode innerDoc(List<String> lines) => schema.node(
      'doc', null, Fragment.from([for (final line in lines) paragraph(line)]));

  /// A caixa como [insertTextBox] a cria: com `textBoxDoc`, geometria e
  /// bordas — e SEM `word`, que é o que diz "esta caixa não tem origem para
  /// carimbar, gere a forma".
  PMNode newBox({
    List<String> lines = const ['caixa nova'],
    int width = 5670,
    int height = 1701,
  }) =>
      schema.node('textBox', {
        'text': lines.join('\n'),
        'textBoxDoc': innerDoc(lines).toJSON(),
        'width': width,
        'height': height,
        'insetLeft': 144,
        'insetTop': 72,
        'insetRight': 144,
        'insetBottom': 72,
        'borderWidth': 10,
        'borderColor': '#000000',
        'background': '#FFFFFF',
      });

  PMNode docWithBox(PMNode box) => schema.node(
        'doc',
        null,
        Fragment.from([
          schema.node('paragraph', null, Fragment.from([box])),
          paragraph('corpo do documento'),
        ]),
      );

  PMNode? findTextBox(PMNode node) {
    if (node.type.name == 'textBox') return node;
    for (var i = 0; i < node.childCount; i++) {
      final found = findTextBox(node.child(i));
      if (found != null) return found;
    }
    return null;
  }

  group('documento NOVO (sem pacote de origem)', () {
    test('o pacote gerado passa pelo DocxValidator', () {
      final bytes =
          OfficeDocxCodec(schema: schema).exportDocument(docWithBox(newBox()));

      expect(DocxValidator.validate(bytes), isEmpty,
          reason: 'XML malformado ou rel quebrada é o diálogo de reparo do '
              'Word — o custo de gerar DrawingML à mão');
    });

    test('o document.xml declara os namespaces que a caixa usa', () {
      final bytes =
          OfficeDocxCodec(schema: schema).exportDocument(docWithBox(newBox()));
      final xml =
          ZipArchive.decodeBytes(bytes).readString('word/document.xml')!;

      // O `w:document` de um documento novo declara só `w` e `r`
      // (DocxReader.createEmpty): sem declaração local, cada prefixo destes é
      // XML malformado. Reparsear é a prova de que nenhum ficou de fora.
      expect(() => XmlDocument.parse(xml), returnsNormally);
      for (final prefix in ['mc:', 'wp:', 'wps:', 'a:', 'v:']) {
        expect(xml, contains('xmlns:${prefix.substring(0, prefix.length - 1)}'),
            reason: '$prefix precisa estar declarado no elemento gerado');
      }
    });

    test('a forma sai como caixa de texto, não como imagem', () {
      final bytes =
          OfficeDocxCodec(schema: schema).exportDocument(docWithBox(newBox()));
      final xml =
          ZipArchive.decodeBytes(bytes).readString('word/document.xml')!;

      expect(xml, contains('<mc:AlternateContent'),
          reason: 'o importador só reconhece caixa dentro de '
              'mc:AlternateContent; um w:drawing solto voltaria como imagem');
      expect(xml, contains('<wps:wsp>'));
      expect(xml, contains('<w:txbxContent>'));
      expect(xml, contains('caixa nova'));
    });

    test('o miolo é gravado nas DUAS cópias (DrawingML e VML)', () {
      final bytes = OfficeDocxCodec(schema: schema)
          .exportDocument(docWithBox(newBox(lines: ['duas vezes'])));
      final xml =
          ZipArchive.decodeBytes(bytes).readString('word/document.xml')!;

      // O `mc:Fallback` existe para quem não entende `wps`. Se as duas cópias
      // divergissem, o texto mudaria conforme o leitor que abrisse.
      expect('<w:txbxContent>'.allMatches(xml).length, 2);
      expect('duas vezes'.allMatches(xml).length, 2);
    });

    test('round-trip: exportar e reimportar devolve uma CAIXA', () {
      final codec = OfficeDocxCodec(schema: schema);
      final bytes = codec.exportDocument(docWithBox(newBox(
        lines: ['linha um', 'linha dois'],
        width: 4000,
        height: 2000,
      )));

      final reopened = codec.import(bytes, includePackageResources: false);
      final box = findTextBox(PMNode.fromJSON(schema, reopened.snapshot.body));

      expect(box, isNotNull,
          reason: 'inserir, salvar e reabrir sem a caixa é o bug que este '
              'trabalho existe para fechar');
      expect(box!.attrs['width'], 4000);
      expect(box.attrs['height'], 2000);
      expect(box.attrs['insetLeft'], 144);
      expect(box.attrs['insetTop'], 72);
      final inner = PMNode.fromJSON(schema, box.attrs['textBoxDoc'] as Map);
      expect(inner.childCount, 2);
      expect(inner.child(0).textContent, 'linha um');
      expect(inner.child(1).textContent, 'linha dois');
    });

    test('a caixa reaberta traz borda e preenchimento declarados', () {
      final codec = OfficeDocxCodec(schema: schema);
      final bytes = codec.exportDocument(docWithBox(newBox()));
      final box = findTextBox(PMNode.fromJSON(schema,
          codec.import(bytes, includePackageResources: false).snapshot.body));

      expect(box!.attrs['borderColor'], '#000000');
      expect(box.attrs['background'], '#FFFFFF');
      expect(box.attrs['borderWidth'], 10);
    });

    test('duas caixas recebem docPr ids DIFERENTES', () {
      final codec = OfficeDocxCodec(schema: schema);
      final bytes = codec.exportDocument(schema.node(
        'doc',
        null,
        Fragment.from([
          schema.node('paragraph', null, Fragment.from([newBox()])),
          schema.node('paragraph', null, Fragment.from([newBox()])),
        ]),
      ));
      final xml =
          ZipArchive.decodeBytes(bytes).readString('word/document.xml')!;

      final ids = RegExp(r'<wp:docPr id="(\d+)"')
          .allMatches(xml)
          .map((m) => m.group(1))
          .toList();
      expect(ids, hasLength(2));
      // `wp:docPr/@id` repetido é uma das causas clássicas do reparo.
      expect(ids.toSet(), hasLength(2));
    });

    test(
        'o redimensionamento chega ao arquivo (a caixa nova não tem '
        'carimbo para ficar mentindo)', () {
      final codec = OfficeDocxCodec(schema: schema);
      // 4000 twips = 2540000 EMU (635 EMU por twip).
      final bytes = codec.exportDocument(docWithBox(newBox(width: 4000)));
      final xml =
          ZipArchive.decodeBytes(bytes).readString('word/document.xml')!;

      expect(xml, contains('cx="2540000"'));
    });
  });

  group('documento IMPORTADO (com pacote a preservar)', () {
    test(
      'a caixa inserida no corpo sobrevive ao save preservador',
      () {
        final source = Uint8List.fromList(File(etpPath).readAsBytesSync());
        final codec = OfficeDocxCodec(schema: schema);
        final imported = codec.import(source, includePackageResources: false);
        final body = PMNode.fromJSON(schema, imported.snapshot.body);

        // A caixa entra no PRIMEIRO parágrafo do corpo, que é o que a ação da
        // ribbon faz com o cursor onde ele estiver.
        final first = body.child(0);
        final edited = body.copy(body.content.replaceChild(
          0,
          first.copy(first.content.addToStart(newBox(lines: ['CAIXA_NOVA']))),
        ));

        final exported = codec.exportEditedFromDocx(
          source,
          imported.snapshot.sourceMap,
          edited,
        );

        expect(DocxValidator.validate(exported), isEmpty);
        final reopened = codec.import(exported, includePackageResources: false);
        final box =
            findTextBox(PMNode.fromJSON(schema, reopened.snapshot.body));
        expect(box, isNotNull);
        expect(
            PMNode.fromJSON(schema, box!.attrs['textBoxDoc'] as Map)
                .textContent,
            'CAIXA_NOVA');
      },
      skip: hasCorpus ? null : 'corpus versionado ausente: $etpPath',
    );
  });
}
