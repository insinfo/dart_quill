import 'dart:html';
import 'abstract/blot.dart';

class Break extends EmbedBlot {
  Break(HtmlElement domNode) : super(domNode);

  static dynamic value_() {
    return null; // Em Dart, 'undefined' pode ser representado por 'null'
  }

  @override
  void optimize([dynamic context]) {
    if (prev != null || next != null) {
      remove();
    }
  }

  @override
  int length() {
    return 0;
  }

  @override
  dynamic value() {
    return '';
  }
  
  static const String blotName = 'break';
  static const String tagName = 'BR';

  @override
  Blot clone() => Break(domNode.clone(true) as HtmlElement);

  @override
  void attach() {}

  @override
  void detach() {}

  @override
  void format(String name, value) {}

  @override
  void formatAt(int index, int length, String name, value) {}

  @override
  void insertAt(int index, String value, [def]) {}

  @override
  void deleteAt(int index, int length) {}

  @override
  List<dynamic> path(int index, [bool inclusive = false]) => [];

  @override
  int offset(Blot? root) => 0;
}
