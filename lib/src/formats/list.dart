import '../blots/abstract/blot.dart';
import '../platform/dom.dart';
import '../platform/platform.dart';

class ListContainer extends ContainerBlot {
  ListContainer(DomElement domNode) : super(domNode);

  static const String kBlotName = 'list-container';
  static const int kScope = Scope.BLOCK_BLOT;

  static ListContainer create(String value) {
    final tag = value == 'ordered' ? 'ol' : 'ul';
    final node = domBindings.adapter.document.createElement(tag.toUpperCase());
    node.dataset['list'] = tag;
    return ListContainer(node);
  }

  static ListContainer? wrap(Blot blot) {
    if (blot.parent is ListContainer) {
      return null;
    }
    final node = domBindings.adapter.document.createElement('OL');
    node.dataset['list'] = 'ordered';
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

class ListItem extends BlockBlot {
  ListItem(DomElement domNode) : super(domNode);

  static const String kBlotName = 'list';
  static const String kTagName = 'LI';
  static const int kScope = Scope.BLOCK_BLOT;
  static const Type requiredContainer = ListContainer;

  static ListItem create(String value) {
    final node = domBindings.adapter.document.createElement(kTagName);
    if (value == 'checked' || value == 'unchecked') {
      node.dataset['list'] = value;
    }
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
        'list': {
          'type': parentFormats['list'],
          'checked': marker == 'checked',
        }
      };
    }
    return parentFormats;
  }

  @override
  void format(String name, dynamic value) {
    if (name != kBlotName) {
      super.format(name, value);
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

    // Ensure proper container
    final parent = this.parent;
    if (parent != null && parent is! ListContainer) {
      final container = ListContainer.wrap(this);
      if (container != null) {
        container.appendChild(this);
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

  @override
  int length() {
    return super.length() + 1; // Account for the list marker
  }
}
