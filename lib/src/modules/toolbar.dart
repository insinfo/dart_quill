import '../core/module.dart';
import '../core/quill.dart';
import '../core/selection.dart';
import '../core/emitter.dart';
import '../blots/abstract/blot.dart';
import '../platform/platform.dart';
import '../platform/dom.dart';
import 'table.dart';

// Placeholder for logger
class Logger {
  void error(dynamic message) => print('ERROR: $message');
  void log(dynamic message) => print('LOG: $message');
}

final debug = Logger();

// Type definitions
typedef Handler = void Function(dynamic value);

// ToolbarConfig is a list of toolbar groups
class ToolbarConfig {
  final List<List<dynamic>> groups;
  ToolbarConfig(this.groups);
}

class ToolbarProps {
  final dynamic
      container; // DomElement | String selector | ToolbarConfig | null
  final Map<String, Handler>? handlers;
  final int? option;
  final bool? module;
  final bool? theme;

  ToolbarProps({
    this.container,
    this.handlers,
    this.option,
    this.module,
    this.theme,
  });
}

class Toolbar extends Module<ToolbarProps> {
  static final DEFAULTS = ToolbarProps();
  static const Set<String> _blockSelectFormats = {'header'};

  DomElement? container;
  final List<List<dynamic>> controls = []; // [format, input]
  final Map<String, Handler> handlers = {};
  Range? _savedRange;
  _TableGridPicker? _tableGridPicker;

  Toolbar(Quill quill, ToolbarProps options) : super(quill, options) {
    final document = domBindings.adapter.document;

    if (options.container is ToolbarConfig) {
      final containerDiv = document.createElement('div');
      containerDiv.setAttribute('role', 'toolbar');
      addControls(containerDiv, options.container as ToolbarConfig);
      quill.container.parentNode?.insertBefore(containerDiv, quill.container);
      container = containerDiv;
    } else if (options.container is String) {
      container = document.querySelector(options.container as String);
    } else {
      container = options.container as DomElement?;
    }

    if (container == null) {
      debug.error('Container required for toolbar');
      return;
    }
    container!.classes.add('ql-toolbar');
    container!.addEventListener('mousedown', (event) {
      _captureRange();
      // Toolbar controls must not replace the editor's native selection.
      event.preventDefault();
    });

    if (options.handlers != null) {
      options.handlers!.forEach((format, handler) {
        addHandler(format, handler);
      });
    }

    _registerBuiltInHandlers();

    void attachDescendants(DomElement element) {
      for (final node in element.childNodes) {
        if (node is! DomElement) {
          continue;
        }
        final tag = node.tagName.toLowerCase();
        if (tag == 'button' || tag == 'select') {
          attach(node);
        }
        attachDescendants(node);
      }
    }

    attachDescendants(container!);

    quill.on(EmitterEvents.EDITOR_CHANGE, (type, range, oldRange, source) {
      update(quill.selection.getRange());
    });
  }

  void addHandler(String format, Handler handler) {
    handlers[format] = handler;
  }

