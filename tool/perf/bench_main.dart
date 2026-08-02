/// Laboratório de desempenho: por que abrir um DOCX de 140 páginas trava, e
/// qual arquitetura resolve.
///
/// O trabalho tem duas metades bem diferentes:
///
/// * **parse** (`docxToDelta`) — CPU pura sobre bytes. Não toca no DOM, então
///   é a única metade que pode ir para um Worker ou ser compilada para
///   WebAssembly.
/// * **materialização** — transformar o Delta em árvore de blots + DOM. Nem
///   Worker nem WebAssembly têm DOM, então esta metade é main-thread por
///   definição. O que dá para escolher é COMO ela é feita:
///     - `setContents(delta)`: o caminho normal do Quill, op a op;
///     - `innerHTML` + `Scroll.build()`: o HTML pode ser gerado em Dart puro
///       (inclusive num worker, com `package:html`) e a main thread paga
///       apenas o parser nativo do navegador, que é código C++ otimizado.
///
/// Cada cenário devolve JSON com os tempos, para o harness comparar.
library;

import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:dart_quill/dart_quill.dart';
import 'package:dart_quill/dart_quill_docx.dart' as docx;
import 'package:dart_quill/dart_quill_html.dart' as html_conv;
import 'package:dart_quill/dart_quill_table_better.dart';
import 'package:dart_quill/src/platform/html_dom.dart';
import 'package:web/web.dart' as web;

web.Element _freshHost() {
  final old = web.document.getElementById('bench-host');
  old?.remove();
  final host = web.document.createElement('div');
  host.id = 'bench-host';
  web.document.body!.appendChild(host);
  return host;
}

Quill _mount(web.Element host) => Quill(
      HtmlDomElement(host),
      options: ThemeOptions(theme: 'snow', modules: {'table-better': {}}),
    );

void main() {
  initializeQuill();
  registerTableBetter();

  /// Cenário 1 — tudo na main thread, caminho atual: parse + setContents.
  String benchSetContents(JSArrayBuffer buffer) {
    final bytes = buffer.toDart.asUint8List();
    final parse = Stopwatch()..start();
    final delta = docx.docxToDelta(bytes);
    parse.stop();
    final ops = delta.toJson().length;

    final host = _freshHost();
    final mount = Stopwatch()..start();
    final quill = _mount(host);
    mount.stop();

    final hydrate = Stopwatch()..start();
    quill.setContents(delta);
    hydrate.stop();

    return jsonEncode({
      'ops': ops,
      'parseMs': parse.elapsedMilliseconds,
      'mountMs': mount.elapsedMilliseconds,
      'hydrateMs': hydrate.elapsedMilliseconds,
    });
  }

  /// Cenário 2 — parse + Delta→HTML (Dart puro) + `innerHTML` e construção do
  /// editor sobre o DOM já pronto. É o caminho que um worker poderia
  /// alimentar: ele devolveria a STRING de HTML.
  String benchInnerHtml(JSArrayBuffer buffer) {
    final bytes = buffer.toDart.asUint8List();
    final parse = Stopwatch()..start();
    final delta = docx.docxToDelta(bytes);
    parse.stop();
    final ops = delta.toJson().length;

    final toHtml = Stopwatch()..start();
    String html;
    try {
      html = html_conv.deltaToHtml(delta);
    } catch (error, stack) {
      return jsonEncode({
        'error': '$error',
        'where': stack.toString().split('\n').take(3).join(' | '),
      });
    }
    toHtml.stop();

    final host = _freshHost();
    final inject = Stopwatch()..start();
    HtmlDomElement(host).innerHTML = html;
    inject.stop();

    final build = Stopwatch()..start();
    _mount(host);
    build.stop();

    return jsonEncode({
      'ops': ops,
      'htmlChars': html.length,
      'parseMs': parse.elapsedMilliseconds,
      'toHtmlMs': toHtml.elapsedMilliseconds,
      'injectMs': inject.elapsedMilliseconds,
      'buildMs': build.elapsedMilliseconds,
    });
  }

  /// Cenário 3 — a main thread recebe do worker o HTML pronto (string) e só
  /// paga `innerHTML` + construção. Mede exatamente o que sobraria para ela.
  String benchFromHtml(JSString htmlJs) {
    final html = htmlJs.toDart;
    final host = _freshHost();
    final inject = Stopwatch()..start();
    HtmlDomElement(host).innerHTML = html;
    inject.stop();
    final build = Stopwatch()..start();
    _mount(host);
    build.stop();
    return jsonEncode({
      'htmlChars': html.length,
      'injectMs': inject.elapsedMilliseconds,
      'buildMs': build.elapsedMilliseconds,
    });
  }

  /// Cenário 4 — a main thread recebe do worker o Delta em JSON e faz
  /// `setContents`. Mede o que sobra quando só o PARSE vai para o worker.
  String benchFromDeltaJson(JSString json) {
    final ops = jsonDecode(json.toDart) as List;
    final delta = Delta.fromJson(ops);
    final host = _freshHost();
    final quill = _mount(host);
    final hydrate = Stopwatch()..start();
    quill.setContents(delta);
    hydrate.stop();
    return jsonEncode({
      'ops': ops.length,
      'hydrateMs': hydrate.elapsedMilliseconds,
    });
  }

  /// Envolve um cenário para que uma exceção vire dado, não um stack opaco
  /// do JS compilado.
  String Function(T) guarded<T>(String Function(T) body) => (T arg) {
        try {
          return body(arg);
        } catch (error, stack) {
          return jsonEncode({
            'error': '$error',
            'where': stack.toString().split('\n').take(4).join(' | '),
          });
        }
      };

  globalContext.setProperty(
      'benchSetContents'.toJS, guarded(benchSetContents).toJS);
  globalContext.setProperty(
      'benchInnerHtml'.toJS, guarded(benchInnerHtml).toJS);
  globalContext.setProperty(
      'benchFromHtml'.toJS, guarded(benchFromHtml).toJS);
  globalContext.setProperty(
      'benchFromDeltaJson'.toJS, guarded(benchFromDeltaJson).toJS);
  globalContext.setProperty('benchReady'.toJS, true.toJS);
}
