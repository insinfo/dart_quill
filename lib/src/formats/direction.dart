import '../blots/abstract/blot.dart';
import 'abstract/attributor.dart';

final Map<String, dynamic> directionConfig = {
  'scope': Scope.BLOCK,
  'whitelist': ['rtl']
};

class DirectionAttribute extends Attributor {
  static final DirectionAttribute instance = DirectionAttribute._();
  
  DirectionAttribute._() : super('direction', 'dir', directionConfig);
}

class DirectionClass extends ClassAttributor {
  static final DirectionClass instance = DirectionClass._();
  
  DirectionClass._() : super('direction', 'ql-direction', directionConfig);
}

class DirectionStyle extends StyleAttributor {
  static final DirectionStyle instance = DirectionStyle._();
  
  DirectionStyle._() : super('direction', 'direction', directionConfig);
}
