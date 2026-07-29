@TestOn('vm')
@Timeout(Duration(minutes: 12))
library;

/// End-to-end coverage of the quill-table-better UI driven by REAL input:
/// hovering the 10x10 grid, clicking cells and menu items, dragging cell
/// borders to resize and dragging across cells to select.
///
/// Menu items are clicked BY THEIR VISIBLE LABEL, taken from the same
/// `Language` table the app uses with the configured locale (pt_BR in the
/// demo) — so a locale regression makes these tests fail on the click.
import 'package:dart_quill/src/table_better/language/language.dart';
import 'package:puppeteer/puppeteer.dart';
import 'package:test/test.dart';

import 'support/e2e_app.dart';

void main() {
  late E2eApp app;
  final language = Language('pt_BR');
  String t(String key) => language.useLanguage(key);

  setUpAll(() async => app = await E2eApp.start());
  tearDownAll(() async => app.stop());

  /// A pristine page with one freshly inserted table.
  Future<void> freshTable(int rows, int columns) async {
    await app.reload();
    await app.resetEditor();
    await app.insertTableFromToolbar(rows, columns);
  }

  /// Real drag across cells to build a multi-cell selection.
  Future<void> selectCells(
      int fromRow, int fromColumn, int toRow, int toColumn) async {
    final from = await app.rectOf('.ql-editor table tbody '
        'tr:nth-child(${fromRow + 1}) td:nth-child(${fromColumn + 1})');
    final to = await app.rectOf('.ql-editor table tbody '
        'tr:nth-child(${toRow + 1}) td:nth-child(${toColumn + 1})');
    await app.drag(
      Point((from['left'] as num) + 5, (from['top'] as num) + 5),
      Point((to['right'] as num) - 5, (to['bottom'] as num) - 5),
    );
  }

  group('10x10 grid of the toolbar', () {
    test('hovering highlights only the cells up to the pointer', () async {
      await app.reload();
      await app.resetEditor();
      await app.page.click('.ql-toolbar button.ql-table-better');
      await app.settle();

      // Hover the (2, 3) cell: the rectangle above/left of it must light up.
      final cell =
          await app.page.$('.ql-table-select-list span[row="2"][column="3"]');
      final box = (await cell.boundingBox)!;
      await app.page.mouse
          .move(Point(box.left + box.width / 2, box.top + box.height / 2));
      await app.settle();

      final state = await app.tableGridState();
      expect(state['hidden'], isFalse);
      expect(state['selected'], 6,
          reason: 'a 2x3 hover highlights exactly six cells, not the whole '
              'grid ($state)');
      expect(state['label'], '2 x 3');

      // Moving further down-right grows the rectangle.
      final bigger =
          await app.page.$('.ql-table-select-list span[row="4"][column="4"]');
      final biggerBox = (await bigger.boundingBox)!;
      await app.page.mouse.move(Point(
          biggerBox.left + biggerBox.width / 2,
          biggerBox.top + biggerBox.height / 2));
      await app.settle();
      final grown = await app.tableGridState();
      expect(grown['selected'], 16);
      expect(grown['label'], '4 x 4');
    });

    test('clicking a grid cell inserts that table into the model', () async {
      await freshTable(2, 3);

      final shape = await app.tableShape();
      expect(shape['rows'], 2);
      expect(shape['columns'], 3);

      final contents = await app.contents();
      expect(contents, contains('table-temporary'),
          reason: 'the MODEL must carry the table, not only the DOM');
      expect(contents, contains('table-cell'));
      expect(await app.eval<bool>(
          '() => document.querySelector(".ql-editor table td")'
          '.hasAttribute("data-row")'),
          isTrue);
      expect((await app.tableGridState())['hidden'], isTrue,
          reason: 'the grid closes after inserting');
    });
  });

  group('floating menus', () {
    test('clicking a cell shows the menus with inline SVG icons', () async {
      await freshTable(2, 3);
      await app.clickCell(0, 0);

      final menus = await app.eval<Map<String, dynamic>>('''() => {
        const root = document.querySelector('.ql-table-menus-container');
        const entries = [...root.querySelectorAll('[data-category]')];
        return {
          visible: !root.classList.contains('ql-hidden'),
          categories: entries.map(e => e.dataset.category),
          svgIcons: entries.every(e => e.querySelector('svg')),
          fontGlyphs: root.querySelectorAll('i.ti').length,
        };
      }''');
      expect(menus['visible'], isTrue, reason: '$menus');
      expect(
          menus['categories'],
          containsAll(
              ['column', 'row', 'merge', 'table', 'cell', 'wrap', 'delete']));
      expect(menus['svgIcons'], isTrue,
          reason: 'menu icons must be inline SVG, not icon-font glyphs');
      expect(menus['fontGlyphs'], 0);
    });

    test('the menu labels honour the configured locale (pt_BR)', () async {
      await freshTable(2, 2);
      await app.clickCell(0, 0);
      await app.openTableMenu('row');

      final labels = await app.eval<String>('''() => [...document.querySelectorAll(
          '.ql-table-menus-container [data-category="row"] li')]
          .map(li => li.textContent.trim()).filter(Boolean).join("|")''');
      expect(labels, contains(t('insRowAbv')));
      expect(labels, contains(t('insRowBlw')));
      expect(labels, contains(t('delRow')));
      expect(labels, isNot(contains('Insert row below')),
          reason: 'the demo configures pt_BR, so no English may leak');
    });
  });

  group('rows and columns', () {
    test('inserting a row above and below grows the table', () async {
      await freshTable(2, 2);
      await app.clickCell(0, 0);

      await app.openTableMenu('row');
      await app.clickTableMenuItem('row', t('insRowBlw'));
      expect((await app.tableShape())['rows'], 3);

      await app.clickCell(0, 0);
      await app.openTableMenu('row');
      await app.clickTableMenuItem('row', t('insRowAbv'));
      expect((await app.tableShape())['rows'], 4);
      expect((await app.tableShape())['columns'], 2,
          reason: 'row inserts must not disturb the column count');
    });

    test('inserting a column left and right grows the table', () async {
      await freshTable(2, 2);
      await app.clickCell(0, 0);

      await app.openTableMenu('column');
      await app.clickTableMenuItem('column', t('insColR'));
      expect((await app.tableShape())['columns'], 3);

      await app.clickCell(0, 0);
      await app.openTableMenu('column');
      await app.clickTableMenuItem('column', t('insColL'));
      final shape = await app.tableShape();
      expect(shape['columns'], 4);
      expect(shape['rows'], 2);
    });

    test('deleting a row and a column shrinks the table', () async {
      await freshTable(3, 3);
      await app.clickCell(1, 1);

      await app.openTableMenu('row');
      await app.clickTableMenuItem('row', t('delRow'));
      expect((await app.tableShape())['rows'], 2);

      await app.clickCell(0, 0);
      await app.openTableMenu('column');
      await app.clickTableMenuItem('column', t('delCol'));
      expect((await app.tableShape())['columns'], 2);
    });

    test('typed text survives a row insert', () async {
      await freshTable(2, 2);
      await app.clickCell(0, 0);
      await app.type('conteudo');
      expect(await app.editorText(), contains('conteudo'));

      await app.clickCell(0, 0);
      await app.openTableMenu('row');
      await app.clickTableMenuItem('row', t('insRowBlw'));

      expect(await app.editorText(), contains('conteudo'));
      expect(await app.contents(), contains('conteudo'));
    });
  });

  group('merge and split', () {
    test('dragging across two cells selects them', () async {
      await freshTable(2, 2);
      await selectCells(0, 0, 0, 1);

      expect(await app.eval<int>(
          '() => document.querySelectorAll(".ql-editor td.ql-cell-selected,'
          ' .ql-editor td.ql-cell-focused").length'),
          greaterThanOrEqualTo(2),
          reason: 'a drag across cells must build a multi-cell selection');
    });

    test('merging two cells and splitting them back', () async {
      await freshTable(2, 2);
      await selectCells(0, 0, 0, 1);
      await app.openTableMenu('merge');
      await app.clickTableMenuItem('merge', t('mCells'));

      var firstRow = await app.eval<Map<String, dynamic>>('''() => {
        const row = document.querySelector('.ql-editor table tbody tr');
        const first = row.querySelector('td');
        return {cells: row.querySelectorAll('td').length,
                colspan: first.getAttribute('colspan')};
      }''');
      expect(firstRow['cells'], 1, reason: 'the two cells became one');
      expect(firstRow['colspan'], '2');

      await app.clickCell(0, 0);
      await app.openTableMenu('merge');
      await app.clickTableMenuItem('merge', t('sCell'));

      firstRow = await app.eval<Map<String, dynamic>>('''() => {
        const row = document.querySelector('.ql-editor table tbody tr');
        const first = row.querySelector('td');
        return {cells: row.querySelectorAll('td').length,
                colspan: first.getAttribute('colspan')};
      }''');
      expect(firstRow['cells'], 2, reason: 'splitting restores both cells');
      expect(firstRow['colspan'], isNull);
    });
  });

  group('header row and surrounding paragraphs', () {
    test('the header-row switch converts the first row to <th>', () async {
      await freshTable(2, 2);
      await app.clickCell(0, 0);
      await app.openTableMenu('row');
      await app.clickTableMenuItem('row', t('headerRow'));

      expect(await app.eval<int>(
          '() => document.querySelectorAll(".ql-editor table th").length'),
          2,
          reason: 'the first row becomes header cells');
      expect(await app.eval<bool>(
          '() => document.querySelector(".ql-editor table thead") !== null'),
          isTrue);
    });

    test('inserting a paragraph after the table adds a line outside it',
        () async {
      await freshTable(2, 2);
      await app.clickCell(0, 0);
      await app.openTableMenu('wrap');
      await app.clickTableMenuItem('wrap', t('insAft'));

      expect(await app.eval<int>('''() => {
        const root = document.querySelector('.ql-editor');
        return [...root.children].filter(el => el.tagName === 'P').length;
      }'''), greaterThanOrEqualTo(1),
          reason: 'a paragraph must exist outside the table');
    });
  });

  group('resize by dragging', () {
    test('dragging a column border widens the column', () async {
      await freshTable(2, 2);
      // Use the LAST row: the floating menus hover over the table's top edge.
      final before =
          await app.rectOf('.ql-editor tr:last-child td:first-child');
      final borderX = (before['right'] as num).toDouble();
      final middleY =
          (before['top'] as num).toDouble() + (before['height'] as num) / 2;

      await app.page.mouse.move(Point(borderX - 30, middleY));
      await app.page.mouse.move(Point(borderX - 1, middleY));
      await app.settle();
      expect(
          await app.eval<bool>(
              '() => { const l = document.querySelector('
              '".ql-operate-line-container");'
              ' return l != null && getComputedStyle(l).display !== "none"; }'),
          isTrue,
          reason: 'hovering a vertical border must arm the resize line');

      await app.drag(Point(borderX - 1, middleY), Point(borderX + 60, middleY));

      final after =
          await app.rectOf('.ql-editor tr:last-child td:first-child');
      expect((after['width'] as num) - (before['width'] as num),
          greaterThan(20),
          reason: 'before ${before['width']} / after ${after['width']}');
      expect(
          await app.eval<String>(
              '() => { const td = document.querySelector('
              '".ql-editor tr:last-child td:first-child");'
              ' return td.style.width || td.getAttribute("width") || ""; }'),
          isNotEmpty,
          reason: 'the new width must be persisted on the cell');
    });

    test('dragging a row border makes the row taller', () async {
      await freshTable(2, 2);
      final before =
          await app.rectOf('.ql-editor tr:last-child td:first-child');
      final borderY = (before['bottom'] as num).toDouble();
      final middleX =
          (before['left'] as num).toDouble() + (before['width'] as num) / 2;

      await app.page.mouse.move(Point(middleX, borderY - 30));
      await app.page.mouse.move(Point(middleX, borderY - 1));
      await app.settle();
      final armed = await app.eval<Map<String, dynamic>>('''() => {
        const l = document.querySelector('.ql-operate-line-container');
        if (!l) return {display: 'missing'};
        const cs = getComputedStyle(l);
        return {display: cs.display, cursor: cs.cursor};
      }''');
      expect(armed['display'], isNot('none'),
          reason: 'hovering a horizontal border must arm the resize line '
              '($armed)');
      expect(armed['cursor'], 'row-resize',
          reason: 'the horizontal border resizes rows ($armed)');

      await app.drag(Point(middleX, borderY - 1), Point(middleX, borderY + 50));

      final after =
          await app.rectOf('.ql-editor tr:last-child td:first-child');
      expect((after['height'] as num) - (before['height'] as num),
          greaterThan(20),
          reason: 'before ${before['height']} / after ${after['height']}');
    });

    test('a finished resize does not keep resizing on later clicks', () async {
      await freshTable(2, 2);
      final before =
          await app.rectOf('.ql-editor tr:last-child td:first-child');
      final borderX = (before['right'] as num).toDouble();
      final middleY =
          (before['top'] as num).toDouble() + (before['height'] as num) / 2;

      await app.page.mouse.move(Point(borderX - 30, middleY));
      await app.page.mouse.move(Point(borderX - 1, middleY));
      await app.drag(Point(borderX - 1, middleY), Point(borderX + 40, middleY));

      final afterDrag =
          await app.rectOf('.ql-editor tr:last-child td:first-child');

      // Click around the page the way a user would after resizing. The drag
      // listeners must be gone: while they leaked, every one of these clicks
      // replayed the resize and the table grew without end.
      for (final point in [
        Point<num>(400, 400),
        Point<num>(600, 300),
        Point<num>(200, 250),
      ]) {
        await app.page.mouse.move(point);
        await app.page.mouse.down();
        await app.page.mouse.up();
        await app.settle(60);
      }

      final afterClicks =
          await app.rectOf('.ql-editor tr:last-child td:first-child');
      expect((afterClicks['width'] as num).round(),
          (afterDrag['width'] as num).round(),
          reason: 'clicks after a drag must not resize anything '
              '(after drag ${afterDrag['width']}, after clicks '
              '${afterClicks['width']})');
    });
  });

  group('deleting the table', () {
    test('the delete menu removes the table and hides the floating UI',
        () async {
      await freshTable(2, 2);
      await app.clickCell(0, 0);
      await app.page.click(
          '.ql-table-menus-container [data-category="delete"]');
      await app.settle();

      final state = await app.eval<Map<String, dynamic>>('''() => ({
        table: document.querySelector('.ql-editor table') != null,
        menusHidden: document.querySelector('.ql-table-menus-container')
            .classList.contains('ql-hidden'),
      })''');
      expect(state['table'], isFalse);
      expect(state['menusHidden'], isTrue,
          reason: 'the floating menus must not outlive the table');
      expect(await app.contents(), isNot(contains('table-cell')),
          reason: 'the model must lose the table too');
    });
  });
}
