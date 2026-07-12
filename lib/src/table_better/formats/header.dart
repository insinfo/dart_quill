import '../../formats/header.dart';
import '../../platform/dom.dart';
import '../formats/table.dart';

/// Header line inside a table-better cell.
class TableHeader extends Header {
  TableHeader(DomElement node) : super(node);

  static const String kBlotName = 'table-header';
  static const String kClassName = 'ql-table-header';
  static const List<String> kTagNames = Header.kTagNames;
  static const int kScope = Header.kScope;

  static TableHeader create([dynamic formats]) {
    if (formats is DomElement) return TableHeader(formats);
    final map = formats is Map ? formats : const <String, dynamic>{};
    final value = int.tryParse('${map['value'] ?? formats ?? 1}') ?? 1;
    final node = Header.create(value);
    node.classes.add(kClassName);
    node.setAttribute('class', kClassName);
    final id = map['cellId'];
    node.setAttribute('data-cell', id == null ? cellId() : '$id');
    return TableHeader(node);
  }

  static Map<String, dynamic> formatsFromNode(DomElement node) => {
        'cellId': node.getAttribute('data-cell'),
        'value': Header.getLevel(node),
      };

  @override
  String get blotName => kBlotName;

  @override
  Map<String, dynamic> formats() => {
        ...super.formats()..remove(Header.kBlotName),
        kBlotName: formatsFromNode(element),
      };

  @override
  void format(String name, dynamic value) {
    if (name == Header.kBlotName) {
      final current = Header.getLevel(element);
      if (value == null || value == false || value == current) {
        replaceBlotWith(
          this,
          TableCellBlock.kBlotName,
          element.getAttribute('data-cell'),
        );
      } else {
        replaceBlotWith(this, kBlotName, {
          'cellId': element.getAttribute('data-cell'),
          'value': value,
        });
      }
      return;
    }
    if (name == kBlotName && (value == null || value == false)) {
      replaceBlotWith(
        this,
        TableCellBlock.kBlotName,
        element.getAttribute('data-cell'),
      );
      return;
    }
    super.format(name, value);
  }

  @override
  TableHeader clone() => TableHeader(element.cloneNode(deep: false));
}
