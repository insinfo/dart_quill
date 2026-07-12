/// Port of quill-table-better `src/formats/table.ts` (v1.2.3).
///
/// Contains the 12 structural blots (TableCellBlock, TableThBlock, TableCell,
/// TableTh, TableRow, TableThRow, TableBody, TableThead, TableTemporary,
/// TableContainer, TableCol, TableColgroup) plus the `cellId()`/`tableId()`
/// helpers, adapted to this repo's vendored parchment layer
/// (`lib/src/blots/abstract/blot.dart`).
///
/// Parchment features the Dart layer lacks are approximated:
/// * `checkMerge()` + container merging: parchment's `ContainerBlot.optimize`
///   merges a container into its identically named next sibling; this is
///   reproduced in [TableBetterContainer.optimize].
/// * `allowedChildren` / `requiredContainer` enforcement: not implemented.
///   TODO(table-better): approximate structural enforcement in optimize()
///   like `lib/src/formats/table.dart` does, once the module phase needs it.
/// * `wrap` / `replaceWith` / `splitAfter`: implemented locally
///   ([wrapBlot], [replaceBlotWith], [TableBetterContainer.splitAfter]).
import 'dart:math' as math;

import '../../blots/abstract/blot.dart';
import '../../blots/block.dart';
import '../../blots/container.dart';
import '../../platform/dom.dart';
import '../../platform/platform.dart';
import '../config/config.dart';
import '../utils/utils.dart' as utils;

/// TS `TABLE_ATTRIBUTE`.
const List<String> tableAttribute = ['border', 'cellspacing', 'style', 'data-class'];

/// TS `STYLE_RULES`.
const List<String> styleRules = ['color', 'border', 'width', 'height'];

/// TS `COL_ATTRIBUTE`.
const List<String> colAttribute = ['width'];

final math.Random _random = math.Random();

String _randomId() =>
    _random.nextInt(36 * 36 * 36 * 36).toRadixString(36).padLeft(4, '0');

/// TS `cellId()`.
String cellId() => 'cell-${_randomId()}';

/// TS `tableId()`.
String tableId() => 'row-${_randomId()}';

int _toInt(String? value) => int.tryParse(value ?? '') ?? 0;

DomElement _createElement(String tagName) =>
    domBindings.adapter.document.createElement(tagName);

DomElement? _parentElement(DomNode? node) {
  final parent = node?.parentNode;
  return parent is DomElement ? parent : null;
}

DomElement? _nextElementSibling(DomNode? node) {
  var sibling = node?.nextSibling;
  while (sibling != null && sibling is! DomElement) {
    sibling = sibling.nextSibling;
  }
  return sibling as DomElement?;
}

DomElement? _previousElementSibling(DomNode? node) {
  var sibling = node?.previousSibling;
  while (sibling != null && sibling is! DomElement) {
    sibling = sibling.previousSibling;
  }
  return sibling as DomElement?;
}

/// Serializes an element to HTML (the platform abstraction has no
/// `outerHTML`; the element is deep-cloned into a temp wrapper).
String outerHtml(DomElement element) {
  final wrapper = _createElement('DIV');
  wrapper.append(element.cloneNode(deep: true));
  return wrapper.innerHTML ?? '';
}

/// Local equivalent of parchment's `ShadowBlot.wrap(name, value)`.
ParentBlot wrapBlot(Blot blot, String name, [dynamic value]) {
  final wrapper = blot.scroll.create(name, value) as ParentBlot;
  final parent = blot.parent;
  if (parent != null) {
    parent.insertBefore(wrapper, blot.next);
  }
  wrapper.appendChild(blot);
  return wrapper;
}

/// Local equivalent of parchment's `ShadowBlot.replaceWith(name, value)`:
/// creates the replacement, moves the children over and removes the target.
Blot replaceBlotWith(Blot target, String name, dynamic value) {
  final replacement = target.scroll.create(name, value);
  final parent = target.parent;
  if (parent != null) {
    parent.insertBefore(replacement, target.next);
  }
  if (target is ParentBlot && replacement is ParentBlot) {
    target.moveChildren(replacement, null);
  }
  target.remove();
  return replacement;
}

void _setClassAttribute(DomElement node, String className) {
  for (final token in className.split(RegExp(r'\s+'))) {
    if (token.isNotEmpty) {
      node.classes.add(token);
    }
  }
  node.setAttribute('class', className);
}

/// Parchment's `requiredContainer` enforcement (shadow.ts `optimize` +
/// the assignments in table.ts:851-872): when [blot]'s parent does not
/// [satisfied] the constraint, the blot is wrapped in a new [wrapperName].
///
/// Deviation: parchment converges through its mutation-driven optimize loop;
/// the Dart [Scroll.optimize] is a single pass, so convergence is local —
/// a blot whose *previous sibling* already is a suitable container joins it
/// instead of spawning a duplicate, and the adopting side re-optimizes so
/// sibling merges (`checkMerge`) still collapse split rows/bodies.
///
/// Returns true when the tree was restructured (callers should stop their
/// own optimize pass; the re-entrant optimize already finished the job).
bool _enforceRequiredContainer(
  Blot blot,
  String wrapperName,
  bool Function(Blot) satisfied,
  List<DomMutationRecord>? mutations,
  Map<String, dynamic>? context,
) {
  final parentBlot = blot.parent;
  if (parentBlot == null || satisfied(parentBlot)) return false;
  final prevBlot = blot.prev;
  if (prevBlot is ParentBlot && satisfied(prevBlot)) {
    prevBlot.appendChild(blot);
    final sibling = blot.prev;
    if (sibling != null) {
      sibling.optimize(mutations, context);
    } else {
      blot.optimize(mutations, context);
    }
    return true;
  }
  final wrapper = wrapBlot(blot, wrapperName);
  wrapper.optimize(mutations, context);
  return true;
}

/// Base for the table-better container blots. Reproduces the parts of
/// parchment's `ContainerBlot.optimize` that the Dart layer lacks: removal of
/// empty containers, `requiredContainer` wrapping and merging into an
/// identically named next sibling when [checkMerge] allows it.
abstract class TableBetterContainer extends Container {
  TableBetterContainer(DomElement domNode) : super(domNode);

