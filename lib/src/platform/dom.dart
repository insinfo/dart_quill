typedef DomEventListener = void Function(DomEvent event);

// Abstractions to decouple the rest of the codebase from dart:html.
// These interfaces capture only the subset of behaviours the current
// implementation relies on, making it possible to provide alternative
// adapters (e.g. mocks in tests or platform specific integrations).

/// Generic DOM node abstraction.
abstract class DomNode {
  static const int ELEMENT_NODE = 1;
  static const int TEXT_NODE = 3;

  /// A stable object identifying the underlying node, usable as an [Expando]
  /// key.
  ///
  /// An adapter that wraps a platform node hands out a NEW wrapper on every
  /// DOM access — `element.parentNode` twice gives two objects for one node.
  /// The wrappers compare equal, but `Expando` is keyed by *identity*, so
  /// storing anything against a wrapper silently loses it on the next lookup.
  /// Adapters return the wrapped node here; the fake DOM, whose wrappers are
  /// the nodes, returns itself.
  Object get identityKey;

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

  /// Names of all attributes present on the element.
  List<String> get attributeNames;

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

  /// Dispatch a trusted click when supported by the platform element.
  void click();

  /// Get or set the scroll position (vertical).
  int get scrollTop;
  set scrollTop(int value);

  /// Get or set the scroll position (horizontal).
  int get scrollLeft;
  set scrollLeft(int value);

  /// Get the element's width including padding and border.
  int get offsetWidth;

  /// Get the element's height including padding and border.
  int get offsetHeight;

  /// Get the element's client width (inside padding).
  int get clientWidth;

  /// Get the element's client height (inside padding).
  int get clientHeight;

  /// Scroll by a relative amount, optionally using smooth browser behavior.
  void scrollBy(double left, double top, {bool smooth = false});

  /// Get or set the HTML content inside the element.
  String? get innerHTML;
  set innerHTML(String? value);

  /// The element's own serialization, tags included (DOM `outerHTML`).
  /// Used by the semantic HTML converter (editor.ts convertHTML), which
  /// splits it around the innerHTML to recover the open/close tags.
  String get outerHTML;

  /// Get or set the value of an input or textarea element.
  String get value;
  set value(String? val);
}

/// Abstraction for text nodes.
abstract class DomText extends DomNode {
  String get data;
  set data(String value);
}

/// Abstraction for documents so code can remain agnostic to the concrete DOM.
abstract class DomDocument {
  /// See [DomNode.identityKey] — the document is wrapped per access too.
  Object get identityKey;

  DomElement createElement(String tag);
  DomText createTextNode(String value);
  void addEventListener(String type, DomEventListener listener);
  void removeEventListener(String type, DomEventListener listener);
  DomElement? querySelector(String selectors);
  List<DomElement> querySelectorAll(String selectors);
  DomElement get body;
  DomElement get documentElement;
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
  void observe(DomNode target,
      {bool? subtree,
      bool? childList,
      bool? characterData,
      bool? attributes,
      bool? characterDataOldValue});
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
  void stopPropagation();
  dynamic get rawEvent;
  DomNode? get target;
}

/// DOM input event abstraction.
abstract class DomInputEvent extends DomEvent {
  String? get inputType;
  String? get data;
  DomDataTransfer? get dataTransfer;
  List<DomNativeRange> getTargetRanges();

  /// True enquanto uma composição IME está em curso.
  ///
  /// Na interface (e não só no evento concreto do browser) porque qualquer
  /// pipeline de entrada precisa distinguir composição de digitação: um
  /// `beforeinput` de composição não é cancelável de forma confiável, então
  /// tratá-lo como digitação normal corrompe o documento em CJK, acentos
  /// mortos e autocorreção de mobile.
  bool get isComposing;
}

/// DOM clipboard event abstraction.
abstract class DomClipboardEvent extends DomEvent {
  DomDataTransfer? get clipboardData;
}

