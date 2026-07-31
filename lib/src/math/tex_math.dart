/// A LaTeX math renderer written in Dart.
///
/// It replaces the KaTeX script upstream Quill's `formula` format requires on
/// `window`: `dart_quill` ships no external assets, so a formula has to render
/// with nothing but the package itself.
///
/// The output is MathML, which browsers lay out natively — no font files and
/// no stylesheet to load, and the same string can be produced on the VM (for
/// tests, HTML export and DOCX/PDF conversion).
///
/// Failure behaves like `katex.render(..., {throwOnError: false})`: the source
/// is returned marked up in the error colour instead of throwing, so a typo in
/// a formula never takes the editor down.
library;

import 'symbols.dart';

export 'symbols.dart' show AtomKind;

/// Thrown internally when the source cannot be parsed. Callers of
/// [texToMathML] never see it — they get the error markup instead.
class MathSyntaxError implements Exception {
  MathSyntaxError(this.message, [this.position]);

  final String message;
  final int? position;

  @override
  String toString() => position == null
      ? 'MathSyntaxError: $message'
      : 'MathSyntaxError: $message (at $position)';
}

const String _mathmlNamespace = 'http://www.w3.org/1998/Math/MathML';

/// Greek (and Greek-extended) letters plus the letter-like symbols that TeX
/// treats as identifiers rather than operators.
final RegExp _greekOrLetter =
    RegExp(r'^[A-Za-zͰ-Ͽἀ-῿℀-⅏]$');

/// Combining long solidus overlay — how `\not` strikes through a relation.
const String _combiningSlash = '̸';

/// Non-breaking space, so runs of spaces inside `\text{}` survive layout.
const String _nbsp = ' ';

/// Renders [tex] as a MathML string.
///
/// [displayMode] switches to TeX's display style (centred, full-size limits).
/// [errorColor] is used for the fallback markup.
String texToMathML(
  String tex, {
  bool displayMode = false,
  String errorColor = '#f00',
}) {
  try {
    final body = parseTex(tex);
    final display = displayMode ? 'block' : 'inline';
    return '<math xmlns="$_mathmlNamespace" display="$display">$body</math>';
  } on MathSyntaxError catch (error) {
    return _errorMarkup(tex, errorColor, error.message);
  } catch (error) {
    return _errorMarkup(tex, errorColor, '$error');
  }
}

/// Parses [tex] and returns its MathML body (without the `<math>` wrapper).
///
/// Throws [MathSyntaxError] on invalid input; [texToMathML] is the forgiving
/// entry point.
String parseTex(String tex) {
  final parser = _Parser(tex);
  final body = parser.parseUntilEnd();
  return body;
}

/// Whether [tex] parses cleanly — useful to validate before storing.
bool isValidTex(String tex) {
  try {
    parseTex(tex);
    return true;
  } catch (_) {
    return false;
  }
}

String _errorMarkup(String tex, String color, String message) =>
    '<span class="ql-formula-error" style="color: $color" '
    'title="${escapeXml(message)}">${escapeXml(tex)}</span>';

String escapeXml(String value) => value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');

// ---------------------------------------------------------------------------
// Scanner
// ---------------------------------------------------------------------------

enum _TokKind { command, char, number, open, close, sup, sub, amp, rowSep, eof }

class _Tok {
  const _Tok(this.kind, this.text, this.pos);

  final _TokKind kind;
  final String text;
  final int pos;

  @override
  String toString() => '${kind.name}($text)';
}

class _Scanner {
  _Scanner(this.src);

  final String src;
  int _pos = 0;
  _Tok? _peeked;

  static final RegExp _letters = RegExp(r'[A-Za-z]');
  static final RegExp _digits = RegExp(r'[0-9]');
  static final RegExp _space = RegExp(r'[ \t\r\n]');

  _Tok peek() => _peeked ??= _scan();

  _Tok next() {
    final token = peek();
    _peeked = null;
    return token;
  }

  bool get atEnd => peek().kind == _TokKind.eof;

