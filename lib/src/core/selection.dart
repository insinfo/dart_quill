import 'dart:async';
import 'dart:math' as math;

import '../blots/abstract/blot.dart';
import '../blots/cursor.dart';
import '../blots/embed.dart' show EmbedContextRange;
import '../blots/scroll.dart';
import '../dependencies/dart_quill_delta/dart_quill_delta.dart';
import '../platform/dom.dart';
import '../platform/platform.dart';
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

/// Port of quill's `core/selection.ts`.
///
/// On the browser (adapter with [DomAdapter.supportsNativeSelection]) this is
/// the upstream native-backed selection: `getRange` reads the live
/// `document.getSelection()`, `setRange` writes it back through
/// `rangeToNative`/`setNativeRange`, `update` reconciles logical state from
/// native and maintains `savedRange` (the last non-null range — what toolbar
/// clicks restore through `focus()`).
///
/// On the VM / fake DOM there is no native selection; the class keeps the
/// logical model this port always had, so headless tests exercise the same
/// public API with a stored range.
class Selection {
  Selection(this.scroll, this.emitter) {
    if (_nativeMode) {
      _handleComposition();
      _handleDragging();
      // Parity selection.ts:64-68.
      emitter.listenDOM('selectionchange', null, (DomEvent event) {
        if (!mouseDown && !composing) {
          Timer(const Duration(milliseconds: 1),
              () => update(EmitterSource.USER));
        }
      });
      // Parity selection.ts:69-102 — carry the native selection across a DOM
      // reconciliation pass, then re-read it.
      emitter.on(EmitterEvents.SCROLL_BEFORE_UPDATE, (dynamic source) {
        if (!hasFocus()) return;
        final native = getNativeRange();
        if (native == null) return;
        if (native.start.node == _cursor?.textNode) return;
        emitter.once(EmitterEvents.SCROLL_UPDATE,
            (dynamic updateSource, dynamic mutations) {
          try {
            if (root.contains(native.start.node) &&
                root.contains(native.end.node)) {
              setNativeRange(
                native.start.node,
                native.start.offset,
                native.end.node,
                native.end.offset,
              );
            }
            final records = mutations is List ? mutations : const <dynamic>[];
            final triggeredByTyping = records.any((dynamic m) =>
                m is DomMutationRecord &&
                (m.type == 'characterData' ||
                    m.type == 'childList' ||
                    (m.type == 'attributes' && m.target == root)));
            update(triggeredByTyping
                ? EmitterSource.SILENT
                : (updateSource is String
                    ? updateSource
                    : EmitterSource.USER));
          } catch (_) {
            // Parity: upstream swallows failures here.
          }
        });
      });
      // Parity selection.ts:103-109 — embed guards report the corrected
      // caret through the optimize context.
      emitter.on(EmitterEvents.SCROLL_OPTIMIZE,
          (dynamic mutations, dynamic context) {
        if (context is Map && context['range'] is EmbedContextRange) {
          final range = context['range'] as EmbedContextRange;
          setNativeRange(
            range.startNode,
            range.startOffset,
            range.endNode ?? range.startNode,
            range.endOffset ?? range.startOffset,
          );
          update(EmitterSource.SILENT);
        }
      });
      update(EmitterSource.SILENT);
    }
  }

  final ScrollBlot scroll;
  final Emitter emitter;

  Range? _range;
  Range? savedRange;
  Range? lastRange;
  NormalizedNativeRange? lastNative;
  bool composing = false;
  bool mouseDown = false;

  bool get _nativeMode => domBindings.adapter.supportsNativeSelection;

  DomElement get root => scroll.element;

  void _handleComposition() {
    emitter.on(EmitterEvents.COMPOSITION_BEFORE_START, () {
      composing = true;
    });
    emitter.on(EmitterEvents.COMPOSITION_END, () {
      composing = false;
      final cursor = _cursor;
      if (cursor != null && cursor.parent != null) {
        final range = cursor.restore();
        if (range == null) return;
        Timer(const Duration(milliseconds: 1), () {
          setNativeRange(
            range.startNode,
            range.startOffset,
            range.endNode ?? range.startNode,
            range.endOffset ?? range.startOffset,
          );
        });
      }
    });
  }

  void _handleDragging() {
    emitter.listenDOM('mousedown', null, (DomEvent event) {
      mouseDown = true;
    });
    emitter.listenDOM('mouseup', null, (DomEvent event) {
      mouseDown = false;
      update(EmitterSource.USER);
    });
  }

  Range? getRange() {
    if (!_nativeMode) return _range;
    return getRangePair().$1;
  }

