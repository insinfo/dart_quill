import 'dart:async';

import '../blots/abstract/blot.dart';
import '../blots/break.dart';
import '../blots/cursor.dart';
import '../blots/inline.dart';
import '../blots/text.dart';
import '../core/emitter.dart';
import '../core/module.dart';
import '../core/quill.dart';
import '../dependencies/dart_quill_delta/dart_quill_delta.dart';
import '../formats/code.dart' as code_format;
import '../platform/dom.dart';
import '../platform/platform.dart';

typedef SyntaxHighlighter = Delta Function(String text, String language);

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
  }) : languages = languages ?? Syntax.defaultLanguages;

  factory SyntaxOptions.fromConfig(dynamic options) {
    if (options is SyntaxOptions) {
      return options;
    }
    if (options is Map) {
      final interval = options['interval'];
      final highlighter = options['highlighter'];
      return SyntaxOptions(
        interval: interval is int
            ? Duration(milliseconds: interval)
            : interval is Duration
                ? interval
                : const Duration(milliseconds: 1000),
        languages: _resolveLanguages(options['languages']),
        highlighter: highlighter is SyntaxHighlighter ? highlighter : null,
      );
    }
    return SyntaxOptions();
  }

  final Duration interval;
  final List<SyntaxLanguage> languages;
  final SyntaxHighlighter? highlighter;

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
    for (final token in element.classes.values) {
      if (token.startsWith(kTokenPrefix)) {
        return token.substring(kTokenPrefix.length);
      }
    }
    return null;
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
    _clearToken();
    element.classes.add(kClassName);
    element.classes.add('$kTokenPrefix$value');
  }

  void _clearToken() {
    for (final token in element.classes.values.toList(growable: false)) {
      if (token.startsWith(kTokenPrefix)) {
        element.classes.remove(token);
      }
    }
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
  static final List<Type> allowedChildren = [
    CodeToken,
    Cursor,
    TextBlot,
    Break,
  ];

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

  @override
  Map<String, dynamic> formats() {
    final language = element.getAttribute('data-language');
    return {kBlotName: language == null || language.isEmpty ? true : language};
  }

  @override
  void format(String name, dynamic value) {
    if (name == kBlotName && value != null && value != false) {
      element.setAttribute('data-language', '$value');
      return;
    }
    super.format(name, value);
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
  static final List<Type> allowedChildren = [SyntaxCodeBlock];

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

  void highlight(SyntaxHighlighter highlighter, {bool forced = false}) {
    final text = '${children.map((child) => child.value()).join('\n')}\n';
    final language = _language;
    if (forced || forceNext || cachedText != text) {
      highlighter(text, language);
      cachedText = text;
      forceNext = false;
    }
  }

  @override
  String html(int index, int length) {
    final language = _language;
    return '<pre data-language="$language">\n${code_format.escapeText(code(index, length))}\n</pre>';
  }

  String get _language {
    final first = children.isEmpty ? null : children.first;
    if (first is SyntaxCodeBlock) {
      final value = first.formats()[SyntaxCodeBlock.kBlotName];
      if (value is String && value.isNotEmpty) {
        return value;
      }
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

  void highlight([SyntaxCodeBlockContainer? blot, bool force = false]) {
    final targets = blot == null
        ? quill.scroll.descendants<SyntaxCodeBlockContainer>().toList()
        : [blot];
    for (final target in targets) {
      target.highlight(highlightBlot, forced: force);
    }
  }

  Delta highlightBlot(String text, [String language = 'plain']) {
    final normalizedLanguage =
        _languages[language] == true ? language : 'plain';
    final custom = options.highlighter;
    if (custom != null && normalizedLanguage != 'plain') {
      return custom(text, normalizedLanguage);
    }
    return _plainDelta(text, normalizedLanguage);
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
