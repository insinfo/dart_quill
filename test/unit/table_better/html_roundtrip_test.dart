/// Ciclo completo: DOCX → Delta → HTML → editor.
///
/// Três bugs distintos impediam este ciclo de fechar, todos com o mesmo
/// sintoma final (`Maximum optimize iterations exceeded` ou tabela deformada):
///
/// 1. o eco `table: 1` que o matcher core de `<tr>` adiciona por cima dos
///    formatos do table-better era REBAIXADO a formato quando o vencedor da
///    linha era um container — e criava a estrutura de tabela CORE dentro da
///    do plugin; as duas se desfaziam mutuamente a cada passada do optimize.
///    A regra do `createBlock` agora é semântica e independe da ordem das
///    chaves: a linha nasce como o último blot de bloco SIMPLES, containers
///    são rebaixados (preservando o data-row) e os demais descartados;
/// 2. o importador de DOCX não emitia a âncora `table-temporary`, e sem ela o
///    conversor Delta→HTML não tem onde fechar uma tabela: as três do ETP
///    viravam UMA com todas as 18 linhas;
/// 3. `table-cell-block` sem `staticFormats` fazia o clipboard reportar
///    cellId `true` para toda célula (coberto em paste_cell_id_test).
@TestOn('vm')
library;

import 'dart:io';

import 'package:dart_quill/dart_quill_docx.dart';
import 'package:dart_quill/dart_quill_html.dart';
import 'package:dart_quill/src/delta/delta.dart';
import 'package:dart_quill/src/table_better/formats/table.dart';
import 'package:dart_quill/src/table_better/register.dart';
import 'package:test/test.dart';

import '../../support/quill_test_helpers.dart';

void main() {
  setUpAll(() {
    ensureQuillTestInitialized();
    registerTableBetter();
  });

  test('o ETP fecha o ciclo com as três tabelas', () {
    final delta = docxToDelta(
        File('test/assets/docx/etp_corpus.docx').readAsBytesSync());
    final html = deltaToHtml(delta);
    expect('<table'.allMatches(html).length, 3,
        reason: 'o HTML gerado precisa de uma <table> por tabela');

    final quill = createTestQuill(initialHtml: html);
    expect(quill.scroll.descendants<TableContainer>().toList(), hasLength(3),
        reason: 'as três tabelas sobrevivem à hidratação');
    expect(quill.getText(), contains('Severidade'));
  });

  group('hidratar linha com o eco table:1 do matcher core', () {
    List<Map<String, dynamic>> tableOps(Map<String, dynamic> Function() attrs) => [
          {
            'insert': '\n',
            'attributes': {
              'table-temporary': {'data-class': 'ql-table-better'}
            },
          },
          {'insert': 'x\n', 'attributes': attrs()},
          {'insert': 'y\n', 'attributes': attrs()..['table-cell-block'] = 'b'},
          {'insert': '\n'},
        ];

    void expectTwoCells(List<Map<String, dynamic>> ops) {
      final quill = createTestQuill();
      quill.setContents(Delta.fromJson(ops));
      final html = quill.root.innerHTML ?? '';
      expect('<td'.allMatches(html).length, 2, reason: html);
      expect(html, contains('data-row="1"'),
          reason: 'o data-row do Delta é preservado');
    }

    test('ordem do clipboard (cellBlock por último)', () {
      expectTwoCells(tableOps(() => {
            'table': 1,
            'table-cell': {'data-row': '1'},
            'table-cell-block': 'a',
          }));
    });

    test('ordem de Delta gravado (cell por último)', () {
      expectTwoCells(tableOps(() => {
            'table': 1,
            'table-cell-block': 'a',
            'table-cell': {'data-row': '1'},
          }));
    });

    test('células de cabeçalho (table-th)', () {
      final quill = createTestQuill();
      quill.setContents(Delta.fromJson([
        {
          'insert': '\n',
          'attributes': {
            'table-temporary': {'data-class': 'ql-table-better'}
          },
        },
        {
          'insert': 'A\n',
          'attributes': {
            'table': 1,
            'table-th-block': 'h1',
            'table-th': {'data-row': '1'},
          },
        },
        {'insert': '\n'},
      ]));
      final html = quill.root.innerHTML ?? '';
      expect(html, contains('<thead'));
      expect(html, contains('data-cell="h1"'));
    });
  });

  test('tabela de HTML externo, sem classes do plugin', () {
    const html = '<table style="border-collapse: collapse;">'
        '<tbody><tr><td>x</td><td>y</td></tr></tbody></table><p><br></p>';
    final quill = createTestQuill(initialHtml: html);
    expect('<td'.allMatches(quill.root.innerHTML ?? '').length, 2);
  });
}
