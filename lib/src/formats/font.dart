import 'abstract/attributor.dart';
import 'dart:html';

final Map<String, dynamic> config = {
  'scope': Scope.INLINE,
  'whitelist': ['serif', 'monospace'],
};

class FontClass extends ClassAttributor {
  FontClass() : super('font', 'ql-font', config);
}

class FontStyleAttributor extends StyleAttributor {
  FontStyleAttributor() : super('font', 'font-family', config);

  @override
  dynamic value(HtmlElement node) {
    return super.value(node).replaceAll(RegExp(r'["']'), '');
  }
}
