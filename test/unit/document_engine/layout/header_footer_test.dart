/// Fase 4 — cabeçalho e rodapé como regiões.
///
/// Todo ofício e memorando tem timbre e numeração de página. Eles são
/// regiões PRÓPRIAS: repetem em todas as páginas, ficam fora do espaço de
/// posições do documento e são inertes na projeção — a mesma região
/// aparecendo N vezes não pode virar N edições concorrentes do mesmo nó.
@TestOn('vm')
library;

import 'package:test/test.dart';

import 'dart:typed_data';

import 'package:dart_quill/dart_quill_office.dart';

import '../../../support/pdf_reader.dart';

void main() {
  final schema = officeQuillSchema();

  PMNode paragraph(String text) =>
      schema.node('paragraph', null, Fragment.from([schema.text(text)]));

  PMNode region(String text) =>
      schema.node('doc', null, Fragment.from([paragraph(text)]));

  PMNode exactParagraph(String text, int lineTwips,
          {bool sectionBreak = false}) =>
      schema.node(
          'paragraph',
          {
            'style': {
              'lineTwips': lineTwips,
              'lineRule': 'exact',
              'spaceBeforeTwips': 0,
              'spaceAfterTwips': 0,
              'widowControl': false,
              if (sectionBreak) 'sectionBreak': true,
            }
          },
          Fragment.from([schema.text(text)]));

  PMNode exactRegion(String text, int lineTwips) => schema.node(
      'doc', null, Fragment.from([exactParagraph(text, lineTwips)]));

  PMNode exactBody(int blocks, int lineTwips,
          {bool firstEndsSection = false}) =>
      schema.node(
          'doc',
          null,
          Fragment.from([
            for (var i = 0; i < blocks; i++)
              exactParagraph('Linha $i', lineTwips,
                  sectionBreak: firstEndsSection && i == 0),
          ]));

  PMNode body(int blocks) => schema.node(
      'doc',
      null,
      Fragment.from([
        for (var i = 0; i < blocks; i++)
          paragraph('Parágrafo $i com texto suficiente para ocupar a linha '
              'inteira e forçar a paginação a trabalhar.')
      ]));

  /// O texto que o PDF realmente desenha. Os content streams são
  /// comprimidos, então ler os bytes crus não encontraria nada.
  String pdfText(List<int> bytes) =>
      PdfReader(Uint8List.fromList(bytes)).decodedStreams.join('\n');

  group('composição', () {
    test('a região aparece em TODAS as páginas', () {
      final graph = LayoutComposer(
        header: region('Prefeitura Municipal'),
        footer: region('documento oficial'),
      ).compose(body(300));

      expect(graph.pages.length, greaterThan(2));
      for (final page in graph.pages) {
        expect(page.header, isNotEmpty);
        expect(page.footer, isNotEmpty);
      }
    });

    test('sem região, nada é adicionado', () {
      final graph = LayoutComposer().compose(body(60));
      expect(graph.pages.first.header, isEmpty);
      expect(graph.pages.first.footer, isEmpty);
    });

    test('a região NÃO entra no espaço de posições do documento', () {
      final graph = LayoutComposer(header: region('timbre')).compose(body(120));
      for (final entry in graph.positionMap.entries) {
        expect(entry.docPosStart, greaterThanOrEqualTo(0),
            reason: 'nenhuma posição do corpo pode vir da região');
      }
      // O fragmento da região declara -1: não corresponde a posição alguma.
      expect(graph.pages.first.header.first.docPos, -1);
    });

    test('sem campo, a MESMA lista é reusada em todas as páginas', () {
      final graph =
          LayoutComposer(header: region('timbre fixo')).compose(body(300));
      final first = graph.pages.first.header;
      for (final page in graph.pages) {
        expect(identical(page.header, first), isTrue,
            reason: 'recompor conteúdo idêntico 200 vezes é desperdício puro');
      }
    });

    test(
        'anchor de header relativo ao parágrafo usa linePitch cru sem ativar a grade do corpo',
        () {
      PMNode anchoredHeader(String relativeFrom) => schema.node(
            'doc',
            null,
            Fragment.from([
              schema.node(
                'paragraph',
                {
                  'style': {
                    'lineTwips': 200,
                    'lineRule': 'exact',
                  }
                },
                Fragment.from([
                  schema.node('textBox', {
                    'text': 'carimbo',
                    'height': 900,
                    'offsetY': 100,
                    'positionVRelativeFrom': relativeFrom,
                    'word': '<wp:wrapTopAndBottom/>',
                  })
                ]),
              )
            ]),
          );

      const setup = PageSetupTwips(
        marginTopTwips: 1000,
        headerDistanceTwips: 200,
        documentGridLinePitchTwips: 326,
        // Ausente/default: a grade não arredonda linhas comuns do corpo.
      );
      final paragraphRelative = LayoutComposer(
        setup: setup,
        header: anchoredHeader('paragraph'),
      ).compose(schema.node(
          'doc',
          null,
          Fragment.from([
            schema.node(
                'paragraph',
                {
                  'style': {
                    'lineTwips': 200,
                    'lineRule': 'exact',
                  }
                },
                Fragment.from([schema.text('corpo')]))
          ])));
      final bodyBlock =
          paragraphRelative.pages.single.fragments.single as BlockFragment;

      expect(bodyBlock.lines.single.heightTwips, 200,
          reason: 'docGrid sem type continua inativo no fluxo do corpo');
      expect(bodyBlock.yTwips, 526,
          reason:
              '200 headerDistance + 326 linha da grade + 100 offset + 900 caixa - 1000 marginTop');

      final pageRelative = LayoutComposer(
        setup: setup,
        header: anchoredHeader('page'),
      ).compose(body(1));
      expect(pageRelative.pages.single.fragments.single.yTwips, 200,
          reason:
              'anchors relativos à página não recebem a linha do parágrafo');
    });

    test('imagem inline alta do header impede sobreposição com o corpo', () {
      final inlineHeader = schema.node(
          'doc',
          null,
          Fragment.from([
            schema.node(
                'paragraph',
                {
                  'style': {
                    'spaceBeforeTwips': 0,
                    'spaceAfterTwips': 0,
                  }
                },
                Fragment.from([
                  schema.node('image', {
                    'src': 'data:image/png;base64,AA==',
                    'width': 600,
                    'height': 900,
                  })
                ]))
          ]));
      const setup = PageSetupTwips(
        widthTwips: 6000,
        heightTwips: 4000,
        marginTopTwips: 1000,
        marginRightTwips: 500,
        marginBottomTwips: 500,
        marginLeftTwips: 500,
        headerDistanceTwips: 200,
      );
      final graph = LayoutComposer(
        setup: setup,
        header: inlineHeader,
      ).compose(exactBody(1, 200));
      final headerBottom = setup.headerDistanceTwips +
          graph.pages.single.header
              .map((block) => block.yTwips + block.heightTwips)
              .reduce((a, b) => a > b ? a : b);
      final bodyBlock = graph.pages.single.fragments.single as BlockFragment;

      expect(headerBottom, greaterThan(setup.marginTopTwips));
      expect(bodyBlock.yTwips, headerBottom - setup.marginTopTwips,
          reason: 'o início do corpo deve ficar abaixo do fluxo inline real');
    });
  });

  group('campos de página', () {
    test('{PAGE} vira o número da página', () {
      final graph =
          LayoutComposer(footer: region('Página {PAGE}')).compose(body(300));
      expect(graph.pages.length, greaterThan(2));

      String textOf(int index) => graph.pages[index].footer
          .expand((f) => f.lines)
          .expand((l) => l.segments)
          .map((s) => s.text)
          .join();

      expect(textOf(0), contains('Página 1'));
      expect(textOf(1), contains('Página 2'));
      expect(textOf(graph.pages.length - 1),
          contains('Página ${graph.pages.length}'));
    });

    test('{NUMPAGES} vira o total', () {
      final graph = LayoutComposer(footer: region('{PAGE} de {NUMPAGES}'))
          .compose(body(300));
      final total = graph.pages.length;
      final last = graph.pages.last.footer
          .expand((f) => f.lines)
          .expand((l) => l.segments)
          .map((s) => s.text)
          .join();
      expect(last, contains('$total de $total'));
    });

    test('com campo, cada página tem a SUA composição', () {
      final graph =
          LayoutComposer(footer: region('Página {PAGE}')).compose(body(300));
      expect(identical(graph.pages[0].footer, graph.pages[1].footer), isFalse,
          reason: 'o texto muda por página, então a medição também muda');
    });
  });

  group('variantes Word first/default/even', () {
    const setup = PageSetupTwips(
      widthTwips: 6000,
      heightTwips: 1000,
      marginTopTwips: 100,
      marginRightTwips: 100,
      marginBottomTwips: 100,
      marginLeftTwips: 100,
    );

    String headerText(PageGraph graph, int pageIndex) =>
        graph.pages[pageIndex].header
            .expand((fragment) => fragment.lines)
            .expand((line) => line.segments)
            .map((segment) => segment.text)
            .join();

    test('titlePg escolhe first e setting global escolhe even', () {
      final graph = LayoutComposer(
        setup: setup,
        headerVariants: {
          'default': exactRegion('DEFAULT {PAGE}', 100),
          'first': exactRegion('FIRST {PAGE}', 100),
          'even': exactRegion('EVEN {PAGE}', 100),
        },
        titlePage: true,
        evenAndOddHeaders: true,
      ).compose(exactBody(3, 600));

      expect(graph.pages, hasLength(3));
      expect(headerText(graph, 0), 'FIRST 1');
      expect(headerText(graph, 1), 'EVEN 2');
      expect(headerText(graph, 2), 'DEFAULT 3');
    });

    test('referências first/even inativas não vazam para a projeção', () {
      final graph = LayoutComposer(
        setup: setup,
        headerVariants: {
          'default': exactRegion('DEFAULT', 100),
          'first': exactRegion('FIRST', 100),
          'even': exactRegion('EVEN', 100),
        },
      ).compose(exactBody(3, 600));

      for (var page = 0; page < 3; page++) {
        expect(headerText(graph, page), 'DEFAULT');
      }
    });
  });

  group('reserva vertical do rodapé', () {
    test('rodapé contido na margem não reduz a caixa do corpo', () {
      const setup = PageSetupTwips(
        widthTwips: 6000,
        heightTwips: 2000,
        marginTopTwips: 200,
        marginRightTwips: 200,
        marginBottomTwips: 300,
        marginLeftTwips: 200,
        footerDistanceTwips: 100,
      );
      final doc = exactBody(3, 500);
      final withoutFooter = LayoutComposer(setup: setup).compose(doc);
      final withinMargin = LayoutComposer(
        setup: setup,
        footer: exactRegion('rodapé baixo', 100),
      ).compose(doc);

      expect(withoutFooter.pages, hasLength(1));
      expect(withinMargin.pages.length, withoutFooter.pages.length,
          reason:
              '100 de distância + 100 de altura ainda cabem nos 300 da margem');
    });

    test('rodapé alto reduz a capacidade e empurra conteúdo para outra página',
        () {
      const setup = PageSetupTwips(
        widthTwips: 6000,
        heightTwips: 2000,
        marginTopTwips: 200,
        marginRightTwips: 200,
        marginBottomTwips: 200,
        marginLeftTwips: 200,
        footerDistanceTwips: 100,
      );
      final doc = exactBody(4, 400);

      expect(LayoutComposer(setup: setup).compose(doc).pages, hasLength(1));
      expect(
        LayoutComposer(
          setup: setup,
          footer: exactRegion('rodapé alto', 400),
        ).compose(doc).pages,
        hasLength(2),
        reason: '100 + 400 - 200 = 300 twips do corpo pertencem ao rodapé',
      );
    });

    test('mudança de seção recalcula a invasão do rodapé', () {
      const first = PageSetupTwips(
        widthTwips: 6000,
        heightTwips: 2000,
        marginTopTwips: 200,
        marginRightTwips: 200,
        marginBottomTwips: 200,
        marginLeftTwips: 200,
        footerDistanceTwips: 0,
      );
      const second = PageSetupTwips(
        widthTwips: 6000,
        heightTwips: 2000,
        marginTopTwips: 200,
        marginRightTwips: 200,
        marginBottomTwips: 200,
        marginLeftTwips: 200,
        footerDistanceTwips: 300,
      );
      final graph = LayoutComposer(
        setup: first,
        sections: const [first, second],
        footer: exactRegion('rodapé de seção', 400),
      ).compose(exactBody(4, 400, firstEndsSection: true));

      expect(graph.pages, hasLength(3),
          reason:
              'a primeira seção ocupa uma página; a segunda tem só 1100 twips e divide 3 linhas de 400');
      expect(graph.pages[1].setup.footerDistanceTwips, 300);
      expect(graph.pages[2].setup.footerDistanceTwips, 300);
    });

    test('campos PAGE/NUMPAGES não alteram a extensão reservada', () {
      const setup = PageSetupTwips(
        widthTwips: 8000,
        heightTwips: 2000,
        marginTopTwips: 200,
        marginRightTwips: 200,
        marginBottomTwips: 200,
        marginLeftTwips: 200,
        footerDistanceTwips: 100,
      );
      final doc = exactBody(4, 400);
      final literal = LayoutComposer(
        setup: setup,
        footer: exactRegion('Página 1 de 2', 400),
      ).compose(doc);
      final fields = LayoutComposer(
        setup: setup,
        footer: exactRegion('Página {PAGE} de {NUMPAGES}', 400),
      ).compose(doc);

      expect(fields.pages.length, literal.pages.length);
      expect(fields.pages, hasLength(2));
      for (final page in fields.pages) {
        expect(page.footer.single.heightTwips, 400);
      }
    });
  });

  group('nas duas saídas', () {
    test('o PDF desenha o timbre em todas as páginas', () {
      final graph =
          LayoutComposer(header: region('PREFEITURA')).compose(body(300));
      final pdf = PageGraphPdfRenderer().render(graph);
      final content = pdfText(pdf);

      // Standard-14 escreve o texto legível no stream.
      expect('PREFEITURA'.allMatches(content).length,
          greaterThanOrEqualTo(graph.pages.length),
          reason: 'uma ocorrência por página, no mínimo');
    });

    test('a numeração de página sai correta no PDF', () {
      final graph =
          LayoutComposer(footer: region('- {PAGE} -')).compose(body(300));
      final content = pdfText(PageGraphPdfRenderer().render(graph));
      expect(content, contains('- 1 -'));
      expect(content, contains('- 2 -'));
    });

    test('o PDF sem região continua igual', () {
      final doc = body(120);
      final withNone =
          PageGraphPdfRenderer().render(LayoutComposer().compose(doc));
      final again =
          PageGraphPdfRenderer().render(LayoutComposer().compose(doc));
      expect(again.length, withNone.length);
    });
  });
}
