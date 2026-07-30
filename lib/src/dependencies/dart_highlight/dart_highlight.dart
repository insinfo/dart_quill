/// A syntax highlighter written in Dart.
///
/// It replaces the `highlight.js` script Quill's Syntax module expects on
/// `window`: `dart_quill` ships no external assets, so highlighting has to
/// work with nothing but the package itself, on the web *and* on the VM.
///
/// The token classes it produces are highlight.js' (`hljs-keyword`,
/// `hljs-string`, …), which keeps two things true: the `code-token` values in
/// the document model are the ones upstream Quill writes, and any hljs
/// stylesheet — including the one bundled in `assets/quill.syntax.css` —
/// colours the result.
library;

import 'engine.dart';
import 'languages.dart' as grammars;
import 'mode.dart';

export 'mode.dart' show HighlightToken, Language, Mode;

/// Names offered by the highlighter, including aliases.
Iterable<String> get supportedLanguages => grammars.languages.keys;

/// Whether [language] (name or alias) has a grammar.
bool supportsLanguage(String language) =>
    grammars.languages.containsKey(language.toLowerCase());

/// Registers (or replaces) a grammar, so an application can add a language
/// without patching the package.
void registerLanguage(Language language) {
  grammars.languages[language.name] = language;
  for (final alias in language.aliases) {
    grammars.languages[alias] = language;
  }
}

/// Splits [code] into tokens using the grammar of [language].
///
/// An unknown language yields a single unhighlighted token, which is what
/// `plain` does too — never an exception, because this runs on every keystroke
/// inside a code block.
List<HighlightToken> highlight(String code, String language) {
  if (code.isEmpty) return const [];
  final grammar = grammars.languages[language.toLowerCase()];
  if (grammar == null || grammar.root.contains.isEmpty && grammar.root.keywords == null) {
    return [HighlightToken(code)];
  }
  try {
    return tokenize(code, grammar, resolve: _resolve);
  } catch (_) {
    // A grammar bug must not cost the user their code block.
    return [HighlightToken(code)];
  }
}

Language? _resolve(String name) => grammars.languages[name.toLowerCase()];

/// Renders [code] as highlight.js-compatible HTML.
///
/// Provided for parity with `hljs.highlight(...).value`: it is what feeds
/// Quill's HTML-based highlighter hook and the clipboard.
String highlightToHtml(String code, String language) {
  final buffer = StringBuffer();
  for (final token in highlight(code, language)) {
    final text = escapeHtml(token.text);
    if (token.scope == null) {
      buffer.write(text);
    } else {
      buffer.write('<span class="hljs-${token.scope}">$text</span>');
    }
  }
  return buffer.toString();
}

String escapeHtml(String value) => value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');
