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

/// The two suites this tool can record.
class Suite {
  const Suite(this.name, this.casesPath, this.goldenPath, this.page);

  final String name;
  final String casesPath;
  final String goldenPath;
  final String page;

  static const core = Suite('core', 'test/goldens/cases.json',
      'test/goldens/quill_2.0.3.json', _corePage);
  static const tableBetter = Suite(
      'table-better',
      'test/goldens/table_better_cases.json',
      'test/goldens/quill_table_better_1.2.3.json',
      _tableBetterPage);

  static Suite byName(String name) =>
      name == 'table-better' ? tableBetter : core;
}

const String expectedVersion = '2.0.3';

Future<void> main(List<String> args) async {
  final check = args.contains('--check');
  final suite = Suite.byName(_argValue(args, '--suite') ?? 'core');
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

  if (suite.name == 'table-better' && !File(_pluginBundle).existsSync()) {
    stderr.writeln('No plugin bundle at $_pluginBundle');
    exit(2);
  }

  final cases = (jsonDecode(File(suite.casesPath).readAsStringSync())
      as Map<String, dynamic>)['cases'] as List<dynamic>;
  stdout.writeln(
      'Running ${cases.length} ${suite.name} cases against $bundle');

  final recorded = await _record(suite, bundle, cases);
  final encoded = '${const JsonEncoder.withIndent('  ').convert(recorded)}\n';

  final golden = File(suite.goldenPath);
  if (check) {
    if (!golden.existsSync() || golden.readAsStringSync() != encoded) {
      stderr.writeln('${suite.goldenPath} is stale — re-run the generator');
      exit(1);
    }
    stdout.writeln('${suite.goldenPath} is up to date');
    return;
  }
  golden.writeAsStringSync(encoded);
  stdout.writeln('Wrote ${suite.goldenPath}');
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

/// The plugin bundle, vendored in `referencias/` alongside its source.
const String _pluginBundle =
    'referencias/quill_table_better/1.2.3/src/dist/quill-table-better.js';

Future<Map<String, dynamic>> _record(
    Suite suite, File bundle, List<dynamic> cases) async {
  final handler = shelf.Cascade()
      .add(createStaticHandler(bundle.parent.absolute.path))
      .add(createStaticHandler(File(_pluginBundle).parent.absolute.path))
      .add((request) => shelf.Response.ok(suite.page, headers: const {
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
          'html': raw['html'],
          if (raw['semantic'] != null) 'semantic': raw['semantic'],
          if (raw['converted'] != null) 'converted': raw['converted'],
        },
      });
      final status = raw['error'] == null ? 'ok' : 'ERROR ${raw['error']}';
      stdout.writeln('  ${testCase['name']} — $status');
    }
    return {
      'quill': version,
      'suite': suite.name,
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
const String _corePage = '''
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
    let converted = null;
    const setup = testCase.setup || {};
    if (typeof setup.pasteHtml === 'string') {
      quill.setContents(new Delta());
      quill.clipboard.dangerouslyPasteHTML(setup.pasteHtml);
    } else if (typeof setup.html === 'string') {
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
    return {
      contents: quill.getContents().ops,
      text: quill.getText(),
      html: quill.root.innerHTML,
      // The public HTML serialization (editor.getHTML/convertHTML), so the
      // port's getSemanticHTML is proven against upstream on every case.
      semantic: quill.getSemanticHTML(),
      ...(converted ? { converted } : {}),
    };
  } catch (error) {
    return { error: String(error && error.stack || error) };
  }
}
</script>
</body>
</html>
''';

/// The table-better harness: quill plus the plugin bundle, wired exactly as the
/// plugin README prescribes (module registered with `overwrite`, the built-in
/// `table` module off, and the plugin's keyboard bindings installed).
const String _tableBetterPage = '''
<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <link rel="stylesheet" href="quill.snow.css">
  <link rel="stylesheet" href="quill-table-better.css">
</head>
<body>
<div id="editor"></div>
<script src="quill.js"></script>
<script src="quill-table-better.js"></script>
<script>
const Delta = Quill.import('delta');
Quill.register({ 'modules/table-better': QuillTableBetter }, true);

function runCase(testCase) {
  const host = document.getElementById('editor');
  host.innerHTML = '';
  const container = document.createElement('div');
  host.appendChild(container);
  try {
    const quill = new Quill(container, {
      theme: 'snow',
      modules: {
        table: false,
        // initWhiteList reads toolbar.container, so the plugin needs one.
        toolbar: [['bold', 'italic'], ['table-better']],
        'table-better': { language: 'en_US' },
        keyboard: { bindings: QuillTableBetter.keyboardBindings },
      },
    });
    let converted = null;
    const setup = testCase.setup || {};
    if (typeof setup.pasteHtml === 'string') {
      quill.setContents(new Delta());
      quill.clipboard.dangerouslyPasteHTML(setup.pasteHtml);
    } else if (typeof setup.html === 'string') {
      quill.setContents(quill.clipboard.convert({ html: setup.html }));
    } else {
      quill.setContents(new Delta(setup.delta || []));
    }
    for (const action of testCase.actions || []) {
      const args = (action.args || []).map(arg =>
        action.method === 'updateContents' && Array.isArray(arg)
          ? new Delta(arg)
          : arg);
      if (action.module) {
        quill.getModule('table-better')[action.module](...args);
      } else if (action.method === 'pasteHtml') {
        // Diagnostic: the intermediate delta, so a mismatch can be pinned on
        // the matchers or on the blots rather than guessed at.
        converted = quill.clipboard.convert({ html: args[1] }).ops;
        quill.clipboard.dangerouslyPasteHTML(args[0], args[1]);
      } else {
        quill[action.method](...args);
      }
    }
    return {
      contents: quill.getContents().ops,
      text: quill.getText(),
      html: quill.root.innerHTML,
      ...(converted ? { converted } : {}),
    };
  } catch (error) {
    return { error: String(error && error.stack || error) };
  }
}
</script>
</body>
</html>
''';
