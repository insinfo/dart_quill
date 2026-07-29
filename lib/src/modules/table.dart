import '../blots/abstract/blot.dart';
import 'dart:math' as math;

import '../blots/block.dart';
import '../blots/break.dart';
import '../core/emitter.dart';
import '../core/module.dart';
import '../core/quill.dart';
import '../core/selection.dart';
import '../dependencies/dart_quill_delta/dart_quill_delta.dart';
import '../core/theme.dart';
import '../formats/table.dart';
import '../platform/dom.dart';
import '../platform/platform.dart';
import '../ui/icons.dart' as ui_icons;

class TableOptions {
  const TableOptions();

  factory TableOptions.fromConfig(dynamic _) {
    return const TableOptions();
  }
}

String _tablerIcon(String action) =>
    const {
      'row-insert-top': 'row-insert-top',
      'row-insert-bottom': 'row-insert-bottom',
      'column-insert-left': 'column-insert-left',
      'column-insert-right': 'column-insert-right',
      'row-remove': 'row-remove',
      'column-remove': 'column-remove',
      'arrow-merge': 'arrow-merge',
      'arrows-split': 'arrows-split',
      'table-off': 'table-off',
    }[action] ??
    'table';

class Table extends Module<TableOptions> {
  /// Registers the four blots used by the basic table module.
  ///
  /// This mirrors Quill's `Table.register()` extension entry point. Calling it
  /// repeatedly is safe because [Quill.register] preserves existing entries.
  static void register() {
    for (final entry in tableRegistryEntries()) {
      Quill.register(entry);
    }
  }

  bool _isBalancing = false;

  Table(Quill quill, TableOptions options) : super(quill, options) {
    _buildContextToolbar();
    _listenBalanceCells();
    quill.emitter.on(
      EmitterEvents.TEXT_CHANGE,
      (dynamic changeDelta, dynamic _old, dynamic source) {
        if (source == EmitterSource.SILENT) {
          return;
        }
        if (_needsTableNormalization()) {
          balanceTables();
        }
      },
    );
    balanceTables();
  }

  late final DomElement _contextToolbar;
  TableCell? _activeCell;
  DomElement? _activeCellElement;

  void _buildContextToolbar() {
    _contextToolbar = quill.addContainer('ql-table-context-toolbar');
    _contextToolbar.setAttribute('role', 'toolbar');
    _contextToolbar.setAttribute('aria-label', 'Ferramentas da tabela');
    _contextToolbar.style.cssText =
        'display:none;position:absolute;z-index:1100;height:40px;'
        'align-items:center;padding:4px;gap:2px;box-sizing:border-box;'
        'background:#fff;border:1px solid #ccced1;border-radius:2px;'
        'box-shadow:0 1px 2px 1px rgba(0,0,0,.15);';
    final actions = <(String, String, String, void Function())>[
      (
        'row-insert-top',
        'Inserir linha acima',
        'table-row-above',
        insertRowAbove
      ),
      (
        'row-insert-bottom',
        'Inserir linha abaixo',
        'table-row-below',
        insertRowBelow
      ),
      (
        'column-insert-left',
        'Inserir coluna à esquerda',
        'table-column-left',
        insertColumnLeft
      ),
      (
        'column-insert-right',
        'Inserir coluna à direita',
        'table-column-right',
        insertColumnRight
      ),
      ('row-remove', 'Excluir linha', 'table-delete-row', deleteRow),
      ('column-remove', 'Excluir coluna', 'table-delete-column', deleteColumn),
      (
        'arrow-merge',
        'Mesclar com a célula à direita',
        'table-merge',
        mergeCellRight
      ),
      ('arrows-split', 'Dividir célula', 'table-split', splitCell),
      ('table-off', 'Excluir tabela', 'table-delete', deleteTable),
    ];
    // The context toolbar honors the editor's icon theme: Tabler webfont
    // glyphs when the theme asked for them, the official SVG set otherwise
    // (the demo runs QuillIconTheme.svg and used to render empty <i> tags).
    final useTabler = quill.theme.options.iconTheme == QuillIconTheme.tabler;
    for (final action in actions) {
      final button = quill.container.ownerDocument.createElement('button');
      button
        ..setAttribute('type', 'button')
        ..setAttribute('title', action.$2)
        ..setAttribute('aria-label', action.$2)
        ..setAttribute('data-table-action', action.$3)
        ..style.cssText = _contextButtonStyle
        ..innerHTML = useTabler
            ? '<i class="ti ti-${_tablerIcon(action.$1)}" aria-hidden="true"></i>'
            : _svgIcon(action.$3);
      button.addEventListener('mousedown', (event) {
        event.preventDefault();
        event.stopPropagation();
      });
      button.addEventListener('click', (event) {
        action.$4();
        updateContextToolbar();
        event.preventDefault();
        event.stopPropagation();
      });
      _contextToolbar.append(button);
    }
    quill.root.addEventListener('click', (event) {
      DomNode? node = event.target;
      while (node != null && node != quill.root) {
        if (node is DomElement && node.tagName.toLowerCase() == 'td') {
          _activeCellElement = node;
          updateContextToolbar();
          return;
        }
        node = node.parentNode;
      }
      _activeCell = null;
      _activeCellElement = null;
      _contextToolbar.style.display = 'none';
    });
    quill.root.addEventListener('keyup', (_) => updateContextToolbar());
    quill.root.addEventListener('scroll', (_) => updateContextToolbar());
    quill.emitter.on(EmitterEvents.SELECTION_CHANGE,
        (dynamic range, dynamic _oldRange, dynamic _source) {
      // A selection that settles outside any table drops the click anchor,
      // so the toolbar follows the caret instead of a stale cell.
      if (range is Range && getTable(range).cell == null) {
        _activeCell = null;
        _activeCellElement = null;
      }
      updateContextToolbar();
    });
  }

