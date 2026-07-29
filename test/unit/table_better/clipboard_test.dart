import 'package:dart_quill/src/dependencies/dart_quill_delta/dart_quill_delta.dart';
import 'package:dart_quill/src/modules/clipboard.dart';
import 'package:dart_quill/src/table_better/modules/clipboard.dart';
import 'package:dart_quill/src/table_better/register.dart';
import 'package:test/test.dart';

import '../../support/quill_test_helpers.dart';
import '../../support/test_helpers.dart';

void main() {
  setUpAll(() {
    ensureQuillTestInitialized();
    registerTableBetter(replaceClipboard: false);
  });

  setUp(() {
    final body = testAdapter.document.body;
    while (body.firstChild != null) {
      body.firstChild!.remove();
    }
  });

  test('preserves table, columns, headers and cell ids', () {
    // The plugin's clipboard never exists without the module: `register()`
    // installs the table blots first, and matchBlot needs them in the
    // registry to report the cell's own attribute map.
    final quill = createTestQuill(
      modules: {'table-better': const <String, dynamic>{}},
    );
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
        // `span="2"` is two columns: matchBlot emits one `\n` for the `<col>`
        // itself (as upstream does — see the colgroup golden's `converted`)
        // and matchTableCol prepends span-1 more. The old single-op
        // expectation encoded a lost column.
        ..insert('\n\n', {
          'table-col': {'width': '120'}
        })
        // Faithful to the plugin's own `clipboard.convert` (recorded in the
        // table-better golden as `converted`): quill's core `tr` matcher
        // contributes `table: rowNumber` — the plugin does not remove it —
        // matchBlot reports the `<th>`'s own attribute map (so the explicit
        // `data-row="header"` survives on the first cell), and computed ids
        // are numbers while ids read from attributes stay strings.
        ..insert('Name\n', {
          'table': 1,
          'table-th-block': 'name',
          'table-th': {'data-row': 'header'},
        })
        ..insert('Value\n', {
          'table': 1,
          'table-th-block': 2,
          'table-th': {'data-row': 1},
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
