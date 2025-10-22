import 'package:collection/collection.dart';

import '../blots/abstract/blot.dart';
import '../blots/inline.dart';
import '../platform/dom.dart';
import '../platform/platform.dart';

class Link extends InlineBlot {
  Link(DomElement domNode) : super(domNode);

  static const String kBlotName = 'link';
  static const String kTagName = 'A';
  static const String kSanitizedUrl = 'about:blank';
  static const int kScope = Scope.INLINE_BLOT;
  static const List<String> kProtocolWhitelist = [
    'http',
    'https',
    'mailto',
    'tel',
    'sms',
  ];

  static Link create(String value) {
    final node = domBindings.adapter.document.createElement(kTagName);
    node.setAttribute('href', sanitize(value));
    node.setAttribute('rel', 'noopener noreferrer');
    node.setAttribute('target', '_blank');
    return Link(node);
  }

  static String sanitize(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      return kSanitizedUrl;
    }
    final scheme = uri.scheme.isEmpty ? null : uri.scheme.toLowerCase();
    if (scheme == null) {
      return url;
    }
    final isAllowed =
        kProtocolWhitelist.firstWhereOrNull((allowed) => allowed == scheme) != null;
    return isAllowed ? url : kSanitizedUrl;
  }

  static String? getFormat(DomElement node) => node.getAttribute('href');

  @override
  String get blotName => kBlotName;

  @override
  int get scope => kScope;

  @override
  Map<String, dynamic> formats() => {kBlotName: element.getAttribute('href')};

  @override
  void format(String name, dynamic value) {
    if (name == kBlotName) {
      if (value == null) {
        unwrap();
      } else {
        element.setAttribute('href', sanitize(value.toString()));
      }
      return;
    }
    super.format(name, value);
  }

  @override
  Link clone() => Link(element.cloneNode(deep: true));

  @override
  void optimize([
    List<DomMutationRecord>? mutations,
    Map<String, dynamic>? context,
  ]) {
    super.optimize(mutations, context);
    if (element.getAttribute('href') == kSanitizedUrl) {
      unwrap();
    }
  }
}
