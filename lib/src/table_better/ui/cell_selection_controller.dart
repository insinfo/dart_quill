/// Interaction layer of `quill-table-better/src/ui/cell-selection.ts` (v1.2.3).
///
/// [CellSelection] holds the logical model; this class turns pointer and
/// keyboard events into model transitions and drives the surrounding UI
/// (toolbar disabling, header-row switch, menu availability).
///
/// Deviation, systematic: the TS resolves the dragged rectangle by comparing
/// `getBoundingClientRect` edges. Here the anchor and focus cells are mapped to
/// grid coordinates and the rectangle comes from [CellSelection.select], which
/// yields the same set of cells and also works without layout.
library;

import '../../core/emitter.dart';
import '../../core/quill.dart';
import '../../core/selection.dart';
import '../../platform/dom.dart';
import '../formats/table.dart';
import '../utils/utils.dart' as utils;
import 'cell_selection.dart';

/// TS `WHITE_LIST` — toolbar formats that stay enabled while cells are
/// selected.
const List<String> kToolbarWhiteList = [
  'bold',
  'italic',
  'underline',
  'strike',
  'size',
  'color',
  'background',
  'font',
  'list',
  'header',
  'align',
  'link',
  'image',
];

/// TS `SINGLE_WHITE_LIST` — formats that only apply to a single cell.
const List<String> kToolbarSingleWhiteList = ['link', 'image'];

/// Hooks the controller needs from the owning module, kept as callbacks so the
/// controller does not depend on `TableBetter` (which depends on it).
class CellSelectionHost {
  const CellSelectionHost({
    required this.hideTools,
    required this.showTools,
    this.toggleHeaderRowSwitch,
    this.disableMenu,
    this.updateMenus,
    this.deleteColumn,
    this.deleteRow,
    this.toolbarContainer,
    this.toolbarButtons,
  });

  final void Function() hideTools;
  final void Function(bool force) showTools;
  final void Function(String value)? toggleHeaderRowSwitch;
  final void Function(String category, bool disabled)? disableMenu;
  final void Function()? updateMenus;

  /// TS `tableMenus.deleteColumn(true)` / `deleteRow(true)`.
  final void Function(bool isKeyboard)? deleteColumn;
  final void Function(bool isKeyboard)? deleteRow;

  /// Toolbar container scanned by `initWhiteList`.
  final DomElement? toolbarContainer;

  /// TS `options.toolbarButtons` — `{whiteList, singleWhiteList}`.
  final Map<String, List<String>>? toolbarButtons;
}

/// TS `class CellSelection`, interaction half.
class CellSelectionController {
  CellSelectionController({
    required this.quill,
    required this.root,
    CellSelectionHost? host,
  })  : host = host ??
            const CellSelectionHost(hideTools: _noop, showTools: _noopForce),
        selection = CellSelection() {
    _clickListener = handleClick;
    _mousedownListener = handleMousedown;
    _keyupListener = _onKeyup;
    root.addEventListener('click', _clickListener);
    root.addEventListener('mousedown', _mousedownListener);
    root.addEventListener('keyup', _keyupListener);
    initWhiteList();
  }

  static void _noop() {}
  static void _noopForce(bool _) {}

  final Quill quill;
  final DomElement root;

  /// The editor's single live selection, as upstream has (`this.cellSelection`
  /// on the module). Its grid is re-aimed at whatever table the user touches.
  final CellSelection selection;

  /// The table the live selection is bound to. Only valid while a selection
  /// exists — every caller below is reached through one.
  TableContainer get table => selection.table;
  final CellSelectionHost host;

  late final DomEventListener _clickListener;
  late final DomEventListener _mousedownListener;
  late final DomEventListener _keyupListener;
  DomEventListener? _mousemoveListener;
  DomEventListener? _mouseupListener;

  /// TS `disabledList` — toolbar inputs greyed out while cells are selected.
  final List<DomElement> disabledList = [];

  /// TS `singleList` — inputs greyed out for multi-cell selections only.
  final List<DomElement> singleList = [];

  TableCell? _anchor;

  List<DomElement> get selectedTds => selection.selectedTds;

