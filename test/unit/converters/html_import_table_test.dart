/// H6 — HTML→Delta de tabelas: a célula era achatada para `cell.text` com um
/// bold único — links, cores, itálico parcial e múltiplos parágrafos se
/// perdiam; `<colgroup>` não virava `table-col`; o `data-row` era reindexado
/// (round-trip instável) e `rowspan` não deslocava o índice das colunas.
@TestOn('vm')
library;

import 'package:dart_quill/dart_quill_html.dart';
import 'package:test/test.dart';

void main() {
  List<Map<String, dynamic>> opsOf(String html) => htmlToDelta(html)
      .toJson()
      .map((op) => (op as Map).cast<String, dynamic>())
      .toList();

  Map<String, dynamic>? attrsOf(Map<String, dynamic> op) =>
      (op['attributes'] as Map?)?.cast<String, dynamic>();

  test('formatação parcial dentro da célula sobrevive', () {
    final ops = opsOf('<table><tr><td>texto <b>negrito</b> e '
        '<a href="https://exemplo.gov.br">link</a></td></tr></table>');
    final bold = ops.firstWhere((op) => op['insert'] == 'negrito');
    expect(attrsOf(bold)?['bold'], isTrue,
        reason: 'o negrito PARCIAL não pode contaminar a célula toda: $ops');
    final plain = ops.firstWhere((op) => op['insert'] == 'texto ');
    expect(attrsOf(plain)?['bold'], isNull);
    final link = ops.firstWhere((op) => op['insert'] == 'link');
    expect(attrsOf(link)?['link'], 'https://exemplo.gov.br');
  });

  test('múltiplos parágrafos viram linhas da MESMA célula', () {
    final ops = opsOf(
        '<table><tr><td><p>primeiro</p><p>segundo</p></td></tr></table>');
    final cellLines = ops
        .where((op) =>
            op['insert'] == '\n' &&
            attrsOf(op)?.containsKey('table-cell-block') == true)
        .toList();
    expect(cellLines, hasLength(2),
        reason: 'cada parágrafo é uma linha da célula: $ops');
    expect(attrsOf(cellLines[0])?['table-cell-block'],
        attrsOf(cellLines[1])?['table-cell-block'],
        reason: 'o mesmo id de célula agrupa as duas linhas');
  });

  test('<colgroup> vira ops table-col', () {
    final ops = opsOf('<table><colgroup><col width="100"><col width="250">'
        '</colgroup><tr><td>x</td><td>y</td></tr></table>');
    final cols = ops
        .where((op) => attrsOf(op)?.containsKey('table-col') == true)
        .map((op) => (attrsOf(op)!['table-col'] as Map)['width'])
        .toList();
    expect(cols, ['100', '250'],
        reason: 'as larguras de coluna têm de voltar ao Delta: $ops');
  });

  test('data-row e data-cell do export voltam intactos (round-trip)', () {
    final ops = opsOf('<table><tr data-row="row-is10">'
        '<td data-cell="cell-7">a</td></tr></table>');
    final line = ops.firstWhere(
        (op) => attrsOf(op)?.containsKey('table-cell') == true);
    expect((attrsOf(line)!['table-cell'] as Map)['data-row'], 'row-is10',
        reason: 'o id opaco não pode ser reindexado');
    expect(attrsOf(line)!['table-cell-block'], 'cell-7');
  });

  test('rowspan desloca o índice de coluna da linha seguinte', () {
    // A célula "b2" da segunda linha é a SEGUNDA coluna: a primeira está
    // ocupada pela mescla de "a1".
    final ops = opsOf('<table>'
        '<tr><td rowspan="2">a1</td><td>b1</td></tr>'
        '<tr><td>b2</td></tr>'
        '</table>');
    final lines = ops
        .where((op) => attrsOf(op)?.containsKey('table-cell-block') == true)
        .toList();
    expect(lines, hasLength(3));
    expect(attrsOf(lines[2])!['table-cell-block'], '2',
        reason: 'sem a grade de ocupação o índice escorregava para 1: $ops');
  });

  test('export → import → export estabiliza (round-trip de verdade)', () {
    final ops = <dynamic>[
      {
        'insert': '\n',
        'attributes': {
          'table-temporary': {'data-class': 'ql-table-better'}
        },
      },
      {'insert': 'a'},
      {
        'insert': '\n',
        'attributes': {
          'table-cell-block': 'cell-1',
          'table-cell': {'data-row': 'row-is10'},
        },
      },
      {'insert': '\n'},
    ];
    // O primeiro ciclo pode normalizar defaults (border, cellspacing); o que
    // não pode é DERIVAR: a partir do segundo ciclo o HTML é ponto fixo —
    // sem isso cada salvar-e-abrir mudava o documento um pouco.
    final html1 = opsToHtml(ops);
    final html2 = opsToHtml(htmlToDelta(html1).toJson());
    final html3 = opsToHtml(htmlToDelta(html2).toJson());
    expect(html3, html2,
        reason: 'reimportar o próprio export tem de estabilizar');
    expect(html2, contains('data-row="row-is10"'),
        reason: 'o id opaco sobrevive ao ciclo');
    expect(html2, contains('data-cell="cell-1"'));
  });
}
