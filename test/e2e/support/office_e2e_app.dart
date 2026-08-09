/// Puppeteer harness for the real `example/office_editor` application.
///
/// Unlike the browser unit tests, this builds and serves the consumer example,
/// opens DOCX files through the native file chooser, types with trusted
/// keyboard events, and downloads the DOCX produced by the ribbon. Runtime
/// evidence is written below `build/e2e-office-artifacts/`.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:puppeteer/puppeteer.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_static/shelf_static.dart';
import 'package:test/test.dart';

import '../../support/pdf_reader.dart';

final class OfficeImportEvidence {
  const OfficeImportEvidence({
    required this.metrics,
    required this.issues,
    required this.screenshots,
  });

  final Map<String, dynamic> metrics;
  final List<Map<String, dynamic>> issues;
  final List<String> screenshots;

  Map<String, dynamic> toJson() => {
        'metrics': metrics,
        'issues': issues,
        'screenshots': screenshots,
      };
}

/// Evidence from Arquivo -> Exportar PDF in the real browser application.
///
/// The file is the exact Blob handed to the application's download anchor,
/// not a second PDF produced by test code.
final class OfficePdfExportEvidence {
  const OfficePdfExportEvidence({
    required this.file,
    required this.browserFilename,
    required this.mimeType,
    required this.byteLength,
    required this.pageCount,
    required this.performance,
  });

  final File file;
  final String browserFilename;
  final String mimeType;
  final int byteLength;
  final int pageCount;
  final Map<String, dynamic> performance;

  Map<String, dynamic> toJson() => {
        'browserFilename': browserFilename,
        'mimeType': mimeType,
        'bytes': byteLength,
        'pageCount': pageCount,
        'file': file.absolute.path,
        'performance': performance,
      };
}

typedef _PaperCapture = ({
  List<int> bytes,
  Map<String, dynamic> evidence,
});

typedef _BrowserExportCapture = ({
  File file,
  Uint8List bytes,
  String browserFilename,
  String mimeType,
  Map<String, dynamic> performance,
});

/// Localiza um DOCX de `resources/` pelo PREFIXO do nome.
///
/// Os corpora de produção têm acento no nome (`Gestão`, `Recuperação`), e a
/// forma de normalização Unicode gravada no disco difere entre o Windows do
/// desenvolvedor e o checkout do Linux da CI: um caminho literal
/// `File('…Gestão…')` existe aqui e NÃO existe lá. Varrer o diretório e
/// comparar por prefixo ASCII é a única forma que funciona nos dois.
File officeCorpusFile(String prefix) {
  final directory = Directory('resources');
  if (directory.existsSync()) {
    for (final file in directory.listSync().whereType<File>()) {
      final name = file.uri.pathSegments.last;
      if (name.startsWith(prefix) && name.toLowerCase().endsWith('.docx')) {
        return file;
      }
    }
  }
  // Devolve um caminho inexistente com nome legível: o chamador decide entre
  // pular (corpus opcional) e falhar com mensagem clara.
  return File('resources/$prefix<ausente>.docx');
}

/// Os dois corpora de produção usados pelos e2e do editor Office.
File officeEtpCorpus() => officeCorpusFile('PGCTIC1_-_ETP_-');
File officeTrCorpus() => officeCorpusFile('PGCTIC1_-_TR_-');

/// Pula o teste quando o corpus de produção não está presente.
///
/// `resources/` é ignorado pelo git: os DOCX reais de compras públicas não
/// são versionados, então na CI eles simplesmente não existem. Falhar ali
/// dizia "o editor quebrou" quando o fato é "o insumo não veio" — e uma
/// suíte vermelha por ausência de fixture deixa de ser sinal. Pular é
/// visível no relatório; passar em silêncio, não.
bool skipWithoutCorpus(File corpus, String what) {
  if (corpus.existsSync()) return false;
  markTestSkipped(
      '$what indisponível (${corpus.path}): os corpora de produção não são '
      'versionados; rode localmente com resources/ populado');
  return true;
}

/// A built office example under control of a real Chromium instance.
final class OfficeE2eApp {
  OfficeE2eApp._(
    this._sessionLease,
    this._server,
    this._browser,
    this.page,
    this.artifactDirectory,
    this._issues,
  );

  static const String _exampleDirectory = 'example/office_editor';
  static const String _buildDirectory = 'example/office_editor/build';
  static const String _sessionLeasePortEnvironment = 'DART_QUILL_E2E_LOCK_PORT';
  static const int _defaultSessionLeasePort = 45873;
  static const Duration _sessionLeaseWait = Duration(minutes: 35);
  static const Duration _sessionLeasePoll = Duration(milliseconds: 250);

  final ServerSocket _sessionLease;
  final HttpServer _server;
  final Browser _browser;
  final Page page;
  final Directory artifactDirectory;
  final List<Map<String, dynamic>> _issues;
  Map<String, dynamic> _lastExportPerformance = const {};
  Map<String, dynamic> _lastEditPerformance = const {};
  Future<void>? _stopFuture;

  /// Performance evidence from the most recent real ribbon export.
  Map<String, dynamic> get lastExportPerformance =>
      Map<String, dynamic>.unmodifiable(_lastExportPerformance);

  /// Performance evidence from the most recent trusted table edit.
  Map<String, dynamic> get lastEditPerformance =>
      Map<String, dynamic>.unmodifiable(_lastEditPerformance);

  int get issueCount => _issues.length;

  List<Map<String, dynamic>> issuesSince(int start) =>
      List<Map<String, dynamic>>.unmodifiable(_issues.skip(start));

