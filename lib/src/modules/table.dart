import '../blots/abstract/blot.dart';
import '../blots/block.dart';
import '../blots/break.dart';
import '../core/emitter.dart';
import '../core/module.dart';
import '../core/quill.dart';
import '../core/selection.dart';
import '../dependencies/dart_quill_delta/dart_quill_delta.dart';
import '../formats/table.dart';
import '../platform/dom.dart';
import '../platform/platform.dart';

class TableOptions {
  const TableOptions();

  factory TableOptions.fromConfig(dynamic _) {
    return const TableOptions();
  }
}

class Table extends Module<TableOptions> {
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
        'display:none;position:absolute;z-index:1100;padding:4px;gap:2px;'
        'background:#fff;border:1px solid #bbb;border-radius:4px;'
        'box-shadow:0 3px 10px rgba(0,0,0,.18);';
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
    for (final action in actions) {
      final button = quill.container.ownerDocument.createElement('button');
      button
        ..setAttribute('type', 'button')
        ..setAttribute('title', action.$2)
        ..setAttribute('aria-label', action.$2)
        ..setAttribute('data-table-action', action.$3)
        ..style.cssText = _contextButtonStyle
        ..innerHTML = '<i class="ti ti-${action.$1}" aria-hidden="true"></i>';
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
        (dynamic _range, dynamic _oldRange, dynamic _source) {
      updateContextToolbar();
    });
  }

  static const String _contextButtonStyle =
      'appearance:none;-webkit-appearance:none;width:28px;height:28px;'
      'min-width:28px;min-height:28px;margin:0;padding:3px;border:0;'
      'border-radius:2px;background:transparent;box-shadow:none;outline:none;'
      'display:inline-flex;align-items:center;justify-content:center;'
      'color:#444;font-size:18px;line-height:1;cursor:pointer;';

  void updateContextToolbar() {
    final context = _getTable(quill.selection.getRange());
    final cell = _activeCell ?? context.cell;
    final cellElement = _activeCellElement ?? cell?.element;
    if (cellElement == null) {
      return;
    }
    final bounds = domBindings.adapter
        .getElementBounds(cellElement, relativeTo: quill.container);
    if (bounds == null) {
      _contextToolbar.style.display = 'none';
      return;
    }
    final top =
        ((bounds['top'] as num).toDouble() - 38).clamp(0, double.infinity);
    _contextToolbar.style
      ..display = 'flex'
      ..left = '${bounds['left']}px'
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
    final context = _getTable();
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
    final context = _getTable();
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
    final context = _getTable();
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
    final cell = _activeCell ?? _getTable(quill.selection.getRange()).cell;
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
    final cell = _activeCell ?? _getTable(quill.selection.getRange()).cell;
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
    _insertColumn(0);
  }

  void insertColumnRight() {
    _insertColumn(1);
  }

  void insertRowAbove() {
    _insertRow(0);
  }

  void insertRowBelow() {
    _insertRow(1);
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

  void _insertColumn(int offset) {
    final range = quill.getSelection();
    if (range == null) {
      return;
    }
    final context = _getTable(range);
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

  void _insertRow(int offset) {
    final range = quill.getSelection();
    if (range == null) {
      return;
    }
    final context = _getTable(range);
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

  _TableContext _getTable([Range? range]) {
    _ensureTableStructure();
    final targetRange = range ?? quill.getSelection();
    if (targetRange == null) {
      return const _TableContext();
    }
    final entry = quill.scroll.descendant(
      (blot) => blot is TableCell,
      targetRange.index,
    );
    final blot = entry.key;
    final offset = entry.value;
    if (blot is! TableCell) {
      return _TableContext(offset: offset);
    }
    final row = blot.parent;
    final body = row?.parent;
    final table = body?.parent;
    if (row is TableRow && body is TableBody && table is TableContainer) {
      return _TableContext(
        table: table,
        row: row,
        cell: blot,
        offset: offset,
      );
    }
    return _TableContext(offset: offset);
  }
}

class _TableContext {
  const _TableContext({
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