  /// TS `requiredContainer` blot name (table.ts:851-867); null when the
  /// container has no placement constraint.
  String? get requiredContainerBlotName => null;

  /// Whether [blot] satisfies [requiredContainerBlotName] as a parent (TS
  /// uses `instanceof`, so subclasses of the required container qualify).
  bool isRequiredContainer(Blot blot) => true;

  /// Parchment's default `checkMerge`.
  bool checkMerge() {
    final nextBlot = next;
    return nextBlot != null && nextBlot.blotName == blotName;
  }

  @override
  void optimize([
    List<DomMutationRecord>? mutations,
    Map<String, dynamic>? context,
  ]) {
    super.optimize(mutations, context);
    if (children.isEmpty) {
      remove();
      return;
    }
    if (requiredContainerBlotName != null &&
        _enforceRequiredContainer(
          this,
          requiredContainerBlotName!,
          isRequiredContainer,
          mutations,
          context,
        )) {
      return;
    }
    var nextBlot = next;
    while (nextBlot is ContainerBlot &&
        nextBlot.prev == this &&
        nextBlot.element.tagName == element.tagName &&
        checkMerge()) {
      nextBlot.moveChildren(this, null);
      nextBlot.remove();
      // Adopted children may now merge with their new siblings (parchment
      // reaches the same fixpoint through its mutation loop).
      super.optimize(mutations, context);
      nextBlot = next;
    }
  }

  /// Parchment's `ContainerBlot.splitAfter(child)`.
  ParentBlot splitAfter(Blot child) {
    final after = clone() as ParentBlot;
    while (child.next != null) {
      after.appendChild(child.next!);
    }
    parent?.insertBefore(after, next);
    return after;
  }
}

/// TS `TableCellBlock` — the `<p class="ql-table-block">` line inside a cell.
class TableCellBlock extends Block {
  TableCellBlock(DomElement domNode) : super(domNode);

  static const String kBlotName = 'table-cell-block';
  static const String kClassName = 'ql-table-block';
  static const String kTagName = 'P';
  static const int kScope = Scope.BLOCK_BLOT;

  static TableCellBlock create([dynamic value]) {
    if (value is DomElement) return TableCellBlock(value);
    return TableCellBlock(createBlockNode(value, kTagName, kClassName));
  }

  /// Shared node factory for [TableCellBlock] and [TableThBlock].
  static DomElement createBlockNode(
    dynamic value,
    String tagName,
    String className,
  ) {
    final node = _createElement(tagName);
    _setClassAttribute(node, className);
    if (value is String && value.isNotEmpty) {
      node.setAttribute('data-cell', value);
    } else {
      node.setAttribute('data-cell', cellId());
    }
    return node;
  }

  @override
  String get blotName => kBlotName;

  @override
  int get scope => kScope;

  @override
  TableCellBlock clone() => TableCellBlock(element.cloneNode(deep: false));

  @override
  void format(String name, dynamic value) {
    final truthy = value != null && value != false && value != '';
    if (name == TableCell.kBlotName && truthy) {
      wrapBlot(this, TableRow.kBlotName);
      wrapBlot(this, name, value);
    } else if (name == TableTh.kBlotName && truthy) {
      wrapBlot(this, TableThRow.kBlotName);
      wrapBlot(this, name, value);
    } else if (name == TableContainer.kBlotName) {
      wrapBlot(this, name, value);
    } else if (name == 'header' ||
        name == 'table-header' ||
        name == 'list' ||
        name == 'table-list') {
      // TODO(table-better): TS replaces this block with `table-header` /
      // `table-list` blots (formats/header.ts, formats/list.ts) which are not
      // part of the foundation port; fall through to the default handling.
      super.format(name, value);
    } else {
      super.format(name, value);
    }
  }

  @override
  Map<String, dynamic> formats() {
    final formats = Map<String, dynamic>.from(super.formats());
    final format = element.getAttribute('data-cell');
    if (format != null) {
      formats[blotName] = format;
    }
    return formats;
  }

  /// TS `getCellFormats(parent)`.
  Map<String, String> getCellFormats(Blot? parent) {
    final cellBlot = utils.getCorrectCellBlot(parent);
    if (cellBlot == null) return {};
    final (formats, _) = utils.getCellFormats(cellBlot);
    return formats;
  }

  /// TS `wrapTableCell(parent)`.
  void wrapTableCell(Blot? parent) {
    final cellBlot = utils.getCorrectCellBlot(parent);
    if (cellBlot == null) return;
    final (formats, _) = utils.getCellFormats(cellBlot);
    wrapBlot(this, cellBlot.blotName, formats);
  }

  /// TS `TableCellBlock.requiredContainer = TableCell` (table.ts:870).
  ///
  /// Deviation guard: enforcement is limited to blocks that actually carry
  /// the `ql-table-block` class. A registry that lists this blot first for
  /// the `P` tag (as the barebones test registries do) hydrates plain
  /// paragraphs as [TableCellBlock]; without the guard those would be
  /// swallowed into a table on the first optimize pass.
  @override
  void optimize([
    List<DomMutationRecord>? mutations,
    Map<String, dynamic>? context,
  ]) {
    super.optimize(mutations, context);
    if (parent == null) return;
    if (!element.classes.contains(TableCellBlock.kClassName)) return;
    _enforceRequiredContainer(
      this,
      TableCell.kBlotName,
      (blot) => blot is TableCell,
      mutations,
      context,
    );
  }
}

/// TS `TableThBlock` — the block line inside a `<th>`.
class TableThBlock extends TableCellBlock {
  TableThBlock(DomElement domNode) : super(domNode);

  static const String kBlotName = 'table-th-block';
  static const String kClassName = 'table-th-block';
  static const String kTagName = 'P';
  static const int kScope = Scope.BLOCK_BLOT;

  static TableThBlock create([dynamic value]) {
    if (value is DomElement) return TableThBlock(value);
    return TableThBlock(
        TableCellBlock.createBlockNode(value, kTagName, kClassName));
  }

  @override
  String get blotName => kBlotName;

  @override
  TableThBlock clone() => TableThBlock(element.cloneNode(deep: false));
}

/// TS `TableCell` — the `<td>` container.
class TableCell extends TableBetterContainer {
  TableCell(DomElement domNode) : super(domNode);

