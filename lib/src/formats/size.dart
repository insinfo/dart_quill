import '../blots/abstract/blot.dart';
import 'abstract/attributor.dart';

final Map<String, dynamic> config = {
  'scope': Scope.INLINE,
  'whitelist': ['small', 'large', 'huge'],
};

class SizeClass extends ClassAttributor {
  SizeClass() : super('size', 'ql-size', config);
}

class SizeStyle extends StyleAttributor {
  SizeStyle() : super('size', 'font-size', {
    'scope': Scope.INLINE,
    'whitelist': ['10px', '18px', '32px'],
  });
}
