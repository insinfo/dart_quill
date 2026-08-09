/// Operações estruturais de tabela — funções PURAS sobre o estado.
///
/// Separadas da UI de propósito: a aba contextual e uma futura quickbar
/// flutuante chamam as MESMAS funções, e elas são testáveis sem montar
/// chrome nenhum.
library;

import '../model/index.dart';
import '../state/index.dart';
import 'table_map.dart';

/// A profundidade da tabela que contém a seleção, ou null.
int? tableDepthOf(EditorState state) {
  final resolved = state.selection.fromRes;
  for (var depth = resolved.depth; depth > 0; depth--) {
    if (resolved.node(depth).type.name == 'table') return depth;
  }
  return null;
}

// -- seleção retangular de células -------------------------------------------

/// Seleciona o retângulo de células entre as posições [anchorPos] e
/// [headPos] (posições quaisquer DENTRO das duas células).
///
/// Devolve false quando as duas posições não estão na MESMA tabela — uma
/// seleção que atravessa tabelas não tem retângulo, e tentar inventá-lo
/// produziria operações estruturais sobre a árvore errada.
bool selectCellRange(
  EditorState state,
  void Function(Transaction) dispatch,
  int anchorPos,
  int headPos,
) {
  final map = OfficeTableMap.at(state.doc, anchorPos);
  if (map == null) return false;
  final headMap = OfficeTableMap.at(state.doc, headPos);
  if (headMap == null || headMap.tablePos != map.tablePos) return false;

  final anchorCell = map.cellAt(anchorPos);
  final headCell = map.cellAt(headPos);
  if (anchorCell == null || headCell == null) return false;

  final rectangle = map.rectangleBetween(anchorCell, headCell);
  final cells = map.cellsIn(
    fromRow: rectangle.fromRow,
    toRow: rectangle.toRow,
    fromColumn: rectangle.fromColumn,
    toColumn: rectangle.toColumn,
  );
  if (cells.isEmpty) return false;
  dispatch(state.tr
    ..setSelection(CellSelection.create(
      state.doc,
      anchorCell.pos,
      headCell.pos,
      [for (final cell in cells) cell.pos],
    )));
  return true;
}

/// Seleciona a LINHA inteira que contém a seleção.
bool selectTableRow(EditorState state, void Function(Transaction) dispatch) {
  final map = OfficeTableMap.at(state.doc, state.selection.from);
  final cell = map?.cellAt(state.selection.from);
  if (map == null || cell == null || map.columns == 0) return false;
  final first = map.cellCovering(cell.row, 0);
  final last = map.cellCovering(cell.row, map.columns - 1);
  if (first == null || last == null) return false;
  return selectCellRange(state, dispatch, first.pos + 1, last.pos + 1);
}

/// Seleciona a COLUNA inteira que contém a seleção.
bool selectTableColumn(EditorState state, void Function(Transaction) dispatch) {
  final map = OfficeTableMap.at(state.doc, state.selection.from);
  final cell = map?.cellAt(state.selection.from);
  if (map == null || cell == null || map.rows == 0) return false;
  final first = map.cellCovering(0, cell.column);
  final last = map.cellCovering(map.rows - 1, cell.column);
  if (first == null || last == null) return false;
  return selectCellRange(state, dispatch, first.pos + 1, last.pos + 1);
}

/// Seleciona a TABELA inteira (o que a âncora ⊞ faz no Word).
bool selectWholeTable(EditorState state, void Function(Transaction) dispatch) {
  final map = OfficeTableMap.at(state.doc, state.selection.from);
  if (map == null || map.rows == 0 || map.columns == 0) return false;
  final first = map.cellCovering(0, 0);
  final last = map.cellCovering(map.rows - 1, map.columns - 1);
  if (first == null || last == null) return false;
  return selectCellRange(state, dispatch, first.pos + 1, last.pos + 1);
}

// -- mesclar e dividir --------------------------------------------------------

