import '../core/module.dart';
import '../core/quill.dart';
import '../core/selection.dart';
import '../blots/block.dart';
import '../blots/text.dart';
import '../blots/abstract/blot.dart';
import 'dart:html';
import 'package:quill_delta/quill_delta.dart';

// Placeholder for logger
class Logger {
  void error(dynamic message) => print('ERROR: $message');
  void log(dynamic message) => print('LOG: $message');
}

final debug = Logger();

const String SHORTKEY = 'metaKey'; // Simplified for now, assuming Mac-like behavior

class Context {
  final bool collapsed;
  final bool empty;
  final int offset;
  final String prefix;
  final String suffix;
  final Map<String, dynamic> format;
  final KeyboardEvent event;
  final Block line;

  Context({
    required this.collapsed,
    required this.empty,
    required this.offset,
    required this.prefix,
    required this.suffix,
    required this.format,
    required this.event,
    required this.line,
  });
}

class BindingObject {
  dynamic key;
  bool? shortKey;
  bool? shiftKey;
  bool? altKey;
  bool? metaKey;
  bool? ctrlKey;
  RegExp? prefix;
  RegExp? suffix;
  dynamic format;
  Function? handler;

  BindingObject({
    this.key,
    this.shortKey,
    this.shiftKey,
    this.altKey,
    this.metaKey,
    this.ctrlKey,
    this.prefix,
    this.suffix,
    this.format,
    this.handler,
  });
}

class NormalizedBinding extends BindingObject {
  NormalizedBinding({
    required super.key,
    super.shortKey,
    super.shiftKey,
    super.altKey,
    super.metaKey,
    super.ctrlKey,
    super.prefix,
    super.suffix,
    super.format,
    super.handler,
  });
}

class KeyboardOptions {
  final Map<String, dynamic> bindings;

  KeyboardOptions({
    required this.bindings,
  });
}

class Keyboard extends Module<KeyboardOptions> {
  static final DEFAULTS = KeyboardOptions(bindings: {});

  Map<dynamic, List<NormalizedBinding>> bindings = {};

  Keyboard(Quill quill, KeyboardOptions options) : super(quill, options) {
    // Simplified constructor for now
    // Add default bindings
    addBinding(BindingObject(key: 'Enter', shiftKey: null), handler: handleEnter);
    addBinding(BindingObject(key: 'Enter', metaKey: null, ctrlKey: null, altKey: null), handler: (_) {});

    // Firefox specific bindings
    if (window.navigator.userAgent!.contains(RegExp(r'Firefox', caseSensitive: false))) {
      addBinding(BindingObject(key: 'Backspace'), context: {'collapsed': true}, handler: handleBackspace);
      addBinding(BindingObject(key: 'Delete'), context: {'collapsed': true}, handler: handleDelete);
    } else {
      addBinding(BindingObject(key: 'Backspace'), context: {'collapsed': true, 'prefix': RegExp(r'.?$',)}, handler: handleBackspace);
      addBinding(BindingObject(key: 'Delete'), context: {'collapsed': true, 'suffix': RegExp(r'.?$',)}, handler: handleDelete);
    }
    addBinding(BindingObject(key: 'Backspace'), context: {'collapsed': false}, handler: handleDeleteRange);
    addBinding(BindingObject(key: 'Delete'), context: {'collapsed': false}, handler: handleDeleteRange);
    addBinding(BindingObject(key: 'Backspace', altKey: null, ctrlKey: null, metaKey: null, shiftKey: null), context: {'collapsed': true, 'offset': 0}, handler: handleBackspace);

    listen();
  }

  static bool match(KeyboardEvent evt, BindingObject binding) {
    if ((['altKey', 'ctrlKey', 'metaKey', 'shiftKey'] as List<String>).any((key) {
      // @ts-expect-error
      return (binding[key] != null && binding[key] != evt[key]);
    })) {
      return false;
    }
    return binding.key == evt.key || binding.key == evt.keyCode;
  }

  void addBinding(dynamic keyBinding, {dynamic context, Function? handler}) {
    BindingObject binding = normalize(keyBinding)!;
    if (binding == null) {
      debug.log('Attempted to add invalid keyboard binding', keyBinding);
      return;
    }

    if (context is Map) {
      binding.format = context['format'];
      binding.collapsed = context['collapsed'];
      binding.empty = context['empty'];
      binding.offset = context['offset'];
      binding.prefix = context['prefix'];
      binding.suffix = context['suffix'];
    }
    if (handler != null) {
      binding.handler = handler;
    }

    final keys = binding.key is List ? binding.key as List : [binding.key];
    keys.forEach((key) {
      final singleBinding = NormalizedBinding(
        key: key,
        shortKey: binding.shortKey,
        shiftKey: binding.shiftKey,
        altKey: binding.altKey,
        metaKey: binding.metaKey,
        ctrlKey: binding.ctrlKey,
        prefix: binding.prefix,
        suffix: binding.suffix,
        format: binding.format,
        handler: binding.handler,
        collapsed: binding.collapsed,
        empty: binding.empty,
        offset: binding.offset,
      );
      bindings.putIfAbsent(singleBinding.key, () => []).add(singleBinding);
    });
  }

