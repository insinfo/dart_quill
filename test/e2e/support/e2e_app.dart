/// Shared harness for the end-to-end suites: builds the demo in `web/`,
/// serves it, drives it with a real Chrome through Puppeteer and exposes
/// helpers that use REAL user input (typing, clicking, dragging) plus the
/// model hooks the demo installs (`window.e2eGetContents` and friends).
///
/// Every helper here goes through the browser the way a person would; the
/// only "cheating" is reading the editor's model back, because a DOM that
/// looks right while the model is empty is exactly the class of bug these
/// tests exist to catch.
library;

import 'dart:async';
import 'dart:io';

import 'package:puppeteer/puppeteer.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_static/shelf_static.dart';

/// A running demo app under Puppeteer control.
class E2eApp {
  E2eApp._(this._server, this._browser, this.page);

  final HttpServer _server;
  final Browser _browser;
  final Page page;

  static const _buildDir = 'build/e2e';

  /// Builds (once per process, serialized across processes), serves and opens
  /// the demo.
  static Future<E2eApp> start() async {
    await _build();
    final handler = createStaticHandler(
      Directory(_buildDir).absolute.path,
      defaultDocument: 'index.html',
    );
    final server = await shelf_io.serve(handler, InternetAddress.loopbackIPv4, 0);
    final browser = await puppeteer.launch(
      headless: true,
      args: const ['--no-sandbox'],
    );
    final page = await browser.newPage();
    await page.setViewport(DeviceViewport(width: 1280, height: 900));
    await page.goto('http://127.0.0.1:${server.port}', wait: Until.networkIdle);
    return E2eApp._(server, browser, page);
  }

  Future<void> stop() async {
    await _browser.close();
    await _server.close(force: true);
  }

  /// `webdev build`, guarded by an inter-process lock: `dart test` runs test
  /// files concurrently and two build_runner instances in one package fight
  /// over `.dart_tool`.
  static Future<void> _build() async {
    final lockFile = File('build/.e2e_build.lock')
      ..parent.createSync(recursive: true);
    final lock = lockFile.openSync(mode: FileMode.write);
    lock.lockSync(FileLock.blockingExclusive);
    try {
      for (var attempt = 0; attempt < 2; attempt++) {
        final build = await Process.run(
          Platform.resolvedExecutable,
          const [
            'run',
            'webdev',
            'build',
            '--no-release',
            '--output',
            'web:$_buildDir',
            '--',
            '--delete-conflicting-outputs',
          ],
          workingDirectory: Directory.current.path,
        );
        if (build.exitCode != 0) {
          throw StateError('Web build failed:\n${build.stdout}\n${build.stderr}');
        }
        // A cold build_runner run can exit 0 having written only the
        // manifest; verify the merged output before trusting it.
        if (File('$_buildDir/index.html').existsSync()) return;
        if (attempt == 1) {
          throw StateError('Web build produced no index.html in $_buildDir');
        }
      }
    } finally {
      lock.unlockSync();
      lock.closeSync();
    }
  }

  // --- generic browser helpers ---------------------------------------------

  Future<T> eval<T>(String jsFunction) => page.evaluate<T>(jsFunction);

  /// Reloads the page — the cheapest way to guarantee a pristine editor
  /// (a leftover table and its floating menus can cover the toolbar and
  /// swallow real clicks).
  Future<void> reload() async {
    await page.reload(wait: Until.networkIdle);
  }

  Future<void> settle([int ms = 120]) =>
      Future<void>.delayed(Duration(milliseconds: ms));

  // --- editor helpers -------------------------------------------------------

  /// Puts the editor back to a blank document and focuses it.
  ///
  /// Setup only — everything under test is still driven by real input. It
  /// goes through the demo's `e2eReset` hook rather than Ctrl+A+Delete
  /// because deleting the text keeps the last line's block format (a list
  /// stays a list), which would silently change what the next action means.
  Future<void> resetEditor() async {
    await eval<void>('() => window.e2eReset()');
    await page.click('.ql-editor');
    await settle(60);
  }

  /// Clears the document the way a user would: Ctrl+A then Delete.
  Future<void> clearWithKeyboard() async {
    await page.click('.ql-editor');
    await selectAll();
    await page.keyboard.press(Key.delete);
  }

  Future<void> selectAll() async {
    await page.keyboard.down(Key.control);
    await page.keyboard.press(Key.keyA);
    await page.keyboard.up(Key.control);
  }

  Future<void> type(String text) => page.type('.ql-editor', text);

  /// Types [text] into a fresh document and selects all of it.
  Future<void> typeAndSelect(String text) async {
    await resetEditor();
    await type(text);
    await selectAll();
  }

  Future<void> shortcut(Key key) async {
    await page.keyboard.down(Key.control);
    await page.keyboard.press(key);
    await page.keyboard.up(Key.control);
  }

  Future<String> editorText() async =>
      await page.$eval<String?>('.ql-editor', '(el) => el.textContent') ?? '';

  Future<String> editorHtml() async =>
      await page.$eval<String?>('.ql-editor', '(el) => el.innerHTML') ?? '';

  /// The editor's MODEL (delta JSON) through the demo's read-only hook.
  Future<String> contents() => eval<String>('() => window.e2eGetContents()');

  /// The editor's logical selection as `index:length` (or `null`).
  Future<String> selection() => eval<String>('() => window.e2eGetSelection()');

