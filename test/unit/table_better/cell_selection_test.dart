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

  test('reports logical coordinates for cells with spans', () {
    final scroll = createScroll(
      _tableHtml,
      registry: createRegistry(registerTableBetterFormats()),
    );
    final table = scroll.descendants<TableContainer>().first;
    final cells = table.descendants<TableCell>().toList();
    final selection = CellSelection(table);
    expect(selection.coordinateOf(cells[0]), (row: 0, column: 0));
    expect(selection.coordinateOf(cells[1]), (row: 0, column: 1));
    expect(selection.coordinateOf(cells[2]), (row: 1, column: 0));
    expect(selection.coordinateOf(cells[3]), (row: 1, column: 1));
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

  test('mergeCells merges a rectangle into the top-left cell with colspan',
      () {
    final scroll = createScroll(
      _tableHtml,
      registry: createRegistry(registerTableBetterFormats()),
    );
    final table = scroll.descendants<TableContainer>().first;
    final selection = CellSelection(table);
    selection.select(startRow: 0, startColumn: 0, endRow: 0, endColumn: 2);

    final merged = selection.mergeCells();

    expect(merged, isNotNull);
    expect(merged!.element.getAttribute('colspan'), '3');
    expect(merged.element.hasAttribute('rowspan'), isFalse);
    final firstRowCells = table
        .descendants<TableRow>()
        .first
        .children
        .whereType<TableCell>()
        .toList();
    expect(firstRowCells.length, 1);
    expect(merged.element.textContent, 'ab');
    // Children adopt the surviving cell's id (setChildrenId parity).
    final ids = merged.children
        .map((child) => (child as TableCellBlock)
            .element
            .getAttribute('data-cell'))
        .toSet();
    expect(ids.length, 1);
    // Merged cell stays selected.
    expect(selection.selectedCells, [merged]);
  });

  test('mergeCells removes emptied rows and shrinks sibling rowspans', () {
    final scroll = createScroll(
      _tableHtml,
      registry: createRegistry(registerTableBetterFormats()),
    );
    final table = scroll.descendants<TableContainer>().first;
    final selection = CellSelection(table);
    // d, e (row 1) + f, g (row 2); c spans rows 1-2 outside the selection.
    selection.select(startRow: 1, startColumn: 1, endRow: 2, endColumn: 2);
    expect(selection.selectedCells.length, 4);

    final merged = selection.mergeCells();

    expect(merged, isNotNull);
    final rows = table.descendants<TableRow>().toList();
    expect(rows.length, 2, reason: 'row 3 was emptied by the merge');
    expect(merged!.element.getAttribute('colspan'), '2');
    expect(merged.element.hasAttribute('rowspan'), isFalse,
        reason: 'rowspan 2 minus one removed row collapses to 1');
    final spanned = rows[1].children.whereType<TableCell>().first;
    expect(spanned.element.textContent, 'c');
    expect(spanned.element.hasAttribute('rowspan'), isFalse,
        reason: 'sibling rowspan shrinks with the removed row');
    expect(merged.element.textContent, 'defg');
  });

  test('splitCells restores 1x1 cells from a rowspan cell', () {
    final scroll = createScroll(
      _tableHtml,
      registry: createRegistry(registerTableBetterFormats()),
    );
    final table = scroll.descendants<TableContainer>().first;
    final selection = CellSelection(table);
    // c spans rows 1-2 at column 0.
    selection.select(startRow: 1, startColumn: 0, endRow: 1, endColumn: 0);
    expect(selection.selectedCells.single.element.textContent, 'c');

    selection.splitCells();

    final rows = table.descendants<TableRow>().toList();
    final cellBlot = rows[1].children.whereType<TableCell>().first;
    expect(cellBlot.element.hasAttribute('rowspan'), isFalse);
    final lastRowCells =
        rows[2].children.whereType<TableCell>().toList();
    expect(lastRowCells.length, 3);
    expect(lastRowCells.first.element.textContent ?? '', isEmpty,
        reason: 'new empty cell fills the freed grid slot');
    expect(lastRowCells.first.element.getAttribute('data-row'), 'r3');
    expect(lastRowCells[1].element.textContent, 'f');
  });

  test('splitCells expands a colspan+rowspan cell across rows and columns',
      () {
    const html = '''
<table class="ql-table-better"><tbody>
<tr><td data-row="m1" colspan="2" rowspan="2"><p class="ql-table-block" data-cell="m">m</p></td>
<td data-row="m1"><p class="ql-table-block" data-cell="x">x</p></td></tr>
<tr><td data-row="m2"><p class="ql-table-block" data-cell="y">y</p></td></tr>
<tr><td data-row="m3"><p class="ql-table-block" data-cell="p">p</p></td>
<td data-row="m3"><p class="ql-table-block" data-cell="q">q</p></td>
<td data-row="m3"><p class="ql-table-block" data-cell="r">r</p></td></tr>
</tbody></table>
''';
    final scroll = createScroll(
      html,
      registry: createRegistry(registerTableBetterFormats()),
    );
    final table = scroll.descendants<TableContainer>().first;
    final selection = CellSelection(table);
    selection.select(startRow: 0, startColumn: 0, endRow: 0, endColumn: 0);

    selection.splitCells();

    final rows = table.descendants<TableRow>().toList();
    final row0 = rows[0].children.whereType<TableCell>().toList();
    final row1 = rows[1].children.whereType<TableCell>().toList();
    expect(row0.length, 3);
    expect(row0.first.element.hasAttribute('colspan'), isFalse);
    expect(row0.first.element.hasAttribute('rowspan'), isFalse);
    expect(row0.last.element.textContent, 'x');
    expect(row1.length, 3);
    expect(row1.last.element.textContent, 'y');
    expect(row1.first.element.getAttribute('data-row'), 'm2');
  });

  test('merge then split roundtrip keeps a balanced grid', () {
    final scroll = createScroll(
      _tableHtml,
      registry: createRegistry(registerTableBetterFormats()),
    );
    final table = scroll.descendants<TableContainer>().first;
    final selection = CellSelection(table);
    selection.select(startRow: 0, startColumn: 0, endRow: 0, endColumn: 2);
    final merged = selection.mergeCells();
    expect(merged, isNotNull);

    selection.splitCells();

    final firstRow =
        table.descendants<TableRow>().first.children.whereType<TableCell>();
    expect(firstRow.length, 3);
    expect(
        firstRow.every((cell) => !cell.element.hasAttribute('colspan')), isTrue);
  });

  test('convertToHeaderRow moves the selected row and rows above into thead',
      () {
    final scroll = createScroll(
      _tableHtml,
      registry: createRegistry(registerTableBetterFormats()),
    );
    final table = scroll.descendants<TableContainer>().first;
    final selection = CellSelection(table);
    // Selecting in the first row converts just that row.
    selection.select(startRow: 0, startColumn: 0, endRow: 0, endColumn: 0);

    final th = selection.convertToHeaderRow();

    expect(th, isNotNull);
    final thead = table.descendants<TableThead>().first;
    final headerRows = thead.children.whereType<TableThRow>().toList();
    expect(headerRows.length, 1);
    final headerCells = headerRows.first.children.whereType<TableTh>().toList();
    expect(headerCells.length, 2);
    expect(headerCells.first.element.tagName.toUpperCase(), 'TH');
    expect(headerCells.first.element.textContent, 'a');
    expect(headerCells[1].element.getAttribute('colspan'), '2');
    // Body keeps the remaining two rows.
    final bodyRows = table
        .descendants<TableRow>()
        .where((row) => row is! TableThRow)
        .toList();
    expect(bodyRows.length, 2);
    expect(selection.selectedCells.single, th);
  });

  test('convertToRow moves header rows back into the body', () {
    final scroll = createScroll(
      _tableHtml,
      registry: createRegistry(registerTableBetterFormats()),
    );
    final table = scroll.descendants<TableContainer>().first;
    final selection = CellSelection(table);
    selection.select(startRow: 0, startColumn: 0, endRow: 0, endColumn: 0);
    selection.convertToHeaderRow();
    expect(table.descendants<TableThead>().length, 1);

    final td = selection.convertToRow();

    expect(td, isNotNull);
    expect(td!.element.tagName.toUpperCase(), 'TD');
    expect(table.descendants<TableThead>(), isEmpty,
        reason: 'emptied thead is removed');
    final rows = table.descendants<TableRow>().toList();
    expect(rows.length, 3);
    final firstRowCells = rows.first.children.whereType<TableCell>().toList();
    expect(firstRowCells.first.element.textContent, 'a',
        reason: 'converted row returns to the top of the body');
    expect(firstRowCells[1].element.getAttribute('colspan'), '2');
  });

  test('copyTableData serializes the whole table with a leading paragraph',
      () {
    final scroll = createScroll(
      _tableHtml,
      registry: createRegistry(registerTableBetterFormats()),
    );
    final table = scroll.descendants<TableContainer>().first;
    final selection = CellSelection(table);

    final data = selection.copyTableData();

    expect(data.html, startsWith('<p><br></p>'));
    expect(data.html, contains('<table'));
    expect(data.html, isNot(contains('data-cell=')));
    expect(data.text.split('\n').length, 3);
    expect(data.text, contains('a\tb'));
    expect(data.text, contains('f\tg'));
  });

  test('copies and cuts selected cells as table html and TSV text', () {
    final scroll = createScroll(
      _tableHtml,
      registry: createRegistry(registerTableBetterFormats()),
    );
    final table = scroll.descendants<TableContainer>().first;
    final selection = CellSelection(table);
    selection.select(startRow: 0, startColumn: 0, endRow: 1, endColumn: 1);

    final copied = selection.copyData();
    expect(copied.html, contains('<table><tbody><tr>'));
    expect(copied.html, isNot(contains('data-cell=')));
    expect(copied.text, contains('a\tb'));

    final cut = selection.cutData();
    expect(cut.text, copied.text);
    expect(
      selection.selectedCells.every(
        (cell) => cell.children.whereType<TableCellBlock>().every(
              (block) => (block.element.textContent ?? '').trim().isEmpty,
            ),
      ),
      isTrue,
    );
  });
}
