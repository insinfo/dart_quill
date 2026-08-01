import 'package:dart_quill/dart_quill.dart' hide Input;
import 'package:dart_quill/dart_quill_table_better.dart';
import 'package:dart_quill/src/platform/html_dom.dart';
import 'package:ngdart/angular.dart';
import 'package:web/web.dart' as web;

@Component(
  selector: 'quill-editor',
  template: '<div id="quillEditorHost" class="quill-editor-host"></div>',
  styles: [
    ':host { display: block; }',
    '.quill-editor-host { min-height: 320px; }',
  ],
  changeDetection: ChangeDetectionStrategy.onPush,
)
class QuillEditorComponent implements AfterViewInit {
  QuillEditorComponent();

  // Mirrors web/main.dart, the configuration exercised by the E2E suite:
  // the table button comes from the table-better module ('table-better' in the
  // toolbar + toolbarTable), not from the basic 'table' module.
  static const List<List<dynamic>> _defaultToolbar = [
    [
      {
        'header': [false, '1', '2', '3']
      },
      {'font': []},
    ],
    ['bold', 'italic', 'underline'],
    [
      {'color': []},
      {'background': []},
    ],
    [
      {'list': 'ordered'},
      {'list': 'bullet'},
      {'align': []},
    ],
    ['link', 'image', 'video'],
    ['table-better'],
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

  @override
  void ngAfterViewInit() {
    initializeQuill();
    registerTableBetter();
    final host = web.document.getElementById('quillEditorHost');
    if (host == null) {
      return;
    }

    final container = HtmlDomElement(host);
    final modules = <String, dynamic>{
      'syntax': true,
      'table': false,
      'table-better': <String, dynamic>{
        'language': 'pt_BR',
        'menus': <String>[
          'column',
          'row',
          'merge',
          'table',
          'cell',
          'wrap',
          'copy',
          'delete',
        ],
        'toolbarTable': true,
      },
      if (showToolbar)
        'toolbar': <String, dynamic>{
          'container': _defaultToolbar,
        },
    };

    final options = ThemeOptions(
      theme: theme,
      iconTheme: QuillIconTheme.svg,
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
