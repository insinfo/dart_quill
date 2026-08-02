/// Worker: abre o DOCX e devolve OU o Delta em JSON OU o HTML já montado.
///
/// Nada aqui toca no DOM do navegador — um Worker não tem DOM. O que ele pode
/// fazer é justamente o trabalho de CPU (unzip, XML, modelo, conversão) e a
/// geração do HTML em Dart puro, entregando à main thread uma string que ela
/// injeta de uma vez.
///
/// Os bytes chegam como `ArrayBuffer` transferível: a posse muda de thread,
/// sem cópia.
library;

import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:dart_quill/dart_quill_docx.dart' as docx;
import 'package:dart_quill/dart_quill_html.dart' as html_conv;

@JS('self')
external JSObject get _self;

void main() {
  void onMessage(JSObject event) {
    final data = event.getProperty<JSObject>('data'.toJS);
    final mode = (data.getProperty<JSString?>('mode'.toJS))?.toDart ?? 'delta';
    final buffer = data.getProperty<JSArrayBuffer>('buffer'.toJS);
    final bytes = buffer.toDart.asUint8List();

    final parse = Stopwatch()..start();
    final delta = docx.docxToDelta(bytes);
    parse.stop();

    String payload;
    var toHtmlMs = 0;
    if (mode == 'html') {
      final toHtml = Stopwatch()..start();
      payload = html_conv.deltaToHtml(delta);
      toHtml.stop();
      toHtmlMs = toHtml.elapsedMilliseconds;
    } else {
      payload = jsonEncode(delta.toJson());
    }

    final result = JSObject()
      ..setProperty('mode'.toJS, mode.toJS)
      ..setProperty('payload'.toJS, payload.toJS)
      ..setProperty('parseMs'.toJS, parse.elapsedMilliseconds.toJS)
      ..setProperty('toHtmlMs'.toJS, toHtmlMs.toJS);
    _self.callMethod<JSAny?>('postMessage'.toJS, result);
  }

  _self.setProperty('onmessage'.toJS, onMessage.toJS);
  _self.callMethod<JSAny?>('postMessage'.toJS, 'ready'.toJS);
}
