import '../blots/abstract/blot.dart';
import '../blots/inline.dart';
import '../platform/dom.dart';
import '../platform/platform.dart';

class Italic extends InlineBlot {
  Italic(DomElement domNode) : super(domNode);

  static const String kBlotName = 'italic';
  static const List<String> kTagNames = ['EM', 'I'];
  static const int kScope = Scope.INLINE_BLOT;

  static Italic create([dynamic value]) {
    final node = domBindings.adapter.document.createElement(kTagNames.first);
    return Italic(node);
  }

  @override
  String get blotName => kBlotName;

  @override
  int get scope => kScope;

  @override
  Map<String, dynamic> formats() => {kBlotName: true};

  @override
  void optimize([
    List<DomMutationRecord>? mutations,
    Map<String, dynamic>? context,
  ]) {
    super.optimize(mutations, context);
    if (element.tagName != kTagNames.first) {
      unwrap();
      parent?.insertBefore(Italic.create(), next);
    }
  }

  @override
  Italic clone() => Italic(element.cloneNode(deep: true));
}