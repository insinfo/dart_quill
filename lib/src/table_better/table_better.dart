/// Port of `quill-table-better.ts` (v1.2.3) — the `table-better` module core.
///
/// Covers the document-level operations (`insertTable`, `getTable`,
/// `deleteTable`, `deleteTableTemporary`, `listenDeleteTable`), the root-level
/// handlers (`handleKeyup`, `handleMousedown`, `handleMouseMove`,
/// `handleScroll`, `clearHistorySelected`) and the tool layers the TS
/// constructor builds: [TableMenus], [OperateLine], [TableSelect] and the
/// keyboard bindings.
///
/// Like upstream, there is exactly one [CellSelectionController] per editor,
/// so only one selection is ever live and the editor-wide toolbar state has a
/// single owner. Its logical grid is re-aimed at whatever table the user
/// touches (`CellSelection.rebind`), which is where the TS instead reads
/// geometry off `selectedTds` with `getBoundingClientRect`.
import 'dart:math' as math;

import '../blots/block.dart';
import '../blots/abstract/blot.dart';
import '../core/emitter.dart';
import '../core/module.dart';
import '../core/quill.dart';
import '../core/selection.dart';
import '../delta/delta.dart';
import '../modules/keyboard.dart';
import '../platform/dom.dart';
import 'formats/table.dart';
import 'formats/header.dart';
import 'formats/list.dart';
import 'language/language.dart';
import 'modules/toolbar.dart';
import 'ui/cell_selection.dart';
import 'ui/cell_selection_controller.dart';
import 'ui/operate_line.dart';
import 'ui/table_menus.dart';
import 'ui/toolbar_table.dart';
import '../ui/icons.dart';

/// Mirrors the TS `Options` interface.
class TableBetterOptions {
  const TableBetterOptions({
    this.language,
    this.menus,
    this.toolbarButtons,
    this.toolbarTable = false,
  });

  /// Locale name ([String]) or a [LanguageConfig] to register and select.
  final dynamic language;

  /// TS `menus` — names of the floating menus to show, in order. `null` (or
  /// empty) yields the upstream default set.
  final List<String>? menus;

  /// TS `toolbarButtons` — `{ whiteList, singleWhiteList }` of toolbar formats
  /// allowed while cells are selected.
  final Map<String, List<String>>? toolbarButtons;

  /// TS `toolbarTable` — replace the built-in table button with the
  /// table-better 10x10 selector.
  final bool toolbarTable;

  factory TableBetterOptions.fromConfig(dynamic config) {
    if (config is TableBetterOptions) return config;
    if (config is Map) {
      final rawLanguage = config['language'];
      dynamic language = rawLanguage;
      if (rawLanguage is Map) {
        final name = '${rawLanguage['name'] ?? ''}';
        final rawContent = rawLanguage['content'];
        final content = <String, String>{};
        if (rawContent is Map) {
          for (final entry in rawContent.entries) {
            content['${entry.key}'] = '${entry.value}';
          }
        }
        language = LanguageConfig(name: name, content: content);
      }
      final rawMenus = config['menus'];
      final rawButtons = config['toolbarButtons'];
      return TableBetterOptions(
        language: language,
        menus: rawMenus is List
            ? rawMenus.map((entry) => '$entry').toList(growable: false)
            : null,
        toolbarButtons: rawButtons is Map
            ? {
                for (final entry in rawButtons.entries)
                  '${entry.key}': entry.value is List
                      ? (entry.value as List)
                          .map((value) => '$value')
                          .toList(growable: false)
                      : const <String>[],
              }
            : null,
        toolbarTable: config['toolbarTable'] == true,
      );
    }
    return const TableBetterOptions();
  }
}

/// TS `getTable` result tuple `[TableContainer, TableRow, TableCell, offset]`.
class TableBetterContext {
  const TableBetterContext({
    this.table,
    this.row,
    this.cell,
    this.offset = -1,
  });

  final TableContainer? table;
  final TableRow? row;
  final TableCell? cell;
  final int offset;

  bool get isInTable => table != null;
}

