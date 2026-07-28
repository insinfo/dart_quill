import 'package:dart_quill/src/core/selection.dart';
import 'package:dart_quill/src/modules/toolbar.dart';
import 'package:dart_quill/src/platform/dom.dart';
import 'package:dart_quill/src/table_better/formats/table.dart';
import 'package:dart_quill/src/table_better/register.dart';
import 'package:dart_quill/src/table_better/table_better.dart';
import 'package:test/test.dart';

import '../../support/fake_dom.dart';
import '../../support/quill_test_helpers.dart';
import '../../support/test_helpers.dart';

/// The menus are shown and hidden with `ql-hidden`, as upstream does.
bool _menusVisible(TableBetter module) =>
    !module.tableMenus.root.classes.contains('ql-hidden');

DomElement? _toolbarButton(TableBetter module, String className) {
  final toolbar = module.quill.getModule('toolbar');
  final container = (toolbar as dynamic).container as DomElement?;
  if (container == null) return null;
  for (final button in container.querySelectorAll('button')) {
    if (button.classes.contains(className)) return button;
  }
  return null;
}

/// The root-level handlers of `quill-table-better.ts` (G6.8): `handleKeyup`,
/// `handleMousedown`, `handleMouseMove`, `handleScroll` and
/// `clearHistorySelected`.
///
/// These are the module's lifecycle around the grid — the part that decides
/// when the floating tools appear and disappear. The per-cell behaviour they
/// sit on top of is covered by `cell_selection_controller_test.dart`.
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

  ({TableBetter module, TableContainer table}) withTable({
    int rows = 2,
    int columns = 2,
    bool toolbar = false,
  }) {
    final quill = createTestQuill(
      theme: toolbar ? 'snow' : null,
      modules: {
        if (toolbar)
          'toolbar': ToolbarProps(
            container: ToolbarConfig(const [
              ['bold', 'blockquote']
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

  DomElement cellAt(TableContainer table, int row, int column) {
    final rows = table.descendants<TableRow>().toList();
    return rows[row].children.whereType<TableCell>().elementAt(column).element;
  }

  FakeDomElement root(TableBetter module) => module.quill.root as FakeDomElement;

  group('clearHistorySelected', () {
    test('strips both marker classes straight off the cells', () {
      final (:module, :table) = withTable();
      final first = cellAt(table, 0, 0);
      final second = cellAt(table, 0, 1);
      first.classes.add('ql-cell-focused');
      second.classes.add('ql-cell-selected');

      module.clearHistorySelected();

      expect(first.classes.contains('ql-cell-focused'), isFalse);
      expect(second.classes.contains('ql-cell-selected'), isFalse);
    });

    test('does nothing when the caret is outside a table', () {
      final (:module, :table) = withTable();
      final cell = cellAt(table, 0, 0);
      cell.classes.add('ql-cell-focused');
      module.quill.setSelection(const Range(0, 0));

      module.clearHistorySelected();

      // The caret is on the paragraph before the table, so getTable() is empty
      // and upstream returns early — the class survives.
      expect(cell.classes.contains('ql-cell-focused'), isTrue);
    });
  });

  group('handleKeyup', () {
    test('Ctrl+Z hides the tools and clears the replayed classes', () {
      final (:module, :table) = withTable();
      module.showTools();
      expect(_menusVisible(module), isTrue);
      final cell = cellAt(table, 0, 0);
      expect(cell.classes.contains('ql-cell-focused'), isTrue);

      root(module).dispatchEvent(
        'keyup',
        FakeDomKeyboardEvent(type: 'keyup', key: 'z', ctrlKey: true),
      );

      expect(_menusVisible(module), isFalse);
      expect(cell.classes.contains('ql-cell-focused'), isFalse);
      expect(cell.classes.contains('ql-cell-selected'), isFalse);
    });

    test('Ctrl+Y does the same, as redo replays the same DOM', () {
      final (:module, :table) = withTable();
      module.showTools();

      module.handleKeyup(
          FakeDomKeyboardEvent(type: 'keyup', key: 'y', ctrlKey: true));

      expect(_menusVisible(module), isFalse);
    });

    test('a plain z leaves the tools alone', () {
      final (:module, :table) = withTable();
      module.showTools();

      module.handleKeyup(FakeDomKeyboardEvent(type: 'keyup', key: 'z'));

      expect(_menusVisible(module), isTrue);
    });

    test('a disabled editor ignores the key entirely', () {
      final (:module, :table) = withTable();
      module.showTools();
      module.quill.disable();

      module.handleKeyup(
          FakeDomKeyboardEvent(type: 'keyup', key: 'z', ctrlKey: true));

      expect(_menusVisible(module), isTrue);
    });
  });

  group('handleMousedown', () {
    test('a click outside any table hides the tools', () {
      final (:module, :table) = withTable();
      module.showTools();
      expect(_menusVisible(module), isTrue);

      module.handleMousedown(
          FakeDomMouseEvent(type: 'mousedown', target: module.quill.root));

      expect(_menusVisible(module), isFalse);
    });

    test('a click inside a table keeps them and disables the toolbar', () {
      final (:module, :table) = withTable(toolbar: true);
      module.showTools();
      // `bold` is white-listed (it applies fine inside a cell); `blockquote`
      // is not, so it is the one that gets greyed out.
      final quote = _toolbarButton(module, 'ql-blockquote')!;
      quote.classes.remove('ql-table-button-disabled');

      module.handleMousedown(
          FakeDomMouseEvent(type: 'mousedown', target: cellAt(table, 1, 1)));

      expect(_menusVisible(module), isTrue);
      expect(quote.classes.contains('ql-table-button-disabled'), isTrue);
      expect(_toolbarButton(module, 'ql-bold')!.classes
          .contains('ql-table-button-disabled'), isFalse);
    });

    test('it closes an open 10x10 grid', () {
      final quill = createTestQuill(
        theme: 'snow',
        modules: {
          'toolbar': ToolbarProps(
            container: ToolbarConfig(const [
              ['bold', 'table-better']
            ]),
          ),
          'table-better': const <String, dynamic>{'toolbarTable': true},
        },
      );
      final module = quill.getModule('table-better') as TableBetter;
      final select = module.tableSelect!;
      select.show();
      expect(select.isHidden, isFalse);

      module.handleMousedown(
          FakeDomMouseEvent(type: 'mousedown', target: quill.root));

      expect(select.isHidden, isTrue);
    });

    test('a disabled editor ignores the click', () {
      final (:module, :table) = withTable();
      module.showTools();
      module.quill.disable();

      module.handleMousedown(
          FakeDomMouseEvent(type: 'mousedown', target: module.quill.root));

      expect(_menusVisible(module), isTrue);
    });
  });

  group('handleMouseMove', () {
    test('a drag that reaches a table widens the range to the whole table', () {
      final (:module, :table) = withTable();
      final quill = module.quill;
      // A native drag starting on the paragraph before the table.
      quill.setSelection(const Range(0, 0));
      module.handleMouseMove();

      root(module).dispatchEvent(
        'mousemove',
        FakeDomMouseEvent(type: 'mousemove', target: cellAt(table, 0, 0)),
      );
      root(module).dispatchEvent(
        'mouseup',
        FakeDomMouseEvent(type: 'mouseup', target: cellAt(table, 0, 0)),
      );

      final index = quill.scroll.offset(table);
      final range = quill.getSelection()!;
      expect(range.index, lessThanOrEqualTo(index));
      expect(range.index + range.length,
          greaterThanOrEqualTo(index + table.length()));
    });

    test('a drag that never touches a table leaves the selection alone', () {
      final (:module, :table) = withTable();
      final quill = module.quill;
      quill.setSelection(const Range(0, 0));
      module.handleMouseMove();

      root(module).dispatchEvent('mousemove',
          FakeDomMouseEvent(type: 'mousemove', target: quill.root));
      root(module).dispatchEvent(
          'mouseup', FakeDomMouseEvent(type: 'mouseup', target: quill.root));

      expect(quill.getSelection(), equals(const Range(0, 0)));
    });

    test('the listeners are removed on mouseup', () {
      final (:module, :table) = withTable();
      final quill = module.quill;
      quill.setSelection(const Range(0, 0));
      module.handleMouseMove();

      root(module).dispatchEvent(
          'mouseup', FakeDomMouseEvent(type: 'mouseup', target: quill.root));
      final after = quill.getSelection();

      // A move after mouseup must not re-arm the widening.
      root(module).dispatchEvent(
        'mousemove',
        FakeDomMouseEvent(type: 'mousemove', target: cellAt(table, 0, 0)),
      );
      root(module).dispatchEvent(
        'mouseup',
        FakeDomMouseEvent(type: 'mouseup', target: cellAt(table, 0, 0)),
      );

      expect(quill.getSelection(), equals(after));
    });
  });

  group('handleScroll', () {
    test('hides the tools and arms the menus for a reposition', () {
      final (:module, :table) = withTable();
      module.showTools();
      expect(_menusVisible(module), isTrue);

      root(module).dispatchEvent('scroll', FakeDomEvent('scroll', null));

      expect(_menusVisible(module), isFalse);
      expect(module.tableMenus.scroll, isTrue);
    });

    test('a disabled editor ignores the scroll', () {
      final (:module, :table) = withTable();
      module.showTools();
      module.quill.disable();

      module.handleScroll();

      expect(_menusVisible(module), isTrue);
    });
  });
}
