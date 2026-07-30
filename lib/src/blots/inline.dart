import '../platform/dom.dart';
import '../platform/platform.dart';
import '../formats/abstract/attributor.dart';
import 'abstract/blot.dart';
import 'break.dart';
import 'text.dart';

class Inline extends InlineBlot {
  Inline(DomElement domNode) : super(domNode);

  static const String kBlotName = 'inline';
  static const String kTagName = 'SPAN';
  static const int kScope = Scope.INLINE_BLOT;

  static Inline create() =>
      Inline(domBindings.adapter.document.createElement(kTagName));

  @override
  String get blotName => kBlotName;

  @override
  int get scope => kScope;

  @override
  Inline clone() => Inline(element.cloneNode(deep: false));
}

abstract class InlineBlot extends ParentBlot {
  // Parity quill inline.ts:7 — `Inline.allowedChildren = [Inline, Break,
  // EmbedBlot, Text]`. Was a dead empty `static const List<Type>`.
  @override
  bool Function(Blot child)? get allowedChildren => (child) =>
      child is InlineBlot ||
      child is Break ||
      child is EmbedBlot ||
      child is TextBlot;

  static const List<String> order = [
    'cursor',
    'inline',
    'link',
    'underline',
    'strike',
    'italic',
    'bold',
    'script',
    'code',
  ];

  InlineBlot(DomElement domNode) : super(domNode);

  /// Parity parchment inline.ts — every inline carries an attributor store
  /// (color/background/font/size wrappers live here).
  late final AttributorStore attributes = AttributorStore(element);

  static int compare(String self, String other) {
    final selfIndex = InlineBlot.order.indexOf(self);
    final otherIndex = InlineBlot.order.indexOf(other);
    if (selfIndex >= 0 || otherIndex >= 0) {
      return selfIndex - otherIndex;
    }
    if (self == other) {
      return 0;
    }
    return self.compareTo(other);
  }

  Attributor? _lookupAttributor(String name) =>
      isAttached ? scroll.queryAttributor(name, Scope.INLINE_ATTRIBUTE) : null;

  void _ensureAttributesBuilt() {
    if (isAttached) {
      attributes.ensureBuilt(_lookupAttributor);
    }
  }

  @override
  void format(String name, dynamic value) {
    // Parity parchment inline.ts:62-85.
    if (name == blotName && (value == null || value == false)) {
      // The attributor store of the blot being dissolved is copied onto each
      // child first (wrapping bare children in a generic `inline`), exactly
      // as inline.ts:63-71 does. Without it, removing a link dropped the
      // `size`/`color`/`font` that lived on the `<a>` itself.
      _ensureAttributesBuilt();
      if (attributes.values().isNotEmpty) {
        for (final child in List<Blot>.from(children)) {
          final target =
              child is InlineBlot ? child : child.wrap(Inline.kBlotName);
          attributes.copy(target.format);
        }
      }
      unwrap();
      return;
    }
    final attribute = _lookupAttributor(name);
    if (attribute != null) {
      _ensureAttributesBuilt();
      attributes.attribute(attribute, value);
      return;
    }
    final isTruthy = value != null && value != false && value != '';
    if (isTruthy &&
        isAttached &&
        scroll.query(name, Scope.INLINE) != null &&
        (name != blotName || formats()[name] != value)) {
      replaceWith(name, value);
    }
  }

  @override
  void formatAt(int index, int length, String name, dynamic value) {
    // Parity quill inline.ts:36-48 FIRST: when the requested format belongs
    // OUTSIDE this one in the wrapper order, this blot isolates ITSELF and the
    // isolated half gets wrapped — `<em>45</em>` formatted bold over one
    // character becomes `<strong><em>4</em></strong><em>5</em>`.
    //
    // The port did not have this branch; `TextBlot.formatAt` compensated with
    // a bespoke `_highestWrapTarget` that climbed to the outermost inline
    // wrapper and wrapped THAT, so the format leaked over the whole `<em>`.
    if (isAttached &&
        InlineBlot.compare(blotName, name) < 0 &&
        scroll.query(name, Scope.BLOT) != null) {
      final blot = isolate(index, length);
      final isTruthy = value != null && value != false && value != '';
      if (isTruthy) {
        blot.wrap(name, value);
      }
      return;
    }
    // Parity parchment inline.ts:96-111. Without this the attributor branch
    // reached the element of the *whole* blot, so clearing `color` over one
    // character cleared it for every character in the span — losing formatting
    // the caller never asked to touch. Isolating first confines the change to
    // the requested range, exactly as a blot format already did.
    if (formats()[name] != null ||
        (isAttached && scroll.queryAttributor(name, Scope.ATTRIBUTE) != null)) {
      final blot = isolate(index, length);
      blot.format(name, value);
      return;
    }
    super.formatAt(index, length, name, value);
  }

