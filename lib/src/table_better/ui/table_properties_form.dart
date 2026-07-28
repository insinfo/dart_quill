/// Port of `quill-table-better/src/ui/table-properties-form.ts` (v1.2.3) — the
/// table/cell properties dialog.
///
/// Faithful in DOM shape and class names (`.ql-table-properties-form`,
/// `.properties-form-row`, `.label-field-view`, `.ql-table-color-container`,
/// `.color-list`, `.color-picker-select`, `.ql-table-check-container`,
/// `.properties-form-action-row`), in the inline validation (an invalid value
/// shows the message and disables Save instead of throwing), in
/// `getDiffProperties` (only changed values are written, dimensions gain their
/// unit), in `saveTableAction`'s align→margin translation and in
/// `saveCellAction`'s percent width plus `text-align` propagation into the
/// cell's blocks. Positioning follows `updatePropertiesForm`.
///
/// One capability is not ported: the colour *wheel*, which upstream delegates
/// to the `@jaames/iro` package. The 15-colour palette, the hex input and
/// "remove colour" are all here; a wheel would mean vendoring a dependency,
/// which this package deliberately avoids.
library;

import '../../platform/dom.dart';
import '../assets/icons.dart';
import '../config/config.dart';
import '../formats/table.dart';
import '../formats/list.dart';
import '../language/language.dart';
import '../utils/utils.dart' as utils;
import 'properties_form.dart';

/// TS `ACTION_LIST`.
const List<({String icon, String label})> kActionList = [
  (icon: 'check', label: 'save'),
  (icon: 'close', label: 'cancel'),
];

/// TS `COLOR_LIST` — the 15 palette swatches.
const List<({String value, String describe})> kColorList = [
  (value: '#000000', describe: 'black'),
  (value: '#4d4d4d', describe: 'dimGrey'),
  (value: '#808080', describe: 'grey'),
  (value: '#e6e6e6', describe: 'lightGrey'),
  (value: '#ffffff', describe: 'white'),
  (value: '#ff0000', describe: 'red'),
  (value: '#ffa500', describe: 'orange'),
  (value: '#ffff00', describe: 'yellow'),
  (value: '#99e64d', describe: 'lightGreen'),
  (value: '#008000', describe: 'green'),
  (value: '#7fffd4', describe: 'aquamarine'),
  (value: '#40e0d0', describe: 'turquoise'),
  (value: '#4d99e6', describe: 'lightBlue'),
  (value: '#0000ff', describe: 'blue'),
  (value: '#800080', describe: 'purple'),
];

/// Everything the form needs from its surroundings, so it stays independent of
/// `TableMenus` (which owns it).
class TablePropertiesFormHost {
  const TablePropertiesFormHost({
    required this.container,
    required this.language,
    required this.onClose,
    this.table,
    this.selectedCells = const [],
    this.containerBounds,
    this.targetBounds,
  });

  /// Where the form is appended (upstream: `quill.container`).
  final DomElement container;
  final Language language;

  /// Called after save/cancel so the menus can reappear.
  final void Function() onClose;

  /// The table being edited (`type == 'table'`).
  final TableContainer? table;

  /// The cells being edited (`type == 'cell'`).
  final List<TableCell> selectedCells;

  /// Bounds used by `updatePropertiesForm`; resolved lazily so tests can feed
  /// synthetic geometry.
  final utils.CorrectBound? containerBounds;
  final utils.CorrectBound? targetBounds;
}

/// TS `class TablePropertiesForm`.
class TablePropertiesForm {
  TablePropertiesForm({
    required this.host,
    required this.type,
    required Map<String, String> attribute,
    TablePropertiesController? controller,
  })  : options = PropertiesOptions(type: type, attribute: attribute),
        attrs = Map<String, String>.from(attribute),
        controller = controller ?? TablePropertiesController() {
    form = createPropertiesForm();
  }

  final TablePropertiesFormHost host;

  /// `'table'` or `'cell'`.
  final String type;
  final PropertiesOptions options;
  final TablePropertiesController controller;

  /// TS `this.attrs` — the working copy edited by the controls.
  final Map<String, String> attrs;