  /// Reads a brace group verbatim (for `\text{…}`), preserving spaces.
  ///
  /// Must be called with no token buffered, i.e. right after [next].
  String readRawGroup() {
    if (_peeked != null) {
      throw MathSyntaxError('internal: raw group after lookahead', _pos);
    }
    while (_pos < src.length && _space.hasMatch(src[_pos])) {
      _pos++;
    }
    if (_pos >= src.length || src[_pos] != '{') {
      // `\text x` — a single token argument, like TeX allows.
      if (_pos < src.length) {
        final char = src[_pos];
        _pos++;
        return char;
      }
      throw MathSyntaxError('missing argument', _pos);
    }
    _pos++; // consume '{'
    final buffer = StringBuffer();
    var depth = 1;
    while (_pos < src.length) {
      final char = src[_pos];
      if (char == r'\' && _pos + 1 < src.length) {
        // Keep escapes for the few that matter inside text.
        final escaped = src[_pos + 1];
        if (escaped == '{' || escaped == '}' || escaped == r'\') {
          buffer.write(escaped);
          _pos += 2;
          continue;
        }
      }
      if (char == '{') depth++;
      if (char == '}') {
        depth--;
        if (depth == 0) {
          _pos++;
          return buffer.toString();
        }
      }
      buffer.write(char);
      _pos++;
    }
    throw MathSyntaxError('unclosed group', _pos);
  }

  _Tok _scan() {
    while (_pos < src.length && _space.hasMatch(src[_pos])) {
      _pos++;
    }
    if (_pos >= src.length) return _Tok(_TokKind.eof, '', _pos);
    final start = _pos;
    final char = src[_pos];

    if (char == r'\') {
      _pos++;
      if (_pos >= src.length) {
        throw MathSyntaxError('trailing backslash', start);
      }
      if (src[_pos] == r'\') {
        _pos++;
        return _Tok(_TokKind.rowSep, r'\\', start);
      }
      if (_letters.hasMatch(src[_pos])) {
        final buffer = StringBuffer();
        while (_pos < src.length && _letters.hasMatch(src[_pos])) {
          buffer.write(src[_pos]);
          _pos++;
        }
        return _Tok(_TokKind.command, '\\$buffer', start);
      }
      // Single-character command: \, \; \{ \% …
      final symbol = src[_pos];
      _pos++;
      return _Tok(_TokKind.command, '\\$symbol', start);
    }

    switch (char) {
      case '{':
        _pos++;
        return _Tok(_TokKind.open, '{', start);
      case '}':
        _pos++;
        return _Tok(_TokKind.close, '}', start);
      case '^':
        _pos++;
        return _Tok(_TokKind.sup, '^', start);
      case '_':
        _pos++;
        return _Tok(_TokKind.sub, '_', start);
      case '&':
        _pos++;
        return _Tok(_TokKind.amp, '&', start);
    }

    if (_digits.hasMatch(char)) {
      final buffer = StringBuffer();
      while (_pos < src.length && _digits.hasMatch(src[_pos])) {
        buffer.write(src[_pos]);
        _pos++;
      }
      // A decimal point belongs to the number, a period on its own does not.
      if (_pos + 1 < src.length &&
          (src[_pos] == '.' || src[_pos] == ',') &&
          _digits.hasMatch(src[_pos + 1])) {
        buffer.write(src[_pos]);
        _pos++;
        while (_pos < src.length && _digits.hasMatch(src[_pos])) {
          buffer.write(src[_pos]);
          _pos++;
        }
      }
      return _Tok(_TokKind.number, buffer.toString(), start);
    }

    _pos++;
    return _Tok(_TokKind.char, char, start);
  }
}

// ---------------------------------------------------------------------------
// Fragments
// ---------------------------------------------------------------------------

/// One rendered MathML element plus what the parser needs to know about it.
class _Frag {
  _Frag(this.mathml, {this.kind = AtomKind.ord, this.limits = false, this.raw});

  /// A MathML element — always exactly one, which is what `msup` and friends
  /// require of their arguments.
  final String mathml;
  final AtomKind kind;

  /// Scripts attach above/below rather than beside.
  final bool limits;

  /// The plain source of a single symbol, used by `\not`.
  final String? raw;
}

// ---------------------------------------------------------------------------
// Parser
// ---------------------------------------------------------------------------

class _Parser {
  _Parser(String source) : _scanner = _Scanner(source);

  final _Scanner _scanner;

