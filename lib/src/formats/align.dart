import '../blots/abstract/blot.dart';
import '../platform/dom.dart';
import 'abstract/attributor.dart';

final Map<String, dynamic> alignConfig = {
  'scope': Scope.BLOCK,
  'whitelist': ['right', 'center', 'justify']
};

class AlignAttribute extends Attributor {
  static final AlignAttribute instance = AlignAttribute._();
  
  AlignAttribute._() : super('align', 'align', alignConfig);
}

class AlignClass extends ClassAttributor {
  static final AlignClass instance = AlignClass._();
  
  AlignClass._() : super('align', 'ql-align', alignConfig);
}

class AlignStyle extends StyleAttributor {
  static final AlignStyle instance = AlignStyle._();
  
  AlignStyle._() : super('align', 'text-align', alignConfig);

  @override
  String? value(DomElement domNode) {
    final current = super.value(domNode) as String?;
    if (current == null) return null;
    return alignConfig['whitelist'].contains(current) ? current : '';
  }
}
