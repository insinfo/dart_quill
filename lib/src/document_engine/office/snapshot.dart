/// OfficeDocumentSnapshot — o formato persistente CANÔNICO do modo avançado.
///
/// Um envelope Office versionado: várias raízes ProseMirror-like (body,
/// headers, footers, notas, comentários, caixas de texto) mais os recursos
/// que um DOCX carrega além da árvore visível (seções, styles, numbering,
/// tema, settings, relationships, assets por hash, partes opacas), o source
/// map para o round-trip preservador e a área de interop com o Delta.
///
/// Decisões que este arquivo trava (plano § Arquitetura consolidada):
/// * NÃO existe um Delta espelhando a árvore — Delta é codec de fronteira;
/// * assets NÃO viajam em base64 no snapshot: viajam por referência
///   (`sha256:<hex>`), com os bytes em armazenamento próprio;
/// * o hash canônico é calculado por [canonicalBytes] — JSON com chaves de
///   mapa ORDENADAS e sem whitespace — nunca pelos bytes de um `jsonb`.
library;

import 'dart:convert';
import 'dart:typed_data';

import '../model/index.dart';
import 'sha256.dart';

/// Erro de decodificação do envelope (formato/versão/estrutura).
class OfficeSnapshotFormatException implements Exception {
  OfficeSnapshotFormatException(this.message);

  final String message;

  @override
  String toString() => 'OfficeSnapshotFormatException: $message';
}

/// Recursos não-árvore do documento (espelha o pacote OOXML).
class OfficeResourcesSnapshot {
  OfficeResourcesSnapshot({
    List<Map<String, dynamic>>? sections,
    Map<String, dynamic>? styles,
    Map<String, dynamic>? numbering,
    Map<String, dynamic>? theme,
    Map<String, dynamic>? settings,
    List<Map<String, dynamic>>? relationships,
    List<Map<String, dynamic>>? assets,
    List<Map<String, dynamic>>? opaqueParts,
  })  : sections = sections ?? const [],
        styles = styles ?? const {},
        numbering = numbering ?? const {},
        theme = theme ?? const {},
        settings = settings ?? const {},
        relationships = relationships ?? const [],
        assets = assets ?? const [],
        opaqueParts = opaqueParts ?? const [];

  final List<Map<String, dynamic>> sections;
  final Map<String, dynamic> styles;
  final Map<String, dynamic> numbering;
  final Map<String, dynamic> theme;
  final Map<String, dynamic> settings;
  final List<Map<String, dynamic>> relationships;

  /// Referências de asset: `{"hash": "sha256:...", "mediaType": ..., "size": ...}`.
  /// Os BYTES moram fora do snapshot (tabela/objeto próprio, dedup por hash).
  final List<Map<String, dynamic>> assets;

  /// Partes OOXML não compreendidas, preservadas verbatim para o round-trip.
  final List<Map<String, dynamic>> opaqueParts;

  Map<String, dynamic> toJson() => {
        'sections': sections,
        'styles': styles,
        'numbering': numbering,
        'theme': theme,
        'settings': settings,
        'relationships': relationships,
        'assets': assets,
        'opaqueParts': opaqueParts,
      };

  static OfficeResourcesSnapshot fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> listOf(String key) =>
        ((json[key] as List?) ?? const [])
            .map((e) => (e as Map).cast<String, dynamic>())
            .toList();
    Map<String, dynamic> mapOf(String key) =>
        ((json[key] as Map?) ?? const {}).cast<String, dynamic>();
    return OfficeResourcesSnapshot(
      sections: listOf('sections'),
      styles: mapOf('styles'),
      numbering: mapOf('numbering'),
      theme: mapOf('theme'),
      settings: mapOf('settings'),
      relationships: listOf('relationships'),
      assets: listOf('assets'),
      opaqueParts: listOf('opaqueParts'),
    );
  }
}

/// O envelope versionado.
class OfficeDocumentSnapshot {
  OfficeDocumentSnapshot({
    required this.documentId,
    required this.body,
    this.schemaVersion = 1,
    this.revision = 0,
    Map<String, Map<String, dynamic>>? headers,
    Map<String, Map<String, dynamic>>? footers,
    Map<String, Map<String, dynamic>>? footnotes,
    Map<String, Map<String, dynamic>>? endnotes,
    Map<String, Map<String, dynamic>>? comments,
    Map<String, Map<String, dynamic>>? textBoxes,
    OfficeResourcesSnapshot? resources,
    Map<String, dynamic>? sourceMap,
    Map<String, dynamic>? interop,
  })  : headers = headers ?? const {},
        footers = footers ?? const {},
        footnotes = footnotes ?? const {},
        endnotes = endnotes ?? const {},
        comments = comments ?? const {},
        textBoxes = textBoxes ?? const {},
        resources = resources ?? OfficeResourcesSnapshot(),
        sourceMap = sourceMap ?? const {'nodes': <String, dynamic>{}},
        interop = interop ??
            const {
              'sourceFormat': null,
              'quillProfile': null,
              'opaqueQuillOperations': <dynamic>[],
            };

  static const String format = 'dart-office-document';
  static const int formatVersion = 1;