/// Mescla as células da seleção retangular numa só.
///
/// O conteúdo das células absorvidas é CONCATENADO na primeira, e não
/// descartado — perder texto silenciosamente numa mesclagem é o pior
/// resultado possível dessa operação. As absorvidas somem da árvore
/// (estratégia do Quill), e a sobrevivente ganha `colspan`/`rowspan`.
bool mergeSelectedCells(
  EditorState state,
  void Function(Transaction) dispatch,
) {
  final selection = state.selection;
  if (selection is! CellSelection || selection.cellPositions.length < 2) {
    return false;
  }
  final map = OfficeTableMap.at(state.doc, selection.anchorCellPos);
  if (map == null) return false;

  final cells = [
    for (final pos in selection.cellPositions)
      if (map.cellAt(pos + 1) != null) map.cellAt(pos + 1)!,
  ];
  if (cells.length < 2) return false;

  var top = cells.first.row, bottom = cells.first.rowEnd;
  var left = cells.first.column, right = cells.first.columnEnd;
  for (final cell in cells) {
    if (cell.row < top) top = cell.row;
    if (cell.rowEnd > bottom) bottom = cell.rowEnd;
    if (cell.column < left) left = cell.column;
    if (cell.columnEnd > right) right = cell.columnEnd;
  }

  // A primeira em ordem de documento sobrevive.
  final survivor = cells.first;
  final absorbed = cells.skip(1).toList();

  final blocks = <PMNode>[...survivor.node.children];
  for (final cell in absorbed) {
    for (final block in cell.node.children) {
      // Parágrafos vazios das células absorvidas não viram linhas em branco
      // na sobrevivente.
      if (block.isTextblock && block.content.size == 0) continue;
      blocks.add(block);
    }
  }
  if (blocks.isEmpty) blocks.add(state.schema.node('paragraph'));

  final merged = state.schema.node(
    'tableCell',
    {
      ...survivor.node.attrs,
      'cell': {
        ..._mapOf(survivor.node.attrs['cell']),
        'colspan': right - left,
        'rowspan': bottom - top,
      }..removeWhere((key, value) => key == 'vMerge'),
    },
    Fragment.from(blocks),
  );

  final tr = state.tr;
  // Em ordem DECRESCENTE: apagar uma célula não desloca as anteriores.
  for (final cell in absorbed.reversed) {
    tr.delete(cell.pos, cell.pos + cell.node.nodeSize);
  }
  tr.replaceRangeWith(
      survivor.pos, survivor.pos + survivor.node.nodeSize, merged);
  tr.setSelection(TextSelection.create(tr.doc, survivor.pos + 2));
  dispatch(tr);
  return true;
}

/// Divide a célula mesclada da seleção de volta em células simples.
bool splitSelectedCell(
  EditorState state,
  void Function(Transaction) dispatch,
) {
  final map = OfficeTableMap.at(state.doc, state.selection.from);
  final cell = map?.cellAt(state.selection.from);
  if (map == null || cell == null) return false;
  if (cell.columnSpan <= 1 && cell.rowSpan <= 1) return false;

  final extra = cell.columnSpan * cell.rowSpan - 1;
  final simple = state.schema.node(
    'tableCell',
    {
      ...cell.node.attrs,
      'cell': _mapOf(cell.node.attrs['cell'])
        ..remove('colspan')
        ..remove('rowspan')
        ..remove('vMerge'),
    },
    cell.node.content,
  );

  final tr = state.tr;
  tr.replaceRangeWith(cell.pos, cell.pos + cell.node.nodeSize, simple);
  // As células novas entram DEPOIS da dividida, na mesma linha: é a divisão
  // horizontal, que é o caso comum e o único que não exige rearranjar a
  // grade inteira.
  final insertAt = cell.pos + simple.nodeSize;
  for (var i = 0; i < extra; i++) {
    tr.insert(insertAt, _emptyCell(state.schema));
  }
  tr.setSelection(TextSelection.create(tr.doc, cell.pos + 2));
  dispatch(tr);
  return true;
}

/// Grava a largura da coluna [columnIndex] em twips.
///
/// A largura vive em dois lugares que precisam concordar: `colWidths` da
/// tabela (a grade declarada, `w:tblGrid`) e o `width` de cada célula
/// daquela coluna. Escrever só um deles faz o Word e a nossa projeção
/// discordarem sobre a largura real.
bool setTableColumnWidth(
  EditorState state,
  void Function(Transaction) dispatch, {
  required int tablePos,
  required int columnIndex,
  required int widthTwips,
}) {
  if (widthTwips <= 0) return false;
  final map = OfficeTableMap.of(state.doc, tablePos);
  if (columnIndex < 0 || columnIndex >= map.columns) return false;

  final tr = state.tr;
  // Células da coluna, em ordem decrescente: setNodeMarkup não muda
  // tamanhos, mas manter a ordem evita surpresa se algum passo passar a
  // mudar.
  final columnCells = [
    for (final cell in map.cells)
      if (cell.column == columnIndex && cell.columnSpan == 1) cell,
  ].reversed;
  for (final cell in columnCells) {
    tr.setNodeMarkup(cell.pos, null, {
      ...cell.node.attrs,
      'cell': {
        ..._mapOf(cell.node.attrs['cell']),
        'width': widthTwips,
      },
    });
  }

  final widths = <int>[];
  final declared = map.table.attrs['colWidths'];
  if (declared is List) {
    for (final value in declared) {
      widths.add(value is num ? value.toInt() : 0);
    }
  }
  while (widths.length < map.columns) {
    widths.add(0);
  }
  widths[columnIndex] = widthTwips;
  tr.setNodeMarkup(tablePos, null, {
    ...map.table.attrs,
    'colWidths': widths,
  });
  dispatch(tr);
  return true;
}

