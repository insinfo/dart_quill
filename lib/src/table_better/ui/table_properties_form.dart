import '../../platform/dom.dart';
import '../config/config.dart';
import '../formats/table.dart';
import 'properties_form.dart';

/// Lightweight DOM dialog for the table-better table/cell properties form.
class TablePropertiesForm {
  TablePropertiesForm({
    required this.host,
    TablePropertiesController? controller,
  }) : controller = controller ?? TablePropertiesController();

  final DomElement host;
  final TablePropertiesController controller;
  DomElement? _dialog;
  TableContainer? _table;
  List<TableCell> _cells = const [];
  bool _cellMode = false;

  bool get isOpen => _dialog != null;

  /// Opens a table-level properties dialog.
  void openTable(TableContainer table) {
    _table = table;
    _cells = const [];
    _cellMode = false;
    _open(
        controller.readTable(table), tableProperties, 'Propriedades da tabela');
  }

  /// Opens a cell-level dialog and applies values to all selected cells.
  void openCells(Iterable<TableCell> cells) {
    _table = null;
    _cells = cells.toList(growable: false);
    _cellMode = true;
    if (_cells.isEmpty) return;
    _open(controller.readCell(_cells.first), cellProperties,
        'Propriedades das células');
  }

  void close() {
    _dialog?.remove();
    _dialog = null;
    _table = null;
    _cells = const [];
  }

  void _open(
      Map<String, String> values, List<String> properties, String title) {
    close();
    final document = host.ownerDocument;
    final dialog = document.createElement('div')
      ..setAttribute('role', 'dialog')
      ..setAttribute('aria-label', title)
      ..setAttribute('data-table-properties-form', 'true')
      ..style.cssText = _dialogStyle;
    final heading = document.createElement('div')
      ..setAttribute('data-table-properties-title', 'true')
      ..style.cssText = 'font-weight:600;margin-bottom:10px;';
    heading.text = title;
    dialog.append(heading);

    final body = document.createElement('div')
      ..setAttribute('data-table-properties-fields', 'true')
      ..style.cssText = 'display:grid;grid-template-columns:1fr;gap:6px;';
    for (final property in properties) {
      final label = document.createElement('label')
        ..style.cssText =
            'display:flex;align-items:center;gap:6px;font-size:12px;';
      label.text = _label(property);
      final input = document.createElement('input')
        ..setAttribute('type', 'text')
        ..setAttribute('data-table-property', property)
        ..setAttribute('aria-label', _label(property))
        ..style.cssText = 'flex:1;min-width:120px;padding:3px;';
      input.value = values[property] ?? '';
      label.append(input);
      body.append(label);
    }
    dialog.append(body);

    final actions = document.createElement('div')
      ..style.cssText =
          'display:flex;justify-content:flex-end;gap:6px;margin-top:12px;';
    final cancel = _button(document, 'Cancelar', 'table-properties-cancel');
    cancel.addEventListener('click', (_) => close());
    final apply = _button(document, 'Aplicar', 'table-properties-apply');
    apply.addEventListener('click', (_) => _apply(dialog));
    actions
      ..append(cancel)
      ..append(apply);
    dialog.append(actions);
    host.append(dialog);
    _dialog = dialog;
  }

  DomElement _button(DomDocument document, String text, String action) {
    final button = document.createElement('button')
      ..setAttribute('type', 'button')
      ..setAttribute('data-table-properties-action', action)
      ..setAttribute('title', text)
      ..style.cssText = _buttonStyle;
    button.innerHTML = '<i class="ti ti-check" aria-hidden="true"></i> $text';
    return button;
  }

  void _apply(DomElement dialog) {
    final values = <String, String>{};
    for (final input in dialog.querySelectorAll('input[data-table-property]')) {
      final property = input.getAttribute('data-table-property');
      if (property != null) values[property] = input.value;
    }
    if (_cellMode) {
      controller.applyCells(_cells, values);
    } else if (_table != null) {
      controller.applyTable(_table!, values);
    }
    close();
  }

  String _label(String property) => property
      .replaceAll('-', ' ')
      .split(' ')
      .map((word) =>
          word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');

  static const _dialogStyle =
      'position:absolute;z-index:1200;top:40px;right:10px;width:280px;'
      'padding:12px;background:#fff;border:1px solid #bbb;border-radius:4px;'
      'box-shadow:0 4px 18px rgba(0,0,0,.22);';
  static const _buttonStyle =
      'appearance:none;border:0;border-radius:3px;padding:5px 9px;'
      'background:#f1f3f5;cursor:pointer;';
}
