/// Fase 2 — IME e reconciliação DOM→modelo.
///
/// A composição é a ÚNICA parte do editor em que o browser escreve na
/// projeção. Estes testes travam as duas metades do contrato: o diff que
/// reconstrói a edição a partir do DOM, e a política de não reprojetar
/// enquanto o IME está compondo.
@TestOn('vm')
library;

import 'package:test/test.dart';

import 'package:dart_quill/dart_quill_office.dart';
import 'package:dart_quill/src/platform/dom.dart';

import '../../../support/fake_dom.dart';
import '../../../support/test_helpers.dart';

void main() {
  final schema = officeQuillSchema();
  const reconciler = OfficeDomReconciler();

  group('diff', () {
    test('inserção no meio vira a menor faixa possível', () {
      final diff = reconciler.diffText('abcd', 'abXcd', 1);
      expect(diff.from, 1 + 2);
      expect(diff.to, 1 + 2);
      expect(diff.text, 'X');
    });

    test('remoção vira faixa sem texto', () {
      final diff = reconciler.diffText('abcd', 'acd', 1);
      expect(diff.from, 1 + 1);
      expect(diff.to, 1 + 2);
      expect(diff.text, '');
    });

    test('substituição cobre só o que mudou', () {
      final diff = reconciler.diffText('um dois tres', 'um DOIS tres', 1);
      expect(diff.text, 'DOIS');
      expect(diff.from, 1 + 3);
      expect(diff.to, 1 + 7);
    });

    test('texto igual não produz faixa', () {
      expect(reconciler.diffText('igual', 'igual', 1).isEmpty, isTrue);
    });

    test('acento composto substitui a vogal, não acrescenta', () {
      // O que um dead key faz: "ca" + composição -> "cá".
      final diff = reconciler.diffText('ca', 'cá', 1);
      expect(diff.text, 'á');
      expect(diff.from, 1 + 1);
      expect(diff.to, 1 + 2);
    });

    test('CJK composto entra inteiro', () {
      final diff = reconciler.diffText('', '日本語', 1);
      expect(diff.text, '日本語');
      expect(diff.from, 1);
      expect(diff.to, 1);
    });

    test('emoji NÃO é cortado ao meio', () {
      // "a😀b" -> "a😀Xb": o par substituto tem de ficar inteiro do lado do
      // prefixo comum, senão o texto resultante é Unicode inválido.
      final diff = reconciler.diffText('a😀b', 'a😀Xb', 1);
      expect(diff.text, 'X');
      expect(String.fromCharCodes('a😀b'.codeUnits.sublist(0, diff.from - 1)),
          'a😀',
          reason: 'o corte tem de cair DEPOIS do par substituto inteiro');
    });

    test('emoji inserido logo após outro emoji', () {
      final diff = reconciler.diffText('😀', '😀😀', 1);
      expect(diff.text, '😀');
    });
  });

  group('na view', () {
    late DomAdapter adapter;
    late DomElement host;
    OfficeEditorView? view;

    setUpAll(initializeFakeDom);

    setUp(() {
      adapter = testAdapter;
      host = adapter.document.createElement('div');
      adapter.document.body.append(host);
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

    OfficeEditorView mount(List<PMNode> blocks) =>
        view = OfficeEditorView.withExtensions(
            host: host,
            doc: docOf(blocks),
            adapter: adapter,
            extensions: officeDefaultExtensions(schema));

    String textOf(OfficeEditorView view) => view.state.doc
        .textBetween(0, view.state.doc.content.size, blockSeparator: ' ');

    ({DomElement block, DomElement line}) projectedLine({
      required int docPos,
      required int charStart,
      required int charEnd,
    }) {
      final block = adapter.document.createElement('div');
      block.classes.add('dq-office-block');
      block.setAttribute('data-doc-pos', '$docPos');
      final line = adapter.document.createElement('div');
      line.classes.add('dq-office-line');
      line.setAttribute('data-char-start', '$charStart');
      line.setAttribute('data-char-end', '$charEnd');
      block.append(line);
      host.append(block);
      return (block: block, line: line);
    }

    DomText runText(DomElement line, String text) {
      final run = adapter.document.createElement('span');
      run.classes.add('dq-office-run');
      run.appendText(text);
      line.append(run);
      return run.firstChild! as DomText;
    }

    void caretAt(int modelPosition) {
      const map = OfficeDomPositionMap();
      final position = map.domPositionFor(host, modelPosition)!;
      adapter.setSelectionByNodes(
          position.node, position.offset, position.node, position.offset);
    }

    void fire(String type) {
      (host as FakeDomElement).dispatchEvent(type, FakeDomEvent(type, host));
    }

    /// Simula o que o BROWSER faz durante a composição: escreve direto no nó
    /// de texto da projeção, sem passar pelo modelo.
    void browserWrites(int modelPosition, String text) {
      const map = OfficeDomPositionMap();
      final position = map.domPositionFor(host, modelPosition)!;
      final node = position.node as DomText;
      node.data = node.data.substring(0, position.offset) +
          text +
          node.data.substring(position.offset);
    }

    test('fragmento de continuação reconcilia só sua faixa do parágrafo', () {
      const prefix = 'prefixo ';
      const continuation = 'segunda metade';
      final doc = docOf([paragraph('$prefix$continuation')]);
      final state = EditorState.create(EditorStateConfig(doc: doc));
      final projection = projectedLine(
        docPos: 1,
        charStart: prefix.length,
        charEnd: prefix.length + continuation.length,
      );
      final text = runText(projection.line, '${continuation}X');

      final transaction = reconciler.reconcile(
        host: host,
        node: text,
        state: state,
      );

      expect(transaction, isNotNull);
      final after = state.apply(transaction!);
      expect(after.doc.child(0).textContent, '${prefix}${continuation}X',
          reason: 'o prefixo que vive em outra página não pode ser truncado');
    });

    test('hífen discricionário visual nunca vira texto do modelo', () {
      const source = 'palavra';
      final doc = docOf([paragraph(source)]);
      final state = EditorState.create(EditorStateConfig(doc: doc));
      final projection = projectedLine(
        docPos: 1,
        charStart: 0,
        charEnd: source.length,
      );
      runText(projection.line, 'pala');
      final hyphen = adapter.document.createElement('span');
      hyphen.classes.add('dq-office-discretionary-hyphen');
      hyphen.setAttribute('contenteditable', 'false');
      hyphen.setAttribute('data-model-length', '0');
      hyphen.appendText('-');
      projection.line.append(hyphen);
      final tail = runText(projection.line, 'vraX');

      final transaction = reconciler.reconcile(
        host: host,
        node: tail,
        state: state,
      );

      final after = state.apply(transaction!);
      expect(after.doc.child(0).textContent, 'palavraX');
      expect(after.doc.child(0).textContent, isNot(contains('-')));
    });

    test('textBox visual é ignorado e seu atom preserva o offset', () {
      final textBox = schema.node('textBox', {
        'text': 'RÓTULO VISUAL',
        'width': 400,
        'height': 200,
        'offsetX': 0,
        'offsetY': 0,
      });
      final block = schema.node(
        'paragraph',
        null,
        Fragment.from([schema.text('A'), textBox, schema.text('B')]),
      );
      final state = EditorState.create(EditorStateConfig(doc: docOf([block])));
      final projection = projectedLine(
        docPos: 1,
        charStart: 0,
        charEnd: block.content.size,
      );
      final visual = adapter.document.createElement('div');
      visual.classes.add('dq-office-text-box');
      visual.setAttribute('contenteditable', 'false');
      visual.setAttribute('data-model-length', '1');
      visual.appendText('RÓTULO VISUAL');
      projection.block.insertBefore(visual, projection.line);
      runText(projection.line, 'A');
      final anchor = adapter.document.createElement('span');
      anchor.classes.add('dq-office-text-box-anchor');
      anchor.setAttribute('contenteditable', 'false');
      anchor.setAttribute('data-model-length', '1');
      projection.line.append(anchor);
      final tail = runText(projection.line, 'BX');

      final transaction = reconciler.reconcile(
        host: host,
        node: tail,
        state: state,
      );

      final after = state.apply(transaction!);
      expect(after.doc.child(0).textContent, 'ABX');
      expect(after.doc.child(0).child(1).type.name, 'textBox');
      expect(after.doc.textContent, isNot(contains('RÓTULO VISUAL')));
    });

    test('compositionstart marca composição e trava a reprojeção', () {
      final view = mount([paragraph('base')]);
      fire('compositionstart');
      expect(view.isComposing, isTrue);
    });

    test('o texto que o browser escreveu entra no modelo no fim', () {
      final view = mount([paragraph('ca')]);
      caretAt(1 + 2);
      fire('compositionstart');
      browserWrites(1 + 2, 'fé');
      caretAt(1 + 2);
      fire('compositionend');

      expect(view.isComposing, isFalse);
      expect(textOf(view), 'café');
    });

    test('CJK composto entra como UMA edição no histórico', () {
      final view = mount([paragraph('x')]);
      caretAt(1 + 1);
      fire('compositionstart');
      browserWrites(1 + 1, '日本語');
      caretAt(1 + 1);
      fire('compositionend');
      expect(textOf(view), 'x日本語');

      (host as FakeDomElement).dispatchEvent(
          'keydown',
          FakeDomKeyboardEvent(
              type: 'keydown', target: host, key: 'z', ctrlKey: true));
      expect(textOf(view), 'x',
          reason: 'um undo tem de desfazer a composição inteira');
    });

    test('a projeção volta a mostrar o estado do modelo', () {
      final view = mount([paragraph('ab')]);
      caretAt(1 + 2);
      fire('compositionstart');
      browserWrites(1 + 2, 'cd');
      caretAt(1 + 2);
      fire('compositionend');

      expect(textOf(view), 'abcd');
      expect(host.textContent, contains('abcd'));
    });

    test('composição que não mudou nada não gera transação', () {
      final view = mount([paragraph('estavel')]);
      caretAt(1 + 7);
      final before = view.state;
      fire('compositionstart');
      fire('compositionend');
      expect(view.state, same(before),
          reason: 'transação vazia sujaria o histórico');
    });

    test('beforeinput com isComposing NÃO é cancelado', () {
      mount([paragraph('base')]);
      caretAt(1 + 4);
      final event = FakeDomInputEvent(
          type: 'beforeinput',
          target: host,
          inputType: 'insertText',
          data: 'ç',
          isComposing: true);
      (host as FakeDomElement).dispatchEvent('beforeinput', event);
      expect(event.defaultPrevented, isFalse,
          reason: 'cancelar durante composição quebraria o IME');
    });

    test('dispatch durante composição NÃO reprojeta', () {
      final view = mount([paragraph('inicial')]);
      fire('compositionstart');
      view.dispatch(view.state.tr..insertText('!', 1 + 7));

      expect(textOf(view), 'inicial!', reason: 'o modelo muda');
      expect(host.textContent, isNot(contains('inicial!')),
          reason: 'a projeção pertence ao browser enquanto o IME compõe');

      fire('compositionend');
      expect(host.textContent, contains('inicial!'),
          reason: 'e volta a ser nossa quando a composição termina');
    });

    test('composição em documento de várias linhas acerta o bloco', () {
      final view = mount([paragraph('primeiro'), paragraph('segundo')]);
      final second = view.state.doc.child(0).nodeSize + 1;
      caretAt(second + 7);
      fire('compositionstart');
      browserWrites(second + 7, 'X');
      caretAt(second + 7);
      fire('compositionend');

      expect(view.state.doc.child(0).textContent, 'primeiro');
      expect(view.state.doc.child(1).textContent, 'segundoX');
    });

    test('composição num editor NÃO reescreve o documento do outro', () {
      // Dois editores na mesma página é requisito do plano. A seleção
      // nativa é global, e `data-doc-pos` faz sentido em qualquer projeção
      // — sem delimitar pelo host, o compositionend de um editor aplicaria
      // o texto do outro.
      final first = mount([paragraph('primeiro editor')]);
      final otherHost = adapter.document.createElement('div');
      adapter.document.body.append(otherHost);
      final second = OfficeEditorView.withExtensions(
          host: otherHost,
          doc: docOf([paragraph('segundo editor')]),
          adapter: adapter,
          extensions: officeDefaultExtensions(schema));
      addTearDown(() {
        second.dispose();
        otherHost.remove();
      });

      // O caret está no SEGUNDO editor; o primeiro recebe o compositionend.
      const map = OfficeDomPositionMap();
      final position = map.domPositionFor(otherHost, 1 + 7)!;
      adapter.setSelectionByNodes(
          position.node, position.offset, position.node, position.offset);
      fire('compositionstart');
      fire('compositionend');

      expect(textOf(first), 'primeiro editor');
      expect(textOf(second), 'segundo editor');
    });

    test('dispose solta os listeners de composição', () {
      final view = mount([paragraph('final')]);
      view.dispose();
      fire('compositionstart');
      expect(view.isComposing, isFalse);
    });
  });
}
