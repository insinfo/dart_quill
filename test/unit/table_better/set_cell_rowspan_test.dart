import 'package:dart_quill/src/table_better/formats/table.dart';
import 'package:dart_quill/src/table_better/register.dart';
import 'package:test/test.dart';

import '../../support/test_helpers.dart';

// A 3-row table whose first cell spans all three rows; deleting the single
// remaining cell of a spanned row must shrink that rowspan (TS
// `setCellRowspan`, table.ts:736-757).
const _span3Html = '''
<table class="ql-table-better"><tbody>
<tr><td data-row="r1" rowspan="3"><p class="ql-table-block" data-cell="a">a</p></td>
<td data-row="r1"><p class="ql-table-block" data-cell="b">b</p></td></tr>
<tr><td data-row="r2"><p class="ql-table-block" data-cell="c">c</p></td></tr>
<tr><td data-row="r3"><p class="ql-table-block" data-cell="d">d</p></td></tr>
</tbody></table>
''';

const _span2Html = '''
<table class="ql-table-better"><tbody>
<tr><td data-row="r1" rowspan="2"><p class="ql-table-block" data-cell="a">a</p></td>
<td data-row="r1"><p class="ql-table-block" data-cell="b">b</p></td></tr>
<tr><td data-row="r2"><p class="ql-table-block" data-cell="c">c</p></td></tr>
</tbody></table>
''';

void main() {
  setUpAll(initializeFakeDom);

  TableContainer buildTable(String html) {
    final scroll = createScroll(
      html,
      registry: createRegistry(registerTableBetterFormats()),
    );
    return scroll.descendants<TableContainer>().first;
  }

  test('setCellRowspan decrements a rowspan greater than 2', () {
    final table = buildTable(_span3Html);
    final rows = table.descendants<TableRow>().toList();
    // The walk starts from the previous sibling of the removed row, exactly
    // as deleteColumn hands it over.
    table.setCellRowspan(rows[0].element);
    table.scroll.optimize();

    final spanned = table
        .descendants<TableCell>()
        .firstWhere((cell) => cell.element.getAttribute('data-row') == 'r1');
    expect(spanned.element.getAttribute('rowspan'), '2');
    // The cell must still sit directly under its row: the format() detour
    // (wrap in a fresh tr+td) has to be normalized away by optimize.
    expect(spanned.parent, isA<TableRow>());
    expect(spanned.element.querySelectorAll('tr'), isEmpty,
        reason: 'no nested rows may survive inside the cell');
    expect(table.element.querySelectorAll('td').length, 4);
  });

  test('setCellRowspan removes a rowspan that collapses to 1', () {
    final table = buildTable(_span2Html);
    final rows = table.descendants<TableRow>().toList();
    table.setCellRowspan(rows[0].element);
    table.scroll.optimize();

    final spanned = table
        .descendants<TableCell>()
        .firstWhere((cell) => cell.element.getAttribute('data-cell') != null
            ? cell.element.querySelectorAll('[data-cell="a"]').isNotEmpty
            : false,
            orElse: () => table.descendants<TableCell>().first);
    expect(spanned.element.hasAttribute('rowspan'), isFalse,
        reason: 'rowspan 2 minus 1 collapses to no attribute (TS ~~x||1 - 1)');
  });

  test('setCellRowspan walks up past rows without spanned cells', () {
    final table = buildTable(_span3Html);
    final rows = table.descendants<TableRow>().toList();
    // Start from the middle row (no td[rowspan] of its own): the TS loop
    // walks previousElementSibling until it finds one.
    table.setCellRowspan(rows[1].element);
    table.scroll.optimize();

    final spanned = table
        .descendants<TableCell>()
        .firstWhere((cell) => cell.element.getAttribute('data-row') == 'r1');
    expect(spanned.element.getAttribute('rowspan'), '2');
  });

  test('deleteColumn shrinks the rowspan when a spanned row empties', () {
    final table = buildTable(_span3Html);
    final rows = table.descendants<TableRow>().toList();
    // Delete the second column: r1 loses "b", r2 loses its only cell "c" —
    // r2 exists only because of the rowspan, so the span must shrink.
    final delB = rows[0].children.whereType<TableCell>().last.element;
    final delC = rows[1].children.whereType<TableCell>().first.element;
    table.deleteColumn(const [], [delB, delC], () => fail('not a full wipe'));
    table.scroll.optimize();

    final spanned = table
        .descendants<TableCell>()
        .firstWhere((cell) => cell.element.getAttribute('data-row') == 'r1');
    expect(spanned.element.getAttribute('rowspan'), '2');
  });
}
