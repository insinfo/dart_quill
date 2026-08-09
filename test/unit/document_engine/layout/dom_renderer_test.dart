/// Fase 2 / gate da Fase 5 — o lado EDITOR do invariante central:
/// o DOMRenderer consome o MESMO PageGraph que o PdfRenderer.
///
/// O teste-chave desta suíte é a paridade TRIPLA: para cada página, o texto
/// que o grafo compôs aparece no DOM daquela página E no stream PDF daquela
/// página. É a prova operacional de "a linha da página 18 do editor é a
/// linha da página 18 do PDF".
@TestOn('vm')
library;

import 'package:test/test.dart';

import 'package:dart_quill/dart_quill_office.dart';
import 'package:dart_quill/src/platform/dom.dart';

import '../../../support/fake_dom.dart';
import '../../../support/pdf_reader.dart';

/// Texto concatenado de um elemento e seus descendentes.
String textOf(DomElement element) => element.textContent ?? '';

List<DomElement> childrenOf(DomElement element) =>
    element.childNodes.whereType<DomElement>().toList();

Iterable<DomElement> descendantsOf(DomElement element) sync* {
  for (final child in childrenOf(element)) {
    yield child;
    yield* descendantsOf(child);
  }
}

void main() {
  final schema = officeQuillSchema();

  late FakeDomDocument document;
  late DomElement host;

  setUp(() {
    document = FakeDomDocument();
    host = document.createElement('div');
    document.body.append(host);
  });

  PMNode docOf(List<PMNode> blocks) =>
      schema.node('doc', null, Fragment.from(blocks));

  PMNode paragraph(String text) =>
      schema.node('paragraph', null, Fragment.from([schema.text(text)]));

  List<DomElement> pagesIn(DomElement host) => childrenOf(host)
      .where((e) => e.classes.contains('dq-office-page'))
      .toList();

  group('projeção de páginas', () {
    test('uma página por PageLayout, com a geometria em pixels', () {
      final graph = LayoutComposer().compose(docOf([paragraph('olá')]));
      PageGraphDomRenderer(document: document).render(graph, host);

      final pages = pagesIn(host);
      expect(pages, hasLength(1));
      final style = pages.first.getAttribute('style')!;
      // A4 = 11906 twips = 595.3pt; a 96/72 px/pt ≈ 793.7px.
      expect(style, contains('width:793.73px'));
      expect(style, contains('height:1122.53px'));
      expect(pages.first.getAttribute('data-page'), '0');
    });

    test('o content box respeita as margens da seção', () {
      final graph = LayoutComposer().compose(docOf([paragraph('x')]));
      PageGraphDomRenderer(document: document).render(graph, host);

      final content = childrenOf(pagesIn(host).first).single;
      expect(content.classes.contains('dq-office-page-content'), isTrue);
      final style = content.getAttribute('style')!;
      // margem de 2 cm = 1134 twips = 56.7pt ≈ 75.6px.
      expect(style, contains('left:75.6px'));
      expect(style, contains('top:75.6px'));
    });

    test('editable liga contenteditable e desliga o spellcheck nativo', () {
      final graph = LayoutComposer().compose(docOf([paragraph('x')]));
      PageGraphDomRenderer(document: document, editable: true)
          .render(graph, host);

      final content = childrenOf(pagesIn(host).first).single;
      expect(content.getAttribute('contenteditable'), 'true');
      expect(content.getAttribute('spellcheck'), 'false');
    });

    test('regiões pintam antes do corpo para não encobrir texto na margem', () {
      final graph = LayoutComposer(
        header: docOf([paragraph('TIMBRE')]),
        footer: docOf([paragraph('RODAPÉ')]),
      ).compose(docOf([paragraph('CORPO')]));
      PageGraphDomRenderer(document: document).render(graph, host);

      final children = childrenOf(pagesIn(host).single);
      expect(children.map((child) => child.className), [
        contains('dq-office-header'),
        contains('dq-office-footer'),
        contains('dq-office-page-content'),
      ]);
    });

    test('render substitui a projeção anterior, não acumula', () {
      final renderer = PageGraphDomRenderer(document: document);
      final graph = LayoutComposer().compose(docOf([paragraph('um')]));
      renderer.render(graph, host);
      renderer.render(graph, host);
      expect(pagesIn(host), hasLength(1));
    });
  });

  group('âncoras do PositionMap no DOM', () {
    test('metadado OOXML sem layout fica ancorado e não cria caret vazio', () {
      final marker = schema.node('opaque', {
        'id': 'bookmark-end-1',
        'insert': {
          'qname': 'w:bookmarkEnd',
          'officeXml': '<w:bookmarkEnd w:id="1"/>'
        }
      });
      final graph = LayoutComposer()
          .compose(docOf([paragraph('antes'), marker, paragraph('depois')]));
      PageGraphDomRenderer(document: document, editable: true)
          .render(graph, host);

      final element = host.querySelector('.dq-office-block-opaque');
      expect(element, isNotNull);
      expect(element!.getAttribute('data-node-id'), 'bookmark-end-1');
      expect(element.getAttribute('contenteditable'), 'false');
      expect(element.getAttribute('aria-hidden'), 'true');
      expect(element.getAttribute('style'), contains('display:none'));
      expect(element.querySelector('.dq-office-line-empty'), isNull,
          reason: 'range marker não pode virar parágrafo/caret fantasma');
    });

    test('cada bloco carrega docPos e o id estável do nó', () {
      final block = schema.node(
          'paragraph', {'id': 'p-42'}, Fragment.from([schema.text('texto')]));
      final graph = LayoutComposer().compose(docOf([block]));
      PageGraphDomRenderer(document: document).render(graph, host);

      final content = childrenOf(pagesIn(host).first).single;
      final blockElement = childrenOf(content).single;
      expect(blockElement.getAttribute('data-doc-pos'), '1');
      expect(blockElement.getAttribute('data-node-id'), 'p-42');
      expect(
          blockElement.classes.contains('dq-office-block-paragraph'), isTrue);
    });

    test('as linhas carregam o intervalo de caracteres do bloco', () {
      final graph = LayoutComposer()
          .compose(docOf([paragraph('primeira linha de conteúdo')]));
      PageGraphDomRenderer(document: document).render(graph, host);

      final content = childrenOf(pagesIn(host).first).single;
      final line = childrenOf(childrenOf(content).single).single;
      expect(line.classes.contains('dq-office-line'), isTrue);
      expect(line.getAttribute('data-char-start'), '0');
      expect(int.parse(line.getAttribute('data-char-end')!), greaterThan(0));
    });

    test('bloco que atravessa páginas marca a continuação nos dois lados', () {
      final long = paragraph(List.generate(2000, (i) => 'palavra$i').join(' '));
      final graph = LayoutComposer().compose(docOf([long]));
      PageGraphDomRenderer(document: document).render(graph, host);

      final pages = pagesIn(host);
      expect(pages.length, greaterThan(1));
      final first = childrenOf(childrenOf(pages[0]).single).single;
      final second = childrenOf(childrenOf(pages[1]).single).single;
      expect(first.getAttribute('data-continues-on'), 'true');
      expect(second.getAttribute('data-continues-from'), 'true');
      expect(first.getAttribute('data-doc-pos'),
          second.getAttribute('data-doc-pos'),
          reason: 'o MESMO nó nas duas páginas');
    });
  });

  group('estilo do run vira CSS inline (nunca classe global)', () {
    test('fonte DOCX ausente usa fallback da mesma métrica do layout', () {
      PMNode withFont(String text, String family) => schema.node(
            'paragraph',
            null,
            Fragment.from([
              schema.text(text, [
                schema.marks['font']!.create({'value': family}),
              ]),
            ]),
          );

      final graph = LayoutComposer().compose(docOf([
        withFont('eco', 'Ecofont_Spranq_eco_Sans'),
        withFont('desconhecida', 'Fonte Inexistente'),
        withFont('serifada', 'Times New Roman'),
        withFont('mono', 'Courier New'),
        withFont('serif genérica', 'serif'),
        withFont('mono genérica', 'monospace'),
        withFont('consolas', 'Consolas'),
      ]));
      PageGraphDomRenderer(document: document).render(graph, host);

      final runs = descendantsOf(host)
          .where((element) => element.classes.contains('dq-office-run'))
          .toList();
      String styleOf(String text) => runs
          .singleWhere((run) => run.textContent == text)
          .getAttribute('style')!;

      expect(
        styleOf('eco'),
        contains(
          'font-family:Ecofont_Spranq_eco_Sans,calibri,carlito,arial,sans-serif;',
        ),
      );
      expect(
        styleOf('desconhecida'),
        contains("font-family:'Fonte Inexistente',arial,sans-serif;"),
      );
      expect(
        styleOf('serifada'),
        contains("font-family:'Times New Roman',serif;"),
      );
      expect(
        styleOf('mono'),
        contains("font-family:'Courier New',monospace;"),
      );
      expect(
        styleOf('serif genérica'),
        contains("font-family:'times new roman',serif;"),
      );
      expect(
        styleOf('mono genérica'),
        contains("font-family:'courier new',monospace;"),
      );
      expect(
        styleOf('consolas'),
        contains("font-family:Consolas,'courier new',monospace;"),
      );
    });

    test('negrito, itálico, cor e link', () {
      final block = schema.node(
          'paragraph',
          null,
          Fragment.from([
            schema.text('forte', [schema.marks['bold']!.create()]),
            schema.text('ligado', [
              schema.marks['link']!.create({'href': 'https://x.gov.br'})
            ]),
          ]));
      final graph = LayoutComposer().compose(docOf([block]));
      PageGraphDomRenderer(document: document).render(graph, host);

      final content = childrenOf(pagesIn(host).first).single;
      final runs = childrenOf(childrenOf(childrenOf(content).single).single);
      expect(runs.first.getAttribute('style'), contains('font-weight:bold'));
      final link = runs.firstWhere((r) => r.getAttribute('data-link') != null);
      expect(link.getAttribute('data-link'), 'https://x.gov.br');
      // Nenhuma classe do Quill vaza para a projeção Office.
      for (final run in runs) {
        expect(run.classes.contains('dq-office-run'), isTrue);
        expect(run.className, isNot(contains('ql-')));
      }
    });

    test('marcador de lista é projeção: inerte e fora da acessibilidade', () {
      final item = schema.node('listItem', {'kind': 'ordered'},
          Fragment.from([schema.text('item')]));
      final graph = LayoutComposer().compose(docOf([item]));
      PageGraphDomRenderer(document: document).render(graph, host);

      final content = childrenOf(pagesIn(host).first).single;
      final marker = childrenOf(childrenOf(content).single)
          .firstWhere((e) => e.classes.contains('dq-office-marker'));
      expect(textOf(marker), '1. ');
      expect(marker.getAttribute('contenteditable'), 'false');
      expect(marker.getAttribute('aria-hidden'), 'true');
    });
  });

  group('tabelas', () {
    test('linhas e células viram caixas posicionadas com borda', () {
      final rows = [
        for (var r = 0; r < 3; r++)
          schema.node(
              'tableRow',
              {'rowId': 'r$r'},
              Fragment.from([
                schema.node('tableCell', {'cellId': 'a$r'},
                    Fragment.from([paragraph('A$r')])),
                schema.node('tableCell', {'cellId': 'b$r'},
                    Fragment.from([paragraph('B$r')])),
              ]))
      ];
      final table = schema.node(
          'table',
          {
            'colWidths': [
              {'width': '200'},
              {'width': '200'}
            ]
          },
          Fragment.from(rows));
      final graph = LayoutComposer().compose(docOf([table]));
      PageGraphDomRenderer(document: document).render(graph, host);

      final content = childrenOf(pagesIn(host).first).single;
      final tableElement = childrenOf(content).single;
      expect(tableElement.classes.contains('dq-office-table'), isTrue);
      final rowElements = childrenOf(tableElement);
      expect(rowElements, hasLength(3));
      final cells = childrenOf(rowElements.first);
      expect(cells, hasLength(2));
      expect(cells.first.getAttribute('style'), contains('border:1px solid'));
      expect(textOf(cells.first), contains('A0'));
      expect(textOf(cells.last), contains('B0'));
    });

    test(
        'fragmentos e recomposição incremental preservam identidade no grafo e DOM',
        () {
      PMNode identifiedCell({
        required String id,
        required String sourceId,
        required int sourceIndex,
        required List<PMNode> blocks,
        Map<String, dynamic> word = const {},
        Map<String, dynamic> presentation = const {},
      }) =>
          schema.node(
              'tableCell',
              {
                'id': id,
                'cellId': sourceId,
                if (presentation.isNotEmpty) 'cell': presentation,
                'word': {
                  ...word,
                  'sourceCellIndex': sourceIndex,
                },
              },
              Fragment.from(blocks));

      PMNode identifiedRow({
        required String id,
        required String sourceId,
        required int sourceIndex,
        required List<PMNode> cells,
        Map<String, dynamic> word = const {},
      }) =>
          schema.node(
              'tableRow',
              {
                'id': id,
                'rowId': sourceId,
                'word': {
                  ...word,
                  'sourceRowIndex': sourceIndex,
                },
              },
              Fragment.from(cells));

      final longInlines = <PMNode>[];
      for (var i = 0; i < 18; i++) {
        if (i > 0) longInlines.add(schema.node('hardBreak'));
        longInlines.add(schema.text('linha-$i'));
      }
      final longParagraph = schema.node(
          'paragraph', {'id': 'pm-body-p'}, Fragment.from(longInlines));

      final header = identifiedRow(
        id: 'pm-header-row',
        sourceId: 'source-header-row',
        sourceIndex: 0,
        word: const {
          'tblHeader': true,
          'heightTwips': 300,
          'heightRule': 'exact',
        },
        cells: [
          identifiedCell(
            id: 'pm-header-cell',
            sourceId: 'source-header-cell',
            sourceIndex: 0,
            blocks: [paragraph('cabeçalho')],
          ),
        ],
      );
      final shortRow = identifiedRow(
        id: 'pm-short-row',
        sourceId: 'source-short-row',
        sourceIndex: 1,
        word: const {'heightTwips': 300, 'heightRule': 'exact'},
        cells: [
          identifiedCell(
            id: 'pm-short-cell',
            sourceId: 'source-short-cell',
            sourceIndex: 0,
            blocks: [paragraph('primeira linha de dados')],
          ),
        ],
      );
      final bodyRow = identifiedRow(
        id: 'pm-body-row',
        sourceId: 'source-body-row',
        sourceIndex: 2,
        cells: [
          identifiedCell(
            id: 'pm-body-cell',
            sourceId: 'source-body-cell',
            sourceIndex: 0,
            blocks: [longParagraph],
          ),
        ],
      );
      final mergeStart = identifiedRow(
        id: 'pm-merge-start-row',
        sourceId: 'source-merge-start-row',
        sourceIndex: 3,
        word: const {'heightTwips': 300, 'heightRule': 'exact'},
        cells: [
          identifiedCell(
            id: 'pm-merge-start-cell',
            sourceId: 'source-merge-start-cell',
            sourceIndex: 0,
            word: const {'vMerge': 'restart'},
            presentation: const {'vMerge': 'restart'},
            blocks: [paragraph('mesclada')],
          ),
        ],
      );
      final mergeContinue = identifiedRow(
        id: 'pm-merge-continue-row',
        sourceId: 'source-merge-continue-row',
        sourceIndex: 4,
        word: const {'heightTwips': 300, 'heightRule': 'exact'},
        cells: [
          identifiedCell(
            id: 'pm-merge-continue-cell',
            sourceId: 'source-merge-continue-cell',
            sourceIndex: 0,
            word: const {'vMerge': 'continue'},
            presentation: const {'vMerge': 'continue'},
            blocks: [
              schema.node(
                  'paragraph', {'id': 'pm-merge-empty-p'}, Fragment.empty),
            ],
          ),
        ],
      );
      final table = schema.node(
          'table',
          {
            'id': 'source-table',
            'colWidths': [4000],
          },
          Fragment.from(
              [header, shortRow, bodyRow, mergeStart, mergeContinue]));
      final composer = LayoutComposer(
        setup: const PageSetupTwips(
          widthTwips: 5000,
          heightTwips: 2200,
          marginTopTwips: 100,
          marginRightTwips: 100,
          marginBottomTwips: 100,
          marginLeftTwips: 100,
        ),
        quality: LayoutQuality.fidelity,
      );
      final prefixInlines = <PMNode>[];
      for (var i = 0; i < 7; i++) {
        if (i > 0) prefixInlines.add(schema.node('hardBreak'));
        prefixInlines.add(schema.text('prefixo-$i'));
      }
      final prefix = schema.node(
          'paragraph', {'id': 'pm-prefix'}, Fragment.from(prefixInlines));
      final before = docOf([prefix, table]);
      final tableFrom = prefix.nodeSize;
      final tableTo = tableFrom + table.nodeSize;
      final graph = composer.compose(before);

      final fragments = [
        for (final page in graph.pages)
          ...page.fragments.whereType<TableFragment>(),
      ];
      expect(fragments.length, greaterThan(1));
      expect(fragments.map((fragment) => fragment.sourceTableId).toSet(),
          {'source-table'});
      expect(
          fragments.map((fragment) => fragment.docFrom).toSet(), {tableFrom});
      expect(fragments.map((fragment) => fragment.docTo).toSet(), {tableTo});

      final graphRows = [for (final fragment in fragments) ...fragment.rows];
      final bodyParts = graphRows
          .where((row) => row.sourceRowId == 'source-body-row')
          .toList();
      expect(bodyParts.length, greaterThan(1),
          reason: 'a mesma row deve atravessar páginas');
      expect(bodyParts.map((row) => row.nodeId).toSet(), {'pm-body-row'});
      expect(bodyParts.map((row) => row.sourceRowIndex).toSet(), {2});
      expect(bodyParts.map((row) => row.docFrom).toSet(), hasLength(1));
      expect(bodyParts.map((row) => row.docTo).toSet(), hasLength(1));
      final bodyCells = [for (final row in bodyParts) ...row.cells];
      expect(bodyCells.map((cell) => cell.sourceCellId).toSet(),
          {'source-body-cell'});
      expect(bodyCells.map((cell) => cell.nodeId).toSet(), {'pm-body-cell'});
      expect(bodyCells.map((cell) => cell.docFrom).toSet(), hasLength(1));
      expect(bodyCells.map((cell) => cell.docTo).toSet(), hasLength(1));
      expect(graphRows.where((row) => row.isRepeatedHeader), isNotEmpty);
      expect(
          graphRows
              .where((row) => row.isRepeatedHeader)
              .map((row) => row.sourceRowId)
              .toSet(),
          {'source-header-row'});
      final mergeContinuation = graphRows
          .expand((row) => row.cells)
          .singleWhere((cell) => cell.isMergeContinuation);
      expect(mergeContinuation.sourceTableId, 'source-table');
      expect(mergeContinuation.sourceRowId, 'source-merge-continue-row');
      expect(mergeContinuation.sourceCellId, 'source-merge-continue-cell');

      PageGraphDomRenderer(document: document, editable: true)
          .render(graph, host);
      final domTables = descendantsOf(host)
          .where((element) => element.classes.contains('dq-office-table'))
          .toList();
      expect(domTables, hasLength(fragments.length));
      for (final element in domTables) {
        expect(element.getAttribute('data-node-id'), 'source-table');
        expect(element.getAttribute('data-source-table'), 'source-table');
        expect(element.getAttribute('data-doc-from'), '$tableFrom');
        expect(element.getAttribute('data-doc-to'), '$tableTo');
      }

      final domRows = [
        for (final tableElement in domTables) ...childrenOf(tableElement),
      ];
      final domBodyParts = domRows
          .where(
              (row) => row.getAttribute('data-source-row') == 'source-body-row')
          .toList();
      expect(domBodyParts.length, bodyParts.length);
      for (final row in domBodyParts) {
        expect(row.getAttribute('data-node-id'), 'pm-body-row');
        expect(row.getAttribute('data-source-table'), 'source-table');
        expect(row.getAttribute('data-source-row-index'), '2');
        expect(row.getAttribute('data-doc-from'), isNotNull);
        expect(row.getAttribute('data-doc-to'), isNotNull);
        final cellElement = childrenOf(row).single;
        expect(cellElement.getAttribute('data-node-id'), 'pm-body-cell');
        expect(
            cellElement.getAttribute('data-source-cell'), 'source-body-cell');
        expect(cellElement.getAttribute('data-source-cell-index'), '0');
        expect(cellElement.getAttribute('data-doc-from'), isNotNull);
        expect(cellElement.getAttribute('data-doc-to'), isNotNull);
      }

      final repeatedHeaders = domRows
          .where((row) => row.getAttribute('data-repeated-header') == 'true')
          .toList();
      expect(repeatedHeaders, isNotEmpty);
      for (final row in repeatedHeaders) {
        expect(row.getAttribute('data-node-id'), isNull,
            reason: 'cópia visual não cria uma segunda âncora editável');
        expect(row.getAttribute('data-source-row'), 'source-header-row');
        expect(row.getAttribute('data-doc-from'), isNotNull);
        expect(row.getAttribute('data-doc-to'), isNotNull);
        expect(row.getAttribute('contenteditable'), 'false');
      }

      final hiddenContinuation = descendantsOf(host).singleWhere(
          (element) => element.getAttribute('data-vmerge') == 'continue');
      expect(hiddenContinuation.getAttribute('data-node-id'),
          'pm-merge-continue-cell');
      expect(hiddenContinuation.getAttribute('data-source-row'),
          'source-merge-continue-row');
      expect(hiddenContinuation.getAttribute('data-source-cell'),
          'source-merge-continue-cell');
      expect(hiddenContinuation.getAttribute('data-doc-from'), isNotNull);
      expect(hiddenContinuation.getAttribute('data-doc-to'), isNotNull);

      // Regressão do corpus TR: editar uma célula de uma row já dividida
      // entre páginas precisa invalidar a tabela inteira, chegar ao novo
      // PageGraph e substituir a janela DOM montada — sem perder a chave
      // que leva a projeção de volta à mesma célula PM.
      final oldBodyPages = <int>{
        for (final page in graph.pages)
          if (page.fragments.whereType<TableFragment>().any((fragment) =>
              fragment.rows.any((row) => row.sourceRowId == 'source-body-row')))
            page.index,
      };
      expect(oldBodyPages.length, greaterThan(1));
      final continuationPageNumber = oldBodyPages.skip(1).first;

      // A edição anterior ao início da tabela faz o compositor convergir e
      // reutilizar o sufixo. Todos os ranges internos das rows/cells desse
      // sufixo precisam deslocar junto; caso contrário o próximo clique
      // aponta para a posição PM antiga (o fluxo real do E2E do TR).
      const prefixToken = ' CORPO_TOKEN';
      final initialState = EditorState.create(EditorStateConfig(doc: before));
      final prefixInsertAt = 1 + 'prefixo-0'.length;
      final prefixTransaction = initialState.tr
        ..insertText(prefixToken, prefixInsertAt);
      final afterPrefixState = initialState.apply(prefixTransaction);
      final shiftedGraph = composer.composeIncremental(
        afterPrefixState.doc,
        previous: graph,
        changedFromDocPos: prefixInsertAt,
      );
      final shiftedBodyPages = <int>{
        for (final page in shiftedGraph.pages)
          if (page.fragments.whereType<TableFragment>().any((fragment) =>
              fragment.rows.any((row) => row.sourceRowId == 'source-body-row')))
            page.index,
      };
      expect(shiftedBodyPages, oldBodyPages);
      final originalBodyDocPos = bodyParts.first.docPos;
      final shiftedBodyDocPos = shiftedGraph.pages
          .expand((page) => page.fragments.whereType<TableFragment>())
          .expand((fragment) => fragment.rows)
          .firstWhere((row) => row.sourceRowId == 'source-body-row')
          .docPos;
      expect(shiftedBodyDocPos, originalBodyDocPos + prefixToken.length,
          reason: 'row reutilizada precisa acompanhar o delta anterior');

      PageGraphDomRenderer(document: document, editable: true).render(
        shiftedGraph,
        host,
        window: PageWindow(
          firstPage: continuationPageNumber,
          lastPage: continuationPageNumber,
        ),
      );
      final continuationPage = pagesIn(host).singleWhere((page) =>
          page.getAttribute('data-page') == '$continuationPageNumber');
      final continuationCell = descendantsOf(continuationPage).firstWhere(
          (element) =>
              element.getAttribute('data-source-cell') == 'source-body-cell');
      final continuationRun = descendantsOf(continuationCell).firstWhere(
          (element) =>
              element.classes.contains('dq-office-run') &&
              (element.textContent ?? '').isNotEmpty);
      final continuationText = continuationRun.firstChild!;
      final insertAt = const OfficeDomPositionMap().modelPositionAt(
        continuationText,
        (continuationText.textContent ?? '').length,
      );
      expect(insertAt, isNotNull,
          reason: 'run de um fragmento posterior precisa voltar ao PM');
      final modelInsertAt = insertAt!;
      const token = ' E2E_TABLE_TOKEN';
      final transaction = afterPrefixState.tr..insertText(token, modelInsertAt);
      final after = afterPrefixState.apply(transaction).doc;
      final incremental = composer.composeIncremental(
        after,
        previous: shiftedGraph,
        changedFromDocPos: modelInsertAt,
      );
      final newBodyPages = <int>{
        for (final page in incremental.pages)
          if (page.fragments.whereType<TableFragment>().any((fragment) =>
              fragment.rows.any((row) => row.sourceRowId == 'source-body-row')))
            page.index,
      };
      expect(incremental.pages.length, shiftedGraph.pages.length,
          reason: 'identidade/invalidação não altera a paginação');
      expect(newBodyPages, oldBodyPages);

      final newBodyParts = [
        for (final page in incremental.pages)
          for (final fragment in page.fragments.whereType<TableFragment>())
            ...fragment.rows
                .where((row) => row.sourceRowId == 'source-body-row'),
      ];
      expect(newBodyParts.map((row) => row.nodeId).toSet(), {'pm-body-row'});
      expect(
          newBodyParts
              .expand((row) => row.cells)
              .map((cell) => cell.sourceCellId)
              .toSet(),
          {'source-body-cell'});
      expect(
          newBodyParts
              .expand((row) => row.cells)
              .expand((cell) => cell.blocks)
              .expand((block) => block.lines)
              .expand((line) => line.segments)
              .map((segment) => segment.text)
              .join(),
          contains(token.trim()));

      PageGraphDomRenderer(document: document, editable: true).render(
        incremental,
        host,
        window: PageWindow(
          firstPage: continuationPageNumber,
          lastPage: continuationPageNumber,
        ),
      );
      final editedCell = descendantsOf(host).firstWhere((element) =>
          element.getAttribute('data-source-cell') == 'source-body-cell');
      expect(editedCell.getAttribute('data-node-id'), 'pm-body-cell');
      expect(editedCell.getAttribute('data-source-table'), 'source-table');
      expect(textOf(editedCell), contains(token.trim()));
    });
  });

  group('virtualização por janela de páginas', () {
    test('páginas fora da janela viram placeholder da MESMA altura', () {
      final blocks = [
        for (var i = 0; i < 200; i++) paragraph('Parágrafo $i do documento.')
      ];
      final graph = LayoutComposer().compose(docOf(blocks));
      expect(graph.pages.length, greaterThan(3));

      PageGraphDomRenderer(document: document).render(graph, host,
          window: const PageWindow(firstPage: 0, lastPage: 1));

      final children = childrenOf(host);
      expect(children.length, graph.pages.length,
          reason: 'toda página ocupa um slot — o scroll não pode pular');
      expect(pagesIn(host), hasLength(2), reason: 'só a janela é montada');
      final placeholder = children.last;
      expect(
          placeholder.classes.contains('dq-office-page-placeholder'), isTrue);
      expect(placeholder.getAttribute('style'), contains('height:1122.53px'),
          reason: 'placeholder com a altura exata da página');
      expect(textOf(placeholder), isEmpty);
    });
  });

  group('GATE: grafo, DOM e PDF concordam página a página', () {
    test('o texto da página N está no DOM N e no PDF N', () {
      final blocks = [
        for (var i = 0; i < 120; i++)
          paragraph('Sentenca numero $i com conteudo distinto.')
      ];
      final graph = LayoutComposer().compose(docOf(blocks));
      expect(graph.pages.length, greaterThan(1));

      PageGraphDomRenderer(document: document).render(graph, host);
      final domPages = pagesIn(host);
      final pdfStreams = PdfReader(PageGraphPdfRenderer().render(graph))
          .decodedStreams
          .where((s) => s.contains('Tj'))
          .toList();

      expect(domPages.length, graph.pages.length);
      expect(pdfStreams.length, graph.pages.length);

      for (var p = 0; p < graph.pages.length; p++) {
        final domText = textOf(domPages[p]);
        for (final fragment
            in graph.pages[p].fragments.whereType<BlockFragment>()) {
          for (final line in fragment.lines) {
            for (final segment in line.segments) {
              final word = segment.text.split(' ').firstWhere(
                  (w) => RegExp(r'^[A-Za-z0-9]{4,}$').hasMatch(w),
                  orElse: () => '');
              if (word.isEmpty) continue;
              expect(domText, contains(word),
                  reason: '"$word" do grafo pág. $p tem de estar no DOM $p');
              expect(pdfStreams[p], contains(word),
                  reason: '"$word" do grafo pág. $p tem de estar no PDF $p');
              break;
            }
          }
        }
      }
    });

    test('o DOM não perde nem duplica texto do documento', () {
      final blocks = [
        for (var i = 0; i < 40; i++) paragraph('linha unica numero $i')
      ];
      final graph = LayoutComposer().compose(docOf(blocks));
      PageGraphDomRenderer(document: document).render(graph, host);

      // `textContent` concatena blocos sem separador, então a busca precisa
      // fechar o número (senão "numero 1" casaria dentro de "numero 12").
      final domText = textOf(host);
      for (var i = 0; i < 40; i++) {
        final occurrences =
            RegExp('numero $i(?![0-9])').allMatches(domText).length;
        expect(occurrences, 1,
            reason: 'o parágrafo $i aparece exatamente uma vez no DOM');
      }
    });
  });
}
