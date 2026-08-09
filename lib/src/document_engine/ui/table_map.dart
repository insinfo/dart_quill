/// O MAPA DE GRADE de uma tabela: de célula do modelo para (linha, coluna).
///
/// A árvore do documento guarda linhas com as células que existem; a grade
/// VISUAL é outra coisa, porque `colspan` ocupa colunas vizinhas e
/// `vMerge`/`rowspan` ocupam linhas abaixo. Sem essa tradução não é possível
/// dizer "as células da coluna 3", que é a pergunta que seleção retangular,
/// redimensionamento de coluna e mesclagem fazem o tempo todo.
///
/// As duas convenções que o compositor já usa são respeitadas aqui, para o
/// chrome e o layout nunca discordarem sobre onde uma célula está:
///
/// * `colspan` vem de `cell.colspan` ou de `word.gridSpan` (OOXML);
/// * a continuação vertical aparece de dois jeitos — DOCX materializa a
///   célula com `vMerge=continue`, e o Quill simplesmente OMITE o slot
///   coberto. Os dois viram o mesmo `covered` aqui.
library;

import '../model/index.dart';

/// Uma célula real da árvore, com o retângulo que ela ocupa na grade.
class OfficeTableCell {
  const OfficeTableCell({
    required this.node,
    required this.pos,
    required this.rowIndex,
    required this.cellIndex,
    required this.row,
    required this.column,
    required this.rowSpan,
    required this.columnSpan,
    required this.isMergeContinuation,
  });

  final PMNode node;

  /// Posição do NÓ da célula no documento (antes do conteúdo).
  final int pos;

  /// Índices na ÁRVORE (linha e posição dentro da linha).
  final int rowIndex;
  final int cellIndex;

  /// Canto superior esquerdo na GRADE visual.
  final int row;
  final int column;

  final int rowSpan;
  final int columnSpan;

  /// `vMerge=continue`: a célula existe na árvore mas é a continuação da
  /// mesclagem começada acima.
  final bool isMergeContinuation;

  int get rowEnd => row + rowSpan;
  int get columnEnd => column + columnSpan;

  bool covers(int gridRow, int gridColumn) =>
      gridRow >= row &&
      gridRow < rowEnd &&
      gridColumn >= column &&
      gridColumn < columnEnd;
}

/// A grade resolvida de uma tabela.
class OfficeTableMap {
  OfficeTableMap._(this.tablePos, this.table, this.cells, this.rows,
      this.columns);

  /// Posição do nó `table` no documento.
  final int tablePos;
  final PMNode table;

  /// Todas as células REAIS (as omitidas por rowspan não existem aqui).
  final List<OfficeTableCell> cells;

  final int rows;
  final int columns;

  /// Constrói o mapa da tabela em [tablePos].
  static OfficeTableMap of(PMNode doc, int tablePos) {
    final table = doc.nodeAt(tablePos);
    if (table == null || table.type.name != 'table') {
      throw ArgumentError.value(tablePos, 'tablePos', 'não é uma tabela');
    }
    final cells = <OfficeTableCell>[];
    // `occupied[linha][coluna]` marca slots já tomados por spans anteriores.
    final occupied = <int, Set<int>>{};
    var rowOffset = 0;
    var rowIndex = 0;

    for (var r = 0; r < table.childCount; r++) {
      final row = table.child(r);
      if (row.type.name != 'tableRow') {
        rowOffset += row.nodeSize;
        continue;
      }
      var cellOffset = 0;
      var column = 0;
      for (var c = 0; c < row.childCount; c++) {
        final cell = row.child(c);
        // Pula colunas que um rowspan de cima já ocupa.
        while (occupied[rowIndex]?.contains(column) ?? false) {
          column++;
        }
        final columnSpan = _spanOf(cell, 'colspan', 'gridSpan');
        final rowSpan = _rowSpanOf(cell);
        final continuation = _isMergeContinuation(cell);
        final pos = tablePos + 1 + rowOffset + 1 + cellOffset;
        cells.add(OfficeTableCell(
          node: cell,
          pos: pos,
          rowIndex: rowIndex,
          cellIndex: c,
          row: rowIndex,
          column: column,
          rowSpan: rowSpan,
          columnSpan: columnSpan,
          isMergeContinuation: continuation,
        ));
        for (var rr = rowIndex; rr < rowIndex + rowSpan; rr++) {
          final set = occupied.putIfAbsent(rr, () => <int>{});
          for (var cc = column; cc < column + columnSpan; cc++) {
            set.add(cc);
          }
        }
        column += columnSpan;
        cellOffset += cell.nodeSize;
      }
      rowOffset += row.nodeSize;
      rowIndex++;
    }

    var columns = 0;
    for (final cell in cells) {
      if (cell.columnEnd > columns) columns = cell.columnEnd;
    }
    return OfficeTableMap._(tablePos, table, cells, rowIndex, columns);
  }

