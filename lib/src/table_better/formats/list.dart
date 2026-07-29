import '../../blots/abstract/blot.dart';
import '../../formats/list.dart';
import '../../platform/dom.dart';
import '../../platform/platform.dart';
import '../config/config.dart';
import '../utils/utils.dart' as utils;
import 'header.dart';
import 'table.dart';

const _defaultSpanAttributes = ['colspan', 'rowspan'];

/// List container that retains the surrounding table-cell attributes.
class TableListContainer extends TableBetterContainer {
  TableListContainer(DomElement node) : super(node);

  static const String kBlotName = 'table-list-container';
  static const String kClassName = 'table-list-container';
  static const String kTagName = 'OL';
  static const int kScope = Scope.BLOCK_BLOT;

  static TableListContainer create([dynamic value]) {
    if (value is DomElement) return TableListContainer(value);
    final node = TableCellBlock.createBlockNode(null, kTagName, kClassName);
    node.removeAttribute('data-cell');
    final values = value is Map ? Map<dynamic, dynamic>.from(value) : {};
    for (final key in _defaultSpanAttributes) {
      if ('${values[key] ?? ''}' == '1') values.remove(key);
    }
    for (final entry in values.entries) {
      final key = '${entry.key}';
      final attribute = key == 'data-row'
          ? key
          : key == 'cellId'
              ? 'data-cell'
              : 'data-$key';
      node.setAttribute(attribute, '${entry.value}');
    }
    return TableListContainer(node);
  }

  static Map<String, String> formatsFromNode(DomElement node) {
    final result = <String, String>{};
    for (final attr in cellAttribute) {
      final name = attr.startsWith('data-') ? attr : 'data-$attr';
      final value = node.getAttribute(name);
      if (value != null) result[attr] = value;
    }
    result['cellId'] = node.getAttribute('data-cell') ?? cellId();
    for (final key in _defaultSpanAttributes) {
      result.putIfAbsent(key, () => '1');
    }
    return result;
  }

  @override
  String get blotName => kBlotName;

  @override
  int get scope => kScope;

  @override
  Map<String, dynamic> formats() => {kBlotName: formatsFromNode(element)};

  @override
  TableListContainer clone() =>
      TableListContainer(element.cloneNode(deep: false));
}

/// List item line inside a table-better cell.
class TableList extends ListItem {
  TableList(DomElement node) : super(node);

  static const String kBlotName = 'table-list';
  static const String kClassName = 'table-list';
  static const String kTagName = 'LI';
  static const int kScope = Scope.BLOCK_BLOT;

  static TableList create([dynamic value]) {
    if (value is DomElement) return TableList(value);
    final type = '$value'.isEmpty ? 'bullet' : '$value';
    // Build the bare <li> here instead of via ListItem.create: constructing a
    // ListItem attaches its checklist ui span to the node, and the TableList
    // constructor (through ListItem's) attaches another — every list item in
    // a cell came out with two .ql-ui spans.
    final node = domBindings.adapter.document.createElement(kTagName);
    node.setAttribute('data-list', type);
    node.setAttribute('class', kClassName);
    return TableList(node);
  }

  @override
  String get blotName => kBlotName;

  @override
  Map<String, dynamic> formats() {
    final type = element.dataset['list'] ??
        (parent is TableListContainer
            ? (parent as TableListContainer).element.dataset['list']
            : null) ??
        'bullet';
    return {...super.formats()..remove(ListItem.kBlotName), kBlotName: type};
  }

  @override
  void format(String name, dynamic value, [bool isReplace = false]) {
    if (name == ListItem.kBlotName) {
      // TS list.ts:66-73 — the same value (or none) turns the item back into a
      // plain cell block; a different value swaps the list type.
      final current = formats()[kBlotName];
      if (value == null || value == false || value == current) {
        // TS reads the cell id *before* restructuring: setReplace re-parents
        // this blot, after which the list container is no longer reachable.
        final id = _cellId();
        setReplace(isReplace);
        replaceBlotWith(this, TableCellBlock.kBlotName, id);
      } else {
        element.dataset['list'] = '$value';
      }
      return;
    }
    if (name == 'header') {
      // TS list.ts:82-86 — a list item becomes a header line.
      final id = _cellId();
      setReplace(isReplace);
      replaceBlotWith(
        this,
        TableHeader.kBlotName,
        {'cellId': id, 'value': value},
      );
      return;
    }
    if ((name == TableCell.kBlotName || name == TableTh.kBlotName) &&
        value != null &&
        value != false) {
      // TS list.ts:87-96 — the cell wrapper is rebuilt around the item and its
      // list container restored on top.
      final container = parent;
      if (container is! TableListContainer) return;
      final containerFormats = Map<String, dynamic>.from(
          container.formats()[container.blotName] as Map<String, dynamic>? ??
              const {});
      wrapBlot(this, name, value);
      wrapBlot(this, TableListContainer.kBlotName, {
        ...containerFormats,
        if (value is Map) ...value,
      });
      return;
    }
    if (name == kBlotName && (value == null || value == false)) {
      replaceBlotWith(this, TableCellBlock.kBlotName, _cellId());
      return;
    }
    super.format(name, value);
  }

  /// TS `setReplace(isReplace, formats)` — when the whole cell is being
  /// reformatted the cell itself is rebuilt; otherwise the line is wrapped in
  /// a fresh cell so the rest of the original one survives.
  void setReplace(bool isReplace) {
    final container = parent;
    if (container is! TableListContainer) return;
    final cellBlot = utils.getCorrectCellBlot(container);
    if (cellBlot == null) return;
    final (formats, _) = utils.getCellFormats(cellBlot);
    if (isReplace) {
      replaceBlotWith(container, cellBlot.blotName, formats);
    } else {
      wrapBlot(this, cellBlot.blotName, formats);
    }
  }

  String _cellId() {
    if (parent is TableListContainer) {
      return (parent as TableListContainer).element.getAttribute('data-cell') ??
          cellId();
    }
    return element.getAttribute('data-cell') ?? cellId();
  }

  @override
  void optimize([
    List<DomMutationRecord>? mutations,
    Map<String, dynamic>? context,
  ]) {
    final parentBlot = parent;
    if (parentBlot != null && parentBlot is! TableListContainer) {
      final wrapper = scroll.create(TableListContainer.kBlotName, {
        'cellId': element.getAttribute('data-cell') ?? cellId(),
      }) as TableListContainer;
      parentBlot.insertBefore(wrapper, this);
      wrapper.appendChild(this);
    }
  }

  @override
  TableList clone() => TableList(element.cloneNode(deep: false));
}
