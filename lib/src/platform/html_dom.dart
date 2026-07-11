import 'dart:async';
import 'dart:collection';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

import 'dom.dart';

// ---------------------------------------------------------------------------
// HTML sanitisation
//
// dart:html sanitised markup assigned through `setInnerHtml` using a
// NodeValidator. package:web has no equivalent, so we replicate the
// security-relevant parts of the previous policy: strip script-capable
// elements, inline event handlers and URIs with disallowed schemes.
// ---------------------------------------------------------------------------

const Set<String> _allowedUriSchemes = {
  'about',
  'data',
  'http',
  'https',
  'mailto',
  'tel',
};

const Set<String> _forbiddenTags = {
  'SCRIPT',
  'STYLE',
  'LINK',
  'META',
  'BASE',
  'TITLE',
  'HEAD',
  'OBJECT',
  'EMBED',
  'APPLET',
  'NOSCRIPT',
};

const Set<String> _uriAttributes = {
  'href',
  'src',
  'xlink:href',
  'action',
  'formaction',
  'poster',
  'background',
  'cite',
  'data',
};

bool _allowsUri(String uri) {
  final parsed = Uri.tryParse(uri);
  if (parsed == null) {
    return false;
  }
  if (!parsed.hasScheme) {
    return true;
  }
  return _allowedUriSchemes.contains(parsed.scheme.toLowerCase());
}

void _sanitizeElementAttributes(web.Element element) {
  final names = element.getAttributeNames().toDart;
  for (final jsName in names) {
    final name = jsName.toDart;
    final lower = name.toLowerCase();
    if (lower.startsWith('on')) {
      element.removeAttribute(name);
      continue;
    }
    if (_uriAttributes.contains(lower)) {
      final value = element.getAttribute(name);
      if (value == null || !_allowsUri(value.trim())) {
        element.removeAttribute(name);
      }
    }
  }
}

void _sanitizeTree(web.Node root) {
  var child = root.firstChild;
  while (child != null) {
    final next = child.nextSibling;
    if (child.isA<web.Element>()) {
      final element = child as web.Element;
      if (_forbiddenTags.contains(element.tagName.toUpperCase())) {
        root.removeChild(child);
      } else {
        _sanitizeElementAttributes(element);
        _sanitizeTree(element);
      }
    }
    child = next;
  }
}

/// Creates the platform-specific DOM adapter
/// On web platforms, returns HtmlDomAdapter
DomAdapter createPlatformAdapter() => HtmlDomAdapter();

// Generic wrapper for any native DOM node.
// We can't have a common base class for HtmlDomElement and HtmlDomText
// since they wrap different interop types from package:web.
// This class provides the common functionality from DomNode interface.
DomNode _wrapNode(web.Node node) {
  if (node.isA<web.Element>()) {
    return HtmlDomElement(node as web.Element);
  }
  if (node.isA<web.Text>()) {
    return HtmlDomText(node as web.Text);
  }
  return _HtmlDomNode(node);
}

class _HtmlDomNode implements DomNode {
  _HtmlDomNode(this.node);

  final web.Node node;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is _HtmlDomNode && other.node == node;
  }

  @override
  int get hashCode => node.hashCode;

  @override
  String get nodeName => node.nodeName;

  @override
  int get nodeType => node.nodeType;

  @override
  String? get textContent => node.textContent;

  @override
  void append(DomNode node) {
    this.node.appendChild((node as _HtmlDomNode).node);
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
    final parent = node.parentNode;
    if (parent != null) {
      parent.removeChild(node);
    }
  }

  @override
  List<DomNode> get childNodes {
    final children = node.childNodes;
    return [
      for (var i = 0; i < children.length; i++) _wrapNode(children.item(i)!)
    ];
  }

  @override
  DomNode? get firstChild =>
      node.firstChild == null ? null : _wrapNode(node.firstChild!);

  @override
  DomNode? get lastChild =>
      node.lastChild == null ? null : _wrapNode(node.lastChild!);

  @override
  DomNode? get nextSibling =>
      node.nextSibling == null ? null : _wrapNode(node.nextSibling!);

  @override
  DomNode? get parentNode =>
      node.parentNode == null ? null : _wrapNode(node.parentNode!);

  @override
  DomNode? get previousSibling =>
      node.previousSibling == null ? null : _wrapNode(node.previousSibling!);
}

