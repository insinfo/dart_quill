@TestOn('browser')
library office_word_editor_test;

/// O componente Word completo em Chrome REAL: chrome montado pela
/// biblioteca, clique de verdade na ribbon, zoom mudando a escala da
/// projeção — o que o consumidor obtém com uma chamada.
import 'dart:async';
import 'dart:js_interop';

import 'package:dart_quill/dart_quill_office.dart';
import 'package:dart_quill/src/platform/dom.dart';
import 'package:dart_quill/src/platform/platform.dart';
import 'package:test/test.dart';
import 'package:web/web.dart' as web;

void main() {
  final schema = officeQuillSchema();
  final adapter = domBindings.adapter;

  late DomElement host;
  OfficeWordEditor? editor;

  setUpAll(() async {
    // Como numa aplicação real: o chrome vem dos ASSETS do pacote. O
    // servidor do `dart test` serve `packages/...` na raiz da suíte.
    for (final href in [
      'packages/dart_quill/assets/office_word_editor.css',
      'packages/dart_quill/assets/office_word_icons.css',
    ]) {
      final link = web.document.createElement('link') as web.HTMLLinkElement
        ..rel = 'stylesheet'
        ..href = href;
      final loaded = Completer<void>();
      link.addEventListener('load', ((web.Event _) => loaded.complete()).toJS);
      link.addEventListener(
          'error',
          ((web.Event _) =>
                  loaded.completeError(StateError('falhou ao carregar $href')))
              .toJS);
      web.document.head!.append(link);
      await loaded.future;
    }
  });

  setUp(() {
    host = adapter.document.createElement('div');
    adapter.document.body.append(host);
  });

  tearDown(() {
    editor?.dispose();
    editor = null;
    host.remove();
  });

  PMNode docOf(int blocks) => schema.node(
      'doc',
      null,
      Fragment.from([
        for (var i = 0; i < blocks; i++)
          schema.node(
              'paragraph',
              null,
              Fragment.from(
                  [schema.text('Parágrafo $i com texto real para paginar.')]))
      ]));

  OfficeWordEditor mount({int blocks = 40}) => editor = OfficeWordEditor.mount(
        host: host,
        adapter: adapter,
        document: docOf(blocks),
        schema: schema,
        options: const OfficeWordEditorOptions(
            headerText: 'PREFEITURA', footerText: 'Página {PAGE}'),
      );

  test('uma chamada monta o editor com cara de Word', () {
    mount();
    final ribbon = web.document.querySelector('.dq-office-ribbon');
    final ruler = web.document.querySelector('.dq-office-ruler');
    final page = web.document.querySelector('.dq-office-page');
    expect(ribbon, isNotNull);
    expect(ruler, isNotNull);
    expect(page, isNotNull);

    // Geometria real: a página A4 em 100% tem ~794 px de largura, e a
    // régua acompanha.
    final pageWidth = (page as web.HTMLElement).getBoundingClientRect().width;
    expect(pageWidth, closeTo(794, 2));
    final center = web.document.querySelector('.dq-office-ruler-center')
        as web.HTMLElement;
    expect(center.getBoundingClientRect().width, closeTo(pageWidth, 2));
    // ALINHAMENTO: o centro da régua e a página compartilham o eixo — a
    // diferença de left tem de ser subpixel.
    final page2 =
        web.document.querySelector('.dq-office-page') as web.HTMLElement;
    expect(center.getBoundingClientRect().left,
        closeTo(page2.getBoundingClientRect().left, 1.5));

    // A horizontal pertence ao chrome: fica colada sob a ribbon, fora do
    // viewport rolável. A vertical nasce no canto esquerdo do viewport e
    // acompanha apenas a página ativa.
    final ribbonRect = (ribbon as web.HTMLElement).getBoundingClientRect();
    final rulerWrap =
        web.document.querySelector('.dq-office-ruler-wrap') as web.HTMLElement;
    final rulerRect = rulerWrap.getBoundingClientRect();
    expect(rulerRect.top, closeTo(ribbonRect.bottom, 1));
    final canvas =
        web.document.querySelector('.dq-office-canvas') as web.HTMLElement;
    final vertical =
        web.document.querySelector('.dq-office-vruler-slot') as web.HTMLElement;
    expect(vertical.getBoundingClientRect().left,
        closeTo(canvas.getBoundingClientRect().left, 1));
    expect(vertical.getBoundingClientRect().top,
        closeTo(page2.getBoundingClientRect().top, 1));
  });

  test('clique REAL no botão de negrito formata a seleção nativa', () {
    final editor = mount(blocks: 3);
    const map = OfficeDomPositionMap();
    final pages = host.querySelector('.dq-office-pages')!;
    final from = map.domPositionFor(pages, 1)!;
    final to = map.domPositionFor(pages, 1 + 9)!;
    adapter.setSelectionByNodes(from.node, from.offset, to.node, to.offset);

    (web.document.querySelector('.dq-office-b') as web.HTMLElement).click();

    expect(editor.state.doc.child(0).firstChild?.marks.map((m) => m.type.name),
        contains('bold'));
  });

  test('zoom muda a largura REAL da página, não o grafo', () {
    final editor = mount();
    final before =
        (web.document.querySelector('.dq-office-page') as web.HTMLElement)
            .getBoundingClientRect()
            .width;
    final pagesBefore = editor.pageGraph.pages.length;

    editor.setZoom(1.5);

    final after =
        (web.document.querySelector('.dq-office-page') as web.HTMLElement)
            .getBoundingClientRect()
            .width;
    expect(after, closeTo(before * 1.5, 3));
    expect(editor.pageGraph.pages.length, pagesBefore);
  });

  test('digitação REAL continua funcionando sob o chrome', () {
    final editor = mount(blocks: 3);
    const map = OfficeDomPositionMap();
    final pages = host.querySelector('.dq-office-pages')!;
    final position = map.domPositionFor(pages, 1)!;
    final surface = web.document.querySelector('.dq-office-page-content')
        as web.HTMLElement;
    surface.focus();
    adapter.setSelectionByNodes(
        position.node, position.offset, position.node, position.offset);

    surface.dispatchEvent(web.InputEvent(
        'beforeinput',
        web.InputEventInit(
            inputType: 'insertText',
            data: 'X',
            bubbles: true,
            cancelable: true)));

    expect(editor.state.doc.child(0).textContent, startsWith('X'));
  });
}
