/// Grammar primitives of the Dart syntax highlighter.
///
/// The model mirrors highlight.js' mode system — `begin`/`end`/`contains`/
/// `keywords` — because the class names it produces (`hljs-keyword`,
/// `hljs-string`, …) are the ones Quill's Syntax module turns into
/// `code-token` formats. Keeping the shape means a grammar can be transcribed
/// from highlight.js almost literally, and the CSS of any hljs theme applies.
library;

/// A single grammar rule.
class Mode {
  const Mode({
    this.scope,
    this.begin,
    this.beginKeywords,
    this.end,
    this.illegal,
    this.keywords,
    this.keywordPattern,
    this.contains = const [],
    this.variants,
    this.returnBegin = false,
    this.excludeBegin = false,
    this.returnEnd = false,
    this.excludeEnd = false,
    this.endsParent = false,
    this.endsWithParent = false,
    this.subLanguage,
    this.skip = false,
    this.self = false,
  });

  /// The token class, *without* the `hljs-` prefix (`keyword`, `string`, …).
  /// A mode with no scope groups its children without colouring itself.
  final String? scope;

  /// Regex source that opens the mode.
  final String? begin;

  /// Sugar for `begin: r'\b(?:a|b)\b'`.
  final List<String>? beginKeywords;

  /// Regex source that closes the mode. `null` makes it a single-match mode
  /// (it closes right after [begin]).
  final String? end;

  /// Regex source that invalidates the mode; the match is emitted as plain
  /// text and the mode closes, which is how highlight.js keeps a broken
  /// grammar from swallowing the rest of the document.
  final String? illegal;

  /// Keyword class (`keyword`, `built_in`, `literal`, `type`, …) to words.
  final Map<String, List<String>>? keywords;

  /// Regex source used to split text into keyword candidates.
  final String? keywordPattern;

  /// Nested rules.
  final List<Mode> contains;

  /// Alternative forms; each variant inherits the fields it does not set.
  final List<Mode>? variants;

  /// Do not consume the opening match (re-scan it inside the mode).
  final bool returnBegin;

  /// The opening match belongs to the *parent*, not to this mode.
  final bool excludeBegin;

  /// Do not consume the closing match (let the parent see it).
  final bool returnEnd;

  /// The closing match belongs to the parent, not to this mode.
  final bool excludeEnd;

  /// Closing this mode also closes its parent.
  final bool endsParent;

  /// The parent's `end` also closes this mode.
  final bool endsWithParent;

  /// Highlight the mode's content with another language.
  final String? subLanguage;

  /// Match and emit as plain text (used to skip over escapes).
  final bool skip;

  /// `contains: [self]` — a mode nesting itself (bracket/brace nesting).
  final bool self;

  Mode copyWith({
    String? scope,
    String? begin,
    String? end,
    String? illegal,
    List<Mode>? contains,
    bool? returnBegin,
    bool? excludeBegin,
    bool? returnEnd,
    bool? excludeEnd,
    bool? endsParent,
    bool? endsWithParent,
    Map<String, List<String>>? keywords,
    String? keywordPattern,
    String? subLanguage,
    bool? skip,
    bool? self,
    List<String>? beginKeywords,
  }) {
    return Mode(
      scope: scope ?? this.scope,
      begin: begin ?? this.begin,
      beginKeywords: beginKeywords ?? this.beginKeywords,
      end: end ?? this.end,
      illegal: illegal ?? this.illegal,
      keywords: keywords ?? this.keywords,
      keywordPattern: keywordPattern ?? this.keywordPattern,
      contains: contains ?? this.contains,
      returnBegin: returnBegin ?? this.returnBegin,
      excludeBegin: excludeBegin ?? this.excludeBegin,
      returnEnd: returnEnd ?? this.returnEnd,
      excludeEnd: excludeEnd ?? this.excludeEnd,
      endsParent: endsParent ?? this.endsParent,
      endsWithParent: endsWithParent ?? this.endsWithParent,
      subLanguage: subLanguage ?? this.subLanguage,
      skip: skip ?? this.skip,
      self: self ?? this.self,
    );
  }
}

/// A language grammar: the top-level mode plus its aliases.
class Language {
  const Language({
    required this.name,
    this.aliases = const [],
    required this.root,
    this.caseInsensitive = false,
  });

  final String name;
  final List<String> aliases;
  final Mode root;
  final bool caseInsensitive;
}

/// A piece of highlighted text.
///
/// [scope] is the innermost token class without the `hljs-` prefix, or `null`
/// for unhighlighted text. A flat list is exactly what Quill's model needs:
/// `code-token` holds one value per character range.
class HighlightToken {
  const HighlightToken(this.text, [this.scope]);

  final String text;
  final String? scope;

  @override
  String toString() => scope == null ? 'text(${_p(text)})' : '$scope(${_p(text)})';

  static String _p(String value) => value.replaceAll('\n', r'\n');

  @override
  bool operator ==(Object other) =>
      other is HighlightToken && other.text == text && other.scope == scope;

  @override
  int get hashCode => Object.hash(text, scope);
}
