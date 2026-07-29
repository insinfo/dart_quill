/// Port of `quill-table-better/src/ui/operate-line.ts` (v1.2.3) — the resize
/// overlay: a hairline that follows the cell edge under the pointer, and a
/// corner block that resizes the whole table.
///
/// Faithful in DOM shape (`.ql-operate-line-container` > `.ql-operate-line`,
/// `.ql-operate-block`, `.ql-operate-drag-table`), in the 5px hit tolerance
/// and in where the result is persisted: `width`/`height` **attributes** on
/// the cells (plus the matching inline style), the column widths on `<col>`
/// when a colgroup exists, and the table width through `updateTableWidth`.
/// The previous port invented `data-width`/`data-height` attributes and an
/// index-based API; both are gone.
library;

import 'dart:math' as math;

import '../../core/emitter.dart';
import '../../core/quill.dart';
import '../../platform/dom.dart';
import '../formats/table.dart';
import '../utils/utils.dart' as utils;

/// TS `DRAG_BLOCK_HEIGHT` / `DRAG_BLOCK_WIDTH`.
const double kDragBlockHeight = 8;
const double kDragBlockWidth = 8;

/// TS `LINE_CONTAINER_HEIGHT` / `LINE_CONTAINER_WIDTH`.
const double kLineContainerHeight = 5;
const double kLineContainerWidth = 5;

/// TS hit tolerance for "the pointer is on a cell edge".
const double kOperateLineTolerance = 5;

/// TS `interface Options`.
class OperateLineOptions {
  const OperateLineOptions({
    required this.tableNode,
    required this.cellNode,
    required this.clientX,
    required this.clientY,
  });

  final DomElement tableNode;
  final DomElement cellNode;
  final num clientX;
  final num clientY;
}

/// TS `getProperty` result.
class _OperateLineProperties {
  const _OperateLineProperties({
    required this.dragBlockProps,
    this.containerProps,
    this.lineProps,
  });

  final Map<String, String> dragBlockProps;
  final Map<String, String>? containerProps;
  final Map<String, String>? lineProps;
}

/// TS `class OperateLine`.
class OperateLine {
  OperateLine({
    required this.quill,
    required this.resolveTable,
    this.onResized,
  }) {
    _mousemoveListener = handleMouseMove;
    quill.root.addEventListener('mousemove', _mousemoveListener);
  }

  final Quill quill;

  /// Resolves the [TableContainer] blot behind a `<table>` element.
  final TableContainer? Function(DomElement table) resolveTable;

  /// TS ends every drag with `tableMenus.updateMenus(tableNode)`.
  final void Function(DomElement tableNode)? onResized;

  late final DomEventListener _mousemoveListener;

  OperateLineOptions? options;
  bool drag = false;
  DomElement? line;
  DomElement? dragBlock;
  DomElement? dragTable;

  /// TS `this.direction` — `'level'` (column) or `'vertical'` (row).
  String? direction;

  DomDocument get _document => quill.root.ownerDocument;

  void destroy() {
    quill.root.removeEventListener('mousemove', _mousemoveListener);
    line?.remove();
    dragBlock?.remove();
    dragTable?.remove();
    line = null;
    dragBlock = null;
    dragTable = null;
  }

  // --- overlay ------------------------------------------------------------

  /// TS `createOperateLine()`.
  void createOperateLine() {
    final container = _document.createElement('div');
    final inner = _document.createElement('div');
    container.classes.add('ql-operate-line-container');
    final properties = getProperty(options!);
    if (properties.containerProps != null) {
      utils.setElementProperty(container, properties.containerProps!);
    }
    if (properties.lineProps != null) {
      utils.setElementProperty(inner, properties.lineProps!);
    }
    container.append(inner);
    quill.container.append(container);
    line = container;
    updateCell(container);
  }

