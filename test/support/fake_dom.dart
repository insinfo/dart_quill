import 'dart:typed_data';

import 'package:dart_quill/src/platform/dom.dart';
import 'package:html/dom.dart' as html_dom;
import 'package:html/parser.dart' as html_parser;

class FakeDomAdapter implements DomAdapter {
  FakeDomAdapter() : document = FakeDomDocument();

  @override
  final FakeDomDocument document;

  DomSelectionRange? selectionRange;
  DomNativeRange? nativeSelectionRange;

  /// What [caretRangeFromPoint] answers; the fake DOM has no layout, so a test
  /// that exercises a drop sets this explicitly.
  DomNativeRange? caretRangeAtPoint;

  @override
  DomNativeRange? caretRangeFromPoint(num x, num y) => caretRangeAtPoint;

  // The fake DOM has no live native selection: Selection stays in its
  // logical mode, which is what the VM suite exercises.
  @override
  bool get supportsNativeSelection => false;

  @override
  bool hasFocus(DomElement root) =>
      root is FakeDomElement && root.getAttribute('data-focused') == 'true';

  @override
  void clearNativeSelection() {
    nativeSelectionRange = null;
  }

  /// Downloads registrados pelo adaptador fake — o teste inspeciona a
  /// intenção (nome, tipo, bytes) sem precisar de browser.
  final List<({String filename, String mimeType, List<int> bytes})> downloads =
      [];

  @override
  void downloadBytes(String filename, String mimeType, List<int> bytes) {
    downloads.add((filename: filename, mimeType: mimeType, bytes: bytes));
  }

  /// Pedidos de [pickFile] pendentes: o teste injeta o arquivo chamando o
  /// callback registrado.
  final List<({String accept, void Function(String, Uint8List) onFile})>
      filePicks = [];

  @override
  void pickFile(
      String accept, void Function(String name, Uint8List bytes) onFile) {
    filePicks.add((accept: accept, onFile: onFile));
  }

  @override
  DomMutationObserver createMutationObserver(
    void Function(List<DomMutationRecord> records, DomMutationObserver observer)
        callback,
  ) {
    return FakeDomMutationObserver(callback);
  }

  // Helper method for creating fake events (not part of DomAdapter interface)
  DomEvent createEvent(String type) => FakeDomEvent(type);

  @override
  void focus(DomElement element) {
    if (element is FakeDomElement) {
      element.setAttribute('data-focused', 'true');
    }
  }

  @override
  void blur(DomElement element) {
    if (element is FakeDomElement) {
      element.removeAttribute('data-focused');
    }
  }

  @override
  DomSelectionRange? getSelectionRange(DomElement root) => selectionRange;

  @override
  DomNativeRange? getNativeSelectionRange() => nativeSelectionRange;

  @override
  void setSelectionRange(DomElement root, int index, int length) {
    selectionRange = DomSelectionRange(index, length);
  }

  @override
  void setSelectionByNodes(
      DomNode startNode, int startOffset, DomNode endNode, int endOffset) {
    nativeSelectionRange = DomNativeRange(
      startContainer: startNode,
      startOffset: startOffset,
      endContainer: endNode,
      endOffset: endOffset,
    );
  }

  @override
  Map<String, dynamic>? getBounds(DomElement root, int index, int length) {
    return {
      'left': index * 8.0,
      'right': (index + length) * 8.0,
      'top': 0.0,
      'bottom': 20.0,
      'width': length * 8.0,
      'height': 20.0,
    };
  }

  @override
  Map<String, dynamic>? getRangeBounds(
          DomNode startNode, int startOffset, DomNode endNode, int endOffset) =>
      null;

  @override
  Map<String, dynamic>? getElementBounds(DomElement element,
      {DomElement? relativeTo}) {
    final width = double.tryParse(element.getAttribute('width') ?? '') ?? 120;
    final height = double.tryParse(element.getAttribute('height') ?? '') ?? 80;
    return {
      'left': 0.0,
      'right': width,
      'top': 0.0,
      'bottom': height,
      'width': width,
      'height': height,
    };
  }

  @override
  DomElement? getParentElement(DomElement element) =>
      element.parentNode is DomElement
          ? element.parentNode as DomElement
          : null;