  /// TS `this.borderForm` — [style, color, width] of the border row.
  final List<DomElement> borderForm = [];

  DomElement? saveButton;
  late final DomElement form;

  DomDocument get _document => host.container.ownerDocument;

  String _t(String key) => host.language.useLanguage(key);

  // --- construction -------------------------------------------------------

  /// TS `createPropertiesForm(options)`.
  DomElement createPropertiesForm() {
    final description = getProperties(options, _t);
    final container = _document.createElement('div');
    container.classes.add('ql-table-properties-form');
    final header = _document.createElement('h2');
    header.text = description.title;
    header.classes.add('properties-form-header');
    container.append(header);
    for (final property in description.properties) {
      container.append(createProperty(property));
    }
    final actions = createActionBtns(
      (label) => checkBtnsAction(label),
      showLabel: true,
    );
    container.append(actions);
    setBorderDisabled();
    host.container.append(container);
    setSaveButton(actions);
    return container;
  }

  /// TS `createProperty(property)`.
  DomElement createProperty(PropertyGroup property) {
    final container = _document.createElement('div');
    final label = _document.createElement('label');
    label.text = property.content;
    label.classes.add('ql-table-dropdown-label');
    container.classes.add('properties-form-row');
    if (property.children.length == 1) {
      container.classes.add('properties-form-row-full');
    }
    container.append(label);
    for (final child in property.children) {
      final node = createPropertyChild(child);
      if (node == null) continue;
      container.append(node);
      if (property.content == _t('border')) borderForm.add(node);
    }
    return container;
  }

  /// TS `createPropertyChild(child)`.
  DomElement? createPropertyChild(PropertyDescriptor child) {
    switch (child.category) {
      case 'dropdown':
        return createDropdown(child);
      case 'color':
        return createColorContainer(child);
      case 'menus':
        return createCheckBtns(child);
      case 'input':
        return createInput(child);
      default:
        return null;
    }
  }

  /// TS `createDropdown(value, category)` + `createList(child, dropText)`.
  DomElement createDropdown(PropertyDescriptor child) {
    final container = _document.createElement('div');
    final dropText = _document.createElement('span');
    final dropDown = _document.createElement('span');
    dropDown.innerHTML = tableBetterIcons['down'];
    dropDown.classes.add('ql-table-dropdown-icon');
    if (child.value != null) dropText.text = child.value!;
    container.classes.add('ql-table-dropdown-properties');
    dropText.classes.add('ql-table-dropdown-text');
    container.append(dropText);
    container.append(dropDown);

    final options = child.options ?? const <String>[];
    if (options.isNotEmpty) {
      final list = _document.createElement('ul');
      for (final option in options) {
        final item = _document.createElement('li');
        item.text = option;
        list.append(item);
      }
      list.classes.add('ql-table-dropdown-list');
      list.classes.add('ql-hidden');
      list.addEventListener('click', (event) {
        final target = _closest(event.target, 'LI');
        if (target == null) return;
        final value = target.text ?? '';
        dropText.text = value;
        toggleBorderDisabled(value);
        setAttribute(child.propertyName, value);
        updateSelectedStatus(container, value, 'dropdown');
      });
      container.append(list);
      container.addEventListener('click', (event) {
        if (_closest(event.target, 'LI') != null) return;
        toggleHidden(list);
        updateSelectedStatus(container, dropText.text ?? '', 'dropdown');
      });
    }
    return container;
  }

  /// TS `createInput(child)`.
  DomElement createInput(PropertyDescriptor child) {
    final container = _document.createElement('div');
    final wrapper = _document.createElement('div');
    final label = _document.createElement('label');
    final input = _document.createElement('input');
    final status = _document.createElement('div');
    container.classes.add('label-field-view');
    // Dart addition: the property name is recorded on the container so the
    // form can address a field without a live DOM query by label text.
    container.setAttribute('data-property', child.propertyName);
    wrapper.classes.add('label-field-view-input-wrapper');
    label.text = child.attribute?['placeholder'] ?? '';
    if (child.attribute != null) {
      utils.setElementAttribute(input, child.attribute!);
    }
    input.classes.add('property-input');
    input.setAttribute('value', child.value ?? '');
    input.addEventListener('input', (event) {
      final target = event.target;
      final value =
          target is DomElement ? target.getAttribute('value') ?? '' : '';
      onInput(child, container, wrapper, status, value);
    });
    status.classes.add('label-field-view-status');
    status.classes.add('ql-hidden');
    if (child.message != null) status.text = child.message!;
    wrapper.append(input);
    wrapper.append(label);
    container.append(wrapper);
    if (child.valid != null) container.append(status);
    return container;
  }

