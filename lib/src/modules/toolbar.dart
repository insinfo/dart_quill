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
  final dynamic container; // DomElement | String selector | ToolbarConfig | null
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

  DomElement? container;
  final List<List<dynamic>> controls = []; // [format, input]
  final Map<String, Handler> handlers = {};

  Toolbar(Quill quill, ToolbarProps options) : super(quill, options) {
    final document = domBindings.adapter.document;
    
    if (options.container is ToolbarConfig) {
      final containerDiv = document.createElement('div');
      containerDiv.setAttribute('role', 'toolbar');
      addControls(containerDiv, options.container as ToolbarConfig);
      quill.container?.parentNode?.insertBefore(containerDiv, quill.container);
      container = containerDiv;
    } else if (options.container is String) {
      container = document.querySelector(options.container as String) as DomElement?;
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

    container!.querySelectorAll('button, select').forEach((input) {
      attach(input as DomElement);
    });

    quill.on(EmitterEvents.EDITOR_CHANGE, (type, range, oldRange, source) {
      if (type == EmitterEvents.EDITOR_CHANGE) {
        update(range as Range?);
      }
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
          value = (optionValue != null && optionValue.isNotEmpty) ? optionValue : false;
        } else {
          value = false;
        }
      } else {
        // For buttons, check active state
        if (input.classes.contains('ql-active')) {
          value = false;
        } else {
          value = input.getAttribute('value') ?? true;
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
    final formats = range == null ? <String, dynamic>{} : quill.getFormat(range.index, range.length);
    controls.forEach((pair) {
      final format = pair[0] as String;
      final input = pair[1] as DomElement;

      final isSelect = input.tagName.toLowerCase() == 'select';
      
      if (isSelect) {
        // For select elements, update selected option via attributes
        DomElement? option;
        if (range == null) {
          option = null;
        } else if (formats[format] == null) {
          option = input.querySelector('option[selected]');
        } else if (formats[format] is! List) {
          var value = formats[format];
          if (value is String) {
            value = value.replaceAll(RegExp(r'"'), r'\"');
          }
          option = input.querySelector('option[value="$value"]');
        }
        
        // Remove all selected attributes first
        input.querySelectorAll('option').forEach((opt) {
          opt.removeAttribute('selected');
        });
        
        // Set selected on the target option
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
          final isActive = value == input.getAttribute('value') ||
              (value != null && value.toString() == input.getAttribute('value')) ||
              (value == null && input.getAttribute('value') == null);
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
}

void addButton(DomElement container, String format, [String? value]) {
  final document = domBindings.adapter.document;
  final input = document.createElement('button');
  input.setAttribute('type', 'button');
  input.classes.add('ql-$format');
  input.setAttribute('aria-pressed', 'false');
  if (value != null) {
    input.setAttribute('value', value);
    input.setAttribute('aria-label', '$format: $value');
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
          addButton(group, format, value as String?);
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
