import '../platform/dom.dart';
import 'abstract/blot.dart';

abstract class InlineBlot extends ParentBlot {
  static const List<Type> allowedChildren = [];
  static const List<String> order = [
    'cursor',
    'inline',
    'link',
    'underline',
    'strike',
    'italic',
    'bold',
    'script',
    'code',
  ];

  InlineBlot(DomElement domNode) : super(domNode);

  static int compare(String self, String other) {
    final selfIndex = InlineBlot.order.indexOf(self);
    final otherIndex = InlineBlot.order.indexOf(other);
    if (selfIndex >= 0 || otherIndex >= 0) {
      return selfIndex - otherIndex;
    }
    if (self == other) {
      return 0;
    }
    return self.compareTo(other);
  }

  @override
  void format(String name, dynamic value) {
    if (value) {
      addClass(name);
    } else {
      removeClass(name);
    }
  }

  @override
  void formatAt(int index, int length, String name, dynamic value) {
    // Delegate to base implementation
    super.formatAt(index, length, name, value);
  }

  @override
  Map<String, dynamic> formats() {
    return {
      for (final token in element.classes.values) token: true,
    };
  }

  void addClass(String name) {
    element.classes.add(name);
  }

  void removeClass(String name) {
    element.classes.remove(name);
  }

  void unwrap() {
    if (parent != null) {
      parent!.removeChild(this);
    }
  }

  // wrap intentionally unimplemented in this simplified base.

  @override
  void optimize([List<DomMutationRecord>? mutations, Map<String, dynamic>? context]) {
    super.optimize(mutations, context);
  }
}