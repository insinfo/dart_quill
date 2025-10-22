import 'dart:html' as html;

import 'dom.dart';

class HtmlDomAdapter implements DomAdapter {
  HtmlDomAdapter({html.HtmlDocument? document})
  : _document = document ?? html.document;

  final html.HtmlDocument _document;

  @override
  DomDocument get document => HtmlDomDocument(_document);

  @override
  DomMutationObserver createMutationObserver(
    void Function(List<DomMutationRecord> records, DomMutationObserver observer) callback,
  ) {
    final observer = html.MutationObserver((records, obs) {
      callback(records.map(HtmlDomMutationRecord.new).toList(), HtmlDomMutationObserver(obs));
    });
    return HtmlDomMutationObserver(observer);
  }

  @override
  DomEvent createEvent(String type) => HtmlDomEvent(html.Event(type));
}

class HtmlDomDocument implements DomDocument {
  HtmlDomDocument(this._document);

  final html.HtmlDocument _document;

  @override
  DomElement createElement(String tagName) => HtmlDomElement(_document.createElement(tagName));

  @override
  DomText createTextNode(String value) => HtmlDomText(html.Text(value));

  @override
  DomElement get body => HtmlDomElement(_document.body!);
}

class HtmlDomNode implements DomNode {
  HtmlDomNode(this.node);

  final html.Node node;

  @override
  void append(DomNode node) {
    this.node.append((node as HtmlDomNode).node);
  }

  @override
  List<DomNode> get childNodes =>
      [for (final child in node.childNodes) HtmlDomNode(child)];

  @override
  DomNode? get firstChild => node.firstChild == null ? null : HtmlDomNode(node.firstChild!);

  @override
  DomNode? get lastChild => node.lastChild == null ? null : HtmlDomNode(node.lastChild!);

  @override
  DomNode? get nextSibling => node.nextNode == null ? null : HtmlDomNode(node.nextNode!);

  @override
  DomNode? get parentNode => node.parentNode == null ? null : HtmlDomNode(node.parentNode!);

  @override
  DomNode? get previousSibling => node.previousNode == null ? null : HtmlDomNode(node.previousNode!);

  @override
  void insertBefore(DomNode node, DomNode? referenceNode) {
    this.node.insertBefore(
      (node as HtmlDomNode).node,
      referenceNode == null ? null : (referenceNode as HtmlDomNode).node,
    );
  }

  @override
  void remove() {
    node.remove();
  }
}

class HtmlDomElement extends HtmlDomNode implements DomElement {
  HtmlDomElement(html.Element element)
      : _element = element,
        super(element);

  final html.Element _element;

  @override
  DomDocument get ownerDocument => HtmlDomDocument(_element.ownerDocument!);

  @override
  DomClassList get classes => HtmlDomClassList(_element.classes);

  @override
  Map<String, String> get dataset => _element.dataset;

  @override
  String get tagName => _element.tagName;

  @override
  String? get text => _element.text;

  @override
  set text(String? value) {
    _element.text = value;
  }

  @override
  void addEventListener(String type, DomEventListener listener) {
    _element.addEventListener(type, (event) => listener(HtmlDomEvent(event)));
  }

  @override
  void removeEventListener(String type, DomEventListener listener) {
    _element.removeEventListener(type, (event) => listener(HtmlDomEvent(event)));
  }

  @override
  void setAttribute(String name, String value) {
    _element.setAttribute(name, value);
  }

  @override
  String? getAttribute(String name) => _element.getAttribute(name);

  @override
  bool hasAttribute(String name) => _element.hasAttribute(name);

  @override
  void removeAttribute(String name) => _element.removeAttribute(name);

  @override
  void appendText(String value) {
    append(HtmlDomText(html.Text(value)));
  }

  @override
  DomElement cloneNode({bool deep = false}) =>
      HtmlDomElement(_element.clone(deep));

  @override
  void replaceWith(DomElement node) {
    _element.replaceWith((node as HtmlDomElement)._element);
  }
}

class HtmlDomText extends HtmlDomNode implements DomText {
  HtmlDomText(html.Text text)
      : _text = text,
        super(text);

  final html.Text _text;

  @override
  String get data => _text.data ?? '';

  @override
  set data(String value) {
    _text.data = value;
  }
}

class HtmlDomClassList implements DomClassList {
  HtmlDomClassList(this._classes);

  final html.CssClassSet _classes;

  @override
  void add(String token) => _classes.add(token);

  @override
  bool contains(String token) => _classes.contains(token);

  @override
  void remove(String token) => _classes.remove(token);

  @override
  void toggle(String token, [bool? force]) {
    if (force == null) {
      _classes.toggle(token);
    } else {
      force ? _classes.add(token) : _classes.remove(token);
    }
  }

  @override
  Iterable<String> get values => _classes.toSet();
}

class HtmlDomMutationObserver implements DomMutationObserver {
  HtmlDomMutationObserver(this._observer);

  final html.MutationObserver _observer;

  @override
  void observe(DomNode target, {bool? subtree, bool? childList, bool? characterData}) {
    _observer.observe(
      (target as HtmlDomNode).node,
      subtree: subtree ?? false,
      childList: childList ?? false,
      characterData: characterData ?? false,
    );
  }

  @override
  void disconnect() => _observer.disconnect();

  @override
  List<DomMutationRecord> takeRecords() => _observer.takeRecords().map(HtmlDomMutationRecord.new).toList();
}

class HtmlDomMutationRecord implements DomMutationRecord {
  HtmlDomMutationRecord(this._record);

  final html.MutationRecord _record;

  @override
  List<DomNode> get addedNodes =>
      _record.addedNodes == null
          ? const []
          : [for (final node in _record.addedNodes!) HtmlDomNode(node)];

  @override
  List<DomNode> get removedNodes =>
      _record.removedNodes == null
          ? const []
          : [for (final node in _record.removedNodes!) HtmlDomNode(node)];

  @override
  DomNode? get nextSibling => _record.nextSibling == null ? null : HtmlDomNode(_record.nextSibling!);

  @override
  DomNode? get previousSibling => _record.previousSibling == null ? null : HtmlDomNode(_record.previousSibling!);

  @override
  DomNode get target => HtmlDomNode(_record.target);

  @override
  String get type => _record.type ?? '';
}

class HtmlDomEvent implements DomEvent {
  HtmlDomEvent(this._event);
  final html.Event _event;

  @override
  void preventDefault() => _event.preventDefault();
}