/// DOM mouse/pointer event abstraction.
///
/// `detail` is the click counter browsers expose on `MouseEvent`; table-better
/// uses `detail >= 3` to recognise a triple click.
abstract class DomMouseEvent extends DomEvent {
  num get clientX;
  num get clientY;

  /// The payload of a drag/drop, when this is a drag event (`DragEvent`
  /// extends `MouseEvent` in the DOM, so drops arrive here). Null otherwise.
  DomDataTransfer? get dataTransfer;

  int get detail;
  bool get altKey;
  bool get ctrlKey;
  bool get metaKey;
  bool get shiftKey;
}

/// DOM keyboard event abstraction.
abstract class DomKeyboardEvent extends DomEvent {
  String get key;
  int? get keyCode;
  bool get altKey;
  bool get ctrlKey;
  bool get metaKey;
  bool get shiftKey;

  /// True enquanto uma composição IME está em curso.
  ///
  /// Um `keydown` de composição chega com a tecla física (e keyCode 229 em
  /// vários browsers); tratá-lo como atalho dispararia comandos no meio de
  /// uma palavra sendo composta.
  bool get isComposing;
}

/// DOM data transfer abstraction.
abstract class DomDataTransfer {
  List<DomFile> get files;
  List<String> get types;
  String? getData(String format);
  void setData(String format, String data);
}

/// A text selection expressed as plain-text offsets inside an editor root.
class DomSelectionRange {
  const DomSelectionRange(this.index, this.length);

  final int index;
  final int length;
}

/// A browser range expressed with DOM nodes and offsets.
///
/// This is used for `InputEvent.getTargetRanges()` and native selection
/// handling without leaking `package:web` types into the editor core.
class DomNativeRange {
  const DomNativeRange({
    required this.startContainer,
    required this.startOffset,
    required this.endContainer,
    required this.endOffset,
  });

  final DomNode startContainer;
  final int startOffset;
  final DomNode endContainer;
  final int endOffset;

  bool get collapsed =>
      startContainer == endContainer && startOffset == endOffset;
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
      void Function(
              List<DomMutationRecord> mutations, DomMutationObserver observer)
          callback);
  DomSelectionRange? getSelectionRange(DomElement root);
  DomNativeRange? getNativeSelectionRange();

  /// The caret position at viewport coordinates ([x], [y]).
  ///
  /// Wraps `document.caretRangeFromPoint` / `caretPositionFromPoint`, which is
  /// how a drop lands where the pointer is instead of at the old selection.
  /// Adapters without layout return null.
  DomNativeRange? caretRangeFromPoint(num x, num y);
  void setSelectionRange(DomElement root, int index, int length);
  void setSelectionByNodes(
      DomNode startNode, int startOffset, DomNode endNode, int endOffset);
  Map<String, dynamic>? getBounds(DomElement root, int index, int length);
  Map<String, dynamic>? getRangeBounds(
    DomNode startNode,
    int startOffset,
    DomNode endNode,
    int endOffset,
  );
  Map<String, dynamic>? getElementBounds(DomElement element,
      {DomElement? relativeTo});
  DomElement? getParentElement(DomElement element);
  Map<String, double> getViewportBounds(DomDocument document);
  String getComputedStyleProperty(DomElement element, String property);
  Future<String?> readFileAsDataUrl(dynamic file);
  void focus(DomElement element);

  /// Removes focus from [element] when it currently holds it.
  void blur(DomElement element);

  /// Whether this platform exposes a real native selection
  /// (`document.getSelection()`); false on the VM / fake DOM, where the
  /// Selection keeps its logical model instead.
  bool get supportsNativeSelection;

  /// Whether `document.activeElement` is [root] or a descendant of it
  /// (parity selection.ts `hasFocus`).
  bool hasFocus(DomElement root);

  /// `document.getSelection().removeAllRanges()`.
  void clearNativeSelection();
  String? get userAgent;
  String? get platform;
}

/// Represents a parser for DOM.
abstract class DomParser {
  DomDocument parseFromString(String string, String type);
}