// ---------------------------------------------------------------------------
// Raw event proxies
//
// Several call sites access `event.rawEvent` dynamically, e.g.
// `(event.rawEvent as dynamic).key`. With dart:html the raw event was a Dart
// object, so dynamic dispatch worked. package:web events are JS interop
// extension types (plain JSObject at runtime) where dynamic member access
// fails. These proxies restore the dynamic surface those call sites rely on.
// ---------------------------------------------------------------------------

class HtmlRawEventProxy {
  HtmlRawEventProxy(this.nativeEvent);

  final web.Event nativeEvent;

  bool get defaultPrevented => nativeEvent.defaultPrevented;

  void preventDefault() => nativeEvent.preventDefault();

  void stopPropagation() => nativeEvent.stopPropagation();

  String get type => nativeEvent.type;

  bool get isComposing {
    if (nativeEvent.isA<web.KeyboardEvent>()) {
      return (nativeEvent as web.KeyboardEvent).isComposing;
    }
    if (nativeEvent.isA<web.InputEvent>()) {
      return (nativeEvent as web.InputEvent).isComposing;
    }
    return false;
  }

  String? get key => nativeEvent.isA<web.KeyboardEvent>()
      ? (nativeEvent as web.KeyboardEvent).key
      : null;

  int? get keyCode => nativeEvent.isA<web.KeyboardEvent>()
      ? (nativeEvent as web.KeyboardEvent).keyCode
      : null;

  bool get altKey => nativeEvent.isA<web.KeyboardEvent>() &&
      (nativeEvent as web.KeyboardEvent).altKey;

  bool get ctrlKey => nativeEvent.isA<web.KeyboardEvent>() &&
      (nativeEvent as web.KeyboardEvent).ctrlKey;

  bool get metaKey => nativeEvent.isA<web.KeyboardEvent>() &&
      (nativeEvent as web.KeyboardEvent).metaKey;

  bool get shiftKey => nativeEvent.isA<web.KeyboardEvent>() &&
      (nativeEvent as web.KeyboardEvent).shiftKey;

  String? get inputType => nativeEvent.isA<web.InputEvent>()
      ? (nativeEvent as web.InputEvent).inputType
      : null;

  String? get data => nativeEvent.isA<web.InputEvent>()
      ? (nativeEvent as web.InputEvent).data
      : null;

  HtmlRawEventTargetProxy? get target {
    final t = nativeEvent.target;
    return t == null ? null : HtmlRawEventTargetProxy(t);
  }
}

class HtmlRawEventTargetProxy {
  HtmlRawEventTargetProxy(this.nativeTarget);

  final web.EventTarget nativeTarget;

  /// Files selected on an `<input type="file">`, wrapped as [HtmlDomFile]
  /// so downstream dynamic accesses (`file.type`) keep working.
  List<HtmlDomFile>? get files {
    if (!nativeTarget.isA<web.HTMLInputElement>()) {
      return null;
    }
    final fileList = (nativeTarget as web.HTMLInputElement).files;
    if (fileList == null) {
      return null;
    }
    return [
      for (var i = 0; i < fileList.length; i++) HtmlDomFile(fileList.item(i)!)
    ];
  }

  String? get value {
    if (nativeTarget.isA<web.HTMLInputElement>()) {
      return (nativeTarget as web.HTMLInputElement).value;
    }
    if (nativeTarget.isA<web.HTMLTextAreaElement>()) {
      return (nativeTarget as web.HTMLTextAreaElement).value;
    }
    return null;
  }

  set value(String? val) {
    if (nativeTarget.isA<web.HTMLInputElement>()) {
      (nativeTarget as web.HTMLInputElement).value = val ?? '';
    } else if (nativeTarget.isA<web.HTMLTextAreaElement>()) {
      (nativeTarget as web.HTMLTextAreaElement).value = val ?? '';
    }
  }
}

class HtmlDomEvent implements DomEvent {
  final web.Event nativeEvent;

  HtmlDomEvent(this.nativeEvent);

  @override
  dynamic get rawEvent => HtmlRawEventProxy(nativeEvent);