  void attach(DomElement input) {
    // Find format from class names
    var format = '';
    for (final className in input.classes.values) {
      if (className.startsWith('ql-')) {
        format = className;
        break;
      }
    }
    if (format.isEmpty) return;
    format = format.substring('ql-'.length);

    // Set button type if it's a button element
    if (input.tagName.toLowerCase() == 'button') {
      input.setAttribute('type', 'button');
    }
    if (format == 'table' && input.tagName.toLowerCase() == 'button') {
      _tableGridPicker ??= _TableGridPicker(quill, container!, input);
    }

    // Placeholder for quill.scroll.query
    // if (handlers[format] == null && quill.scroll.query(format) == null) {
    //   debug.log('ignoring attaching to nonexistent format', format, input);
    //   return;
    // }

    // Determine if this is a select element or button
    final isSelect = input.tagName.toLowerCase() == 'select';
    final eventName = isSelect ? 'change' : 'mousedown';

    input.addEventListener(eventName, (e) {
      final actionRange = _captureRange();
      dynamic value;
      if (isSelect) {
        // For select elements, get the selected option's value via getAttribute
        final selected = input.querySelector('option[selected]');
        if (selected != null) {
          final optionValue = selected.getAttribute('value');
          value = (optionValue != null && optionValue.isNotEmpty)
              ? optionValue
              : false;
        } else {
          value = false;
        }
      } else {
        // For buttons, check active state
        if (input.classes.contains('ql-active')) {
          value = false;
        } else {
          final rawValue = input.getAttribute('value');
          if (rawValue == null) {
            value = true;
          } else if (rawValue.isEmpty) {
            value = false;
          } else {
            value = rawValue;
          }
        }
        e.preventDefault();
      }

      final range = _restoreRange(actionRange);
      if (range == null) return;

      if (handlers[format] != null) {
        handlers[format]!(value);
      } else {
        // Placeholder for EmbedBlot check
        // if (quill.scroll.query(format).prototype is EmbedBlot) {
        //   value = window.prompt('Enter $format');
        //   if (value == null) return;
        //   quill.updateContents(
        //     Delta()..retain(range.index)..delete(range.length)..insert({format: value}),
        //     EmitterSource.USER,
        //   );
        // } else {
        _formatRange(range, format, value);
        // }
      }
      update(range);
    });
    controls.add([format, input]);
  }

  void update(Range? range) {
    final formats = range == null
        ? <String, dynamic>{}
        : quill.getFormat(range.index, range.length);
    controls.forEach((pair) {
      final format = pair[0] as String;
      final input = pair[1] as DomElement;

      final isSelect = input.tagName.toLowerCase() == 'select';

      if (isSelect) {
        DomElement? option;
        final options = input.querySelectorAll('option');
        final hasConflict = range != null && _hasSelectConflict(format, range);

        DomElement? findOption(bool Function(DomElement option) predicate) {
          for (final candidate in options) {
            if (predicate(candidate)) {
              return candidate;
            }
          }
          return null;
        }

        if (range == null) {
          option = null;
        } else if (hasConflict) {
          option = null;
        } else if (!formats.containsKey(format)) {
          option = findOption((opt) => opt.getAttribute('value') == null);
        } else if (formats[format] is! List) {
          var value = formats[format];
          if (value is String) {
            value = value.replaceAll(RegExp(r'"'), r'\"');
          }
          final expected = value?.toString() ?? '';
          option = findOption((opt) => opt.getAttribute('value') == expected);
        }

        for (final opt in options) {
          opt.removeAttribute('selected');
        }

        if (option != null) {
          option.setAttribute('selected', 'selected');
        }
      } else {
        // For buttons, toggle active class
        if (range == null) {
          input.classes.remove('ql-active');
          input.setAttribute('aria-pressed', 'false');
        } else if (input.hasAttribute('value')) {
          final value = formats[format];
          final attrValue = input.getAttribute('value');
          final attrIsDefault = attrValue == null || attrValue.isEmpty;
          final isActive = value == attrValue ||
              (value != null && value.toString() == attrValue) ||
              (value == null && attrIsDefault);
          input.classes.toggle('ql-active', isActive);
          input.setAttribute('aria-pressed', isActive.toString());
        } else {
          final isActive = formats[format] != null;
          input.classes.toggle('ql-active', isActive);
          input.setAttribute('aria-pressed', isActive.toString());
        }
      }
    });
  }

  bool _hasSelectConflict(String format, Range range) {
    if (range.length == 0) {
      return false;
    }
    if (!_blockSelectFormats.contains(format)) {
      return false;
    }
    return _hasBlockFormatConflict(range, format);
  }

  bool _hasBlockFormatConflict(Range range, String format) {
    final lines = quill.scroll.lines(range.index, range.length);
    if (lines.length <= 1) {
      return false;
    }
    dynamic referenceValue;
    var isFirst = true;
    for (final line in lines) {
      dynamic lineValue;
      try {
        final formats = (line as dynamic).formats();
        lineValue = formats[format];
      } catch (_) {
        lineValue = null;
      }
      if (isFirst) {
        referenceValue = lineValue;
        isFirst = false;
        continue;
      }
      if (lineValue != referenceValue) {
        return true;
      }
    }
    return false;
  }

