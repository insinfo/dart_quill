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
  int index(DomNode node, int offset) {
    if (identical(node, _textNode)) return 0;
    return offset > 0 ? 1 : 0;
  }

  /// Parity cursor.ts:65-67 — the caret parks at the end of the guard text.
  @override
  MapEntry<DomNode, int> position(int index, [bool inclusive = false]) {
    return MapEntry(_textNode, _textNode.data.length);
  }

  /// Parity cursor.ts:75-151 (without native-range remapping, which needs
  /// the G2 Selection layer): pull any typed text out of the cursor into an
  /// adjacent TextBlot and reset the guard contents.
  EmbedContextRange? restore() {
    if (isComposing?.call() ?? false) return null;
    if (parent == null) return null;

    // Undo the browser's occasional push-down of sibling nodes into the
    // cursor span (cursor.ts:84-90).
    final parentNode = element.parentNode;
    if (parentNode is DomElement) {
      while (element.lastChild != null &&
          !identical(element.lastChild, _textNode)) {
        parentNode.insertBefore(element.lastChild!, element);
      }
    }

    final prevTextBlot = prev is TextBlot ? prev as TextBlot : null;
    final nextTextBlot = next is TextBlot ? next as TextBlot : null;
    final newText = _textNode.data.split(kContents).join('');
    _textNode.data = kContents;

    DomNode rangeNode;
    int rangeOffset;
    if (prevTextBlot != null) {
      final prevLength = prevTextBlot.length();
      prevTextBlot.insertAt(prevLength, newText);
      rangeNode = prevTextBlot.domNode;
      rangeOffset = prevLength + newText.length;
      remove();
    } else if (nextTextBlot != null) {
      nextTextBlot.insertAt(0, newText);
      rangeNode = nextTextBlot.domNode;
      rangeOffset = newText.length;
    } else {
      final newTextNode = domBindings.adapter.document.createTextNode(newText);
      final blot = TextBlot(newTextNode);
      parent!.insertBefore(blot, this);
      rangeNode = newTextNode;
      rangeOffset = newText.length;
    }
    if (newText.isEmpty) return null;
    return EmbedContextRange(startNode: rangeNode, startOffset: rangeOffset);
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
        identical(mutation.target, _textNode));
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
