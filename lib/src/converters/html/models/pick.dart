// --- pick.dart ---
import 'dart:core';
import '../line.dart';
import '../listener.dart';

/// Pick Object holds the line which is picked with optional data.
class Pick {
  final Line line;
  final Listener listener;
  final Map<String, dynamic> _options;
  final int _index;

  Map<String, dynamic> get options => _options;

  Pick(this.listener, this.line, this._options, this._index);

  /// Return the value of an option if available
  dynamic optionValue(String name, [dynamic defaultValue]) {
    return _options.containsKey(name) ? _options[name] : defaultValue;
  }

  /// Whether current pick is the first pick inside the list of picks.
  bool get isFirst => _index == 0;

  /// Whether current pick is the last pick inside the list of picks.
  bool get isLast => (listener.picks.length - 1) == _index;
}
