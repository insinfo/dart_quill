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
    // Parity: TS Italic extends Bold and inherits its optimize — normalize
    // <i> to <em> moving the children into the replacement (the previous
    // unwrap+insertBefore dropped the content), then merge equal siblings.
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
    if (previous is Italic && previous.parent == parent) {
      moveChildren(previous, null);
      remove();
      previous.optimize(mutations, context);
      return;
    }

    final following = next;
    if (following is Italic && following.parent == parent) {
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
  Italic clone() => Italic(element.cloneNode(deep: true));
}