  static const Set<String> _fractions = {
    r'\frac', r'\dfrac', r'\tfrac', r'\cfrac',
  };
  static const Set<String> _binomials = {r'\binom', r'\dbinom', r'\tbinom'};
  static const Set<String> _textCommands = {
    r'\text', r'\textrm', r'\textnormal', r'\mbox',
  };

  String parseUntilEnd() {
    final fragments = _parseList(const {_TokKind.eof});
    final token = _scanner.peek();
    if (token.kind != _TokKind.eof) {
      throw MathSyntaxError('unexpected ${token.text}', token.pos);
    }
    return _join(fragments);
  }

  /// The stops of the list being parsed, so a command that consumes "the rest
  /// of the list" (`\displaystyle`) knows where the rest ends.
  Set<_TokKind> _stops = const {_TokKind.eof};
  Set<String> _stopCommands = const {};

  /// Parses fragments until one of [stops] is at the head (not consumed).
  List<_Frag> _parseList(Set<_TokKind> stops, {Set<String> stopCommands = const {}}) {
    final outerStops = _stops;
    final outerStopCommands = _stopCommands;
    _stops = stops;
    _stopCommands = stopCommands;
    try {
      return _parseListInner(stops, stopCommands);
    } finally {
      _stops = outerStops;
      _stopCommands = outerStopCommands;
    }
  }

  List<_Frag> _parseListInner(Set<_TokKind> stops, Set<String> stopCommands) {
    final fragments = <_Frag>[];
    while (true) {
      final token = _scanner.peek();
      if (stops.contains(token.kind)) break;
      if (token.kind == _TokKind.eof) break;
      if (token.kind == _TokKind.command && stopCommands.contains(token.text)) {
        break;
      }
      // `a \over b` splits the whole list into a fraction.
      if (token.kind == _TokKind.command &&
          (token.text == r'\over' ||
              token.text == r'\atop' ||
              token.text == r'\choose')) {
        _scanner.next();
        final numerator = _join(fragments);
        final denominator =
            _join(_parseList(stops, stopCommands: stopCommands));
        final thickness = token.text == r'\over' ? '' : ' linethickness="0"';
        final fraction = '<mfrac$thickness>'
            '<mrow>$numerator</mrow><mrow>$denominator</mrow></mfrac>';
        return [
          _Frag(token.text == r'\choose' ? _fence('(', fraction, ')') : fraction),
        ];
      }
      fragments.add(_parseAtomWithScripts());
    }
    return fragments;
  }

  _Frag _parseAtomWithScripts() {
    var base = _parseAtom();
    var limits = base.limits;
    String? sup;
    String? sub;
    var primes = 0;

    while (true) {
      final token = _scanner.peek();
      if (token.kind == _TokKind.command && token.text == r'\limits') {
        _scanner.next();
        limits = true;
        continue;
      }
      if (token.kind == _TokKind.command && token.text == r'\nolimits') {
        _scanner.next();
        limits = false;
        continue;
      }
      if (token.kind == _TokKind.char && token.text == "'") {
        _scanner.next();
        primes++;
        continue;
      }
      if (token.kind == _TokKind.sup) {
        if (sup != null) {
          throw MathSyntaxError('double superscript', token.pos);
        }
        _scanner.next();
        sup = _parseAtom().mathml;
        continue;
      }
      if (token.kind == _TokKind.sub) {
        if (sub != null) {
          throw MathSyntaxError('double subscript', token.pos);
        }
        _scanner.next();
        sub = _parseAtom().mathml;
        continue;
      }
      break;
    }

    if (primes > 0) {
      final marks = '<mo>${'′' * primes}</mo>';
      sup = sup == null ? marks : '<mrow>$marks$sup</mrow>';
    }
    if (sup == null && sub == null) return base;

    // Both families take (base, under/sub, over/sup) in that order.
    final scriptTag = sup != null && sub != null
        ? (limits ? 'munderover' : 'msubsup')
        : (sup != null
            ? (limits ? 'mover' : 'msup')
            : (limits ? 'munder' : 'msub'));
    final scripts = sup != null && sub != null ? '$sub$sup' : (sup ?? sub!);
    return _Frag('<$scriptTag>${base.mathml}$scripts</$scriptTag>',
        kind: base.kind);
  }

