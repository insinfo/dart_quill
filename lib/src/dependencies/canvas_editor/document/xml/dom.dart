import 'dart:convert';
import 'dart:typed_data';

import 'sax.dart';
import 'serializer.dart';

/// Nó do DOM leve do ce_xml (roteiro_editor_profissional, decisão D6).
sealed class XmlNode {
  XmlElement? parent;

  void writeTo(StringBuffer buffer);

  XmlNode copy();

  String toXmlString() {
    final buffer = StringBuffer();
    writeTo(buffer);
    return buffer.toString();
  }
}

class XmlText extends XmlNode {
  String value;

  XmlText(this.value);

  @override
  void writeTo(StringBuffer buffer) => buffer.write(XmlEscape.text(value));

  @override
  XmlText copy() => XmlText(value);
}

class XmlCData extends XmlNode {
  String value;

  XmlCData(this.value);

  @override
  void writeTo(StringBuffer buffer) {
    buffer
      ..write('<![CDATA[')
      ..write(value)
      ..write(']]>');
  }

  @override
  XmlCData copy() => XmlCData(value);
}

class XmlComment extends XmlNode {
  String value;

  XmlComment(this.value);

  @override
  void writeTo(StringBuffer buffer) {
    buffer
      ..write('<!--')
      ..write(value)
      ..write('-->');
  }

  @override
  XmlComment copy() => XmlComment(value);
}

class XmlProcessingInstruction extends XmlNode {
  String target;
  String? data;

  XmlProcessingInstruction(this.target, [this.data]);

  @override
  void writeTo(StringBuffer buffer) {
    buffer.write('<?$target');
    final d = data;
    if (d != null && d.isNotEmpty) buffer.write(' $d');
    buffer.write('?>');
  }

  @override
  XmlProcessingInstruction copy() => XmlProcessingInstruction(target, data);
}

class XmlAttribute {
  String qname;
  String value;

  XmlAttribute(this.qname, this.value);

  String get localName => XmlNameUtil.localName(qname);
  String? get prefix => XmlNameUtil.prefix(qname);

  XmlAttribute copy() => XmlAttribute(qname, value);

  @override
  String toString() => '$qname="$value"';
}

class XmlElement extends XmlNode {
  String qname;
  final List<XmlAttribute> attributes;
  final List<XmlNode> children;

  XmlElement(this.qname,
      [List<XmlAttribute>? attributes, List<XmlNode>? children])
      : attributes = attributes ?? <XmlAttribute>[],
        children = children ?? <XmlNode>[] {
    for (final child in this.children) {
      child.parent = this;
    }
  }

  String get localName => XmlNameUtil.localName(qname);
  String? get prefix => XmlNameUtil.prefix(qname);

  // ---- Atributos ----

  String? getAttribute(String qname) {
    for (final attr in attributes) {
      if (attr.qname == qname) return attr.value;
    }
    return null;
  }

  void setAttribute(String qname, String value) {
    for (final attr in attributes) {
      if (attr.qname == qname) {
        attr.value = value;
        return;
      }
    }
    attributes.add(XmlAttribute(qname, value));
  }

  bool removeAttribute(String qname) {
    for (var i = 0; i < attributes.length; i++) {
      if (attributes[i].qname == qname) {
        attributes.removeAt(i);
        return true;
      }
    }
    return false;
  }

  // ---- Filhos ----

  Iterable<XmlElement> get childElements => children.whereType<XmlElement>();

  /// Primeiro filho direto com o [qname] dado, ou `null`.
  XmlElement? firstChild(String qname) {
    for (final child in children) {
      if (child is XmlElement && child.qname == qname) return child;
    }
    return null;
  }

  /// Filhos diretos com o [qname] dado.
  Iterable<XmlElement> childrenNamed(String qname) sync* {
    for (final child in children) {
      if (child is XmlElement && child.qname == qname) yield child;
    }
  }

  /// Descendentes (profundidade, ordem do documento) com o [qname] dado.
  Iterable<XmlElement> descendantsNamed(String qname) sync* {
    for (final child in children) {
      if (child is XmlElement) {
        if (child.qname == qname) yield child;
        yield* child.descendantsNamed(qname);
      }
    }
  }

  /// Todos os descendentes elementos (profundidade, ordem do documento).
  Iterable<XmlElement> get descendants sync* {
    for (final child in children) {
      if (child is XmlElement) {
        yield child;
        yield* child.descendants;
      }
    }
  }

  void add(XmlNode node) {
    node.parent = this;
    children.add(node);
  }

  void insert(int index, XmlNode node) {
    node.parent = this;
    children.insert(index, node);
  }

  bool remove(XmlNode node) {
    final removed = children.remove(node);
    if (removed) node.parent = null;
    return removed;
  }

  /// Texto concatenado de todos os descendentes.
  String get text {
    final buffer = StringBuffer();
    _collectText(buffer);
    return buffer.toString();
  }

