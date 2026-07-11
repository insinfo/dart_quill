import 'package:dart_quill/src/dependencies/dart_quill_delta/dart_quill_delta.dart';
import 'package:dart_quill/src/modules/clipboard.dart';
import 'package:dart_quill/src/table_better/modules/clipboard.dart';
import 'package:test/test.dart';

import '../../support/quill_test_helpers.dart';
import '../../support/test_helpers.dart';

void main() {
  setUpAll(ensureQuillTestInitialized);

  setUp(() {
    final body = testAdapter.document.body;
    while (body.firstChild != null) {
      body.firstChild!.remove();
    }
  });

  test('preserves table, columns, headers and cell ids', () {
    final quill = createTestQuill();
    final clipboard = TableClipboard(quill, const ClipboardOptions());
    const html = '<table border="1" cellspacing="2" class="invoice" '
        'style="width: 80%; mso-padding-alt: 0;">'
        '<colgroup><col span="2" width="120"></colgroup>'
        '<thead><tr><th data-row="header"><p data-cell="name">Name</p></th>'
        '<th><p>Value</p></th></tr></thead>'
        '</table>';

    expectDelta(
      clipboard.convert(html: html),
      Delta()
        ..insert('\n', {
          'table-temporary': {
            'border': '1',
            'cellspacing': '2',
            'style': 'width: 80%; ',
            'data-class': 'invoice',
          }
        })
        ..insert('\n', {
          'table-col': {'width': '120'}
        })
        ..insert('Name\n', {
          'table-th': 1,
          'table-th-block': 'name',
        })
        ..insert('Value\n', {
          'table-th': 1,
          'table-th-block': '2',
        }),
    );
  });

  test('applies the active cell context to external pasted text', () {
    final quill = createTestQuill();
    final clipboard = TableClipboard(quill, const ClipboardOptions());
    final delta = clipboard.getTableDelta(
      text: 'external',
      formats: const {
        'table-cell': 1,
        'table-cell-block': 'cell-1',
      },
    );

    expectDelta(
      delta,
      Delta()
        ..insert('external', {
          'table-cell': 1,
          'table-cell-block': 'cell-1',
        }),
    );
  });

  test('does not nest a copied table inside an active cell', () {
    final quill = createTestQuill();
    final clipboard = TableClipboard(quill, const ClipboardOptions());
    final delta = clipboard.getTableDelta(
      html: '<table><tr><td>nested</td></tr></table>',
      formats: const {
        'table-cell': 1,
        'table-cell-block': 'cell-1',
      },
    );

    expect(delta.isEmpty, isTrue);
  });
}
