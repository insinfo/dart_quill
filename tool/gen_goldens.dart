/// Records the Delta that the real Quill produces for every case in
/// `test/goldens/cases.json`.
///
/// This is the only way to *prove* the port is Delta-compatible instead of
/// arguing it by inspection: the expectations are produced by the upstream
/// implementation itself, running in a real browser, and `goldens_test.dart`
/// replays the same cases against the Dart port and diffs op by op.
///
/// Usage:
///
///   dart run tool/gen_goldens.dart --quill <path to quill dist dir>
///   dart run tool/gen_goldens.dart --check      # CI: fail if stale
///
/// The Quill build is not vendored — point `--quill` at a `dist` directory
/// holding `quill.js` (`npm install quill@2.0.3` gives you one). The version is
/// read from the bundle and written into the golden, so a mismatch is visible
/// in the diff rather than silent.
library;

import 'dart:convert';
import 'dart:io';

import 'package:puppeteer/puppeteer.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_static/shelf_static.dart';

const String casesPath = 'test/goldens/cases.json';
const String goldenPath = 'test/goldens/quill_2.0.3.json';
const String expectedVersion = '2.0.3';

Future<void> main(List<String> args) async {
  final check = args.contains('--check');
  final quillDir = _argValue(args, '--quill') ?? _guessQuillDir();
  if (quillDir == null) {
    stderr.writeln(
      'Could not find a Quill build. Pass --quill <dir containing quill.js>, '
      'e.g. after `npm install quill@$expectedVersion`.',
    );
    exit(2);
  }
  final bundle = File('$quillDir/quill.js');
  if (!bundle.existsSync()) {
    stderr.writeln('No quill.js in $quillDir');
    exit(2);
  }

  final cases = (jsonDecode(File(casesPath).readAsStringSync())
      as Map<String, dynamic>)['cases'] as List<dynamic>;
  stdout.writeln('Running ${cases.length} cases against $bundle');

  final recorded = await _record(bundle, cases);
  final encoded = '${const JsonEncoder.withIndent('  ').convert(recorded)}\n';

  final golden = File(goldenPath);
  if (check) {
    if (!golden.existsSync() || golden.readAsStringSync() != encoded) {
      stderr.writeln('$goldenPath is stale — run `dart run tool/gen_goldens.dart`');
      exit(1);
    }
    stdout.writeln('$goldenPath is up to date');
    return;
  }
  golden.writeAsStringSync(encoded);
  stdout.writeln('Wrote $goldenPath');
}

String? _argValue(List<String> args, String name) {
  final index = args.indexOf(name);
  if (index < 0 || index + 1 >= args.length) return null;
  return args[index + 1];
}

/// Looks in the usual places so the common case needs no flag.
String? _guessQuillDir() {
  for (final candidate in const [
    'node_modules/quill/dist',
    '../node_modules/quill/dist',
    'referencias/quill_table_better/1.2.3/src/node_modules/quill/dist',
  ]) {
    if (File('$candidate/quill.js').existsSync()) return candidate;
  }
  return null;
}

Future<Map<String, dynamic>> _record(File bundle, List<dynamic> cases) async {
  final handler = shelf.Cascade()
      .add(createStaticHandler(bundle.parent.absolute.path))
      .add((request) => shelf.Response.ok(_page, headers: const {
            'content-type': 'text/html; charset=utf-8',
          }))
      .handler;
  final server = await shelf_io.serve(handler, InternetAddress.loopbackIPv4, 0);
  final browser = await puppeteer.launch(
    headless: true,
    args: const ['--no-sandbox'],
  );
  try {
    final page = await browser.newPage();
    final errors = <String>[];
    page.onError.listen((error) => errors.add('$error'));
    await page.goto('http://127.0.0.1:${server.port}/', wait: Until.load);
    if (errors.isNotEmpty) {
      throw StateError('Page failed to load Quill:\n${errors.join('\n')}');
    }

    final version = await page.evaluate<String>('() => window.Quill.version');
    if (version != expectedVersion) {
      stdout.writeln(
        'WARNING: recording against Quill $version, not $expectedVersion',
      );
    }

    final results = <Map<String, dynamic>>[];
    for (final entry in cases) {
      final testCase = entry as Map<String, dynamic>;
      final raw = await page.evaluate<Map<String, dynamic>>(
        '(testCase) => runCase(testCase)',
        args: [testCase],
      );
      results.add({
        'group': testCase['group'],
        'name': testCase['name'],
        if (raw['error'] != null) 'error': raw['error'],
        if (raw['error'] == null) ...{
          'contents': raw['contents'],
          'text': raw['text'],
        },
      });
      final status = raw['error'] == null ? 'ok' : 'ERROR ${raw['error']}';
      stdout.writeln('  ${testCase['name']} — $status');
    }
    return {
      'quill': version,
      'generator': 'tool/gen_goldens.dart',
      'note': 'Generated — do not edit. See the README block in cases.json.',
      'results': results,
    };
  } finally {
    await browser.close();
    await server.close(force: true);
  }
}

/// The harness page: a bare Quill with no theme, so nothing but the core
/// registry decides the Delta.
const String _page = '''
<!doctype html>
<html>
<head><meta charset="utf-8"><link rel="stylesheet" href="quill.core.css"></head>
<body>
<div id="editor"></div>
<script src="quill.js"></script>
<script>
const Delta = Quill.import('delta');

function runCase(testCase) {
  const host = document.getElementById('editor');
  host.innerHTML = '';
  const container = document.createElement('div');
  host.appendChild(container);
  try {
    const quill = new Quill(container, { theme: null });
    const setup = testCase.setup || {};
    if (typeof setup.html === 'string') {
      quill.setContents(quill.clipboard.convert({ html: setup.html }));
    } else {
      quill.setContents(new Delta(setup.delta || []));
    }
    for (const action of testCase.actions || []) {
      const args = (action.args || []).map(arg =>
        action.method === 'updateContents' && Array.isArray(arg)
          ? new Delta(arg)
          : arg);
      quill[action.method](...args);
    }
    return { contents: quill.getContents().ops, text: quill.getText() };
  } catch (error) {
    return { error: String(error && error.stack || error) };
  }
}
</script>
</body>
</html>
''';
