/// Fase 4 — numeração multinível.
///
/// Num DOCX, "1.1 Objeto" NÃO tem o "1.1" no texto: o Word o calcula de
/// `numbering.xml`. Sem resolver isso, todo documento administrativo
/// importado perde a numeração das seções — e o PDF assinado sai sem ela.
@TestOn('vm')
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:test/test.dart';

import 'package:dart_quill/dart_quill_office.dart';
import 'package:dart_quill/src/office/document/docx/model.dart';
import 'package:dart_quill/src/office/document/docx/numbering.dart';

void main() {
  final schema = officeQuillSchema();

  WpParagraph numbered(int numId, int ilvl) => WpParagraph(
      properties:
          WpParagraphProperties(numPr: WpNumPr(numId: numId, ilvl: ilvl)),
      inlines: [
        WpRun(content: [WpText('texto')])
      ]);

  WpNumbering multilevel({String format = 'decimal'}) => WpNumbering(
        abstractNums: {
          1: WpAbstractNum(id: 1, levels: {
            0: WpNumberingLevel(ilvl: 0, numFmt: format, lvlText: '%1.'),
            1: WpNumberingLevel(ilvl: 1, numFmt: format, lvlText: '%1.%2.'),
            2: WpNumberingLevel(ilvl: 2, numFmt: format, lvlText: '%1.%2.%3.'),
          })
        },
        nums: {7: WpNum(numId: 7, abstractNumId: 1)},
      );

  group('contador', () {
    test('sequência simples avança', () {
      final counter = OfficeNumberingCounter(multilevel());
      expect(counter.labelFor(numbered(7, 0)), '1. ');
      expect(counter.labelFor(numbered(7, 0)), '2. ');
      expect(counter.labelFor(numbered(7, 0)), '3. ');
    });

    test('nível profundo compõe com o superior', () {
      final counter = OfficeNumberingCounter(multilevel());
      expect(counter.labelFor(numbered(7, 0)), '1. ');
      expect(counter.labelFor(numbered(7, 1)), '1.1. ');
      expect(counter.labelFor(numbered(7, 1)), '1.2. ');
      expect(counter.labelFor(numbered(7, 2)), '1.2.1. ');
    });

    test('o nível profundo REINICIA quando o superior avança', () {
      final counter = OfficeNumberingCounter(multilevel());
      counter.labelFor(numbered(7, 0)); // 1.
      counter.labelFor(numbered(7, 1)); // 1.1.
      counter.labelFor(numbered(7, 1)); // 1.2.
      expect(counter.labelFor(numbered(7, 0)), '2. ');
      expect(counter.labelFor(numbered(7, 1)), '2.1. ',
          reason: 'sem reiniciar sairia 2.3 — o erro clássico de numeração');
    });

    test('parágrafo sem numeração não tem rótulo', () {
      final counter = OfficeNumberingCounter(multilevel());
      expect(counter.labelFor(WpParagraph(inlines: [])), isNull);
    });

    test('numId 0 REMOVE a numeração herdada, não usa a lista zero', () {
      final counter = OfficeNumberingCounter(multilevel());
      expect(counter.labelFor(numbered(0, 0)), isNull);
    });

    test('listas diferentes têm contadores independentes', () {
      final numbering = WpNumbering(
        abstractNums: {
          1: WpAbstractNum(id: 1, levels: {
            0: WpNumberingLevel(ilvl: 0, lvlText: '%1.'),
          })
        },
        nums: {
          7: WpNum(numId: 7, abstractNumId: 1),
          8: WpNum(numId: 8, abstractNumId: 1),
        },
      );
      final counter = OfficeNumberingCounter(numbering);
      expect(counter.labelFor(numbered(7, 0)), '1. ');
      expect(counter.labelFor(numbered(8, 0)), '1. ');
      expect(counter.labelFor(numbered(7, 0)), '2. ');
    });

    test('start diferente de 1 é respeitado', () {
      final numbering = WpNumbering(
        abstractNums: {
          1: WpAbstractNum(id: 1, levels: {
            0: WpNumberingLevel(ilvl: 0, start: 5, lvlText: '%1.'),
          })
        },
        nums: {7: WpNum(numId: 7, abstractNumId: 1)},
      );
      expect(OfficeNumberingCounter(numbering).labelFor(numbered(7, 0)), '5. ');
    });

    test('bullet usa o próprio lvlText', () {
      final numbering = WpNumbering(
        abstractNums: {
          1: WpAbstractNum(id: 1, levels: {
            0: WpNumberingLevel(ilvl: 0, numFmt: 'bullet', lvlText: '•'),
          })
        },
        nums: {7: WpNum(numId: 7, abstractNumId: 1)},
      );
      expect(
          OfficeNumberingCounter(numbering).labelFor(numbered(7, 0)), '• ');
    });
  });

  group('formatos', () {
    test('romano e letra seguem o esquema do Word', () {
      expect(OfficeNumberingCounter.formatNumber(4, 'upperRoman'), 'IV');
      expect(OfficeNumberingCounter.formatNumber(9, 'lowerRoman'), 'ix');
      expect(OfficeNumberingCounter.formatNumber(1, 'upperLetter'), 'A');
      expect(OfficeNumberingCounter.formatNumber(26, 'lowerLetter'), 'z');
      // O Word REPETE a letra em vez de usar base 26 posicional.
      expect(OfficeNumberingCounter.formatNumber(27, 'upperLetter'), 'AA');
      expect(OfficeNumberingCounter.formatNumber(5, 'decimalZero'), '05');
    });

    test('formato desconhecido cai em decimal em vez de sumir', () {
      expect(OfficeNumberingCounter.formatNumber(3, 'ideographDigital'), '3');
    });
  });

  group('no documento importado', () {
    final etpPath = 'test/assets/docx/etp_corpus.docx';
    final hasCorpus = File(etpPath).existsSync();
    Uint8List corpus() => File(etpPath).readAsBytesSync();

    test('o rótulo vira MARCADOR, não texto do documento', () {
      if (!hasCorpus) return;
      final imported = OfficeDocxCodec().import(corpus());
      final doc = PMNode.fromJSON(schema, imported.snapshot.body);

      for (var i = 0; i < doc.childCount; i++) {
        final style = doc.child(i).attrs['style'];
        if (style is! Map || style['marker'] is! String) continue;
        final marker = (style['marker'] as String).trim();
        if (marker.isEmpty) continue;
        expect(doc.child(i).textContent, isNot(startsWith(marker)),
            reason: 'se o rótulo virasse texto, editar corromperia e salvar '
                'gravaria o número por cima da numeração automática');
      }
    });

    test('o marcador resolvido chega ao layout', () {
      final doc = schema.node(
          'doc',
          null,
          Fragment.from([
            schema.node(
                'paragraph',
                {
                  'style': {'sizePt': 12.0, 'marker': '1.1. '}
                },
                Fragment.from([schema.text('Objeto')]))
          ]));
      final graph = LayoutComposer().compose(doc);
      expect(
          graph.pages.first.fragments.whereType<BlockFragment>().first.marker,
          '1.1. ');
    });
  });
}