  static const String kBlotName = 'table-cell';
  static const String kTagName = 'TD';
  static const int kScope = Scope.BLOCK_BLOT;

  static TableCell create([dynamic value]) {
    if (value is DomElement) return TableCell(value);
    final node = _createElement(kTagName);
    applyCellAttributes(node, value);
    return TableCell(node);
  }

  /// TS `create` attribute loop (`value[key] && node.setAttribute(...)`).
  static void applyCellAttributes(DomElement node, dynamic value) {
    if (value is Map) {
      for (final entry in value.entries) {
        final raw = entry.value;
        if (raw == null || raw == false || '$raw'.isEmpty) continue;
        node.setAttribute('${entry.key}', '$raw');
      }
    }
  }

  /// TS static `formats(domNode)`.
  static Map<String, String> formatsFromNode(DomElement domNode) {
    final rowspan = getEmptyRowspan(domNode);
    final formats = <String, String>{};
    for (final attr in cellAttribute) {
      if (domNode.hasAttribute(attr)) {
        final raw = domNode.getAttribute(attr) ?? '';
        if (attr == 'rowspan' && rowspan > 0) {
          formats[attr] = '${_toInt(raw) - rowspan}';
        } else {
          formats[attr] = utils.filterWordStyle(raw);
        }
      }
    }
    if (hasColgroup(domNode)) {
      formats.remove('width');
      final style = formats['style'];
      if (style != null) {
        formats['style'] = style.replaceAll(RegExp(r'width.*?;'), '');
      }
    }
    return formats;
  }

  /// TS static `getEmptyRowspan(domNode)`.
  static int getEmptyRowspan(DomElement domNode) {
    var nextNode = _nextElementSibling(_parentElement(domNode));
    var rowspan = 0;
    while (nextNode != null &&
        nextNode.tagName == 'TR' &&
        (nextNode.innerHTML ?? '').replaceAll(RegExp(r'\s'), '').isEmpty) {
      rowspan++;
      nextNode = _nextElementSibling(nextNode);
    }
    return rowspan;
  }

  /// TS static `hasColgroup(domNode)`.
  static bool hasColgroup(DomElement domNode) {
    DomElement? node = domNode;
    while (node != null && node.tagName != 'TBODY') {
      node = _parentElement(node);
    }
    while (node != null) {
      if (node.tagName == 'COLGROUP') {
        return true;
      }
      node = _previousElementSibling(node);
    }
    return false;
  }

  @override
  String get blotName => kBlotName;

  @override
  int get scope => kScope;

  @override
  TableCell clone() => TableCell(element.cloneNode(deep: false));

  /// TS `TableCell.requiredContainer = TableRow` (table.ts:865).
  @override
  String? get requiredContainerBlotName => TableRow.kBlotName;

  @override
  bool isRequiredContainer(Blot blot) => blot is TableRow;

  String? _childCellId(Blot child) =>
      utils.getCellId(child.formats()[child.blotName]);

  @override
  bool checkMerge() {
    if (!super.checkMerge()) return false;
    final nextBlot = next;
    if (nextBlot is! ParentBlot ||
        nextBlot.children.isEmpty ||
        children.isEmpty) {
      return false;
    }
    final thisHead = _childCellId(children.first);
    final thisTail = _childCellId(children.last);
    final nextHead = _childCellId(nextBlot.children.first);
    final nextTail = _childCellId(nextBlot.children.last);
    return thisHead == thisTail && thisHead == nextHead && thisHead == nextTail;
  }

  @override
  Map<String, dynamic> formats() {
    return {blotName: TableCell.formatsFromNode(element)};
  }

  /// TS `html()` (rewrites bullet `<ol>` lists back to `<ul>`).
  String html() {
    final reg = RegExp(
      r'<(ol)[^>]*><li[^>]* data-list="bullet">(?:.*?)</li></(ol)>',
      caseSensitive: false,
    );
    return outerHtml(element).replaceAllMapped(reg, (match) {
      return match
          .group(0)!
          .replaceFirst('ol', 'ul')
          .replaceFirst('ol', 'ul');
    });
  }

  TableRow? row() => parent is TableRow ? parent as TableRow : null;

  int rowOffset() {
    final rowBlot = row();
    if (rowBlot != null) {
      return rowBlot.rowOffset();
    }
    return -1;
  }

  /// TS `setChildrenId(cellId)`.
  void setChildrenId(String cellId) {
    for (final child in children) {
      if (child is ParentBlot) {
        child.element.setAttribute('data-cell', cellId);
      }
    }
  }

  TableContainer? table() {
    Blot? cur = parent;
    while (cur != null && cur.blotName != TableContainer.kBlotName) {
      cur = cur.parent;
    }
    return cur is TableContainer ? cur : null;
  }

  @override
  void optimize([
    List<DomMutationRecord>? mutations,
    Map<String, dynamic>? context,
  ]) {
    super.optimize(mutations, context);
    if (parent == null) return; // removed by the base optimize
    for (final child in List<Blot>.from(children)) {
      if (child.parent != this) continue;
      final nextChild = child.next;
      if (nextChild == null) continue;
      final childFormats = utils.getCellId(child.formats()[child.blotName]);
      final nextFormats =
          utils.getCellId(nextChild.formats()[nextChild.blotName]);
      if (childFormats != nextFormats) {
        final nextCell = splitAfter(child);
        nextCell.optimize(mutations, context);
        // We might be able to merge with prev now.
        prev?.optimize(mutations, context);
      }
    }
  }
}

/// TS `TableTh` — the `<th>` container.
class TableTh extends TableCell {
  TableTh(DomElement domNode) : super(domNode);

  static const String kBlotName = 'table-th';
  static const String kTagName = 'TH';

  static TableTh create([dynamic value]) {
    if (value is DomElement) return TableTh(value);
    final node = _createElement(kTagName);
    TableCell.applyCellAttributes(node, value);
    return TableTh(node);
  }

  @override
  String get blotName => kBlotName;

  @override
  TableTh clone() => TableTh(element.cloneNode(deep: false));

  /// TS `TableTh.requiredContainer = TableThRow` (table.ts:867).
  @override
  String? get requiredContainerBlotName => TableThRow.kBlotName;

