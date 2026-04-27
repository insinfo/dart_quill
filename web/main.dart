// NÂO REMOVA ESTE CODIGO COMENTADO
// import 'package:ngdart/angular.dart';
// import 'package:dart_quill/src/app/app_component.template.dart' as app;
// void main() {
//   runApp(app.AppComponentNgFactory);
// }
import 'dart:html' as html;
import 'package:dart_quill/src/core/initialization.dart';
import 'package:dart_quill/src/core/quill.dart';
import 'package:dart_quill/src/core/theme.dart';
import 'package:dart_quill/src/platform/html_dom.dart';

void main() {
  initializeQuill();
  final host = html.DivElement();
  html.document.body?.append(host);

  final defaultToolbar = [
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

  final container = HtmlDomElement(host);
  final modules = <String, dynamic>{
    if (true)
      'toolbar': <String, dynamic>{
        'container': defaultToolbar,
      },
  };
  String theme = 'snow';

  final options = ThemeOptions(
    theme: theme,
    modules: modules,
  );

  final _quill = Quill(container, options: options);
  String placeholderText = 'placeholder';
  if (placeholderText.isNotEmpty) {
    _quill.root.setAttribute('data-placeholder', placeholderText);
  }
}
