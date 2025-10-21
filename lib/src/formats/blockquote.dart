import '../blots/block.dart';
import 'dart:html';

class Blockquote extends Block {
  Blockquote(HtmlElement domNode) : super(domNode);

  static const String blotName = 'blockquote';
  static const String tagName = 'blockquote';

  @override
  Blot clone() => Blockquote(domNode.clone(true) as HtmlElement);
}