  @override
  bool get defaultPrevented => nativeEvent.defaultPrevented;

  @override
  void preventDefault() {
    nativeEvent.preventDefault();
  }

  @override
  void stopPropagation() {
    nativeEvent.stopPropagation();
  }

  @override
  DomNode? get target {
    final t = nativeEvent.target;
    if (t == null) return null;
    // EventTarget is the base, Node is more specific - need to check
    if (t.isA<web.Node>()) {
      return _wrapNode(t as web.Node);
    }
    return null;
  }
}

class HtmlDomInputEvent extends HtmlDomEvent implements DomInputEvent {
  HtmlDomInputEvent(super.nativeEvent);

  @override
  String? get inputType {
    if (!nativeEvent.isA<web.InputEvent>()) {
      return null;
    }
    return (nativeEvent as web.InputEvent).inputType;
  }

  @override
  String? get data {
    if (!nativeEvent.isA<web.InputEvent>()) {
      return null;
    }
    return (nativeEvent as web.InputEvent).data;
  }

  @override
  DomDataTransfer? get dataTransfer {
    if (!nativeEvent.isA<web.InputEvent>()) {
      return null;
    }
    final transfer = (nativeEvent as web.InputEvent).dataTransfer;
    return transfer == null ? null : HtmlDomDataTransfer(transfer);
  }
}

class HtmlDomMutationObserver implements DomMutationObserver {
  HtmlDomMutationObserver(this._native);

  final web.MutationObserver _native;

  @override
  void observe(
    DomNode target, {
    bool? subtree,
    bool? childList,
    bool? characterData,
  }) {
    final options = web.MutationObserverInit();
    if (subtree != null) {
      options.subtree = subtree;
    }
    if (childList != null) {
      options.childList = childList;
    }
    if (characterData != null) {
      options.characterData = characterData;
    }
    _native.observe((target as _HtmlDomNode).node, options);
  }

  @override
  void disconnect() => _native.disconnect();

  @override
  List<DomMutationRecord> takeRecords() {
    return [
      for (final record in _native.takeRecords().toDart)
        HtmlDomMutationRecord(record)
    ];
  }
}

class HtmlDomMutationRecord implements DomMutationRecord {
  HtmlDomMutationRecord(this._native);

  final web.MutationRecord _native;

  @override
  DomNode get target => _HtmlDomNode(_native.target);

  @override
  String get type => _native.type;

  @override
  List<DomNode> get addedNodes {
    final nodes = _native.addedNodes;
    return [
      for (var i = 0; i < nodes.length; i++) _HtmlDomNode(nodes.item(i)!)
    ];
  }

  @override
  List<DomNode> get removedNodes {
    final nodes = _native.removedNodes;
    return [
      for (var i = 0; i < nodes.length; i++) _HtmlDomNode(nodes.item(i)!)
    ];
  }

  @override
  DomNode? get previousSibling => _native.previousSibling == null
      ? null
      : _HtmlDomNode(_native.previousSibling!);

  @override
  DomNode? get nextSibling =>
      _native.nextSibling == null ? null : _HtmlDomNode(_native.nextSibling!);
}

class HtmlDomClipboardEvent extends HtmlDomEvent implements DomClipboardEvent {
  HtmlDomClipboardEvent(super.nativeEvent);

  @override
  DomDataTransfer? get clipboardData {
    if (!nativeEvent.isA<web.ClipboardEvent>()) {
      return null;
    }
    final data = (nativeEvent as web.ClipboardEvent).clipboardData;
    return data == null ? null : HtmlDomDataTransfer(data);
  }
}

class HtmlDomKeyboardEvent extends HtmlDomEvent implements DomKeyboardEvent {
  HtmlDomKeyboardEvent(super.nativeEvent);

  web.KeyboardEvent get _keyboardEvent => nativeEvent as web.KeyboardEvent;

  @override
  String get key => _keyboardEvent.key;

  @override
  int? get keyCode => _keyboardEvent.keyCode;

  @override
  bool get altKey => _keyboardEvent.altKey;

  @override
  bool get ctrlKey => _keyboardEvent.ctrlKey;

  @override
  bool get metaKey => _keyboardEvent.metaKey;