  @override
  Map<String, double> getViewportBounds(DomDocument document) => {
        'width': document.documentElement.clientWidth.toDouble(),
        'height': document.documentElement.clientHeight.toDouble(),
      };

  @override
  String getComputedStyleProperty(DomElement element, String property) {
    if (property == 'direction') {
      return element.getAttribute('dir') ?? 'ltr';
    }
    final style = element.style;
    if (style is _FakeStyle) {
      return style.getPropertyValue(property);
    }
    return '';
  }

  @override
  Future<String?> readFileAsDataUrl(dynamic file) async {
    if (file is FakeDomFile && file.type.startsWith('image/')) {
      return 'data:${file.type};base64,';
    }
    return null;
  }

  @override
  String? get userAgent => 'fake-user-agent';

  @override
  String? get platform => 'fake-platform';
}

class FakeDomDocument implements DomDocument {
  @override
  Object get identityKey => this;

  FakeDomDocument() {
    _documentElement = FakeDomElement('HTML', document: this);
    _body = FakeDomElement('BODY', document: this);
    _documentElement.append(_body);
  }

  factory FakeDomDocument.fromHtml(String html) {
    final document = FakeDomDocument();
    document._loadFromHtml(html);
    return document;
  }

  final Map<String, List<DomEventListener>> _listeners = {};

  @override
  void addEventListener(String type, DomEventListener listener) {
    (_listeners[type] ??= []).add(listener);
  }

  @override
  void removeEventListener(String type, DomEventListener listener) {
    _listeners[type]?.remove(listener);
  }

  void dispatchEvent(String type, DomEvent event) {
    for (final listener
        in List<DomEventListener>.from(_listeners[type] ?? const [])) {
      listener(event);
    }
  }

  late final FakeDomElement _documentElement;
  late final FakeDomElement _body;

  @override
  DomElement createElement(String tagName) =>
      FakeDomElement(tagName.toUpperCase(), document: this);

  @override
  DomText createTextNode(String value) => FakeDomText(value, document: this);

  @override
  DomElement get body => _body;

  @override
  DomElement get documentElement => _documentElement;

  @override
  DomElement? querySelector(String selectors) {
    final matcher = _SelectorMatcher(selectors);
    return _findFirst(_documentElement, matcher);
  }

  @override
  List<DomElement> querySelectorAll(String selectors) {
    final matcher = _SelectorMatcher(selectors);
    final results = <DomElement>[];
    void traverse(FakeDomNode node) {
      if (node is FakeDomElement) {
        if (matcher.matches(node)) {
          results.add(node);
        }
        for (final child in node.internalChildren) {
          traverse(child);
        }
      }
    }

    traverse(_documentElement);
    return results;
  }

  FakeDomElement? _findFirst(FakeDomElement root, _SelectorMatcher matcher) {
    if (matcher.matches(root)) {
      return root;
    }
    for (final child in root.internalChildren) {
      if (child is FakeDomElement) {
        final result = _findFirst(child, matcher);
        if (result != null) {
          return result;
        }
      }
    }
    return null;
  }

  @override
  DomParser get parser => FakeDomParser();

  void _loadFromHtml(String html) {
    final parsed = html_parser.parse(html);
    final parsedHtml = parsed.documentElement;
    final root = _documentElement;
    final body = _body;

    // Clear existing tree while preserving body instance.
    while (root.firstChild != null) {
      root.firstChild!.remove();
    }
    while (body.firstChild != null) {
      body.firstChild!.remove();
    }

    // Copy attributes from parsed <html> element.
    if (parsedHtml != null) {
      for (final entry in parsedHtml.attributes.entries) {
        root.setAttribute(entry.key.toString(), entry.value.toString());
      }
      // Append converted head if present.
      final head = parsed.head;
      if (head != null) {
        final convertedHead = _convertHtmlNode(head, this);
        if (convertedHead != null) {
          root.append(convertedHead);
        }
      }
    }

    // Re-append body and populate with parsed contents.
    root.append(body);
    final parsedBody = parsed.body;
    if (parsedBody != null) {
      body.innerHTML = parsedBody.innerHtml;
    } else {
      body.innerHTML = parsedHtml?.innerHtml;
    }
  }
}

