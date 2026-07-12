import '../formats/table.dart';
import '../utils/utils.dart' as utils;

typedef TableResizeChange = void Function();

/// State and mutation layer for table-better column/row resize handles.
///
/// The browser-facing operate-line overlay can call these methods while a
/// pointer is dragged. Widths and heights are clamped and persisted on the
/// same `col`, `tr` and `table` nodes used by the TypeScript plugin.
class OperateLine {
  OperateLine(
    this.table, {
    this.minColumnWidth = 24,
    this.minRowHeight = 20,
    this.minTableWidth = 100,
    this.onChange,
  });

  final TableContainer table;
  final double minColumnWidth;
  final double minRowHeight;
  final double minTableWidth;
  final TableResizeChange? onChange;

  double resizeColumn(int index, double delta) {
    final colgroup = table.colgroup() ?? _createColgroup();
    final cols = colgroup.children.whereType<TableCol>().toList();
    if (index < 0 || index >= cols.length) return 0;
    final col = cols[index];
    final width = _numeric(col.element.getAttribute('width')) ?? 100;
    return setColumnWidth(index, width + delta);
  }

  double setColumnWidth(int index, double width) {
    final colgroup = table.colgroup() ?? _createColgroup();
    final cols = colgroup.children.whereType<TableCol>().toList();
    if (index < 0 || index >= cols.length) return 0;
    final value = _clamp(width, minColumnWidth);
    final text = _format(value);
    cols[index].element.setAttribute('width', text);
    utils.setElementProperty(cols[index].element, {'width': '${text}px'});
    onChange?.call();
    return value;
  }

  double resizeRow(int index, double delta) {
    final rows = table.descendants<TableRow>().toList();
    if (index < 0 || index >= rows.length) return 0;
    final row = rows[index];
    final current = _numeric(row.element.style?.height?.toString()) ??
        _numeric(row.element.getAttribute('data-height')) ??
        24;
    return setRowHeight(index, current + delta);
  }

  double setRowHeight(int index, double height) {
    final rows = table.descendants<TableRow>().toList();
    if (index < 0 || index >= rows.length) return 0;
    final value = _clamp(height, minRowHeight);
    final text = _format(value);
    rows[index].element.setAttribute('data-height', text);
    utils.setElementProperty(rows[index].element, {'height': '${text}px'});
    onChange?.call();
    return value;
  }

  double resizeTable(double delta) {
    final current = _numeric(table.element.getAttribute('data-width')) ??
        _numeric(table.element.style?.width?.toString()) ??
        0;
    return setTableWidth(current + delta);
  }

  double setTableWidth(double width) {
    final value = _clamp(width, minTableWidth);
    final text = _format(value);
    table.element.setAttribute('data-width', text);
    utils.setElementProperty(table.element, {'width': '${text}px'});
    onChange?.call();
    return value;
  }

  TableColgroup _createColgroup() {
    final colgroup =
        table.scroll.create(TableColgroup.kBlotName) as TableColgroup;
    final first = table.children.isEmpty ? null : table.children.first;
    table.insertBefore(colgroup, first);
    return colgroup;
  }

  double _clamp(double value, double minimum) =>
      value < minimum ? minimum : value;

  double? _numeric(String? value) {
    if (value == null) return null;
    final match = RegExp(r'-?\d+(?:\.\d+)?').firstMatch(value);
    return match == null ? null : double.tryParse(match.group(0)!);
  }

  String _format(double value) => value.roundToDouble() == value
      ? value.toInt().toString()
      : value.toStringAsFixed(2);
}
