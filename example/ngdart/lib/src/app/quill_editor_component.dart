import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:dart_quill/dart_quill.dart' hide Input;
import 'package:dart_quill/dart_quill_docx.dart' as docx;
import 'package:dart_quill/dart_quill_pdf.dart' as pdf;
import 'package:dart_quill/dart_quill_table_better.dart';
import 'package:dart_quill/src/platform/html_dom.dart';
import 'package:ngdart/angular.dart';
import 'package:web/web.dart' as web;

@Component(
  selector: 'quill-editor',
  template: '''
    <div class="mb-2 d-flex flex-wrap gap-1" *ngIf="showActions">
      <button type="button" class="btn btn-sm btn-outline-primary"
              (click)="importDocx()">Importar DOCX</button>
      <button type="button" class="btn btn-sm btn-outline-primary"
              (click)="importDelta()">Importar Delta</button>
      <button type="button" class="btn btn-sm btn-outline-secondary"
              (click)="exportDocx()">Exportar DOCX</button>
      <button type="button" class="btn btn-sm btn-outline-secondary"
              (click)="exportDelta()">Exportar Delta</button>
      <button type="button" class="btn btn-sm btn-outline-secondary"
              (click)="exportPdf()">Exportar PDF</button>
      <button type="button" class="btn btn-sm btn-primary"
              (click)="print()">Imprimir</button>
    </div>
    <div id="quillEditorHost" class="quill-editor-host"></div>
  ''',
  directives: [coreDirectives],
  styles: [
    // --dq-editor-max-height dá ao editor uma caixa com rolagem própria; sem
    // ela o container cresce indefinidamente e só a página rola.
    ':host { display: block; --dq-editor-max-height: 60vh; }',
    '.quill-editor-host { min-height: 320px; }',
  ],
  changeDetection: ChangeDetectionStrategy.onPush,
)
class QuillEditorComponent implements AfterViewInit {
  QuillEditorComponent();

  // Mirrors web/main.dart, the configuration exercised by the E2E suite:
  // the table button comes from the table-better module ('table-better' in the
  // toolbar + toolbarTable), not from the basic 'table' module.
  /// Famílias e tamanhos do Word. O pacote nasce com a whitelist enxuta do
  /// upstream (`serif`/`monospace`, três tamanhos em px), que descarta em
  /// silêncio o `Arial 10` de qualquer DOCX; a aplicação declara o que aceita.
  static const List<String> _wordFonts = [
    'Arial',
    'Calibri',
    'Times New Roman',
    'Verdana',
    'Georgia',
    'Courier New',
    'Inter',
  ];
  static const List<String> _wordSizes = [
    '8pt', '9pt', '10pt', '11pt', '12pt', '14pt', '16pt', '18pt', //
    '20pt', '22pt', '24pt', '26pt', '28pt', '36pt', '48pt', '72pt',
  ];