  @override
  bool isRequiredContainer(Blot blot) => blot is TableThRow;
}

/// TS `TableRow` — the `<tr>` container.
class TableRow extends TableBetterContainer {
  TableRow(DomElement domNode) : super(domNode);

  static const String kBlotName = 'table-row';
  static const String kTagName = 'TR';
  static const int kScope = Scope.BLOCK_BLOT;

  static TableRow create([dynamic value]) {
    if (value is DomElement) return TableRow(value);
    return TableRow(_createElement(kTagName));
  }

  @override
  String get blotName => kBlotName;

  @override
  int get scope => kScope;

  @override
  TableRow clone() => TableRow(element.cloneNode(deep: false));

  /// TS `TableRow.requiredContainer = TableBody` (table.ts:857).
  @override
  String? get requiredContainerBlotName => TableBody.kBlotName;

  @override
  bool isRequiredContainer(Blot blot) => blot is TableBody;

  String? _dataRow(Blot child) {
    final formats = child.formats()[child.blotName];
    return formats is Map ? formats['data-row'] as String? : null;
  }

  @override
  bool checkMerge() {
    if (!super.checkMerge()) return false;
    final nextBlot = next;
    if (nextBlot is! ParentBlot ||
        nextBlot.children.isEmpty ||
        children.isEmpty) {
      return false;
    }
    final thisHead = _dataRow(children.first);
    final thisTail = _dataRow(children.last);
    final nextHead = _dataRow(nextBlot.children.first);
    final nextTail = _dataRow(nextBlot.children.last);
    return thisHead == thisTail && thisHead == nextHead && thisHead == nextTail;
  }

  int rowOffset() {
    final parentBlot = parent;
    if (parentBlot != null) {
      return parentBlot.children.indexOf(this);
    }
    return -1;
  }
}

/// TS `TableThRow` — the `<tr>` inside a `<thead>`.
///
/// Note: it shares the `TR` tag with [TableRow]; the Dart registry resolves
/// by tag name in insertion order, so hydration of a bare `<tr>` always
/// yields [TableRow] (the TS registry has the same tag collision).
class TableThRow extends TableRow {
  TableThRow(DomElement domNode) : super(domNode);

  static const String kBlotName = 'table-th-row';
  static const String kTagName = 'TR';

  static TableThRow create([dynamic value]) {
    if (value is DomElement) return TableThRow(value);
    return TableThRow(_createElement(kTagName));
  }

  @override
  String get blotName => kBlotName;

  @override
  TableThRow clone() => TableThRow(element.cloneNode(deep: false));

  /// TS `TableThRow.requiredContainer = TableThead` (table.ts:859).
  @override
  String? get requiredContainerBlotName => TableThead.kBlotName;

  @override
  bool isRequiredContainer(Blot blot) => blot is TableThead;
}

/// TS `TableBody` — the `<tbody>` container.
class TableBody extends TableBetterContainer {
  TableBody(DomElement domNode) : super(domNode);

  static const String kBlotName = 'table-body';
  static const String kTagName = 'TBODY';
  static const int kScope = Scope.BLOCK_BLOT;

  static TableBody create([dynamic value]) {
    if (value is DomElement) return TableBody(value);
    return TableBody(_createElement(kTagName));
  }

  @override
  String get blotName => kBlotName;

  @override
  int get scope => kScope;

  @override
  TableBody clone() => TableBody(element.cloneNode(deep: false));

  /// TS `TableBody.requiredContainer = TableContainer` (table.ts:851; the
  /// thead subclass shares it via table.ts:852).
  @override
  String? get requiredContainerBlotName => TableContainer.kBlotName;

  @override
  bool isRequiredContainer(Blot blot) => blot is TableContainer;
}

/// TS `TableThead` — the `<thead>` container.
class TableThead extends TableBody {
  TableThead(DomElement domNode) : super(domNode);

  static const String kBlotName = 'table-thead';
  static const String kTagName = 'THEAD';

  static TableThead create([dynamic value]) {
    if (value is DomElement) return TableThead(value);
    return TableThead(_createElement(kTagName));
  }

  @override
  String get blotName => kBlotName;

  @override
  TableThead clone() => TableThead(element.cloneNode(deep: false));
}

/// TS `TableTemporary` — the `<temporary>` element that carries the table's
/// attributes (border, cellspacing, style, data-class) through the delta.
class TableTemporary extends Block {
  TableTemporary(DomElement domNode) : super(domNode);

  static const String kBlotName = 'table-temporary';
  static const String kClassName = 'ql-table-temporary';
  static const String kTagName = 'TEMPORARY';
  static const int kScope = Scope.BLOCK_BLOT;

  static TableTemporary create([dynamic value]) {
    if (value is DomElement) return TableTemporary(value);
    final node = _createElement(kTagName);
    _setClassAttribute(node, kClassName);
    if (value is Map) {
      final className = TableContainer.kDefaultClassName;
      for (final entry in value.entries) {
        final key = '${entry.key}';
        final raw = '${entry.value}';
        if (key == 'data-class' && !raw.contains(className)) {
          node.setAttribute(key, '$className $raw');
        } else {
          node.setAttribute(key, raw);
        }
      }
    }
    return TableTemporary(node);
  }

  /// TS static `formats(domNode)`.
  static Map<String, String> formatsFromNode(DomElement domNode) {
    final formats = <String, String>{};
    for (final attr in tableAttribute) {
      if (domNode.hasAttribute(attr)) {
        formats[attr] = domNode.getAttribute(attr) ?? '';
      }
    }
    return formats;
  }

  @override
  String get blotName => kBlotName;

  @override
  int get scope => kScope;

  @override
  TableTemporary clone() => TableTemporary(element.cloneNode(deep: false));

  @override
  Map<String, dynamic> formats() {
    return {blotName: TableTemporary.formatsFromNode(element)};
  }

