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
    tr.setNodeMarkup(
        cell.pos, null, _cellAttrsWithWidth(cell.node, widthTwips));
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

// -- formatação de célula -----------------------------------------------------

/// As células ALVO de uma formatação, com o mapa da tabela delas.
///
/// Com uma [CellSelection] são todas as do retângulo; sem ela, a célula do
/// cursor — exatamente a regra do Word, onde "sombrear" sem seleção pinta a
/// célula em que se está digitando. Não existe um terceiro caso: a seleção
/// CRUA entre células é bloqueada pela view justamente para não haver um
/// alvo ambíguo aqui.
({OfficeTableMap map, List<OfficeTableCell> cells})? tableFormatScope(
    EditorState state) {
  final selection = state.selection;
  final map = OfficeTableMap.at(state.doc, selection.from);
  if (map == null) return null;
  if (selection is CellSelection) {
    final cells = <OfficeTableCell>[
      for (final pos in selection.cellPositions)
        if (map.cellAt(pos + 1) != null) map.cellAt(pos + 1)!,
    ];
    if (cells.isNotEmpty) return (map: map, cells: cells);
  }
  final cell = map.cellAt(selection.from);
  return cell == null ? null : (map: map, cells: [cell]);
}

/// As opções de borda do grupo Bordas do Word.
///
/// `outside`/`inside` são relativas ao RETÂNGULO da seleção, não à tabela:
/// selecionar quatro células e pedir "externas" contorna o bloco escolhido,
/// que é o que o usuário vê selecionado.
enum OfficeCellBorders { all, none, outside, inside, top, bottom, left, right }

/// Uma aresta visível de 1/2 pt — o padrão do Word (`w:sz` em oitavos de
/// ponto). A cor `auto` deixa o tema decidir; o compositor a resolve como
/// preto.
const Map<String, dynamic> officeVisibleCellBorder = {
  'val': 'single',
  'sizeEighths': 4,
  'color': 'auto',
};

/// Ausência EXPLÍCITA de aresta. Não é o mesmo que omitir a chave: omitir
/// faz a célula herdar a borda da tabela (`tblBorders`), enquanto `nil`
/// apaga a aresta naquela célula — a diferença entre "não opinei" e "não
/// quero", que é o que "Sem Bordas" precisa dizer.
const Map<String, dynamic> officeNoCellBorder = {'val': 'nil'};

/// Aplica bordas nas células do escopo ([tableFormatScope]).
///
/// Grava em `attrs['word']['borders']`, o MESMO mapa que o compositor lê
/// (`layout_composer._resolvedCellBorder`) e que a exportação devolve para
/// `w:tcBorders`. As arestas não mencionadas ficam intactas: pedir "borda
/// superior" não apaga o resto, como no Word.
bool setCellBorders(
  EditorState state,
  void Function(Transaction) dispatch,
  OfficeCellBorders which,
) {
  final scope = tableFormatScope(state);
  if (scope == null) return false;
  final cells = scope.cells;

  var top = cells.first.row, bottom = cells.first.rowEnd;
  var left = cells.first.column, right = cells.first.columnEnd;
  for (final cell in cells) {
    if (cell.row < top) top = cell.row;
    if (cell.rowEnd > bottom) bottom = cell.rowEnd;
    if (cell.column < left) left = cell.column;
    if (cell.columnEnd > right) right = cell.columnEnd;
  }

  final tr = state.tr;
  var changed = false;
  // Ordem decrescente pela mesma razão das outras operações: nenhum passo
  // anterior desloca as posições dos seguintes.
  for (final cell in cells.reversed) {
    final onTop = cell.row == top;
    final onBottom = cell.rowEnd == bottom;
    final onLeft = cell.column == left;
    final onRight = cell.columnEnd == right;
    final sides = <String, dynamic>{};
    void set(String side, Map<String, dynamic> border) => sides[side] = border;

    switch (which) {
      case OfficeCellBorders.all:
        for (final side in const ['top', 'bottom', 'left', 'right']) {
          set(side, officeVisibleCellBorder);
        }
      case OfficeCellBorders.none:
        for (final side in const ['top', 'bottom', 'left', 'right']) {
          set(side, officeNoCellBorder);
        }
      case OfficeCellBorders.outside:
        if (onTop) set('top', officeVisibleCellBorder);
        if (onBottom) set('bottom', officeVisibleCellBorder);
        if (onLeft) set('left', officeVisibleCellBorder);
        if (onRight) set('right', officeVisibleCellBorder);
      case OfficeCellBorders.inside:
        if (!onTop) set('top', officeVisibleCellBorder);
        if (!onBottom) set('bottom', officeVisibleCellBorder);
        if (!onLeft) set('left', officeVisibleCellBorder);
        if (!onRight) set('right', officeVisibleCellBorder);
      case OfficeCellBorders.top:
        if (onTop) set('top', officeVisibleCellBorder);
      case OfficeCellBorders.bottom:
        if (onBottom) set('bottom', officeVisibleCellBorder);
      case OfficeCellBorders.left:
        if (onLeft) set('left', officeVisibleCellBorder);
      case OfficeCellBorders.right:
        if (onRight) set('right', officeVisibleCellBorder);
    }
    if (sides.isEmpty) continue;

    final word = _mapOf(cell.node.attrs['word']);
    tr.setNodeMarkup(cell.pos, null, {
      ...cell.node.attrs,
      'word': {
        ...word,
        'borders': {..._mapOf(word['borders']), ...sides},
      },
    });
    changed = true;
  }
  if (!changed) return false;
  dispatch(tr);
  return true;
}

