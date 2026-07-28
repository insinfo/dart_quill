import '../blots/abstract/blot.dart';
import 'abstract/attributor.dart';

final Map<String, dynamic> config = {
  'scope': Scope.INLINE,
};

class BackgroundClass extends ClassAttributor {
  static final BackgroundClass instance = BackgroundClass._();

  BackgroundClass._() : super('background', 'ql-bg', config);
}

class BackgroundStyle extends ColorAttributor {
  static final BackgroundStyle instance = BackgroundStyle._();

  BackgroundStyle._() : super('background', 'background-color', config);
}