  @override
  void optimize([
    List<DomMutationRecord>? mutations,
    Map<String, dynamic>? context,
  ]) {
    // `requiredContainer` approximation: mirror the temporary's attributes
    // onto the parent table (TS checks `parent instanceof requiredContainer`).
    final parentBlot = parent;
    if (parentBlot is TableContainer) {
      final formats = TableTemporary.formatsFromNode(element);
      for (final key in tableAttribute) {
        final value = formats[key];
        if (value != null && value.isNotEmpty) {
          if (key == 'data-class') {
            parentBlot.element.setAttribute('class', value);
          } else {
            parentBlot.element.setAttribute(key, value);
          }
        } else {
          parentBlot.element.removeAttribute(key);
        }
      }
    }
    super.optimize(mutations, context);
    if (parent == null) return;
    // TS `TableTemporary.requiredContainer = TableContainer` (table.ts:853).
    _enforceRequiredContainer(
      this,
      TableContainer.kBlotName,
      (blot) => blot is TableContainer,
      mutations,
      context,
    );
  }
}

/// TS `TableCol` — the `<col>` element (a Block in TS as well).
class TableCol extends Block {
  TableCol(DomElement domNode) : super(domNode);

  static const String kBlotName = 'table-col';
  static const String kTagName = 'COL';
  static const int kScope = Scope.BLOCK_BLOT;

  static TableCol create([dynamic value]) {
    if (value is DomElement) return TableCol(value);
    final node = _createElement(kTagName);
    if (value is Map) {
      for (final entry in value.entries) {
        node.setAttribute('${entry.key}', '${entry.value}');
      }
    }
    return TableCol(node);
  }

  /// TS static `formats(domNode)`.
  static Map<String, String> formatsFromNode(DomElement domNode) {
    final formats = <String, String>{};
    for (final attr in colAttribute) {
      if (domNode.hasAttribute(attr)) {
        formats[attr] = domNode.getAttribute(attr) ?? '';
      }
    }
    return formats;
  }

  @override
  String get blotName => kBlotName;

  @override
  int get scope => kScope;

  @override
  TableCol clone() => TableCol(element.cloneNode(deep: false));

  @override
  Map<String, dynamic> formats() {
    return {blotName: TableCol.formatsFromNode(element)};
  }

  /// TS `html()`.
  String html() => outerHtml(element);

  @override
  void optimize([
    List<DomMutationRecord>? mutations,
    Map<String, dynamic>? context,
  ]) {
    super.optimize(mutations, context);
    // Deviation: the Dart Block base appends a Break to empty blocks, but a
    // real `<col>` cannot hold children (browsers drop them); keep it clean.
    for (final child in List<Blot>.from(children)) {
      child.remove();
    }
    if (parent == null) return;
    // TS `TableCol.requiredContainer = TableColgroup` (table.ts:862).
    _enforceRequiredContainer(
      this,
      TableColgroup.kBlotName,
      (blot) => blot is TableColgroup,
      mutations,
      context,
    );
  }
}

/// TS `TableColgroup` — the `<colgroup>` container.
class TableColgroup extends TableBetterContainer {
  TableColgroup(DomElement domNode) : super(domNode);

  static const String kBlotName = 'table-colgroup';
  static const String kTagName = 'COLGROUP';
  static const int kScope = Scope.BLOCK_BLOT;

  static TableColgroup create([dynamic value]) {
    if (value is DomElement) return TableColgroup(value);
    return TableColgroup(_createElement(kTagName));
  }

  @override
  String get blotName => kBlotName;

  @override
  int get scope => kScope;

  @override
  TableColgroup clone() => TableColgroup(element.cloneNode(deep: false));

  /// TS `TableColgroup.requiredContainer = TableContainer` (table.ts:854).
  @override
  String? get requiredContainerBlotName => TableContainer.kBlotName;

  @override
  bool isRequiredContainer(Blot blot) => blot is TableContainer;
}

/// Entry of the `columnCells` work lists built by `insertColumn`/`deleteRow`.
/// Mirrors the TS tuple `[TableRow, Props | string, TableCell, TableCell]`.
class _ColumnCellEntry {
  _ColumnCellEntry(this.row, this.props, this.ref, this.prev);

  final TableRow? row;

  /// Either the `data-row` id ([String]) or a cell formats map.
  final dynamic props;
  final TableCell? ref;
  final TableCell? prev;
}

/// TS `TableContainer` — the `<table>` container and its editing API.
class TableContainer extends TableBetterContainer {
  TableContainer(DomElement domNode) : super(domNode);

  static const String kBlotName = 'table-container';
  static const String kDefaultClassName = 'ql-table-better';
  static const String kTagName = 'TABLE';
  static const int kScope = Scope.BLOCK_BLOT;

  static TableContainer create([dynamic value]) {
    if (value is DomElement) return TableContainer(value);
    return TableContainer(_createElement(kTagName));
  }

  @override
  String get blotName => kBlotName;

  @override
  int get scope => kScope;

  @override
  TableContainer clone() => TableContainer(element.cloneNode(deep: false));

  T? _firstDescendant<T extends Blot>() {
    for (final descendant in descendants<T>()) {
      return descendant;
    }
    return null;
  }

  /// TS `colgroup()`.
  TableColgroup? colgroup() =>
      _firstDescendant<TableColgroup>() ??
      findChild(TableColgroup.kBlotName) as TableColgroup?;

  /// TS `deleteColumn(changeTds, delTds, deleteTable, cols)`.
  ///
  /// Adapted: `Quill.find(td)` becomes `scroll.find(td)`, and elements are
  /// removed through their blots so the blot tree stays consistent (the TS
  /// code removes DOM nodes and relies on the MutationObserver rebuild).
  void deleteColumn(
    List<MapEntry<DomElement, int>> changeTds,
    List<DomElement> delTds,
    void Function() deleteTable, [
    List<DomElement> cols = const [],
  ]) {
    final body = tbody();
    final tableCells = descendants<TableCell>().toList();
    if (body == null || body.children.isEmpty) return;
    if (delTds.length == tableCells.length) {
      deleteTable();
    } else {
      for (final entry in changeTds) {
        final blot = scroll.find(entry.key).key;
        if (blot is TableCell) {
          setCellColspan(blot, entry.value);
        }
      }
      for (final td in [...delTds, ...cols]) {
        final parentEl = _parentElement(td);
        if (parentEl != null &&
            parentEl.childNodes.whereType<DomElement>().length == 1) {
          final prevEl = _previousElementSibling(parentEl);
          if (prevEl != null) {
            setCellRowspan(prevEl);
          }
        }
        final blot = scroll.find(td).key;
        if (blot != null) {
          blot.remove();
        } else {
          td.remove();
        }
      }
    }
  }

