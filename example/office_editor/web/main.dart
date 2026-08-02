/// Demonstração do modo avançado do `dart_quill`.
///
/// O que este exemplo mostra, em uma tela, é a tese da arquitetura:
///
/// * o DOM é PROJEÇÃO — nada é lido de volta dele para o modelo;
/// * o PDF sai do MESMO `PageGraph` que a tela mostra, então a página 18 do
///   editor é a página 18 do arquivo;
/// * o layout é incremental — o rodapé mostra o custo real de cada tecla;
/// * a virtualização mantém só uma janela de páginas montada, e o número de
///   páginas no DOM fica visível para se poder conferir.
library;

import 'dart:convert';
import 'dart:js_interop';

import 'package:dart_quill/dart_quill_office.dart';
import 'package:dart_quill/src/platform/dom.dart';
import 'package:dart_quill/src/platform/platform.dart';
import 'package:web/web.dart' as web;

/// Uma instância só: `officeQuillSchema()` devolve um Schema NOVO a cada
/// chamada, e nós de schemas diferentes não se misturam.
final schema = officeQuillSchema();

late OfficeEditorView view;
late DomElement host;
late DomAdapter adapter;

void main() {
  adapter = domBindings.adapter;
  host = adapter.document.querySelector('#host')!;

  _wireToolbar();
  _mount(_sampleDocument(600), virtualize: true);
}

// -- documento de demonstração ------------------------------------------------

PMNode _paragraph(String text, {List<Mark>? marks}) => schema.node(
    'paragraph', null, Fragment.from([schema.text(text, marks)]));

PMNode _heading(int level, String text) => schema.node(
    'heading', {'level': level}, Fragment.from([schema.text(text)]));

PMNode _sampleDocument(int blocks) {
  final bold = schema.marks['bold']!.create();
  final children = <PMNode>[
    _heading(1, 'Estudo Técnico Preliminar'),
    schema.node(
        'paragraph',
        null,
        Fragment.from([
          schema.text('Este documento é gerado em memória para demonstrar o '),
          schema.text('modo avançado', [bold]),
          schema.text(': layout paginado próprio, edição sobre '
              'contenteditable e PDF a partir do mesmo grafo de páginas.'),
        ])),
  ];
  for (var i = 0; i < blocks; i++) {
    if (i % 25 == 0) {
      children.add(_heading(2, 'Seção ${i ~/ 25 + 1}'));
      continue;
    }
    children.add(_paragraph(
        'Parágrafo $i. O texto existe para ocupar a largura útil da página e '
        'forçar a quebra de linha a trabalhar com a métrica real da fonte, '
        'que é a mesma autoridade usada na geração do PDF.'));
  }
  return schema.node('doc', null, Fragment.from(children));
}

// -- montagem -----------------------------------------------------------------

/// Timbre e numeração de página — regiões PRÓPRIAS, não parte do corpo.
///
/// Elas repetem em todas as páginas e são inertes na projeção: a mesma
/// região aparecendo N vezes não pode virar N edições concorrentes do mesmo
/// nó.
PMNode _region(String text) => schema.node(
    'doc',
    null,
    Fragment.from([
      schema.node('paragraph', {'align': 'center'},
          Fragment.from([schema.text(text)]))
    ]));

void _mount(PMNode doc, {required bool virtualize}) {
  view = OfficeEditorView.withExtensions(
    host: host,
    doc: doc,
    adapter: adapter,
    extensions: officeDefaultExtensions(schema),
    composer: LayoutComposer(
      header: _region('PREFEITURA MUNICIPAL — Secretaria de Administração'),
      footer: _region('Página {PAGE} de {NUMPAGES}'),
    ),
    virtualization: virtualize ? const OfficeVirtualization(radius: 3) : null,
    scrollContainer: adapter.document.querySelector('#scroller'),
    onStateChange: (_) => _refreshStats(),
  );
  _refreshStats();
}

void _remount(PMNode doc) {
  view.dispose();
  final checkbox = web.document.getElementById('virtual') as web.HTMLInputElement;
  _mount(doc, virtualize: checkbox.checked);
}

