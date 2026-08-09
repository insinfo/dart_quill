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

  group('parser OOXML', () {
    test('preserva startOverride sem exigir um w:lvl duplicado', () {
      const xml = '''
<w:numbering xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:abstractNum w:abstractNumId="10">
    <w:lvl w:ilvl="1">
      <w:start w:val="7"/>
      <w:numFmt w:val="decimal"/>
      <w:lvlText w:val="%1.%2."/>
    </w:lvl>
    <w:lvl w:ilvl="2">
      <w:start w:val="1"/>
      <w:numFmt w:val="lowerLetter"/>
      <w:lvlText w:val="%1.%2.%3."/>
    </w:lvl>
  </w:abstractNum>
  <w:num w:numId="12">
    <w:abstractNumId w:val="10"/>
    <w:lvlOverride w:ilvl="1">
      <w:startOverride w:val="4"/>
    </w:lvlOverride>
    <w:lvlOverride w:ilvl="2">
      <w:lvl>
        <w:start w:val="3"/>
        <w:numFmt w:val="upperRoman"/>
        <w:lvlText w:val="%1.%2.%3."/>
      </w:lvl>
    </w:lvlOverride>
  </w:num>
</w:numbering>
''';

      final numbering = WpNumbering.parse(xml);
      expect(numbering.nums[12]!.startOverrides, {1: 4});
      expect(numbering.levelOf(12, 1)!.start, 4);
      expect(numbering.levelOf(12, 2)!.ilvl, 2,
          reason: 'w:lvlOverride/@w:ilvl é a chave autoritativa');
      expect(numbering.levelOf(12, 2)!.numFmt, 'upperRoman');
    });

    test('w:suff é preservado e ausência usa o default tab', () {
      const xml = '''
<w:numbering xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:abstractNum w:abstractNumId="1">
    <w:lvl w:ilvl="0"><w:suff w:val="nothing"/></w:lvl>
    <w:lvl w:ilvl="1"><w:suff w:val="space"/></w:lvl>
    <w:lvl w:ilvl="2"/>
  </w:abstractNum>
  <w:num w:numId="7"><w:abstractNumId w:val="1"/></w:num>
</w:numbering>
''';
      final numbering = WpNumbering.parse(xml);
      expect(numbering.levelOf(7, 0)!.suffix, 'nothing');
      expect(numbering.levelOf(7, 1)!.suffix, 'space');
      expect(numbering.levelOf(7, 2)!.suffix, 'tab');
    });
  });

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

    test('startOverride reinicia filho preservando o pai compartilhado', () {
      final numbering = WpNumbering(
        abstractNums: {
          10: WpAbstractNum(id: 10, levels: {
            0: const WpNumberingLevel(ilvl: 0, lvlText: '%1.'),
            1: const WpNumberingLevel(ilvl: 1, lvlText: '%1.%2.'),
            2: const WpNumberingLevel(ilvl: 2, lvlText: '%1.%2.%3.'),
          }),
        },
        nums: {
          11: const WpNum(numId: 11, abstractNumId: 10),
          12: const WpNum(
            numId: 12,
            abstractNumId: 10,
            startOverrides: {0: 1, 1: 1, 2: 1},
          ),
        },
      );
      final counter = OfficeNumberingCounter(numbering);
      for (var i = 1; i <= 8; i++) {
        expect(counter.labelFor(numbered(11, 0)), '$i. ');
      }
      expect(counter.labelFor(numbered(11, 1)), '8.1. ');
      expect(counter.labelFor(numbered(11, 1)), '8.2. ');
      expect(counter.labelFor(numbered(11, 1)), '8.3. ');

      expect(counter.labelFor(numbered(12, 1)), '8.1. ');
      expect(counter.labelFor(numbered(11, 1)), '8.2. ');
      expect(counter.labelFor(numbered(11, 2)), '8.2.1. ');
      expect(counter.labelFor(numbered(11, 2)), '8.2.2. ');
      expect(counter.labelFor(numbered(11, 1)), '8.3. ');
    });

    test('lvlRestart zero mantém o contador do nível profundo', () {
      final numbering = WpNumbering(
        abstractNums: {
          1: WpAbstractNum(id: 1, levels: {
            0: const WpNumberingLevel(ilvl: 0, lvlText: '%1.'),
            1: const WpNumberingLevel(ilvl: 1, lvlText: '%1.%2.'),
            2: const WpNumberingLevel(
              ilvl: 2,
              lvlText: '%1.%2.%3.',
              restart: 0,
            ),
          }),
        },
        nums: {7: const WpNum(numId: 7, abstractNumId: 1)},
      );
      final counter = OfficeNumberingCounter(numbering);
      expect(counter.labelFor(numbered(7, 0)), '1. ');
      expect(counter.labelFor(numbered(7, 1)), '1.1. ');
      expect(counter.labelFor(numbered(7, 2)), '1.1.1. ');
      expect(counter.labelFor(numbered(7, 1)), '1.2. ');
      expect(counter.labelFor(numbered(7, 2)), '1.2.2. ');
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
      expect(OfficeNumberingCounter(numbering).labelFor(numbered(7, 0)), '• ');
    });

    test('bullet de Symbol/Wingdings vira Unicode, não quadrado tofu', () {
      final numbering = WpNumbering(
        abstractNums: {
          1: WpAbstractNum(id: 1, levels: {
            0: WpNumberingLevel(ilvl: 0, numFmt: 'bullet', lvlText: '\uF0B7'),
          })
        },
        nums: {7: WpNum(numId: 7, abstractNumId: 1)},
      );
      expect(OfficeNumberingCounter(numbering).labelFor(numbered(7, 0)), '• ');
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

    final trCandidates = Directory('resources').existsSync()
        ? Directory('resources')
            .listSync()
            .whereType<File>()
            .where((file) =>
                file.path.contains('_TR_') && file.path.endsWith('.docx'))
            .toList()
        : <File>[];

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

    test('TR mantém a sequência Word exata ao redor da página 31', () {
      if (trCandidates.isEmpty) return;
      final imported = OfficeDocxCodec().import(
        Uint8List.fromList(trCandidates.single.readAsBytesSync()),
        includePackageResources: false,
      );
      final doc = PMNode.fromJSON(schema, imported.snapshot.body);
      final markers = <String, String>{};
      final targetIds = <String, String>{};
      doc.descendants((node, position, parent, index) {
        final id = officeNodeId(node);
        final style = node.attrs['style'];
        if (id != null && style is Map && style['marker'] is String) {
          markers[id] = style['marker'] as String;
          if (node.textContent.startsWith('As fases de apresentação não')) {
            targetIds['4.81.10'] = id;
            expect(style['marker'], '4.81.10. ');
            expect(style['markerSuffix'], 'tab');
          } else if (node.textContent
              .startsWith('A ordem de apresentação dos módulos')) {
            targetIds['4.81.11'] = id;
            expect(style['marker'], '4.81.11. ');
            expect(style['markerSuffix'], 'tab');
          }
        }
        return true;
      });

      expect(
        {
          for (final id in ['b448', 'b450', 'b452', 'b453', 'b454', 'b455'])
            id: markers[id],
        },
        {
          'b448': '8.3. ',
          'b450': '8.1. ',
          'b452': '8.2. ',
          'b453': '8.2.1. ',
          'b454': '8.2.2. ',
          'b455': '8.3. ',
        },
      );

      expect(targetIds.keys, containsAll(<String>['4.81.10', '4.81.11']));
      final graph = LayoutComposer().compose(doc);
      final targetFragments = <String, BlockFragment>{};
      for (final fragment in graph.pages
          .expand((page) => page.fragments)
          .whereType<BlockFragment>()) {
        for (final entry in targetIds.entries) {
          if (fragment.nodeId == entry.value &&
              !targetFragments.containsKey(entry.key)) {
            targetFragments[entry.key] = fragment;
          }
        }
      }
      for (final marker in targetIds.keys) {
        expect(
          targetFragments[marker]!.lines.first.indentTwips,
          1416,
          reason: '$marker cruza o primeiro tab e deve iniciar o texto no '
              'segundo, sem colar número e palavra',
        );
      }
    });
  });
}
