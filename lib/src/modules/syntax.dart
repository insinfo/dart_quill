import 'dart:async';

import '../blots/abstract/blot.dart';
import '../blots/block.dart';
import '../blots/scroll.dart';
import '../blots/break.dart';
import '../blots/cursor.dart';
import '../blots/inline.dart';
import '../blots/text.dart';
import '../core/emitter.dart';
import '../core/module.dart';
import '../core/quill.dart';
import '../dependencies/dart_quill_delta/dart_quill_delta.dart';
import '../formats/abstract/attributor.dart';
import '../formats/code.dart' as code_format;
import '../platform/dom.dart';
import '../platform/platform.dart';
import '../ui/dom_interop.dart' as dom_interop;
import 'clipboard.dart' show Matcher, traverse;

typedef SyntaxHighlighter = Delta Function(String text, String language);

/// Highlighter that returns HTML with `hljs-*` class names, mirroring the
/// contract of highlight.js used by upstream `syntax.ts`.
typedef SyntaxHtmlHighlighter = String Function(String text, String language);

/// Parity syntax.ts:14-16 — `new ClassAttributor('code-token', 'hljs')`.
class TokenAttributor extends ClassAttributor {
  TokenAttributor()
      : super('code-token', 'hljs', const {'scope': Scope.INLINE});
}

final TokenAttributor tokenAttributor = TokenAttributor();

/// Reads a `<select>` value, falling back to the `selected` attribute when the
/// platform has no live DOM (VM tests).
String? readSelectValue(DomElement select) {
  final native = dom_interop.selectValue(select);
  if (native != null) return native;
  for (final option in select.querySelectorAll('option')) {
    if (option.hasAttribute('selected')) {
      return option.getAttribute('value');
    }
  }
  return null;
}

/// Writes a `<select>` value; keeps the `selected` attribute in sync so the
/// fake DOM and serialized HTML agree with the live property.
void writeSelectValue(DomElement select, String value) {
  dom_interop.setSelectValue(select, value);
  for (final option in select.querySelectorAll('option')) {
    if (option.getAttribute('value') == value) {
      option.setAttribute('selected', 'selected');
    } else {
      option.removeAttribute('selected');
    }
  }
}

class SyntaxLanguage {
  const SyntaxLanguage({required this.key, required this.label});

  final String key;
  final String label;
}

class SyntaxOptions {
  SyntaxOptions({
    this.interval = const Duration(milliseconds: 1000),
    List<SyntaxLanguage>? languages,
    this.highlighter,
    this.htmlHighlighter,
  }) : languages = languages ?? Syntax.defaultLanguages;

  factory SyntaxOptions.fromConfig(dynamic options) {
    if (options is SyntaxOptions) {
      return options;
    }
    if (options is Map) {
      final interval = options['interval'];
      final highlighter = options['highlighter'];
      // `hljs` is the upstream option name for an HTML-producing highlighter.
      final htmlHighlighter = options['htmlHighlighter'] ?? options['hljs'];
      return SyntaxOptions(
        interval: interval is int
            ? Duration(milliseconds: interval)
            : interval is Duration
                ? interval
                : const Duration(milliseconds: 1000),
        languages: _resolveLanguages(options['languages']),
        highlighter: highlighter is SyntaxHighlighter ? highlighter : null,
        htmlHighlighter:
            htmlHighlighter is SyntaxHtmlHighlighter ? htmlHighlighter : null,
      );
    }
    return SyntaxOptions();
  }

  final Duration interval;
  final List<SyntaxLanguage> languages;

  /// Dart-native highlighter returning a ready Delta.
  final SyntaxHighlighter? highlighter;

  /// highlight.js-style highlighter returning HTML with `hljs-*` classes.
  final SyntaxHtmlHighlighter? htmlHighlighter;

