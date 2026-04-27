import 'dart:async';
import 'dart:html' as html;
import 'dart:js_util' as js_util;

import 'dom.dart';

final html.NodeValidator _quillHtmlValidator =
    html.NodeValidatorBuilder.common()
      ..allowSvg()
      ..allowNavigation(_QuillUriPolicy())
      ..allowImages(_QuillUriPolicy())
      ..allowElement(
        'input',
        attributes: [
          'type',
          'data-formula',
          'data-link',
          'data-video',
        ],
      )
      ..allowElement(
        'a',
        attributes: [
          'class',
          'href',
          'rel',
          'target',
        ],
        uriAttributes: ['href'],
        uriPolicy: _QuillUriPolicy(),
      );

class _QuillUriPolicy implements html.UriPolicy {
  @override
  bool allowsUri(String uri) {
    final parsed = Uri.tryParse(uri);
    if (parsed == null) {
      return false;
    }
    if (!parsed.hasScheme) {
      return true;
    }
    return const {
      'about',
      'data',
      'http',
      'https',
      'mailto',
      'tel',
    }.contains(parsed.scheme.toLowerCase());
  }
}

/// Creates the platform-specific DOM adapter
/// On web platforms, returns HtmlDomAdapter
DomAdapter createPlatformAdapter() => HtmlDomAdapter();

// Generic wrapper for any native DOM node.
// We can't have a common base class for HtmlDomElement and HtmlDomText
// since they need to extend different classes from dart:html.
// This class provides the common functionality from DomNode interface.
DomNode _wrapNode(html.Node node) {
  if (node is html.Element) {
    return HtmlDomElement(node);
  }
  if (node is html.Text) {
    return HtmlDomText(node);
  }
  return _HtmlDomNode(node);
}

class _HtmlDomNode implements DomNode {
  _HtmlDomNode(this.node);

  final html.Node node;

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
      [for (final child in node.childNodes) _wrapNode(child)];

  @override
  DomNode? get firstChild =>
      node.firstChild == null ? null : _wrapNode(node.firstChild!);

  @override
  DomNode? get lastChild =>
      node.lastChild == null ? null : _wrapNode(node.lastChild!);

  @override
  DomNode? get nextSibling =>
      node.nextNode == null ? null : _wrapNode(node.nextNode!);

  @override
  DomNode? get parentNode =>
      node.parentNode == null ? null : _wrapNode(node.parentNode!);

  @override
  DomNode? get previousSibling =>
      node.previousNode == null ? null : _wrapNode(node.previousNode!);
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
  void stopPropagation() {
    rawEvent.stopPropagation();
  }

  @override
  DomNode? get target {
    final t = rawEvent.target;
    if (t == null) return null;
    // EventTarget is the base, Node is more specific - need to check
    if (t is html.Node) {
      if (t is html.Element) {
        return HtmlDomElement(t);
      }
      if (t is html.Text) {
        return HtmlDomText(t);
      }
      return _HtmlDomNode(t);
    }
    return null;
  }
}

class HtmlDomInputEvent extends HtmlDomEvent implements DomInputEvent {
  HtmlDomInputEvent(super.rawEvent);

  @override
  String? get inputType {
    final event = rawEvent;
    if (!js_util.hasProperty(event, 'inputType')) {
      return null;
    }
    final value = js_util.getProperty(event, 'inputType');
    return value == null ? null : value.toString();
  }

  @override
  String? get data {
    final event = rawEvent;
    if (!js_util.hasProperty(event, 'data')) {
      return null;
    }
    final value = js_util.getProperty(event, 'data');
    return value == null ? null : value.toString();
  }

  @override
  DomDataTransfer? get dataTransfer {
    final event = rawEvent;
    if (!js_util.hasProperty(event, 'dataTransfer')) {
      return null;
    }
    final transfer = js_util.getProperty(event, 'dataTransfer');
    if (transfer is html.DataTransfer) {
      return HtmlDomDataTransfer(transfer);
    }
    return null;
  }
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
    return [
      for (final record in _native.takeRecords()) HtmlDomMutationRecord(record)
    ];
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
  List<DomNode> get addedNodes =>
      [for (final node in _native.addedNodes!) _HtmlDomNode(node)];

