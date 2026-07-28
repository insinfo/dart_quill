import '../blots/abstract/blot.dart';
import 'abstract/attributor.dart';

final Map<String, dynamic> config = {
  'scope': Scope.INLINE,
  'whitelist': ['small', 'large', 'huge'],
};

class SizeClass extends ClassAttributor {
  static final SizeClass instance = SizeClass._();

  SizeClass._() : super('size', 'ql-size', config);
}

class SizeStyle extends StyleAttributor {
  static final SizeStyle instance = SizeStyle._();

  SizeStyle._()
      : super('size', 'font-size', {
          'scope': Scope.INLINE,
          'whitelist': ['10px', '18px', '32px'],
        });
}