class _SelectorMatcher {
  _SelectorMatcher(String selector) {
    final trimmed = selector.trim();
    final bracketIndex = trimmed.indexOf('[');
    if (trimmed.startsWith('.')) {
      className = trimmed.substring(1);
      tag = null;
    } else if (trimmed.startsWith('[')) {
      tag = null;
      _parseAttribute(trimmed);
    } else if (bracketIndex == -1) {
      tag = trimmed.toUpperCase();
    } else {
      tag = trimmed.substring(0, bracketIndex).toUpperCase();
      _parseAttribute(trimmed.substring(bracketIndex));
    }
  }

  String? tag;
  String? className;
  String? attribute;
  String? operatorSymbol;
  String? value;

  void _parseAttribute(String fragment) {
    var inner = fragment.trim();
    if (!inner.startsWith('[') || !inner.endsWith(']')) {
      return;
    }
    inner = inner.substring(1, inner.length - 1).trim();
    if (inner.isEmpty) {
      return;
    }

    final opMatch = RegExp(r'(\*=|\^=|=)').firstMatch(inner);
    if (opMatch == null) {
      attribute = inner;
      return;
    }

    attribute = inner.substring(0, opMatch.start).trim();
    operatorSymbol = opMatch.group(0);
    var rawValue = inner.substring(opMatch.end).trim();
    if (rawValue.length >= 2 &&
        ((rawValue.startsWith('"') && rawValue.endsWith('"')) ||
            (rawValue.startsWith("'") && rawValue.endsWith("'")))) {
      rawValue = rawValue.substring(1, rawValue.length - 1);
    }
    // CSS string escapes are syntax, not part of the attribute value.
    value = rawValue.replaceAll(r'\"', '"').replaceAll(r"\'", "'");
  }

  bool matches(FakeDomElement element) {
    if (tag != null && element.tagName != tag) {
      return false;
    }
    if (className != null && !element.classes.contains(className!)) {
      return false;
    }
    if (attribute == null) {
      return true;
    }
    final attrValue = attribute == 'class'
        ? element.className ?? ''
        : element.getAttribute(attribute!);
    if (attrValue == null) {
      return false;
    }
    if (operatorSymbol == null) {
      return true;
    }
    switch (operatorSymbol) {
      case '*=':
        return attrValue.contains(value ?? '');
      case '^=':
        return attrValue.startsWith(value ?? '');
      case '=':
        return attrValue == (value ?? '');
      default:
        return false;
    }
  }
}

class FakeDomNode implements DomNode {
  /// The fake DOM hands out the same object for a node, so it is its own key.
  @override
  Object get identityKey => this;

  FakeDomNode([String? tagName])
      : _tagName = tagName,
        parentNode = null;

  @override
  FakeDomNode? parentNode;
  @override
  FakeDomNode? previousSibling;
  @override
  FakeDomNode? nextSibling;

  // Filhos como LISTA ENCADEADA sobre previousSibling/nextSibling (que os
  // nós já mantêm), como um DOM de verdade: o List espelho fazia indexOf +
  // removeAt com shift, e o dreno das fusões de container do editor virava
  // O(n²) — só no fake DOM, escondendo que o browser (C++) não paga isso.
  FakeDomNode? _firstChild;
  FakeDomNode? _lastChild;
  final String? _tagName;

  Iterable<FakeDomNode> get internalChildren sync* {
    for (var node = _firstChild; node != null; node = node.nextSibling) {
      yield node;
    }
  }

  String? get rawTagName => _tagName;

  @override
  String get nodeName => _tagName ?? '#node';

  @override
  int get nodeType =>
      _tagName != null ? DomNode.ELEMENT_NODE : DomNode.TEXT_NODE;

  @override
  String? get textContent {
    if (this is FakeDomText) {
      return (this as FakeDomText).data;
    }
    if (this is FakeDomElement) {
      return (this as FakeDomElement).text;
    }
    return null;
  }

  @override
  List<DomNode> get childNodes => List<DomNode>.unmodifiable(internalChildren);

  @override
  DomNode? get firstChild => _firstChild;

  @override
  DomNode? get lastChild => _lastChild;

  @override
  void append(DomNode node) {
    insertBefore(node, null);
  }

