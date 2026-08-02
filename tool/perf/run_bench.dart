/// Roda a bancada no Chrome e imprime a tabela comparativa.
///
/// Cenários medidos com o MESMO arquivo (o TR de 140 páginas):
///
/// 1. main thread, caminho atual  — parse + `setContents`
/// 2. main thread, via HTML       — parse + Delta→HTML + `innerHTML` + build
/// 3. worker devolvendo Delta     — main thread só faz `setContents`
/// 4. worker devolvendo HTML      — main thread só faz `innerHTML` + build
/// 5. WebAssembly (WasmGC)        — só o parse, para medir o ganho do alvo
///
/// Além do tempo, mede o CONGELAMENTO: uma sonda de `requestAnimationFrame`
/// conta o maior intervalo entre frames. É isso que o usuário sente.
library;

import 'dart:convert';
import 'dart:io';

import 'package:puppeteer/puppeteer.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_static/shelf_static.dart';

const _root = r'c:\MyDartProjects\dart_quill';

Future<void> main() async {
  // Serve tool/perf e também /packages/dart_quill/assets para o CSS.
  final perf = createStaticHandler('$_root\\tool\\perf',
      defaultDocument: 'index.html');
  final assets = createStaticHandler('$_root\\lib');
  shelf.Handler handler = (request) {
    if (request.url.path.startsWith('packages/dart_quill/')) {
      final rest = request.url.path.substring('packages/dart_quill/'.length);
      return assets(shelf.Request(request.method,
          Uri.parse('http://localhost/$rest')));
    }
    return perf(request);
  };
  final server = await shelf_io.serve(handler, '127.0.0.1', 8145);

  final browser = await puppeteer.launch(args: ['--no-sandbox']);
  final rows = <String, Map<String, dynamic>>{};
  try {
    final page = await browser.newPage();
    page.onConsole.listen((m) {
      final text = m.text ?? '';
      if (m.type == ConsoleMessageType.error) stdout.writeln('  [console] $text');
    });
    await page.goto('http://127.0.0.1:8145/', wait: Until.networkIdle);
    await page.waitForFunction('() => window.benchReady === true',
        timeout: const Duration(seconds: 60));

    /// Carrega os bytes do DOCX na página uma vez.
    await page.evaluate('''async () => {
      const res = await fetch('tr.docx');
      window.__docx = await res.arrayBuffer();
      window.__size = window.__docx.byteLength;
    }''');
    final size = await page.evaluate<int>('() => window.__size');
    stdout.writeln('arquivo: ${(size / 1024).round()} KB\n');

    /// Executa um cenário medindo o congelamento da interface.
    Future<Map<String, dynamic>> run(String label, String jsBody) async {
      final raw = await page.evaluate<String>('''async () => {
        window.startFrameProbe();
        const t0 = performance.now();
        const result = await (async () => { $jsBody })();
        const wall = performance.now() - t0;
        const probe = JSON.parse(window.stopFrameProbe());
        return JSON.stringify({
          ...JSON.parse(result),
          wallMs: Math.round(wall),
          maxGapMs: probe.maxGapMs,
          frames: probe.frames,
        });
      }''');
      final parsed = jsonDecode(raw) as Map<String, dynamic>;
      rows[label] = parsed;
      stdout.writeln('$label -> $parsed');
      return parsed;
    }

    // 2. Main thread, via HTML.
    await run('2. main: parse + HTML + innerHTML',
        "return window.benchInnerHtml(window.__docx.slice(0));");

    // 3/4. Worker.
    await page.evaluate('() => window.startWorker()');
    await run(
        '3. worker->Delta + setContents',
        "const r = await window.workerParse(window.__docx.slice(0), 'delta');"
        "const main = JSON.parse(window.benchFromDeltaJson(r.payload));"
        "return JSON.stringify({...main, workerParseMs: r.parseMs});");
    await run(
        '4. worker->HTML + innerHTML',
        "const r = await window.workerParse(window.__docx.slice(0), 'html');"
        "const main = JSON.parse(window.benchFromHtml(r.payload));"
        "return JSON.stringify({...main, workerParseMs: r.parseMs, "
        "workerToHtmlMs: r.toHtmlMs});");

    // 5. WebAssembly (só o parse).
    final wasmStartup =
        await page.evaluate<num>('() => window.loadWasm()');
    await page.waitForFunction('() => window.benchParse !== undefined',
        timeout: const Duration(seconds: 60));
    await run('5. wasm: parse',
        "return window.benchParse(window.__docx.slice(0));");
    stdout.writeln('   (startup do wasm: ${wasmStartup.round()} ms)');

    // 1. O caminho atual, por último: leva minutos e congela a página.
    if (Platform.environment['SKIP_SLOW'] != '1') {
      await run('1. main: parse + setContents',
          "return window.benchSetContents(window.__docx.slice(0));");
    }
  } finally {
    await browser.close();
    await server.close(force: true);
  }

  stdout.writeln('\n--- resumo (ms) ---');
  for (final entry in rows.entries) {
    final r = entry.value;
    stdout.writeln('${entry.key.padRight(34)} '
        'total=${r['wallMs']}  maiorTravada=${r['maxGapMs']}');
  }
}
