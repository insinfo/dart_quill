import 'package:dart_quill/src/table_better/formats/table.dart';
import 'package:dart_quill/src/table_better/register.dart';
import 'package:dart_quill/src/table_better/ui/cell_selection.dart';
import 'package:test/test.dart';

import '../../support/test_helpers.dart';

const _tableHtml = '''
<table class="ql-table-better"><tbody>
<tr><td data-row="r1"><p class="ql-table-block" data-cell="a">a</p></td>
<td data-row="r1" colspan="2"><p class="ql-table-block" data-cell="b">b</p></td></tr>
<tr><td data-row="r2" rowspan="2"><p class="ql-table-block" data-cell="c">c</p></td>
<td data-row="r2"><p class="ql-table-block" data-cell="d">d</p></td>
<td data-row="r2"><p class="ql-table-block" data-cell="e">e</p></td></tr>
<tr><td data-row="r3"><p class="ql-table-block" data-cell="f">f</p></td>
<td data-row="r3"><p class="ql-table-block" data-cell="g">g</p></td></tr>
</tbody></table>
''';

void main() {
  setUpAll(initializeFakeDom);

  test('normalizes reversed range and selects cells across spans', () {
    final scroll = createScroll(
      _tableHtml,
      registry: createRegistry(registerTableBetterFormats()),
    );
    final table = scroll.descendants<TableContainer>().first;
    final selection = CellSelection(table);

    final selected = selection.select(
      startRow: 2,
      startColumn: 2,
      endRow: 0,
      endColumn: 0,
    );

    expect(selection.range.toString(), '0:0-2:2');
    expect(selected.map((cell) => cell.element.getAttribute('data-row')),
        containsAll(<String>['r1', 'r2', 'r3']));
    expect(selected.length, 7);
    expect(
        selected
            .every((cell) => cell.element.classes.contains('ql-cell-selected')),
        isTrue);
  });

  test('clear removes selection class', () {
    final scroll = createScroll(
      _tableHtml,
      registry: createRegistry(registerTableBetterFormats()),
    );
    final table = scroll.descendants<TableContainer>().first;
    final selection = CellSelection(table);
    selection.select(startRow: 0, startColumn: 0, endRow: 0, endColumn: 0);
    selection.clear();
    expect(selection.isActive, isFalse);
    expect(
        table
            .descendants<TableCell>()
            .first
            .element
            .classes
            .contains('ql-cell-selected'),
        isFalse);
  });
}
