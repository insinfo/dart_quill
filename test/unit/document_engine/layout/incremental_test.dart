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

  PMNode paragraph(String text) => schema.node(
      'paragraph', null, Fragment.from([schema.text(text)]));

  PMNode docOf(List<PMNode> blocks) =>
      schema.node('doc', null, Fragment.from(blocks));

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
      PMNode cell(String text) => schema.node(
          'tableCell', null, Fragment.from([paragraph(text)]));
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
          'listItem', {'kind': 'ordered'},
          Fragment.from([schema.text(text)]));

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
      blocks[0] = paragraph(
          'Parágrafo 0 com texto suficiente para ocupar espaço real '
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
}

/// Posição do primeiro caractere do bloco [index].
int _startOfBlock(PMNode doc, int index) {
  var offset = 0;
  for (var i = 0; i < index; i++) {
    offset += doc.child(i).nodeSize;
  }
  return offset + 1;
}
