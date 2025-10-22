import '../blots/abstract/blot.dart';
import '../blots/embed.dart';
import '../platform/dom.dart';
import '../platform/platform.dart';

String sanitizeUrl(String url, List<String> protocols) {
  final Uri? uri = Uri.tryParse(url);
  if (uri == null) return '//:0';
  
  if (uri.scheme.isEmpty) return url; // Relative URL
  if (protocols.contains(uri.scheme.toLowerCase())) {
    return url;
  }
  return '//:0';
}

class Image extends Embed {
  Image(DomElement node) : super(node);

  static const String kBlotName = 'image';
  static const String kTagName = 'IMG';
  static const int kScope = Scope.INLINE_BLOT;
  static const List<String> kAttributes = ['alt', 'height', 'width'];

  static DomElement create(dynamic value) {
    if (value is! String) {
      throw ArgumentError('Image value must be a string URL');
    }

    final node = domBindings.adapter.document.createElement(kTagName);
    node.setAttribute('src', sanitizeUrl(value, ['http', 'https', 'data']));
    return node;
  }

  static Map<String, String?> getAttributes(DomElement node) {
    return kAttributes.fold<Map<String, String?>>({}, (attrs, attribute) {
      if (node.hasAttribute(attribute)) {
        attrs[attribute] = node.getAttribute(attribute);
      }
      return attrs;
    });
  }

  static bool match(String url) {
    return RegExp(r'\.(jpe?g|gif|png|webp|avif)$', caseSensitive: false).hasMatch(url) ||
           RegExp(r'^data:image\/.+;base64').hasMatch(url);
  }

  static String? getValue(DomElement node) {
    return node.getAttribute('src');
  }

  @override
  String get blotName => kBlotName;

  @override
  int get scope => kScope;

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

  @override
  Map<String, dynamic> formats() {
    final attributes = getAttributes(element);
    return {kBlotName: getValue(element), ...attributes};
  }

  @override
  dynamic value() => getValue(element);

  @override
  Image clone() => Image(element.cloneNode(deep: true));

  @override
  void optimize([List<DomMutationRecord>? mutations, Map<String, dynamic>? context]) {
    super.optimize(mutations, context);
    // Remove imagem se a URL for inválida
    final src = getValue(element);
    if (src == null || src == '//:0') {
      remove();
    }
  }
}