  static List<SyntaxLanguage>? _resolveLanguages(dynamic value) {
    if (value is List<SyntaxLanguage>) {
      return value;
    }
    if (value is List) {
      return value.whereType<Map>().map((entry) {
        return SyntaxLanguage(
          key: '${entry['key']}',
          label: '${entry['label'] ?? entry['key']}',
        );
      }).toList(growable: false);
    }
    return null;
  }
}

class CodeToken extends InlineBlot {
  CodeToken(DomElement domNode, [dynamic value]) : super(domNode) {
    element.classes.add(kClassName);
    if (value != null && value != false) {
      _setToken(value);
    }
  }

  static const String kBlotName = 'code-token';
  static const String kClassName = 'ql-token';
  static const String kTokenPrefix = 'hljs-';
  static const int kScope = Scope.INLINE_BLOT;

  static CodeToken create([dynamic value]) {
    if (value is DomElement) {
      return CodeToken(value);
    }
    final node = domBindings.adapter.document.createElement('span');
    return CodeToken(node, value);
  }

  @override
  String get blotName => kBlotName;

  @override
  int get scope => kScope;

  @override
  CodeToken clone() => CodeToken(element.cloneNode(deep: false), tokenValue);

  String? get tokenValue {
    final value = tokenAttributor.value(element);
    return value is String && value.isNotEmpty ? value : null;
  }

  @override
  Map<String, dynamic> formats() {
    final value = tokenValue;
    return value == null ? const {} : {kBlotName: value};
  }

  @override
  void format(String name, dynamic value) {
    if (name != kBlotName) {
      super.format(name, value);
      return;
    }
    if (value == null || value == false) {
      _clearToken();
    } else {
      _setToken(value);
    }
  }

  @override
  void optimize([
    List<DomMutationRecord>? mutations,
    Map<String, dynamic>? context,
  ]) {
    super.optimize(mutations, context);
    if (tokenValue == null) {
      element.classes.remove(kClassName);
      unwrap();
    }
  }

  void _setToken(dynamic value) {
    element.classes.add(kClassName);
    tokenAttributor.add(element, value);
  }

  void _clearToken() {
    tokenAttributor.remove(element);
    element.classes.remove(kClassName);
  }
}

class SyntaxCodeBlock extends code_format.CodeBlock {
  SyntaxCodeBlock(DomElement domNode) : super(domNode) {
    element.classes.add(kClassName);
  }

  static const String kBlotName = code_format.CodeBlock.kBlotName;
  static const String kClassName = code_format.CodeBlock.kClassName;
  static const String kTagName = code_format.CodeBlock.kTagName;
  static const int kScope = code_format.CodeBlock.kScope;
  static const Type requiredContainer = SyntaxCodeBlockContainer;
  // Parity syntax.ts — `SyntaxCodeBlock.allowedChildren = [CodeToken, Cursor,
  // TextBlot, Break]`, now a real predicate instead of a dead static list.
  @override
  bool Function(Blot child)? get allowedChildren => (child) =>
      child is CodeToken ||
      child is Cursor ||
      child is TextBlot ||
      child is Break;

  static SyntaxCodeBlock create([dynamic value]) {
    if (value is DomElement) {
      return SyntaxCodeBlock(value);
    }
    final node = domBindings.adapter.document.createElement(kTagName);
    node.classes.add(kClassName);
    if (value is String && value.isNotEmpty) {
      node.setAttribute('data-language', value);
    }
    return SyntaxCodeBlock(node);
  }

  @override
  SyntaxCodeBlock clone() => SyntaxCodeBlock(element.cloneNode(deep: false));

  /// Parity syntax.ts:67-70 — the language is the format value, defaulting to
  /// `plain` so highlighter output and the model delta always compare equal.
  static String languageOf(DomElement node) {
    final language = node.getAttribute('data-language');
    return language == null || language.isEmpty ? 'plain' : language;
  }

  @override
  Map<String, dynamic> formats() => {kBlotName: languageOf(element)};

  @override
  void format(String name, dynamic value) {
    if (name == kBlotName && value != null && value != false) {
      element.setAttribute('data-language', '$value');
      return;
    }
    super.format(name, value);
  }

