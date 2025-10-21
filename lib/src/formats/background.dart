import '../blots/abstract/blot.dart';
import 'abstract/attributor.dart';

final Map<String, dynamic> config = {
  'scope': Scope.INLINE,
};

class BackgroundClass extends ClassAttributor {
  BackgroundClass() : super('background', 'ql-bg', config);
}

class BackgroundStyle extends ColorAttributor {
  BackgroundStyle() : super('background', 'background-color', config);
}