  /// Official-set SVG for a context-toolbar action, sized to the button (the
  /// inlined sources carry only a viewBox; without explicit dimensions the
  /// browser falls back to 300x150 and the icon overflows).
  static String _svgIcon(String action) {
    final icon = ui_icons.icons[action];
    if (icon is! String) return '';
    return icon.replaceFirst('<svg ', '<svg width="18" height="18" ');
  }

  static const String _contextButtonStyle =
      'appearance:none;-webkit-appearance:none;width:28px;height:28px;'
      'min-width:28px;min-height:28px;margin:0;padding:3px;border:0;'
      'border-radius:2px;background:transparent;box-shadow:none;outline:none;'
      'display:inline-flex;align-items:center;justify-content:center;'
      'color:#444;font-size:18px;line-height:1;cursor:pointer;';

  void updateContextToolbar() {
    // A cell captured on click may be gone by now (table deleted, undo, cell
    // removed) — a detached anchor must never keep the toolbar alive.
    var activeElement = _activeCellElement;
    if (activeElement != null && !quill.root.contains(activeElement)) {
      _activeCell = null;
      _activeCellElement = null;
      activeElement = null;
    }
    final context = getTable(quill.selection.getRange());
    if (context.cell != null) {
      _activeCell = context.cell;
      _activeCellElement = context.cell!.element;
      activeElement = _activeCellElement;
    }
    final cellElement = activeElement;
    if (cellElement == null) {
      _contextToolbar.style.display = 'none';
      return;
    }
    final anchor = context.table?.element ?? cellElement;
    final bounds = domBindings.adapter
        .getElementBounds(anchor, relativeTo: quill.container);
    if (bounds == null) {
      _contextToolbar.style.display = 'none';
      return;
    }
    final tableWidth = (bounds['width'] as num?)?.toDouble() ?? 0;
    const toolbarWidth = 286.0;
    final containerWidth = quill.container.clientWidth.toDouble();
    final centered =
        (bounds['left'] as num).toDouble() + (tableWidth - toolbarWidth) / 2;
    final left = centered.clamp(0, math.max(0, containerWidth - toolbarWidth));
    final top =
        ((bounds['top'] as num).toDouble() - 42).clamp(0, double.infinity);
    _contextToolbar.style
      ..display = 'flex'
      ..width = '${toolbarWidth}px'
      ..left = '${left}px'
      ..top = '${top}px';
  }

