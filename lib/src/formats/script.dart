import '../blots/inline.dart';
import 'dart:html';

class Script extends Inline {
  Script(HtmlElement domNode) : super(domNode);

  static const String blotName = 'script';
  static const List<String> tagName = ['SUB', 'SUP'];

  static HtmlElement create(String value) {
    if (value == 'super') {
      return HtmlElement.tag('sup');
    }
    if (value == 'sub') {
      return HtmlElement.tag('sub');
    }
    // super.create(value) is not directly translatable as Inline does not have a static create method
    return HtmlElement.span(); // Placeholder
  }

  static String? formats(HtmlElement domNode) {
    if (domNode.tagName == 'SUB') return 'sub';
    if (domNode.tagName == 'SUP') return 'super';
    return null;
  }

  @override
  Blot clone() => Script(domNode.clone(true) as HtmlElement);
}
