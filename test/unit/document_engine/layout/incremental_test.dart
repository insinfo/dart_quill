/// Fase 7 — invalidação incremental e cache tipográfico.
///
/// O invariante que importa não é "ficou rápido": é que a recomposição
/// incremental produza EXATAMENTE o mesmo grafo que a completa. Um
/// paginador incremental que diverge do completo é pior que um lento —
/// o editor mostraria uma página e o PDF outra, quebrando o gate central
/// da arquitetura.
@TestOn('vm')
library;

import 'package:test/test.dart';

import 'package:dart_quill/dart_quill_office.dart';

void main() {
  final schema = officeQuillSchema();

  PMNode paragraph(String text) =>
      schema.node('paragraph', null, Fragment.from([schema.text(text)]));

  PMNode docOf(List<PMNode> blocks) =>
      schema.node('doc', null, Fragment.from(blocks));

  PMNode tableDocument(int rows, {bool invalidVerticalMerge = false}) {
    PMNode cell(int index, String side) => schema.node(
          'tableCell',
          {
            'id': 'c-$index-$side',
            if (invalidVerticalMerge && index == 0 && side == 'a')
              'word': {'vMerge': 'continue'},
          },
          Fragment.from([
            paragraph('Linha $index, célula $side com texto para medir.'),
          ]),
        );

    final table = schema.node(
      'table',
      {
        'id': 'table-$rows-$invalidVerticalMerge',
        'colWidths': [3200, 3200],
        'word': {
          'borders': {
            'insideH': {'val': 'single', 'sizeEighths': 4},
            'insideV': {'val': 'single', 'sizeEighths': 4},
          },
        },
      },
      Fragment.from([
        for (var index = 0; index < rows; index++)
          schema.node(
            'tableRow',
            {'id': 'r-$index'},
            Fragment.from([cell(index, 'a'), cell(index, 'b')]),
          ),
      ]),
    );
    return docOf([table]);
  }

  PMNode longDoc(int blocks, {String? changeAt, int? changeIndex}) => docOf([
        for (var i = 0; i < blocks; i++)
          paragraph(i == changeIndex
              ? changeAt!
              : 'Parágrafo $i com texto suficiente para ocupar espaço real '
                  'na página e forçar a composição a trabalhar de verdade.')
      ]);

  /// Compara dois grafos página a página — a única prova que interessa.
  void expectSameGraph(PageGraph actual, PageGraph expected) {
    expect(actual.pages.length, expected.pages.length,
        reason: 'contagem de páginas divergiu');
    for (var p = 0; p < expected.pages.length; p++) {
      final a = actual.pages[p];
      final e = expected.pages[p];
      expect(a.index, e.index);
      expect(a.fragments.length, e.fragments.length,
          reason: 'fragmentos da página $p divergiram');
      for (var f = 0; f < e.fragments.length; f++) {
        final af = a.fragments[f];
        final ef = e.fragments[f];
        expect(af.docPos, ef.docPos, reason: 'docPos na página $p');
        expect(af.yTwips, ef.yTwips, reason: 'y na página $p');
        expect(af.heightTwips, ef.heightTwips, reason: 'altura na página $p');
        if (af is BlockFragment && ef is BlockFragment) {
          expect(af.lines.length, ef.lines.length,
              reason: 'linhas na página $p, fragmento $f');
          for (var l = 0; l < ef.lines.length; l++) {
            expect(af.lines[l].charStart, ef.lines[l].charStart);
            expect(af.lines[l].charEnd, ef.lines[l].charEnd);
          }
        } else if (af is TableFragment && ef is TableFragment) {
          expect(af.rows.length, ef.rows.length,
              reason: 'rows na página $p, fragmento $f');
          for (var r = 0; r < ef.rows.length; r++) {
            final ar = af.rows[r];
            final er = ef.rows[r];
            expect(ar.docPos, er.docPos);
            expect(ar.docPosEnd, er.docPosEnd);
            expect(ar.heightTwips, er.heightTwips);
            expect(ar.continuesFromPreviousPage, er.continuesFromPreviousPage);
            expect(ar.continuesOnNextPage, er.continuesOnNextPage);
            expect(ar.cells.length, er.cells.length);
            for (var c = 0; c < er.cells.length; c++) {
              final ac = ar.cells[c];
              final ec = er.cells[c];
              expect(ac.docPos, ec.docPos);
              expect(ac.docPosEnd, ec.docPosEnd);
              expect(ac.xTwips, ec.xTwips);
              expect(ac.widthTwips, ec.widthTwips);
              expect(ac.heightTwips, ec.heightTwips);
              expect(ac.contentHeightTwips, ec.contentHeightTwips);
              expect(ac.columnIndex, ec.columnIndex);
              expect(ac.columnSpan, ec.columnSpan);
              expect(ac.rowSpan, ec.rowSpan);
              expect(ac.isMergeContinuation, ec.isMergeContinuation);
              expect(ac.contentOffsetTwips, ec.contentOffsetTwips);
              expect(ac.blocks.length, ec.blocks.length);
              for (var b = 0; b < ec.blocks.length; b++) {
                final ab = ac.blocks[b];
                final eb = ec.blocks[b];
                expect(ab.docPos, eb.docPos);
                expect(ab.yTwips, eb.yTwips);
                expect(ab.heightTwips, eb.heightTwips);
                expect(ab.lines.length, eb.lines.length);
                for (var l = 0; l < eb.lines.length; l++) {
                  expect(ab.lines[l].charStart, eb.lines[l].charStart);
                  expect(ab.lines[l].charEnd, eb.lines[l].charEnd);
                  expect(ab.lines[l].widthTwips, eb.lines[l].widthTwips);
                }
              }
            }
          }
        }
      }
    }
  }

  group('equivalência com a composição completa', () {
    test('edição no FIM: incremental == completa', () {
      final composer = LayoutComposer();
      final before = longDoc(120);
      final graph = composer.compose(before);
      expect(graph.pages.length, greaterThan(3));

      final after = longDoc(120, changeIndex: 119, changeAt: 'ALTERADO');
      final changedFrom = after.child(119) == before.child(119)
          ? after.content.size
          : _startOfBlock(after, 119);

      expectSameGraph(
        composer.composeIncremental(after,
            previous: graph, changedFromDocPos: changedFrom),
        LayoutComposer().compose(after),
      );
    });

    test('edição no MEIO: incremental == completa', () {
      final composer = LayoutComposer();
      final before = longDoc(120);
      final graph = composer.compose(before);

      final after = longDoc(120, changeIndex: 60, changeAt: 'MEIO alterado');
      expectSameGraph(
        composer.composeIncremental(after,
            previous: graph, changedFromDocPos: _startOfBlock(after, 60)),
        LayoutComposer().compose(after),
      );
    });

    test('edição no INÍCIO converge e continua correta', () {
      final composer = LayoutComposer();
      final before = longDoc(60);
      final graph = composer.compose(before);

      final after = longDoc(60, changeIndex: 0, changeAt: 'INICIO');
      expectSameGraph(
        composer.composeIncremental(after,
            previous: graph, changedFromDocPos: 1),
        LayoutComposer().compose(after),
      );
    });

    test('inserir bloco no INÍCIO desloca o sufixo corretamente', () {
      final composer = LayoutComposer();
      final before = longDoc(120);
      final graph = composer.compose(before);

      final blocks = [for (var i = 0; i < 120; i++) before.child(i)]
        ..insert(0, paragraph('bloco novo no topo'));
      final after = docOf(blocks);

      expectSameGraph(
        composer.composeIncremental(after,
            previous: graph, changedFromDocPos: 1),
        LayoutComposer().compose(after),
      );
    });

    test('remover bloco no INÍCIO também', () {
      final composer = LayoutComposer();
      final before = longDoc(120);
      final graph = composer.compose(before);

      final blocks = [for (var i = 0; i < 120; i++) before.child(i)]
        ..removeAt(0);
      final after = docOf(blocks);

      expectSameGraph(
        composer.composeIncremental(after,
            previous: graph, changedFromDocPos: 1),
        LayoutComposer().compose(after),
      );
    });

    test('inserir um bloco desloca as posições corretamente', () {
      final composer = LayoutComposer();
      final before = longDoc(80);
      final graph = composer.compose(before);

      final blocks = [
        for (var i = 0; i < 80; i++) before.child(i),
      ]..insert(70, paragraph('bloco novo no meio do documento'));
      final after = docOf(blocks);

      expectSameGraph(
        composer.composeIncremental(after,
            previous: graph, changedFromDocPos: _startOfBlock(after, 70)),
        LayoutComposer().compose(after),
      );
    });

    test('remover um bloco também', () {
      final composer = LayoutComposer();
      final before = longDoc(80);
      final graph = composer.compose(before);

      final blocks = [for (var i = 0; i < 80; i++) before.child(i)]
        ..removeAt(65);
      final after = docOf(blocks);

      expectSameGraph(
        composer.composeIncremental(after,
            previous: graph, changedFromDocPos: _startOfBlock(after, 65)),
        LayoutComposer().compose(after),
      );
    });

    test('documento com tabela: incremental == completa', () {
      final composer = LayoutComposer();
      PMNode cell(String text) =>
          schema.node('tableCell', null, Fragment.from([paragraph(text)]));
      PMNode row(int i) => schema.node(
          'tableRow', null, Fragment.from([cell('a$i'), cell('b$i')]));
      final table = schema.node(
          'table', null, Fragment.from([for (var i = 0; i < 40; i++) row(i)]));

      final before = docOf([
        for (var i = 0; i < 30; i++) paragraph('antes $i'),
        table,
        for (var i = 0; i < 30; i++) paragraph('depois $i'),
      ]);
      final graph = composer.compose(before);

      final after = docOf([
        for (var i = 0; i < 30; i++) paragraph('antes $i'),
        table,
        for (var i = 0; i < 30; i++) paragraph(i == 10 ? 'MUDOU' : 'depois $i'),
      ]);
      expectSameGraph(
        composer.composeIncremental(after,
            previous: graph, changedFromDocPos: _startOfBlock(after, 41)),
        LayoutComposer().compose(after),
      );
    });

    test('listas ordenadas: o carry da numeração sobrevive ao reuso', () {
      final composer = LayoutComposer();
      PMNode item(String text) => schema.node(
          'listItem', {'kind': 'ordered'}, Fragment.from([schema.text(text)]));

      final before = docOf([for (var i = 0; i < 90; i++) item('item $i')]);
      final graph = composer.compose(before);

      final blocks = [for (var i = 0; i < 90; i++) before.child(i)];
      blocks[80] = item('item OITENTA alterado');
      final after = docOf(blocks);

      expectSameGraph(
        composer.composeIncremental(after,
            previous: graph, changedFromDocPos: _startOfBlock(after, 80)),
        LayoutComposer().compose(after),
      );
    });

    test('retomada preserva supressão de spaceBefore no topo da página', () {
      PMNode exact(String text, {int before = 0, required int height}) =>
          schema.node(
              'paragraph',
              {
                'style': {
                  'lineTwips': height,
                  'lineRule': 'exact',
                  'spaceBeforeTwips': before,
                  'spaceAfterTwips': 0,
                  'widowControl': false,
                }
              },
              Fragment.from([schema.text(text)]));
      const setup = PageSetupTwips(
        widthTwips: 5000,
        heightTwips: 400,
        marginTopTwips: 0,
        marginRightTwips: 0,
        marginBottomTwips: 0,
        marginLeftTwips: 0,
      );
      final composer = LayoutComposer(setup: setup);
      final before = docOf([
        exact('p0', height: 300),
        exact('p1', before: 120, height: 200),
        exact('p2', height: 200),
      ]);
      final graph = composer.compose(before);
      expect(graph.pages, hasLength(2));
      expect(graph.pages[1].signature.suppressSpaceBeforeAtPageTop, isTrue);
      expect((graph.pages[1].fragments.first as BlockFragment).spaceBeforeTwips,
          0);

      final after = docOf([
        before.child(0),
        before.child(1),
        exact('P2', height: 200),
      ]);
      final incremental = composer.composeIncremental(
        after,
        previous: graph,
        changedFromDocPos: _startOfBlock(after, 2),
      );
      final complete = LayoutComposer(setup: setup).compose(after);

      expectSameGraph(incremental, complete);
      expect(incremental.pages, hasLength(2));
      expect(
          (incremental.pages[1].fragments.first as BlockFragment)
              .spaceBeforeTwips,
          0);
    });
  });

  group('reuso real', () {
    test('a página de retomada começa num bloco fresco', () {
      final graph = LayoutComposer().compose(longDoc(120));
      for (final page in graph.pages) {
        if (!page.signature.startsFreshBlock) {
          expect(page.fragments.first, isA<PageFragment>(),
              reason: 'página que continua bloco não pode ser retomada');
        }
      }
      expect(graph.pages.first.signature.firstBlockIndex, 0);
      expect(graph.pages.first.signature.startsFreshBlock, isTrue);
    });

    test('editar no fim NÃO recompõe as páginas iniciais', () {
      final composer = LayoutComposer();
      final before = longDoc(200);
      final graph = composer.compose(before);
      final firstPage = graph.pages.first;

      final after = longDoc(200, changeIndex: 199, changeAt: 'FIM');
      final next = composer.composeIncremental(after,
          previous: graph, changedFromDocPos: _startOfBlock(after, 199));

      expect(identical(next.pages.first, firstPage), isTrue,
          reason: 'a página 0 tem de ser o MESMO objeto, não uma cópia igual');
    });

    test('convergência: editar no INÍCIO reusa o SUFIXO', () {
      final composer = LayoutComposer();
      final before = longDoc(400);
      final graph = composer.compose(before);
      final lastPageBefore = graph.pages.last;

      // Edição que NÃO muda o tamanho: o sufixo tem de ser reusado sem nem
      // precisar deslocar.
      final blocks = [for (var i = 0; i < 400; i++) before.child(i)];
      blocks[0] =
          paragraph('Parágrafo 0 com texto suficiente para ocupar espaço real '
              'na página e forçar a composição a trabalhar de VERDADE.');
      final after = docOf(blocks);

      final next = composer.composeIncremental(after,
          previous: graph, changedFromDocPos: 1);
      expect(next.pages.length, graph.pages.length);
      expect(identical(next.pages.last, lastPageBefore), isTrue,
          reason: 'a última página tem de ser o MESMO objeto: converge e '
              'reusa em vez de recompor as 400 páginas');
    });

    test('o PositionMap reusado continua respondendo', () {
      final composer = LayoutComposer();
      final before = longDoc(120);
      final graph = composer.compose(before);
      final after = longDoc(120, changeIndex: 100, changeAt: 'X');
      final next = composer.composeIncremental(after,
          previous: graph, changedFromDocPos: _startOfBlock(after, 100));

      expect(next.positionMap.pageOf(5), 0);
      final full = LayoutComposer().compose(after);
      for (final position in [1, 50, 500, 2000]) {
        if (position >= after.content.size) continue;
        expect(next.positionMap.pageOf(position),
            full.positionMap.pageOf(position),
            reason: 'o mapa incremental divergiu em $position');
      }
    });
  });

  group('cache tipográfico', () {
    test('não muda o resultado', () {
      final cached = LayoutComposer();
      final doc = longDoc(40);
      final first = cached.compose(doc);
      final second = cached.compose(doc);
      expectSameGraph(second, first);
      expectSameGraph(second, LayoutComposer().compose(doc));
    });

    test('recompor o mesmo documento não acrescenta medições', () {
      // Estrutural, não cronometrado: comparar tempo de parede pisca na CI.
      // Se a segunda composição não acrescenta nenhuma entrada, toda medida
      // veio do cache.
      final composer = LayoutComposer();
      final doc = longDoc(300);
      composer.compose(doc);
      final afterFirst = composer.measurementCacheSize;
      expect(afterFirst, greaterThan(0));

      composer.compose(doc);
      expect(composer.measurementCacheSize, afterFirst,
          reason: 'a segunda passada tem de ser 100% cache');
    });

    test('duas instâncias podem compartilhar as medições', () {
      final measurements = LayoutMeasurementCache();
      final doc = longDoc(300);

      final first = LayoutComposer(measurementCache: measurements);
      final firstGraph = first.compose(doc);
      final afterFirst = measurements.length;
      expect(afterFirst, greaterThan(0));

      final second = LayoutComposer(measurementCache: measurements);
      final secondGraph = second.compose(doc);
      expect(measurements.length, afterFirst,
          reason: 'remontar o editor não deve medir de novo o mesmo texto');
      expectSameGraph(secondGraph, firstGraph);
    });

    test('pré-aquecimento cooperativo deixa a composição 100% no cache',
        () async {
      final measurements = LayoutMeasurementCache();
      final composer = LayoutComposer(measurementCache: measurements);
      final doc = longDoc(300);

      final yields = await composer.prewarmMeasurementsAsync(
        [doc],
        sliceBudgetMicroseconds: 1,
      );
      final afterWarmup = measurements.length;
      expect(yields, greaterThan(0));
      expect(afterWarmup, greaterThan(0));

      composer.compose(doc);
      expect(measurements.length, afterWarmup,
          reason: 'texto simples já deve chegar completamente medido');
    });

    test('o limite é aplicado durante a própria composição', () {
      final measurements = LayoutMeasurementCache(maxEntries: 12);
      LayoutComposer(measurementCache: measurements).compose(longDoc(300));
      expect(measurements.length, lessThanOrEqualTo(12));
    });

    test('o cache reaproveita palavras repetidas entre blocos', () {
      final composer = LayoutComposer();
      // 200 blocos com o MESMO texto: as medições distintas têm de ser
      // muito menos que o número de blocos.
      composer.compose(docOf(
          [for (var i = 0; i < 200; i++) paragraph('texto exatamente igual')]));
      expect(composer.measurementCacheSize, lessThan(50),
          reason: 'medir a mesma palavra 200 vezes seria o desperdício');
    });
  });

  group('pré-composição cooperativa de tabelas', () {
    test('aquece por linha e preserva exatamente o mesmo PageGraph', () async {
      final cache = LayoutTableCache();
      final composer = LayoutComposer(tableCache: cache);
      final doc = tableDocument(180);
      final timings = <String, int>{};

      final yields = await composer.prewarmTableLayoutsAsync(
        doc,
        sliceBudgetMicroseconds: 1,
        timings: timings,
      );

      expect(yields, greaterThan(0));
      expect(timings['tableRowCount'], 180);
      expect(cache.length, 1);
      expect(cache.rowCount, 180);
      final first = composer.compose(doc);
      final second = composer.compose(doc);
      final fresh = LayoutComposer().compose(doc);
      expectSameGraph(first, fresh);
      expectSameGraph(second, fresh);
    });

    test('cache hit reaplica warnings da construção', () async {
      final cache = LayoutTableCache();
      final doc = tableDocument(2, invalidVerticalMerge: true);
      final warm = LayoutComposer(tableCache: cache);
      await warm.prewarmTableLayoutsAsync(doc, sliceBudgetMicroseconds: 1);

      final graph = LayoutComposer(tableCache: cache).compose(doc);
      expect(
        graph.diagnostics.warnings,
        contains(contains('vMerge continue sem restart')),
      );
    });

    test('split interno de row não altera a geometria canônica em cache',
        () async {
      final longText = List<String>.generate(
        180,
        (index) => 'palavra$index',
      ).join(' ');
      final cell = schema.node(
        'tableCell',
        {'id': 'split-cell'},
        Fragment.from([paragraph(longText)]),
      );
      final table = schema.node(
        'table',
        {
          'id': 'split-table',
          'colWidths': [2800]
        },
        Fragment.from([
          schema.node(
            'tableRow',
            {'id': 'split-row'},
            Fragment.from([cell]),
          ),
        ]),
      );
      final doc = docOf([table]);
      const setup = PageSetupTwips(
        widthTwips: 4000,
        heightTwips: 3000,
        marginTopTwips: 200,
        marginRightTwips: 200,
        marginBottomTwips: 200,
        marginLeftTwips: 200,
      );
      final cache = LayoutTableCache();
      final composer = LayoutComposer(setup: setup, tableCache: cache);
      await composer.prewarmTableLayoutsAsync(doc);

      final first = composer.compose(doc);
      expect(first.pages.length, greaterThan(1));
      expect(
        first.pages.first.fragments
            .whereType<TableFragment>()
            .single
            .rows
            .last
            .continuesOnNextPage,
        isTrue,
      );
      final second = composer.compose(doc);
      final fresh = LayoutComposer(setup: setup).compose(doc);
      expectSameGraph(first, fresh);
      expectSameGraph(second, fresh);
    });

    test('editar uma célula reutiliza as linhas das demais células', () async {
      final tableCache = LayoutTableCache();
      final lineCache = LayoutTableLineCache();
      final composer = LayoutComposer(
        tableCache: tableCache,
        tableLineCache: lineCache,
      );
      final original = tableDocument(180);
      await composer.prewarmTableLayoutsAsync(original);
      final originalGraph = composer.compose(original);
      final hitsBefore = lineCache.hitCount;

      final oldTable = original.child(0);
      final oldRow = oldTable.child(90);
      final oldCell = oldRow.child(0);
      final changedCell = oldCell.copy(Fragment.from([
        paragraph('Célula realmente alterada pelo usuário.'),
      ]));
      final changedRow = oldRow.copy(Fragment.from([
        changedCell,
        oldRow.child(1),
      ]));
      final changedTable = oldTable.copy(Fragment.from([
        for (var index = 0; index < oldTable.childCount; index++)
          index == 90 ? changedRow : oldTable.child(index),
      ]));
      final edited = docOf([changedTable]);

      final actual = composer.compose(
        edited,
        honorRenderedPageBreaks: false,
      );
      final reused = lineCache.hitCount - hitsBefore;
      expect(reused, greaterThanOrEqualTo(359),
          reason: 'só o parágrafo editado deve perder a identidade/cache');
      expectSameGraph(
        actual,
        LayoutComposer().compose(
          edited,
          honorRenderedPageBreaks: false,
        ),
      );
      expect(originalGraph.pages, isNotEmpty);
    });

    test('usa a largura da seção ativa em vez do setup padrão', () async {
      const narrow = PageSetupTwips(widthTwips: 8000);
      const wide = PageSetupTwips(widthTwips: 16000);
      final endSection = schema.node(
        'paragraph',
        {
          'style': {'sectionBreak': true}
        },
        Fragment.from([schema.text('fim')]),
      );
      final table = tableDocument(3).child(0);
      final doc = docOf([endSection, table]);
      final cache = LayoutTableCache();
      final composer = LayoutComposer(
        sections: const [narrow, wide],
        tableCache: cache,
      );

      await composer.prewarmTableLayoutsAsync(doc);
      expect(cache.length, 1);
      composer.compose(doc);
      expect(cache.length, 1,
          reason: 'um miss aqui denunciaria warmup com largura da seção 1');
    });

    test('cache é limitado pela quantidade total de rows', () async {
      final cache = LayoutTableCache(maxEntries: 8, maxRows: 20);
      final composer = LayoutComposer(tableCache: cache);
      await composer.prewarmTableLayoutsAsync(tableDocument(12));
      await composer.prewarmTableLayoutsAsync(tableDocument(14));
      expect(cache.length, 1);
      expect(cache.rowCount, 14);
    });
  });
}

/// Posição do primeiro caractere do bloco [index].
int _startOfBlock(PMNode doc, int index) {
  var offset = 0;
  for (var i = 0; i < index; i++) {
    offset += doc.child(i).nodeSize;
  }
  return offset + 1;
}
