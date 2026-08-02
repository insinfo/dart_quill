/// Fase 5 — LayoutComposer + PageGraph + PdfRenderer.
///
/// O invariante central da arquitetura: o editor e o PDF consomem o MESMO
/// PageGraph — o teste de paridade confere que o texto da página N do grafo
/// é exatamente o texto da página N do PDF. E a fragmentação por LINHA:
/// um parágrafo que não cabe atravessa páginas sem virar dois nós.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import 'package:dart_quill/dart_quill_office.dart';

import '../../../support/pdf_reader.dart';

void main() {
  final schema = officeQuillSchema();

  PMNode docOf(List<PMNode> blocks) =>
      schema.node('doc', null, Fragment.from(blocks));

  PMNode paragraph(String text) => schema.node(
      'paragraph', null, Fragment.from([schema.text(text)]));

  group('LayoutComposer', () {
    test('documento curto cabe numa página', () {
      final graph = LayoutComposer()
          .compose(docOf([paragraph('linha um'), paragraph('linha dois')]));
      expect(graph.pages, hasLength(1));
      expect(graph.pages.first.fragments, hasLength(2));
      final first = graph.pages.first.fragments[0];
      final second = graph.pages.first.fragments[1];
      expect(second.yTwips, first.yTwips + first.heightTwips,
          reason: 'fragments empilham sem sobreposição');
    });

    test('muitos parágrafos fragmentam em várias páginas', () {
      final blocks = [
        for (var i = 0; i < 200; i++)
          paragraph('Parágrafo $i com texto suficiente para uma linha real.')
      ];
      final graph = LayoutComposer().compose(docOf(blocks));
      expect(graph.pages.length, greaterThan(1));
      final capacity = graph.pages.first.setup.contentHeightTwips;
      for (final page in graph.pages) {
        for (final fragment in page.fragments) {
          expect(fragment.yTwips + fragment.heightTwips,
              lessThanOrEqualTo(capacity),
              reason: 'página ${page.index}: fragment dentro da área útil');
        }
      }
    });

    test('parágrafo maior que a página atravessa em granularidade de LINHA',
        () {
      final long = paragraph(List.generate(
              2000, (i) => 'palavra$i').join(' '));
      final graph = LayoutComposer().compose(docOf([long]));
      expect(graph.pages.length, greaterThan(1));
      final first = graph.pages.first.fragments.single as BlockFragment;
      final second = graph.pages[1].fragments.first as BlockFragment;
      expect(first.continuesOnNextPage, isTrue);
      expect(second.continuesFromPreviousPage, isTrue);
      expect(first.docPos, second.docPos,
          reason: 'o MESMO nó produz os dois fragments');
      expect(second.marker, isNull);
    });

    test('determinístico: duas composições dão o mesmo grafo', () {
      final doc = docOf([
        for (var i = 0; i < 50; i++) paragraph('linha $i de conteúdo estável')
      ]);
      String signature(PageGraph g) => jsonEncode([
            for (final page in g.pages)
              [
                for (final f in page.fragments)
                  [
                    f.docPos,
                    f.yTwips,
                    f.heightTwips,
                    if (f is BlockFragment)
                      for (final l in f.lines) [l.charStart, l.charEnd]
                  ]
              ]
          ]);
      expect(signature(LayoutComposer().compose(doc)),
          signature(LayoutComposer().compose(doc)));
    });

    test('PositionMap responde a página de uma posição', () {
      final blocks = [
        for (var i = 0; i < 200; i++)
          paragraph('Parágrafo $i para o mapa de posições ficar denso.')
      ];
      final graph = LayoutComposer().compose(docOf(blocks));
      expect(graph.pages.length, greaterThan(1));
      // a primeira posição está na página 0; a última, na última página.
      expect(graph.positionMap.pageOf(1), 0);
      final lastEntry = graph.positionMap.entries.last;
      expect(graph.positionMap.pageOf(lastEntry.docPosStart),
          graph.pages.length - 1);
    });

    test('heading sai maior e listItem sai com marcador e recuo', () {
      final doc = docOf([
        schema.node('heading', {'level': 1},
            Fragment.from([schema.text('Título')])),
        schema.node('listItem', {'kind': 'ordered'},
            Fragment.from([schema.text('item')])),
      ]);
      final graph = LayoutComposer().compose(doc);
      final fragments =
          graph.pages.first.fragments.cast<BlockFragment>();
      expect(fragments[0].lines.first.heightTwips,
          greaterThan(fragments[1].lines.first.heightTwips),
          reason: 'H1 é maior que texto de lista');
      expect(fragments[1].marker, '1. ');
      expect(fragments[1].indentTwips, greaterThan(0));
    });
  });

  group('PdfRenderer — o MESMO PageGraph', () {
    test('o PDF tem o mesmo número de páginas do grafo', () {
      final blocks = [
        for (var i = 0; i < 200; i++)
          paragraph('Parágrafo $i indo para o PDF pelo grafo.')
      ];
      final graph = LayoutComposer().compose(docOf(blocks));
      final pdf = PdfReader(PageGraphPdfRenderer().render(graph));
      expect(pdf.pageCount, graph.pages.length);
    });

    test('paridade por página: o texto da página N do grafo está na página N',
        () {
      final blocks = [
        for (var i = 0; i < 120; i++)
          paragraph('Sentença número $i com conteúdo distinto.')
      ];
      final graph = LayoutComposer().compose(docOf(blocks));
      expect(graph.pages.length, greaterThan(1));
      final streams = PdfReader(PageGraphPdfRenderer().render(graph))
          .decodedStreams
          .where((s) => s.contains('Tj'))
          .toList();
      expect(streams.length, graph.pages.length);
      for (var p = 0; p < graph.pages.length; p++) {
        for (final fragment
            in graph.pages[p].fragments.whereType<BlockFragment>()) {
          for (final line in fragment.lines) {
            for (final segment in line.segments) {
              // WinAnsi escapa acentos como octal no stream: amostra ASCII.
              final word = segment.text.split(' ').firstWhere(
                  (w) => RegExp(r'^[A-Za-z0-9]{4,}$').hasMatch(w),
                  orElse: () => '');
              if (word.isEmpty) continue;
              expect(streams[p], contains(word),
                  reason: '"$word" do grafo pág. $p tem de estar no PDF '
                      'pág. $p');
              break; // uma amostra por linha basta
            }
          }
        }
      }
    });

    test('tabela compõe TableFragment e fragmenta por linha de tabela', () {
      // 60 linhas de tabela não cabem numa página: o MESMO nó produz
      // fragments em páginas consecutivas.
      final rows = <PMNode>[];
      for (var r = 0; r < 60; r++) {
        rows.add(schema.node('tableRow', {'rowId': 'r$r'}, Fragment.from([
          schema.node('tableCell', {'cellId': 'a$r'}, Fragment.from([
            paragraph('célula A da linha $r'),
          ])),
          schema.node('tableCell', {'cellId': 'b$r'}, Fragment.from([
            paragraph('célula B $r'),
          ])),
        ])));
      }
      final table = schema.node('table', {
        'colWidths': [
          {'width': '300'},
          {'width': '300'},
        ],
      }, Fragment.from(rows));
      final graph = LayoutComposer().compose(docOf([table]));
      expect(graph.pages.length, greaterThan(1));
      final first = graph.pages.first.fragments.single as TableFragment;
      final second = graph.pages[1].fragments.first as TableFragment;
      expect(first.continuesOnNextPage, isTrue);
      expect(second.continuesFromPreviousPage, isTrue);
      expect(first.docPos, second.docPos,
          reason: 'a MESMA tabela produz os fragments');
      final totalRows = graph.pages
          .expand((p) => p.fragments)
          .whereType<TableFragment>()
          .expand((f) => f.rows)
          .length;
      expect(totalRows, 60, reason: 'nenhuma linha se perde na fragmentação');

      // E o PDF desenha as grades: um retângulo por célula.
      final streams = PdfReader(PageGraphPdfRenderer().render(graph))
          .decodedStreams
          .join('\n');
      final rects = RegExp(r'(?:[-\d.]+ ){4}re S').allMatches(streams).length;
      expect(rects, 120, reason: '60 linhas × 2 células');
    });

    test('Delta real do SALI passa pelo grafo até o PDF', () {
      final raw = jsonDecode(
          File('test/assets/delta/documento.delta.json').readAsStringSync());
      final ops = (raw as Map)['ops'] as List;
      final imported = importQuillDelta(ops, schema);
      final graph = LayoutComposer().compose(imported.doc);
      expect(graph.pages, isNotEmpty);
      final pdf = PdfReader(PageGraphPdfRenderer().render(graph));
      expect(pdf.pageCount, graph.pages.length);
      final text = pdf.decodedStreams.join(' ');
      expect(text, contains('Servidores'),
          reason: 'o conteúdo real chega ao PDF via PageGraph');
    });
  });
}
