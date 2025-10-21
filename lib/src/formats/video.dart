import '../blots/block.dart';
import 'link.dart';
import 'dart:html';

const List<String> ATTRIBUTES = ['height', 'width'];

class Video extends BlockEmbed {
  Video(HtmlElement domNode) : super(domNode);

  static const String blotName = 'video';
  static const String className = 'ql-video';
  static const String tagName = 'IFRAME';

  static HtmlElement create(String value) {
    final node = HtmlElement.iframe(); // super.create(value) as Element;
    node.setAttribute('frameborder', '0');
    node.setAttribute('allowfullscreen', 'true');
    node.setAttribute('src', Video.sanitize(value));
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

  static String sanitize(String url) {
    return Link.sanitize(url);
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

  String html() {
    // Placeholder for value() returning a map with 'video' key
    // final video = value()['video'];
    final video = value(); // Assuming value() returns the video string directly
    return '<a href="$video">$video</a>';
  }

  @override
  Blot clone() => Video(domNode.clone(true) as HtmlElement);

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
