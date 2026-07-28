import 'dart:math' as math;

import '../blots/abstract/blot.dart';
import '../blots/cursor.dart';
import '../blots/scroll.dart';
import '../dependencies/dart_quill_delta/dart_quill_delta.dart';
import '../platform/dom.dart';
import 'emitter.dart';

class Range {
  final int index;
  final int length;

  const Range(this.index, this.length);
}

class NativePosition {
  const NativePosition(this.node, this.offset);

  final DomNode node;
  final int offset;
}

class NormalizedNativeRange {
  const NormalizedNativeRange({
    required this.start,
    required this.end,
    required this.native,
  });

  final NativePosition start;
  final NativePosition end;
  final DomNativeRange native;
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

  /// Normalize a browser range so each endpoint resolves to a leaf-like DOM
  /// position inside the editor, matching Quill's `normalizeNative`.
  NormalizedNativeRange? normalizeNative(DomNativeRange nativeRange) {
    final root = scroll.element;
    if (!root.contains(nativeRange.startContainer) ||
        (!nativeRange.collapsed && !root.contains(nativeRange.endContainer))) {
      return null;
    }

    NativePosition normalize(DomNode initialNode, int initialOffset) {
      var node = initialNode;
      var offset = initialOffset;
      while (node is! DomText && node.childNodes.isNotEmpty) {
        if (node.childNodes.length > offset) {
          node = node.childNodes[offset];
          offset = 0;
        } else if (node.childNodes.length == offset) {
          node = node.lastChild!;
          if (node is DomText) {
            offset = node.data.length;
          } else if (node.childNodes.isNotEmpty) {
            offset = node.childNodes.length;
          } else {
            offset = node.childNodes.length + 1;
          }
        } else {
          break;
        }
      }
      return NativePosition(node, offset);
    }

    return NormalizedNativeRange(
      start: normalize(nativeRange.startContainer, nativeRange.startOffset),
      end: normalize(nativeRange.endContainer, nativeRange.endOffset),
      native: nativeRange,
    );
  }

  /// Convert a normalized native range to Quill document coordinates.
  Range? normalizedToRange(NormalizedNativeRange range) {
    final positions = <NativePosition>[range.start];
    if (!range.native.collapsed) {
      positions.add(range.end);
    }
    final indexes = <int>[];
    for (final position in positions) {
      final blot = scroll.find(position.node, bubble: true).key;
      if (blot == null) return null;
      final base = scroll.offset(blot);
      if (position.offset == 0) {
        indexes.add(base);
      } else if (blot is LeafBlot) {
        indexes.add(base + blot.index(position.node, position.offset));
      } else {
        indexes.add(base + blot.length());
      }
    }
    final documentEnd = math.max(0, scroll.length() - 1);
    final end = indexes.reduce(math.max).clamp(0, documentEnd);
    final start = indexes.reduce(math.min).clamp(0, end);
    return Range(start, end - start);
  }

  bool _rangesEqual(Range? a, Range? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    return a.index == b.index && a.length == b.length;
  }
}
