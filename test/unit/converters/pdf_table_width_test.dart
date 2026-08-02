/// P12 — cascata de larguras de tabela: uma tabela colada do Word não traz
/// NENHUM `table-col`; as larguras reais moram nas células e no style da
/// âncora `table-temporary` (px/pt ou %). Antes o exportador dividia a área
/// útil em partes iguais e a tabela saía deformada.
@TestOn('vm')
library;

import 'dart:typed_data';

import 'package:dart_quill/dart_quill_pdf.dart';
import 'package:dart_quill/src/delta/delta.dart';
import 'package:dart_quill/src/office/word/quill_delta.dart';
import 'package:dart_quill/src/office/editor/dataset/enum/element.dart';
import 'package:dart_quill/src/office/editor/interface/element.dart';
import 'package:test/test.dart';

import '../../support/pdf_reader.dart';

void main() {
  Map<String, dynamic> ops(String anchorStyle,
          {List<String> cellWidths = const ['100', '200']}) =>
      {
        'ops': [
          {
            'insert': '\n',
            'attributes': {
              'table-temporary': {
                'data-class': 'ql-table-better',
                'style': anchorStyle,
              }
            }
          },
          for (int i = 0; i < cellWidths.length; i++) ...[
            {'insert': 'c$i'},
            {
              'insert': '\n',
              'attributes': {
                'table-cell-block': 'cell$i',
                'table-cell': {'data-row': 'r1', 'width': cellWidths[i]},
              }
            },
          ],
        ]
      };

  IElement tableOf(Map<String, dynamic> delta) =>
      QuillDeltaConverter.fromDelta(delta)
          .firstWhere((e) => e.type == ElementType.table);

  List<double> colWidths(IElement table) =>
      [for (final col in table.colgroup!) col.width];

  test('sem table-col, as larguras vêm das células', () {
    final table = tableOf(ops('border-collapse: collapse;'));
    expect(colWidths(table), [100, 200]);
  });

  test('a âncora em px reescala a soma das colunas', () {
    // As células somam 300, mas o Word declara 150px na tabela: a proporção
    // das células fica, a soma obedece a âncora.
    final table =
        tableOf(ops('border-collapse: collapse; width: 150px;'));
    expect(colWidths(table), [50, 100]);
  });

  test('a âncora em pt converte para px antes de reescalar', () {
    // 225pt = 300px: escala 1, larguras intactas.
    final table = tableOf(ops('margin-left: -20.45pt; width: 225.0pt;'));
    expect(colWidths(table), [100, 200]);
  });

  test('a âncora em % não resolve no conversor: viaja no extension', () {
    final table = tableOf(
        ops('width:100.0%;border-collapse:collapse;border:none'));
    expect(table.extension?['tableWidthPercent'], 100.0);
    expect(colWidths(table), [100, 200]);
  });

  test('tabela 100% ocupa a área útil inteira do PDF', () {
    final delta = Delta();
    for (final op in (ops('width:100.0%;', cellWidths: ['100', '100'])['ops']
        as List)) {
      final map = op as Map<String, dynamic>;
      delta.insert(map['insert'], map['attributes'] as Map<String, dynamic>?);
    }
    delta.insert('\n');
    final Uint8List pdf = deltaToPdf(delta);
    final streams = PdfReader(pdf).decodedStreams.join('\n');
    final widths = RegExp(r'(?:[-\d.]+ ){2}([-\d.]+) [-\d.]+ re S')
        .allMatches(streams)
        .map((m) => double.parse(m.group(1)!))
        .toList();
    expect(widths, isNotEmpty);
    // A4 com margem de 2cm: área útil = 595.28 - 2×56.69 ≈ 481.9pt; cada
    // uma das duas células iguais fica com a metade.
    final double half = widths.reduce((a, b) => a > b ? a : b);
    expect(half, closeTo(481.9 / 2, 2.0),
        reason: 'a célula deve ocupar metade da área útil: $widths');
  });

  test('células com colspan não roubam a largura da coluna', () {
    final delta = {
      'ops': [
        {
          'insert': '\n',
          'attributes': {
            'table-temporary': {'data-class': 'ql-table-better', 'style': ''}
          }
        },
        {'insert': 'todo'},
        {
          'insert': '\n',
          'attributes': {
            'table-cell-block': 'a1',
            'table-cell': {'data-row': 'r1', 'width': '300', 'colspan': '2'},
          }
        },
        {'insert': 'x'},
        {
          'insert': '\n',
          'attributes': {
            'table-cell-block': 'b1',
            'table-cell': {'data-row': 'r2', 'width': '100'},
          }
        },
        {'insert': 'y'},
        {
          'insert': '\n',
          'attributes': {
            'table-cell-block': 'b2',
            'table-cell': {'data-row': 'r2', 'width': '200'},
          }
        },
      ]
    };
    // A célula mesclada (colspan 2, largura 300) não define coluna nenhuma;
    // a segunda linha, com células simples, é quem define 100 e 200.
    expect(colWidths(tableOf(delta)), [100, 200]);
  });
}