  void dispose() {
    root.removeEventListener('click', _clickListener);
    root.removeEventListener('mousedown', _mousedownListener);
    root.removeEventListener('keyup', _keyupListener);
    _detachDragListeners();
    clear();
  }

  /// TS `clearSelected()`.
  void clear() {
    for (final td in selection.selectedTds) {
      td.classes.remove('ql-cell-focused');
      td.classes.remove('ql-cell-selected');
    }
    selection.clear();
    _anchor = null;
  }

  // --- toolbar white list -------------------------------------------------

  /// TS `getButtonsWhiteList()`.
  (List<String> whiteList, List<String> singleWhiteList) getButtonsWhiteList() {
    final buttons = host.toolbarButtons ?? const <String, List<String>>{};
    return (
      buttons['whiteList'] ?? kToolbarWhiteList,
      buttons['singleWhiteList'] ?? kToolbarSingleWhiteList,
    );
  }

  /// TS `getCorrectDisabled(input, format)` — a `<select>` also disables the
  /// `.ql-picker` span the theme built next to it.
  List<DomElement> getCorrectDisabled(DomElement input, String format) {
    if (input.tagName.toUpperCase() != 'SELECT') return [input];
    DomNode? node = input.parentNode;
    DomElement? formats;
    while (node != null) {
      if (node is DomElement && node.classes.contains('ql-formats')) {
        formats = node;
        break;
      }
      node = node.parentNode;
    }
    if (formats == null) return [input];
    final pickers = <DomElement>[];
    for (final candidate in formats.querySelectorAll('span')) {
      if (candidate.classes.contains(format) &&
          candidate.classes.contains('ql-picker')) {
        pickers.add(candidate);
      }
    }
    return [...pickers, input];
  }

  /// TS `attach(input)`.
  void attach(DomElement input) {
    String? format;
    for (final className in input.classes.values) {
      if (className.startsWith('ql-')) {
        format = className;
        break;
      }
    }
    if (format == null) return;
    final (whiteList, singleWhiteList) = getButtonsWhiteList();
    final correctDisabled = getCorrectDisabled(input, format);
    final name = format.substring('ql-'.length);
    if (!whiteList.contains(name)) disabledList.addAll(correctDisabled);
    if (singleWhiteList.contains(name)) singleList.addAll(correctDisabled);
  }

  /// TS `initWhiteList()`.
  void initWhiteList() {
    final container = host.toolbarContainer;
    if (container == null) return;
    for (final input in [
      ...container.querySelectorAll('button'),
      ...container.querySelectorAll('select'),
    ]) {
      attach(input);
    }
  }

  /// TS `setDisabled(disabled)`.
  void setDisabled(bool disabled) {
    for (final input in disabledList) {
      if (disabled) {
        input.classes.add('ql-table-button-disabled');
      } else {
        input.classes.remove('ql-table-button-disabled');
      }
    }
    setSingleDisabled();
  }

  /// TS `setSingleDisabled()`.
  void setSingleDisabled() {
    final multiple = selection.selectedTds.length > 1;
    for (final input in singleList) {
      if (multiple) {
        input.classes.add('ql-table-button-disabled');
      } else {
        input.classes.remove('ql-table-button-disabled');
      }
    }
  }

  /// TS `setHeaderRowSwitch()`.
  void setHeaderRowSwitch() {
    final (:hasTd, :hasTh) = selection.hasTdTh();
    host.toggleHeaderRowSwitch?.call(hasTh && !hasTd ? 'true' : 'false');
  }

  /// TS `setMenuDisable(category)` — merging a mix of `<td>` and `<th>` is
  /// disallowed.
  void setMenuDisable(String category) {
    final (:hasTd, :hasTh) = selection.hasTdTh();
    host.disableMenu?.call(category, hasTd && hasTh);
  }

  // --- selection ----------------------------------------------------------

  /// TS `setSelected(target, force)`.
  void setSelected(DomElement target, [bool force = true]) {
    clear();
    final cell = selection.setSelected(target);
    _anchor = cell;
    setHeaderRowSwitch();
    setMenuDisable('merge');
    setSingleDisabled();
    if (cell == null || !force) return;
    quill.setSelection(
      Range(quill.scroll.offset(cell) + cell.length() - 1, 0),
      source: EmitterSource.USER,
    );
  }

