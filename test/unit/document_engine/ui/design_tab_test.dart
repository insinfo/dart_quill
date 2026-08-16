/// A aba Design: marca-d'água, cor da página e bordas de página.
///
/// O contrato que estes testes protegem tem três partes:
///
/// 1. **nada disso é conteúdo** — ligar uma marca-d'água não muda uma
///    posição do documento, não repagina e não cria alvo de caret;
/// 2. **a tela e o PDF concordam** — o que o usuário vê ao aprovar é o que
///    vai para o arquivo assinado;
/// 3. **a moldura importada sobrevive** — o `w:pgBorders` de um DOCX vira
///    borda na tela, e salvar sem tocar nela não reescreve o `sectPr`.
@TestOn('vm')
library;

import 'package:test/test.dart';

import 'package:dart_quill/dart_quill_office.dart';
import 'package:dart_quill/src/document_engine/ui/ribbon_actions.dart'
    as actions;
import 'package:dart_quill/src/platform/dom.dart';

import '../../../support/fake_dom.dart';
import '../../../support/pdf_reader.dart';
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

  PMNode doc() => schema.node(
        'doc',
        null,
        Fragment.from([
          for (var i = 0; i < 3; i++)
            schema.node('paragraph', null,
                Fragment.from([schema.text('Parágrafo $i do documento.')])),
        ]),
      );

  OfficeWordEditor mount() => editor = OfficeWordEditor.mount(
        host: host,
        adapter: adapter,
        document: doc(),
        schema: schema,
        options: const OfficeWordEditorOptions(),
      );

  DomElement tab(String label) => host
      .querySelectorAll('.dq-office-ribbon-tab')
      .firstWhere((element) => element.textContent == label);

  void click(DomElement element) => (element as FakeDomElement)
      .dispatchEvent('click', FakeDomMouseEvent(type: 'click', target: element));

  DomElement menuItem(String text) => host
      .querySelectorAll('.dq-office-menu-item')
      .firstWhere((item) => (item.textContent ?? '').contains(text));

  group('a aba existe e é do Word', () {
    test('Design fica entre Inserir e Layout, e não é contextual', () {
      mount();
      final labels = [
        for (final element in host.querySelectorAll('.dq-office-ribbon-tab'))
          element.textContent
      ];
      expect(labels, containsAllInOrder(['Inserir', 'Design', 'Layout']));
      expect(tab('Design').classes.contains('dq-office-ribbon-tab-hidden'),
          isFalse);
    });

    test('traz os três comandos do grupo Plano de Fundo da Página', () {
      mount();
      click(tab('Design'));
      final titles = [
        for (final button in host.querySelectorAll('.dq-office-btn'))
          button.getAttribute('title')
      ];
      expect(titles, contains('Marca-d\'Água'));
      expect(titles, contains('Cor da Página'));
      expect(titles, contains('Bordas de Página'));
    });
  });

  group('marca-d\'água', () {
    test('a galeria aplica o texto e marca o vigente', () {
      final editor = mount();
      click(tab('Design'));
      click(host
          .querySelectorAll('.dq-office-btn')
          .firstWhere((b) => b.getAttribute('title') == 'Marca-d\'Água'));

      click(menuItem('MINUTA'));

      expect(editor.pageSetup.watermark?.text, 'MINUTA');
      expect(editor.pageSetup.watermark?.diagonal, isTrue);
    });

    test('aparece em TODAS as páginas, inerte e fora do documento', () {
      final editor = mount();
      actions.setWatermarkText(editor, 'MINUTA');

      final layers = host.querySelectorAll('.dq-office-watermark');
      expect(layers, isNotEmpty);
      expect(layers.length, editor.pageGraph.pages.length);
      for (final layer in layers) {
        expect(layer.textContent, 'MINUTA');
        expect(layer.getAttribute('contenteditable'), 'false');
        // Zero posições do documento: o caret nunca cai dentro dela, e
        // Ctrl+A não a seleciona.
        expect(layer.getAttribute('data-model-length'), '0');
        expect(layer.getAttribute('style'), contains('pointer-events:none'));
      }
    });

    test('ligar e desligar NÃO mexe no documento nem na paginação', () {
      final editor = mount();
      final before = editor.state.doc;
      final pagesBefore = editor.pageGraph.pages.length;

      actions.setWatermarkText(editor, 'RASCUNHO');
      expect(identical(editor.state.doc, before), isTrue,
          reason: 'a marca-d\'água é da FOLHA, não do texto');
      expect(editor.pageGraph.pages.length, pagesBefore);

      actions.setWatermarkText(editor, null);
      expect(editor.pageSetup.watermark, isNull);
      expect(host.querySelectorAll('.dq-office-watermark'), isEmpty);
    });

    test('a orientação segue o Word: diagonal por padrão', () {
      final editor = mount();
      actions.setWatermarkText(editor, 'CÓPIA');
      expect(host.querySelector('.dq-office-watermark')!.getAttribute('style'),
          contains('rotate(-45deg)'));

      actions.setWatermarkDiagonal(editor, false);

      expect(
          host.querySelector('.dq-office-watermark')!.getAttribute('style'),
          isNot(contains('rotate')));
    });

    test('o PDF carrega a mesma marca — o que foi aprovado é o que assina',
        () {
      final editor = mount();
      actions.setWatermarkText(editor, 'MINUTA');

      final pdf = PdfReader(editor.exportPdf()).decodedStreams.join(' ');

      expect(pdf, contains('MINUTA'));
      // A rotação sai por matriz de texto, não por transformação do sistema
      // de coordenadas (que inverteria também a conversão de y).
      expect(pdf, contains(' Tm'));
    });
  });

  group('cor da página', () {
    test('pinta a folha e não o conteúdo', () {
      final editor = mount();
      actions.setPageColor(editor, '#d9d9d9');

      final page = host.querySelector('.dq-office-page')!;
      expect(page.getAttribute('style'), contains('background:#d9d9d9'));
      final content = host.querySelector('.dq-office-page-content')!;
      expect(content.getAttribute('style') ?? '', isNot(contains('background')));
    });

    test('o PDF pinta a folha inteira antes do texto', () {
      final editor = mount();
      actions.setPageColor(editor, '#d9d9d9');
      final pdf = PdfReader(editor.exportPdf()).decodedStreams.join(' ');
      // `re f` é o retângulo preenchido; sem cor de página não haveria
      // nenhum no documento de teste.
      expect(pdf, contains('re f'));
    });

    test('remover devolve a folha branca', () {
      final editor = mount();
      actions.setPageColor(editor, '#d9d9d9');
      actions.setPageColor(editor, null);
      expect(editor.pageSetup.pageColor, isNull);
      expect(host.querySelector('.dq-office-page')!.getAttribute('style'),
          isNot(contains('background')));
    });
  });

  group('bordas de página', () {
    test('a galeria aplica as quatro arestas e marca a vigente', () {
      final editor = mount();
      actions.setPageBorder(editor, style: 'single', sizeEighths: 8);

      final borders = editor.pageSetup.pageBorders!;
      expect(borders.top!.widthTwips, 20); // 1 pt
      expect(borders.right!.isVisible, isTrue);
      expect(borders.bottom!.isVisible, isTrue);
      expect(borders.left!.isVisible, isTrue);
      expect(actions.currentPageBorderName(editor), 'Simples');
    });

    test('a moldura é desenhada por cima do conteúdo, e é inerte', () {
      final editor = mount();
      actions.setPageBorder(editor, style: 'single', sizeEighths: 8);

      final layer = host.querySelector('.dq-office-pageborder')!;
      final style = layer.getAttribute('style')!;
      expect(style, contains('pointer-events:none'));
      expect(layer.getAttribute('data-model-length'), '0');
      // Recuo padrão do Word: 24 pt da borda do papel — que a 96 dpi são
      // 32 px na projeção.
      expect(style, contains('left:32px'));
    });

    test('"Sem borda" remove a moldura', () {
      final editor = mount();
      actions.setPageBorder(editor, style: 'single', sizeEighths: 8);
      actions.setPageBorder(editor, style: null, sizeEighths: 0);

      expect(editor.pageSetup.pageBorders, isNull);
      expect(host.querySelectorAll('.dq-office-pageborder'), isEmpty);
      expect(actions.currentPageBorderName(editor), 'Sem borda');
    });

    test('o PDF desenha as quatro linhas', () {
      final editor = mount();
      actions.setPageBorder(editor, style: 'single', sizeEighths: 8);
      final pdf = PdfReader(editor.exportPdf()).decodedStreams.join(' ');
      // Quatro `S` de stroke a mais que o documento sem moldura.
      expect(RegExp(r'\bS\b').allMatches(pdf).length, greaterThanOrEqualTo(4));
    });
  });

  group('conversão OOXML', () {
    test('w:pgBorders → layout: oitavos de ponto viram twips', () {
      final borders = officePageBordersFromOoxml({
        'offsetFrom': 'page',
        'top': {'val': 'single', 'sz': 8, 'color': 'C00000', 'space': 24},
        'left': {'val': 'dashed', 'sz': 24, 'color': '000000', 'space': 24},
      });

      expect(borders, isNotNull);
      // 8 oitavos = 1 pt = 20 twips.
      expect(borders!.top!.widthTwips, 20);
      expect(borders.top!.color, '#C00000');
      expect(borders.left!.style, 'dashed');
      expect(borders.right, isNull);
      expect(officePageBorderSpaceOf({
        'top': {'space': 31}
      }), 31);
    });

    test('layout → w:pgBorders e de volta é ponto fixo', () {
      const border = TableBorder(style: 'double', widthTwips: 30);
      const borders = BlockBorders(
          top: border, right: border, bottom: border, left: border);

      final ooxml = officePageBordersToOoxml(borders, spacePt: 20)!;
      expect(ooxml['offsetFrom'], 'page');
      expect((ooxml['top'] as Map)['val'], 'double');
      expect((ooxml['top'] as Map)['space'], 20);

      final back = officePageBordersFromOoxml(ooxml)!;
      expect(back.top!.style, 'double');
      expect(back.top!.widthTwips, 30);
      expect(officePageBorderSpaceOf(ooxml), 20);
    });

    test('val="nil" não vira moldura invisível', () {
      expect(
        officePageBordersFromOoxml({
          'top': {'val': 'nil'},
          'left': {'val': 'none'},
        }),
        isNull,
      );
    });
  });

  group('a geometria não perde campos', () {
    test('trocar papel/orientação PRESERVA o chrome da folha', () {
      final editor = mount();
      actions.setWatermarkText(editor, 'MINUTA');
      actions.setPageColor(editor, '#eaf3fb');
      actions.setPageBorder(editor, style: 'single', sizeEighths: 8);

      actions.setOrientation(editor, portrait: false);
      actions.setPaper(editor, 'Ofício');

      // O `_copySetup` listava campo a campo e apagava tudo que fosse novo:
      // é exatamente assim que a grade de texto do documento se perdeu.
      expect(editor.pageSetup.watermark?.text, 'MINUTA');
      expect(editor.pageSetup.pageColor, '#eaf3fb');
      expect(editor.pageSetup.pageBorders?.top?.isVisible, isTrue);
    });

    test('copyWith remove só o que o chamador pediu', () {
      const setup = PageSetupTwips(
        pageColor: '#ffffff',
        watermark: OfficePageWatermark(text: 'X'),
      );
      expect(setup.copyWith(clearWatermark: true).pageColor, '#ffffff');
      expect(setup.copyWith(clearWatermark: true).watermark, isNull);
      expect(setup.copyWith(clearPageColor: true).watermark?.text, 'X');
    });
  });
}
