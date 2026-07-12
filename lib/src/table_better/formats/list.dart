import '../../blots/abstract/blot.dart';
import '../../formats/list.dart';
import '../../platform/dom.dart';
import '../config/config.dart';
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
    final node = ListItem.create(type).element;
    node.classes.add(kClassName);
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
  void format(String name, dynamic value) {
    if (name == ListItem.kBlotName) {
      final current = formats()[kBlotName];
      if (value == null || value == false || value == current) {
        replaceBlotWith(this, TableCellBlock.kBlotName, _cellId());
      } else {
        element.dataset['list'] = '$value';
      }
      return;
    }
    if (name == kBlotName && (value == null || value == false)) {
      replaceBlotWith(this, TableCellBlock.kBlotName, _cellId());
      return;
    }
    super.format(name, value);
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
