/// Colar uma tabela precisa preservar o id de cada célula.
///
/// O `matchBlot` do clipboard reporta o que a entrada do registro declara em
/// `staticFormats` (a contraparte do `'formats' in match` do upstream). Sem
/// declarar nada, um blot identificado por CLASSE cai no fallback `true` — e
/// como o merge de células compara cellIds, todas as células de uma tabela
/// colada tinham o mesmo id `true` e se fundiam numa só.
@TestOn('vm')
library;

import 'package:dart_quill/src/table_better/formats/table.dart';
import 'package:dart_quill/src/table_better/register.dart';
import 'package:test/test.dart';

import '../../support/quill_test_helpers.dart';

void main() {
  setUpAll(() {
    ensureQuillTestInitialized();
    registerTableBetter();
  });

  test('células coladas continuam separadas, com seus ids', () {
    const html = '<table class="ql-table-better"><tbody><tr>'
        '<td data-row="1"><p class="ql-table-block" data-cell="a">x</p></td>'
        '<td data-row="1"><p class="ql-table-block" data-cell="b">y</p></td>'
        '</tr></tbody></table><p><br></p>';
    final quill = createTestQuill(initialHtml: html);
    final rendered = quill.root.innerHTML ?? '';

    expect('<td'.allMatches(rendered).length, 2,
        reason: 'duas células distintas não podem virar uma ($rendered)');
    expect(rendered, contains('data-cell="a"'));
    expect(rendered, contains('data-cell="b"'));
    expect(quill.scroll.descendants<TableContainer>().toList(), hasLength(1));
    expect(quill.getText(), contains('x'));
    expect(quill.getText(), contains('y'));
  });

  // O caso equivalente com <thead>/<th> ainda esbarra no
  // `Maximum optimize iterations exceeded` descrito em
  // doc/PERF_ABERTURA_DOCX_GRANDE.md — outro bug, com diagnóstico próprio.
}