  /// TS `setSelectedTds(selectedTds)`.
  void setSelectedTds(List<DomElement> tds) {
    clear();
    selection.setSelectedTds(tds);
    setSingleDisabled();
    setHeaderRowSwitch();
    setMenuDisable('merge');
  }

  /// Selects the rectangle spanned by two cells (TS drags between them).
  void selectRange(TableCell anchor, TableCell focus) {
    final start = selection.coordinateOf(anchor);
    final end = selection.coordinateOf(focus);
    if (start == null || end == null) return;
    clear();
    _anchor = anchor;
    selection.select(
      startRow: start.row,
      startColumn: start.column,
      endRow: end.row,
      endColumn: end.column,
    );
  }

  // --- pointer ------------------------------------------------------------

  /// TS `handleMousedown(e)` plus the mousemove/mouseup pair it installs.
  void handleMousedown(DomEvent event) {
    final startTd = _cellFromTarget(event.target);
    if (startTd == null) return;
    clear();
    _anchor = startTd;
    selection.setSelected(startTd.element);
    setHeaderRowSwitch();
    setMenuDisable('merge');

    _detachDragListeners();
    _mousemoveListener = (moveEvent) {
      final endTd = _cellFromTarget(moveEvent.target);
      if (endTd == null || identical(endTd, startTd)) return;
      selectRange(startTd, endTd);
      // TS blurs so the browser's own text selection does not fight the grid.
      quill.blur();
    };
    _mouseupListener = (_) {
      setSingleDisabled();
      setHeaderRowSwitch();
      setMenuDisable('merge');
      _detachDragListeners();
    };
    root.addEventListener('mousemove', _mousemoveListener!);
    root.addEventListener('mouseup', _mouseupListener!);
  }

  /// TS `handleClick(e)` — a triple click selects the whole cell, and the
  /// selection is shortened by one so deleting removes the content, not the
  /// cell itself.
  void handleClick(DomEvent event) {
    final detail = event is DomMouseEvent ? event.detail : 1;
    if (detail < 3 || selection.selectedTds.isEmpty) {
      _handleShiftClick(event);
      return;
    }
    final range = quill.getSelection(focus: true);
    if (range == null) return;
    quill.setSelection(
      Range(range.index, range.length > 0 ? range.length - 1 : 0),
      source: EmitterSource.SILENT,
    );
    quill.scrollSelectionIntoView();
  }

  /// Shift-click extension. Upstream reaches the same state by dragging; this
  /// keeps the keyboard-friendly path the previous port already offered.
  void _handleShiftClick(DomEvent event) {
    final cell = _cellFromTarget(event.target);
    if (cell == null) return;
    final shift = event is DomMouseEvent && event.shiftKey;
    final anchor = _anchor;
    if (!shift || anchor == null) {
      clear();
      _anchor = cell;
      selection.setSelected(cell.element);
      setHeaderRowSwitch();
      setMenuDisable('merge');
      return;
    }
    event.preventDefault();
    selectRange(anchor, cell);
    setSingleDisabled();
    setHeaderRowSwitch();
    setMenuDisable('merge');
  }

  // --- keyboard -----------------------------------------------------------

  void _onKeyup(DomEvent event) {
    if (event is! DomKeyboardEvent) return;
    handleDeleteKeyup(event);
    handleKeyup(event);
  }

  /// TS `handleKeyup(e)`.
  void handleKeyup(DomKeyboardEvent event) {
    switch (event.key) {
      case 'ArrowLeft':
      case 'ArrowRight':
        makeTableArrowLevelHandler(event.key);
        break;
      case 'ArrowUp':
      case 'ArrowDown':
        makeTableArrowVerticalHandler(event.key);
        break;
      default:
        break;
    }
  }

