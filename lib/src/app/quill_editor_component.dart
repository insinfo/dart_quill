import 'dart:html' as html;

import 'package:ngdart/angular.dart';

import '../core/initialization.dart';
import '../core/quill.dart';
import '../core/theme.dart';
import '../platform/html_dom.dart';

@Component(
  selector: 'quill-editor',
  template: '<div class="quill-editor-host" #editorHost></div>',
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
      {'header': '1'},
      {'header': '2'},
      {'header': '3'},
      {'header': false},
    ],
    ['bold', 'italic', 'underline', 'strike'],
    [
      {'list': 'ordered'},
      {'list': 'bullet'},
    ],
    ['link', 'image', 'code'],
    ['clean'],
  ];

  @ViewChild('editorHost')
  html.DivElement? editorHost;

  @Input()
  bool showToolbar = true;

  @Input()
  String theme = 'snow';

  @Input()
  String? placeholder;

  Quill? _quill;

  void ngAfterViewInit() {
    initializeQuill();
    final host = editorHost;
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
