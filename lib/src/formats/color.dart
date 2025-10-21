import '../blots/abstract/blot.dart';
import 'abstract/attributor.dart';

final Map<String, dynamic> config = {
  'scope': Scope.INLINE,
};

class ColorClass extends ClassAttributor {
  ColorClass() : super('color', 'ql-color', config);
}

class ColorStyle extends ColorAttributor {
  ColorStyle() : super('color', 'color', config);
}