  /// A single atom: a group, a command or a character.
  _Frag _parseAtom() {
    final token = _scanner.next();
    switch (token.kind) {
      case _TokKind.open:
        final body = _parseList(const {_TokKind.close});
        _expect(_TokKind.close);
        return _Frag(_wrapList(body));
      case _TokKind.command:
        return _parseCommand(token);
      case _TokKind.number:
        return _Frag('<mn>${escapeXml(token.text)}</mn>', kind: AtomKind.ord);
      case _TokKind.char:
        return _parseChar(token);
      case _TokKind.close:
        throw MathSyntaxError('unexpected }', token.pos);
      case _TokKind.sup:
      case _TokKind.sub:
        throw MathSyntaxError('missing base for ${token.text}', token.pos);
      case _TokKind.amp:
        throw MathSyntaxError('& outside an environment', token.pos);
      case _TokKind.rowSep:
        throw MathSyntaxError(r'\\ outside an environment', token.pos);
      case _TokKind.eof:
        throw MathSyntaxError('unexpected end of formula', token.pos);
    }
  }

  _Frag _parseChar(_Tok token) {
    final char = token.text;
    const relations = {'=', '<', '>', ':'};
    const binaries = {'+', '-', '*', '/'};
    const openers = {'(', '['};
    const closers = {')', ']'};

    if (char == '-') {
      return _Frag('<mo>−</mo>', kind: AtomKind.bin, raw: '−');
    }
    if (binaries.contains(char)) {
      return _Frag('<mo>${escapeXml(char)}</mo>', kind: AtomKind.bin, raw: char);
    }
    if (relations.contains(char)) {
      return _Frag('<mo>${escapeXml(char)}</mo>', kind: AtomKind.rel, raw: char);
    }
    if (openers.contains(char)) {
      return _Frag('<mo stretchy="false">$char</mo>', kind: AtomKind.open);
    }
    if (closers.contains(char)) {
      return _Frag('<mo stretchy="false">$char</mo>', kind: AtomKind.close);
    }
    if (char == ',' || char == ';') {
      return _Frag('<mo>$char</mo>', kind: AtomKind.punct);
    }
    if (char == '.') return _Frag('<mo>.</mo>', kind: AtomKind.punct);
    if (char == '|') return _Frag('<mo>|</mo>', kind: AtomKind.ord);
    if (char == '!') return _Frag('<mo>!</mo>', kind: AtomKind.close);
    if (RegExp(r'[A-Za-z]').hasMatch(char)) {
      return _Frag('<mi>$char</mi>', kind: AtomKind.ord, raw: char);
    }
    return _Frag('<mo>${escapeXml(char)}</mo>', kind: AtomKind.ord, raw: char);
  }

