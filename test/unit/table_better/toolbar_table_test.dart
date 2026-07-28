import 'package:dart_quill/src/core/quill.dart';
import 'package:dart_quill/src/core/selection.dart';
import 'package:dart_quill/src/modules/toolbar.dart';
import 'package:dart_quill/src/table_better/formats/table.dart';
import 'package:dart_quill/src/table_better/register.dart';
import 'package:dart_quill/src/table_better/table_better.dart';
import 'package:dart_quill/src/table_better/ui/toolbar_table.dart';
import 'package:dart_quill/src/ui/icons.dart';
import 'package:test/test.dart';

import '../../support/fake_dom.dart';
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

  TableBetter createModule({bool toolbarTable = false}) {
    final quill = createTestQuill(
      theme: 'snow',
      modules: {
        'toolbar': ToolbarProps(
          container: ToolbarConfig(const [
            ['bold', 'table-better']
          ]),
        ),
        'table-better': <String, dynamic>{'toolbarTable': toolbarTable},
      },
    );
    return quill.getModule('table-better') as TableBetter;
  }

  group('TableSelect', () {
    test('builds a 10x10 grid with row/column attributes and a 0 x 0 label',
        () {
      final select = TableSelect(document: testAdapter.document);

      expect(select.root.classes.contains('ql-table-select-container'), isTrue);
      expect(select.root.classes.contains('ql-hidden'), isTrue);
      expect(select.cells.length, equals(100));

      final first = select.cells.first;
      expect(select.getSelectAttrs(first), equals((1, 1)));
      expect(select.getSelectAttrs(select.cells.last), equals((10, 10)));

      final label =
          select.root.querySelectorAll('.ql-table-select-label').first;
      expect(label.text, equals('0 x 0'));
    });

    test('highlighting marks the rectangle and updates the label', () {
      final select = TableSelect(document: testAdapter.document);
      final label =
          select.root.querySelectorAll('.ql-table-select-label').first;

      select.highlightTo(3, 4);
      expect(select.computeChildren.length, equals(12));
      expect(label.text, equals('3 x 4'));
      expect(
        select.computeChildren
            .every((cell) => cell.classes.contains('ql-cell-selected')),
        isTrue,
      );

      // A smaller rectangle clears the cells that left it.
      select.highlightTo(2, 2);
      expect(select.computeChildren.length, equals(4));
      expect(label.text, equals('2 x 2'));
      expect(
        select.cells
            .where((cell) => cell.classes.contains('ql-cell-selected'))
            .length,
        equals(4),
      );

      select.clearSelected();
      expect(select.computeChildren, isEmpty);
      expect(label.text, equals('0 x 0'));
    });

    test('show/hide/toggle drive ql-hidden and drop the highlight', () {
      final select = TableSelect(document: testAdapter.document);
      select.highlightTo(2, 2);

      select.show();
      expect(select.isHidden, isFalse);
      expect(select.computeChildren, isEmpty);

      select.highlightTo(2, 2);
      select.hide();
      expect(select.isHidden, isTrue);
      expect(select.computeChildren, isEmpty);

      select.toggle(false);
      expect(select.isHidden, isFalse);
    });

    test('clicking a cell inserts that many rows and columns, then hides', () {
      final select = TableSelect(document: testAdapter.document);
      select.show();
      int? rows;
      int? columns;

      final target = select.cells.firstWhere((cell) {
        final (row, column) = select.getSelectAttrs(cell);
        return row == 3 && column == 5;
      });
      select.handleClick(target, (r, c) {
        rows = r;
        columns = c;
      });

      expect(rows, equals(3));
      expect(columns, equals(5));
      expect(select.isHidden, isTrue);
    });

    test('clicking between cells falls back to the last hovered cell', () {
      final select = TableSelect(document: testAdapter.document);
      select.show();
      select.highlightTo(2, 3);
      int? rows;
      int? columns;

      // The container itself is not a cell — TS `getClickInfo` reports
      // "between spans" and reuses the hover rectangle.
      select.handleClick(select.root, (r, c) {
        rows = r;
        columns = c;
      });

      expect(rows, equals(2));
      expect(columns, equals(3));
    });
  });

  group('ToolbarTable blot', () {
    test('is an inline blot named table-better', () {
      final entry = ToolbarTable.registryEntry;
      expect(entry.blotName, equals('table-better'));
      expect(entry.tagNames, equals(['SPAN']));
    });
  });

  group('registerToolbarTable', () {
    test('does nothing unless the option is enabled', () {
      final module = createModule();
      expect(module.tableSelect, isNull);
      expect(
        module.quill.scroll.registry.contains(ToolbarTable.kBlotName),
        isFalse,
      );
    });

    test('registers the blot, the icon and hangs the grid on the button', () {
      final module = createModule(toolbarTable: true);

      expect(module.tableSelect, isNotNull);
      expect(module.quill.scroll.registry.contains(ToolbarTable.kBlotName),
          isTrue);
      expect(icons['table-better'], isNotNull);
      expect(Quill.importDefinition('formats/table-better'), isNotNull);

      final toolbar = module.quill.getModule('toolbar') as Toolbar;
      final button = toolbar.container!
          .querySelectorAll('button')
          .firstWhere((element) => element.classes.contains('ql-table-better'));
      expect(
        button.querySelectorAll('.ql-table-select-container').length,
        equals(1),
      );
    });

    test('the grid inserts a table-better table, not the basic one', () {
      final module = createModule(toolbarTable: true);
      module.quill.setSelection(const Range(0, 0));
      final select = module.tableSelect!;

      final target = select.cells.firstWhere((cell) {
        final (row, column) = select.getSelectAttrs(cell);
        return row == 2 && column == 3;
      });
      select.handleClick(target, module.insertTable);

      final tables = module.quill.scroll.descendants<TableContainer>().toList();
      expect(tables, hasLength(1));
      // table-better tables carry the temporary blot and data-row cells that
      // the basic `table` module never emits.
      expect(module.quill.scroll.descendants<TableTemporary>(), isNotEmpty);
      final rows = tables.single.tbody()!.children.whereType<TableRow>();
      expect(rows.length, equals(2));
      expect(
        rows.every((row) => row.children.whereType<TableCell>().length == 3),
        isTrue,
      );
      expect(
        tables.single
            .descendants<TableCell>()
            .every((cell) => cell.element.hasAttribute('data-row')),
        isTrue,
      );
    });

    test('a click outside the button hides an open grid', () {
      final module = createModule(toolbarTable: true);
      final select = module.tableSelect!;
      select.show();
      expect(select.isHidden, isFalse);

      final outside = testAdapter.document.createElement('div');
      testAdapter.document.body.append(outside);
      testAdapter.document
          .dispatchEvent('click', FakeDomEvent('click', outside));

      expect(select.isHidden, isTrue);
    });

    test('a click on the button itself leaves the grid open', () {
      final module = createModule(toolbarTable: true);
      final select = module.tableSelect!;
      select.show();

      final toolbar = module.quill.getModule('toolbar') as Toolbar;
      final button = toolbar.container!
          .querySelectorAll('button')
          .firstWhere((element) => element.classes.contains('ql-table-better'));
      testAdapter.document
          .dispatchEvent('click', FakeDomEvent('click', button));

      expect(select.isHidden, isFalse);
    });
  });
}