  void applyFromPicker(DomElement _select, String format, String? value) {
    dynamic resolvedValue = value;
    if (resolvedValue == null ||
        (resolvedValue is String && resolvedValue.isEmpty)) {
      resolvedValue = false;
    }

    final range = _restoreRange(_savedRange ?? quill.selection.savedRange);
    if (range == null) {
      return;
    }

    final handler = handlers[format];
    if (handler != null) {
      handler(resolvedValue);
    } else {
      _formatRange(range, format, resolvedValue);
    }

    update(range);
  }

  Range? _captureRange() {
    final range = quill.getSelection() ?? quill.selection.savedRange;
    if (range != null) {
      _savedRange = range;
    }
    return range;
  }

  Range? _restoreRange(Range? range) {
    final restored = range ?? _savedRange ?? quill.selection.savedRange;
    if (restored == null) {
      return null;
    }
    _savedRange = restored;
    quill.focus(preventScroll: true);
    quill.setSelection(restored, source: EmitterSource.SILENT);
    return restored;
  }

  void _formatRange(Range range, String format, dynamic value) {
    final isBlock = quill.scroll.registry.query(format, Scope.BLOCK) != null ||
        quill.scroll.registry.queryAttributor(format, Scope.BLOCK_ATTRIBUTE) !=
            null;
    if (isBlock) {
      quill.formatLine(
        range.index,
        range.length,
        format,
        value,
        source: EmitterSource.USER,
      );
    } else {
      quill.formatText(
        range.index,
        range.length,
        format,
        value,
        source: EmitterSource.USER,
      );
    }
  }

  void _registerBuiltInHandlers() {
    if (!handlers.containsKey('clean')) {
      addHandler('clean', (_) {
        final range = quill.selection.getRange();
        if (range == null) return;
        if (range.length == 0) {
          final formats = quill.getFormat(range.index, range.length);
          for (final entry in formats.entries) {
            quill.format(entry.key, false, source: EmitterSource.USER);
          }
        } else {
          quill.removeFormat(range.index, range.length,
              source: EmitterSource.USER);
        }
      });
    }

    if (!handlers.containsKey('direction')) {
      addHandler('direction', (value) {
        final range = quill.selection.getRange();
        if (range == null) return;
        final formats = quill.getFormat(range.index, range.length);
        final align = formats['align'];
        if (value == 'rtl' && (align == null || align == false)) {
          quill.format('align', 'right', source: EmitterSource.USER);
        } else if ((value == null || value == false) && align == 'right') {
          quill.format('align', false, source: EmitterSource.USER);
        }
        quill.format('direction', value, source: EmitterSource.USER);
      });
    }

    if (!handlers.containsKey('indent')) {
      addHandler('indent', (value) {
        final range = quill.selection.getRange();
        if (range == null) return;
        final formats = quill.getFormat(range.index, range.length);
        final currentIndent = int.tryParse('${formats['indent'] ?? 0}') ?? 0;
        int modifier = 0;
        if (value == '+1') {
          modifier = 1;
        } else if (value == '-1') {
          modifier = -1;
        }
        if (formats['direction'] == 'rtl') {
          modifier *= -1;
        }
        final target = currentIndent + modifier;
        if (target <= 0) {
          quill.format('indent', false, source: EmitterSource.USER);
        } else {
          quill.format('indent', target, source: EmitterSource.USER);
        }
      });
    }

    if (!handlers.containsKey('link')) {
      addHandler('link', (value) {
        final range = quill.selection.getRange();
        if (range == null) return;
        final formats = quill.getFormat(range.index, range.length);
        final hasLink = formats.containsKey('link');
        if (value == null || value == true) {
          if (hasLink) {
            quill.format('link', false, source: EmitterSource.USER);
          }
          if (!hasLink) {
            final theme = quill.theme;
            final dynamic tooltip = (theme as dynamic).tooltip;
            if (tooltip != null) {
              try {
                tooltip.edit('link');
              } catch (_) {
                // Ignore when tooltip does not support edit.
              }
            }
          }
          return;
        }
        quill.format('link', value, source: EmitterSource.USER);
      });
    }

    if (!handlers.containsKey('list')) {
      addHandler('list', (value) {
        final range = quill.selection.getRange();
        if (range == null) return;
        final formats = quill.getFormat(range.index, range.length);
        if (value == 'check') {
          final current = formats['list'];
          if (current == 'checked' || current == 'unchecked') {
            quill.format('list', false, source: EmitterSource.USER);
          } else {
            quill.format('list', 'unchecked', source: EmitterSource.USER);
          }
          return;
        }
        quill.format('list', value, source: EmitterSource.USER);
      });
    }

    if (!handlers.containsKey('table')) {
      addHandler('table', (_) {
        _tableGridPicker?.toggle();
      });
    }

    final tableActions = <String, void Function(Table)>{
      'table-row-above': (table) => table.insertRowAbove(),
      'table-row-below': (table) => table.insertRowBelow(),
      'table-column-left': (table) => table.insertColumnLeft(),
      'table-column-right': (table) => table.insertColumnRight(),
      'table-delete-row': (table) => table.deleteRow(),
      'table-delete-column': (table) => table.deleteColumn(),
      'table-delete': (table) => table.deleteTable(),
    };
    for (final entry in tableActions.entries) {
      if (!handlers.containsKey(entry.key)) {
        addHandler(entry.key, (_) {
          final module = quill.getModule('table');
          if (module is Table) entry.value(module);
        });
      }
    }
  }
}

