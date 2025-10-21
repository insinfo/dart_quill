

import 'package:ngdart/angular.dart';
import 'package:ngforms/angular_forms.dart';

@Component(
  selector: 'my-app',
  template: '''
    <h1>Welcome to {{title}}</h1>
  ''',
  directives: [formDirectives],
)
class AppComponent {
  var title = 'Dart Quill';
}