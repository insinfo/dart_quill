import '../../ce_xml.dart';

/// Namespace dos arquivos `.rels`.
const String relationshipsNamespace =
    'http://schemas.openxmlformats.org/package/2006/relationships';

/// Tipos de relacionamento usados pelo corpus DOCX (seção 2.2 do roteiro).
class RelType {
  RelType._();

  static const officeDocument =
      'http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument';
  static const styles =
      'http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles';
  static const numbering =
      'http://schemas.openxmlformats.org/officeDocument/2006/relationships/numbering';
  static const settings =
      'http://schemas.openxmlformats.org/officeDocument/2006/relationships/settings';
  static const webSettings =
      'http://schemas.openxmlformats.org/officeDocument/2006/relationships/webSettings';
  static const fontTable =
      'http://schemas.openxmlformats.org/officeDocument/2006/relationships/fontTable';
  static const theme =
      'http://schemas.openxmlformats.org/officeDocument/2006/relationships/theme';
  static const header =
      'http://schemas.openxmlformats.org/officeDocument/2006/relationships/header';
  static const footer =
      'http://schemas.openxmlformats.org/officeDocument/2006/relationships/footer';
  static const image =
      'http://schemas.openxmlformats.org/officeDocument/2006/relationships/image';
  static const hyperlink =
      'http://schemas.openxmlformats.org/officeDocument/2006/relationships/hyperlink';
  static const customXml =
      'http://schemas.openxmlformats.org/officeDocument/2006/relationships/customXml';
  static const coreProperties =
      'http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties';
  static const extendedProperties =
      'http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties';
}

/// Um relacionamento OPC (`<Relationship .../>`).
class Relationship {
  final String id;
  final String type;
  final String target;

  /// `TargetMode="External"` (hyperlinks externos etc.).
  final bool isExternal;

  const Relationship({
    required this.id,
    required this.type,
    required this.target,
    this.isExternal = false,
  });

  @override
  String toString() =>
      'Relationship($id, $type, $target${isExternal ? ', external' : ''})';
}

/// Coleção de relacionamentos de uma parte (arquivo `.rels`).
class Relationships {
  final List<Relationship> items;

  Relationships([List<Relationship>? items])
      : items = items ?? <Relationship>[];

  static Relationships parse(String xml) {
    final doc = XmlDocument.parse(xml);
    final result = Relationships();
    for (final child in doc.rootElement.childElements) {
      if (child.localName != 'Relationship') continue;
      final id = child.getAttribute('Id');
      final type = child.getAttribute('Type');
      final target = child.getAttribute('Target');
      if (id == null || type == null || target == null) continue;
      result.items.add(Relationship(
        id: id,
        type: type,
        target: target,
        isExternal: child.getAttribute('TargetMode') == 'External',
      ));
    }
    return result;
  }

  Relationship? byId(String id) {
    for (final rel in items) {
      if (rel.id == id) return rel;
    }
    return null;
  }

  Iterable<Relationship> ofType(String type) =>
      items.where((rel) => rel.type == type);

  /// Primeiro relacionamento do tipo dado, ou `null`.
  Relationship? firstOfType(String type) {
    for (final rel in items) {
      if (rel.type == type) return rel;
    }
    return null;
  }

  /// Gera um Id novo não conflitante (`rIdN`).
  String nextId() {
    var max = 0;
    for (final rel in items) {
      final match = RegExp(r'^rId(\d+)$').firstMatch(rel.id);
      if (match != null) {
        final n = int.parse(match.group(1)!);
        if (n > max) max = n;
      }
    }
    return 'rId${max + 1}';
  }

  void add(Relationship rel) => items.add(rel);

  String toXmlString() {
    final root = XmlElement(
        'Relationships', [XmlAttribute('xmlns', relationshipsNamespace)]);
    for (final rel in items) {
      final attrs = [
        XmlAttribute('Id', rel.id),
        XmlAttribute('Type', rel.type),
        XmlAttribute('Target', rel.target),
      ];
      if (rel.isExternal) attrs.add(XmlAttribute('TargetMode', 'External'));
      root.add(XmlElement('Relationship', attrs));
    }
    final doc = XmlDocument(
        declaration: XmlDeclaration(
            version: '1.0', encoding: 'UTF-8', standalone: 'yes'),
        children: [root]);
    return doc.toXmlString();
  }
}