  /// TS `createDragBlock()`.
  void createDragBlock() {
    final block = _document.createElement('div');
    block.classes.add('ql-operate-block');
    utils.setElementProperty(block, getProperty(options!).dragBlockProps);
    dragBlock = block;
    quill.container.append(block);
    updateCell(block);
  }

  /// TS `updateCell(node)` (operate-line.ts:361-422) — the drag wiring: a
  /// mousedown on the overlay arms document-level drag/mouseup listeners, and
  /// the mouseup persists the resize through [setCellRect] / [setCellsRect].
  void updateCell(DomElement? node) {
    if (node == null) return;
    final nodeIsLine = isLine(node);

    void handleDrag(DomEvent e) {
      e.preventDefault();
      if (!drag) return;
      final clientX = e is DomMouseEvent ? e.clientX : 0;
      final clientY = e is DomMouseEvent ? e.clientY : 0;
      if (nodeIsLine) {
        updateDragLine(clientX, clientY);
        hideDragBlock();
      } else {
        updateDragBlock(clientX, clientY);
        hideLine();
      }
    }

    void handleMouseup(DomEvent e) {
      e.preventDefault();
      final current = options;
      if (current == null) return;
      final clientX = e is DomMouseEvent ? e.clientX : 0;
      final clientY = e is DomMouseEvent ? e.clientY : 0;
      if (nodeIsLine) {
        setCellRect(current.cellNode, clientX, clientY);
        toggleLineChildClass(false);
      } else {
        final tableBounds = utils.elementRectResolver(current.tableNode);
        setCellsRect(current.cellNode, clientX - tableBounds.right,
            clientY - tableBounds.bottom);
        dragBlock?.classes.remove('ql-operate-block-move');
        hideDragBlock();
        hideDragTable();
      }
      drag = false;
      _document.removeEventListener('mousemove', handleDrag);
      _document.removeEventListener('mouseup', handleMouseup);
    }

    void handleMousedown(DomEvent e) {
      e.preventDefault();
      final current = options;
      if (current == null) return;
      if (nodeIsLine) {
        toggleLineChildClass(true);
      } else {
        if (dragTable != null) {
          utils.setElementProperty(
              dragTable!, getDragTableProperty(current.tableNode));
        } else {
          createDragTable(current.tableNode);
        }
      }
      drag = true;
      _document.addEventListener('mousemove', handleDrag);
      _document.addEventListener('mouseup', handleMouseup);
    }

    node.addEventListener('mousedown', handleMousedown);
  }

  /// TS `createDragTable(table)`.
  void createDragTable(DomElement table) {
    final element = _document.createElement('div');
    element.classes.add('ql-operate-drag-table');
    utils.setElementProperty(element, getDragTableProperty(table));
    dragTable = element;
    quill.container.append(element);
  }

  /// TS `getDragTableProperty(table)`.
  Map<String, String> getDragTableProperty(DomElement table) {
    final bounds = utils.getCorrectBounds(table, quill.container);
    return {
      'left': '${utils.formatNum(bounds.left)}px',
      'top': '${utils.formatNum(bounds.top)}px',
      'width': '${utils.formatNum(bounds.width)}px',
      'height': '${utils.formatNum(bounds.height)}px',
      'display': 'block',
    };
  }

