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
import '../../office/document/docx/styles.dart';
import 'numbering.dart';
import '../../office/document/docx/writer.dart';
import '../../office/document/zip/zip_archive.dart';
import '../layout/page_graph.dart';
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

  /// Folha de estilos do documento sendo importado, para a cascata.
  WpStyleSheet? _styles;

  /// Contador de numeração. É STATEFUL e percorre o corpo na ordem: o
  /// rótulo de um parágrafo depende de tudo que veio antes dele.
  OfficeNumberingCounter? _counter;

  /// Quebras de seção encontradas nos parágrafos, na ordem do documento.
  final List<WpSectionProperties> _sectionBreaks = [];

  /// Importa o pacote inteiro, preservando o que não sabemos ler.
  OfficeDocxImport import(Uint8List bytes, {String documentId = 'docx'}) {
    final docx = DocxReader.read(bytes);
    _styles = docx.styles;
    _counter = OfficeNumberingCounter(docx.numbering);
    _sectionBreaks.clear();
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
      // O ID é atribuído AQUI, não depois: é ele que liga o nó à sua origem
      // no XML. Sem id, nenhuma âncora casa no save e o writer regenera o
      // documento inteiro — anulando justamente a preservação.
      final nodeId = 'b$ordinal';
      final node = _blockToNode(block, report, nodeId);
      if (node == null) {
        ordinal++;
        continue;
      }
      anchors.add(OfficeSourceAnchor(
        partUri: docx.mainPartName,
        nodeId: nodeId,
        ordinal: ordinal,
        rawHash: nodeSignature(node),
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
        headers: _regionsOf(docx.headersByType, report),
        footers: _regionsOf(docx.footersByType, report),
        sourceMap: {
          'mainPart': docx.mainPartName,
          'nodes': [for (final a in anchors) a.toJson()],
        },
        interop: {'sourceFormat': 'docx'},
        resources: OfficeResourcesSnapshot(
          opaqueParts: parts,
          assets: assets,
          // TODAS as seções, na ordem: as quebras encontradas nos
          // parágrafos e, por último, a do fim do body — que governa a
          // seção final.
          sections: [
            for (final section in _sectionBreaks) _sectionToJson(section),
            if (docx.document.section != null)
              _sectionToJson(docx.document.section!),
          ],
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

  /// Exporta o `.docx` refletindo as EDIÇÕES da árvore.
  ///
  /// A estratégia é a que preserva: um bloco cuja assinatura não mudou volta
  /// com o XML ORIGINAL, byte a byte — inclusive as propriedades que o nosso
  /// modelo nem representa (bookmarks, proofing, campos, atributos de
  /// fabricante). Só o que o usuário realmente tocou é regenerado.
  ///
  /// Sem isso, salvar um documento de 500 parágrafos depois de corrigir uma
  /// vírgula reescreveria os 500 e destruiria tudo que não modelamos.
  Uint8List exportEdited(OfficeDocumentSnapshot snapshot, PMNode doc) {
    // O pacote reconstruído é a base: todas as outras partes vêm dele
    // intocadas. Reabrir é o que devolve os blocos com o XML de origem.
    final docx = DocxReader.read(export(snapshot));
    final anchors = _anchorsOf(snapshot);
    final original = docx.document.body;

    // Reconstrução por ORDINAL. Anexar os blocos opacos no fim seria
    // catastrófico e silencioso: as tabelas migrariam para o final do
    // documento. Eles têm de voltar ENTRE os parágrafos, onde estavam.
    final claimed = {for (final a in anchors.values) a.ordinal};
    final blocks = <WpBlock>[];
    var nextOriginal = 0;

    void emitOpaqueUpTo(int limit) {
      while (nextOriginal < limit) {
        if (!claimed.contains(nextOriginal)) {
          blocks.add(original[nextOriginal]);
        }
        nextOriginal++;
      }
    }

    for (var i = 0; i < doc.childCount; i++) {
      final node = doc.child(i);
      final nodeId = officeNodeId(node);
      final anchor = nodeId == null ? null : anchors[nodeId];

      if (anchor == null || anchor.ordinal >= original.length) {
        // Nó NOVO: entra exatamente onde a árvore o colocou.
        blocks.add(_nodeToParagraph(node));
        continue;
      }

      emitOpaqueUpTo(anchor.ordinal);
      blocks.add(anchor.rawHash == nodeSignature(node)
          // Intocado: o XML original volta verbatim, com tudo que o nosso
          // modelo nem representa (bookmarks, proofing, campos, extensões).
          ? original[anchor.ordinal]
          // Editado: `sourceXml: null` faz o writer serializar do modelo.
          : _nodeToParagraph(node));
      nextOriginal = anchor.ordinal + 1;
    }

    // Cauda: o que sobrou de opaco depois do último nó ancorado. Um bloco
    // cujo ordinal ESTÁ em `claimed` mas cujo nó sumiu da árvore foi
    // apagado pelo usuário e não volta.
    emitOpaqueUpTo(original.length);

    return DocxWriter.write(DocxFile(
      package: docx.package,
      document: WpDocumentModel(body: blocks, section: docx.document.section),
      styles: docx.styles,
      numbering: docx.numbering,
      settings: docx.settings,
      mainPartName: docx.mainPartName,
      documentBodyPrefix: docx.documentBodyPrefix,
      documentBodySuffix: docx.documentBodySuffix,
      headersByType: docx.headersByType,
      footersByType: docx.footersByType,
      fidelityNotes: docx.fidelityNotes,
    ));
  }

  /// Cabeçalhos/rodapés viram RAÍZES próprias do snapshot, indexadas pela
  /// variante (`default`/`first`/`even`) — não são parte do corpo.
  ///
  /// Manter separado importa: eles repetem em todas as páginas, então
  /// misturá-los ao corpo faria uma posição do documento apontar para N
  /// lugares.
  Map<String, Map<String, dynamic>> _regionsOf(
      Map<String, WpHeaderFooter> byType, OfficeCompatibilityReport report) {
    final result = <String, Map<String, dynamic>>{};
    byType.forEach((variant, region) {
      final blocks = <PMNode>[];
      var ordinal = 0;
      for (final block in region.blocks) {
        final node = _blockToNode(block, report, '$variant-$ordinal');
        ordinal++;
        if (node != null) blocks.add(node);
      }
      if (blocks.isEmpty) return;
      result[variant] =
          schema.node('doc', null, Fragment.from(blocks)).toJSON()
              as Map<String, dynamic>;
    });
    return result;
  }

  /// A região `default` do snapshot como árvore, pronta para o composer.
  static PMNode? regionOf(
      Map<String, Map<String, dynamic>> regions, Schema schema) {
    final json = regions['default'] ?? regions.values.firstOrNull;
    return json == null ? null : PMNode.fromJSON(schema, json);
  }

  /// Geometria da seção, em TWIPS — as unidades canônicas do plano, sem
  /// passar por pixel em lugar nenhum.
  static Map<String, dynamic> _sectionToJson(WpSectionProperties section) => {
        'pageWidthTwips': section.pageWidthTwips,
        'pageHeightTwips': section.pageHeightTwips,
        'orientation': section.orientation,
        'marginTopTwips': section.marginTopTwips,
        'marginRightTwips': section.marginRightTwips,
        'marginBottomTwips': section.marginBottomTwips,
        'marginLeftTwips': section.marginLeftTwips,
        'titlePage': section.titlePage,
      };

  /// A configuração de página do documento IMPORTADO.
  ///
  /// Sem isto o editor pagina tudo em A4 retrato com margens padrão, e um
  /// documento em ofício ou paisagem quebraria nas linhas erradas — na tela
  /// E no PDF, porque os dois consomem o mesmo grafo. O default só entra
  /// quando o DOCX realmente não declara a medida.
  /// TODAS as geometrias do snapshot, na ordem das seções.
  static List<PageSetupTwips> pageSetupsOf(OfficeDocumentSnapshot snapshot) => [
        for (var i = 0; i < snapshot.resources.sections.length; i++)
          _setupAt(snapshot, i)
      ];

  static PageSetupTwips _setupAt(OfficeDocumentSnapshot snapshot, int index) {
    const fallback = PageSetupTwips();
    final section = snapshot.resources.sections[index];
    int value(String key, int byDefault) {
      final raw = section[key];
      return raw is num && raw > 0 ? raw.toInt() : byDefault;
    }

    return PageSetupTwips(
      widthTwips: value('pageWidthTwips', fallback.widthTwips),
      heightTwips: value('pageHeightTwips', fallback.heightTwips),
      marginTopTwips: value('marginTopTwips', fallback.marginTopTwips),
      marginRightTwips: value('marginRightTwips', fallback.marginRightTwips),
      marginBottomTwips: value('marginBottomTwips', fallback.marginBottomTwips),
      marginLeftTwips: value('marginLeftTwips', fallback.marginLeftTwips),
    );
  }

  static PageSetupTwips pageSetupOf(OfficeDocumentSnapshot snapshot) {
    const fallback = PageSetupTwips();
    if (snapshot.resources.sections.isEmpty) return fallback;
    final section = snapshot.resources.sections.first;
    int value(String key, int byDefault) {
      final raw = section[key];
      return raw is num && raw > 0 ? raw.toInt() : byDefault;
    }

    return PageSetupTwips(
      widthTwips: value('pageWidthTwips', fallback.widthTwips),
      heightTwips: value('pageHeightTwips', fallback.heightTwips),
      marginTopTwips: value('marginTopTwips', fallback.marginTopTwips),
      marginRightTwips: value('marginRightTwips', fallback.marginRightTwips),
      marginBottomTwips: value('marginBottomTwips', fallback.marginBottomTwips),
      marginLeftTwips: value('marginLeftTwips', fallback.marginLeftTwips),
    );
  }

  Map<String, OfficeSourceAnchor> _anchorsOf(OfficeDocumentSnapshot snapshot) {
    final raw = snapshot.sourceMap['nodes'];
    if (raw is! List) return const {};
    final result = <String, OfficeSourceAnchor>{};
    for (final entry in raw) {
      final anchor = OfficeSourceAnchor.fromJson(entry as Map<String, dynamic>);
      result[anchor.nodeId] = anchor;
    }
    return result;
  }

  /// Nó editado vira parágrafo Word SEM `sourceXml`, para o writer
  /// serializá-lo a partir do modelo.
  WpParagraph _nodeToParagraph(PMNode node) {
    final inlines = <WpInline>[];
    for (var i = 0; i < node.childCount; i++) {
      final child = node.child(i);
      final text = child.text;
      if (text == null || text.isEmpty) continue;
      final names = child.marks.map((m) => m.type.name).toSet();
      inlines.add(WpRun(
        properties: WpRunProperties(
          bold: names.contains('bold') ? true : null,
          italic: names.contains('italic') ? true : null,
          strike: names.contains('strike') ? true : null,
          underline: names.contains('underline') ? 'single' : null,
        ),
        content: [WpText(text)],
      ));
    }
    final level = node.attrs['level'];
    return WpParagraph(
      properties: WpParagraphProperties(
        styleId: node.type.name == 'heading' && level != null
            ? 'Heading$level'
            : null,
      ),
      inlines: inlines,
    );
  }

  // -- corpo -----------------------------------------------------------------

  /// Um bloco Word vira nó editável, ou `null` quando ainda não sabemos
  /// representá-lo — e nesse caso ele continua vivo nas partes opacas.
  PMNode? _blockToNode(
      WpBlock block, OfficeCompatibilityReport report, String nodeId) {
    switch (block) {
      case WpParagraph():
        return _paragraphToNode(block, nodeId);
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

  /// Resolve a apresentação do parágrafo pela cascata do Word.
  ///
  /// A ordem é normativa (ECMA-376): docDefaults, depois a cadeia
  /// `basedOn` do estilo — da RAIZ para a folha, senão o estilo base
  /// sobrescreveria o derivado —, depois a formatação DIRETA, que sempre
  /// ganha. Achatar isso num palpite por nome de estilo faria um "Título 1"
  /// de 14 pt sair com 24.
  ///
  /// O resultado é só APRESENTAÇÃO: a definição original continua intacta
  /// nas partes preservadas, então salvar não substitui o estilo pelo
  /// achatado.
  Map<String, dynamic>? _resolvePresentation(WpParagraph paragraph) {
    final styles = _styles;
    if (styles == null) return null;

    var size = styles.docDefaultsRun?.sizeHalfPoints;
    var bold = styles.docDefaultsRun?.bold;
    var family = styles.docDefaultsRun?.fontAscii;
    String? align = styles.docDefaultsParagraph?.jc;
    int? indent = styles.docDefaultsParagraph?.indent?.leftTwips;

    for (final style in _styleChain(paragraph.properties?.styleId, styles)) {
      size = style.runProperties?.sizeHalfPoints ?? size;
      bold = style.runProperties?.bold ?? bold;
      family = style.runProperties?.fontAscii ?? family;
      align = style.paragraphProperties?.jc ?? align;
      indent = style.paragraphProperties?.indent?.leftTwips ?? indent;
    }

    // Formatação direta do parágrafo e do primeiro run: ganha de tudo.
    final direct = paragraph.properties;
    align = direct?.jc ?? align;
    indent = direct?.indent?.leftTwips ?? indent;
    final firstRun = paragraph.inlines.whereType<WpRun>().firstOrNull;
    size = firstRun?.properties?.sizeHalfPoints ?? size;
    bold = firstRun?.properties?.bold ?? bold;
    family = firstRun?.properties?.fontAscii ?? family;

    if (size == null) return null;
    return {
      'sizePt': size / 2.0, // half-points são a unidade canônica do OOXML
      if (bold != null) 'bold': bold,
      if (family != null) 'family': family,
      if (align != null) 'align': _alignOf(align),
      if (indent != null) 'indentTwips': indent,
    };
  }

  /// A cadeia `basedOn`, da RAIZ para a folha.
  ///
  /// Percorrer na ordem errada faria o estilo base sobrescrever o derivado.
  /// O limite de profundidade não é zelo: `basedOn` cíclico existe em
  /// documentos reais e travaria a importação.
  static List<WpStyle> _styleChain(String? styleId, WpStyleSheet styles) {
    final chain = <WpStyle>[];
    final seen = <String>{};
    var current = styleId;
    while (current != null && seen.add(current) && chain.length < 16) {
      final style = styles.byId[current];
      if (style == null) break;
      chain.add(style);
      current = style.basedOn;
    }
    return chain.reversed.toList();
  }

  static String? _alignOf(String value) => switch (value) {
        'center' => 'center',
        'right' || 'end' => 'right',
        'both' || 'justify' => 'justify',
        'left' || 'start' => 'left',
        _ => null,
      };

  PMNode _paragraphToNode(WpParagraph paragraph, String nodeId) {
    final inline = <PMNode>[];
    for (final child in paragraph.inlines) {
      if (child is! WpRun) continue;
      final text = child.text;
      if (text.isEmpty) continue;
      inline.add(schema.text(text, _marksOf(child.properties)));
    }
    final level = _headingLevelOf(paragraph.properties?.styleId);
    final presentation = _resolvePresentation(paragraph);
    // O rótulo é PROJEÇÃO: vai para `style.marker`, não para o texto. Se
    // virasse texto, editar o parágrafo o corromperia e salvar gravaria o
    // número literal por cima da numeração automática do Word.
    final label = _counter?.labelFor(paragraph);
    // O `sectPr` do parágrafo ENCERRA a seção corrente. Registrar aqui,
    // durante a travessia, é o que mantém a ORDEM das seções — e a ordem é
    // o que liga cada geometria ao trecho certo do documento.
    final sectionBreak = paragraph.properties?.sectionBreak;
    if (sectionBreak != null) _sectionBreaks.add(sectionBreak);

    final resolved = <String, dynamic>{
      ...?presentation,
      if (label != null && label.isNotEmpty) 'marker': label,
      if (sectionBreak != null) 'sectionBreak': true,
    };
    if (level != null) {
      return schema.node(
          'heading',
          {
            officeIdAttribute: nodeId,
            'level': level,
            'style': resolved.isEmpty ? null : resolved
          },
          Fragment.from(inline));
    }
    return schema.node(
        'paragraph',
        {officeIdAttribute: nodeId, 'style': resolved.isEmpty ? null : resolved},
        Fragment.from(inline));
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

  /// Assinatura de um nó da árvore — a chave que decide entre reusar o XML
  /// original e regenerá-lo.
  ///
  /// É calculada SEMPRE a partir do nó, nunca do bloco Word, nos dois
  /// lados da comparação. Se cada ponta computasse a sua, a igualdade
  /// passaria a depender de dois mapeamentos concordarem, e a divergência
  /// apareceria como "o Word perdeu minha formatação" em vez de como bug.
  ///
  /// Inclui as MARCAS: aplicar negrito sem mudar o texto é uma edição, e
  /// uma assinatura só de texto a deixaria passar despercebida.
  static String nodeSignature(PMNode node) {
    final buffer = StringBuffer()
      ..write(node.type.name)
      ..write('|')
      ..write(node.attrs['level'] ?? '');
    for (var i = 0; i < node.childCount; i++) {
      final child = node.child(i);
      buffer
        ..write('|')
        ..write(child.marks.map((m) => m.type.name).join(','))
        ..write(':')
        ..write(child.text ?? '');
    }
    return sha256Hex(utf8.encode(buffer.toString()));
  }
}
