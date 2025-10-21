import 'dart:html';
import 'abstract/blot.dart';

// Placeholder classes for now, will be properly implemented later
class Break extends EmbedBlot {
  Break(HtmlElement domNode) : super(domNode);
  @override
  int length() => 0;
  @override
  dynamic value() => '';
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
  Blot clone() => Break(domNode.clone(true) as HtmlElement);
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

class TextBlot extends LeafBlot {
  TextBlot(String text, HtmlElement domNode) : super(domNode);
  @override
  int length() => 0;
  @override
  dynamic value() => '';
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

class Inline extends InlineBlot {
  Inline(HtmlElement domNode) : super(domNode);

  static List<Type> allowedChildren = [Inline, Break, EmbedBlot, TextBlot];
  static List<String> order = [
    'cursor',
    'inline',
    'link',
    'underline',
    'strike',
    'italic',
    'bold',
    'script',
    'code',
  ];

  static int compare(String self, String other) {
    final selfIndex = Inline.order.indexOf(self);
    final otherIndex = Inline.order.indexOf(other);
    if (selfIndex >= 0 || otherIndex >= 0) {
      return selfIndex - otherIndex;
    }
    if (self == other) {
      return 0;
    }
    return self.compareTo(other);
  }

  @override
  void formatAt(int index, int length, String name, dynamic value) {
    // Placeholder for statics.blotName and scroll.query
    if (Inline.compare(statics['blotName'], name) < 0 &&
        scroll.query(name, Scope.BLOT) != null) {
      // Placeholder for isolate and wrap
      // final blot = isolate(index, length);
      // if (value != null) {
      //   blot.wrap(name, value);
      // }
    } else {
      super.formatAt(index, length, name, value);
    }
  }

  @override
  void optimize([dynamic context]) {
    super.optimize(context);
    // Placeholder for statics.blotName and parent being Inline
    if (parent is Inline &&
        Inline.compare(statics['blotName'], parent!.statics['blotName']) > 0) {
      // Placeholder for isolate and moveChildren and wrap
      // final parentBlot = parent!.isolate(offset(), length());
      // moveChildren(parentBlot);
      // parentBlot.wrap(this);
    }
  }

  @override
  Blot clone() => Inline(domNode.clone(true) as HtmlElement);

  @override
  void attach() {}

  @override
  void detach() {}

  @override
  Map<String, dynamic> formats() => {};

  @override
  void format(String name, value) {}

  @override
  void insertAt(int index, String value, [def]) {}

  @override
  void deleteAt(int index, int length) {}

  @override
  dynamic value() => null;

  @override
  List<dynamic> path(int index, [bool inclusive = false]) => [];

  @override
  int offset(Blot? root) => 0;
}