  void listen() {
    quill.root.addEventListener('keydown', (evt) {
      final event = evt as KeyboardEvent;
      if (event.defaultPrevented || event.isComposing!) return;

      final isComposing = event.keyCode == 229 && (event.key == 'Enter' || event.key == 'Backspace');
      if (isComposing) return;

      final matchedBindings = (bindings[event.key] ?? []).toList();
      if (event.keyCode != null) {
        matchedBindings.addAll(bindings[event.keyCode] ?? []);
      }

      final matches = matchedBindings.where((binding) => Keyboard.match(event, binding)).toList();
      if (matches.isEmpty) return;

      // Placeholder for Quill.find
      // final blot = Quill.find(event.target!, true);
      // if (blot != null && blot.scroll != quill.scroll) return;

      final range = quill.getSelection();
      if (range == null || !quill.hasFocus()) return;

      // Placeholder for quill.getLine, quill.getLeaf
      final line = Block(HtmlElement.div()); // Dummy Block
      final offset = 0;
      final leafStart = TextBlot('', HtmlElement.span()); // Dummy TextBlot
      final offsetStart = 0;
      final leafEnd = TextBlot('', HtmlElement.span()); // Dummy TextBlot
      final offsetEnd = 0;

      final prefixText = leafStart.value().substring(0, offsetStart);
      final suffixText = leafEnd.value().substring(offsetEnd);

      final curContext = Context(
        collapsed: range.length == 0,
        empty: range.length == 0 && line.length() <= 1,
        format: quill.getFormat(range.index, range.length),
        line: line,
        offset: offset,
        prefix: prefixText,
        suffix: suffixText,
        event: event,
      );

      final prevented = matches.any((binding) {
        if (binding.collapsed != null && binding.collapsed != curContext.collapsed) return false;
        if (binding.empty != null && binding.empty != curContext.empty) return false;
        if (binding.offset != null && binding.offset != curContext.offset) return false;

        if (binding.format is List) {
          if (!(binding.format as List).every((name) => curContext.format[name] == null)) return false;
        } else if (binding.format is Map) {
          if (!(binding.format as Map).keys.every((name) {
            if (binding.format[name] == true) return curContext.format[name] != null;
            if (binding.format[name] == false) return curContext.format[name] == null;
            return isEqual(binding.format[name], curContext.format[name]);
          })) return false;
        }

        if (binding.prefix != null && !binding.prefix!.hasMatch(curContext.prefix)) return false;
        if (binding.suffix != null && !binding.suffix!.hasMatch(curContext.suffix)) return false;

        return binding.handler?.call(this, range, curContext, binding) != true;
      });

      if (prevented) {
        event.preventDefault();
      }
    });
  }

  void handleBackspace(Range range, Context context) {
    // Placeholder
  }

  void handleDelete(Range range, Context context) {
    // Placeholder
  }

  void handleDeleteRange(Range range) {
    deleteRange(quill: quill, range: range);
    quill.focus();
  }

  void handleEnter(Range range, Context context) {
    // Placeholder
  }
}

BindingObject? normalize(dynamic binding) {
  if (binding is String || binding is int) {
    return BindingObject(key: binding);
  } else if (binding is Map) {
    final newBinding = BindingObject();
    binding.forEach((key, value) {
      // @ts-expect-error
      newBinding[key] = value;
    });
    if (newBinding.shortKey != null) {
      // @ts-expect-error
      newBinding[SHORTKEY] = newBinding.shortKey;
      newBinding.shortKey = null;
    }
    return newBinding;
  }
  return null;
}

void deleteRange({required Quill quill, required Range range}) {
  // Placeholder
}

int? tableSide(dynamic table, Blot row, Blot cell, int offset) {
  // Placeholder
  return null;
}

BindingObject makeCodeBlockHandler(bool indent) {
  return BindingObject(); // Placeholder
}

BindingObject makeEmbedArrowHandler(String key, bool? shiftKey) {
  return BindingObject(); // Placeholder
}

BindingObject makeFormatHandler(String format) {
  return BindingObject(); // Placeholder
}

BindingObject makeTableArrowHandler(bool up) {
  return BindingObject(); // Placeholder
}
