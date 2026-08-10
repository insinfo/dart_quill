@TestOn('vm')
library;

import 'package:dart_quill/dart_quill_office.dart';
import 'package:test/test.dart';

import '../../../support/fake_dom.dart';

/// Disposição do texto (`wp:wrapSquare` e afins) no compositor.
///
/// O que estes testes cobram é a LINHA, não o atributo: um controle que
/// grava `wrapMode` sem encurtar linha nenhuma é exatamente o que este
/// arquivo existe para impedir.
void main() {
  final schema = officeQuillSchema();

  PMNode paragraph(List<PMNode> content, {Map<String, Object?>? attrs}) =>
      schema.node('paragraph', attrs, Fragment.from(content));

  PMNode doc(List<PMNode> blocks) =>
      schema.node('doc', null, Fragment.from(blocks));

  /// Uma caixa flutuante larga, encostada à direita da área útil.
  PMNode floatingBox({
    required String wrapMode,
    String? wrapSide,
    String positionHAlign = 'right',
    int width = 3000,
    int height = 2000,
    int offsetY = 0,
  }) =>
      schema.node('textBox', {
        'text': 'caixa',
        'width': width,
        'height': height,
        'offsetY': offsetY,
        'positionHAlign': positionHAlign,
        'wrapMode': wrapMode,
        if (wrapSide != null) 'wrapSide': wrapSide,
      });

  const longText = 'Lorem ipsum dolor sit amet consectetur adipiscing elit '
      'sed do eiusmod tempor incididunt ut labore et dolore magna aliqua '
      'ut enim ad minim veniam quis nostrud exercitation ullamco laboris '
      'nisi ut aliquip ex ea commodo consequat duis aute irure dolor';

  /// Documento com a caixa ancorada num parágrafo curto e um parágrafo
  /// longo logo abaixo — o caso real de um carimbo lateral.
  PageGraph composeWith(PMNode box) => LayoutComposer().compose(doc([
        paragraph([schema.text('âncora'), box]),
        paragraph([schema.text(longText)]),
      ]));

  List<LineBox> bodyLinesOf(PageGraph graph) {
    final fragments = graph.pages.first.fragments.cast<BlockFragment>();
    return fragments.last.lines;
  }

  group('exclusão lateral encurta a LINHA', () {
    test('wrapSquare à direita reduz a largura útil das linhas cobertas', () {
      final withoutWrap = composeWith(floatingBox(wrapMode: 'inFrontOfText'));
      final withWrap = composeWith(floatingBox(wrapMode: 'square'));

      final plain = bodyLinesOf(withoutWrap);
      final wrapped = bodyLinesOf(withWrap);

      expect(plain.first.wrapRightInsetTwips, 0,
          reason: 'sem exclusão nada encolhe');
      expect(wrapped.first.wrapRightInsetTwips, greaterThan(0),
          reason: 'a linha tem de ENCURTAR ao lado da caixa, não só desviar');
      expect(wrapped.first.widthTwips, lessThan(plain.first.widthTwips));
      expect(wrapped.first.charEnd, lessThan(plain.first.charEnd),
          reason: 'linha mais curta cabe menos texto');
      expect(wrapped.length, greaterThan(plain.length),
          reason: 'o mesmo texto passa a precisar de mais linhas');
    });

    test('a exclusão termina onde a caixa termina', () {
      final graph = composeWith(
          floatingBox(wrapMode: 'square', width: 3000, height: 700));
      final lines = bodyLinesOf(graph);

      expect(lines.first.wrapRightInsetTwips, greaterThan(0));
      expect(lines.last.wrapRightInsetTwips, 0,
          reason: 'abaixo da caixa a linha volta à largura inteira');
      expect(lines.last.wrapLeftInsetTwips, 0);
    });

    test('wrapText=left mantém o texto à esquerda de uma caixa centralizada',
        () {
      final graph = composeWith(floatingBox(
        wrapMode: 'square',
        wrapSide: 'left',
        positionHAlign: 'center',
      ));
      final line = bodyLinesOf(graph).first;

      expect(line.wrapRightInsetTwips, greaterThan(0));
      expect(line.wrapLeftInsetTwips, 0);
    });

    test('wrapText=right empurra o começo da linha para depois da caixa', () {
      final graph = composeWith(floatingBox(
        wrapMode: 'square',
        wrapSide: 'right',
        positionHAlign: 'left',
      ));
      final line = bodyLinesOf(graph).first;

      expect(line.wrapLeftInsetTwips, greaterThan(0));
      expect(line.wrapRightInsetTwips, 0);
    });

    test('bothSides escolhe o lado com mais espaço', () {
      // Caixa colada à esquerda: sobra mais espaço à DIREITA dela, então o
      // texto corre à direita e a linha começa depois da caixa.
      final atLeft = bodyLinesOf(composeWith(floatingBox(
        wrapMode: 'square',
        positionHAlign: 'left',
      ))).first;
      // Caixa colada à direita: sobra mais espaço à ESQUERDA.
      final atRight = bodyLinesOf(composeWith(floatingBox(
        wrapMode: 'square',
        positionHAlign: 'right',
      ))).first;

      expect(atLeft.wrapLeftInsetTwips, greaterThan(0));
      expect(atLeft.wrapRightInsetTwips, 0);
      expect(atRight.wrapRightInsetTwips, greaterThan(0));
      expect(atRight.wrapLeftInsetTwips, 0);
    });

    test('tight e through usam a mesma caixa delimitadora do square', () {
      final square = bodyLinesOf(composeWith(floatingBox(wrapMode: 'square')));
      final tight = bodyLinesOf(composeWith(floatingBox(wrapMode: 'tight')));
      final through =
          bodyLinesOf(composeWith(floatingBox(wrapMode: 'through')));

      expect(tight.first.wrapRightInsetTwips, square.first.wrapRightInsetTwips);
      expect(
          through.first.wrapRightInsetTwips, square.first.wrapRightInsetTwips);
    });

    test('behindText e inFrontOfText não excluem nada', () {
      for (final mode in const ['behindText', 'inFrontOfText']) {
        final lines = bodyLinesOf(composeWith(floatingBox(wrapMode: mode)));
        expect(lines.every((line) => line.wrapRightInsetTwips == 0), isTrue,
            reason: '$mode não cria exclusão');
        expect(lines.every((line) => line.wrapLeftInsetTwips == 0), isTrue,
            reason: '$mode não cria exclusão');
      }
    });

    test('o parágrafo ÂNCORA também encurta ao redor da própria caixa', () {
      final graph = LayoutComposer().compose(doc([
        paragraph([floatingBox(wrapMode: 'square'), schema.text(longText)]),
      ]));
      final lines = (graph.pages.first.fragments.single as BlockFragment).lines;

      expect(lines.first.wrapRightInsetTwips, greaterThan(0),
          reason: 'a segunda passada fecha o laço âncora↔exclusão: a linha '
              'que HOSPEDA a caixa já nasce encurtada');
    });

    test('a exclusão começa na linha da âncora, não no topo do parágrafo', () {
      // Caixa ancorada no FIM do parágrafo: as linhas acima dela não têm por
      // que desviar, e desviar seria pior do que não desviar.
      final graph = LayoutComposer().compose(doc([
        paragraph([schema.text(longText), floatingBox(wrapMode: 'square')]),
      ]));
      final lines = (graph.pages.first.fragments.single as BlockFragment).lines;

      expect(lines.first.wrapRightInsetTwips, 0);
      expect(lines.last.wrapRightInsetTwips, greaterThan(0));
    });
  });

  group('exclusão vertical', () {
    test('wrapTopAndBottom empurra o parágrafo seguinte para baixo da caixa',
        () {
      final without = LayoutComposer().compose(doc([
        paragraph([
          schema.text('âncora'),
          floatingBox(wrapMode: 'inFrontOfText', height: 2000)
        ]),
        paragraph([schema.text('depois')]),
      ]));
      final with_ = LayoutComposer().compose(doc([
        paragraph([
          schema.text('âncora'),
          floatingBox(wrapMode: 'topAndBottom', height: 2000)
        ]),
        paragraph([schema.text('depois')]),
      ]));

      final plainSecond = without.pages.first.fragments[1] as BlockFragment;
      final pushedSecond = with_.pages.first.fragments[1] as BlockFragment;

      expect(pushedSecond.yTwips, greaterThan(plainSecond.yTwips));
      expect(pushedSecond.yTwips, greaterThanOrEqualTo(2000),
          reason: 'o corpo recomeça abaixo da caixa de 2000 twips');
      // E nenhuma linha encurta: topAndBottom desloca, não estreita.
      expect(pushedSecond.lines.first.wrapRightInsetTwips, 0);
    });
  });

  group('renderers projetam a MESMA exclusão', () {
    test('DOM soma o inset ao left/right da linha', () {
      final graph = composeWith(floatingBox(wrapMode: 'square'));
      final line = bodyLinesOf(graph).first;
      expect(line.wrapRightInsetTwips, greaterThan(0));

      final document = FakeDomDocument();
      final host = document.createElement('div');
      document.body.append(host);
      PageGraphDomRenderer(document: document, editable: true)
          .render(graph, host);

      final lines = host.querySelectorAll('.dq-office-line');
      expect(lines, isNotEmpty);
      final styles = [
        for (final element in lines) element.getAttribute('style') ?? '',
      ];
      final rightPx = line.wrapRightInsetTwips / 20 * (96 / 72);
      expect(
        styles.any((style) =>
            style.contains('right:${rightPx.toStringAsFixed(2)}px') ||
            style.contains('right:${rightPx.round()}px')),
        isTrue,
        reason: 'alguma linha projetada carrega o recuo da exclusão; '
            'estilos: $styles',
      );
    });

    test('PDF consome o mesmo PageGraph e escreve sem quebrar', () {
      final graph = composeWith(floatingBox(wrapMode: 'square'));
      final bytes = PageGraphPdfRenderer().render(graph);
      expect(bytes, isNotEmpty);
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    });
  });
}
