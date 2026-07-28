/// Port of `quill-table-better.ts` (v1.2.3) — the `table-better` module core.
///
/// Scope of this increment: document-level operations (`insertTable`,
/// `getTable`, `deleteTable`, `deleteTableTemporary`, `listenDeleteTable`)
/// plus per-table [CellSelectionController] wiring. The DOM tool layers the
/// TS constructor also builds (`TableMenus`, `OperateLine`, `ToolbarTable`)
/// and the keyboard bindings are later increments (F5.7/F5.8/F5.10).
import 'dart:math' as math;

import '../blots/block.dart';
import '../blots/abstract/blot.dart';
import '../core/emitter.dart';
import '../core/module.dart';
import '../core/quill.dart';
import '../core/selection.dart';
import '../dependencies/dart_quill_delta/dart_quill_delta.dart';
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
    registerToolbarTable(options.toolbarTable);
    listenDeleteTable();
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

  final Map<TableContainer, CellSelectionController> _cellSelections = {};

  /// Resolves the [CellSelection] owning a `<table>` element, for [tableMenus].
  CellSelection? _selectionForElement(DomElement element) {
    final table = _tableForElement(element);
    return table == null ? null : controllerFor(table).selection;
  }

  /// Resolves the [TableContainer] blot behind a `<table>` element.
  TableContainer? _tableForElement(DomElement element) {
    for (final table in quill.scroll.descendants<TableContainer>()) {
      if (identical(table.element, element)) return table;
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
    final delta = Delta()
      ..retain(range.index)
      ..insert('\n', context.format)
      ..retain(math.max(0, context.line.length() - context.offset - 1))
      ..retain(1, {TableHeader.kBlotName: null});
    quill.updateContents(delta, source: EmitterSource.USER);
    quill.setSelection(
      Range(range.index + 1, 0),
      source: EmitterSource.SILENT,
    );
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
    return controllerFor(table).selection;
  }

  /// Lazily wires a [CellSelectionController] (drag/click/keyboard layer) for
  /// [table]. Controllers of removed tables are disposed on text-change.
  CellSelectionController controllerFor(TableContainer table) {
    return _cellSelections.putIfAbsent(
      table,
      () => CellSelectionController(
        quill: quill,
        root: quill.root,
        table: table,
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
      ),
    );
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
    quill.scroll.optimize([], {});
    final length = quill.scroll.length();
    quill.setSelection(
      Range(offset.clamp(0, length).toInt(), 0),
      source: EmitterSource.SILENT,
    );
  }

  /// TS `deleteTableTemporary(source)` (quill-table-better.ts:124).
  void deleteTableTemporary() {
    final temporaries =
        quill.scroll.descendants<TableTemporary>().toList(growable: false);
    for (final temporary in temporaries) {
      temporary.remove();
    }
    hideTools();
    quill.scroll.optimize([], {});
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
      if (identical(node, ancestor)) return true;
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

  /// Routes a paste to the active cell selection (TS `onCapturePaste`).
  ///
  /// Returns false when no table has cells selected, so the clipboard module
  /// falls back to its normal paste.
  bool pasteGridIntoSelection(String html) {
    for (final controller in _cellSelections.values) {
      if (controller.selectedTds.isEmpty) continue;
      if (controller.pasteGrid(html)) return true;
    }
    return false;
  }

  /// TS `hideTools()` (quill-table-better.ts:214) — clears the cell selections
  /// and hides the floating menus. The operate-line overlay joins in G6.5.
  void hideTools() {
    for (final controller in _cellSelections.values) {
      controller.clear();
      controller.setDisabled(false);
    }
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

  void _syncCellSelections() {
    final live = quill.scroll.descendants<TableContainer>().toSet();
    final removed = _cellSelections.keys
        .where((table) => !live.contains(table))
        .toList(growable: false);
    for (final table in removed) {
      _cellSelections.remove(table)?.dispose();
    }
    for (final table in live) {
      controllerFor(table);
    }
  }
}
