import 'package:dart_quill/src/table_better/formats/table.dart';
import 'package:dart_quill/src/table_better/register.dart';
import 'package:dart_quill/src/table_better/ui/operate_line.dart';
import 'package:test/test.dart';

import '../../support/test_helpers.dart';

void main() {
  setUpAll(initializeFakeDom);

  test('resizes columns and clamps to the minimum width', () {
    final scroll = createScroll(
      '<table><colgroup><col width="80"><col width="100"></colgroup>'
      '<tbody><tr><td><p class="ql-table-block">a</p></td>'
      '<td><p class="ql-table-block">b</p></td></tr></tbody></table>',
      registry: createRegistry(registerTableBetterFormats()),
    );
    final table = scroll.descendants<TableContainer>().first;
    final operate = OperateLine(table);
    expect(operate.resizeColumn(0, -100), 24);
    expect(
        (table.colgroup()!.children.first as TableCol)
            .element
            .getAttribute('width'),
        '24');
    expect(operate.setColumnWidth(1, 140), 140);
    expect(
        (table.colgroup()!.children.elementAt(1) as TableCol)
            .element
            .getAttribute('width'),
        '140');
  });

  test('resizes rows and table with minimum constraints', () {
    final scroll = createScroll(
      '<table data-width="200"><tbody><tr><td><p class="ql-table-block">a</p></td></tr>'
      '<tr><td><p class="ql-table-block">b</p></td></tr></tbody></table>',
      registry: createRegistry(registerTableBetterFormats()),
    );
    final table = scroll.descendants<TableContainer>().first;
    final operate = OperateLine(table);
    expect(operate.resizeRow(0, -100), 20);
    expect(
        table.descendants<TableRow>().first.element.getAttribute('data-height'),
        '20');
    expect(operate.resizeTable(-500), 100);
    expect(table.element.getAttribute('data-width'), '100');
  });
}