  @override
  List<DomNode> get removedNodes =>
      [for (final node in _native.removedNodes!) _HtmlDomNode(node)];

  @override
  DomNode? get previousSibling => _native.previousSibling == null
      ? null
      : _HtmlDomNode(_native.previousSibling!);

  @override
  DomNode? get nextSibling =>
      _native.nextSibling == null ? null : _HtmlDomNode(_native.nextSibling!);
}

class HtmlDomClipboardEvent extends HtmlDomEvent implements DomClipboardEvent {
  HtmlDomClipboardEvent(super.rawEvent);

  @override
  DomDataTransfer? get clipboardData {
    final data = (rawEvent as html.ClipboardEvent).clipboardData;
    return data == null ? null : HtmlDomDataTransfer(data);
  }
}

class HtmlDomKeyboardEvent extends HtmlDomEvent implements DomKeyboardEvent {
  HtmlDomKeyboardEvent(super.rawEvent);

  html.KeyboardEvent get _keyboardEvent => rawEvent as html.KeyboardEvent;

  @override
  String get key => _keyboardEvent.key ?? '';

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
      void Function(
              List<DomMutationRecord> mutations, DomMutationObserver observer)
          callback) {
    late HtmlDomMutationObserver observer;
    final nativeObserver = html.MutationObserver((mutations, nativeObserver) {
      callback([for (final m in mutations) HtmlDomMutationRecord(m)], observer);
    });
    observer = HtmlDomMutationObserver(nativeObserver);
    return observer;
  }

  @override
  String? get userAgent => html.window.navigator.userAgent;

  @override
  void focus(DomElement element) {
    final native = (element as _HtmlDomNode).node;
    if (native is html.HtmlElement) {
      native.focus();
    } else if (native is html.Element) {
      js_util.callMethod(native, 'focus', const []);
    }
  }

  @override
  DomSelectionRange? getSelectionRange(DomElement root) {
    final rootNode = (root as _HtmlDomNode).node;
    if (rootNode is! html.Element) {
      return null;
    }
    final selection = html.window.getSelection();
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
    if (rootNode is! html.Element) {
      return;
    }
    final selection = html.window.getSelection();
    if (selection == null) {
      return;
    }

    final start = _findTextPosition(rootNode, index);
    final end = _findTextPosition(rootNode, index + length);
    final nativeRange = html.document.createRange();
    nativeRange.setStart(start.node, start.offset);
    nativeRange.setEnd(end.node, end.offset);
    selection
      ..removeAllRanges()
      ..addRange(nativeRange);
  }

  @override
  Map<String, dynamic>? getBounds(DomElement root, int index, int length) {
    final rootNode = (root as _HtmlDomNode).node;
    if (rootNode is! html.Element) {
      return null;
    }

    final start = _findTextPosition(rootNode, index);
    final end = _findTextPosition(rootNode, index + length);
    final nativeRange = html.document.createRange();
    nativeRange.setStart(start.node, start.offset);
    nativeRange.setEnd(end.node, end.offset);

    html.Rectangle<num>? rect;
    if (length > 0) {
      rect = nativeRange.getBoundingClientRect();
    } else {
      final clientRects = nativeRange.getClientRects();
      if (clientRects.isNotEmpty) {
        rect = clientRects.first;
      }
      rect ??= nativeRange.getBoundingClientRect();
    }

    if (rect.width == 0 && rect.height == 0) {
      return null;
    }

    final container = rootNode.parent;
    final containerRect =
        container?.getBoundingClientRect() ?? rootNode.getBoundingClientRect();
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
    final nativeFile = file is HtmlDomFile
        ? file._native
        : file is html.File
            ? file
            : null;
    if (nativeFile == null) {
      return Future.value(null);
    }

    final completer = Completer<String?>();
    final reader = html.FileReader();
    reader.onLoad.first.then((_) {
      final result = reader.result;
      completer.complete(result == null ? null : result.toString());
    });
    reader.onError.first.then((_) {
      if (!completer.isCompleted) {
        completer.complete(null);
      }
    });
    reader.readAsDataUrl(nativeFile);
    return completer.future;
  }
}

