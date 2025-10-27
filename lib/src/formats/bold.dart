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
    if (value is DomElement) {
      return Bold(value);
    }
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
      final parentBlot = parent;
      if (parentBlot is ParentBlot) {
        final replacement = scroll.create(kBlotName) as ParentBlot;
        parentBlot.insertBefore(replacement, next);
        moveChildren(replacement, null);
        remove();
        replacement.optimize(mutations, context);
        return;
      }
    }

    final previous = prev;
    if (previous is Bold && previous.parent == parent) {
      moveChildren(previous, null);
      remove();
      previous.optimize(mutations, context);
      return;
    }

    final nextBold = next;
    if (nextBold is Bold && nextBold.parent == parent) {
      nextBold.moveChildren(this, null);
      nextBold.remove();
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
