import 'package:dart_quill/src/platform/dom.dart';

class FakeDomAdapter implements DomAdapter {
  FakeDomAdapter() : document = FakeDomDocument();

  @override
  final FakeDomDocument document;

  @override
  DomMutationObserver createMutationObserver(
    void Function(List<DomMutationRecord> records, DomMutationObserver observer) callback,
  ) {
    return FakeDomMutationObserver(callback);
  }

  @override
  DomEvent createEvent(String type) => FakeDomEvent(type);
}

class FakeDomDocument implements DomDocument {
  FakeDomDocument() {
    _body = FakeDomElement('BODY', document: this);
  }

  late final FakeDomElement _body;

  @override
  DomElement createElement(String tagName) => FakeDomElement(tagName.toUpperCase(), document: this);

  @override
  DomText createTextNode(String value) => FakeDomText(value, document: this);

  @override
  DomElement get body => _body;
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
  String? get text => _text;

  @override
  set text(String? value) {
    _text = value;
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
}

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
  void observe(DomNode target, {bool? subtree, bool? childList, bool? characterData}) {}

  @override
  List<DomMutationRecord> takeRecords() => const [];
}

class FakeDomEvent implements DomEvent {
  FakeDomEvent(this.type);
  final String type;
  bool defaultPrevented = false;

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

