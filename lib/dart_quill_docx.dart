/// DOCX import/export for dart_quill.
///
/// Pure-Dart (VM and web) conversion between Quill [Delta] documents and
/// Office Open XML (`.docx`) files, backed by the vendored OOXML stack in
/// `src/dependencies/canvas_editor`.
///
/// ```dart
/// import 'dart:io';
/// import 'package:dart_quill/dart_quill_docx.dart';
///
/// final delta = docxToDelta(File('input.docx').readAsBytesSync());
/// File('output.docx').writeAsBytesSync(deltaToDocx(delta));
/// ```
library dart_quill_docx;

export 'src/converters/docx/docx_codec.dart' show docxToDelta, deltaToDocx;