  final String documentId;
  final int schemaVersion;
  final int revision;

  /// JSON ProseMirror-like da raiz principal (`{"type": "doc", ...}`).
  final Map<String, dynamic> body;

  /// Raízes auxiliares por chave (ex.: `section-1:default`).
  final Map<String, Map<String, dynamic>> headers;
  final Map<String, Map<String, dynamic>> footers;
  final Map<String, Map<String, dynamic>> footnotes;
  final Map<String, Map<String, dynamic>> endnotes;
  final Map<String, Map<String, dynamic>> comments;
  final Map<String, Map<String, dynamic>> textBoxes;

  final OfficeResourcesSnapshot resources;

  /// `{"nodes": {nodeId: OfficeSourceAnchor}}` — o vínculo de cada nó com o
  /// XML de origem, para o writer patch-based da Fase 4.
  final Map<String, dynamic> sourceMap;

  /// Fronteira com o mundo Delta/Quill (perfil, ops opacas preservadas).
  final Map<String, dynamic> interop;

  /// Decodifica a raiz principal contra um [schema].
  PMNode decodeBody(Schema schema) => PMNode.fromJSON(schema, body);

  /// Snapshot a partir de um documento raiz + demais campos.
  static OfficeDocumentSnapshot fromDocument(
    PMNode doc, {
    required String documentId,
    int schemaVersion = 1,
    int revision = 0,
    OfficeResourcesSnapshot? resources,
    Map<String, dynamic>? sourceMap,
    Map<String, dynamic>? interop,
  }) =>
      OfficeDocumentSnapshot(
        documentId: documentId,
        body: (doc.toJSON() as Map).cast<String, dynamic>(),
        schemaVersion: schemaVersion,
        revision: revision,
        resources: resources,
        sourceMap: sourceMap,
        interop: interop,
      );

  Map<String, dynamic> toJson() => {
        'format': format,
        'formatVersion': formatVersion,
        'schemaVersion': schemaVersion,
        'revision': revision,
        'documentId': documentId,
        'roots': {
          'body': body,
          'headers': headers,
          'footers': footers,
          'footnotes': footnotes,
          'endnotes': endnotes,
          'comments': comments,
          'textBoxes': textBoxes,
        },
        'resources': resources.toJson(),
        'sourceMap': sourceMap,
        'interop': interop,
      };

  static OfficeDocumentSnapshot fromJson(Map<String, dynamic> json) {
    final actualFormat = json['format'];
    if (actualFormat != format) {
      throw OfficeSnapshotFormatException(
          'formato desconhecido: "$actualFormat" (esperado "$format")');
    }
    final version = json['formatVersion'];
    if (version is! int || version < 1 || version > formatVersion) {
      throw OfficeSnapshotFormatException(
          'formatVersion não suportada: $version (máx $formatVersion)');
    }
    final roots = json['roots'];
    if (roots is! Map) {
      throw OfficeSnapshotFormatException('envelope sem "roots"');
    }
    final body = roots['body'];
    if (body is! Map) {
      throw OfficeSnapshotFormatException('envelope sem "roots.body"');
    }
    Map<String, Map<String, dynamic>> rootsOf(String key) =>
        ((roots[key] as Map?) ?? const {}).map((k, v) =>
            MapEntry('$k', (v as Map).cast<String, dynamic>()));
    return OfficeDocumentSnapshot(
      documentId: '${json['documentId']}',
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 1,
      revision: (json['revision'] as num?)?.toInt() ?? 0,
      body: body.cast<String, dynamic>(),
      headers: rootsOf('headers'),
      footers: rootsOf('footers'),
      footnotes: rootsOf('footnotes'),
      endnotes: rootsOf('endnotes'),
      comments: rootsOf('comments'),
      textBoxes: rootsOf('textBoxes'),
      resources: OfficeResourcesSnapshot.fromJson(
          ((json['resources'] as Map?) ?? const {}).cast<String, dynamic>()),
      sourceMap:
          ((json['sourceMap'] as Map?) ?? const {}).cast<String, dynamic>(),
      interop: ((json['interop'] as Map?) ?? const {}).cast<String, dynamic>(),
    );
  }

  /// Serialização CANÔNICA: chaves de mapa ordenadas, sem whitespace, UTF-8.
  /// É sobre ESTES bytes que o hash de conteúdo é calculado — dois snapshots
  /// semanticamente iguais produzem os mesmos bytes, independentemente da
  /// ordem de inserção das chaves ou de quem serializou.
  Uint8List canonicalBytes() =>
      Uint8List.fromList(utf8.encode(_canonicalEncode(toJson())));

  /// SHA-256 hex dos [canonicalBytes] — o `content_hash` da revisão.
  String contentHash() => sha256Hex(canonicalBytes());

  static String _canonicalEncode(dynamic value) {
    if (value is Map) {
      final keys = value.keys.map((k) => '$k').toList()..sort();
      final parts = keys.map((k) =>
          '${json.encode(k)}:${_canonicalEncode(value[k])}');
      return '{${parts.join(',')}}';
    }
    if (value is List) {
      return '[${value.map(_canonicalEncode).join(',')}]';
    }
    return json.encode(value);
  }
}