/// Sombreia as células do escopo. [color] em `#rrggbb`; null limpa.
///
/// Grava nos DOIS lugares que precisam concordar, como a largura de coluna:
/// `attrs['cell']['background']` (o caminho direto do compositor) e
/// `attrs['word']['shading']` (o que vira `w:shd` na exportação). O OOXML
/// quer o hexa SEM `#`, então só o mapa `cell` carrega o prefixo.
bool setCellShading(
  EditorState state,
  void Function(Transaction) dispatch,
  String? color,
) {
  final scope = tableFormatScope(state);
  if (scope == null) return false;
  final fill = color == null
      ? null
      : (color.startsWith('#') ? color.substring(1) : color).toUpperCase();

  final tr = state.tr;
  for (final cell in scope.cells.reversed) {
    final presentation = _mapOf(cell.node.attrs['cell']);
    final word = _mapOf(cell.node.attrs['word']);
    if (color == null) {
      presentation.remove('background');
      word.remove('shading');
    } else {
      presentation['background'] = color;
      word['shading'] = {'val': 'clear', 'color': 'auto', 'fill': fill};
    }
    tr.setNodeMarkup(cell.pos, null, {
      ...cell.node.attrs,
      'cell': presentation,
      'word': word,
    });
  }
  dispatch(tr);
  return true;
}

/// Alinhamento vertical do conteúdo das células do escopo.
///
/// [align] aceita `top`, `center` (ou `middle`) e `bottom`. Grava em
/// `attrs['cell']['verticalAlign']` — o primeiro lugar que o compositor
/// consulta — e em `attrs['word']['vAlign']`, que é o `w:vAlign` da
/// exportação.
bool setCellVerticalAlign(
  EditorState state,
  void Function(Transaction) dispatch,
  String align,
) {
  final value = switch (align.trim().toLowerCase()) {
    'top' => 'top',
    'center' || 'middle' => 'center',
    'bottom' => 'bottom',
    _ => null,
  };
  if (value == null) return false;
  final scope = tableFormatScope(state);
  if (scope == null) return false;

  final tr = state.tr;
  for (final cell in scope.cells.reversed) {
    tr.setNodeMarkup(cell.pos, null, {
      ...cell.node.attrs,
      'cell': {..._mapOf(cell.node.attrs['cell']), 'verticalAlign': value},
      'word': {..._mapOf(cell.node.attrs['word']), 'vAlign': value},
    });
  }
  dispatch(tr);
  return true;
}

// -- distribuir ---------------------------------------------------------------

/// As posições dos nós `tableRow` de [map], em ordem de documento.
///
/// O mapa de grade indexa CÉLULAS; quem precisa gravar em `w:trPr` (altura
/// de linha) precisa da posição da própria linha, que só sai percorrendo os
/// filhos da tabela.
List<int> tableRowPositions(OfficeTableMap map) {
  final positions = <int>[];
  var offset = map.tablePos + 1;
  for (var r = 0; r < map.table.childCount; r++) {
    final row = map.table.child(r);
    if (row.type.name == 'tableRow') positions.add(offset);
    offset += row.nodeSize;
  }
  return positions;
}

