/// Delta <-> DOCX codec.
///
/// Bridges the vendored pure-Dart OOXML stack (`dependencies/canvas_editor`)
/// with the dart_quill [Delta] model:
///
/// - [docxToDelta]: DOCX bytes -> `DocxReader` -> `DocxToElementConverter`
///   -> `QuillDeltaConverter.toDelta` -> [Delta].
/// - [deltaToDocx]: [Delta] -> `QuillDeltaConverter.fromDelta`
///   -> `EditorToDocx.apply` -> `DocxWriter` -> DOCX bytes.
///
/// Supported content (see doc comments in the vendored converters):
/// inline formatting (bold, italic, underline, strike, color, background,
/// font, size, sub/superscript), headers 1-6, alignment, ordered/bullet
/// lists, hyperlinks, images and tables in the `quill-table-better` format.
///
/// Known limitations of the pipeline:
/// - Lists are written to DOCX as plain paragraphs with a literal marker
///   ("1. ", "2. ", or bullet) instead of real WordprocessingML numbering,
///   and DOCX numbering is imported back as literal marker text. The Quill
///   `list` attribute therefore does not survive a DOCX round-trip.
/// - Alignment of the very first paragraph of a document is not recovered
///   on import (the editor model carries it on paragraph separators, and
///   the first paragraph has none).
/// - Only the main document body is converted; headers, footers and page
///   geometry exposed by the vendored converter are ignored here.
library;

import 'dart:typed_data';

import '../../dependencies/canvas_editor/ce_docx.dart'
    show DocxFile, DocxReader, DocxWriter;
import '../../dependencies/canvas_editor/editor/dataset/enum/element.dart'
    show ElementType;
import '../../dependencies/canvas_editor/editor/dataset/enum/list.dart'
    show ListType;
import '../../dependencies/canvas_editor/editor/dataset/enum/row.dart'
    show RowFlex;
import '../../dependencies/canvas_editor/editor/interface/element.dart'
    show IElement;
import '../../dependencies/canvas_editor/word/docx_to_element.dart'
    show DocxConversionResult, DocxToElementConverter;
import '../../dependencies/canvas_editor/word/element_to_docx.dart'
    show EditorToDocx;
import '../../dependencies/canvas_editor/word/quill_delta.dart'
    show QuillDeltaConverter;
import '../../dependencies/dart_quill_delta/dart_quill_delta.dart' show Delta;

/// Converts the bytes of a `.docx` file into a Quill [Delta].
///
/// Only the main document body is converted (headers/footers and page
/// geometry are ignored). Throws a [FormatException] if [bytes] is not a
/// valid DOCX (ZIP/OPC) package.
Delta docxToDelta(Uint8List bytes) {
  final DocxFile file = DocxReader.read(bytes);
  final DocxConversionResult converted = DocxToElementConverter.convert(file);
  final List<IElement> main = _normalizeSeparators(converted.main);
  final Map<String, dynamic> deltaJson = QuillDeltaConverter.toDelta(main);
  return Delta.fromJson(deltaJson['ops'] as List);
}

/// Converts a Quill [Delta] into the bytes of a minimal `.docx` file.
///
/// A fresh empty WordprocessingML package is created and the delta content
/// is written as its document body. List lines are materialized as
/// paragraphs with a literal marker ("1. "/"2. " for ordered, a bullet for
/// unordered) — see the library-level limitations note.
Uint8List deltaToDocx(Delta delta) {
  final List<IElement> elements = QuillDeltaConverter.fromDelta(
      <String, dynamic>{'ops': delta.toJson()});
  _materializeListMarkers(elements);
  final DocxFile file = DocxReader.createEmpty();
  final List<IElement> original = DocxToElementConverter.convert(file).main;
  EditorToDocx.apply(file, elements, original);
  return DocxWriter.write(file);
}

// ---------------------------------------------------------------------------
// Normalization helpers (adaptations live here, not in the vendored tree).
// ---------------------------------------------------------------------------

bool _isSeparator(IElement element) =>
    (element.type == null || element.type == ElementType.text) &&
    element.value == '\n';

bool _isSelfTerminatingBlock(IElement element) =>
    element.type == ElementType.title ||
    element.type == ElementType.list ||
    element.type == ElementType.table;

bool _hasAlign(RowFlex? rowFlex) =>
    rowFlex == RowFlex.center ||
    rowFlex == RowFlex.right ||
    rowFlex == RowFlex.alignment ||
    rowFlex == RowFlex.justify;

/// Adapts the editor's "separator-before" line model to Quill's
/// "terminator-after" model before `QuillDeltaConverter.toDelta`:
///
/// - a `'\n'` separator carries the rowFlex of the paragraph it *starts*;
///   in Quill the same newline terminates the *previous* line, so each
///   separator is re-tagged with the previous line's rowFlex;
/// - separators that directly follow a self-terminating block (title, list,
///   table) are dropped — `toDelta` already emits that block's terminator,
///   and keeping the separator would fabricate an empty line;
/// - when the document ends in an aligned plain line, a trailing separator
///   is appended so the final Quill terminator carries the alignment.
List<IElement> _normalizeSeparators(List<IElement> main) {
  final List<IElement> result = <IElement>[];
  IElement? previousOriginal;
  for (final IElement element in main) {
    if (_isSeparator(element)) {
      if (previousOriginal != null &&
          _isSelfTerminatingBlock(previousOriginal)) {
        // Artifact: the block already terminates its own line.
        previousOriginal = element;
        continue;
      }
      element.rowFlex =
          previousOriginal != null && !_isSeparator(previousOriginal)
              ? previousOriginal.rowFlex
              : null;
    }
    result.add(element);
    previousOriginal = element;
  }
  final IElement? last = result.isEmpty ? null : result.last;
  if (last != null &&
      !_isSeparator(last) &&
      !_isSelfTerminatingBlock(last) &&
      _hasAlign(last.rowFlex)) {
    result.add(IElement(value: '\n', rowFlex: last.rowFlex));
  }
  return result;
}

/// Materializes visible list markers ("1. ", "2. ", "• ") on list items so
/// the numbering is not lost when `EditorToDocx` exports list elements as
/// plain paragraphs (the vendored exporter does not emit `w:numPr`).
void _materializeListMarkers(List<IElement> elements) {
  // `QuillDeltaConverter.fromDelta` emits one list element per list line;
  // the ordinal keeps counting across consecutive ordered list elements
  // (only plain '\n' separators may sit between them) and resets otherwise.
  int ordinal = 0;
  for (final IElement element in elements) {
    if (_isSeparator(element)) continue;
    if (element.type != ElementType.list) {
      ordinal = 0;
      continue;
    }
    final bool ordered = element.listType == ListType.ordered;
    if (!ordered) ordinal = 0;
    final List<IElement> children = element.valueList ?? const <IElement>[];
    final List<IElement> rebuilt = <IElement>[];
    bool atItemStart = true;
    for (final IElement child in children) {
      if (child.type == null && child.value == '\n') {
        rebuilt.add(child);
        atItemStart = true;
        continue;
      }
      if (atItemStart) {
        rebuilt.add(IElement(
          value: ordered ? '${++ordinal}. ' : '• ',
          font: child.font,
          size: child.size,
          rowFlex: child.rowFlex,
        ));
        atItemStart = false;
      }
      rebuilt.add(child);
    }
    element.valueList = rebuilt;
  }
}
