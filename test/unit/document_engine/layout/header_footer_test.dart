/// Fase 4 — cabeçalho e rodapé como regiões.
///
/// Todo ofício e memorando tem timbre e numeração de página. Eles são
/// regiões PRÓPRIAS: repetem em todas as páginas, ficam fora do espaço de
/// posições do documento e são inertes na projeção — a mesma região
/// aparecendo N vezes não pode virar N edições concorrentes do mesmo nó.
@TestOn('vm')
library;

import 'package:test/test.dart';

import 'dart:typed_data';

import 'package:dart_quill/dart_quill_office.dart';

import '../../../support/pdf_reader.dart';

void main() {
  final schema = officeQuillSchema();

  PMNode paragraph(String text) => schema.node(
      'paragraph', null, Fragment.from([schema.text(text)]));

  PMNode region(String text) =>
      schema.node('doc', null, Fragment.from([paragraph(text)]));

  PMNode body(int blocks) => schema.node(
      'doc',
      null,
      Fragment.from([
        for (var i = 0; i < blocks; i++)
          paragraph('Parágrafo $i com texto suficiente para ocupar a linha '
              'inteira e forçar a paginação a trabalhar.')
      ]));

  /// O texto que o PDF realmente desenha. Os content streams são
  /// comprimidos, então ler os bytes crus não encontraria nada.
  String pdfText(List<int> bytes) =>
      PdfReader(Uint8List.fromList(bytes)).decodedStreams.join('\n');

  group('composição', () {
    test('a região aparece em TODAS as páginas', () {
      final graph = LayoutComposer(
        header: region('Prefeitura Municipal'),
        footer: region('documento oficial'),
      ).compose(body(300));

      expect(graph.pages.length, greaterThan(2));
      for (final page in graph.pages) {
        expect(page.header, isNotEmpty);
        expect(page.footer, isNotEmpty);
      }
    });

    test('sem região, nada é adicionado', () {
      final graph = LayoutComposer().compose(body(60));
      expect(graph.pages.first.header, isEmpty);
      expect(graph.pages.first.footer, isEmpty);
    });

    test('a região NÃO entra no espaço de posições do documento', () {
      final graph =
          LayoutComposer(header: region('timbre')).compose(body(120));
      for (final entry in graph.positionMap.entries) {
        expect(entry.docPosStart, greaterThanOrEqualTo(0),
            reason: 'nenhuma posição do corpo pode vir da região');
      }
      // O fragmento da região declara -1: não corresponde a posição alguma.
      expect(graph.pages.first.header.first.docPos, -1);
    });

    test('sem campo, a MESMA lista é reusada em todas as páginas', () {
      final graph =
          LayoutComposer(header: region('timbre fixo')).compose(body(300));
      final first = graph.pages.first.header;
      for (final page in graph.pages) {
        expect(identical(page.header, first), isTrue,
            reason: 'recompor conteúdo idêntico 200 vezes é desperdício puro');
      }
    });
  });

  group('campos de página', () {
    test('{PAGE} vira o número da página', () {
      final graph = LayoutComposer(footer: region('Página {PAGE}'))
          .compose(body(300));
      expect(graph.pages.length, greaterThan(2));

      String textOf(int index) => graph.pages[index].footer
          .expand((f) => f.lines)
          .expand((l) => l.segments)
          .map((s) => s.text)
          .join();

      expect(textOf(0), contains('Página 1'));
      expect(textOf(1), contains('Página 2'));
      expect(textOf(graph.pages.length - 1),
          contains('Página ${graph.pages.length}'));
    });

    test('{NUMPAGES} vira o total', () {
      final graph = LayoutComposer(footer: region('{PAGE} de {NUMPAGES}'))
          .compose(body(300));
      final total = graph.pages.length;
      final last = graph.pages.last.footer
          .expand((f) => f.lines)
          .expand((l) => l.segments)
          .map((s) => s.text)
          .join();
      expect(last, contains('$total de $total'));
    });

    test('com campo, cada página tem a SUA composição', () {
      final graph =
          LayoutComposer(footer: region('Página {PAGE}')).compose(body(300));
      expect(identical(graph.pages[0].footer, graph.pages[1].footer), isFalse,
          reason: 'o texto muda por página, então a medição também muda');
    });
  });

  group('nas duas saídas', () {
    test('o PDF desenha o timbre em todas as páginas', () {
      final graph = LayoutComposer(header: region('PREFEITURA'))
          .compose(body(300));
      final pdf = PageGraphPdfRenderer().render(graph);
      final content = pdfText(pdf);

      // Standard-14 escreve o texto legível no stream.
      expect('PREFEITURA'.allMatches(content).length,
          greaterThanOrEqualTo(graph.pages.length),
          reason: 'uma ocorrência por página, no mínimo');
    });

    test('a numeração de página sai correta no PDF', () {
      final graph = LayoutComposer(footer: region('- {PAGE} -'))
          .compose(body(300));
      final content = pdfText(PageGraphPdfRenderer().render(graph));
      expect(content, contains('- 1 -'));
      expect(content, contains('- 2 -'));
    });

    test('o PDF sem região continua igual', () {
      final doc = body(120);
      final withNone = PageGraphPdfRenderer().render(LayoutComposer().compose(doc));
      final again = PageGraphPdfRenderer().render(LayoutComposer().compose(doc));
      expect(again.length, withNone.length);
    });
  });
}