  /// TS `handleDeleteKeyup(e)` — Ctrl+Backspace/Delete removes the whole
  /// row/column, a bare Backspace/Delete only the cells' content.
  void handleDeleteKeyup(DomKeyboardEvent event) {
    if (selection.selectedTds.length < 2) return;
    if (event.key != 'Backspace' && event.key != 'Delete') return;
    if (event.ctrlKey || event.metaKey) {
      host.deleteColumn?.call(true);
      host.deleteRow?.call(true);
    } else {
      removeSelectedTdsContent();
    }
  }

  /// TS `makeTableArrowLevelHandler(key)`.
  void makeTableArrowLevelHandler(String key) {
    final range = quill.getSelection();
    if (range == null) return;
    final cell = utils.getCorrectCellBlot(quill.getLine(range.index).key);
    if (cell == null) {
      host.hideTools();
      return;
    }
    final td = key == 'ArrowLeft' ? selection.startTd : selection.endTd;
    if (td == null || !identical(td, cell.element)) {
      setSelected(cell.element, false);
      host.showTools(false);
    }
  }

  /// TS `makeTableArrowVerticalHandler(key)`.
  ///
  /// The TS matches the target cell by comparing pixel edges across rows; the
  /// logical grid gives the column directly.
  void makeTableArrowVerticalHandler(String key) {
    final up = key == 'ArrowUp';
    final range = quill.getSelection();
    if (range == null) return;
    final entry = quill.getLine(range.index);
    final block = entry.key;
    final offset = entry.value;
    if (block == null) return;

    final sibling = up ? block.prev : block.next;
    if (sibling != null && selection.selectedTds.isNotEmpty) {
      final limit = sibling.length() - 1;
      final index =
          quill.scroll.offset(sibling) + (offset < limit ? offset : limit);
      quill.setSelection(Range(index, 0), source: EmitterSource.USER);
      return;
    }

    final cell = utils.getCorrectCellBlot(block);
    if (cell == null) return;
    if (selection.selectedTds.isEmpty) {
      tableArrowSelection(up, cell);
      host.showTools(false);
      return;
    }

    final coordinate = selection.coordinateOf(cell);
    if (coordinate == null) {
      exitTableFocus(cell, up);
      return;
    }
    final target = _cellInDirection(coordinate.row, coordinate.column, up);
    if (target == null) {
      exitTableFocus(cell, up);
    } else {
      tableArrowSelection(up, target);
    }
  }

  /// TS `tableArrowSelection(up, cellBlot)`.
  void tableArrowSelection(bool up, TableCell cell) {
    if (cell.children.isEmpty) return;
    final child = up ? cell.children.last : cell.children.first;
    final offset = up ? child.length() - 1 : 0;
    setSelected(cell.element, false);
    quill.setSelection(
      Range(quill.scroll.offset(child) + offset, 0),
      source: EmitterSource.USER,
    );
  }

  /// TS `exitTableFocus(block, up)`.
  void exitTableFocus(TableCell cell, bool up) {
    final container = cell.table();
    if (container == null) return;
    final offset = up ? -1 : container.length();
    final index = quill.scroll.offset(container) + offset;
    host.hideTools();
    quill.setSelection(
      Range(index.clamp(0, quill.scroll.length()).toInt(), 0),
      source: EmitterSource.USER,
    );
  }

  // --- content ------------------------------------------------------------

  /// TS `removeSelectedTdContent(td)` — replaces a cell's content with one
  /// empty block that keeps the cell id.
  void removeSelectedTdContent(TableCell cell) {
    if (cell.children.isEmpty) return;
    final head = cell.children.first;
    final id = head is TableCellBlock
        ? (head.formats()[TableCellBlock.kBlotName] as String?) ?? cellId()
        : cellId();
    final block = quill.scroll.create(TableCellBlock.kBlotName, id);
    cell.insertBefore(block, head);
    for (final child in cell.children.toList()) {
      if (identical(child, block)) continue;
      child.remove();
    }
  }

  /// TS `removeSelectedTdsContent()`.
  void removeSelectedTdsContent() {
    if (selection.selectedCells.length < 2) return;
    for (final cell in selection.selectedCells) {
      removeSelectedTdContent(cell);
    }
    host.updateMenus?.call();
  }

