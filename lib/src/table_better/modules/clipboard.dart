import '../../core/quill.dart';
import '../../core/emitter.dart';
import '../../core/selection.dart';
import '../../dependencies/dart_quill_delta/dart_quill_delta.dart';
import '../../modules/clipboard.dart';
import '../utils/clipboard_matchers.dart';

/// Clipboard variant used by quill-table-better 1.2.3.
class TableClipboard extends Clipboard {
  TableClipboard(Quill quill, ClipboardOptions options)
      : super(quill, options) {
    matchers.removeWhere(
      (pair) => pair[0] == 'tr' && identical(pair[1], matchTable),
    );
    addMatcher('tr', matchTableBetterRow);
    addMatcher('td, th', matchTableBetterCell);
    addMatcher('col', matchTableBetterCol);
    addMatcher('table', matchTableTemporary);
  }

  /// Converts pasted content while retaining the active table-cell context.
  ///
  /// Content copied from a table carries structural attributes. External
  /// content (or ordinary lists/headers pasted into a cell) receives the
  /// current cell formats, matching `getTableDelta` in the reference plugin.
  Delta getTableDelta(
      {String? html, String? text, Map<String, dynamic>? formats}) {
    final activeFormats =
        formats ?? quill.getFormat(quill.selection.getRange()?.index ?? 0);
    final delta = convert(html: html, text: text, formats: activeFormats);
    if (activeFormats.containsKey('table-cell-block') ||
        activeFormats.containsKey('table-th-block')) {
      final result = Delta();
      for (final op in delta.operations) {
        final attributes = op.attributes ?? const <String, dynamic>{};
        if (attributes.containsKey('table-temporary')) {
          return Delta();
        }
        final isStructured = attributes.containsKey('table-cell-block') ||
            attributes.containsKey('table-th-block');
        final needsContext = attributes.containsKey('header') ||
            attributes.containsKey('list') ||
            !isStructured;
        result.insert(
          op.data,
          needsContext
              ? <String, dynamic>{...activeFormats, ...attributes}
              : attributes,
        );
      }
      return result;
    }
    return delta;
  }

  @override
  void onPaste(Range range, {String? text, String? html}) {
    final formats = quill.getFormat(range.index);
    final pastedDelta = getTableDelta(html: html, text: text, formats: formats);
    final change = (Delta()
          ..retain(range.index)
          ..delete(range.length))
        .concat(pastedDelta);
    quill.updateContents(change, source: EmitterSource.USER);
    quill.setSelection(
      Range(range.index + pastedDelta.length, 0),
      source: EmitterSource.SILENT,
    );
  }
}
