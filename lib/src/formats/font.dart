import '../blots/abstract/blot.dart';
import '../platform/dom.dart';
import 'abstract/attributor.dart';

final Map<String, dynamic> fontConfig = {
  'scope': Scope.INLINE,
  'whitelist': ['serif', 'monospace']
};

class FontClass extends ClassAttributor {
  static final FontClass instance = FontClass._();
  
  FontClass._() : super('font', 'ql-font', fontConfig);
}

class FontStyleAttributor extends StyleAttributor {
  static final FontStyleAttributor instance = FontStyleAttributor._();
  
  FontStyleAttributor._() : super('font', 'font-family', fontConfig);

  @override
  String? value(DomElement node) {
    final raw = super.value(node) as String?;
    if (raw == null) return null;
    return raw.replaceAll('"', '').replaceAll("'", '');
  }
}
