@TestOn('vm')
library;

import 'package:dart_quill/dart_quill_office.dart';
import 'package:dart_quill/src/platform/dom.dart';
import 'package:test/test.dart';

import '../../../support/fake_dom.dart';

void main() {
  final schema = officeQuillSchema();

  PMNode paragraph(String text, {String? id}) => schema.node(
      'paragraph',
      {if (id != null) 'id': id},
      text.isEmpty ? Fragment.empty : Fragment.from([schema.text(text)]));

  PMNode cell(String id, String text,
          {Map<String, dynamic>? presentation, Map<String, dynamic>? word}) =>
      schema.node(
          'tableCell',
          {
            'id': id,
            'cellId': id,
            if (presentation != null) 'cell': presentation,
            if (word != null) 'word': word,
          },
          Fragment.from([paragraph(text, id: '$id-p')]));

  PMNode row(String id, List<PMNode> cells, {Map<String, dynamic>? word}) =>
      schema.node(
          'tableRow',
          {'id': id, 'rowId': id, if (word != null) 'word': word},
          Fragment.from(cells));

  PMNode documentWith(PMNode table) =>
      schema.node('doc', null, Fragment.from([table]));

  group('tabelas Word no PageGraph', () {
    test('colWidths numérico é twips e colspan soma a grade real', () {
      final first = cell(
        'a',
        'alpha',
        presentation: {
          'colspan': 2,
          'background': '#F0E0D0',
          'verticalAlign': 'center',
        },
        word: {
          'gridSpan': 2,
          'vAlign': 'center',
          'shading': {'fill': 'F0E0D0'},
          'borders': {
            'top': {
              'val': 'double',
              'sizeEighths': 8,
              'color': 'FF0000',
            },
          },
        },
      );
      final second = cell('b', 'beta');
      final table = schema.node(
          'table',
          {
            'id': 't',
            'colWidths': [1200, 1800, 1600],
            'word': {
              'borders': {
                'top': {'val': 'single', 'sizeEighths': 4, 'color': '000000'},
                'bottom': {
                  'val': 'single',
                  'sizeEighths': 4,
                  'color': '000000'
                },
                'left': {'val': 'single', 'sizeEighths': 4, 'color': '000000'},
                'right': {'val': 'single', 'sizeEighths': 4, 'color': '000000'},
                'insideH': {
                  'val': 'single',
                  'sizeEighths': 4,
                  'color': '000000'
                },
                'insideV': {
                  'val': 'single',
                  'sizeEighths': 4,
                  'color': '000000'
                },
              },
            },
          },
          Fragment.from([
            row('r0', [
              first,
              second
            ], word: {
              'heightTwips': 900,
              'heightRule': 'exact',
              'cantSplit': true,
              'tblHeader': true,
            }),
          ]));

      final graph = LayoutComposer().compose(documentWith(table));
      final fragment = graph.pages.single.fragments.single as TableFragment;
      final layoutRow = fragment.rows.single;
      final a = layoutRow.cells.first;
      final b = layoutRow.cells.last;

      expect(a.widthTwips, 3000, reason: '1200 + 1800 twips, sem conversão px');
      expect(a.columnSpan, 2);
      expect(b.xTwips, 3000);
      expect(b.widthTwips, 1600);
      expect(layoutRow.heightTwips, 900);
      expect(layoutRow.heightRule, 'exact');
      expect(layoutRow.cantSplit, isTrue);
      expect(layoutRow.repeatHeader, isTrue);
      expect(a.backgroundColor, '#F0E0D0');
      expect(a.verticalAlign, TableCellVerticalAlign.center);
      expect(a.contentOffsetTwips, greaterThan(0));
      expect(a.borders.top?.style, 'double');
      expect(a.borders.top?.color, '#FF0000');
    });

    test('background auto legado é transparente no PageGraph', () {
      final table = schema.node(
          'table',
          {
            'id': 't-auto',
            'colWidths': [2400]
          },
          Fragment.from([
            row('r-auto', [
              cell(
                'c-auto',
                'sem preenchimento',
                presentation: {'background': '#auto'},
                word: {
                  'shading': {'val': 'clear', 'color': 'auto', 'fill': 'auto'}
                },
              ),
            ]),
          ]));

      final graph = LayoutComposer().compose(documentWith(table));
      final fragment = graph.pages.single.fragments.single as TableFragment;

      expect(fragment.rows.single.cells.single.backgroundColor, isNull);
    });

    test('posições PM internas são reais e o PositionMap é por linha', () {
      final table = schema.node(
          'table',
          {
            'id': 't',
            'colWidths': [2000, 2000]
          },
          Fragment.from([
            row('r0', [cell('a', 'alpha'), cell('b', 'beta')]),
          ]));
      final graph = LayoutComposer().compose(documentWith(table));
      final fragment = graph.pages.single.fragments.single as TableFragment;
      final layoutRow = fragment.rows.single;
      final firstCell = layoutRow.cells.first;
      final secondCell = layoutRow.cells.last;

      expect(fragment.docPos, 1, reason: 'conteúdo da tabela');
      expect(layoutRow.docPos, 2, reason: 'conteúdo da primeira row');
      expect(firstCell.docPos, 3, reason: 'conteúdo da primeira célula');
      expect(firstCell.blocks.single.docPos, 4,
          reason: 'conteúdo do parágrafo dentro da célula');
      expect(secondCell.docPos, 3 + table.child(0).child(0).nodeSize,
          reason: 'offset PM inclui o nodeSize da célula anterior');
      expect(firstCell.blocks.single.docPos, isNot(0));

      final alphaEntries = graph.positionMap.entries.where((entry) =>
          entry.docPosStart == firstCell.blocks.single.docPos &&
          entry.docPosEnd == firstCell.blocks.single.docPos + 'alpha'.length);
      expect(alphaEntries, hasLength(1));
      expect(graph.positionMap.pageOf(firstCell.blocks.single.docPos), 0);
      expect(graph.positionMap.entries.length, greaterThanOrEqualTo(5),
          reason: 'row, células e linhas têm âncoras próprias');
    });

    test('gridBefore/gridAfter deslocam células de linhas irregulares', () {
      final table = schema.node(
          'table',
          {
            'colWidths': [1000, 1000, 1000]
          },
          Fragment.from([
            row('r', [
              cell('middle', 'centro')
            ], word: {
              'gridBefore': 1,
              'gridAfter': 1,
              'widthBefore': {'value': 1000, 'type': 'dxa'},
              'widthAfter': {'value': 1000, 'type': 'dxa'},
            }),
          ]));
      final fragment = LayoutComposer()
          .compose(documentWith(table))
          .pages
          .single
          .fragments
          .single as TableFragment;

      expect(fragment.rows.single.gridBefore, 1);
      expect(fragment.rows.single.gridAfter, 1);
      expect(fragment.rows.single.widthBeforeTwips, 1000);
      expect(fragment.rows.single.cells.single.xTwips, 1000);
    });

    test('w:jc posiciona a grade inteira sem alterar larguras', () {
      PMNode alignedTable(String jc,
              {int? indentTwips, List<int> widths = const [1200, 1800]}) =>
          schema.node(
              'table',
              {
                'colWidths': widths,
                'word': {
                  'jc': jc,
                  if (indentTwips != null) 'indentTwips': indentTwips,
                },
              },
              Fragment.from([
                row('r-$jc', [cell('a-$jc', 'A'), cell('b-$jc', 'B')]),
              ]));

      TableFragment compose(String jc,
              {int? indentTwips, List<int> widths = const [1200, 1800]}) =>
          LayoutComposer(
            setup: const PageSetupTwips(
              widthTwips: 7000,
              heightTwips: 9000,
              marginTopTwips: 1000,
              marginRightTwips: 1000,
              marginBottomTwips: 1000,
              marginLeftTwips: 1000,
            ),
          )
              .compose(documentWith(
                  alignedTable(jc, indentTwips: indentTwips, widths: widths)))
              .pages
              .single
              .fragments
              .single as TableFragment;

      final centered = compose('center');
      expect(centered.rows.single.cells.first.xTwips, 1000,
          reason: '(5000 - 3000) / 2');
      expect(centered.rows.single.cells.last.xTwips, 2200);
      expect(centered.rows.single.cells.last.widthTwips, 1800);

      expect(compose('right').rows.single.cells.first.xTwips, 2000);
      expect(compose('left', indentTwips: 360).rows.single.cells.first.xTwips,
          360);
      expect(compose('center', indentTwips: 360).rows.single.cells.first.xTwips,
          1000,
          reason: 'tblInd não desloca uma tabela centralizada');
      expect(
        compose('left', indentTwips: 360, widths: const [2500, 2500])
            .rows
            .single
            .cells
            .first
            .xTwips,
        360,
        reason: 'tblInd pode projetar a grade além da margem direita',
      );
    });

    test('vMerge vira rowspan e o grupo não quebra entre páginas', () {
      final rows = [
        row('r0', [
          cell('a0', 'mesclada',
              presentation: {'vMerge': 'restart'}, word: {'vMerge': 'restart'}),
          cell('b0', 'B0'),
        ]),
        row('r1', [
          cell('a1', '',
              presentation: {'vMerge': 'continue'},
              word: {'vMerge': 'continue'}),
          cell('b1', 'B1'),
        ]),
        row('r2', [
          cell('a2', '',
              presentation: {'vMerge': 'continue'},
              word: {'vMerge': 'continue'}),
          cell('b2', 'B2'),
        ]),
      ];
      final table = schema.node(
          'table',
          {
            'colWidths': [1500, 1500]
          },
          Fragment.from(rows));
      final doc =
          schema.node('doc', null, Fragment.from([paragraph('antes'), table]));
      final graph = LayoutComposer(
        setup: const PageSetupTwips(
          widthTwips: 5000,
          heightTwips: 1250,
          marginTopTwips: 100,
          marginRightTwips: 100,
          marginBottomTwips: 100,
          marginLeftTwips: 100,
        ),
      ).compose(doc);
      final fragments = graph.pages
          .expand((page) => page.fragments)
          .whereType<TableFragment>()
          .toList();

      expect(fragments, hasLength(1),
          reason: 'as três rows do vMerge formam um grupo indivisível');
      expect(fragments.single.rows.first.cells.first.rowSpan, 3);
      expect(fragments.single.rows[1].cells.first.isMergeContinuation, isTrue);
      expect(fragments.single.rows[2].cells.first.isMergeContinuation, isTrue);
      expect(
          fragments.single.rows.first.cells.first.heightTwips,
          fragments.single.rows
              .fold<int>(0, (sum, row) => sum + row.heightTwips));
    });

    test('header Word é repetido sem duplicar entradas editáveis', () {
      final rows = <PMNode>[
        row('header', [cell('h', 'CABEÇALHO')], word: {'tblHeader': true}),
        for (var i = 0; i < 10; i++) row('r$i', [cell('c$i', 'linha $i')]),
      ];
      final table = schema.node(
          'table',
          {
            'colWidths': [2500]
          },
          Fragment.from(rows));
      final graph = LayoutComposer(
        setup: const PageSetupTwips(
          widthTwips: 4000,
          heightTwips: 1500,
          marginTopTwips: 100,
          marginRightTwips: 100,
          marginBottomTwips: 100,
          marginLeftTwips: 100,
        ),
      ).compose(documentWith(table));
      final fragments = graph.pages
          .expand((page) => page.fragments)
          .whereType<TableFragment>()
          .toList();

      expect(fragments.length, greaterThan(1));
      expect(fragments[1].rows.first.isRepeatedHeader, isTrue);
      expect(fragments[1].rows.first.repeatHeader, isTrue);
      final headerTextPos =
          fragments.first.rows.first.cells.first.blocks.first.docPos;
      final pagesForHeader = graph.positionMap.entries
          .where((entry) => entry.docPosStart == headerTextPos)
          .map((entry) => entry.pageIndex)
          .toSet();
      expect(pagesForHeader, {0},
          reason: 'a cópia visual não cria um segundo caret editável');
    });

    test('tblCellMar é herdado e tcMar sobrescreve cada lado em dxa', () {
      final inner = schema.node(
          'paragraph',
          {
            'style': {
              'lineTwips': 200,
              'lineRule': 'exact',
            }
          },
          Fragment.from([schema.text('conteúdo')]));
      final tableCell = schema.node(
          'tableCell',
          {
            'id': 'margins',
            'word': {
              'margins': {
                'left': {'value': 140, 'type': 'dxa'},
              }
            }
          },
          Fragment.from([inner]));
      final table = schema.node(
          'table',
          {
            'colWidths': [2000],
            'word': {
              'cellMargins': {
                'top': {'value': 0, 'type': 'dxa'},
                'right': {'value': 70, 'type': 'dxa'},
                'bottom': {'value': 0, 'type': 'dxa'},
                'left': {'value': 70, 'type': 'dxa'},
              }
            }
          },
          Fragment.from([
            row('r', [tableCell])
          ]));

      final fragment = LayoutComposer()
          .compose(documentWith(table))
          .pages
          .single
          .fragments
          .single as TableFragment;
      final layoutCell = fragment.rows.single.cells.single;

      expect(layoutCell.marginTopTwips, 0);
      expect(layoutCell.marginRightTwips, 70);
      expect(layoutCell.marginBottomTwips, 0);
      expect(layoutCell.marginLeftTwips, 140,
          reason: 'tcMar/left ganha de tblCellMar/left');
      expect(layoutCell.blocks.single.yTwips, 0);
      expect(layoutCell.blocks.single.indentTwips, 140);
      expect(layoutCell.blocks.single.rightIndentTwips, 70);
      expect(layoutCell.contentHeightTwips, 200);
      expect(fragment.rows.single.heightTwips, 200,
          reason: 'margem vertical zero não infla a row em 120 twips');
    });

    test('borda colapsada fecha row atLeast uma vez, exact já a inclui', () {
      final bottom = {
        'val': 'single',
        'sizeEighths': 4,
        'color': '000000',
      };
      PMNode borderedCell(String id) => cell(id, '', word: {
            'borders': {
              'top': {'val': 'nil'},
              'bottom': bottom,
            },
            'margins': {
              'top': {'value': 0, 'type': 'dxa'},
              'bottom': {'value': 0, 'type': 'dxa'},
            },
          });
      final table = schema.node(
          'table',
          {
            'colWidths': [2000],
            'word': {
              'cellMargins': {
                'top': {'value': 0, 'type': 'dxa'},
                'bottom': {'value': 0, 'type': 'dxa'},
              }
            },
          },
          Fragment.from([
            row('at-least', [
              borderedCell('a')
            ], word: {
              'heightTwips': 290,
            }),
            row('exact', [
              borderedCell('b')
            ], word: {
              'heightTwips': 290,
              'heightRule': 'exact',
            }),
          ]));

      final fragment = LayoutComposer()
          .compose(documentWith(table))
          .pages
          .single
          .fragments
          .single as TableFragment;

      expect(fragment.rows.first.heightTwips, 300,
          reason: 'clip 290 + uma aresta w:sz=4 de 10 twips');
      expect(fragment.rows.last.heightTwips, 290,
          reason: 'altura exact já inclui a borda no box fixo');
      expect(fragment.heightTwips, 590);
    });

    test('row fragmenta por linha, preserva texto e evita viúva final', () {
      final inline = <PMNode>[];
      for (var i = 0; i < 10; i++) {
        inline.add(schema.text('L$i'));
        if (i != 9) {
          inline.add(schema.node('hardBreak', {'breakType': null}, null));
        }
      }
      final inner = schema.node(
          'paragraph',
          {
            'style': {
              'lineTwips': 200,
              'lineRule': 'exact',
            }
          },
          Fragment.from(inline));
      final tableCell =
          schema.node('tableCell', {'id': 'long-cell'}, Fragment.from([inner]));
      final table = schema.node(
          'table',
          {
            'id': 'long-table',
            'colWidths': [2000],
            'word': {
              'cellMargins': {
                'top': {'value': 0, 'type': 'dxa'},
                'right': {'value': 0, 'type': 'dxa'},
                'bottom': {'value': 0, 'type': 'dxa'},
                'left': {'value': 0, 'type': 'dxa'},
              }
            }
          },
          Fragment.from([
            row('long-row', [tableCell], word: {'cantSplit': false})
          ]));
      final graph = LayoutComposer(
        setup: const PageSetupTwips(
          widthTwips: 4000,
          heightTwips: 900,
          marginTopTwips: 100,
          marginRightTwips: 100,
          marginBottomTwips: 100,
          marginLeftTwips: 100,
        ),
      ).compose(documentWith(table));
      final fragments = graph.pages
          .expand((page) => page.fragments)
          .whereType<TableFragment>()
          .toList();
      final rows = fragments.map((fragment) => fragment.rows.single).toList();

      expect(graph.pages, hasLength(4));
      expect(rows.map((row) => row.heightTwips), [600, 600, 400, 400],
          reason: 'widowControl padrão mantém as duas últimas linhas juntas');
      expect(rows.map((row) => row.continuesFromPreviousPage),
          [false, true, true, true]);
      expect(rows.map((row) => row.continuesOnNextPage),
          [true, true, true, false]);
      final lines = rows
          .expand((row) => row.cells.single.blocks)
          .expand((block) => block.lines)
          .toList();
      expect(lines, hasLength(10));
      expect(
          lines
              .expand((line) => line.segments)
              .where((segment) => !segment.hardBreak)
              .map((segment) => segment.text)
              .join(),
          'L0L1L2L3L4L5L6L7L8L9');
      expect(graph.positionMap.pageOf(1 + 1 + 1 + 1), 0);
      expect(graph.positionMap.entries.map((entry) => entry.pageIndex).toSet(),
          {0, 1, 2, 3});
    });

    test('page break inline dentro de célula corta a mesma row entre páginas',
        () {
      final inner = schema.node(
          'paragraph',
          {
            'id': 'split-paragraph',
            'style': const {
              'lineTwips': 200,
              'lineRule': 'exact',
              'widowControl': false,
            },
          },
          Fragment.from([
            schema.text('head'),
            schema.node('hardBreak', {'breakType': 'page'}, null),
            schema.text('tail'),
          ]));
      final tableCell = schema.node('tableCell',
          {'id': 'split-cell', 'cellId': 'split-cell'}, Fragment.from([inner]));
      final table = schema.node(
          'table',
          {
            'id': 'split-table',
            'colWidths': [2000],
            'word': {
              'cellMargins': {
                'top': {'value': 0, 'type': 'dxa'},
                'right': {'value': 0, 'type': 'dxa'},
                'bottom': {'value': 0, 'type': 'dxa'},
                'left': {'value': 0, 'type': 'dxa'},
              }
            }
          },
          Fragment.from([
            row('split-row', [tableCell], word: {'cantSplit': false})
          ]));

      final graph = LayoutComposer(
        setup: const PageSetupTwips(
          widthTwips: 4000,
          heightTwips: 1000,
          marginTopTwips: 0,
          marginRightTwips: 0,
          marginBottomTwips: 0,
          marginLeftTwips: 0,
        ),
      ).compose(documentWith(table));

      expect(graph.pages, hasLength(2));
      final first = graph.pages.first.fragments.single as TableFragment;
      final second = graph.pages.last.fragments.single as TableFragment;
      expect(first.rows.single.continuesOnNextPage, isTrue);
      expect(second.rows.single.continuesFromPreviousPage, isTrue);
      expect(first.rows.single.sourceRowId, second.rows.single.sourceRowId);
      final firstLine =
          first.rows.single.cells.single.blocks.single.lines.single;
      final secondLine =
          second.rows.single.cells.single.blocks.single.lines.single;
      expect(
          firstLine.segments.map((segment) => segment.text).join(), 'head\n');
      expect(secondLine.segments.map((segment) => segment.text).join(), 'tail');
      expect(secondLine.manualPageBreakBefore, isTrue);
      expect(graph.positionMap.entries.map((entry) => entry.pageIndex).toSet(),
          {0, 1});
    });

    test('hint interno de row e alias na row seguinte formam uma só quebra',
        () {
      PMNode marker() => schema.node('opaqueInline', {
            'insert': {
              'qname': 'w:lastRenderedPageBreak',
              'officeXml': '<w:lastRenderedPageBreak/>',
              'runContent': true,
              'renderedPageBreakHint': true,
            }
          });
      PMNode exactParagraph(String id, List<PMNode> inline) => schema.node(
          'paragraph',
          {
            'id': id,
            'style': const {'lineTwips': 200, 'lineRule': 'exact'},
          },
          Fragment.from(inline));
      PMNode exactCell(String id, PMNode inner) => schema.node(
          'tableCell', {'id': id, 'cellId': id}, Fragment.from([inner]));

      final table = schema.node(
          'table',
          {
            'id': 'hinted-table',
            'colWidths': [2000, 2000],
            'word': {
              'cellMargins': {
                'top': {'value': 0, 'type': 'dxa'},
                'right': {'value': 0, 'type': 'dxa'},
                'bottom': {'value': 0, 'type': 'dxa'},
                'left': {'value': 0, 'type': 'dxa'},
              }
            }
          },
          Fragment.from([
            row('r0', [
              exactCell('r0c0', exactParagraph('left', [schema.text('left')])),
              exactCell(
                  'r0c1',
                  exactParagraph('split',
                      [schema.text('head'), marker(), schema.text('tail')])),
            ]),
            row('r1', [
              exactCell('r1c0',
                  exactParagraph('next', [marker(), schema.text('next')])),
              exactCell(
                  'r1c1', exactParagraph('right', [schema.text('right')])),
            ]),
          ]));
      final doc = documentWith(table);
      final composer = LayoutComposer(
        setup: const PageSetupTwips(
          widthTwips: 5000,
          heightTwips: 1000,
          marginTopTwips: 0,
          marginRightTwips: 0,
          marginBottomTwips: 0,
          marginLeftTwips: 0,
        ),
      );
      final imported = composer.compose(doc);

      expect(imported.pages, hasLength(2));
      expect(imported.honoredRenderedPageBreakHints, isTrue);
      final firstRows = imported.pages.first.fragments
          .whereType<TableFragment>()
          .expand((fragment) => fragment.rows)
          .toList();
      final secondRows = imported.pages.last.fragments
          .whereType<TableFragment>()
          .expand((fragment) => fragment.rows)
          .toList();
      expect(firstRows.map((row) => row.sourceRowId), ['r0']);
      expect(firstRows.single.continuesOnNextPage, isTrue);
      expect(secondRows.map((row) => row.sourceRowId), ['r0', 'r1'],
          reason: 'o marker no início de r1 é alias do corte interno de r0');
      expect(secondRows.first.continuesFromPreviousPage, isTrue);

      final natural = composer.compose(doc, honorRenderedPageBreaks: false);
      expect(natural.pages, hasLength(1));
      expect(natural.honoredRenderedPageBreakHints, isFalse);
      final naturalRows =
          (natural.pages.single.fragments.single as TableFragment).rows;
      expect(naturalRows, hasLength(2));
      expect(naturalRows.map((row) => row.heightTwips), [200, 200]);
      final naturalSplit = naturalRows.first.cells[1].blocks.single;
      expect(naturalSplit.lines, hasLength(1),
          reason: 'marker desabilitado é opaco; não fecha a linha da célula');
      expect(
        naturalSplit.lines.single.segments
            .map((segment) => segment.text)
            .join(),
        'headtail',
      );

      final edited = composer.composeIncremental(
        doc,
        previous: imported,
        changedFromDocPos: 1,
      );
      expect(edited.pages, hasLength(1),
          reason: 'lastRenderedPageBreak não vira quebra manual após editar');
      expect(edited.honoredRenderedPageBreakHints, isFalse);
    });

    test('hint no primeiro conteúdo da row abre a row na página seguinte', () {
      final marker = schema.node('opaqueInline', {
        'insert': {
          'qname': 'w:lastRenderedPageBreak',
          'officeXml': '<w:lastRenderedPageBreak/>',
          'runContent': true,
          'renderedPageBreakHint': true,
        }
      });
      PMNode hintedCell(String id, List<PMNode> inline) => schema.node(
          'tableCell',
          {'id': id, 'cellId': id},
          Fragment.from([
            schema.node(
                'paragraph',
                {
                  'id': '$id-p',
                  'style': const {'lineTwips': 200, 'lineRule': 'exact'},
                },
                Fragment.from(inline))
          ]));
      final table = schema.node(
          'table',
          {
            'id': 'row-start-hint',
            'colWidths': [3000]
          },
          Fragment.from([
            row('r0', [
              hintedCell('c0', [schema.text('antes')])
            ]),
            row('r1', [
              hintedCell('c1', [marker, schema.text('depois')])
            ]),
          ]));
      final graph = LayoutComposer(
        setup: const PageSetupTwips(
          widthTwips: 4000,
          heightTwips: 1000,
          marginTopTwips: 0,
          marginRightTwips: 0,
          marginBottomTwips: 0,
          marginLeftTwips: 0,
        ),
      ).compose(documentWith(table));

      expect(graph.pages, hasLength(2));
      expect(
        graph.pages.first.fragments
            .whereType<TableFragment>()
            .expand((fragment) => fragment.rows)
            .map((row) => row.sourceRowId),
        ['r0'],
      );
      expect(
        graph.pages.last.fragments
            .whereType<TableFragment>()
            .expand((fragment) => fragment.rows)
            .map((row) => row.sourceRowId),
        ['r1'],
      );
    });
  });

  group('projeção DOM de tabelas Word', () {
    late FakeDomDocument document;
    late DomElement host;

    setUp(() {
      document = FakeDomDocument();
      host = document.createElement('div');
      document.body.append(host);
    });

    test('projeta âncoras, spans, shading, bordas, vAlign e flags da row', () {
      final table = schema.node(
          'table',
          {
            'colWidths': [1200, 1200]
          },
          Fragment.from([
            row('r', [
              cell('a', 'alpha', presentation: {
                'colspan': 2,
                'background': '#ABCDEF',
                'verticalAlign': 'bottom',
              }, word: {
                'gridSpan': 2,
                'vAlign': 'bottom',
                'shading': {'fill': 'ABCDEF'},
              }),
            ], word: {
              'heightTwips': 800,
              'heightRule': 'exact',
              'cantSplit': true,
              'tblHeader': true,
            }),
          ]));
      final graph = LayoutComposer().compose(documentWith(table));
      PageGraphDomRenderer(document: document, editable: true)
          .render(graph, host);

      final rowElement = host.querySelector('.dq-office-table-row')!;
      final cellElement = host.querySelector('.dq-office-table-cell')!;
      final blockElement = host.querySelector('.dq-office-block')!;
      expect(rowElement.getAttribute('data-doc-pos'), '2');
      expect(rowElement.getAttribute('data-height-rule'), 'exact');
      expect(rowElement.getAttribute('data-cant-split'), 'true');
      expect(rowElement.getAttribute('data-repeat-header'), 'true');
      expect(cellElement.getAttribute('data-doc-pos'), '3');
      expect(cellElement.getAttribute('colspan'), '2');
      expect(cellElement.getAttribute('aria-colspan'), '2');
      expect(cellElement.getAttribute('data-vertical-align'), 'bottom');
      expect(
          cellElement.getAttribute('style'),
          allOf(contains('background-color:#ABCDEF'),
              contains('height:53.33px')));
      expect(blockElement.getAttribute('data-doc-pos'), '4');

      const positionMap = OfficeDomPositionMap();
      final point = positionMap.domPositionFor(host, 4)!;
      expect(positionMap.modelPositionAt(point.node, point.offset), 4);
    });

    test('continuação vMerge fica estrutural e não desenha outra célula', () {
      final table = schema.node(
          'table',
          {
            'colWidths': [1000, 1000]
          },
          Fragment.from([
            row('r0', [
              cell('a0', 'A',
                  presentation: {'vMerge': 'restart'},
                  word: {'vMerge': 'restart'}),
              cell('b0', 'B0'),
            ]),
            row('r1', [
              cell('a1', '',
                  presentation: {'vMerge': 'continue'},
                  word: {'vMerge': 'continue'}),
              cell('b1', 'B1'),
            ]),
          ]));
      final graph = LayoutComposer().compose(documentWith(table));
      PageGraphDomRenderer(document: document).render(graph, host);

      final cells = host.querySelectorAll('.dq-office-table-cell');
      final origin = cells.first;
      final continuation = cells.firstWhere((element) =>
          element.classes.contains('dq-office-table-cell-merge-continuation'));
      expect(origin.getAttribute('rowspan'), '2');
      expect(origin.getAttribute('aria-rowspan'), '2');
      expect(continuation.getAttribute('data-vmerge'), 'continue');
      expect(continuation.getAttribute('style'), 'display:none;');
      expect(continuation.getAttribute('contenteditable'), 'false');
    });

    test('header repetido é projeção inerte sem data-doc-pos', () {
      final rows = <PMNode>[
        row('hrow', [cell('h', 'HEAD')], word: {'tblHeader': true}),
        for (var i = 0; i < 8; i++) row('r$i', [cell('c$i', 'row $i')]),
      ];
      final table = schema.node(
          'table',
          {
            'colWidths': [2000]
          },
          Fragment.from(rows));
      final graph = LayoutComposer(
        setup: const PageSetupTwips(
          widthTwips: 4000,
          heightTwips: 1300,
          marginTopTwips: 100,
          marginRightTwips: 100,
          marginBottomTwips: 100,
          marginLeftTwips: 100,
        ),
      ).compose(documentWith(table));
      PageGraphDomRenderer(document: document, editable: true)
          .render(graph, host);

      final repeated =
          host.querySelector('.dq-office-table-row-repeated-header')!;
      expect(repeated.getAttribute('data-repeated-header'), 'true');
      expect(repeated.getAttribute('contenteditable'), 'false');
      expect(repeated.getAttribute('aria-hidden'), 'true');
      expect(repeated.getAttribute('data-doc-pos'), isNull);
      expect(
          repeated
              .querySelector('.dq-office-block')!
              .getAttribute('data-doc-pos'),
          isNull);
    });

    test('continuação de row e margens ficam explícitas no DOM', () {
      final inline = <PMNode>[];
      for (var i = 0; i < 5; i++) {
        inline.add(schema.text('L$i'));
        if (i != 4) {
          inline.add(schema.node('hardBreak', {'breakType': null}, null));
        }
      }
      final inner = schema.node(
          'paragraph',
          {
            'style': {
              'lineTwips': 200,
              'lineRule': 'exact',
            }
          },
          Fragment.from(inline));
      final tableCell = schema.node(
          'tableCell',
          {
            'word': {
              'margins': {
                'left': {'value': 70, 'type': 'dxa'},
              }
            }
          },
          Fragment.from([inner]));
      final table = schema.node(
          'table',
          {
            'colWidths': [2000],
            'word': {
              'cellMargins': {
                'top': {'value': 0, 'type': 'dxa'},
                'right': {'value': 0, 'type': 'dxa'},
                'bottom': {'value': 0, 'type': 'dxa'},
                'left': {'value': 0, 'type': 'dxa'},
              }
            }
          },
          Fragment.from([
            row('r', [tableCell])
          ]));
      final graph = LayoutComposer(
        setup: const PageSetupTwips(
          widthTwips: 4000,
          heightTwips: 700,
          marginTopTwips: 100,
          marginRightTwips: 100,
          marginBottomTwips: 100,
          marginLeftTwips: 100,
        ),
      ).compose(documentWith(table));

      PageGraphDomRenderer(document: document).render(graph, host);

      final rows = host.querySelectorAll('.dq-office-table-row');
      expect(rows, hasLength(3));
      expect(rows.first.getAttribute('data-continues-on'), 'true');
      expect(rows[1].getAttribute('data-continues-from'), 'true');
      final cells = host.querySelectorAll('.dq-office-table-cell');
      expect(cells.first.getAttribute('data-margin-left-twips'), '70');
      expect(cells.first.getAttribute('data-margin-top-twips'), '0');
    });
  });
}
