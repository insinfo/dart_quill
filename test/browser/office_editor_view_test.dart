@TestOn('browser')
library office_editor_view_test;

/// O laço de edição do modo avançado contra um browser REAL.
///
/// O evento é um `InputEvent` de verdade, despachado na superfície
/// `contenteditable` focada, e sobe até o listener como o Chrome faria; a
/// seleção é a nativa e a projeção é reconstruída a cada transação. Se o
/// ciclo entrada→modelo→layout→DOM→seleção estiver furado em qualquer
/// ponto, o caret escorrega ou o texto some — é isso que estes testes
/// pegam.
///
/// Por que NÃO `execCommand`: medido neste Chrome headless, ele devolve
/// `true` e **não emite `beforeinput`** — um teste construído sobre ele
/// mediria o vazio e passaria por acidente.
import 'package:dart_quill/dart_quill_office.dart';
import 'package:dart_quill/src/platform/dom.dart';
import 'package:dart_quill/src/platform/platform.dart';
import 'package:test/test.dart';
import 'package:web/web.dart' as web;

void main() {
  final schema = officeQuillSchema();
  final adapter = domBindings.adapter;

  late DomElement host;
  late web.HTMLElement hostElement;
  OfficeEditorView? view;

  setUp(() {
    host = adapter.document.createElement('div');
    adapter.document.body.append(host);
    hostElement = web.document.body!.lastElementChild! as web.HTMLElement;
  });

  tearDown(() {
    view?.dispose();
    view = null;
    host.remove();
  });

  PMNode docOf(List<PMNode> blocks) =>
      schema.node('doc', null, Fragment.from(blocks));

  PMNode paragraph(String text) =>
      schema.node('paragraph', null, Fragment.from([schema.text(text)]));

  OfficeEditorView mount(PMNode doc) {
    final state = EditorState.create(EditorStateConfig(doc: doc));
    return view = OfficeEditorView(host: host, state: state, adapter: adapter);
  }

  /// Foca a superfície editável NATIVA.
  web.HTMLElement focusSurface() {
    final content = hostElement.querySelector('.dq-office-page-content')!
        as web.HTMLElement;
    content.focus();
    return content;
  }

  /// Dispara o `beforeinput` que o browser mandaria, na superfície focada.
  /// Devolve o evento para o teste poder conferir o `defaultPrevented`.
  web.InputEvent sendInput(String inputType, {String? data}) {
    final event = web.InputEvent(
        'beforeinput',
        web.InputEventInit(
          inputType: inputType,
          data: data ?? '',
          bubbles: true,
          cancelable: true,
        ));
    focusSurface().dispatchEvent(event);
    return event;
  }

  /// Coloca o caret na posição do MODELO, com a superfície focada.
  void caretAt(OfficeEditorView view, int modelPosition) {
    const map = OfficeDomPositionMap();
    final position = map.domPositionFor(host, modelPosition)!;
    focusSurface();
    adapter.setSelectionByNodes(
        position.node, position.offset, position.node, position.offset);
  }

  String docText(OfficeEditorView view) =>
      view.state.doc.textBetween(0, view.state.doc.content.size,
          blockSeparator: ' ');

  /// Editor com as extensões padrão (histórico, keymap, marcas).
  OfficeEditorView mountWithExtensions(PMNode doc) => view =
      OfficeEditorView.withExtensions(
          host: host,
          doc: doc,
          adapter: adapter,
          extensions: officeDefaultExtensions(schema));

  /// Dispara um keydown REAL na superfície focada.
  void pressKey(String key, {bool ctrl = false, bool shift = false}) {
    focusSurface().dispatchEvent(web.KeyboardEvent(
        'keydown',
        web.KeyboardEventInit(
          key: key,
          ctrlKey: ctrl,
          shiftKey: shift,
          bubbles: true,
          cancelable: true,
        )));
  }

  test('digitar insere no modelo e a projeção acompanha', () {
    final view = mount(docOf([paragraph('alpha')]));
    caretAt(view, 1 + 5); // fim de "alpha"

    sendInput('insertText', data: ' beta');

    expect(docText(view), contains('alpha beta'),
        reason: 'o texto tem de entrar pelo MODELO, não pelo DOM');
    expect(hostElement.textContent, contains('alpha beta'),
        reason: 'e a projeção tem de mostrar o novo estado');
  });

  test('o caret fica DEPOIS do texto inserido', () {
    final view = mount(docOf([paragraph('abc')]));
    caretAt(view, 1 + 3);
    sendInput('insertText', data: 'XY');

    final selection = view.readNativeSelection();
    expect(selection, isNotNull);
    expect(selection!.from, 1 + 5,
        reason: 'o caret segue o mapeamento da transação');
  });

  test('digitar no MEIO do texto insere no lugar certo', () {
    final view = mount(docOf([paragraph('aaabbb')]));
    caretAt(view, 1 + 3); // entre "aaa" e "bbb"
    sendInput('insertText', data: '-');

    expect(docText(view), contains('aaa-bbb'));
  });

  test('backspace apaga o caractere anterior', () {
    final view = mount(docOf([paragraph('abcd')]));
    caretAt(view, 1 + 4);
    sendInput('deleteContentBackward');

    expect(docText(view), contains('abc'));
    expect(docText(view), isNot(contains('abcd')));
  });

  test('digitar sobre uma seleção substitui o intervalo', () {
    final view = mount(docOf([paragraph('um dois tres')]));
    const map = OfficeDomPositionMap();
    final from = map.domPositionFor(host, 1 + 3)!;
    final to = map.domPositionFor(host, 1 + 7)!;
    focusSurface();
    adapter.setSelectionByNodes(from.node, from.offset, to.node, to.offset);

    sendInput('insertText', data: 'X');
    expect(docText(view), contains('um X tres'));
  });

  test('o documento NÃO muda quando o inputType não é suportado', () {
    final view = mount(docOf([paragraph('intacto')]));
    caretAt(view, 1 + 7);
    final before = docText(view);

    // formatBold é CANCELADO: a view não deixa o browser mexer na projeção.
    final event = sendInput('formatBold');

    expect(event.defaultPrevented, isTrue,
        reason: 'o browser precisa ser impedido de editar a projeção');
    expect(docText(view), before,
        reason: 'entrada não suportada é cancelada, nunca aplicada pelo DOM');
    expect(hostElement.querySelectorAll('b').length, 0);
    expect(hostElement.querySelectorAll('strong').length, 0);
  });

  test('dispatch programático reprojeta e mantém o gate com o PDF', () {
    final view = mount(docOf([paragraph('inicial')]));
    final pagesBefore = view.pageGraph.pages.length;

    final transaction = view.state.tr..insertText(' acrescentado', 1 + 7);
    view.dispatch(transaction);

    expect(docText(view), contains('inicial acrescentado'));
    expect(hostElement.textContent, contains('inicial acrescentado'));
    expect(view.pageGraph.pages.length, greaterThanOrEqualTo(pagesBefore),
        reason: 'o grafo foi recomposto a partir do novo estado');
  });

  test('Ctrl+B do teclado REAL aplica negrito na seleção nativa', () {
    final view = mountWithExtensions(docOf([paragraph('texto')]));
    const map = OfficeDomPositionMap();
    final from = map.domPositionFor(host, 1)!;
    final to = map.domPositionFor(host, 1 + 5)!;
    focusSurface();
    adapter.setSelectionByNodes(from.node, from.offset, to.node, to.offset);

    pressKey('b', ctrl: true);

    expect(view.state.doc.child(0).firstChild?.marks.map((m) => m.type.name),
        contains('bold'),
        reason: 'a seleção NATIVA precisa chegar ao comando');
  });

  test('Ctrl+Z do teclado REAL desfaz e a projeção acompanha', () {
    final view = mountWithExtensions(docOf([paragraph('abc')]));
    caretAt(view, 1 + 3);
    sendInput('insertText', data: 'XYZ');
    expect(hostElement.textContent, contains('abcXYZ'));

    pressKey('z', ctrl: true);

    expect(docText(view), 'abc');
    expect(hostElement.textContent, isNot(contains('XYZ')));
  });

  test('copiar escreve no DataTransfer REAL do browser', () {
    mountWithExtensions(docOf([paragraph('copie isto')]));
    const map = OfficeDomPositionMap();
    final from = map.domPositionFor(host, 1)!;
    final to = map.domPositionFor(host, 1 + 10)!;
    focusSurface();
    adapter.setSelectionByNodes(from.node, from.offset, to.node, to.offset);

    final data = web.DataTransfer();
    focusSurface().dispatchEvent(web.ClipboardEvent(
        'copy',
        web.ClipboardEventInit(
            clipboardData: data, bubbles: true, cancelable: true)));

    expect(data.getData('text/plain'), 'copie isto');
    expect(data.getData('text/html'), contains(officeSliceAttribute));
  });

  test('colar do DataTransfer REAL entra pelo modelo e reprojeta', () {
    final view = mountWithExtensions(docOf([paragraph('antes ')]));
    caretAt(view, 1 + 6);

    final data = web.DataTransfer()..setData('text/html', '<p><b>ok</b></p>');
    final event = web.ClipboardEvent(
        'paste',
        web.ClipboardEventInit(
            clipboardData: data, bubbles: true, cancelable: true));
    focusSurface().dispatchEvent(event);

    expect(event.defaultPrevented, isTrue,
        reason: 'o browser nunca cola direto na projeção');
    expect(docText(view), contains('antes ok'));
    expect(hostElement.textContent, contains('antes ok'));
    expect(view.state.doc.child(0).lastChild?.marks.map((m) => m.type.name),
        contains('bold'));
  });

  test('composição IME REAL: o browser escreve e o modelo reconcilia', () {
    final view = mountWithExtensions(docOf([paragraph('ca')]));
    caretAt(view, 1 + 2);

    final surface = focusSurface();
    surface.dispatchEvent(web.CompositionEvent(
        'compositionstart',
        web.CompositionEventInit(bubbles: true, cancelable: true)));
    expect(view.isComposing, isTrue);

    // O que o IME faz: escreve DIRETO no nó de texto da projeção.
    const map = OfficeDomPositionMap();
    final position = map.domPositionFor(host, 1 + 2)!;
    final textNode = (position.node as dynamic).node as web.Text;
    textNode.data = '${textNode.data}fé';
    adapter.setSelectionByNodes(
        position.node, position.offset, position.node, position.offset);

    surface.dispatchEvent(web.CompositionEvent(
        'compositionend',
        web.CompositionEventInit(
            data: 'fé', bubbles: true, cancelable: true)));

    expect(view.isComposing, isFalse);
    expect(docText(view), 'café',
        reason: 'o que o browser escreveu tem de voltar para o MODELO');
    expect(hostElement.textContent, contains('café'));
  });

  test('dispose solta o listener: digitar depois não muda mais nada', () {
    final view = mount(docOf([paragraph('final')]));
    caretAt(view, 1 + 5);
    view.dispose();
    final before = docText(view);

    sendInput('insertText', data: 'ZZZ');
    expect(docText(view), before);
  });
}
