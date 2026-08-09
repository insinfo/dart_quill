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
import 'dart:convert';
import 'dart:io';

import 'package:puppeteer/puppeteer.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_static/shelf_static.dart';

/// A running demo app under Puppeteer control.
class E2eApp {
  E2eApp._(this._server, this._browser, this.page, this._sessionLease);

  final HttpServer _server;
  final Browser _browser;
  final Page page;
  final ServerSocket _sessionLease;
  Future<void>? _stopFuture;

  static const _buildDir = 'build/e2e';
  static const _sessionLeasePortEnvironment =
      'DART_QUILL_E2E_LOCK_PORT';
  static const _defaultSessionLeasePort = 45873;
  static const _sessionLeaseWait = Duration(minutes: 35);
  static const _sessionLeasePoll = Duration(milliseconds: 250);

  /// Builds (once per process, serialized across processes), serves and opens
  /// the demo.
  static Future<E2eApp> start() async {
    final sessionLease = await _acquireSessionLease();

    HttpServer? server;
    Browser? browser;
    try {
      await _build();
      final handler = createStaticHandler(
        Directory(_buildDir).absolute.path,
        defaultDocument: 'index.html',
      );
      server = await shelf_io.serve(handler, InternetAddress.loopbackIPv4, 0);
      browser = await puppeteer.launch(
        headless: true,
        args: const ['--no-sandbox'],
      );
      final page = await browser.newPage();
      await page.setViewport(DeviceViewport(width: 1280, height: 900));
      await page.goto(
        'http://127.0.0.1:${server.port}',
        wait: Until.networkIdle,
      );
      return E2eApp._(server, browser, page, sessionLease);
    } catch (_) {
      if (browser != null) {
        try {
          await _closeBrowser(browser);
        } catch (_) {
          // Preserve the startup failure; cleanup is best effort here.
        }
      }
      if (server != null) {
        try {
          await server
              .close(force: true)
              .timeout(const Duration(seconds: 5));
        } catch (_) {
          // Preserve the startup failure; cleanup is best effort here.
        }
      }
      try {
        await sessionLease.close().timeout(const Duration(seconds: 5));
      } catch (_) {
        // Preserve the startup failure; cleanup is best effort here.
      }
      rethrow;
    }
  }

  Future<void> stop() => _stopFuture ??= _stopOnce();

  Future<void> _stopOnce() async {
    Object? firstError;
    StackTrace? firstStackTrace;

    Future<void> attempt(Future<void> Function() action) async {
      try {
        await action();
      } catch (error, stackTrace) {
        firstError ??= error;
        firstStackTrace ??= stackTrace;
      }
    }

    await attempt(() => _closeBrowser(_browser));
    await attempt(() async {
      await _server.close(force: true).timeout(const Duration(seconds: 5));
    });
    await attempt(() async {
      await _sessionLease.close().timeout(const Duration(seconds: 5));
    });

    if (firstError != null) {
      Error.throwWithStackTrace(firstError!, firstStackTrace!);
    }
  }

  static Future<ServerSocket> _acquireSessionLease() async {
    final configured =
        Platform.environment[_sessionLeasePortEnvironment]?.trim();
    final port = configured == null || configured.isEmpty
        ? _defaultSessionLeasePort
        : int.tryParse(configured);
    if (port == null || port < 1024 || port > 65535) {
      throw StateError(
        '$_sessionLeasePortEnvironment must be a port from 1024 to 65535',
      );
    }

    final wait = Stopwatch()..start();
    SocketException? lastError;
    while (wait.elapsed < _sessionLeaseWait) {
      try {
        return await ServerSocket.bind(
          InternetAddress.loopbackIPv4,
          port,
          shared: false,
        );
      } on SocketException catch (error) {
        final code = error.osError?.errorCode;
        if (code != 10048 && code != 98 && code != 48) rethrow;
        lastError = error;
        await Future<void>.delayed(_sessionLeasePoll);
      }
    }
    throw TimeoutException(
      'Timed out waiting for the browser E2E session lease on '
      '127.0.0.1:$port. Last bind error: $lastError',
      _sessionLeaseWait,
    );
  }

  static Future<void> _closeBrowser(Browser browser) async {
    try {
      await browser.close().timeout(const Duration(seconds: 15));
    } catch (_) {
      final process = browser.process;
      if (process != null) {
        process.kill();
        try {
          await process.exitCode.timeout(const Duration(seconds: 5));
        } catch (_) {
          // The original close failure is the actionable error.
        }
      }
      rethrow;
    }
  }