  void balanceTables() {
    if (_isBalancing) {
      return;
    }
    _isBalancing = true;
    try {
      _runUserOptimize();
      _ensureTableStructure();
      final tables = quill.scroll.descendants<TableContainer>().toList();
      for (final table in tables) {
        table.balanceCells();
      }
      for (final table in tables) {
        _normalizeTableBoundaries(table);
      }
      _wireContextCells();
      _runUserOptimize();
    } finally {
      _isBalancing = false;
    }
  }

  void _wireContextCells() {
    for (final cell in quill.scroll.descendants<TableCell>()) {
      if (cell.element.dataset['contextToolbarBound'] == 'true') continue;
      cell.element.dataset['contextToolbarBound'] = 'true';
      cell.element.addEventListener('click', (_) {
        _activeCell = cell;
        _activeCellElement = cell.element;
        updateContextToolbar();
      });
    }
  }

  void deleteColumn() {
    final context = getTable();
    final table = context.table;
    final cell = context.cell;
    if (table == null || cell == null) {
      return;
    }
    table.deleteColumn(cell.cellOffset());
    _runUserOptimize();
    balanceTables();
    _runUserOptimize();
  }

  void deleteRow() {
    final context = getTable();
    final row = context.row;
    if (row == null) {
      return;
    }
    row.remove();
    _runUserOptimize();
    balanceTables();
    _runUserOptimize();
  }

  void deleteTable() {
    final context = getTable();
    final table = context.table;
    if (table == null) {
      return;
    }
    final offset = quill.scroll.offset(table);
    table.remove();
    _runUserOptimize();
    balanceTables();
    _runUserOptimize();
    final documentLength = quill.scroll.length();
    final normalizedOffset = offset.clamp(0, documentLength).toInt();
    quill.setSelection(
      Range(normalizedOffset, 0),
      source: EmitterSource.SILENT,
    );
  }

  /// Merges the active cell with its immediate right sibling.
  ///
  /// This is the single-cell foundation used by table-better's rectangular
  /// multi-cell merge operation. The resulting logical width is persisted as
  /// HTML `colspan`.
  void mergeCellRight() {
    final cell = _activeCell ?? getTable(quill.selection.getRange()).cell;
    final row = cell?.row();
    if (cell == null || row == null) return;
    final offset = cell.cellOffset();
    if (offset < 0 || offset + 1 >= row.children.length) return;
    final right = row.children[offset + 1];
    if (right is! TableCell) return;
    final span = cell.colspan + right.colspan;
    final rightText = right.element.text ?? '';
    if (rightText.isNotEmpty) {
      final insertionIndex = cell.length() > 0 ? cell.length() - 1 : 0;
      cell.insertAt(insertionIndex, rightText);
    }
    right.remove();
    cell.setSpan(colspan: span, rowspan: cell.rowspan);
    _activeCell = cell;
    _activeCellElement = cell.element;
    updateContextToolbar();
  }

  /// Splits a horizontally merged cell back into individual cells.
  void splitCell() {
    final cell = _activeCell ?? getTable(quill.selection.getRange()).cell;
    final row = cell?.row();
    if (cell == null || row == null || cell.colspan <= 1) return;
    final span = cell.colspan;
    final ref = cell.next;
    cell.setSpan(rowspan: cell.rowspan);
    for (var index = 1; index < span; index++) {
      final newCell = TableCell.create(cell.rowId);
      row.insertBefore(newCell, ref);
      newCell.optimize();
    }
    _activeCell = cell;
    _activeCellElement = cell.element;
    updateContextToolbar();
  }

  void insertColumnLeft() {
    insertColumn(0);
  }

  void insertColumnRight() {
    insertColumn(1);
  }

  void insertRowAbove() {
    insertRow(0);
  }

  void insertRowBelow() {
    insertRow(1);
  }