/// TS `class Table extends Module` from `quill-table-better.ts:56`.
class TableBetter extends Module<TableBetterOptions> {
  TableBetter(Quill quill, TableBetterOptions options)
      : language = Language(options.language),
        super(quill, options) {
    _registerKeyboardBindings();
    toolbarRouter = TableToolbarRouter(
      quill,
      () => activeCellSelection,
      onFormatted: () => tableMenus.updateMenus(),
    );
    tableMenus = TableMenus(
      quill: quill,
      language: language,
      menus: options.menus,
      resolveSelection: _selectionForElement,
      hideTools: hideTools,
    );
    toolbarRouter.install();
    operateLine = OperateLine(
      quill: quill,
      resolveTable: _tableForElement,
      onResized: (tableNode) => tableMenus.updateMenus(tableNode),
    );
    cellSelection = CellSelectionController(
      quill: quill,
      root: quill.root,
      host: CellSelectionHost(
        hideTools: hideTools,
        showTools: showTools,
        toggleHeaderRowSwitch: tableMenus.toggleHeaderRowSwitch,
        disableMenu: tableMenus.disableMenu,
        updateMenus: tableMenus.updateMenus,
        deleteColumn: tableMenus.deleteColumn,
        deleteRow: tableMenus.deleteRow,
        toolbarContainer: _toolbarContainer,
        toolbarButtons: options.toolbarButtons,
      ),
    );
    registerToolbarTable(options.toolbarTable);
    listenDeleteTable();
    // TS quill-table-better.ts:96-98 — the module owns the root-level
    // lifecycle; the CellSelectionController keeps its own click / mousedown /
    // keyup listeners for the grid itself, as the TS CellSelection does.
    quill.root.addEventListener('keyup', (event) {
      if (event is DomKeyboardEvent) handleKeyup(event);
    });
    quill.root.addEventListener('mousedown', handleMousedown);
    quill.root.addEventListener('scroll', (_) => handleScroll());
    quill.emitter.on(
      EmitterEvents.TEXT_CHANGE,
      (dynamic _delta, dynamic _old, dynamic source) {
        if (source == EmitterSource.SILENT) return;
        _syncCellSelections();
      },
    );
    _syncCellSelections();
  }

  final Language language;
  late final TableToolbarRouter toolbarRouter;

  /// TS `this.tableMenus` — the floating menu bar (`ui/table-menus.ts`).
  late final TableMenus tableMenus;

  /// TS `this.tableSelect` — only built when `toolbarTable` is enabled.
  TableSelect? tableSelect;

  /// TS `this.operateLine` — the resize overlay (`ui/operate-line.ts`).
  late final OperateLine operateLine;

  /// TS `this.cellSelection` — one per editor, as upstream has.
  late final CellSelectionController cellSelection;

  /// Resolves the [CellSelection] for a `<table>` element, for [tableMenus].
  CellSelection? _selectionForElement(DomElement element) {
    final table = _tableForElement(element);
    if (table == null) return null;
    cellSelection.selection.rebind(table);
    return cellSelection.selection;
  }

  /// Resolves the [TableContainer] blot behind a `<table>` element.
  TableContainer? _tableForElement(DomElement element) {
    for (final table in quill.scroll.descendants<TableContainer>()) {
      if (table.element == element) return table;
    }
    return null;
  }

