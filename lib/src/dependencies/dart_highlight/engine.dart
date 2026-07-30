/// The tokenizer of the Dart syntax highlighter.
///
/// It walks the source once, keeping a stack of open [Mode]s, and emits a flat
/// list of [HighlightToken]s carrying the innermost token class — the shape
/// Quill's `code-token` format consumes.
library;

import 'mode.dart';

/// Compiled counterpart of a [Mode]: regexes built once per mode tree.
class _CompiledMode {
  _CompiledMode(this.mode, {required bool caseInsensitive})
      : _caseInsensitive = caseInsensitive {
    final begin = mode.beginKeywords != null
        ? r'\b(?:' + mode.beginKeywords!.map(_escape).join('|') + r')\b'
        : mode.begin;
    beginRe = begin == null ? null : _compile(begin);
    endRe = mode.end == null ? null : _compile(mode.end!);
    illegalRe = mode.illegal == null ? null : _compile(mode.illegal!);
    keywordRe = _compile(
      mode.keywordPattern ?? r'[A-Za-z_$][A-Za-z0-9_$]*',
    );
    // Parity with highlight.js: `beginKeywords` doubles as the mode's keyword
    // list, which is what colours the `function`/`class` that opened it.
    final keywords = mode.keywords ??
        (mode.beginKeywords == null
            ? null
            : <String, List<String>>{'keyword': mode.beginKeywords!});
    if (keywords != null) {
      keywordMap = {};
      for (final entry in keywords.entries) {
        for (final word in entry.value) {
          keywordMap![caseInsensitive ? word.toLowerCase() : word] = entry.key;
        }
      }
    }
  }

  final Mode mode;
  final bool _caseInsensitive;

  RegExp? beginRe;
  RegExp? endRe;
  RegExp? illegalRe;
  late RegExp keywordRe;
  Map<String, String>? keywordMap;

  /// Children, resolved lazily so `contains: [self]` cannot recurse forever
  /// while building the tree.
  List<_CompiledMode>? _children;

  List<_CompiledMode> children(_Compiler compiler) {
    final cached = _children;
    if (cached != null) return cached;
    final resolved = <_CompiledMode>[];
    _children = resolved; // break self-reference cycles
    for (final child in mode.contains) {
      if (child.self) {
        resolved.add(this);
        continue;
      }
      for (final variant in _expand(child)) {
        resolved.add(compiler.compile(variant));
      }
    }
    return resolved;
  }

  RegExp _compile(String source) => RegExp(
        source,
        multiLine: true,
        caseSensitive: !_caseInsensitive,
      );

  static Iterable<Mode> _expand(Mode mode) {
    final variants = mode.variants;
    if (variants == null || variants.isEmpty) return [mode];
    return variants.map((variant) => Mode(
          scope: variant.scope ?? mode.scope,
          begin: variant.begin ?? mode.begin,
          beginKeywords: variant.beginKeywords ?? mode.beginKeywords,
          end: variant.end ?? mode.end,
          illegal: variant.illegal ?? mode.illegal,
          keywords: variant.keywords ?? mode.keywords,
          keywordPattern: variant.keywordPattern ?? mode.keywordPattern,
          contains: variant.contains.isEmpty ? mode.contains : variant.contains,
          returnBegin: variant.returnBegin || mode.returnBegin,
          excludeBegin: variant.excludeBegin || mode.excludeBegin,
          returnEnd: variant.returnEnd || mode.returnEnd,
          excludeEnd: variant.excludeEnd || mode.excludeEnd,
          endsParent: variant.endsParent || mode.endsParent,
          endsWithParent: variant.endsWithParent || mode.endsWithParent,
          subLanguage: variant.subLanguage ?? mode.subLanguage,
          skip: variant.skip || mode.skip,
        ));
  }

  static String _escape(String value) =>
      value.replaceAllMapped(RegExp(r'[.*+?^${}()|[\]\\]'), (m) => '\\${m[0]}');
}

