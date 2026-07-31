
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:web/web.dart' as web;
import 'package:dart_quill/dart_quill_docx.dart' as docx;
import 'package:dart_quill/src/core/emitter.dart';
import 'package:dart_quill/src/core/initialization.dart';
import 'package:dart_quill/src/core/selection.dart' show Range;
import 'package:dart_quill/src/delta/delta.dart';
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
    // The Syntax module is opt-in upstream; the highlighter is bundled here.
    'syntax': true,
    'table': false,
    'table-better': <String, dynamic>{
      // Upstream defaults to en_US; the plugin's `language` option is what
      // selects a locale (all 16 are bundled).
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
  };

  final options = ThemeOptions(
    theme: 'snow',
    iconTheme: QuillIconTheme.svg,
    modules: modules,
  );

  final quill = Quill(container, options: options);
  _loadSampleDocument(quill);
  _exposeE2eHooks(quill);

  _addButton(actions, 'Abrir DOCX', () => _openDocx(quill));
  _addButton(actions, 'Exportar DOCX', () => _exportDocx(quill));
}

/// Content that exercises what needs a browser to be believed: a highlighted
/// code block and a rendered formula, neither of which loads anything from the
/// network.
void _loadSampleDocument(Quill quill) {
  final delta = Delta()
    ..insert('dart_quill')
    ..insert('\n', {'header': '1'})
    ..insert('Realce de sintaxe e fórmulas ')
    ..insert('sem dependências externas', {'bold': true})
    ..insert(': o realçador e o renderizador de LaTeX fazem parte do pacote.\n')
    ..insert("const quill = Quill('#editor', { theme: 'snow' });")
    ..insert('\n', {'code-block': 'javascript'})
    ..insert('// o <select> ao lado troca a linguagem')
    ..insert('\n', {'code-block': 'javascript'})
    ..insert('Fórmula: ')
    ..insert({'formula': r'x = \frac{-b \pm \sqrt{b^2 - 4ac}}{2a}'})
    ..insert(' e um somatório ')
    ..insert({'formula': r'\sum_{n=1}^{\infty} \frac{1}{n^2} = \frac{\pi^2}{6}'})
    ..insert('.\n');
  quill.setContents(delta);
  quill.history.clear();
}

/// Read-only hooks consumed by `test/e2e` to assert the MODEL state after
/// real typing/clicking (the DOM alone can lie when reconciliation breaks).
void _exposeE2eHooks(Quill quill) {
  String contents() => jsonEncode(quill.getContents().toJson());
  String selectionOf() {
    final range = quill.getSelection();
    return range == null ? 'null' : '${range.index}:${range.length}';
  }

  // Test SETUP only (the behaviour under test is always driven by real
  // input): a blank document, since deleting the text with Ctrl+A+Delete
  // leaves the last line's block format behind, as Quill intends.
  void reset() {
    quill.setContents(Delta()..insert('\n'));
    quill.history.clear();
  }

  // Test SETUP only: loads a document the way an application would after
  // fetching it from a database, so rendering-on-load (KaTeX, syntax) is
  // exercised instead of only the insertion path.
  void setContents(String json) {
    final ops = jsonDecode(json) as List;
    quill.setContents(Delta.fromJson(ops));
  }

  // The upstream E2E specs drive the editor through `window.quill.*`. A Dart
  // object cannot be handed to JS, so the same surface is exposed as hooks —
  // one per API the specs use, with the same arguments.
  void updateContents(String json, String source) {
    final ops = jsonDecode(json) as List;
    quill.updateContents(Delta.fromJson(ops), source: source);
  }

  void setSelection(int index, int length) {
    quill.setSelection(Range(index, length), source: EmitterSource.API);
  }

  void cutoffHistory() => quill.history.cutoff();

  void setHistoryUserOnly(bool value) {
    quill.history.options.userOnly = value;
  }

  web.window.setProperty('e2eGetContents'.toJS, contents.toJS);
  web.window.setProperty('e2eGetSelection'.toJS, selectionOf.toJS);
  web.window.setProperty('e2eReset'.toJS, reset.toJS);
  web.window.setProperty('e2eSetContents'.toJS, setContents.toJS);
  web.window.setProperty('e2eUpdateContents'.toJS, updateContents.toJS);
  web.window.setProperty('e2eSetSelection'.toJS, setSelection.toJS);
  web.window.setProperty('e2eCutoffHistory'.toJS, cutoffHistory.toJS);
  web.window.setProperty('e2eSetHistoryUserOnly'.toJS, setHistoryUserOnly.toJS);

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
