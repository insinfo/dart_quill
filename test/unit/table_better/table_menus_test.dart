import 'package:dart_quill/src/core/selection.dart';
import 'package:dart_quill/src/platform/dom.dart';
import 'package:dart_quill/src/table_better/formats/table.dart';
import 'package:dart_quill/src/table_better/language/language.dart';
import 'package:dart_quill/src/table_better/register.dart';
import 'package:dart_quill/src/table_better/table_better.dart';
import 'package:dart_quill/src/table_better/ui/table_menus.dart';
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

  TableBetter createModule() {
    final quill = createTestQuill(
      modules: {'table-better': const <String, dynamic>{}},
    );
    return quill.getModule('table-better') as TableBetter;
  }

  List<DomElement> menusOf(TableMenus menus) =>
      menus.root.querySelectorAll('[data-category]');

  group('table-better menus config', () {
    test('the default set matches upstream, in order', () {
      final config = getMenusConfig(Language('en_US'));
      expect(
        config.map((menu) => menu.name).toList(),
        equals(['column', 'row', 'merge', 'table', 'cell', 'wrap', 'delete']),
      );
      // `copy` is EXTRA: only reachable through an explicit `menus` option.
      expect(config.any((menu) => menu.name == 'copy'), isFalse);
    });

    test('an explicit menus option filters and reorders, copy included', () {
      final config =
          getMenusConfig(Language('en_US'), const ['copy', 'delete', 'nope']);
      expect(
          config.map((menu) => menu.name).toList(), equals(['copy', 'delete']));
    });

    test('labels come from the active language', () {
      final english = getMenusConfig(Language('en_US')).first;
      final portuguese = getMenusConfig(Language('pt_BR')).first;
      expect(english.content, equals(Language('en_US').useLanguage('col')));
      expect(portuguese.content, equals(Language('pt_BR').useLanguage('col')));
      expect(english.content, isNot(equals(portuguese.content)));
    });
  });

  group('table-better menus DOM', () {
    test('builds one hidden dropdown per menu with tooltip and icon', () {
      final module = createModule();
      final menus = module.tableMenus;

      expect(menus.root.classes.contains('ql-table-menus-container'), isTrue);
      expect(menus.root.classes.contains('ql-hidden'), isTrue);

      final entries = menusOf(menus);
      expect(entries.length, equals(7));
      expect(entries.first.getAttribute('data-category'), equals('column'));

      final column = entries.first;
      expect(column.querySelectorAll('.ql-table-tooltip').length, equals(1));
      expect(
          column.querySelectorAll('.ql-table-dropdown-list').length, equals(1));
      final items = column
          .querySelectorAll('.ql-table-dropdown-list')[0]
          .querySelectorAll('li');
      expect(items.length, equals(4));
      expect(
          items.first.text, equals(Language('en_US').useLanguage('insColL')));

      // `delete` has no children, so it gets no list.
      final delete = entries.firstWhere(
          (entry) => entry.getAttribute('data-category') == 'delete');
      expect(delete.querySelectorAll('.ql-table-dropdown-list'), isEmpty);
    });

    test('the row menu carries a header-row switch and a divider', () {
      final module = createModule();
      final row = menusOf(module.tableMenus)
          .firstWhere((entry) => entry.getAttribute('data-category') == 'row');
      final list = row.querySelectorAll('.ql-table-dropdown-list').first;
      expect(list.querySelectorAll('.ql-table-header-row').length, equals(1));
      expect(list.querySelectorAll('.ql-table-divider').length, equals(1));
      // header + divider + above/below/delete/select
      expect(list.querySelectorAll('li').length, equals(6));

      final switchInner = row.querySelectorAll('.ql-table-switch-inner').first;
      expect(switchInner.getAttribute('aria-checked'), equals('false'));
      module.tableMenus.toggleHeaderRowSwitch();
      expect(switchInner.getAttribute('aria-checked'), equals('true'));
      module.tableMenus.toggleHeaderRowSwitch('false');
      expect(switchInner.getAttribute('aria-checked'), equals('false'));
    });

    test('toggleAttribute opens one list at a time', () {
      final module = createModule();
      final menus = module.tableMenus;
      final entries = menusOf(menus);
      final columnList =
          entries[0].querySelectorAll('.ql-table-dropdown-list').first;
      final columnTooltip =
          entries[0].querySelectorAll('.ql-table-tooltip').first;
      final rowList =
          entries[1].querySelectorAll('.ql-table-dropdown-list').first;
      final rowTooltip = entries[1].querySelectorAll('.ql-table-tooltip').first;

      menus.toggleAttribute(columnList, columnTooltip);
      expect(columnList.classes.contains('ql-hidden'), isFalse);

      menus.toggleAttribute(rowList, rowTooltip);
      expect(columnList.classes.contains('ql-hidden'), isTrue,
          reason: 'opening another menu closes the previous list');
      expect(rowList.classes.contains('ql-hidden'), isFalse);
    });

    test('disableMenu toggles ql-table-disabled by category', () {
      final module = createModule();
      final menus = module.tableMenus;
      final merge = menusOf(menus).firstWhere(
          (entry) => entry.getAttribute('data-category') == 'merge');

      menus.disableMenu('merge', true);
      expect(merge.classes.contains('ql-table-disabled'), isTrue);
      menus.disableMenu('merge', false);
      expect(merge.classes.contains('ql-table-disabled'), isFalse);
    });

    test('show/hide toggle the container', () {
      final menus = createModule().tableMenus;
      menus.showMenus();
      expect(menus.root.classes.contains('ql-hidden'), isFalse);
      menus.hideMenus();
      expect(menus.root.classes.contains('ql-hidden'), isTrue);
    });
  });

  group('table-better menus actions', () {
    TableBetter withTable({int rows = 2, int columns = 2}) {
      final module = createModule();
      module.quill.setSelection(const Range(0, 0));
      module.insertTable(rows, columns);
      // Park the caret inside the table so `getTable()` resolves it.
      final table = module.quill.scroll.descendants<TableContainer>().single;
      final block = table.descendants<TableCellBlock>().first;
      module.quill.setSelection(Range(module.quill.scroll.offset(block), 0));
      return module;
    }

    test('insertTable reveals the menus over the new table', () {
      final module = withTable();
      expect(module.tableMenus.root.classes.contains('ql-hidden'), isFalse);
      expect(module.tableMenus.table, isNotNull);
      final table = module.getTable().table!;
      expect(identical(module.tableMenus.table, table.element), isTrue);
    });

    test('insertRow below adds a row and keeps the menus in sync', () {
      final module = withTable();
      final table = module.getTable().table!;
      expect(table.descendants<TableRow>().length, equals(2));

      module.tableMenus.insertRow(1);
      expect(table.descendants<TableRow>().length, equals(3));
    });

    test('deleteRow removes the selected row', () {
      final module = withTable(rows: 3, columns: 2);
      final table = module.getTable().table!;
      final selection = module.controllerFor(table).selection;
      selection.select(startRow: 1, startColumn: 0, endRow: 1, endColumn: 1);

      module.tableMenus.deleteRow();
      expect(table.descendants<TableRow>().length, equals(2));
    });

    test('deleteColumn removes the selected column from every row', () {
      final module = withTable(rows: 2, columns: 3);
      final table = module.getTable().table!;
      final selection = module.controllerFor(table).selection;
      selection.select(startRow: 0, startColumn: 1, endRow: 1, endColumn: 1);

      module.tableMenus.deleteColumn();
      for (final row in table.descendants<TableRow>()) {
        expect(row.children.whereType<TableCell>().length, equals(2));
      }
    });

    test('deleteTable drops the table and hides the menus', () {
      final module = withTable();
      module.tableMenus.deleteTable();
      expect(module.quill.scroll.descendants<TableContainer>(), isEmpty);
      expect(module.tableMenus.root.classes.contains('ql-hidden'), isTrue);
    });

    test('selectRow/selectColumn widen the selection to the whole line', () {
      final module = withTable(rows: 3, columns: 3);
      final table = module.getTable().table!;
      final selection = module.controllerFor(table).selection;
      selection.select(startRow: 1, startColumn: 1, endRow: 1, endColumn: 1);

      module.tableMenus.selectRow();
      expect(selection.selectedCells.length, equals(3));

      selection.select(startRow: 1, startColumn: 1, endRow: 1, endColumn: 1);
      module.tableMenus.selectColumn();
      expect(selection.selectedCells.length, equals(3));
    });

    test('insertParagraph adds a line before/after the table', () {
      final module = withTable();
      final before = module.quill.getLength();
      module.tableMenus.insertParagraph(1);
      expect(module.quill.getLength(), greaterThan(before));
    });

    test('the header-row menu converts the selected row to <th>', () {
      final module = withTable();
      final table = module.getTable().table!;
      final selection = module.controllerFor(table).selection;
      selection.select(startRow: 0, startColumn: 0, endRow: 0, endColumn: 1);

      module.tableMenus.toggleHeaderRow();
      expect(table.thead(), isNotNull);
      expect(table.descendants<TableTh>().length, equals(2));

      // Toggling again on the header row converts it back.
      final thead = table.thead()!;
      final ths = thead.descendants<TableTh>().toList();
      selection
          .setSelectedTds(ths.map((th) => th.element).toList(growable: false));
      module.tableMenus.toggleHeaderRow();
      expect(table.descendants<TableTh>(), isEmpty);
    });

    test('copyTable returns the serialized table and moves the caret past it',
        () {
      final module = withTable();
      final data = module.tableMenus.copyTable();
      expect(data, isNotNull);
      expect(data!.html, startsWith('<p><br></p>'));
      expect(data.html, contains('<table'));
      expect(module.tableMenus.root.classes.contains('ql-hidden'), isTrue);
    });

    test('merge then split round-trips the grid', () {
      final module = withTable();
      final table = module.getTable().table!;
      final selection = module.controllerFor(table).selection;
      selection.select(startRow: 0, startColumn: 0, endRow: 0, endColumn: 1);

      module.tableMenus.mergeCells();
      final merged = table.descendants<TableCell>().first;
      expect(merged.element.getAttribute('colspan'), equals('2'));

      selection.setSelectedTds([merged.element]);
      module.tableMenus.splitCell();
      expect(merged.element.getAttribute('colspan'), isNull);
      expect(
        table
            .descendants<TableRow>()
            .first
            .children
            .whereType<TableCell>()
            .length,
        equals(2),
      );
    });
  });

  group('table-better menus positioning', () {
    TableBetter withTableForPositioning() {
      final module = createModule();
      module.quill.setSelection(const Range(0, 0));
      module.insertTable(2, 2);
      final table = module.quill.scroll.descendants<TableContainer>().single;
      final block = table.descendants<TableCellBlock>().first;
      module.quill.setSelection(Range(module.quill.scroll.offset(block), 0));
      return module;
    }

    test('updateMenus writes left/top and picks a triangle direction', () {
      final module = withTableForPositioning();
      final menus = module.tableMenus;

      menus.updateMenus();
      final style = menus.root.getAttribute('style') ?? '';
      expect(style, contains('left'));
      expect(style, contains('top'));
      expect(
        menus.root.classes.contains('ql-table-triangle-up') ||
            menus.root.classes.contains('ql-table-triangle-down'),
        isTrue,
      );
    });
  });
}
