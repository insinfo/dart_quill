typedef DomEventListener = void Function(DomEvent event);

// Abstractions to decouple the rest of the codebase from dart:html.
// These interfaces capture only the subset of behaviours the current
// implementation relies on, making it possible to provide alternative
// adapters (e.g. mocks in tests or platform specific integrations).

/// Generic DOM node abstraction.
abstract class DomNode {
  static const int ELEMENT_NODE = 1;
  static const int TEXT_NODE = 3;

  String get nodeName;
  int get nodeType;
  String? get textContent;

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

  String? get id;
  String? get className;
  dynamic get style;

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

  List<DomElement> querySelectorAll(String selectors);

  DomElement cloneNode({bool deep = false});
  void replaceWith(DomElement node);

  /// Convenience helper for appending raw text.
  void appendText(String value);

  /// Check if this element contains the given node.
  bool contains(DomNode? node);

  /// Query for a single element matching the selector.
  DomElement? querySelector(String selector);

  /// Select the contents of a textual input element.
  void select();

  /// Get or set the scroll position (vertical).
  int get scrollTop;
  set scrollTop(int value);

  /// Get the element's width including padding and border.
  int get offsetWidth;

  /// Get or set the HTML content inside the element.
  String? get innerHTML;
  set innerHTML(String? value);
}

/// Abstraction for text nodes.
abstract class DomText extends DomNode {
  String get data;
  set data(String value);
}

/// Abstraction for documents so code can remain agnostic to the concrete DOM.
abstract class DomDocument {
  DomElement createElement(String tag);
  DomText createTextNode(String value);
  DomElement? querySelector(String selectors);
  List<DomElement> querySelectorAll(String selectors);
  DomElement get body;
  DomParser get parser;
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
  bool get defaultPrevented;
  void preventDefault();
  dynamic get rawEvent;
  DomNode? get target;
}

/// DOM input event abstraction.
abstract class DomInputEvent extends DomEvent {
  String? get inputType;
}

/// DOM clipboard event abstraction.
abstract class DomClipboardEvent extends DomEvent {
  DomDataTransfer? get clipboardData;
}

/// DOM data transfer abstraction.
abstract class DomDataTransfer {
  List<DomFile> get files;
  String? getData(String format);
  void setData(String format, String data);
}

/// DOM file abstraction.
abstract class DomFile {
  String get name;
  String get type;
  int get size;
}

/// Factory responsible for obtaining the concrete DOM adapter.
abstract class DomAdapter {
  DomDocument get document;
  DomMutationObserver createMutationObserver(
      void Function(List<DomMutationRecord> mutations, DomMutationObserver observer)
          callback);
}


/// Represents a parser for DOM.
abstract class DomParser {
  DomDocument parseFromString(String string, String type);
}