/// Iguala a largura das colunas da tabela da seleção.
///
/// A largura total preservada é a DECLARADA (`colWidths`, o `w:tblGrid`)
/// quando ela existe — distribuir não pode mudar o tamanho da tabela. Só
/// quando a tabela não declara grade nenhuma é que [totalWidthTwips] entra:
/// aí a largura real vem da área útil da página, que o chrome conhece e uma
/// função pura sobre o documento não teria como adivinhar.
bool distributeTableColumns(
  EditorState state,
  void Function(Transaction) dispatch, {
  int? totalWidthTwips,
}) {
  final map = OfficeTableMap.at(state.doc, state.selection.from);
  if (map == null || map.columns == 0) return false;

  final declared = <int>[];
  final raw = map.table.attrs['colWidths'];
  if (raw is List) {
    for (final value in raw) {
      final width = value is num ? value.toInt() : int.tryParse('$value');
      if (width != null && width > 0) declared.add(width);
    }
  }
  final total = declared.length >= map.columns
      ? declared.take(map.columns).fold<int>(0, (sum, w) => sum + w)
      : (totalWidthTwips ?? 0);
  if (total <= 0) return false;

  final each = total ~/ map.columns;
  if (each <= 0) return false;
  final widths = [
    for (var c = 0; c < map.columns; c++)
      c == map.columns - 1 ? total - each * (map.columns - 1) : each,
  ];

  final tr = state.tr;
  // Mesma regra de `setTableColumnWidth`: a grade e o `width` das células
  // simples têm de concordar, senão a projeção e o Word discordam.
  for (final cell in map.cells.reversed) {
    if (cell.columnSpan != 1 || cell.column >= widths.length) continue;
    tr.setNodeMarkup(
        cell.pos, null, _cellAttrsWithWidth(cell.node, widths[cell.column]));
  }
  tr.setNodeMarkup(map.tablePos, null, {
    ...map.table.attrs,
    'colWidths': widths,
  });
  dispatch(tr);
  return true;
}

/// Iguala a altura das linhas da tabela da seleção em [heightTwips].
///
/// A regra gravada é `atLeast`, não `exact`: no Word, distribuir linhas não
/// pode fazer texto sumir — uma linha cujo conteúdo não caiba na altura
/// distribuída continua crescendo. `exact` cortaria o conteúdo em silêncio.
///
/// A altura vem de FORA porque só a projeção sabe a altura real das linhas
/// de uma tabela cujo `w:trHeight` não é declarado (o caso comum); calcular
/// isso aqui exigiria compor o documento dentro de uma operação de modelo.
bool distributeTableRows(
  EditorState state,
  void Function(Transaction) dispatch, {
  required int heightTwips,
}) {
  if (heightTwips <= 0) return false;
  final map = OfficeTableMap.at(state.doc, state.selection.from);
  if (map == null) return false;
  final positions = tableRowPositions(map);
  if (positions.isEmpty) return false;

  final tr = state.tr;
  for (final pos in positions.reversed) {
    final row = state.doc.nodeAt(pos);
    if (row == null) continue;
    tr.setNodeMarkup(pos, null, {
      ...row.attrs,
      'word': {
        ..._mapOf(row.attrs['word']),
        'heightTwips': heightTwips,
        'heightRule': 'atLeast',
      },
    });
  }
  dispatch(tr);
  return true;
}

/// Os attrs de uma célula com a largura gravada nos DOIS lugares que o Word
/// consulta.
///
/// `cell.width` é o que a NOSSA projeção usa; `word.width` é o `w:tcW`, que
/// a exportação reserializa (`docx_codec._tableCellPropertiesToJson`). Numa
/// tabela IMPORTADA o `tcW` antigo sobrevive no XML, e o Word costuma
/// preferi-lo à grade nova — atualizar só um dos dois faz a coluna
/// redimensionada voltar ao tamanho velho ao abrir no Word.
Map<String, dynamic> _cellAttrsWithWidth(PMNode cell, int widthTwips) {
  final word = _mapOf(cell.attrs['word']);
  return {
    ...cell.attrs,
    'cell': {
      ..._mapOf(cell.attrs['cell']),
      'width': widthTwips,
    },
    'word': {
      ...word,
      'width': {'value': widthTwips, 'type': 'dxa'},
    },
  };
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
