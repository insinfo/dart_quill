import '../blots/abstract/blot.dart';
import '../blots/inline.dart';
import '../platform/dom.dart';
import '../platform/platform.dart';

class Bold extends InlineBlot {
  Bold(DomElement domNode) : super(domNode);

  static const String kBlotName = 'bold';
  static const int kScope = Scope.INLINE_BLOT;
  static const List<String> kTagNames = ['STRONG', 'B'];

  static Bold create([dynamic value]) {
    final node = domBindings.adapter.document.createElement(kTagNames.first);
    return Bold(node);
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
      parent?.insertBefore(Bold.create(), next);
    }
  }

  @override
  void format(String name, dynamic value) {
    if (name == kBlotName && value == false) {
      unwrap();
      return;
    }
    super.format(name, value);
  }

  @override
  Bold clone() => Bold(element.cloneNode(deep: true));
}