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
    final parentBlot = parent;
    if (parentBlot is ParentBlot) {
      final reference = next;
      moveChildren(parentBlot, reference);
      parentBlot.removeChild(this);
    }
  }

  // wrap intentionally unimplemented in this simplified base.

  @override
  void optimize([
    List<DomMutationRecord>? mutations,
    Map<String, dynamic>? context,
  ]) {
    super.optimize(mutations, context);
    final parentInline = parent;
    if (parentInline is InlineBlot &&
        InlineBlot.compare(blotName, parentInline.blotName) > 0) {
      _reorderWithParent(parentInline);
    }
  }

  void _reorderWithParent(InlineBlot parentInline) {
    final grandParent = parentInline.parent;
    if (grandParent is! ParentBlot) {
      return;
    }

    final scrollBlot = parentInline.scroll;

    final children = List<Blot>.from(parentInline.children);
    final index = children.indexOf(this);
    if (index == -1) {
      return;
    }

    final beforeNodes = children.sublist(0, index);
    final afterNodes = children.sublist(index + 1);

    final reference = parentInline.next;

    // Detach all nodes from parentInline so we can redistribute them.
    for (final node in beforeNodes) {
      parentInline.removeChild(node);
    }
    parentInline.removeChild(this);
    for (final node in afterNodes) {
      parentInline.removeChild(node);
    }

    // Prepare wrappers in insertion order.
    final sequence = <Blot>[];

    if (beforeNodes.isNotEmpty) {
      for (final node in beforeNodes) {
        parentInline.appendChild(node);
      }
      sequence.add(parentInline);
    }

    final innerWrapper = scrollBlot.create(parentInline.blotName) as ParentBlot;
    moveChildren(innerWrapper, null);
    appendChild(innerWrapper);
    sequence.add(this);

    ParentBlot? afterWrapper;
    if (afterNodes.isNotEmpty) {
      afterWrapper = scrollBlot.create(parentInline.blotName) as ParentBlot;
      for (final node in afterNodes) {
        afterWrapper.appendChild(node);
      }
      sequence.add(afterWrapper);
    }

    // Ensure parentInline is not left dangling if unused.
    grandParent.removeChild(parentInline);

    for (final blot in sequence) {
      grandParent.insertBefore(blot, reference);
    }

    if (afterWrapper != null) {
      afterWrapper.optimize();
    }
    if (beforeNodes.isNotEmpty) {
      parentInline.optimize();
    }
  }
}