  _Frag _parseCommand(_Tok token) {
    final name = token.text;

    // --- fractions ---------------------------------------------------------
    if (_fractions.contains(name)) {
      final numerator = _requiredGroup();
      final denominator = _requiredGroup();
      return _Frag('<mfrac><mrow>$numerator</mrow>'
          '<mrow>$denominator</mrow></mfrac>');
    }
    if (_binomials.contains(name)) {
      final top = _requiredGroup();
      final bottom = _requiredGroup();
      final stack = '<mfrac linethickness="0"><mrow>$top</mrow>'
          '<mrow>$bottom</mrow></mfrac>';
      return _Frag(_fence('(', stack, ')'));
    }

    // --- roots -------------------------------------------------------------
    if (name == r'\sqrt') {
      final index = _optionalGroup();
      final body = _requiredGroup();
      if (index == null) return _Frag('<msqrt>$body</msqrt>');
      return _Frag('<mroot><mrow>$body</mrow><mrow>$index</mrow></mroot>');
    }

    // --- fences ------------------------------------------------------------
    if (name == r'\left') {
      final open = _readDelimiter();
      final body = _parseList(
        const {_TokKind.eof},
        stopCommands: const {r'\right'},
      );
      final closing = _scanner.peek();
      if (closing.kind != _TokKind.command || closing.text != r'\right') {
        throw MathSyntaxError(r'\left without \right', token.pos);
      }
      _scanner.next();
      final close = _readDelimiter();
      return _Frag(_fence(open, _join(body), close, stretchy: true));
    }
    if (name == r'\right') {
      throw MathSyntaxError(r'\right without \left', token.pos);
    }
    if (name == r'\middle') {
      final delimiter = _readDelimiter();
      return _Frag(delimiter.isEmpty
          ? ''
          : '<mo fence="true">${escapeXml(delimiter)}</mo>');
    }

    // --- text --------------------------------------------------------------
    if (_textCommands.contains(name)) {
      final text = _scanner.readRawGroup();
      return _Frag('<mtext>${_preserveSpaces(text)}</mtext>');
    }
    if (name == r'\textbf') {
      final text = _scanner.readRawGroup();
      return _Frag('<mtext mathvariant="bold">${_preserveSpaces(text)}</mtext>');
    }
    if (name == r'\textit' || name == r'\emph') {
      final text = _scanner.readRawGroup();
      return _Frag('<mtext mathvariant="italic">${_preserveSpaces(text)}</mtext>');
    }
    if (name == r'\texttt') {
      final text = _scanner.readRawGroup();
      return _Frag(
          '<mtext mathvariant="monospace">${_preserveSpaces(text)}</mtext>');
    }
    if (name == r'\textsf') {
      final text = _scanner.readRawGroup();
      return _Frag(
          '<mtext mathvariant="sans-serif">${_preserveSpaces(text)}</mtext>');
    }
    if (name == r'\operatorname' || name == r'\operatornamewithlimits') {
      final text = _scanner.readRawGroup();
      return _Frag('<mi mathvariant="normal">${escapeXml(text)}</mi>',
          kind: AtomKind.functionName,
          limits: name == r'\operatornamewithlimits');
    }

    // --- fonts -------------------------------------------------------------
    final variant = texFontVariants[name];
    if (variant != null) {
      final body = _requiredGroup();
      return _Frag('<mstyle mathvariant="$variant">$body</mstyle>');
    }

    // --- accents -----------------------------------------------------------
    final accent = texAccents[name];
    if (accent != null) {
      final body = _requiredGroup();
      final stretchy = name.startsWith(r'\wide') ||
          name == r'\overline' ||
          name == r'\overbrace' ||
          name.startsWith(r'\overright') ||
          name.startsWith(r'\overleft');
      return _Frag('<mover accent="true"><mrow>$body</mrow>'
          '<mo stretchy="$stretchy">${escapeXml(accent)}</mo></mover>');
    }
    final underAccent = texUnderAccents[name];
    if (underAccent != null) {
      final body = _requiredGroup();
      return _Frag('<munder accentunder="true"><mrow>$body</mrow>'
          '<mo stretchy="true">${escapeXml(underAccent)}</mo></munder>');
    }
    if (name == r'\overset' || name == r'\stackrel') {
      final top = _requiredGroup();
      final base = _requiredGroup();
      return _Frag('<mover><mrow>$base</mrow><mrow>$top</mrow></mover>');
    }
    if (name == r'\underset') {
      final bottom = _requiredGroup();
      final base = _requiredGroup();
      return _Frag('<munder><mrow>$base</mrow><mrow>$bottom</mrow></munder>');
    }

    // --- spacing and grouping ---------------------------------------------
    final space = texSpaces[name];
    if (space != null) {
      return _Frag('<mspace width="$space"/>');
    }
    if (name == r'\hspace' || name == r'\mspace' || name == r'\kern') {
      final width = _scanner.readRawGroup();
      return _Frag('<mspace width="${escapeXml(width)}"/>');
    }
    if (name == r'\phantom') {
      final body = _requiredGroup();
      return _Frag('<mphantom>$body</mphantom>');
    }
    if (name == r'\boxed') {
      final body = _requiredGroup();
      return _Frag('<mrow style="padding: 0.15em; border: 1px solid currentColor">'
          '$body</mrow>');
    }
    if (name == r'\textcolor' || name == r'\color') {
      final color = _scanner.readRawGroup();
      final body = name == r'\color' ? '' : _requiredGroup();
      if (body.isEmpty) return _Frag('');
      return _Frag('<mstyle mathcolor="${escapeXml(color)}">$body</mstyle>');
    }
    if (name == r'\displaystyle' ||
        name == r'\textstyle' ||
        name == r'\scriptstyle' ||
        name == r'\scriptscriptstyle') {
      // A style switch applies to the remainder of the group it appears in.
      final display = name == r'\displaystyle';
      final rest = _parseList(_stops, stopCommands: _stopCommands);
      return _Frag('<mstyle displaystyle="$display">${_join(rest)}</mstyle>');
    }
    if (name == r'\not') {
      final next = _parseAtom();
      final raw = next.raw;
      if (raw != null) {
        return _Frag('<mo>${escapeXml(raw)}$_combiningSlash</mo>',
            kind: next.kind);
      }
      return _Frag('<mrow><mo>¬</mo>${next.mathml}</mrow>', kind: next.kind);
    }
    if (name == r'\pmod') {
      final body = _requiredGroup();
      return _Frag('<mrow><mspace width="0.5em"/><mo stretchy="false">(</mo>'
          '<mi mathvariant="normal">mod</mi><mspace width="0.25em"/>'
          '$body<mo stretchy="false">)</mo></mrow>');
    }

    // --- environments ------------------------------------------------------
    if (name == r'\begin') {
      return _parseEnvironment(token);
    }
    if (name == r'\end') {
      throw MathSyntaxError(r'\end without \begin', token.pos);
    }

    // --- symbol tables -----------------------------------------------------
    final symbol = texSymbols[name];
    if (symbol != null) {
      return _renderSymbol(symbol);
    }
    final functionLimits = texFunctionNames[name.substring(1)];
    if (functionLimits != null) {
      return _Frag('<mi mathvariant="normal">${name.substring(1)}</mi>',
          kind: AtomKind.functionName, limits: functionLimits);
    }

    throw MathSyntaxError('unknown command $name', token.pos);
  }