  /// Parity syntax.ts:83-86 — tokens are meaningless outside a code block, so
  /// strip them before morphing into another blot.
  @override
  Blot replaceWith(String name, [dynamic value]) {
    formatAt(0, length(), CodeToken.kBlotName, false);
    return super.replaceWith(name, value);
  }

  @override
  Blot replaceWithBlot(Blot replacement) {
    formatAt(0, length(), CodeToken.kBlotName, false);
    return super.replaceWithBlot(replacement);
  }
}

class SyntaxCodeBlockContainer extends code_format.CodeBlockContainer {
  SyntaxCodeBlockContainer(DomElement domNode) : super(domNode) {
    element.classes.add(kClassName);
    element.setAttribute('spellcheck', 'false');
  }

  static const String kBlotName = code_format.CodeBlockContainer.kBlotName;
  static const String kClassName = code_format.CodeBlockContainer.kClassName;
  static const String kTagName = code_format.CodeBlockContainer.kTagName;
  static const int kScope = code_format.CodeBlockContainer.kScope;
  bool forceNext = false;
  String? cachedText;

  static SyntaxCodeBlockContainer create([dynamic value]) {
    if (value is DomElement) {
      return SyntaxCodeBlockContainer(value);
    }
    final node = domBindings.adapter.document.createElement(kTagName);
    return SyntaxCodeBlockContainer(node);
  }

  @override
  SyntaxCodeBlockContainer clone() =>
      SyntaxCodeBlockContainer(element.cloneNode(deep: false));

  /// Parity syntax.ts:93-98 — announce the mount so the Syntax module can hang
  /// the language `<select>` on this container.
  @override
  void attach() {
    super.attach();
    forceNext = false;
    final root = scrollOrNull;
    if (root is Scroll) {
      root.emitMount(this);
    }
  }

  @override
  void format(String name, dynamic value) {
    if (name == SyntaxCodeBlock.kBlotName) {
      forceNext = true;
      for (final child in children) {
        child.format(name, value);
      }
      return;
    }
    super.format(name, value);
  }

  @override
  void formatAt(int index, int length, String name, dynamic value) {
    if (name == SyntaxCodeBlock.kBlotName) {
      forceNext = true;
    }
    super.formatAt(index, length, name, value);
  }

  /// Parity syntax.ts:117-154 — recompute the highlighted delta and *apply* it
  /// as a diff of formats, instead of discarding it as the previous port did.
  void highlight(SyntaxHighlighter highlighter, {bool forced = false}) {
    if (children.isEmpty) return;
    final nodes = element.childNodes
        .where((node) => node != uiNode)
        .toList(growable: false);
    final text = '${nodes.map((node) => node.textContent ?? '').join('\n')}\n';
    final language = _language;
    if (!forced && !forceNext && cachedText == text) return;

    if (text.trim().isNotEmpty || cachedText == null) {
      var oldDelta = Delta();
      for (final child in children) {
        if (child is Block) {
          oldDelta = oldDelta.concat(blockDelta(child, filter: false));
        }
      }
      final delta = highlighter(text, language);
      var index = 0;
      for (final op in oldDelta.diff(delta).operations) {
        final retain = op.isRetain ? op.length ?? 0 : 0;
        if (retain == 0) continue;
        final attributes = op.attributes;
        if (attributes != null) {
          for (final format in attributes.keys) {
            if (format == SyntaxCodeBlock.kBlotName ||
                format == CodeToken.kBlotName) {
              formatAt(index, retain, format, attributes[format]);
            }
          }
        }
        index += retain;
      }
    }
    cachedText = text;
    forceNext = false;
  }

  @override
  String html([int index = 0, int length = 0]) {
    final language = _language;
    return '<pre data-language="$language">\n${code_format.escapeText(code(index, length))}\n</pre>';
  }

