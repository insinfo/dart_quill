/// DOCX ↔ OfficeDocumentSnapshot — importação e exportação PRESERVADORAS.
///
/// O contrato da Fase 4 não é "abre o Word": é **não perder nada**. Um DOCX
/// tem dezenas de partes que o editor não entende — temas, custom XML,
/// assinaturas, extensões de fabricante — e o usuário nunca autorizou
/// descartá-las só porque abriu o arquivo.
///
/// Por isso o importador cataloga TODAS as entradas do pacote, não apenas as
/// que sabe interpretar:
///
/// * partes XML viram `office-part` em texto;
/// * partes binárias (imagens, fontes, OLE) viram `office-asset` em base64,
///   deduplicadas por SHA-256 — o mesmo logotipo repetido dez vezes ocupa
///   um lugar só;
/// * a árvore editável é DERIVADA do corpo, e cada nó guarda uma âncora
///   (`OfficeSourceAnchor`) para o bloco de origem.
///
/// Consequência que vale declarar: o snapshot é autocontido. Reconstruir o
/// `.docx` não precisa dos bytes originais — precisa só do JSON. É o que
/// permite guardar o documento no banco sem guardar o arquivo.
///
/// O que NÃO se promete: identidade byte a byte do ZIP. Compressão, ordem
/// de entradas e timestamps podem diferir. O gate é identidade do CONTEÚDO
/// de cada parte, que é o que preserva formatação e dados.
library;

import 'dart:convert';
import 'dart:typed_data';

import '../../office/document/docx/model.dart';
import '../../office/document/docx/reader.dart';
import '../../office/document/zip/zip_archive.dart';
import '../model/index.dart';
import 'ids.dart';
import 'quill_codec.dart' show OfficeCompatibilityReport;
import 'schema.dart';
import 'sha256.dart';
import 'snapshot.dart';

/// Vínculo persistente entre um nó editável e sua origem no OOXML.
///
/// É o que permite, no save, reescrever SÓ o que o usuário tocou e
/// reaproveitar o XML original do resto — inclusive de propriedades que o
/// modelo nem representa.
class OfficeSourceAnchor {
  const OfficeSourceAnchor({
    required this.partUri,
    required this.nodeId,
    required this.ordinal,
    required this.rawHash,
  });

  /// Parte OPC de origem (`word/document.xml`, um header, uma nota…).
  final String partUri;

  final String nodeId;

  /// Posição do bloco dentro da parte — o que reencontra a origem quando o
  /// XML é reprocessado.
  final int ordinal;

  /// Hash do XML original do bloco. Se ele mudar sem passar por nós, isso é
  /// erro de integridade, não uma versão a escolher em silêncio.
  final String rawHash;

  Map<String, dynamic> toJson() => {
        'partUri': partUri,
        'nodeId': nodeId,
        'ordinal': ordinal,
        'rawHash': rawHash,
      };

  static OfficeSourceAnchor fromJson(Map<String, dynamic> json) =>
      OfficeSourceAnchor(
        partUri: json['partUri'] as String,
        nodeId: json['nodeId'] as String,
        ordinal: (json['ordinal'] as num).toInt(),
        rawHash: json['rawHash'] as String,
      );
}

/// O resultado de importar um DOCX.
class OfficeDocxImport {
  const OfficeDocxImport({
    required this.snapshot,
    required this.report,
    required this.anchors,
  });

  final OfficeDocumentSnapshot snapshot;

  /// Tudo que não coube no modelo editável aparece aqui — nunca some.
  final OfficeCompatibilityReport report;

  final List<OfficeSourceAnchor> anchors;
}

/// Nomes de entrada que são XML de texto; o resto vira asset binário.
bool _isTextPart(String name) =>
    name.endsWith('.xml') || name.endsWith('.rels');

class OfficeDocxCodec {
  OfficeDocxCodec({Schema? schema}) : schema = schema ?? officeQuillSchema();

  final Schema schema;

  /// Importa o pacote inteiro, preservando o que não sabemos ler.
  OfficeDocxImport import(Uint8List bytes, {String documentId = 'docx'}) {
    final docx = DocxReader.read(bytes);
    final report = OfficeCompatibilityReport();
    final anchors = <OfficeSourceAnchor>[];

    // 1. Catálogo COMPLETO do pacote. Isto vem antes de qualquer
    //    interpretação: o que não for catalogado aqui está perdido.
    final parts = <Map<String, dynamic>>[];
    final assets = <Map<String, dynamic>>[];
    final assetsByHash = <String, int>{};

    for (final entry in docx.package.archive.entries) {
      final name = entry.name;
      if (_isTextPart(name)) {
        parts.add({
          'uri': name,
          'mode': 'opaqueRaw',
          'encoding': 'utf8',
          'data': utf8.decode(entry.content, allowMalformed: true),
        });
        continue;
      }
      final hash = sha256Hex(entry.content);
      if (!assetsByHash.containsKey(hash)) {
        assetsByHash[hash] = assets.length;
        assets.add({
          'id': 'sha256:$hash',
          'encoding': 'base64',
          'data': base64Encode(entry.content),
        });
      }
      parts.add({
        'uri': name,
        'mode': 'opaqueRaw',
        'encoding': 'assetRef',
        'assetId': 'sha256:$hash',
      });
    }

    // 2. Árvore editável derivada do corpo, com âncora por bloco.
    final blocks = <PMNode>[];
    var ordinal = 0;
    for (final block in docx.document.body) {
      final node = _blockToNode(block, report);
      if (node == null) {
        ordinal++;
        continue;
      }
      final nodeId = officeNodeId(node) ?? 'b$ordinal';
      anchors.add(OfficeSourceAnchor(
        partUri: docx.mainPartName,
        nodeId: nodeId,
        ordinal: ordinal,
        rawHash: sha256Hex(utf8.encode(_signatureOf(block))),
      ));
      blocks.add(node);
      ordinal++;
    }

    for (final note in docx.fidelityNotes) {
      report.add('docx-fidelity-note', note);
    }

    final doc = schema.node('doc', null, Fragment.from(blocks));
    return OfficeDocxImport(
      snapshot: OfficeDocumentSnapshot(
        documentId: documentId,
        body: doc.toJSON() as Map<String, dynamic>,
        sourceMap: {
          'mainPart': docx.mainPartName,
          'nodes': [for (final a in anchors) a.toJson()],
        },
        interop: {'sourceFormat': 'docx'},
        resources: OfficeResourcesSnapshot(
          opaqueParts: parts,
          assets: assets,
        ),
      ),
      report: report,
      anchors: anchors,
    );
  }

