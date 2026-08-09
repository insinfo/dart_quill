/// Fase 2 — a camada de extensões: comandos nomeados, atalhos e plugins.
///
/// O que estes testes protegem é o CONTRATO da camada, não a lógica dos
/// comandos (que vem do port e tem os testes upstream): que o atalho chegue
/// no comando certo, que o plugin do histórico esteja instalado a tempo de
/// o undo enxergar a primeira transação, e que uma tecla NÃO ligada passe
/// direto para o browser.
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

  PMNode docOf(String text) => schema.node(
      'doc',
      null,
      Fragment.from([
        schema.node('paragraph', null, Fragment.from([schema.text(text)]))
      ]));

  OfficeEditorView mount(String text, {List<OfficeExtension>? extensions}) {
    return view = OfficeEditorView.withExtensions(
      host: host,
      doc: docOf(text),
      adapter: adapter,
      extensions: extensions ?? officeDefaultExtensions(schema),
    );
  }

  String textOf(OfficeEditorView view) => view.state.doc
      .textBetween(0, view.state.doc.content.size, blockSeparator: ' ');

  void caretAt(int modelPosition, [int? to]) {
    const map = OfficeDomPositionMap();
    final from = map.domPositionFor(host, modelPosition)!;
    final end = map.domPositionFor(host, to ?? modelPosition)!;
    adapter.setSelectionByNodes(from.node, from.offset, end.node, end.offset);
  }

  void typeText(int at, String data) {
    caretAt(at);
    (host as FakeDomElement).dispatchEvent(
        'beforeinput',
        FakeDomInputEvent(
            type: 'beforeinput',
            target: host,
            inputType: 'insertText',
            data: data));
  }

  FakeDomKeyboardEvent press(String key,
      {bool ctrl = false,
      bool meta = false,
      bool shift = false,
      bool alt = false,
      bool composing = false}) {
    final event = FakeDomKeyboardEvent(
      type: 'keydown',
      target: host,
      key: key,
      ctrlKey: ctrl,
      metaKey: meta,
      shiftKey: shift,
      altKey: alt,
      isComposing: composing,
    );
    (host as FakeDomElement).dispatchEvent('keydown', event);
    return event;
  }

  group('resolução do conjunto', () {
    test('comandos das extensões ficam acessíveis por nome', () {
      final set = OfficeExtensionSet(officeDefaultExtensions(schema));
      expect(set.commandNames,
          containsAll(['undo', 'redo', 'bold', 'italic', 'selectAll']));
    });

    test('o plugin do histórico entra no estado', () {
      final set = OfficeExtensionSet(officeDefaultExtensions(schema));
      expect(set.plugins, isNotEmpty);
    });

    test('extensão POSTERIOR sobrescreve o atalho da anterior', () {
      var ran = false;
      final override = _TestExtension(
        shortcuts: [
          OfficeKeyBinding('Mod-b', (state, [dispatch, view]) {
            ran = true;
            return true;
          }),
        ],
      );
      final view = mount('texto',
          extensions: [...officeDefaultExtensions(schema), override]);
      caretAt(1, 1 + 5);
      press('b', ctrl: true);
      expect(ran, isTrue,
          reason: 'a aplicação precisa poder trocar um atalho embutido');
      expect(view.state.doc.child(0).firstChild?.marks, isEmpty,
          reason: 'o comando original não deve ter rodado também');
    });
  });

  group('atalhos', () {
    test('Ctrl+B aplica negrito na seleção', () {
      final view = mount('texto');
      caretAt(1, 1 + 5);
      press('b', ctrl: true);
      expect(view.state.doc.child(0).firstChild?.marks.map((m) => m.type.name),
          contains('bold'));
    });

    test('Cmd+B também funciona (Mod casa com Ctrl OU Meta)', () {
      final view = mount('texto');
      caretAt(1, 1 + 5);
      press('b', meta: true);
      expect(view.state.doc.child(0).firstChild?.marks.map((m) => m.type.name),
          contains('bold'));
    });

    test('B sem modificador NÃO é atalho', () {
      final view = mount('texto');
      caretAt(1, 1 + 5);
      final event = press('b');
      expect(event.defaultPrevented, isFalse,
          reason: 'tecla não ligada tem de passar para o browser');
      expect(view.state.doc.child(0).firstChild?.marks, isEmpty);
    });

    test('a tecla tratada é cancelada; a não tratada, não', () {
      mount('texto');
      caretAt(1, 1 + 5);
      expect(press('b', ctrl: true).defaultPrevented, isTrue);
      expect(press('k', ctrl: true).defaultPrevented, isFalse,
          reason: 'cancelar o que não se trata quebraria o browser');
    });

    test('Shift faz parte da combinação', () {
      final view = mount('texto');
      caretAt(1, 1 + 5);
      press('x', ctrl: true, shift: true); // Mod-Shift-x = strike
      expect(view.state.doc.child(0).firstChild?.marks.map((m) => m.type.name),
          contains('strike'));
    });

    test('keydown durante composição IME é ignorado', () {
      final view = mount('texto');
      caretAt(1, 1 + 5);
      press('b', ctrl: true, composing: true);
      expect(view.state.doc.child(0).firstChild?.marks, isEmpty,
          reason: 'atalho no meio de uma composição agiria na palavra errada');
    });
  });

  group('undo/redo', () {
    test('Ctrl+Z desfaz o que foi digitado', () {
      final view = mount('abc');
      typeText(1 + 3, 'XYZ');
      expect(textOf(view), 'abcXYZ');

      press('z', ctrl: true);
      expect(textOf(view), 'abc',
          reason: 'o histórico precisa enxergar a transação da digitação');
    });

    test('Ctrl+Shift+Z refaz', () {
      final view = mount('abc');
      typeText(1 + 3, 'XYZ');
      press('z', ctrl: true);
      press('z', ctrl: true, shift: true);
      expect(textOf(view), 'abcXYZ');
    });

    test('Ctrl+Y também refaz', () {
      final view = mount('abc');
      typeText(1 + 3, 'XYZ');
      press('z', ctrl: true);
      press('y', ctrl: true);
      expect(textOf(view), 'abcXYZ');
    });

    test('undo reprojeta o DOM, não só o modelo', () {
      mount('abc');
      typeText(1 + 3, 'XYZ');
      expect(host.textContent, contains('abcXYZ'));

      press('z', ctrl: true);
      expect(host.textContent, contains('abc'));
      expect(host.textContent, isNot(contains('XYZ')),
          reason: 'a projeção tem de acompanhar o desfazer');
    });

    test('sem a extensão de histórico, undo simplesmente não existe', () {
      final view = mount('abc', extensions: [OfficeMarksExtension(schema)]);
      typeText(1 + 3, 'XYZ');
      press('z', ctrl: true);
      expect(textOf(view), 'abcXYZ',
          reason: 'sem plugin instalado o atalho não pode inventar histórico');
      expect(view.runCommand('undo'), isFalse);
    });
  });

  group('comandos pela UI', () {
    test('runCommand aplica o mesmo comando do atalho', () {
      final view = mount('texto');
      caretAt(1, 1 + 5);
      expect(view.runCommand('bold'), isTrue);
      expect(view.state.doc.child(0).firstChild?.marks.map((m) => m.type.name),
          contains('bold'));
    });

    test('comando inexistente devolve false em vez de explodir', () {
      final view = mount('texto');
      expect(view.runCommand('naoExiste'), isFalse);
    });

    test('runCommand depois de dispose não faz nada', () {
      final view = mount('texto');
      caretAt(1, 1 + 5);
      view.dispose();
      expect(view.runCommand('bold'), isFalse);
    });

    test('dispose solta também o listener de teclado', () {
      final view = mount('abc');
      typeText(1 + 3, 'XYZ');
      view.dispose();
      press('z', ctrl: true);
      expect(textOf(view), 'abcXYZ');
    });
  });
}

class _TestExtension extends OfficeExtensionBase {
  const _TestExtension({this.shortcuts = const []});

  @override
  String get name => 'test';

  @override
  final List<OfficeKeyBinding> shortcuts;
}
