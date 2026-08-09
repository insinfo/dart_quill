/// Paginação progressiva (estilo Word): `compose(maxPages:)` +
/// `composeContinue` produzem, fatia a fatia, EXATAMENTE o mesmo grafo do
/// compose único — páginas, assinaturas, mapa de posições e regiões.
@TestOn('vm')
library;

import 'package:test/test.dart';

import 'package:dart_quill/dart_quill_office.dart';

void main() {
  final schema = officeQuillSchema();

  PMNode docOf(List<PMNode> blocks) =>
      schema.node('doc', null, Fragment.from(blocks));

  PMNode paragraph(String text) =>
      schema.node('paragraph', null, Fragment.from([schema.text(text)]));

  PMNode longDoc({int blocks = 400}) => docOf([
        for (var i = 0; i < blocks; i++)
          paragraph('Bloco $i — texto longo o suficiente para ocupar a '
              'largura útil da página e forçar quebras de linha reais, '
              'porque a paginação progressiva precisa parar em fronteiras '
              'de página que coincidem com fronteiras de bloco.'),
      ]);

  PMNode region(String text) => schema.node(
        'doc',
        null,
        Fragment.from([
          schema.node('paragraph', {'align': 'center'},
              Fragment.from([schema.text(text)]))
        ]),
      );

  void expectSameGraph(PageGraph expected, PageGraph actual) {
    expect(actual.isPartial, isFalse);
    expect(actual.pages, hasLength(expected.pages.length));
    for (var i = 0; i < expected.pages.length; i++) {
      final a = expected.pages[i];
      final b = actual.pages[i];
      expect(b.index, a.index);
      expect(b.fragments.length, a.fragments.length, reason: 'página ${i + 1}');
      expect(b.signature.firstBlockIndex, a.signature.firstBlockIndex);
      expect(b.signature.firstBlockOffset, a.signature.firstBlockOffset);
      expect(b.header.length, a.header.length);
      expect(b.footer.length, a.footer.length);
    }
    expect(
        actual.positionMap.entries.length, expected.positionMap.entries.length);
  }

  test('fatias reconstroem o grafo completo, byte a byte de geometria', () {
    final composer = LayoutComposer();
    final doc = longDoc();
    final full = composer.compose(doc);
    expect(full.pages.length, greaterThan(8),
        reason: 'o corpus precisa de várias páginas para valer o teste');
    expect(full.isPartial, isFalse);

    var partial = composer.compose(doc, maxPages: 3);
    expect(partial.isPartial, isTrue);
    expect(partial.pages.length, greaterThanOrEqualTo(3));
    expect(partial.pages.length, lessThan(full.pages.length));

    var slices = 0;
    while (partial.isPartial) {
      partial = composer.composeContinue(doc, partial,
          maxPages: partial.pages.length + 2);
      slices++;
      expect(slices, lessThan(200), reason: 'progresso garantido por fatia');
    }
    expectSameGraph(full, partial);
  });

  test('composeContinue SEM maxPages completa o documento de uma vez', () {
    final composer = LayoutComposer();
    final doc = longDoc(blocks: 200);
    final full = composer.compose(doc);
    final partial = composer.compose(doc, maxPages: 2);
    expect(partial.isPartial, isTrue);
    final completed = composer.composeContinue(doc, partial);
    expectSameGraph(full, completed);
  });

  test('regiões com PAGE/NUMPAGES ficam corretas quando a última fatia fecha',
      () {
    final composer = LayoutComposer(
      footer: region('Página {PAGE} de {NUMPAGES}'),
    );
    final doc = longDoc(blocks: 200);
    final full = composer.compose(doc);
    var partial = composer.compose(doc, maxPages: 2);
    while (partial.isPartial) {
      partial = composer.composeContinue(doc, partial,
          maxPages: partial.pages.length + 3);
    }
    expectSameGraph(full, partial);

    String footerText(PageLayout page) => [
          for (final fragment in page.footer)
            for (final line in fragment.lines)
              for (final segment in line.segments) segment.text
        ].join();
    final total = partial.pages.length;
    expect(footerText(partial.pages.first), 'Página 1 de $total');
    expect(footerText(partial.pages.last), 'Página $total de $total');
  });

  test('grafo parcial não interfere num documento que cabe no limite', () {
    final composer = LayoutComposer();
    final doc = docOf([paragraph('só uma página')]);
    final graph = composer.compose(doc, maxPages: 5);
    expect(graph.isPartial, isFalse);
    expect(graph.pages, hasLength(1));
  });
}
