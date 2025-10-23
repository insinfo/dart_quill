import 'dart:html' as html;

import 'dom.dart';

// Generic wrapper for any native DOM node.
// We can't have a common base class for HtmlDomElement and HtmlDomText
// since they need to extend different classes from dart:html.
// This class provides the common functionality from DomNode interface.
class _HtmlDomNode implements DomNode {
  _HtmlDomNode(this.node);

  final html.Node node;

  @override
  String get nodeName => node.nodeName ?? '';

  @override
  int get nodeType => node.nodeType;

  @override
  String? get textContent => node.text;

  @override
  void append(DomNode node) {
    this.node.append((node as _HtmlDomNode).node);
  }

  @override
  void insertBefore(DomNode node, DomNode? ref) {
    this.node.insertBefore(
      (node as _HtmlDomNode).node,
      ref == null ? null : (ref as _HtmlDomNode).node,
    );
  }

  @override
  void remove() {
    node.remove();
  }

  @override
  List<DomNode> get childNodes =>
      [for (final child in node.childNodes) _HtmlDomNode(child)];

  @override
  DomNode? get firstChild =>
      node.firstChild == null ? null : _HtmlDomNode(node.firstChild!);

  @override
  DomNode? get lastChild =>
      node.lastChild == null ? null : _HtmlDomNode(node.lastChild!);

  @override
  DomNode? get nextSibling =>
      node.nextNode == null ? null : _HtmlDomNode(node.nextNode!);

  @override
  DomNode? get parentNode =>
      node.parentNode == null ? null : _HtmlDomNode(node.parentNode!);

  @override
  DomNode? get previousSibling =>
      node.previousNode == null ? null : _HtmlDomNode(node.previousNode!);
}

class HtmlDomEvent implements DomEvent {
  final html.Event rawEvent;

  HtmlDomEvent(this.rawEvent);

  @override
  bool get defaultPrevented => rawEvent.defaultPrevented;

  @override
  void preventDefault() {
    rawEvent.preventDefault();
  }

  @override
  DomNode? get target {
    final t = rawEvent.target;
    return t == null ? null : _HtmlDomNode(t);
  }
}

class HtmlDomInputEvent extends HtmlDomEvent implements DomInputEvent {
  HtmlDomInputEvent(super.rawEvent);

  @override
  String? get inputType => (rawEvent as dynamic).inputType;
}

class HtmlDomMutationObserver implements DomMutationObserver {
  HtmlDomMutationObserver(this._native);

  final html.MutationObserver _native;

  @override
  void observe(
    DomNode target, {
    bool? subtree,
    bool? childList,
    bool? characterData,
  }) {
    _native.observe(
      (target as _HtmlDomNode).node,
      subtree: subtree,
      childList: childList,
      characterData: characterData,
    );
  }

  @override
  void disconnect() => _native.disconnect();

  @override
  List<DomMutationRecord> takeRecords() {
    return [for (final record in _native.takeRecords()) HtmlDomMutationRecord(record)];
  }
}

class HtmlDomMutationRecord implements DomMutationRecord {
  HtmlDomMutationRecord(this._native);

  final html.MutationRecord _native;

  @override
  DomNode get target => _HtmlDomNode(_native.target!);

  @override
  String get type => _native.type!;

  @override
  List<DomNode> get addedNodes => [for (final node in _native.addedNodes!) _HtmlDomNode(node)];

  @override
  List<DomNode> get removedNodes => [for (final node in _native.removedNodes!) _HtmlDomNode(node)];

  @override
  DomNode? get previousSibling => _native.previousSibling == null ? null : _HtmlDomNode(_native.previousSibling!);

  @override
  DomNode? get nextSibling => _native.nextSibling == null ? null : _HtmlDomNode(_native.nextSibling!);
}

class HtmlDomClipboardEvent extends HtmlDomEvent implements DomClipboardEvent {
  HtmlDomClipboardEvent(super.rawEvent);

  @override
  DomDataTransfer? get clipboardData {
    final data = (rawEvent as html.ClipboardEvent).clipboardData;
    return data == null ? null : HtmlDomDataTransfer(data);
  }
}

class HtmlDomDataTransfer implements DomDataTransfer {
  final html.DataTransfer _native;

  HtmlDomDataTransfer(this._native);

  @override
  List<DomFile> get files =>
      _native.files?.map((f) => HtmlDomFile(f)).toList() ?? [];

  @override
  String? getData(String format) {
    return _native.getData(format);
  }

  @override
  void setData(String format, String data) {
    _native.setData(format, data);
  }
}

class HtmlDomFile implements DomFile {
  final html.File _native;

  HtmlDomFile(this._native);

  @override
  String get name => _native.name;

  @override
  int get size => _native.size;

  @override
  String get type => _native.type;
}

class HtmlDomAdapter implements DomAdapter {
  @override
  late final DomDocument document;

  HtmlDomAdapter() {
    document = HtmlDomDocument();
  }

  @override
  DomMutationObserver createMutationObserver(
      void Function(List<DomMutationRecord> mutations, DomMutationObserver observer)
          callback) {
    late HtmlDomMutationObserver observer;
    final nativeObserver = html.MutationObserver((mutations, nativeObserver) {
      callback([for (final m in mutations) HtmlDomMutationRecord(m)], observer);
    });
    observer = HtmlDomMutationObserver(nativeObserver);
    return observer;
  }
}

class HtmlDomDocument implements DomDocument {
  @override
  DomElement createElement(String tag) {
    return HtmlDomElement(html.Element.tag(tag));
  }

