/// A aba contextual "Formato de Imagem" / "Formato da Forma".
///
/// O contrato que estes testes protegem é o do plano: a aba aparece com o
/// objeto e some com ele, o rótulo segue o TIPO (como no Word), e cada
/// controle exposto grava algo que a projeção honra — os campos de tamanho
/// passam pela MESMA função que a alça de redimensionamento usa.
@TestOn('vm')
library;

import 'package:test/test.dart';

import 'package:dart_quill/dart_quill_office.dart';
import 'package:dart_quill/src/document_engine/ui/ribbon_actions.dart'
    as actions;
import 'package:dart_quill/src/platform/dom.dart';

import '../../../support/fake_dom.dart';
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

  PMNode doc() => schema.node(
      'doc',
      null,
      Fragment.from([
        schema.node(
            'paragraph',
            null,
            Fragment.from([
              schema.node('image', {
                'src': 'data:image/png;base64,AAAA',
                'width': 1134, // 2 cm
                'height': 567, // 1 cm
              }),
            ])),
        schema.node(
            'paragraph',
            null,
            Fragment.from([
              schema.text('âncora'),
              schema.node('textBox', {
                'text': 'carimbo',
                'width': 2400,
                'height': 900,
              }),
            ])),
        paragraph('Depois.'),
      ]));

  OfficeWordEditor mount() => editor = OfficeWordEditor.mount(
        host: host,
        adapter: adapter,
        document: doc(),
        schema: schema,
        options: const OfficeWordEditorOptions(),
      );

  int positionOf(OfficeWordEditor editor, String type) {
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

  void select(OfficeWordEditor editor, String type) {
    final pos = positionOf(editor, type);
    editor.view.dispatch(editor.state.tr
      ..setSelection(NodeSelection.create(editor.state.doc, pos)));
  }

  DomElement objectTab() => host
      .querySelectorAll('.dq-office-ribbon-tab')
      .firstWhere((tab) => (tab.textContent ?? '').startsWith('Formato'));

  bool tabVisible(DomElement tab) =>
      !tab.classes.contains('dq-office-ribbon-tab-hidden');

  DomElement sizeInput(String label) => host
      .querySelectorAll('.dq-office-spinner')
      .firstWhere((wrap) => (wrap.textContent ?? '').contains(label))
      .querySelectorAll('.dq-office-spinner-input')
      .first;

  void changeTo(DomElement input, String value) {
    input.value = value;
    (input as FakeDomElement)
        .dispatchEvent('change', FakeDomEvent('change', input));
  }

  group('visibilidade e rótulo', () {
    test('a aba nasce escondida e aparece com o objeto selecionado', () {
      final editor = mount();
      expect(tabVisible(objectTab()), isFalse);

      select(editor, 'image');

      expect(tabVisible(objectTab()), isTrue);
      expect(objectTab().textContent, 'Formato de Imagem');
    });

    test('o rótulo segue o tipo: caixa de texto é "Formato da Forma"', () {
      final editor = mount();
      select(editor, 'textBox');

      expect(tabVisible(objectTab()), isTrue);
      expect(objectTab().textContent, 'Formato da Forma');
    });

    test('a aba some quando a seleção volta para o texto', () {
      final editor = mount();
      select(editor, 'image');
      expect(tabVisible(objectTab()), isTrue);

      editor.view.dispatch(editor.state.tr
        ..setSelection(TextSelection.create(editor.state.doc, 1)));

      expect(tabVisible(objectTab()), isFalse);
      // A aba ativa volta a ser a Página Inicial: uma aba escondida não pode
      // continuar sendo a que está na tela.
      expect(
        host
            .querySelectorAll('.dq-office-ribbon-tab-active')
            .single
            .textContent,
        'Página Inicial',
      );
    });

    test('selecionar o objeto TROCA para a aba dele, como no Word', () {
      final editor = mount();
      select(editor, 'image');
      expect(
        host
            .querySelectorAll('.dq-office-ribbon-tab-active')
            .single
            .textContent,
        'Formato de Imagem',
      );
    });
  });

  group('grupo Tamanho', () {
    test('os campos refletem o tamanho do objeto em cm', () {
      final editor = mount();
      select(editor, 'image');

      expect(sizeInput('Largura').value, '2.00');
      expect(sizeInput('Altura').value, '1.00');
    });

    test('digitar a largura grava twips e mantém a proporção', () {
      final editor = mount();
      select(editor, 'image');

      changeTo(sizeInput('Largura'), '4');

      final image = editor.state.doc.nodeAt(positionOf(editor, 'image'))!;
      expect(image.attrs['width'], (4 * 567));
      // A trava de proporção nasce ligada, como no Word: 2×1 cm vira 4×2.
      expect(image.attrs['height'], (2 * 567));
      expect(editor.state.selection, isA<NodeSelection>(),
          reason: 'mudar o tamanho não é motivo para perder o objeto');
    });

    test('arrastar a alça atualiza os campos — a UI reflete o modelo', () {
      final editor = mount();
      select(editor, 'image');

      final adorner = OfficeObjectAdorner(editor);
      final target = adorner.selectedObject()!;
      adorner.resizeTo(target.pos, target.node,
          widthPx: 567 * 6 * editor.pxPerTwip,
          heightPx: 567 * 3 * editor.pxPerTwip);

      expect(sizeInput('Largura').value, '6.00');
      expect(sizeInput('Altura').value, '3.00');
    });
  });

  group('grupo Organizar', () {
    test('alinhar a caixa grava positionHAlign', () {
      final editor = mount();
      select(editor, 'textBox');

      actions.setObjectAlign(editor, 'center');

      final box = editor.state.doc.nodeAt(positionOf(editor, 'textBox'))!;
      expect(box.attrs['positionHAlign'], 'center');
    });

    test('a aba oferece a MESMA disposição do texto do popover', () {
      final editor = mount();
      select(editor, 'textBox');

      final wrapButton = host
          .querySelectorAll('.dq-office-btn')
          .where((b) => b.getAttribute('title') == 'Disposição do Texto');
      expect(wrapButton, hasLength(1),
          reason: 'o botão da aba abre o menu de layout_options.dart, sem '
              'nenhuma segunda implementação');
    });

    test('a chave da aba contextual está registrada na ribbon', () {
      expect(OfficeRibbon.contextualTabKeys,
          contains(OfficeRibbon.objectTabKey));
    });
  });
}
