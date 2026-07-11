import '../blots/abstract/blot.dart';
import '../blots/block.dart';
import '../platform/dom.dart';
import '../platform/platform.dart';

class ListContainer extends ContainerBlot {
  ListContainer(DomElement domNode) : super(domNode);

  static const String kBlotName = 'list-container';
  static const int kScope = Scope.BLOCK_BLOT;

  static ListContainer create(String value) {
    final type = (value == 'ordered' || value == 'bullet') ? value : 'ordered';
    final tag = type == 'ordered' ? 'OL' : 'UL';
    final node = domBindings.adapter.document.createElement(tag);
    node.dataset['list'] = type;
    return ListContainer(node);
  }

  @override
  String get blotName => kBlotName;

  @override
  int get scope => kScope;

  @override
  dynamic value() => children.map((child) => child.value()).toList();

  @override
  Map<String, dynamic> formats() {
    final type = element.dataset['list'];
    if (type == 'ordered' || type == 'bullet') {
      return {'list': type};
    }
    final tag = element.tagName.toLowerCase();
    if (tag == 'ol') return {'list': 'ordered'};
    if (tag == 'ul') return {'list': 'bullet'};
    return const {};
  }

  @override
  void format(String name, dynamic value) {
    if (name != 'list') {
      super.format(name, value);
      return;
    }
    final type = value == 'ordered' ? 'ordered' : 'bullet';
    element.dataset['list'] = type;
  }

  @override
  ListContainer clone() => ListContainer(element.cloneNode(deep: true));

  void mergeWith(ListContainer other) {
    // Move all children from other list to this list
    while (other.children.isNotEmpty) {
      final child = other.children.first;
      insertBefore(child, null);
    }
    other.remove();
  }
}

// Mirrors quill's list.ts where ListItem extends Block, so line-level
// machinery (isLine, getFormat, newline accounting) treats it as a line.
class ListItem extends Block {
  ListItem(DomElement domNode) : super(domNode);

  static const String kBlotName = 'list';
  static const String kTagName = 'LI';
  static const int kScope = Scope.BLOCK_BLOT;
  static const Type requiredContainer = ListContainer;

  static ListItem create(String value) {
    final node = domBindings.adapter.document.createElement(kTagName);
    // The type is kept on the item until optimize() wraps it into the
    // matching ListContainer (ordered/bullet move to the container;
    // checked/unchecked stay on the item).
    node.dataset['list'] = value;
    return ListItem(node);
  }

  @override
  String get blotName => kBlotName;

  @override
  int get scope => kScope;

  @override
  Map<String, dynamic> formats() {
    final Map<String, dynamic> parentFormats = parent is ListContainer
        ? (parent as ListContainer).formats()
        : const <String, dynamic>{};
    final marker = element.dataset['list'];
    if (marker == 'checked' || marker == 'unchecked') {
      return {
        ...super.formats(),
        'list': {
          'type': parentFormats['list'],
          'checked': marker == 'checked',
        }
      };
    }
    return {...super.formats(), ...parentFormats};
  }

  @override
  void format(String name, dynamic value) {
    if (name != kBlotName) {
      super.format(name, value);
      return;
    }
    if (value == null || value == false) {
      // Match Quill's ListItem.format: clearing the list delegates to Block,
      // which replaces the <li> with a normal paragraph. Our list container
      // is explicit, so place that paragraph beside (not inside) the list.
      final list = parent;
      final outer = list?.parent;
      if (list is ListContainer && outer != null) {
        final replacement = scroll.create(Block.kBlotName) as Block;
        outer.insertBefore(replacement, list);
        moveChildren(replacement, null);
        for (final entry in super.formats().entries) {
          if (entry.key != kBlotName) {
            replacement.format(entry.key, entry.value);
          }
        }
        remove();
        if (list.children.isEmpty) {
          list.remove();
        }
      } else {
        super.format(name, value);
      }
      return;
    }
    if (value is Map) {
      final checked = value['checked'];
      if (checked != null) {
        element.dataset['list'] = checked ? 'checked' : 'unchecked';
      }
      if (parent != null && value['type'] != null) {
        parent!.format('list', value['type']);
      }
    } else {
      element.dataset.remove('list');
      parent?.format('list', value);
    }
  }

  @override
  void optimize(
      [List<DomMutationRecord>? mutations, Map<String, dynamic>? context]) {
    super.optimize(mutations, context);

    // Ensure proper container: mirror parchment's wrap() — the container is
    // inserted into the tree BEFORE the item is moved into it.
    final parent = this.parent;
    if (parent != null && parent is! ListContainer) {
      final marker = element.dataset['list'];
      final type =
          (marker == 'ordered' || marker == 'bullet') ? marker! : 'ordered';
      final container = ListContainer.create(type);
      parent.insertBefore(container, this);
      container.appendChild(this);
      if (marker == 'ordered' || marker == 'bullet') {
        element.dataset.remove('list');
        element.removeAttribute('data-list');
      }
    }

    // Merge adjacent lists of same type
    if (parent != null && parent is ListContainer) {
      if (prev != null && prev is ListItem) {
        final prevParent = prev!.parent;
        if (prevParent != null &&
            prevParent != parent &&
            prevParent is ListContainer &&
            prevParent.formats()['list'] == parent.formats()['list']) {
          parent.mergeWith(prevParent);
        }
      }
      if (next != null && next is ListItem) {
        final nextParent = next!.parent;
        if (nextParent != null &&
            nextParent != parent &&
            nextParent is ListContainer &&
            nextParent.formats()['list'] == parent.formats()['list']) {
          parent.mergeWith(nextParent);
        }
      }
    }

    // Handle empty lists
    if (parent != null && parent is ListContainer && parent.children.isEmpty) {
      parent.remove();
    }
  }

  @override
  ListItem clone() => ListItem(element.cloneNode(deep: true));
}
