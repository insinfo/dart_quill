import 'package:dart_quill/src/table_better/formats/header.dart';
import 'package:dart_quill/src/table_better/formats/list.dart';
import 'package:dart_quill/src/table_better/formats/table.dart';
import 'package:dart_quill/src/table_better/register.dart';
import 'package:test/test.dart';

import '../../support/test_helpers.dart';

void main() {
  setUpAll(initializeFakeDom);

  test('hydrates a table header and converts it back to a cell block', () {
    final scroll = createScroll(
      '<table><tbody><tr><td data-row="r1">'
      '<h2 class="ql-table-header" data-cell="head">Heading</h2>'
      '</td></tr></tbody></table>',
      registry: createRegistry(registerTableBetterFormats()),
    );
    final header = scroll.descendants<TableHeader>().single;
    expect(header.formats()[TableHeader.kBlotName], {
      'cellId': 'head',
      'value': 2,
    });
    header.format('header', false);
    final block = scroll.descendants<TableCellBlock>().single;
    expect(block.element.getAttribute('data-cell'), 'head');
    expect(block.element.textContent, 'Heading');
  });

  test('hydrates a table list and clears it back to a cell block', () {
    final scroll = createScroll(
      '<table><tbody><tr><td data-row="r1">'
      '<ol class="table-list-container" data-cell="list-cell">'
      '<li class="table-list" data-list="bullet">Item</li>'
      '</ol></td></tr></tbody></table>',
      registry: createRegistry(registerTableBetterFormats()),
    );
    final list = scroll.descendants<TableList>().single;
    expect(list.parent, isA<TableListContainer>());
    expect(list.formats()[TableList.kBlotName], 'bullet');
    list.format('list', false);
    final block = scroll.descendants<TableCellBlock>().single;
    expect(block.element.getAttribute('data-cell'), 'list-cell');
    expect(block.element.textContent, 'Item');
  });
}
