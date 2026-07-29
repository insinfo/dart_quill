import '../platform/dom.dart';
import '../platform/platform.dart';
import 'abstract/blot.dart';
import 'embed.dart' show EmbedContextRange;
import 'inline.dart';
import 'text.dart';

/// Port of quilljs blots/cursor.ts — the zero-length marker blot that holds
/// pending formats at a collapsed selection ("enable bold, then type").
class Cursor extends EmbedBlot {
  Cursor(DomElement domNode)
      : _textNode = domBindings.adapter.document.createTextNode(kContents),
        super(domNode) {
    element.classes.add(kClassName);
    element.append(_textNode);
  }

  static const String kBlotName = 'cursor';
  static const String kTagName = 'SPAN';
  static const String kClassName = 'ql-cursor';
  static const String kContents = '﻿';
  static const int kScope = Scope.INLINE_BLOT;

  final DomText _textNode;
  int _savedLength = 0;

  /// Hook the Selection layer sets so [restore] can bail out during IME
  /// composition (cursor.ts:76 checks `selection.composing`).
  bool Function()? isComposing;

  /// Hook the Selection layer sets so [restore] can read the CURRENT native
  /// selection (cursor.ts:77 `this.selection.getNativeRange()`) — the
  /// restored caret is remapped from where the user's caret actually is,
  /// never synthesized. Null off-browser.
  ({DomNode startNode, int startOffset, DomNode endNode, int endOffset})?
      Function()? nativeRangeProvider;

  DomText get textNode => _textNode;

  static Cursor create([dynamic value]) {
    final node = domBindings.adapter.document.createElement(kTagName);
    return Cursor(node);
  }

  @override
  String get blotName => kBlotName;

  @override
  int get scope => kScope;

  @override
  int length() => _savedLength;

  @override
  Cursor clone() {
    final cloneElement = element.cloneNode(deep: false);
    return Cursor(cloneElement);
  }

  @override
  dynamic value() => '';

  /// Parity cursor.ts:34-54 — while the cursor is zero-length, formatting it
  /// climbs to the enclosing block and formats a temporary 1-length range at
  /// the cursor position (savedLength makes length() report 1 meanwhile).
  @override
  void format(String name, dynamic value) {
    if (_savedLength != 0) {
      super.format(name, value);
      return;
    }
    Blot? target = this;
    var index = 0;
    while (target != null && (target.scope & Scope.BLOCK) == 0) {
      final parentBlot = target.parent;
      if (parentBlot == null) {
        target = null;
        break;
      }
      index += parentBlot.childOffset(target);
      target = parentBlot;
    }
    if (target != null) {
      _savedLength = kContents.length;
      target.optimize();
      target.formatAt(index, kContents.length, name, value);
      _savedLength = 0;
    }
  }

  /// Parity cursor.ts:56-59.
  @override
  int index(DomNode node, int offset) {
    if (node == _textNode) return 0;
    return offset > 0 ? 1 : 0;
  }

  /// Parity cursor.ts:65-67 — the caret parks at the end of the guard text.
  @override
  MapEntry<DomNode, int> position(int index, [bool inclusive = false]) {
    return MapEntry(_textNode, _textNode.data.length);
  }

  /// Parity cursor.ts:75-151: pull any typed text out of the cursor into a
  /// merged adjacent TextBlot, ALWAYS remove the cursor (a parented leftover
  /// re-enters restore on the next selection update and re-assigns the guard
  /// data, which collapses the browser caret), and remap the CURRENT native
  /// selection onto the merged text.
  EmbedContextRange? restore() {
    if (isComposing?.call() ?? false) return null;
    if (parent == null) return null;
    final range = nativeRangeProvider?.call();

    // Undo the browser's occasional push-down of sibling nodes into the
    // cursor span (cursor.ts:80-89).
    final parentNode = element.parentNode;
    if (parentNode is DomElement) {
      while (element.lastChild != null &&
          element.lastChild != _textNode) {
        parentNode.insertBefore(element.lastChild!, element);
      }
    }

    final prevTextBlot = prev is TextBlot ? prev as TextBlot : null;
    final prevTextLength = prevTextBlot?.length() ?? 0;
    final nextTextBlot = next is TextBlot ? next as TextBlot : null;
    final nextText = nextTextBlot != null ? '${nextTextBlot.value()}' : '';
    final newText = _textNode.data.split(kContents).join('');
    _textNode.data = kContents;

    // Proactively merge the TextBlots around the cursor so optimization does
    // not lose the caret (cursor.ts:101-121).
    Blot mergedTextBlot;
    if (prevTextBlot != null) {
      mergedTextBlot = prevTextBlot;
      if (newText.isNotEmpty || nextTextBlot != null) {
        prevTextBlot.insertAt(prevTextBlot.length(), newText + nextText);
        nextTextBlot?.remove();
      }
    } else if (nextTextBlot != null) {
      mergedTextBlot = nextTextBlot;
      if (newText.isNotEmpty) {
        nextTextBlot.insertAt(0, newText);
      }
    } else {
      final newTextNode = domBindings.adapter.document.createTextNode(newText);
      final blot = TextBlot(newTextNode);
      parent!.insertBefore(blot, this);
      mergedTextBlot = blot;
    }

    remove();
    if (range != null) {
      // Parity cursor.ts:126-148 — carry the user's caret onto the merged
      // text (`- 1` strips the FEFF guard character).
      int? remapOffset(DomNode node, int offset) {
        if (prevTextBlot != null && node == prevTextBlot.domNode) {
          return offset;
        }
        if (node == _textNode) {
          return prevTextLength + offset - 1;
        }
        if (nextTextBlot != null && node == nextTextBlot.domNode) {
          return prevTextLength + newText.length + offset;
        }
        return null;
      }

      final start = remapOffset(range.startNode, range.startOffset);
      final end = remapOffset(range.endNode, range.endOffset);
      if (start != null && end != null) {
        return EmbedContextRange(
          startNode: mergedTextBlot.domNode,
          startOffset: start,
          endNode: mergedTextBlot.domNode,
          endOffset: end,
        );
      }
    }
    return null;
  }

  @override
  void applyMutations(
    List<DomMutationRecord> mutations,
    Map<String, dynamic> context,
  ) =>
      update(mutations, context);

  /// Parity cursor.ts:153-164.
  void update(List<DomMutationRecord> mutations, Map<String, dynamic> context) {
    final touched = mutations.any((mutation) =>
        mutation.type == 'characterData' &&
        mutation.target == _textNode);
    if (touched) {
      final range = restore();
      if (range != null) {
        context['range'] = range;
      }
    }
  }

  /// Parity cursor.ts:176-191 — Safari renders a caret inside `<a>` styled
  /// as a link; the cursor must escape any anchor ancestor.
  @override
  void optimize([
    List<DomMutationRecord>? mutations,
    Map<String, dynamic>? context,
  ]) {
    super.optimize(mutations, context);
    var ancestor = parent;
    while (ancestor != null) {
      if (ancestor.element.tagName == 'A') {
        _savedLength = kContents.length;
        final isolated = ancestor.isolate(ancestor.offset(this), length());
        if (isolated is InlineBlot) {
          isolated.unwrap();
        }
        _savedLength = 0;
        break;
      }
      ancestor = ancestor.parent;
    }
  }

  @override
  void remove() {
    super.remove();
    parent = null;
  }

  /// Kept for compatibility with earlier port call-sites.
  void resetContents() {
    _savedLength = 0;
    _textNode.data = kContents;
  }

  void saveLength(int length) {
    _savedLength = length;
  }
}
