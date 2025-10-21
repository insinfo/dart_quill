import '../blots/inline.dart';
import 'dart:html';

class Bold extends Inline {
  Bold(HtmlElement domNode) : super(domNode);

  static const String blotName = 'bold';
  static const List<String> tagName = ['STRONG', 'B'];

  static Bold create() {
    return Bold(HtmlElement.tag(tagName[0]));
  }

  static bool formats() {
    return true;
  }

  @override
  void optimize([dynamic context]) {
    super.optimize(context);
    // Placeholder for statics.tagName
    if (domNode.tagName != tagName[0]) {
      // Placeholder for replaceWith
      // replaceWith(statics.blotName);
    }
  }

  @override
  Blot clone() => Bold(domNode.clone(true) as HtmlElement);
}
