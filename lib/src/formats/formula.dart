import '../blots/embed.dart';
import 'dart:html';

class Formula extends Embed {
  Formula(HtmlElement domNode) : super(null as dynamic, domNode); // ScrollBlot needs to be passed

  static const String blotName = 'formula';
  static const String className = 'ql-formula';
  static const String tagName = 'SPAN';

  static HtmlElement create(String value) {
    // @ts-expect-error
    // if (window.katex == null) {
    //   throw new Error('Formula module requires KaTeX.');
    // }
    final node = HtmlElement.span(); // super.create(value) as Element;
    if (value is String) {
      // @ts-expect-error
      // window.katex.render(value, node, {
      //   throwOnError: false,
      //   errorColor: '#f00',
      // });
      node.setAttribute('data-value', value);
    }
    return node;
  }

  static String? value(HtmlElement domNode) {
    return domNode.getAttribute('data-value');
  }

  String html() {
    // Placeholder for value() returning a map with 'formula' key
    // final formula = value()['formula'];
    final formula = value(); // Assuming value() returns the formula string directly
    return '<span>$formula</span>';
  }

  @override
  Blot clone() => Formula(domNode.clone(true) as HtmlElement);

  @override
  void attach() {}

  @override
  void detach() {}

  @override
  Map<String, dynamic> formats() => {};

  @override
  void format(String name, value) {}

  @override
  void formatAt(int index, int length, String name, value) {}

  @override
  void insertAt(int index, String value, [def]) {}

  @override
  void deleteAt(int index, int length) {}

  @override
  dynamic value() => null;

  @override
  void optimize([context]) {}

  @override
  void update([source]) {}

  @override
  List<dynamic> path(int index, [bool inclusive = false]) => [];

  @override
  int offset(Blot? root) => 0;
}