  /// TS `getProperty(options)` — decides the direction from the pointer's
  /// distance to the cell's right/bottom edge.
  _OperateLineProperties getProperty(OperateLineOptions options) {
    final containerBounds = utils.getCorrectBounds(quill.container);
    final tableBounds =
        utils.getCorrectBounds(options.tableNode, quill.container);
    final cellBounds =
        utils.getCorrectBounds(options.cellNode, quill.container);
    final x = cellBounds.left + cellBounds.width;
    final y = cellBounds.top + cellBounds.height;
    final dragBlockProps = {
      'width': '${utils.formatNum(kDragBlockWidth)}px',
      'height': '${utils.formatNum(kDragBlockHeight)}px',
      'top': '${utils.formatNum(tableBounds.bottom)}px',
      'left': '${utils.formatNum(tableBounds.right)}px',
      'display': tableBounds.bottom > containerBounds.bottom ? 'none' : 'block',
    };

    if ((x - options.clientX).abs() <= kOperateLineTolerance) {
      direction = 'level';
      return _OperateLineProperties(
        dragBlockProps: dragBlockProps,
        containerProps: {
          'width': '${utils.formatNum(kLineContainerWidth)}px',
          'height': '${utils.formatNum(containerBounds.height)}px',
          'top': '0',
          'left': '${utils.formatNum(x - kLineContainerWidth / 2)}px',
          'display': 'flex',
          'cursor': 'col-resize',
        },
        lineProps: const {'width': '1px', 'height': '100%'},
      );
    }
    if ((y - options.clientY).abs() <= kOperateLineTolerance) {
      direction = 'vertical';
      return _OperateLineProperties(
        dragBlockProps: dragBlockProps,
        containerProps: {
          'width': '${utils.formatNum(containerBounds.width)}px',
          'height': '${utils.formatNum(kLineContainerHeight)}px',
          'top': '${utils.formatNum(y - kLineContainerHeight / 2)}px',
          'left': '0',
          'display': 'flex',
          'cursor': 'row-resize',
        },
        lineProps: const {'width': '100%', 'height': '1px'},
      );
    }
    hideLine();
    return _OperateLineProperties(dragBlockProps: dragBlockProps);
  }

  /// TS `handleMouseMove(e)`.
  void handleMouseMove(DomEvent event) {
    if (!quill.isEnabled()) return;
    final tableNode = _closest(event.target, const {'TABLE'});
    if (tableNode != null && !_containedByRoot(tableNode)) return;
    final cellNode = _closest(event.target, const {'TD', 'TH'});
    if (tableNode == null || cellNode == null) {
      if (line != null && !drag) {
        hideLine();
        hideDragBlock();
      }
      return;
    }
    final clientX = event is DomMouseEvent ? event.clientX : 0;
    final clientY = event is DomMouseEvent ? event.clientY : 0;
    final next = OperateLineOptions(
      tableNode: tableNode,
      cellNode: cellNode,
      clientX: clientX,
      clientY: clientY,
    );
    if (line == null) {
      options = next;
      createOperateLine();
      createDragBlock();
      return;
    }
    if (drag) return;
    updateProperty(next);
  }

  /// TS `updateProperty(options)`.
  void updateProperty(OperateLineOptions next) {
    final properties = getProperty(next);
    if (properties.containerProps == null || properties.lineProps == null) {
      return;
    }
    options = next;
    final container = line;
    if (container == null) return;
    utils.setElementProperty(container, properties.containerProps!);
    final inner = container.firstChild;
    if (inner is DomElement) {
      utils.setElementProperty(inner, properties.lineProps!);
    }
    final block = dragBlock;
    if (block != null) {
      utils.setElementProperty(block, properties.dragBlockProps);
    }
  }

  /// TS `hideLine()`.
  void hideLine() {
    final element = line;
    if (element != null) {
      utils.setElementProperty(element, const {'display': 'none'});
    }
  }

  /// TS `hideDragBlock()`.
  void hideDragBlock() {
    final element = dragBlock;
    if (element != null) {
      utils.setElementProperty(element, const {'display': 'none'});
    }
  }

  /// TS `hideDragTable()`.
  void hideDragTable() {
    final element = dragTable;
    if (element != null) {
      utils.setElementProperty(element, const {'display': 'none'});
    }
  }

  /// TS `isLine(node)`.
  bool isLine(DomElement node) =>
      node.classes.contains('ql-operate-line-container');

  /// TS `toggleLineChildClass(isAdd)`.
  void toggleLineChildClass(bool isAdd) {
    final inner = line?.firstChild;
    if (inner is! DomElement) return;
    if (isAdd) {
      inner.classes.add('ql-operate-line');
    } else {
      inner.classes.remove('ql-operate-line');
    }
  }