  /// TS `onCaptureCopy(e, isCut)` payload — null when fewer than two cells are
  /// selected, which is when the TS lets the native copy through.
  CellSelectionClipboardData? copyData({bool isCut = false}) {
    if (selection.selectedTds.length < 2) return null;
    final data = selection.copyData();
    if (isCut) removeSelectedTdsContent();
    return data;
  }

  /// TS `onCapturePaste(e)` — pastes a copied grid into the current selection,
  /// growing the table when the payload does not fit.
  ///
  /// Deviation: the TS locates the destination cells by intersecting pixel
  /// bounds (`getPasteComputeBounds` + `getComputeSelectedTds`). The logical
  /// grid gives the same rectangle directly: it starts at the anchor cell and
  /// spans the pasted rows and columns.
  ///
  /// Returns false when there is nothing to paste, so the caller can let the
  /// native paste through.
  bool pasteGrid(String html) {
    if (selection.selectedTds.isEmpty) return false;
    final copyRows = _parseCopyRows(html);
    if (copyRows.isEmpty) return false;
    final anchor = _anchor ?? selection.selectedCells.firstOrNull;
    if (anchor == null) return false;
    final origin = selection.coordinateOf(anchor);
    if (origin == null) return false;

    quill.history.cutoff();

    // TS `getCopyColumns(container)` — the widest row decides the width.
    final copyColumns = copyRows
        .map((row) => row.fold<int>(0, (sum, td) => sum + _colspanOf(td)))
        .fold<int>(0, (widest, width) => width > widest ? width : widest);

    _growToFit(origin, copyRows.length, copyColumns);

    final pasted = <DomElement>[];
    for (var rowOffset = 0; rowOffset < copyRows.length; rowOffset++) {
      final copyCells = copyRows[rowOffset];
      var column = origin.column;
      for (final copyTd in copyCells) {
        final target = _cellAtCoordinate(origin.row + rowOffset, column);
        if (target != null) {
          final replacement = pasteSelectedTd(target, copyTd);
          if (replacement != null) pasted.add(replacement.element);
        }
        column += _colspanOf(copyTd);
      }
    }

    if (pasted.isNotEmpty) setSelectedTds(pasted);
    host.updateMenus?.call();
    quill.scrollSelectionIntoView();
    return true;
  }

  /// TS `pasteSelectedTd(selectedTd, copyTd)` — the destination cell adopts the
  /// copied cell's formats (keeping its own `data-row`) and content.
  TableCell? pasteSelectedTd(TableCell target, DomElement copyTd) {
    final id = target.element.getAttribute('data-row');
    final formats = <String, String>{
      ...TableCell.formatsFromNode(copyTd),
      if (id != null) 'data-row': id,
    };
    final replacement =
        replaceBlotWith(target, target.blotName, formats) as TableCell;

    // Replace the cell's content with the copied one, converted through the
    // clipboard so inline formats survive.
    for (final child in replacement.children.toList()) {
      child.remove();
    }
    final block = quill.scroll.create(
      replacement.blotName == TableTh.kBlotName
          ? TableThBlock.kBlotName
          : TableCellBlock.kBlotName,
      cellId(),
    ) as TableCellBlock;
    replacement.appendChild(block);

    final text = (copyTd.textContent ?? '').trim();
    if (text.isNotEmpty) {
      final index = quill.scroll.offset(block);
      quill.insertText(index, text, source: EmitterSource.USER);
    }
    return replacement;
  }

  /// Inserts the rows and columns the pasted grid needs beyond the table's
  /// current size (TS `getPasteInfo` + `insertColumnCell` + `insertRow`).
  void _growToFit(({int row, int column}) origin, int rows, int columns) {
    final existingRows = table.descendants<TableRow>().length;
    final missingRows = origin.row + rows - existingRows;
    for (var i = 0; i < missingRows; i++) {
      table.insertRow(table.descendants<TableRow>().length, 1);
    }

    final body = table.tbody();
    if (body == null) return;
    for (final row in body.children.whereType<TableRow>()) {
      var width = 0;
      for (final cell in row.children.whereType<TableCell>()) {
        width += _colspanOf(cell.element);
      }
      final missing = origin.column + columns - width;
      if (missing <= 0) continue;
      final last = row.children.whereType<TableCell>().lastOrNull;
      final id = last?.element.getAttribute('data-row') ?? tableId();
      for (var i = 0; i < missing; i++) {
        table.insertColumnCell(row, id, null);
      }
    }
  }