  @override
  void insertBefore(DomNode node, DomNode? referenceNode) {
    final fake = node as FakeDomNode;
    fake.parentNode?.removeChild(fake);
    fake.parentNode = this;

    final ref = referenceNode as FakeDomNode?;
    if (ref == null || !identical(ref.parentNode, this)) {
      // append (ref ausente ou estranho, como no DOM real)
      final last = _lastChild;
      fake.previousSibling = last;
      fake.nextSibling = null;
      if (last != null) {
        last.nextSibling = fake;
      } else {
        _firstChild = fake;
      }
      _lastChild = fake;
    } else {
      final prev = ref.previousSibling;
      fake.previousSibling = prev;
      fake.nextSibling = ref;
      ref.previousSibling = fake;
      if (prev != null) {
        prev.nextSibling = fake;
      } else {
        _firstChild = fake;
      }
    }
  }

  void replaceChild(FakeDomNode existing, DomNode replacement) {
    if (!identical(existing.parentNode, this)) return;
    final fakeReplacement = replacement as FakeDomNode;
    fakeReplacement.parentNode?.removeChild(fakeReplacement);
    fakeReplacement.parentNode = this;
    final prev = existing.previousSibling;
    final next = existing.nextSibling;
    fakeReplacement.previousSibling = prev;
    fakeReplacement.nextSibling = next;
    if (prev != null) {
      prev.nextSibling = fakeReplacement;
    } else {
      _firstChild = fakeReplacement;
    }
    if (next != null) {
      next.previousSibling = fakeReplacement;
    } else {
      _lastChild = fakeReplacement;
    }
    existing.parentNode = null;
    existing.previousSibling = null;
    existing.nextSibling = null;
  }

  void removeChild(FakeDomNode child) {
    if (!identical(child.parentNode, this)) return;
    final prev = child.previousSibling;
    final next = child.nextSibling;
    if (prev != null) {
      prev.nextSibling = next;
    } else {
      _firstChild = next;
    }
    if (next != null) {
      next.previousSibling = prev;
    } else {
      _lastChild = prev;
    }
    child.parentNode = null;
    child.previousSibling = null;
    child.nextSibling = null;
  }

  @override
  void remove() {
    parentNode?.removeChild(this);
  }
}

class FakeDomElement extends FakeDomNode implements DomElement {
  FakeDomElement(String tagName, {FakeDomDocument? document})
      : _ownerDocument = document ?? FakeDomDocument(),
        _tagName = tagName.toUpperCase(),
        _classes = FakeDomClassList(),
        super(tagName.toUpperCase()) {
    // A real browser materializes the `class` attribute on ANY classList
    // mutation — even remove() on an element without one leaves class="".
    // The serialized outerHTML depends on that presence.
    _classes.onMutate = () => _classAttributePresent = true;
  }

  bool _classAttributePresent = false;

  final FakeDomDocument _ownerDocument;
  final String _tagName;
  String? _text;
  final Map<String, String> _attributes = {};
  final Map<String, String> _dataset = {};
  final FakeDomClassList _classes;
  final Map<String, List<DomEventListener>> _listeners = {};
  late final _FakeStyle _style = _FakeStyle(this);
  int _scrollTop = 0;
  int _scrollLeft = 0;
  final List<({double left, double top, bool smooth})> scrollCalls = [];

  @override
  String get tagName => _tagName;

  @override
  DomDocument get ownerDocument => _ownerDocument;

  @override
  DomClassList get classes => _classes;

  @override
  String? get text => _text ?? _collectTextFromChildren();

  @override
  set text(String? value) {
    while (firstChild != null) {
      firstChild!.remove();
    }
    _text = value;
    if (value != null && value.isNotEmpty) {
      append(FakeDomText(value, document: _ownerDocument));
    }
  }

  @override
  void addEventListener(String type, DomEventListener listener) {
    (_listeners[type] ??= []).add(listener);
  }

  @override
  void removeEventListener(String type, DomEventListener listener) {
    _listeners[type]?.remove(listener);
  }

  void dispatchEvent(String type, DomEvent event) {
    for (final listener
        in List<DomEventListener>.from(_listeners[type] ?? const [])) {
      listener(event);
    }
  }

