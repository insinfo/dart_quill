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
    // The plugin does NOT remove quill's own `tr` matcher: core matchTable
    // keeps prepending `table: rowNumber` to every cell op, and that key is
    // what applyDelta consumes FIRST — the line becomes a core `table` block
    // (still a Block, so the cell text stays put) before `table-cell-block`
    // and `table-cell` restructure it. Removing it reordered the attribute
    // keys and broke the whole paste convergence.
    addMatcher('tr', matchTableBetterRow);
    addMatcher('td, th', matchTableBetterCell);
    addMatcher('col', matchTableBetterCol);
    addMatcher('table', matchTableTemporary);
  }

  /// Converts pasted content while retaining the active table-cell context.
  ///
  /// Content copied from a table carries structural attributes. External
  /// content (or ordinary lists/headers pasted into a cell) receives the
  /// current cell formats, matching `getTableDelta` in the reference plugin
  /// (clipboard.ts:39-59): the caret cell's formats are spread LAST, so they
  /// override whatever the copied ops carried — pasted lines are re-homed
  /// into the destination cell.
  Delta getTableDelta(
      {String? html, String? text, Map<String, dynamic>? formats}) {
    final activeFormats =
        formats ?? quill.getFormat(quill.selection.getRange()?.index ?? 0);
    final delta = convert(html: html, text: text, formats: activeFormats);
    if (_truthy(activeFormats['table-cell-block']) ||
        _truthy(activeFormats['table-th-block'])) {
      final result = Delta();
      for (final op in delta.operations) {
        final attributes = op.attributes ?? const <String, dynamic>{};
        // External copied tables or table contents copied within an editor.
        if (_truthy(attributes['table-temporary'])) {
          return Delta();
        }
        // Process externally pasted lists or headers or text. The TS
        // condition (`!cellBlock || !thBlock`) is true for every op — no op
        // carries both keys — so every op is stamped, matching upstream.
        final needsContext = _truthy(attributes['header']) ||
            _truthy(attributes['list']) ||
            !_truthy(attributes['table-cell-block']) ||
            !_truthy(attributes['table-th-block']);
        result.insert(
          op.data,
          needsContext
              ? <String, dynamic>{...attributes, ...activeFormats}
              : attributes,
        );
      }
      return result;
    }
    return delta;
  }

  @override
  void onPaste(Range range, {String? text, String? html}) {
    // Parity cell-selection.ts `onCapturePaste`: with cells selected, a copied
    // grid is pasted cell-by-cell into the selection instead of flowing into
    // the caret's line.
    if (html != null && html.isNotEmpty) {
      final module = quill.getModule('table-better');
      if (module != null && (module as dynamic).pasteGridIntoSelection(html)) {
        return;
      }
    }
    final formats = quill.getFormat(range.index);
    final pastedDelta = getTableDelta(html: html, text: text, formats: formats);
    final change = (Delta()
          ..retain(range.index)
          ..delete(range.length))
        .concat(pastedDelta);
    quill.updateContents(change, source: EmitterSource.USER);
    // Parity clipboard.ts:31-35 — `delta.length() - range.length`, where
    // `length()` sums op lengths (the deleted range contributes to it).
    quill.setSelection(
      Range(_contentLength(change) - range.length, 0),
      source: EmitterSource.SILENT,
    );
    quill.scrollSelectionIntoView();
  }
}

/// JS truthiness for attribute values (`op?.attributes?.header`).
bool _truthy(dynamic value) =>
    value != null && value != false && value != '' && value != 0;

/// TS `delta.length()` — sum of op lengths, not the operation count.
int _contentLength(Delta delta) =>
    delta.operations.fold<int>(0, (length, op) => length + (op.length ?? 0));
