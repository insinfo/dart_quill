/// Port of `quill-table-better/src/ui/toolbar-table.ts` (v1.2.3) — the
/// `ql-table-better` toolbar button's 10×10 insertion grid, plus the
/// `ToolbarTable` blot registered under `formats/table-better`.
library;

import '../../blots/abstract/blot.dart';
import '../../blots/inline.dart';
import '../../platform/dom.dart';
import '../../platform/platform.dart';
import '../assets/icons.dart';
import '../utils/utils.dart' as utils;

/// TS `const SUM = 10` — the grid is 10×10.
const int kTableSelectSum = 10;

/// TS `class ToolbarTable extends Inline`.
///
/// The blot itself carries no behaviour upstream either; it exists so
/// `formats/table-better` resolves and the toolbar renders a `ql-table-better`
/// button.
class ToolbarTable extends InlineBlot {
  ToolbarTable(DomElement domNode) : super(domNode);

  static const String kBlotName = 'table-better';
  static const String kTagName = 'SPAN';
  static const int kScope = Scope.INLINE_BLOT;

  static ToolbarTable create([dynamic value]) {
    if (value is DomElement) return ToolbarTable(value);
    return ToolbarTable(domBindings.adapter.document.createElement(kTagName));
  }

  static RegistryEntry get registryEntry => RegistryEntry(
        blotName: kBlotName,
        scope: kScope,
        tagNames: const [kTagName],
        create: create,
      );

  @override
  String get blotName => kBlotName;

  @override
  int get scope => kScope;

  @override
  ToolbarTable clone() => ToolbarTable(element.cloneNode(deep: false));
}

/// TS `class TableSelect` — the hoverable 10×10 grid with an `N x M` label.
class TableSelect {
  TableSelect({DomDocument? document})
      : _document = document ?? domBindings.adapter.document {
    root = createContainer();
  }

  final DomDocument _document;

  /// TS `this.root`.
  late final DomElement root;

  /// TS `this.computeChildren` — the highlighted cells of the current hover.
  List<DomElement> computeChildren = const [];

  final List<DomElement> _cells = [];
  late final DomElement _label;

  /// Every grid cell, row-major (TS reads them off `list.children`).
  List<DomElement> get cells => List.unmodifiable(_cells);

  /// TS `createContainer()`.
  DomElement createContainer() {
    final container = _document.createElement('div');
    final list = _document.createElement('div');
    final label = _document.createElement('div');
    for (var row = 1; row <= kTableSelectSum; row++) {
      for (var column = 1; column <= kTableSelectSum; column++) {
        final child = _document.createElement('span');
        child.setAttribute('row', '$row');
        child.setAttribute('column', '$column');
        _cells.add(child);
        list.append(child);
      }
    }
    label.text = '0 x 0';
    container.classes.add('ql-table-select-container');
    container.classes.add('ql-hidden');
    list.classes.add('ql-table-select-list');
    label.classes.add('ql-table-select-label');
    container.append(list);
    container.append(label);
    _label = label;
    container.addEventListener('mousemove', (event) => handleMouseMove(event));
    return container;
  }

  /// TS `getSelectAttrs(element)` — `[row, column]`.
  (int row, int column) getSelectAttrs(DomElement element) {
    final row = int.tryParse(element.getAttribute('row') ?? '') ?? 0;
    final column = int.tryParse(element.getAttribute('column') ?? '') ?? 0;
    return (row, column);
  }

  /// TS `setLabelContent(label, child)`.
  void setLabelContent(DomElement? child) {
    if (child == null) {
      _label.text = '0 x 0';
      return;
    }
    final (row, column) = getSelectAttrs(child);
    _label.text = '$row x $column';
  }

  /// TS `clearSelected(children)`.
  void clearSelected([List<DomElement>? children]) {
    for (final child in children ?? computeChildren) {
      child.classes.remove('ql-cell-selected');
    }
    computeChildren = const [];
    setLabelContent(null);
  }

