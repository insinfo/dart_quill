import 'package:ngdart/angular.dart';

import 'quill_editor_component.dart';

@Component(
  selector: 'my-app',
  template: '''
    <div class="app-shell">
      <h1>Welcome to {{title}}</h1>
      <quill-editor placeholder="Start writing..."></quill-editor>
    </div>
  ''',
  directives: [
    QuillEditorComponent,
  ],
  styles: [
    '''
    .app-shell {
      padding: 1rem;
      font-family: Arial, sans-serif;
    }
    quill-editor {
      display: block;
      margin-bottom: 1rem;
    }
    '''
  ],
)
class AppComponent {
  var title = 'Dart Quill';
}
