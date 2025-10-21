import '../blots/inline.dart';
import 'dart:html';

class Underline extends Inline {
  Underline(HtmlElement domNode) : super(domNode);

  static const String blotName = 'underline';
  static const String tagName = 'U';

  @override
  Blot clone() => Underline(domNode.clone(true) as HtmlElement);
}
