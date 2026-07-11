import '../../core/quill.dart';
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
}
