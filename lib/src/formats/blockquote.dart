import '../blots/abstract/blot.dart';
import '../blots/block.dart';
import '../platform/dom.dart';
import '../platform/platform.dart';

class Blockquote extends Block {
  Blockquote(DomElement domNode) : super(domNode);

  static const String kBlotName = 'blockquote';
  static const String kTagName = 'BLOCKQUOTE';
  static const int kScope = Scope.BLOCK_BLOT;

  static Blockquote create([dynamic value]) {
    final node = domBindings.adapter.document.createElement(kTagName);
    return Blockquote(node);
  }

  @override
  String get blotName => kBlotName;

  @override
  int get scope => kScope;

  @override
  Map<String, dynamic> formats() => {kBlotName: true};

  @override
  Blockquote clone() => Blockquote(element.cloneNode(deep: true));
}
