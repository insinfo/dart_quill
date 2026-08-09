/// F4 — tabela interativa: o mapa de grade, a seleção retangular de células
/// e as operações que ela destrava (mesclar, dividir, largura de coluna).
///
/// O foco é o MODELO: se a grade for lida errado, "as células da coluna 2"
/// vira uma lista errada e toda operação estrutural age no lugar errado —
/// e isso não aparece olhando a tela, aparece no DOCX exportado.
@TestOn('vm')
library;

import 'package:test/test.dart';

import 'package:dart_quill/dart_quill_office.dart';
import 'package:dart_quill/src/document_engine/ui/table_ops.dart' as ops;

void main() {
  final schema = officeQuillSchema();

  PMNode cell(String text, {int? colspan, int? rowspan, String? vMerge}) {
    final attrs = <String, dynamic>{};
    final map = <String, dynamic>{};
    if (colspan != null) map['colspan'] = colspan;
    if (rowspan != null) map['rowspan'] = rowspan;
    if (vMerge != null) map['vMerge'] = vMerge;
    if (map.isNotEmpty) attrs['cell'] = map;
    return schema.node(
      'tableCell',
      attrs.isEmpty ? null : attrs,
      Fragment.from([
        schema.node('paragraph', null,
            text.isEmpty ? Fragment.empty : Fragment.from([schema.text(text)])),
      ]),
    );
  }

  PMNode row(List<PMNode> cells) =>
      schema.node('tableRow', null, Fragment.from(cells));

  PMNode tableDoc(List<PMNode> rows) => schema.node(
        'doc',
        null,
        Fragment.from([
          schema.node('paragraph', null, Fragment.from([schema.text('antes')])),
          schema.node('table', null, Fragment.from(rows)),
          schema.node(
              'paragraph', null, Fragment.from([schema.text('depois')])),
        ]),
      );

  /// Uma grade simples 3×3 com o texto "rXcY".
  PMNode grid3x3() => tableDoc([
        for (var r = 0; r < 3; r++)
          row([for (var c = 0; c < 3; c++) cell('r${r}c$c')]),
      ]);

  int tablePositionOf(PMNode doc) {
    var offset = 0;
    for (var i = 0; i < doc.childCount; i++) {
      if (doc.child(i).type.name == 'table') return offset;
      offset += doc.child(i).nodeSize;
    }
    throw StateError('sem tabela');
  }

  EditorState stateOf(PMNode doc) =>
      EditorState.create(EditorStateConfig(doc: doc));

  /// Aplica transações num estado local, como faria a view.
  ({EditorState state}) run(
    EditorState state,
    bool Function(EditorState, void Function(Transaction)) action,
  ) {
    var current = state;
    action(state, (tr) => current = current.apply(tr));
    return (state: current);
  }

  group('mapa de grade', () {
    test('grade simples: cada célula na sua linha e coluna', () {
      final doc = grid3x3();
      final map = OfficeTableMap.of(doc, tablePositionOf(doc));

      expect(map.rows, 3);
      expect(map.columns, 3);
      expect(map.cells, hasLength(9));
      final middle = map.cellCovering(1, 1);
      expect(middle, isNotNull);
      expect(middle!.node.textContent, 'r1c1');
    });

    test('colspan ocupa as colunas vizinhas e desloca as seguintes', () {
      // Linha 0: [A(colspan 2)][B] — B fica na coluna 2, não na 1.
      final doc = tableDoc([
        row([cell('A', colspan: 2), cell('B')]),
        row([cell('C'), cell('D'), cell('E')]),
      ]);
      final map = OfficeTableMap.of(doc, tablePositionOf(doc));

      expect(map.columns, 3);
      expect(map.cellCovering(0, 0)!.node.textContent, 'A');
      expect(map.cellCovering(0, 1)!.node.textContent, 'A',
          reason: 'a segunda coluna é COBERTA pelo colspan');
      expect(map.cellCovering(0, 2)!.node.textContent, 'B');
      expect(map.cellCovering(1, 1)!.node.textContent, 'D');
    });

    test('rowspan ocupa as linhas de baixo e empurra as células da direita',
        () {
      // A ocupa (0,0) e (1,0); na linha 1 a primeira célula da árvore é C,
      // que na GRADE está na coluna 1.
      final doc = tableDoc([
        row([cell('A', rowspan: 2), cell('B')]),
        row([cell('C')]),
      ]);
      final map = OfficeTableMap.of(doc, tablePositionOf(doc));

      expect(map.cellCovering(0, 0)!.node.textContent, 'A');
      expect(map.cellCovering(1, 0)!.node.textContent, 'A');
      expect(map.cellCovering(1, 1)!.node.textContent, 'C');
    });

    test('o retângulo entre duas células EXPANDE para não cortar mesclagem',
        () {
      final doc = tableDoc([
        row([cell('A', colspan: 2), cell('B')]),
        row([cell('C'), cell('D'), cell('E')]),
      ]);
      final map = OfficeTableMap.of(doc, tablePositionOf(doc));
      // De C (linha 1, coluna 0) até a célula que cobre (0,1) — que é A,
      // mesclada: o retângulo tem de crescer para conter A inteira.
      final rectangle = map.rectangleBetween(
        map.cellCovering(1, 0)!,
        map.cellCovering(0, 1)!,
      );
      expect(rectangle.fromRow, 0);
      expect(rectangle.toRow, 1);
      expect(rectangle.fromColumn, 0);
      expect(rectangle.toColumn, 1);
    });
  });

  group('seleção retangular', () {
    test('selecionar coluna pega as três células dela', () {
      final doc = grid3x3();
      final map = OfficeTableMap.of(doc, tablePositionOf(doc));
      final top = map.cellCovering(0, 1)!;
      var state = stateOf(doc);
      state = state.apply(
          state.tr..setSelection(TextSelection.create(doc, top.pos + 2)));

      final result =
          run(state, (s, dispatch) => ops.selectTableColumn(s, dispatch));

      final selection = result.state.selection;
      expect(selection, isA<CellSelection>());
      final cells = (selection as CellSelection).cellPositions;
      expect(cells, hasLength(3));
      final texts = [
        for (final pos in cells) result.state.doc.nodeAt(pos)!.textContent,
      ];
      expect(texts, ['r0c1', 'r1c1', 'r2c1']);
    });

    test('selecionar linha pega as três células dela', () {
      final doc = grid3x3();
      final map = OfficeTableMap.of(doc, tablePositionOf(doc));
      var state = stateOf(doc);
      state = state.apply(state.tr
        ..setSelection(
            TextSelection.create(doc, map.cellCovering(2, 0)!.pos + 2)));

      final result =
          run(state, (s, dispatch) => ops.selectTableRow(s, dispatch));

      final cells = (result.state.selection as CellSelection).cellPositions;
      expect([
        for (final pos in cells) result.state.doc.nodeAt(pos)!.textContent,
      ], [
        'r2c0',
        'r2c1',
        'r2c2'
      ]);
    });

    test('selecionar a tabela inteira pega as nove células', () {
      final doc = grid3x3();
      final map = OfficeTableMap.of(doc, tablePositionOf(doc));
      var state = stateOf(doc);
      state = state.apply(state.tr
        ..setSelection(
            TextSelection.create(doc, map.cellCovering(1, 1)!.pos + 2)));

      final result =
          run(state, (s, dispatch) => ops.selectWholeTable(s, dispatch));

      expect((result.state.selection as CellSelection).cellPositions,
          hasLength(9));
    });

    test('uma seleção de células nunca é considerada vazia', () {
      final doc = tableDoc([
        row([cell(''), cell('')]),
      ]);
      final map = OfficeTableMap.of(doc, tablePositionOf(doc));
      var state = stateOf(doc);
      state = state.apply(state.tr
        ..setSelection(
            TextSelection.create(doc, map.cellCovering(0, 0)!.pos + 2)));
      final result =
          run(state, (s, dispatch) => ops.selectTableRow(s, dispatch));

      expect(result.state.selection.empty, isFalse,
          reason: 'células em branco continuam sendo uma escolha do usuário');
    });

    test('não seleciona retângulo entre tabelas diferentes', () {
      final doc = schema.node(
          'doc',
          null,
          Fragment.from([
            schema.node(
                'table',
                null,
                Fragment.from([
                  row([cell('A')])
                ])),
            schema.node(
                'table',
                null,
                Fragment.from([
                  row([cell('B')])
                ])),
          ]));
      final first = OfficeTableMap.of(doc, 0);
      var second = 0;
      for (var i = 0; i < doc.childCount; i++) {
        if (i == 1) break;
        second += doc.child(i).nodeSize;
      }
      final secondMap = OfficeTableMap.of(doc, second);
      final state = stateOf(doc);

      final selected = ops.selectCellRange(
        state,
        (_) {},
        first.cells.first.pos + 1,
        secondMap.cells.first.pos + 1,
      );

      expect(selected, isFalse);
    });
  });

  group('mesclar e dividir', () {
    test('mesclar duas células soma o span e CONCATENA o conteúdo', () {
      final doc = grid3x3();
      final map = OfficeTableMap.of(doc, tablePositionOf(doc));
      var state = stateOf(doc);
      state = state.apply(state.tr
        ..setSelection(
            TextSelection.create(doc, map.cellCovering(0, 0)!.pos + 2)));
      var afterSelection =
          run(state, (s, dispatch) => ops.selectTableRow(s, dispatch)).state;

      final merged = run(afterSelection,
          (s, dispatch) => ops.mergeSelectedCells(s, dispatch)).state;

      final newMap = OfficeTableMap.of(merged.doc, tablePositionOf(merged.doc));
      final survivor = newMap.cellCovering(0, 0)!;
      expect(survivor.columnSpan, 3,
          reason: 'a linha inteira virou uma célula');
      expect(survivor.node.textContent, contains('r0c0'));
      expect(survivor.node.textContent, contains('r0c1'));
      expect(survivor.node.textContent, contains('r0c2'),
          reason: 'nenhum texto pode sumir numa mesclagem');
      // A linha passa a ter UMA célula na árvore.
      expect(newMap.cells.where((c) => c.row == 0), hasLength(1));
    });

    test('dividir devolve as células e o span some', () {
      final doc = tableDoc([
        row([cell('A', colspan: 3)]),
        row([cell('C'), cell('D'), cell('E')]),
      ]);
      final map = OfficeTableMap.of(doc, tablePositionOf(doc));
      var state = stateOf(doc);
      state = state.apply(state.tr
        ..setSelection(
            TextSelection.create(doc, map.cellCovering(0, 0)!.pos + 2)));

      final split =
          run(state, (s, dispatch) => ops.splitSelectedCell(s, dispatch)).state;

      final newMap = OfficeTableMap.of(split.doc, tablePositionOf(split.doc));
      expect(newMap.cells.where((c) => c.row == 0), hasLength(3));
      expect(newMap.cellCovering(0, 0)!.columnSpan, 1);
      expect(newMap.cellCovering(0, 0)!.node.textContent, 'A',
          reason: 'o conteúdo fica na primeira célula');
    });

    test('mesclar sem seleção de células não faz nada', () {
      final doc = grid3x3();
      final state = stateOf(doc);
      expect(ops.mergeSelectedCells(state, (_) {}), isFalse);
    });

    test('dividir uma célula simples não faz nada', () {
      final doc = grid3x3();
      final map = OfficeTableMap.of(doc, tablePositionOf(doc));
      var state = stateOf(doc);
      state = state.apply(state.tr
        ..setSelection(
            TextSelection.create(doc, map.cellCovering(1, 1)!.pos + 2)));
      expect(ops.splitSelectedCell(state, (_) {}), isFalse);
    });
  });

  group('largura de coluna', () {
    test('grava nos DOIS lugares: colWidths da tabela e width das células', () {
      final doc = grid3x3();
      final tablePos = tablePositionOf(doc);
      final state = stateOf(doc);

      final result = run(
        state,
        (s, dispatch) => ops.setTableColumnWidth(
          s,
          dispatch,
          tablePos: tablePos,
          columnIndex: 1,
          widthTwips: 2000,
        ),
      ).state;

      final table = result.doc.nodeAt(tablePos)!;
      expect((table.attrs['colWidths'] as List)[1], 2000);
      final map = OfficeTableMap.of(result.doc, tablePos);
      for (var r = 0; r < 3; r++) {
        final cell = map.cellCovering(r, 1)!;
        expect((cell.node.attrs['cell'] as Map)['width'], 2000,
            reason: 'a célula da linha $r tem de acompanhar a grade');
      }
      // As outras colunas ficam intactas.
      expect((map.cellCovering(0, 0)!.node.attrs['cell'] as Map?)?['width'],
          isNull);
    });

    test('grava também o w:tcW, senão o Word ignora a grade nova', () {
      final doc = grid3x3();
      final tablePos = tablePositionOf(doc);
      final state = stateOf(doc);

      final result = run(
        state,
        (s, dispatch) => ops.setTableColumnWidth(
          s,
          dispatch,
          tablePos: tablePos,
          columnIndex: 1,
          widthTwips: 2000,
        ),
      ).state;

      final map = OfficeTableMap.of(result.doc, tablePos);
      final word = map.cellCovering(0, 1)!.node.attrs['word'] as Map;
      // O formato é o que docx_codec._widthFromJson lê de volta.
      expect((word['width'] as Map)['value'], 2000);
      expect((word['width'] as Map)['type'], 'dxa');
    });

    test('largura não positiva é rejeitada', () {
      final doc = grid3x3();
      final state = stateOf(doc);
      expect(
        ops.setTableColumnWidth(state, (_) {},
            tablePos: tablePositionOf(doc), columnIndex: 0, widthTwips: 0),
        isFalse,
      );
    });
  });
}
