import '../core/module.dart';
import '../core/quill.dart';
import '../core/selection.dart';
import '../core/emitter.dart';
import '../dependencies/dart_quill_delta/dart_quill_delta.dart';
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

const String SHORTKEY =
    'metaKey'; // Simplified for now, assuming Mac-like behavior

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
        context: {
          'collapsed': true,
          'prefix': RegExp(
            r'.?$',
          )
        },
        handler: handleBackspace);
    addBinding(BindingObject(key: 'Delete'),
        context: {
          'collapsed': true,
          'suffix': RegExp(
            r'.?$',
          )
        },
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

    addBinding(BindingObject(key: 'z', shortKey: true),
        handler: (Range range, Context context) {
      quill.history.undo();
    });
    addBinding(BindingObject(key: 'y', shortKey: true),
        handler: (Range range, Context context) {
      quill.history.redo();
    });
    addBinding(BindingObject(key: 'z', shortKey: true, shiftKey: true),
        handler: (Range range, Context context) {
      quill.history.redo();
    });

    listen();
  }

  static bool match(DomEvent evt, BindingObject binding) {
    if (evt is! DomKeyboardEvent) return false;
    final event = evt;

    if (binding.altKey != null && binding.altKey != event.altKey) return false;
    if (binding.ctrlKey != null && binding.ctrlKey != event.ctrlKey) return false;
    if (binding.metaKey != null && binding.metaKey != event.metaKey) return false;
    if (binding.shiftKey != null && binding.shiftKey != event.shiftKey) return false;

    return binding.key == event.key || binding.key == event.keyCode?.toString();
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

      final lineEntry = quill.getLine(range.index);
      final line = lineEntry.key;
      final lineOffset = lineEntry.value;

      if (line == null || line is! Block) return;

      final leafStartEntry = quill.getLeaf(range.index);
      final leafStart = leafStartEntry.key;
      final offsetStart = leafStartEntry.value;

      final leafEndEntry = range.length == 0
          ? leafStartEntry
          : quill.getLeaf(range.index + range.length);
      final leafEnd = leafEndEntry.key;
      final offsetEnd = leafEndEntry.value;

      final prefixText = (leafStart is TextBlot)
          ? leafStart.value().substring(0, offsetStart)
          : '';
      final suffixText = (leafEnd is TextBlot)
          ? leafEnd.value().substring(offsetEnd)
          : '';

      final curContext = Context(
        collapsed: range.length == 0,
        empty: range.length == 0 && line.length() <= 1,
        format: quill.getFormat(range.index, range.length),
        line: line,
        offset: lineOffset,
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
          if (!(binding.format as List)
              .every((name) => curContext.format[name] == null)) return false;
        } else if (binding.format is Map) {
          if (!(binding.format as Map).keys.every((name) {
            if (binding.format[name] == true)
              return curContext.format[name] != null;
            if (binding.format[name] == false)
              return curContext.format[name] == null;
            return isEqual(binding.format[name], curContext.format[name]);
          })) return false;
        }

        if (binding.prefix != null &&
            !binding.prefix!.hasMatch(curContext.prefix)) return false;
        if (binding.suffix != null &&
            !binding.suffix!.hasMatch(curContext.suffix)) return false;

        final handler = binding.handler;
        if (handler == null) {
          return false;
        }
        return _invokeHandler(handler, range, curContext) != true;
      });

      if (prevented) {
        event.preventDefault();
      }
    });
  }

  void handleBackspace(Range range, Context context) {
    if (range.length > 0) {
      deleteRange(quill: quill, range: range);
      quill.focus();
      return;
    }
    if (range.index <= 0) {
      return;
    }
    final length = _endsWithAstralSymbol(context.prefix) ? 2 : 1;
    final deleteIndex = (range.index - length).clamp(0, range.index);
    quill.updateContents(
      Delta()
        ..retain(deleteIndex)
        ..delete(range.index - deleteIndex),
      source: EmitterSource.USER,
    );
    quill.setSelection(Range(deleteIndex, 0), source: EmitterSource.SILENT);
    quill.focus();
  }

  void handleDelete(Range range, Context context) {
    if (range.length > 0) {
      deleteRange(quill: quill, range: range);
      quill.focus();
      return;
    }
    final length = _startsWithAstralSymbol(context.suffix) ? 2 : 1;
    if (range.index >= quill.scroll.length() - length) {
      return;
    }
    quill.updateContents(
      Delta()
        ..retain(range.index)
        ..delete(length),
      source: EmitterSource.USER,
    );
    quill.setSelection(Range(range.index, 0), source: EmitterSource.SILENT);
    quill.focus();
  }

  void handleDeleteRange(Range range, Context context) {
    deleteRange(quill: quill, range: range);
    quill.focus();
  }

  bool handleEnter(Range range, Context context) {
    if (range.length > 0) {
      quill.deleteText(range.index, range.length, source: EmitterSource.USER);
    }

    final lineFormats = <String, dynamic>{};
    context.format.forEach((name, value) {
      if (quill.scroll.registry.query(name, Scope.BLOCK) != null &&
          value is! List) {
        lineFormats[name] = value;
      }
    });

    quill.insertText(range.index, '\n',
        formats: lineFormats, source: EmitterSource.USER);
    quill.focus();
    return false;
  }

  dynamic _invokeHandler(Function handler, Range range, Context context) {
    try {
      return Function.apply(handler, [range, context]);
    } on NoSuchMethodError {
      return Function.apply(handler, [range]);
    }
  }

  bool _endsWithAstralSymbol(String value) =>
      RegExp(r'[\uD800-\uDBFF][\uDC00-\uDFFF]$').hasMatch(value);

  bool _startsWithAstralSymbol(String value) =>
      RegExp(r'^[\uD800-\uDBFF][\uDC00-\uDFFF]').hasMatch(value);

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
  if (range.length <= 0) {
    return;
  }

  final blockFormats = <String, dynamic>{};
  final lineEntry = quill.scroll.line(range.index);
  final lineBlot = lineEntry.key;
  if (lineBlot != null) {
    final formats = lineBlot.formats();
    formats.forEach((name, value) {
      final definition = quill.scroll.query(name, Scope.BLOCK);
      if (definition != null) {
        blockFormats[name] = value;
      }
    });
  }

  final delta = Delta()
    ..retain(range.index)
    ..delete(range.length);

  quill.updateContents(delta, source: EmitterSource.USER);
  if (blockFormats.isNotEmpty) {
    final targetEntry = quill.scroll.line(range.index);
    final targetLine = targetEntry.key;
    if (targetLine != null) {
      blockFormats.forEach((name, value) {
        targetLine.format(name, value);
      });
      targetLine.optimize();
    }
  }
  quill.setSelection(Range(range.index, 0), source: EmitterSource.SILENT);
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
