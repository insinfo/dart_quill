import 'package:dart_quill/src/core/selection.dart';
import 'package:dart_quill/src/modules/toolbar.dart';
import 'package:dart_quill/src/table_better/formats/header.dart';
import 'package:dart_quill/src/table_better/formats/list.dart';
import 'package:dart_quill/src/table_better/formats/table.dart';
import 'package:dart_quill/src/table_better/register.dart';
import 'package:dart_quill/src/table_better/table_better.dart';
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

  ({TableBetter module, TableContainer table}) withTable(
      {int rows = 2, int columns = 2}) {
    final quill = createTestQuill(
      theme: 'snow',
      modules: {
        'toolbar': ToolbarProps(
          container: ToolbarConfig(const [
            ['header', 'list', 'align']
          ]),
        ),
        'table-better': const <String, dynamic>{},
      },
    );
    final module = quill.getModule('table-better') as TableBetter;
    quill.setSelection(const Range(0, 0));
    module.insertTable(rows, columns);
    final table = quill.scroll.descendants<TableContainer>().single;
    final block = table.descendants<TableCellBlock>().first;
    quill.setSelection(Range(quill.scroll.offset(block), 0));
    return (module: module, table: table);
  }

  group('routing', () {
    test('with no cells selected the toolbar keeps its own behaviour', () {
      final quill = createTestQuill(
        theme: 'snow',
        modules: {
          'toolbar': ToolbarProps(
            container: ToolbarConfig(const [
              ['header']
            ]),
          ),
          'table-better': const <String, dynamic>{},
        },
      );
      final module = quill.getModule('table-better') as TableBetter;
      quill.setContents(quill.clipboard.convert(html: '<p>plain</p>'));
      quill.setSelection(const Range(0, 0));

      module.toolbarRouter.handle('header', 1);

      expect(quill.getFormat(0)['header'], equals(1));
    });

    test('with cells selected the format reaches every selected cell', () {
      final (:module, :table) = withTable();
      final controller = module.controllerFor(table);
      controller.setSelectedTds(
        table.descendants<TableCell>().take(2).map((c) => c.element).toList(),
      );

      module.toolbarRouter.handle('header', 2);

      final headers = table.descendants<TableHeader>().toList();
      expect(headers, hasLength(2));
      for (final header in headers) {
        expect(header.formats()[TableHeader.kBlotName]['value'], equals(2));
      }
    });

    test('list turns the selected cell blocks into table list items', () {
      final (:module, :table) = withTable();
      final controller = module.controllerFor(table);
      controller.setSelectedTds(
        table.descendants<TableCell>().take(2).map((c) => c.element).toList(),
      );

      module.toolbarRouter.handle('list', 'bullet');

      expect(table.descendants<TableList>(), hasLength(2));
      expect(table.descendants<TableListContainer>(), hasLength(2));
    });

    test('list toggles off, restoring cell blocks', () {
      final (:module, :table) = withTable();
      final controller = module.controllerFor(table);
      final cells =
          table.descendants<TableCell>().take(2).map((c) => c.element).toList();
      controller.setSelectedTds(cells);

      module.toolbarRouter.handle('list', 'bullet');
      expect(table.descendants<TableList>(), hasLength(2));

      controller.setSelectedTds(cells);
      module.toolbarRouter.handle('list', 'bullet');
      expect(table.descendants<TableList>(), isEmpty);
      expect(table.descendants<TableCellBlock>().length, greaterThan(0));
    });

    test('an inline line format applies to each selected cell line', () {
      final (:module, :table) = withTable();
      final controller = module.controllerFor(table);
      controller.setSelectedTds(
        table.descendants<TableCell>().take(2).map((c) => c.element).toList(),
      );

      module.toolbarRouter.handle('align', 'center');

      final blocks = table.descendants<TableCellBlock>().take(2);
      for (final block in blocks) {
        expect(block.formats()['align'], equals('center'));
      }
    });
  });

  group('isReplace', () {
    test('a multi-cell selection always replaces', () {
      final (:module, :table) = withTable();
      final cells = table.descendants<TableCell>().take(2).toList();
      expect(
        module.toolbarRouter.isReplace(const Range(0, 0), cells, const []),
        isTrue,
      );
    });

    test('a single cell covered entirely replaces, a partial one does not', () {
      final (:module, :table) = withTable();
      final cell = table.descendants<TableCell>().first;
      final router = module.toolbarRouter;

      // No containers inside the cell: lengths match only for an empty line
      // list, which is the "covers nothing" case upstream treats as replace.
      expect(router.containersOf(cell), isEmpty);
      expect(router.isReplace(const Range(0, 0), [cell], const []), isTrue);
      expect(
        router.isReplace(const Range(0, 0), [cell], router.linesOf(cell)),
        isFalse,
      );
    });

    test('a single header line turning into a list always replaces', () {
      final (:module, :table) = withTable();
      final cell = table.descendants<TableCell>().first;
      final block = cell.children.first;
      block.format('header', 2);
      final header = table.descendants<TableHeader>().first;

      expect(
        module.toolbarRouter.headerReplace([cell], 'list', header, false),
        isTrue,
      );
      expect(
        module.toolbarRouter.headerReplace([cell], 'align', header, false),
        isFalse,
      );
    });
  });

  group('list tri-state', () {
    test('check on an unlisted line yields unchecked', () {
      final (:module, :table) = withTable();
      final controller = module.controllerFor(table);
      controller.setSelectedTds([table.descendants<TableCell>().first.element]);

      expect(
        module.toolbarRouter.listCorrectValue('check', controller.selection),
        equals('unchecked'),
      );
    });

    test('a plain value passes through untouched', () {
      final (:module, :table) = withTable();
      final controller = module.controllerFor(table);
      controller.setSelectedTds([table.descendants<TableCell>().first.element]);

      expect(
        module.toolbarRouter.listCorrectValue('bullet', controller.selection),
        equals('bullet'),
      );
    });
  });

  group('cross-format branches', () {
    test('a cell block becomes a header and back', () {
      final (module: _, :table) = withTable();
      final cell = table.descendants<TableCell>().first;

      cell.children.first.format('header', 1);
      expect(table.descendants<TableHeader>(), hasLength(1));

      table.descendants<TableHeader>().first.format('header', false);
      expect(table.descendants<TableHeader>(), isEmpty);
      expect(cell.children.first, isA<TableCellBlock>());
    });

    test('a cell block becomes a list item inside a list container', () {
      final (module: _, :table) = withTable();
      final cell = table.descendants<TableCell>().first;
      final id = (cell.children.first as TableCellBlock)
          .element
          .getAttribute('data-cell');

      cell.children.first.format('list', 'bullet');

      final container = table.descendants<TableListContainer>().single;
      expect(container.element.getAttribute('data-cell'), equals(id));
      expect(table.descendants<TableList>(), hasLength(1));
    });

    test('a header becomes a list item, keeping the cell id', () {
      final (module: _, :table) = withTable();
      final cell = table.descendants<TableCell>().first;
      cell.children.first.format('header', 2);
      final header = table.descendants<TableHeader>().single;

      header.format('list', 'ordered', true);

      expect(table.descendants<TableHeader>(), isEmpty);
      expect(table.descendants<TableList>(), hasLength(1));
    });

    test('a list item becomes a header', () {
      final (module: _, :table) = withTable();
      final cell = table.descendants<TableCell>().first;
      cell.children.first.format('list', 'bullet');
      final item = table.descendants<TableList>().single;

      item.format('header', 3, true);

      expect(table.descendants<TableList>(), isEmpty);
      expect(table.descendants<TableHeader>(), hasLength(1));
    });
  });
}
