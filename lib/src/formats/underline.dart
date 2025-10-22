import '../blots/abstract/blot.dart';
import '../blots/inline.dart';
import '../platform/dom.dart';
import '../platform/platform.dart';

class Underline extends InlineBlot {
  Underline(DomElement domNode) : super(domNode);

  static const String kBlotName = 'underline';
  static const String kTagName = 'U';
  static const int kScope = Scope.INLINE_BLOT;

  static Underline create([dynamic value]) {
    final node = (domBindings.adapter.document).createElement(kTagName);
    return Underline(node);
  }

  @override
  String get blotName => kBlotName;

  @override
  int get scope => kScope;

  @override
  Map<String, dynamic> formats() => {kBlotName: true};

  @override
  void format(String name, dynamic value) {
    if (name == kBlotName && value == false) {
      unwrap();
      return;
    }
    super.format(name, value);
  }

  @override
  Underline clone() => Underline(element.cloneNode(deep: true));
}
