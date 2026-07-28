import 'package:dart_quill/src/core/selection.dart';
import 'package:dart_quill/src/platform/dom.dart';
import 'package:dart_quill/src/table_better/formats/table.dart';
import 'package:dart_quill/src/table_better/register.dart';
import 'package:dart_quill/src/table_better/table_better.dart';
import 'package:dart_quill/src/table_better/ui/operate_line.dart';
import 'package:test/test.dart';

import '../../support/fake_dom.dart';
import '../../support/quill_test_helpers.dart';
import '../../support/test_helpers.dart';

/// The fake adapter lays every element out at (0, 0) with the size taken from
/// its `width`/`height` attributes (120x80 by default), so a cell's right edge
/// is at x = 120 and its bottom edge at y = 80.
const double _defaultRight = 120;
const double _defaultBottom = 80;

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

  ({TableBetter module, TableContainer table, OperateLine line}) withTable({
    int rows = 2,
    int columns = 2,
  }) {
    final quill = createTestQuill(
      modules: {'table-better': const <String, dynamic>{}},
    );
    final module = quill.getModule('table-better') as TableBetter;
    quill.setSelection(const Range(0, 0));
    module.insertTable(rows, columns);
    final table = quill.scroll.descendants<TableContainer>().single;
    return (module: module, table: table, line: module.operateLine);
  }

  DomElement cellAt(TableContainer table, int row, int column) {
    final rows = table.descendants<TableRow>().toList();
    return rows[row].children.whereType<TableCell>().elementAt(column).element;
  }

  group('overlay', () {
    test('a mousemove over a cell builds the line and the drag block', () {
      final (:module, :table, :line) = withTable();
      expect(line.line, isNull);

      line.handleMouseMove(
          FakeDomMouseEvent(type: 'mousemove', target: cellAt(table, 0, 0)));

      expect(line.line, isNotNull);
      expect(line.line!.classes.contains('ql-operate-line-container'), isTrue);
      expect(line.line!.firstChild, isNotNull);
      expect(line.dragBlock, isNotNull);
      expect(line.dragBlock!.classes.contains('ql-operate-block'), isTrue);
      // Both live in the editor container, as upstream appends them there.
      expect(
        module.quill.container.querySelectorAll('.ql-operate-line-container'),
        hasLength(1),
      );
    });

    test('leaving the table hides the overlay', () {
      final (:module, :table, :line) = withTable();
      line.handleMouseMove(
          FakeDomMouseEvent(type: 'mousemove', target: cellAt(table, 0, 0)));

      line.handleMouseMove(
          FakeDomMouseEvent(type: 'mousemove', target: module.quill.root));

      expect(line.line!.getAttribute('style'), contains('display: none'));
      expect(line.dragBlock!.getAttribute('style'), contains('display: none'));
    });

    test('the direction follows the edge the pointer is near', () {
      final (module: _, :table, :line) = withTable();
      final cell = cellAt(table, 0, 0);

      // Right edge → column resize.
      line.handleMouseMove(FakeDomMouseEvent(
        type: 'mousemove',
        target: cell,
        clientX: _defaultRight,
        clientY: 1,
      ));
      expect(line.direction, equals('level'));
      expect(line.line!.getAttribute('style'), contains('col-resize'));

      // Bottom edge → row resize.
      line.handleMouseMove(FakeDomMouseEvent(
        type: 'mousemove',
        target: cell,
        clientX: 1,
        clientY: _defaultBottom,
      ));
      expect(line.direction, equals('vertical'));
      expect(line.line!.getAttribute('style'), contains('row-resize'));
    });

    test('a pointer away from both edges hides the line', () {
      final (module: _, :table, :line) = withTable();
      final cell = cellAt(table, 0, 0);
      line.handleMouseMove(FakeDomMouseEvent(
          type: 'mousemove', target: cell, clientX: _defaultRight));

      line.handleMouseMove(FakeDomMouseEvent(
        type: 'mousemove',
        target: cell,
        clientX: _defaultRight / 2,
        clientY: _defaultBottom / 2,
      ));
      expect(line.line!.getAttribute('style'), contains('display: none'));
    });

    test('toggleLineChildClass marks the hairline while dragging', () {
      final (module: _, :table, :line) = withTable();
      line.handleMouseMove(
          FakeDomMouseEvent(type: 'mousemove', target: cellAt(table, 0, 0)));

      line.toggleLineChildClass(true);
      final inner = line.line!.firstChild as DomElement;
      expect(inner.classes.contains('ql-operate-line'), isTrue);
      line.toggleLineChildClass(false);
      expect(inner.classes.contains('ql-operate-line'), isFalse);
    });

    test('the drag table overlay is created and hidden on demand', () {
      final (module: _, :table, :line) = withTable();
      line.createDragTable(table.element);
      expect(line.dragTable, isNotNull);
      expect(line.dragTable!.classes.contains('ql-operate-drag-table'), isTrue);
      expect(line.dragTable!.getAttribute('style'), contains('display: block'));

      line.hideDragTable();
      expect(line.dragTable!.getAttribute('style'), contains('display: none'));
    });
  });

  group('geometry helpers', () {
    test('getLevelColSum counts colspans to the left, inclusive', () {
      final (module: _, :table, :line) = withTable(rows: 1, columns: 3);
      expect(line.getLevelColSum(cellAt(table, 0, 0)), equals(1));
      expect(line.getLevelColSum(cellAt(table, 0, 2)), equals(3));

      cellAt(table, 0, 0).setAttribute('colspan', '2');
      expect(line.getLevelColSum(cellAt(table, 0, 1)), equals(3));
    });

    test('getMaxColNum sums the colspans of the row', () {
      final (module: _, :table, :line) = withTable(rows: 1, columns: 3);
      expect(line.getMaxColNum(cellAt(table, 0, 0)), equals(3));
      cellAt(table, 0, 0).setAttribute('colspan', '2');
      expect(line.getMaxColNum(cellAt(table, 0, 0)), equals(4));
    });

    test('getVerticalCells follows a rowspan down to the row it ends on', () {
      final (module: _, :table, :line) = withTable(rows: 3, columns: 2);
      final cell = cellAt(table, 0, 0);
      cell.setAttribute('rowspan', '2');

      final cells = line.getVerticalCells(cell, 2);
      final secondRow = table.descendants<TableRow>().elementAt(1);
      expect(cells.length, equals(secondRow.children.length));
    });

    test('getCorrectCol picks the sum-th column, 1-based', () {
      final (module: _, table: _, :line) = withTable(rows: 1, columns: 3);
      // `insertTable` builds a colgroup-less table, so the colgroup is made
      // here to exercise the lookup in isolation.
      final scroll = createScroll(
        '<table class="ql-table-better"><colgroup>'
        '<col width="50"><col width="60"><col width="70"></colgroup>'
        '<tbody><tr><td data-row="r"><p class="ql-table-block" data-cell="c">a</p>'
        '</td></tr></tbody></table>',
        registry: createRegistry(registerTableBetterFormats()),
      );
      final colgroup = scroll.descendants<TableContainer>().first.colgroup()!;
      final cols = colgroup.children.whereType<TableCol>().toList();
      expect(line.getCorrectCol(colgroup, 1), same(cols[0]));
      expect(line.getCorrectCol(colgroup, 3), same(cols[2]));
      expect(line.getCorrectCol(colgroup, 4), isNull);
      expect(line.getCorrectCol(colgroup, 0), isNull);
    });
  });

  group('persistence', () {
    test('a column resize writes width on the cells, not data-width', () {
      final (module: _, :table, :line) = withTable(rows: 2, columns: 2);
      // `insertTable` produces a colgroup-less table, so the per-cell branch
      // of `setCellLevelRect` runs (upstream keeps both paths).
      expect(table.colgroup(), isNull);
      final cell = cellAt(table, 0, 0);

      line.direction = 'level';
      line.setCellRect(cell, _defaultRight + 20, 0);

      expect(cell.getAttribute('width'), isNotNull);
      expect(cell.hasAttribute('data-width'), isFalse);
      expect(table.element.hasAttribute('data-width'), isFalse);
      // Same column of every row moved together.
      expect(cellAt(table, 1, 0).getAttribute('width'), isNotNull);
    });

    test('a row resize writes height on every cell of the row', () {
      final (module: _, :table, :line) = withTable(rows: 2, columns: 2);
      final cell = cellAt(table, 0, 0);

      line.direction = 'vertical';
      line.setCellRect(cell, 0, _defaultBottom + 15);

      final row = table.descendants<TableRow>().first;
      for (final child in row.children.whereType<TableCell>()) {
        expect(child.element.getAttribute('height'), isNotNull);
        expect(child.element.hasAttribute('data-height'), isFalse);
      }
    });

    test('the corner drag spreads the delta over rows and columns', () {
      final (module: _, :table, :line) = withTable(rows: 2, columns: 2);
      final cell = cellAt(table, 0, 0);

      line.setCellsRect(cell, 40, 30);

      for (final child in table.descendants<TableCell>()) {
        expect(child.element.getAttribute('height'), isNotNull);
        expect(child.element.getAttribute('width'), isNotNull);
      }
    });

    test('a resize repositions the menus of the table it touched', () {
      final (:module, :table, :line) = withTable(rows: 2, columns: 2);
      final cell = cellAt(table, 0, 0);

      module.tableMenus.updateTable(table.element);
      line.direction = 'level';
      line.setCellRect(cell, _defaultRight + 5, 0);

      expect(
          module.tableMenus.root.getAttribute('style') ?? '', contains('left'));
    });
  });
}