Map<String, dynamic> _mapOf(Object? value) => value is Map
    ? Map<String, dynamic>.from(value.cast<String, dynamic>())
    : <String, dynamic>{};

PMNode _emptyCell(Schema schema) =>
    schema.node('tableCell', null, Fragment.from([schema.node('paragraph')]));

/// Insere uma linha acima/abaixo da linha da seleção.
void tableInsertRow(
  EditorState state,
  void Function(Transaction) dispatch,
  Schema schema, {
  required bool above,
}) {
  final depth = tableDepthOf(state);
  if (depth == null) return;
  final resolved = state.selection.fromRes;
  final row = resolved.node(depth + 1);
  final newRow = schema.node(
      'tableRow',
      null,
      Fragment.from(
          [for (var c = 0; c < row.childCount; c++) _emptyCell(schema)]));
  final pos = above ? resolved.before(depth + 1) : resolved.after(depth + 1);
  dispatch(state.tr..insert(pos, newRow));
}

/// Exclui a linha da seleção; a última linha exclui a tabela inteira.
void tableDeleteRow(
  EditorState state,
  void Function(Transaction) dispatch,
) {
  final depth = tableDepthOf(state);
  if (depth == null) return;
  final resolved = state.selection.fromRes;
  if (resolved.node(depth).childCount <= 1) {
    tableDelete(state, dispatch);
    return;
  }
  dispatch(
      state.tr..delete(resolved.before(depth + 1), resolved.after(depth + 1)));
}

/// Insere uma coluna à esquerda/direita da coluna da seleção, em TODAS as
/// linhas.
///
/// As posições são calculadas no documento ATUAL e aplicadas em ordem
/// DECRESCENTE: cada inserção anterior não desloca as seguintes.
void tableInsertColumn(
  EditorState state,
  void Function(Transaction) dispatch,
  Schema schema, {
  required bool before,
}) {
  final depth = tableDepthOf(state);
  if (depth == null) return;
  final resolved = state.selection.fromRes;
  final table = resolved.node(depth);
  final colIndex = resolved.index(depth + 1);
  final tableStart = resolved.start(depth);

  final insertions = <int>[];
  var rowOffset = tableStart;
  for (var r = 0; r < table.childCount; r++) {
    final row = table.child(r);
    var cellOffset = rowOffset + 1;
    for (var c = 0; c < row.childCount; c++) {
      if (c == colIndex) {
        insertions
            .add(before ? cellOffset : cellOffset + row.child(c).nodeSize);
        break;
      }
      cellOffset += row.child(c).nodeSize;
    }
    rowOffset += row.nodeSize;
  }
  final tr = state.tr;
  for (final pos in insertions.reversed) {
    tr.insert(pos, _emptyCell(schema));
  }
  dispatch(tr);
}

/// Exclui a coluna da seleção; a última coluna exclui a tabela inteira.
void tableDeleteColumn(
  EditorState state,
  void Function(Transaction) dispatch,
) {
  final depth = tableDepthOf(state);
  if (depth == null) return;
  final resolved = state.selection.fromRes;
  final table = resolved.node(depth);
  if (table.child(0).childCount <= 1) {
    tableDelete(state, dispatch);
    return;
  }
  final colIndex = resolved.index(depth + 1);
  final tableStart = resolved.start(depth);

  final ranges = <(int, int)>[];
  var rowOffset = tableStart;
  for (var r = 0; r < table.childCount; r++) {
    final row = table.child(r);
    var cellOffset = rowOffset + 1;
    for (var c = 0; c < row.childCount; c++) {
      final size = row.child(c).nodeSize;
      if (c == colIndex) {
        ranges.add((cellOffset, cellOffset + size));
        break;
      }
      cellOffset += size;
    }
    rowOffset += row.nodeSize;
  }
  final tr = state.tr;
  for (final (start, end) in ranges.reversed) {
    tr.delete(start, end);
  }
  dispatch(tr);
}

/// Exclui a tabela inteira.
void tableDelete(
  EditorState state,
  void Function(Transaction) dispatch,
) {
  final depth = tableDepthOf(state);
  if (depth == null) return;
  final resolved = state.selection.fromRes;
  dispatch(state.tr..delete(resolved.before(depth), resolved.after(depth)));
}