  static final List<List<dynamic>> _defaultToolbar = [
    [
      {
        'header': [false, '1', '2', '3']
      },
      {'font': _wordFonts},
      {'size': _wordSizes},
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
  bool showActions = true;

  @Input()
  String theme = 'snow';

  @Input()
  String? placeholder;

  Quill? _quill;

  @override
  void ngAfterViewInit() {
    initializeQuill();
    // Fonte e tamanho por ESTILO (font-family / font-size inline), não por
    // classe: é o que sobrevive a um documento de terceiros, em que a família
    // e o tamanho vêm do arquivo. O padrão do upstream é por classe, com uma
    // whitelist de três nomes.
    Quill.register(FontStyleAttributor.instance);
    Quill.register(SizeStyle.instance);
    setFontWhitelist(_wordFonts);
    // Sem whitelist de tamanho: o importador de DOCX converte os pontos do
    // Word para px, então qualquer valor precisa passar. A toolbar continua
    // oferecendo só os tamanhos padrão.
    setSizeStyleWhitelist(null);
    registerTableBetter();
    final host = web.document.getElementById('quillEditorHost');
    if (host == null) {
      return;
    }

    final container = HtmlDomElement(host);
    // The toolbar entry must come BEFORE table-better: modules are built in
    // map order and registerToolbarTable looks the toolbar up at construction
    // time (same order sensitivity as upstream quill-table-better).
    final modules = <String, dynamic>{
      if (showToolbar)
        'toolbar': <String, dynamic>{
          'container': _defaultToolbar,
        },
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

  // --- import ---------------------------------------------------------------

  void importDocx() => _pickFile(
        '.docx,application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        (bytes) => _quill?.setContents(docx.docxToDelta(bytes)),
      );

  void importDelta() => _pickFile(
        '.json,application/json',
        (bytes) {
          final decoded = jsonDecode(utf8.decode(bytes));
          // Aceita tanto o envelope {"ops":[...]} quanto a lista crua: os dois
          // circulam por aí, e o Delta.fromJson só entende a lista.
          final ops = decoded is Map ? decoded['ops'] as List : decoded as List;
          _quill?.setContents(Delta.fromJson(ops));
        },
      );

  void _pickFile(String accept, void Function(Uint8List bytes) onBytes) {
    final input = web.document.createElement('input') as web.HTMLInputElement;
    input.type = 'file';
    input.accept = accept;
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
            onBytes(buffer.asUint8List());
          }).toJS,
        );
        reader.readAsArrayBuffer(file);
      }).toJS,
    );
    input.click();
  }

  // --- export ---------------------------------------------------------------

  void exportDocx() {
    final quill = _quill;
    if (quill == null) return;
    _download(
      docx.deltaToDocx(quill.getContents()),
      'documento.docx',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    );
  }

  void exportDelta() {
    final quill = _quill;
    if (quill == null) return;
    final json = jsonEncode({'ops': quill.getContents().toJson()});
    _download(
      Uint8List.fromList(utf8.encode(json)),
      'documento.delta.json',
      'application/json',
    );
  }

  void exportPdf() {
    final quill = _quill;
    if (quill == null) return;
    _download(pdf.deltaToPdf(quill.getContents()), 'documento.pdf',
        'application/pdf');
  }

  // --- print ----------------------------------------------------------------

  /// Converte o documento em PDF e manda imprimir por um iframe oculto — sem
  /// abrir aba e sem servidor. O iframe precisa ficar no DOM (um display:none
  /// impediria a impressão), então ele é dimensionado a zero e removido depois
  /// que a caixa de impressão fecha.
  void print() {
    final quill = _quill;
    if (quill == null) return;
    final bytes = pdf.deltaToPdf(quill.getContents());
    final blob = web.Blob(
      [bytes.toJS].toJS,
      web.BlobPropertyBag(type: 'application/pdf'),
    );
    final url = web.URL.createObjectURL(blob);

    final frame = web.document.createElement('iframe') as web.HTMLIFrameElement;
    frame.setAttribute('aria-hidden', 'true');
    frame.style.cssText =
        'position:fixed;right:0;bottom:0;width:0;height:0;border:0;';
    // `src` ANTES de anexar: um iframe sem src dispara um `load` de
    // about:blank assim que entra no DOM, e imprimir nesse momento abria uma
    // primeira caixa de impressão com a página em branco, antes da do PDF.
    // A flag é o cinto de segurança para navegadores que emitam `load` mais
    // de uma vez.
    var printed = false;
    frame.addEventListener(
      'load',
      ((web.Event _) {
        if (printed) return;
        final view = frame.contentWindow;
        if (view == null) return;
        printed = true;
        view.focus();
        view.print();
      }).toJS,
    );
    frame.src = url;
    web.document.body?.appendChild(frame);

    // O objeto de URL e o iframe só podem sair depois que o diálogo do
    // navegador terminou de ler o documento.
    web.window.addEventListener(
      'focus',
      ((web.Event _) {
        web.URL.revokeObjectURL(url);
        frame.remove();
      }).toJS,
      _once,
    );
  }

  static final JSAny _once = (<String, Object>{'once': true}).jsify()!;

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
}