bool _containsOrIs(html.Node root, html.Node node) {
  if (identical(root, node)) {
    return true;
  }
  if (root is html.Element) {
    return root.contains(node);
  }
  return false;
}

int _textOffset(html.Node root, html.Node target, int targetOffset) {
  var offset = 0;
  var found = false;

  void visit(html.Node node) {
    if (found) {
      return;
    }
    if (identical(node, target)) {
      if (node is html.Text) {
        offset += targetOffset.clamp(0, node.data?.length ?? 0);
      } else {
        final children = node.childNodes;
        final limit = targetOffset.clamp(0, children.length);
        for (var i = 0; i < limit; i++) {
          offset += children[i].text?.length ?? 0;
        }
      }
      found = true;
      return;
    }
    if (node is html.Text) {
      offset += node.data?.length ?? 0;
      return;
    }
    for (final child in node.childNodes) {
      visit(child);
      if (found) {
        return;
      }
    }
  }

  visit(root);
  return offset;
}

({html.Node node, int offset}) _findTextPosition(html.Node root, int index) {
  final target = index < 0 ? 0 : index;
  var remaining = target;
  html.Text? lastText;

  ({html.Node node, int offset})? visit(html.Node node) {
    if (node is html.Text) {
      lastText = node;
      final length = node.data?.length ?? 0;
      if (remaining <= length) {
        return (node: node, offset: remaining);
      }
      remaining -= length;
      return null;
    }
    for (final child in node.childNodes) {
      final found = visit(child);
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
    return (node: text, offset: text.data?.length ?? 0);
  }
  return (node: root, offset: root.childNodes.length);
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
  DomElement get documentElement =>
      HtmlDomElement(html.document.documentElement!);

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
  final html.Document _doc;

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
    return _doc
        .querySelectorAll(selectors)
        .map((e) => HtmlDomElement(e))
        .toList();
  }

  @override
  DomElement get body {
    // For HtmlDocument we have body, for generic Document we use documentElement
    if (_doc is html.HtmlDocument) {
      return HtmlDomElement(_doc.body!);
    }
    return HtmlDomElement(_doc.documentElement!);
  }

  @override
  DomElement get documentElement => HtmlDomElement(_doc.documentElement!);
}

class HtmlDomElement extends _HtmlDomNode implements DomElement {
  HtmlDomElement(html.Element element) : super(element);

  html.Element get _element => node as html.Element;

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
      _HtmlDomDocumentWrapper(_element.ownerDocument!);

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
      } else if (['keydown', 'keyup', 'keypress'].contains(type)) {
        listener(HtmlDomKeyboardEvent(event));
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
    return _element
        .querySelectorAll(selectors)
        .map((e) => HtmlDomElement(e as html.HtmlElement))
        .toList();
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
  void select() {
    if (_element is html.InputElement) {
      (_element as html.InputElement).select();
    } else if (_element is html.TextAreaElement) {
      (_element as html.TextAreaElement).select();
    }
  }

  @override
  void click() {
    _element.click();
  }

  @override
  int get scrollTop => _element.scrollTop;

  @override
  set scrollTop(int value) {
    _element.scrollTop = value;
  }

  @override
  int get scrollLeft => _element.scrollLeft;

  @override
  set scrollLeft(int value) {
    _element.scrollLeft = value;
  }

  @override
  int get offsetWidth => _element.offsetWidth;

  @override
  int get offsetHeight => _element.offsetHeight;

  @override
  int get clientWidth => _element.clientWidth;

  @override
  int get clientHeight => _element.clientHeight;

  @override
  String? get innerHTML => _element.innerHtml;

  @override
  set innerHTML(String? value) {
    // ignore: unsafe_html
    _element.setInnerHtml(value, validator: _quillHtmlValidator);
  }

  @override
  String get value {
    if (_element is html.InputElement) {
      return (_element as html.InputElement).value ?? '';
    }
    if (_element is html.TextAreaElement) {
      return (_element as html.TextAreaElement).value ?? '';
    }
    return '';
  }

  @override
  set value(String? val) {
    if (_element is html.InputElement) {
      (_element as html.InputElement).value = val;
    } else if (_element is html.TextAreaElement) {
      (_element as html.TextAreaElement).value = val;
    }
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
