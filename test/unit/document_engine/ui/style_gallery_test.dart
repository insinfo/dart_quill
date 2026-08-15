/// F8 — a galeria DINÂMICA de estilos da aba Página Inicial.
///
/// O que estes testes protegem:
/// * a galeria mostra os estilos DO DOCUMENTO quando existe catálogo, e não
///   regride para os quatro fixos quando ele não existe;
/// * o cartão aceso é o do `w:styleId` do bloco — não o do NOME, que muda;
/// * aplicar um cartão grava as três coisas que fazem o estilo aparecer na
///   tela E no DOCX (styleId, apresentação resolvida e marcas dos runs);
/// * o diálogo só oferece propriedades que o compositor honra.
@TestOn('vm')
library;

import 'package:test/test.dart';

import 'package:dart_quill/dart_quill_office.dart';
import 'package:dart_quill/src/document_engine/ui/dialogs/style_dialog.dart';
import 'package:dart_quill/src/document_engine/ui/ribbon_actions.dart'
    as actions;
import 'package:dart_quill/src/platform/dom.dart';

import '../../../support/fake_dom.dart';
import '../../../support/test_helpers.dart';

const String _stylesXml =
    '<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">'
    '<w:docDefaults><w:rPrDefault><w:rPr>'
    '<w:rFonts w:ascii="Times New Roman" w:hAnsi="Times New Roman"/>'
    '<w:sz w:val="24"/></w:rPr></w:rPrDefault></w:docDefaults>'
    '<w:style w:type="paragraph" w:default="1" w:styleId="Normal">'
    '<w:name w:val="Normal"/><w:qFormat/></w:style>'
    // Ttulo1 sem qFormat e sem formatação própria: existe só para dar a
    // Nivel01 a MESMA herança do corpus real (Nivel01 → Ttulo1), que é o que
    // faz o estilo ser reconhecido como de título.
    '<w:style w:type="paragraph" w:styleId="Ttulo1">'
    '<w:name w:val="heading 1"/><w:basedOn w:val="Normal"/></w:style>'
    '<w:style w:type="paragraph" w:styleId="Nivel01">'
    '<w:name w:val="Nivel 01"/><w:basedOn w:val="Ttulo1"/><w:qFormat/>'
    '<w:pPr><w:jc w:val="center"/><w:spacing w:before="240"/></w:pPr>'
    '<w:rPr><w:rFonts w:ascii="Arial" w:hAnsi="Arial"/><w:b/>'
    '<w:sz w:val="28"/><w:color w:val="C00000"/></w:rPr></w:style>'
    '<w:style w:type="paragraph" w:styleId="SemGaleria">'
    '<w:name w:val="Sem Galeria"/><w:basedOn w:val="Normal"/></w:style>'
    '</w:styles>';

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

  /// Um documento como o importador o produz: `word.styleId` no bloco e a
  /// apresentação já RESOLVIDA em `attrs['style']`, com as marcas dos runs
  /// achatadas da cascata. Reproduzir isso é o que torna o teste honesto —
  /// um doc "limpo" esconderia justamente o conflito marca × bloco.
  PMNode importedDoc() {
    final catalog = OfficeStyleCatalog.fromStylesXml(_stylesXml);
    PMNode block(String styleId, String text) {
      final style = catalog[styleId]!;
      return schema.node(
        styleId == 'Nivel01' ? 'heading' : 'paragraph',
        {
          if (styleId == 'Nivel01') 'level': 1,
          'word': {'styleId': styleId},
          'style': catalog.blockStyleOf(styleId),
        },
        Fragment.from([
          schema.text(text, [
            schema.marks['font']!.create(
                {'value': style.formatting.family ?? 'Times New Roman'}),
            schema.marks['size']!.create(
                {'value': '${(style.formatting.sizePt ?? 12).round()}pt'}),
            if (style.formatting.bold == true) schema.marks['bold']!.create(),
          ]),
        ]),
      );
    }

    return schema.node(
        'doc',
        null,
        Fragment.from([
          block('Nivel01', 'DO OBJETO'),
          block('Normal', 'Texto do corpo do documento.'),
          block('Nivel01', 'DA JUSTIFICATIVA'),
        ]));
  }

  OfficeWordEditor mount({bool withCatalog = true}) {
    final instance = editor = OfficeWordEditor.mount(
      host: host,
      adapter: adapter,
      document: withCatalog
          ? importedDoc()
          : schema.node(
              'doc',
              null,
              Fragment.from([
                schema.node(
                    'paragraph', null, Fragment.from([schema.text('oi')]))
              ])),
      schema: schema,
    );
    if (withCatalog) {
      instance.openDocument(
        importedDoc(),
        styleCatalog: OfficeStyleCatalog.fromStylesXml(_stylesXml),
      );
    }
    return instance;
  }

  List<DomElement> cards() => host.querySelectorAll('.dq-office-stylecard');
  List<String?> cardIds() =>
      [for (final card in cards()) card.getAttribute('data-style-id')];
  List<String> cardLabels() => [
        for (final label in host.querySelectorAll('.dq-office-stylecard-label'))
          label.textContent ?? ''
      ];

  DomElement cardOf(String styleId) => cards()
      .firstWhere((card) => card.getAttribute('data-style-id') == styleId);

  void click(DomElement element) => (element as FakeDomElement).dispatchEvent(
      'click', FakeDomMouseEvent(type: 'click', target: element));

  void rightClick(DomElement element) =>
      (element as FakeDomElement).dispatchEvent('contextmenu',
          FakeDomMouseEvent(type: 'contextmenu', target: element));

  DomElement menuItem(String text) => host
      .querySelectorAll('.dq-office-menu-item')
      .firstWhere((item) => (item.textContent ?? '').contains(text));

  DomElement field(String key) {
    for (final selector in const [
      '.dq-office-dialog-input',
      '.dq-office-dialog-check'
    ]) {
      for (final input in host.querySelectorAll(selector)) {
        if (input.getAttribute('data-field') == key) return input;
      }
    }
    throw StateError('campo não encontrado: $key');
  }

  DomElement footerButton(String label) => host
      .querySelectorAll('.dq-office-dialog-button')
      .firstWhere((button) => (button.textContent ?? '').contains(label));

  group('galeria', () {
    test('sem catálogo, os quatro cartões fixos continuam de pé', () {
      mount(withCatalog: false);
      expect(cardIds(), ['Normal', 'Heading1', 'Heading2', 'Heading3']);
      expect(cardLabels(), ['Normal', 'Título 1', 'Título 2', 'Título 3']);
    });

    test('com catálogo, os cartões são os estilos qFormat do documento', () {
      mount();
      expect(cardIds(), ['Normal', 'Nivel01'],
          reason: 'SemGaleria não tem w:qFormat e fica fora, como no Word');
      expect(cardLabels(), ['Normal', 'Nivel 01']);
    });

    test('o preview usa fonte, corpo, negrito e cor REAIS do estilo', () {
      mount();
      final sample = cardOf('Nivel01')
          .querySelectorAll('.dq-office-stylecard-sample')
          .first;
      final css = sample.getAttribute('style') ?? '';
      expect(css, contains("font-family:'Arial'"));
      expect(css, contains('font-weight:700'));
      expect(css, contains('color:#C00000'));
      expect(css, contains('text-align:center'));
      // 14 pt escalado e travado na faixa legível do cartão.
      expect(css, contains('font-size:'));
    });

    test('o cartão do estilo do bloco corrente fica aceso', () {
      final editor = mount();
      // O caret começa no primeiro bloco, que é "Nivel01".
      expect(cardOf('Nivel01').classes.contains('dq-office-stylecard-active'),
          isTrue);
      expect(cardOf('Normal').classes.contains('dq-office-stylecard-active'),
          isFalse);

      // Segundo bloco = Normal.
      final second = editor.state.doc.child(0).nodeSize + 1;
      editor.view.dispatch(editor.state.tr
        ..setSelection(TextSelection.create(editor.state.doc, second)));

      expect(cardOf('Normal').classes.contains('dq-office-stylecard-active'),
          isTrue);
      expect(cardOf('Nivel01').classes.contains('dq-office-stylecard-active'),
          isFalse);
    });

    /// A galeria é uma JANELA, não uma fileira: um DOCX real traz dezenas de
    /// estilos `qFormat`, e despejá-los todos na faixa fazia a ribbon crescer
    /// e nascer com uma barra de rolagem horizontal atravessando o editor —
    /// o que o Word nunca faz.
    test('os cartões vivem numa trilha recortada, com ▲ ▼ e "Mais"', () {
      mount();
      final viewport = host.querySelectorAll('.dq-office-stylegallery');
      expect(viewport, hasLength(1));
      final track = host.querySelectorAll('.dq-office-stylegallery-track');
      expect(track, hasLength(1));
      for (final card in cards()) {
        expect(card.parentNode, same(track.single),
            reason: 'nenhum cartão pode estar solto na linha da faixa');
      }
      expect(host.querySelectorAll('.dq-office-stylegallery-arrow'),
          hasLength(3));
    });

    test('"Mais" abre a galeria inteira sem roubar o realce da faixa', () {
      final editor = mount();
      final track = host.querySelector('.dq-office-stylegallery-track')!;
      DomElement trackCard(String styleId) => track
          .querySelectorAll('.dq-office-stylecard')
          .firstWhere((card) => card.getAttribute('data-style-id') == styleId);

      click(host.querySelector('.dq-office-stylegallery-more')!);

      final panel = host.querySelector('.dq-office-stylegallery-panel');
      expect(panel, isNotNull);
      expect(panel!.querySelectorAll('.dq-office-stylecard'), hasLength(2));
      // O cartão do painel nasce refletindo o estilo corrente…
      expect(
        panel
            .querySelectorAll('.dq-office-stylecard')
            .where((c) => c.classes.contains('dq-office-stylecard-active'))
            .length,
        1,
      );

      // …mas quem o realce de ESTADO continua atualizando é o cartão da
      // faixa: o mapa é indexado por styleId, e registrar os dois faria o
      // cartão descartável do painel substituir o permanente.
      final second = editor.state.doc.child(0).nodeSize + 1;
      editor.view.dispatch(editor.state.tr
        ..setSelection(TextSelection.create(editor.state.doc, second)));

      expect(
          trackCard('Normal').classes.contains('dq-office-stylecard-active'),
          isTrue);
      expect(
          trackCard('Nivel01').classes.contains('dq-office-stylecard-active'),
          isFalse);
    });
  });

  group('aplicar', () {
    test('clicar num cartão grava styleId, apresentação E marcas do run', () {
      final editor = mount();
      final second = editor.state.doc.child(0).nodeSize + 1;
      editor.view.dispatch(editor.state.tr
        ..setSelection(TextSelection.create(editor.state.doc, second)));

      click(cardOf('Nivel01'));

      final block = editor.state.doc.child(1);
      expect((block.attrs['word'] as Map)['styleId'], 'Nivel01');
      final style = block.attrs['style'] as Map;
      expect(style['wordStyleId'], 'Nivel01');
      expect(style['family'], 'Arial');
      expect(style['sizePt'], 14);
      expect(style['align'], 'center');
      // A marca do run tinha a fonte do estilo ANTIGO; sem trocá-la o
      // compositor continuaria desenhando Times (a marca ganha do bloco).
      final marks = {
        for (final mark in block.firstChild!.marks)
          mark.type.name: mark.attrs['value']
      };
      expect(marks['font'], 'Arial');
      expect(marks['size'], '14pt');
    });

    test('um estilo de título transforma o parágrafo em heading', () {
      final editor = mount();
      final second = editor.state.doc.child(0).nodeSize + 1;
      editor.view.dispatch(editor.state.tr
        ..setSelection(TextSelection.create(editor.state.doc, second)));

      click(cardOf('Nivel01'));

      expect(editor.state.doc.child(1).type.name, 'heading',
          reason: 'Nivel01 é basedOn de um estilo de título');
    });

    test('formatação DIRETA divergente sobrevive à troca de estilo', () {
      final editor = mount();
      final second = editor.state.doc.child(0).nodeSize + 1;
      editor.view.dispatch(editor.state.tr
        ..setSelection(TextSelection.create(editor.state.doc, second)));
      // Recuo posto à mão: não é o do estilo Normal (que não declara nenhum).
      editor.applyBlockStyle({'indentTwips': 1134});

      click(cardOf('Nivel01'));

      final style = editor.state.doc.child(1).attrs['style'] as Map;
      expect(style['indentTwips'], 1134,
          reason: 'o que o usuário ajustou à mão não é da cascata');
    });
  });

  group('menu do cartão', () {
    test('o botão direito abre os quatro comandos do Word', () {
      mount();
      rightClick(cardOf('Nivel01'));
      final labels = [
        for (final item in host.querySelectorAll('.dq-office-menu-item'))
          item.textContent ?? ''
      ];
      expect(labels.length, 4);
      expect(labels[0], contains('Corresponder à Seleção'));
      expect(labels[1], contains('Modificar'));
      expect(labels[2], contains('Renomear'));
      expect(labels[3], contains('Remover da Galeria'));
    });

    test('"Remover da Galeria" tira o cartão e mantém o estilo', () {
      final editor = mount();
      rightClick(cardOf('Nivel01'));
      click(menuItem('Remover da Galeria'));

      expect(cardIds(), ['Normal']);
      expect(editor.styleCatalog!['Nivel01'], isNotNull,
          reason: 'remover da GALERIA não pode apagar a definição');
      expect(editor.isDirty, isTrue);
    });

    test('renomear troca o rótulo sem mexer no id dos parágrafos', () {
      final editor = mount();
      rightClick(cardOf('Nivel01'));
      click(menuItem('Renomear'));
      field('name').value = 'Nível 1 — Seção';
      click(footerButton('OK'));

      expect(cardLabels(), ['Normal', 'Nível 1 — Seção']);
      expect(cardIds(), ['Normal', 'Nivel01']);
      expect((editor.state.doc.child(0).attrs['word'] as Map)['styleId'],
          'Nivel01');
    });

    test('"Atualizar para Corresponder à Seleção" leva a formatação do bloco',
        () {
      final editor = mount();
      editor.view.dispatch(editor.state.tr
        ..setSelection(TextSelection.create(editor.state.doc, 1)));
      editor.applyBlockStyle({'spaceAfterTwips': 300});

      rightClick(cardOf('Nivel01'));
      click(menuItem('Corresponder à Seleção'));

      expect(editor.styleCatalog!['Nivel01']!.formatting.spaceAfterTwips, 300);
      // E o OUTRO parágrafo do mesmo estilo acompanha.
      final last = editor.state.doc.child(2).attrs['style'] as Map;
      expect(last['spaceAfterTwips'], 300);
    });
  });

  group('diálogo Modificar Estilo', () {
    test('só expõe propriedades que o compositor honra a partir do BLOCO', () {
      final editor = mount();
      openModifyStyleDialog(editor, 'Nivel01');
      final keys = [
        for (final selector in const [
          '.dq-office-dialog-input',
          '.dq-office-dialog-check'
        ])
          for (final input in host.querySelectorAll(selector))
            input.getAttribute('data-field'),
      ];
      expect(
          keys,
          containsAll([
            'name',
            'basedOn',
            'family',
            'size',
            'bold',
            'align',
            'indentLeft',
            'indentFirst',
            'spaceBefore',
            'spaceAfter',
            'lineSpacing',
          ]));
      // Estes três NÃO podem estar aqui: `_BlockStyle` não tem os campos, e
      // o controle mudaria o modelo sem mudar a tela.
      expect(keys, isNot(contains('color')));
      expect(keys, isNot(contains('italic')));
      expect(keys, isNot(contains('underline')));
    });

    test('abre com os valores RESOLVIDOS do estilo', () {
      final editor = mount();
      openModifyStyleDialog(editor, 'Nivel01');
      expect(field('name').value, 'Nivel 01');
      expect(field('family').value, 'Arial');
      expect(field('size').value, '14');
      expect(field('bold').value, 'true');
      expect(field('align').value, 'Centralizado');
      expect(field('spaceBefore').value, '12');
    });

    test('cancelar não toca no catálogo nem no documento', () {
      final editor = mount();
      final before = editor.state.doc.child(0).attrs['style'];
      openModifyStyleDialog(editor, 'Nivel01');
      field('family').value = 'Verdana';
      click(footerButton('Cancelar'));

      expect(editor.styleCatalog!['Nivel01']!.formatting.family, 'Arial');
      expect(editor.state.doc.child(0).attrs['style'], before);
      expect(editor.styleCatalog!.hasEdits, isFalse);
    });

    test('OK muda o catálogo E todos os parágrafos que usam o estilo', () {
      final editor = mount();
      openModifyStyleDialog(editor, 'Nivel01');
      field('family').value = 'Verdana';
      field('size').value = '18';
      click(footerButton('OK'));

      expect(editor.styleCatalog!['Nivel01']!.formatting.family, 'Verdana');
      expect(editor.styleCatalog!.hasEdits, isTrue);

      for (final index in const [0, 2]) {
        final block = editor.state.doc.child(index);
        final style = block.attrs['style'] as Map;
        expect(style['family'], 'Verdana');
        expect(style['sizePt'], 18);
        final marks = {
          for (final mark in block.firstChild!.marks)
            mark.type.name: mark.attrs['value']
        };
        expect(marks['font'], 'Verdana',
            reason: 'sem reescrever a marca, a tela não mudaria');
        expect(marks['size'], '18pt');
      }
      // O parágrafo de outro estilo não foi tocado.
      expect((editor.state.doc.child(1).attrs['style'] as Map)['family'],
          'Times New Roman');
    });

    test('o undo volta a modificação inteira numa transação', () {
      final editor = mount();
      openModifyStyleDialog(editor, 'Nivel01');
      field('family').value = 'Verdana';
      click(footerButton('OK'));

      editor.runCommand('undo');

      expect(
          (editor.state.doc.child(0).attrs['style'] as Map)['family'], 'Arial');
      expect(
          (editor.state.doc.child(2).attrs['style'] as Map)['family'], 'Arial');
    });
  });

  group('criar estilo', () {
    test('nasce da seleção, entra na galeria e o bloco o adota', () {
      final editor = mount();
      final second = editor.state.doc.child(0).nodeSize + 1;
      editor.view.dispatch(editor.state.tr
        ..setSelection(TextSelection.create(editor.state.doc, second)));

      openCreateStyleDialog(editor);
      field('name').value = 'Meu Corpo';
      field('size').value = '13';
      click(footerButton('OK'));

      final created = editor.styleCatalog!['MeuCorpo'];
      expect(created, isNotNull,
          reason: 'o id do Word cai os não-alfanuméricos');
      expect(created!.inGallery, isTrue);
      expect(cardIds(), contains('MeuCorpo'));
      expect((editor.state.doc.child(1).attrs['word'] as Map)['styleId'],
          'MeuCorpo');
      expect((editor.state.doc.child(1).attrs['style'] as Map)['sizePt'], 13);
    });
  });

  group('ações sem chrome', () {
    test('currentStyleId cai no default do catálogo quando o bloco não diz',
        () {
      final editor = mount();
      final plain = schema.node(
          'doc',
          null,
          Fragment.from([
            schema.node('paragraph', null, Fragment.from([schema.text('x')]))
          ]));
      editor.openDocument(plain,
          styleCatalog: OfficeStyleCatalog.fromStylesXml(_stylesXml));
      expect(actions.currentStyleId(editor), 'Normal');
    });
  });
}