  @override
  void setAttribute(String name, String value) {
    // NB: `style` is stored verbatim, as a real browser does for setAttribute.
    // The rgb()/semicolon normalization of CSSOM writes lives in
    // StyleAttributor._writeInlineStyles, the path that emulates
    // `node.style[prop] = value`.
    //
    // `class` is one state with `classes`/`className`, as in a real DOM:
    // setAttribute('class', …) rewrites the token list. Keeping them apart
    // made an element report a class through getAttribute that its
    // serialized outerHTML did not carry.
    if (name == 'class') {
      _classes._values.clear();
      for (final token in value.split(RegExp(r'\s+'))) {
        if (token.isNotEmpty) _classes._values.add(token);
      }
      _classAttributePresent = true;
      return;
    }
    _attributes[name] = value;
    if (name.startsWith('data-')) {
      _dataset[name.substring(5)] = value;
    }
  }

  @override
  String? getAttribute(String name) {
    if (name == 'class') {
      return hasAttribute('class') ? (className ?? '') : null;
    }
    return _attributes[name];
  }

  @override
  bool hasAttribute(String name) => name == 'class'
      ? (_classAttributePresent || _classes.values.isNotEmpty)
      : _attributes.containsKey(name);

  Map<String, String> get attributes => Map.unmodifiable(_attributes);

  @override
  List<String> get attributeNames => [
        if (hasAttribute('class')) 'class',
        ..._attributes.keys.where((name) => name != 'class'),
      ];

  @override
  void removeAttribute(String name) {
    if (name == 'class') {
      _classes._values.clear();
      _classAttributePresent = false;
      return;
    }
    _attributes.remove(name);
    if (name.startsWith('data-')) {
      _dataset.remove(name.substring(5));
    }
  }

  @override
  Map<String, String> get dataset => _dataset;

  @override
  void select() {
    _dataset['selected'] = 'true';
  }

  @override
  void click() {
    _dataset['clicked'] = 'true';
    // A real `element.click()` dispatches a click event, so listeners run.
    dispatchEvent('click', FakeDomMouseEvent(type: 'click', target: this));
  }

  @override
  void appendText(String value) {
    append(FakeDomText(value, document: _ownerDocument));
  }

  @override
  DomElement cloneNode({bool deep = false}) {
    final clone = FakeDomElement(_tagName, document: _ownerDocument);
    // A shallow clone carries NO content in a real browser. `_text` is the
    // childless-element shortcut, so copying it made `cloneNode(false)` hand
    // back the original's text — the test double would then disagree with the
    // browser about what a split produced.
    if (deep) {
      clone._text = _text;
    }
    clone._attributes.addAll(_attributes);
    clone._dataset.addAll(_dataset);
    for (final token in _classes.values) {
      clone._classes.add(token);
    }
    clone._classAttributePresent = _classAttributePresent;
    if (deep) {
      for (final child in internalChildren) {
        if (child is FakeDomElement) {
          clone.append(child.cloneNode(deep: true));
        } else if (child is FakeDomText) {
          clone.append(FakeDomText(child.data, document: _ownerDocument));
        }
      }
    }
    return clone;
  }

  @override
  void replaceWith(DomElement node) {
    final parent = parentNode;
    if (parent == null) return;
    parent.replaceChild(this, node);
  }

  @override
  bool contains(DomNode? node) {
    if (node == null) return false;
    DomNode? current = node;
    while (current != null) {
      if (current == this) return true;
      current = current.parentNode;
    }
    return false;
  }

  @override
  DomElement? querySelector(String selector) {
    final matcher = _SelectorMatcher(selector);

    DomElement? find(FakeDomNode node) {
      if (node is FakeDomElement) {
        if (matcher.matches(node)) return node;
        for (final child in node.internalChildren) {
          final result = find(child);
          if (result != null) return result;
        }
      }
      return null;
    }

    for (final child in internalChildren) {
      final result = find(child);
      if (result != null) return result;
    }
    return null;
  }

  @override
  List<DomElement> querySelectorAll(String selectors) {
    final matcher = _SelectorMatcher(selectors);
    final results = <DomElement>[];

    void traverse(FakeDomNode node) {
      if (node is FakeDomElement) {
        if (matcher.matches(node)) {
          results.add(node);
        }
        for (final child in node.internalChildren) {
          traverse(child);
        }
      }
    }

    for (final child in internalChildren) {
      traverse(child);
    }

    return results;
  }

  @override
  String? get className => _classes.values.join(' ');

  @override
  String? get id => getAttribute('id');

  @override
  dynamic get style => _style;

  @override
  int get scrollTop => _scrollTop;

  @override
  set scrollTop(int value) {
    _scrollTop = value;
  }

  @override
  int get scrollLeft => _scrollLeft;