/// Port of quill-table-better `TableSelect`: a 10×10 insertion grid.
class _TableGridPicker {
  _TableGridPicker(this.quill, this.toolbar, DomElement button) {
    root = quill.container.ownerDocument.createElement('div');
    root.classes.add('ql-table-select-container');
    root.classes.add('ql-hidden');
    root.setAttribute('role', 'dialog');
    root.setAttribute('aria-label', 'Escolher tamanho da tabela');
    root.style.cssText =
        'display:none;position:fixed;z-index:1200;width:224px;padding:8px;'
        'box-sizing:border-box;background:#fff;border:1px solid #ccced1;'
        'border-radius:2px;box-shadow:0 1px 2px 1px rgba(0,0,0,.15);';

    final list = quill.container.ownerDocument.createElement('div');
    list.classes.add('ql-table-select-list');
    list.style.cssText =
        'display:grid;grid-template-columns:repeat(10,18px);gap:3px;'
        'justify-content:center;';
    for (var row = 1; row <= 10; row++) {
      for (var column = 1; column <= 10; column++) {
        final cell = quill.container.ownerDocument.createElement('span');
        cell
          ..setAttribute('data-row', '$row')
          ..setAttribute('data-column', '$column')
          ..setAttribute('role', 'button')
          ..setAttribute('aria-label', '$row por $column')
          ..style.cssText = 'width:18px;height:18px;border:1px solid #ccced1;'
              'box-sizing:border-box;background:#fff;';
        cell.addEventListener('mouseenter', (_) => highlight(row, column));
        cell.addEventListener('click', (event) {
          final module = quill.getModule('table');
          if (module is Table) module.insertTable(row, column);
          hide();
          event.preventDefault();
          event.stopPropagation();
        });
        cells.add(cell);
        list.append(cell);
      }
    }
    label = quill.container.ownerDocument.createElement('div');
    label.classes.add('ql-table-select-label');
    label
      ..text = '0 × 0'
      ..style.cssText = 'padding-top:8px;text-align:center;font-size:12px;';
    root
      ..append(list)
      ..append(label);
    toolbar.append(root);
    button.setAttribute('aria-haspopup', 'dialog');
    button.setAttribute('aria-expanded', 'false');
    _button = button;
  }

  final Quill quill;
  final DomElement toolbar;
  final List<DomElement> cells = [];
  late final DomElement root;
  late final DomElement label;
  late final DomElement _button;

