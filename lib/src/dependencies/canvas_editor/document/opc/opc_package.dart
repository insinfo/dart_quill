import 'dart:convert';
import 'dart:typed_data';

import '../../ce_xml.dart';
import '../../ce_zip.dart';

import 'content_types.dart';
import 'relationships.dart';

/// Pacote OPC (Open Packaging Conventions) sobre [ZipArchive]
/// (roteiro_editor_profissional, Fase 1.3).
///
/// Nomes de parte são usados sem `/` inicial (iguais aos nomes de entrada
/// do ZIP), ex.: `word/document.xml`. A estratégia de preservação (D1) vem
/// do [ZipArchive]: partes não tocadas são re-emitidas byte a byte no save.
class OpcPackage {
  final ZipArchive archive;
  final ContentTypes contentTypes;

  final Map<String, Relationships> _relsCache = {};

  OpcPackage._(this.archive, this.contentTypes);

  factory OpcPackage.decode(Uint8List bytes) {
    final archive = ZipArchive.decodeBytes(bytes);
    final contentTypesXml = archive.readString('[Content_Types].xml');
    if (contentTypesXml == null) {
      throw const FormatException(
          'Pacote OPC inválido: [Content_Types].xml ausente.');
    }
    return OpcPackage._(archive, ContentTypes.parse(contentTypesXml));
  }

  /// Nomes de todas as partes do pacote (inclui `[Content_Types].xml`).
  List<String> get partNames => archive.entryNames;

  bool hasPart(String partName) => archive.contains(_normalize(partName));

  Uint8List? partBytes(String partName) =>
      archive.readBytes(_normalize(partName));

  String? partString(String partName) =>
      archive.readString(_normalize(partName));

  XmlDocument? partXml(String partName) {
    final xml = partString(partName);
    return xml == null ? null : XmlDocument.parse(xml);
  }

  /// Content type de uma parte, resolvido via `[Content_Types].xml`.
  String? contentTypeOf(String partName) =>
      contentTypes.typeOf(_normalize(partName));

  /// Substitui/cria o conteúdo de uma parte (marca como modificada no ZIP).
  void setPart(String partName, List<int> bytes) {
    final name = _normalize(partName);
    archive.setFile(name, bytes);
    if (name == '[Content_Types].xml' || _isRelsPart(name)) {
      _relsCache.remove(name);
    }
  }

  void setPartString(String partName, String content) =>
      setPart(partName, utf8.encode(content));

  bool removePart(String partName) {
    final name = _normalize(partName);
    _relsCache.remove(_relsPartNameFor(name));
    return archive.removeFile(name);
  }

  // ---- Relacionamentos ----

  /// Relacionamentos do pacote (raiz, `_rels/.rels`).
  Relationships get packageRelationships => relationshipsFor(null);

  /// Relacionamentos de uma parte ([partName] `null` = raiz do pacote).
  /// Retorna coleção vazia quando a parte não tem `.rels`.
  Relationships relationshipsFor(String? partName) {
    final relsName = partName == null
        ? '_rels/.rels'
        : _relsPartNameFor(_normalize(partName));
    final cached = _relsCache[relsName];
    if (cached != null) return cached;
    final xml = archive.readString(relsName);
    final rels = xml == null ? Relationships() : Relationships.parse(xml);
    _relsCache[relsName] = rels;
    return rels;
  }

  /// Grava de volta os relacionamentos de uma parte.
  void setRelationshipsFor(String? partName, Relationships rels) {
    final relsName = partName == null
        ? '_rels/.rels'
        : _relsPartNameFor(_normalize(partName));
    archive.setFile(relsName, utf8.encode(rels.toXmlString()));
    _relsCache[relsName] = rels;
  }

  /// Resolve o target (relativo à parte base) para um nome de parte.
  /// Targets externos devem ser tratados pelo chamador ([Relationship.isExternal]).
  String resolveTarget(String? basePartName, String target) {
    if (target.startsWith('/')) return target.substring(1);
    final baseDir = basePartName == null
        ? ''
        : _normalize(basePartName).replaceFirst(RegExp(r'[^/]+$'), '');
    final segments = <String>[...baseDir.split('/').where((s) => s.isNotEmpty)];
    for (final segment in target.split('/')) {
      if (segment == '..') {
        if (segments.isNotEmpty) segments.removeLast();
      } else if (segment != '.' && segment.isNotEmpty) {
        segments.add(segment);
      }
    }
    return segments.join('/');
  }

  /// Parte principal do documento (via rel `officeDocument` da raiz).
  String get mainDocumentPartName {
    final rel = packageRelationships.firstOfType(RelType.officeDocument);
    if (rel == null) {
      throw const FormatException(
          'Pacote OPC sem relacionamento officeDocument.');
    }
    return resolveTarget(null, rel.target);
  }

  /// Serializa o pacote; partes intocadas ficam byte a byte idênticas.
  Uint8List save() => archive.encode();

  static String _normalize(String partName) =>
      partName.startsWith('/') ? partName.substring(1) : partName;

  static bool _isRelsPart(String name) =>
      name == '_rels/.rels' || name.endsWith('.rels');

  static String _relsPartNameFor(String partName) {
    final slash = partName.lastIndexOf('/');
    final dir = slash < 0 ? '' : partName.substring(0, slash + 1);
    final base = slash < 0 ? partName : partName.substring(slash + 1);
    return '$dir' '_rels/$base.rels';
  }
}
