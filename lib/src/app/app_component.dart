import 'package:ngdart/angular.dart';
import 'package:ngforms/angular_forms.dart';

import 'quill_editor_component.dart';

@Component(
  selector: 'my-app',
  template: '''
    <div class="app-shell">
      <h1>Welcome to {{title}}</h1>
      <quill-editor [(value)]="content" placeholder="Start writing..."></quill-editor>
      <section class="preview">
        <h2>Preview</h2>
        <pre>{{content}}</pre>
      </section>
    </div>
  ''',
  directives: [
    formDirectives,
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
    .preview pre {
      background: #f5f5f5;
      padding: 0.75rem;
      border-radius: 4px;
    }
    '''
  ],
)
class AppComponent {
  var title = 'Dart Quill';
  String content = '';
}