  void insertTable(int rows, int columns) {
    final range = quill.getSelection();
    if (range == null) {
      return;
    }
    final delta = Delta()..retain(range.index);
    for (var i = 0; i < rows; i++) {
      final buffer = StringBuffer();
      for (var j = 0; j < columns; j++) {
        buffer.write('\n');
      }
      delta.insert(buffer.toString(), {'table': tableId()});
    }
    quill.updateContents(delta, source: EmitterSource.USER);
    _runUserOptimize();
    balanceTables();
    _runUserOptimize();
    _ensureTrailingLine();
    quill.setSelection(
      Range(range.index, range.length),
      source: EmitterSource.SILENT,
    );
  }

  /// Inserts a column at the current cell plus [offset].
  ///
  /// Pass `0` to insert on the left and `1` to insert on the right, matching
  /// Quill's public table-module API.
  void insertColumn(int offset) {
    final range = quill.getSelection();
    if (range == null) {
      return;
    }
    final context = getTable(range);
    final table = context.table;
    final row = context.row;
    final cell = context.cell;
    if (table == null || row == null || cell == null) {
      return;
    }
    final column = cell.cellOffset();
    table.insertColumn(column + offset);
    _runUserOptimize();
    balanceTables();
    _runUserOptimize();
    var shift = row.rowOffset();
    if (offset == 0) {
      shift += 1;
    }
    quill.setSelection(
      Range(range.index + shift, range.length),
      source: EmitterSource.SILENT,
    );
  }

  /// Inserts a row at the current row plus [offset].
  ///
  /// Pass `0` to insert above and `1` to insert below, matching Quill's public
  /// table-module API.
  void insertRow(int offset) {
    final range = quill.getSelection();
    if (range == null) {
      return;
    }
    final context = getTable(range);
    final table = context.table;
    final row = context.row;
    if (table == null || row == null) {
      return;
    }
    final index = row.rowOffset();
    table.insertRow(index + offset);
    _runUserOptimize();
    balanceTables();
    _runUserOptimize();
    if (offset > 0) {
      quill.setSelection(range, source: EmitterSource.SILENT);
    } else {
      final length = row.children.length;
      quill.setSelection(
        Range(range.index + length, range.length),
        source: EmitterSource.SILENT,
      );
    }
  }

  void _listenBalanceCells() {
    quill.emitter.on(
      EmitterEvents.SCROLL_OPTIMIZE,
      (dynamic records, dynamic _) {
        if (records is! List<DomMutationRecord>) {
          return;
        }
        final shouldBalance = records.any((mutation) {
              final target = mutation.target;
              if (target is! DomElement) {
                return false;
              }
              final tagName = target.tagName.toUpperCase();
              return tagName == 'TD' ||
                  tagName == 'TR' ||
                  tagName == 'TBODY' ||
                  tagName == 'TABLE';
            }) ||
            _needsTableNormalization();
        if (!shouldBalance) {
          return;
        }
        quill.emitter.once(
          EmitterEvents.TEXT_CHANGE,
          (dynamic _delta, dynamic _old, dynamic source) {
            if (source == EmitterSource.SILENT) {
              return;
            }
            if (_needsTableNormalization()) {
              balanceTables();
            }
          },
        );
      },
    );
  }

  void _runUserOptimize() {
    quill.scroll.optimize([], {'source': EmitterSource.USER});
  }

  bool _needsTableNormalization() {
    return quill.scroll.descendants<TableCell>().any((cell) {
      if (cell.parent is! TableRow) {
        return true;
      }
      return cell.rowId == null;
    });
  }

  void _ensureTableStructure() {
    final scroll = quill.scroll;
    final children = scroll.children.toList(growable: false);
    TableContainer? currentContainer;
    TableBody? currentBody;
    final rowsById = <String, TableRow>{};

    void resetContainer() {
      currentContainer = null;
      currentBody = null;
      rowsById.clear();
    }

    for (final child in children) {
      if (child is! TableCell || child.parent is TableRow) {
        resetContainer();
        continue;
      }
      if (currentContainer == null) {
        currentContainer = TableContainer.create();
        currentBody = TableBody.create();
        currentContainer!.appendChild(currentBody!);
        scroll.insertBefore(currentContainer!, child);
      }
      final body = currentBody!;
      final rowId = child.rowId ?? tableId();
      var row = rowsById[rowId];
      if (row == null) {
        row = TableRow.create();
        rowsById[rowId] = row;
        body.appendChild(row);
      }
      row.appendChild(child);
    }
  }