  void _registerKeyboardBindings() {
    for (final up in const [true, false]) {
      quill.keyboard.addBinding(
        BindingObject(key: up ? 'ArrowUp' : 'ArrowDown'),
        context: {
          'collapsed': true,
          'format': [TableCell.kBlotName, TableTh.kBlotName],
        },
        handler: (Range _range, Context _context) => false,
      );
    }
    for (final key in const ['Backspace', 'Delete']) {
      quill.keyboard.addBinding(
        BindingObject(key: key),
        context: {
          'collapsed': true,
          'format': [TableCellBlock.kBlotName, TableThBlock.kBlotName],
        },
        handler: (Range range, Context context) =>
            _handleCellBlockKey(key, range, context),
      );
      quill.keyboard.addBinding(
        BindingObject(key: key),
        context: {
          'collapsed': true,
          'empty': true,
          'format': [TableHeader.kBlotName],
        },
        handler: (Range range, Context context) =>
            _handleEmptyHeader(range, context),
      );
      quill.keyboard.addBinding(
        BindingObject(key: key),
        context: {
          'collapsed': true,
          'empty': true,
          'format': [TableList.kBlotName],
        },
        handler: (Range _range, Context context) =>
            _replaceWithCellBlock(context.line),
      );
    }
    quill.keyboard.addBinding(
      BindingObject(key: 'Enter'),
      context: {
        'collapsed': true,
        'suffix': RegExp(r'^$'),
        'format': [TableHeader.kBlotName],
      },
      handler: (Range range, Context context) =>
          _handleHeaderEnter(range, context),
    );
    quill.keyboard.addBinding(
      BindingObject(key: 'Enter'),
      context: {
        'collapsed': true,
        'empty': true,
        'format': [TableList.kBlotName],
      },
      handler: (Range _range, Context context) =>
          _replaceWithCellBlock(context.line),
    );
  }

  bool _handleEmptyHeader(Range range, Context context) {
    if (context.line.prev != null) {
      context.line.remove();
      quill.setSelection(
        Range((range.index - 1).clamp(0, range.index).toInt(), 0),
        source: EmitterSource.SILENT,
      );
      return false;
    }
    return _replaceWithCellBlock(context.line);
  }

  bool _replaceWithCellBlock(Block line) {
    // Parity quill-table-better.ts:354/431 — for list lines the cellId lives
    // on the ListContainer (data-cell on the <ol>), never on the <li>;
    // reading the line's own attribute minted a fresh id and detached the
    // block from its cell grouping.
    String? id;
    final parentBlot = line.parent;
    if (parentBlot is TableListContainer) {
      id = parentBlot.element.getAttribute('data-cell');
    }
    id ??= line.element.getAttribute('data-cell');
    replaceBlotWith(line, TableCellBlock.kBlotName, id ?? cellId());
    return false;
  }

  bool _handleHeaderEnter(Range range, Context context) {
    // Parity quill-table-better.ts:328-343 — the retain key is `header`
    // (TableHeader.format's first branch turns `header: null` into a cell
    // block), so the emitted TEXT_CHANGE delta matches upstream's.
    final delta = Delta()
      ..retain(range.index)
      ..insert('\n', context.format)
      ..retain(math.max(0, context.line.length() - context.offset - 1))
      ..retain(1, {'header': null});
    quill.updateContents(delta, source: EmitterSource.USER);
    quill.setSelection(
      Range(range.index + 1, 0),
      source: EmitterSource.SILENT,
    );
    quill.scrollSelectionIntoView();
    return false;
  }

  bool _handleCellBlockKey(String key, Range range, Context context) {
    final line = context.line;
    if (context.offset == 0 && line.prev == null) return false;
    // Parity quill-table-better.ts:372-381 — the previous sibling may be a
    // list container or a header line, not only another cell block.
    final prev = line.prev;
    if (context.offset == 0 &&
        (prev is TableCellBlock ||
            prev is TableListContainer ||
            prev is TableHeader)) {
      line.remove();
      quill.setSelection(
        Range((range.index - 1).clamp(0, range.index).toInt(), 0),
        source: EmitterSource.SILENT,
      );
      return false;
    }
    if (context.offset != 0 && context.suffix.isEmpty && key == 'Delete') {
      return false;
    }
    return true;
  }

  /// Logical multi-cell selection of the table under the caret, if any.
  CellSelection? get activeCellSelection {
    final table = getTable().table;
    if (table == null) return null;
    cellSelection.selection.rebind(table);
    return cellSelection.selection;
  }

  /// The live controller, with its grid pointed at [table].
  CellSelectionController controllerFor(TableContainer table) {
    cellSelection.selection.rebind(table);
    return cellSelection;
  }

  DomElement? get _toolbarContainer {
    final toolbar = quill.getModule('toolbar');
    if (toolbar == null) return null;
    return (toolbar as dynamic).container as DomElement?;
  }