  /// TS `deleteRow(rows, deleteTable)`.
  ///
  /// The rowspan redistribution path is layout-dependent (it measures the
  /// removed cell's rectangle); see `utils.elementRectResolver`.
  void deleteRow(List<TableRow> rows, void Function() deleteTable) {
    final body = tbody();
    if (body == null || body.children.isEmpty) return;
    if (rows.length == body.children.length) {
      deleteTable();
      return;
    }
    // TS uses a WeakMap keyed by cell blots; a plain identity map suffices.
    final weakMap = <TableCell, ({TableRow? next, int rowspan})>{};
    final columnCells = <_ColumnCellEntry>[];
    final keys = <TableCell>[];
    final headRow = body.children.first as TableRow;
    final maxColumns = getMaxColumns(headRow.children);
    for (final row in rows) {
      final prevRow = getCorrectRow(row, maxColumns);
      if (prevRow == null) continue;
      for (final child in List<Blot>.from(prevRow.children)) {
        if (child is! TableCell) continue;
        final rowspan = _toInt(child.element.getAttribute('rowspan'));
        if (rowspan > 1) {
          final blotName = child.blotName;
          final (formats, _) = utils.getCellFormats(child);
          final childRow = child.parent;
          if (childRow is TableRow && rows.contains(childRow)) {
            final nextRow =
                childRow.next is TableRow ? childRow.next as TableRow : null;
            if (weakMap.containsKey(child)) {
              final existing = weakMap[child]!;
              weakMap[child] = (next: nextRow, rowspan: existing.rowspan - 1);
            } else {
              weakMap[child] = (next: nextRow, rowspan: rowspan - 1);
              keys.add(child);
            }
          } else {
            replaceBlotWith(child, blotName, {
              ...formats,
              'rowspan': '${rowspan - 1}',
            });
          }
        }
      }
    }
    for (final prevCell in keys) {
      final (formats, _) = utils.getCellFormats(prevCell);
      // TODO(table-better): layout-dependent — requires a real
      // elementRectResolver (getBoundingClientRect) in the UI phase.
      final rect = utils.elementRectResolver(prevCell.element);
      final entry = weakMap[prevCell]!;
      _setColumnCells(
        entry.next,
        columnCells,
        position: rect.right,
        width: rect.width,
        formats: formats,
        rowspan: entry.rowspan,
        prev: prevCell,
      );
    }
    for (final entry in columnCells) {
      final cell = scroll.create(
        TableCell.kBlotName,
        entry.props,
      ) as TableCell;
      entry.prev!.moveChildren(cell, null);
      cell.setChildrenId(cellId());
      entry.row!.insertBefore(cell, entry.ref);
      entry.prev!.remove();
    }
    for (final row in rows) {
      row.remove();
    }
  }

  /// TS `deleteTable()`.
  void deleteTable() => remove();

  /// TS `findChild(blotName)`.
  Blot? findChild(String blotName) {
    for (final child in children) {
      if (child.blotName == blotName) {
        return child;
      }
    }
    return null;
  }

  /// TS `getCopyTable(html?)`.
  String getCopyTable([String? html]) {
    html ??= outerHtml(element);
    return html
        .replaceAll(
          RegExp(r'<temporary[^>]*>(.*?)</temporary>', caseSensitive: false),
          '',
        )
        .replaceAllMapped(
          RegExp(r'<td[^>]*>(.*?)</td>', caseSensitive: false),
          (match) => utils.getCopyTd(match.group(0)!),
        );
  }

  /// TS `getCorrectRow(prev, maxColumns)`.
  TableRow? getCorrectRow(TableRow? prev, int maxColumns) {
    var isCorrect = false;
    while (prev != null && !isCorrect) {
      final prevMaxColumns = getMaxColumns(prev.children);
      if (maxColumns == prevMaxColumns) {
        isCorrect = true;
        return prev;
      }
      prev = prev.prev is TableRow ? prev.prev as TableRow : null;
    }
    return prev;
  }

  /// TS `getInsertRow(prev, ref, offset, isTh)`.
  TableRow? getInsertRow(
    TableRow prev,
    TableRow? ref,
    int offset, [
    bool isTh = false,
  ]) {
    final body = tbody();
    final theadBlot = thead();
    if ((body == null || body.children.isEmpty) &&
        (theadBlot == null || theadBlot.children.isEmpty)) {
      return null;
    }
    final id = tableId();
    final blotName = isTh ? TableThRow.kBlotName : TableRow.kBlotName;
    final row = scroll.create(blotName) as TableRow;
    final source = body != null && body.children.isNotEmpty ? body : theadBlot!;
    final headRow = source.children.first as TableRow;
    final maxColumns = getMaxColumns(headRow.children);
    final nextMaxColumns = getMaxColumns(prev.children);
    if (nextMaxColumns == maxColumns) {
      for (final child in List<Blot>.from(prev.children)) {
        if (child is! TableCell) continue;
        final formats = <String, String>{'height': '24', 'data-row': id};
        final colspan = _toInt(child.element.getAttribute('colspan'));
        insertTableCell(colspan == 0 ? 1 : colspan, formats, row, isTh);
      }
      return row;
    } else {
      final correctRow = getCorrectRow(
        prev.prev is TableRow ? prev.prev as TableRow : null,
        maxColumns,
      );
      if (correctRow == null) return row;
      for (final child in List<Blot>.from(correctRow.children)) {
        if (child is! TableCell) continue;
        final formats = <String, String>{'height': '24', 'data-row': id};
        final colspan = _toInt(child.element.getAttribute('colspan'));
        final rowspan = _toInt(child.element.getAttribute('rowspan'));
        if (rowspan > 1) {
          if (offset > 0 && ref == null) {
            insertTableCell(colspan == 0 ? 1 : colspan, formats, row, isTh);
          } else {
            final (cellFormats, _) = utils.getCellFormats(child);
            replaceBlotWith(child, child.blotName, {
              ...cellFormats,
              'rowspan': '${rowspan + 1}',
            });
          }
        } else {
          insertTableCell(colspan == 0 ? 1 : colspan, formats, row, isTh);
        }
      }
      return row;
    }
  }

