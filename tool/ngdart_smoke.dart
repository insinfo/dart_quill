// Smoke test for example/ngdart: serves the built example and drives it with
// Puppeteer. Verifies (1) table-better menus hidden on load, (2) placeholder
// behavior, (3) inserting a 3x3 table through the toolbar grid picker.
import 'dart:io';

import 'package:puppeteer/puppeteer.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_static/shelf_static.dart';

Future<void> main() async {
  final buildDir = r'c:\MyDartProjects\dart_quill\example\ngdart\build';
  final handler = createStaticHandler(buildDir, defaultDocument: 'index.html');
  final server = await shelf_io.serve(
      const shelf.Pipeline().addHandler(handler), '127.0.0.1', 8137);

  final browser = await puppeteer.launch(args: ['--no-sandbox']);
  var failures = 0;
  void check(String name, bool ok, [String? detail]) {
    stdout.writeln('${ok ? "PASS" : "FAIL"}: $name${detail == null ? "" : " — $detail"}');
    if (!ok) failures++;
  }

  try {
    final page = await browser.newPage();
    final consoleErrors = <String>[];
    page.onConsole.listen((m) {
      if (m.type == ConsoleMessageType.error) consoleErrors.add(m.text ?? '');
    });
    await page.goto('http://127.0.0.1:8137/', wait: Until.networkIdle);
    await page.waitForSelector('.ql-editor', timeout: const Duration(seconds: 20));
    await Future<void>.delayed(const Duration(milliseconds: 500));

    // 1. Table menus bar must be hidden without a table.
    final menusDisplay = await page.evaluate<String>('''() => {
      const el = document.querySelector('.ql-table-menus-container');
      return el ? getComputedStyle(el).display : 'absent';
    }''');
    check('menus bar hidden on load', menusDisplay == 'none' || menusDisplay == 'absent',
        'display=$menusDisplay');

    // Grid picker (toolbar table select) must also be hidden.
    final gridDisplay = await page.evaluate<String>('''() => {
      const el = document.querySelector('.ql-table-select-container');
      return el ? getComputedStyle(el).display : 'absent';
    }''');
    check('grid picker hidden on load', gridDisplay == 'none' || gridDisplay == 'absent',
        'display=$gridDisplay');

    // 2. Placeholder: root has ql-blank + data-placeholder; typing clears it.
    final placeholderState = await page.evaluate<String>('''() => {
      const ed = document.querySelector('.ql-editor');
      const cs = getComputedStyle(ed, '::before');
      return JSON.stringify({
        blank: ed.classList.contains('ql-blank'),
        attr: ed.getAttribute('data-placeholder'),
        content: cs.content,
        position: cs.position,
      });
    }''');
    stdout.writeln('placeholder state on load: $placeholderState');
    check('ql-blank set on empty editor', placeholderState.contains('"blank":true'));

    await page.click('.ql-editor');
    await page.keyboard.type('abc');
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final blankAfter = await page.evaluate<bool>(
        '''() => document.querySelector('.ql-editor').classList.contains('ql-blank')''');
    final beforeContent = await page.evaluate<String>(
        '''() => getComputedStyle(document.querySelector('.ql-editor'), '::before').content''');
    check('placeholder cleared after typing', blankAfter == false,
        'ql-blank=$blankAfter, ::before content=$beforeContent');

    // 3. Insert a table through the toolbar grid.
    await page.click('button.ql-table-better');
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final gridShown = await page.evaluate<String>('''() => {
      const el = document.querySelector('.ql-table-select-container');
      return el ? getComputedStyle(el).display : 'absent';
    }''');
    check('grid picker opens on click', gridShown != 'none' && gridShown != 'absent',
        'display=$gridShown');

    // Hover the cell at row 3, col 3 and click it.
    final inserted = await page.evaluate<bool>('''() => {
      const container = document.querySelector('.ql-table-select-container');
      if (!container) return false;
      const cells = container.querySelectorAll('span');
      // 10x10 grid, row-major: index for (3,3) = 2*10+2.
      const target = cells[22];
      if (!target) return false;
      target.dispatchEvent(new MouseEvent('mousemove', {bubbles: true}));
      target.dispatchEvent(new MouseEvent('click', {bubbles: true}));
      return true;
    }''');
    check('grid cell clickable', inserted);
    await Future<void>.delayed(const Duration(milliseconds: 600));

    final tableState = await page.evaluate<String>('''() => {
      const t = document.querySelector('.ql-editor table');
      if (!t) return 'no-table';
      return 'rows=' + t.querySelectorAll('tr').length +
             ' cells=' + t.querySelectorAll('td,th').length;
    }''');
    check('3x3 table inserted', tableState == 'rows=3 cells=9', tableState);

    // Cell borders must be visible: Limitless bundles a pre-tables Quill and
    // Bootstrap's reboot zeroes td borders; quill.limitless.css restores the
    // core rules.
    final tdBorder = await page.evaluate<String>('''() => {
      const td = document.querySelector('.ql-editor td');
      if (!td) return 'no-td';
      const cs = getComputedStyle(td);
      return cs.borderTopWidth + ' ' + cs.borderTopStyle;
    }''');
    check('table cell has a visible border', tdBorder == '1px solid',
        tdBorder);

    // Menus bar should now be visible (caret inside the table).
    final menusAfter = await page.evaluate<String>('''() => {
      const el = document.querySelector('.ql-table-menus-container');
      return el ? getComputedStyle(el).display : 'absent';
    }''');
    stdout.writeln('menus bar after insert: display=$menusAfter');

    await page.screenshot().then((bytes) =>
        File(r'c:\MyDartProjects\dart_quill\example\ngdart\build\smoke.png')
            .writeAsBytesSync(bytes));

    if (consoleErrors.isNotEmpty) {
      stdout.writeln('console errors (${consoleErrors.length}):');
      for (final e in consoleErrors.take(5)) {
        stdout.writeln('  $e');
      }
    }
  } finally {
    await browser.close();
    await server.close(force: true);
  }
  stdout.writeln(failures == 0 ? 'ALL PASS' : '$failures FAILURES');
  exit(failures == 0 ? 0 : 1);
}