  /// TS `updateDragLine(clientX, clientY)`.
  void updateDragLine(num clientX, num clientY) {
    final element = line;
    if (element == null) return;
    final bounds = utils.getCorrectBounds(quill.container);
    if (direction == 'level') {
      utils.setElementProperty(element, {
        'left':
            '${utils.formatNum(clientX - bounds.left - kLineContainerWidth / 2)}px',
      });
    } else if (direction == 'vertical') {
      utils.setElementProperty(element, {
        'top':
            '${utils.formatNum(clientY - bounds.top - kLineContainerHeight / 2)}px',
      });
    }
  }

  /// TS `updateDragBlock(clientX, clientY)`.
  void updateDragBlock(num clientX, num clientY) {
    final block = dragBlock;
    if (block == null) return;
    final bounds = utils.getCorrectBounds(quill.container);
    block.classes.add('ql-operate-block-move');
    utils.setElementProperty(block, {
      'top':
          '${utils.formatNum(clientY - bounds.top - kDragBlockHeight / 2)}px',
      'left':
          '${utils.formatNum(clientX - bounds.left - kDragBlockWidth / 2)}px',
    });
    updateDragTable(clientX, clientY);
  }

  /// TS `updateDragTable(clientX, clientY)`.
  void updateDragTable(num clientX, num clientY) {
    final element = dragTable;
    if (element == null) return;
    final bounds = utils.getCorrectBounds(element, quill.container);
    utils.setElementProperty(element, {
      'width': '${utils.formatNum(clientX - bounds.left)}px',
      'height': '${utils.formatNum(clientY - bounds.top)}px',
      'display': 'block',
    });
  }

  // --- persistence --------------------------------------------------------

  /// TS `getLevelColSum(cell)` — 1-based column index of the cell's right edge.
  int getLevelColSum(DomElement cell) {
    DomElement? node = cell;
    var sum = 0;
    while (node != null) {
      sum += _span(node, 'colspan');
      node = _previousElement(node);
    }
    return sum;
  }

  /// TS `getMaxColNum(cell)`.
  int getMaxColNum(DomElement cell) {
    final row = _parentElement(cell);
    if (row == null) return 0;
    var total = 0;
    for (final child in _childElements(row)) {
      total += _span(child, 'colspan');
    }
    return total;
  }

  /// TS `getCorrectCol(colgroup, sum)` — the `sum`-th `<col>` (1-based).
  TableCol? getCorrectCol(TableColgroup colgroup, int sum) {
    final cols = colgroup.children.whereType<TableCol>().toList();
    final index = sum - 1;
    if (index < 0 || index >= cols.length) return null;
    return cols[index];
  }

  /// TS `setColWidth(domNode, width, isPercent)`.
  void setColWidth(DomElement node, double width, bool isPercent) {
    if (isPercent) {
      utils.setElementProperty(
          node, {'width': utils.getCorrectWidth(width, true)});
    } else {
      utils.setElementAttribute(node, {'width': utils.formatNum(width)});
    }
  }

  /// TS `setCellRect(cell, clientX, clientY)`.
  void setCellRect(DomElement cell, num clientX, num clientY) {
    if (direction == 'level') {
      setCellLevelRect(cell, clientX);
    } else if (direction == 'vertical') {
      setCellVerticalRect(cell, clientY);
    }
  }