// -- barra de ferramentas -----------------------------------------------------

void _on(String id, void Function() action) {
  web.document.getElementById(id)!.addEventListener(
      'click',
      (web.Event _) {
        action();
      }.toJS);
}

void _wireToolbar() {
  // Os comandos são os MESMOS que os atalhos disparam — a UI não tem um
  // caminho próprio para mudar o documento.
  for (final name in ['bold', 'italic', 'underline', 'undo', 'redo']) {
    _on(name, () => view.runCommand(name));
  }

  _on('reload', () {
    final select = web.document.getElementById('size') as web.HTMLSelectElement;
    _remount(_sampleDocument(int.parse(select.value)));
  });

  web.document.getElementById('virtual')!.addEventListener(
      'change',
      (web.Event _) {
        _remount(view.state.doc);
      }.toJS);

  _on('pdf', _generatePdf);

  final dialog = web.document.getElementById('deltaDialog') as web.HTMLDialogElement;
  // Membros de interop não podem virar tear-off: precisam de closure.
  _on('importDelta', () => dialog.showModal());
  _on('deltaCancel', () => dialog.close());
  _on('deltaOk', () {
    final text =
        (web.document.getElementById('deltaText') as web.HTMLTextAreaElement)
            .value;
    dialog.close();
    _importDelta(text);
  });
}

// -- ações --------------------------------------------------------------------

void _importDelta(String raw) {
  try {
    final decoded = jsonDecode(raw);
    final ops = decoded is Map ? decoded['ops'] as List : decoded as List;
    final imported = importQuillDelta(ops, schema);
    _remount(imported.doc);
    _note(imported.report.issues.isEmpty
        ? 'Delta importado sem perda.'
        : 'Delta importado com ${imported.report.issues.length} aviso(s): '
            '${imported.report.issues.first}');
  } catch (error) {
    _note('Delta inválido: $error');
  }
}

/// Gera o PDF a partir do grafo QUE JÁ ESTÁ NA TELA.
///
/// É o ponto do exemplo: não há segunda paginação. `fromPageGraph` recebe o
/// mesmo `PageGraph` que o DOM projetou, então o arquivo não pode divergir
/// do que o usuário viu. (O mesmo serviço roda no backend, sem browser — a
/// conversão não depende de plataforma.)
void _generatePdf() {
  final stopwatch = Stopwatch()..start();
  final result = OfficePdfService(title: 'Demonstração dart_quill')
      .fromPageGraph(view.pageGraph);
  stopwatch.stop();

  final blob = web.Blob(
      [result.bytes.toJS].toJS, web.BlobPropertyBag(type: 'application/pdf'));
  final url = web.URL.createObjectURL(blob);
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = url
    ..download = 'documento.pdf';
  anchor.click();
  web.URL.revokeObjectURL(url);

  _note('PDF com ${result.pageCount} páginas — as MESMAS da tela — em '
      '${stopwatch.elapsedMilliseconds} ms.');
}

// -- rodapé -------------------------------------------------------------------

void _text(String id, String value) =>
    web.document.getElementById(id)!.textContent = value;

void _note(String message) => _text('note', message);

void _refreshStats() {
  final graph = view.pageGraph;
  _text('pages', '${graph.pages.length}');
  _text('blocks', '${view.state.doc.childCount}');

  final mounted =
      web.document.querySelectorAll('.dq-office-page').length;
  final window = view.mountedWindow;
  _text(
      'mounted',
      window == null
          ? '$mounted (tudo)'
          : '$mounted de ${graph.pages.length} '
              '(${window.firstPage}..${window.lastPage})');

  // O tempo por tecla é medido recompondo o MESMO documento a partir do
  // grafo atual: é o custo real do caminho incremental.
  final stopwatch = Stopwatch()..start();
  LayoutComposer().composeIncremental(view.state.doc,
      previous: graph, changedFromDocPos: view.state.selection.from);
  stopwatch.stop();
  _text('ms', '${stopwatch.elapsedMicroseconds / 1000} ms');
}
