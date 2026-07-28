import '../platform/dom.dart';
import '../platform/platform.dart';
import 'abstract/blot.dart';

class Break extends EmbedBlot {
  Break(DomElement domNode) : super(domNode);

  static const String kBlotName = 'break';
  static const String tagName = 'BR';
  // Parity: parchment LeafBlot.scope = Scope.INLINE_BLOT (leaf.ts:6); Break
  // inherits it. BLOCK_BLOT here broke Scroll.insertBefore wrapping and
  // bubbleFormats' scope-boundary check.
  static const int kScope = Scope.INLINE_BLOT;

  static Break create() {
    final node = domBindings.adapter.document.createElement(tagName);
    return Break(node);
  }

  @override
  String get blotName => kBlotName;

  @override
  int get scope => kScope;

  @override
  int length() => 0;

  @override
  dynamic value() => '';

  @override
  Break clone() => Break((domNode as DomElement).cloneNode(deep: false));

  @override
  void optimize([
    List<DomMutationRecord>? mutations,
    Map<String, dynamic>? context,
  ]) {
    if (prev != null || next != null) {
      remove();
    }
  }
}