  /// Parity syntax.ts:167-181 — keep the language `<select>` in sync with the
  /// first child's `data-language`.
  @override
  void optimize([
    List<DomMutationRecord>? mutations,
    Map<String, dynamic>? context,
  ]) {
    super.optimize(mutations, context);
    final ui = uiNode;
    if (parent != null && children.isNotEmpty && ui != null) {
      final language = _language;
      if (readSelectValue(ui) != language) {
        writeSelectValue(ui, language);
      }
    }
  }

  String get _language {
    final first = children.isEmpty ? null : children.first;
    if (first is SyntaxCodeBlock) {
      return SyntaxCodeBlock.languageOf(first.element);
    }
    return 'plain';
  }
}

class Syntax extends Module<SyntaxOptions> {
  Syntax(Quill quill, SyntaxOptions options) : super(quill, options) {
    register(registry: quill.scroll.registry);
    _languages = {
      for (final language in options.languages) language.key: true,
    };
    initListener();
    _listenForOptimize();
  }

  static const List<SyntaxLanguage> defaultLanguages = [
    SyntaxLanguage(key: 'plain', label: 'Plain'),
    SyntaxLanguage(key: 'bash', label: 'Bash'),
    SyntaxLanguage(key: 'cpp', label: 'C++'),
    SyntaxLanguage(key: 'cs', label: 'C#'),
    SyntaxLanguage(key: 'css', label: 'CSS'),
    SyntaxLanguage(key: 'diff', label: 'Diff'),
    SyntaxLanguage(key: 'xml', label: 'HTML/XML'),
    SyntaxLanguage(key: 'java', label: 'Java'),
    SyntaxLanguage(key: 'javascript', label: 'JavaScript'),
    SyntaxLanguage(key: 'markdown', label: 'Markdown'),
    SyntaxLanguage(key: 'php', label: 'PHP'),
    SyntaxLanguage(key: 'python', label: 'Python'),
    SyntaxLanguage(key: 'ruby', label: 'Ruby'),
    SyntaxLanguage(key: 'sql', label: 'SQL'),
  ];

  late final Map<String, bool> _languages;
  Timer? _timer;

  static void register({Registry? registry}) {
    final entries = <RegistryEntry>[
      RegistryEntry(
        blotName: CodeToken.kBlotName,
        scope: CodeToken.kScope,
        tagNames: const ['SPAN'],
        classNames: const [CodeToken.kClassName],
        create: CodeToken.create,
      ),
      RegistryEntry(
        blotName: SyntaxCodeBlockContainer.kBlotName,
        scope: SyntaxCodeBlockContainer.kScope,
        tagNames: const [SyntaxCodeBlockContainer.kTagName],
        classNames: const [SyntaxCodeBlockContainer.kClassName],
        create: SyntaxCodeBlockContainer.create,
      ),
      RegistryEntry(
        blotName: SyntaxCodeBlock.kBlotName,
        scope: SyntaxCodeBlock.kScope,
        tagNames: const [SyntaxCodeBlock.kTagName],
        classNames: const [SyntaxCodeBlock.kClassName],
        create: SyntaxCodeBlock.create,
        requiredContainerBlotName: SyntaxCodeBlockContainer.kBlotName,
      ),
    ];

    if (registry != null) {
      for (final entry in entries) {
        registry.register(entry);
      }
      return;
    }

    for (final entry in entries) {
      Quill.register(entry, true);
    }
  }

  /// Parity syntax.ts:235-258 — every mounted code-block container gets a
  /// language `<select>` as its UI node.
  void initListener() {
    quill.emitter.on(EmitterEvents.SCROLL_BLOT_MOUNT, (dynamic blot) {
      if (blot is! SyntaxCodeBlockContainer) return;
      if (blot.uiNode != null) return;
      final document = quill.root.ownerDocument;
      final select = document.createElement('select');
      for (final language in options.languages) {
        final option = document.createElement('option');
        option.text = language.label;
        option.setAttribute('value', language.key);
        select.append(option);
      }
      select.addEventListener('change', (_) {
        final value = readSelectValue(select) ?? 'plain';
        blot.format(SyntaxCodeBlock.kBlotName, value);
        quill.focus(); // Prevent scrolling
        highlight(blot, true);
      });
      blot.attachUI(select);
      if (blot.children.isNotEmpty) {
        final first = blot.children.first;
        if (first is SyntaxCodeBlock) {
          writeSelectValue(select, SyntaxCodeBlock.languageOf(first.element));
        }
      }
    });
  }

