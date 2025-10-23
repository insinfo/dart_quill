import '../core/module.dart';
import '../core/quill.dart';
import '../core/selection.dart';
import '../blots/block.dart';
import '../blots/text.dart';
import '../blots/abstract/blot.dart';
import '../platform/dom.dart';

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
  final DomEvent event;
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
  bool? collapsed;
  bool? empty;
  int? offset;

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
    this.collapsed,
    this.empty,
    this.offset,
  });

  // Helper to set properties from a map, avoiding dynamic invocation issues.
  void setFromMap(Map<String, dynamic> map) {
    if (map.containsKey('key')) key = map['key'];
    if (map.containsKey('shortKey')) shortKey = map['shortKey'];
    if (map.containsKey('shiftKey')) shiftKey = map['shiftKey'];
    if (map.containsKey('altKey')) altKey = map['altKey'];
    if (map.containsKey('metaKey')) metaKey = map['metaKey'];
    if (map.containsKey('ctrlKey')) ctrlKey = map['ctrlKey'];
    if (map.containsKey('prefix')) prefix = map['prefix'];
    if (map.containsKey('suffix')) suffix = map['suffix'];
    if (map.containsKey('format')) format = map['format'];
    if (map.containsKey('handler')) handler = map['handler'];
    if (map.containsKey('collapsed')) collapsed = map['collapsed'];
    if (map.containsKey('empty')) empty = map['empty'];
    if (map.containsKey('offset')) offset = map['offset'];
  }
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
    super.collapsed,
    super.empty,
    super.offset,
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
    addBinding(BindingObject(key: 'Enter', shiftKey: null),
        handler: handleEnter);
    addBinding(
        BindingObject(key: 'Enter', metaKey: null, ctrlKey: null, altKey: null),
        handler: (_) {});

    // Simplified bindings, removing browser-specific checks
    addBinding(BindingObject(key: 'Backspace'),
        context: {'collapsed': true, 'prefix': RegExp(r'.?$',)},
        handler: handleBackspace);
    addBinding(BindingObject(key: 'Delete'),
        context: {'collapsed': true, 'suffix': RegExp(r'.?$',)},
        handler: handleDelete);

    addBinding(BindingObject(key: 'Backspace'),
        context: {'collapsed': false}, handler: handleDeleteRange);
    addBinding(BindingObject(key: 'Delete'),
        context: {'collapsed': false}, handler: handleDeleteRange);
    addBinding(
        BindingObject(
            key: 'Backspace',
            altKey: null,
            ctrlKey: null,
            metaKey: null,
            shiftKey: null),
        context: {'collapsed': true, 'offset': 0},
        handler: handleBackspace);

    listen();
  }

  static bool match(DomEvent evt, BindingObject binding) {
    final event = evt.rawEvent as dynamic;
    // A map to access binding properties by string key
    final bindingMap = {
      'altKey': binding.altKey,
      'ctrlKey': binding.ctrlKey,
      'metaKey': binding.metaKey,
      'shiftKey': binding.shiftKey,
    };

    if (bindingMap.keys.any((key) {
      return (bindingMap[key] != null && bindingMap[key] != event[key]);
    })) {
      return false;
    }
    return binding.key == event.key || binding.key == event.keyCode;
  }

  void addBinding(dynamic keyBinding, {dynamic context, Function? handler}) {
    BindingObject? binding = normalize(keyBinding);
    if (binding == null) {
      // debug.log('Attempted to add invalid keyboard binding', keyBinding);
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
      final event = evt;
      final raw = event.rawEvent as dynamic;
      if (raw.defaultPrevented || raw.isComposing!) return;

      final isComposing =
          raw.keyCode == 229 && (raw.key == 'Enter' || raw.key == 'Backspace');
      if (isComposing) return;

      final matchedBindings = (bindings[raw.key] ?? []).toList();
      if (raw.keyCode != null) {
        matchedBindings.addAll(bindings[raw.keyCode] ?? []);
      }

      final matches = matchedBindings
          .where((binding) => Keyboard.match(event, binding))
          .toList();
      if (matches.isEmpty) return;

      // Placeholder for Quill.find
      // final blot = Quill.find(event.target!, true);
      // if (blot != null && blot.scroll != quill.scroll) return;

      final range = quill.getSelection();
      if (range == null || !quill.hasFocus()) return;

      // Placeholder for quill.getLine, quill.getLeaf
      final line = Block(quill.root.cloneNode()); // Dummy Block
      final offset = 0;
      final leafStart = TextBlot.create(''); // Dummy TextBlot
      final offsetStart = 0;
      final leafEnd = TextBlot.create(''); // Dummy TextBlot
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
        if (binding.collapsed != null &&
            binding.collapsed != curContext.collapsed) return false;
        if (binding.empty != null && binding.empty != curContext.empty)
          return false;
        if (binding.offset != null && binding.offset != curContext.offset)
          return false;

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
        if (binding.suffix != null &&
            !binding.suffix!.hasMatch(curContext.suffix)) return false;

        return binding.handler?.call(range, curContext) != true;
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

  bool isEqual(dynamic a, dynamic b) {
    if (a == b) return true;
    if (a == null || b == null) return false;
    if (a is Map && b is Map) {
      if (a.length != b.length) return false;
      for (final key in a.keys) {
        if (!b.containsKey(key)) return false;
        if (!isEqual(a[key], b[key])) return false;
      }
      return true;
    }
    if (a is List && b is List) {
      if (a.length != b.length) return false;
      for (var i = 0; i < a.length; i++) {
        if (!isEqual(a[i], b[i])) return false;
      }
      return true;
    }
    return false;
  }
}

BindingObject? normalize(dynamic binding) {
  if (binding is String || binding is int) {
    return BindingObject(key: binding);
  } else if (binding is BindingObject) {
    return binding;
  } else if (binding is Map) {
    final newBinding = BindingObject();
    newBinding.setFromMap(binding as Map<String, dynamic>);

    if (newBinding.shortKey == true) {
      newBinding.metaKey = newBinding.shortKey; // Simplified for now
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
