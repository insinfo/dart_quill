/// P13 — tabela aninhada numa célula.
///
/// O Delta do quill-table-better é plano (não expressa aninhamento), mas o
/// modelo office expressa — uma importação de DOCX produz células com
/// tabelas dentro. O exportador PULAVA a tabela interna com um aviso; agora
/// ela desenha dentro da célula, que cresce para acomodá-la.
@TestOn('vm')
library;

import 'package:dart_quill/dart_quill_pdf.dart';
import 'package:dart_quill/src/office/editor/dataset/enum/element.dart';
import 'package:dart_quill/src/office/editor/dataset/enum/table/table.dart';
import 'package:dart_quill/src/office/editor/interface/element.dart';
import 'package:dart_quill/src/office/editor/interface/table/td.dart';
import 'package:test/test.dart';

import '../../support/pdf_reader.dart';

void main() {
  IElement makeTable(List<List<List<IElement>>> cells, double columnWidth) =>
      IElement(
        type: ElementType.table,
        value: '',
        colgroup: [
          for (int c = 0; c < cells.first.length; c++)
            IColgroup(width: columnWidth),
        ],
        trList: [
          for (final row in cells)
            ITr(height: 42, minHeight: 16, tdList: [
              for (final cell in row)
                ITd(colspan: 1, rowspan: 1, value: cell),
            ]),
        ],
        borderType: TableBorder.all,
      );

  test('tabela aninhada desenha dentro da célula, sem aviso', () {
    final inner = makeTable([
      [
        [IElement(value: 'interna A')],
        [IElement(value: 'interna B')],
      ],
    ], 100);
    final outer = makeTable([
      [
        [IElement(value: 'antes'), IElement(value: '\n'), inner],
        [IElement(value: 'vizinha')],
      ],
    ], 300);

    final result = elementsToPdfWithReport([outer]);
    expect(
        result.warnings.where((w) => w.contains('aninhada')), isEmpty,
        reason: 'a tabela interna não pode mais ser pulada: '
            '${result.warnings}');

    final streams = PdfReader(result.bytes).decodedStreams.join('\n');
    // Moldura: 2 células externas + 2 internas = 4 retângulos contornados.
    final rects = RegExp(r'(?:[-\d.]+ ){4}re S').allMatches(streams).length;
    expect(rects, 4, reason: 'externas + internas: $streams');
    // O writer emite um Tj por palavra: procura palavra a palavra.
    for (final text in ['antes', 'interna', 'vizinha', '(A)', '(B)']) {
      expect(streams, contains(text),
          reason: 'o texto "$text" deve estar no PDF');
    }
  });

  test('a célula externa cresce para caber a tabela interna', () {
    IElement makeOuter(bool nested) => makeTable([
          [
            [
              IElement(value: 'x'),
              if (nested) IElement(value: '\n'),
              if (nested)
                makeTable([
                  for (int r = 0; r < 4; r++)
                    [
                      [IElement(value: 'linha $r')],
                    ],
                ], 120),
            ],
            [IElement(value: 'y')],
          ],
        ], 260);

    double outerHeight(bool nested) {
      final streams =
          PdfReader(elementsToPdfWithReport([makeOuter(nested)]).bytes)
              .decodedStreams
              .join('\n');
      // O maior retângulo é a célula externa.
      return RegExp(r'(?:[-\d.]+ ){3}([-\d.]+) re S')
          .allMatches(streams)
          .map((m) => double.parse(m.group(1)!))
          .reduce((a, b) => a > b ? a : b);
    }

    expect(outerHeight(true), greaterThan(outerHeight(false) + 4 * 16 - 1),
        reason: 'quatro linhas internas de no mínimo 16pt cabem na externa');
  });
}
