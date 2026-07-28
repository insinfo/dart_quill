import 'dart:math' as math;

import '../blots/abstract/blot.dart';
import '../blots/cursor.dart';
import '../blots/scroll.dart';
import '../dependencies/dart_quill_delta/dart_quill_delta.dart';
import 'emitter.dart';

class Range {
  final int index;
  final int length;

  const Range(this.index, this.length);
}

/// Shifts [range] by a document [change], mirroring `shiftRange` in
/// quill's selection.ts. Positions are transformed through the delta;
/// user-sourced changes at the exact position do not push the caret.
Range shiftRangeByDelta(Range range, Delta change, String source) {
  // JS: transformPosition(pos, priority = source !== 'user'); Dart's `force`
  // is the negation of JS `priority` (force pushes past same-position insert).
  final force = source == EmitterSource.USER;
  final start = change.transformPosition(range.index, force: force);
  final end =
      change.transformPosition(range.index + range.length, force: force);
  return Range(start, math.max(0, end - start));
}

/// Shifts [range] given an edit at [index] adding/removing [shift]
/// characters, mirroring the numeric overload of `shiftRange`.
Range shiftRangeByLength(Range range, int index, int shift, String source) {
  int move(int pos) {
    if (pos < index || (pos == index && source == EmitterSource.USER)) {
      return pos;
    }
    if (shift >= 0) {
      return pos + shift;
    }
    return math.max(index, pos + shift);
  }

  final start = move(range.index);
  final end = move(range.index + range.length);
  return Range(start, math.max(0, end - start));
}

/// Represents bounding rectangle information for an element or range.
class Bounds {
  final double bottom;
  final double height;
  final double left;
  final double right;
  final double top;
  final double width;

  const Bounds({
    required this.bottom,
    required this.height,
    required this.left,
    required this.right,
    required this.top,
    required this.width,
  });
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
    savedRange = range;
    emitter.emit(EmitterEvents.SELECTION_CHANGE, range, previous, source);
    emitter.emit(
      EmitterEvents.EDITOR_CHANGE,
      EmitterEvents.SELECTION_CHANGE,
      range,
      previous,
      source,
    );
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
    savedRange = newRange;
    emitter.emit(EmitterEvents.SCROLL_SELECTION_CHANGE, newRange, previous);
  }

  void clear() {
    if (_range == null) return;
    final previous = _range;
    _range = null;
    emitter.emit(EmitterEvents.SCROLL_SELECTION_CHANGE, null, previous);
    emitter.emit(
      EmitterEvents.EDITOR_CHANGE,
      EmitterEvents.SELECTION_CHANGE,
      null,
      previous,
      EmitterSource.API,
    );
  }

  bool hasFocus() => _range != null;

  void focus() {
    // No direct DOM handling here; the host application is responsible for
    // reflecting focus state in the UI if necessary.
  }

  /// The pending-format marker blot (parity selection.ts `this.cursor`),
  /// created lazily and reused across calls.
  Cursor? _cursor;

  /// Parity selection.ts:157-186.
  ///
  /// With a collapsed selection the format cannot be applied to any existing
  /// text, so a zero-length [Cursor] blot is parked at the caret and formatted
  /// instead — that is the "enable bold, then type" behavior. With a real
  /// range the format is applied directly.
  void format(String name, dynamic value) {
    final range = _range;
    if (range == null) return;
    if (range.length > 0) {
      scroll.formatAt(range.index, range.length, name, value);
      return;
    }
    // Block formats are handled by Quill.formatLine, never by the cursor.
    if (scroll.query(name, Scope.BLOCK) != null) return;

    final scrollBlot = scroll;
    if (scrollBlot is! Scroll) return;
    final leafEntry = scrollBlot.leaf(range.index);
    final leaf = leafEntry.key;
    if (leaf == null) return;

    var cursor = _cursor;
    if (cursor == null) {
      cursor = scrollBlot.create(Cursor.kBlotName) as Cursor;
      _cursor = cursor;
    } else if (cursor.parent != null) {
      cursor.remove();
    }

    final after = leaf.split(leafEntry.value);
    leaf.parent?.insertBefore(cursor, after);
    cursor.format(name, value);
    scroll.optimize([], {});
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
