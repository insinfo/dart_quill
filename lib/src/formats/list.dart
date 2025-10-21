import '../blots/block.dart';
import '../blots/container.dart';
import '../blots/abstract/blot.dart';
import 'dart:html';

// Placeholder for Quill
class Quill {
  static void register(dynamic blot, [bool overwrite = false]) {}
}

class ListContainer extends Container {
  ListContainer(HtmlElement domNode) : super(domNode);

  static const String blotName = 'list-container';
  static const String tagName = 'OL';
  static List<Type> allowedChildren = [ListItem]; // Placeholder for ListItem

  @override
  Blot clone() => ListContainer(domNode.clone(true) as HtmlElement);
}

class ListItem extends Block {
  ListItem(HtmlElement domNode) : super(domNode);

  static HtmlElement create(String value) {
    final node = HtmlElement.li(); // super.create() as HTMLElement;
    node.setAttribute('data-list', value);
    return node;
  }

  static String? formats(HtmlElement domNode) {
    return domNode.getAttribute('data-list');
  }

  static void register() {
    Quill.register(ListContainer);
  }

  // Constructor in TS takes scroll, domNode. In Dart, we pass domNode to super.
  // The UI attachment logic needs to be adapted.
  // ListItem(ScrollBlot scroll, HtmlElement domNode) : super(domNode) {
  //   final ui = domNode.ownerDocument!.createElement('span');
  //   final listEventHandler = (Event e) {
  //     if (!scroll.isEnabled()) return;
  //     final format = ListItem.formats(domNode);
  //     if (format == 'checked') {
  //       format('list', 'unchecked');
  //       e.preventDefault();
  //     } else if (format == 'unchecked') {
  //       format('list', 'checked');
  //       e.preventDefault();
  //     }
  //   };
  //   ui.addEventListener('mousedown', listEventHandler);
  //   ui.addEventListener('touchstart', listEventHandler);
  //   // attachUI(ui); // Needs implementation
  // }

  @override
  void format(String name, dynamic value) {
    if (name == ListItem.blotName && value != null) {
      domNode.setAttribute('data-list', value.toString());
    } else {
      super.format(name, value);
    }
  }

  static const String blotName = 'list';
  static const String tagName = 'LI';
  static Type requiredContainer = ListContainer;

  @override
  Blot clone() => ListItem(domNode.clone(true) as HtmlElement);
}