  static Future<OfficeE2eApp> start() async {
    final sessionLease = await _acquireSessionLease();

    HttpServer? server;
    Browser? browser;
    try {
      if (Platform.environment['OFFICE_E2E_REUSE_BUILD'] == '1') {
        _verifyBuildOutput();
      } else {
        await _buildExample();
      }

      final artifacts = Directory('build/e2e-office-artifacts')
        ..createSync(recursive: true);
      final handler = createStaticHandler(
        Directory(_buildDirectory).absolute.path,
        defaultDocument: 'index.html',
      );
      server = await shelf_io.serve(
        handler,
        InternetAddress.loopbackIPv4,
        0,
      );
      browser = await puppeteer.launch(
        headless: true,
        args: const [
          '--no-sandbox',
          '--disable-background-timer-throttling',
          '--disable-backgrounding-occluded-windows',
          '--disable-renderer-backgrounding',
        ],
      );
      final page = await browser.newPage();
      await page.setViewport(
        DeviceViewport(width: 1600, height: 1000, deviceScaleFactor: 1),
      );

      final issues = <Map<String, dynamic>>[];
      page.onConsole.listen((message) {
        issues.add({
          'kind': 'console',
          'severity': message.typeName,
          'message': message.text ?? '',
          if (message.url != null) 'url': message.url,
          if (message.lineNumber != null) 'line': message.lineNumber,
        });
      });
      page.onError.listen((error) {
        issues.add({
          'kind': 'page-error',
          'severity': 'error',
          'message': error.toString(),
        });
      });
      page.onResponse.listen((response) {
        if (response.status >= 400) {
          issues.add({
            'kind': 'http',
            'severity': 'error',
            'status': response.status,
            'url': response.url,
          });
        }
      });

      await page.goto(
        'http://127.0.0.1:${server.port}',
        wait: Until.networkIdle,
        timeout: const Duration(minutes: 2),
      );
      await page.waitForSelector(
        '.dq-office-app .dq-office-page',
        timeout: const Duration(minutes: 2),
      );
      return OfficeE2eApp._(
        sessionLease,
        server,
        browser,
        page,
        artifacts,
        issues,
      );
    } catch (_) {
      try {
        if (browser != null) await _closeBrowser(browser);
      } catch (_) {
        // Preserve the startup error; browser cleanup is best-effort here.
      }
      try {
        if (server != null) {
          await server.close(force: true).timeout(const Duration(seconds: 5));
        }
      } catch (_) {
        // Preserve the startup error; server cleanup is best-effort here.
      }
      try {
        await sessionLease.close().timeout(const Duration(seconds: 5));
      } catch (_) {
        // Preserve the startup error; the OS also releases a socket on exit.
      }
      rethrow;
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
        if (!_isAddressInUse(error)) rethrow;
        lastError = error;
        // Yield to the isolate that currently owns the browser session.
        await Future<void>.delayed(_sessionLeasePoll);
      }
    }
    throw TimeoutException(
      'Timed out waiting for the browser E2E session lease on '
      '127.0.0.1:$port. Last bind error: $lastError',
      _sessionLeaseWait,
    );
  }

  static bool _isAddressInUse(SocketException error) =>
      const {48, 98, 10048}.contains(error.osError?.errorCode);

  static Future<void> _closeBrowser(Browser browser) async {
    try {
      await browser.close().timeout(const Duration(seconds: 15));
    } catch (error, stackTrace) {
      final process = browser.process;
      if (process == null) {
        Error.throwWithStackTrace(error, stackTrace);
      }
      // Chromium 131 + Puppeteer 3.19 can leave its graceful Browser.close
      // handshake waiting after a large (140-page) session. Once the owned
      // process exits after SIGTERM, cleanup is complete and must not turn a
      // fully successful interaction test red.
      if (Platform.isWindows) {
        // Puppeteer's root process can exit while a renderer still owns the
        // inherited stdio handles, leaving Process.exitCode unresolved. Kill
        // only the exact process tree launched above; taskkill /T confirms the
        // whole owned Chromium tree is gone and avoids touching user browsers.
        try {
          final terminated = await Process.run(
            'taskkill',
            ['/PID', '${process.pid}', '/T', '/F'],
          ).timeout(const Duration(seconds: 20));
          if (terminated.exitCode == 0) return;
        } catch (_) {
          // Fall through to the portable strong-signal path.
        }
      }
      final signalled = process.kill(ProcessSignal.sigkill);
      if (!signalled) return; // already exited between close and termination
      // A successful strong signal is the cleanup boundary. On Windows,
      // Chromium renderers may keep the Process stdio handles inherited by
      // Puppeteer alive even after the owned root was terminated, so waiting
      // on `exitCode` can time out a second time and incorrectly fail an
      // otherwise complete interaction test.
      return;
    }
  }

  static Future<void> _buildExample() async {
    final lockFile = File('build/.office_e2e_build.lock')
      ..parent.createSync(recursive: true);
    final lock = lockFile.openSync(mode: FileMode.write);
    lock.lockSync(FileLock.blockingExclusive);
    try {
      final pubGet = await Process.run(
        Platform.resolvedExecutable,
        const ['pub', 'get'],
        workingDirectory: Directory(_exampleDirectory).absolute.path,
      );
      if (pubGet.exitCode != 0) {
        throw StateError(
          'Office example pub get failed:\n'
          '${pubGet.stdout}\n${pubGet.stderr}',
        );
      }
      final build = await Process.run(
        Platform.resolvedExecutable,
        const [
          'run',
          'build_runner',
          'build',
          '--release',
          '--delete-conflicting-outputs',
          '--output',
          'web:build',
        ],
        workingDirectory: Directory(_exampleDirectory).absolute.path,
      );
      if (build.exitCode != 0) {
        throw StateError(
          'Office example build failed:\n${build.stdout}\n${build.stderr}',
        );
      }
      _verifyBuildOutput();
    } finally {
      lock.unlockSync();
      lock.closeSync();
    }
  }

  static void _verifyBuildOutput() {
    if (!File('$_buildDirectory/index.html').existsSync() ||
        !File('$_buildDirectory/main.dart.js').existsSync()) {
      throw StateError('Office example build produced no runnable output');
    }
  }

  Future<void> stop() => _stopFuture ??= _stopOnce();

  Future<void> _stopOnce() async {
    Object? firstError;
    StackTrace? firstStackTrace;

    Future<void> close(Future<void> Function() action) async {
      try {
        await action();
      } catch (error, stackTrace) {
        firstError ??= error;
        firstStackTrace ??= stackTrace;
      }
    }

    await close(() => _closeBrowser(_browser));
    await close(() async {
      await _server.close(force: true).timeout(const Duration(seconds: 5));
    });
    await close(() async {
      await _sessionLease.close().timeout(const Duration(seconds: 5));
    });

    if (firstError != null) {
      Error.throwWithStackTrace(firstError!, firstStackTrace!);
    }
  }

  Future<void> reload() async {
    await page.reload(wait: Until.networkIdle);
    await page.waitForSelector(
      '.dq-office-app .dq-office-page',
      timeout: const Duration(seconds: 30),
    );
  }

  /// Opens [docx] through Arquivo -> Abrir DOCX and records render evidence.
  Future<OfficeImportEvidence> importDocx(
    File docx, {
    required String artifactName,
    Duration timeout = const Duration(minutes: 3),
    List<int> pageNumbers = const [],
    bool captureScreenshots = true,
  }) async {
    if (!docx.existsSync()) {
      throw StateError('DOCX fixture does not exist: ${docx.path}');
    }
    final issueStart = _issues.length;
    final screenshots = <String>[];
    final stopwatch = Stopwatch();

    try {
      await _trustedPointerClick('.dq-office-ribbon-tab:nth-child(1)');
      // Keep a handle to the ephemeral input created by the web adapter. The
      // normal path below is still Chromium's real file-chooser event; this
      // handle is a recovery path for a known CDP race where Puppeteer 3.19
      // occasionally misses that event even though the trusted ribbon click
      // did create the input.
      await page.evaluate<void>('''() => {
        window.__dqOfficeLastFileInput = null;
        if (window.__dqOfficeFileInputHookInstalled) return;
        window.__dqOfficeFileInputHookInstalled = true;
        const nativeClick = HTMLInputElement.prototype.click;
        HTMLInputElement.prototype.click = function() {
          if (this.type === 'file') window.__dqOfficeLastFileInput = this;
          return nativeClick.call(this);
        };
      }''');
      final chooserFuture = page.waitForFileChooser(
        timeout: const Duration(seconds: 15),
      );
      await _trustedPointerClick(
        'button[title="Abrir arquivo DOCX"]',
        bringToFront: false,
      );
      try {
        final chooser = await chooserFuture;
        await chooser.accept([docx.absolute]);
      } on TimeoutException {
        final handle = await page.evaluateHandle<JsHandle>(
          '() => window.__dqOfficeLastFileInput',
        );
        final input = handle.asElement;
        if (input == null) {
          await handle.dispose();
          rethrow;
        }
        try {
          await input.uploadFile([docx.absolute]);
        } finally {
          await input.dispose();
        }
      }
      // Native chooser/CDP hand-off time is neither parsing nor rendering.
      // Starting here keeps the metric about editor work after the user has
      // selected the file and avoids rAF suspension while the chooser is up.
      stopwatch.start();
      await _startPerformanceProbe();

      await _waitForImportedDocument(
        issueStart: issueStart,
        timeout: timeout,
      );
      await Future<void>.delayed(const Duration(milliseconds: 250));
      stopwatch.stop();

      final metrics = await _finishPerformanceProbe();
      metrics['file'] = docx.absolute.path;
      metrics['sourceBytes'] = docx.lengthSync();
      metrics['importMs'] = stopwatch.elapsedMilliseconds;
      metrics['topStatusPage'] = await _visibleStatusPage();

      final indexedStatus = <String, dynamic>{};
      metrics['indexedPageStatus'] = indexedStatus;
      if (captureScreenshots) {
        screenshots.add(await screenshot('$artifactName-imported-top'));
        final firstPage = await _mountedPageScreenshot(
          '$artifactName-rendered-page-first',
        );
        if (firstPage != null) screenshots.add(firstPage);
        final middle = await _middleScreenshot(artifactName, metrics);
        if (middle != null) screenshots.add(middle);
        final last = await _lastScreenshot(artifactName, metrics);
        if (last != null) screenshots.add(last);
        for (final pageNumber in pageNumbers.toSet()) {
          if (pageNumber < 1 || pageNumber > (metrics['totalPages'] as int)) {
            continue;
          }
          final captured = await _indexedPageScreenshot(
            artifactName,
            pageNumber,
            status: indexedStatus,
          );
          if (captured != null) screenshots.add(captured);
        }
        if (pageNumbers.isNotEmpty) {
          final lastPage = metrics['totalPages'] as int;
          if (pageNumbers.contains(lastPage)) {
            indexedStatus['last'] = indexedStatus['$lastPage'];
          } else {
            final captured = await _indexedPageScreenshot(
              artifactName,
              lastPage,
              label: 'last',
              status: indexedStatus,
            );
            if (captured != null) screenshots.add(captured);
          }
          await page.evaluate<void>('''() => {
            const canvas = document.querySelector('.dq-office-canvas');
            if (canvas) canvas.scrollTop = 0;
          }''');
          await Future<void>.delayed(const Duration(milliseconds: 150));
        }
      }

      final evidence = OfficeImportEvidence(
        metrics: metrics,
        issues: _issues.sublist(issueStart),
        screenshots: screenshots,
      );
      await writeJson('$artifactName-import', evidence.toJson());
      stdout.writeln(
        'OFFICE_E2E import $artifactName: ${jsonEncode(metrics)}',
      );
      return evidence;
    } catch (error, stackTrace) {
      stopwatch.stop();
      try {
        screenshots.add(await screenshot('$artifactName-import-failed'));
      } catch (_) {
        // A crashed page may be unable to provide a screenshot. Preserve the
        // original import error, which is more useful than this secondary one.
      }
      await writeJson('$artifactName-import-failed', {
        'file': docx.absolute.path,
        'importMs': stopwatch.elapsedMilliseconds,
        'error': '$error',
        'stackTrace': '$stackTrace',
        'issues': _issues.sublist(issueStart),
        'screenshots': screenshots,
      });
      rethrow;
    }
  }

  Future<void> _waitForImportedDocument({
    required int issueStart,
    required Duration timeout,
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      final fatal = _issues.skip(issueStart).where(_isFatalIssue).toList();
      if (fatal.isNotEmpty) {
        throw StateError('Browser error while importing DOCX: $fatal');
      }
      final imported = await page.evaluate<bool>('''() => {
        const pages = document.querySelector('.dq-office-pages');
        if (!pages) return false;
        const text = pages.textContent || '';
        return !text.includes('Documento de demonstração do editor Word') &&
            pages.children.length > 0 && text.trim().length > 20;
      }''');
      if (imported) return;
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    throw TimeoutException(
        'DOCX import did not replace the sample document', timeout);
  }

  static bool _isFatalIssue(Map<String, dynamic> issue) =>
      issue['severity'] == 'error';

  Future<void> _startPerformanceProbe() => page.evaluate<void>('''() => {
    window.__dqOfficeLongTasks = [];
    try {
      window.__dqOfficeLongTaskObserver?.disconnect();
      window.__dqOfficeLongTaskObserver = new PerformanceObserver((list) => {
        for (const entry of list.getEntries()) {
          window.__dqOfficeLongTasks.push({
            startTime: entry.startTime,
            duration: entry.duration,
          });
        }
      });
      window.__dqOfficeLongTaskObserver.observe({entryTypes: ['longtask']});
    } catch (_) {}

    const probe = window.__dqOfficeFrameProbe = {
      running: true,
      last: null,
      maxGapMs: 0,
      frames: 0,
    };
    const frame = (now) => {
      if (!probe.running) return;
      // The first rAF is a baseline only. In headless Chromium a background
      // tab may throttle that first callback for seconds; charging time since
      // the CDP command would report a freeze that did not happen in editor
      // work. PerformanceObserver long tasks remain independently recorded.
      if (probe.last !== null) {
        probe.maxGapMs = Math.max(probe.maxGapMs, now - probe.last);
      }
      probe.last = now;
      probe.frames++;
      requestAnimationFrame(frame);
    };
    requestAnimationFrame(frame);
  }''');

  Future<Map<String, dynamic>> _finishPerformanceProbe() async {
    final raw = await page.evaluate<String>('''() => {
      const probe = window.__dqOfficeFrameProbe || {};
      probe.running = false;
      const observer = window.__dqOfficeLongTaskObserver;
      // PerformanceObserver callbacks are delivered asynchronously. Drain
      // queued records before disconnecting so a long task that produced the
      // export Blob cannot slip through the final sampling boundary.
      try {
        for (const entry of observer?.takeRecords?.() || []) {
          window.__dqOfficeLongTasks.push({
            startTime: entry.startTime,
            duration: entry.duration,
          });
        }
      } catch (_) {}
      observer?.disconnect();
      const tasks = window.__dqOfficeLongTasks || [];
      const pages = document.querySelector('.dq-office-pages');
      const canvas = document.querySelector('.dq-office-canvas');
      const firstPaper = pages?.querySelector('.dq-office-page');
      const firstPaperRect = firstPaper?.getBoundingClientRect();
      const status = [...document.querySelectorAll('.dq-office-status-item')]
          .map((element) => element.textContent || '');
      const memory = performance.memory;
      let phaseTimings = {};
      let exportPhaseTimings = {};
      try {
        phaseTimings = JSON.parse(document.body.getAttribute(
          'data-dq-office-import-timings') || '{}');
      } catch (_) {}
      try {
        exportPhaseTimings = JSON.parse(document.body.getAttribute(
          'data-dq-office-export-timings') || '{}');
      } catch (_) {}
      return JSON.stringify({
        totalPages: pages ? pages.children.length : 0,
        mountedPages: pages ? pages.querySelectorAll('.dq-office-page').length : 0,
        placeholders: pages ? pages.querySelectorAll(
            '.dq-office-page-placeholder').length : 0,
        editableSurfaces: pages ? pages.querySelectorAll(
            '[contenteditable="true"]').length : 0,
        renderedBlocks: pages ? pages.querySelectorAll('.dq-office-block').length : 0,
        renderedRuns: pages ? pages.querySelectorAll('.dq-office-run').length : 0,
        visibleTextChars: pages ? (pages.textContent || '').length : 0,
        domNodes: document.querySelectorAll('*').length,
        canvasScrollHeight: canvas ? canvas.scrollHeight : 0,
        canvasClientHeight: canvas ? canvas.clientHeight : 0,
        firstPaperWidthPx: firstPaperRect ? firstPaperRect.width : 0,
        firstPaperHeightPx: firstPaperRect ? firstPaperRect.height : 0,
        status,
        frames: probe.frames || 0,
        maxFrameGapMs: Math.round(probe.maxGapMs || 0),
        longTasks: tasks.length,
        longTaskTotalMs: Math.round(tasks.reduce(
            (total, task) => total + task.duration, 0)),
        maxLongTaskMs: Math.round(tasks.reduce(
            (maximum, task) => Math.max(maximum, task.duration), 0)),
        jsHeapBytes: memory ? memory.usedJSHeapSize : null,
        resources: performance.getEntriesByType('resource').length,
        phaseTimings,
        exportPhaseTimings,
      });
    }''');
    return (jsonDecode(raw) as Map).cast<String, dynamic>();
  }

  Future<String?> _middleScreenshot(
      String artifactName, Map<String, dynamic> metrics) async {
    final pageCount = await page.evaluate<int>('''() =>
      document.querySelector('.dq-office-pages')?.children.length || 0''');
    if (pageCount < 3) return null;
    final middle = await _mountLogicalPage(pageCount ~/ 2);
    await middle.dispose();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    metrics['middleStatusPage'] = await _visibleStatusPage();
    final path = await screenshot('$artifactName-imported-middle');
    final first = await _mountLogicalPage(0);
    await first.dispose();
    return path;
  }

  Future<String?> _lastScreenshot(
      String artifactName, Map<String, dynamic> metrics) async {
    final pageCount = await page.evaluate<int>('''() =>
      document.querySelector('.dq-office-pages')?.children.length || 0''');
    if (pageCount < 2) return null;
    final last = await _mountLogicalPage(pageCount - 1);
    await last.dispose();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    metrics['lastStatusPage'] = await _visibleStatusPage();
    final path = await screenshot('$artifactName-imported-last');
    final first = await _mountLogicalPage(0);
    await first.dispose();
    return path;
  }

  Future<int> _visibleStatusPage() => page.evaluate<int>('''() => {
    const text = document.querySelector(
      '.dq-office-status-item')?.textContent || '';
    const value = Number(text.split(' ')[1]);
    return Number.isFinite(value) ? value : 0;
  }''');

  /// Actively mounts a virtualized logical page and keeps it at the canvas
  /// viewport. Merely waiting for `.dq-office-page` is not sufficient after
  /// Puppeteer's full-element screenshot temporarily resizes the viewport:
  /// the resize can replace the paper with its placeholder without emitting
  /// another canvas scroll event.
  Future<ElementHandle> _mountLogicalPage(
    int pageIndex, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final selector = '.dq-office-page[data-page="$pageIndex"]';
    final watch = Stopwatch()..start();
    while (watch.elapsed < timeout) {
      final found = await page.evaluate<bool>('''async () => {
        const canvas = document.querySelector('.dq-office-canvas');
        const target = document.querySelector('[data-page="$pageIndex"]');
        if (!canvas || !target) return false;
        const canvasTop = canvas.getBoundingClientRect().top;
        const targetTop = target.getBoundingClientRect().top;
        canvas.scrollTop += targetTop - canvasTop;
        // Setting scrollTop normally queues a scroll event. Dispatching one
        // now also covers the clamped/no-delta case after viewport restore.
        canvas.dispatchEvent(new Event('scroll'));
        await new Promise(resolve => requestAnimationFrame(() =>
          requestAnimationFrame(resolve)));
        return true;
      }''');
      if (!found) {
        throw StateError('Logical page ${pageIndex + 1} does not exist');
      }
      final mounted = await page.$OrNull(selector);
      if (mounted != null) return mounted;
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    throw TimeoutException(
      'Logical page ${pageIndex + 1} was not mounted after active scrolling',
      timeout,
    );
  }

  Future<String?> _indexedPageScreenshot(
    String artifactName,
    int pageNumber, {
    String? label,
    required Map<String, dynamic> status,
  }) async {
    final pageIndex = pageNumber - 1;
    var element = await _mountLogicalPage(pageIndex);
    await element.dispose();
    await Future<void>.delayed(const Duration(milliseconds: 250));
    // Reacquire because the final alignment scroll can replace the DOM node.
    element = await _mountLogicalPage(pageIndex);
    status[label ?? '$pageNumber'] = await _visibleStatusPage();
    final name = label ?? 'p$pageNumber';
    final file = File(
      '${artifactDirectory.path}/$artifactName-rendered-page-$name.png',
    );
    final _PaperCapture capture;
    try {
      capture = await _isolatedPaperScreenshot(element);
    } finally {
      await element.dispose();
    }
    file.writeAsBytesSync(capture.bytes);
    await writeJson(
      '$artifactName-rendered-page-$name-capture',
      capture.evidence,
    );
    return file.absolute.path;
  }

  /// Captures one logical page and returns the pixel/DOM evidence sidecar.
  /// This is intentionally public only on the E2E harness so focused tests do
  /// not need to trigger every viewport screenshot made by [importDocx].
  Future<Map<String, dynamic>> capturePageEvidence({
    required String artifactName,
    required int pageNumber,
  }) async {
    final status = <String, dynamic>{};
    final path = await _indexedPageScreenshot(
      artifactName,
      pageNumber,
      status: status,
    );
    if (path == null) {
      throw StateError('Rendered page $pageNumber could not be captured');
    }
    final sidecar = File(
      '${artifactDirectory.path}/$artifactName-rendered-page-'
      'p$pageNumber-capture.json',
    );
    final evidence =
        (jsonDecode(sidecar.readAsStringSync()) as Map).cast<String, dynamic>();
    return {
      ...evidence,
      'file': path,
      'status': status,
    };
  }

  /// Captures a complete rendered paper element (without the surrounding
  /// ribbon/canvas) so it can be compared directly with a Word/PDF reference
  /// page. Puppeteer temporarily grows the viewport when the full A4 element
  /// is taller than it, then restores the original viewport.
  Future<String?> _mountedPageScreenshot(String name) async {
    final element = await page.$OrNull('.dq-office-page');
    if (element == null) return null;
    final file = File('${artifactDirectory.path}/$name.png');
    final capture = await _isolatedPaperScreenshot(element);
    file.writeAsBytesSync(capture.bytes);
    await writeJson('$name-capture', capture.evidence);
    return file.absolute.path;
  }

  /// Captures only the paper from a fixed clone outside the canvas scroller.
  ///
  /// Puppeteer 3.19 grows the viewport to the element height, but the editor's
  /// title/ribbon/rulers/status still consume part of that height. The A4 page
  /// therefore remains taller than `.dq-office-canvas`; Chromium centers it
  /// in that overflow ancestor and paints the clipped ends with app chrome.
  /// A fixed clone remains under `.dq-office-app` (preserving scoped CSS and
  /// fonts) while escaping only that overflow boundary.
  Future<_PaperCapture> _isolatedPaperScreenshot(
    ElementHandle element,
  ) async {
    final before = await _paperInvariant(element);
    final beforeMap = (jsonDecode(before) as Map).cast<String, dynamic>();
    final pageIndex = await element.evaluate<String>(
      "element => element.getAttribute('data-page')",
    );
    if (pageIndex == null) {
      throw StateError('Rendered paper has no data-page identity');
    }

    JsHandle? cloneHandle;
    ElementHandle? clone;
    late List<int> bytes;
    late String regionsRaw;
    late Map<String, dynamic> cloneInvariantMap;
    late Map<String, dynamic> pixelEvidence;
    try {
      cloneHandle = await element.evaluateHandle<JsHandle>('''async element => {
        document.querySelector('[data-dq-office-e2e-paper-clone]')?.remove();
        const app = element.closest('.dq-office-app');
        if (!app) throw new Error('Paper has no Office app ancestor');

        const clone = element.cloneNode(true);
        clone.removeAttribute('data-page');
        clone.setAttribute('data-dq-office-e2e-paper-clone', 'true');
        clone.setAttribute('aria-hidden', 'true');
        clone.style.setProperty('position', 'fixed', 'important');
        clone.style.setProperty('left', '0', 'important');
        clone.style.setProperty('top', '0', 'important');
        clone.style.setProperty('margin', '0', 'important');
        clone.style.setProperty('z-index', '2147483647', 'important');
        clone.style.setProperty('pointer-events', 'none', 'important');
        app.append(clone);

        if (document.fonts?.ready) await document.fonts.ready;
        await Promise.all([...clone.querySelectorAll('img')].map(async image => {
          try { await image.decode(); } catch (_) {}
        }));
        await new Promise(resolve => requestAnimationFrame(() =>
          requestAnimationFrame(resolve)));
        return clone;
      }''');
      clone = cloneHandle.asElement;
      if (clone == null) {
        throw StateError('Paper clone is not an element');
      }

      final cloneInvariant = await _paperInvariant(clone);
      if (cloneInvariant != before) {
        throw StateError(
          'Fixed paper clone changed geometry/content: '
          '$before -> $cloneInvariant',
        );
      }
      cloneInvariantMap =
          (jsonDecode(cloneInvariant) as Map).cast<String, dynamic>();

      regionsRaw = (await clone.evaluate<String>('''element => {
        const paper = element.getBoundingClientRect();
        const relativeVisualRect = selector => {
          const region = element.querySelector(selector);
          if (!region) return null;
          const boxes = [region, ...region.querySelectorAll('*')]
            .map(node => node.getBoundingClientRect())
            .filter(rect => rect.width > 0 && rect.height > 0);
          const left = Math.max(paper.left,
            Math.min(...boxes.map(rect => rect.left)));
          const top = Math.max(paper.top,
            Math.min(...boxes.map(rect => rect.top)));
          const right = Math.min(paper.right,
            Math.max(...boxes.map(rect => rect.right)));
          const bottom = Math.min(paper.bottom,
            Math.max(...boxes.map(rect => rect.bottom)));
          return {
            left: left - paper.left,
            top: top - paper.top,
            width: Math.max(0, right - left),
            height: Math.max(0, bottom - top),
          };
        };
        return JSON.stringify({
          header: relativeVisualRect('.dq-office-header'),
          footer: relativeVisualRect('.dq-office-footer'),
        });
      }'''))!;

      // Capture the clone, never the original element still clipped by the
      // canvas.
      bytes = await clone.screenshot();
      final dataUrl = 'data:image/png;base64,${base64Encode(bytes)}';
      final pixelsRaw = await page.evaluate<String>(
        '''async (url, regionsJson) => {
          const regions = JSON.parse(regionsJson);
          const image = new Image();
          image.src = url;
          await image.decode();
          const canvas = document.createElement('canvas');
          canvas.width = image.naturalWidth;
          canvas.height = image.naturalHeight;
          const context = canvas.getContext('2d', {willReadFrequently: true});
          context.drawImage(image, 0, 0);
          const pixels = context.getImageData(
            0, 0, canvas.width, canvas.height).data;

          const rgbaAt = (x, y) => {
            const offset = (y * canvas.width + x) * 4;
            return [...pixels.slice(offset, offset + 4)];
          };
          const inkIn = rect => {
            if (!rect) return {pixels: 0, widthSpan: 0, heightSpan: 0};
            const left = Math.max(0, Math.floor(rect.left));
            const top = Math.max(0, Math.floor(rect.top));
            const right = Math.min(canvas.width,
              Math.ceil(rect.left + rect.width));
            const bottom = Math.min(canvas.height,
              Math.ceil(rect.top + rect.height));
            let ink = 0;
            let minX = right;
            let maxX = left - 1;
            let minY = bottom;
            let maxY = top - 1;
            for (let y = top; y < bottom; y++) {
              for (let x = left; x < right; x++) {
                const offset = (y * canvas.width + x) * 4;
                const r = pixels[offset];
                const g = pixels[offset + 1];
                const b = pixels[offset + 2];
                const a = pixels[offset + 3];
                const appGray = r === 248 && g === 248 && b === 247;
                if (a > 0 && !appGray &&
                    ((255 - r) + (255 - g) + (255 - b) > 30)) {
                  ink++;
                  minX = Math.min(minX, x);
                  maxX = Math.max(maxX, x);
                  minY = Math.min(minY, y);
                  maxY = Math.max(maxY, y);
                }
              }
            }
            return {
              pixels: ink,
              widthSpan: ink === 0 ? 0 : maxX - minX + 1,
              heightSpan: ink === 0 ? 0 : maxY - minY + 1,
            };
          };

          const headerInk = inkIn(regions.header);
          const footerInk = inkIn(regions.footer);

          let currentAppGrayBand = 0;
          let maxAppGrayBand = 0;
          for (let y = 0; y < canvas.height; y++) {
            let fullAppGray = true;
            for (let x = 0; x < canvas.width; x++) {
              const offset = (y * canvas.width + x) * 4;
              if (pixels[offset] !== 248 ||
                  pixels[offset + 1] !== 248 ||
                  pixels[offset + 2] !== 247 ||
                  pixels[offset + 3] !== 255) {
                fullAppGray = false;
                break;
              }
            }
            currentAppGrayBand = fullAppGray
              ? currentAppGrayBand + 1 : 0;
            maxAppGrayBand = Math.max(maxAppGrayBand,
              currentAppGrayBand);
          }

          return JSON.stringify({
            width: canvas.width,
            height: canvas.height,
            topLeft: rgbaAt(0, 0),
            bottomLeft: rgbaAt(0, canvas.height - 1),
            maxAppGrayBandRows: maxAppGrayBand,
            headerInkPixels: headerInk.pixels,
            headerInkWidthSpan: headerInk.widthSpan,
            headerInkHeightSpan: headerInk.heightSpan,
            footerInkPixels: footerInk.pixels,
            footerInkWidthSpan: footerInk.widthSpan,
            footerInkHeightSpan: footerInk.heightSpan,
          });
        }''',
        args: [dataUrl, regionsRaw],
      );
      pixelEvidence = (jsonDecode(pixelsRaw) as Map).cast<String, dynamic>();

      final expectedWidth = (beforeMap['width'] as num).round();
      final expectedHeight = (beforeMap['height'] as num).round();
      if (pixelEvidence['width'] != expectedWidth ||
          pixelEvidence['height'] != expectedHeight) {
        throw StateError(
          'Paper PNG dimensions differ from its DOM box: '
          '$expectedWidth×$expectedHeight -> '
          '${pixelEvidence['width']}×${pixelEvidence['height']}',
        );
      }
      if ((pixelEvidence['maxAppGrayBandRows'] as num).toInt() != 0) {
        throw StateError(
          'Paper PNG still contains a full-width clipped app-gray band: '
          '$pixelEvidence',
        );
      }
      const paperCorner = [255, 255, 255, 255];
      if (!_sameNumbers(pixelEvidence['topLeft'], paperCorner) ||
          !_sameNumbers(pixelEvidence['bottomLeft'], paperCorner)) {
        throw StateError(
          'Paper PNG corners are not the white paper background: '
          '$pixelEvidence',
        );
      }
      if ((beforeMap['headers'] as num).toInt() > 0 &&
          (pixelEvidence['headerInkPixels'] as num).toInt() == 0) {
        throw StateError('Paper PNG lost its rendered header: $pixelEvidence');
      }
      if ((beforeMap['footers'] as num).toInt() > 0 &&
          (pixelEvidence['footerInkPixels'] as num).toInt() == 0) {
        throw StateError('Paper PNG lost its rendered footer: $pixelEvidence');
      }
    } finally {
      if (clone != null) {
        try {
          await clone.evaluate<void>('element => element.remove()');
        } finally {
          await clone.dispose();
        }
      } else {
        if (cloneHandle != null) await cloneHandle.dispose();
      }
      await page.evaluate<void>(
        "() => document.querySelector('[data-dq-office-e2e-paper-clone]')?.remove()",
      );
    }

    // Growing/restoring the viewport for a full-element screenshot can make
    // virtualization replace the paper node. Reacquire the same logical page
    // instead of treating a detached (0×0) handle as changed geometry.
    final current = await _mountLogicalPage(
      int.parse(pageIndex),
      timeout: const Duration(seconds: 30),
    );
    final after = await _paperInvariant(current);
    await current.dispose();
    if (after != before) {
      throw StateError(
        'Paper geometry/content changed while taking screenshot: '
        '$before -> $after',
      );
    }
    return (
      bytes: bytes,
      evidence: {
        'pageIndex': int.parse(pageIndex),
        'sourceInvariant': beforeMap,
        'cloneInvariant': cloneInvariantMap,
        'regions': (jsonDecode(regionsRaw) as Map).cast<String, dynamic>(),
        'screenshot': pixelEvidence,
      },
    );
  }

  Future<String> _paperInvariant(ElementHandle element) async =>
      (await element.evaluate<String>('''element => {
        const rect = element.getBoundingClientRect();
        const text = element.textContent || '';
        let hash = 2166136261;
        for (let index = 0; index < text.length; index++) {
          hash ^= text.charCodeAt(index);
          hash = Math.imul(hash, 16777619);
        }
        return JSON.stringify({
          width: Math.round(rect.width * 1000) / 1000,
          height: Math.round(rect.height * 1000) / 1000,
          textLength: text.length,
          textHash: hash >>> 0,
          headers: element.querySelectorAll('.dq-office-header').length,
          footers: element.querySelectorAll('.dq-office-footer').length,
        });
      }'''))!;

  static bool _sameNumbers(dynamic actual, List<int> expected) {
    if (actual is! List || actual.length != expected.length) return false;
    for (var index = 0; index < expected.length; index++) {
      if (actual[index] is! num ||
          (actual[index] as num).toInt() != expected[index]) {
        return false;
      }
    }
    return true;
  }

  /// Exact rendered-token lookup used only as browser-reopen evidence. The
  /// durable assertions inspect the imported PM ancestry, not global text.
  Future<bool> renderedTokenExists(String token) => page.evaluate<bool>(
        '''() => [...document.querySelectorAll('.dq-office-run')].some(run =>
          [...run.childNodes].some(node => node.nodeType === Node.TEXT_NODE &&
            node.data.includes(${jsonEncode(token)})))''',
      );

  /// Places the caret in the first body run, then types through Puppeteer's
  /// keyboard. Selection setup is deterministic; the mutation itself is made
  /// exclusively by trusted browser input events.
  Future<void> typeMarker(
    String marker, {
    required String artifactName,
    bool requirePlain = false,
  }) async {
    await page.evaluate<void>('''() => {
      const canvas = document.querySelector('.dq-office-canvas');
      if (canvas) canvas.scrollTop = 0;
      const run = [...document.querySelectorAll(
          '.dq-office-page-content .dq-office-run')].find((element) => {
        if (element.closest('.dq-office-table')) return false;
        const style = getComputedStyle(element);
        const weight = Number.parseInt(style.fontWeight, 10) || 400;
        if (${requirePlain ? 'true' : 'false'} &&
            (weight >= 600 || style.fontStyle === 'italic')) return false;
        return [...element.childNodes].some(
          node => node.nodeType === Node.TEXT_NODE);
      });
      if (!run) throw new Error('No editable text run was rendered');
      const node = [...run.childNodes].find(
        child => child.nodeType === Node.TEXT_NODE);
      const range = document.createRange();
      range.setStart(node, node.data.length);
      range.collapse(true);
      const selection = document.getSelection();
      selection.removeAllRanges();
      selection.addRange(range);
      run.closest('.dq-office-page-content').focus();
    }''');
    await page.keyboard.type(marker, delay: const Duration(milliseconds: 5));
    await _waitForRenderedToken(marker);
    await Future<void>.delayed(const Duration(milliseconds: 150));
    await screenshot('$artifactName-edited');
  }

  /// Types one body token, proves grouped undo/redo through trusted keyboard
  /// shortcuts, then applies bold + italic through real ribbon clicks.
  Future<void> typeBodyTokenWithUndoRedoFormatting(
    String token, {
    required String artifactName,
  }) async {
    await _showHomeTab();
    await typeMarker(
      ' $token',
      artifactName: '$artifactName-body-typed',
      requirePlain: true,
    );

    await _shortcut(Key.keyZ);
    await _waitForRenderedToken(token, present: false);
    await _shortcut(Key.keyY);
    await _waitForRenderedToken(token);

    await _selectRenderedToken(token);
    await _clickHomeControl('Negrito (Ctrl+B)');
    await _clickHomeControl('Itálico (Ctrl+I)');
    await Future<void>.delayed(const Duration(milliseconds: 150));
    await screenshot('$artifactName-body-formatted');
  }

  /// Types into a different ordinary body block and turns that exact block
  /// into an ordered list through the ribbon.
  Future<void> createOrderedListToken(
    String token, {
    required String artifactName,
    required String excludeToken,
  }) async {
    await _showHomeTab();
    final placed = await page.evaluate<bool>('''() => {
      const canvas = document.querySelector('.dq-office-canvas');
      if (canvas) canvas.scrollTop = 0;
      const blocks = [...document.querySelectorAll(
        '.dq-office-page-content .dq-office-block')];
      const block = blocks.find(candidate => {
        if (candidate.closest('.dq-office-table') ||
            candidate.textContent.includes(${jsonEncode(excludeToken)})) {
          return false;
        }
        if ([...candidate.children].some(child =>
            child.classList.contains('dq-office-marker'))) return false;
        const rect = candidate.getBoundingClientRect();
        return rect.width > 0 && rect.height > 0 &&
          [...candidate.querySelectorAll('.dq-office-run')].some(run =>
            [...run.childNodes].some(
              node => node.nodeType === Node.TEXT_NODE));
      });
      if (!block) return false;
      const run = [...block.querySelectorAll('.dq-office-run')].find(run =>
        [...run.childNodes].some(
          node => node.nodeType === Node.TEXT_NODE));
      const node = [...run.childNodes].find(
        child => child.nodeType === Node.TEXT_NODE);
      const range = document.createRange();
      range.setStart(node, node.data.length);
      range.collapse(true);
      const selection = document.getSelection();
      selection.removeAllRanges();
      selection.addRange(range);
      run.closest('.dq-office-page-content').focus();
      return true;
    }''');
    if (!placed) throw StateError('No separate body block for list scenario');
    await page.keyboard.type(' $token', delay: const Duration(milliseconds: 5));
    await _waitForRenderedToken(token);
    await _clickHomeControl('Lista numerada');
    await page.waitForFunction(
      '''() => [...document.querySelectorAll('.dq-office-run')].some(run => {
        if (![...run.childNodes].some(node =>
            node.nodeType === Node.TEXT_NODE &&
            node.data.includes(${jsonEncode(token)}))) return false;
        const block = run.closest('.dq-office-block');
        return !!block && [...block.children].some(child =>
          child.classList.contains('dq-office-marker'));
      })''',
      timeout: const Duration(seconds: 30),
    );
    await screenshot('$artifactName-list-created');
  }

  /// Scrolls until an editable table cell is mounted, clicks its text with a
  /// trusted Puppeteer mouse event, and types through the real keyboard. This
  /// catches position-map bugs that a body-paragraph-only smoke test misses.
  Future<Map<String, dynamic>> typeMarkerInTable(
    String marker, {
    required String artifactName,
    bool bold = false,
    int? startPageNumber,
    Duration renderTimeout = const Duration(seconds: 30),
  }) async {
    if (startPageNumber != null) {
      final pageIndex = startPageNumber - 1;
      final mounted = await _mountLogicalPage(
        pageIndex,
        timeout: renderTimeout,
      );
      await mounted.dispose();
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    const selector = '.dq-office-table-row:not([data-repeated-header]) '
        '.dq-office-table-cell:not([data-vmerge="continue"]) '
        '.dq-office-run';
    const targetSelector = '$selector[data-dq-e2e-table-target="true"]';
    Map<String, dynamic>? identity;
    for (var attempt = 0; attempt < 48 && identity == null; attempt++) {
      final rawIdentity = await page.evaluate<String>('''() => {
        document.querySelectorAll('[data-dq-e2e-table-target]')
          .forEach((element) => element.removeAttribute(
            'data-dq-e2e-table-target'));
        const canvas = document.querySelector('.dq-office-canvas');
        if (!canvas) return '';
        const viewport = canvas.getBoundingClientRect();
        const visibleTop = Math.max(0, viewport.top) + 2;
        const visibleBottom = Math.min(
          window.innerHeight, viewport.bottom) - 2;
        const candidates = [...document.querySelectorAll(
          ${jsonEncode(selector)})];
        const target = candidates.find((element) => {
          const rect = element.getBoundingClientRect();
          const style = getComputedStyle(element);
          const weight = Number.parseInt(style.fontWeight, 10) || 400;
          return rect.width > 0 && rect.height > 0 &&
              rect.top >= visibleTop && rect.bottom <= visibleBottom &&
              [...element.childNodes].some(node =>
                node.nodeType === Node.TEXT_NODE && node.data.length > 0) &&
              (!${bold ? 'true' : 'false'} || weight < 600);
        });
        if (!target) return '';
        target.setAttribute('data-dq-e2e-table-target', 'true');
        const table = target.closest('.dq-office-table');
        const row = target.closest('.dq-office-table-row');
        const cell = target.closest('.dq-office-table-cell');
        return JSON.stringify({
          tableId: table?.getAttribute('data-node-id') || '',
          rowId: row?.getAttribute('data-node-id') || '',
          cellId: cell?.getAttribute('data-node-id') || '',
          blockId: target.closest('.dq-office-block')
            ?.getAttribute('data-node-id') || '',
          sourceRowIndex: Number(row?.getAttribute(
            'data-source-row-index') ?? -1),
          sourceCellIndex: Number(cell?.getAttribute(
            'data-source-cell-index') ?? -1),
          pageIndex: Number(target.closest('.dq-office-page')
            ?.getAttribute('data-page') ?? -1),
        });
      }''');
      if (rawIdentity.isNotEmpty) {
        identity = (jsonDecode(rawIdentity) as Map).cast<String, dynamic>();
        break;
      }
      await page.evaluate<void>('''() => {
        const canvas = document.querySelector('.dq-office-canvas');
        if (canvas) canvas.scrollTop += canvas.clientHeight * 2.5;
      }''');
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    final stableIdentity = identity;
    if (stableIdentity == null) {
      throw StateError('No editable table cell was mounted after scrolling');
    }
    if (const ['tableId', 'rowId', 'cellId', 'blockId']
        .any((key) => (stableIdentity[key] as String).isEmpty)) {
      throw StateError(
          'Editable table target has no stable PM identity: $stableIdentity');
    }
    if (const ['sourceRowIndex', 'sourceCellIndex']
        .any((key) => (stableIdentity[key] as num).toInt() < 0)) {
      throw StateError('Editable table target has no stable source index');
    }

    await page.evaluate<void>('''() => {
      if (window.__dqTableBeforeInputCapture) {
        document.removeEventListener('beforeinput',
          window.__dqTableBeforeInputCapture, true);
      }
      if (window.__dqTableBeforeInputBubble) {
        document.removeEventListener('beforeinput',
          window.__dqTableBeforeInputBubble, false);
      }
      window.__dqTableInputEvents = [];
      const logicalLength = node => {
        if (node.nodeType === Node.ELEMENT_NODE) {
          const declared = Number(node.getAttribute('data-model-length'));
          if (Number.isFinite(declared) && declared >= 0) return declared;
        }
        return (node.textContent || '').length;
      };
      const modelPosition = (node, offset) => {
        const element = node?.nodeType === Node.ELEMENT_NODE
          ? node : node?.parentElement;
        const line = element?.closest('.dq-office-line');
        const block = element?.closest('.dq-office-block');
        if (!line || !block) return null;
        const docPos = Number(block.getAttribute('data-doc-pos'));
        const charStart = Number(line.getAttribute('data-char-start'));
        if (!Number.isFinite(docPos) || !Number.isFinite(charStart)) {
          return null;
        }
        let within = 0;
        for (const run of line.childNodes) {
          if (run === node || run.contains?.(node)) {
            if (node?.nodeType === Node.TEXT_NODE) within += offset;
            else within += Math.min(offset, logicalLength(run));
            return docPos + charStart + within;
          }
          within += logicalLength(run);
        }
        return docPos + charStart + within;
      };
      const nodeSnapshot = (node, offset) => {
        const element = node?.nodeType === Node.ELEMENT_NODE
          ? node : node?.parentElement;
        const line = element?.closest('.dq-office-line');
        const block = element?.closest('.dq-office-block');
        const table = element?.closest('.dq-office-table');
        const row = element?.closest('.dq-office-table-row');
        const cell = element?.closest('.dq-office-table-cell');
        const page = element?.closest('.dq-office-page');
        return {
          nodeName: node?.nodeName || null,
          offset,
          textLength: node?.nodeType === Node.TEXT_NODE
            ? node.data.length : null,
          modelPosition: modelPosition(node, offset),
          page: page?.getAttribute('data-page') || null,
          tableId: table?.getAttribute('data-node-id') || null,
          rowId: row?.getAttribute('data-node-id') || null,
          cellId: cell?.getAttribute('data-node-id') || null,
          blockId: block?.getAttribute('data-node-id') || null,
          blockDocPos: block?.getAttribute('data-doc-pos') || null,
          lineCharStart: line?.getAttribute('data-char-start') || null,
          lineCharEnd: line?.getAttribute('data-char-end') || null,
        };
      };
      const selectionSnapshot = () => {
        const selection = document.getSelection();
        return {
          anchor: nodeSnapshot(selection?.anchorNode,
            selection?.anchorOffset ?? -1),
          focus: nodeSnapshot(selection?.focusNode,
            selection?.focusOffset ?? -1),
          collapsed: selection?.isCollapsed ?? null,
        };
      };
      const surfaceSnapshot = () => ({
        dirty: document.querySelector('.dq-office-app')
          ?.getAttribute('data-dq-office-dirty'),
        status: document.querySelector('.dq-office-status-item')
          ?.textContent || '',
        mountedPages: [...document.querySelectorAll('.dq-office-page')]
          .map(page => Number(page.getAttribute('data-page'))),
        selection: selectionSnapshot(),
      });
      window.__dqTableSelectionSnapshot = selectionSnapshot;
      window.__dqTableSurfaceSnapshot = surfaceSnapshot;
      const eventSnapshot = (event, phase) => ({
        phase,
        inputType: event.inputType,
        data: event.data,
        defaultPrevented: event.defaultPrevented,
        cancelable: event.cancelable,
        targetClass: event.target?.className || '',
        selection: selectionSnapshot(),
        targetRanges: [...event.getTargetRanges()].map(range => ({
          start: nodeSnapshot(range.startContainer, range.startOffset),
          end: nodeSnapshot(range.endContainer, range.endOffset),
        })),
      });
      window.__dqTableBeforeInputCapture = event => {
        window.__dqTableInputEvents.push(eventSnapshot(event, 'capture'));
        setTimeout(() => window.__dqTableInputEvents.push({
          phase: 'after-dispatch',
          inputType: event.inputType,
          data: event.data,
          surface: surfaceSnapshot(),
        }), 0);
      };
      window.__dqTableBeforeInputBubble = event => {
        window.__dqTableInputEvents.push(eventSnapshot(event, 'bubble'));
      };
      document.addEventListener('beforeinput',
        window.__dqTableBeforeInputCapture, true);
      document.addEventListener('beforeinput',
        window.__dqTableBeforeInputBubble, false);
    }''');

    final target = await page.$OrNull(targetSelector);
    final box = await target?.boundingBox;
    if (target == null || box == null || box.width <= 0 || box.height <= 0) {
      await target?.dispose();
      throw StateError('Editable table target detached before trusted click: '
          '$stableIdentity');
    }
    // A direct mouse event cannot invoke Puppeteer's implicit
    // scrollIntoView, so the virtualizer cannot replace the atomically
    // identified node between targeting and the trusted click.
    await page.mouse.click(Point(
      box.left + box.width / 2,
      box.top + box.height / 2,
    ));
    await target.dispose();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final clickedIdentityRaw = await page.evaluate<String>('''() => {
      const selection = document.getSelection();
      const anchor = selection?.anchorNode;
      const element = anchor?.nodeType === Node.ELEMENT_NODE
        ? anchor : anchor?.parentElement;
      const table = element?.closest('.dq-office-table');
      const row = element?.closest('.dq-office-table-row');
      const cell = element?.closest('.dq-office-table-cell');
      const block = element?.closest('.dq-office-block');
      return JSON.stringify({
        tableId: table?.getAttribute('data-node-id') || '',
        rowId: row?.getAttribute('data-node-id') || '',
        cellId: cell?.getAttribute('data-node-id') || '',
        blockId: block?.getAttribute('data-node-id') || '',
      });
    }''');
    final clickedIdentity =
        (jsonDecode(clickedIdentityRaw) as Map).cast<String, dynamic>();
    for (final key in const ['tableId', 'rowId', 'cellId', 'blockId']) {
      if (clickedIdentity[key] != stableIdentity[key]) {
        throw StateError('Trusted click landed outside selected table target: '
            '$stableIdentity -> $clickedIdentity');
      }
    }
    await page.keyboard.press(Key.end);
    await _startPerformanceProbe();
    try {
      await page.keyboard.type(marker, delay: const Duration(milliseconds: 5));
      await _waitForRenderedTableToken(
        marker,
        cellId: stableIdentity['cellId'] as String,
        blockId: stableIdentity['blockId'] as String,
        timeout: renderTimeout,
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
    } catch (error, stackTrace) {
      final rawDiagnostic = await page.evaluate<String>('''() => {
        const expectedCell = ${jsonEncode(stableIdentity['cellId'])};
        const cell = [...document.querySelectorAll(
          '.dq-office-table-cell')].find(element =>
            element.getAttribute('data-node-id') === expectedCell);
        return JSON.stringify({
          expected: ${jsonEncode(stableIdentity)},
          marker: ${jsonEncode(marker)},
          surface: window.__dqTableSurfaceSnapshot?.() || null,
          selectedCellText: cell?.textContent || null,
          selectedCellConnected: cell?.isConnected ?? false,
          activeElement: {
            tag: document.activeElement?.tagName || null,
            className: document.activeElement?.className || null,
            contenteditable: document.activeElement
              ?.getAttribute('contenteditable') || null,
          },
          markerRuns: [...document.querySelectorAll('.dq-office-run')]
            .map(run => run.textContent || '')
            .filter(text => text.includes('E2E_')),
          inputEvents: window.__dqTableInputEvents || [],
        });
      }''');
      final diagnostic =
          (jsonDecode(rawDiagnostic) as Map).cast<String, dynamic>();
      await writeJson('$artifactName-table-typing-failed', {
        ...diagnostic,
        'error': '$error',
        'stackTrace': '$stackTrace',
      });
      throw StateError(
          'Trusted table typing did not render: ${jsonEncode(diagnostic)}');
    } finally {
      _lastEditPerformance = await _finishPerformanceProbe();
    }
    if (bold) {
      await _showHomeTab();
      await _selectRenderedToken(marker.trim());
      await _clickHomeControl('Negrito (Ctrl+B)');
    }
    await Future<void>.delayed(const Duration(milliseconds: 150));
    await screenshot('$artifactName-table-edited');
    return stableIdentity;
  }

  Future<void> _showHomeTab() async {
    await page.click('.dq-office-ribbon-tab:nth-child(2)');
    await page.waitForSelector('button[title="Negrito (Ctrl+B)"]');
  }

  Future<void> _clickHomeControl(String title) async {
    final selector = 'button[title=${jsonEncode(title)}]';
    await page.waitForSelector(selector);
    await page.click(selector);
  }

  Future<void> _selectRenderedToken(String token) async {
    final selected = await page.evaluate<bool>('''() => {
      for (const run of document.querySelectorAll('.dq-office-run')) {
        for (const node of run.childNodes) {
          if (node.nodeType !== Node.TEXT_NODE) continue;
          const start = node.data.indexOf(${jsonEncode(token)});
          if (start < 0) continue;
          const range = document.createRange();
          range.setStart(node, start);
          range.setEnd(node, start + ${token.length});
          const selection = document.getSelection();
          selection.removeAllRanges();
          selection.addRange(range);
          run.closest('.dq-office-page-content')?.focus();
          return true;
        }
      }
      return false;
    }''');
    if (!selected) throw StateError('Rendered token not selectable: $token');
  }

  Future<void> _shortcut(Key key) async {
    await page.keyboard.down(Key.control);
    try {
      await page.keyboard.press(key);
    } finally {
      await page.keyboard.up(Key.control);
    }
  }

  Future<void> _waitForRenderedToken(
    String token, {
    bool present = true,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    await page.waitForFunction(
      '''() => [...document.querySelectorAll('.dq-office-run')].some(run =>
          [...run.childNodes].some(node => node.nodeType === Node.TEXT_NODE &&
            node.data.includes(${jsonEncode(token)}))) === $present''',
      timeout: timeout,
    );
  }

  /// Waits for the exact logical text in the same stable PM table block.
  ///
  /// A Word line wrap may leave a leading space in one `.dq-office-run` and
  /// place the following word in the next run. Requiring the whole token in
  /// one text node therefore reports a false negative even though both the
  /// model and the projected block contain the exact string. Scoping the
  /// concatenation to the clicked cell + block preserves structural rigor
  /// while accepting that normal visual fragmentation.
  Future<void> _waitForRenderedTableToken(
    String token, {
    required String cellId,
    required String blockId,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    await page.waitForFunction(
      '''() => [...document.querySelectorAll('.dq-office-block')].some(block => {
        if (block.getAttribute('data-node-id') !== ${jsonEncode(blockId)}) {
          return false;
        }
        const cell = block.closest('.dq-office-table-cell');
        return cell?.getAttribute('data-node-id') === ${jsonEncode(cellId)} &&
          (block.textContent || '').includes(${jsonEncode(token)});
      })''',
      timeout: timeout,
    );
  }

  /// Uses the real Arquivo -> Exportar DOCX button and captures the Blob that
  /// the application hands to its download anchor. Chromium's headless
  /// download manager varies by version; the Blob is the exact browser-side
  /// payload and keeps this assertion deterministic without bypassing the UI.
  Future<File> exportDocx({
    required String artifactName,
    bool viaShortcut = false,
  }) async {
    final capture = await _captureBrowserExport(
      artifactName: artifactName,
      kind: 'docx',
      expectedMimeType:
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      fallbackFilename: 'document.docx',
      buttonSelector: 'button[title="Exportar DOCX"]',
      viaShortcut: viaShortcut,
      timeout: const Duration(seconds: 60),
    );
    final bytes = capture.bytes;
    if (bytes.length < 4 || bytes[0] != 0x50 || bytes[1] != 0x4b) {
      throw StateError('Export is not a DOCX ZIP: ${capture.file.path}');
    }
    await writeJson('$artifactName-export', {
      'browserFilename': capture.browserFilename,
      'mimeType': capture.mimeType,
      'bytes': bytes.length,
      'file': capture.file.absolute.path,
      ...capture.performance,
    });
    stdout.writeln(
      'OFFICE_E2E export $artifactName: '
      '${capture.file.absolute.path} (${bytes.length} bytes)',
    );
    return capture.file;
  }

  /// Uses the real Arquivo -> Exportar PDF ribbon action and validates the
  /// exact Blob produced by the editor, including its page tree and xref.
  Future<OfficePdfExportEvidence> exportPdf({
    required String artifactName,
    Duration timeout = const Duration(minutes: 5),
  }) async {
    final capture = await _captureBrowserExport(
      artifactName: '$artifactName-pdf',
      kind: 'pdf',
      expectedMimeType: 'application/pdf',
      fallbackFilename: 'document.pdf',
      buttonSelector: 'button[title^="Exportar PDF"]',
      timeout: timeout,
    );
    final bytes = capture.bytes;
    if (bytes.length < 8) {
      throw StateError('Exported PDF is truncated: ${capture.file.path}');
    }

    final pdf = PdfReader(bytes);
    if (!pdf.header.startsWith('%PDF-')) {
      throw StateError(
        'Export does not have a PDF signature: ${capture.file.path}',
      );
    }
    if (!pdf.endsWithEof) {
      throw StateError('Exported PDF has no final %%EOF marker');
    }
    if (!pdf.hasTrailerRoot) {
      throw StateError('Exported PDF trailer has no /Root reference');
    }
    final xrefOffsets = pdf.xrefOffsets;
    if (xrefOffsets.isEmpty ||
        xrefOffsets.any((offset) => pdf.objectHeaderAt(offset) == null)) {
      throw StateError('Exported PDF has an invalid cross-reference table');
    }
    final pageCount = pdf.pageCount;
    if (pageCount < 1) {
      throw StateError('Exported PDF has no pages');
    }

    final performance = <String, dynamic>{
      ...capture.performance,
      'pageCount': pageCount,
    };
    _lastExportPerformance = performance;
    final evidence = OfficePdfExportEvidence(
      file: capture.file,
      browserFilename: capture.browserFilename,
      mimeType: capture.mimeType,
      byteLength: bytes.length,
      pageCount: pageCount,
      performance: Map<String, dynamic>.unmodifiable(performance),
    );
    await writeJson('$artifactName-pdf-export', evidence.toJson());
    stdout.writeln(
      'OFFICE_E2E PDF export $artifactName: '
      '${capture.file.absolute.path} '
      '($pageCount pages, ${bytes.length} bytes)',
    );
    return evidence;
  }

  Future<_BrowserExportCapture> _captureBrowserExport({
    required String artifactName,
    required String kind,
    required String expectedMimeType,
    required String fallbackFilename,
    required String buttonSelector,
    required Duration timeout,
    bool viaShortcut = false,
  }) async {
    final downloadDirectory = Directory(
      '${artifactDirectory.path}/downloads/'
      '$artifactName-${DateTime.now().microsecondsSinceEpoch}',
    )..createSync(recursive: true);
    await page.evaluate<void>('''() => {
      window.__dqOfficeExportBlob = null;
      window.__dqOfficeExportName = null;
      window.__dqOfficeExpectedExportMime = ${jsonEncode(expectedMimeType)};
      if (window.__dqOfficeDownloadHookInstalled) return;
      window.__dqOfficeDownloadHookInstalled = true;

      const createObjectURL = URL.createObjectURL.bind(URL);
      URL.createObjectURL = (blob) => {
        const actual = (blob?.type || '').toLowerCase().split(';', 1)[0];
        window.__dqOfficeLastCreatedBlobType = actual;
        window.__dqOfficeLastCreatedBlobSize = blob?.size ?? null;
        const expected = (window.__dqOfficeExpectedExportMime || '')
            .toLowerCase();
        if (actual === expected) {
          window.__dqOfficeExportBlob = blob;
        }
        return createObjectURL(blob);
      };
      const anchorClick = HTMLAnchorElement.prototype.click;
      HTMLAnchorElement.prototype.click = function() {
        if (this.download && window.__dqOfficeExportBlob) {
          window.__dqOfficeExportName = this.download;
          // The application has reached the real download boundary and the
          // exact Blob is captured above. Do not hand this E2E-only click to
          // Chromium's headless download manager: on Windows it can block
          // the renderer while antivirus scans the native download, which is
          // browser/host work rather than editor serialization. Unrelated
          // anchors still retain their native behavior.
          return;
        }
        return anchorClick.call(this);
      };
    }''');

    // Ribbon navigation is setup, not export work. A direct trusted pointer
    // click avoids Puppeteer 3.19's ElementHandle scroll-into-view path, whose
    // IntersectionObserver can be throttled for tens of seconds after a
    // full-element screenshot in headless Chromium.
    if (!viaShortcut) {
      await _trustedPointerClick('.dq-office-ribbon-tab:nth-child(1)');
    }
    await page.bringToFront();
    // Resolving an ElementHandle/bounding box forces Chromium layout. It is
    // setup for the user action, not export serialization, so complete it
    // before the responsiveness probe starts.
    final clickPoint = viaShortcut
        ? null
        : await _trustedPointerPoint(buttonSelector, bringToFront: false);
    await _startPerformanceProbe();
    final stopwatch = Stopwatch()..start();
    if (viaShortcut) {
      await _shortcut(Key.keyS);
    } else {
      await page.mouse.click(clickPoint!);
    }
    await page.waitForFunction(
      '''() => window.__dqOfficeExportBlob !== null &&
          window.__dqOfficeExportName !== null''',
      timeout: timeout,
    );
    stopwatch.stop();
    // Stop the user-facing performance probe as soon as the application has
    // produced the Blob. Reading and base64-encoding that Blob below is test
    // transport work and must not be charged to the editor's export path.
    final performance = await _finishPerformanceProbe();
    final payload = await page.evaluate<Map<String, dynamic>>('''async () => {
      const blob = window.__dqOfficeExportBlob;
      const bytes = new Uint8Array(await blob.arrayBuffer());
      const chunks = [];
      for (let offset = 0; offset < bytes.length; offset += 0x8000) {
        chunks.push(String.fromCharCode(
            ...bytes.subarray(offset, offset + 0x8000)));
      }
      return {
        name: window.__dqOfficeExportName || ${jsonEncode(fallbackFilename)},
        base64: btoa(chunks.join('')),
        mimeType: blob.type,
      };
    }''');
    final bytes = base64Decode(payload['base64'] as String);
    final browserFilename =
        (payload['name'] as String).replaceAll('\\', '/').split('/').last;
    final downloaded = File('${downloadDirectory.path}/$browserFilename')
      ..writeAsBytesSync(bytes);
    _lastExportPerformance = {
      'browserFilename': payload['name'],
      'kind': kind,
      'trigger': viaShortcut ? 'ctrl+s' : 'ribbon',
      'exportMs': stopwatch.elapsedMilliseconds,
      'maxFrameGapMs': performance['maxFrameGapMs'],
      'longTasks': performance['longTasks'],
      'maxLongTaskMs': performance['maxLongTaskMs'],
      'phaseTimings': performance['exportPhaseTimings'],
    };
    return (
      file: downloaded,
      bytes: bytes,
      browserFilename: payload['name'] as String,
      mimeType: payload['mimeType'] as String,
      performance: Map<String, dynamic>.unmodifiable(
        _lastExportPerformance,
      ),
    );
  }

  Future<void> _trustedPointerClick(
    String selector, {
    bool bringToFront = true,
  }) async {
    final point = await _trustedPointerPoint(
      selector,
      bringToFront: bringToFront,
    );
    await page.mouse.click(point);
  }

  Future<Point<double>> _trustedPointerPoint(
    String selector, {
    bool bringToFront = true,
  }) async {
    if (bringToFront) await page.bringToFront();
    final target = await page.waitForSelector(selector);
    if (target == null) {
      throw StateError('Trusted click target does not exist: $selector');
    }
    final box = await target.boundingBox;
    if (box == null || box.width <= 0 || box.height <= 0) {
      await target.dispose();
      throw StateError('Trusted click target is not visible: $selector');
    }
    final point = Point<double>(
      box.left + box.width / 2,
      box.top + box.height / 2,
    );
    await target.dispose();
    return point;
  }

  Future<String> screenshot(String name) async {
    final file = File('${artifactDirectory.path}/$name.png');
    file.writeAsBytesSync(await page.screenshot());
    return file.absolute.path;
  }

  Future<String> writeJson(String name, Map<String, dynamic> value) async {
    final file = File('${artifactDirectory.path}/$name.json');
    file.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(value),
    );
    return file.absolute.path;
  }
}
