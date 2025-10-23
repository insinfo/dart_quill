import '../blots/abstract/blot.dart';
import 'emitter.dart';

class Range {
  final int index;
  final int length;

  const Range(this.index, this.length);
}

/// Selection model decoupled from the browser DOM. UI integrations can
/// observe selection-change events and synchronise native selections when
/// needed. This keeps the core editor logic platform agnostic.
class Selection {
  Selection(this.scroll, this.emitter);

  final ScrollBlot scroll;
  final Emitter emitter;

  Range? _range;
  Range? savedRange;
  bool composing = false;

  Range? getRange() => _range;

  void setSelection(Range range, String source) {
    if (_rangesEqual(_range, range)) {
      return;
    }
    final previous = _range;
    _range = range;
    emitter.emit(EmitterEvents.SELECTION_CHANGE, [range, previous, source]);
  }

  Map<String, dynamic> getFormat(int index, [int length = 0]) {
    final range = Range(index, length);
    return scroll.getFormat(range.index, range.length);
  }

  void setRange(int index, int length) {
    final documentLength = scroll.length();
    final normalizedIndex = index.clamp(0, documentLength);
    final normalizedLength = length.clamp(0, documentLength - normalizedIndex);
    final newRange = Range(normalizedIndex, normalizedLength);
    if (_rangesEqual(_range, newRange)) {
      return;
    }
    final previous = _range;
    _range = newRange;
    emitter.emit(EmitterEvents.SCROLL_SELECTION_CHANGE, [newRange, previous]);
  }

  void clear() {
    if (_range == null) return;
    final previous = _range;
    _range = null;
    emitter.emit(EmitterEvents.SCROLL_SELECTION_CHANGE, [null, previous]);
  }

  bool hasFocus() => _range != null;

  void focus() {
    // No direct DOM handling here; the host application is responsible for
    // reflecting focus state in the UI if necessary.
  }

  void format(String name, dynamic value) {
    final range = _range;
    if (range == null || range.length == 0) {
      return;
    }
    scroll.formatAt(range.index, range.length, name, value);
  }

  Map<String, int>? getNativeRange() {
    final range = _range;
    if (range == null) return null;
    return {'index': range.index, 'length': range.length};
  }

  bool _rangesEqual(Range? a, Range? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    return a.index == b.index && a.length == b.length;
  }
}
