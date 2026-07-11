import 'package:ngdart/angular.dart';

import 'quill_editor_component.dart';

@Component(
  selector: 'my-app',
  template: '''
    <div class="container-fluid py-4">
      <div class="card shadow-sm">
        <div class="card-header">
          <h1 class="mb-0">{{title}}</h1>
        </div>
        <div class="card-body">
          <quill-editor placeholder="Comece a escrever..."></quill-editor>
        </div>
      </div>
    </div>
  ''',
  directives: [
    QuillEditorComponent,
  ],
  styles: [
    '''
    quill-editor {
      display: block;
    }
    '''
  ],
)
class AppComponent {
  var title = 'Dart Quill com Limitless';
}
