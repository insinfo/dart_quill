import '../blots/abstract/blot.dart';
import '../blots/block.dart';
import '../platform/dom.dart';
import '../platform/platform.dart';
import 'link.dart';

const List<String> kAttributes = ['height', 'width'];

class Video extends BlockEmbed {
  Video(DomElement domNode) : super(domNode);

  static const String kBlotName = 'video';
  static const String kClassName = 'ql-video';
  static const String kTagName = 'IFRAME';

  @override
  String get blotName => kBlotName;

  @override
  int get scope => Scope.BLOCK_BLOT;

  static Video create(String value) {
    final node = domBindings.adapter.document.createElement(kTagName);
    node.classes.add(kClassName);
    node.setAttribute('frameborder', '0');
    node.setAttribute('allowfullscreen', 'true');
    node.setAttribute('src', Video.sanitize(value));
    return Video(node);
  }

  static Map<String, String?> formatsDom(DomElement domNode) {
    return kAttributes.fold<Map<String, String?>>({}, (formats, attribute) {
      if (domNode.hasAttribute(attribute)) {
        formats[attribute] = domNode.getAttribute(attribute);
      }
      return formats;
    });
  }

  static String sanitize(String url) {
    return Link.sanitize(url);
  }

  static String? valueDom(DomElement domNode) {
    return domNode.getAttribute('src');
  }

  @override
  Map<String, dynamic> formats() {
    return kAttributes.fold<Map<String, dynamic>>({}, (formats, attribute) {
      if (element.hasAttribute(attribute)) {
        formats[attribute] = element.getAttribute(attribute);
      }
      return formats;
    });
  }

  @override
  dynamic value() => element.getAttribute('src');

  @override
  void format(String name, dynamic value) {
    if (kAttributes.contains(name)) {
      if (value != null) {
        element.setAttribute(name, value.toString());
      } else {
        element.removeAttribute(name);
      }
    } else {
      super.format(name, value);
    }
  }

  String html() {
    final video = value();
    return '<a href="$video">$video</a>';
  }

  @override
  Video clone() => Video(element.cloneNode(deep: true));
}
