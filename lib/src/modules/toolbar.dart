import '../core/module.dart';
import '../core/quill.dart';
import '../core/selection.dart';
import '../blots/abstract/blot.dart';
import 'dart:html';
import 'package:quill_delta/quill_delta.dart';

// Placeholder for logger
class Logger {
  void error(dynamic message) => print('ERROR: $message');
  void log(dynamic message) => print('LOG: $message');
}

final debug = Logger();

// Type definitions
typedef Handler = void Function(dynamic value);

class ToolbarConfig extends List<dynamic> {
  ToolbarConfig() : super();
}

class ToolbarProps {
  final dynamic container; // HTMLElement | ToolbarConfig | null
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

  HtmlElement? container;
  final List<List<dynamic>> controls = []; // [format, input]
  final Map<String, Handler> handlers = {};

  Toolbar(Quill quill, ToolbarProps options) : super(quill, options) {
    if (options.container is ToolbarConfig) {
      final containerDiv = HtmlElement.div();
      containerDiv.setAttribute('role', 'toolbar');
      addControls(containerDiv, options.container as ToolbarConfig);
      quill.container?.parentNode?.insertBefore(containerDiv, quill.container);
      container = containerDiv;
    } else if (options.container is String) {
      container = document.querySelector(options.container as String) as HtmlElement?;
    } else {
      container = options.container as HtmlElement?;
    }

    if (container == null) {
      debug.error('Container required for toolbar', options);
      return;
    }
    container!.classes.add('ql-toolbar');

    if (options.handlers != null) {
      options.handlers!.forEach((format, handler) {
        addHandler(format, handler);
      });
    }

    container!.querySelectorAll('button, select').forEach((input) {
      attach(input as HtmlElement);
    });

    quill.on(Quill.events.EDITOR_CHANGE, (type, range, oldRange, source) {
      if (type == Quill.events.EDITOR_CHANGE) {
        update(range as Range?);
      }
    });
  }

  void addHandler(String format, Handler handler) {
    handlers[format] = handler;
  }

  void attach(HtmlElement input) {
    var format = input.classes.firstWhere((className) => className.startsWith('ql-'), orElse: () => '');
    if (format.isEmpty) return;
    format = format.substring('ql-'.length);

    if (input is ButtonElement) {
      input.setAttribute('type', 'button');
    }

    // Placeholder for quill.scroll.query
    // if (handlers[format] == null && quill.scroll.query(format) == null) {
    //   debug.log('ignoring attaching to nonexistent format', format, input);
    //   return;
    // }

    final eventName = input is SelectElement ? 'change' : 'click';
    input.addEventListener(eventName, (e) {
      dynamic value;
      if (input is SelectElement) {
        if (input.selectedIndex < 0) return;
        final selected = input.options[input.selectedIndex];
        if (selected.hasAttribute('selected')) {
          value = false;
        } else {
          value = selected.value.isNotEmpty ? selected.value : false;
        }
      } else {
        if (input.classes.contains('ql-active')) {
          value = false;
        } else {
          value = input.getAttribute('value') != null ? input.getAttribute('value') : true;
        }
        e.preventDefault();
      }

      quill.focus();
      final range = quill.selection.getRange()[0] as Range?;
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
        //     Quill.sources.USER,
        //   );
        // } else {
          quill.format(format, value, Quill.sources.USER);
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
      final input = pair[1] as HtmlElement;

      if (input is SelectElement) {
        OptionElement? option;
        if (range == null) {
          option = null;
        } else if (formats[format] == null) {
          option = input.querySelector('option[selected]') as OptionElement?;
        } else if (formats[format] is! List) {
          var value = formats[format];
          if (value is String) {
            value = value.replaceAll(RegExp(r'"'), r'\"');
          }
          option = input.querySelector('option[value="$value"]') as OptionElement?;
        }
        if (option == null) {
          input.value = '';
          input.selectedIndex = -1;
        } else {
          option.selected = true;
        }
      } else {
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

void addButton(HtmlElement container, String format, [String? value]) {
  final input = ButtonElement();
  input.setAttribute('type', 'button');
  input.classes.add('ql-$format');
  input.setAttribute('aria-pressed', 'false');
  if (value != null) {
    input.value = value;
    input.setAttribute('aria-label', '$format: $value');
  } else {
    input.setAttribute('aria-label', format);
  }
  container.append(input);
}

void addControls(HtmlElement container, ToolbarConfig groups) {
  // Assuming groups is always a List<List<dynamic>> or List<dynamic>
  final actualGroups = (groups.isNotEmpty && groups[0] is List) ? groups as List<List<dynamic>> : [groups as List<dynamic>];

  actualGroups.forEach((controls) {
    final group = HtmlElement.span();
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

void addSelect(HtmlElement container, String format, List<dynamic> values) {
  final input = SelectElement();
  input.classes.add('ql-$format');
  values.forEach((value) {
    final option = OptionElement();
    if (value != false) {
      option.setAttribute('value', value.toString());
    } else {
      option.setAttribute('selected', 'selected');
    }
    input.append(option);
  });
  container.append(input);
}