  /// TS `getMaxColumns(children)` (sum of colspans).
  int getMaxColumns(Iterable<Blot> children) {
    return children.fold<int>(0, (num, child) {
      if (child is! ParentBlot) return num;
      final colspan = _toInt(child.element.getAttribute('colspan'));
      return num + (colspan == 0 ? 1 : colspan);
    });
  }

  /// TS `insertColumn(position, isLast, w, offset)`.
  ///
  /// The `isLast` path is position-free; inserting at an arbitrary pixel
  /// position is layout-dependent (see `utils.elementRectResolver`).
  void insertColumn(double position, bool isLast, double w, int offset) {
    final colgroupBlot = colgroup();
    final body = tbody();
    final theadBlot = thead();
    if ((body == null || body.children.isEmpty) &&
        (theadBlot == null || theadBlot.children.isEmpty)) {
      return;
    }
    final columnCells = <_ColumnCellEntry>[];
    final cols = <(TableColgroup, TableCol?)>[];
    final rows = descendants<TableRow>().toList();
    for (final row in rows) {
      if (isLast && offset > 0) {
        final lastCell = row.children.last;
        final id = lastCell is ParentBlot
            ? lastCell.element.getAttribute('data-row') ?? ''
            : '';
        columnCells.add(_ColumnCellEntry(row, id, null, null));
      } else {
        _setColumnCells(row, columnCells, position: position, width: w);
      }
    }
    if (colgroupBlot != null) {
      if (isLast) {
        cols.add((colgroupBlot, null));
      } else {
        var correctLeft = 0.0;
        var correctRight = 0.0;
        Blot? colBlot =
            colgroupBlot.children.isNotEmpty ? colgroupBlot.children.first : null;
        while (colBlot != null) {
          final col = colBlot as TableCol;
          // TODO(table-better): layout-dependent — requires a real
          // elementRectResolver (getBoundingClientRect) in the UI phase.
          final rect = utils.elementRectResolver(col.element);
          correctLeft = correctLeft != 0 ? correctLeft : rect.left;
          correctRight = correctLeft + rect.width;
          if ((correctLeft - position).abs() <= deviation) {
            cols.add((colgroupBlot, col));
            break;
          } else if ((correctRight - position).abs() <= deviation &&
              col.next == null) {
            cols.add((colgroupBlot, null));
            break;
          }
          correctLeft += rect.width;
          colBlot = colBlot.next;
        }
      }
    }
    for (final entry in columnCells) {
      if (entry.row == null) {
        setCellColspan(entry.ref!, 1);
      } else {
        insertColumnCell(entry.row, '${entry.props}', entry.ref);
      }
    }
    for (final (group, ref) in cols) {
      insertCol(group, ref);
    }
  }

  /// TS `insertCol(colgroup, ref)`.
  void insertCol(TableColgroup colgroup, TableCol? ref) {
    final col = scroll.create(
      TableCol.kBlotName,
      {'width': '$cellDefaultWidth'},
    );
    colgroup.insertBefore(col, ref);
  }

  /// TS `insertColumnCell(row, id, ref)`.
  TableCell insertColumnCell(TableRow? row, String id, TableCell? ref) {
    if (row == null) {
      final body = tbody();
      row = scroll.create(TableRow.kBlotName) as TableRow;
      body?.insertBefore(row, null);
    }
    final colgroupBlot = colgroup();
    final formats = colgroupBlot != null
        ? <String, String>{'data-row': id}
        : <String, String>{'data-row': id, 'width': '$cellDefaultWidth'};
    final isTableRow = row.blotName == TableRow.kBlotName;
    final cellBlotName = isTableRow ? TableCell.kBlotName : TableTh.kBlotName;
    final blockBlotName =
        isTableRow ? TableCellBlock.kBlotName : TableThBlock.kBlotName;
    final cell = scroll.create(cellBlotName, formats) as TableCell;
    final cellBlock = scroll.create(blockBlotName, cellId()) as TableCellBlock;
    cell.appendChild(cellBlock);
    row.insertBefore(cell, ref);
    cellBlock.optimize();
    return cell;
  }

  /// TS `insertRow(index, offset, isTh)`.
  void insertRow(int index, int offset, [bool isTh = false]) {
    final body = tbody();
    final theadBlot = thead();
    if ((body == null || body.children.isEmpty) &&
        (theadBlot == null || theadBlot.children.isEmpty)) {
      return;
    }
    final parentBlot = isTh ? theadBlot : body;
    if (parentBlot == null) return;
    final refBlot =
        isTh ? _childAt(theadBlot, index) : _childAt(body, index);
    final ref = refBlot is TableRow ? refBlot : null;
    final prevBlot = ref ?? _childAt(body, index - 1);
    if (prevBlot is! TableRow) return;
    final correctRow = getInsertRow(prevBlot, ref, offset, isTh);
    if (correctRow != null) {
      parentBlot.insertBefore(correctRow, ref);
    }
  }

  /// TS `insertTableCell(colspan, formats, row, isTh)`.
  void insertTableCell(
    int colspan,
    Map<String, String> formats,
    TableRow row, [
    bool isTh = false,
  ]) {
    if (colspan > 1) {
      formats['colspan'] = '$colspan';
    } else {
      formats.remove('colspan');
    }
    final cellBlotName = isTh ? TableTh.kBlotName : TableCell.kBlotName;
    final blockBlotName =
        isTh ? TableThBlock.kBlotName : TableCellBlock.kBlotName;
    final cell = scroll.create(cellBlotName, formats) as TableCell;
    final cellBlock = scroll.create(blockBlotName, cellId()) as TableCellBlock;
    cell.appendChild(cellBlock);
    row.appendChild(cell);
    cellBlock.optimize();
  }

  /// TS `isPercent()`.
  ///
  /// Adaptation: inline style is read from the `style` attribute (the
  /// platform abstraction has no typed CSSStyleDeclaration).
  bool isPercent() {
    final width = element.getAttribute('width') ??
        utils.getInlineStyleValue(element, 'width');
    if (width == null || width.isEmpty) return false;
    return width.endsWith('%');
  }

