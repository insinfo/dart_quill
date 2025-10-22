import '../blots/abstract/blot.dart';
import '../blots/inline.dart';
import '../platform/dom.dart';
import '../platform/platform.dart';

class Strike extends InlineBlot {
  Strike(DomElement domNode) : super(domNode);

  static const String kBlotName = 'strike';
  static const List<String> kTagNames = ['S', 'STRIKE'];
  static const int kScope = Scope.INLINE_BLOT;

  static Strike create([dynamic value]) {
    final node = domBindings.adapter.document.createElement(kTagNames.first);
    return Strike(node);
  }

  @override
  String get blotName => kBlotName;

  @override
  int get scope => kScope;

  @override
  Map<String, dynamic> formats() => {kBlotName: true};

  @override
  Strike clone() => Strike(element.cloneNode(deep: true));
}
