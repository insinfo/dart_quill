import '../blots/abstract/blot.dart';
import 'abstract/attributor.dart';
import 'dart:html';

class IndentAttributor extends ClassAttributor {
  IndentAttributor() : super('indent', 'ql-indent', {
    'scope': Scope.BLOCK,
    'whitelist': [1, 2, 3, 4, 5, 6, 7, 8],
  });

  @override
  bool add(HtmlElement node, dynamic value) {
    int normalizedValue = 0;
    if (value == '+1' || value == '-1') {
      final indent = this.value(node) ?? 0;
      normalizedValue = value == '+1' ? indent + 1 : indent - 1;
    } else if (value is int) {
      normalizedValue = value;
    }
    if (normalizedValue == 0) {
      remove(node);
      return true;
    }
    return super.add(node, normalizedValue.toString());
  }

  @override
  bool canAdd(HtmlElement node, dynamic value) {
    return super.canAdd(node, value) || super.canAdd(node, int.tryParse(value.toString()));
  }

  @override
  int? value(HtmlElement node) {
    return int.tryParse(super.value(node) ?? '');
  }
}

final IndentClass = IndentAttributor();