  _Frag _renderSymbol(SymbolDef symbol) {
    final text = escapeXml(symbol.output);
    switch (symbol.kind) {
      case AtomKind.ord:
        // Greek letters are identifiers (`mi`); the rest are operators (`mo`).
        final isLetter = _greekOrLetter.hasMatch(symbol.output);
        return _Frag(
          isLetter ? '<mi>$text</mi>' : '<mo stretchy="false">$text</mo>',
          kind: AtomKind.ord,
          raw: symbol.output,
        );
      case AtomKind.bigOp:
        return _Frag(
          '<mo movablelimits="${symbol.limits}" largeop="true">$text</mo>',
          kind: AtomKind.bigOp,
          limits: symbol.limits,
          raw: symbol.output,
        );
      case AtomKind.open:
      case AtomKind.close:
        return _Frag('<mo stretchy="false">$text</mo>', kind: symbol.kind);
      case AtomKind.functionName:
        return _Frag('<mi mathvariant="normal">$text</mi>', kind: symbol.kind);
      case AtomKind.bin:
      case AtomKind.rel:
      case AtomKind.punct:
        return _Frag('<mo>$text</mo>', kind: symbol.kind, raw: symbol.output);
    }
  }

  /// `\begin{pmatrix} a & b \\ c & d \end{pmatrix}` and friends.
  _Frag _parseEnvironment(_Tok token) {
    final name = _scanner.readRawGroup();
    final definition = texEnvironments[name];
    if (definition == null) {
      throw MathSyntaxError('unknown environment $name', token.pos);
    }
    // `array` takes a column spec, which only affects alignment.
    var alignment = definition[2];
    if (name == 'array') {
      final spec = _scanner.readRawGroup();
      alignment = spec
          .replaceAll(RegExp(r'[^lcr]'), '')
          .split('')
          .map((c) => c == 'l' ? 'left' : (c == 'r' ? 'right' : 'center'))
          .join(' ');
      if (alignment.isEmpty) alignment = 'center';
    }

    final rows = <List<String>>[];
    var cells = <String>[];
    while (true) {
      final body = _parseList(
        const {_TokKind.amp, _TokKind.rowSep, _TokKind.eof},
        stopCommands: const {r'\end'},
      );
      cells.add(_join(body));
      final head = _scanner.peek();
      if (head.kind == _TokKind.amp) {
        _scanner.next();
        continue;
      }
      if (head.kind == _TokKind.rowSep) {
        _scanner.next();
        rows.add(cells);
        cells = <String>[];
        continue;
      }
      if (head.kind == _TokKind.command && head.text == r'\end') {
        _scanner.next();
        final closing = _scanner.readRawGroup();
        if (closing != name) {
          throw MathSyntaxError(
              r'\end{' '$closing' r'} does not match \begin{' '$name}',
              head.pos);
        }
        break;
      }
      throw MathSyntaxError('unclosed environment $name', head.pos);
    }
    // A trailing `\\` must not add an empty row.
    if (cells.length > 1 || (cells.length == 1 && cells.first.isNotEmpty)) {
      rows.add(cells);
    }

    final table = StringBuffer('<mtable columnalign="$alignment">');
    for (final row in rows) {
      table.write('<mtr>');
      for (final cell in row) {
        table.write('<mtd>$cell</mtd>');
      }
      table.write('</mtr>');
    }
    table.write('</mtable>');

    final open = definition[0];
    final close = definition[1];
    if (open.isEmpty && close.isEmpty) {
      return _Frag(table.toString());
    }
    return _Frag(_fence(open, table.toString(), close, stretchy: true));
  }

