// NÂO REMOVA ESTE CODIGO COMENTADO
// import 'package:ngdart/angular.dart';
// import 'package:dart_quill/src/app/app_component.template.dart' as app;
// void main() {
//   runApp(app.AppComponentNgFactory);
// }
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;
import 'package:dart_quill/dart_quill_docx.dart' as docx;
import 'package:dart_quill/src/core/initialization.dart';
import 'package:dart_quill/src/core/quill.dart';
import 'package:dart_quill/src/core/theme.dart';
import 'package:dart_quill/src/platform/html_dom.dart';

void main() {
  initializeQuill();

  final actions = web.document.createElement('div');
  actions.setAttribute('style', 'margin: 8px 0; display: flex; gap: 8px;');
  web.document.body?.appendChild(actions);

  final host = web.document.createElement('div');
  web.document.body?.appendChild(host);

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
    [
      {'table': '3x3'},
    ],
    ['formula', 'code-block'],
    ['clean'],
  ];

  final container = HtmlDomElement(host);
  final modules = <String, dynamic>{
    'toolbar': <String, dynamic>{
      'container': defaultToolbar,
    },
  };

  final options = ThemeOptions(
    theme: 'snow',
    modules: modules,
  );

  final quill = Quill(container, options: options);
  quill.root.setAttribute('data-placeholder', 'placeholder');

  _addButton(actions, 'Abrir DOCX', () => _openDocx(quill));
  _addButton(actions, 'Exportar DOCX', () => _exportDocx(quill));
}

void _addButton(web.Element parent, String label, void Function() onClick) {
  final button = web.document.createElement('button');
  button.textContent = label;
  button.addEventListener(
    'click',
    ((web.Event _) => onClick()).toJS,
  );
  parent.appendChild(button);
}

void _openDocx(Quill quill) {
  final input = web.document.createElement('input') as web.HTMLInputElement;
  input.type = 'file';
  input.accept =
      '.docx,application/vnd.openxmlformats-officedocument.wordprocessingml.document';
  input.addEventListener(
    'change',
    ((web.Event _) {
      final file = input.files?.item(0);
      if (file == null) return;
      final reader = web.FileReader();
      reader.addEventListener(
        'load',
        ((web.Event _) {
          final buffer = (reader.result as JSArrayBuffer).toDart;
          final delta = docx.docxToDelta(buffer.asUint8List());
          quill.setContents(delta);
        }).toJS,
      );
      reader.readAsArrayBuffer(file);
    }).toJS,
  );
  input.click();
}

void _exportDocx(Quill quill) {
  final bytes = docx.deltaToDocx(quill.getContents());
  _download(
    bytes,
    'documento.docx',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  );
}

void _download(Uint8List bytes, String filename, String mimeType) {
  final blob = web.Blob(
    [bytes.toJS].toJS,
    web.BlobPropertyBag(type: mimeType),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
  anchor.href = url;
  anchor.download = filename;
  anchor.click();
  web.URL.revokeObjectURL(url);
}