  /// Parity selection.ts `getRange()` — the logical range and the normalized
  /// native range it was computed from.
  (Range?, NormalizedNativeRange?) getRangePair() {
    if (!_nativeMode) return (_range, null);
    if (root.parentNode == null) {
      // Approximation of upstream's `!root.isConnected` fast path.
      return (null, null);
    }
    final normalized = getNativeRange();
    if (normalized == null) return (null, null);
    return (normalizedToRange(normalized), normalized);
  }

  void setSelection(Range range, String source) {
    if (_nativeMode) {
      setRange(range, source: source);
      return;
    }
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

  /// Parity selection.ts `setRange(range, force, source)`.
  void setRange(
    Range? range, {
    bool force = false,
    String source = EmitterSource.API,
  }) {
    if (!_nativeMode) {
      if (range == null) {
        clear();
      } else {
        setSelection(range, source);
      }
      return;
    }
    if (range != null) {
      final positions = rangeToNative(range);
      setNativeRange(
        positions.startNode,
        positions.startOffset,
        positions.endNode,
        positions.endOffset,
        force,
      );
    } else {
      setNativeRange(null);
    }
    update(source);
  }

  Map<String, dynamic> getFormat(int index, [int length = 0]) {
    final range = Range(index, length);
    return scroll.getFormat(range.index, range.length);
  }

  void clear() {
    if (_nativeMode) {
      setRange(null);
      return;
    }
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

  bool hasFocus() => _nativeMode
      ? domBindings.adapter.hasFocus(root)
      : _range != null;

  /// Parity selection.ts:144-148 — refocus the editor root (preventScroll)
  /// and restore the last saved range. This is what makes a toolbar click
  /// keep the user's selection.
  void focus() {
    if (!_nativeMode) return;
    if (hasFocus()) return;
    final previousTop = root.scrollTop;
    domBindings.adapter.focus(root);
    root.scrollTop = previousTop;
    final saved = savedRange;
    if (saved != null) {
      setRange(saved);
    }
  }

  /// The pending-format marker blot (parity selection.ts `this.cursor`),
  /// created lazily and reused across calls.
  Cursor? _cursor;

  Cursor? get cursorBlot => _cursor;

  Cursor _ensureCursor(Scroll scrollBlot) {
    var cursor = _cursor;
    if (cursor == null) {
      cursor = scrollBlot.create(Cursor.kBlotName) as Cursor;
      cursor.isComposing = () => composing;
      // cursor.ts:77 — restore() remaps the LIVE native selection.
      cursor.nativeRangeProvider = () {
        final normalized = getNativeRange();
        if (normalized == null) return null;
        return (
          startNode: normalized.start.node,
          startOffset: normalized.start.offset,
          endNode: normalized.end.node,
          endOffset: normalized.end.offset,
        );
      };
      _cursor = cursor;
    }
    return cursor;
  }

  /// Parity selection.ts:150-176.
  ///
  /// With a collapsed selection the format cannot be applied to any existing
  /// text, so a zero-length [Cursor] blot is parked at the caret and formatted
  /// instead — that is the "enable bold, then type" behavior. With a real
  /// range the format is applied directly (logical mode keeps this port's
  /// original behavior; Quill.format routes ranged formats to formatText).
  void format(String name, dynamic value) {
    if (_nativeMode) {
      _formatNative(name, value);
      return;
    }
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

    final cursor = _ensureCursor(scrollBlot);
    if (cursor.parent != null) {
      cursor.remove();
    }

    final after = leaf.split(leafEntry.value);
    leaf.parent?.insertBefore(cursor, after);
    cursor.format(name, value);
    scroll.optimize([], {});
  }

  void _formatNative(String name, dynamic value) {
    final scrollBlot = scroll;
    if (scrollBlot is! Scroll) return;
    scrollBlot.update();
    final nativeRange = getNativeRange();
    if (nativeRange == null ||
        !nativeRange.native.collapsed ||
        scroll.query(name, Scope.BLOCK) != null) {
      return;
    }
    final cursor = _ensureCursor(scrollBlot);
    if (nativeRange.start.node != cursor.textNode) {
      final blot = scroll.find(nativeRange.start.node, bubble: false).key;
      if (blot == null) return;
      if (cursor.parent != null) {
        cursor.remove();
      }
      if (blot is LeafBlot) {
        final after = blot.split(nativeRange.start.offset);
        blot.parent?.insertBefore(cursor, after);
      } else if (blot is ParentBlot) {
        // Parity upstream comment: should never happen.
        blot.insertBefore(cursor, null);
      }
    }
    cursor.format(name, value);
    scroll.optimize([], {});
    setNativeRange(cursor.textNode, cursor.textNode.data.length);
    update();
  }

  /// Parity selection.ts `getNativeRange()` — the current browser selection
  /// normalized into the editor, or null when it is elsewhere.
  NormalizedNativeRange? getNativeRange() {
    if (!_nativeMode) return null;
    final native = domBindings.adapter.getNativeSelectionRange();
    if (native == null) return null;
    return normalizeNative(native);
  }

  /// Parity selection.ts `rangeToNative(range)`.
  ({DomNode? startNode, int startOffset, DomNode? endNode, int endOffset})
      rangeToNative(Range range) {
    final scrollBlot = scroll;
    final scrollLength = scroll.length();
    MapEntry<DomNode, int>? getPosition(int index, bool inclusive) {
      if (scrollBlot is! Scroll) return null;
      final clamped = math.max(0, math.min(scrollLength - 1, index));
      final leafEntry = scrollBlot.leaf(clamped);
      final leaf = leafEntry.key;
      if (leaf == null) return null;
      return leaf.position(leafEntry.value, inclusive);
    }

    final start = getPosition(range.index, false);
    final end = getPosition(range.index + range.length, true);
    return (
      startNode: start?.key,
      startOffset: start?.value ?? -1,
      endNode: end?.key,
      endOffset: end?.value ?? -1,
    );
  }

  /// Parity selection.ts `setNativeRange(...)`.
  void setNativeRange(
    DomNode? startNode, [
    int? startOffset,
    DomNode? endNode,
    int? endOffset,
    bool force = false,
  ]) {
    if (!_nativeMode) return;
    endNode ??= startNode;
    endOffset ??= startOffset;
    if (startNode != null &&
        (root.parentNode == null ||
            startNode.parentNode == null ||
            endNode!.parentNode == null)) {
      return;
    }
    if (startNode != null) {
      // `rangeToNative` reports -1 for a position it cannot resolve, and
      // `Cursor.restore`'s remap can reach -1 when the caret sits before the
      // guard character. A negative offset has no meaning, and handing it to
      // `Range.setStart` throws an IndexSizeError from inside an optimize
      // pass — which leaves the editor wedged. Leave the selection alone.
      if ((startOffset ?? 0) < 0 || (endOffset ?? 0) < 0) return;
      if (!hasFocus()) {
        final previousTop = root.scrollTop;
        domBindings.adapter.focus(root);
        root.scrollTop = previousTop;
      }
      final native = getNativeRange()?.native;
      if (native == null ||
          force ||
          startNode != native.startContainer ||
          startOffset != native.startOffset ||
          endNode != native.endContainer ||
          endOffset != native.endOffset) {
        var resolvedStart = startNode;
        var resolvedStartOffset = startOffset ?? 0;
        if (resolvedStart is DomElement && resolvedStart.tagName == 'BR') {
          final parent = resolvedStart.parentNode;
          if (parent != null) {
            resolvedStartOffset = parent.childNodes.indexOf(resolvedStart);
            resolvedStart = parent;
          }
        }
        var resolvedEnd = endNode!;
        var resolvedEndOffset = endOffset ?? 0;
        if (resolvedEnd is DomElement && resolvedEnd.tagName == 'BR') {
          final parent = resolvedEnd.parentNode;
          if (parent != null) {
            resolvedEndOffset = parent.childNodes.indexOf(resolvedEnd);
            resolvedEnd = parent;
          }
        }
        domBindings.adapter.setSelectionByNodes(
          resolvedStart,
          resolvedStartOffset,
          resolvedEnd,
          resolvedEndOffset,
        );
      }
    } else {
      domBindings.adapter.clearNativeSelection();
      domBindings.adapter.blur(root);
    }
  }

  /// Parity selection.ts `update(source)` — reconcile the logical range from
  /// the native selection, keep `savedRange`, restore a parked cursor and
  /// emit the change events.
  void update([String source = EmitterSource.USER]) {
    if (!_nativeMode) return;
    final oldRange = lastRange;
    final pair = getRangePair();
    lastRange = pair.$1;
    lastNative = pair.$2;
    _range = lastRange;
    if (lastRange != null) {
      savedRange = lastRange;
    }
    if (!_rangesEqual(oldRange, lastRange)) {
      final nativeRange = pair.$2;
      if (!composing &&
          nativeRange != null &&
          nativeRange.native.collapsed &&
          nativeRange.start.node != _cursor?.textNode) {
        final range = _cursor?.restore();
        if (range != null) {
          setNativeRange(
            range.startNode,
            range.startOffset,
            range.endNode ?? range.startNode,
            range.endOffset ?? range.startOffset,
          );
        }
      }
      emitter.emit(
        EmitterEvents.EDITOR_CHANGE,
        EmitterEvents.SELECTION_CHANGE,
        lastRange,
        oldRange,
        source,
      );
      if (source != EmitterSource.SILENT) {
        emitter.emit(
          EmitterEvents.SELECTION_CHANGE,
          lastRange,
          oldRange,
          source,
        );
      }
    }
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