  @override
  set scrollLeft(int value) {
    _scrollLeft = value;
  }

  @override
  int get offsetWidth => 100; // Fake width for testing

  @override
  int get offsetHeight => 24; // Fake height for testing

  @override
  int get clientWidth => 100;

  @override
  int get clientHeight => 24;

  @override
  void scrollBy(double left, double top, {bool smooth = false}) {
    scrollCalls.add((left: left, top: top, smooth: smooth));
    _scrollLeft += left.round();
    _scrollTop += top.round();
  }

  @override
  String? get innerHTML {
    if (internalChildren.isEmpty) {
      return _text;
    }
    final buffer = StringBuffer();
    for (final child in internalChildren) {
      _serializeHtmlNode(child, buffer);
    }
    return buffer.toString();
  }

  @override
  String get outerHTML {
    final buffer = StringBuffer();
    _serializeHtmlNode(this, buffer);
    return buffer.toString();
  }

  @override
  set innerHTML(String? value) {
    while (firstChild != null) {
      firstChild!.remove();
    }
    _text = null;
    if (value == null || value.isEmpty) {
      return;
    }
    final fragment = html_parser.parseFragment(value);
    for (final node in fragment.nodes) {
      final converted = _convertHtmlNode(node, _ownerDocument);
      if (converted != null) {
        append(converted);
      }
    }
  }

  @override
  String get value => _attributes['value'] ?? '';

  @override
  set value(String? val) {
    if (val == null) {
      _attributes.remove('value');
    } else {
      _attributes['value'] = val;
    }
  }

  String? _collectTextFromChildren() {
    if (internalChildren.isEmpty) {
      return null;
    }
    final buffer = StringBuffer();
    for (final child in internalChildren) {
      if (child is FakeDomText) {
        buffer.write(child.data);
      } else if (child is FakeDomElement) {
        final nested = child.text;
        if (nested != null) {
          buffer.write(nested);
        }
      }
    }
    return buffer.isEmpty ? null : buffer.toString();
  }
}

FakeDomNode? _convertHtmlNode(html_dom.Node node, FakeDomDocument document) {
  if (node is html_dom.Element) {
    final tagName = node.localName ?? 'div';
    final element = FakeDomElement(tagName, document: document);
    for (final entry in node.attributes.entries) {
      final key = entry.key.toString();
      final attrValue = entry.value.toString();
      element.setAttribute(key, attrValue);
      if (key == 'class') {
        for (final token in attrValue.split(RegExp(r'\s+'))) {
          if (token.isNotEmpty) {
            element.classes.add(token);
          }
        }
      }
    }
    for (final child in node.nodes) {
      final convertedChild = _convertHtmlNode(child, document);
      if (convertedChild != null) {
        element.append(convertedChild);
      }
    }
    return element;
  }
  if (node is html_dom.Text) {
    return FakeDomText(node.data, document: document);
  }
  return null;
}

void _serializeHtmlNode(FakeDomNode node, StringBuffer buffer) {
  if (node is FakeDomText) {
    buffer.write(node.data);
    return;
  }
  if (node is FakeDomElement) {
    final tag = node.tagName.toLowerCase();
    buffer.write('<$tag');
    // Well-known attributes first, so existing expectations keep their order;
    // then everything else, alphabetically.
    //
    // This list used to be the *only* thing serialized, which meant
    // `data-row`, `data-cell`, `style`, `colspan` and friends were invisible in
    // `innerHTML`. That is not a cosmetic gap: it made a correctly built table
    // look like one that had lost its row ids, and sent a debugging session
    // after a bug that was not there. A fake DOM may be small, but it must not
    // hide state it was asked to store.
    const attributeOrder = [
      'src',
      'href',
      'class',
      'id',
      'frameborder',
      'allowfullscreen',
      'width',
      'height',
      'alt',
    ];
    void writeAttribute(String name) {
      if (name == 'class') {
        // Present-but-empty serializes as class="" — a browser keeps the
        // attribute after classList mutations empty it.
        if (node.hasAttribute('class')) {
          buffer.write(' class="${node.className ?? ''}"');
        }
        return;
      }
      if (name == 'id') {
        final id = node.id;
        if (id != null && id.isNotEmpty) {
          buffer.write(' id="$id"');
        }
        return;
      }
      final value = node.getAttribute(name);
      if (value != null) {
        buffer.write(' $name="$value"');
      }
    }

    for (final name in attributeOrder) {
      writeAttribute(name);
    }
    final rest = node.attributeNames
        .where((name) => !attributeOrder.contains(name))
        .toList()
      ..sort();
    for (final name in rest) {
      writeAttribute(name);
    }
    buffer.write('>');
    if (_voidHtmlElements.contains(tag)) {
      return;
    }
    if (node.internalChildren.isEmpty) {
      // The `_text` shortcut is what innerHTML reports for a childless
      // element; outerHTML must serialize the same content or the
      // outer/inner split in the semantic HTML converter breaks.
      final text = node._text;
      if (text != null) {
        buffer.write(text);
      }
    }
    for (final child in node.internalChildren) {
      _serializeHtmlNode(child, buffer);
    }
    buffer.write('</$tag>');
  }
}