  /// TS `getTable(range)` (quill-table-better.ts:133).
  TableBetterContext getTable([Range? range]) {
    final targetRange = range ?? quill.getSelection();
    if (targetRange == null) return const TableBetterContext();
    final entry = quill.getLine(targetRange.index);
    final block = entry.key;
    final offset = entry.value;
    if (block == null ||
        !const {
          TableCellBlock.kBlotName,
          TableThBlock.kBlotName,
          TableHeader.kBlotName,
          TableList.kBlotName,
        }.contains(block.blotName)) {
      return TableBetterContext(offset: offset);
    }
    Blot? cell = block.parent;
    while (cell != null && cell is! TableCell) {
      cell = cell.parent;
    }
    final row = cell?.parent;
    final table = row?.parent?.parent;
    if (cell is TableCell && row is TableRow && table is TableContainer) {
      return TableBetterContext(
        table: table,
        row: row,
        cell: cell,
        offset: offset,
      );
    }
    return TableBetterContext(offset: offset);
  }

  /// TS `insertTable(rows, columns)` (quill-table-better.ts:224).
  void insertTable(int rows, int columns) {
    final range = quill.getSelection(focus: true);
    if (range == null) return;
    if (_isTable(range)) return;
    const style = 'width: 100%';
    final formats =
        range.index > 0 ? quill.getFormat(range.index - 1) : const {};
    final offset = quill.getLine(range.index).value;
    final isExtra =
        formats.containsKey(TableCellBlock.kBlotName) || offset != 0;
    final selectionOffset = isExtra ? 2 : 1;
    final delta = Delta();
    if (range.index > 0) delta.retain(range.index);
    if (range.length > 0) delta.delete(range.length);
    if (isExtra) delta.insert('\n');
    delta.insert('\n', {
      TableTemporary.kBlotName: {'style': style}
    });
    for (var r = 0; r < rows; r++) {
      final id = tableId();
      for (var c = 0; c < columns; c++) {
        delta.insert('\n', {
          TableCellBlock.kBlotName: cellId(),
          TableCell.kBlotName: {'data-row': id}
        });
      }
    }
    quill.updateContents(delta, source: EmitterSource.USER);
    quill.setSelection(
      Range(range.index + selectionOffset, 0),
      source: EmitterSource.SILENT,
    );
    // TS `insertTable` finishes with `this.showTools()` (quill-table-better.ts:252).
    showTools();
  }

  /// TS `deleteTable()` (quill-table-better.ts:114).
  void deleteTable() {
    final table = getTable().table;
    if (table == null) return;
    final offset = quill.scroll.offset(table);
    table.remove();
    hideTools();
    // TS calls quill.update(USER): the tree changed outside the delta
    // pipeline, so the document delta must be reconciled — without it,
    // getContents() keeps reporting the removed table.
    quill.update(EmitterSource.USER);
    final length = quill.scroll.length();
    quill.setSelection(
      Range(offset.clamp(0, length).toInt(), 0),
      source: EmitterSource.SILENT,
    );
  }

  /// TS `deleteTableTemporary(source)` (quill-table-better.ts:124).
  void deleteTableTemporary([String source = EmitterSource.API]) {
    final temporaries =
        quill.scroll.descendants<TableTemporary>().toList(growable: false);
    for (final temporary in temporaries) {
      temporary.remove();
    }
    hideTools();
    // TS: quill.update(source) — reconcile the delta after the direct removal.
    quill.update(source);
  }

