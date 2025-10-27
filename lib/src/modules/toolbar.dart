import '../core/module.dart';
import '../core/quill.dart';
import '../core/selection.dart';
import '../core/emitter.dart';
import '../platform/platform.dart';
import '../platform/dom.dart';

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

    // Placeholder for quill.scroll.query
    // if (handlers[format] == null && quill.scroll.query(format) == null) {
    //   debug.log('ignoring attaching to nonexistent format', format, input);
    //   return;
    // }

    // Determine if this is a select element or button
    final isSelect = input.tagName.toLowerCase() == 'select';
    final eventName = isSelect ? 'change' : 'click';

    input.addEventListener(eventName, (e) {
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

      quill.focus();
      final range = quill.selection.getRange();
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
        quill.format(format, value, source: EmitterSource.USER);
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

    quill.focus();
    final range = quill.selection.getRange();
    if (range == null) {
      return;
    }

    final handler = handlers[format];
    if (handler != null) {
      handler(resolvedValue);
    } else {
      quill.format(format, resolvedValue, source: EmitterSource.USER);
    }

    update(range);
  }

  void _registerBuiltInHandlers() {
    if (!handlers.containsKey('clean')) {
      addHandler('clean', (_) {
        final range = quill.getSelection();
        if (range == null) return;
        if (range.length == 0) {
          final formats = quill.getFormat(range.index, range.length);
          for (final entry in formats.entries) {
            quill.format(entry.key, false, source: EmitterSource.USER);
          }
        } else {
          final formats = quill.getFormat(range.index, range.length);
          for (final entry in formats.entries) {
            quill.formatText(range.index, range.length, entry.key, false,
                source: EmitterSource.USER);
          }
        }
      });
    }

    if (!handlers.containsKey('direction')) {
      addHandler('direction', (value) {
        final range = quill.getSelection();
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
        final range = quill.getSelection();
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
        final range = quill.getSelection();
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
        final range = quill.getSelection();
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
  container.append(input);
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