  /// The `input` listener body, exposed so callers (and tests) can type into a
  /// field without synthesising DOM events.
  void onInput(
    PropertyDescriptor child,
    DomElement container,
    DomElement wrapper,
    DomElement status,
    String value,
  ) {
    final valid = child.valid;
    if (valid != null) {
      switchHidden(status, valid(value));
      updateInputStatus(wrapper, !valid(value));
    }
    setAttribute(child.propertyName, value, container);
  }

  /// Types [value] into the input holding [propertyName] (test/API affordance).
  bool setInputValue(String propertyName, String value) {
    final description = getProperties(options, _t);
    for (final group in description.properties) {
      for (final child in group.children) {
        if (child.propertyName != propertyName) continue;
        if (child.category != 'input' && child.category != 'color') continue;
        final container = _containerFor(propertyName);
        if (container == null) return false;
        final inputs = container.querySelectorAll('.property-input');
        if (inputs.isEmpty) return false;
        inputs.first.setAttribute('value', value);
        final wrappers =
            container.querySelectorAll('.label-field-view-input-wrapper');
        final statuses = container.querySelectorAll('.label-field-view-status');
        onInput(
          child,
          container,
          wrappers.isEmpty ? container : wrappers.first,
          statuses.isEmpty ? container : statuses.first,
          value,
        );
        return true;
      }
    }
    return false;
  }

  /// TS `createColorContainer(child)`.
  DomElement createColorContainer(PropertyDescriptor child) {
    final container = _document.createElement('div');
    container.classes.add('ql-table-color-container');
    container.setAttribute('data-property', child.propertyName);
    final input = createInput(child);
    input.classes.add('label-field-view-color');
    container.append(input);
    container.append(createColorPicker(child));
    return container;
  }

  /// TS `createColorPicker(child)`.
  DomElement createColorPicker(PropertyDescriptor child) {
    final container = _document.createElement('span');
    final colorButton = _document.createElement('span');
    container.classes.add('color-picker');
    colorButton.classes.add('color-button');
    final value = child.value;
    if (value != null && value.isNotEmpty) {
      utils.setElementProperty(colorButton, {'background-color': value});
    } else {
      colorButton.classes.add('color-unselected');
    }
    final select = createColorPickerSelect(child.propertyName);
    colorButton.addEventListener('click', (_) => toggleHidden(select));
    container.append(colorButton);
    container.append(select);
    return container;
  }

  /// TS `createColorPickerSelect(propertyName)`.
  DomElement createColorPickerSelect(String propertyName) {
    final container = _document.createElement('div');
    container.classes.add('color-picker-select');
    container.classes.add('ql-hidden');
    container.append(createColorPickerIcon(
      tableBetterIcons['erase'] ?? '',
      _t('removeColor'),
      () => setColorValue(propertyName, ''),
    ));
    container.append(createColorList(propertyName));
    // Upstream's third section is the `iro` colour wheel; the hex input above
    // covers the same need without vendoring a dependency.
    return container;
  }

  /// TS `createColorList(propertyName)`.
  DomElement createColorList(String propertyName) {
    final container = _document.createElement('ul');
    container.classes.add('color-list');
    for (final swatch in kColorList) {
      final item = _document.createElement('li');
      item.setAttribute('data-color', swatch.value);
      item.classes.add('ql-table-tooltip-hover');
      utils.setElementProperty(item, {'background-color': swatch.value});
      item.append(utils.createTooltip(_t(swatch.describe)));
      item.addEventListener(
          'click', (_) => setColorValue(propertyName, swatch.value));
      container.append(item);
    }
    return container;
  }

