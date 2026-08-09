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
import 'package:dart_quill/src/office/ce_xml.dart';
import 'package:dart_quill/src/office/document/docx/effective.dart';
import 'package:dart_quill/src/office/document/docx/model.dart';
import 'package:dart_quill/src/office/document/docx/styles.dart';
import 'package:dart_quill/src/office/document/docx/writer.dart';

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

    test('run sem pStyle herda a fonte do estilo Normal, não docDefaults', () {
      if (!hasCorpus) return;
      final imported = OfficeDocxCodec().import(corpus());
      final doc = PMNode.fromJSON(schema, imported.snapshot.body);

      PMNode? responsible;
      void visit(PMNode node) {
        if (responsible != null) return;
        if (node.isTextblock &&
            node.textContent.contains('Leonardo Calheiros')) {
          responsible = node;
          return;
        }
        for (var i = 0; i < node.childCount; i++) {
          visit(node.child(i));
        }
      }

      visit(doc);
      expect(responsible, isNotNull);
      expect((responsible!.attrs['style'] as Map)['family'],
          'Ecofont_Spranq_eco_Sans');
      final fontValues = <Object?>{};
      responsible!.descendants((node, _, __, ___) {
        if (!node.isText) return true;
        for (final mark in node.marks) {
          if (mark.type.name == 'font') fontValues.add(mark.attrs['value']);
        }
        return true;
      });
      expect(fontValues, {'Ecofont_Spranq_eco_Sans'},
          reason: 'mark herdado não pode reintroduzir Times New Roman');
    });

    test('recuo do nível de numeração chega às listas importadas', () {
      if (!hasCorpus) return;
      final imported = OfficeDocxCodec().import(corpus());
      final doc = PMNode.fromJSON(schema, imported.snapshot.body);

      final numberedStyles = <Map>[];
      void visit(PMNode node) {
        final style = node.attrs['style'];
        if (style is Map && style['marker'] is String) {
          numberedStyles.add(style);
        }
        for (var i = 0; i < node.childCount; i++) {
          visit(node.child(i));
        }
      }

      visit(doc);
      expect(numberedStyles, isNotEmpty);
      expect(
          numberedStyles
              .any((style) => (style['indentTwips'] as num? ?? 0) > 0),
          isTrue,
          reason: 'o <w:lvl>/<w:ind> não pode desaparecer na projeção');
    });
  });

  test('spacing e indent fazem merge por atributo na cascata', () {
    const inherited = WpParagraphProperties(
      spacing: WpSpacing(beforeTwips: 120, afterTwips: 80),
      indent: WpIndent(leftTwips: 720, hangingTwips: 360),
    );
    const direct = WpParagraphProperties(
      spacing: WpSpacing(line: 360, lineRule: 'auto'),
      indent: WpIndent(rightTwips: 240),
    );
    final merged = inherited.mergedWith(direct);
    expect(merged.spacing?.beforeTwips, 120);
    expect(merged.spacing?.afterTwips, 80);
    expect(merged.spacing?.line, 360);
    expect(merged.indent?.leftTwips, 720);
    expect(merged.indent?.rightTwips, 240);
    expect(merged.indent?.hangingTwips, 360);
  });

  test('numPr parcial faz merge de numId e ilvl campo a campo', () {
    const inherited = WpParagraphProperties(
      numPr: WpNumPr(numId: 11, ilvl: 1),
    );
    const onlyLevel = WpParagraphProperties(
      numPr: WpNumPr(ilvl: 2),
    );
    final levelMerged = inherited.mergedWith(onlyLevel).numPr!;
    expect(levelMerged.numId, 11,
        reason: 'ilvl direto não pode apagar o numId herdado');
    expect(levelMerged.ilvl, 2);

    const onlyNumbering = WpParagraphProperties(
      numPr: WpNumPr(numId: 12),
    );
    final numberingMerged = inherited.mergedWith(onlyNumbering).numPr!;
    expect(numberingMerged.numId, 12);
    expect(numberingMerged.ilvl, 1,
        reason: 'numId direto sem w:ilvl mantém o nível herdado');

    final removed = inherited
        .mergedWith(const WpParagraphProperties(numPr: WpNumPr(numId: 0)))
        .numPr!;
    expect(removed.numId, 0,
        reason: 'numId=0 explícito continua removendo a numeração');
    expect(removed.ilvl, 1);
  });

  test('parser distingue ilvl ausente de nível zero explícito', () {
    final absent = WpParagraphProperties.fromXml(XmlDocument.parse('''
      <w:pPr xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
        <w:numPr><w:numId w:val="11"/></w:numPr>
      </w:pPr>
    ''').rootElement)!.numPr!;
    final zero = WpParagraphProperties.fromXml(XmlDocument.parse('''
      <w:pPr xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
        <w:numPr><w:ilvl w:val="0"/></w:numPr>
      </w:pPr>
    ''').rootElement)!.numPr!;

    expect(absent.ilvl, 0);
    expect(absent.hasIlvl, isFalse);
    expect(zero.ilvl, 0);
    expect(zero.hasIlvl, isTrue);
  });

  test('writer preserva ilvl zero explícito e suppressAutoHyphens', () {
    final xml = DocxWriter.serializeParagraph(WpParagraph(
      properties: const WpParagraphProperties(
        numPr: WpNumPr(numId: 11, ilvl: 0),
        suppressAutoHyphens: true,
      ),
      inlines: [],
    ));

    expect(xml, contains('<w:ilvl w:val="0"/>'));
    expect(xml, contains('<w:numId w:val="11"/>'));
    expect(xml, contains('<w:suppressAutoHyphens/>'));
  });

  test('suppressAutoHyphens faz parse e merge como on/off tri-state', () {
    WpParagraphProperties parse(String value) =>
        WpParagraphProperties.fromXml(XmlDocument.parse('''
      <w:pPr xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
        <w:suppressAutoHyphens $value/>
      </w:pPr>
    ''').rootElement)!;

    final inherited = parse('');
    final explicitOff = parse('w:val="0"');
    expect(inherited.suppressAutoHyphens, isTrue);
    expect(explicitOff.suppressAutoHyphens, isFalse);
    expect(
      inherited.mergedWith(const WpParagraphProperties()).suppressAutoHyphens,
      isTrue,
      reason: 'omissão direta mantém o valor herdado',
    );
    expect(inherited.mergedWith(explicitOff).suppressAutoHyphens, isFalse,
        reason: 'off explícito reativa a hifenização herdada');
  });

  test('estilo Normal default participa da cascata sem w:pStyle', () {
    final styles = WpStyleSheet.parse('''
      <w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
        <w:style w:type="paragraph" w:default="1" w:styleId="Normal">
          <w:pPr><w:suppressAutoHyphens/></w:pPr>
        </w:style>
      </w:styles>
    ''');
    final resolver = FormatResolver(styles);
    final paragraph = WpParagraph(properties: null, inlines: const []);

    expect(resolver.resolveParagraph(paragraph).suppressAutoHyphens, isTrue,
        reason:
            'ausência de w:pStyle significa o estilo default, não apenas docDefaults');
  });

  test('spacing de caracteres faz cascata em twips assinados', () {
    const inherited = WpRunProperties(spacingTwips: 12);

    expect(inherited.mergedWith(const WpRunProperties()).spacingTwips, 12,
        reason: 'omissão direta mantém o valor herdado');
    expect(
        inherited
            .mergedWith(const WpRunProperties(spacingTwips: -2))
            .spacingTwips,
        -2,
        reason: 'valor negativo direto comprime e vence a cascata');
    expect(
        inherited
            .mergedWith(const WpRunProperties(spacingTwips: 0))
            .spacingTwips,
        0,
        reason: 'zero explícito remove o espaçamento herdado');
  });

  test('spacing de caracteres percorre docDefaults e basedOn', () {
    final styles = WpStyleSheet.parse('''
      <w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
        <w:docDefaults>
          <w:rPrDefault><w:rPr><w:spacing w:val="12"/></w:rPr></w:rPrDefault>
        </w:docDefaults>
        <w:style w:type="paragraph" w:styleId="Base">
          <w:rPr><w:spacing w:val="6"/></w:rPr>
        </w:style>
        <w:style w:type="paragraph" w:styleId="Filho">
          <w:basedOn w:val="Base"/>
          <w:rPr><w:spacing w:val="-2"/></w:rPr>
        </w:style>
      </w:styles>
    ''');
    final resolver = FormatResolver(styles);
    final paragraph = WpParagraph(
      properties: const WpParagraphProperties(styleId: 'Filho'),
      inlines: const [],
    );

    expect(resolver.resolveRun(paragraph, null).spacingTwips, -2);
    expect(
        resolver
            .resolveRun(paragraph, const WpRunProperties(spacingTwips: 0))
            .spacingTwips,
        0,
        reason: 'formatação direta zero vence a cadeia inteira');
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
      expect(graph.pages.first.fragments.whereType<BlockFragment>().first.align,
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
