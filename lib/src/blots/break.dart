import '../platform/dom.dart';
import '../platform/platform.dart';
import 'abstract/blot.dart';

class Break extends EmbedBlot {
  Break(DomElement domNode) : super(domNode);

  static const String kBlotName = 'break';
  static const String tagName = 'BR';
  static const int kScope = Scope.BLOCK_BLOT;

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