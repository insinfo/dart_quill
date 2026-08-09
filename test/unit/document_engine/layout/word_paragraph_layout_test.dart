@TestOn('vm')
library;

import 'package:dart_quill/dart_quill_office.dart';
import 'package:test/test.dart';

import '../../../support/fake_dom.dart';
import '../../../support/pdf_reader.dart';

void main() {
  final schema = officeQuillSchema();

  PMNode docOf(PMNode block) =>
      schema.node('doc', null, Fragment.from([block]));

  PMNode styledParagraph(
    List<PMNode> content, {
    required Map<String, Object?> style,
  }) =>
      schema.node('paragraph', {'style': style}, Fragment.from(content));

  PMNode hardBreak() => schema.node('hardBreak', {'breakType': null}, null);

  group('espaçamento Word e quebra manual no PageGraph', () {
    test('before/after, exact e hardBreak têm geometria e posições reais', () {
      final paragraph = styledParagraph(
        [schema.text('alpha'), hardBreak(), schema.text('beta')],
        style: const {
          'spaceBeforeTwips': 100,
          'spaceAfterTwips': 200,
          'lineTwips': 400,
          'lineRule': 'exact',
        },
      );

      final graph = LayoutComposer().compose(docOf(paragraph));
      final fragment = graph.pages.single.fragments.single as BlockFragment;

      expect(fragment.spaceBeforeTwips, 100);
      expect(fragment.spaceAfterTwips, 200);
      expect(fragment.heightTwips, 1100,
          reason: '100 antes + 2 × 400 linhas + 200 depois');
      expect(fragment.lines, hasLength(2));
      expect(fragment.lines.map((line) => line.heightTwips), [400, 400]);
      expect(fragment.lines.first.charStart, 0);
      expect(fragment.lines.first.charEnd, 6,
          reason: 'alpha (5) + hardBreak (nodeSize 1)');
      expect(fragment.lines.last.charStart, 6);
      expect(fragment.lines.last.charEnd, 10);
      expect(fragment.lines.first.segments.last.hardBreak, isTrue);
      expect(fragment.lines.first.segments.last.text, '\n');
      expect(graph.diagnostics.warnings, isEmpty,
          reason: 'hardBreak é conteúdo suportado, não embed opaco');
    });

    test('page break inline divide o parágrafo exatamente na posição do nó',
        () {
      final paragraph = styledParagraph(
        [
          schema.text('antes'),
          schema.node('hardBreak', {'breakType': 'page'}, null),
          schema.text('depois'),
        ],
        style: const {
          'lineTwips': 300,
          'lineRule': 'exact',
          'widowControl': false,
        },
      );

      final graph = LayoutComposer().compose(docOf(paragraph));

      expect(graph.pages, hasLength(2));
      final first = graph.pages.first.fragments.single as BlockFragment;
      final second = graph.pages.last.fragments.single as BlockFragment;
      expect(
        first.lines.single.segments.map((segment) => segment.text).join(),
        'antes\n',
      );
      expect(
        second.lines.single.segments.map((segment) => segment.text).join(),
        'depois',
      );
      expect(first.lines.single.charStart, 0);
      expect(first.lines.single.charEnd, 6,
          reason: 'cinco caracteres + o nó w:br preservado');
      expect(second.lines.single.charStart, 6);
      expect(second.lines.single.charEnd, 12);
      expect(second.lines.single.manualPageBreakBefore, isTrue);
      expect(first.continuesOnNextPage, isTrue);
      expect(second.continuesFromPreviousPage, isTrue);
      expect(first.nodeId, second.nodeId,
          reason: 'a quebra fragmenta o mesmo parágrafo, não cria outro');
    });

    test('column break no fluxo monocoluna avança para a próxima página', () {
      final paragraph = styledParagraph(
        [
          schema.text('coluna atual'),
          schema.node('hardBreak', {'breakType': 'column'}, null),
          schema.text('próxima coluna'),
        ],
        style: const {'widowControl': false},
      );

      final graph = LayoutComposer().compose(docOf(paragraph));

      expect(graph.pages, hasLength(2));
      expect(
        (graph.pages.first.fragments.single as BlockFragment)
            .lines
            .single
            .segments
            .map((segment) => segment.text)
            .join(),
        'coluna atual\n',
      );
      final next = graph.pages.last.fragments.single as BlockFragment;
      expect(next.lines.single.segments.map((segment) => segment.text).join(),
          'próxima coluna');
      expect(next.lines.single.manualPageBreakBefore, isTrue);
    });

    test('lineRule auto escala por 240 e atLeast nunca reduz a linha', () {
      PMNode paragraphWith(Map<String, Object?> style) => styledParagraph(
            [schema.text('linha')],
            style: style,
          );

      final natural = (LayoutComposer()
              .compose(docOf(paragraphWith(const {})))
              .pages
              .single
              .fragments
              .single as BlockFragment)
          .lines
          .single
          .heightTwips;
      final auto = (LayoutComposer()
              .compose(docOf(paragraphWith(const {
                'lineTwips': 480,
                'lineRule': 'auto',
              })))
              .pages
              .single
              .fragments
              .single as BlockFragment)
          .lines
          .single
          .heightTwips;
      final atLeast = (LayoutComposer()
              .compose(docOf(paragraphWith({
                'lineTwips': natural + 73,
                'lineRule': 'atLeast',
              })))
              .pages
              .single
              .fragments
              .single as BlockFragment)
          .lines
          .single
          .heightTwips;

      expect(auto, natural * 2,
          reason: 'line=480 multiplica por 2 a caixa real da fonte');
      expect(atLeast, natural + 73);

      final arial10Natural = (LayoutComposer()
              .compose(docOf(paragraphWith(const {'sizePt': 10})))
              .pages
              .single
              .fragments
              .single as BlockFragment)
          .lines
          .single
          .heightTwips;
      expect(arial10Natural, 230,
          reason: 'sem w:spacing, usa hhea real da Arial, não piso de 1,2 em');

      final arial10Auto276 = (LayoutComposer()
              .compose(docOf(paragraphWith(const {
                'sizePt': 10,
                'lineTwips': 276,
                'lineRule': 'auto',
              })))
              .pages
              .single
              .fragments
              .single as BlockFragment)
          .lines
          .single
          .heightTwips;
      expect(arial10Auto276, (arial10Natural * 276 / 240).round(),
          reason: 'line=276 multiplica a caixa real da fonte por 1,15');
    });

    test('lista Word com hanging usa o tab só na primeira linha', () {
      final paragraph = styledParagraph(
        [
          schema.text(
              'pela empresa proponente durante toda a execução contratual')
        ],
        style: const {
          'marker': '4.73. ',
          'indentTwips': 0,
          'firstLineIndentTwips': -432,
          'lineTwips': 200,
          'lineRule': 'exact',
        },
      );
      final graph = LayoutComposer(
        setup: const PageSetupTwips(
          widthTwips: 2600,
          heightTwips: 4000,
          marginTopTwips: 0,
          marginRightTwips: 0,
          marginBottomTwips: 0,
          marginLeftTwips: 0,
        ),
      ).compose(docOf(paragraph));
      final fragment = graph.pages.single.fragments.single as BlockFragment;

      expect(fragment.marker, '4.73. ');
      expect(fragment.markerPositionTwips, 0,
          reason: 'o número permanece na margem esquerda');
      expect(fragment.indentTwips, 0,
          reason: 'o left=0 do Word governa as linhas de continuação');
      expect(fragment.lines.length, greaterThanOrEqualTo(2));
      expect(fragment.lines.first.indentTwips, 708,
          reason: 'somente o texto da primeira linha começa no tab default');
      expect(
        fragment.lines.skip(1).map((line) => line.indentTwips),
        everyElement(0),
        reason: 'continuações voltam ao left=0 e usam a largura integral',
      );
    });

    test('marcador multinível longo avança ao próximo tab sem tocar o texto',
        () {
      BlockFragment composeMarker(String marker) {
        final paragraph = styledParagraph(
          [schema.text('As fases de apresentação continuam normalmente')],
          style: {
            'family': 'Arial',
            'sizePt': 10.0,
            'marker': marker,
            'indentTwips': 0,
            'firstLineIndentTwips': -504,
            'lineTwips': 276,
            'lineRule': 'auto',
          },
        );
        return LayoutComposer(
          setup: const PageSetupTwips(
            widthTwips: 5000,
            heightTwips: 3000,
            marginTopTwips: 0,
            marginRightTwips: 0,
            marginBottomTwips: 0,
            marginLeftTwips: 0,
          ),
        ).compose(docOf(paragraph)).pages.single.fragments.single
            as BlockFragment;
      }

      expect(composeMarker('4.81.9. ').lines.first.indentTwips, 708);
      expect(
        composeMarker('4.81.10. ').lines.first.indentTwips,
        1416,
        reason: 'o rótulo de dois dígitos cruza 708 twips e o suffix tab '
            'leva o primeiro texto ao stop seguinte, como no Word',
      );
    });

    test('justificado contrai espaços em até 20% e projeta o mesmo ajuste', () {
      PMNode textParagraph(String text, String align) => styledParagraph(
            [schema.text(text)],
            style: {'align': align},
          );

      int naturalWidth(String text) {
        final graph = LayoutComposer(
          setup: const PageSetupTwips(
            widthTwips: 10000,
            heightTwips: 4000,
            marginTopTwips: 0,
            marginRightTwips: 0,
            marginBottomTwips: 0,
            marginLeftTwips: 0,
          ),
        ).compose(docOf(textParagraph(text, 'left')));
        return (graph.pages.single.fragments.single as BlockFragment)
            .lines
            .single
            .widthTwips;
      }

      const text = 'alpha beta';
      final natural = naturalWidth(text);
      final space = natural - naturalWidth('alpha') - naturalWidth('beta');
      expect(space, greaterThan(4));
      final withinLimit = natural - space ~/ 5;
      final beyondLimit = withinLimit - 1;

      BlockFragment composeAt(int width, String align) {
        final graph = LayoutComposer(
          setup: PageSetupTwips(
            widthTwips: width,
            heightTwips: 4000,
            marginTopTwips: 0,
            marginRightTwips: 0,
            marginBottomTwips: 0,
            marginLeftTwips: 0,
          ),
        ).compose(docOf(textParagraph(text, align)));
        return graph.pages.first.fragments.first as BlockFragment;
      }

      expect(composeAt(withinLimit, 'left').lines, hasLength(2));
      final justified = composeAt(withinLimit, 'justify');
      expect(justified.lines, hasLength(1));
      expect(justified.lines.single.wordSpacingTwips,
          closeTo(withinLimit - natural, 0.001));
      expect(justified.lines.single.wordSpacingTwips,
          greaterThanOrEqualTo(-space / 5));
      expect(composeAt(beyondLimit, 'justify').lines, hasLength(2),
          reason: 'uma contração maior que 20% volta a quebrar a linha');

      final document = FakeDomDocument();
      final host = document.createElement('div');
      document.body.append(host);
      final graph = LayoutComposer(
        setup: PageSetupTwips(
          widthTwips: withinLimit,
          heightTwips: 4000,
          marginTopTwips: 0,
          marginRightTwips: 0,
          marginBottomTwips: 0,
          marginLeftTwips: 0,
        ),
      ).compose(docOf(textParagraph(text, 'justify')));
      PageGraphDomRenderer(document: document).render(graph, host);
      expect(host.querySelector('.dq-office-line')!.getAttribute('style'),
          contains('word-spacing:-'));

      final pdf = PdfReader(PageGraphPdfRenderer().render(graph));
      expect(pdf.decodedStreams.join('\n'), contains(' Tw'),
          reason: 'PDF recebe a mesma contração do PageGraph em um operador');
    });

    test('pontuação final pendura sem hifenizar o título do Word', () {
      const text =
          'FASE 2: DEMONSTRAÇÃO ITEM A ITEM E POR CADA MÓDULO DOS REQUISITOS FUNCIONAIS:';
      final paragraph = styledParagraph(
        [schema.text(text)],
        style: const {
          'family': 'Arial',
          'sizePt': 10.0,
          'align': 'justify',
          'marker': '4.81. ',
          'indentTwips': 0,
          'firstLineIndentTwips': -432,
          'lineTwips': 276,
          'lineRule': 'auto',
          'autoHyphenation': true,
        },
      );
      final fragment = LayoutComposer(
        setup: const PageSetupTwips(
          widthTwips: 9638,
          heightTwips: 4000,
          marginTopTwips: 0,
          marginRightTwips: 0,
          marginBottomTwips: 0,
          marginLeftTwips: 0,
        ),
      ).compose(docOf(paragraph)).pages.single.fragments.single
          as BlockFragment;

      expect(fragment.lines, hasLength(1));
      expect(
          fragment.lines.single.segments.map((segment) => segment.text).join(),
          text);
      expect(fragment.lines.single.widthTwips, greaterThan(8930),
          reason:
              'somente o glifo final pode passar do limite da primeira linha');
      expect(
        fragment.lines.single.segments
            .where((segment) => segment.isDiscretionaryHyphen),
        isEmpty,
        reason: 'o Word prefere pendurar o dois-pontos a quebrar FUNCIONAIS',
      );
    });

    test('vírgula intermediária também pendura antes da próxima linha', () {
      const text = 'A Licitante vencedora deverá trazer todos os equipamentos '
          'necessários para realizar a demonstração, tais como projetos, '
          'computadores e impressoras';
      final paragraph = styledParagraph(
        [schema.text(text)],
        style: const {
          'family': 'Arial',
          'sizePt': 10.0,
          'align': 'justify',
          'marker': '4.81.4.',
          'markerSuffix': 'tab',
          'indentTwips': 0,
          'firstLineIndentTwips': -432,
          'lineTwips': 276,
          'lineRule': 'auto',
          'autoHyphenation': true,
          'hyphenationZoneTwips': 425,
        },
      );
      final fragment = LayoutComposer(
        setup: const PageSetupTwips(
          widthTwips: 9638,
          heightTwips: 4000,
          marginTopTwips: 0,
          marginRightTwips: 0,
          marginBottomTwips: 0,
          marginLeftTwips: 0,
        ),
      ).compose(docOf(paragraph)).pages.single.fragments.single
          as BlockFragment;
      final firstLine = fragment.lines.first.segments
          .map((segment) => segment.text)
          .join()
          .trimRight();

      expect(firstLine, endsWith('demonstração,'));
      expect(
        fragment.lines.first.segments
            .where((segment) => segment.isDiscretionaryHyphen),
        isEmpty,
      );
    });

    test('hífen automático é visual, seek-safe e não altera offsets', () {
      const text =
          'Somente será precedida à Fase 2 aquele que atender a 100% (cem por cento) dos requisitos obrigatórios da Fase 1. Na hipótese do não atendimento ao percentual mínimo de 90% (noventa por cento) dos Requisitos Funcionais obrigatórios detalhados no Termo de Referência e conforme especificação detalhada, pela empresa proponente, o Pregoeiro convocará a empresa licitante subsequente, na ordem de classificação, para que se habilitada faça a respectiva demonstração primeiramente da Fase 1, caso venha ser aprovada nesta fase anterior, proceda a demonstração da Fase 2, sendo avaliada nos mesmos moldes da empresa licitante anterior, e assim sucessivamente, até a apuração de uma empresa que atenda 90% (noventa por cento) por cada módulo dos Requisitos Funcionais obrigatórios conforme Termo de Referência;';
      final renderedBreak = schema.node('opaqueInline', {
        'insert': {
          'qname': 'w:lastRenderedPageBreak',
          'officeXml': '<w:lastRenderedPageBreak/>',
          'runContent': true,
          'renderedPageBreakHint': true,
        }
      });
      final paragraph = styledParagraph(
        [
          schema.text(text.substring(0, 301)),
          renderedBreak,
          schema.text(text.substring(301)),
        ],
        style: const {
          'family': 'Arial',
          'sizePt': 10.0,
          'align': 'justify',
          'marker': '4.81.1. ',
          'indentTwips': 0,
          'firstLineIndentTwips': -504,
          'lineTwips': 276,
          'lineRule': 'auto',
          'autoHyphenation': true,
        },
      );
      final graph = LayoutComposer(
        setup: const PageSetupTwips(
          widthTwips: 9638,
          heightTwips: 12000,
          marginTopTwips: 0,
          marginRightTwips: 0,
          marginBottomTwips: 0,
          marginLeftTwips: 0,
        ),
      ).compose(docOf(paragraph));
      final fragment = graph.pages.first.fragments.single as BlockFragment;
      final continuation = graph.pages.last.fragments.single as BlockFragment;
      String lineText(BlockFragment block, int index) =>
          block.lines[index].segments.map((segment) => segment.text).join();

      expect(fragment.lines[0].charEnd, 95);
      expect(lineText(fragment, 0), endsWith('obriga-'));
      expect(fragment.lines[1].charStart, 95);
      expect(lineText(fragment, 1), startsWith('tórios '));
      expect(fragment.lines[2].charEnd, 301);
      expect(continuation.lines.first.charStart, 301);
      expect(lineText(continuation, 0), startsWith('pela empresa'));

      final discretionary = fragment.lines.first.segments
          .singleWhere((segment) => segment.isDiscretionaryHyphen);
      expect(discretionary.text, '-');

      final document = FakeDomDocument();
      final host = document.createElement('div');
      document.body.append(host);
      PageGraphDomRenderer(document: document, editable: true)
          .render(graph, host);
      final hyphen = host.querySelector('.dq-office-discretionary-hyphen')!;
      expect(hyphen.getAttribute('data-model-length'), '0');
      expect(hyphen.getAttribute('contenteditable'), 'false');
      expect(hyphen.getAttribute('aria-hidden'), 'true');
      const positionMap = OfficeDomPositionMap();
      final hyphenText = hyphen.childNodes.single;
      expect(positionMap.modelPositionAt(hyphenText, 0), fragment.docPos + 95);
      expect(
        positionMap.modelPositionAt(hyphenText, 1),
        positionMap.modelPositionAt(hyphenText, 0),
        reason: 'o glifo visual não soma um caractere ao offset PM',
      );
    });

    test('zona de hifenização aceita folga curta antes de cortar a palavra',
        () {
      BlockFragment composeWithZone(int zone) {
        final paragraph = styledParagraph(
          [schema.text('AAAA demonstração')],
          style: {
            'family': 'Arial',
            'sizePt': 10.0,
            'autoHyphenation': true,
            'hyphenationZoneTwips': zone,
          },
        );
        return LayoutComposer(
          setup: const PageSetupTwips(
            widthTwips: 1600,
            heightTwips: 3000,
            marginTopTwips: 0,
            marginRightTwips: 0,
            marginBottomTwips: 0,
            marginLeftTwips: 0,
          ),
        ).compose(docOf(paragraph)).pages.single.fragments.single
            as BlockFragment;
      }

      final protected = composeWithZone(5000);
      expect(
        protected.lines.first.segments
            .where((segment) => segment.isDiscretionaryHyphen),
        isEmpty,
      );
      final aggressive = composeWithZone(0);
      expect(
        aggressive.lines.first.segments
            .where((segment) => segment.isDiscretionaryHyphen),
        isNotEmpty,
      );
    });

    test('espaçamento entre parágrafos usa max(after, before), não soma', () {
      final first = styledParagraph([
        schema.text('primeiro')
      ], style: const {
        'spaceAfterTwips': 80,
        'lineTwips': 200,
        'lineRule': 'exact',
      });
      final second = styledParagraph([
        schema.text('segundo')
      ], style: const {
        'spaceBeforeTwips': 120,
        'lineTwips': 200,
        'lineRule': 'exact',
      });
      final doc = schema.node('doc', null, Fragment.from([first, second]));
      final fragments = LayoutComposer()
          .compose(doc)
          .pages
          .single
          .fragments
          .cast<BlockFragment>();

      expect(fragments.first.spaceAfterTwips, 80);
      expect(fragments.last.spaceBeforeTwips, 40,
          reason: 'o after anterior já forneceu 80 dos 120 twips');
      expect(fragments.last.yTwips, 280);
      expect(fragments.last.yTwips + fragments.last.spaceBeforeTwips, 320,
          reason: 'distância entre baselines geométricas é 200 + max(80,120)');
    });

    test('contextualSpacing suprime gap entre parágrafos do mesmo estilo', () {
      PMNode sameStyle(String text) => styledParagraph([
            schema.text(text)
          ], style: const {
            'wordStyleId': 'ListParagraph',
            'contextualSpacing': true,
            'spaceBeforeTwips': 120,
            'spaceAfterTwips': 120,
            'lineTwips': 200,
            'lineRule': 'exact',
          });
      final doc = schema.node(
          'doc', null, Fragment.from([sameStyle('um'), sameStyle('dois')]));
      final fragments = LayoutComposer()
          .compose(doc)
          .pages
          .single
          .fragments
          .cast<BlockFragment>();

      expect(fragments.first.spaceAfterTwips, 0);
      expect(fragments.last.spaceBeforeTwips, 0);
      expect(fragments.last.yTwips, 320,
          reason:
              'o primeiro before permanece no início; entre eles não há gap');
    });

    test('docGrid arredonda linhas do corpo, mas não linhas em tabela', () {
      const setup = PageSetupTwips(
        documentGridLinePitchTwips: 326,
        documentGridType: 'lines',
      );
      final body = styledParagraph([
        schema.text('corpo')
      ], style: const {
        'lineTwips': 200,
        'lineRule': 'exact',
      });
      final bodyLine = (LayoutComposer(setup: setup)
              .compose(docOf(body))
              .pages
              .single
              .fragments
              .single as BlockFragment)
          .lines
          .single;
      expect(bodyLine.heightTwips, 326);

      final inner = styledParagraph([
        schema.text('célula')
      ], style: const {
        'lineTwips': 200,
        'lineRule': 'exact',
      });
      final cell = schema.node('tableCell', null, Fragment.from([inner]));
      final row = schema.node('tableRow', null, Fragment.from([cell]));
      final table = schema.node(
          'table',
          {
            'colWidths': [2000]
          },
          Fragment.from([row]));
      final tableFragment = LayoutComposer(setup: setup)
          .compose(docOf(table))
          .pages
          .single
          .fragments
          .single as TableFragment;
      expect(
          tableFragment
              .rows.single.cells.single.blocks.single.lines.single.heightTwips,
          200);

      const defaultGrid = PageSetupTwips(documentGridLinePitchTwips: 326);
      final withoutGrid = (LayoutComposer(setup: defaultGrid)
              .compose(docOf(body))
              .pages
              .single
              .fragments
              .single as BlockFragment)
          .lines
          .single;
      expect(withoutGrid.heightTwips, 200,
          reason: 'docGrid sem type é default/no-grid em OOXML');
    });

    test('marcadores OOXML de bloco preservados não fabricam linhas', () {
      PMNode exact(String text) => styledParagraph(
            [schema.text(text)],
            style: const {'lineTwips': 200, 'lineRule': 'exact'},
          );
      PMNode opaque(String qname) => schema.node('opaque', {
            'insert': {'qname': qname, 'officeXml': '<$qname w:id="1"/>'}
          });

      final a = exact('A');
      final bookmarkStart = opaque('w:bookmarkStart');
      final bookmarkEnd = opaque('w:bookmarkEnd');
      final b = exact('B');
      final graph = LayoutComposer(
        setup: const PageSetupTwips(
          widthTwips: 3000,
          heightTwips: 600,
          marginTopTwips: 100,
          marginRightTwips: 100,
          marginBottomTwips: 100,
          marginLeftTwips: 100,
        ),
      ).compose(schema.node(
          'doc', null, Fragment.from([a, bookmarkStart, bookmarkEnd, b])));

      expect(graph.pages, hasLength(1));
      final blocks = graph.pages.single.fragments.cast<BlockFragment>();
      expect(blocks.map((block) => block.kind),
          ['paragraph', 'opaque', 'opaque', 'paragraph']);
      expect(blocks.map((block) => block.heightTwips), [200, 0, 0, 200]);
      expect(blocks.map((block) => block.yTwips), [0, 200, 200, 200]);

      final firstMarkerPos = 1 + a.nodeSize;
      final secondMarkerPos = firstMarkerPos + bookmarkStart.nodeSize;
      expect(
          graph.positionMap.entries.any((entry) =>
              entry.docPosStart == firstMarkerPos &&
              entry.docPosEnd == firstMarkerPos + bookmarkStart.nodeSize &&
              entry.pageIndex == 0),
          isTrue);
      expect(
          graph.positionMap.entries.any((entry) =>
              entry.docPosStart == secondMarkerPos &&
              entry.docPosEnd == secondMarkerPos + bookmarkEnd.nodeSize &&
              entry.pageIndex == 0),
          isTrue);

      final visualOpaque = LayoutComposer()
          .compose(docOf(opaque('w:altChunk')))
          .pages
          .single
          .fragments
          .single as BlockFragment;
      expect(visualOpaque.heightTwips, greaterThan(0),
          reason: 'nós opacos potencialmente visuais não entram na whitelist');
    });

    test('parágrafo final vazio extra em célula não aumenta a linha Word', () {
      PMNode exact(String text) => styledParagraph(
            [schema.text(text)],
            style: const {'lineTwips': 200, 'lineRule': 'exact'},
          );
      PMNode empty({bool imported = true}) => schema.node(
          'paragraph',
          {
            if (imported)
              'word': {
                'markRunProperties': {
                  'languageEastAsia': 'zh-CN',
                  'languageBidi': 'hi-IN',
                }
              }
          },
          Fragment.empty);
      PMNode tableOf(List<PMNode> blocks) {
        final cell = schema.node('tableCell', null, Fragment.from(blocks));
        final row = schema.node('tableRow', null, Fragment.from([cell]));
        return schema.node(
            'table',
            {
              'colWidths': [2000]
            },
            Fragment.from([row]));
      }

      TableFragment compose(List<PMNode> blocks) => LayoutComposer()
          .compose(docOf(tableOf(blocks)))
          .pages
          .single
          .fragments
          .single as TableFragment;

      final reference = compose([exact('LOTE 3 – SAAE')]);
      final withTerminator = compose([exact('LOTE 3 – SAAE'), empty()]);
      final cell = withTerminator.rows.single.cells.single;
      expect(cell.blocks, hasLength(2));
      expect(cell.blocks.first.heightTwips,
          reference.rows.single.cells.single.blocks.single.heightTwips);
      expect(cell.blocks.last.heightTwips, 0);
      expect(cell.blocks.last.yTwips,
          cell.blocks.first.yTwips + cell.blocks.first.heightTwips);
      expect(withTerminator.rows.single.heightTwips,
          reference.rows.single.heightTwips,
          reason: 'o terminador obrigatório compartilha a linha visual final');

      final onlyEmpty = compose([empty()]);
      expect(onlyEmpty.rows.single.cells.single.blocks.single.heightTwips,
          greaterThan(0),
          reason: 'célula realmente vazia mantém uma linha editável mínima');

      final middleEmpty = compose([exact('A'), empty(), exact('B')]);
      expect(middleEmpty.rows.single.cells.single.blocks[1].heightTwips,
          greaterThan(0),
          reason: 'somente o último parágrafo vazio extra é colapsado');

      final editorTrailing = compose([exact('A'), empty(imported: false)]);
      expect(editorTrailing.rows.single.cells.single.blocks.last.heightTwips,
          greaterThan(0),
          reason: 'Enter no editor cria uma nova linha/caret visível');
    });

    test('hint inline quebra uma vez e é descartado na primeira edição', () {
      final marker = schema.node('opaqueInline', {
        'insert': {
          'qname': 'w:lastRenderedPageBreak',
          'officeXml': '<w:lastRenderedPageBreak/>',
          'runContent': true,
          'renderedPageBreakHint': true,
        }
      });
      final paragraph = schema.node(
          'paragraph',
          {
            'id': 'hinted',
            'style': {
              'lineTwips': 200,
              'lineRule': 'exact',
            }
          },
          Fragment.from([schema.text('antes'), marker, schema.text('depois')]));
      final doc = docOf(paragraph);
      final composer = LayoutComposer(
        setup: const PageSetupTwips(
          widthTwips: 5000,
          heightTwips: 1000,
          marginTopTwips: 0,
          marginRightTwips: 0,
          marginBottomTwips: 0,
          marginLeftTwips: 0,
        ),
      );

      final imported = composer.compose(doc);
      expect(imported.pages, hasLength(2));
      expect(imported.honoredRenderedPageBreakHints, isTrue);
      expect(
          (imported.pages.last.fragments.single as BlockFragment)
              .lines
              .single
              .renderedPageBreakBefore,
          isTrue);

      final natural = composer.compose(doc, honorRenderedPageBreaks: false);
      expect(natural.pages, hasLength(1));
      expect(natural.honoredRenderedPageBreakHints, isFalse);
      final naturalLine =
          (natural.pages.single.fragments.single as BlockFragment).lines.single;
      expect(naturalLine.segments.map((segment) => segment.text).join(),
          'antesdepois');
      expect(naturalLine.charStart, 0);
      expect(naturalLine.charEnd, 12,
          reason: '5 + marker opaco de modelLength 1 + 6 caracteres');

      final firstEdit = composer.composeIncremental(
        doc,
        previous: imported,
        changedFromDocPos: 1,
      );
      expect(firstEdit.pages, hasLength(1),
          reason: 'marker de layout não vira hard break depois de editar');
      expect(firstEdit.honoredRenderedPageBreakHints, isFalse);

      final secondEdit = composer.composeIncremental(
        doc,
        previous: firstEdit,
        changedFromDocPos: 1,
      );
      expect(secondEdit.pages, hasLength(1));
      expect(secondEdit.honoredRenderedPageBreakHints, isFalse,
          reason: 'edições seguintes não recompõem eternamente por markers');
    });

    test('parágrafo importado só com page break não fabrica página branca', () {
      final bookmark = schema.node('opaqueInline', {
        'insert': {
          'qname': 'w:bookmarkStart',
          'officeXml': '<w:bookmarkStart w:id="1" w:name="x"/>',
        }
      });
      final renderedMarker = schema.node('opaqueInline', {
        'insert': {
          'qname': 'w:lastRenderedPageBreak',
          'officeXml': '<w:lastRenderedPageBreak/>',
          'runContent': true,
          'renderedPageBreakHint': true,
        }
      });
      final importedPageBreak = schema.node(
          'paragraph',
          {
            'id': 'break',
            'style': {'pageBreakBefore': true},
            'word': {'pageBreakBefore': null},
          },
          Fragment.from([bookmark]));
      final following = schema.node(
          'paragraph',
          {
            'id': 'following',
            'style': {'renderedPageBreakBefore': true},
          },
          Fragment.from([renderedMarker, schema.text('ANEXO')]));
      final graph = LayoutComposer().compose(schema.node(
          'doc',
          null,
          Fragment.from([
            styledParagraph([schema.text('corpo')], style: const {}),
            importedPageBreak,
            following,
          ])));

      expect(graph.pages, hasLength(2));
      final page = graph.pages.last;
      expect(page.fragments, hasLength(2));
      expect((page.fragments.first as BlockFragment).heightTwips, 0);
      final followingFragment = page.fragments.last as BlockFragment;
      expect(
          followingFragment.lines.single.segments
              .map((segment) => segment.text)
              .join(),
          'ANEXO');

      final editorBreak = schema.node(
          'paragraph',
          {
            'style': {'pageBreakBefore': true}
          },
          Fragment.empty);
      final editorGraph = LayoutComposer().compose(docOf(editorBreak));
      expect(
          (editorGraph.pages.single.fragments.single as BlockFragment)
              .heightTwips,
          greaterThan(0));
    });

    test('spaceBefore some no topo automático, mas não no manual', () {
      PMNode exact(String text,
              {int before = 0, int after = 0, bool manual = false}) =>
          styledParagraph([
            schema.text(text)
          ], style: {
            'lineTwips': text == 'primeiro' ? 300 : 200,
            'lineRule': 'exact',
            if (before > 0) 'spaceBeforeTwips': before,
            if (after > 0) 'spaceAfterTwips': after,
            if (manual) 'pageBreakBefore': true,
          });
      const setup = PageSetupTwips(
        widthTwips: 5000,
        heightTwips: 400,
        marginTopTwips: 0,
        marginRightTwips: 0,
        marginBottomTwips: 0,
        marginLeftTwips: 0,
      );

      final automatic = LayoutComposer(setup: setup).compose(schema.node(
          'doc',
          null,
          Fragment.from([
            exact('primeiro', after: 80),
            exact('segundo', before: 120),
          ])));
      expect(automatic.pages, hasLength(2));
      expect(
          (automatic.pages.last.fragments.single as BlockFragment)
              .spaceBeforeTwips,
          0);

      final manual = LayoutComposer(setup: setup).compose(schema.node(
          'doc',
          null,
          Fragment.from([
            exact('primeiro', after: 80),
            exact('segundo', before: 120, manual: true),
          ])));
      expect(manual.pages, hasLength(2));
      expect(
          (manual.pages.last.fragments.single as BlockFragment)
              .spaceBeforeTwips,
          120);
    });

    test('spacing distingue break inline de lastRenderedPageBreak', () {
      final first = styledParagraph([
        schema.text('primeira')
      ], style: const {
        'lineTwips': 200,
        'lineRule': 'exact',
        'spaceAfterTwips': 80,
      });
      final breakOnly = schema.node(
        'paragraph',
        {'word': const <String, dynamic>{}},
        Fragment.from([
          schema.node('hardBreak', {'breakType': 'page'}, null),
        ]),
      );
      final afterInline = styledParagraph(
        [schema.text('depois do break inline')],
        style: const {
          'spaceBeforeTwips': 120,
          'lineTwips': 200,
          'lineRule': 'exact',
        },
      );
      final inlineGraph = LayoutComposer().compose(schema.node(
        'doc',
        null,
        Fragment.from([first, breakOnly, afterInline]),
      ));
      expect(inlineGraph.pages, hasLength(2));
      final inlineVisible = inlineGraph.pages.last.fragments
          .whereType<BlockFragment>()
          .where((fragment) => fragment.heightTwips > 0)
          .single;
      expect(inlineVisible.spaceBeforeTwips, 0,
          reason: 'o break inline consome spacing no topo como no Word');

      final rendered = styledParagraph(
        [schema.text('depois do hint renderizado')],
        style: const {
          'renderedPageBreakBefore': true,
          'spaceBeforeTwips': 120,
          'lineTwips': 200,
          'lineRule': 'exact',
        },
      );
      final renderedGraph = LayoutComposer().compose(schema.node(
        'doc',
        null,
        Fragment.from([first, rendered]),
      ));
      expect(renderedGraph.pages, hasLength(2));
      expect(
        (renderedGraph.pages.last.fragments.single as BlockFragment)
            .spaceBeforeTwips,
        120,
        reason: 'o hint confirma a geometria salva e preserva o spacing',
      );
    });

    test('page breaks inline consecutivos preservam a página em branco', () {
      PMNode carrier(String id) => schema.node(
            'paragraph',
            {
              'id': id,
              'word': const <String, dynamic>{},
            },
            Fragment.from([
              schema.node('hardBreak', {'breakType': 'page'}, null),
            ]),
          );
      final graph = LayoutComposer().compose(schema.node(
        'doc',
        null,
        Fragment.from([
          styledParagraph([schema.text('antes')], style: const {}),
          carrier('break-1'),
          carrier('break-2'),
          styledParagraph([schema.text('depois')], style: const {}),
        ]),
      ));

      expect(graph.pages, hasLength(3));
      expect(graph.pages[1].fragments, isNotEmpty,
          reason: 'a página em branco mantém o carrier editável');
      expect(graph.pages[1].fragments.every((f) => f.heightTwips == 0), isTrue);
      expect(
        graph.pages.last.fragments
            .whereType<BlockFragment>()
            .where((fragment) => fragment.heightTwips > 0)
            .single
            .lines
            .single
            .segments
            .map((segment) => segment.text)
            .join(),
        'depois',
      );
    });

    test('apagar o último caractere ativa o rPr da marca do parágrafo', () {
      final attrs = {
        'style': {'sizePt': 12.0, 'family': 'Calibri'},
        'word': {
          'markRunProperties': {
            'sizeHalfPoints': 10,
            'fontAscii': 'Arial',
          },
        },
      };
      final editedEmpty = schema.node('paragraph', attrs, Fragment.empty);
      final expectedEmpty = schema.node(
        'paragraph',
        {
          ...attrs,
          'style': {'sizePt': 5.0, 'family': 'Arial'},
        },
        Fragment.empty,
      );
      final editedFragment = LayoutComposer()
          .compose(docOf(editedEmpty))
          .pages
          .single
          .fragments
          .single as BlockFragment;
      final expectedFragment = LayoutComposer()
          .compose(docOf(expectedEmpty))
          .pages
          .single
          .fragments
          .single as BlockFragment;

      expect(editedFragment.heightTwips, expectedFragment.heightTwips,
          reason: 'o layout antes do save deve coincidir com o reimportado');
      expect(editedFragment.heightTwips, lessThan(200),
          reason: 'a linha vazia usa 5 pt, não o estilo anterior de 12 pt');
    });

    test('before só entra no primeiro fragmento e after só no último', () {
      final content = <PMNode>[];
      for (var i = 0; i < 7; i++) {
        content.add(schema.text('L$i'));
        if (i != 6) content.add(hardBreak());
      }
      final paragraph = styledParagraph(content, style: const {
        'spaceBeforeTwips': 100,
        'spaceAfterTwips': 50,
        'lineTwips': 200,
        'lineRule': 'exact',
        'widowControl': false,
      });
      final graph = LayoutComposer(
        setup: const PageSetupTwips(
          widthTwips: 4000,
          heightTwips: 900,
          marginTopTwips: 100,
          marginRightTwips: 100,
          marginBottomTwips: 100,
          marginLeftTwips: 100,
        ),
      ).compose(docOf(paragraph));
      final fragments = graph.pages
          .expand((page) => page.fragments)
          .whereType<BlockFragment>()
          .toList();

      expect(fragments, hasLength(3));
      expect(
          fragments.map((fragment) => fragment.spaceBeforeTwips), [100, 0, 0]);
      expect(fragments.map((fragment) => fragment.spaceAfterTwips), [0, 0, 50]);
      expect(
          fragments.map((fragment) => fragment.heightTwips), [700, 600, 250]);
      expect(fragments.first.continuesOnNextPage, isTrue);
      expect(fragments[1].continuesFromPreviousPage, isTrue);
      expect(fragments.last.continuesOnNextPage, isFalse);
    });

    test('keepLines move o parágrafo inteiro quando ele cabe na próxima', () {
      final before = styledParagraph([
        schema.text('antes')
      ], style: const {
        'lineTwips': 400,
        'lineRule': 'exact',
      });
      final kept = styledParagraph(
        [schema.text('A'), hardBreak(), schema.text('B')],
        style: const {
          'lineTwips': 200,
          'lineRule': 'exact',
          'keepLines': true,
        },
      );
      final doc = schema.node('doc', null, Fragment.from([before, kept]));
      final graph = LayoutComposer(
        setup: const PageSetupTwips(
          widthTwips: 4000,
          heightTwips: 900,
          marginTopTwips: 100,
          marginRightTwips: 100,
          marginBottomTwips: 100,
          marginLeftTwips: 100,
        ),
      ).compose(doc);

      expect(graph.pages, hasLength(2));
      expect(graph.pages.first.fragments, hasLength(1));
      final second = graph.pages.last.fragments.single as BlockFragment;
      expect(second.lines, hasLength(2));
      expect(second.continuesFromPreviousPage, isFalse);
    });

    test('keepNext leva título e primeira linha seguinte para a mesma página',
        () {
      final before = styledParagraph([
        schema.text('antes')
      ], style: const {
        'lineTwips': 400,
        'lineRule': 'exact',
      });
      final title = styledParagraph([
        schema.text('Título')
      ], style: const {
        'lineTwips': 200,
        'lineRule': 'exact',
        'keepNext': true,
      });
      final next = styledParagraph([
        schema.text('conteúdo')
      ], style: const {
        'lineTwips': 200,
        'lineRule': 'exact',
      });
      final doc =
          schema.node('doc', null, Fragment.from([before, title, next]));
      final graph = LayoutComposer(
        setup: const PageSetupTwips(
          widthTwips: 4000,
          heightTwips: 900,
          marginTopTwips: 100,
          marginRightTwips: 100,
          marginBottomTwips: 100,
          marginLeftTwips: 100,
        ),
      ).compose(doc);

      expect(graph.pages, hasLength(2));
      expect(graph.pages.first.fragments, hasLength(1));
      expect(graph.pages.last.fragments, hasLength(2));
      expect(
          (graph.pages.last.fragments.first as BlockFragment)
              .lines
              .first
              .segments
              .first
              .text,
          'Título');
    });

    test('keepNext respeita fragmento mínimo imposto por widowControl', () {
      final before = styledParagraph([
        schema.text('antes')
      ], style: const {
        'lineTwips': 300,
        'lineRule': 'exact',
      });
      final title = styledParagraph([
        schema.text('Título')
      ], style: const {
        'lineTwips': 100,
        'lineRule': 'exact',
        'keepNext': true,
      });
      final next = styledParagraph(
        [
          schema.text('A'),
          hardBreak(),
          schema.text('B'),
          hardBreak(),
          schema.text('C'),
        ],
        style: const {
          'lineTwips': 100,
          'lineRule': 'exact',
          'spaceAfterTwips': 100,
          'widowControl': true,
        },
      );
      final graph = LayoutComposer(
        setup: const PageSetupTwips(
          widthTwips: 4000,
          heightTwips: 900,
          marginTopTwips: 100,
          marginRightTwips: 100,
          marginBottomTwips: 100,
          marginLeftTwips: 100,
        ),
      ).compose(schema.node('doc', null, Fragment.from([before, title, next])));

      expect(graph.pages, hasLength(2));
      expect(graph.pages.first.fragments, hasLength(1));
      expect(graph.pages.last.fragments, hasLength(2));
      expect((graph.pages.last.fragments.last as BlockFragment).lines,
          hasLength(3));
    });
  });

  group('paridade DOM/PDF de parágrafo Word', () {
    test('DOM desloca linhas pelo before e projeta hardBreak como br', () {
      final paragraph = styledParagraph(
        [schema.text('alpha'), hardBreak(), schema.text('beta')],
        style: const {
          'spaceBeforeTwips': 100,
          'spaceAfterTwips': 200,
          'lineTwips': 400,
          'lineRule': 'exact',
        },
      );
      final graph = LayoutComposer().compose(docOf(paragraph));
      final document = FakeDomDocument();
      final host = document.createElement('div');
      document.body.append(host);

      PageGraphDomRenderer(document: document, editable: true)
          .render(graph, host);

      final lines = host.querySelectorAll('.dq-office-line');
      expect(lines, hasLength(2));
      expect(lines.first.getAttribute('style'),
          allOf(contains('top:6.67px'), contains('height:26.67px')));
      expect(lines.last.getAttribute('style'), contains('top:33.33px'));
      final br = host.querySelector('.dq-office-hard-break');
      expect(br, isNotNull);
      expect(br!.tagName.toLowerCase(), 'br');
      expect(br.getAttribute('data-model-length'), '1');
      expect(host.textContent, 'alphabeta');
    });

    test('PDF mantém as duas linhas sem desenhar placeholder da quebra', () {
      final paragraph = styledParagraph(
        [schema.text('alpha'), hardBreak(), schema.text('beta')],
        style: const {
          'spaceBeforeTwips': 100,
          'lineTwips': 400,
          'lineRule': 'exact',
        },
      );
      final graph = LayoutComposer().compose(docOf(paragraph));
      final reader = PdfReader(PageGraphPdfRenderer().render(graph));
      final streams = reader.decodedStreams.join('\n');

      expect(reader.pageCount, graph.pages.length);
      expect(streams, contains('alpha'));
      expect(streams, contains('beta'));
      expect(streams, isNot(contains('\\n')),
          reason: 'hardBreak só muda a geometria; não vira glifo no PDF');
    });
  });
}