class _Compiler {
  _Compiler(this.caseInsensitive);

  final bool caseInsensitive;
  final Map<Mode, _CompiledMode> _cache = {};

  _CompiledMode compile(Mode mode) => _cache.putIfAbsent(
        mode,
        () => _CompiledMode(mode, caseInsensitive: caseInsensitive),
      );
}

/// What kind of terminator matched at a position.
enum _Kind { begin, end, illegal }

class _Candidate {
  _Candidate(this.kind, this.match, this.target);

  final _Kind kind;
  final Match match;

  /// The mode the candidate refers to: the child for [_Kind.begin], the
  /// closing mode for [_Kind.end].
  final _CompiledMode target;
}

/// An open mode on the stack, with the text collected for it.
class _Frame {
  _Frame(this.compiled);

  final _CompiledMode compiled;
  final StringBuffer buffer = StringBuffer();
}

/// Highlights [code] with [language]; [resolve] provides sub-languages.
List<HighlightToken> tokenize(
  String code,
  Language language, {
  Language? Function(String name)? resolve,
}) {
  return _Run(language, resolve).run(code);
}

class _Run {
  _Run(this.language, this._resolve)
      : _compiler = _Compiler(language.caseInsensitive);

  final Language language;
  final Language? Function(String name)? _resolve;
  final _Compiler _compiler;

  final List<HighlightToken> _tokens = [];
  final List<_Frame> _stack = [];

  List<HighlightToken> run(String code) {
    _stack.add(_Frame(_compiler.compile(language.root)));
    var index = 0;
    var guardIndex = -1;
    var guardDepth = -1;

    while (index < code.length) {
      final candidate = _nextCandidate(code, index);
      if (candidate == null) break;

      // Text between the cursor and the terminator belongs to the open mode.
      _stack.last.buffer.write(code.substring(index, candidate.match.start));

      final consumed = _apply(code, candidate);
      final next = consumed < index ? index : consumed;

      // Zero-width terminators (`$`, lookaheads) are legitimate, but two of
      // them in a row with an unchanged stack would spin forever.
      if (next == index && _stack.length == guardDepth && index == guardIndex) {
        _stack.last.buffer.write(code[index]);
        index += 1;
      } else {
        guardIndex = index;
        guardDepth = _stack.length;
        index = next;
      }
    }

    if (index < code.length) {
      _stack.last.buffer.write(code.substring(index));
    }
    // Flush what is still open, outermost last.
    while (_stack.length > 1) {
      _closeFrame(_stack.removeLast());
    }
    _flush(_stack.last);
    return _merge(_tokens);
  }

  /// The leftmost terminator visible from the top of the stack. Ties keep
  /// highlight.js' precedence: children first, then the mode's own end, then
  /// illegal.
  _Candidate? _nextCandidate(String code, int index) {
    final frame = _stack.last;
    final current = frame.compiled;
    _Candidate? best;

    void consider(_Kind kind, RegExp? regex, _CompiledMode target) {
      if (regex == null) return;
      final match = regex.allMatches(code, index).firstOrNull;
      if (match == null) return;
      if (best == null || match.start < best!.match.start) {
        best = _Candidate(kind, match, target);
      }
    }

    for (final child in current.children(_compiler)) {
      consider(_Kind.begin, child.beginRe, child);
    }
    consider(_Kind.end, current.endRe, current);
    // A child declared `endsWithParent` closes when an ancestor closes; the
    // ancestor's end must therefore stay visible from inside it.
    for (var i = _stack.length - 1; i > 0; i--) {
      if (!_stack[i].compiled.mode.endsWithParent) break;
      consider(_Kind.end, _stack[i - 1].compiled.endRe, _stack[i - 1].compiled);
    }
    consider(_Kind.illegal, current.illegalRe, current);
    return best;
  }