  @override
  bool get shiftKey => _keyboardEvent.shiftKey;
}

class HtmlDomDataTransfer implements DomDataTransfer {
  final web.DataTransfer _native;

  HtmlDomDataTransfer(this._native);

  @override
  List<DomFile> get files {
    final fileList = _native.files;
    return [
      for (var i = 0; i < fileList.length; i++) HtmlDomFile(fileList.item(i)!)
    ];
  }

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
  final web.File _native;

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
      void Function(
              List<DomMutationRecord> mutations, DomMutationObserver observer)
          callback) {
    late HtmlDomMutationObserver observer;
    final nativeObserver = web.MutationObserver(
      (JSArray<web.MutationRecord> mutations, web.MutationObserver _) {
        callback(
          [for (final m in mutations.toDart) HtmlDomMutationRecord(m)],
          observer,
        );
      }.toJS,
    );
    observer = HtmlDomMutationObserver(nativeObserver);
    return observer;
  }

  @override
  String? get userAgent => web.window.navigator.userAgent;

  @override
  void focus(DomElement element) {
    final native = (element as _HtmlDomNode).node;
    if (native.isA<web.HTMLElement>()) {
      (native as web.HTMLElement).focus();
    } else if (native.isA<web.Element>()) {
      (native as JSObject).callMethod('focus'.toJS);
    }
  }

  @override
  DomSelectionRange? getSelectionRange(DomElement root) {
    final rootNode = (root as _HtmlDomNode).node;
    if (!rootNode.isA<web.Element>()) {
      return null;
    }
    final selection = web.window.getSelection();
    final rangeCount = selection?.rangeCount ?? 0;
    if (rangeCount <= 0) {
      return null;
    }
    final range = selection!.getRangeAt(0);
    final startContainer = range.startContainer;
    final endContainer = range.endContainer;
    if (!_containsOrIs(rootNode, startContainer) ||
        !_containsOrIs(rootNode, endContainer)) {
      return null;
    }

    final start = _textOffset(rootNode, startContainer, range.startOffset);
    final end = range.collapsed
        ? start
        : _textOffset(rootNode, endContainer, range.endOffset);
    final normalizedStart = start < end ? start : end;
    final normalizedEnd = start < end ? end : start;
    return DomSelectionRange(normalizedStart, normalizedEnd - normalizedStart);
  }

  @override
  void setSelectionRange(DomElement root, int index, int length) {
    final rootNode = (root as _HtmlDomNode).node;
    if (!rootNode.isA<web.Element>()) {
      return;
    }
    final selection = web.window.getSelection();
    if (selection == null) {
      return;
    }

    final start = _findTextPosition(rootNode, index);
    final end = _findTextPosition(rootNode, index + length);
    final nativeRange = web.document.createRange();
    nativeRange.setStart(start.node, start.offset);
    nativeRange.setEnd(end.node, end.offset);
    selection
      ..removeAllRanges()
      ..addRange(nativeRange);
  }

  @override
  void setSelectionByNodes(
      DomNode startNode, int startOffset, DomNode endNode, int endOffset) {
    final selection = web.window.getSelection();
    if (selection == null) {
      return;
    }
    final nativeStart = (startNode as _HtmlDomNode).node;
    final nativeEnd = (endNode as _HtmlDomNode).node;
    final nativeRange = web.document.createRange();
    nativeRange.setStart(nativeStart, startOffset);
    nativeRange.setEnd(nativeEnd, endOffset);
    selection
      ..removeAllRanges()
      ..addRange(nativeRange);
  }

  @override
  Map<String, dynamic>? getBounds(DomElement root, int index, int length) {
    final rootNode = (root as _HtmlDomNode).node;
    if (!rootNode.isA<web.Element>()) {
      return null;
    }

    final start = _findTextPosition(rootNode, index);
    final end = _findTextPosition(rootNode, index + length);
    final nativeRange = web.document.createRange();
    nativeRange.setStart(start.node, start.offset);
    nativeRange.setEnd(end.node, end.offset);

    web.DOMRect? rect;
    if (length > 0) {
      rect = nativeRange.getBoundingClientRect();
    } else {
      final clientRects = nativeRange.getClientRects();
      if (clientRects.length > 0) {
        rect = clientRects.item(0);
      }
      rect ??= nativeRange.getBoundingClientRect();
    }

    if (rect.width == 0 && rect.height == 0) {
      return null;
    }

    final rootElement = rootNode as web.Element;
    final container = rootElement.parentElement;
    final containerRect = container?.getBoundingClientRect() ??
        rootElement.getBoundingClientRect();
    return {
      'left': rect.left - containerRect.left,
      'right': rect.right - containerRect.left,
      'top': rect.top - containerRect.top,
      'bottom': rect.bottom - containerRect.top,
      'width': rect.width,
      'height': rect.height,
    };
  }

  @override
  Future<String?> readFileAsDataUrl(dynamic file) {
    web.File? nativeFile;
    if (file is HtmlDomFile) {
      nativeFile = file._native;
    } else if (file is JSObject && file.isA<web.File>()) {
      nativeFile = file as web.File;
    }
    if (nativeFile == null) {
      return Future.value(null);
    }

    final completer = Completer<String?>();
    final reader = web.FileReader();
    reader.onload = (web.Event _) {
      if (!completer.isCompleted) {
        final result = reader.result;
        completer.complete(result?.dartify()?.toString());
      }
    }.toJS;
    reader.onerror = (web.Event _) {
      if (!completer.isCompleted) {
        completer.complete(null);
      }
    }.toJS;
    reader.readAsDataURL(nativeFile);
    return completer.future;
  }
}

