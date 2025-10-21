import 'bold.dart';
import 'dart:html';

class Italic extends Bold {
  Italic(HtmlElement domNode) : super(domNode);

  static const String blotName = 'italic';
  static const List<String> tagName = ['EM', 'I'];

  @override
  Blot clone() => Italic(domNode.clone(true) as HtmlElement);
}
