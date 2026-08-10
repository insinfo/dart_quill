/// Opções de Layout do objeto: o popover de disposição do texto, o botão da
/// quickbar e o arrasto que reposiciona a caixa flutuante.
///
/// A regra que estes testes protegem é a da honestidade: um modo que o
/// compositor não honra tem de aparecer DESABILITADO, e um modo habilitado
/// tem de gravar o atributo que o compositor lê. O fake DOM não tem
/// geometria, então as asserções são sobre o modelo e sobre a estrutura do
/// menu — nunca sobre pixels.
@TestOn('vm')
library;

import 'package:test/test.dart';

import 'package:dart_quill/dart_quill_office.dart';
import 'package:dart_quill/src/document_engine/ui/ribbon_actions.dart'
    as actions;
import 'package:dart_quill/src/platform/dom.dart';

import '../../../support/test_helpers.dart';

void main() {
  final schema = officeQuillSchema();

  late DomAdapter adapter;
  late DomElement host;
  OfficeWordEditor? editor;

  setUpAll(initializeFakeDom);

  setUp(() {
    adapter = testAdapter;
    host = adapter.document.createElement('div');
    adapter.document.body.append(host);
  });

  tearDown(() {
    editor?.dispose();
    editor = null;
    host.remove();
  });

  PMNode paragraph(String text) =>
      schema.node('paragraph', null, Fragment.from([schema.text(text)]));

  PMNode textBoxNode({String wrapMode = 'inFrontOfText'}) =>
      schema.node('textBox', {
        'text': 'carimbo',
        'width': 2000,
        'height': 900,
        'offsetX': 100,
        'offsetY': 50,
        'positionHAlign': 'right',
        'wrapMode': wrapMode,
      });

  PMNode docWithTextBox({String wrapMode = 'inFrontOfText'}) => schema.node(
      'doc',
      null,
      Fragment.from([
        schema.node(
            'paragraph',
            null,
            Fragment.from([
              schema.text('âncora'),
              textBoxNode(wrapMode: wrapMode),
            ])),
        paragraph('Depois da caixa.'),
      ]));

  PMNode docWithImage() => schema.node(
      'doc',
      null,
      Fragment.from([
        schema.node(
            'paragraph',
            null,
            Fragment.from([
              schema.node('image', {
                'src': 'data:image/png;base64,AAAA',
                'width': 1440,
                'height': 720,
              })
            ])),
      ]));

  OfficeWordEditor mount(PMNode document) => editor = OfficeWordEditor.mount(
        host: host,
        adapter: adapter,
        document: document,
        schema: schema,
        options: const OfficeWordEditorOptions(),
      );

  /// Posição do primeiro nó inline do tipo pedido.
  int inlinePositionOf(OfficeWordEditor editor, String type) {
    var offset = 0;
    for (var i = 0; i < editor.state.doc.childCount; i++) {
      final block = editor.state.doc.child(i);
      var inner = offset + 1;
      for (var j = 0; j < block.childCount; j++) {
        final child = block.child(j);
        if (child.type.name == type) return inner;
        inner += child.nodeSize;
      }
      offset += block.nodeSize;
    }
    throw StateError('$type não encontrado');
  }

  void selectNode(OfficeWordEditor editor, String type) {
    final pos = inlinePositionOf(editor, type);
    editor.view.dispatch(editor.state.tr
      ..setSelection(NodeSelection.create(editor.state.doc, pos)));
  }

  group('popover Opções de Layout', () {
    test('lista os sete modos do Word, com o atual marcado', () {
      final editor = mount(docWithTextBox(wrapMode: 'square'));
      selectNode(editor, 'textBox');

      final entries = buildLayoutOptionsEntries(editor);
      expect(entries, hasLength(7));
      expect(
        entries.map((entry) => entry.label),
        containsAll(const [
          'Em linha com o texto',
          'Quadrado',
          'Próximo',
          'Através',
          'Superior e inferior',
          'Atrás do texto',
          'Na frente do texto',
        ]),
      );
      final checked = entries.where((entry) => entry.checked).toList();
      expect(checked, hasLength(1));
      expect(checked.single.label, 'Quadrado');
    });

    test('o modo que o compositor NÃO honra fica visível e desabilitado', () {
      final editor = mount(docWithTextBox());
      selectNode(editor, 'textBox');

      final inline = buildLayoutOptionsEntries(editor)
          .firstWhere((entry) => entry.label == 'Em linha com o texto');
      expect(inline.enabled, isFalse);
      expect(inline.description, isNotNull,
          reason: 'o motivo real tem de estar escrito no item');
      expect(inline.description, contains('flutuante'));
    });

    test('imagem tem todos os modos desabilitados, com o motivo', () {
      final editor = mount(docWithImage());
      selectNode(editor, 'image');

      final entries = buildLayoutOptionsEntries(editor);
      expect(entries.every((entry) => !entry.enabled), isTrue);
      expect(entries.every((entry) => entry.description!.contains('em linha')),
          isTrue);
      expect(entries.any((entry) => entry.checked), isFalse);
    });

    test('escolher um modo grava o MESMO atributo que o compositor lê', () {
      final editor = mount(docWithTextBox());
      selectNode(editor, 'textBox');
      expect(actions.objectWrapMode(editor), 'inFrontOfText');

      actions.setObjectWrap(editor, 'square');

      final pos = inlinePositionOf(editor, 'textBox');
      expect(editor.state.doc.nodeAt(pos)!.attrs['wrapMode'], 'square');
      expect(editor.state.selection, isA<NodeSelection>(),
          reason: 'trocar a disposição não é motivo para perder o objeto');
      expect(actions.objectWrapMode(editor), 'square');
    });

    test('trocar a disposição repagina com a linha encurtada', () {
      final editor = mount(docWithTextBox());
      selectNode(editor, 'textBox');
      final before = editor.pageGraph.pages.first.fragments
          .whereType<BlockFragment>()
          .last
          .lines
          .first;
      expect(before.wrapRightInsetTwips, 0);

      actions.setObjectWrap(editor, 'square');

      final after = editor.pageGraph.pages.first.fragments
          .whereType<BlockFragment>()
          .last
          .lines
          .first;
      expect(after.wrapRightInsetTwips, greaterThan(0),
          reason: 'o botão só existe porque o compositor honra o atributo');
    });

    test('imagem selecionada não muda de disposição por engano', () {
      final editor = mount(docWithImage());
      selectNode(editor, 'image');
      final pos = inlinePositionOf(editor, 'image');

      actions.setObjectWrap(editor, 'square');

      expect(
          editor.state.doc.nodeAt(pos)!.attrs.containsKey('wrapMode'), isFalse);
    });
  });

  group('moldura do objeto', () {
    test('a moldura traz o ícone de Opções de Layout e as faixas de mover', () {
      final editor = mount(docWithTextBox());
      selectNode(editor, 'textBox');

      expect(host.querySelectorAll('.dq-office-objanchor'), hasLength(1));
      expect(host.querySelectorAll('.dq-office-objmove'), hasLength(4));
    });

    test('o ícone abre o menu de disposição no overlay', () {
      final editor = mount(docWithTextBox());
      selectNode(editor, 'textBox');
      final adorner = OfficeObjectAdorner(editor);
      adorner.refresh();

      adorner.openLayoutOptions();

      final menu = host.querySelectorAll('.dq-office-layout-options');
      expect(menu, hasLength(1));
      expect(host.querySelectorAll('.dq-office-menu-item'), hasLength(7));
    });
  });

  group('arrastar para reposicionar', () {
    test('soma o deslocamento aos offsets da âncora em UMA transação', () {
      final editor = mount(docWithTextBox());
      selectNode(editor, 'textBox');
      final adorner = OfficeObjectAdorner(editor);
      final target = adorner.selectedObject()!;
      final pxPerTwip = editor.pxPerTwip;

      adorner.moveBy(
        target.pos,
        target.node,
        deltaXPx: 240 * pxPerTwip,
        deltaYPx: -60 * pxPerTwip,
      );

      final moved =
          editor.state.doc.nodeAt(inlinePositionOf(editor, 'textBox'))!;
      expect(moved.attrs['offsetX'], 340, reason: '100 + 240');
      expect(moved.attrs['offsetY'], -10, reason: '50 - 60');
      expect(moved.attrs['positionHAlign'], 'right',
          reason: 'o referencial do offset não pode ser zerado no arrasto');
      expect(editor.state.selection, isA<NodeSelection>());
    });

    test('imagem não é arrastável: não há âncora flutuante no modelo', () {
      final editor = mount(docWithImage());
      selectNode(editor, 'image');
      final adorner = OfficeObjectAdorner(editor);
      final target = adorner.selectedObject()!;

      adorner.moveBy(target.pos, target.node, deltaXPx: 100, deltaYPx: 100);

      final image = editor.state.doc.nodeAt(inlinePositionOf(editor, 'image'))!;
      expect(image.attrs.containsKey('offsetX'), isFalse);
    });
  });

  group('quickbar de objeto', () {
    test('tem o botão de disposição do texto', () {
      final editor = mount(docWithTextBox());
      selectNode(editor, 'textBox');
      final quickbar = OfficeSelectionQuickbar(editor);

      quickbar.showForObject(x: 0, y: 0);

      // O fake DOM só casa seletores simples: filtramos pelo popup depois.
      final titles = host
          .querySelectorAll('.dq-office-btn')
          .map((button) => button.getAttribute('title'))
          .toList();
      expect(titles, contains('Disposição do Texto'));
      expect(host.querySelectorAll('.dq-office-quickbar'), hasLength(1));
    });
  });
}
