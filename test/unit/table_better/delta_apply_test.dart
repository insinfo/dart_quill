import 'package:dart_quill/src/dependencies/dart_quill_delta/dart_quill_delta.dart';
import 'package:dart_quill/src/table_better/formats/table.dart';
import 'package:dart_quill/src/table_better/register.dart';
import 'package:test/test.dart';

import '../../support/quill_test_helpers.dart';

/// End-to-end delta → DOM: the insertTable delta shape used by
/// `quill-table-better.ts:224` must hydrate into a single well-formed
/// `<table>` through the requiredContainer optimize chain.
void main() {
  setUpAll(() {
    ensureQuillTestInitialized();
    registerTableBetter();
  });

  Delta insertTableDelta(int rows, int columns) {
    final delta = Delta()
      ..insert('\n', {
        'table-temporary': {'style': 'width: 100%'}
      });
    for (var r = 0; r < rows; r++) {
      final rowId = 'row-test$r';
      for (var c = 0; c < columns; c++) {
        delta.insert('\n', {
          'table-cell-block': 'cell-test$r$c',
          'table-cell': {'data-row': rowId}
        });
      }
    }
    return delta;
  }

  test('insertTable delta builds a single well-formed table', () {
    final quill = createTestQuill(initialHtml: '<p><br></p>');
    quill.updateContents(insertTableDelta(2, 2));

    final tables = quill.scroll.descendants<TableContainer>().toList();
    expect(tables, hasLength(1));
    final table = tables.single;
    expect(table.element.getAttribute('style'), contains('width: 100%'));

    final bodies = table.descendants<TableBody>().toList();
    expect(bodies, hasLength(1));
    final rows = table.descendants<TableRow>().toList();
    expect(rows, hasLength(2));
    for (final row in rows) {
      final cells = row.children.whereType<TableCell>().toList();
      expect(cells, hasLength(2));
      final ids = cells
          .map((cell) => cell.element.getAttribute('data-row'))
          .toSet();
      expect(ids, hasLength(1), reason: 'cells of a row share data-row');
      for (final cell in cells) {
        expect(cell.children.first, isA<TableCellBlock>());
      }
    }
    // Distinct rows carry distinct ids.
    expect(
      rows
          .map((row) => (row.children.first as TableCell)
              .element
              .getAttribute('data-row'))
          .toSet(),
      hasLength(2),
    );
    // The temporary lives inside the table, not at the scroll root.
    expect(quill.scroll.descendants<TableTemporary>().single.parent, table);
  });

  test('table delta roundtrips through getContents', () {
    final quill = createTestQuill(initialHtml: '<p><br></p>');
    quill.updateContents(insertTableDelta(2, 3));

    final contents = quill.getContents();
    final tableOps = contents.operations
        .where((op) =>
            op.attributes?.containsKey('table-cell') == true ||
            op.attributes?.containsKey('table-temporary') == true)
        .toList();
    expect(tableOps, hasLength(7),
        reason: '1 temporary + 6 cell lines survive the roundtrip');
  });
}