// The full HTML void-element set — a fake serializer that closes a void
// element (`<col></col>`) diverges from every real browser's outerHTML.
const Set<String> _voidHtmlElements = {
  'area',
  'base',
  'br',
  'col',
  'embed',
  'hr',
  'img',
  'input',
  'link',
  'meta',
  'source',
  'track',
  'wbr',
};

class FakeDomText extends FakeDomNode implements DomText {
  FakeDomText(this._data, {FakeDomDocument? document})
      : _ownerDocument = document ?? FakeDomDocument(),
        super(null);

  final FakeDomDocument _ownerDocument;
  String _data;

  @override
  String get nodeName => '#text';

  @override
  int get nodeType => DomNode.TEXT_NODE;

  @override
  String get data => _data;

  @override
  set data(String value) {
    _data = value;
  }

  FakeDomText cloneNode() => FakeDomText(_data, document: _ownerDocument);
}

class FakeDomClassList implements DomClassList {
  final Set<String> _values = <String>{};

  /// Called on every mutation — the owning element uses it to materialize the
  /// `class` attribute, as a real browser's classList does.
  void Function()? onMutate;

  void clear() {
    _values.clear();
    onMutate?.call();
  }

  @override
  void add(String token) {
    _values.add(token);
    onMutate?.call();
  }

  @override
  bool contains(String token) => _values.contains(token);

  @override
  void remove(String token) {
    _values.remove(token);
    onMutate?.call();
  }

  @override
  void toggle(String token, [bool? force]) {
    final shouldAdd = force ?? !_values.contains(token);
    if (shouldAdd) {
      _values.add(token);
    } else {
      _values.remove(token);
    }
    onMutate?.call();
  }

  @override
  Iterable<String> get values => _values;
}

class FakeDomMutationObserver implements DomMutationObserver {
  FakeDomMutationObserver(this.callback);

  final void Function(List<DomMutationRecord>, DomMutationObserver) callback;

  @override
  void disconnect() {}

  @override
  void observe(DomNode target,
      {bool? subtree,
      bool? childList,
      bool? characterData,
      bool? attributes,
      bool? characterDataOldValue}) {}

  @override
  List<DomMutationRecord> takeRecords() => const [];
}

class _FakeStyle {
  _FakeStyle(this.element);
  final FakeDomElement element;
  final Map<String, String> _styles = {};

  void setProperty(String property, String value) {
    _styles[property] = value;
  }

  String getPropertyValue(String property) => _styles[property] ?? '';

  // Allow dynamic property access
  dynamic noSuchMethod(Invocation invocation) {
    final name = invocation.memberName.toString().split('"')[1];
    if (invocation.isGetter) {
      return _styles[name] ?? '';
    } else if (invocation.isSetter) {
      final value = invocation.positionalArguments[0];
      _styles[name.substring(0, name.length - 1)] = value.toString();
      return null;
    }
    return super.noSuchMethod(invocation);
  }
}

class FakeDomParser implements DomParser {
  @override
  DomDocument parseFromString(String string, String type) {
    // Parse the incoming HTML into a new fake document so clipboard tests
    // can traverse the expected structure.
    return FakeDomDocument.fromHtml(string);
  }
}

class FakeDomEvent implements DomEvent {
  FakeDomEvent(this.type, [this.target]);
  final String type;
  bool defaultPrevented = false;

  @override
  final DomNode? target;

  @override
  dynamic get rawEvent => this;

