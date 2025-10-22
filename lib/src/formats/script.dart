import '../blots/abstract/blot.dart';
import '../blots/inline.dart';
import '../platform/dom.dart';
import '../platform/platform.dart';

class Script extends InlineBlot {
  Script(DomElement domNode) : super(domNode);

  static const String kBlotName = 'script';
  static const int kScope = Scope.INLINE_BLOT;
  static const List<String> kTagNames = ['SUB', 'SUP'];

  static Script create([dynamic value]) {
    final document = domBindings.adapter.document;
    final tag = value == 'super'
        ? 'SUP'
        : value == 'sub'
            ? 'SUB'
            : 'SPAN';
    final node = document.createElement(tag);
    return Script(node);
  }

  static String? getFormat(DomElement node) {
    final tag = node.tagName.toUpperCase();
    if (tag == 'SUB') return 'sub';
    if (tag == 'SUP') return 'super';
    return null;
  }

  @override
  String get blotName => kBlotName;

  @override
  int get scope => kScope;

  @override
  Map<String, dynamic> formats() => {kBlotName: getFormat(element)};

  @override
  Script clone() => Script(element.cloneNode(deep: true));
}