  /// Parity syntax.ts:273-288 — flush pending user edits, re-highlight, then
  /// restore the selection silently so the caret does not jump.
  void highlight([SyntaxCodeBlockContainer? blot, bool force = false]) {
    if (quill.selection.composing) return;
    quill.update(EmitterSource.USER);
    final range = quill.getSelection();
    final targets = blot == null
        ? quill.scroll.descendants<SyntaxCodeBlockContainer>().toList()
        : [blot];
    for (final target in targets) {
      target.highlight(highlightBlot, forced: force);
    }
    quill.update(EmitterSource.SILENT);
    if (range != null) {
      quill.setSelection(range, source: EmitterSource.SILENT);
    }
  }

  Delta highlightBlot(String text, [String language = 'plain']) {
    final normalizedLanguage =
        _languages[language] == true ? language : 'plain';
    if (normalizedLanguage != 'plain') {
      final custom = options.highlighter;
      if (custom != null) {
        return custom(text, normalizedLanguage);
      }
      final htmlHighlighter = options.htmlHighlighter;
      if (htmlHighlighter != null) {
        return _traverseHighlighted(
          htmlHighlighter(text, normalizedLanguage),
          normalizedLanguage,
        );
      }
    }
    return _plainDelta(text, normalizedLanguage);
  }

  /// Parity syntax.ts:302-332 — walk the highlighter's HTML output, turning
  /// `hljs-*` classes into `code-token` formats and newlines into code-block
  /// line breaks.
  Delta _traverseHighlighted(String html, String language) {
    final document = quill.root.ownerDocument;
    final doc = document.parser.parseFromString(
      '<div class="${code_format.CodeBlock.kClassName}">$html</div>',
      'text/html',
    );
    final container = doc.body.firstChild;
    if (container is! DomElement) {
      return _plainDelta(html, language);
    }

    final elementMatchers = <Matcher>[
      (DomNode node, Delta delta, dynamic scroll) {
        if (node is! DomElement) return delta;
        final value = tokenAttributor.value(node);
        if (value != null && value != false && value != '') {
          return delta.compose(
            Delta()..retain(delta.length, {CodeToken.kBlotName: value}),
          );
        }
        return delta;
      },
    ];
    final textMatchers = <Matcher>[
      (DomNode node, Delta delta, dynamic scroll) {
        final lines = (node.textContent ?? '').split('\n');
        var result = delta;
        for (var i = 0; i < lines.length; i += 1) {
          if (i != 0) {
            result.insert('\n', {SyntaxCodeBlock.kBlotName: language});
          }
          if (lines[i].isNotEmpty) {
            result.insert(lines[i]);
          }
        }
        return result;
      },
    ];

    return traverse(
      quill.scroll,
      container,
      elementMatchers,
      textMatchers,
      <DomNode, List<Matcher>>{},
    );
  }

  void _listenForOptimize() {
    quill.emitter.on(EmitterEvents.SCROLL_OPTIMIZE, (_) {
      _timer?.cancel();
      _timer = Timer(options.interval, () {
        _timer = null;
        highlight();
      });
    });
  }

  Delta _plainDelta(String text, String language) {
    final delta = Delta();
    final lines = text.split('\n');
    for (var i = 0; i < lines.length; i++) {
      if (i != 0) {
        delta.insert('\n', {SyntaxCodeBlock.kBlotName: language});
      }
      if (lines[i].isNotEmpty) {
        delta.insert(lines[i]);
      }
    }
    return delta;
  }
}