  /// Applies [candidate]; returns the new cursor.
  int _apply(String code, _Candidate candidate) {
    final match = candidate.match;
    switch (candidate.kind) {
      case _Kind.begin:
        final child = candidate.target;
        if (child.mode.skip) {
          _stack.last.buffer.write(match[0]!);
          return match.end;
        }
        if (child.mode.returnBegin) {
          _flush(_stack.last); // the parent's text comes first
          _stack.add(_Frame(child));
          return match.start;
        }
        if (child.mode.excludeBegin) {
          _stack.last.buffer.write(match[0]!);
          _flush(_stack.last);
          _stack.add(_Frame(child));
          return match.end;
        }
        _flush(_stack.last);
        final frame = _Frame(child);
        frame.buffer.write(match[0]!);
        _stack.add(frame);
        if (child.endRe == null && child.mode.subLanguage == null) {
          // Single-match mode: it closes as soon as it opened.
          _closeFrame(_stack.removeLast());
          if (child.mode.endsParent && _stack.length > 1) {
            _closeFrame(_stack.removeLast());
          }
        }
        return match.end;

      case _Kind.end:
        // Close everything down to (and including) the mode that ended.
        while (_stack.length > 1 && _stack.last.compiled != candidate.target) {
          _closeFrame(_stack.removeLast());
        }
        if (_stack.length == 1) return match.end; // the root never closes
        final frame = _stack.removeLast();
        if (candidate.target.mode.returnEnd) {
          _closeFrame(frame);
          return match.start;
        }
        if (candidate.target.mode.excludeEnd) {
          _closeFrame(frame);
          _stack.last.buffer.write(match[0]!);
        } else {
          frame.buffer.write(match[0]!);
          _closeFrame(frame);
        }
        if (candidate.target.mode.endsParent && _stack.length > 1) {
          _closeFrame(_stack.removeLast());
        }
        return match.end;

      case _Kind.illegal:
        // Bail out of the mode: emit the offending text unhighlighted so the
        // rest of the document still gets highlighted.
        if (_stack.length > 1) {
          _closeFrame(_stack.removeLast());
        }
        _stack.last.buffer.write(match[0]!);
        return match.end;
    }
  }

  void _closeFrame(_Frame frame) {
    _flush(frame);
  }

  /// Turns a frame's collected text into tokens.
  void _flush(_Frame frame) {
    final text = frame.buffer.toString();
    frame.buffer.clear();
    if (text.isEmpty) return;
    final mode = frame.compiled.mode;

    final subLanguageName = mode.subLanguage;
    if (subLanguageName != null) {
      final sub = _resolve?.call(subLanguageName);
      if (sub != null) {
        _tokens.addAll(tokenize(text, sub, resolve: _resolve));
        return;
      }
    }

    final keywordMap = frame.compiled.keywordMap;
    if (keywordMap == null || keywordMap.isEmpty) {
      _tokens.add(HighlightToken(text, mode.scope));
      return;
    }

    // Keyword pass: the mode's own scope stays as the background, keyword
    // matches override it.
    var cursor = 0;
    for (final match in frame.compiled.keywordRe.allMatches(text)) {
      final word = match[0]!;
      final scope = keywordMap[language.caseInsensitive ? word.toLowerCase() : word];
      if (scope == null) continue;
      if (match.start > cursor) {
        _tokens.add(HighlightToken(text.substring(cursor, match.start), mode.scope));
      }
      _tokens.add(HighlightToken(word, scope));
      cursor = match.end;
    }
    if (cursor < text.length) {
      _tokens.add(HighlightToken(text.substring(cursor), mode.scope));
    }
  }

  /// Adjacent tokens with the same scope become one, which keeps the Delta
  /// this feeds compact (and the diff against the document stable).
  static List<HighlightToken> _merge(List<HighlightToken> tokens) {
    final merged = <HighlightToken>[];
    for (final token in tokens) {
      if (token.text.isEmpty) continue;
      if (merged.isNotEmpty && merged.last.scope == token.scope) {
        merged[merged.length - 1] =
            HighlightToken(merged.last.text + token.text, token.scope);
        continue;
      }
      merged.add(token);
    }
    return merged;
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
