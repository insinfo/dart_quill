import '../platform/dom.dart';

const String _dropdownIcon = '''
<svg viewBox="0 0 18 18">
  <polygon class="ql-stroke" points="7 11 9 13 11 11 7 11"></polygon>
  <polygon class="ql-stroke" points="7 7 9 5 11 7 7 7"></polygon>
</svg>
''';

int _optionsIdCounter = 0;

/// Base class for Quill pickers (color, icon, etc.).
class Picker {
  Picker(this.select, {this.iconSvg}) {
    _build();
  }

  final DomElement select;
  final String? iconSvg;

  late final DomElement container;
  late final DomElement label;
  late final DomElement _optionsContainer;
  final List<DomElement> _items = [];
  final List<DomElement> _options = [];
  final List<String?> _values = [];

  void Function(String?)? onSelected;

  void _build() {
    final document = select.ownerDocument;
    container = document.createElement('span');
    _copyAttributes(select, container);
    container.classes.add('ql-picker');

    // Insert picker before select and hide original select element.
    select.parentNode?.insertBefore(container, select);
    final style = select.style as dynamic;
    style.display = 'none';

    label = _buildLabel(document);
    container.append(label);

    _optionsContainer = _buildOptions(document);
    container.append(_optionsContainer);

    label.addEventListener('mousedown', (_) => toggle());
    label.addEventListener('keydown', (event) {
      final key = (event.rawEvent as dynamic).key as String?;
      if (key == 'Enter') {
        toggle();
        event.preventDefault();
      } else if (key == 'Escape') {
        close();
        event.preventDefault();
      }
    });

    select.addEventListener('change', (_) => update());
    update();
  }

  void toggle() {
    if (container.classes.contains('ql-expanded')) {
      close();
    } else {
      open();
    }
  }

  void open() {
    container.classes.add('ql-expanded');
    label.setAttribute('aria-expanded', 'true');
    _optionsContainer.setAttribute('aria-hidden', 'false');
  }

  void close() {
    container.classes.remove('ql-expanded');
    label.setAttribute('aria-expanded', 'false');
    _optionsContainer.setAttribute('aria-hidden', 'true');
  }

  void update() {
    DomElement? item;
    DomElement? option;

    final dynamic nativeSelect = select as dynamic;
    try {
      final selectedIndex = nativeSelect.selectedIndex as int?;
      if (selectedIndex != null && selectedIndex >= 0 && selectedIndex < _items.length) {
        item = _items[selectedIndex];
        option = _options[selectedIndex];
      }
    } catch (_) {
      // Fall back to attributes if direct access is unavailable.
    }

    if (item == null) {
      for (var i = 0; i < _options.length; i += 1) {
        if (_options[i].hasAttribute('selected')) {
          item = _items[i];
          option = _options[i];
          break;
        }
      }
    }

    _selectItem(item, trigger: false);

  final initialOption = select.querySelector('option[selected]');
  final isActive = option != null && (initialOption == null || option != initialOption);
    label.classes.toggle('ql-active', isActive);
  }

  DomElement _buildLabel(DomDocument document) {
    final element = document.createElement('span');
    element.classes.add('ql-picker-label');
    element.setAttribute('role', 'button');
    element.setAttribute('tabindex', '0');
    element.setAttribute('aria-expanded', 'false');
    element.innerHTML = iconSvg ?? _dropdownIcon;
    decorateLabel(element);
    return element;
  }

  DomElement _buildOptions(DomDocument document) {
    _items.clear();
    _options.clear();
    _values.clear();

    final options = document.createElement('span');
    options.classes.add('ql-picker-options');
    options.setAttribute('aria-hidden', 'true');
    options.setAttribute('tabindex', '-1');

    final id = 'ql-picker-options-${_optionsIdCounter++}';
    options.setAttribute('id', id);
    label.setAttribute('aria-controls', id);

    final selectOptions = select.querySelectorAll('option');
    for (var i = 0; i < selectOptions.length; i += 1) {
      final option = selectOptions[i];
      final item = document.createElement('span');
      item.classes.add('ql-picker-item');
      item.setAttribute('role', 'button');
      item.setAttribute('tabindex', '0');

      final rawValue = option.getAttribute('value');
      final normalizedValue = (rawValue == null || rawValue.isEmpty || rawValue == 'false')
          ? null
          : rawValue;
      if (normalizedValue != null) {
        item.setAttribute('data-value', normalizedValue);
      }

      final labelText = option.text ?? '';
      if (labelText.isNotEmpty) {
        item.setAttribute('data-label', labelText);
      }

      item.addEventListener('click', (_) => _selectItem(item));
      item.addEventListener('keydown', (event) {
        final key = (event.rawEvent as dynamic).key as String?;
        if (key == 'Enter') {
          _selectItem(item);
          event.preventDefault();
        } else if (key == 'Escape') {
          close();
          event.preventDefault();
        }
      });

      decorateItem(item, option, normalizedValue, i);
      options.append(item);
      _items.add(item);
      _options.add(option);
      _values.add(normalizedValue);
    }

    return options;
  }