bool _containsOrIs(web.Node root, web.Node node) {
  if (root == node) {
    return true;
  }
  if (root.isA<web.Element>()) {
    return root.contains(node);
  }
  return false;
}

int _textOffset(web.Node root, web.Node target, int targetOffset) {
  var offset = 0;
  var found = false;

  void visit(web.Node node) {
    if (found) {
      return;
    }
    if (node == target) {
      if (node.isA<web.Text>()) {
        offset += targetOffset.clamp(0, (node as web.Text).data.length);
      } else {
        final children = node.childNodes;
        final limit = targetOffset.clamp(0, children.length);
        for (var i = 0; i < limit; i++) {
          offset += children.item(i)!.textContent?.length ?? 0;
        }
      }
      found = true;
      return;
    }
    if (node.isA<web.Text>()) {
      offset += (node as web.Text).data.length;
      return;
    }
    final children = node.childNodes;
    for (var i = 0; i < children.length; i++) {
      visit(children.item(i)!);
      if (found) {
        return;
      }
    }
  }

  visit(root);
  return offset;
}

({web.Node node, int offset}) _findTextPosition(web.Node root, int index) {
  final target = index < 0 ? 0 : index;
  var remaining = target;
  web.Text? lastText;

  ({web.Node node, int offset})? visit(web.Node node) {
    if (node.isA<web.Text>()) {
      final textNode = node as web.Text;
      lastText = textNode;
      final length = textNode.data.length;
      if (remaining <= length) {
        return (node: node, offset: remaining);
      }
      remaining -= length;
      return null;
    }
    final children = node.childNodes;
    for (var i = 0; i < children.length; i++) {
      final found = visit(children.item(i)!);
      if (found != null) {
        return found;
      }
    }
    return null;
  }

  final found = visit(root);
  if (found != null) {
    return found;
  }
  final text = lastText;
  if (text != null) {
    return (node: text, offset: text.data.length);
  }
  return (node: root, offset: root.childNodes.length);
}

class HtmlDomDocument implements DomDocument {
  @override
  DomElement createElement(String tag) {
    return HtmlDomElement(web.document.createElement(tag));
  }

  @override
  DomText createTextNode(String value) => HtmlDomText(web.Text(value));

  @override
  List<DomElement> querySelectorAll(String selectors) {
    final nodes = web.document.querySelectorAll(selectors);
    return [
      for (var i = 0; i < nodes.length; i++)
        HtmlDomElement(nodes.item(i)! as web.Element)
    ];
  }

  @override
  DomElement? querySelector(String selectors) {
    final element = web.document.querySelector(selectors);
    return element == null ? null : HtmlDomElement(element);
  }

  @override
  DomElement get body => HtmlDomElement(web.document.body!);

  @override
  DomElement get documentElement =>
      HtmlDomElement(web.document.documentElement!);

