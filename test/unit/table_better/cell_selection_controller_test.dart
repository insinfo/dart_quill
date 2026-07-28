import 'package:dart_quill/src/core/selection.dart';
import 'package:dart_quill/src/modules/toolbar.dart';
import 'package:dart_quill/src/platform/dom.dart';
import 'package:dart_quill/src/table_better/formats/table.dart';
import 'package:dart_quill/src/table_better/register.dart';
import 'package:dart_quill/src/table_better/table_better.dart';
import 'package:dart_quill/src/table_better/ui/cell_selection_controller.dart';
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

  TableBetter createModule({bool withToolbar = false}) {
    final quill = createTestQuill(
      theme: withToolbar ? 'snow' : null,
      modules: {
        if (withToolbar)
          'toolbar': ToolbarProps(
            container: ToolbarConfig(const [
              ['bold', 'link', 'code-block'],
              ['header']
            ]),
          ),
        'table-better': const <String, dynamic>{},
      },
    );
    return quill.getModule('table-better') as TableBetter;
  }

  ({TableBetter module, TableContainer table, CellSelectionController ctrl})
      withTable({int rows = 3, int columns = 3, bool withToolbar = false}) {
    final module = createModule(withToolbar: withToolbar);
    module.quill.setSelection(const Range(0, 0));
    module.insertTable(rows, columns);
    final table = module.quill.scroll.descendants<TableContainer>().single;
    final block = table.descendants<TableCellBlock>().first;
    module.quill.setSelection(Range(module.quill.scroll.offset(block), 0));
    return (module: module, table: table, ctrl: module.controllerFor(table));
  }

  DomElement cellAt(TableContainer table, int row, int column) {
    final rows = table.descendants<TableRow>().toList();
    return rows[row].children.whereType<TableCell>().elementAt(column).element;
  }

  group('drag selection', () {
    test('mousedown focuses one cell, drag extends to a rectangle', () {
      final (:module, :table, :ctrl) = withTable();
      final start = cellAt(table, 0, 0);
      final end = cellAt(table, 1, 1);

      ctrl.handleMousedown(FakeDomMouseEvent(type: 'mousedown', target: start));
      expect(ctrl.selectedTds, hasLength(1));
      expect(start.classes.contains('ql-cell-focused'), isTrue);

      // The drag listener is installed on the editor root.
      (module.quill.root as FakeDomElement).dispatchEvent(
          'mousemove', FakeDomMouseEvent(type: 'mousemove', target: end));
      expect(ctrl.selectedTds, hasLength(4));
      expect(
        ctrl.selectedTds.every((td) => td.classes.contains('ql-cell-selected')),
        isTrue,
      );

      (module.quill.root as FakeDomElement).dispatchEvent(
          'mouseup', FakeDomMouseEvent(type: 'mouseup', target: end));
      // After mouseup the drag listeners are gone: further moves do nothing.
      (module.quill.root as FakeDomElement).dispatchEvent('mousemove',
          FakeDomMouseEvent(type: 'mousemove', target: cellAt(table, 2, 2)));
      expect(ctrl.selectedTds, hasLength(4));
    });

    test('dragging back onto the anchor keeps a single cell selected', () {
      final (module: _, :table, :ctrl) = withTable();
      final start = cellAt(table, 1, 1);
      ctrl.handleMousedown(FakeDomMouseEvent(type: 'mousedown', target: start));
      ctrl.selectRange(
        ctrl.selection.selectedCells.single,
        ctrl.selection.selectedCells.single,
      );
      expect(ctrl.selectedTds, hasLength(1));
    });

    test('clear drops both marker classes', () {
      final (module: _, :table, :ctrl) = withTable();
      ctrl.handleMousedown(
          FakeDomMouseEvent(type: 'mousedown', target: cellAt(table, 0, 0)));
      final focused = cellAt(table, 0, 0);
      expect(focused.classes.contains('ql-cell-focused'), isTrue);

      ctrl.clear();
      expect(focused.classes.contains('ql-cell-focused'), isFalse);
      expect(focused.classes.contains('ql-cell-selected'), isFalse);
      expect(ctrl.selectedTds, isEmpty);
    });
  });

  group('toolbar white list', () {
    test('non-whitelisted buttons are collected and greyed out', () {
      final (:module, table: _, :ctrl) = withTable(withToolbar: true);

      // `bold`, `link` and `header` are whitelisted; `code-block` is not.
      expect(
        ctrl.disabledList
            .any((input) => input.classes.contains('ql-code-block')),
        isTrue,
      );
      expect(
        ctrl.disabledList.any((input) => input.classes.contains('ql-bold')),
        isFalse,
      );

      ctrl.setDisabled(true);
      expect(
        ctrl.disabledList
            .every((i) => i.classes.contains('ql-table-button-disabled')),
        isTrue,
      );
      ctrl.setDisabled(false);
      expect(
        ctrl.disabledList
            .any((i) => i.classes.contains('ql-table-button-disabled')),
        isFalse,
      );
      expect(module.tableMenus.root, isNotNull);
    });

    test('single-cell formats are disabled only for multi-cell selections', () {
      final (module: _, :table, :ctrl) = withTable(withToolbar: true);
      final link =
          ctrl.singleList.where((i) => i.classes.contains('ql-link')).toList();
      expect(link, isNotEmpty);

      ctrl.setSelectedTds([cellAt(table, 0, 0)]);
      expect(link.first.classes.contains('ql-table-button-disabled'), isFalse);

      ctrl.setSelectedTds([cellAt(table, 0, 0), cellAt(table, 0, 1)]);
      expect(link.first.classes.contains('ql-table-button-disabled'), isTrue);
    });

    test('a custom toolbarButtons option overrides the defaults', () {
      final quill = createTestQuill(
        theme: 'snow',
        modules: {
          'toolbar': ToolbarProps(
            container: ToolbarConfig(const [
              ['bold', 'italic']
            ]),
          ),
          'table-better': <String, dynamic>{
            'toolbarButtons': {
              'whiteList': ['italic'],
              'singleWhiteList': ['bold'],
            },
          },
        },
      );
      final module = quill.getModule('table-better') as TableBetter;
      quill.setSelection(const Range(0, 0));
      module.insertTable(2, 2);
      final table = quill.scroll.descendants<TableContainer>().single;
      final ctrl = module.controllerFor(table);

      expect(
        ctrl.disabledList.any((i) => i.classes.contains('ql-bold')),
        isTrue,
        reason: 'bold left the white list',
      );
      expect(
        ctrl.disabledList.any((i) => i.classes.contains('ql-italic')),
        isFalse,
      );
      expect(ctrl.singleList.any((i) => i.classes.contains('ql-bold')), isTrue);
    });
  });

  group('menus feedback', () {
    test('selecting header cells flips the header-row switch', () {
      final (:module, :table, :ctrl) = withTable(rows: 2, columns: 2);
      ctrl.setSelectedTds([cellAt(table, 0, 0), cellAt(table, 0, 1)]);
      module.tableMenus.toggleHeaderRow();

      final ths = table.descendants<TableTh>().toList();
      expect(ths, hasLength(2));
      ctrl.setSelectedTds(ths.map((th) => th.element).toList());

      final switchInner =
          module.tableMenus.root.querySelectorAll('.ql-table-switch-inner');
      expect(switchInner.first.getAttribute('aria-checked'), equals('true'));
    });

    test('a mixed td/th selection disables the merge menu', () {
      final (:module, :table, :ctrl) = withTable(rows: 2, columns: 2);
      ctrl.setSelectedTds([cellAt(table, 0, 0), cellAt(table, 0, 1)]);
      module.tableMenus.toggleHeaderRow();

      final th = table.descendants<TableTh>().first.element;
      final td = table
          .descendants<TableCell>()
          .firstWhere((cell) => cell.element.tagName.toUpperCase() == 'TD')
          .element;
      ctrl.setSelectedTds([th, td]);

      final merge = module.tableMenus.root
          .querySelectorAll('[data-category]')
          .firstWhere((e) => e.getAttribute('data-category') == 'merge');
      expect(merge.classes.contains('ql-table-disabled'), isTrue);
    });
  });

  group('keyboard', () {
    test('Backspace over several cells clears their content only', () {
      final (:module, :table, :ctrl) = withTable(rows: 2, columns: 2);
      module.quill.insertText(
        module.quill.scroll.offset(table.descendants<TableCellBlock>().first),
        'hello',
      );
      ctrl.setSelectedTds([cellAt(table, 0, 0), cellAt(table, 0, 1)]);

      ctrl.handleDeleteKeyup(
          FakeDomKeyboardEvent(type: 'keyup', key: 'Backspace'));

      expect(table.descendants<TableRow>(), hasLength(2));
      expect(
        table.descendants<TableCell>().first.element.textContent ?? '',
        isEmpty,
      );
    });

    test('Ctrl+Backspace removes a fully selected row', () {
      final (:module, :table, :ctrl) = withTable(rows: 3, columns: 3);
      // Upstream only deletes when the selection covers the row/column
      // exactly (the `isKeyboard` guard), so select the whole middle row.
      ctrl.setSelectedTds([
        cellAt(table, 1, 0),
        cellAt(table, 1, 1),
        cellAt(table, 1, 2),
      ]);

      ctrl.handleDeleteKeyup(
          FakeDomKeyboardEvent(type: 'keyup', key: 'Backspace', ctrlKey: true));

      expect(table.descendants<TableRow>(), hasLength(2));
    });

    test('Ctrl+Backspace on a partial selection deletes nothing', () {
      final (module: _, :table, :ctrl) = withTable(rows: 3, columns: 3);
      ctrl.setSelectedTds([cellAt(table, 1, 0), cellAt(table, 1, 1)]);

      ctrl.handleDeleteKeyup(
          FakeDomKeyboardEvent(type: 'keyup', key: 'Backspace', ctrlKey: true));

      expect(table.descendants<TableRow>(), hasLength(3));
    });

    test('a single selected cell ignores the delete shortcut', () {
      final (module: _, :table, :ctrl) = withTable(rows: 2, columns: 2);
      ctrl.setSelectedTds([cellAt(table, 0, 0)]);

      ctrl.handleDeleteKeyup(
          FakeDomKeyboardEvent(type: 'keyup', key: 'Backspace', ctrlKey: true));

      expect(table.descendants<TableRow>(), hasLength(2));
    });

    test('ArrowDown moves the focus to the cell below', () {
      final (:module, :table, :ctrl) = withTable(rows: 2, columns: 2);
      final first = cellAt(table, 0, 0);
      ctrl.setSelected(first, false);

      // Park the caret on the last line of the cell so there is no next
      // sibling inside it and the vertical handler crosses into the next row.
      final cell = table.descendants<TableCell>().first;
      module.quill.setSelection(
        Range(module.quill.scroll.offset(cell.children.last), 0),
      );
      ctrl.makeTableArrowVerticalHandler('ArrowDown');

      expect(ctrl.selection.startTd, isNot(same(first)));
      expect(ctrl.selectedTds, hasLength(1));
    });

    test('ArrowUp from the first row exits the table', () {
      final (:module, :table, :ctrl) = withTable(rows: 2, columns: 2);
      final cell = table.descendants<TableCell>().first;
      ctrl.setSelected(cell.element, false);
      module.quill.setSelection(
        Range(module.quill.scroll.offset(cell.children.first), 0),
      );

      ctrl.makeTableArrowVerticalHandler('ArrowUp');
      expect(ctrl.selectedTds, isEmpty, reason: 'exitTableFocus hides tools');
    });
  });

  group('clipboard', () {
    test('copyData serializes the selected cells only', () {
      final (:module, :table, :ctrl) = withTable(rows: 2, columns: 2);
      module.quill.insertText(
        module.quill.scroll.offset(table.descendants<TableCellBlock>().first),
        'x',
      );
      ctrl.setSelectedTds([cellAt(table, 0, 0), cellAt(table, 0, 1)]);

      final data = ctrl.copyData();
      expect(data, isNotNull);
      expect(data!.html, startsWith('<table><tbody>'));
      expect('<tr>'.allMatches(data.html).length, equals(1));
    });

    test('cut clears the cells it copied', () {
      final (:module, :table, :ctrl) = withTable(rows: 2, columns: 2);
      module.quill.insertText(
        module.quill.scroll.offset(table.descendants<TableCellBlock>().first),
        'x',
      );
      ctrl.setSelectedTds([cellAt(table, 0, 0), cellAt(table, 0, 1)]);

      final data = ctrl.copyData(isCut: true);
      expect(data!.text, contains('x'));
      expect(table.descendants<TableCell>().first.element.textContent ?? '',
          isEmpty);
    });

    test('fewer than two cells falls through to the native clipboard', () {
      final (module: _, :table, :ctrl) = withTable(rows: 2, columns: 2);
      ctrl.setSelectedTds([cellAt(table, 0, 0)]);
      expect(ctrl.copyData(), isNull);
    });
  });
}