  void _collectText(StringBuffer buffer) {
    for (final child in children) {
      if (child is XmlText) buffer.write(child.value);
      if (child is XmlCData) buffer.write(child.value);
      if (child is XmlElement) child._collectText(buffer);
    }
  }

  // ---- Namespaces ----

  /// Resolve um prefixo para o namespace URI, subindo pelos `xmlns:`.
  /// Prefixo `null`/vazio resolve o namespace default (`xmlns`).
  String? resolvePrefix(String? prefix) {
    final attrName =
        (prefix == null || prefix.isEmpty) ? 'xmlns' : 'xmlns:$prefix';
    XmlElement? node = this;
    while (node != null) {
      final value = node.getAttribute(attrName);
      if (value != null) return value;
      node = node.parent;
    }
    return null;
  }

  /// Namespace URI deste elemento (resolvendo o próprio prefixo).
  String? get namespaceUri => resolvePrefix(prefix);

  @override
  void writeTo(StringBuffer buffer) {
    buffer
      ..write('<')
      ..write(qname);
    for (final attr in attributes) {
      buffer
        ..write(' ')
        ..write(attr.qname)
        ..write('="')
        ..write(XmlEscape.attribute(attr.value))
        ..write('"');
    }
    if (children.isEmpty) {
      buffer.write('/>');
      return;
    }
    buffer.write('>');
    for (final child in children) {
      child.writeTo(buffer);
    }
    buffer
      ..write('</')
      ..write(qname)
      ..write('>');
  }

  @override
  XmlElement copy() => XmlElement(
      qname,
      attributes.map((a) => a.copy()).toList(),
      children.map((c) => c.copy()).toList());
}

/// Declaração `<?xml ...?>`.
class XmlDeclaration {
  String? version;
  String? encoding;
  String? standalone;

  XmlDeclaration({this.version, this.encoding, this.standalone});

  void writeTo(StringBuffer buffer) {
    buffer.write('<?xml');
    if (version != null) buffer.write(' version="$version"');
    if (encoding != null) buffer.write(' encoding="$encoding"');
    if (standalone != null) buffer.write(' standalone="$standalone"');
    buffer.write('?>');
  }
}

/// Documento XML completo (declaração + misc + elemento raiz).
class XmlDocument {
  XmlDeclaration? declaration;
  final List<XmlNode> children;

  XmlDocument({this.declaration, List<XmlNode>? children})
      : children = children ?? <XmlNode>[];

  XmlElement get rootElement => children.whereType<XmlElement>().first;

  static XmlDocument parse(String source) {
    final builder = _DomBuilder();
    XmlSaxParser.parseString(source, builder);
    return builder.document;
  }

  static XmlDocument parseBytes(Uint8List bytes) {
    final builder = _DomBuilder();
    XmlSaxParser.parseBytes(bytes, builder);
    return builder.document;
  }

  String toXmlString() {
    final buffer = StringBuffer();
    final decl = declaration;
    if (decl != null) {
      decl.writeTo(buffer);
      // O Word emite a declaração seguida de CRLF antes do raiz.
      buffer.write('\r\n');
    }
    for (final child in children) {
      child.writeTo(buffer);
    }
    return buffer.toString();
  }

  Uint8List toUtf8Bytes() => utf8.encode(toXmlString());
}

class _DomBuilder extends XmlSaxHandler {
  final XmlDocument document = XmlDocument();
  final List<XmlElement> _stack = [];

  @override
  void xmlDeclaration(String? version, String? encoding, String? standalone) {
    document.declaration = XmlDeclaration(
        version: version, encoding: encoding, standalone: standalone);
  }

  @override
  void startElement(
      String qname, List<XmlSaxAttribute> attributes, bool selfClosing) {
    final element = XmlElement(
        qname,
        attributes.isEmpty
            ? null
            : attributes.map((a) => XmlAttribute(a.qname, a.value)).toList());
    if (_stack.isEmpty) {
      document.children.add(element);
    } else {
      _stack.last.add(element);
    }
    _stack.add(element);
  }

  @override
  void endElement(String qname) {
    _stack.removeLast();
  }

  @override
  void characters(String text) {
    if (_stack.isEmpty) return;
    _stack.last.add(XmlText(text));
  }

  @override
  void cdata(String text) {
    if (_stack.isEmpty) return;
    _stack.last.add(XmlCData(text));
  }

  @override
  void comment(String text) {
    final node = XmlComment(text);
    if (_stack.isEmpty) {
      document.children.add(node);
    } else {
      _stack.last.add(node);
    }
  }

  @override
  void processingInstruction(String target, String? data) {
    final node = XmlProcessingInstruction(target, data);
    if (_stack.isEmpty) {
      document.children.add(node);
    } else {
      _stack.last.add(node);
    }
  }
}
