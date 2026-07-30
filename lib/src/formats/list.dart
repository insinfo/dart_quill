import '../blots/abstract/blot.dart';
import '../blots/block.dart';
import '../blots/scroll.dart';
import '../core/emitter.dart';
import '../platform/dom.dart';
import '../platform/platform.dart';

/// Parity quill `formats/list.ts` — the upstream data model, exactly:
/// the container is ALWAYS an `<ol>` and carries no value; the whole list
/// format ('ordered' | 'bullet' | 'checked' | 'unchecked') lives in the
/// `data-list` attribute of each `<li>`. Two adjacent lists of different
/// kinds are one `<ol>` whose items differ in `data-list` — rendering is
/// CSS's job (`li[data-list=bullet]` etc.), not the DOM structure's.
class ListContainer extends ContainerBlot {
  ListContainer(DomElement domNode) : super(domNode);

  static const String kBlotName = 'list-container';
  static const String kTagName = 'OL';
  static const int kScope = Scope.BLOCK_BLOT;

  static ListContainer create([dynamic value]) {
    if (value is DomElement) return ListContainer(value);
    return ListContainer(domBindings.adapter.document.createElement(kTagName));
  }

  @override
  String get blotName => kBlotName;

  @override
  int get scope => kScope;

  // Parity list.ts: `ListContainer.allowedChildren = [ListItem]`. This is what
  // pops a paragraph out of the `<ol>` when a line's list format is cleared.
  @override
  bool Function(Blot child)? get allowedChildren => (child) => child is ListItem;

  @override
  ListContainer clone() => ListContainer(element.cloneNode(deep: false));
}

/// Parity quill `formats/list.ts` ListItem.
class ListItem extends Block {
  ListItem(DomElement domNode) : super(domNode) {
    // Parity list.ts:26-41 — the checklist toggle is wired in the constructor
    // and attached as the line's UI node.
    final ui = domNode.ownerDocument.createElement('span');
    void toggleChecklist(DomEvent event) {
      final root = scroll;
      if (root is Scroll && !root.isEnabled()) return;
      final format = element.getAttribute('data-list');
      if (format == 'checked') {
        this.format('list', 'unchecked');
        event.preventDefault();
      } else if (format == 'unchecked') {
        this.format('list', 'checked');
        event.preventDefault();
      } else {
        return;
      }
      // `format` only writes `data-list` on the element. Upstream learns of it
      // through the MutationObserver, which watches attributes; this port's
      // observer does not (see the note in scroll.dart / G12), so without this
      // the checkbox flipped on screen while `getContents()` kept reporting
      // the old state — the toggle was invisible to the application.
      _announceChange(root);
    }

    ui.addEventListener('mousedown', toggleChecklist);
    ui.addEventListener('touchstart', toggleChecklist);
    attachUI(ui);
  }

  /// Announces a DOM-only change through the same event a real mutation takes
  /// (`SCROLL_UPDATE` → `Quill.modify(editor.update)`), so the document delta
  /// and TEXT_CHANGE match what upstream's attribute-observing MutationObserver
  /// produces.
  void _announceChange(Blot? root) {
    if (root is! Scroll) return;
    root.emitter.emit(
      EmitterEvents.SCROLL_UPDATE,
      EmitterSource.USER,
      const <DomMutationRecord>[],
    );
  }

  static const String kBlotName = 'list';
  static const String kTagName = 'LI';
  static const int kScope = Scope.BLOCK_BLOT;

  static ListItem create([dynamic value]) {
    if (value is DomElement) return ListItem(value);
    final node = domBindings.adapter.document.createElement(kTagName);
    if (value != null && value != false && '$value'.isNotEmpty) {
      node.setAttribute('data-list', '$value');
    }
    return ListItem(node);
  }

  @override
  String get blotName => kBlotName;

  @override
  int get scope => kScope;

  @override
  Map<String, dynamic> formats() {
    // Parity list.ts:20-22 — the value is the `data-list` attribute.
    final list = element.getAttribute('data-list');
    return {
      ...super.formats(),
      if (list != null && list.isNotEmpty) kBlotName: list,
    };
  }

  @override
  void format(String name, dynamic value) {
    // Parity list.ts:43-49 — a truthy list value only rewrites `data-list`;
    // everything else (including clearing) is Block's business, which
    // replaces the `<li>` with a paragraph that the container then expels.
    final truthy = value != null && value != false && value != '';
    if (name == kBlotName && truthy) {
      element.setAttribute('data-list', '$value');
      // The line's delta is cached, and writing an attribute leaves the blot
      // tree untouched: upstream invalidates through the MutationObserver,
      // which watches attributes. Without this the `<li>` renders as checked
      // while `getContents()` keeps reporting the old value.
      invalidateCache();
    } else {
      super.format(name, value);
    }
  }

  @override
  ListItem clone() => ListItem(element.cloneNode(deep: false));
}
