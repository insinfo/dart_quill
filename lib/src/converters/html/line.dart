// --- line.dart ---
import 'dart:convert';
import 'lexer.dart';

class Line {
  static const int STATUS_CLEAN = 1;
  static const int STATUS_PICKED = 2;
  static const int STATUS_DONE = 3;

  final int index;
  String _input;
  final Map<String, dynamic> _attributes;
  final DeltaToHtmlConverter _lexer;

  bool _isInline = false;
  bool _isEscaped = false;
  int _status = STATUS_CLEAN;

  final bool _hadEndNewline;
  final bool _hasNewline;

  String output = '';
  final Map<int, String> _prepend = <int, String>{};
  final List<String> _debug = <String>[];

  Line? nextLine;
  Line? prevLine;

  Line(
    this.index,
    String input,
    Map<String, dynamic> attributes,
    this._lexer,
    bool hadEndNewline,
    bool hasNewline,
  )   : _input = input,
        _attributes = attributes,
        _hadEndNewline = hadEndNewline,
        _hasNewline = hasNewline;

  // Getter opcional caso você queira usar line.attributes em debug, etc.
  Map<String, dynamic> get attributes => _attributes;

  bool hasNewline() => _hasNewline;
  bool hasEndNewline() => _hadEndNewline;
  bool isFirst() => previous() == null;
  DeltaToHtmlConverter getLexer() => _lexer;

  String getInput() => isEscaped() ? _input : _lexer.escape(getUnsafeInput());
  String getUnsafeInput() => _input;

  Map<String, dynamic> getAttributes() => _attributes;
  bool hasAttributes() => _attributes.isNotEmpty;

  // DEFAULT = null (mais seguro p/ Dart)
  dynamic getAttribute(String name, [dynamic defaultValue]) {
    return _attributes.containsKey(name) ? _attributes[name] : defaultValue;
  }

  void setInput(String newInput) => _input = newInput;

  void setAsInline() => _isInline = true;
  bool isInline() => _isInline;

  void setAsEscaped() => _isEscaped = true;
  bool isEscaped() => _isEscaped;

  int getIndex() => index;

  void setPicked() => _status = STATUS_PICKED;
  bool isPicked() => _status == STATUS_PICKED;

  void setDone() => _status = STATUS_DONE;
  bool isDone() => _status == STATUS_DONE;

  bool isEmpty() => _input.isEmpty && _prepend.isEmpty;

  bool isJsonInsert() => DeltaToHtmlConverter.isJson(_input);
  dynamic getArrayInsert() => jsonDecode(_input);

  dynamic insertJsonKey(String key) {
    if (!isJsonInsert()) return null;
    final insert = getArrayInsert();
    return (insert is Map && insert.containsKey(key)) ? insert[key] : null;
  }

  void debugInfo(String message) {
    if (_lexer.debug) _debug.add(message);
  }

  List<String> getDebugInfo() => _debug;

  void addPrepend(String value, Line line) {
    _prepend[line.getIndex()] = value;
  }

  String renderPrepend() {
    final keys = _prepend.keys.toList()..sort();
    final seen = <String>{};
    final buffer = StringBuffer();
    for (final k in keys) {
      final v = _prepend[k];
      if (v == null) continue;
      if (seen.add(v)) buffer.write(v);
    }
    return buffer.toString();
  }

  Line? _iterate(Line start, int Function(int) step, bool Function(Line) fn) {
    var i = start.getIndex();
    while (true) {
      i = step(i);
      final el = _lexer.getLine(i);
      if (el == null) return null;
      if (fn(el)) return el;
    }
  }

  Line? next([bool Function(Line)? fn]) {
    if (fn == null) return _lexer.getLine(index + 1);
    return _iterate(this, (i) => i + 1, fn);
  }

  Line? previous([bool Function(Line)? fn]) {
    if (fn == null) return _lexer.getLine(index - 1);
    return _iterate(this, (i) => i - 1, fn);
  }

  void whileNext(bool Function(Line line) condition) {
    var i = index + 1;
    while (true) {
      final line = _lexer.getLine(i);
      if (line == null) break;
      if (!condition(line)) break;
      i++;
    }
  }

  void whilePrevious(bool Function(Line line) condition) {
    var i = index - 1;
    while (true) {
      final line = _lexer.getLine(i);
      if (line == null) break;
      if (!condition(line)) break;
      i--;
    }
  }
}
