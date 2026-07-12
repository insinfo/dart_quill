import 'package:dart_quill/src/table_better/formats/table.dart';
import 'package:dart_quill/src/table_better/register.dart';
import 'package:dart_quill/src/table_better/ui/table_properties_form.dart';
import 'package:dart_quill/src/platform/dom.dart';
import 'package:test/test.dart';

import '../../support/test_helpers.dart';

void main() {
  setUpAll(initializeFakeDom);

  test('builds and closes the table properties dialog', () {
    final scroll = createScroll(
      '<table><tbody><tr><td data-row="r1"><p class="ql-table-block" data-cell="a">a</p></td></tr></tbody></table>',
      registry: createRegistry(registerTableBetterFormats()),
    );
    final host = testAdapter.document.createElement('div');
    final table = scroll.descendants<TableContainer>().first;
    final form = TablePropertiesForm(host: host);
    form.openTable(table);

    expect(form.isOpen, isTrue);
    expect(host.childNodes, isNotEmpty);
    final dialog = host.childNodes.first as DomElement;
    expect(dialog.getAttribute('data-table-properties-form'), 'true');
    expect(dialog.querySelectorAll('input').length, greaterThanOrEqualTo(7));
    form.close();
    expect(form.isOpen, isFalse);
  });
}
