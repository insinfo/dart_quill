import '../blots/block.dart';
import 'dart:html';

class Header extends Block {
  Header(HtmlElement domNode) : super(domNode);

  static const String blotName = 'header';
  static const List<String> tagName = ['H1', 'H2', 'H3', 'H4', 'H5', 'H6'];

  static int formats(HtmlElement domNode) {
    return tagName.indexOf(domNode.tagName) + 1;
  }

  @override
  Blot clone() => Header(domNode.clone(true) as HtmlElement);
}