  /// TS `createColorPickerIcon(svg, text, listener)`.
  DomElement createColorPickerIcon(
      String svg, String text, void Function() listener) {
    final container = _document.createElement('div');
    final icon = _document.createElement('span');
    final button = _document.createElement('button');
    icon.innerHTML = svg;
    button.text = text;
    button.setAttribute('type', 'button');
    container.classes.add('erase-container');
    container.append(icon);
    container.append(button);
    container.addEventListener('click', (_) => listener());
    return container;
  }

  /// TS `createCheckBtns(child)` — the alignment toggles.
  DomElement createCheckBtns(PropertyDescriptor child) {
    final container = _document.createElement('div');
    container.classes.add('ql-table-check-container');
    container.setAttribute('data-property', child.propertyName);
    for (final menu in child.menus ?? const <PropertyMenu>[]) {
      final item = _document.createElement('span');
      item.innerHTML = tableBetterIcons[menu.icon] ?? menu.icon;
      item.setAttribute('data-align', menu.align);
      item.classes.add('ql-table-tooltip-hover');
      if (options.attribute[child.propertyName] == menu.align) {
        item.classes.add('ql-table-btns-checked');
      }
      item.append(utils.createTooltip(menu.describe));
      item.addEventListener('click', (_) {
        switchButton(container, item);
        setAttribute(child.propertyName, menu.align);
      });
      container.append(item);
    }
    return container;
  }

  /// TS `createActionBtns(listener, showLabel)`.
  DomElement createActionBtns(void Function(String label) listener,
      {required bool showLabel}) {
    final container = _document.createElement('div');
    container.classes.add('properties-form-action-row');
    for (final action in kActionList) {
      final button = _document.createElement('button');
      final iconContainer = _document.createElement('span');
      iconContainer.innerHTML = tableBetterIcons[action.icon] ?? '';
      button.append(iconContainer);
      utils.setElementAttribute(button, {
        'label': action.label,
        'type': 'button',
      });
      if (showLabel) {
        final labelContainer = _document.createElement('span');
        labelContainer.text = _t(action.label);
        button.append(labelContainer);
      }
      button.addEventListener('click', (_) => listener(action.label));
      container.append(button);
    }
    return container;
  }

  // --- state --------------------------------------------------------------

  /// TS `setAttribute(propertyName, value, container)`.
  void setAttribute(String propertyName, String value,
      [DomElement? container]) {
    attrs[propertyName] = value;
    if (propertyName.contains('-color')) {
      final target = container == null
          ? _containerFor(propertyName)
          : _colorClosest(container) ?? _containerFor(propertyName);
      if (target != null) updateSelectColor(target, value);
    }
  }

  /// Picks a colour through the palette or the "remove colour" button.
  void setColorValue(String propertyName, String value) {
    setAttribute(propertyName, value);
    final container = _containerFor(propertyName);
    if (container != null) updateInputStatus(container, false, isColor: true);
  }

  /// TS `updateSelectColor(element, value)`.
  void updateSelectColor(DomElement element, String value) {
    final buttons = element.querySelectorAll('.color-button');
    if (buttons.isNotEmpty) {
      final colorButton = buttons.first;
      if (value.isEmpty) {
        colorButton.classes.add('color-unselected');
      } else {
        colorButton.classes.remove('color-unselected');
      }
      utils.setElementProperty(colorButton, {'background-color': value});
    }
    final inputs = element.querySelectorAll('.property-input');
    if (inputs.isNotEmpty) inputs.first.setAttribute('value', value);
    for (final select in element.querySelectorAll('.color-picker-select')) {
      select.classes.add('ql-hidden');
    }
    final statuses = element.querySelectorAll('.label-field-view-status');
    if (statuses.isNotEmpty) {
      switchHidden(statuses.first, value.isEmpty || utils.isValidColor(value));
    }
  }

  /// TS `updateSelectedStatus(container, value, type)`.
  void updateSelectedStatus(DomElement container, String value, String type) {
    final selector =
        type == 'color' ? '.color-list' : '.ql-table-dropdown-list';
    final lists = container.querySelectorAll(selector);
    if (lists.isEmpty) return;
    final items = lists.first.querySelectorAll('li');
    for (final item in items) {
      item.classes.remove('ql-table-$type-selected');
    }
    for (final item in items) {
      final data =
          type == 'color' ? item.getAttribute('data-color') : item.text;
      if (data == value) {
        item.classes.add('ql-table-$type-selected');
        break;
      }
    }
  }