  /// The cell occupying a grid coordinate, spans included.
  TableCell? _cellAtCoordinate(int row, int column) {
    for (final cell in table.descendants<TableCell>()) {
      final coordinate = selection.coordinateOf(cell);
      if (coordinate == null) continue;
      final colspan = _colspanOf(cell.element);
      final rowspan = _rowspanOf(cell.element);
      if (coordinate.row <= row &&
          row < coordinate.row + rowspan &&
          coordinate.column <= column &&
          column < coordinate.column + colspan) {
        return cell;
      }
    }
    return null;
  }

  /// Parses the pasted HTML into rows of `<td>`/`<th>` elements.
  List<List<DomElement>> _parseCopyRows(String html) {
    if (html.trim().isEmpty) return const [];
    final document =
        quill.root.ownerDocument.parser.parseFromString(html, 'text/html');
    final rows = <List<DomElement>>[];
    for (final row in document.body.querySelectorAll('tr')) {
      final cells = <DomElement>[];
      for (final cell in row.childNodes.whereType<DomElement>()) {
        final tag = cell.tagName.toUpperCase();
        if (tag == 'TD' || tag == 'TH') cells.add(cell);
      }
      if (cells.isNotEmpty) rows.add(cells);
    }
    return rows;
  }

  int _colspanOf(DomElement node) {
    final value = int.tryParse(node.getAttribute('colspan') ?? '') ?? 1;
    return value < 1 ? 1 : value;
  }

  int _rowspanOf(DomElement node) {
    final value = int.tryParse(node.getAttribute('rowspan') ?? '') ?? 1;
    return value < 1 ? 1 : value;
  }

  // --- helpers ------------------------------------------------------------

  void _detachDragListeners() {
    final move = _mousemoveListener;
    if (move != null) root.removeEventListener('mousemove', move);
    final up = _mouseupListener;
    if (up != null) root.removeEventListener('mouseup', up);
    _mousemoveListener = null;
    _mouseupListener = null;
  }

  /// The cell above/below (row, column), skipping rows that do not reach that
  /// column (a merged neighbour).
  TableCell? _cellInDirection(int row, int column, bool up) {
    final rows = table.descendants<TableRow>().length;
    var index = up ? row - 1 : row + 1;
    while (index >= 0 && index < rows) {
      for (final cell in table.descendants<TableCell>()) {
        final coordinate = selection.coordinateOf(cell);
        if (coordinate == null) continue;
        final raw =
            int.tryParse(cell.element.getAttribute('colspan') ?? '') ?? 1;
        final span = raw < 1 ? 1 : raw;
        if (coordinate.row == index &&
            coordinate.column <= column &&
            column < coordinate.column + span) {
          return cell;
        }
      }
      index = up ? index - 1 : index + 1;
    }
    return null;
  }

  /// Resolves the blot behind a `<td>`/`<th>` anywhere in the editor and points
  /// the live selection at its table.
  ///
  /// Upstream needs no equivalent: its `CellSelection` never knows a table, so
  /// a cell from any table is simply the new selection. Re-aiming the grid here
  /// is what keeps that single-selection invariant.
  TableCell? _bind(DomElement element) {
    for (final container in quill.scroll.descendants<TableContainer>()) {
      for (final cell in container.descendants<TableCell>()) {
        if (identical(cell.element, element)) {
          selection.rebind(container);
          return cell;
        }
      }
    }
    return null;
  }

  TableCell? _cellFromTarget(DomNode? target) {
    DomNode? node = target;
    while (node != null && !identical(node, root)) {
      if (node is DomElement) {
        final tag = node.tagName.toUpperCase();
        if (tag == 'TD' || tag == 'TH') {
          return _bind(node);
        }
      }
      node = node.parentNode;
    }
    return null;
  }
}
