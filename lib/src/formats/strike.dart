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
  void optimize([
    List<DomMutationRecord>? mutations,
    Map<String, dynamic>? context,
  ]) {
    super.optimize(mutations, context);
    // Parity: TS Strike extends Bold — normalize <strike> to <s> and merge
    // adjacent equal siblings.
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
    if (previous is Strike && previous.parent == parent) {
      moveChildren(previous, null);
      remove();
      previous.optimize(mutations, context);
      return;
    }

    final following = next;
    if (following is Strike && following.parent == parent) {
      following.moveChildren(this, null);
      following.remove();
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
  Strike clone() => Strike(element.cloneNode(deep: true));
}