  /// Reconstrói o `.docx` a partir do snapshot — SEM os bytes originais.
  ///
  /// Partes não tocadas voltam exatamente como entraram. O ZIP em si pode
  /// diferir (compressão, ordem, timestamps); o que o gate exige é
  /// identidade do CONTEÚDO de cada parte.
  Uint8List export(OfficeDocumentSnapshot snapshot) {
    final archive = ZipArchive();
    final assets = <String, Uint8List>{
      for (final asset in snapshot.resources.assets)
        asset['id'] as String: base64Decode(asset['data'] as String),
    };

    for (final part in snapshot.resources.opaqueParts) {
      final uri = part['uri'] as String;
      final encoding = part['encoding'] as String?;
      if (encoding == 'assetRef') {
        final bytes = assets[part['assetId']];
        if (bytes == null) {
          throw StateError('asset ausente para a parte $uri');
        }
        archive.setFile(uri, bytes);
        continue;
      }
      archive.setFile(uri, utf8.encode(part['data'] as String));
    }
    return archive.encode();
  }

  // -- corpo -----------------------------------------------------------------

  /// Um bloco Word vira nó editável, ou `null` quando ainda não sabemos
  /// representá-lo — e nesse caso ele continua vivo nas partes opacas.
  PMNode? _blockToNode(WpBlock block, OfficeCompatibilityReport report) {
    switch (block) {
      case WpParagraph():
        return _paragraphToNode(block);
      case WpTable():
        report.add('docx-table-opaque',
            'tabela preservada na parte original; a edição semântica entra '
            'com o writer patch-based');
        return null;
      default:
        report.add('docx-block-opaque',
            'bloco ${block.runtimeType} preservado opaco');
        return null;
    }
  }

  PMNode _paragraphToNode(WpParagraph paragraph) {
    final inline = <PMNode>[];
    for (final child in paragraph.inlines) {
      if (child is! WpRun) continue;
      final text = child.text;
      if (text.isEmpty) continue;
      inline.add(schema.text(text, _marksOf(child.properties)));
    }
    final style = paragraph.properties?.styleId;
    final level = _headingLevelOf(style);
    if (level != null) {
      return schema.node(
          'heading', {'level': level}, Fragment.from(inline));
    }
    return schema.node('paragraph', null, Fragment.from(inline));
  }

  List<Mark> _marksOf(WpRunProperties? properties) {
    if (properties == null) return const [];
    final marks = <Mark>[];
    void add(String name, bool? on) {
      if (on != true) return;
      final type = schema.marks[name];
      if (type != null) marks.add(type.create());
    }

    add('bold', properties.bold);
    add('italic', properties.italic);
    add('strike', properties.strike);
    if (properties.underline != null && properties.underline != 'none') {
      final type = schema.marks['underline'];
      if (type != null) marks.add(type.create());
    }
    return marks;
  }

  /// `Heading1`, `Ttulo2`, `heading 3`… — o Word usa nomes variados por
  /// idioma, então o que identifica é o dígito no fim do styleId.
  static int? _headingLevelOf(String? styleId) {
    if (styleId == null) return null;
    final lower = styleId.toLowerCase();
    if (!lower.contains('heading') &&
        !lower.contains('titulo') &&
        !lower.contains('ttulo')) {
      return null;
    }
    final digits = RegExp(r'(\d+)').firstMatch(lower)?.group(1);
    final level = int.tryParse(digits ?? '');
    if (level == null || level < 1 || level > 6) return null;
    return level;
  }

  /// Assinatura estável do bloco de origem, para detectar divergência.
  static String _signatureOf(WpBlock block) => switch (block) {
        WpParagraph(:final properties, :final inlines) =>
          'p|${properties?.styleId}|${inlines.length}|'
              '${inlines.whereType<WpRun>().map((r) => r.text).join()}',
        WpTable(:final rows) => 'tbl|${rows.length}',
        _ => block.runtimeType.toString(),
      };
}
