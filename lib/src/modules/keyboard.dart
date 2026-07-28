import 'dart:math' as math;

import '../core/module.dart';
import '../core/quill.dart';
import '../core/selection.dart';
import '../core/emitter.dart';
import '../dependencies/dart_quill_delta/dart_quill_delta.dart';
import '../blots/block.dart';
import '../blots/text.dart';
import '../blots/abstract/blot.dart';
import '../platform/dom.dart';
import '../platform/platform.dart';

// Placeholder for logger
class Logger {
  void error(dynamic message) => print('ERROR: $message');
  void log(dynamic message) => print('LOG: $message');
}

final debug = Logger();

/// Parity with keyboard.ts:13 — `/Mac/i.test(navigator.platform)` decides
/// between metaKey (Mac) and ctrlKey (Windows/Linux). Resolved lazily from
/// the platform adapter's userAgent; defaults to ctrlKey when unknown.
bool get isMacPlatform {
  final agent = domBindings.adapter.userAgent?.toLowerCase() ?? '';
  return agent.contains('mac os') ||
      agent.contains('macintosh') ||
      agent.contains('iphone') ||
      agent.contains('ipad');
}

String get SHORTKEY => isMacPlatform ? 'metaKey' : 'ctrlKey';

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

/// Signature of a binding handler written by third-party code:
/// `(range, context) => bool?`. Returning `true` lets the event fall through
/// (no `preventDefault`), anything else swallows it.
typedef BindingHandler = dynamic Function(Range range, Context context);

/// Signature used by the built-in [Keyboard.DEFAULTS] handlers. Parity
/// keyboard.ts, where every default handler runs with `this` bound to the
/// module; Dart has no dynamic `this`, so the module is passed explicitly as
/// the first argument and [Keyboard._invokeHandler] recognizes the arity.
typedef DefaultBindingHandler = dynamic Function(
    Keyboard keyboard, Range range, Context context);

class BindingObject {
  dynamic key;
  bool? shortKey;

