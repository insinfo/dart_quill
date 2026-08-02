/// Só o parse do DOCX — a metade do trabalho que NÃO toca no DOM e por isso
/// é a única candidata a rodar num Worker ou compilada para WebAssembly.
///
/// Este mesmo arquivo é compilado para JavaScript (`dart compile js`) e para
/// WasmGC (`dart compile wasm`), para os dois alvos serem medidos sobre a
/// mesma entrada.
library;

import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:dart_quill/dart_quill_docx.dart' as docx;

void main() {
  String benchParse(JSArrayBuffer buffer) {
    final bytes = buffer.toDart.asUint8List();
    final watch = Stopwatch()..start();
    final delta = docx.docxToDelta(bytes);
    watch.stop();
    final ops = delta.toJson().length;
    return jsonEncode({'ops': ops, 'parseMs': watch.elapsedMilliseconds});
  }

  globalContext.setProperty('benchParse'.toJS, benchParse.toJS);
  globalContext.setProperty('benchReady'.toJS, true.toJS);
}
