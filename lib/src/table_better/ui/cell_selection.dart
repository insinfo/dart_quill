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

  /// Merges the selected rectangular cells into the top-left cell.
  ///
  /// Port of `TableMenus.mergeCells` (table-menus.ts:834), replacing the
  /// pixel-bound arithmetic with the logical grid from [_placements]: the
  /// resulting `colspan`/`rowspan` are the number of grid columns/rows covered
  /// by the selection, and rows emptied by the merge shrink the spans exactly
  /// like the TS `offset` bookkeeping.
  TableCell? mergeCells() {
    if (_selected.length < 2) return null;
    final placements = _placements();
    _CellPlacement? topLeft;
    var minRow = -1, minColumn = -1, maxRow = -1, maxColumn = -1;
    for (final placement in placements) {
      if (!_selected.contains(placement.cell)) continue;
      final rowEnd = placement.row + _span(placement.cell, 'rowspan') - 1;
      final colEnd = placement.column + _span(placement.cell, 'colspan') - 1;
      if (topLeft == null) {
        topLeft = placement;
        minRow = placement.row;
        minColumn = placement.column;
        maxRow = rowEnd;
        maxColumn = colEnd;
        continue;
      }
      if (placement.row < minRow) minRow = placement.row;
      if (placement.column < minColumn) minColumn = placement.column;
      if (rowEnd > maxRow) maxRow = rowEnd;
      if (colEnd > maxColumn) maxColumn = colEnd;
      if (placement.row < topLeft.row ||
          (placement.row == topLeft.row &&
              placement.column < topLeft.column)) {
        topLeft = placement;
      }
    }
    if (topLeft == null) return null;
    final target = topLeft.cell;
    final colspan = maxColumn - minColumn + 1;
    final rowspan = maxRow - minRow + 1;

    var removedRows = 0;
    for (final cell in _selected) {
      if (identical(cell, target)) continue;
      final row = cell.row();
      cell.moveChildren(target, null);
      cell.remove();
      if (row != null && row.children.isEmpty) {
        row.remove();
        removedRows++;
      }
    }
    // Rows deleted by the merge shorten every other cell of the target row
    // that spanned them (table-menus.ts:876-885).
    if (removedRows > 0) {
      final row = target.row();
      if (row != null) {
        for (final child in row.children) {
          if (child is! TableCell || identical(child, target)) continue;
          _writeSpan(child, 'rowspan', _span(child, 'rowspan') - removedRows);
        }
      }
    }
    _writeSpan(target, 'colspan', colspan);
    _writeSpan(target, 'rowspan', rowspan - removedRows);
    final (_, id) = utils.getCellFormats(target);
    if (id.isNotEmpty) target.setChildrenId(id);

    _reselect(target);
    return target;
  }

  /// Splits every merged cell in the selection back into 1x1 cells.
  ///
  /// Port of `TableMenus.splitCell` (table-menus.ts:924). The TS resolves the
  /// insertion reference in the rows below by comparing pixel edges
  /// (`getRefInfo`); here the logical grid gives it directly: the reference is
  /// the first cell of the row whose logical column lies past the merged
  /// region's left edge.
  void splitCells() {
    final cells = List<TableCell>.from(_selected);
    if (cells.isEmpty) return;
    TableCell? focus;
    for (final cell in cells) {
      final colspan = _span(cell, 'colspan');
      final rowspan = _span(cell, 'rowspan');
      if (colspan == 1 && rowspan == 1) continue;
      final coordinate = coordinateOf(cell);
      final rowBlot = cell.row();
      if (coordinate == null || rowBlot == null) continue;
      focus ??= cell;
      if (rowspan > 1) {
        var nextRow = rowBlot.next;
        for (var i = 1; i < rowspan; i++) {
          final row = nextRow is TableRow ? nextRow : null;
          final (:id, :ref) = _refInfo(row, coordinate.column);
          for (var j = 0; j < colspan; j++) {
            table.insertColumnCell(row, id, ref);
          }
          nextRow = row?.next;
        }
      }
      if (colspan > 1) {
        final id = cell.element.getAttribute('data-row') ?? tableId();
        final next = cell.next;
        final ref = next is TableCell ? next : null;
        for (var i = 1; i < colspan; i++) {
          table.insertColumnCell(rowBlot, id, ref);
        }
      }
      cell.element.removeAttribute('colspan');
      cell.element.removeAttribute('rowspan');
      final width = double.tryParse(cell.element.getAttribute('width') ?? '');
      if (width != null) {
        cell.element.setAttribute('width', '${width ~/ colspan}');
      }
    }
    if (focus == null) return;
    _reselect(focus);
  }

  /// Converts the selected rows — plus every body row above them, keeping the
  /// header block contiguous — into `<th>` rows inside `<thead>`.
  ///
  /// Port of `TableMenus.convertToHeaderRow` (table-menus.ts:329). The TS
  /// clones each `<td>` and `replaceWith`s it as a `table-th`; here the cell
  /// children are moved into a freshly created [TableTh] with the same
  /// formats, which is equivalent and avoids re-hydrating cloned DOM.
  TableTh? convertToHeaderRow() {
    final selectedRows =
        _selectedRows().where((row) => row is! TableThRow).toList();
    if (selectedRows.isEmpty) return null;
    final rows = <TableRow>[];
    Object? cursor = selectedRows.last;
    while (cursor is TableRow) {
      rows.insert(0, cursor);
      cursor = cursor.prev;
    }
    var thead = table.thead();
    if (thead == null) {
      thead = table.scroll.create(TableThead.kBlotName) as TableThead;
      table.insertBefore(thead, table.tbody());
    }
    TableTh? first;
    for (final row in rows) {
      final thRow = table.scroll.create(TableThRow.kBlotName) as TableThRow;
      for (final child in row.children.toList()) {
        if (child is! TableCell) continue;
        final th = table.scroll.create(
          TableTh.kBlotName,
          TableCell.formatsFromNode(child.element),
        ) as TableTh;
        child.moveChildren(th, null);
        thRow.insertBefore(th, null);
        first ??= th;
      }
      thead.insertBefore(thRow, null);
      row.remove();
    }
    final body = table.tbody();
    if (body != null && body.children.isEmpty) body.remove();
    _reselect(first);
    return first;
  }

  /// Converts the selected header rows — plus every header row below them —
  /// back into body rows, inserted above the current `<tbody>` content.
  ///
  /// Port of `TableMenus.convertToRow` (table-menus.ts:297).
  TableCell? convertToRow() {
    final selectedRows = _selectedRows().whereType<TableThRow>().toList();
    if (selectedRows.isEmpty) return null;
    final rows = <TableRow>[];
    Object? cursor = selectedRows.first;
    while (cursor is TableRow) {
      rows.add(cursor);
      cursor = cursor.next;
    }
    var body = table.tbody();
    final created = body == null;
    body ??= table.scroll.create(TableBody.kBlotName) as TableBody;
    final ref = body.children.isEmpty ? null : body.children.first;
    TableCell? first;
    for (final row in rows) {
      final tdRow = table.scroll.create(TableRow.kBlotName) as TableRow;
      for (final child in row.children.toList()) {
        if (child is! TableCell) continue;
        final td = table.scroll.create(
          TableCell.kBlotName,
          TableCell.formatsFromNode(child.element),
        ) as TableCell;
        child.moveChildren(td, null);
        tdRow.insertBefore(td, null);
        first ??= td;
      }
      body.insertBefore(tdRow, ref);
      row.remove();
    }
    if (created) table.insertBefore(body, null);
    final thead = table.thead();
    if (thead != null && thead.children.isEmpty) thead.remove();
    _reselect(first);
    return first;
  }

  /// Serializes the whole table for clipboard copy.
  ///
  /// Payload of `TableMenus.copyTable` (table-menus.ts:359); the caller owns
  /// the ClipboardItem write and any selection move.
  CellSelectionClipboardData copyTableData() {
    final html = '<p><br></p>${table.getCopyTable()}';
    final textRows = <String>[];
    for (final row in table.descendants<TableRow>()) {
      final cells = row.children
          .whereType<TableCell>()
          .map((cell) => cell.element.textContent ?? '')
          .toList();
      if (cells.isNotEmpty) textRows.add(cells.join('\t'));
    }
    return CellSelectionClipboardData(html: html, text: textRows.join('\n'));
  }

  /// Rows (in table order) that contain at least one selected cell.
  List<TableRow> _selectedRows() {
    final rows = <TableRow>[];
    for (final row in table.descendants<TableRow>()) {
      final hasSelected = row.children
          .any((child) => child is TableCell && _selected.contains(child));
      if (hasSelected) rows.add(row);
    }
    return rows;
  }

  void _reselect(TableCell? cell) {
    clear();
    if (cell == null) return;
    final coordinate = coordinateOf(cell);
    if (coordinate == null) return;
    select(
      startRow: coordinate.row,
      startColumn: coordinate.column,
      endRow: coordinate.row,
      endColumn: coordinate.column,
    );
  }

  /// Logical counterpart of `TableMenus.getRefInfo` (table-menus.ts:670):
  /// the row id plus the cell before which the split cells are inserted.
  ({String id, TableCell? ref}) _refInfo(TableRow? row, int column) {
    if (row == null) return (id: tableId(), ref: null);
    final head = row.children.isEmpty ? null : row.children.first;
    final id = head is TableCell
        ? head.element.getAttribute('data-row') ?? tableId()
        : tableId();
    for (final placement in _placements()) {
      if (!identical(placement.cell.row(), row)) continue;
      if (placement.column > column) return (id: id, ref: placement.cell);
    }
    return (id: id, ref: null);
  }

  void _writeSpan(TableCell cell, String name, int value) {
    if (value > 1) {
      cell.element.setAttribute(name, '$value');
    } else {
      cell.element.removeAttribute(name);
    }
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