  /// Modifier requirements are tri-state, exactly like keyboard.ts:63-72
  /// (`!!binding[key] !== evt[key] && binding[key] !== null`):
  /// * `false` (the default when the field is omitted) — must NOT be pressed;
  /// * `true` — must be pressed;
  /// * `null` — don't care (only when explicitly written as `null`).
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
    this.shiftKey = false,
    this.altKey = false,
    this.metaKey = false,
    this.ctrlKey = false,
    this.prefix,
    this.suffix,
    this.format,
    this.handler,
    this.collapsed,
    this.empty,
    this.offset,
  });

  /// Shallow copy, standing in for the `cloneDeep(binding)` of
  /// keyboard.ts:790. Keeps [Keyboard.DEFAULTS] immune to the mutations
  /// `normalize`/`addBinding` perform (shortKey → platform modifier, context
  /// spread), which would otherwise leak across Quill instances.
  BindingObject copy() => BindingObject(
        key: key,
        shortKey: shortKey,
        shiftKey: shiftKey,
        altKey: altKey,
        metaKey: metaKey,
        ctrlKey: ctrlKey,
        prefix: prefix,
        suffix: suffix,
        format: format,
        handler: handler,
        collapsed: collapsed,
        empty: empty,
        offset: offset,
      );

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
  /// Parity keyboard.ts:357-635 (`defaultOptions`). The port keeps the same
  /// binding names so user options can override or disable them by name, the
  /// way `expandConfig` merges `Keyboard.DEFAULTS` upstream.
  static final KeyboardOptions DEFAULTS = KeyboardOptions(bindings: {
    'bold': makeFormatHandler('bold'),
    'italic': makeFormatHandler('italic'),
    'underline': makeFormatHandler('underline'),
    // Highlight tab, or tab at the beginning of a list/indent/blockquote.
    'indent': BindingObject(
      key: 'Tab',
      format: ['blockquote', 'indent', 'list'],
      handler: _handleIndent,
    ),
    'outdent': BindingObject(
      key: 'Tab',
      shiftKey: true,
      format: ['blockquote', 'indent', 'list'],
      handler: _handleOutdent,
    ),
    'outdent backspace': BindingObject(
      key: 'Backspace',
      collapsed: true,
      shiftKey: null,
      metaKey: null,
      ctrlKey: null,
      altKey: null,
      format: ['indent', 'list'],
      offset: 0,
      handler: _handleOutdentBackspace,
    ),
    'indent code-block': makeCodeBlockHandler(true),
    'outdent code-block': makeCodeBlockHandler(false),
    'remove tab': BindingObject(
      key: 'Tab',
      shiftKey: true,
      collapsed: true,
      prefix: RegExp(r'\t$'),
      handler: _handleRemoveTab,
    ),
    'tab': BindingObject(key: 'Tab', handler: _handleTab),
    'blockquote empty enter': BindingObject(
      key: 'Enter',
      collapsed: true,
      format: ['blockquote'],
      empty: true,
      handler: _handleBlockquoteEmptyEnter,
    ),
    'list empty enter': BindingObject(
      key: 'Enter',
      collapsed: true,
      format: ['list'],
      empty: true,
      handler: _handleListEmptyEnter,
    ),
    'checklist enter': BindingObject(
      key: 'Enter',
      collapsed: true,
      format: {'list': 'checked'},
      handler: _handleChecklistEnter,
    ),
    'header enter': BindingObject(
      key: 'Enter',
      collapsed: true,
      format: ['header'],
      suffix: RegExp(r'^$'),
      handler: _handleHeaderEnter,
    ),
    'table backspace': BindingObject(
      key: 'Backspace',
      format: ['table'],
      collapsed: true,
      offset: 0,
      handler: _handleTableNoop,
    ),
    'table delete': BindingObject(
      key: 'Delete',
      format: ['table'],
      collapsed: true,
      suffix: RegExp(r'^$'),
      handler: _handleTableNoop,
    ),
    'table enter': BindingObject(
      key: 'Enter',
      shiftKey: null,
      format: ['table'],
      handler: _handleTableEnter,
    ),
    'table tab': BindingObject(
      key: 'Tab',
      shiftKey: null,
      format: ['table'],
      handler: _handleTableTab,
    ),
    'list autofill': BindingObject(
      key: ' ',
      shiftKey: null,
      collapsed: true,
      format: {
        'code-block': false,
        'blockquote': false,
        'table': false,
      },
      prefix: RegExp(r'^\s*?(\d+\.|-|\*|\[ ?\]|\[x\])$'),
      handler: _handleListAutofill,
    ),
    'code exit': BindingObject(
      key: 'Enter',
      collapsed: true,
      format: ['code-block'],
      prefix: RegExp(r'^$'),
      suffix: RegExp(r'^\s*$'),
      handler: _handleCodeExit,
    ),
    'embed left': makeEmbedArrowHandler('ArrowLeft', false),
    'embed left shift': makeEmbedArrowHandler('ArrowLeft', true),
    'embed right': makeEmbedArrowHandler('ArrowRight', false),
    'embed right shift': makeEmbedArrowHandler('ArrowRight', true),
    'table down': makeTableArrowHandler(false),
    'table up': makeTableArrowHandler(true),
  });

  Map<dynamic, List<NormalizedBinding>> bindings = {};

  Keyboard(Quill quill, KeyboardOptions options) : super(quill, options) {
    // Parity keyboard.ts:80-86. Upstream `expandConfig` merges the module
    // options over `Keyboard.DEFAULTS` before the module is constructed; the
    // port has no such merge step, so the defaults are folded in here. A user
    // entry with the same name replaces the default, and a falsy value
    // (`null`/`false`) disables it.
    final mergedBindings = <String, dynamic>{
      ...DEFAULTS.bindings,
      ...options.bindings,
    };
    mergedBindings.forEach((name, binding) {
      if (binding == null || binding == false) return;
      addBinding(binding);
    });

    addBinding(BindingObject(key: 'Enter', shiftKey: null),
        handler: handleEnter);
    addBinding(
        BindingObject(key: 'Enter', metaKey: null, ctrlKey: null, altKey: null),
        handler: (_) {});

    // Simplified bindings, removing browser-specific checks
    addBinding(BindingObject(key: 'Backspace'),
        context: {
          'collapsed': true,
          // Parity keyboard.ts:107 — /^.?$/ (anchored: at most one char
          // before the caret in the line).
          'prefix': RegExp(
            r'^.?$',
          )
        },
        handler: handleBackspace);
    addBinding(BindingObject(key: 'Delete'),
        context: {
          'collapsed': true,
          // Parity keyboard.ts:112 — /^.?$/.
          'suffix': RegExp(
            r'^.?$',
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

    // Undo/redo bindings belong to the History module (parity history.ts:27),
    // which registers them via quill.keyboard.addBinding.

    listen();
  }

  static bool match(DomEvent evt, BindingObject binding) {
    if (evt is! DomKeyboardEvent) return false;
    final event = evt;

    if (binding.altKey != null && binding.altKey != event.altKey) return false;
    if (binding.ctrlKey != null && binding.ctrlKey != event.ctrlKey)
      return false;
    if (binding.metaKey != null && binding.metaKey != event.metaKey)
      return false;
    if (binding.shiftKey != null && binding.shiftKey != event.shiftKey)
      return false;

    return binding.key == event.key || binding.key == event.keyCode?.toString();
  }

  /// Parity keyboard.ts:140-171.
  ///
  /// [context] may be a map of extra binding fields **or** a handler function
  /// (upstream `addBinding(key, handler)`); either one is spread over the
  /// normalized binding, so fields the binding already carries survive unless
  /// the context explicitly provides them.
  void addBinding(dynamic keyBinding, {dynamic context, Function? handler}) {
    BindingObject? binding = normalize(keyBinding);
    if (binding == null) {
      debug.error('Attempted to add invalid keyboard binding: $keyBinding');
      return;
    }

    // `context` doubles as the handler slot (keyboard.ts:154-156).
    var resolvedHandler = handler;
    if (context is Function) {
      resolvedHandler ??= context;
      context = null;
    }

    if (context is Map) {
      // Spread semantics: only keys actually present in the map override the
      // binding. Writing `binding.collapsed = context['collapsed']` blindly
      // (as the previous port did) wiped fields declared on the binding
      // itself, which is what `{...binding, ...context}` never does.
      binding.setFromMap(Map<String, dynamic>.from(context));
    } else if (context is BindingObject) {
      if (context.format != null) binding.format = context.format;
      if (context.collapsed != null) binding.collapsed = context.collapsed;
      if (context.empty != null) binding.empty = context.empty;
      if (context.offset != null) binding.offset = context.offset;
      if (context.prefix != null) binding.prefix = context.prefix;
      if (context.suffix != null) binding.suffix = context.suffix;
      if (context.handler != null) binding.handler = context.handler;
    }
    if (resolvedHandler != null) {
      binding.handler = resolvedHandler;
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
    quill.root.addEventListener('keydown', handleKeydown);
  }

  /// Parity keyboard.ts:174-265 (the body of the `keydown` listener), split
  /// out of [listen] so it can be driven without a real DOM event loop.
  /// Returns whether the event was swallowed (`preventDefault`).
  bool handleKeydown(DomEvent event) {
    if (event.defaultPrevented || _isComposing(event)) return false;

    final eventKey = event is DomKeyboardEvent ? event.key : null;
    final eventKeyCode = event is DomKeyboardEvent ? event.keyCode : null;

    // evt.isComposing is false when pressing Enter/Backspace while composing
    // in Safari: https://bugs.webkit.org/show_bug.cgi?id=165004
    if (eventKeyCode == 229 &&
        (eventKey == 'Enter' || eventKey == 'Backspace')) {
      return false;
    }

    final matchedBindings = (bindings[eventKey] ?? []).toList();
    if (eventKeyCode != null) {
      matchedBindings.addAll(bindings[eventKeyCode] ?? []);
    }

    final matches = matchedBindings
        .where((binding) => Keyboard.match(event, binding))
        .toList();
    if (matches.isEmpty) return false;

    // Placeholder for Quill.find
    // final blot = Quill.find(event.target!, true);
    // if (blot != null && blot.scroll != quill.scroll) return false;

    final range = quill.getSelection();
    if (range == null || !quill.hasFocus()) return false;

    final lineEntry = quill.getLine(range.index);
    final line = lineEntry.key;
    final lineOffset = lineEntry.value;

    if (line == null || line is! Block) return false;

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
    final suffixText =
        (leafEnd is TextBlot) ? leafEnd.value().substring(offsetEnd) : '';

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
      if (binding.empty != null && binding.empty != curContext.empty) {
        return false;
      }
      if (binding.offset != null && binding.offset != curContext.offset) {
        return false;
      }

      if (binding.format is List) {
        // Any of the formats must be present.
        if (!(binding.format as List)
            .any((name) => curContext.format[name] != null)) return false;
      } else if (binding.format is Map) {
        // All formats must match.
        if (!(binding.format as Map).keys.every((name) {
          if (binding.format[name] == true) {
            return curContext.format[name] != null;
          }
          if (binding.format[name] == false) {
            return curContext.format[name] == null;
          }
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
    return prevented;
  }

  /// `evt.isComposing` is not part of the [DomEvent] abstraction; the browser
  /// adapter exposes it on the raw event, fakes usually do not.
  bool _isComposing(DomEvent event) {
    // The html adapter exposes `isComposing` on its event wrapper; try that
    // first, then the raw event, and treat "not available" as "not composing".
    for (final candidate in <dynamic>[event, event.rawEvent]) {
      if (candidate == null) continue;
      try {
        final value = candidate.isComposing;
        if (value is bool) return value;
      } catch (_) {
        // Property absent on this implementation; keep looking.
      }
    }
    return false;
  }

  /// Parity keyboard.ts:268-301.
  void handleBackspace(Range range, Context context) {
    if (range.length > 0) {
      deleteRange(quill: quill, range: range);
      quill.focus();
      return;
    }
    // Check for astral symbols.
    final length = _endsWithAstralSymbol(context.prefix) ? 2 : 1;
    if (range.index == 0 || quill.scroll.length() <= 1) {
      return;
    }
    final deleteIndex = math.max(0, range.index - length);
    var formats = <String, dynamic>{};
    final line = quill.getLine(range.index).key;
    var delta = Delta()
      ..retain(deleteIndex)
      ..delete(range.index - deleteIndex);
    if (context.offset == 0 && line != null) {
      // Always deleting a newline here, length is always 1.
      final prev = quill.getLine(range.index - 1).key;
      if (prev != null) {
        final isPrevLineEmpty =
            prev.blotName == Block.kBlotName && prev.length() <= 1;
        if (!isPrevLineEmpty) {
          final curFormats = line.formats();
          final prevFormats = quill.getFormat(range.index - 1, 1);
          formats = Delta.diffAttributes(curFormats, prevFormats) ?? {};
          if (formats.isNotEmpty) {
            // line.length() - 1 targets the \n of the line, another -1 for
            // the newline being deleted.
            final formatDelta = Delta()
              ..retain(math.max(0, range.index + line.length() - 2))
              ..retain(1, formats);
            delta = delta.compose(formatDelta);
          }
        }
      }
    }
    quill.updateContents(delta, source: EmitterSource.USER);
    quill.setSelection(Range(deleteIndex, 0), source: EmitterSource.SILENT);
    quill.focus();
  }

  /// Parity keyboard.ts:303-327.
  void handleDelete(Range range, Context context) {
    if (range.length > 0) {
      deleteRange(quill: quill, range: range);
      quill.focus();
      return;
    }
    // Check for astral symbols.
    final length = _startsWithAstralSymbol(context.suffix) ? 2 : 1;
    if (range.index >= quill.scroll.length() - length) {
      return;
    }
    var formats = <String, dynamic>{};
    final line = quill.getLine(range.index).key;
    final delta = Delta()
      ..retain(range.index)
      ..delete(length);
    if (line != null && context.offset >= line.length() - 1) {
      final next = quill.getLine(range.index + 1).key;
      if (next != null) {
        final curFormats = line.formats();
        final nextFormats = quill.getFormat(range.index, 1);
        formats = Delta.diffAttributes(curFormats, nextFormats) ?? {};
        if (formats.isNotEmpty) {
          delta
            ..retain(math.max(0, next.length() - 1))
            ..retain(1, formats);
        }
      }
    }
    quill.updateContents(delta, source: EmitterSource.USER);
    quill.setSelection(Range(range.index, 0), source: EmitterSource.SILENT);
    quill.focus();
  }

  void handleDeleteRange(Range range, Context context) {
    deleteRange(quill: quill, range: range);
    quill.focus();
  }

  bool handleEnter(Range range, Context context) {
    final lineFormats = <String, dynamic>{};
    context.format.forEach((name, value) {
      if (quill.scroll.registry.query(name, Scope.BLOCK) != null &&
          value is! List) {
        lineFormats[name] = value;
      }
    });

    final delta = Delta()
      ..retain(range.index)
      ..delete(range.length)
      ..insert('\n', lineFormats.isEmpty ? null : lineFormats);
    quill.updateContents(delta, source: EmitterSource.USER);
    quill.setSelection(Range(range.index + 1, 0), source: EmitterSource.SILENT);
    quill.focus();
    return false;
  }

  dynamic _invokeHandler(Function handler, Range range, Context context) {
    // Built-in bindings take the module as their first argument (see
    // [DefaultBindingHandler]); everything else uses the public
    // `(range, context)` shape, with a `(range)` fallback for terser handlers.
    if (handler is DefaultBindingHandler) {
      return handler(this, range, context);
    }
    try {
      return Function.apply(handler, [range, context]);
    } on NoSuchMethodError {
      try {
        return Function.apply(handler, [range]);
      } on NoSuchMethodError {
        return Function.apply(handler, [this, range, context]);
      }
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
  BindingObject? newBinding;
  if (binding is String || binding is int) {
    newBinding = BindingObject(key: binding);
  } else if (binding is BindingObject) {
    // keyboard.ts:790 clones the binding before mutating it; without the copy
    // the shared `Keyboard.DEFAULTS` objects would be rewritten in place.
    newBinding = binding.copy();
  } else if (binding is Map) {
    newBinding = BindingObject();
    newBinding.setFromMap(Map<String, dynamic>.from(binding));
  }
  if (newBinding == null) {
    return null;
  }
  // Parity keyboard.ts:794-797 — shortKey resolves to the platform modifier
  // (metaKey on Mac, ctrlKey elsewhere) before matching.
  if (newBinding.shortKey != null) {
    if (SHORTKEY == 'metaKey') {
      newBinding.metaKey = newBinding.shortKey;
    } else {
      newBinding.ctrlKey = newBinding.shortKey;
    }
    newBinding.shortKey = null;
  }
  return newBinding;
}

/// Parity keyboard.ts:802-815 (`deleteRange`). The surviving line keeps the
/// formats of the *first* line of the range: the diff between the last and
/// the first line formats is re-applied through `formatLine` after the text
/// is deleted, so everything flows through the delta pipeline (and emits
/// TEXT_CHANGE) instead of mutating blots directly.
void deleteRange({required Quill quill, required Range range}) {
  if (range.length <= 0) {
    return;
  }

  final lines = quill.scroll.lines(range.index, range.length);
  var formats = <String, dynamic>{};
  if (lines.length > 1) {
    final firstFormats = lines.first.formats();
    final lastFormats = lines.last.formats();
    formats = Delta.diffAttributes(lastFormats, firstFormats) ?? {};
  }

  // keyboard.ts calls `quill.deleteText(range, USER)`; the port's
  // `Quill.deleteText` forwards to `Editor.deleteText` → `Scroll.deleteAt`,
  // which stops at the first block boundary (only `Editor.update` loops until
  // the whole range is gone), so a multi-line deletion is expressed as a
  // delete op instead. Same event pipeline, same resulting delta.
  quill.updateContents(
    Delta()
      ..retain(range.index)
      ..delete(range.length),
    source: EmitterSource.USER,
  );
  if (formats.isNotEmpty) {
    // `Quill.formatLine` in the port takes a single name/value pair.
    formats.forEach((name, value) {
      quill.formatLine(range.index, 1, name, value,
          source: EmitterSource.USER);
    });
  }
  quill.setSelection(Range(range.index, 0), source: EmitterSource.SILENT);
}

/// Parity keyboard.ts:817-831.
int? tableSide(dynamic table, Blot row, Blot cell, int offset) {
  if (row.prev == null && row.next == null) {
    if (cell.prev == null && cell.next == null) {
      return offset == 0 ? -1 : 1;
    }
    return cell.prev == null ? -1 : 1;
  }
  if (row.prev == null) {
    return -1;
  }
  if (row.next == null) {
    return 1;
  }
  return null;
}

/// Indentation unit of a code block.
///
/// TODO(G3): depende de `CodeBlock.TAB` (fase G5.2) — o formato `code-block`
/// do port ainda não expõe a constante estática usada por keyboard.ts:647.
const String _codeBlockTab = '  ';

bool _isTruthy(dynamic value) =>
    value != null && value != false && value != '';

/// Walks up from [blot] to the enclosing `table-container` blot (the port has
/// no public `module.getTable`, cf. TODO in `_handleTableEnter`).
Blot? _closestTableContainer(Blot? blot) {
  Blot? current = blot;
  while (current != null) {
    if (current.blotName == 'table-container') {
      return current;
    }
    current = current.parent;
  }
  return null;
}

bool _eventShiftKey(DomEvent event) =>
    event is DomKeyboardEvent && event.shiftKey;

/// Parity keyboard.ts:639-681.
BindingObject makeCodeBlockHandler(bool indent) {
  return BindingObject(
    key: 'Tab',
    shiftKey: !indent,
    format: {'code-block': true},
    handler: indent ? _handleCodeBlockIndent : _handleCodeBlockOutdent,
  );
}

dynamic _handleCodeBlockIndent(
        Keyboard keyboard, Range range, Context context) =>
    _handleCodeBlockTab(keyboard, range, context, true);

dynamic _handleCodeBlockOutdent(
        Keyboard keyboard, Range range, Context context) =>
    _handleCodeBlockTab(keyboard, range, context, false);

dynamic _handleCodeBlockTab(
  Keyboard keyboard,
  Range range,
  Context context,
  bool indent,
) {
  final quill = keyboard.quill;
  final tab = _codeBlockTab;
  if (range.length == 0 && !_eventShiftKey(context.event)) {
    quill.insertText(range.index, tab, source: EmitterSource.USER);
    quill.setSelection(Range(range.index + tab.length, 0),
        source: EmitterSource.SILENT);
    return null;
  }

  final lines = range.length == 0
      ? quill.scroll.lines(range.index, 1)
      : quill.scroll.lines(range.index, range.length);
  var index = range.index;
  var length = range.length;
  // keyboard.ts mutates the line blots and then calls `quill.update(USER)`.
  // The port has no `Quill.update`, so the same edit is expressed as a delta
  // (which also keeps history/TEXT_CHANGE correct).
  // TODO(G3): depende de `Quill.update(source)` (fase G2.1) para paridade
  // literal com keyboard.ts:677.
  final delta = Delta();
  var consumed = 0;
  for (var i = 0; i < lines.length; i++) {
    final lineIndex = quill.scroll.offset(lines[i]);
    if (lineIndex < 0) continue;
    if (indent) {
      delta
        ..retain(lineIndex - consumed)
        ..insert(tab);
      consumed = lineIndex;
      if (i == 0) {
        index += tab.length;
      } else {
        length += tab.length;
      }
    } else if (quill.getText(lineIndex, tab.length) == tab) {
      delta
        ..retain(lineIndex - consumed)
        ..delete(tab.length);
      consumed = lineIndex + tab.length;
      if (i == 0) {
        index -= tab.length;
      } else {
        length -= tab.length;
      }
    }
  }
  if (delta.operations.isNotEmpty) {
    quill.updateContents(delta, source: EmitterSource.USER);
  }
  quill.setSelection(Range(math.max(0, index), math.max(0, length)),
      source: EmitterSource.SILENT);
  return null;
}

/// Parity keyboard.ts:683-725.
BindingObject makeEmbedArrowHandler(String key, bool? shiftKey) {
  final binding = BindingObject(
    key: key,
    shiftKey: shiftKey,
    altKey: null,
    handler: key == 'ArrowLeft'
        ? (shiftKey == true ? _handleEmbedLeftShift : _handleEmbedLeft)
        : (shiftKey == true ? _handleEmbedRightShift : _handleEmbedRight),
  );
  if (key == 'ArrowLeft') {
    binding.prefix = RegExp(r'^$');
  } else {
    binding.suffix = RegExp(r'^$');
  }
  return binding;
}

dynamic _handleEmbedLeft(Keyboard keyboard, Range range, Context context) =>
    _handleEmbedArrow(keyboard, range, 'ArrowLeft', false);

dynamic _handleEmbedLeftShift(
        Keyboard keyboard, Range range, Context context) =>
    _handleEmbedArrow(keyboard, range, 'ArrowLeft', true);

dynamic _handleEmbedRight(Keyboard keyboard, Range range, Context context) =>
    _handleEmbedArrow(keyboard, range, 'ArrowRight', false);

dynamic _handleEmbedRightShift(
        Keyboard keyboard, Range range, Context context) =>
    _handleEmbedArrow(keyboard, range, 'ArrowRight', true);

dynamic _handleEmbedArrow(
  Keyboard keyboard,
  Range range,
  String key,
  bool shiftKey,
) {
  final quill = keyboard.quill;
  var index = range.index;
  if (key == 'ArrowRight') {
    index += range.length + 1;
  }
  final leaf = quill.getLeaf(index).key;
  if (leaf is! EmbedBlot) return true;
  if (key == 'ArrowLeft') {
    if (shiftKey) {
      quill.setSelection(Range(math.max(0, range.index - 1), range.length + 1),
          source: EmitterSource.USER);
    } else {
      quill.setSelection(Range(math.max(0, range.index - 1), 0),
          source: EmitterSource.USER);
    }
  } else if (shiftKey) {
    quill.setSelection(Range(range.index, range.length + 1),
        source: EmitterSource.USER);
  } else {
    quill.setSelection(Range(range.index + range.length + 1, 0),
        source: EmitterSource.USER);
  }
  return false;
}

/// Parity keyboard.ts:727-735.
BindingObject makeFormatHandler(String format) {
  return BindingObject(
    key: format[0],
    shortKey: true,
    handler: (Keyboard keyboard, Range range, Context context) {
      keyboard.quill.format(format, !_isTruthy(context.format[format]),
          source: EmitterSource.USER);
      return null;
    },
  );
}

/// Parity keyboard.ts:737-784.
BindingObject makeTableArrowHandler(bool up) {
  return BindingObject(
    key: up ? 'ArrowUp' : 'ArrowDown',
    collapsed: true,
    format: ['table'],
    handler: up ? _handleTableUp : _handleTableDown,
  );
}

dynamic _handleTableUp(Keyboard keyboard, Range range, Context context) =>
    _handleTableArrow(keyboard, context, true);

dynamic _handleTableDown(Keyboard keyboard, Range range, Context context) =>
    _handleTableArrow(keyboard, context, false);

dynamic _handleTableArrow(Keyboard keyboard, Context context, bool up) {
  // TODO move to table module (same note as keyboard.ts:743).
  final quill = keyboard.quill;
  final cell = context.line;
  final row = cell.parent;
  final targetRow = up ? row?.prev : row?.next;
  if (targetRow != null) {
    if (targetRow.blotName == 'table-row' && targetRow is ParentBlot) {
      Blot? targetCell = targetRow.firstChild;
      Blot? cur = cell;
      while (cur?.prev != null && targetCell != null) {
        cur = cur!.prev;
        targetCell = targetCell.next;
      }
      if (targetCell != null) {
        final cellIndex = quill.scroll.offset(targetCell);
        if (cellIndex >= 0) {
          final index = cellIndex +
              math.min<int>(context.offset, targetCell.length() - 1);
          quill.setSelection(Range(math.max<int>(0, index), 0),
              source: EmitterSource.USER);
        }
      }
    }
  } else {
    final table = _closestTableContainer(cell);
    final targetLine = up ? table?.prev : table?.next;
    if (targetLine != null) {
      final lineIndex = quill.scroll.offset(targetLine);
      if (lineIndex >= 0) {
        if (up) {
          quill.setSelection(
              Range(math.max(0, lineIndex + targetLine.length() - 1), 0),
              source: EmitterSource.USER);
        } else {
          quill.setSelection(Range(lineIndex, 0), source: EmitterSource.USER);
        }
      }
    }
  }
  return false;
}

// ---------------------------------------------------------------------------
// Default binding handlers (keyboard.ts:357-635)
// ---------------------------------------------------------------------------

dynamic _handleIndent(Keyboard keyboard, Range range, Context context) {
  if (context.collapsed && context.offset != 0) return true;
  keyboard.quill.format('indent', '+1', source: EmitterSource.USER);
  return false;
}

dynamic _handleOutdent(Keyboard keyboard, Range range, Context context) {
  if (context.collapsed && context.offset != 0) return true;
  keyboard.quill.format('indent', '-1', source: EmitterSource.USER);
  return false;
}

dynamic _handleOutdentBackspace(
    Keyboard keyboard, Range range, Context context) {
  if (context.format['indent'] != null) {
    keyboard.quill.format('indent', '-1', source: EmitterSource.USER);
  } else if (context.format['list'] != null) {
    keyboard.quill.format('list', false, source: EmitterSource.USER);
  }
  return null;
}

dynamic _handleRemoveTab(Keyboard keyboard, Range range, Context context) {
  if (range.index <= 0) return null;
  keyboard.quill.deleteText(range.index - 1, 1, source: EmitterSource.USER);
  return null;
}

dynamic _handleTab(Keyboard keyboard, Range range, Context context) {
  if (_isTruthy(context.format['table'])) return true;
  final quill = keyboard.quill;
  quill.history.cutoff();
  final delta = Delta()
    ..retain(range.index)
    ..delete(range.length)
    ..insert('\t');
  quill.updateContents(delta, source: EmitterSource.USER);
  quill.history.cutoff();
  quill.setSelection(Range(range.index + 1, 0), source: EmitterSource.SILENT);
  return false;
}

dynamic _handleBlockquoteEmptyEnter(
    Keyboard keyboard, Range range, Context context) {
  keyboard.quill.format('blockquote', false, source: EmitterSource.USER);
  return null;
}

dynamic _handleListEmptyEnter(
    Keyboard keyboard, Range range, Context context) {
  keyboard.quill
      .formatLine(range.index, range.length, 'list', false,
          source: EmitterSource.USER);
  if (_isTruthy(context.format['indent'])) {
    keyboard.quill.formatLine(range.index, range.length, 'indent', false,
        source: EmitterSource.USER);
  }
  return null;
}

dynamic _handleChecklistEnter(
    Keyboard keyboard, Range range, Context context) {
  final quill = keyboard.quill;
  final entry = quill.getLine(range.index);
  final line = entry.key;
  final offset = entry.value;
  if (line == null) return null;
  final formats = <String, dynamic>{
    ...line.formats(),
    'list': 'checked',
  };
  final delta = Delta()
    ..retain(range.index)
    ..insert('\n', formats)
    ..retain(math.max(0, line.length() - offset - 1))
    ..retain(1, {'list': 'unchecked'});
  quill.updateContents(delta, source: EmitterSource.USER);
  quill.setSelection(Range(range.index + 1, 0), source: EmitterSource.SILENT);
  // TODO(G3): depende de `Quill.scrollSelectionIntoView` (fase G2.5).
  return null;
}

dynamic _handleHeaderEnter(Keyboard keyboard, Range range, Context context) {
  final quill = keyboard.quill;
  final entry = quill.getLine(range.index);
  final line = entry.key;
  final offset = entry.value;
  if (line == null) return null;
  final delta = Delta()
    ..retain(range.index)
    ..insert('\n', Map<String, dynamic>.from(context.format))
    ..retain(math.max(0, line.length() - offset - 1))
    ..retain(1, {'header': null});
  quill.updateContents(delta, source: EmitterSource.USER);
  quill.setSelection(Range(range.index + 1, 0), source: EmitterSource.SILENT);
  // TODO(G3): depende de `Quill.scrollSelectionIntoView` (fase G2.5).
  return null;
}

/// `handler() {}` upstream: swallows the key inside a table cell
/// (keyboard.ts:493-506).
dynamic _handleTableNoop(Keyboard keyboard, Range range, Context context) =>
    null;

dynamic _handleTableEnter(Keyboard keyboard, Range range, Context context) {
  final quill = keyboard.quill;
  // TODO(G3): depende de `module.getTable(range)` público no módulo table
  // (fase G3.4); enquanto isso o trio table/row/cell é derivado da própria
  // linha do contexto, que é a célula.
  final cell = context.line;
  final row = cell.parent;
  final table = _closestTableContainer(cell);
  if (row == null || table == null) return null;
  final shift = tableSide(table, row, cell, context.offset);
  if (shift == null) return null;
  var index = quill.scroll.offset(table);
  if (index < 0) return null;
  if (shift < 0) {
    final delta = Delta()
      ..retain(index)
      ..insert('\n');
    quill.updateContents(delta, source: EmitterSource.USER);
    quill.setSelection(Range(range.index + 1, range.length),
        source: EmitterSource.SILENT);
  } else if (shift > 0) {
    index += table.length();
    final delta = Delta()
      ..retain(index)
      ..insert('\n');
    quill.updateContents(delta, source: EmitterSource.USER);
    quill.setSelection(Range(index, 0), source: EmitterSource.USER);
  }
  return null;
}

dynamic _handleTableTab(Keyboard keyboard, Range range, Context context) {
  final quill = keyboard.quill;
  final cell = context.line;
  final offset = quill.scroll.offset(cell);
  if (offset < 0) return null;
  if (_eventShiftKey(context.event)) {
    quill.setSelection(Range(math.max(0, offset - 1), 0),
        source: EmitterSource.USER);
  } else {
    quill.setSelection(Range(offset + cell.length(), 0),
        source: EmitterSource.USER);
  }
  return null;
}

dynamic _handleListAutofill(Keyboard keyboard, Range range, Context context) {
  final quill = keyboard.quill;
  if (quill.scroll.query('list', Scope.ANY) == null) return true;
  final length = context.prefix.length;
  final entry = quill.getLine(range.index);
  final line = entry.key;
  final offset = entry.value;
  if (line == null || offset > length) return true;
  String value;
  switch (context.prefix.trim()) {
    case '[]':
    case '[ ]':
      value = 'unchecked';
      break;
    case '[x]':
      value = 'checked';
      break;
    case '-':
    case '*':
      value = 'bullet';
      break;
    default:
      value = 'ordered';
  }
  quill.insertText(range.index, ' ', source: EmitterSource.USER);
  quill.history.cutoff();
  final delta = Delta()
    ..retain(math.max(0, range.index - offset))
    ..delete(length + 1)
    ..retain(math.max(0, line.length() - 2 - offset))
    ..retain(1, {'list': value});
  quill.updateContents(delta, source: EmitterSource.USER);
  quill.history.cutoff();
  quill.setSelection(Range(math.max(0, range.index - length), 0),
      source: EmitterSource.SILENT);
  return false;
}

dynamic _handleCodeExit(Keyboard keyboard, Range range, Context context) {
  final quill = keyboard.quill;
  final entry = quill.getLine(range.index);
  final line = entry.key;
  final offset = entry.value;
  if (line == null) return true;
  var numLines = 2;
  Blot? cur = line;
  while (cur != null &&
      cur.length() <= 1 &&
      _isTruthy(cur.formats()['code-block'])) {
    cur = cur.prev;
    numLines -= 1;
    // Requisite prev lines are empty.
    if (numLines <= 0) {
      final delta = Delta()
        ..retain(math.max(0, range.index + line.length() - offset - 2))
        ..retain(1, {'code-block': null})
        ..delete(1);
      quill.updateContents(delta, source: EmitterSource.USER);
      quill.setSelection(Range(math.max(0, range.index - 1), 0),
          source: EmitterSource.SILENT);
      return false;
    }
  }
  return true;
}
