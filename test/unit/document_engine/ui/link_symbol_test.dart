/// Inserir → Link (Ctrl+K) e Inserir → Símbolo (F10).
///
/// O que estes testes protegem: o link é aplicado como MARCA do schema (nada
/// de nó novo), vale para o hiperlink INTEIRO quando o cursor está dentro
/// dele, some por completo quando o endereço é apagado — e o símbolo entra
/// como texto comum, sem virar átomo.
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

  PMNode paragraph(List<PMNode> content) =>
      schema.node('paragraph', null, Fragment.from(content));

  PMNode docOf(List<PMNode> blocks) =>
      schema.node('doc', null, Fragment.from(blocks));

  OfficeWordEditor mount(PMNode document) => editor = OfficeWordEditor.mount(
        host: host,
        adapter: adapter,
        document: document,
        schema: schema,
      );

  OfficeWordEditor mountText(String text) => mount(docOf([
        paragraph([schema.text(text)])
      ]));

  void select(OfficeWordEditor editor, int from, [int? to]) {
    editor.view.dispatch(editor.state.tr
      ..setSelection(TextSelection.create(editor.state.doc, from, to ?? from)));
  }

  void click(DomElement element) => (element as FakeDomElement).dispatchEvent(
      'click', FakeDomMouseEvent(type: 'click', target: element));

  DomElement dialogField(String key) {
    for (final input in host.querySelectorAll('.dq-office-dialog-input')) {
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

  String? dialogTitle() =>
      host.querySelector('.dq-office-dialog-title')?.textContent;

  Map<String, Mark> marksAt(OfficeWordEditor editor, int pos) => {
        for (final mark in editor.state.doc.resolve(pos).marks())
          mark.type.name: mark
      };

  group('normalização do endereço', () {
    test('sem esquema vale https, e-mail vira mailto', () {
      expect(officeNormalizeHref('www.exemplo.com'), 'https://www.exemplo.com');
      expect(officeNormalizeHref('contato@exemplo.com'),
          'mailto:contato@exemplo.com');
      expect(officeNormalizeHref('https://x.dev/a?b=1'), 'https://x.dev/a?b=1');
      expect(officeNormalizeHref('#indicador'), '#indicador');
    });

    test('esquema executável é RECUSADO', () {
      // O href viaja no DOCX e é reprojetado por quem abrir o documento: um
      // javascript: guardado aqui é XSS na aplicação de terceiro.
      expect(officeNormalizeHref('javascript:alert(1)'), isNull);
      expect(officeNormalizeHref('JavaScript:alert(1)'), isNull);
      expect(officeNormalizeHref('data:text/html,<script>'), isNull);
      expect(officeNormalizeHref('   '), isNull);
    });
  });

  group('aplicar link', () {
    test('Ctrl+K abre o diálogo com o texto selecionado', () {
      final editor = mountText('veja o site aqui');
      select(editor, 8, 12);

      (host as FakeDomElement).dispatchEvent(
          'keydown',
          FakeDomKeyboardEvent(
              type: 'keydown', target: host, key: 'k', ctrlKey: true));

      expect(dialogTitle(), 'Inserir Link');
      expect(dialogField('text').value, 'site');
      expect(dialogField('href').value, '');
    });

    test('OK aplica a marca link (e a aparência) numa transação só', () {
      final editor = mountText('veja o site aqui');
      select(editor, 8, 12);

      openLinkDialog(editor);
      dialogField('href').value = 'www.exemplo.com';
      click(footerButton('OK'));

      final marks = marksAt(editor, 9);
      expect(marks['link']?.attrs['href'], 'https://www.exemplo.com');
      expect(marks.containsKey('underline'), isTrue,
          reason: 'um link sem aparência é um controle que não mostra nada');
      expect(marks['color']?.attrs['value'], officeHyperlinkColor);
      expect(editor.state.doc.child(0).textContent, 'veja o site aqui',
          reason: 'o texto não muda quando o campo não muda');

      editor.runCommand('undo');
      expect(marksAt(editor, 9), isEmpty,
          reason: 'um Ctrl+Z desfaz marca e aparência juntas');
    });

    test('trocar o texto de exibição reescreve o run e mantém o link', () {
      final editor = mountText('veja o site aqui');
      select(editor, 8, 12);

      openLinkDialog(editor);
      dialogField('text').value = 'nosso portal';
      dialogField('href').value = 'https://exemplo.com';
      click(footerButton('OK'));

      expect(editor.state.doc.child(0).textContent, 'veja o nosso portal aqui');
      expect(marksAt(editor, 9)['link']?.attrs['href'], 'https://exemplo.com');
    });

    test('sem seleção, o texto digitado é INSERIDO com o link', () {
      final editor = mountText('vazio: ');
      select(editor, 8);

      openLinkDialog(editor);
      dialogField('text').value = 'site';
      dialogField('href').value = 'exemplo.com';
      click(footerButton('OK'));

      expect(editor.state.doc.child(0).textContent, 'vazio: site');
      expect(marksAt(editor, 9)['link']?.attrs['href'], 'https://exemplo.com');
    });

    test('endereço recusado não muda nada', () {
      final editor = mountText('veja o site aqui');
      select(editor, 8, 12);

      openLinkDialog(editor);
      dialogField('href').value = 'javascript:alert(1)';
      click(footerButton('OK'));

      expect(marksAt(editor, 9), isEmpty);
    });

    test('Cancelar não aplica nada', () {
      final editor = mountText('veja o site aqui');
      select(editor, 8, 12);

      openLinkDialog(editor);
      dialogField('href').value = 'exemplo.com';
      click(footerButton('Cancelar'));

      expect(marksAt(editor, 9), isEmpty);
    });
  });

  group('editar e remover', () {
    OfficeWordEditor withLink() {
      final link = schema.marks['link']!;
      final underline = schema.marks['underline']!;
      final color = schema.marks['color']!;
      final marks = [
        link.create({'href': 'https://antigo.com'}),
        underline.create(),
        color.create({'value': officeHyperlinkColor}),
      ];
      return mount(docOf([
        paragraph([
          schema.text('veja o '),
          // Dois runs vizinhos com a MESMA marca: o link é um só, e a UI tem
          // de tratá-lo assim (o negrito no meio de um link é comum).
          schema.text('si', marks),
          schema.text('te', [...marks, schema.marks['bold']!.create()]),
          schema.text(' aqui'),
        ]),
      ]));
    }

    test('officeLinkAt devolve a faixa INTEIRA a partir do cursor no meio', () {
      final editor = withLink();
      select(editor, 10); // dentro de "site"

      final found = officeLinkAt(editor.state)!;

      expect(found.href, 'https://antigo.com');
      expect(found.from, 8);
      expect(found.to, 12);
      expect(editor.state.doc.textBetween(found.from, found.to), 'site');
    });

    test('o diálogo abre em modo edição com o endereço atual', () {
      final editor = withLink();
      select(editor, 10);

      openLinkDialog(editor);

      expect(dialogTitle(), 'Editar Link');
      expect(dialogField('href').value, 'https://antigo.com');
      expect(dialogField('text').value, 'site');
    });

    test('reescrever o endereço vale para o link inteiro', () {
      final editor = withLink();
      select(editor, 10);

      openLinkDialog(editor);
      dialogField('href').value = 'https://novo.com';
      click(footerButton('OK'));

      expect(marksAt(editor, 9)['link']?.attrs['href'], 'https://novo.com');
      expect(marksAt(editor, 11)['link']?.attrs['href'], 'https://novo.com');
    });

    test('endereço em branco REMOVE o link e a aparência dele', () {
      final editor = withLink();
      select(editor, 10);

      openLinkDialog(editor);
      dialogField('href').value = '';
      click(footerButton('OK'));

      final marks = marksAt(editor, 9);
      expect(marks.containsKey('link'), isFalse);
      expect(marks.containsKey('underline'), isFalse);
      expect(marks.containsKey('color'), isFalse);
      expect(editor.state.doc.child(0).textContent, 'veja o site aqui',
          reason: 'remover o link preserva o texto');
      // A formatação que era do USUÁRIO fica: só a do hiperlink sai.
      expect(marksAt(editor, 11).containsKey('bold'), isTrue);
    });

    test('cor escolhida pelo usuário sobrevive à remoção do link', () {
      final link = schema.marks['link']!;
      final color = schema.marks['color']!;
      final editor = mount(docOf([
        paragraph([
          schema.text('um ', null),
          schema.text('link', [
            link.create({'href': 'https://x.dev'}),
            color.create({'value': '#FF0000'}),
          ]),
        ]),
      ]));

      officeRemoveLink(editor, from: 4, to: 8);

      final marks = marksAt(editor, 5);
      expect(marks.containsKey('link'), isFalse);
      expect(marks['color']?.attrs['value'], '#FF0000');
    });

    test('sem link sob o cursor não há faixa', () {
      final editor = mountText('texto sem link');
      select(editor, 3);
      expect(officeLinkAt(editor.state), isNull);
    });
  });

  group('símbolo', () {
    test('a galeria oferece os sinais e insere no cursor', () {
      final editor = mountText('a b');
      select(editor, 2);

      final gallery = buildSymbolGallery(editor, (symbol) {
        officeInsertSymbol(editor, symbol);
      });
      host.append(gallery);

      final cells = host.querySelectorAll('.dq-office-symbol');
      expect(cells.length, officeSymbols.length);
      expect(
          [for (final cell in cells) cell.getAttribute('data-symbol')],
          containsAll([
            'Ω',
            '§',
            '©',
            '®',
            '±',
            '×',
            '÷',
            '≤',
            '≥',
            '≠',
            '→',
            '€',
            '£',
            '¼',
            '½',
            '¾',
            '“',
            '”',
            '—',
            '\u00a0'
          ]));

      final omega =
          cells.firstWhere((cell) => cell.getAttribute('data-symbol') == 'Ω');
      click(omega);

      expect(editor.state.doc.child(0).textContent, 'aΩ b');
    });

    test('o símbolo é TEXTO, não átomo, e herda a formatação do ponto', () {
      final bold = schema.marks['bold']!;
      final editor = mount(docOf([
        paragraph([
          schema.text('ab', [bold.create()])
        ]),
      ]));
      select(editor, 3);

      officeInsertSymbol(editor, '§');

      final block = editor.state.doc.child(0);
      expect(block.childCount, 1, reason: 'entrou no MESMO run, sem nó novo');
      expect(block.firstChild!.isText, isTrue);
      expect(block.textContent, 'ab§');
      expect(block.firstChild!.marks.map((mark) => mark.type.name),
          contains('bold'));
    });

    test('o espaço não separável entra como caractere de texto', () {
      final editor = mountText('a b');
      select(editor, 2, 3);

      officeInsertSymbol(editor, '\u00a0');

      expect(editor.state.doc.child(0).textContent, 'a\u00a0b');
    });

    test('a galeria abre no overlay e some ao escolher', () {
      final editor = mountText('texto');
      select(editor, 1);
      final anchor = adapter.document.createElement('span');
      host.append(anchor);

      openSymbolGallery(editor, anchor);
      expect(host.querySelectorAll('.dq-office-symbols'), hasLength(1));

      click(host.querySelectorAll('.dq-office-symbol').first);

      expect(host.querySelectorAll('.dq-office-symbols'), isEmpty);
      expect(editor.state.doc.child(0).textContent, startsWith('€'));
    });
  });

  group('marcas de formatação (¶)', () {
    test('alterna uma CLASSE no host, e nada mais', () {
      final editor = mountText('um dois');
      final pages = host.querySelector('.dq-office-pages')!;
      final projection = pages.innerHTML;
      final document = editor.state.doc;

      expect(officeToggleFormattingMarks(editor), isTrue);
      expect(host.classes.contains(officeFormattingMarksClass), isTrue);

      // O contrato que impede o adorno de virar conteúdo: a projeção é
      // BYTE A BYTE a mesma, então o mapa de posições (que soma
      // `data-model-length`/`textContent`) não tem como se deslocar, e o
      // documento não foi tocado. Um ¶ inserido como nó quebraria isto.
      expect(pages.innerHTML, projection);
      expect(identical(editor.state.doc, document), isTrue);

      expect(officeToggleFormattingMarks(editor), isFalse);
      expect(host.classes.contains(officeFormattingMarksClass), isFalse);
      expect(pages.innerHTML, projection);
    });

    test('o botão da Página Inicial acende com o estado', () {
      final editor = mountText('um dois');
      click(host
          .querySelectorAll('.dq-office-ribbon-tab')
          .firstWhere((tab) => tab.textContent == 'Página Inicial'));
      final button = host.querySelectorAll('.dq-office-btn').firstWhere(
          (element) =>
              (element.getAttribute('title') ?? '').startsWith('Mostrar Tudo'));

      click(button);
      expect(officeFormattingMarksVisible(editor), isTrue);
      expect(button.classes.contains('dq-office-btn-active'), isTrue);

      click(button);
      expect(officeFormattingMarksVisible(editor), isFalse);
      expect(button.classes.contains('dq-office-btn-active'), isFalse);
    });
  });
}
