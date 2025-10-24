import 'package:dart_quill/src/platform/dom.dart';
import 'package:html/dom.dart' as html_dom;
import 'package:html/parser.dart' as html_parser;

class FakeDomAdapter implements DomAdapter {
  FakeDomAdapter() : document = FakeDomDocument();

  @override
  final FakeDomDocument document;

  @override
  DomMutationObserver createMutationObserver(
    void Function(List<DomMutationRecord> records, DomMutationObserver observer)
        callback,
  ) {
    return FakeDomMutationObserver(callback);
  }

  // Helper method for creating fake events (not part of DomAdapter interface)
  DomEvent createEvent(String type) => FakeDomEvent(type);
}

class FakeDomDocument implements DomDocument {
  FakeDomDocument() {
    _body = FakeDomElement('BODY', document: this);
  }

  late final FakeDomElement _body;

  @override
  DomElement createElement(String tagName) =>
      FakeDomElement(tagName.toUpperCase(), document: this);

  @override
  DomText createTextNode(String value) => FakeDomText(value, document: this);

  @override
  DomElement get body => _body;

  @override
  DomElement? querySelector(String selectors) {
    // Simple implementation: return first matching element by tag name
    final tag = selectors.toUpperCase();
    for (final child in _body.internalChildren) {
      if (child is FakeDomElement && child.tagName == tag) {
        return child;
      }
    }
    return null;
  }

  @override
  List<DomElement> querySelectorAll(String selectors) {
    // Simple implementation: return all matching elements
    final results = <DomElement>[];
    final tag = selectors.toUpperCase();
    for (final child in _body.internalChildren) {
      if (child is FakeDomElement && child.tagName == tag) {
        results.add(child);
      }
    }
    return results;
  }

  @override
  DomParser get parser => FakeDomParser();
}

class FakeDomNode implements DomNode {
  FakeDomNode([String? tagName])
      : _tagName = tagName,
        parentNode = null;

  @override
  FakeDomNode? parentNode;
  @override
  FakeDomNode? previousSibling;
  @override
  FakeDomNode? nextSibling;

  final List<FakeDomNode> _children = [];
  final String? _tagName;

  Iterable<FakeDomNode> get internalChildren => _children;

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
  List<DomNode> get childNodes => List.unmodifiable(_children);

  @override
  DomNode? get firstChild => _children.isEmpty ? null : _children.first;

  @override
  DomNode? get lastChild => _children.isEmpty ? null : _children.last;

  @override
  void append(DomNode node) {
    insertBefore(node, null);
  }

  @override
  void insertBefore(DomNode node, DomNode? referenceNode) {
    final fake = node as FakeDomNode;
    fake.parentNode?.removeChild(fake);
    fake.parentNode = this;

    if (referenceNode == null) {
      if (_children.isNotEmpty) {
        final last = _children.last;
        last.nextSibling = fake;
        fake.previousSibling = last;
      }
      _children.add(fake);
    } else {
      final ref = referenceNode as FakeDomNode;
      final index = _children.indexOf(ref);
      if (index == -1) {
        _children.add(fake);
      } else {
        final prev = ref.previousSibling;
        if (prev != null) {
          prev.nextSibling = fake;
          fake.previousSibling = prev;
        }
        fake.nextSibling = ref;
        ref.previousSibling = fake;
        _children.insert(index, fake);
      }
    }
  }

  void replaceChild(FakeDomNode existing, DomNode replacement) {
    final index = _children.indexOf(existing);
    if (index == -1) return;
    final fakeReplacement = replacement as FakeDomNode;
    fakeReplacement.parentNode?.removeChild(fakeReplacement);
    fakeReplacement.parentNode = this;
    final prev = existing.previousSibling;
    final next = existing.nextSibling;
    fakeReplacement.previousSibling = prev;
    fakeReplacement.nextSibling = next;
    if (prev != null) {
      prev.nextSibling = fakeReplacement;
    }
    if (next != null) {
      next.previousSibling = fakeReplacement;
    }
    _children[index] = fakeReplacement;
    existing.parentNode = null;
    existing.previousSibling = null;
    existing.nextSibling = null;
  }

