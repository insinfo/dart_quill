import 'package:dart_quill/src/blots/scroll.dart';
import 'package:dart_quill/src/table_better/config/config.dart';
import 'package:dart_quill/src/table_better/formats/table.dart';
import 'package:dart_quill/src/table_better/language/language.dart';
import 'package:dart_quill/src/table_better/register.dart';
import 'package:dart_quill/src/table_better/utils/utils.dart' as utils;
import 'package:test/test.dart';

import '../../support/test_helpers.dart';

Scroll _createTableScroll(String html) {
  return createScroll(
    html,
    registry: createRegistry(registerTableBetterFormats()),
  );
}

const String _twoByTwo = '''
  <table class="ql-table-better">
    <tbody>
      <tr>
        <td data-row="row-a"><p class="ql-table-block" data-cell="cell-1">a1</p></td>
        <td data-row="row-a"><p class="ql-table-block" data-cell="cell-2">a2</p></td>
      </tr>
      <tr>
        <td data-row="row-b"><p class="ql-table-block" data-cell="cell-3">b1</p></td>
        <td data-row="row-b"><p class="ql-table-block" data-cell="cell-4">b2</p></td>
      </tr>
    </tbody>
  </table>
''';

const String _twoByTwoWithColgroup = '''
  <table class="ql-table-better">
    <colgroup>
      <col width="72">
      <col width="72">
    </colgroup>
    <tbody>
      <tr>
        <td data-row="row-a"><p class="ql-table-block" data-cell="cell-1">a1</p></td>
        <td data-row="row-a"><p class="ql-table-block" data-cell="cell-2">a2</p></td>
      </tr>
      <tr>
        <td data-row="row-b"><p class="ql-table-block" data-cell="cell-3">b1</p></td>
        <td data-row="row-b"><p class="ql-table-block" data-cell="cell-4">b2</p></td>
      </tr>
    </tbody>
  </table>
''';

TableContainer _tableOf(Scroll scroll) =>
    scroll.descendants<TableContainer>().first;

List<TableRow> _rowsOf(TableContainer table) =>
    table.tbody()!.children.whereType<TableRow>().toList();