  @override
  DomParser get parser => HtmlDomParser();
}

class HtmlDomParser implements DomParser {
  final web.DOMParser _native = web.DOMParser();

  @override
  DomDocument parseFromString(String string, String type) {
    final doc = _native.parseFromString(string.toJS, type);
    // We need a way to represent a document without wrapping the global one.
    // For now, let's create a new HtmlDomDocument that can wrap this specific doc.
    // This part of the abstraction might need refinement.
    return _HtmlDomDocumentWrapper(doc);
  }
}

// A wrapper for a parsed document, to distinguish from the main `web.document`.
class _HtmlDomDocumentWrapper extends HtmlDomDocument {
  final web.Document _doc;

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
    final nodes = _doc.querySelectorAll(selectors);
    return [
      for (var i = 0; i < nodes.length; i++)
        HtmlDomElement(nodes.item(i)! as web.Element)
    ];
  }

  @override
  DomElement get body {
    // For HTML documents we have body, otherwise use documentElement.
    final body = _doc.body;
    if (body != null) {
      return HtmlDomElement(body);
    }
    return HtmlDomElement(_doc.documentElement!);
  }

  @override
  DomElement get documentElement => HtmlDomElement(_doc.documentElement!);
}

class HtmlDomElement extends _HtmlDomNode implements DomElement {
  HtmlDomElement(web.Element element) : super(element);

  web.Element get _element => node as web.Element;

  final Map<DomEventListener, JSFunction> _listeners = {};

  @override
  String? get id => _element.id;

  @override
  String? get className => _element.className;

  @override
  dynamic get style {
    if (_element.isA<web.HTMLElement>()) {
      return HtmlDomCssStyle((_element as web.HTMLElement).style);
    }
    if (_element.isA<web.SVGElement>()) {
      return HtmlDomCssStyle((_element as web.SVGElement).style);
    }
    return null;
  }

  @override
  String get tagName => _element.tagName;

  @override
  String? get text => _element.textContent;

  @override
  set text(String? value) {
    _element.textContent = value;
  }

  @override
  DomDocument get ownerDocument =>
      _HtmlDomDocumentWrapper(_element.ownerDocument!);

  @override
  DomClassList get classes => _HtmlDomClassList(_element.classList);

  @override
  Map<String, String> get dataset => _HtmlDomDatasetMap(_element);

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
  List<String> get attributeNames =>
      [for (final name in _element.getAttributeNames().toDart) name.toDart];

  @override
  void addEventListener(String type, DomEventListener listener) {
    final l = (web.Event event) {
      if (type == 'beforeinput') {
        listener(HtmlDomInputEvent(event));
      } else if (['copy', 'cut', 'paste'].contains(type)) {
        listener(HtmlDomClipboardEvent(event));
      } else if (['keydown', 'keyup', 'keypress'].contains(type)) {
        listener(HtmlDomKeyboardEvent(event));
      } else {
        listener(HtmlDomEvent(event));
      }
    }.toJS;
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
    return HtmlDomElement(_element.cloneNode(deep) as web.Element);
  }

  @override
  void replaceWith(DomElement node) {
    _element.replaceWith((node as HtmlDomElement)._element);
  }

  @override
  void appendText(String value) {
    _element.appendChild(web.Text(value));
  }

  @override
  List<DomElement> querySelectorAll(String selectors) {
    final nodes = _element.querySelectorAll(selectors);
    return [
      for (var i = 0; i < nodes.length; i++)
        HtmlDomElement(nodes.item(i)! as web.Element)
    ];
  }

  @override
  bool contains(DomNode? node) {
    if (node == null) return false;
    final nativeNode = (node as _HtmlDomNode).node;
    return _element.contains(nativeNode);
  }

  @override
  DomElement? querySelector(String selector) {
    final element = _element.querySelector(selector);
    return element == null ? null : HtmlDomElement(element);
  }

  @override
  void select() {
    if (_element.isA<web.HTMLInputElement>()) {
      (_element as web.HTMLInputElement).select();
    } else if (_element.isA<web.HTMLTextAreaElement>()) {
      (_element as web.HTMLTextAreaElement).select();
    }
  }