  @override
  void preventDefault() {
    defaultPrevented = true;
  }

  @override
  void stopPropagation() {
    // No-op for fake implementation.
  }
}

class FakeDomMouseEvent extends FakeDomEvent implements DomMouseEvent {
  FakeDomMouseEvent({
    required String type,
    DomNode? target,
    this.dataTransfer,
    this.clientX = 0,
    this.clientY = 0,
    this.detail = 1,
    this.altKey = false,
    this.ctrlKey = false,
    this.metaKey = false,
    this.shiftKey = false,
  }) : super(type, target);

  @override
  final DomDataTransfer? dataTransfer;
  @override
  final num clientX;
  @override
  final num clientY;
  @override
  final int detail;
  @override
  final bool altKey;
  @override
  final bool ctrlKey;
  @override
  final bool metaKey;
  @override
  final bool shiftKey;
}

class FakeDomKeyboardEvent extends FakeDomEvent implements DomKeyboardEvent {
  @override
  final bool isComposing;

  FakeDomKeyboardEvent({
    required String type,
    DomNode? target,
    required this.key,
    this.keyCode,
    this.altKey = false,
    this.ctrlKey = false,
    this.metaKey = false,
    this.shiftKey = false,
    this.isComposing = false,
  }) : super(type, target);

  @override
  final String key;
  @override
  final int? keyCode;
  @override
  final bool altKey;
  @override
  final bool ctrlKey;
  @override
  final bool metaKey;
  @override
  final bool shiftKey;
}

class FakeDomInputEvent extends FakeDomEvent implements DomInputEvent {
  FakeDomInputEvent({
    required String type,
    DomNode? target,
    this.inputType,
    this.data,
    this.isComposing = false,
    DomDataTransfer? dataTransfer,
    List<DomNativeRange> targetRanges = const [],
  })  : _dataTransfer = dataTransfer,
        _targetRanges = targetRanges,
        super(type, target);

  @override
  final String? inputType;

  @override
  final bool isComposing;

  @override
  final String? data;

  final DomDataTransfer? _dataTransfer;

  @override
  DomDataTransfer? get dataTransfer => _dataTransfer;

  final List<DomNativeRange> _targetRanges;

  @override
  List<DomNativeRange> getTargetRanges() =>
      List<DomNativeRange>.unmodifiable(_targetRanges);
}

class FakeDomClipboardEvent extends FakeDomEvent implements DomClipboardEvent {
  FakeDomClipboardEvent({
    required String type,
    DomNode? target,
    DomDataTransfer? clipboardData,
  })  : _clipboardData = clipboardData ?? FakeDomDataTransfer(),
        super(type, target);

  DomDataTransfer? _clipboardData;

  @override
  DomDataTransfer? get clipboardData => _clipboardData;

  set clipboardData(DomDataTransfer? value) {
    _clipboardData = value;
  }
}

class FakeDomFile implements DomFile {
  FakeDomFile({
    required this.name,
    this.type = '',
    this.size = 0,
  });

  @override
  final String name;

  @override
  final String type;

  @override
  final int size;
}

class FakeDomDataTransfer implements DomDataTransfer {
  FakeDomDataTransfer([Map<String, String>? initial, Iterable<DomFile>? files])
      : _data = initial != null
            ? Map<String, String>.from(initial)
            : <String, String>{},
        _files = files != null ? List<DomFile>.from(files) : <DomFile>[];

  final Map<String, String> _data;
  final List<DomFile> _files;

  @override
  List<DomFile> get files => List.unmodifiable(_files);

  @override
  List<String> get types => List.unmodifiable(_data.keys);

  @override
  String? getData(String format) => _data[format];

  @override
  void setData(String format, String data) {
    _data[format] = data;
  }

  void setFiles(Iterable<DomFile> files) {
    _files
      ..clear()
      ..addAll(files);
  }

  Map<String, String> get data => Map.unmodifiable(_data);
}

class FakeDomMutationRecord implements DomMutationRecord {
  FakeDomMutationRecord(this.target);

  @override
  final DomNode target;

  @override
  List<DomNode> get addedNodes => const [];

  @override
  List<DomNode> get removedNodes => const [];

  @override
  DomNode? get previousSibling => null;

  @override
  DomNode? get nextSibling => null;

  @override
  String get type => 'attributes';
}
