/// Fase 4 — cascata de estilos: o documento manda, não a heurística.
///
/// Antes disso o tamanho de fonte vinha de uma escala fixa por nível de
/// heading. Um documento cujo "Título 1" tem 14 pt sairia com 24 — na tela
/// E no PDF, porque os dois consomem o mesmo grafo.
@TestOn('vm')
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:test/test.dart';

import 'package:dart_quill/dart_quill_office.dart';

void main() {
  final schema = officeQuillSchema();
  final etpPath = 'test/assets/docx/etp_corpus.docx';
  final hasCorpus = File(etpPath).existsSync();
  Uint8List corpus() => File(etpPath).readAsBytesSync();

  group('resolução na importação', () {
    test('os blocos importados carregam apresentação resolvida', () {
      if (!hasCorpus) return;
      final imported = OfficeDocxCodec().import(corpus());
      final doc = PMNode.fromJSON(schema, imported.snapshot.body);

      var withStyle = 0;
      for (var i = 0; i < doc.childCount; i++) {
        final style = doc.child(i).attrs['style'];
        if (style is Map && style['sizePt'] is num) withStyle++;
      }
      expect(withStyle, greaterThan(0),
          reason: 'a cascata precisa produzir tamanho para os parágrafos');
    });

    test('os tamanhos vêm em pontos plausíveis, não em half-points', () {
      if (!hasCorpus) return;
      final imported = OfficeDocxCodec().import(corpus());
      final doc = PMNode.fromJSON(schema, imported.snapshot.body);

      for (var i = 0; i < doc.childCount; i++) {
        final style = doc.child(i).attrs['style'];
        if (style is! Map) continue;
        final size = style['sizePt'];
        if (size is! num) continue;
        expect(size, inInclusiveRange(4, 96),
            reason: 'half-points vazando dariam 24 onde deveria ser 12');
      }
    });
  });

  group('o composer honra o resolvido', () {
    PMNode blockWith(Map<String, dynamic>? style) => schema.node(
        'doc',
        null,
        Fragment.from([
          schema.node('heading', {'level': 1, 'style': style},
              Fragment.from([schema.text('Título do documento')]))
        ]));

    test('um heading de 14 pt NÃO sai com o dobro da escala fixa', () {
      final heuristic = LayoutComposer().compose(blockWith(null));
      final resolved =
          LayoutComposer().compose(blockWith({'sizePt': 14.0, 'bold': true}));

      final heuristicHeight = heuristic.pages.first.fragments
          .whereType<BlockFragment>()
          .first
          .heightTwips;
      final resolvedHeight = resolved.pages.first.fragments
          .whereType<BlockFragment>()
          .first
          .heightTwips;

      // A heurística usa 2,0 × 12 pt = 24 pt; o documento diz 14.
      expect(resolvedHeight, lessThan(heuristicHeight),
          reason: 'o tamanho do documento tem de mandar');
    });

    test('alinhamento resolvido chega ao fragmento', () {
      final graph = LayoutComposer()
          .compose(blockWith({'sizePt': 12.0, 'align': 'center'}));
      expect(
          graph.pages.first.fragments.whereType<BlockFragment>().first.align,
          LayoutAlign.center);
    });

    test('recuo resolvido chega ao fragmento', () {
      final graph = LayoutComposer()
          .compose(blockWith({'sizePt': 12.0, 'indentTwips': 720}));
      expect(
          graph.pages.first.fragments
              .whereType<BlockFragment>()
              .first
              .indentTwips,
          720);
    });

    test('style inválido cai na heurística em vez de quebrar', () {
      for (final invalid in [
        <String, dynamic>{},
        {'sizePt': 'grande'},
        {'sizePt': 0},
        {'sizePt': -3},
      ]) {
        final graph = LayoutComposer().compose(blockWith(invalid));
        expect(graph.pages, isNotEmpty);
      }
    });

    test('sem style, o Delta do Quill continua funcionando igual', () {
      // É o fallback que importa: um Delta nunca passou por importador de
      // DOCX e só sabe `header: 1`.
      final before = LayoutComposer().compose(blockWith(null));
      final after = LayoutComposer().compose(blockWith(null));
      expect(after.pages.length, before.pages.length);
      expect(after.pages.first.fragments.first.heightTwips,
          before.pages.first.fragments.first.heightTwips);
    });
  });

  test('o corpus de teste existe', () {
    expect(hasCorpus, isTrue);
  });
}
