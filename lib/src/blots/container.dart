import 'dart:html';
import 'abstract/blot.dart';

class Container extends ContainerBlot {
  Container(HtmlElement domNode) : super(domNode);

  @override
  Blot clone() => Container(domNode.clone(true) as HtmlElement);

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
