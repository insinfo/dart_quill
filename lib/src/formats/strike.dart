import 'bold.dart';
import 'dart:html';

class Strike extends Bold {
  Strike(HtmlElement domNode) : super(domNode);

  static const String blotName = 'strike';
  static const List<String> tagName = ['S', 'STRIKE'];

  @override
  Blot clone() => Strike(domNode.clone(true) as HtmlElement);
}