  void _normalizeTableBoundaries(TableContainer table) {
    final rows = table.rows();
    if (rows.isEmpty) {
      return;
    }

    var insertedLeadingParagraph = false;
    for (final row in rows) {
      final cells = row.children.whereType<TableCell>().toList();
      if (cells.isEmpty) {
        continue;
      }
      final firstCell = cells.first;
      if (!insertedLeadingParagraph &&
          firstCell.rowId == null &&
          _isEmptyCell(firstCell)) {
        firstCell.remove();
        insertedLeadingParagraph = true;
        _insertParagraphsBefore(table, 1);
      }
    }

    if (insertedLeadingParagraph) {
      for (final row in rows) {
        final cells = row.children.whereType<TableCell>().toList();
        if (cells.isEmpty) {
          continue;
        }
        final lastCell = cells.last;
        if (_isEmptyCell(lastCell)) {
          lastCell.remove();
        }
      }
      return;
    }

    var insertedTrailingParagraph = false;
    for (final row in rows) {
      final cells = row.children.whereType<TableCell>().toList();
      if (cells.isEmpty) {
        continue;
      }
      final lastCell = cells.last;
      if (lastCell.rowId == null && _isEmptyCell(lastCell)) {
        lastCell.remove();
        insertedTrailingParagraph = true;
      }
    }

    if (insertedTrailingParagraph) {
      _insertParagraphsAfter(table, 1);
    }
  }

  bool _isEmptyCell(TableCell cell) {
    if (cell.children.isEmpty) {
      return true;
    }
    return cell.children.every((child) => child is Break);
  }

  Block _createParagraphBlock() {
    final block = quill.scroll.create(Block.kBlotName) as Block;
    if (block.children.isEmpty) {
      block.appendChild(Break.create());
    }
    return block;
  }

  void _insertParagraphsBefore(TableContainer table, int count) {
    for (var i = 0; i < count; i++) {
      final paragraph = _createParagraphBlock();
      quill.scroll.insertBefore(paragraph, table);
    }
  }

  void _insertParagraphsAfter(TableContainer table, int count) {
    Blot? ref = table.next;
    for (var i = 0; i < count; i++) {
      final paragraph = _createParagraphBlock();
      quill.scroll.insertBefore(paragraph, ref);
    }
  }

  void _ensureTrailingLine() {
    final children = quill.scroll.children;
    if (children.isEmpty) {
      return;
    }
    final last = children.last;
    if (last is! TableContainer) {
      return;
    }
    final length = quill.scroll.length();
    quill.scroll.insertAt(length, '\n');
    _runUserOptimize();
  }

  /// Returns the table hierarchy and cell-relative offset for [range].
  ///
  /// When [range] is omitted the current selection is used. Outside a table,
  /// the hierarchy fields are null and [TableContext.offset] is `-1`.
  TableContext getTable([Range? range]) {
    _ensureTableStructure();
    final targetRange = range ?? quill.getSelection();
    if (targetRange == null) {
      return const TableContext();
    }
    final entry = quill.scroll.descendant(
      (blot) => blot is TableCell,
      targetRange.index,
    );
    final blot = entry.key;
    final offset = entry.value;
    if (blot is! TableCell) {
      return const TableContext();
    }
    final row = blot.parent;
    final body = row?.parent;
    final table = body?.parent;
    if (row is TableRow && body is TableBody && table is TableContainer) {
      return TableContext(
        table: table,
        row: row,
        cell: blot,
        offset: offset,
      );
    }
    return const TableContext();
  }
}

/// Public result returned by [Table.getTable].
class TableContext {
  const TableContext({
    this.table,
    this.row,
    this.cell,
    this.offset = -1,
  });

  final TableContainer? table;
  final TableRow? row;
  final TableCell? cell;
  final int offset;
}
