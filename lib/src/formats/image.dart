import '../blots/abstract/blot.dart';
import 'dart:html';

// Placeholder for sanitize function from link.js
bool sanitize(String url, List<String> protocols) {
  return true; // Dummy implementation
}

const List<String> ATTRIBUTES = ['alt', 'height', 'width'];

class Image extends EmbedBlot {
  Image(HtmlElement domNode) : super(domNode);

  static const String blotName = 'image';
  static const String tagName = 'IMG';

  static HtmlElement create(String value) {
    final node = HtmlElement.img(); // super.create(value) as Element;
    if (value is String) {
      node.setAttribute('src', Image.sanitize(value));
    }
    return node;
  }

  static Map<String, String?> formats(HtmlElement domNode) {
    return ATTRIBUTES.fold<Map<String, String?>>({}, (formats, attribute) {
      if (domNode.hasAttribute(attribute)) {
        formats[attribute] = domNode.getAttribute(attribute);
      }
      return formats;
    });
  }

  static bool match(String url) {
    return RegExp(r'\.(jpe?g|gif|png)$').hasMatch(url) ||
        RegExp(r'^data:image\/.+;base64').hasMatch(url);
  }

  static String sanitize(String url) {
    return sanitize(url, ['http', 'https', 'data']) ? url : '//:0';
  }

  static String? value(HtmlElement domNode) {
    return domNode.getAttribute('src');
  }

  @override
  void format(String name, dynamic value) {
    if (ATTRIBUTES.contains(name)) {
      if (value != null) {
        domNode.setAttribute(name, value.toString());
      } else {
        domNode.removeAttribute(name);
      }
    } else {
      super.format(name, value);
    }
  }

  @override
  Blot clone() => Image(domNode.clone(true) as HtmlElement);

  @override
  void attach() {}

  @override
  void detach() {}

  @override
  Map<String, dynamic> formats() => {};

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
