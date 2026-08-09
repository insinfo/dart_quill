/// Fase 4 — múltiplas seções.
///
/// Um documento com anexo em paisagem tem DUAS geometrias. Até aqui a
/// primeira governava tudo, então o anexo era paginado em retrato — na tela
/// E no PDF, porque os dois consomem o mesmo grafo.
///
/// A regra que decide a correção: no OOXML o `w:sectPr` fica no parágrafo
/// que TERMINA a seção, não no que começa a seguinte. Ler ao contrário
/// aplicaria a geometria errada ao documento inteiro.
@TestOn('vm')
library;

import 'package:test/test.dart';

import 'package:dart_quill/dart_quill_office.dart';

void main() {
  final schema = officeQuillSchema();

  PMNode paragraph(String text, {bool endsSection = false}) => schema.node(
      'paragraph',
      {
        if (endsSection) 'style': {'sizePt': 12.0, 'sectionBreak': true}
      },
      Fragment.from([schema.text(text)]));

  PMNode docOf(List<PMNode> blocks) =>
      schema.node('doc', null, Fragment.from(blocks));

  const portrait = PageSetupTwips();
  const landscape = PageSetupTwips(widthTwips: 16838, heightTwips: 11906);

  String filler(int i) =>
      'Parágrafo $i com texto suficiente para ocupar a linha inteira e '
      'forçar a paginação a trabalhar de verdade.';

  group('troca de geometria', () {
    test('sem seções declaradas, tudo usa o setup único', () {
      final graph = LayoutComposer()
          .compose(docOf([for (var i = 0; i < 80; i++) paragraph(filler(i))]));
      for (final page in graph.pages) {
        expect(page.setup.widthTwips, portrait.widthTwips);
      }
    });

    test('a seção seguinte muda o tamanho da página', () {
      final blocks = [
        for (var i = 0; i < 40; i++) paragraph(filler(i)),
        paragraph('fim da primeira seção', endsSection: true),
        for (var i = 0; i < 40; i++) paragraph(filler(i)),
      ];
      final graph = LayoutComposer(sections: const [portrait, landscape])
          .compose(docOf(blocks));

      expect(graph.pages.first.setup.widthTwips, portrait.widthTwips);
      expect(graph.pages.last.setup.widthTwips, landscape.widthTwips,
          reason: 'o anexo tem de sair em paisagem');
    });

    test('a quebra força página nova', () {
      final blocks = [
        paragraph('primeira seção, um parágrafo só', endsSection: true),
        for (var i = 0; i < 5; i++) paragraph(filler(i)),
      ];
      final graph = LayoutComposer(sections: const [portrait, landscape])
          .compose(docOf(blocks));

      expect(graph.pages.length, greaterThanOrEqualTo(2),
          reason: 'a seção nova não pode continuar na página da anterior');
      expect(graph.pages[0].setup.widthTwips, portrait.widthTwips);
      expect(graph.pages[1].setup.widthTwips, landscape.widthTwips);
    });

    test('o parágrafo da quebra pertence à geometria ANTIGA', () {
      // O sectPr descreve a seção que TERMINA nele.
      final blocks = [
        paragraph('último da seção 1', endsSection: true),
        paragraph('primeiro da seção 2'),
      ];
      final graph = LayoutComposer(sections: const [portrait, landscape])
          .compose(docOf(blocks));

      final firstPage = graph.pages.first;
      expect(firstPage.setup.widthTwips, portrait.widthTwips);
      expect(
          firstPage.fragments.whereType<BlockFragment>().any((f) => f.lines
              .expand((l) => l.segments)
              .any((s) => s.text.contains('último da seção 1'))),
          isTrue,
          reason: 'ele tem de ficar na página retrato, não na paisagem');
    });

    test('três seções encadeiam na ordem', () {
      const wide = PageSetupTwips(widthTwips: 20000, heightTwips: 11906);
      final blocks = [
        paragraph('s1', endsSection: true),
        paragraph('s2', endsSection: true),
        paragraph('s3'),
      ];
      final graph = LayoutComposer(sections: const [portrait, landscape, wide])
          .compose(docOf(blocks));

      expect(graph.pages.length, 3);
      expect(graph.pages[0].setup.widthTwips, portrait.widthTwips);
      expect(graph.pages[1].setup.widthTwips, landscape.widthTwips);
      expect(graph.pages[2].setup.widthTwips, wide.widthTwips);
    });

    test('mais quebras que geometrias não estoura', () {
      // Documento malformado ou seção que não declarou geometria: a última
      // conhecida continua valendo, em vez de a importação quebrar.
      final blocks = [
        paragraph('a', endsSection: true),
        paragraph('b', endsSection: true),
        paragraph('c', endsSection: true),
      ];
      final graph = LayoutComposer(sections: const [portrait, landscape])
          .compose(docOf(blocks));
      expect(graph.pages, isNotEmpty);
      expect(graph.pages.last.setup.widthTwips, landscape.widthTwips);
    });

    test('a área útil da seção governa a quebra de linha', () {
      // Paisagem é mais larga: o MESMO parágrafo ocupa menos linhas.
      final text = paragraph(filler(0) * 3);
      final tall = LayoutComposer(setup: portrait).compose(docOf([text]));
      final wide = LayoutComposer(setup: landscape).compose(docOf([text]));

      final tallLines = tall.pages.first.fragments
          .whereType<BlockFragment>()
          .first
          .lines
          .length;
      final wideLines = wide.pages.first.fragments
          .whereType<BlockFragment>()
          .first
          .lines
          .length;
      expect(wideLines, lessThan(tallLines));
    });
  });

  group('nas saídas', () {
    test('o PDF emite cada página no tamanho da SUA seção', () {
      final blocks = [
        paragraph('retrato', endsSection: true),
        paragraph('paisagem'),
      ];
      final graph = LayoutComposer(sections: const [portrait, landscape])
          .compose(docOf(blocks));
      final pdf = PageGraphPdfRenderer().render(graph);
      final raw = String.fromCharCodes(pdf);

      // MediaBox em pontos: 11906 twips = 595,3 pt; 16838 = 841,9 pt.
      expect(raw, contains('595'));
      expect(raw, contains('841'));
    });
  });
}