  void _selectItem(DomElement? item, {bool trigger = true}) {
    final selected = container.querySelector('.ql-selected');
    if (selected == item) {
      if (trigger) close();
      return;
    }
    selected?.classes.remove('ql-selected');

    String? value;
    if (item != null) {
      item.classes.add('ql-selected');
      final index = _items.indexOf(item);
      if (index != -1) {
        value = _values[index];
        _applySelectionToOption(index);
      }
    } else {
      _clearOptionSelection();
    }

    _updateLabel(item, value);
    onSelectionChanged(value);

    if (trigger) {
      close();
      onSelected?.call(value);
    }
  }

  void _applySelectionToOption(int index) {
    for (var i = 0; i < _options.length; i += 1) {
      if (i == index) {
        _options[i].setAttribute('selected', 'selected');
      } else {
        _options[i].removeAttribute('selected');
      }
    }

    try {
      final dynamic nativeSelect = select as dynamic;
      nativeSelect.selectedIndex = index;
    } catch (_) {
      // Non-browser adapters may not expose selectedIndex.
    }

    final value = _values[index];
    if (value != null) {
      select.setAttribute('value', value);
      select.setAttribute('data-value', value);
    } else {
      select.removeAttribute('value');
      select.removeAttribute('data-value');
    }
  }

  void _clearOptionSelection() {
    for (final option in _options) {
      option.removeAttribute('selected');
    }
    select.removeAttribute('value');
    select.removeAttribute('data-value');
    try {
      final dynamic nativeSelect = select as dynamic;
      nativeSelect.selectedIndex = -1;
    } catch (_) {
      // Ignore when adapter does not expose selectedIndex.
    }
  }

  void _updateLabel(DomElement? item, String? value) {
    if (item != null && item.hasAttribute('data-label')) {
      label.setAttribute('data-label', item.getAttribute('data-label')!);
    } else {
      label.removeAttribute('data-label');
    }
    if (value != null) {
      label.setAttribute('data-value', value);
    } else {
      label.removeAttribute('data-value');
    }
  }

  void _copyAttributes(DomElement source, DomElement target) {
    final className = source.className;
    if (className != null && className.isNotEmpty) {
      target.setAttribute('class', className);
    }
    final title = source.getAttribute('title');
    if (title != null) {
      target.setAttribute('title', title);
    }
    for (final entry in source.dataset.entries) {
      target.dataset[entry.key] = entry.value;
    }
  }

  void decorateItem(DomElement item, DomElement option, String? value, int index) {}

  void decorateLabel(DomElement element) {}

  void onSelectionChanged(String? value) {}
}

class ColorPicker extends Picker {
  ColorPicker(DomElement select, String? iconSvg)
      : super(select, iconSvg: iconSvg ?? _dropdownIcon) {
    container.classes.add('ql-color-picker');
  }

  @override
  void decorateItem(DomElement item, DomElement option, String? value, int index) {
    final style = item.style as dynamic;
    style.backgroundColor = value ?? '';
    if (index < 7) {
      item.classes.add('ql-primary');
    }
  }

  @override
  void onSelectionChanged(String? value) {
    final colorLabels = label.querySelectorAll('.ql-color-label');
    if (colorLabels.isEmpty) {
      final style = label.style as dynamic;
      style.borderBottom = value != null && value.isNotEmpty ? '2px solid $value' : '';
      return;
    }

    for (final colorLabel in colorLabels) {
      final style = colorLabel.style as dynamic;
      final tag = colorLabel.tagName.toLowerCase();
      if (tag == 'line') {
        style.stroke = value ?? 'transparent';
      } else {
        style.fill = value ?? 'transparent';
      }
    }
  }
}

class IconPicker extends Picker {
  IconPicker(DomElement select, this.icons) : super(select) {
    container.classes.add('ql-icon-picker');
    final items = container.querySelectorAll('.ql-picker-item');
    for (final item in items) {
      final value = item.getAttribute('data-value') ?? '';
      final icon = icons[value] ?? icons[''] ?? '';
      if (icon.isNotEmpty) {
        item.innerHTML = icon;
      }
    }
    _defaultItem = container.querySelector('.ql-selected') ?? (items.isNotEmpty ? items.first : null);
    _selectItem(_defaultItem, trigger: false);
  }

  final Map<String, String> icons;
  DomElement? _defaultItem;

  @override
  void onSelectionChanged(String? value) {
    String? icon;
    if (value != null) {
      icon = icons[value];
    }
    icon ??= _defaultItem?.innerHTML;
    icon ??= icons[''];
    if (icon != null && icon.isNotEmpty) {
      label.innerHTML = icon;
    }
  }
}
