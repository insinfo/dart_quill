/// Delta → HTML de tabelas complexas, alimentado pelos MESMOS deltas que o
/// plugin real (quill-table-better 1.2.3) produziu — `test/goldens/
/// quill_table_better_1.2.3.json`, gravado em Chrome contra o bundle upstream.
///
/// Cobre o que o conversor perdia antes:
/// - uma célula com VÁRIOS blocos virava vários `<td>` (o `<h2>` sumia, cada
///   `<li>` abria uma coluna);
/// - só o op imediatamente anterior entrava na célula, então formatação
///   inline parcial vazava para fora da tabela;
/// - ops `table-col` eram descartados: nenhum `<colgroup>`, nenhuma largura.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:dart_quill/dart_quill_html.dart';
import 'package:test/test.dart';

void main() {
  final golden = jsonDecode(
      File('test/goldens/quill_table_better_1.2.3.json').readAsStringSync());
  final byName = <String, List<dynamic>>{
    for (final c in (golden['results'] as List))
      c['name'] as String: (c['contents'] as List),
  };

  /// O HTML da primeira (e única) tabela do caso.
  String htmlOf(String caseName) {
    final ops = byName[caseName];
    expect(ops, isNotNull, reason: 'golden "$caseName" não existe mais');
    return opsToHtml(ops!);
  }

  int countOf(String needle, String haystack) =>
      needle.allMatches(haystack).length;

  group('uma célula = um <td>, com todos os seus blocos dentro', () {
    test('título + parágrafo na mesma célula', () {
      final html = htmlOf('block content inside a cell');
      expect(countOf('<td', html), 1,
          reason: 'dois blocos da MESMA célula não podem virar dois <td> '
              '($html)');
      expect(html, contains('<h2>title</h2>'),
          reason: 'o table-header vira um heading de verdade');
      expect(html, contains('<p>body</p>'));
      // ordem preservada dentro da célula
      expect(html.indexOf('<h2>'), lessThan(html.indexOf('<p>body')));
    });

    test('lista dentro da célula vira uma <ul> só', () {
      final html = htmlOf('a list inside a cell');
      expect(countOf('<td', html), 1);
      expect(countOf('<ul>', html), 1,
          reason: 'itens consecutivos compartilham a mesma lista ($html)');
      expect(countOf('<li>', html), 2);
      expect(html, contains('<li>one</li>'));
      expect(html, contains('<li>two</li>'));
    });

    test('formatação inline parcial fica inteira dentro do <td>', () {
      final html = htmlOf('inline formatting inside a cell');
      expect(countOf('<td', html), 1);
      expect(html, contains('<strong>bold</strong>'));
      expect(html, contains('<em>italic</em>'));
      expect(html, contains(' and '),
          reason: 'o trecho sem formato entre os dois também entra');
      // nada pode escapar da tabela como parágrafo solto
      final beforeTable = html.substring(0, html.indexOf('<table'));
      expect(beforeTable, isNot(contains('bold')),
          reason: 'texto da célula não pode vazar para fora da tabela');
    });
  });

  group('colgroup e larguras', () {
    test('ops table-col viram <colgroup> com larguras e layout fixo', () {
      final html = htmlOf('a table with a colgroup');
      expect(html, contains('<colgroup>'));
      expect(countOf('<col ', html), 2);
      expect(html, contains('width:100px'));
      expect(html, contains('width:200px'));
      expect(html, contains('table-layout: fixed'),
          reason: 'sem layout fixo o browser ignora as larguras ($html)');
      expect(html.indexOf('<colgroup>'), lessThan(html.indexOf('<tbody>')),
          reason: 'o colgroup precede o corpo, como manda o HTML');
    });

    test('col-widths medido pelo app é usado quando não há ops table-col', () {
      // Formato que o SALI injeta na âncora ao salvar (larguras medidas no
      // DOM), para o HTML exportado reproduzir a tabela vista no editor.
      final ops = <dynamic>[
        {
          'insert': '\n',
          'attributes': {
            'table-temporary': {
              'data-class': 'ql-table-better',
              'col-widths': [120, 240],
            }
          },
        },
        {'insert': 'a'},
        {
          'insert': '\n',
          'attributes': {
            'table-cell-block': 'c1',
            'table-cell': {'data-row': 'row-1'},
          },
        },
        {'insert': 'b'},
        {
          'insert': '\n',
          'attributes': {
            'table-cell-block': 'c2',
            'table-cell': {'data-row': 'row-1'},
          },
        },
        {'insert': '\n'},
      ];
      final html = opsToHtml(ops);
      expect(html, contains('<colgroup>'));
      expect(html, contains('width:120px'));
      expect(html, contains('width:240px'));
      expect(html, contains('table-layout: fixed'));
    });
  });

  group('estrutura preservada', () {
    test('colspan e rowspan sobrevivem', () {
      final html = htmlOf('colspan and rowspan');
      expect(html, contains('colspan="2"'));
      expect(html, contains('rowspan="2"'));
      expect(countOf('<tr', html), 3);
    });

    test('estilos de célula colados do Word continuam no <td>', () {
      final html = htmlOf('cell styles survive the paste');
      expect(html, contains('<td'));
      expect(html, contains('style="'));
      // a borda base do conversor não pode apagar o estilo que veio no delta
      expect(html, contains('border: 1px solid #000;'));
    });

    test('uma tabela 2x2 do editor tem duas linhas e quatro células', () {
      final html = htmlOf('a 2x2 table from an empty document');
      expect(countOf('<tr', html), 2);
      expect(countOf('<td', html), 4);
    });
  });
}
