@TestOn('vm')

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

  test('10x10 picker inserts the hovered table dimensions', () async {
    final body = await page.evaluate<String>('() => document.body.innerHTML');
    final tableButtons = await page.evaluate<int>(
        '() => document.querySelectorAll("button.ql-table").length');
    expect(tableButtons, 1, reason: body);
    final usesBundledTabler = await page.evaluate<bool>('''() =>
      document.querySelector('.ql-container.ql-icons-tabler') != null &&
      document.querySelector('button.ql-table i.ti-table') != null
    ''');
    expect(usesBundledTabler, isTrue);
    await page.click('.ql-editor');
    await page.click('button.ql-table');
    final visible = await page.$eval<bool>(
      '.ql-table-select-container',
      '(element) => getComputedStyle(element).display !== "none"',
    );
    expect(visible, isTrue);

    await page.click(
      '.ql-table-select-list span[data-row="2"][data-column="3"]',
    );

    final shape = await page.evaluate<Map<String, dynamic>>('''() => ({
      rows: document.querySelectorAll('.ql-editor table tr').length,
      columns: document.querySelector('.ql-editor table tr')
        ?.querySelectorAll('td').length ?? 0,
      pickerHidden: getComputedStyle(
        document.querySelector('.ql-table-select-container')
      ).display === 'none'
    })''');
    expect(shape['rows'], 2);
    expect(shape['columns'], 3);
    expect(shape['pickerHidden'], isTrue);
  });

  test('context toolbar uses icon-only normalized controls', () async {
    final hasTable = await page.evaluate<bool>(
        '() => document.querySelector(".ql-editor td") != null');
    if (!hasTable) {
      await page.click('.ql-editor');
      await page.click('button.ql-table');
      await page.click(
        '.ql-table-select-list span[data-row="2"][data-column="3"]',
      );
    }
    await page.click('.ql-editor td');
    final result = await page.evaluate<Map<String, dynamic>>('''() => {
      const toolbar = document.querySelector('.ql-table-context-toolbar');
      const buttons = [...toolbar.querySelectorAll('button')];
      const first = getComputedStyle(buttons[0]);
      return {
        visible: getComputedStyle(toolbar).display === 'flex',
        count: buttons.length,
        icons: buttons.every(button => button.querySelector('i.ti')),
        width: first.width,
        borderWidth: first.borderWidth,
        boxShadow: first.boxShadow
        ,cellBound: document.querySelector('.ql-editor td')?.dataset.contextToolbarBound,
        inlineStyle: toolbar.getAttribute('style')
      };
    }''');
    expect(result['visible'], isTrue, reason: '$result');
    expect(result['count'], 9);
    expect(result['icons'], isTrue);
    expect(result['width'], '28px');
    expect(result['borderWidth'], '0px');
    expect(result['boxShadow'], 'none');
  });

  test('context toolbar merges and splits the active cell', () async {
    final hasTable = await page.evaluate<bool>(
        '() => document.querySelector(".ql-editor td") != null');
    if (!hasTable) {
      await page.click('.ql-editor');
      await page.click('button.ql-table');
      await page.click(
        '.ql-table-select-list span[data-row="2"][data-column="3"]',
      );
    }
    await page.click('.ql-editor td');
    await page.click('[data-table-action="table-merge"]');

    var shape = await page.evaluate<Map<String, dynamic>>('''() => {
      const row = document.querySelector('.ql-editor tr');
      const first = row.querySelector('td');
      return { cells: row.querySelectorAll('td').length, colspan: first.colSpan };
    }''');
    expect(shape['cells'], 2);
    expect(shape['colspan'], 2);

    await page.click('[data-table-action="table-split"]');
    shape = await page.evaluate<Map<String, dynamic>>('''() => {
      const row = document.querySelector('.ql-editor tr');
      const first = row.querySelector('td');
      return { cells: row.querySelectorAll('td').length, colspan: first.colSpan };
    }''');
    expect(shape['cells'], 3);
    expect(shape['colspan'], 1);
  });
}
