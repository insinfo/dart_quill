import '../blots/inline.dart';
import 'dart:html';

class Link extends Inline {
  Link(HtmlElement domNode) : super(domNode);

  static const String blotName = 'link';
  static const String tagName = 'A';
  static const String SANITIZED_URL = 'about:blank';
  static const List<String> PROTOCOL_WHITELIST = ['http', 'https', 'mailto', 'tel', 'sms'];

  static HtmlElement create(String value) {
    final node = HtmlElement.anchor(); // super.create(value) as HTMLElement;
    node.setAttribute('href', Link.sanitize(value));
    node.setAttribute('rel', 'noopener noreferrer');
    node.setAttribute('target', '_blank');
    return node;
  }

  static String? formats(HtmlElement domNode) {
    return domNode.getAttribute('href');
  }

  static String sanitize(String url) {
    return _sanitizeUrl(url, PROTOCOL_WHITELIST) ? url : SANITIZED_URL;
  }

  @override
  void format(String name, dynamic value) {
    if (name != Link.blotName || value == null) {
      super.format(name, value);
    } else {
      domNode.setAttribute('href', Link.sanitize(value.toString()));
    }
  }

  @override
  Blot clone() => Link(domNode.clone(true) as HtmlElement);
}

bool _sanitizeUrl(String url, List<String> protocols) {
  final anchor = HtmlElement.anchor();
  anchor.href = url;
  final protocol = anchor.href.substring(0, anchor.href.indexOf(':'));
  return protocols.contains(protocol);
}
