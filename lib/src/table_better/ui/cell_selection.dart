import '../../platform/dom.dart';
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
  CellSelection([TableContainer? table]) : _table = table;

  /// The table the selection currently lives in.
  ///
  /// Upstream's `CellSelection` has no such field: it serves the whole editor
  /// and reads geometry off `selectedTds` with `getBoundingClientRect`. This
  /// port resolves the same information from a logical grid, which needs to
  /// know the table — so a single instance per editor re-aims this pointer
  /// through [rebind] as the user moves between tables. The invariant upstream
  /// gets by construction (only one selection is ever live) is preserved.
  TableContainer? _table;

  TableContainer get table => _table!;

  bool get isBound => _table != null;

  /// Points the grid at [next], dropping whatever was selected in the table
  /// being left behind.
  void rebind(TableContainer next) {
    if (identical(_table, next)) return;
    for (final cell in _selected) {
      cell.element.classes.remove('ql-cell-focused');
    }
    clear();
    _table = next;
  }

  CellSelectionRange? range;
  List<TableCell> _selected = const [];

  List<TableCell> get selectedCells => List.unmodifiable(_selected);

  bool get isActive => _selected.isNotEmpty;

  // --- TS-shaped DOM surface (cell-selection.ts) -------------------------
  //
  // `table-menus.ts` and `toolbar-table.ts` are written against elements
  // (`selectedTds`, `startTd`, `endTd`); the logical grid above stays the
  // source of truth and these are projections of it.

  /// TS `selectedTds`.
  List<DomElement> get selectedTds =>
      _selected.map((cell) => cell.element).toList(growable: false);

  /// TS `startTd` — the selection's top-left cell element.
  DomElement? get startTd => _corner(first: true)?.cell.element;

  /// TS `endTd` — the selection's bottom-right cell element.
  DomElement? get endTd => _corner(first: false)?.cell.element;

  /// TS `setSelected(target)` — collapses the selection onto one cell.
  ///
  /// The TS variant also moves the text caret into the cell; that belongs to
  /// the caller, which owns the Quill instance.
  TableCell? setSelected(DomElement target) {
    final cell = _cellForElement(target);
    _reselect(cell);
    if (cell != null) {
      // TS setSelected (cell-selection.ts:709-721): the selection list holds
      // the anchor, but only ql-cell-focused is painted on it — never
      // ql-cell-selected, which the grid's select() applies for ranges.
      cell.element.classes.remove('ql-cell-selected');
      cell.element.classes.add('ql-cell-focused');
    }
    return cell;
  }

  /// TS `setSelectedTds(selectedTds)` — selects an explicit element list.
  void setSelectedTds(List<DomElement> tds) {
    clear();
    final cells = <TableCell>[];
    for (final td in tds) {
      final cell = _cellForElement(td);
      if (cell != null) cells.add(cell);
    }
    _selected = List.unmodifiable(cells);
    for (final cell in _selected) {
      cell.element.classes.add('ql-cell-selected');
    }
    range = _rangeOf(_selected);
  }

  /// TS `hasTdTh(selectedTds)` (cell-selection.ts:385-389).
  ({bool hasTd, bool hasTh}) hasTdTh([List<DomElement>? tds]) {
    final targets = tds ?? selectedTds;
    return (
      hasTd: targets.any((td) => td.tagName.toUpperCase() == 'TD'),
      hasTh: targets.any((td) => td.tagName.toUpperCase() == 'TH'),
    );
  }

  /// TS `selectColumn()` payload (table-menus.ts:891) — every cell whose
  /// logical columns intersect the current selection.
  List<TableCell> selectColumn() {
    final current = range;
    if (current == null) return const [];
    final rows = table.descendants<TableRow>().length;
    return select(
      startRow: 0,
      startColumn: current.startColumn,
      endRow: rows == 0 ? 0 : rows - 1,
      endColumn: current.endColumn,
    );
  }

  /// TS `selectRow()` payload (table-menus.ts:899).
  List<TableCell> selectRow() {
    final current = range;
    if (current == null) return const [];
    var columns = 0;
    for (final placement in _placements()) {
      final end = placement.column + _span(placement.cell, 'colspan');
      if (end > columns) columns = end;
    }
    return select(
      startRow: current.startRow,
      startColumn: 0,
      endRow: current.endRow,
      endColumn: columns == 0 ? 0 : columns - 1,
    );
  }

  /// TS `updateSelected(type)` (cell-selection.ts:773) — after a row/column
  /// deletion, park the selection on the neighbour that survived.
  ///
  /// Returns false when nothing is left to select, which the caller answers
  /// with `hideTools()`, exactly as the TS does.
  bool updateSelected(String type) {
    final current = range;
    if (current == null) return false;
    final placements = _placements();
    if (placements.isEmpty) return false;
    var maxRow = 0, maxColumn = 0;
    for (final placement in placements) {
      final rowEnd = placement.row + _span(placement.cell, 'rowspan') - 1;
      final colEnd = placement.column + _span(placement.cell, 'colspan') - 1;
      if (rowEnd > maxRow) maxRow = rowEnd;
      if (colEnd > maxColumn) maxColumn = colEnd;
    }
    int row;
    int column;
    if (type == 'column') {
      row = current.startRow.clamp(0, maxRow).toInt();
      column = current.endColumn + 1;
      if (column > maxColumn) column = current.startColumn - 1;
      if (column < 0) return false;
    } else {
      column = current.startColumn.clamp(0, maxColumn).toInt();
      row = current.endRow + 1;
      if (row > maxRow) row = current.startRow - 1;
      if (row < 0) return false;
    }
    final selected = select(
        startRow: row, startColumn: column, endRow: row, endColumn: column);
    return selected.isNotEmpty;
  }

  TableCell? _cellForElement(DomElement target) {
    for (final cell in table.descendants<TableCell>()) {
      if (cell.element == target) return cell;
    }
    return null;
  }

  _CellPlacement? _corner({required bool first}) {
    _CellPlacement? best;
    for (final placement in _placements()) {
      if (!_selected.contains(placement.cell)) continue;
      if (best == null) {
        best = placement;
        continue;
      }
      final isEarlier = placement.row < best.row ||
          (placement.row == best.row && placement.column < best.column);
      if (first ? isEarlier : !isEarlier) best = placement;
    }
    return best;
  }

  CellSelectionRange? _rangeOf(List<TableCell> cells) {
    if (cells.isEmpty) return null;
    int? minRow, minColumn, maxRow, maxColumn;
    for (final placement in _placements()) {
      if (!cells.contains(placement.cell)) continue;
      final rowEnd = placement.row + _span(placement.cell, 'rowspan') - 1;
      final colEnd = placement.column + _span(placement.cell, 'colspan') - 1;
      minRow =
          minRow == null || placement.row < minRow ? placement.row : minRow;
      minColumn = minColumn == null || placement.column < minColumn
          ? placement.column
          : minColumn;
      maxRow = maxRow == null || rowEnd > maxRow ? rowEnd : maxRow;
      maxColumn = maxColumn == null || colEnd > maxColumn ? colEnd : maxColumn;
    }
    if (minRow == null) return null;
    return CellSelectionRange(
      startRow: minRow,
      startColumn: minColumn!,
      endRow: maxRow!,
      endColumn: maxColumn!,
    );
  }

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
          (placement.row == topLeft.row && placement.column < topLeft.column)) {
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
