import 'dart:html';
import 'abstract/blot.dart';

class TextBlot extends LeafBlot {
  String text;
  TextBlot(this.text, HtmlElement domNode) : super(domNode);

  @override
  int length() => text.length;

  @override
  dynamic value() => text;

  @override
  Map<String, dynamic> formats() => {};

  @override
  void format(String name, value) {}

  @override
  void formatAt(int index, int length, String name, value) {}

  @override
  void insertAt(int index, String value, [def]) {
    text = text.substring(0, index) + value + text.substring(index);
    domNode.text = text;
  }

  @override
  void deleteAt(int index, int length) {
    text = text.substring(0, index) + text.substring(index + length);
    domNode.text = text;
  }

  @override
  Blot clone() => TextBlot(text, domNode.clone(true) as HtmlElement);

  @override
  void attach() {}

  @override
  void detach() {}

  @override
  void optimize([context]) {}

  @override
  void update([source]) {}

  @override
  List<dynamic> path(int index, [bool inclusive = false]) => [];

  @override
  int offset(Blot? root) => 0;
}

class Text extends TextBlot {
  Text(String text, HtmlElement domNode) : super(text, domNode);
}

final Map<String, String> entityMap = {
  '&': '&amp;',
  '<': '&lt;',
  '>': '&gt;',
  '"': '&quot;',
  '\'': '&#39;',
};

String escapeText(String text) {
  return text.replaceAllMapped(RegExp(r'[&<>"\']'), (match) => entityMap[match.group(0)]!));
}
