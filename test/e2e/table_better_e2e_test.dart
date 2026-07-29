@TestOn('vm')
@Timeout(Duration(minutes: 8))
library;

/// End-to-end suite driving the demo app (`web/`) with REAL user input —
/// trusted keyboard typing, mouse clicks and drags through Puppeteer — the
/// kind of interaction that exposed the selection-loss, copy/paste and
/// table-UI lifecycle bugs unit tests cannot see.
import 'dart:io';

import 'package:puppeteer/puppeteer.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_static/shelf_static.dart';
import 'package:test/test.dart';

void main() {
  late HttpServer server;
  late Browser browser;
  late Page page;
  var browserStarted = false;
  var serverStarted = false;

  setUpAll(() async {
    final build = await Process.run(
      Platform.resolvedExecutable,
      const [
        'run',
        'webdev',
        'build',
        '--no-release',
        '--output',
        'web:build/e2e',
        '--',
        '--delete-conflicting-outputs',
      ],
      workingDirectory: Directory.current.path,
    );
    if (build.exitCode != 0) {
      throw StateError('Web build failed:\n${build.stdout}\n${build.stderr}');
    }
    final handler = createStaticHandler(
      Directory('build/e2e').absolute.path,
      defaultDocument: 'index.html',
    );
    server = await shelf_io.serve(handler, InternetAddress.loopbackIPv4, 0);
    serverStarted = true;
    browser = await puppeteer.launch(
      headless: true,
      args: const ['--no-sandbox'],
    );
    browserStarted = true;
    page = await browser.newPage();
    await page.goto(
      'http://127.0.0.1:${server.port}',
      wait: Until.networkIdle,
    );
  });

  tearDownAll(() async {
    if (browserStarted) await browser.close();
    if (serverStarted) await server.close(force: true);
  });

  /// Clears the document with real input: click, Ctrl+A, Delete.
  Future<void> resetEditor() async {
    await page.click('.ql-editor');
    await page.keyboard.down(Key.control);
    await page.keyboard.press(Key.keyA);
    await page.keyboard.up(Key.control);
    await page.keyboard.press(Key.delete);
  }

  Future<void> selectAll() async {
    await page.keyboard.down(Key.control);
    await page.keyboard.press(Key.keyA);
    await page.keyboard.up(Key.control);
  }

  Future<String> editorHtml() async =>
      await page.$eval<String?>('.ql-editor', '(el) => el.innerHTML') ?? '';

  group('typing and toolbar formatting (real input)', () {
    test('typed text lands in the document', () async {
      await resetEditor();
      await page.type('.ql-editor', 'Isaque Neves');
      final text =
          await page.$eval<String>('.ql-editor', '(el) => el.textContent');
      expect(text, 'Isaque Neves');
    });

    test('select-all + Bold button formats without losing the selection',
        () async {
      await resetEditor();
      await page.type('.ql-editor', 'Hello world');
      await selectAll();
      await page.click('.ql-toolbar button.ql-bold');

      final strong = await page.$eval<String?>(
          '.ql-editor', '(el) => el.querySelector("strong")?.textContent');
      expect(strong, 'Hello world',
          reason: 'clicking Bold must format the selected text');

      final selection = await page.evaluate<String>(
          '() => document.getSelection()?.toString() ?? ""');
      expect(selection, 'Hello world',
          reason: 'the selection must survive the toolbar click');

      final active = await page.evaluate<bool>(
          '() => document.querySelector(".ql-toolbar button.ql-bold")'
          '.classList.contains("ql-active")');
      expect(active, isTrue);

      // Clicking Bold again removes the format (still without re-selecting).
      await page.click('.ql-toolbar button.ql-bold');
      final strongAfter = await page.$eval<bool>(
          '.ql-editor', '(el) => el.querySelector("strong") == null');
      expect(strongAfter, isTrue);
    });

    test('Heading 1 from the picker converts the line without deleting text',
        () async {
      await resetEditor();
      await page.type('.ql-editor', 'Titulo grande');
      await selectAll();
      await page.click('.ql-toolbar .ql-picker.ql-header .ql-picker-label');
      await page.click(
          '.ql-toolbar .ql-picker.ql-header .ql-picker-item[data-value="1"]');

      final h1 = await page.$eval<String?>(
          '.ql-editor', '(el) => el.querySelector("h1")?.textContent');
      expect(h1, 'Titulo grande',
          reason: 'Heading 1 must convert the line, never erase it');

      // And back to normal text through the same picker.
      await page.click('.ql-toolbar .ql-picker.ql-header .ql-picker-label');
      await page.click('.ql-toolbar .ql-picker.ql-header '
          '.ql-picker-item:not([data-value])');
      final h1After = await page.$eval<bool>(
          '.ql-editor', '(el) => el.querySelector("h1") == null');
      expect(h1After, isTrue, reason: await editorHtml());
    });

    test('collapsed Ctrl+B sets a pending format for the next typed text',
        () async {
      await resetEditor();
      await page.type('.ql-editor', 'plain ');
      await page.keyboard.down(Key.control);
      await page.keyboard.press(Key.keyB);
      await page.keyboard.up(Key.control);
      await page.type('.ql-editor', 'bold');

      final strong = await page.$eval<String?>(
          '.ql-editor', '(el) => el.querySelector("strong")?.textContent');
      expect(strong, 'bold');
      final text =
          await page.$eval<String>('.ql-editor', '(el) => el.textContent');
      expect(text, 'plain bold');
    });
  });

  group('clipboard (real events)', () {
    test('real Ctrl+C / Ctrl+V duplicates the selected text', () async {
      await resetEditor();
      await page.type('.ql-editor', 'copyme');
      await selectAll();
      await page.keyboard.down(Key.control);
      await page.keyboard.press(Key.keyC);
      await page.keyboard.up(Key.control);
      await page.keyboard.press(Key.arrowRight); // collapse to the end
      await page.keyboard.down(Key.control);
      await page.keyboard.press(Key.keyV);
      await page.keyboard.up(Key.control);

      final text =
          await page.$eval<String>('.ql-editor', '(el) => el.textContent');
      expect(text, 'copymecopyme', reason: await editorHtml());
    });

    test('the copy event receives HTML and plain text payloads', () async {
      await resetEditor();
      await page.type('.ql-editor', 'abc');
      await selectAll();
      await page.click('.ql-toolbar button.ql-bold');
      final payload = await page.evaluate<Map<String, dynamic>>('''() => {
        const dt = new DataTransfer();
        const event = new ClipboardEvent('copy',
            {clipboardData: dt, bubbles: true, cancelable: true});
        document.querySelector('.ql-editor').dispatchEvent(event);
        return {text: dt.getData('text/plain'), html: dt.getData('text/html')};
      }''');
      expect(payload['text'], 'abc');
      expect('${payload['html']}', contains('<strong>'));
    });

    test('a paste event inserts external HTML at the caret', () async {
      await resetEditor();
      await page.type('.ql-editor', 'start-');
      await page.keyboard.press(Key.end);
      await page.evaluate('''() => {
        const dt = new DataTransfer();
        dt.setData('text/html', '<strong>pasted</strong>');
        dt.setData('text/plain', 'pasted');
        const event = new ClipboardEvent('paste',
            {clipboardData: dt, bubbles: true, cancelable: true});
        document.querySelector('.ql-editor').dispatchEvent(event);
      }''');
      final text =
          await page.$eval<String>('.ql-editor', '(el) => el.textContent');
      expect(text, 'start-pasted');
      final strong = await page.$eval<String?>(
          '.ql-editor', '(el) => el.querySelector("strong")?.textContent');
      expect(strong, 'pasted');
    });
  });

  group('table-better UI (real input)', () {
    Future<void> insertTable(int rows, int columns) async {
      // A fresh page per test: a leftover table (and its floating menus)
      // from a previous test can cover the toolbar and swallow real clicks.
      await page.reload(wait: Until.networkIdle);
      await resetEditor();
      await page.click('.ql-toolbar button.ql-table-better');
      final visible = await page.$eval<bool>(
        '.ql-table-select-container',
        '(el) => !el.classList.contains("ql-hidden")',
      );
      expect(visible, isTrue, reason: 'the 10x10 grid must open');
      final cell = await page
          .$('.ql-table-select-list span[row="$rows"][column="$columns"]');
      final box = (await cell.boundingBox)!;
      // Real hover paints the selection rectangle, then a real click inserts.
      await page.mouse.move(
          Point(box.left + box.width - 1, box.top + box.height - 1));
      await cell.click();
    }

    test('the toolbar grid inserts a table-better table', () async {
      await insertTable(2, 3);
      final shape = await page.evaluate<Map<String, dynamic>>('''() => ({
        rows: document.querySelectorAll('.ql-editor table tbody tr').length,
        columns: document.querySelector('.ql-editor table tbody tr')
          ?.querySelectorAll('td').length ?? 0,
        temporary: document.querySelectorAll('.ql-editor table temporary').length,
        dataRow: document.querySelector('.ql-editor table td')
          ?.hasAttribute('data-row') ?? false,
        gridHidden: document.querySelector('.ql-table-select-container')
          .classList.contains('ql-hidden'),
        contents: window.e2eGetContents(),
      })''');
      expect(shape['rows'], 2, reason: '$shape');
      expect(shape['columns'], 3, reason: '$shape');
      // Upstream's insertTable delta is temporary + cells only — no colgroup
      // (the goldens prove it); cols appear later through resizing.
      expect(shape['temporary'], 1,
          reason: 'a table-better table carries its temporary blot');
      expect(shape['dataRow'], isTrue);
      expect(shape['gridHidden'], isTrue);
      expect('${shape['contents']}', contains('table-temporary'),
          reason: 'the MODEL must carry the table, not only the DOM');
    });

    test('clicking a cell shows the SVG-icon menus over the table', () async {
      await insertTable(2, 3);
      await page.click('.ql-editor td');
      final menus = await page.evaluate<Map<String, dynamic>>('''() => {
        const root = document.querySelector('.ql-table-menus-container');
        const entries = [...root.querySelectorAll('[data-category]')];
        return {
          visible: !root.classList.contains('ql-hidden'),
          categories: entries.map((entry) => entry.dataset.category),
          svgIcons: entries.every((entry) => entry.querySelector('svg')),
          tablerIcons: root.querySelectorAll('i.ti').length,
        };
      }''');
      expect(menus['visible'], isTrue, reason: '$menus');
      expect(
          menus['categories'],
          containsAll(
              ['column', 'row', 'merge', 'table', 'cell', 'wrap', 'delete']));
      expect(menus['svgIcons'], isTrue,
          reason: 'menu icons must be inline SVG, not icon-font glyphs');
      expect(menus['tablerIcons'], 0);
    });

    test('deleting the table through the menu hides the floating UI',
        () async {
      await insertTable(2, 2);
      await page.click('.ql-editor td');
      // Open the delete dropdown and confirm.
      await page.click('[data-category="delete"]');
      final state = await page.evaluate<Map<String, dynamic>>('''() => ({
        table: document.querySelector('.ql-editor table') != null,
        menusHidden: document.querySelector('.ql-table-menus-container')
          .classList.contains('ql-hidden'),
      })''');
      expect(state['table'], isFalse,
          reason: 'the delete menu removes the table');
      expect(state['menusHidden'], isTrue,
          reason: 'the floating menus must not outlive the table');
    });

    test('dragging a column border resizes the column', () async {
      await insertTable(2, 2);
      // The LAST row keeps the pointer clear of the floating menus, which
      // hover over the table's top edge.
      final before = await page.evaluate<Map<String, dynamic>>('''() => {
        const cell = document.querySelector(
            '.ql-editor tr:last-child td');
        const rect = cell.getBoundingClientRect();
        return {right: rect.right, top: rect.top, height: rect.height,
                width: rect.width};
      }''');
      final borderX = (before['right'] as num).toDouble();
      final middleY = (before['top'] as num).toDouble() +
          (before['height'] as num).toDouble() / 2;

      // Hover the border so the operate line arms, then drag it 40px right.
      await page.mouse.move(Point(borderX - 30, middleY));
      await page.mouse.move(Point(borderX - 1, middleY));
      await Future<void>.delayed(const Duration(milliseconds: 100));
      final lineVisible = await page.evaluate<bool>(
          '() => document.querySelector(".ql-operate-line-container") != null &&'
          ' getComputedStyle(document.querySelector('
          '".ql-operate-line-container")).display !== "none"');
      expect(lineVisible, isTrue,
          reason: 'hovering a cell border must show the resize line');

      await page.mouse.down();
      await page.mouse.move(Point(borderX + 40, middleY), steps: 8);
      await page.mouse.up();
      await Future<void>.delayed(const Duration(milliseconds: 200));

      // Without a colgroup the width lands on the cells of every row
      // (upstream setCellLevelRect); the rendered cell must have grown.
      final after = await page.evaluate<Map<String, dynamic>>('''() => {
        const cell = document.querySelector('.ql-editor td');
        return {
          rendered: cell.getBoundingClientRect().width,
          persisted: cell.style.width || cell.getAttribute('width') || '',
        };
      }''');
      final grown =
          (after['rendered'] as num) - (before['width'] as num);
      expect(grown, greaterThan(20),
          reason: 'the dragged column must widen '
              '(before ${before['width']}, after $after)');
      expect('${after['persisted']}', isNotEmpty,
          reason: 'the new width must be persisted on the cell');
    });
  });
}