  /// `\left(` / `\right]` delimiters, including `.` for "no delimiter".
  String _readDelimiter() {
    final token = _scanner.next();
    if (token.kind == _TokKind.char) {
      if (token.text == '.') return '';
      return token.text;
    }
    if (token.kind == _TokKind.command) {
      final symbol = texSymbols[token.text];
      if (symbol != null) return symbol.output;
      throw MathSyntaxError('invalid delimiter ${token.text}', token.pos);
    }
    if (token.kind == _TokKind.open) return '{';
    if (token.kind == _TokKind.close) return '}';
    throw MathSyntaxError('invalid delimiter ${token.text}', token.pos);
  }

  /// A `{…}` argument, or a single atom when the braces are omitted.
  String _requiredGroup() {
    final token = _scanner.peek();
    if (token.kind == _TokKind.eof) {
      throw MathSyntaxError('missing argument', token.pos);
    }
    if (token.kind == _TokKind.open) {
      _scanner.next();
      final body = _parseList(const {_TokKind.close});
      _expect(_TokKind.close);
      return _wrapList(body);
    }
    return _parseAtom().mathml;
  }

  /// An optional `[…]` argument (`\sqrt[3]{x}`).
  String? _optionalGroup() {
    final token = _scanner.peek();
    if (token.kind != _TokKind.char || token.text != '[') return null;
    _scanner.next();
    final fragments = <_Frag>[];
    while (true) {
      final head = _scanner.peek();
      if (head.kind == _TokKind.eof) {
        throw MathSyntaxError('unclosed [', head.pos);
      }
      if (head.kind == _TokKind.char && head.text == ']') {
        _scanner.next();
        break;
      }
      fragments.add(_parseAtomWithScripts());
    }
    return _join(fragments);
  }

  void _expect(_TokKind kind) {
    final token = _scanner.next();
    if (token.kind != kind) {
      throw MathSyntaxError('expected ${kind.name}, got ${token.text}', token.pos);
    }
  }

  static String _join(List<_Frag> fragments) =>
      fragments.map((fragment) => fragment.mathml).join();

  /// One element out of a list: no `<mrow>` around a lone child, since every
  /// fragment is already a single element.
  static String _wrapList(List<_Frag> fragments) {
    if (fragments.isEmpty) return '<mrow></mrow>';
    if (fragments.length == 1) return fragments.first.mathml;
    return '<mrow>${_join(fragments)}</mrow>';
  }

  static String _fence(String open, String body, String close,
      {bool stretchy = false}) {
    final buffer = StringBuffer('<mrow>');
    if (open.isNotEmpty) {
      buffer.write('<mo fence="true" stretchy="$stretchy">'
          '${escapeXml(open)}</mo>');
    }
    buffer.write(body);
    if (close.isNotEmpty) {
      buffer.write('<mo fence="true" stretchy="$stretchy">'
          '${escapeXml(close)}</mo>');
    }
    buffer.write('</mrow>');
    return buffer.toString();
  }

  /// Spaces inside `\text{}` must survive; MathML collapses them otherwise.
  static String _preserveSpaces(String text) =>
      escapeXml(text).replaceAll(' ', _nbsp);
}
