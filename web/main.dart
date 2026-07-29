
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:web/web.dart' as web;
import 'package:dart_quill/dart_quill_docx.dart' as docx;
import 'package:dart_quill/src/core/initialization.dart';
import 'package:dart_quill/src/core/quill.dart';
import 'package:dart_quill/src/core/theme.dart';
import 'package:dart_quill/src/platform/html_dom.dart';
import 'package:dart_quill/src/platform/platform.dart';
import 'package:dart_quill/src/table_better/register.dart';

void main() {
  initializeQuill();
  registerTableBetter();

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

  final container = HtmlDomElement(host);
  final modules = <String, dynamic>{
    'toolbar': <String, dynamic>{
      'container': defaultToolbar,
    },
    'table': false,
    'table-better': <String, dynamic>{
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
  };

  final options = ThemeOptions(
    theme: 'snow',
    iconTheme: QuillIconTheme.svg,
    modules: modules,
  );

  final quill = Quill(container, options: options);
  quill.root.setAttribute('data-placeholder', 'placeholder');
  _exposeE2eHooks(quill);

  _addButton(actions, 'Abrir DOCX', () => _openDocx(quill));
  _addButton(actions, 'Exportar DOCX', () => _exportDocx(quill));
}

/// Read-only hooks consumed by `test/e2e` to assert the MODEL state after
/// real typing/clicking (the DOM alone can lie when reconciliation breaks).
void _exposeE2eHooks(Quill quill) {
  String contents() => jsonEncode(quill.getContents().toJson());
  String selectionOf() {
    final range = quill.getSelection();
    return range == null ? 'null' : '${range.index}:${range.length}';
  }

  web.window.setProperty('e2eGetContents'.toJS, contents.toJS);
  web.window.setProperty('e2eGetSelection'.toJS, selectionOf.toJS);

  // Temporary diagnostics for the E2E stabilization; harmless to keep.
  String diag() {
    final buffer = StringBuffer();
    try {
      final adapter = domBindings.adapter;
      buffer.write('supportsNative=${adapter.supportsNativeSelection};');
      buffer.write('hasFocus=${adapter.hasFocus(quill.root)};');
      final native = adapter.getNativeSelectionRange();
      buffer.write('nativeNull=${native == null};');
      if (native != null) {
        buffer.write('containsStart='
            '${quill.root.contains(native.startContainer)};');
        final normalized = quill.selection.normalizeNative(native);
        buffer.write('normalizedNull=${normalized == null};');
        if (normalized != null) {
          final range = quill.selection.normalizedToRange(normalized);
          buffer.write('range=${range?.index}:${range?.length};');
        }
      }
    } catch (error, stack) {
      buffer.write('ERROR=$error@${stack.toString().split('\n').first}');
    }
    return buffer.toString();
  }

  String pump() {
    try {
      final change = quill.update();
      return jsonEncode(change.toJson());
    } catch (error, stack) {
      return 'ERROR=$error@${stack.toString().split('\n').take(4).join(' | ')}';
    }
  }

  web.window.setProperty('e2eDiag'.toJS, diag.toJS);
  web.window.setProperty('e2ePump'.toJS, pump.toJS);
}

void _addButton(web.Element parent, String label, void Function() onClick) {
  final button = web.document.createElement('button');
  button.setAttribute('type', 'button');
  button.className = 'btn btn-primary btn-sm';
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
