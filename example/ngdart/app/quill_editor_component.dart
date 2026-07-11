import 'package:dart_quill/dart_quill.dart';
import 'package:dart_quill/src/platform/html_dom.dart';
import 'package:ngdart/angular.dart';
import 'package:web/web.dart' as web;

@Component(
  selector: 'quill-editor',
  template: '<div id="quillEditorHost" class="quill-editor-host"></div>',
  styles: [
    ':host { display: block; }',
    '.quill-editor-host { min-height: 200px; }',
  ],
  changeDetection: ChangeDetectionStrategy.onPush,
)
class QuillEditorComponent implements AfterViewInit {
  QuillEditorComponent();

  static const List<List<dynamic>> _defaultToolbar = [
    [
      {
        'header': [false, '1', '2', '3']
      },
      {'font': []},
    ],
    ['bold', 'italic', 'underline'],
    [
      {'list': 'ordered'},
      {'list': 'bullet'},
      {'align': []},
    ],
    ['link', 'image', 'video'],
    ['formula', 'code-block'],
    ['clean'],
  ];

  @Input()
  bool showToolbar = true;

  @Input()
  String theme = 'snow';

  @Input()
  String? placeholder;

  Quill? _quill;

  void ngAfterViewInit() {
    initializeQuill();
    final host = web.document.getElementById('quillEditorHost');
    if (host == null) {
      return;
    }

    final container = HtmlDomElement(host);
    final modules = <String, dynamic>{
      if (showToolbar)
        'toolbar': <String, dynamic>{
          'container': _defaultToolbar,
        },
    };

    final options = ThemeOptions(
      theme: theme,
      modules: modules,
    );

    _quill = Quill(container, options: options);
    final placeholderText = placeholder;
    if (placeholderText != null && placeholderText.isNotEmpty) {
      _quill!.root.setAttribute('data-placeholder', placeholderText);
    }
  }

  Quill? get quill => _quill;
}
