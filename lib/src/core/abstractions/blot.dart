
import 'dart:html';

import 'package:dart_quill/src/core/abstractions/parent.dart';

abstract class Blot {
  Blot? parent;
  Blot? prev;
  Blot? next;
  Element domNode;

  Blot(this.domNode);

  void remove() {
    parent?.removeChild(this);
  }

  int length();
  dynamic value();
  Map<String, dynamic> formats();
  void format(String name, dynamic value);
  void formatAt(int index, int length, String name, dynamic value);
  void insertAt(int index, String value, [dynamic def]);
  void deleteAt(int index, int length);
  
  // TODO: Check if this is the correct implementation
  Blot clone() {
    throw UnimplementedError();
  }
  
  // TODO: Check if this is the correct implementation
  void insertInto(Parent parent, [Blot? ref]) {
    throw UnimplementedError();
  }

  // TODO: Check if this is the correct implementation
  void split(int index, [bool force = false]) {
    throw UnimplementedError();
  }
  
  // TODO: Check if this is the correct implementation
  void attach() {
    throw UnimplementedError();
  }

  // TODO: Check if this is the correct implementation
  void detach() {
    throw UnimplementedError();
  }

  // TODO: Check if this is the correct implementation
  void replaceWith(Blot other) {
    throw UnimplementedError();
  }

  // TODO: Check if this is the correct implementation
  void wrap(String name, [dynamic value]) {
    throw UnimplementedError();
  }

  // TODO: Check if this is the correct implementation
  void unwrap() {
    throw UnimplementedError();
  }

  // TODO: Check if this is the correct implementation
  void moveChildren(Parent target, [Blot? ref]) {
    throw UnimplementedError();
  }

  // TODO: Check if this is the correct implementation
  void unwrapChildren(Parent target) {
    throw UnimplementedError();
  }

  // TODO: Check if this is the correct implementation
  void isolate(int index, int length) {
    throw UnimplementedError();
  }

  // TODO: Check if this is the correct implementation
  List<dynamic> path(int index, [bool inclusive = false]) {
    throw UnimplementedError();
  }

  // TODO: Check if this is the correct implementation
  void optimize(Map<String, dynamic> context) {
    throw UnimplementedError();
  }

  // TODO: Check if this is the correct implementation
  int offset([Blot? blot]) {
    throw UnimplementedError();
  }
}

abstract class Formattable extends Blot {
  Formattable(Element domNode) : super(domNode);

  @override
  Map<String, dynamic> formats();
}
