import '../blots/abstract/blot.dart';
import 'abstract/attributor.dart';

final Map<String, dynamic> colorConfig = {
  'scope': Scope.INLINE,
};

class ColorClass extends ClassAttributor {
  static final ColorClass instance = ColorClass._();

  ColorClass._() : super('color', 'ql-color', colorConfig);
}

class ColorStyle extends ColorAttributor {
  static final ColorStyle instance = ColorStyle._();

  ColorStyle._() : super('color', 'color', colorConfig);
}
