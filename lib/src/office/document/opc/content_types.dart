import '../../ce_xml.dart';

/// Namespace do `[Content_Types].xml`.
const String contentTypesNamespace =
    'http://schemas.openxmlformats.org/package/2006/content-types';

/// `[Content_Types].xml` do pacote OPC: defaults por extensão e overrides
/// por parte (ECMA-376 Part 2).
class ContentTypes {
  /// extensão (minúscula, sem ponto) → content type.
  final Map<String, String> defaults;

  /// nome de parte com `/` inicial → content type.
  final Map<String, String> overrides;

  ContentTypes({Map<String, String>? defaults, Map<String, String>? overrides})
      : defaults = defaults ?? <String, String>{},
        overrides = overrides ?? <String, String>{};

  static ContentTypes parse(String xml) {
    final doc = XmlDocument.parse(xml);
    final result = ContentTypes();
    for (final child in doc.rootElement.childElements) {
      switch (child.localName) {
        case 'Default':
          final extension = child.getAttribute('Extension');
          final type = child.getAttribute('ContentType');
          if (extension != null && type != null) {
            result.defaults[extension.toLowerCase()] = type;
          }
        case 'Override':
          final partName = child.getAttribute('PartName');
          final type = child.getAttribute('ContentType');
          if (partName != null && type != null) {
            result.overrides[partName] = type;
          }
      }
    }
    return result;
  }

  /// Content type de uma parte (com ou sem `/` inicial), ou `null`.
  String? typeOf(String partName) {
    final normalized = partName.startsWith('/') ? partName : '/$partName';
    final override = overrides[normalized];
    if (override != null) return override;
    final dot = normalized.lastIndexOf('.');
    if (dot < 0) return null;
    return defaults[normalized.substring(dot + 1).toLowerCase()];
  }

  void setOverride(String partName, String contentType) {
    final normalized = partName.startsWith('/') ? partName : '/$partName';
    overrides[normalized] = contentType;
  }

  void setDefault(String extension, String contentType) {
    defaults[extension.toLowerCase().replaceFirst('.', '')] = contentType;
  }

  String toXmlString() {
    final root =
        XmlElement('Types', [XmlAttribute('xmlns', contentTypesNamespace)]);
    for (final entry in defaults.entries) {
      root.add(XmlElement('Default', [
        XmlAttribute('Extension', entry.key),
        XmlAttribute('ContentType', entry.value),
      ]));
    }
    for (final entry in overrides.entries) {
      root.add(XmlElement('Override', [
        XmlAttribute('PartName', entry.key),
        XmlAttribute('ContentType', entry.value),
      ]));
    }
    final doc = XmlDocument(
        declaration: XmlDeclaration(
            version: '1.0', encoding: 'UTF-8', standalone: 'yes'),
        children: [root]);
    return doc.toXmlString();
  }
}