  void removeChild(FakeDomNode child) {
    final index = _children.indexOf(child);
    if (index == -1) return;
    _children.removeAt(index);
    final prev = child.previousSibling;
    final next = child.nextSibling;
    if (prev != null) {
      prev.nextSibling = next;
    }
    if (next != null) {
      next.previousSibling = prev;
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
        super(tagName.toUpperCase());

  final FakeDomDocument _ownerDocument;
  final String _tagName;
  String? _text;
  final Map<String, String> _attributes = {};
  final Map<String, String> _dataset = {};
  final FakeDomClassList _classes;

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
    // No-op for fake implementation.
  }

  @override
  void removeEventListener(String type, DomEventListener listener) {
    // No-op for fake implementation.
  }

  @override
  void setAttribute(String name, String value) {
    _attributes[name] = value;
    if (name.startsWith('data-')) {
      _dataset[name.substring(5)] = value;
    }
  }

  @override
  String? getAttribute(String name) => _attributes[name];

  @override
  bool hasAttribute(String name) => _attributes.containsKey(name);
  
  Map<String, String> get attributes => Map.unmodifiable(_attributes);

  @override
  void removeAttribute(String name) {
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
  void appendText(String value) {
    append(FakeDomText(value, document: _ownerDocument));
  }

  @override
  DomElement cloneNode({bool deep = false}) {
    final clone = FakeDomElement(_tagName, document: _ownerDocument);
    clone._text = _text;
    clone._attributes.addAll(_attributes);
    clone._dataset.addAll(_dataset);
    for (final token in _classes.values) {
      clone._classes.add(token);
    }
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
    // Simple implementation for testing
    if (selector.startsWith('.')) {
      final className = selector.substring(1);
      for (final child in internalChildren) {
        if (child is FakeDomElement && child.classes.contains(className)) {
          return child;
        }
      }
    } else {
      final tag = selector.toUpperCase();
      for (final child in internalChildren) {
        if (child is FakeDomElement && child.tagName == tag) {
          return child;
        }
      }
    }
    return null;
  }

  @override
  List<DomElement> querySelectorAll(String selectors) {
    final results = <DomElement>[];
    if (selectors.startsWith('.')) {
      final className = selectors.substring(1);
      for (final child in internalChildren) {
        if (child is FakeDomElement && child.classes.contains(className)) {
          results.add(child);
        }
      }
    } else {
      final tag = selectors.toUpperCase();
      for (final child in internalChildren) {
        if (child is FakeDomElement && child.tagName == tag) {
          results.add(child);
        }
      }
    }
    return results;
  }

  @override
  String? get className => _classes.values.join(' ');

  @override
  String? get id => getAttribute('id');

  @override
  dynamic get style => _FakeStyle(this);

  @override
  int get scrollTop => 0;

  @override
  set scrollTop(int value) {
    // No-op for fake
  }

  @override
  int get offsetWidth => 100; // Fake width for testing

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
    for (final name in attributeOrder) {
      if (name == 'class') {
        final className = node.className;
        if (className != null && className.isNotEmpty) {
          buffer.write(' class="$className"');
        }
        continue;
      }
      if (name == 'id') {
        final id = node.id;
        if (id != null && id.isNotEmpty) {
          buffer.write(' id="$id"');
        }
        continue;
      }
      final value = node.getAttribute(name);
      if (value != null) {
        buffer.write(' $name="$value"');
      }
    }
    buffer.write('>');
    if (_voidHtmlElements.contains(tag)) {
      return;
    }
    for (final child in node.internalChildren) {
      _serializeHtmlNode(child, buffer);
    }
    buffer.write('</$tag>');
  }
}

const Set<String> _voidHtmlElements = {
  'br',
  'hr',
  'img',
  'input',
  'meta',
  'link',
};

class FakeDomText extends FakeDomNode implements DomText {
  FakeDomText(this._data, {FakeDomDocument? document})
      : _ownerDocument = document ?? FakeDomDocument(),
        super('#text');

  final FakeDomDocument _ownerDocument;
  String _data;

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

  @override
  void add(String token) {
    _values.add(token);
  }

  @override
  bool contains(String token) => _values.contains(token);

  @override
  void remove(String token) {
    _values.remove(token);
  }

  @override
  void toggle(String token, [bool? force]) {
    final shouldAdd = force ?? !_values.contains(token);
    if (shouldAdd) {
      _values.add(token);
    } else {
      _values.remove(token);
    }
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
      {bool? subtree, bool? childList, bool? characterData}) {}

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
    // Simple fake implementation
    return FakeDomDocument();
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
