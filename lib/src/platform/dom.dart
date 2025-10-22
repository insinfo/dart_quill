// Abstractions to decouple the rest of the codebase from dart:html.
// These interfaces capture only the subset of behaviours the current
// implementation relies on, making it possible to provide alternative
// adapters (e.g. mocks in tests or platform specific integrations).

/// Generic DOM node abstraction.
abstract class DomNode {
  DomNode? get parentNode;
  DomNode? get previousSibling;
  DomNode? get nextSibling;

  /// All direct child nodes.
  List<DomNode> get childNodes;

  DomNode? get firstChild;
  DomNode? get lastChild;

  void append(DomNode node);
  void insertBefore(DomNode node, DomNode? referenceNode);
  void remove();
}

/// Abstraction for DOM elements (nodes with tag names and attributes).
abstract class DomElement extends DomNode {
  String get tagName;
  DomDocument get ownerDocument;

  String? get text;
  set text(String? value);

  DomClassList get classes;

  Map<String, String> get dataset;

  void setAttribute(String name, String value);
  String? getAttribute(String name);
  bool hasAttribute(String name);
  void removeAttribute(String name);

  void addEventListener(String type, DomEventListener listener);
  void removeEventListener(String type, DomEventListener listener);

  DomElement cloneNode({bool deep = false});
  void replaceWith(DomElement node);

  /// Convenience helper for appending raw text.
  void appendText(String value);
}

/// Abstraction for text nodes.
abstract class DomText extends DomNode {
  String get data;
  set data(String value);
}

/// Abstraction for documents so code can remain agnostic to the concrete DOM.
abstract class DomDocument {
  DomElement createElement(String tagName);
  DomText createTextNode(String value);
  DomElement get body;
}

/// Represents a class list on an element (usually `classList`).
abstract class DomClassList {
  Iterable<String> get values;
  bool contains(String token);
  void add(String token);
  void remove(String token);
  void toggle(String token, [bool? force]);
}

/// Represents a mutation observer abstraction.
abstract class DomMutationObserver {
  void observe(DomNode target, {bool? subtree, bool? childList, bool? characterData});
  void disconnect();
  List<DomMutationRecord> takeRecords();
}

/// Represents a DOM mutation record abstraction.
abstract class DomMutationRecord {
  DomNode get target;
  String get type;
  List<DomNode> get addedNodes;
  List<DomNode> get removedNodes;
  DomNode? get previousSibling;
  DomNode? get nextSibling;
}

/// DOM event abstraction used by the editor code.
abstract class DomEvent {
  void preventDefault();
}

typedef DomEventListener = void Function(DomEvent event);

/// Factory responsible for obtaining the concrete DOM adapter.
abstract class DomAdapter {
  DomDocument get document;
  DomMutationObserver createMutationObserver(void Function(List<DomMutationRecord> records, DomMutationObserver observer) callback);
  DomEvent createEvent(String type);
}
