/// Geração de PDF no BACKEND — Dart VM, sem browser.
///
/// Requisito de produto do SALI: quando alguém pede assinatura de um
/// despacho, é o servidor que converte o documento em PDF e o guarda para
/// preservação permanente. Este arquivo NÃO importa `package:web` nem
/// `platform/dom.dart`, e roda com `@TestOn('vm')` justamente para que uma
/// dependência de DOM introduzida por engano quebre aqui — não em produção,
/// na hora de assinar.
@TestOn('vm')
library;

import 'dart:convert';

import 'package:test/test.dart';

import 'package:dart_quill/dart_quill_office.dart';

void main() {
  final schema = officeQuillSchema();

  PMNode paragraph(String text) =>
      schema.node('paragraph', null, Fragment.from([schema.text(text)]));

  PMNode docOf(List<PMNode> blocks) =>
      schema.node('doc', null, Fragment.from(blocks));

  String pdfText(List<int> bytes) => latin1.decode(bytes, allowInvalid: true);

  group('a partir do snapshot persistido', () {
    test('JSON do banco vira PDF sem tocar em DOM', () {
      final snapshot = OfficeDocumentSnapshot(
        documentId: 'despacho-1',
        body: docOf([paragraph('Despacho para assinatura')]).toJSON()
            as Map<String, dynamic>,
      );
      final json = jsonEncode(snapshot.toJson());

      final result = OfficePdfService().fromSnapshotJson(json);

      expect(result.bytes.length, greaterThan(400));
      expect(pdfText(result.bytes), startsWith('%PDF-'));
      expect(result.pageCount, 1);
    });

    test('o PDF gerado no servidor tem as MESMAS páginas do editor', () {
      // O gate central da arquitetura, agora do lado do backend: o servidor
      // não pode paginar diferente do que o usuário viu ao assinar.
      final doc = docOf([
        for (var i = 0; i < 300; i++)
          paragraph('Parágrafo $i do documento administrativo, com texto '
              'longo o suficiente para ocupar a largura útil da página.')
      ]);
      final graph = LayoutComposer().compose(doc);
      expect(graph.pages.length, greaterThan(1));

      final service = OfficePdfService();
      expect(service.fromDocument(doc).pageCount, graph.pages.length);
      expect(service.fromPageGraph(graph).pageCount, graph.pages.length);
    });

    test('o servidor pode reusar o grafo que o editor já compôs', () {
      final doc = docOf([paragraph('reuso do grafo')]);
      final graph = LayoutComposer().compose(doc);
      final fromGraph = OfficePdfService().fromPageGraph(graph);
      final fromDoc = OfficePdfService().fromDocument(doc);
      expect(fromGraph.pageCount, fromDoc.pageCount);
      expect(fromGraph.bytes.length, fromDoc.bytes.length,
          reason: 'compor de novo não pode mudar o resultado');
    });

    test('renderer cooperativo gera os mesmos bytes e cede entre páginas',
        () async {
      final doc = docOf([
        for (var i = 0; i < 220; i++)
          paragraph('Linha cooperativa $i com conteúdo para várias páginas.'),
      ]);
      final graph = LayoutComposer().compose(doc);
      expect(graph.pages.length, greaterThan(1));
      final renderer = PageGraphPdfRenderer(title: 'cooperativo');
      final synchronous = renderer.render(graph);
      final timings = <String, int>{};
      final cooperative = await renderer.renderAsync(
        graph,
        timings: timings,
        workBudget: Duration.zero,
      );

      expect(cooperative, synchronous,
          reason: 'yield não pode alterar um byte do PDF determinístico');
      expect(timings['cooperativeYields'], graph.pages.length - 1);
      expect(timings['maxPageUs'], greaterThan(0));
      expect(
          timings['totalUs'], greaterThanOrEqualTo(timings['pageRenderUs']!));
    });

    test('documento de várias páginas gera todas no PDF', () {
      final doc = docOf([
        for (var i = 0; i < 400; i++)
          paragraph('Linha $i do corpo do documento para forçar paginação.')
      ]);
      final result = OfficePdfService().fromDocument(doc);
      expect(result.pageCount, greaterThan(3));
      // Uma entrada /Type /Page por página do grafo.
      final pages = '/Type /Page'.allMatches(pdfText(result.bytes)).length;
      expect(pages, greaterThanOrEqualTo(result.pageCount));
    });
  });

  group('a partir do Delta do banco', () {
    test('Delta Quill vira PDF e o relatório vem junto', () {
      final ops = [
        {'insert': 'Memorando'},
        {
          'insert': '\n',
          'attributes': {'header': 1}
        },
        {'insert': 'Corpo do despacho.'},
        {'insert': '\n'},
      ];
      final result = OfficePdfService().fromQuillDelta(ops);

      expect(pdfText(result.pdf.bytes), startsWith('%PDF-'));
      expect(result.pdf.pageCount, 1);
      expect(result.report.issues, isEmpty,
          reason: 'um Delta comum não pode gerar aviso de perda');
    });

    test('o que não sabemos representar aparece no relatório, não some', () {
      final ops = [
        {
          'insert': 'texto',
          'attributes': {'formatoInventado': true}
        },
        {'insert': '\n'},
      ];
      final result = OfficePdfService().fromQuillDelta(ops);
      expect(pdfText(result.pdf.bytes), startsWith('%PDF-'));
      expect(result.report.issues, isNotEmpty,
          reason: 'o PDF assinado não pode perder conteúdo em silêncio');
    });
  });

  group('configuração', () {
    test('a página do serviço respeita o setup dado', () {
      final doc = docOf([paragraph('a')]);
      final wide = OfficePdfService(
          setup: const PageSetupTwips(widthTwips: 16838, heightTwips: 11906));
      expect(wide.fromDocument(doc).pageCount, 1);
      expect(pdfText(wide.fromDocument(doc).bytes), contains('/MediaBox'));
    });

    test('diagnostics chegam ao chamador', () {
      final result = OfficePdfService().fromDocument(docOf([paragraph('x')]));
      expect(result.diagnostics.warnings, isEmpty);
    });
  });
}