  /// TS `registerToolbarTable(toolbarTable)` (quill-table-better.ts:281).
  ///
  /// Opt-in: registers the `formats/table-better` blot, hangs the 10x10
  /// [TableSelect] under the toolbar's `ql-table-better` button and closes it
  /// on any click outside.
  void registerToolbarTable(bool enabled) {
    if (!enabled) return;
    Quill.registerPath('formats/table-better', ToolbarTable.registryEntry,
        overwrite: true);
    quill.scroll.registry.register(ToolbarTable.registryEntry);
    icons[ToolbarTable.kBlotName] ??= toolbarTableIcon;

    final toolbar = quill.getModule('toolbar');
    if (toolbar == null) return;
    final container = (toolbar as dynamic).container as DomElement?;
    if (container == null) return;
    DomElement? button;
    for (final candidate in container.querySelectorAll('button')) {
      if (candidate.classes.contains('ql-table-better')) {
        button = candidate;
        break;
      }
    }
    if (button == null) return;
    // The theme may have rendered the toolbar before this module registered
    // the icon (upstream sets it at import time); backfill the button markup.
    final iconMarkup = icons[ToolbarTable.kBlotName];
    if (iconMarkup is String && !(button.innerHTML ?? '').contains('<svg')) {
      button.innerHTML = iconMarkup;
    }
    tableSelect = TableSelect(document: quill.root.ownerDocument);
    button.append(tableSelect!.root);
    button.addEventListener('click', (event) {
      tableSelect!.handleClick(event.target, insertTable);
    });
    quill.root.ownerDocument.addEventListener('click', (event) {
      final select = tableSelect;
      if (select == null || select.isHidden) return;
      if (_isInside(event.target, button!)) return;
      select.hide();
    });
  }

  bool _isInside(DomNode? target, DomNode ancestor) {
    DomNode? node = target;
    while (node != null) {
      // `==` (native-node equality): each `parentNode` step hands back a
      // fresh wrapper, so `identical` treated every click as outside the
      // button and the document listener re-hid the grid on the click that
      // had just opened it.
      if (node == ancestor) return true;
      node = node.parentNode;
    }
    return false;
  }

  /// TS `showTools(force)` (quill-table-better.ts:290) — parks the selection on
  /// the caret's cell and reveals the menus over its table.
  void showTools([bool force = false]) {
    final context = getTable();
    final table = context.table;
    final cell = context.cell;
    if (table == null || cell == null) return;
    final controller = controllerFor(table);
    // TS `showTools`: disable the non-whitelisted toolbar inputs, then park the
    // selection on the caret's cell (quill-table-better.ts:290-298).
    controller.setDisabled(true);
    if (force || !controller.selection.isActive) {
      controller.setSelected(cell.element, force);
    }
    tableMenus.updateTable(table.element);
    tableMenus.showMenus();
    tableMenus.updateMenus(table.element);
  }

  /// TS `updateMenus()` (quill-table-better.ts:316).
  void updateMenus() => tableMenus.updateMenus();

  // --- root-level handlers (quill-table-better.ts:147-212) -----------------

  /// TS `clearHistorySelected()` (quill-table-better.ts:103).
  ///
  /// Undo/redo replays DOM that may still carry the selection classes, and the
  /// blots behind them are gone — so the classes are stripped straight off the
  /// `<td>`s instead of through the selection model.
  void clearHistorySelected() {
    final table = getTable().table;
    if (table == null) return;
    for (final td in table.element.querySelectorAll('td')) {
      td.classes.remove('ql-cell-focused');
      td.classes.remove('ql-cell-selected');
    }
  }

  /// TS `handleKeyup(e)` (quill-table-better.ts:147).
  ///
  /// The arrow-key half lives in [CellSelectionController], which listens on
  /// the same root; this is the surrounding lifecycle.
  void handleKeyup(DomKeyboardEvent event) {
    if (!quill.isEnabled()) return;
    if (event.ctrlKey && (event.key == 'z' || event.key == 'y')) {
      hideTools();
      clearHistorySelected();
    }
    _updateMenusOnKeyup(event);
  }

  /// TS private `updateMenus(e)` (quill-table-better.ts:310) — Enter and
  /// Ctrl+V resize the table, so the menus have to follow.
  void _updateMenusOnKeyup(DomKeyboardEvent event) {
    if (activeCellSelection?.selectedTds.isEmpty ?? true) return;
    if (event.key == 'Enter' || (event.ctrlKey && event.key == 'v')) {
      tableMenus.updateMenus();
    }
  }

  /// TS `handleMousedown(e)` (quill-table-better.ts:157).
  void handleMousedown(DomEvent event) {
    if (!quill.isEnabled()) return;
    tableSelect?.hide();
    final table = _closestTable(event.target);
    if (table != null && !_isInside(table, quill.root)) {
      // A table belonging to an editor nested inside this one.
      hideTools();
      return;
    }
    if (table == null) {
      hideTools();
      handleMouseMove();
      return;
    }
    final blot = _tableForElement(table);
    if (blot != null) controllerFor(blot).setDisabled(true);
  }