  /// `webdev build`, guarded by an inter-process lock: `dart test` runs test
  /// files concurrently and two build_runner instances in one package fight
  /// over `.dart_tool`.
  static Future<void> _build() async {
    final lockFile = File('build/.e2e_build.lock')
      ..parent.createSync(recursive: true);
    final lock = lockFile.openSync(mode: FileMode.write);
    try {
      lock.lockSync(FileLock.blockingExclusive);
    } catch (_) {
      lock.closeSync();
      rethrow;
    }
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
      try {
        lock.unlockSync();
      } finally {
        lock.closeSync();
      }
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

  // --- upstream EditorPage surface ------------------------------------------
  //
  // Port of `referencias/quilljs/test/e2e/pageobjects/EditorPage.ts`, so the
  // upstream E2E specs can be transcribed instead of reinvented. The setup
  // calls go through the demo's hooks (a Dart object cannot be published on
  // `window` the way `window.quill` is upstream); everything under test is
  // still driven by real keyboard, mouse and IME input.

  /// `editorPage.setContents(delta)`.
  Future<void> setContents(List<Map<String, dynamic>> delta) =>
      eval<void>('() => window.e2eSetContents(${_js(jsonEncode(delta))})');

  /// `editorPage.updateContents(delta, source)`.
  Future<void> updateContents(
    List<Map<String, dynamic>> delta, {
    String source = 'api',
  }) =>
      eval<void>('() => window.e2eUpdateContents('
          '${_js(jsonEncode(delta))}, ${_js(source)})');

  /// `editorPage.getContents()`, decoded.
  Future<List<dynamic>> getContents() async =>
      jsonDecode(await contents()) as List<dynamic>;

  /// `editorPage.setSelection(index, length)`.
  Future<void> setSelection(int index, [int length = 0]) =>
      eval<void>('() => window.e2eSetSelection($index, $length)');

  /// `editorPage.getSelection()` as `{index, length}`, or null.
  Future<Map<String, int>?> getSelection() async {
    final raw = await selection();
    if (raw == 'null') return null;
    final parts = raw.split(':');
    return {'index': int.parse(parts[0]), 'length': int.parse(parts[1])};
  }

  /// `editorPage.cutoffHistory()`.
  Future<void> cutoffHistory() => eval<void>('() => window.e2eCutoffHistory()');

  /// `window.quill.history.options.userOnly = value`.
  Future<void> setHistoryUserOnly(bool value) =>
      eval<void>('() => window.e2eSetHistoryUserOnly($value)');

  /// The JS of upstream's `getTextNodeDef` + `updateSelectionDef` helpers.
  ///
  /// Setting the selection resolves only after `selectionchange` has fired and
  /// Quill has read it back — upstream waits for the same thing, because a
  /// real user never acts before the browser has moved the caret.
  static const String _selectionHelpers = '''
    const getTextNode = (el, match) => {
      const walk = el.ownerDocument.createTreeWalker(
          el, NodeFilter.SHOW_TEXT, null, false);
      if (!match) return walk.nextNode();
      let node;
      while ((node = walk.nextNode())) {
        if (node.wholeText.includes(match)) return node;
      }
      return null;
    };
    const updateSelection = (range) => new Promise((resolve) => {
      document.addEventListener('selectionchange', () => {
        setTimeout(resolve, 1);
      }, {once: true});
      const selection = document.getSelection();
      selection?.removeAllRanges();
      selection?.addRange(range);
    });
  ''';

  /// `editorPage.moveCursorTo('s_econd')` — `_` marks the caret.
  Future<void> moveCursorTo(String query) async {
    final text = query.replaceFirst('_', '');
    await eval<void>('''async () => {
      $_selectionHelpers
      const editor = document.querySelector('.ql-editor');
      const node = getTextNode(editor, ${_js(text)});
      if (!node) throw new Error('text not found: ' + ${_js(text)});
      const offset = node.wholeText.indexOf(${_js(text)}) + ${query.indexOf('_')};
      const range = node.ownerDocument.createRange();
      range.setStart(node, offset);
      range.setEnd(node, offset);
      await updateSelection(range);
    }''');
  }

  Future<void> moveCursorAfterText(String text) => moveCursorTo('${text}_');

  Future<void> moveCursorBeforeText(String text) => moveCursorTo('_$text');

  /// `editorPage.selectText(start, [end])` — selects from the start of [start]
  /// to the end of [end] (or of [start] when [end] is omitted).
  Future<void> selectText(String start, [String? end]) async {
    await eval<void>('''async () => {
      $_selectionHelpers
      const editor = document.querySelector('.ql-editor');
      const anchorNode = getTextNode(editor, ${_js(start)});
      if (!anchorNode) throw new Error('text not found: ' + ${_js(start)});
      const focusNode = ${end == null ? 'anchorNode' : 'getTextNode(editor, ${_js(end)})'};
      if (!focusNode) throw new Error('text not found');
      const anchorOffset = anchorNode.wholeText.indexOf(${_js(start)});
      const focusOffset = ${end == null ? 'anchorOffset + ${start.length}' : 'focusNode.wholeText.indexOf(${_js(end)}) + ${end.length}'};
      const range = anchorNode.ownerDocument.createRange();
      range.setStart(anchorNode, anchorOffset);
      range.setEnd(focusNode, focusOffset);
      await updateSelection(range);
    }''');
  }

  /// `editorPage.typeWordWithIME(composition, word)` — a real composition
  /// session over CDP, exactly like upstream's Chromium fixture: two candidate
  /// updates and then a commit, each wrapped in keydown/keyup.
  Future<void> typeWordWithIME(String composedWord) async {
    final input = page.devTools.input;
    var composing = '';
    for (final key in const ['w', 'o']) {
      await _withKeyboardEvents(key, () async {
        composing += key;
        await input.imeSetComposition(
            composing, composing.length, composing.length);
      });
    }
    await _withKeyboardEvents('Space', () async {
      await input.insertText(composedWord);
    });
    await settle(60);
  }

  Future<void> _withKeyboardEvents(String key, Future<void> Function() body) async {
    await eval<void>('''() => {
      const target = document.activeElement;
      target?.dispatchEvent(new KeyboardEvent('keydown',
          {key: ${_js(key)}, bubbles: true, cancelable: true}));
    }''');
    await body();
    await eval<void>('''() => {
      const target = document.activeElement;
      target?.dispatchEvent(new KeyboardEvent('keyup',
          {key: ${_js(key)}, bubbles: true, cancelable: true}));
    }''');
  }

  /// The editor root's `innerHTML`, which several upstream specs assert on.
  Future<String> rootHtml() => editorHtml();

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

  /// Clicks the centre of [selector] with a real mouse click at real page
  /// coordinates, after checking what is actually on top at that point.
  ///
  /// More informative than `page.click`: when the element is off-screen,
  /// covered or zero-sized, the failure names the element that is there
  /// instead of a bare "not visible".
  Future<void> clickElement(String selector) async {
    final probe = await eval<Map<String, dynamic>>('''() => {
      const el = document.querySelector(${_js(selector)});
      if (!el) return {found: false};
      const r = el.getBoundingClientRect();
      const cx = r.left + r.width / 2, cy = r.top + r.height / 2;
      const hit = document.elementFromPoint(cx, cy);
      return {
        found: true, x: cx, y: cy, width: r.width, height: r.height,
        onTop: hit === el || el.contains(hit),
        hitTag: hit ? hit.tagName + '.' + hit.className : 'none',
        inViewport: r.top >= 0 && r.left >= 0 &&
            r.bottom <= window.innerHeight && r.right <= window.innerWidth,
      };
    }''');
    if (probe['found'] != true) {
      throw StateError('clickElement: no element matches $selector');
    }
    if ((probe['width'] as num) == 0 || (probe['height'] as num) == 0) {
      throw StateError('clickElement: $selector has an empty box ($probe)');
    }
    if (probe['inViewport'] != true) {
      throw StateError('clickElement: $selector is outside the viewport '
          '($probe)');
    }
    if (probe['onTop'] != true) {
      throw StateError('clickElement: $selector is covered by '
          '${probe['hitTag']} ($probe)');
    }
    await page.mouse
        .click(Point(probe['x'] as num, probe['y'] as num));
    await settle(80);
  }

  /// Drags from [from] to [to] with a real press-move-release gesture.
  Future<void> drag(Point<num> from, Point<num> to, {int steps = 10}) async {
    await page.mouse.move(from);
    await settle(60);
    await page.mouse.down();
    await page.mouse.move(to, steps: steps);
    await page.mouse.up();
    await settle();
  }

  /// A JS string literal for [value].
  ///
  /// `jsonEncode` (not a hand-rolled quote-escape): a delta carries `\n`, and
  /// escaping only the quotes turns that into a real newline inside the
  /// literal, which JS then hands back to Dart as an unparseable JSON string.
  static String _js(String value) => jsonEncode(value);
}