  /// TS `switchButton(container, target)`.
  void switchButton(DomElement container, DomElement target) {
    for (final child in container.querySelectorAll('span')) {
      child.classes.remove('ql-table-btns-checked');
    }
    target.classes.add('ql-table-btns-checked');
  }

  /// TS `switchHidden(container, valid)`.
  void switchHidden(DomElement container, bool valid) {
    if (valid) {
      container.classes.add('ql-hidden');
    } else {
      container.classes.remove('ql-hidden');
    }
  }

  /// TS `toggleHidden(container)`.
  void toggleHidden(DomElement container) =>
      container.classes.toggle('ql-hidden');

  /// TS `updateInputStatus(container, status, isColor)` — an invalid field
  /// marks the wrapper and disables Save until every field is valid again.
  void updateInputStatus(DomElement container, bool status,
      {bool isColor = false}) {
    final closest = isColor
        ? (_colorClosest(container) ?? container)
        : (_closestByClass(container, 'label-field-view') ?? container);
    final wrappers =
        closest.querySelectorAll('.label-field-view-input-wrapper');
    final wrapper = wrappers.isEmpty ? closest : wrappers.first;
    if (status) {
      wrapper.classes.add('label-field-view-error');
      setSaveButtonDisabled(true);
      return;
    }
    wrapper.classes.remove('label-field-view-error');
    if (form.querySelectorAll('.label-field-view-error').isEmpty) {
      setSaveButtonDisabled(false);
    }
  }

  /// TS `setSaveButton(container)`.
  void setSaveButton(DomElement container) {
    for (final button in container.querySelectorAll('button')) {
      if (button.getAttribute('label') == 'save') {
        saveButton = button;
        return;
      }
    }
  }

  /// TS `setSaveButtonDisabled(disabled)`.
  void setSaveButtonDisabled(bool disabled) {
    final button = saveButton;
    if (button == null) return;
    if (disabled) {
      button.setAttribute('disabled', 'true');
    } else {
      button.removeAttribute('disabled');
    }
  }

  /// TS `setBorderDisabled()`.
  void setBorderDisabled() {
    if (borderForm.isEmpty) return;
    final texts = borderForm.first.querySelectorAll('.ql-table-dropdown-text');
    toggleBorderDisabled(texts.isEmpty ? '' : texts.first.text ?? '');
  }

  /// TS `toggleBorderDisabled(value)` — `none` greys out colour and width.
  void toggleBorderDisabled(String value) {
    if (borderForm.length < 3) return;
    final colorContainer = borderForm[1];
    final widthContainer = borderForm[2];
    if (value.isEmpty || value == 'none') {
      attrs['border-color'] = '';
      attrs['border-width'] = '';
      updateSelectColor(colorContainer, '');
      final inputs = widthContainer.querySelectorAll('.property-input');
      if (inputs.isNotEmpty) inputs.first.setAttribute('value', '');
      colorContainer.classes.add('ql-table-disabled');
      widthContainer.classes.add('ql-table-disabled');
    } else {
      colorContainer.classes.remove('ql-table-disabled');
      widthContainer.classes.remove('ql-table-disabled');
    }
  }

  // --- save ---------------------------------------------------------------

  /// TS `checkBtnsAction(status)`.
  void checkBtnsAction(String label) {
    if (label == 'save') saveAction();
    removePropertiesForm();
    host.onClose();
  }

  /// TS `getDiffProperties()` — only the values the user actually changed,
  /// with dimension units appended.
  Map<String, String> getDiffProperties() {
    final result = <String, String>{};
    for (final entry in attrs.entries) {
      if (entry.value == options.attribute[entry.key]) continue;
      result[entry.key] = utils.isDimensions(entry.key)
          ? utils.addDimensionsUnit(entry.value)
          : entry.value;
    }
    return result;
  }

  /// TS `saveAction(type)`.
  void saveAction() {
    if (type == 'table') {
      saveTableAction();
    } else {
      saveCellAction();
    }
  }