  /// The browser's own selected text.
  Future<String> nativeSelection() =>
      eval<String>('() => document.getSelection()?.toString() ?? ""');

  // --- toolbar helpers ------------------------------------------------------

  /// Clicks a toolbar button, e.g. `clickToolbarButton('bold')` or
  /// `clickToolbarButton('list', value: 'ordered')`.
  Future<void> clickToolbarButton(String format, {String? value}) async {
    final selector = value == null
        ? '.ql-toolbar button.ql-$format'
        : '.ql-toolbar button.ql-$format[value="$value"]';
    await page.click(selector);
    await settle(60);
  }

  Future<bool> isToolbarButtonActive(String format, {String? value}) async {
    final selector = value == null
        ? '.ql-toolbar button.ql-$format'
        : '.ql-toolbar button.ql-$format[value="$value"]';
    return await page.$eval<bool?>(
            selector, '(el) => el.classList.contains("ql-active")') ??
        false;
  }

  /// Opens a picker and clicks one of its items. [value] null picks the
  /// default (the item without `data-value`, e.g. "Normal" / align-left).
  Future<void> pickFromPicker(String pickerClass, String? value) async {
    await page.click('.ql-toolbar .$pickerClass .ql-picker-label');
    await settle(60);
    final item = value == null
        ? '.ql-toolbar .$pickerClass .ql-picker-item:not([data-value])'
        : '.ql-toolbar .$pickerClass .ql-picker-item[data-value="$value"]';
    await page.click(item);
    await settle(60);
  }

  // --- table helpers --------------------------------------------------------

  /// Opens the 10x10 grid, hovers the (rows, columns) cell with a real mouse
  /// move and clicks it — the same gesture a user performs.
  Future<void> insertTableFromToolbar(int rows, int columns) async {
    await page.click('.ql-toolbar button.ql-table-better');
    await settle();
    final cell = await page
        .$('.ql-table-select-list span[row="$rows"][column="$columns"]');
    final box = (await cell.boundingBox)!;
    await page.mouse
        .move(Point(box.left + box.width / 2, box.top + box.height / 2));
    await settle(60);
    await cell.click();
    await settle();
  }

  /// Highlighted cells of the open 10x10 grid, as `rows x columns` label.
  Future<Map<String, dynamic>> tableGridState() =>
      eval<Map<String, dynamic>>('''() => {
        const c = document.querySelector('.ql-table-select-container');
        return {
          hidden: c.classList.contains('ql-hidden'),
          selected: c.querySelectorAll('span.ql-cell-selected').length,
          label: c.querySelector('.ql-table-select-label').textContent,
        };
      }''');

  /// Clicks the cell at [row]/[column] (0-based) of the first table.
  Future<void> clickCell(int row, int column) async {
    final handle = await page.$(
        '.ql-editor table tbody tr:nth-child(${row + 1}) '
        'td:nth-child(${column + 1})');
    await handle.click();
    await settle();
  }

  /// Opens one of the floating menu categories (column/row/merge/…).
  Future<void> openTableMenu(String category) async {
    await page.click('.ql-table-menus-container [data-category="$category"]');
    await settle();
  }

  /// Clicks an item of an open menu category by its visible label — which is
  /// the label of the configured locale, so a wrong locale fails the click.
  Future<void> clickTableMenuItem(String category, String label) async {
    final clicked = await eval<bool>('''() => {
      const menu = document.querySelector(
          '.ql-table-menus-container [data-category="$category"]');
      if (!menu) return false;
      const items = [...menu.querySelectorAll('li')];
      const item = items.find(li => li.textContent.trim() === ${_js(label)});
      if (!item) return false;
      item.dispatchEvent(new MouseEvent('click', {bubbles: true}));
      return true;
    }''');
    if (!clicked) {
      final available = await eval<String>('''() => [...document.querySelectorAll(
          '.ql-table-menus-container [data-category="$category"] li')]
          .map(li => li.textContent.trim()).join(" | ")''');
      throw StateError(
          'Menu item "$label" not found in "$category". Available: $available');
    }
    await settle();
  }

  /// Table shape as `{rows, columns, cells}`.
  Future<Map<String, dynamic>> tableShape() =>
      eval<Map<String, dynamic>>('''() => {
        const table = document.querySelector('.ql-editor table');
        if (!table) return {rows: 0, columns: 0, cells: 0};
        const rows = [...table.querySelectorAll('tbody tr')];
        return {
          rows: rows.length,
          columns: rows.length
              ? rows[0].querySelectorAll('td,th').length : 0,
          cells: table.querySelectorAll('td,th').length,
          headers: table.querySelectorAll('th').length,
        };
      }''');

  /// Viewport rect of a DOM element.
  Future<Map<String, dynamic>> rectOf(String selector) =>
      eval<Map<String, dynamic>>('''() => {
        const el = document.querySelector(${_js(selector)});
        if (!el) return null;
        const r = el.getBoundingClientRect();
        return {left: r.left, top: r.top, right: r.right, bottom: r.bottom,
                width: r.width, height: r.height};
      }''');

  /// Drags from [from] to [to] with a real press-move-release gesture.
  Future<void> drag(Point<num> from, Point<num> to, {int steps = 10}) async {
    await page.mouse.move(from);
    await settle(60);
    await page.mouse.down();
    await page.mouse.move(to, steps: steps);
    await page.mouse.up();
    await settle();
  }

  static String _js(String value) => '"${value.replaceAll('"', r'\"')}"';
}