void main() {
  setUpAll(initializeFakeDom);

  group('table-better ids', () {
    test('cellId/tableId have the expected prefixes', () {
      expect(cellId(), startsWith('cell-'));
      expect(tableId(), startsWith('row-'));
      expect(cellId().length, 'cell-'.length + 4);
      expect(tableId().length, 'row-'.length + 4);
    });
  });

  group('table-better hydration', () {
    test('builds container > colgroup + tbody > tr > td > p.ql-table-block',
        () {
      final scroll = _createTableScroll(_twoByTwoWithColgroup);
      final table = _tableOf(scroll);

      expect(table.children.length, 2);
      expect(table.children[0], isA<TableColgroup>());
      expect(table.children[1], isA<TableBody>());

      final colgroup = table.colgroup()!;
      final cols = colgroup.children.whereType<TableCol>().toList();
      expect(cols.length, 2);
      expect(cols.first.element.getAttribute('width'), '72');

      final rows = _rowsOf(table);
      expect(rows.length, 2);
      for (final row in rows) {
        expect(row.children.length, 2);
        for (final child in row.children) {
          expect(child, isA<TableCell>());
          final cell = child as TableCell;
          expect(cell.element.tagName, 'TD');
          expect(cell.children.length, 1);
          final block = cell.children.first;
          expect(block, isA<TableCellBlock>());
          expect(
            (block as TableCellBlock).element.classes.contains(
                  TableCellBlock.kClassName,
                ),
            isTrue,
          );
        }
      }
    });

    test('cellId/tableId propagate through formats()', () {
      final scroll = _createTableScroll(_twoByTwo);
      final table = _tableOf(scroll);
      final rows = _rowsOf(table);
      final cell = rows.first.children.first as TableCell;
      final block = cell.children.first as TableCellBlock;

      final cellFormats = cell.formats()[TableCell.kBlotName] as Map;
      expect(cellFormats['data-row'], 'row-a');
      expect(block.formats()[TableCellBlock.kBlotName], 'cell-1');

      expect(cell.row(), same(rows.first));
      expect(cell.rowOffset(), 0);
      expect(cell.table(), same(table));
      expect(rows.last.rowOffset(), 1);
      expect(utils.getCorrectCellBlot(block), same(cell));
      final (formats, id) = utils.getCellFormats(cell);
      expect(formats['data-row'], 'row-a');
      expect(id, 'cell-1');
    });
  });

  group('table-better optimize', () {
    test('splits a cell whose blocks have different data-cell ids', () {
      final scroll = _createTableScroll('''
        <table class="ql-table-better">
          <tbody>
            <tr>
              <td data-row="row-a">
                <p class="ql-table-block" data-cell="cell-1">A</p>
                <p class="ql-table-block" data-cell="cell-2">B</p>
              </td>
            </tr>
          </tbody>
        </table>
      ''');
      final table = _tableOf(scroll);
      final rows = _rowsOf(table);
      expect(rows.length, 1);
      expect(rows.first.children.length, 2);
      final first = rows.first.children.first as TableCell;
      final second = rows.first.children.last as TableCell;
      expect(first.children.length, 1);
      expect(second.children.length, 1);
      expect(
        (second.children.first as TableCellBlock).element
            .getAttribute('data-cell'),
        'cell-2',
      );
      // The split clone keeps the original cell attributes.
      expect(second.element.getAttribute('data-row'), 'row-a');
    });

    test('merges adjacent cells whose blocks share the same data-cell id', () {
      final scroll = _createTableScroll('''
        <table class="ql-table-better">
          <tbody>
            <tr>
              <td data-row="row-a"><p class="ql-table-block" data-cell="cell-1">A</p></td>
              <td data-row="row-a"><p class="ql-table-block" data-cell="cell-1">B</p></td>
            </tr>
          </tbody>
        </table>
      ''');
      final table = _tableOf(scroll);
      final rows = _rowsOf(table);
      expect(rows.length, 1);
      expect(rows.first.children.length, 1);
      final cell = rows.first.children.first as TableCell;
      expect(cell.children.length, 2);
    });

    test('table-temporary attributes roundtrip onto the table element', () {
      final scroll = _createTableScroll('<p><br></p>');
      final table = TableContainer.create();
      final temporary = TableTemporary.create({
        'border': '1',
        'cellspacing': '0',
        'data-class': 'custom',
      });
      table.appendChild(temporary);
      scroll.appendChild(table);
      scroll.optimize([], {});

      // `data-class` is prefixed with the default class on create.
      expect(
        temporary.element.getAttribute('data-class'),
        'ql-table-better custom',
      );
      expect(table.element.getAttribute('border'), '1');
      expect(table.element.getAttribute('cellspacing'), '0');
      expect(table.element.getAttribute('class'), 'ql-table-better custom');
      final formats =
          temporary.formats()[TableTemporary.kBlotName] as Map;
      expect(formats['data-class'], 'ql-table-better custom');
      expect(formats['border'], '1');

      // Repeated optimize passes are stable.
      scroll.optimize([], {});
      expect(table.element.getAttribute('class'), 'ql-table-better custom');
    });

    test('removes duplicated table-temporary blots keeping the first', () {
      final scroll = _createTableScroll('<p><br></p>');
      final table = TableContainer.create();
      table.appendChild(TableTemporary.create({'border': '1'}));
      table.appendChild(TableTemporary.create({'border': '2'}));
      scroll.appendChild(table);
      scroll.optimize([], {});
      expect(table.descendants<TableTemporary>().toList().length, 1);
    });
  });

  group('table-better structure edits (2x2)', () {
    test('insertRow in the middle builds a matching row with fresh ids', () {
      final scroll = _createTableScroll(_twoByTwo);
      final table = _tableOf(scroll);
      table.insertRow(1, 0);

      final rows = _rowsOf(table);
      expect(rows.length, 3);
      final newRow = rows[1];
      expect(newRow.children.length, 2);
      final ids = newRow.children
          .map((c) => (c as TableCell).element.getAttribute('data-row'))
          .toSet();
      expect(ids.length, 1);
      expect(ids.first, startsWith('row-'));
      expect(ids.first, isNot(anyOf('row-a', 'row-b')));
      for (final child in newRow.children) {
        final cell = child as TableCell;
        expect(cell.element.getAttribute('height'), '24');
        expect(cell.children.first, isA<TableCellBlock>());
      }
      // Existing rows untouched.
      expect(
        (rows.first.children.first as TableCell).element
            .getAttribute('data-row'),
        'row-a',
      );
      expect(
        (rows.last.children.first as TableCell).element
            .getAttribute('data-row'),
        'row-b',
      );
    });

    test('insertRow past the end appends a row', () {
      final scroll = _createTableScroll(_twoByTwo);
      final table = _tableOf(scroll);
      table.insertRow(2, 1);
      final rows = _rowsOf(table);
      expect(rows.length, 3);
      expect(rows.last.children.length, 2);
      expect(
        (rows.last.children.first as TableCell).element
            .getAttribute('data-row'),
        isNot(anyOf('row-a', 'row-b')),
      );
    });

    test('insertColumn as last column appends cells and a col', () {
      final scroll = _createTableScroll(_twoByTwoWithColgroup);
      final table = _tableOf(scroll);
      table.insertColumn(0, true, 72, 1);

      final rows = _rowsOf(table);
      for (final row in rows) {
        expect(row.children.length, 3);
        final last = row.children.last as TableCell;
        expect(
          last.element.getAttribute('data-row'),
          (row.children.first as TableCell).element.getAttribute('data-row'),
        );
        expect(last.children.first, isA<TableCellBlock>());
        // With a colgroup present no cell width is written.
        expect(last.element.hasAttribute('width'), isFalse);
      }
      final cols = table.colgroup()!.children.whereType<TableCol>().toList();
      expect(cols.length, 3);
      expect(cols.last.element.getAttribute('width'), '$cellDefaultWidth');
    });

    test('insertColumnCell inserts before a reference cell', () {
      final scroll = _createTableScroll(_twoByTwo);
      final table = _tableOf(scroll);
      final row = _rowsOf(table).first;
      final ref = row.children.last as TableCell;
      final cell = table.insertColumnCell(row, 'row-a', ref);

      expect(row.children.length, 3);
      expect(row.children[1], same(cell));
      expect(cell.element.getAttribute('data-row'), 'row-a');
      // No colgroup: the default width is written onto the cell.
      expect(cell.element.getAttribute('width'), '$cellDefaultWidth');
    });

    test('deleteColumn removes one cell per row', () {
      final scroll = _createTableScroll(_twoByTwo);
      final table = _tableOf(scroll);
      final delTds = _rowsOf(table)
          .map((row) => (row.children.first as TableCell).element)
          .toList();
      table.deleteColumn([], delTds, table.deleteTable);

      final rows = _rowsOf(table);
      expect(rows.length, 2);
      for (final row in rows) {
        expect(row.children.length, 1);
      }
      expect(
        (rows.first.children.first as TableCell).element.text,
        contains('a2'),
      );
    });

    test('deleteColumn covering every cell deletes the table', () {
      final scroll = _createTableScroll(_twoByTwo);
      final table = _tableOf(scroll);
      final delTds = [
        for (final row in _rowsOf(table))
          for (final child in row.children) (child as TableCell).element,
      ];
      table.deleteColumn([], delTds, table.deleteTable);
      expect(scroll.descendants<TableContainer>().toList(), isEmpty);
    });

    test('deleteRow removes the given rows', () {
      final scroll = _createTableScroll(_twoByTwo);
      final table = _tableOf(scroll);
      final rows = _rowsOf(table);
      table.deleteRow([rows.first], table.deleteTable);

      final remaining = _rowsOf(table);
      expect(remaining.length, 1);
      expect(
        (remaining.first.children.first as TableCell).element.text,
        contains('b1'),
      );
    });

    test('deleteRow covering every row deletes the table', () {
      final scroll = _createTableScroll(_twoByTwo);
      final table = _tableOf(scroll);
      table.deleteRow(_rowsOf(table), table.deleteTable);
      expect(scroll.descendants<TableContainer>().toList(), isEmpty);
    });

    test('getMaxColumns honours colspan', () {
      final scroll = _createTableScroll('''
        <table class="ql-table-better">
          <tbody>
            <tr>
              <td data-row="row-a" colspan="2"><p class="ql-table-block" data-cell="cell-1">a</p></td>
              <td data-row="row-a"><p class="ql-table-block" data-cell="cell-2">b</p></td>
            </tr>
          </tbody>
        </table>
      ''');
      final table = _tableOf(scroll);
      expect(table.getMaxColumns(_rowsOf(table).first.children), 3);
    });

    test('setCellColspan rewrites the colspan attribute', () {
      final scroll = _createTableScroll(_twoByTwo);
      final table = _tableOf(scroll);
      final row = _rowsOf(table).first;
      final cell = row.children.first as TableCell;
      table.setCellColspan(cell, 1);
      final replaced = row.children.first as TableCell;
      expect(replaced.element.getAttribute('colspan'), '2');
      expect(replaced.element.getAttribute('data-row'), 'row-a');
      // Children were moved into the replacement.
      expect(replaced.children.first, isA<TableCellBlock>());

      table.setCellColspan(replaced, -1);
      final restored = row.children.first as TableCell;
      expect(restored.element.hasAttribute('colspan'), isFalse);
    });
  });

  group('table-better TableCellBlock.format', () {
    test('wrapping with table-cell builds row > cell around the block', () {
      final scroll = _createTableScroll(
        '<p class="ql-table-block" data-cell="cell-x">hi</p>',
      );
      final block = scroll.children.first as TableCellBlock;
      block.format(TableCell.kBlotName, {'data-row': 'row-x'});

      expect(block.parent, isA<TableCell>());
      final cell = block.parent as TableCell;
      expect(cell.element.getAttribute('data-row'), 'row-x');
      expect(cell.parent, isA<TableRow>());
    });
  });

  group('table-better getCopyTable', () {
    test('strips temporary elements and data attributes from copies', () {
      final scroll = _createTableScroll(_twoByTwo);
      final table = _tableOf(scroll);
      table.appendChild(TableTemporary.create({'border': '1'}));
      final copied = table.getCopyTable();
      expect(copied, isNot(contains('<temporary')));
      expect(copied, contains('<td'));
      expect(copied, isNot(contains('data-row')));
    });
  });

  group('table-better utils', () {
    test('convertUnitToInteger rounds and keeps units', () {
      expect(utils.convertUnitToInteger('10.6px'), '11px');
      expect(utils.convertUnitToInteger('2em'), '2em');
      expect(utils.convertUnitToInteger('50%'), '50%');
      expect(utils.convertUnitToInteger(null), isNull);
      expect(utils.convertUnitToInteger(''), '');
    });

    test('addDimensionsUnit appends px only to bare numbers', () {
      expect(utils.addDimensionsUnit('10'), '10px');
      expect(utils.addDimensionsUnit('2em'), '2em');
      expect(utils.addDimensionsUnit(''), '');
    });

    test('isValidColor accepts hex, rgb and named colors', () {
      expect(utils.isValidColor(''), isTrue);
      expect(utils.isValidColor('#FF0000'), isTrue);
      expect(utils.isValidColor('rgb(255, 0, 0)'), isTrue);
      expect(utils.isValidColor('red'), isTrue);
      expect(utils.isValidColor('definitely-not-a-color'), isFalse);
    });

    test('isValidDimensions accepts px/em/% and bare numbers', () {
      expect(utils.isValidDimensions(''), isTrue);
      expect(utils.isValidDimensions('10px'), isTrue);
      expect(utils.isValidDimensions('2em'), isTrue);
      expect(utils.isValidDimensions('50%'), isTrue);
      expect(utils.isValidDimensions('10'), isTrue);
      expect(utils.isValidDimensions('10vw'), isFalse);
    });

    test('rgbToHex/rgbaToHex convert color strings', () {
      expect(utils.rgbToHex('rgb(255, 0, 0)'), '#ff0000');
      expect(utils.rgbToHex('#123456'), '#123456');
      expect(utils.rgbaToHex('rgba(255, 0, 0, 0.5)'), '#ff000080');
    });

    test('filterWordStyle strips mso declarations', () {
      expect(
        utils.filterWordStyle('mso-border-alt:solid;width:10px;'),
        'width:10px;',
      );
    });

    test('getCopyTd removes data attributes and table classes', () {
      final result = utils
          .getCopyTd('<td data-row="r1" class="ql-cell-selected">x</td>');
      expect(result, isNot(contains('data-row')));
      expect(result, isNot(contains('class')));
      expect(result, contains('>x</td>'));
    });

    test('getComputeBounds combines two bounds', () {
      const a = utils.CorrectBound(left: 10, top: 10, right: 50, bottom: 40);
      const b = utils.CorrectBound(left: 30, top: 5, right: 80, bottom: 30);
      final combined = utils.getComputeBounds(a, b);
      expect(combined.left, 10);
      expect(combined.top, 5);
      expect(combined.right, 80);
      expect(combined.bottom, 40);
    });

    test('setElementProperty and removeElementProperty edit inline styles',
        () {
      final scroll = _createTableScroll('<p><br></p>');
      final node = scroll.element;
      utils.setElementProperty(node, {'width': '10px', 'height': '5px'});
      expect(utils.getInlineStyleValue(node, 'width'), '10px');
      utils.removeElementProperty(node, ['width']);
      expect(utils.getInlineStyleValue(node, 'width'), isNull);
      expect(utils.getInlineStyleValue(node, 'height'), '5px');
      utils.removeElementProperty(node, ['height']);
      expect(node.hasAttribute('style'), isFalse);
    });

    test('layout-dependent helpers throw until a rect resolver is installed',
        () {
      final scroll = _createTableScroll(_twoByTwo);
      final table = _tableOf(scroll);
      final cell = _rowsOf(table).first.children.first as TableCell;
      expect(
        () => utils.getCorrectBounds(cell.element),
        throwsUnimplementedError,
      );
    });
  });

  group('table-better language', () {
    test('defaults to en_US', () {
      final language = Language();
      expect(language.name, 'en_US');
      expect(language.useLanguage('col'), 'Column');
      expect(language.useLanguage('tblProps'), 'Table properties');
    });

    test('changeLanguage switches locales', () {
      final language = Language('pt_BR');
      expect(language.useLanguage('col'), 'Coluna');
      expect(language.useLanguage('delTable'), 'Excluir tabela');
      language.changeLanguage('en_US');
      expect(language.useLanguage('col'), 'Column');
    });

    test('registry adds custom locales through LanguageConfig', () {
      final language = Language(
        const LanguageConfig(name: 'xx_XX', content: {'col': 'Kolona'}),
      );
      expect(language.name, 'xx_XX');
      expect(language.useLanguage('col'), 'Kolona');
      expect(language.useLanguage('missing'), '');
    });
  });

  group('table-better config', () {
    String useLanguage(String name) => Language().useLanguage(name);

    test('getProperties dispatches on type', () {
      final tableForm = getProperties(
        const PropertiesOptions(type: 'table', attribute: {'width': '100px'}),
        useLanguage,
      );
      expect(tableForm.title, 'Table properties');
      expect(tableForm.properties.length, 3);

      final cellForm = getProperties(
        const PropertiesOptions(type: 'cell', attribute: {'width': '100px'}),
        useLanguage,
      );
      expect(cellForm.title, 'Cell properties');
      expect(cellForm.properties.length, 4);
    });

    test('cell properties carry values, validators and menus', () {
      final form = getCellProperties(
        {'border-style': 'solid', 'width': '72.4px'},
        useLanguage,
      );
      final border = form.properties.first.children.first;
      expect(border.category, 'dropdown');
      expect(border.value, 'solid');
      expect(border.options, contains('dashed'));

      final width = form.properties[2].children.first;
      expect(width.value, '72px'); // convertUnitToInteger applied
      expect(width.valid!('10px'), isTrue);
      expect(width.valid!('10vw'), isFalse);

      final textAlign = form.properties[3].children.first;
      expect(textAlign.menus!.length, 4);
      expect(textAlign.menus!.first.align, 'left');
    });
  });
}
