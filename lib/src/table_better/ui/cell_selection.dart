import '../formats/table.dart';
import '../utils/utils.dart' as utils;

class CellSelectionClipboardData {
  const CellSelectionClipboardData({required this.html, required this.text});

  final String html;
  final String text;
}

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

  /// Serializes the selected cells in table order for clipboard copy.
  CellSelectionClipboardData copyData() {
    final rows = <int, List<TableCell>>{};
    for (final placement in _placements()) {
      if (_selected.contains(placement.cell)) {
        rows.putIfAbsent(placement.row, () => []).add(placement.cell);
      }
    }
    final htmlRows = StringBuffer();
    final textRows = <String>[];
    for (final row in rows.keys.toList()..sort()) {
      final cells = rows[row]!;
      htmlRows.write('<tr>');
      final textCells = <String>[];
      for (final cell in cells) {
        htmlRows.write(utils.getCopyTd(outerHtml(cell.element)));
        textCells.add(cell.element.textContent ?? '');
      }
      htmlRows.write('</tr>');
      textRows.add(textCells.join('\t'));
    }
    return CellSelectionClipboardData(
      html: '<table><tbody>$htmlRows</tbody></table>',
      text: textRows.join('\n'),
    );
  }

  /// Clears text from selected cells while retaining their table structure.
  void clearContents() {
    for (final cell in _selected) {
      for (final child in cell.children.toList()) {
        child.remove();
      }
      final block = table.scroll.create(
        TableCellBlock.kBlotName,
        cell.element.getAttribute('data-cell') ?? cellId(),
      ) as TableCellBlock;
      cell.appendChild(block);
    }
  }

  /// Returns clipboard data and clears the selected cells.
  CellSelectionClipboardData cutData() {
    final data = copyData();
    clearContents();
    return data;
  }

  /// Returns the logical top-left coordinate of [cell] in this table.
  ({int row, int column})? coordinateOf(TableCell cell) {
    for (final placement in _placements()) {
      if (identical(placement.cell, cell)) {
        return (row: placement.row, column: placement.column);
      }
    }
    return null;
  }

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
