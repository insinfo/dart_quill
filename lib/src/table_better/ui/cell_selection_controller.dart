import '../../platform/dom.dart';
import '../formats/table.dart';
import 'cell_selection.dart';

/// DOM interaction layer for [CellSelection].
///
/// A normal click establishes an anchor. Shift-click extends the anchor to the
/// clicked cell and prevents the browser from moving the text caret. Geometry,
/// drag hit-testing and keyboard navigation remain separate concerns.
class CellSelectionController {
  CellSelectionController({required this.root, required this.table})
      : selection = CellSelection(table) {
    _listener = _onClick;
    root.addEventListener('click', _listener);
  }

  final DomElement root;
  final TableContainer table;
  final CellSelection selection;
  late final DomEventListener _listener;
  TableCell? _anchor;

  void dispose() {
    root.removeEventListener('click', _listener);
    selection.clear();
    _anchor = null;
  }

  void clear() {
    selection.clear();
    _anchor = null;
  }

  void _onClick(DomEvent event) {
    final cell = _cellFromTarget(event.target);
    if (cell == null) return;
    final raw = event.rawEvent as dynamic;
    final shift = raw?.shiftKey == true;
    if (!shift || _anchor == null) {
      _anchor = cell;
      final coordinate = selection.coordinateOf(cell);
      if (coordinate != null) {
        selection.select(
          startRow: coordinate.row,
          startColumn: coordinate.column,
          endRow: coordinate.row,
          endColumn: coordinate.column,
        );
      }
      return;
    }
    final start = selection.coordinateOf(_anchor!);
    final end = selection.coordinateOf(cell);
    if (start == null || end == null) return;
    event.preventDefault();
    selection.select(
      startRow: start.row,
      startColumn: start.column,
      endRow: end.row,
      endColumn: end.column,
    );
  }

  TableCell? _cellFromTarget(DomNode? target) {
    DomNode? node = target;
    while (node != null && node != root) {
      if (node is DomElement) {
        final tag = node.tagName.toUpperCase();
        if (tag == 'TD' || tag == 'TH') {
          for (final cell in table.descendants<TableCell>()) {
            if (identical(cell.element, node)) return cell;
          }
          return null;
        }
      }
      node = node.parentNode;
    }
    return null;
  }
}
