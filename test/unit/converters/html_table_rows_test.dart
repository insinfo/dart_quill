/// Regressão do agrupamento de linhas de tabela no Delta → HTML.
///
/// O id de linha (`data-row` no table-better, o valor do atributo `table` no
/// módulo core) é uma STRING opaca: tabelas criadas no editor usam ids como
/// `row-is10` (tableId()), e só conteúdo colado de HTML/Word traz `"1"`,`"2"`.
/// O conversor convertia o id para int — todo id não numérico virava 0/null e
/// a tabela inteira colapsava em um único `<tr>` (table-better) ou perdia os
/// `<tr>` por completo (table core).
library;

import 'package:dart_quill/dart_quill_html.dart';
import 'package:test/test.dart';

int countOf(String needle, String haystack) =>
    needle.allMatches(haystack).length;

Map<String, dynamic> cell(String text, String row, String block) => {
      'insert': '\n',
      'attributes': {
        'table-cell-block': block,
        'table-cell': {'data-row': row},
      },
    };

void main() {
  group('table-better: um <tr> por id distinto de data-row', () {
    test('ids de editor (row-xxxx) produzem duas linhas 2x2', () {
      final ops = <dynamic>[
        {
          'insert': '\n',
          'attributes': {
            'table-temporary': {'data-class': 'ql-table-better'}
          },
        },
        {'insert': 'a'},
        cell('a', 'row-is10', 'cell-1'),
        {'insert': 'b'},
        cell('b', 'row-is10', 'cell-2'),
        {'insert': 'c'},
        cell('c', 'row-zz42', 'cell-3'),
        {'insert': 'd'},
        cell('d', 'row-zz42', 'cell-4'),
        {'insert': '\n'},
      ];

      final html = opsToHtml(ops);
      expect(countOf('<tr', html), 2,
          reason: 'dois ids distintos => duas <tr> ($html)');
      expect(countOf('</tr>', html), 2);
      expect(countOf('<td', html), 4);
      // a primeira linha contém a/b, a segunda c/d
      final firstRow = html.substring(
          html.indexOf('<tr'), html.indexOf('</tr>'));
      expect(firstRow, contains('>a</td>'));
      expect(firstRow, contains('>b</td>'));
      expect(firstRow, isNot(contains('>c</td>')));
    });

    test('ids numéricos ("1","2") continuam agrupando como antes', () {
      final ops = <dynamic>[
        {
          'insert': '\n',
          'attributes': {
            'table-temporary': {'data-class': 'ql-table-better'}
          },
        },
        {'insert': 'a'},
        cell('a', '1', 'c1'),
        {'insert': 'b'},
        cell('b', '1', 'c2'),
        {'insert': 'c'},
        cell('c', '2', 'c3'),
        {'insert': '\n'},
      ];

      final html = opsToHtml(ops);
      expect(countOf('<tr', html), 2);
      expect(countOf('</tr>', html), 2);
      expect(countOf('<td', html), 3);
    });

    test('tabela 1xN com o mesmo id fica em uma única linha', () {
      final ops = <dynamic>[
        {
          'insert': '\n',
          'attributes': {
            'table-temporary': {'data-class': 'ql-table-better'}
          },
        },
        {'insert': 'x'},
        cell('x', 'row-only', 'c1'),
        {'insert': 'y'},
        cell('y', 'row-only', 'c2'),
        {'insert': '\n'},
      ];

      final html = opsToHtml(ops);
      expect(countOf('<tr', html), 1);
      expect(countOf('</tr>', html), 1);
    });
  });

  group('table core: <tr> emitidos com ids de editor', () {
    List<dynamic> tableOps(List<(String, String)> cells) => [
          for (final (text, row) in cells) ...[
            {'insert': text},
            {
              'insert': '\n',
              'attributes': {'table': row},
            },
          ],
          {'insert': '\n'},
        ];

    test('ids row-xxxx produzem <tr> balanceados', () {
      final html = opsToHtml(tableOps([
        ('a', 'row-1a'),
        ('b', 'row-1a'),
        ('c', 'row-2b'),
      ]));
      expect(countOf('<tr', html), 2, reason: html);
      expect(countOf('</tr>', html), 2);
      expect(countOf('<td', html), 3);
    });

    test('ids numéricos não duplicam </tr> na troca de linha', () {
      final html = opsToHtml(tableOps([
        ('a', '1'),
        ('b', '1'),
        ('c', '2'),
      ]));
      expect(countOf('<tr', html), 2, reason: html);
      expect(countOf('</tr>', html), 2);
    });
  });
}