  @override
  void optimize([
    List<DomMutationRecord>? mutations,
    Map<String, dynamic>? context,
  ]) {
    super.optimize(mutations, context);
    if (parent == null) return; // removed by the base optimize
    final temporaries = descendants<TableTemporary>().toList();
    _setClassName(temporaries);
    if (temporaries.length > 1) {
      for (final temporary in temporaries.skip(1)) {
        temporary.remove();
      }
    }
  }

  /// TS `setCellColspan(cell, offset)`.
  void setCellColspan(TableCell cell, int offset) {
    final blotName = cell.blotName;
    final formats = Map<String, String>.from(
      cell.formats()[blotName] as Map<String, String>,
    );
    final current = _toInt(formats['colspan']);
    final colspan = (current == 0 ? 1 : current) + offset;
    if (colspan > 1) {
      formats['colspan'] = '$colspan';
    } else {
      formats.remove('colspan');
    }
    replaceBlotWith(cell, blotName, formats);
  }

  /// TS `setCellRowspan(parentElement)`.
  ///
  /// TODO(table-better): the final `childBlot.format(blotName, formats)` call
  /// relies on parchment's optimize normalization (allowedChildren
  /// enforcement) to restore a valid tree; that machinery is not ported yet.
  void setCellRowspan(DomElement? parentElement) {
    while (parentElement != null) {
      final children = parentElement.querySelectorAll('td[rowspan]');
      if (children.isNotEmpty) {
        for (final child in children) {
          final cell = scroll.find(child).key;
          if (cell is! TableCell) continue;
          final blotName = cell.blotName;
          final formats = Map<String, String>.from(
            cell.formats()[blotName] as Map<String, String>,
          );
          final current = _toInt(formats['rowspan']);
          final rowspan = (current == 0 ? 1 : current) - 1;
          final childBlot = utils.getCellChildBlot(cell);
          if (rowspan > 1) {
            formats['rowspan'] = '$rowspan';
          } else {
            formats.remove('rowspan');
          }
          childBlot?.format(blotName, formats);
        }
        break;
      }
      parentElement = _previousElementSibling(parentElement);
    }
  }

  /// TS private `setClassName(temporaries)`.
  void _setClassName(List<TableTemporary> temporaries) {
    const defaultClassName = kDefaultClassName;
    final temporaryBlot = temporaries.isNotEmpty ? temporaries.first : null;
    final classAttr = element.getAttribute('class');

    String getClassName(String className) {
      final classNames = className
          .split(RegExp(r'\s+'))
          .where((token) => token.isNotEmpty)
          .toList();
      if (!classNames.contains(defaultClassName)) {
        classNames.insert(0, defaultClassName);
      }
      return classNames.join(' ').trim();
    }

    void setClass(TableTemporary temporary, String? className) {
      final current = temporary.element.getAttribute('data-class');
      if (className != current && className != null) {
        temporary.element.setAttribute('data-class', getClassName(className));
      }
      if ((className == null || className.isEmpty) &&
          (current == null || current.isEmpty)) {
        temporary.element.setAttribute('data-class', defaultClassName);
      }
    }

    if (temporaryBlot == null) {
      final container = prev;
      if (container is! ParentBlot) return;
      TableCell? cell;
      for (final descendant in container.descendants<TableCell>()) {
        cell = descendant;
        break;
      }
      TableTemporary? temporary;
      for (final descendant in container.descendants<TableTemporary>()) {
        temporary = descendant;
        break;
      }
      if (cell == null && temporary != null) {
        setClass(temporary, classAttr);
      }
    } else {
      setClass(temporaryBlot, classAttr);
    }
  }

  /// TS private `setColumnCells(row, columnCells, bounds, formats, rowspan,
  /// prev)`. Layout-dependent (see `utils.elementRectResolver`).
  void _setColumnCells(
    TableRow? row,
    List<_ColumnCellEntry> columnCells, {
    required double position,
    required double width,
    Map<String, String>? formats,
    int? rowspan,
    TableCell? prev,
  }) {
    if (row == null) return;
    Blot? refBlot = row.children.isNotEmpty ? row.children.first : null;
    while (refBlot != null) {
      final ref = refBlot is TableCell ? refBlot : null;
      if (ref == null) {
        refBlot = refBlot.next;
        continue;
      }
      // TODO(table-better): layout-dependent — requires a real
      // elementRectResolver (getBoundingClientRect) in the UI phase.
      final rect = utils.elementRectResolver(ref.element);
      final left = rect.left;
      final right = rect.right;
      final id = ref.element.getAttribute('data-row') ?? '';
      if (formats != null) {
        if (rowspan != null) {
          formats['rowspan'] = '$rowspan';
        }
        formats['data-row'] = id;
      }
      final dynamic props = formats ?? id;
      if ((left - position).abs() <= deviation) {
        columnCells.add(_ColumnCellEntry(row, props, ref, prev));
        break;
      } else if ((right - position).abs() <= deviation && ref.next == null) {
        columnCells.add(_ColumnCellEntry(row, props, null, prev));
        break;
        // rowspan > 1 (insertLeft, position + w is left)
      } else if ((left - position - width).abs() <= deviation) {
        columnCells.add(_ColumnCellEntry(row, props, ref, prev));
        break;
        // rowspan > 1 (position between left and right, rowspan++)
      } else if (position > left && position < right) {
        columnCells.add(_ColumnCellEntry(null, props, ref, prev));
        break;
      }
      refBlot = refBlot.next;
    }
  }

  /// TS `tbody()`.
  ///
  /// Note: [TableThead] extends [TableBody] (as in TS); theads are skipped so
  /// this always resolves the actual `<tbody>`.
  TableBody? tbody() {
    for (final descendant in descendants<TableBody>()) {
      if (descendant is! TableThead) return descendant;
    }
    return findChild(TableBody.kBlotName) as TableBody?;
  }

  /// TS `temporary()`.
  TableTemporary? temporary() => _firstDescendant<TableTemporary>();

  /// TS `thead()`.
  TableThead? thead() =>
      _firstDescendant<TableThead>() ??
      findChild(TableThead.kBlotName) as TableThead?;

  Blot? _childAt(ParentBlot? parent, int index) {
    if (parent == null || index < 0 || index >= parent.children.length) {
      return null;
    }
    return parent.children[index];
  }
}