  @override
  DomText createTextNode(String value) => HtmlDomText(html.Text(value));

  @override
  List<DomElement> querySelectorAll(String selectors) {
    return html.document
        .querySelectorAll(selectors)
        .map((e) => HtmlDomElement(e))
        .toList();
  }

  @override
  DomElement? querySelector(String selectors) {
    final element = html.document.querySelector(selectors);
    return element == null ? null : HtmlDomElement(element);
  }

  @override
  DomElement get body => HtmlDomElement(html.document.body!);

  @override
  DomParser get parser => HtmlDomParser();
}

class HtmlDomParser implements DomParser {
  final html.DomParser _native = html.DomParser();

  @override
  DomDocument parseFromString(String string, String type) {
    final doc = _native.parseFromString(string, type);
    // We need a way to represent a document without wrapping the global one.
    // For now, let's create a new HtmlDomDocument that can wrap this specific doc.
    // This part of the abstraction might need refinement.
    return _HtmlDomDocumentWrapper(doc);
  }
}

// A wrapper for a parsed document, to distinguish from the main `html.document`.
class _HtmlDomDocumentWrapper extends HtmlDomDocument {
  final html.HtmlDocument _doc;

  _HtmlDomDocumentWrapper(this._doc);

  @override
  DomElement createElement(String tag) {
    return HtmlDomElement(_doc.createElement(tag));
  }

  @override
  DomElement? querySelector(String selectors) {
    final element = _doc.querySelector(selectors);
    return element == null ? null : HtmlDomElement(element);
  }

  @override
  List<DomElement> querySelectorAll(String selectors) {
    return _doc.querySelectorAll(selectors).map((e) => HtmlDomElement(e)).toList();
  }

  @override
  DomElement get body => HtmlDomElement(_doc.body!);
}

class HtmlDomElement extends _HtmlDomNode implements DomElement {
  HtmlDomElement(html.HtmlElement element) : super(element);

  html.HtmlElement get _element => node as html.HtmlElement;

  final Map<DomEventListener, html.EventListener> _listeners = {};

  @override
  String? get id => _element.id;

  @override
  String? get className => _element.className;

  @override
  dynamic get style => _element.style;

  @override
  String get tagName => _element.tagName;

  @override
  String? get text => _element.text;

  @override
  set text(String? value) {
    _element.text = value;
  }

  @override
  DomDocument get ownerDocument =>
      _HtmlDomDocumentWrapper(_element.ownerDocument as html.HtmlDocument);

  @override
  DomClassList get classes => _HtmlDomClassList(_element.classes);

  @override
  Map<String, String> get dataset => _element.dataset;

  @override
  void setAttribute(String name, String value) {
    _element.setAttribute(name, value);
  }

  @override
  String? getAttribute(String name) {
    return _element.getAttribute(name);
  }

  @override
  bool hasAttribute(String name) {
    return _element.hasAttribute(name);
  }

  @override
  void removeAttribute(String name) {
    _element.removeAttribute(name);
  }

  @override
  void addEventListener(String type, DomEventListener listener) {
    final l = (html.Event event) {
      if (type == 'beforeinput') {
        listener(HtmlDomInputEvent(event));
      } else if (['copy', 'cut', 'paste'].contains(type)) {
        listener(HtmlDomClipboardEvent(event));
      } else {
        listener(HtmlDomEvent(event));
      }
    };
    _listeners[listener] = l;
    _element.addEventListener(type, l);
  }

  @override
  void removeEventListener(String type, DomEventListener listener) {
    final l = _listeners.remove(listener);
    if (l != null) {
      _element.removeEventListener(type, l);
    }
  }

  @override
  DomElement cloneNode({bool deep = false}) {
    return HtmlDomElement(_element.clone(deep) as html.HtmlElement);
  }

  @override
  void replaceWith(DomElement node) {
    _element.replaceWith((node as HtmlDomElement)._element);
  }

  @override
  void appendText(String value) {
    _element.appendText(value);
  }

  @override
  List<DomElement> querySelectorAll(String selectors) {
    return _element.querySelectorAll(selectors).map((e) => HtmlDomElement(e as html.HtmlElement)).toList();
  }

  @override
  bool contains(DomNode? node) {
    if (node == null) return false;
    final htmlNode = (node as _HtmlDomNode).node;
    return _element.contains(htmlNode);
  }

  @override
  DomElement? querySelector(String selector) {
    final element = _element.querySelector(selector);
    return element == null ? null : HtmlDomElement(element as html.HtmlElement);
  }

  @override
  int get scrollTop => _element.scrollTop;

  @override
  set scrollTop(int value) {
    _element.scrollTop = value;
  }

  @override
  int get offsetWidth => _element.offsetWidth;

  @override
  String? get innerHTML => _element.innerHtml;

  @override
  set innerHTML(String? value) {
    _element.innerHtml = value;
  }
}

class HtmlDomText extends _HtmlDomNode implements DomText {
  HtmlDomText(html.Text text) : super(text);

  html.Text get _text => node as html.Text;

  @override
  String get data => _text.data ?? '';

  @override
  set data(String value) {
    _text.data = value;
  }
}

class _HtmlDomClassList implements DomClassList {
  _HtmlDomClassList(this._native);

  final html.CssClassSet _native;

  @override
  Iterable<String> get values => _native;

  @override
  bool contains(String token) => _native.contains(token);

  @override
  void add(String token) => _native.add(token);

  @override
  void remove(String token) => _native.remove(token);

  @override
  void toggle(String token, [bool? force]) => _native.toggle(token, force);
}
