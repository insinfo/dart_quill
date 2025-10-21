import '../blots/abstract/blot.dart';
import 'abstract/attributor.dart';

final Map<String, dynamic> config = {
  'scope': Scope.BLOCK,
  'whitelist': ['rtl'],
};

class DirectionAttribute extends Attributor {
  DirectionAttribute() : super('direction', 'dir', config);
}

class DirectionClass extends ClassAttributor {
  DirectionClass() : super('direction', 'ql-direction', config);
}

class DirectionStyle extends StyleAttributor {
  DirectionStyle() : super('direction', 'direction', config);
}
