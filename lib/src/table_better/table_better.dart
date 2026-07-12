/// Port of `quill-table-better.ts` (v1.2.3) — the `table-better` module core.
///
/// Scope of this increment: document-level operations (`insertTable`,
/// `getTable`, `deleteTable`, `deleteTableTemporary`, `listenDeleteTable`)
/// plus per-table [CellSelectionController] wiring. The DOM tool layers the
/// TS constructor also builds (`TableMenus`, `OperateLine`, `ToolbarTable`)
/// and the keyboard bindings are later increments (F5.7/F5.8/F5.10).
import 'dart:math' as math;

import '../blots/block.dart';
import '../core/emitter.dart';
import '../core/module.dart';
import '../core/quill.dart';
import '../core/selection.dart';
import '../dependencies/dart_quill_delta/dart_quill_delta.dart';
import '../modules/keyboard.dart';
import 'formats/table.dart';
import 'formats/header.dart';
import 'formats/list.dart';
import 'language/language.dart';
import 'ui/cell_selection.dart';
import 'ui/cell_selection_controller.dart';

/// Mirrors the TS `Options` interface (language only for now; `menus`,
/// `toolbarButtons` and `toolbarTable` belong to the pending UI layers).
class TableBetterOptions {
  const TableBetterOptions({this.language});

  /// Locale name ([String]) or a [LanguageConfig] to register and select.
  final dynamic language;

  factory TableBetterOptions.fromConfig(dynamic config) {
    if (config is TableBetterOptions) return config;
    if (config is Map) {
      final rawLanguage = config['language'];
      if (rawLanguage is Map) {
        final name = '${rawLanguage['name'] ?? ''}';
        final rawContent = rawLanguage['content'];
        final content = <String, String>{};
        if (rawContent is Map) {
          for (final entry in rawContent.entries) {
            content['${entry.key}'] = '${entry.value}';
          }
        }
        return TableBetterOptions(
          language: LanguageConfig(name: name, content: content),
        );
      }
      return TableBetterOptions(language: rawLanguage);
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
  final Map<TableContainer, CellSelectionController> _cellSelections = {};

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
    final id = line.element.getAttribute('data-cell') ?? cellId();
    replaceBlotWith(line, TableCellBlock.kBlotName, id);
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
    if (context.offset == 0 && line.prev is TableCellBlock) {
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

  /// Lazily wires a [CellSelectionController] (click/Shift-click layer) for
  /// [table]. Controllers of removed tables are disposed on text-change.
  CellSelectionController controllerFor(TableContainer table) {
    return _cellSelections.putIfAbsent(
      table,
      () => CellSelectionController(root: quill.root, table: table),
    );
  }

  /// TS `getTable(range)` (quill-table-better.ts:133).
  TableBetterContext getTable([Range? range]) {
    final targetRange = range ?? quill.getSelection();
    if (targetRange == null) return const TableBetterContext();
    final entry = quill.getLine(targetRange.index);
    final block = entry.key;
    final offset = entry.value;
    if (block == null || block.blotName != TableCellBlock.kBlotName) {
      return TableBetterContext(offset: offset);
    }
    final cell = block.parent;
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

  /// TS `hideTools()` (quill-table-better.ts:214) — menus/operate-line are
  /// not part of this increment; clearing the cell selections is the portion
  /// that already exists.
  void hideTools() {
    for (final controller in _cellSelections.values) {
      controller.clear();
    }
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