  void highlight(int rows, int columns) {
    for (final cell in cells) {
      final row = int.parse(cell.getAttribute('data-row')!);
      final column = int.parse(cell.getAttribute('data-column')!);
      final selected = row <= rows && column <= columns;
      cell.classes.toggle('ql-cell-selected', selected);
      cell.style
        ..setProperty('background-color', selected ? '#2b7cff' : '#fff')
        ..setProperty('border-color', selected ? '#2b7cff' : '#aaa');
    }
    label.text = '$rows × $columns';
  }

  void toggle() => root.classes.contains('ql-hidden') ? show() : hide();

  void show() {
    highlight(0, 0);
    final bounds = domBindings.adapter.getElementBounds(_button);
    if (bounds != null) {
      root.style
        ..left = '${bounds['left']}px'
        ..top = '${(bounds['bottom'] as num).toDouble() + 4}px';
    }
    root.classes.remove('ql-hidden');
    root.style.display = 'block';
    _button.setAttribute('aria-expanded', 'true');
  }

  void hide() {
    root.classes.add('ql-hidden');
    root.style.display = 'none';
    _button.setAttribute('aria-expanded', 'false');
  }
}

void addButton(DomElement container, String format, [dynamic value]) {
  final document = domBindings.adapter.document;
  final input = document.createElement('button');
  input.setAttribute('type', 'button');
  input.classes.add('ql-$format');
  input.setAttribute('aria-pressed', 'false');
  if (value != null) {
    final stringValue = value.toString();
    input.setAttribute('value', stringValue);
    input.setAttribute('aria-label', '$format: $stringValue');
  } else {
    input.setAttribute('aria-label', format);
  }
  input.setAttribute('title', _controlTitle(format, value));
  container.append(input);
}

String _controlTitle(String format, dynamic value) {
  final key = value == null ? format : '$format:$value';
  return const <String, String>{
        'bold': 'Negrito',
        'italic': 'Itálico',
        'underline': 'Sublinhado',
        'strike': 'Tachado',
        'blockquote': 'Citação',
        'code-block': 'Bloco de código',
        'link': 'Inserir link',
        'image': 'Inserir imagem',
        'video': 'Inserir vídeo',
        'formula': 'Inserir fórmula',
        'clean': 'Limpar formatação',
        'table:3x3': 'Inserir tabela',
        'table-row-above': 'Inserir linha acima',
        'table-row-below': 'Inserir linha abaixo',
        'table-column-left': 'Inserir coluna à esquerda',
        'table-column-right': 'Inserir coluna à direita',
        'table-delete-row': 'Excluir linha',
        'table-delete-column': 'Excluir coluna',
        'table-delete': 'Excluir tabela',
        'list:ordered': 'Lista numerada',
        'list:bullet': 'Lista com marcadores',
        'list:check': 'Lista de tarefas',
        'indent:-1': 'Diminuir recuo',
        'indent:+1': 'Aumentar recuo',
        'script:sub': 'Subscrito',
        'script:super': 'Sobrescrito',
        'direction:rtl': 'Direção da direita para a esquerda',
      }[key] ??
      (value == null ? format : '$format: $value');
}

void addControls(DomElement container, ToolbarConfig groups) {
  final document = domBindings.adapter.document;
  // Access the groups property
  final actualGroups = groups.groups;

  actualGroups.forEach((controls) {
    final group = document.createElement('span');
    group.classes.add('ql-formats');
    controls.forEach((control) {
      if (control is String) {
        addButton(group, control);
      } else if (control is Map) {
        final format = control.keys.first;
        final value = control[format];
        if (value is List) {
          addSelect(group, format, value);
        } else {
          addButton(group, format, value);
        }
      }
    });
    container.append(group);
  });
}

void addSelect(DomElement container, String format, List<dynamic> values) {
  final document = domBindings.adapter.document;
  final input = document.createElement('select');
  input.classes.add('ql-$format');
  input.setAttribute('title', _controlTitle(format, null));
  input.setAttribute('aria-label', _controlTitle(format, null));
  values.forEach((value) {
    final option = document.createElement('option');
    if (value != false) {
      option.setAttribute('value', value.toString());
    } else {
      option.setAttribute('selected', 'selected');
    }
    input.append(option);
  });
  container.append(input);
}