  /// A tabela que contém [pos], ou null quando a posição está fora de uma.
  static OfficeTableMap? at(PMNode doc, int pos) {
    final resolved = doc.resolve(pos.clamp(0, doc.content.size));
    for (var depth = resolved.depth; depth > 0; depth--) {
      if (resolved.node(depth).type.name == 'table') {
        return OfficeTableMap.of(doc, resolved.before(depth));
      }
    }
    return null;
  }

  /// A célula que contém a posição [pos] do documento.
  OfficeTableCell? cellAt(int pos) {
    OfficeTableCell? best;
    for (final cell in cells) {
      final end = cell.pos + cell.node.nodeSize;
      if (pos >= cell.pos && pos <= end) {
        // A mais interna ganha (posições de fronteira pertencem à célula que
        // realmente as contém).
        if (best == null || cell.pos > best.pos) best = cell;
      }
    }
    return best;
  }

  /// A célula REAL que cobre o slot (linha, coluna) da grade.
  OfficeTableCell? cellCovering(int row, int column) {
    for (final cell in cells) {
      if (cell.covers(row, column)) return cell;
    }
    return null;
  }

  /// As células cujo retângulo intersecta o bloco [fromRow..toRow] ×
  /// [fromColumn..toColumn], em ordem de documento.
  List<OfficeTableCell> cellsIn({
    required int fromRow,
    required int toRow,
    required int fromColumn,
    required int toColumn,
  }) {
    final top = fromRow <= toRow ? fromRow : toRow;
    final bottom = fromRow <= toRow ? toRow : fromRow;
    final left = fromColumn <= toColumn ? fromColumn : toColumn;
    final right = fromColumn <= toColumn ? toColumn : fromColumn;
    final selected = <OfficeTableCell>[
      for (final cell in cells)
        if (cell.row <= bottom &&
            cell.rowEnd > top &&
            cell.column <= right &&
            cell.columnEnd > left)
          cell,
    ];
    selected.sort((a, b) => a.pos.compareTo(b.pos));
    return selected;
  }

  /// O retângulo NORMALIZADO que cobre as duas células — expandido até
  /// conter todo span que cruze a borda, como o Word faz ao arrastar sobre
  /// uma célula mesclada.
  ({int fromRow, int toRow, int fromColumn, int toColumn}) rectangleBetween(
    OfficeTableCell anchor,
    OfficeTableCell head,
  ) {
    var top = anchor.row < head.row ? anchor.row : head.row;
    var bottom =
        anchor.rowEnd > head.rowEnd ? anchor.rowEnd : head.rowEnd;
    var left = anchor.column < head.column ? anchor.column : head.column;
    var right = anchor.columnEnd > head.columnEnd
        ? anchor.columnEnd
        : head.columnEnd;

    // Expande enquanto alguma célula tocada ultrapassar a borda: uma
    // seleção que corta uma mesclagem ao meio não existe no Word.
    var changed = true;
    while (changed) {
      changed = false;
      for (final cell in cellsIn(
        fromRow: top,
        toRow: bottom - 1,
        fromColumn: left,
        toColumn: right - 1,
      )) {
        if (cell.row < top) {
          top = cell.row;
          changed = true;
        }
        if (cell.rowEnd > bottom) {
          bottom = cell.rowEnd;
          changed = true;
        }
        if (cell.column < left) {
          left = cell.column;
          changed = true;
        }
        if (cell.columnEnd > right) {
          right = cell.columnEnd;
          changed = true;
        }
      }
    }
    return (
      fromRow: top,
      toRow: bottom - 1,
      fromColumn: left,
      toColumn: right - 1
    );
  }

  static int _spanOf(PMNode cell, String cellKey, String wordKey) {
    for (final key in const ['cell', 'word']) {
      final attrs = cell.attrs[key];
      if (attrs is! Map) continue;
      final value = attrs[key == 'cell' ? cellKey : wordKey];
      final span = value is num ? value.toInt() : int.tryParse('$value');
      if (span != null && span > 0) return span;
    }
    return 1;
  }

  static int _rowSpanOf(PMNode cell) {
    final attrs = cell.attrs['cell'];
    if (attrs is Map) {
      final value = attrs['rowspan'];
      final span = value is num ? value.toInt() : int.tryParse('$value');
      if (span != null && span > 0) return span;
    }
    // `vMerge=restart` sem rowspan explícito: o alcance real só é conhecido
    // contando as continuações abaixo, o que o chamador faz pela grade. Aqui
    // vale 1 e as continuações ocupam os próprios slots.
    return 1;
  }

  static bool _isMergeContinuation(PMNode cell) {
    for (final key in const ['cell', 'word']) {
      final attrs = cell.attrs[key];
      if (attrs is! Map) continue;
      final value = attrs['vMerge'];
      if (value is String && value.toLowerCase() == 'continue') return true;
      if (value is Map &&
          '${value['value'] ?? value['val'] ?? ''}'.toLowerCase() ==
              'continue') {
        return true;
      }
    }
    return false;
  }
}