  /// TS `setCellLevelRect(cell, clientX)` — a column resize.
  void setCellLevelRect(DomElement cell, num clientX) {
    final blot = _cellBlot(cell);
    final tableBlot = blot?.table();
    if (tableBlot == null) return;
    final bounds = utils.getCorrectBounds(cell, quill.container);
    final change = (clientX - bounds.right).truncateToDouble();
    final colSum = getLevelColSum(cell);
    final isPercent = tableBlot.isPercent();
    final colgroup = tableBlot.colgroup();
    final tableBounds =
        utils.getCorrectBounds(tableBlot.element, quill.container);

    if (colgroup != null) {
      final col = getCorrectCol(colgroup, colSum);
      if (col != null) {
        final width =
            utils.getCorrectBounds(col.element, quill.container).width;
        setColWidth(col.element, width + change, isPercent);
        final next = col.next;
        if (next is TableCol) {
          final nextWidth =
              utils.getCorrectBounds(next.element, quill.container).width;
          setColWidth(next.element, nextWidth - change, isPercent);
        }
      }
    } else {
      final row = _parentElement(cell);
      final body = row == null ? null : _parentElement(row);
      if (body != null) {
        final isLastCell = _nextElement(cell) == null;
        final changes = <MapEntry<DomElement, double>>[];
        for (final currentRow in _childElements(body)) {
          final cells = _childElements(currentRow);
          if (cells.isEmpty) continue;
          if (isLastCell) {
            final last = cells.last;
            final width = utils.getCorrectBounds(last, quill.container).width;
            changes.add(MapEntry(last, (width + change).truncateToDouble()));
            continue;
          }
          var sum = 0;
          for (final current in cells) {
            sum += _span(current, 'colspan');
            if (sum > colSum) break;
            if (sum == colSum) {
              final next = _nextElement(current);
              if (next == null) continue;
              final width =
                  utils.getCorrectBounds(current, quill.container).width;
              final nextWidth =
                  utils.getCorrectBounds(next, quill.container).width;
              changes
                  .add(MapEntry(current, (width + change).truncateToDouble()));
              changes
                  .add(MapEntry(next, (nextWidth - change).truncateToDouble()));
            }
          }
        }
        for (final entry in changes) {
          final correctWidth = utils.getCorrectWidth(entry.value, isPercent);
          utils.setElementAttribute(entry.key, {'width': correctWidth});
          utils.setElementProperty(entry.key, {'width': correctWidth});
        }
      }
    }

    if (_nextElement(cell) == null) {
      utils.updateTableWidth(tableBlot, tableBounds, change);
    }
    _finishResize(tableBlot.element);
  }

  /// TS `setCellVerticalRect(cell, clientY)` — a row resize.
  void setCellVerticalRect(DomElement cell, num clientY) {
    final rowspan = _span(cell, 'rowspan');
    final cells = rowspan > 1
        ? getVerticalCells(cell, rowspan)
        : _childElements(_parentElement(cell));
    for (final current in cells) {
      final top = utils.getCorrectBounds(current, quill.container).top;
      final height = (clientY - top).truncate();
      utils.setElementAttribute(current, {'height': '$height'});
      utils.setElementProperty(current, {'height': '${height}px'});
    }
    final tableBlot = _cellBlot(cell)?.table();
    if (tableBlot != null) _finishResize(tableBlot.element);
  }

  /// TS `getVerticalCells(cell, rowspan)` — the cells of the row the merged
  /// cell's bottom edge actually lands on.
  List<DomElement> getVerticalCells(DomElement cell, int rowspan) {
    var row = _parentElement(cell);
    var remaining = rowspan;
    while (remaining > 1 && row != null) {
      row = _nextElement(row);
      remaining--;
    }
    return _childElements(row);
  }