  /// TS `saveTableAction()` — `align` becomes a margin declaration and the
  /// styles land on the temporary blot when there is one.
  void saveTableAction() {
    final table = host.table;
    if (table == null) return;
    final attributes = getDiffProperties();
    final align = attributes.remove('align');
    switch (align) {
      case 'center':
        attributes['margin'] = '0 auto';
        break;
      case 'left':
        attributes['margin'] = '';
        break;
      case 'right':
        attributes['margin-left'] = 'auto';
        attributes['margin-right'] = '';
        break;
      default:
        break;
    }
    if (attributes.isEmpty) return;
    final temporary = table.temporary();
    utils.setElementProperty(temporary?.element ?? table.element, attributes);
  }

  /// TS `saveCellAction()` — `text-align` propagates into the cell's blocks
  /// (and into list items through their container), the rest becomes style.
  void saveCellAction() {
    final cells = host.selectedCells;
    if (cells.isEmpty) return;
    final attributes = getDiffProperties();
    final align = attributes.remove('text-align');
    for (final cell in cells) {
      if (align != null) {
        final value = align == 'left' ? '' : align;
        for (final child in cell.children.toList()) {
          // TS: a list container forwards the alignment to its items.
          if (child is TableListContainer) {
            for (final item in child.children.toList()) {
              item.format('align', value);
            }
          } else {
            child.format('align', value);
          }
        }
      }
      if (attributes.isNotEmpty) {
        utils.setElementProperty(cell.element, attributes);
      }
    }
  }

  /// TS `removePropertiesForm()`.
  void removePropertiesForm() {
    form.remove();
    borderForm.clear();
  }

  // --- positioning --------------------------------------------------------

  /// TS `updatePropertiesForm(container, type)`.
  void updatePropertiesForm() {
    form.classes.remove('ql-table-triangle-none');
    final containerBounds =
        host.containerBounds ?? utils.getCorrectBounds(host.container);
    final target = host.targetBounds ?? containerBounds;
    final formBounds = utils.getCorrectBounds(form, host.container);
    final height = formBounds.height;
    final width = formBounds.width;
    var correctTop = target.bottom + 10;
    var correctLeft =
        ((target.left + target.right - width) / 2).floorToDouble();
    if (correctTop + containerBounds.top + height > containerBounds.height) {
      correctTop = target.top - height - 10;
      if (correctTop < 0) {
        correctTop = ((containerBounds.height - height) / 2).floorToDouble();
        form.classes.add('ql-table-triangle-none');
      } else {
        form.classes.add('ql-table-triangle-up');
        form.classes.remove('ql-table-triangle-down');
      }
    } else {
      form.classes.add('ql-table-triangle-down');
      form.classes.remove('ql-table-triangle-up');
    }
    if (correctLeft < containerBounds.left) {
      correctLeft = 0;
      form.classes.add('ql-table-triangle-none');
    } else if (correctLeft + width > containerBounds.right) {
      correctLeft = containerBounds.right - width;
      form.classes.add('ql-table-triangle-none');
    }
    utils.setElementProperty(form, {
      'left': '${utils.formatNum(correctLeft)}px',
      'top': '${utils.formatNum(correctTop)}px',
    });
  }

  // --- helpers ------------------------------------------------------------

  DomElement? _containerFor(String propertyName) {
    for (final candidate in form.querySelectorAll('[data-property]')) {
      if (candidate.getAttribute('data-property') == propertyName) {
        return candidate;
      }
    }
    return null;
  }

  DomElement? _colorClosest(DomElement container) =>
      _closestByClass(container, 'ql-table-color-container');

  DomElement? _closestByClass(DomElement start, String className) {
    DomNode? node = start;
    while (node != null) {
      if (node is DomElement && node.classes.contains(className)) return node;
      node = node.parentNode;
    }
    return null;
  }

  DomElement? _closest(DomNode? target, String tagName) {
    DomNode? node = target;
    while (node != null) {
      if (node is DomElement && node.tagName.toUpperCase() == tagName) {
        return node;
      }
      node = node.parentNode;
    }
    return null;
  }
}