  @override
  void click() {
    if (_element.isA<web.HTMLElement>()) {
      (_element as web.HTMLElement).click();
    } else {
      (_element as JSObject).callMethod('click'.toJS);
    }
  }

  @override
  int get scrollTop => _element.scrollTop.round();

  @override
  set scrollTop(int value) {
    _element.scrollTop = value;
  }

  @override
  int get scrollLeft => _element.scrollLeft.round();

  @override
  set scrollLeft(int value) {
    _element.scrollLeft = value;
  }

  @override
  int get offsetWidth => _element.isA<web.HTMLElement>()
      ? (_element as web.HTMLElement).offsetWidth
      : 0;

  @override
  int get offsetHeight => _element.isA<web.HTMLElement>()
      ? (_element as web.HTMLElement).offsetHeight
      : 0;

  @override
  int get clientWidth => _element.clientWidth;

  @override
  int get clientHeight => _element.clientHeight;

  @override
  String? get innerHTML {
    final value = _element.innerHTML;
    return value.dartify()?.toString();
  }

  @override
  set innerHTML(String? value) {
    final markup = value ?? '';
    final doc =
        web.DOMParser().parseFromString(markup.toJS, 'text/html');
    final source = doc.body ?? doc.documentElement;
    if (source != null) {
      _sanitizeTree(source);
    }
    _element.textContent = '';
    if (source != null) {
      var child = source.firstChild;
      while (child != null) {
        _element.appendChild(child);
        child = source.firstChild;
      }
    }
  }

  @override
  String get value {
    if (_element.isA<web.HTMLInputElement>()) {
      return (_element as web.HTMLInputElement).value;
    }
    if (_element.isA<web.HTMLTextAreaElement>()) {
      return (_element as web.HTMLTextAreaElement).value;
    }
    return '';
  }

  @override
  set value(String? val) {
    if (_element.isA<web.HTMLInputElement>()) {
      (_element as web.HTMLInputElement).value = val ?? '';
    } else if (_element.isA<web.HTMLTextAreaElement>()) {
      (_element as web.HTMLTextAreaElement).value = val ?? '';
    }
  }
}

class HtmlDomText extends _HtmlDomNode implements DomText {
  HtmlDomText(web.Text text) : super(text);

  web.Text get _text => node as web.Text;

  @override
  String get data => _text.data;

  @override
  set data(String value) {
    _text.data = value;
  }
}

class _HtmlDomClassList implements DomClassList {
  _HtmlDomClassList(this._native);

  final web.DOMTokenList _native;

  @override
  Iterable<String> get values =>
      [for (var i = 0; i < _native.length; i++) _native.item(i)!];

  @override
  bool contains(String token) => _native.contains(token);

  @override
  void add(String token) => _native.add(token);

  @override
  void remove(String token) => _native.remove(token);

  @override
  void toggle(String token, [bool? force]) {
    if (force == null) {
      _native.toggle(token);
    } else {
      _native.toggle(token, force);
    }
  }
}

/// Live, writable view over an element's `data-*` attributes, mirroring the
/// semantics of dart:html's `Element.dataset`.
class _HtmlDomDatasetMap extends MapBase<String, String> {
  _HtmlDomDatasetMap(this._element);

  final web.Element _element;

  static String _toAttributeName(String key) {
    final buffer = StringBuffer('data-');
    for (final unit in key.codeUnits) {
      // Uppercase ASCII letter -> '-' + lowercase.
      if (unit >= 0x41 && unit <= 0x5A) {
        buffer
          ..writeCharCode(0x2D)
          ..writeCharCode(unit + 0x20);
      } else {
        buffer.writeCharCode(unit);
      }
    }
    return buffer.toString();
  }

  static String _toKey(String attributeName) {
    final raw = attributeName.substring('data-'.length);
    final buffer = StringBuffer();
    var upperNext = false;
    for (final unit in raw.codeUnits) {
      if (unit == 0x2D) {
        upperNext = true;
      } else if (upperNext) {
        upperNext = false;
        if (unit >= 0x61 && unit <= 0x7A) {
          buffer.writeCharCode(unit - 0x20);
        } else {
          buffer.writeCharCode(unit);
        }
      } else {
        buffer.writeCharCode(unit);
      }
    }
    return buffer.toString();
  }