  /// TS `setCellsRect(cell, changeX, changeY)` — the corner block drag, which
  /// spreads the delta over every column and row.
  void setCellsRect(DomElement cell, num changeX, num changeY) {
    final row = _parentElement(cell);
    final body = row == null ? null : _parentElement(row);
    if (body == null) return;
    final rows = _childElements(body);
    if (rows.isEmpty) return;
    final maxColNum = getMaxColNum(cell);
    if (maxColNum == 0) return;
    final averageX = changeX / maxColNum;
    final averageY = changeY / rows.length;

    final tableBlot = _cellBlot(cell)?.table();
    if (tableBlot == null) return;
    final isPercent = tableBlot.isPercent();
    final colgroup = tableBlot.colgroup();
    final tableBounds =
        utils.getCorrectBounds(tableBlot.element, quill.container);

    final changes = <(DomElement, double, double)>[];
    for (final currentRow in rows) {
      for (final current in _childElements(currentRow)) {
        final colspan = _span(current, 'colspan');
        final bounds = utils.getCorrectBounds(current, quill.container);
        changes.add((
          current,
          (bounds.width + averageX * colspan).ceilToDouble(),
          (bounds.height + averageY).ceilToDouble(),
        ));
      }
    }

    if (colgroup != null) {
      for (final (node, _, height) in changes) {
        utils.setElementAttribute(node, {'height': utils.formatNum(height)});
        utils.setElementProperty(
            node, {'height': '${utils.formatNum(height)}px'});
      }
      for (final col in colgroup.children.whereType<TableCol>()) {
        final width =
            utils.getCorrectBounds(col.element, quill.container).width;
        setColWidth(col.element, (width + averageX).ceilToDouble(), isPercent);
      }
    } else {
      for (final (node, width, height) in changes) {
        final correctWidth = utils.getCorrectWidth(width, isPercent);
        utils.setElementAttribute(node, {
          'height': utils.formatNum(height),
          'width': correctWidth,
        });
        utils.setElementProperty(node, {
          'height': '${utils.formatNum(height)}px',
          'width': correctWidth,
        });
      }
    }
    utils.updateTableWidth(tableBlot, tableBounds, changeX.toDouble());
    _finishResize(tableBlot.element);
  }

  /// Ends a resize the way TS `handleMouseup` does: refresh the menus and
  /// resynchronise the model, because the attribute writes above bypass the
  /// delta pipeline and would otherwise leave `getContents()` stale.
  void _finishResize(DomElement tableNode) {
    onResized?.call(tableNode);
    quill.update(EmitterSource.USER);
  }

  // --- helpers ------------------------------------------------------------

  bool _containedByRoot(DomNode node) {
    DomNode? current = node;
    while (current != null) {
      if (current == quill.root) return true;
      current = current.parentNode;
    }
    return false;
  }

  DomElement? _closest(DomNode? target, Set<String> tagNames) {
    DomNode? node = target;
    while (node != null) {
      if (node is DomElement && tagNames.contains(node.tagName.toUpperCase())) {
        return node;
      }
      node = node.parentNode;
    }
    return null;
  }

  TableCell? _cellBlot(DomElement cell) {
    DomNode? node = cell;
    while (node != null) {
      if (node is DomElement && node.tagName.toUpperCase() == 'TABLE') {
        final table = resolveTable(node);
        if (table == null) return null;
        for (final blot in table.descendants<TableCell>()) {
          if (blot.element == cell) return blot;
        }
        return null;
      }
      node = node.parentNode;
    }
    return null;
  }

  int _span(DomElement node, String name) {
    final value = int.tryParse(node.getAttribute(name) ?? '') ?? 1;
    return math.max(1, value);
  }

  DomElement? _parentElement(DomNode? node) {
    final parent = node?.parentNode;
    return parent is DomElement ? parent : null;
  }

  DomElement? _nextElement(DomNode node) {
    var sibling = node.nextSibling;
    while (sibling != null && sibling is! DomElement) {
      sibling = sibling.nextSibling;
    }
    return sibling as DomElement?;
  }

  DomElement? _previousElement(DomNode node) {
    var sibling = node.previousSibling;
    while (sibling != null && sibling is! DomElement) {
      sibling = sibling.previousSibling;
    }
    return sibling as DomElement?;
  }

  List<DomElement> _childElements(DomElement? node) {
    if (node == null) return const [];
    return node.childNodes.whereType<DomElement>().toList(growable: false);
  }
}
