import '../formats/table.dart';

/// Inclusive rectangular range in the logical table grid.
class CellSelectionRange {
  const CellSelectionRange({
    required int startRow,
    required int startColumn,
    required int endRow,
    required int endColumn,
  })  : startRow = startRow < endRow ? startRow : endRow,
        startColumn = startColumn < endColumn ? startColumn : endColumn,
        endRow = startRow < endRow ? endRow : startRow,
        endColumn = startColumn < endColumn ? endColumn : startColumn;

  final int startRow;
  final int startColumn;
  final int endRow;
  final int endColumn;

  bool contains(int row, int column) =>
      row >= startRow &&
      row <= endRow &&
      column >= startColumn &&
      column <= endColumn;

  @override
  String toString() => '$startRow:$startColumn-$endRow:$endColumn';
}

class _CellPlacement {
  const _CellPlacement(this.cell, this.row, this.column);

  final TableCell cell;
  final int row;
  final int column;
}

/// Logical multi-cell selection used by table-better's UI and clipboard.
///
/// The model is independent of browser geometry. The visual layer can feed it
/// the start/end cell coordinates after hit testing, while rowspan/colspan are
/// expanded consistently for merge, formatting and copy operations.
class CellSelection {
  CellSelection(this.table);

  final TableContainer table;
  CellSelectionRange? range;
  List<TableCell> _selected = const [];

  List<TableCell> get selectedCells => List.unmodifiable(_selected);

  bool get isActive => _selected.isNotEmpty;

  void clear() {
    for (final cell in _selected) {
      cell.element.classes.remove('ql-cell-selected');
    }
    _selected = const [];
    range = null;
  }

  List<TableCell> select({
    required int startRow,
    required int startColumn,
    required int endRow,
    required int endColumn,
  }) {
    clear();
    final nextRange = CellSelectionRange(
      startRow: startRow,
      startColumn: startColumn,
      endRow: endRow,
      endColumn: endColumn,
    );
    final placements = _placements();
    _selected = placements
        .where((placement) => _intersects(placement, nextRange))
        .map((placement) => placement.cell)
        .toList(growable: false);
    range = nextRange;
    for (final cell in _selected) {
      cell.element.classes.add('ql-cell-selected');
    }
    return selectedCells;
  }

  bool _intersects(_CellPlacement placement, CellSelectionRange selected) {
    final rowSpan = _span(placement.cell, 'rowspan');
    final colSpan = _span(placement.cell, 'colspan');
    final rowEnd = placement.row + rowSpan - 1;
    final colEnd = placement.column + colSpan - 1;
    return placement.row <= selected.endRow &&
        rowEnd >= selected.startRow &&
        placement.column <= selected.endColumn &&
        colEnd >= selected.startColumn;
  }

  List<_CellPlacement> _placements() {
    final placements = <_CellPlacement>[];
    final occupied = <int, int>{};
    final rows = table.descendants<TableRow>().toList();
    for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) {
      var column = 0;
      for (final child in rows[rowIndex].children) {
        if (child is! TableCell) continue;
        while ((occupied[column] ?? -1) >= rowIndex) {
          column++;
        }
        final rowSpan = _span(child, 'rowspan');
        final colSpan = _span(child, 'colspan');
        placements.add(_CellPlacement(child, rowIndex, column));
        for (var offset = 0; offset < colSpan; offset++) {
          if (rowSpan > 1) occupied[column + offset] = rowIndex + rowSpan - 1;
        }
        column += colSpan;
      }
    }
    return placements;
  }

  int _span(TableCell cell, String name) {
    final value = int.tryParse(cell.element.getAttribute(name) ?? '') ?? 1;
    return value < 1 ? 1 : value;
  }
}