  @override
  String? operator [](Object? key) =>
      key is String ? _element.getAttribute(_toAttributeName(key)) : null;

  @override
  void operator []=(String key, String value) {
    _element.setAttribute(_toAttributeName(key), value);
  }

  @override
  String? remove(Object? key) {
    if (key is! String) {
      return null;
    }
    final attribute = _toAttributeName(key);
    final previous = _element.getAttribute(attribute);
    _element.removeAttribute(attribute);
    return previous;
  }

  @override
  void clear() {
    for (final key in keys.toList()) {
      remove(key);
    }
  }

  @override
  Iterable<String> get keys => [
        for (final name in _element.getAttributeNames().toDart)
          if (name.toDart.startsWith('data-')) _toKey(name.toDart)
      ];
}

/// Wrapper around [web.CSSStyleDeclaration] that supports the dynamic
/// property style access used across the codebase
/// (e.g. `style.marginTop = '4px'`), which used to work with dart:html but
/// fails on package:web interop extension types.
class HtmlDomCssStyle {
  HtmlDomCssStyle(this._style);

  final web.CSSStyleDeclaration _style;

  String get cssText => _style.cssText;
  set cssText(String? value) {
    _style.cssText = value ?? '';
  }

  String getPropertyValue(String property) =>
      _style.getPropertyValue(property);

  void setProperty(String property, String? value, [String? priority]) {
    _style.setProperty(property, value ?? '', priority ?? '');
  }

  String removeProperty(String property) => _style.removeProperty(property);

  String _get(String property) => _style.getPropertyValue(property);

  void _set(String property, String? value) {
    _style.setProperty(property, value ?? '');
  }

  // Explicit members for the CSS properties accessed dynamically in the
  // codebase. Real members keep dynamic dispatch working even in optimised
  // dart2js builds (unlike a pure noSuchMethod forwarder).
  String get display => _get('display');
  set display(String? v) => _set('display', v);

  String get left => _get('left');
  set left(String? v) => _set('left', v);

  String get top => _get('top');
  set top(String? v) => _set('top', v);

  String get right => _get('right');
  set right(String? v) => _set('right', v);

  String get bottom => _get('bottom');
  set bottom(String? v) => _set('bottom', v);

  String get width => _get('width');
  set width(String? v) => _set('width', v);

  String get height => _get('height');
  set height(String? v) => _set('height', v);

  String get marginTop => _get('margin-top');
  set marginTop(String? v) => _set('margin-top', v);

  String get marginLeft => _get('margin-left');
  set marginLeft(String? v) => _set('margin-left', v);

  String get backgroundColor => _get('background-color');
  set backgroundColor(String? v) => _set('background-color', v);

  String get borderBottom => _get('border-bottom');
  set borderBottom(String? v) => _set('border-bottom', v);

  String get stroke => _get('stroke');
  set stroke(String? v) => _set('stroke', v);

  String get fill => _get('fill');
  set fill(String? v) => _set('fill', v);

  static final RegExp _symbolName = RegExp(r'Symbol\("([^"]*)"\)');

  static String _camelToKebab(String name) {
    final buffer = StringBuffer();
    for (final unit in name.codeUnits) {
      if (unit >= 0x41 && unit <= 0x5A) {
        buffer
          ..writeCharCode(0x2D)
          ..writeCharCode(unit + 0x20);
      } else {
        buffer.writeCharCode(unit);
      }
    }
    return buffer.toString();
  }

  /// Fallback for any other CSS property accessed dynamically.
  @override
  dynamic noSuchMethod(Invocation invocation) {
    final match = _symbolName.firstMatch(invocation.memberName.toString());
    final rawName = match?.group(1);
    if (rawName != null && rawName.isNotEmpty) {
      if (invocation.isSetter) {
        final property =
            _camelToKebab(rawName.substring(0, rawName.length - 1));
        final value = invocation.positionalArguments.isNotEmpty
            ? invocation.positionalArguments.first
            : null;
        _set(property, value?.toString());
        return null;
      }
      if (invocation.isGetter) {
        return _get(_camelToKebab(rawName));
      }
    }
    return super.noSuchMethod(invocation);
  }
}