  /// TS `handleMouseMove()` (quill-table-better.ts:177).
  ///
  /// A native drag that starts outside a table and passes through one would
  /// otherwise leave a partial selection cutting cells in half; on mouseup the
  /// range is widened to cover the whole table.
  void handleMouseMove() {
    DomElement? touched;
    late final DomEventListener onMove;
    late final DomEventListener onUp;
    onMove = (moveEvent) {
      touched ??= _closestTable(moveEvent.target);
    };
    onUp = (_) {
      final element = touched;
      if (element != null) {
        final blot = _tableForElement(element);
        final range = quill.getSelection();
        if (blot != null && range != null) {
          final index = quill.scroll.offset(blot);
          final length = blot.length();
          final start = math.min(range.index, index);
          final end = math.max(range.index + range.length, index + length);
          quill.setSelection(
            Range(start, end - start),
            source: EmitterSource.USER,
          );
        }
      }
      quill.root.removeEventListener('mousemove', onMove);
      quill.root.removeEventListener('mouseup', onUp);
    };
    quill.root.addEventListener('mousemove', onMove);
    quill.root.addEventListener('mouseup', onUp);
  }

  /// TS `handleScroll()` (quill-table-better.ts:208).
  void handleScroll() {
    if (!quill.isEnabled()) return;
    hideTools();
    tableMenus.updateScroll(true);
  }

  /// Nearest `<table>` ancestor of [target], itself included.
  DomElement? _closestTable(DomNode? target) {
    DomNode? node = target;
    while (node != null) {
      if (node is DomElement && node.tagName.toUpperCase() == 'TABLE') {
        return node;
      }
      node = node.parentNode;
    }
    return null;
  }

  /// Routes a paste to the live cell selection (TS `onCapturePaste`).
  ///
  /// Returns false when no cells are selected, so the clipboard module falls
  /// back to its normal paste.
  bool pasteGridIntoSelection(String html) {
    if (cellSelection.selectedTds.isEmpty) return false;
    return cellSelection.pasteGrid(html);
  }

  /// TS `hideTools()` (quill-table-better.ts:214) — clears the cell selections
  /// and hides the floating menus. The operate-line overlay joins in G6.5.
  void hideTools() {
    cellSelection.clear();
    cellSelection.setDisabled(false);
    operateLine.hideDragBlock();
    operateLine.hideDragTable();
    operateLine.hideLine();
    tableMenus.hideMenus();
    tableMenus.destroyTablePropertiesForm();
  }

  /// TS `listenDeleteTable()` (quill-table-better.ts:260): user edits that
  /// leave a table with neither tbody nor thead delete the whole table.
  void listenDeleteTable() {
    quill.emitter.on(
      EmitterEvents.TEXT_CHANGE,
      (dynamic _delta, dynamic _old, dynamic source) {
        if (source != EmitterSource.USER) return;
        final tables =
            quill.scroll.descendants<TableContainer>().toList(growable: false);
        if (tables.isEmpty) return;
        final deleteTables = tables
            .where((table) => table.tbody() == null && table.thead() == null)
            .toList(growable: false);
        if (deleteTables.isEmpty) return;
        for (final table in deleteTables) {
          table.remove();
        }
        hideTools();
        quill.scroll.optimize([], {});
      },
    );
  }

  /// TS private `isTable(range)` (quill-table-better.ts:254) — nested tables
  /// are not supported.
  bool _isTable(Range range) {
    final formats = quill.getFormat(range.index);
    return formats.containsKey(TableCellBlock.kBlotName);
  }

  /// Drops the selection when the table it lived in is gone (deleted table,
  /// undo). Upstream reaches the same state through `hideTools()`.
  void _syncCellSelections() {
    if (!cellSelection.selection.isBound) return;
    final live = quill.scroll.descendants<TableContainer>().toSet();
    if (!live.contains(cellSelection.selection.table)) cellSelection.clear();
  }
}
