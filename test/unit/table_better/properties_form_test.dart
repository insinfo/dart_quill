import 'package:dart_quill/src/table_better/formats/table.dart';
import 'package:dart_quill/src/table_better/register.dart';
import 'package:dart_quill/src/table_better/ui/properties_form.dart';
import 'package:test/test.dart';

import '../../support/test_helpers.dart';

void main() {
  setUpAll(initializeFakeDom);

  test('applies validated properties to a table and selected cells', () {
    final scroll = createScroll(
      '<table><tbody><tr><td data-row="r1"><p class="ql-table-block" data-cell="a">a</p></td>'
      '<td data-row="r1"><p class="ql-table-block" data-cell="b">b</p></td></tr></tbody></table>',
      registry: createRegistry(registerTableBetterFormats()),
    );
    final table = scroll.descendants<TableContainer>().first;
    final cells = table.descendants<TableCell>().toList();
    var changes = 0;
    final controller = TablePropertiesController(onChange: () => changes++);

    controller.applyTable(table, {
      'border-style': 'solid',
      'border-color': '#336699',
      'width': '80%',
    });
    controller.applyCells(cells, {
      'background-color': '#ffeecc',
      'text-align': 'center',
    });

    expect(controller.readTable(table)['width'], '80%');
    expect(controller.readCell(cells.first)['background-color'], '#ffeecc');
    expect(controller.readCell(cells.first)['text-align'], 'center');
    expect(changes, 3);
  });

  test('rejects invalid color, dimensions and alignment', () {
    final scroll = createScroll(
      '<table><tbody><tr><td><p class="ql-table-block">a</p></td></tr></tbody></table>',
      registry: createRegistry(registerTableBetterFormats()),
    );
    final table = scroll.descendants<TableContainer>().first;
    final controller = TablePropertiesController();
    expect(() => controller.applyTable(table, {'width': 'not-a-size'}),
        throwsFormatException);
    expect(() => controller.applyTable(table, {'border-color': 'not-a-color'}),
        throwsFormatException);
    expect(
        () => controller.applyCell(
            table.descendants<TableCell>().first, {'text-align': 'diagonal'}),
        throwsFormatException);
  });
}
