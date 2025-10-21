import '../blots/abstract/blot.dart';
import 'abstract/attributor.dart';

final Map<String, dynamic> config = {
  'scope': Scope.BLOCK,
  'whitelist': ['right', 'center', 'justify'],
};

class AlignAttribute extends Attributor {
  AlignAttribute() : super('align', 'align', config);
}

class AlignClass extends ClassAttributor {
  AlignClass() : super('align', 'ql-align', config);
}

class AlignStyle extends StyleAttributor {
  AlignStyle() : super('align', 'text-align', config);
}
