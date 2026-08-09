/// Os diálogos Fonte… e Parágrafo… (pendência do F2).
///
/// O contrato que estes testes protegem é o que distingue um diálogo de uma
/// fileira de botões: **nada é aplicado enquanto o formulário está aberto**,
/// e o OK produz UMA transação com tudo. Se cada campo aplicasse sozinho, o
/// undo depois de "Parágrafo… → OK" desfaria só a última caixinha tocada.
@TestOn('vm')
library;

import 'package:test/test.dart';

import 'package:dart_quill/dart_quill_office.dart';
import 'package:dart_quill/src/document_engine/ui/dialogs/dialog.dart';
import 'package:dart_quill/src/document_engine/ui/dialogs/font_dialog.dart';
import 'package:dart_quill/src/document_engine/ui/dialogs/paragraph_dialog.dart';
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

  PMNode docOf(String text) => schema.node(
        'doc',
        null,
        Fragment.from([
          schema.node('paragraph', null, Fragment.from([schema.text(text)])),
          schema.node(
              'paragraph', null, Fragment.from([schema.text('segundo')])),
        ]),
      );

  OfficeWordEditor mount() => editor = OfficeWordEditor.mount(
        host: host,
        adapter: adapter,
        document: docOf('texto de exemplo para formatar'),
        schema: schema,
      );

  void click(DomElement element) => (element as FakeDomElement).dispatchEvent(
      'click', FakeDomMouseEvent(type: 'click', target: element));

  DomElement field(String key) {
    for (final input in host.querySelectorAll('.dq-office-dialog-input')) {
      if (input.getAttribute('data-field') == key) return input;
    }
    for (final input in host.querySelectorAll('.dq-office-dialog-check')) {
      if (input.getAttribute('data-field') == key) return input;
    }
    throw StateError('campo não encontrado: $key');
  }

  DomElement footerButton(String label) {
    for (final button in host.querySelectorAll('.dq-office-dialog-button')) {
      if ((button.textContent ?? '').contains(label)) return button;
    }
    throw StateError('botão não encontrado: $label');
  }

  group('diálogo Parágrafo', () {
    test('abre com os valores do bloco corrente', () {
      final editor = mount();
      editor.view.dispatch(editor.state.tr
        ..setSelection(TextSelection.create(editor.state.doc, 1)));
      editor.applyBlockStyle({'indentTwips': 1134, 'spaceAfterTwips': 120});

      openParagraphDialog(editor);

      // 1134 twips = 2 cm; 120 twips = 6 pt.
      expect(field('indentLeft').value, '2');
      expect(field('spaceAfter').value, '6');
    });

    test('cancelar NÃO altera o documento', () {
      final editor = mount();
      final before = editor.state.doc.child(0).attrs['style'];
      openParagraphDialog(editor);
      field('indentLeft').value = '5';

      click(footerButton('Cancelar'));

      expect(editor.state.doc.child(0).attrs['style'], before,
          reason: 'mexer no formulário sem confirmar não pode tocar no modelo');
      expect(host.querySelectorAll('.dq-office-dialog'), isEmpty);
    });

    test('OK aplica tudo de uma vez e o undo volta o parágrafo inteiro', () {
      final editor = mount();
      editor.view.dispatch(editor.state.tr
        ..setSelection(TextSelection.create(editor.state.doc, 1)));
      openParagraphDialog(editor);
      field('indentLeft').value = '2';
      field('spaceBefore').value = '12';
      field('align').value = 'Centralizado';
      field('lineSpacing').value = 'Duplo';

      click(footerButton('OK'));

      final style = editor.state.doc.child(0).attrs['style'] as Map;
      expect(style['indentTwips'], 1134);
      expect(style['spaceBeforeTwips'], 240);
      expect(style['align'], 'center');
      expect(style['lineTwips'], 480);
      expect(style['lineRule'], 'auto');

      editor.runCommand('undo');

      final after = editor.state.doc.child(0).attrs['style'];
      expect(after is Map ? after['indentTwips'] : null, isNot(1134),
          reason: 'UMA transação: o undo volta o parágrafo inteiro');
    });

    test('só expõe propriedades que o compositor honra', () {
      final editor = mount();
      openParagraphDialog(editor);
      final keys = [
        for (final input in host.querySelectorAll('.dq-office-dialog-input'))
          input.getAttribute('data-field'),
        for (final input in host.querySelectorAll('.dq-office-dialog-check'))
          input.getAttribute('data-field'),
      ];
      // Todas estas chaves são lidas em layout_composer._resolvedStyleOf.
      expect(
          keys,
          containsAll([
            'align',
            'indentLeft',
            'indentRight',
            'indentFirst',
            'spaceBefore',
            'spaceAfter',
            'lineSpacing',
            'contextualSpacing',
            'widowControl',
            'keepNext',
            'keepLines',
            'pageBreakBefore',
          ]));
    });
  });

  group('diálogo Fonte', () {
    test('OK aplica família, tamanho e marcas numa transação só', () {
      final editor = mount();
      editor.view.dispatch(editor.state.tr
        ..setSelection(TextSelection.create(editor.state.doc, 1, 6)));

      openFontDialog(editor);
      field('family').value = 'Georgia';
      field('size').value = '13.5';
      field('bold').value = 'true';
      click(footerButton('OK'));

      final marks = editor.state.doc.child(0).firstChild!.marks;
      final byName = {for (final mark in marks) mark.type.name: mark};
      expect(byName['font']?.attrs['value'], 'Georgia');
      expect(byName['size']?.attrs['value'], '13.5pt');
      expect(byName.containsKey('bold'), isTrue);

      editor.runCommand('undo');
      expect(editor.state.doc.child(0).firstChild!.marks, isEmpty,
          reason: 'o undo desfaz o diálogo inteiro, não campo a campo');
    });

    test('cancelar não formata nada', () {
      final editor = mount();
      editor.view.dispatch(editor.state.tr
        ..setSelection(TextSelection.create(editor.state.doc, 1, 6)));
      openFontDialog(editor);
      field('family').value = 'Georgia';

      click(footerButton('Cancelar'));

      expect(editor.state.doc.child(0).firstChild!.marks, isEmpty);
    });

    test('a fonte efetiva aparece no formulário mesmo fora da lista padrão',
        () {
      final editor = mount();
      final font = schema.marks['font']!;
      editor.view.dispatch(editor.state.tr
        ..setSelection(TextSelection.create(editor.state.doc, 1, 6))
        ..addMark(1, 6, font.create({'value': 'Ecofont Sans'})));

      openFontDialog(editor);

      expect(field('family').value, 'Ecofont Sans',
          reason: 'abrir o diálogo não pode TROCAR a fonte do texto');
    });
  });

  group('modal', () {
    test('o diálogo abre no overlay e some ao fechar', () {
      final editor = mount();
      expect(host.querySelectorAll('.dq-office-dialog'), isEmpty);

      openParagraphDialog(editor);
      expect(host.querySelectorAll('.dq-office-dialog'), hasLength(1));
      expect(host.querySelectorAll('.dq-office-dialog-veil'), hasLength(1),
          reason: 'o véu é o que torna o diálogo modal');

      click(footerButton('Cancelar'));
      expect(host.querySelectorAll('.dq-office-dialog'), isEmpty);
    });

    test('abrir um diálogo fecha o anterior', () {
      final editor = mount();
      openParagraphDialog(editor);
      openFontDialog(editor);
      expect(host.querySelectorAll('.dq-office-dialog'), hasLength(1));
      expect(
          host.querySelector('.dq-office-dialog-title')!.textContent, 'Fonte');
    });

    test('o menu de contexto oferece Fonte… e Parágrafo…', () {
      mount();
      final canvas = host.querySelector('.dq-office-canvas') as FakeDomElement;
      canvas.dispatchEvent(
          'contextmenu',
          FakeDomMouseEvent(
              type: 'contextmenu', target: canvas, clientX: 10, clientY: 10));

      final labels = [
        for (final item in host.querySelectorAll('.dq-office-menu-label'))
          item.textContent
      ];
      expect(labels, containsAll(['Fonte…', 'Parágrafo…']));
    });
  });

  test('OfficeDialog aplica apenas no OK, e uma vez só', () {
    final editor = mount();
    var applied = 0;
    Map<String, String>? received;
    final dialog = OfficeDialog(
      controller: editor,
      title: 'Teste',
      fields: const [
        OfficeDialogField(key: 'a', label: 'A', kind: 'text', value: 'x'),
      ],
      onApply: (values) {
        applied++;
        received = values;
      },
    )..open();

    field('a').value = 'y';
    expect(applied, 0, reason: 'digitar não aplica');

    click(footerButton('OK'));

    expect(applied, 1);
    expect(received!['a'], 'y');
    expect(dialog.isOpen, isFalse);
  });
}
