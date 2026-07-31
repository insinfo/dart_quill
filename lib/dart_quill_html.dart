/// HTML export for dart_quill.
///
/// Converts a Quill [Delta] into **semantic HTML** — `<strong>`, `<h1>`,
/// `<ul><li>`, `<table>` — rather than the editor's own markup with `ql-*`
/// classes. That is the difference between a document you can display, store
/// and print anywhere and one that only makes sense inside the editor.
///
/// Pure Dart, VM and web, no dependency.
///
/// ```dart
/// import 'package:dart_quill/dart_quill_html.dart';
///
/// final html = deltaToHtml(delta);
///
/// // Or straight from the ops as they arrive from a database:
/// final html2 = opsToHtml(jsonDecode(row['delta'])['ops'] as List);
/// ```
///
/// Not to be confused with `Quill.getSemanticHTML()`, which serializes what the
/// editor currently has on screen: this works off a Delta alone, with no editor
/// and no DOM, which is what a backend needs.
library dart_quill_html;

export 'src/converters/html/delta_to_html.dart'
    show deltaToHtml, opsToHtml, HtmlConvertOptions;
export 'src/converters/html/html_to_delta.dart'
    show htmlToDelta, HtmlToDelta, HtmlOperations, CustomHtmlPart;