  @override
  Map<String, dynamic> formats() {
    // Parity parchment inline.ts:87-94 — attributor values only; concrete
    // formats (Bold, Link, ...) add their own blotName entry in overrides.
    // The previous behavior (every CSS class becomes a format) minted
    // phantom formats like ql-cursor.
    _ensureAttributesBuilt();
    return attributes.values();
  }

  void unwrap() {
    final parentBlot = parent;
    if (parentBlot is ParentBlot) {
      final reference = next;
      moveChildren(parentBlot, reference);
      parentBlot.removeChild(this);
    }
  }

  bool _formatsEqual(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (!b.containsKey(entry.key) || b[entry.key] != entry.value) {
        return false;
      }
    }
    return true;
  }

  @override
  void optimize([
    List<DomMutationRecord>? mutations,
    Map<String, dynamic>? context,
  ]) {
    super.optimize(mutations, context);
    final parentInline = parent;
    if (parentInline is InlineBlot &&
        InlineBlot.compare(blotName, parentInline.blotName) > 0) {
      _reorderWithParent(parentInline);
      return;
    }
    // Parity parchment inline.ts:113-128 — a span with no formats unwraps;
    // adjacent siblings with identical formats merge.
    final currentFormats = formats();
    if (currentFormats.isEmpty && blotName == Inline.kBlotName) {
      unwrap();
      return;
    }
    final following = next;
    if (following is InlineBlot &&
        following.prev == this &&
        following.blotName == blotName &&
        following.element.tagName == element.tagName &&
        _formatsEqual(currentFormats, following.formats())) {
      following.moveChildren(this, null);
      following.remove();
    }
  }

  void _reorderWithParent(InlineBlot parentInline) {
    final grandParent = parentInline.parent;
    if (grandParent is! ParentBlot) {
      return;
    }

    final scrollBlot = parentInline.scroll;

    final children = List<Blot>.from(parentInline.children);
    final index = children.indexOf(this);
    if (index == -1) {
      return;
    }

    final beforeNodes = children.sublist(0, index);
    final afterNodes = children.sublist(index + 1);

    final reference = parentInline.next;

    // Detach all nodes from parentInline so we can redistribute them.
    for (final node in beforeNodes) {
      parentInline.removeChild(node);
    }
    parentInline.removeChild(this);
    for (final node in afterNodes) {
      parentInline.removeChild(node);
    }

    // Prepare wrappers in insertion order.
    final sequence = <Blot>[];

    if (beforeNodes.isNotEmpty) {
      for (final node in beforeNodes) {
        parentInline.appendChild(node);
      }
      sequence.add(parentInline);
    }

    final innerWrapper = scrollBlot.create(parentInline.blotName) as ParentBlot;
    moveChildren(innerWrapper, null);
    appendChild(innerWrapper);
    sequence.add(this);

    ParentBlot? afterWrapper;
    if (afterNodes.isNotEmpty) {
      afterWrapper = scrollBlot.create(parentInline.blotName) as ParentBlot;
      for (final node in afterNodes) {
        afterWrapper.appendChild(node);
      }
      sequence.add(afterWrapper);
    }

    // Ensure parentInline is not left dangling if unused.
    grandParent.removeChild(parentInline);

    for (final blot in sequence) {
      grandParent.insertBefore(blot, reference);
    }

    if (afterWrapper != null) {
      afterWrapper.optimize();
    }
    if (beforeNodes.isNotEmpty) {
      parentInline.optimize();
    }
  }
}
