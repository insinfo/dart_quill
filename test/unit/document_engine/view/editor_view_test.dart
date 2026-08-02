/// Fase 2 — o laço de edição: beforeinput → modelo → layout → projeção.
///
/// Roda no fake DOM porque é onde uma exceção dentro do handler APARECE:
/// num listener de browser ela some no dispatch e o sintoma vira "nada
/// aconteceu". Os testes de Chrome cobrem o que só o browser sabe dizer
/// (foco, seleção nativa, geometria); a lógica do laço se prova aqui.
@TestOn('vm')
library;

import 'package:test/test.dart';

import 'package:dart_quill/dart_quill_office.dart';
import 'package:dart_quill/src/platform/dom.dart';

import '../../../support/fake_dom.dart';
import '../../../support/test_helpers.dart';

void main() {
  final schema = officeQuillSchema();

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

  OfficeEditorView mount(PMNode doc) {
    final state = EditorState.create(EditorStateConfig(doc: doc));
    return view = OfficeEditorView(host: host, state: state, adapter: adapter);
  }

  String textOf(OfficeEditorView view) => view.state.doc
      .textBetween(0, view.state.doc.content.size, blockSeparator: ' ');

  /// Põe o caret na posição do modelo e dispara o `beforeinput` que o
  /// browser mandaria.
  void input(OfficeEditorView view, int modelPosition, String inputType,
      {String? data, int? to}) {
    const map = OfficeDomPositionMap();
    final from = map.domPositionFor(host, modelPosition)!;
    final end = map.domPositionFor(host, to ?? modelPosition)!;
    adapter.setSelectionByNodes(from.node, from.offset, end.node, end.offset);
    (host as FakeDomElement).dispatchEvent(
        'beforeinput',
        FakeDomInputEvent(
            type: 'beforeinput', target: host, inputType: inputType, data: data));
  }

  group('insertText', () {
    test('digitar no fim do parágrafo entra no modelo', () {
      final view = mount(docOf([paragraph('alpha')]));
      input(view, 1 + 5, 'insertText', data: ' beta');
      expect(textOf(view), contains('alpha beta'));
    });

    test('digitar no meio insere no lugar certo', () {
      final view = mount(docOf([paragraph('aaabbb')]));
      input(view, 1 + 3, 'insertText', data: '-');
      expect(textOf(view), contains('aaa-bbb'));
    });

    test('o caret fica DEPOIS do texto inserido', () {
      final view = mount(docOf([paragraph('abc')]));
      input(view, 1 + 3, 'insertText', data: 'XY');
      expect(view.readNativeSelection()?.from, 1 + 5);
    });

    test('digitar sobre uma seleção substitui o intervalo', () {
      final view = mount(docOf([paragraph('um dois tres')]));
      // "um dois tres": a posição 1 é antes do 'u', então [4,8] é "dois".
      input(view, 1 + 3, 'insertText', data: 'X', to: 1 + 7);
      expect(textOf(view), 'um X tres');
    });

    test('a projeção mostra o novo estado', () {
      final view = mount(docOf([paragraph('antes')]));
      input(view, 1 + 5, 'insertText', data: ' depois');
      expect(host.textContent, contains('antes depois'));
    });
  });

  group('apagar', () {
    test('backspace apaga o caractere anterior', () {
      final view = mount(docOf([paragraph('abcd')]));
      input(view, 1 + 4, 'deleteContentBackward');
      expect(textOf(view), 'abc');
    });

    test('delete apaga o caractere seguinte', () {
      final view = mount(docOf([paragraph('abcd')]));
      input(view, 1 + 1, 'deleteContentForward');
      expect(textOf(view), 'acd');
    });

    test('backspace no início do documento é no-op', () {
      final view = mount(docOf([paragraph('abc')]));
      input(view, 1, 'deleteContentBackward');
      expect(textOf(view), 'abc');
    });

    test('backspace com seleção apaga o intervalo', () {
      final view = mount(docOf([paragraph('um dois tres')]));
      // [3,8] cobre " dois" — o espaço antes de "dois" entra no intervalo.
      input(view, 1 + 2, 'deleteContentBackward', to: 1 + 7);
      expect(textOf(view), 'um tres');
    });
  });

  group('parágrafo', () {
    test('Enter divide o bloco em dois', () {
      final view = mount(docOf([paragraph('antesdepois')]));
      final blocksBefore = view.state.doc.childCount;
      input(view, 1 + 5, 'insertParagraph');
      expect(view.state.doc.childCount, blocksBefore + 1);
      expect(view.state.doc.child(0).textContent, 'antes');
      expect(view.state.doc.child(1).textContent, 'depois');
    });
  });

  group('o browser nunca escreve na projeção', () {
    test('inputType não suportado é cancelado e não muda o documento', () {
      final view = mount(docOf([paragraph('intacto')]));
      final before = textOf(view);
      input(view, 1 + 7, 'formatBold');
      expect(textOf(view), before);
    });

    test('composição IME é ignorada enquanto não há reconciliação', () {
      final view = mount(docOf([paragraph('base')]));
      const map = OfficeDomPositionMap();
      final position = map.domPositionFor(host, 1 + 4)!;
      adapter.setSelectionByNodes(
          position.node, position.offset, position.node, position.offset);
      (host as FakeDomElement).dispatchEvent(
          'beforeinput',
          FakeDomInputEvent(
              type: 'beforeinput',
              target: host,
              inputType: 'insertText',
              data: 'ç',
              isComposing: true));
      expect(textOf(view), 'base',
          reason: 'fingir suporte a IME corromperia o documento');
    });
  });

  group('ciclo completo', () {
    test('dispatch programático recompõe o grafo e reprojeta', () {
      final view = mount(docOf([paragraph('inicial')]));
      view.dispatch(view.state.tr..insertText(' extra', 1 + 7));
      expect(textOf(view), contains('inicial extra'));
      expect(host.textContent, contains('inicial extra'));
      expect(view.pageGraph.pages, isNotEmpty);
    });

    test('onStateChange avisa a aplicação a cada transação', () {
      var changes = 0;
      final state = EditorState.create(
          EditorStateConfig(doc: docOf([paragraph('x')])));
      view = OfficeEditorView(
        host: host,
        state: state,
        adapter: adapter,
        onStateChange: (_) => changes++,
      );
      input(view!, 1 + 1, 'insertText', data: 'y');
      expect(changes, 1);
    });

    test('digitar várias vezes acumula no documento', () {
      // Parágrafo VAZIO é um bloco sem filhos — um nó de texto vazio é
      // inválido no schema (e é o estado inicial real de um documento novo).
      final view = mount(
          docOf([schema.node('paragraph', null, Fragment.empty)]));
      for (final letter in ['a', 'b', 'c']) {
        final at = view.state.doc.content.size - 1;
        input(view, at, 'insertText', data: letter);
      }
      expect(textOf(view), 'abc');
    });

    test('dispose solta o listener', () {
      final view = mount(docOf([paragraph('final')]));
      view.dispose();
      input(view, 1 + 5, 'insertText', data: 'ZZZ');
      expect(textOf(view), 'final');
    });
  });
}