  /// TS `getComputeChildren(children, e)` — every cell whose top-left corner is
  /// above and left of the pointer.
  List<DomElement> getComputeChildren(num clientX, num clientY) {
    final result = <DomElement>[];
    for (final child in _cells) {
      final bounds = utils.getCorrectBounds(child);
      if (clientX >= bounds.left && clientY >= bounds.top) {
        result.add(child);
      }
    }
    return result;
  }

  /// TS `handleMouseMove(e, container)`.
  void handleMouseMove(DomEvent event) {
    final raw = event.rawEvent as dynamic;
    num? clientX;
    num? clientY;
    try {
      clientX = raw?.clientX as num?;
      clientY = raw?.clientY as num?;
    } catch (_) {
      // Pointer coordinates are unavailable off-browser.
    }
    if (clientX == null || clientY == null) return;
    highlightAll(getComputeChildren(clientX, clientY));
  }

  /// Highlights the rectangle ending at (row, column).
  ///
  /// Deviation: the TS derives the rectangle from pointer coordinates, which do
  /// not exist without layout. Off-browser callers (and the tests) drive the
  /// same state transition through the logical coordinates instead — the
  /// resulting `computeChildren` is identical.
  void highlightTo(int row, int column) {
    final selected = <DomElement>[];
    for (final child in _cells) {
      final (childRow, childColumn) = getSelectAttrs(child);
      if (childRow <= row && childColumn <= column) selected.add(child);
    }
    highlightAll(selected);
  }

  void highlightAll(List<DomElement> selected) {
    clearSelected(computeChildren);
    for (final child in selected) {
      child.classes.add('ql-cell-selected');
    }
    computeChildren = selected;
    setLabelContent(selected.isEmpty ? null : selected.last);
  }

  /// TS `getClickInfo(e)` — `(isBetweenSpans, span)`. A click that lands inside
  /// the container but not on a cell falls back to the last hovered cell.
  (bool isBetweenSpans, DomElement? span) getClickInfo(DomNode? target) {
    DomElement? span;
    var insideContainer = false;
    DomNode? node = target;
    while (node != null) {
      if (node is DomElement) {
        if (span == null && node.hasAttribute('row')) span = node;
        if (node.classes.contains('ql-table-select-container')) {
          insideContainer = true;
          break;
        }
      }
      node = node.parentNode;
    }
    if (insideContainer && span == null) return (true, null);
    return (false, span);
  }

  /// TS `handleClick(e, insertTable)`.
  void handleClick(
      DomNode? target, void Function(int rows, int columns) insert) {
    final (isBetweenSpans, span) = getClickInfo(target);
    toggle(isBetweenSpans);
    if (span == null) {
      final child = computeChildren.isEmpty ? null : computeChildren.last;
      if (child != null) insertTable(child, insert);
      return;
    }
    insertTable(span, insert);
  }

  /// TS `insertTable(child, insertTable)`.
  void insertTable(
      DomElement child, void Function(int rows, int columns) insert) {
    final (row, column) = getSelectAttrs(child);
    insert(row, column);
    hide();
  }

  /// TS `hide(element)`.
  void hide() {
    clearSelected(computeChildren);
    root.classes.add('ql-hidden');
  }

  /// TS `show(element)`.
  void show() {
    clearSelected(computeChildren);
    root.classes.remove('ql-hidden');
  }

  /// TS `toggle(element, isBetweenSpans)`.
  void toggle(bool isBetweenSpans) {
    if (!isBetweenSpans) clearSelected(computeChildren);
    root.classes.toggle('ql-hidden');
  }

  bool get isHidden => root.classes.contains('ql-hidden');
}

/// TS `icons['table-better'] = tableIcon` (toolbar-table.ts:8-10).
String get toolbarTableIcon => tableBetterIcons['table']!;
