import '../config/config.dart';
import '../formats/table.dart';
import '../../platform/dom.dart';
import '../utils/utils.dart' as utils;

/// Applies the values produced by the table-better properties form.
///
/// Validation is kept here so a future DOM dialog and non-DOM integrations use
/// exactly the same whitelist and error behaviour.
class TablePropertiesController {
  TablePropertiesController({this.onChange});

  final void Function()? onChange;

  Map<String, String> read(DomElement node) {
    final values = <String, String>{...utils.parseInlineStyle(node)};
    for (final name in const ['width', 'height', 'border', 'data-class']) {
      final value = node.getAttribute(name);
      if (value != null && value.isNotEmpty) values[name] = value;
    }
    return values;
  }

  Map<String, String> readTable(TableContainer table) => read(table.element);

  Map<String, String> readCell(TableCell cell) => read(cell.element);

  void applyTable(TableContainer table, Map<String, String> values) {
    _apply(table.element, values, tableProperties);
  }

  void applyCell(TableCell cell, Map<String, String> values) {
    _apply(cell.element, values, cellProperties);
  }

  void applyCells(Iterable<TableCell> cells, Map<String, String> values) {
    for (final cell in cells) {
      applyCell(cell, values);
    }
  }

  void _apply(
    DomElement element,
    Map<String, String> values,
    List<String> allowed,
  ) {
    final styles = <String, String>{};
    for (final entry in values.entries) {
      if (!allowed.contains(entry.key)) continue;
      final value = entry.value.trim();
      if (!_valid(entry.key, value)) {
        throw FormatException('Invalid table property ${entry.key}: $value');
      }
      styles[entry.key] = value;
    }
    if (styles.isEmpty) return;
    utils.setElementProperty(element, styles);
    onChange?.call();
  }

  bool _valid(String name, String value) {
    if (value.isEmpty) return true;
    if (name.endsWith('color')) return utils.isValidColor(value);
    if (name.endsWith('width') ||
        name == 'width' ||
        name == 'height' ||
        name == 'padding') {
      return utils.isValidDimensions(value);
    }
    if (name == 'border-style') {
      return const {
        'dashed',
        'dotted',
        'double',
        'groove',
        'inset',
        'none',
        'outset',
        'ridge',
        'solid'
      }.contains(value);
    }
    if (name == 'align' || name == 'text-align') {
      return const {'left', 'center', 'right', 'justify'}.contains(value);
    }
    if (name == 'vertical-align') {
      return const {'top', 'middle', 'bottom'}.contains(value);
    }
    return true;
  }
}
