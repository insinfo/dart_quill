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

import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import '../../office/ce_opc.dart';
import '../../office/ce_xml.dart';
import '../../office/document/docx/model.dart';
import '../../office/document/docx/numbering.dart'
    show WpAbstractNum, WpNum, WpNumberingLevel;
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
import 'style_catalog.dart';
import 'sha256.dart';
import 'snapshot.dart';
import 'text_box_drawing.dart';

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

  /// Assinatura do nó PM importado. O modo que produziu a assinatura é
  /// versionado no sourceMap; isso permite comparar snapshots antigos sem
  /// reescrever silenciosamente o XML original.
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
    this.styleCatalog,
  });

  final OfficeDocumentSnapshot snapshot;

  /// Tudo que não coube no modelo editável aparece aqui — nunca some.
  final OfficeCompatibilityReport report;

  final List<OfficeSourceAnchor> anchors;

  /// Os estilos do documento como ENTIDADES (F8), para a galeria da ribbon.
  ///
  /// Vem por aqui e não pelo snapshot porque a UI importa com
  /// `includePackageResources: false`: sem as partes opacas o `styles.xml`
  /// não sobrevive ao envelope, e reabrir o pacote só para listar a galeria
  /// custaria outro unzip do documento inteiro.
  final OfficeStyleCatalog? styleCatalog;
}

/// Nomes de entrada que são XML de texto; o resto vira asset binário.
bool _isTextPart(String name) =>
    name.endsWith('.xml') || name.endsWith('.rels');

void _recordMaximum(
    Map<String, int>? timings, String name, int elapsedMicroseconds) {
  if (timings == null) return;
  final previous = timings[name] ?? 0;
  if (elapsedMicroseconds > previous) timings[name] = elapsedMicroseconds;
}

/// Relógio cooperativo usado apenas pelo caminho assíncrono de importação.
///
/// O trabalho OOXML continua determinístico e sequencial, mas uma tabela muito
/// grande não pode ocupar a thread do browser até a última linha. Consultar o
/// relógio é síncrono e barato; um [Future] só é criado quando a fatia realmente
/// estoura o orçamento.
class _CooperativeImportClock {
  _CooperativeImportClock([this._timings]) : _watch = Stopwatch()..start();

  static const _budget = Duration(milliseconds: 16);
  final Map<String, int>? _timings;
  final Stopwatch _watch;
  var _yields = 0;
  var _maxSliceUs = 0;

  bool get expired => _watch.elapsedMicroseconds >= _budget.inMicroseconds;

  Future<void> yieldNow() async {
    _watch.stop();
    _recordSlice();
    _yields++;
    await Future<void>.delayed(Duration.zero);
    _watch
      ..reset()
      ..start();
  }

  void finish() {
    _watch.stop();
    _recordSlice();
    final timings = _timings;
    if (timings == null) return;
    timings['cooperativeYields'] = _yields;
    timings['maxConversionSliceUs'] = _maxSliceUs;
  }

  void _recordSlice() {
    if (_watch.elapsedMicroseconds > _maxSliceUs) {
      _maxSliceUs = _watch.elapsedMicroseconds;
    }
  }
}

class _PackageResources {
  const _PackageResources(this.parts, this.assets);

  final List<Map<String, dynamic>> parts;
  final List<Map<String, dynamic>> assets;
}

class _DocxImageData {
  const _DocxImageData({
    required this.bytes,
    required this.mimeType,
    required this.digest,
    required this.extension,
  });

  final Uint8List bytes;
  final String mimeType;
  final String digest;

  /// Null means that the data URI is internally consistent but this codec
  /// does not know a Word-safe package extension for it. Such bytes may keep
  /// using an existing, matching relationship, but must never be relabelled
  /// as PNG while materializing a new media part.
  final String? extension;
}

class _FieldProjectionState {
  final instruction = StringBuffer();
  bool inResult = false;
  String? command;
}

const int _signatureMask32 = 0xffffffff;

/// Low 32 bits of a multiplication, without relying on a 64-bit product.
///
/// dart2js represents ordinary integers as JavaScript numbers. Multiplying
/// two arbitrary uint32 values directly can exceed JavaScript's exact 53-bit
/// integer range and silently change the low bits. Splitting the operands in
/// 16-bit limbs keeps every intermediate exact on both VM and web.
int _signatureMul32(int left, int right) {
  final leftLow = left & 0xffff;
  final leftHigh = (left >> 16) & 0xffff;
  final rightLow = right & 0xffff;
  final rightHigh = (right >> 16) & 0xffff;
  final low = leftLow * rightLow;
  final cross = ((leftHigh * rightLow + leftLow * rightHigh) & 0xffff) << 16;
  return (low + cross) & _signatureMask32;
}

/// A token stream summarized as two affine uint32 transformations.
///
/// The historical hashes update their states with `state * 31 + code` and
/// `state * 65600 + code`. Therefore a complete subtree can be appended to
/// an ancestor in O(1) while producing exactly the same final bits as
/// replaying every descendant code. This is the key to avoiding four full
/// walks of every cell block in a large Word table.
final class _SignatureSummary {
  const _SignatureSummary({
    required this.firstFactor,
    required this.firstAdd,
    required this.secondFactor,
    required this.secondAdd,
    required this.units,
  });

  final int firstFactor;
  final int firstAdd;
  final int secondFactor;
  final int secondAdd;
  final int units;

  String finish() {
    final first = (_signatureMul32(0x811c9dc5, firstFactor) + firstAdd) &
        _signatureMask32;
    final second = (_signatureMul32(0x9e3779b9, secondFactor) + secondAdd) &
        _signatureMask32;
    final a = first.toUnsigned(32).toRadixString(16).padLeft(8, '0');
    final b = second.toUnsigned(32).toRadixString(16).padLeft(8, '0');
    return '$a$b:$units';
  }
}

final class _SignatureSummaryBuilder {
  var _firstFactor = 1;
  var _firstAdd = 0;
  var _secondFactor = 1;
  var _secondAdd = 0;
  var _units = 0;

  void addCode(int code) {
    _firstFactor = ((_firstFactor << 5) - _firstFactor) & _signatureMask32;
    _firstAdd = ((_firstAdd << 5) - _firstAdd + code) & _signatureMask32;
    _secondFactor = (_secondFactor +
            (_secondFactor << 6) +
            (_secondFactor << 16) -
            _secondFactor) &
        _signatureMask32;
    _secondAdd = (_secondAdd +
            code +
            (_secondAdd << 6) +
            (_secondAdd << 16) -
            _secondAdd) &
        _signatureMask32;
    _units++;
  }

  void addString(String value) {
    addCode(value.length);
    for (final code in value.codeUnits) {
      addCode(code);
    }
    addCode(0x1f);
  }

  void addSummary(_SignatureSummary summary) {
    _firstAdd =
        (_signatureMul32(_firstAdd, summary.firstFactor) + summary.firstAdd) &
            _signatureMask32;
    _firstFactor = _signatureMul32(_firstFactor, summary.firstFactor);
    _secondAdd = (_signatureMul32(_secondAdd, summary.secondFactor) +
            summary.secondAdd) &
        _signatureMask32;
    _secondFactor = _signatureMul32(_secondFactor, summary.secondFactor);
    _units += summary.units;
  }

  _SignatureSummary finish() => _SignatureSummary(
        firstFactor: _firstFactor,
        firstAdd: _firstAdd,
        secondFactor: _secondFactor,
        secondAdd: _secondAdd,
        units: _units,
      );
}

sealed class _SignatureOperation {}

final class _SignatureCode extends _SignatureOperation {
  _SignatureCode(this.into, this.value);
  final _SignatureSummaryBuilder into;
  final int value;
}

final class _SignatureString extends _SignatureOperation {
  _SignatureString(this.into, this.value);
  final _SignatureSummaryBuilder into;
  final String value;
  int offset = -1;
}

final class _SignatureValue extends _SignatureOperation {
  _SignatureValue(this.into, this.value, this.ignoreSourceSignature);
  final _SignatureSummaryBuilder into;
  final dynamic value;
  final bool ignoreSourceSignature;
}

final class _SignatureNode extends _SignatureOperation {
  _SignatureNode(this.into, this.value, this.ignoreSourceSignature);
  final _SignatureSummaryBuilder into;
  final PMNode value;
  final bool ignoreSourceSignature;
}

final class _SignatureFinalizeNode extends _SignatureOperation {
  _SignatureFinalizeNode({
    required this.into,
    required this.nodeBuilder,
    required this.node,
    required this.ignoreSourceSignature,
  });

  final _SignatureSummaryBuilder into;
  final _SignatureSummaryBuilder nodeBuilder;
  final PMNode node;
  final bool ignoreSourceSignature;
}

/// Identity-scoped signature memoization for one import/export operation.
///
/// PM nodes are immutable, but keeping this cache on the codec indefinitely
/// would retain an entire opened document. Callers install a context only
/// for the duration of one operation and restore/clear it in `finally`.
final class _SignatureContext {
  final HashMap<PMNode, _SignatureSummary> _full =
      HashMap<PMNode, _SignatureSummary>.identity();
  final HashMap<PMNode, _SignatureSummary> _semantic =
      HashMap<PMNode, _SignatureSummary>.identity();
  final HashMap<Map<dynamic, dynamic>, List<String>> _sortedKeys =
      HashMap<Map<dynamic, dynamic>, List<String>>.identity();

  var cacheHits = 0;
  var summariesBuilt = 0;
  var semanticAliases = 0;

  static bool _ignoredKey(String key) =>
      key == 'sourceSignature' ||
      key == 'sourceBlockIndex' ||
      key == 'sourceCellIndex' ||
      key == 'sourceRowIndex';

  HashMap<PMNode, _SignatureSummary> _cache(bool semantic) =>
      semantic ? _semantic : _full;

  List<String> _keysOf(Map<dynamic, dynamic> values) => _sortedKeys.putIfAbsent(
        values,
        () => values.keys.map((key) => '$key').toList()..sort(),
      );

  String signatureSync(
    PMNode node, {
    required bool ignoreSourceSignature,
  }) =>
      summarySync(
        node,
        ignoreSourceSignature: ignoreSourceSignature,
      ).finish();

  _SignatureSummary summarySync(
    PMNode node, {
    required bool ignoreSourceSignature,
  }) {
    final cache = _cache(ignoreSourceSignature);
    final cached = cache[node];
    if (cached != null) {
      cacheHits++;
      return cached;
    }

    final builder = _SignatureSummaryBuilder()..addCode(0x11);
    builder.addString(node.type.name);
    _addValueSync(builder, node.attrs, ignoreSourceSignature);
    builder.addCode(node.marks.length);
    for (final mark in node.marks) {
      builder.addString(mark.type.name);
      _addValueSync(builder, mark.attrs, ignoreSourceSignature);
    }
    final text = node.text;
    if (text != null) builder.addString(text);
    builder.addCode(node.childCount);
    for (var i = 0; i < node.childCount; i++) {
      builder.addSummary(summarySync(
        node.child(i),
        ignoreSourceSignature: ignoreSourceSignature,
      ));
    }
    builder.addCode(0x12);
    final result = builder.finish();
    cache[node] = result;
    summariesBuilt++;
    return result;
  }

  void _addValueSync(
    _SignatureSummaryBuilder builder,
    dynamic value,
    bool ignoreSourceSignature,
  ) {
    switch (value) {
      case null:
        builder.addCode(0);
      case bool flag:
        builder.addCode(flag ? 2 : 1);
      case num number:
        builder
          ..addCode(3)
          ..addString(number.toString());
      case String text:
        builder
          ..addCode(4)
          ..addString(text);
      case List values:
        builder
          ..addCode(5)
          ..addCode(values.length);
        for (final item in values) {
          _addValueSync(builder, item, ignoreSourceSignature);
        }
      case Map values:
        builder.addCode(6);
        for (final key in _keysOf(values)) {
          if (ignoreSourceSignature && _ignoredKey(key)) continue;
          builder.addString(key);
          _addValueSync(builder, values[key], ignoreSourceSignature);
        }
        builder.addCode(0x1e);
      default:
        builder
          ..addCode(7)
          ..addString('$value');
    }
  }

  /// The final node differs from [provisional] only by preservation keys
  /// ignored by semantic signatures. Reusing this exact summary prevents a
  /// cell/row parent from walking the same descendants again.
  void aliasSemantic(PMNode node, PMNode provisional) {
    final summary = _semantic[provisional];
    if (summary == null) return;
    _semantic[node] = summary;
    semanticAliases++;
  }

  Future<String> signatureAsync(
    PMNode node, {
    required bool ignoreSourceSignature,
    required _CooperativeImportClock clock,
  }) async {
    final cache = _cache(ignoreSourceSignature);
    final cached = cache[node];
    if (cached != null) {
      cacheHits++;
      return cached.finish();
    }

    final root = _SignatureSummaryBuilder();
    final operations = <_SignatureOperation>[
      _SignatureNode(root, node, ignoreSourceSignature),
    ];
    while (operations.isNotEmpty) {
      if (clock.expired) await clock.yieldNow();
      final operation = operations.removeLast();
      switch (operation) {
        case _SignatureCode():
          operation.into.addCode(operation.value);
        case _SignatureString():
          if (operation.offset < 0) {
            operation.into.addCode(operation.value.length);
            operation.offset = 0;
          }
          var paused = false;
          while (operation.offset < operation.value.length) {
            final candidate = operation.offset + 1024;
            final end = candidate < operation.value.length
                ? candidate
                : operation.value.length;
            while (operation.offset < end) {
              operation.into
                  .addCode(operation.value.codeUnitAt(operation.offset++));
            }
            if (operation.offset < operation.value.length && clock.expired) {
              operations.add(operation);
              await clock.yieldNow();
              paused = true;
              break;
            }
          }
          if (!paused) operation.into.addCode(0x1f);
        case _SignatureValue():
          final into = operation.into;
          final value = operation.value;
          final semantic = operation.ignoreSourceSignature;
          switch (value) {
            case null:
              into.addCode(0);
            case bool flag:
              into.addCode(flag ? 2 : 1);
            case num number:
              into.addCode(3);
              operations.add(_SignatureString(into, number.toString()));
            case String text:
              into.addCode(4);
              operations.add(_SignatureString(into, text));
            case List values:
              into
                ..addCode(5)
                ..addCode(values.length);
              for (var i = values.length - 1; i >= 0; i--) {
                operations.add(_SignatureValue(into, values[i], semantic));
              }
            case Map values:
              into.addCode(6);
              final keys = _keysOf(values);
              operations.add(_SignatureCode(into, 0x1e));
              for (var i = keys.length - 1; i >= 0; i--) {
                final key = keys[i];
                if (semantic && _ignoredKey(key)) continue;
                operations
                  ..add(_SignatureValue(into, values[key], semantic))
                  ..add(_SignatureString(into, key));
              }
            default:
              into.addCode(7);
              operations.add(_SignatureString(into, '$value'));
          }
        case _SignatureNode():
          final nodeCache = _cache(operation.ignoreSourceSignature);
          final nodeSummary = nodeCache[operation.value];
          if (nodeSummary != null) {
            cacheHits++;
            operation.into.addSummary(nodeSummary);
            continue;
          }
          final value = operation.value;
          final semantic = operation.ignoreSourceSignature;
          final nodeBuilder = _SignatureSummaryBuilder()..addCode(0x11);
          operations.add(_SignatureFinalizeNode(
            into: operation.into,
            nodeBuilder: nodeBuilder,
            node: value,
            ignoreSourceSignature: semantic,
          ));
          operations.add(_SignatureCode(nodeBuilder, 0x12));
          for (var i = value.childCount - 1; i >= 0; i--) {
            operations
                .add(_SignatureNode(nodeBuilder, value.child(i), semantic));
          }
          operations.add(_SignatureCode(nodeBuilder, value.childCount));
          final text = value.text;
          if (text != null) {
            operations.add(_SignatureString(nodeBuilder, text));
          }
          for (var i = value.marks.length - 1; i >= 0; i--) {
            final mark = value.marks[i];
            operations
              ..add(_SignatureValue(nodeBuilder, mark.attrs, semantic))
              ..add(_SignatureString(nodeBuilder, mark.type.name));
          }
          operations.add(_SignatureCode(nodeBuilder, value.marks.length));
          operations
            ..add(_SignatureValue(nodeBuilder, value.attrs, semantic))
            ..add(_SignatureString(nodeBuilder, value.type.name));
        case _SignatureFinalizeNode():
          final summary = operation.nodeBuilder.finish();
          _cache(operation.ignoreSourceSignature)[operation.node] = summary;
          summariesBuilt++;
          operation.into.addSummary(summary);
      }
    }
    return root.finish().finish();
  }

  void recordTimings(Map<String, int>? timings) {
    if (timings == null) return;
    timings['signatureCacheHits'] = cacheHits;
    timings['signatureSummariesBuilt'] = summariesBuilt;
    timings['signatureSemanticAliases'] = semanticAliases;
  }
}

final class _NodeJsonFrame {
  _NodeJsonFrame(this.node, this.json);
  final PMNode node;
  final Map<String, dynamic> json;
  int nextChild = 0;
}

class OfficeDocxCodec {
  OfficeDocxCodec({Schema? schema}) : schema = schema ?? officeQuillSchema();

  final Schema schema;

  /// Folha de estilos do documento sendo importado, para a cascata.
  WpStyleSheet? _styles;

  /// Contador de numeração. É STATEFUL e percorre o corpo na ordem: o
  /// rótulo de um parágrafo depende de tudo que veio antes dele.
  OfficeNumberingCounter? _counter;

  /// DOCX currently being converted, needed to resolve image relationships
  /// from the main document and each header/footer part.
  DocxFile? _activeFile;

  /// Memoization scoped to the current import operation. It is installed
  /// after ZIP/XML reading and always restored in `finally`, so retaining a
  /// codec does not retain the PM tree that was imported.
  _SignatureContext? _signatureContext;

  _SignatureContext _beginSignatureOperation() {
    if (_signatureContext != null) {
      throw StateError(
        'OfficeDocxCodec is stateful and does not support overlapping '
        'import/export operations on the same instance.',
      );
    }
    final context = _SignatureContext();
    _signatureContext = context;
    return context;
  }

  void _endSignatureOperation(_SignatureContext context) {
    if (!identical(_signatureContext, context)) {
      throw StateError('DOCX signature operation context was replaced.');
    }
    _signatureContext = null;
  }

  /// Hints de paginação gravados pelo último layout do Word só são usados
  /// quando formam um conjunto completo (Pages - 1). Um conjunto parcial é
  /// cache obsoleto e não pode virar quebra manual.
  final Set<String> _validatedRenderedPageBreakNodeIds = <String>{};

  /// O `app.xml/Pages` confirma que o cache contém cobertura suficiente para
  /// a paginação salva. Tabelas podem registrar a mesma fronteira em mais de
  /// um fluxo de célula, portanto o total legal é MAIOR que `Pages - 1`.
  bool _validatedRenderedPageBreaks = false;

  /// Numbering instances created while exporting UI-authored lists. One
  /// instance per FORMAT (`numFmt|lvlText`) keeps adjacent items of the same
  /// gallery choice in one sequence, while "•" and "▪" — or "1." and "I." —
  /// still get separate definitions instead of overwriting each other.
  final Map<String, int> _generatedListNumIds = {};

  /// Quebras de seção encontradas nos parágrafos, na ordem do documento.
  final List<WpSectionProperties> _sectionBreaks = [];

  int _docPrId = 1;

  /// Importa o pacote inteiro, preservando o que não sabemos ler.
  ///
  /// A UI que retém os próprios bytes compactados pode definir
  /// [includePackageResources] como false: a árvore, regiões, seções e mapa
  /// de origem continuam completos, mas o mesmo pacote não é duplicado em
  /// milhares de objetos JSON. Snapshots destinados a persistência usam o
  /// default `true` e permanecem autocontidos.
  OfficeDocxImport import(
    Uint8List bytes, {
    String documentId = 'docx',
    bool includePackageResources = true,
    Map<String, int>? readerTimings,
  }) {
    final signatures = _beginSignatureOperation();
    try {
      final docx = DocxReader.read(
        bytes,
        captureSourceXml: includePackageResources,
        timings: readerTimings,
      );
      return _importFile(
        docx,
        documentId: documentId,
        includePackageResources: includePackageResources,
      );
    } finally {
      _endSignatureOperation(signatures);
    }
  }

  /// Importa em fatias cooperativas para não monopolizar a thread web.
  ///
  /// O leitor ZIP/XML ainda é uma fase síncrona, mas a conversão para a árvore
  /// PM devolve o event loop por orçamento temporal, inclusive dentro de
  /// tabelas e tabelas aninhadas. A API [import] continua disponível para
  /// VM/persistência e compartilha os mesmos construtores semânticos.
  Future<OfficeDocxImport> importAsync(
    Uint8List bytes, {
    String documentId = 'docx',
    bool includePackageResources = true,
    Map<String, int>? readerTimings,
    Map<String, int>? importTimings,
  }) async {
    final signatures = _beginSignatureOperation();
    try {
      final docx = await DocxReader.readAsync(
        bytes,
        captureSourceXml: includePackageResources,
        timings: readerTimings,
      );
      await Future<void>.delayed(Duration.zero);
      return await _importFileAsync(
        docx,
        documentId: documentId,
        includePackageResources: includePackageResources,
        importTimings: importTimings,
      );
    } finally {
      signatures.recordTimings(importTimings);
      _endSignatureOperation(signatures);
    }
  }

  OfficeDocxImport _importFile(
    DocxFile docx, {
    required String documentId,
    required bool includePackageResources,
  }) {
    _prepareImport(docx);
    final packageResources = _packageResourcesOf(
      docx,
      includePackageResources: includePackageResources,
    );
    final report = OfficeCompatibilityReport();
    final anchors = <OfficeSourceAnchor>[];
    final blocks = <PMNode>[];

    for (var ordinal = 0; ordinal < docx.document.body.length; ordinal++) {
      final block = docx.document.body[ordinal];
      // O ID é atribuído AQUI, não depois: é ele que liga o nó à sua
      // origem no XML. Sem id, nenhuma âncora casa no save e o writer
      // regenera o documento inteiro — anulando justamente a preservação.
      final nodeId = 'b$ordinal';
      final node =
          _blockToNode(block, report, nodeId, fromPart: docx.mainPartName);
      if (node == null) continue;
      anchors.add(OfficeSourceAnchor(
        partUri: docx.mainPartName,
        nodeId: nodeId,
        ordinal: ordinal,
        // Table source* keys are preservation metadata, not Word content.
        // Their semantic cache was already populated while building rows and
        // cells, so this avoids a second full traversal of a large table. Keep
        // non-table anchors full: opaque payloads may legitimately contain a
        // same-named key outside the reserved granular-table namespace.
        rawHash:
            block is WpTable ? _semanticSignature(node) : _nodeSignature(node),
      ));
      blocks.add(node);
    }

    _appendFidelityNotes(docx, report);
    final doc = schema.node('doc', null, Fragment.from(blocks));
    final headers = _regionsOf(docx.headersByType, report);
    final footers = _regionsOf(docx.footersByType, report);
    return _completeImport(
      docx,
      documentId: documentId,
      packageResources: packageResources,
      body: doc.toJSON() as Map<String, dynamic>,
      headers: headers,
      footers: footers,
      report: report,
      anchors: anchors,
    );
  }

  Future<OfficeDocxImport> _importFileAsync(
    DocxFile docx, {
    required String documentId,
    required bool includePackageResources,
    Map<String, int>? importTimings,
  }) async {
    _prepareImport(docx);
    final clock = _CooperativeImportClock(importTimings);
    final packageResources = includePackageResources
        ? await _packageResourcesOfAsync(docx, clock)
        : _PackageResources(<Map<String, dynamic>>[], <Map<String, dynamic>>[]);
    final report = OfficeCompatibilityReport();
    final anchors = <OfficeSourceAnchor>[];
    final blocks = <PMNode>[];

    for (var ordinal = 0; ordinal < docx.document.body.length; ordinal++) {
      if (clock.expired) await clock.yieldNow();
      final block = docx.document.body[ordinal];
      final nodeId = 'b$ordinal';
      final PMNode? node;
      if (block is WpTable) {
        node = await _tableToNodeAsync(
          block,
          report,
          nodeId,
          docx.mainPartName,
          clock,
        );
      } else {
        node = _blockToNode(block, report, nodeId, fromPart: docx.mainPartName);
      }
      if (node == null) continue;

      // A assinatura da tabela atravessa todos os seus descendentes. Depois
      // de uma tabela grande, ela ganha uma tarefa própria para não somar seu
      // custo à última fatia de conversão.
      if (block is WpTable && block.rows.length >= 64) {
        await clock.yieldNow();
      } else if (clock.expired) {
        await clock.yieldNow();
      }
      final signatureWatch =
          importTimings == null ? null : (Stopwatch()..start());
      final rawHash = block is WpTable
          ? block.rows.length >= 64
              ? await _nodeSignatureAsync(
                  node,
                  ignoreSourceSignature: true,
                  clock: clock,
                )
              : _semanticSignature(node)
          : _nodeSignature(node);
      if (signatureWatch != null) {
        signatureWatch.stop();
        _recordMaximum(
          importTimings,
          'maxTopSignatureUs',
          signatureWatch.elapsedMicroseconds,
        );
      }
      if (clock.expired) await clock.yieldNow();
      anchors.add(OfficeSourceAnchor(
        partUri: docx.mainPartName,
        nodeId: nodeId,
        ordinal: ordinal,
        rawHash: rawHash,
      ));
      blocks.add(node);
    }

    _appendFidelityNotes(docx, report);
    final doc = schema.node('doc', null, Fragment.from(blocks));
    final headers = await _regionsOfAsync(docx.headersByType, report, clock);
    final footers = await _regionsOfAsync(docx.footersByType, report, clock);

    // A serialização PM→JSON também percorre a árvore completa. Isolá-la
    // impede que ela seja anexada à última fatia de header/footer.
    await clock.yieldNow();
    final bodyWatch = importTimings == null ? null : (Stopwatch()..start());
    final body = await _nodeToJsonAsync(doc, clock);
    if (bodyWatch != null) {
      bodyWatch.stop();
      importTimings!['bodyJsonUs'] = bodyWatch.elapsedMicroseconds;
    }
    if (clock.expired) await clock.yieldNow();
    final result = _completeImport(
      docx,
      documentId: documentId,
      packageResources: packageResources,
      body: body,
      headers: headers,
      footers: footers,
      report: report,
      anchors: anchors,
    );
    clock.finish();
    return result;
  }

  void _prepareImport(DocxFile docx) {
    _activeFile = docx;
    _styles = docx.styles;
    _counter = OfficeNumberingCounter(docx.numbering);
    _sectionBreaks.clear();
    _configureRenderedPageBreakHints(docx);
  }

  /// `wp:docPr/@id` identifies drawing objects and Word expects it to be
  /// unique across the document stories. Regenerated paragraphs can coexist
  /// with untouched headers, footers, footnotes and body blocks, so starting
  /// at a magic number (or scanning only the edited paragraph) is unsafe.
  ///
  /// A textual scan is enough here and avoids building another DOM for every
  /// part. IDs allocated during this export are monotonically increasing.
  void _prepareDrawingExport(DocxFile docx) {
    var maximum = 0;
    final idPattern = RegExp(r'<wp:docPr\b[^>]*\bid="(\d+)"');
    for (final partName in docx.package.partNames) {
      if (!partName.startsWith('word/') || !partName.endsWith('.xml')) {
        continue;
      }
      final xml = docx.package.partString(partName);
      if (xml == null || !xml.contains('<wp:docPr')) continue;
      for (final match in idPattern.allMatches(xml)) {
        final value = int.tryParse(match.group(1)!);
        if (value != null && value > maximum) maximum = value;
      }
    }
    _docPrId = maximum + 1;
  }

  void _configureRenderedPageBreakHints(DocxFile docx) {
    _validatedRenderedPageBreakNodeIds.clear();
    _validatedRenderedPageBreaks = false;
    final documentXml = docx.package.partString(docx.mainPartName);
    final appXml = docx.package.partString('docProps/app.xml');
    if (documentXml == null || appXml == null) return;

    final XmlDocument document;
    final XmlDocument app;
    try {
      document = XmlDocument.parse(documentXml);
      app = XmlDocument.parse(appXml);
    } on XmlParseException {
      return;
    }
    final pageElement = app.rootElement.descendants
        .where((element) => element.localName == 'Pages')
        .firstOrNull;
    final storedPages = int.tryParse(pageElement?.text.trim() ?? '');
    if (storedPages == null || storedPages <= 1) return;

    final body = document.rootElement.descendantsNamed('w:body').firstOrNull;
    if (body == null) return;
    final markerCount = body.descendantsNamed('w:lastRenderedPageBreak').length;
    // Um marker por fronteira é o mínimo para um cache completo. Em tabelas,
    // a mesma página pode deixar um marker no fluxo de cada célula que a
    // atravessa; rejeitar `markerCount > Pages - 1` descartava justamente os
    // documentos complexos em que as pistas são mais valiosas.
    if (markerCount < storedPages - 1) return;
    _validatedRenderedPageBreaks = true;

    var ordinal = 0;
    for (final block in body.childElements) {
      if (block.qname == 'w:sectPr') continue;
      if (block.qname == 'w:p' && _startsWithRenderedPageBreak(block)) {
        _validatedRenderedPageBreakNodeIds.add('b$ordinal');
      }
      ordinal++;
    }
  }

  static bool _startsWithRenderedPageBreak(XmlElement paragraph) {
    var sawVisibleContent = false;
    bool visit(XmlElement element) {
      for (final child in element.childElements) {
        if (child.qname == 'w:lastRenderedPageBreak') {
          return !sawVisibleContent;
        }
        if ((child.qname == 'w:t' && child.text.isNotEmpty) ||
            child.qname == 'w:tab' ||
            child.qname == 'w:br' ||
            child.qname == 'w:cr' ||
            child.qname == 'w:drawing' ||
            child.qname == 'w:sym') {
          sawVisibleContent = true;
        }
        if (visit(child)) return true;
      }
      return false;
    }

    return visit(paragraph);
  }

  _PackageResources _packageResourcesOf(
    DocxFile docx, {
    required bool includePackageResources,
  }) {
    final parts = <Map<String, dynamic>>[];
    final assets = <Map<String, dynamic>>[];
    final assetsByHash = <String, int>{};
    if (includePackageResources) {
      for (final entry in docx.package.archive.entries) {
        _catalogEntry(entry, parts, assets, assetsByHash);
      }
    }
    return _PackageResources(parts, assets);
  }

  Future<_PackageResources> _packageResourcesOfAsync(
      DocxFile docx, _CooperativeImportClock clock) async {
    final parts = <Map<String, dynamic>>[];
    final assets = <Map<String, dynamic>>[];
    final assetsByHash = <String, int>{};
    for (final entry in docx.package.archive.entries) {
      if (clock.expired) await clock.yieldNow();
      _catalogEntry(entry, parts, assets, assetsByHash);
    }
    return _PackageResources(parts, assets);
  }

  static void _catalogEntry(
    ZipEntry entry,
    List<Map<String, dynamic>> parts,
    List<Map<String, dynamic>> assets,
    Map<String, int> assetsByHash,
  ) {
    final name = entry.name;
    final content = entry.content;
    if (_isTextPart(name)) {
      parts.add({
        'uri': name,
        'mode': 'opaqueRaw',
        'encoding': 'utf8',
        'data': utf8.decode(content, allowMalformed: true),
      });
      return;
    }
    final hash = sha256Hex(content);
    if (!assetsByHash.containsKey(hash)) {
      assetsByHash[hash] = assets.length;
      assets.add({
        'id': 'sha256:$hash',
        'encoding': 'base64',
        'data': base64Encode(content),
      });
    }
    parts.add({
      'uri': name,
      'mode': 'opaqueRaw',
      'encoding': 'assetRef',
      'assetId': 'sha256:$hash',
    });
  }

  static void _appendFidelityNotes(
      DocxFile docx, OfficeCompatibilityReport report) {
    for (final note in docx.fidelityNotes) {
      report.add('docx-fidelity-note', note);
    }
  }

  OfficeDocxImport _completeImport(
    DocxFile docx, {
    required String documentId,
    required _PackageResources packageResources,
    required Map<String, dynamic> body,
    required Map<String, Map<String, dynamic>> headers,
    required Map<String, Map<String, dynamic>> footers,
    required OfficeCompatibilityReport report,
    required List<OfficeSourceAnchor> anchors,
  }) {
    return OfficeDocxImport(
      snapshot: OfficeDocumentSnapshot(
        documentId: documentId,
        body: body,
        headers: headers,
        footers: footers,
        sourceMap: {
          'mainPart': docx.mainPartName,
          // Absent means the historical full-v1 hashes.  Keeping the mode in
          // the source map lets newer editors open persisted older snapshots
          // without falsely regenerating untouched vendor XML.
          'anchorHashMode': 'semantic-tables-v1',
          'nodes': [for (final a in anchors) a.toJson()],
        },
        interop: {'sourceFormat': 'docx'},
        resources: OfficeResourcesSnapshot(
          opaqueParts: packageResources.parts,
          assets: packageResources.assets,
          settings: {
            'evenAndOddHeaders': docx.settings.evenAndOddHeaders,
            'defaultTabStopTwips': docx.settings.defaultTabStopTwips,
          },
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
      styleCatalog: OfficeStyleCatalog.fromStyleSheet(docx.styles),
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
  Uint8List exportEdited(
    OfficeDocumentSnapshot snapshot,
    PMNode doc, {
    PageSetupTwips? pageSetup,
    OfficeStyleCatalog? styleCatalog,
  }) {
    // O pacote reconstruído é a base: todas as outras partes vêm dele
    // intocadas. Reabrir é o que devolve os blocos com o XML de origem.
    final signatures = _beginSignatureOperation();
    try {
      final docx = DocxReader.read(export(snapshot));
      return _exportEditedFile(
        docx,
        _anchorsOf(snapshot.sourceMap),
        doc,
        semanticTableAnchorHashes:
            _usesSemanticTableAnchorHashes(snapshot.sourceMap),
        pageSetup: pageSetup,
        styleCatalog: styleCatalog,
      );
    } finally {
      _endSignatureOperation(signatures);
    }
  }

  /// Fast path for an editor that still has the uploaded DOCX bytes.
  ///
  /// Keeping only the compressed package plus the tiny source map avoids
  /// retaining the snapshot's enormous body/resources JSON next to the live
  /// PM tree. It also skips package reconstruction and a second ZIP decode on
  /// Save. Persisted snapshots continue to use [exportEdited].
  Uint8List exportEditedFromDocx(
    Uint8List sourceBytes,
    Map<String, dynamic> sourceMap,
    PMNode doc, {
    PageSetupTwips? pageSetup,
    Map<String, PMNode> headers = const {},
    Map<String, PMNode> footers = const {},
    OfficeStyleCatalog? styleCatalog,
  }) {
    final signatures = _beginSignatureOperation();
    try {
      final docx = DocxReader.read(sourceBytes);
      _applyEditedRegions(docx, headers: headers, footers: footers);
      return _exportEditedFile(
        docx,
        _anchorsOf(sourceMap),
        doc,
        semanticTableAnchorHashes: _usesSemanticTableAnchorHashes(sourceMap),
        pageSetup: pageSetup,
        styleCatalog: styleCatalog,
      );
    } finally {
      _endSignatureOperation(signatures);
    }
  }

  /// Reescreve as PARTES `word/header*.xml`/`footer*.xml` das regiões
  /// editadas na sessão, mantendo as demais byte a byte.
  ///
  /// É o mesmo contrato do corpo, com uma diferença que importa: aqui não há
  /// âncoras por bloco. Uma região é pequena (um cabeçalho de ofício tem
  /// poucos parágrafos) e é editada por inteiro, então a parte é
  /// reserializada inteira — mas SÓ a parte que mudou, e apenas quando a
  /// sessão realmente entregou um documento para ela.
  ///
  /// O invólucro (`<w:hdr …>` com os namespaces do arquivo) é PRESERVADO:
  /// regerá-lo do zero perderia declarações de namespace que o pacote usa em
  /// outros lugares (`mc:Ignorable`, `w14`, `wp14`), e o Word rejeita o
  /// documento inteiro quando um prefixo usado não está declarado.
  void _applyEditedRegions(
    DocxFile docx, {
    required Map<String, PMNode> headers,
    required Map<String, PMNode> footers,
  }) {
    if (headers.isEmpty && footers.isEmpty) return;
    _activeFile = docx;
    _applyEditedRegionGroup(docx, docx.headersByType, headers, 'w:hdr');
    _applyEditedRegionGroup(docx, docx.footersByType, footers, 'w:ftr');
  }

  void _applyEditedRegionGroup(
    DocxFile docx,
    Map<String, WpHeaderFooter> parts,
    Map<String, PMNode> edited,
    String rootTag,
  ) {
    edited.forEach((type, doc) {
      final part = parts[type];
      // Uma variante que o pacote NÃO tem (o usuário ligou "primeira página
      // diferente" numa sessão) exigiria criar a parte, a relação e a
      // referência no sectPr. Isso é criação de estrutura, não edição, e
      // fica de fora até haver caminho completo — silenciosamente ignorar é
      // melhor que gravar um pacote inconsistente que o Word recusa.
      if (part == null) return;
      final original = docx.package.partString(part.partName);
      if (original == null) return;
      final open = original.indexOf('<$rootTag');
      final close = original.lastIndexOf('</$rootTag>');
      if (open < 0 || close < 0) return;
      final bodyStart = original.indexOf('>', open);
      if (bodyStart < 0 || bodyStart > close) return;

      final buffer = StringBuffer(original.substring(0, bodyStart + 1));
      for (final block in doc.children) {
        buffer.write(DocxWriter.serializeBlock(_nodeToBlock(block)));
      }
      buffer.write(original.substring(close));
      final xml = buffer.toString();
      if (xml != original) docx.package.setPartString(part.partName, xml);
    });
  }

  /// Fast path cooperativo para o botão Salvar/Exportar do browser.
  Future<Uint8List> exportEditedFromDocxAsync(
    Uint8List sourceBytes,
    Map<String, dynamic> sourceMap,
    PMNode doc, {
    PageSetupTwips? pageSetup,
    Map<String, PMNode> headers = const {},
    Map<String, PMNode> footers = const {},
    OfficeStyleCatalog? styleCatalog,
    Map<String, int>? timings,
  }) async {
    final signatures = _beginSignatureOperation();
    try {
      final readerTimings = <String, int>{};
      final readerWatch = Stopwatch()..start();
      final docx = await DocxReader.readAsync(
        sourceBytes,
        timings: readerTimings,
      );
      readerWatch.stop();
      timings?['readerUs'] = readerWatch.elapsedMicroseconds;
      if (timings != null) {
        for (final entry in readerTimings.entries) {
          timings['reader_${entry.key}'] = entry.value;
        }
      }
      await Future<void>.delayed(Duration.zero);
      _applyEditedRegions(docx, headers: headers, footers: footers);
      return await _exportEditedFileAsync(
        docx,
        _anchorsOf(sourceMap),
        doc,
        semanticTableAnchorHashes: _usesSemanticTableAnchorHashes(sourceMap),
        pageSetup: pageSetup,
        styleCatalog: styleCatalog,
        timings: timings,
      );
    } finally {
      signatures.recordTimings(timings);
      _endSignatureOperation(signatures);
    }
  }

  Uint8List _exportEditedFile(
    DocxFile docx,
    Map<String, OfficeSourceAnchor> anchors,
    PMNode doc, {
    required bool semanticTableAnchorHashes,
    PageSetupTwips? pageSetup,
    OfficeStyleCatalog? styleCatalog,
  }) {
    _activeFile = docx;
    _prepareDrawingExport(docx);
    _generatedListNumIds.clear();
    final original = docx.document.body;

    // Reconstrução por ORDINAL. Anexar os blocos opacos no fim seria
    // catastrófico e silencioso: as tabelas migrariam para o final do
    // documento. Eles têm de voltar ENTRE os parágrafos, onde estavam.
    final claimed = {for (final a in anchors.values) a.ordinal};
    final emittedOpaque = <int>{};
    final emittedAnchors = <int>{};
    final blocks = <WpBlock>[];
    var documentChanged = false;
    var lastAnchorOrdinal = -1;

    void emitOpaqueUpTo(int limit) {
      for (var ordinal = 0;
          ordinal < limit && ordinal < original.length;
          ordinal++) {
        if (!claimed.contains(ordinal) && emittedOpaque.add(ordinal)) {
          blocks.add(original[ordinal]);
        }
      }
    }

    for (var i = 0; i < doc.childCount; i++) {
      final node = doc.child(i);
      final nodeId = officeNodeId(node);
      final anchor = nodeId == null ? null : anchors[nodeId];

      if (anchor == null || anchor.ordinal >= original.length) {
        // Nó NOVO: entra exatamente onde a árvore o colocou.
        blocks.add(_nodeToBlock(node));
        documentChanged = true;
        continue;
      }

      emitOpaqueUpTo(anchor.ordinal);
      if (anchor.ordinal < lastAnchorOrdinal) documentChanged = true;
      lastAnchorOrdinal = anchor.ordinal;
      emittedAnchors.add(anchor.ordinal);
      final semanticTableAnchor =
          semanticTableAnchorHashes && original[anchor.ordinal] is WpTable;
      final unchanged = anchor.rawHash ==
          (semanticTableAnchor
              ? _semanticSignature(node)
              : _nodeSignature(node));
      if (!unchanged) documentChanged = true;
      blocks.add(unchanged
          // Intocado: o XML original volta verbatim, com tudo que o nosso
          // modelo nem representa (bookmarks, proofing, campos, extensões).
          ? original[anchor.ordinal]
          // Editado: `sourceXml: null` faz o writer serializar do modelo.
          : _nodeToBlock(node, base: original[anchor.ordinal]));
    }

    // Cauda: o que sobrou de opaco depois do último nó ancorado. Um bloco
    // cujo ordinal ESTÁ em `claimed` mas cujo nó sumiu da árvore foi
    // apagado pelo usuário e não volta.
    emitOpaqueUpTo(original.length);
    if (anchors.values.any((anchor) =>
        anchor.ordinal < original.length &&
        !emittedAnchors.contains(anchor.ordinal))) {
      documentChanged = true;
    }

    _applyStyleCatalog(docx, styleCatalog);
    return DocxWriter.write(
        _editedFile(
          docx,
          blocks,
          pageSetup: pageSetup,
        ),
        invalidateRenderedPageBreaks: documentChanged || pageSetup != null);
  }

  Future<Uint8List> _exportEditedFileAsync(
    DocxFile docx,
    Map<String, OfficeSourceAnchor> anchors,
    PMNode doc, {
    required bool semanticTableAnchorHashes,
    PageSetupTwips? pageSetup,
    OfficeStyleCatalog? styleCatalog,
    Map<String, int>? timings,
  }) async {
    _activeFile = docx;
    _prepareDrawingExport(docx);
    _generatedListNumIds.clear();
    final patchWatch = Stopwatch()..start();
    final clock = _CooperativeImportClock(timings);
    final original = docx.document.body;
    final claimed = {for (final anchor in anchors.values) anchor.ordinal};
    final emittedOpaque = <int>{};
    final emittedAnchors = <int>{};
    final blocks = <WpBlock>[];
    var documentChanged = false;
    var lastAnchorOrdinal = -1;

    void emitOpaqueUpTo(int limit) {
      for (var ordinal = 0;
          ordinal < limit && ordinal < original.length;
          ordinal++) {
        if (!claimed.contains(ordinal) && emittedOpaque.add(ordinal)) {
          blocks.add(original[ordinal]);
        }
      }
    }

    for (var i = 0; i < doc.childCount; i++) {
      if (clock.expired) await clock.yieldNow();
      final node = doc.child(i);
      final nodeId = officeNodeId(node);
      final anchor = nodeId == null ? null : anchors[nodeId];

      if (anchor == null || anchor.ordinal >= original.length) {
        blocks.add(node.type.name == 'table'
            ? await _nodeToTableAsync(node, clock: clock)
            : _nodeToBlock(node));
        documentChanged = true;
        continue;
      }

      emitOpaqueUpTo(anchor.ordinal);
      if (anchor.ordinal < lastAnchorOrdinal) documentChanged = true;
      lastAnchorOrdinal = anchor.ordinal;
      emittedAnchors.add(anchor.ordinal);
      final largeTable = node.type.name == 'table' && node.childCount >= 64;
      if (largeTable) await clock.yieldNow();
      final semanticTableAnchor =
          semanticTableAnchorHashes && original[anchor.ordinal] is WpTable;
      final signature = largeTable
          ? await _nodeSignatureAsync(
              node,
              ignoreSourceSignature: semanticTableAnchor,
              clock: clock,
            )
          : semanticTableAnchor
              ? _semanticSignature(node)
              : _nodeSignature(node);
      if (clock.expired) await clock.yieldNow();
      if (anchor.rawHash == signature) {
        blocks.add(original[anchor.ordinal]);
        continue;
      }
      documentChanged = true;

      final base = original[anchor.ordinal];
      blocks.add(node.type.name == 'table'
          ? await _nodeToTableAsync(
              node,
              base: base is WpTable ? base : null,
              clock: clock,
            )
          : _nodeToBlock(node, base: base));
    }

    emitOpaqueUpTo(original.length);
    if (anchors.values.any((anchor) =>
        anchor.ordinal < original.length &&
        !emittedAnchors.contains(anchor.ordinal))) {
      documentChanged = true;
    }
    patchWatch.stop();
    timings?['patchUs'] = patchWatch.elapsedMicroseconds;
    clock.finish();
    _applyStyleCatalog(docx, styleCatalog);
    await Future<void>.delayed(Duration.zero);
    return DocxWriter.writeAsync(
      _editedFile(docx, blocks, pageSetup: pageSetup),
      timings: timings,
      invalidateRenderedPageBreaks: documentChanged || pageSetup != null,
    );
  }

  /// Grava no pacote o `styles.xml` com os estilos criados/alterados.
  ///
  /// Só quando houve edição: sem isso, salvar um documento em que ninguém
  /// tocou nos estilos reescreveria a parte e quebraria o contrato de
  /// "partes intactas voltam byte a byte". O patch em si é textual e mora
  /// no catálogo — aqui só decidimos QUANDO aplicá-lo.
  static void _applyStyleCatalog(DocxFile docx, OfficeStyleCatalog? catalog) {
    if (catalog == null || !catalog.hasEdits) return;
    const part = 'word/styles.xml';
    final original = docx.package.partString(part);
    if (original == null) return;
    final patched = catalog.patchStylesXml(original);
    if (patched != original) docx.package.setPartString(part, patched);
  }

  DocxFile _editedFile(
    DocxFile docx,
    List<WpBlock> blocks, {
    PageSetupTwips? pageSetup,
  }) {
    return DocxFile(
      package: docx.package,
      document: WpDocumentModel(
        body: blocks,
        section: _sectionWithPageSetup(
          docx.document.section,
          pageSetup,
          preserveExistingAncillary: true,
        ),
      ),
      styles: docx.styles,
      numbering: docx.numbering,
      settings: docx.settings,
      mainPartName: docx.mainPartName,
      documentBodyPrefix: docx.documentBodyPrefix,
      documentBodySuffix: docx.documentBodySuffix,
      headersByType: docx.headersByType,
      footersByType: docx.footersByType,
      fidelityNotes: docx.fidelityNotes,
    );
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
        final node = _blockToNode(block, report, '$variant-$ordinal',
            fromPart: region.partName);
        ordinal++;
        if (node != null) blocks.add(node);
      }
      if (blocks.isEmpty) return;
      result[variant] = schema.node('doc', null, Fragment.from(blocks)).toJSON()
          as Map<String, dynamic>;
    });
    return result;
  }

  Future<Map<String, Map<String, dynamic>>> _regionsOfAsync(
    Map<String, WpHeaderFooter> byType,
    OfficeCompatibilityReport report,
    _CooperativeImportClock clock,
  ) async {
    final result = <String, Map<String, dynamic>>{};
    for (final entry in byType.entries) {
      final variant = entry.key;
      final region = entry.value;
      final blocks = <PMNode>[];
      for (var ordinal = 0; ordinal < region.blocks.length; ordinal++) {
        if (clock.expired) await clock.yieldNow();
        final sourceBlock = region.blocks[ordinal];
        final nodeId = '$variant-$ordinal';
        final PMNode? node;
        if (sourceBlock is WpTable) {
          node = await _tableToNodeAsync(
            sourceBlock,
            report,
            nodeId,
            region.partName,
            clock,
          );
        } else {
          node = _blockToNode(
            sourceBlock,
            report,
            nodeId,
            fromPart: region.partName,
          );
        }
        if (node != null) blocks.add(node);
      }
      if (blocks.isEmpty) continue;
      if (clock.expired) await clock.yieldNow();
      result[variant] = schema.node('doc', null, Fragment.from(blocks)).toJSON()
          as Map<String, dynamic>;
      if (clock.expired) await clock.yieldNow();
    }
    return result;
  }

  /// A região `default` do snapshot como árvore, pronta para o composer.
  static PMNode? regionOf(
      Map<String, Map<String, dynamic>> regions, Schema schema) {
    final json = regions['default'] ?? regions.values.firstOrNull;
    return json == null ? null : PMNode.fromJSON(schema, json);
  }

  /// Todas as variantes OOXML de uma região como árvores independentes.
  ///
  /// Não selecionar `values.first` aqui é importante: uma parte `first`
  /// existe no pacote mesmo quando `w:titlePg` está desligado, e nesse caso
  /// ela deve permanecer preservada sem ser projetada na página 1.
  static Map<String, PMNode> regionVariantsOf(
    Map<String, Map<String, dynamic>> regions,
    Schema schema,
  ) =>
      {
        for (final entry in regions.entries)
          entry.key: PMNode.fromJSON(schema, entry.value),
      };

  /// `w:titlePg` da primeira seção, que ativa a variante `first`.
  static bool titlePageOf(OfficeDocumentSnapshot snapshot) =>
      snapshot.resources.sections.firstOrNull?['titlePage'] == true;

  /// `w:settings/w:evenAndOddHeaders`, que ativa a variante `even`.
  static bool evenAndOddHeadersOf(OfficeDocumentSnapshot snapshot) =>
      snapshot.resources.settings['evenAndOddHeaders'] == true;

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
        'headerDistanceTwips': section.headerDistanceTwips,
        'footerDistanceTwips': section.footerDistanceTwips,
        'documentGridType': section.documentGridType,
        'documentGridLinePitchTwips': section.documentGridLinePitchTwips,
        'columnCount': section.columnCount,
        'columnSpacingTwips': section.columnSpacingTwips,
        'titlePage': section.titlePage,
      };

  /// Substitui somente a geometria editável da seção final.
  ///
  /// Os objetos repetidos e as opções sem UI própria continuam pertencendo
  /// ao DOCX de origem. `sourceXml: null` força o writer a regenerar apenas
  /// este `sectPr`; quebras de seção intermediárias permanecem intactas nos
  /// parágrafos preservados.
  static WpSectionProperties? _sectionWithPageSetup(
    WpSectionProperties? source,
    PageSetupTwips? setup, {
    required bool preserveExistingAncillary,
  }) {
    if (setup == null) return source;
    final base = source ?? const WpSectionProperties();
    return WpSectionProperties(
      pageWidthTwips: setup.widthTwips,
      pageHeightTwips: setup.heightTwips,
      orientation:
          setup.widthTwips > setup.heightTwips ? 'landscape' : 'portrait',
      marginTopTwips: setup.marginTopTwips,
      marginRightTwips: setup.marginRightTwips,
      marginBottomTwips: setup.marginBottomTwips,
      marginLeftTwips: setup.marginLeftTwips,
      headerDistanceTwips: preserveExistingAncillary
          ? base.headerDistanceTwips
          : setup.headerDistanceTwips,
      footerDistanceTwips: preserveExistingAncillary
          ? base.footerDistanceTwips
          : setup.footerDistanceTwips,
      gutterTwips: base.gutterTwips,
      documentGridType: preserveExistingAncillary
          ? base.documentGridType
          : setup.documentGridType,
      documentGridLinePitchTwips: preserveExistingAncillary
          ? base.documentGridLinePitchTwips
          : setup.documentGridLinePitchTwips,
      // Colunas só chegam ao arquivo quando MUDARAM.
      //
      // Gravar sempre o valor do editor parece mais simples e é errado: um
      // chamador que monta a geometria para trocar margens (e não declara
      // colunas) achataria um `w:cols w:num="2"` importado para uma coluna
      // só. É a mesma corrupção silenciosa do B3, e null aqui significa
      // "não mexi", o que faz o writer deixar o `w:cols` de origem intacto —
      // inclusive `w:equalWidth` e os `w:col` que o editor não modela.
      columnCount: setup.columnCount == null ||
              setup.columnCount == (base.columnCount ?? 1)
          ? null
          : setup.columnCount,
      columnSpacingTwips: setup.columnCount == null ||
              setup.columnCount == (base.columnCount ?? 1)
          ? null
          : setup.columnSpacingTwips,
      titlePage: base.titlePage,
      headerReferences: base.headerReferences,
      footerReferences: base.footerReferences,
      geometryOverridden: true,
      // The writer overlays pgSz and the selected pgMar geometry on this
      // element, retaining every ancillary child/attribute in its original
      // order (notably w:cols in the production corpus).
      sourceXml: base.sourceXml,
    );
  }

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
      headerDistanceTwips:
          value('headerDistanceTwips', fallback.headerDistanceTwips),
      footerDistanceTwips:
          value('footerDistanceTwips', fallback.footerDistanceTwips),
      documentGridLinePitchTwips:
          section['documentGridLinePitchTwips'] is num &&
                  (section['documentGridLinePitchTwips'] as num) > 0
              ? (section['documentGridLinePitchTwips'] as num).toInt()
              : null,
      documentGridType: section['documentGridType'] as String?,
      // `w:cols` ausente fica NULL, não 1: é o que permite reexportar sem
      // carimbar um `w:num` que o arquivo não tinha.
      columnCount:
          section['columnCount'] is num && (section['columnCount'] as num) > 0
              ? (section['columnCount'] as num).toInt()
              : null,
      columnSpacingTwips: value('columnSpacingTwips', 720),
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
      headerDistanceTwips:
          value('headerDistanceTwips', fallback.headerDistanceTwips),
      footerDistanceTwips:
          value('footerDistanceTwips', fallback.footerDistanceTwips),
      documentGridLinePitchTwips:
          section['documentGridLinePitchTwips'] is num &&
                  (section['documentGridLinePitchTwips'] as num) > 0
              ? (section['documentGridLinePitchTwips'] as num).toInt()
              : null,
      documentGridType: section['documentGridType'] as String?,
      // `w:cols` ausente fica NULL, não 1: é o que permite reexportar sem
      // carimbar um `w:num` que o arquivo não tinha.
      columnCount:
          section['columnCount'] is num && (section['columnCount'] as num) > 0
              ? (section['columnCount'] as num).toInt()
              : null,
      columnSpacingTwips: value('columnSpacingTwips', 720),
    );
  }

  Map<String, OfficeSourceAnchor> _anchorsOf(Map<String, dynamic> sourceMap) {
    final raw = sourceMap['nodes'];
    if (raw is! List) return const {};
    final result = <String, OfficeSourceAnchor>{};
    for (final entry in raw) {
      final anchor = OfficeSourceAnchor.fromJson(entry as Map<String, dynamic>);
      result[anchor.nodeId] = anchor;
    }
    return result;
  }

  static bool _usesSemanticTableAnchorHashes(Map<String, dynamic> sourceMap) {
    final mode = sourceMap['anchorHashMode'];
    return switch (mode) {
      null || 'full-v1' => false,
      'semantic-tables-v1' => true,
      _ => throw OfficeSnapshotFormatException(
          'anchorHashMode não suportado: $mode',
        ),
    };
  }

  /// O XML da caixa de texto na exportação.
  ///
  /// O caminho normal é o carimbo: devolver o `rawXml` importado intacto
  /// (preservação D1). Mas se o conteúdo da caixa FOI EDITADO (F9), carimbar o
  /// original gravaria no arquivo um texto que não é o que está na tela — o
  /// mesmo problema que os cabeçalhos tinham antes de `_applyEditedRegions`.
  ///
  /// A detecção é por assinatura: `textBoxSourceSignature` é a assinatura do
  /// `textBoxDoc` como ele veio do arquivo. Diferente da atual, o
  /// `w:txbxContent` é regerado a partir dos blocos editados.
  ///
  /// A substituição atinge TODAS as ocorrências de `w:txbxContent` no XML da
  /// caixa: o Word escreve a caixa duas vezes dentro de `mc:AlternateContent`
  /// (DrawingML em `mc:Choice`, VML em `mc:Fallback`), e atualizar só uma
  /// faria o texto mudar ou não conforme o leitor que abrisse o arquivo.
  String _textBoxRawXml(PMNode node, String rawXml) {
    final xml = _textBoxRawXmlWithWrap(node, rawXml);
    final raw = node.attrs['textBoxDoc'];
    if (raw is! Map) return xml;
    final signature = node.attrs['textBoxSourceSignature'];
    PMNode doc;
    try {
      doc = PMNode.fromJSON(node.type.schema, raw);
    } catch (_) {
      return xml;
    }
    if (signature is String &&
        signature == OfficeDocxCodec.nodeSignature(doc)) {
      return xml;
    }
    final content = StringBuffer();
    for (var i = 0; i < doc.childCount; i++) {
      content.write(DocxWriter.serializeBlock(_nodeToBlock(doc.child(i))));
    }
    return _replaceTextBoxContent(xml, content.toString());
  }

  /// Reescreve a DISPOSIÇÃO DO TEXTO no XML preservado da caixa.
  ///
  /// Mesma decisão do `_replaceTextBoxContent`: cirurgia sobre a árvore que
  /// veio do arquivo, nunca reserialização da caixa inteira — a forma, o
  /// preenchimento e as extensões do produtor têm de sobreviver à troca de
  /// um modo de wrap. A reescrita só acontece quando o modo pedido difere do
  /// que está no arquivo, para que abrir e salvar sem tocar no objeto não
  /// mexa num byte.
  static String _textBoxRawXmlWithWrap(PMNode node, String rawXml) {
    final mode = node.attrs['wrapMode'];
    if (mode is! String || mode.isEmpty) return rawXml;
    final XmlElement root;
    try {
      root = XmlDocument.parse(rawXml).rootElement;
    } on XmlParseException {
      return rawXml;
    }
    final side = node.attrs['wrapSide'] is String
        ? node.attrs['wrapSide'] as String
        : null;
    var touched = false;
    for (final anchor in root.descendantsNamed('wp:anchor').toList()) {
      if (_applyWrapToAnchor(anchor, mode, side)) touched = true;
    }
    // Nada mudou no DrawingML: o arquivo já estava no modo pedido e não há
    // razão para mexer num byte do fallback.
    if (!touched) return rawXml;
    // O Word grava a MESMA caixa duas vezes (DrawingML em `mc:Choice`, VML em
    // `mc:Fallback`). O fallback só é lido por consumidores pré-2007, mas
    // deixá-lo divergente faria a caixa mudar de disposição conforme quem
    // abrisse o arquivo.
    for (final wrap in root.descendantsNamed('w10:wrap').toList()) {
      final vmlType = switch (mode) {
        'square' => 'square',
        'tight' => 'tight',
        'through' => 'through',
        'topAndBottom' => 'topAndBottom',
        _ => 'none',
      };
      wrap.setAttribute('type', vmlType);
    }
    return root.toXmlString();
  }

  /// Substitui o elemento de wrap de UMA âncora DrawingML.
  ///
  /// Retorna se algo mudou. `wp:wrapNone` não distingue atrás/na frente: a
  /// ordem de pintura mora em `@behindDoc`, e é por isso que os dois modos
  /// sem exclusão mexem em dois lugares.
  static bool _applyWrapToAnchor(
    XmlElement anchor,
    String mode,
    String? side,
  ) {
    const wrapNames = {
      'wp:wrapSquare',
      'wp:wrapTight',
      'wp:wrapThrough',
      'wp:wrapTopAndBottom',
      'wp:wrapNone',
    };
    final target = switch (mode) {
      'square' => 'wp:wrapSquare',
      'tight' => 'wp:wrapTight',
      'through' => 'wp:wrapThrough',
      'topAndBottom' => 'wp:wrapTopAndBottom',
      _ => 'wp:wrapNone',
    };
    final behind = mode == 'behindText' ? '1' : '0';
    var changed = false;
    if (anchor.getAttribute('behindDoc') != behind) {
      anchor.setAttribute('behindDoc', behind);
      changed = true;
    }

    XmlElement? existing;
    var insertAt = anchor.children.length;
    for (var i = 0; i < anchor.children.length; i++) {
      final child = anchor.children[i];
      if (child is! XmlElement) continue;
      if (wrapNames.contains(child.qname)) {
        existing = child;
        insertAt = i;
        break;
      }
      // Ordem do CT_Anchor: o wrap vem depois de extent/effectExtent e antes
      // de docPr. Sem respeitar a sequência o Word recusa o documento.
      if (const {
        'wp:docPr',
        'wp:cNvGraphicFramePr',
        'a:graphic',
      }.contains(child.qname)) {
        insertAt = i;
        break;
      }
    }
    if (existing != null && existing.qname == target) {
      // Só o lado pode ter mudado.
      if (target == 'wp:wrapSquare' ||
          target == 'wp:wrapTight' ||
          target == 'wp:wrapThrough') {
        final wanted = side ?? existing.getAttribute('wrapText') ?? 'bothSides';
        if (existing.getAttribute('wrapText') != wanted) {
          existing.setAttribute('wrapText', wanted);
          changed = true;
        }
      }
      return changed;
    }

    final replacement = XmlElement(target);
    if (existing != null) {
      // A folga objeto↔texto é do OBJETO, não do modo: preservá-la evita que
      // ir e voltar entre quadrado e comprimido zere o `distL` do autor.
      for (final name in const ['distT', 'distB', 'distL', 'distR']) {
        final value = existing.getAttribute(name);
        if (value != null) replacement.setAttribute(name, value);
      }
      // `wp:wrapTight`/`wp:wrapThrough` exigem `wp:wrapPolygon` pelo schema;
      // o polígono do arquivo é o contorno real do objeto e vale mais que
      // qualquer retângulo que a gente inventasse.
      final polygon = existing.firstChild('wp:wrapPolygon');
      if (polygon != null) replacement.add(polygon);
      anchor.remove(existing);
      if (insertAt > anchor.children.length) insertAt = anchor.children.length;
    }
    if (target == 'wp:wrapSquare' ||
        target == 'wp:wrapTight' ||
        target == 'wp:wrapThrough') {
      replacement.setAttribute('wrapText', side ?? 'bothSides');
    }
    if ((target == 'wp:wrapTight' || target == 'wp:wrapThrough') &&
        replacement.firstChild('wp:wrapPolygon') == null) {
      // Sem polígono herdado, o retângulo completo em coordenadas de forma
      // (0..21600) é o contorno que o próprio Word grava para um retângulo —
      // e é exatamente a aproximação que o compositor usa.
      replacement.add(_rectangleWrapPolygon());
    }
    anchor.insert(insertAt, replacement);
    return true;
  }

  static XmlElement _rectangleWrapPolygon() {
    XmlElement point(String name, int x, int y) => XmlElement(name, [
          XmlAttribute('x', '$x'),
          XmlAttribute('y', '$y'),
        ]);
    return XmlElement('wp:wrapPolygon', [
      XmlAttribute('edited', '0')
    ], [
      point('wp:start', 0, 0),
      point('wp:lineTo', 0, 21600),
      point('wp:lineTo', 21600, 21600),
      point('wp:lineTo', 21600, 0),
      point('wp:lineTo', 0, 0),
    ]);
  }

  /// O XML de uma caixa que NASCEU no editor (F9 — inserir).
  ///
  /// Aqui não há nada a preservar: a forma inteira sai dos atributos do nó,
  /// que é justamente o que faz um redimensionamento pelas alças chegar ao
  /// arquivo — uma caixa nova não tem `wp:extent` velho para ficar mentindo.
  ///
  /// O miolo usa o MESMO serializador de bloco do corpo (`DocxWriter`), então
  /// negrito, alinhamento e listas dentro da caixa saem com a gramática de
  /// parágrafo já testada, e não com uma segunda inventada aqui.
  String _newTextBoxRawXml(PMNode node) {
    int twips(String key, int fallback) {
      final raw = node.attrs[key];
      if (raw is num) return raw.toInt();
      return int.tryParse('$raw') ?? fallback;
    }

    final content = StringBuffer();
    final raw = node.attrs['textBoxDoc'];
    PMNode? doc;
    if (raw is Map) {
      try {
        doc = PMNode.fromJSON(node.type.schema, raw);
      } catch (_) {
        // `textBoxDoc` corrompido não pode impedir a caixa de ser gravada:
        // o fallback de texto plano abaixo ainda preserva o que está na tela.
      }
    }
    if (doc != null && doc.type.name == 'doc' && doc.childCount > 0) {
      for (var i = 0; i < doc.childCount; i++) {
        content.write(DocxWriter.serializeBlock(_nodeToBlock(doc.child(i))));
      }
    } else {
      for (final line in '${node.attrs['text'] ?? ''}'.split('\n')) {
        content.write(DocxWriter.serializeParagraph(WpParagraph(inlines: [
          if (line.isNotEmpty) WpRun(content: [WpText(line)]),
        ])));
      }
    }

    return officeNewTextBoxXml(
      innerXml: content.toString(),
      shapeId: _docPrId++,
      widthTwips: twips('width', officeDefaultTextBoxWidthTwips),
      heightTwips: twips('height', officeDefaultTextBoxHeightTwips),
      insetLeftTwips: twips('insetLeft', officeDefaultTextBoxInsetXTwips),
      insetTopTwips: twips('insetTop', officeDefaultTextBoxInsetYTwips),
      insetRightTwips: twips('insetRight', officeDefaultTextBoxInsetXTwips),
      insetBottomTwips: twips('insetBottom', officeDefaultTextBoxInsetYTwips),
      offsetXTwips: twips('offsetX', 0),
      offsetYTwips: twips('offsetY', 0),
      borderWidthTwips: twips('borderWidth', officeDefaultTextBoxBorderTwips),
      borderColor: node.attrs['borderColor']?.toString(),
      fillColor: node.attrs['background']?.toString(),
    );
  }

  /// Troca o miolo de cada `<w:txbxContent>…</w:txbxContent>` por [inner].
  ///
  /// A varredura é textual de propósito: reserializar a caixa inteira jogaria
  /// fora tudo que não é conteúdo (a forma, o preenchimento, as extensões do
  /// produtor), que é justamente o que a preservação D1 existe para manter.
  static String _replaceTextBoxContent(String xml, String inner) {
    const openPrefix = '<w:txbxContent';
    const close = '</w:txbxContent>';
    final buffer = StringBuffer();
    var cursor = 0;
    while (true) {
      final open = xml.indexOf(openPrefix, cursor);
      if (open < 0) break;
      final openEnd = xml.indexOf('>', open);
      if (openEnd < 0) break;
      // `<w:txbxContent/>` vazio: não há miolo para trocar, e forçar um
      // fecharia a tag por conta própria.
      if (xml[openEnd - 1] == '/') {
        buffer.write(xml.substring(cursor, openEnd + 1));
        cursor = openEnd + 1;
        continue;
      }
      final end = xml.indexOf(close, openEnd);
      if (end < 0) break;
      buffer
        ..write(xml.substring(cursor, openEnd + 1))
        ..write(inner);
      cursor = end;
    }
    buffer.write(xml.substring(cursor));
    return buffer.toString();
  }

  WpBlock _nodeToBlock(PMNode node, {WpBlock? base}) {
    switch (node.type.name) {
      case 'table':
        return _nodeToTable(
          node,
          base: base is WpTable ? base : null,
        );
      case 'opaque':
        final insert = node.attrs['insert'];
        if (insert is Map && insert['officeXml'] is String) {
          return WpPreservedBlock('${insert['qname'] ?? 'w:customXml'}',
              insert['officeXml'] as String);
        }
        return WpParagraph(inlines: [
          WpRun(content: [WpText(node.textContent)])
        ]);
      default:
        return _nodeToParagraph(
          node,
          base: base is WpParagraph ? base : null,
        );
    }
  }

  /// Nó textual editado vira parágrafo Word SEM `sourceXml`, para o writer
  /// serializá-lo a partir do modelo. As propriedades Word importadas ficam
  /// em `attrs.word`; assim uma correção de texto não achata numeração,
  /// alinhamento, espaçamento, tabulações ou bordas do parágrafo.
  WpParagraph _nodeToParagraph(PMNode node, {WpParagraph? base}) {
    final inlines = <WpInline>[];
    final baseTextRuns = base?.allRuns
            .where((run) => run.content.any((content) => content is WpText))
            .toList(growable: false) ??
        const <WpRun>[];
    var textRunIndex = 0;
    for (var i = 0; i < node.childCount; i++) {
      final child = node.child(i);
      final text = child.text;
      if (text != null) {
        if (text.isEmpty) continue;
        final baseRun = textRunIndex < baseTextRuns.length
            ? baseTextRuns[textRunIndex]
            : baseTextRuns.length == 1
                ? baseTextRuns.first
                : null;
        textRunIndex++;
        final run = WpRun(
          properties: _withPreservedRunProperties(
            _runPropertiesFromMarks(child.marks),
            baseRun?.properties,
          ),
          // ProseMirror represents an editable tab as a literal U+0009 in
          // its text stream.  In WordprocessingML that character is not
          // text: it is the run-level `<w:tab/>` atom.  Keeping both text
          // and tabs in the same regenerated run also keeps the original
          // marks/hyperlink around every segment.
          content: _runContentFromPmText(text),
        );
        final link =
            child.marks.where((m) => m.type.name == 'link').firstOrNull;
        final href = link?.attrs['href'];
        if (href is String && href.isNotEmpty) {
          inlines.add(href.startsWith('#')
              ? WpHyperlink(anchor: href.substring(1), runs: [run])
              : WpHyperlink(relId: _relIdForUrl(href), runs: [run]));
        } else {
          inlines.add(run);
        }
        continue;
      }
      if (child.type.name == 'image') {
        final drawing = _drawingFromNode(child);
        if (drawing != null) {
          inlines.add(WpRun(content: [drawing]));
        }
        continue;
      }
      if (child.type.name == 'hardBreak') {
        inlines.add(
            WpRun(content: [WpBreak(child.attrs['breakType'] as String?)]));
        continue;
      }
      if (child.type.name == 'textBox') {
        final word = child.attrs['word'];
        // Sem `word` a caixa NASCEU no editor: não há carimbo para devolver, e
        // pular o nó (o que este ramo fazia) apagaria do arquivo uma caixa que
        // está na tela. A forma inteira é gerada a partir dos atributos.
        final rawXml = word is String
            ? _textBoxRawXml(child, word)
            : _newTextBoxRawXml(child);
        inlines.add(WpRun(content: [
          WpTextBox(blocks: const [], rawXml: rawXml),
        ]));
        continue;
      }
      if (child.type.name == 'opaqueInline') {
        final insert = child.attrs['insert'];
        if (insert is Map && insert['officeXml'] is String) {
          final qname = '${insert['qname'] ?? 'w:customXml'}';
          var xml = insert['officeXml'] as String;
          if (insert['runContent'] == true) {
            // Linked images are projected as opaque run content when their
            // bytes are external. The paragraph can still be regenerated
            // after an adjacent text edit, and copied atoms still need a
            // fresh drawing-object ID just like ordinary image nodes.
            if (qname == 'w:drawing') {
              xml = _rewriteDrawingXml(
                    xml,
                    docPrId: _docPrId++,
                  ) ??
                  xml;
            }
            inlines.add(WpRun(content: [WpPreservedRunContent(qname, xml)]));
          } else {
            inlines.add(WpPreservedInline(qname, xml));
          }
        }
      }
    }
    final level = node.attrs['level'];
    var properties = _paragraphPropertiesFromJson(node.attrs['word']);
    properties = _paragraphPropertiesWithPresentation(
        properties, node.attrs['style'], node.attrs['align']);
    properties =
        _withPreservedParagraphProperties(properties, base?.properties);
    if (node.type.name == 'listItem') {
      final kind = node.attrs['kind'] == 'ordered' ? 'ordered' : 'bullet';
      final style = _asMap(node.attrs['style']);
      properties = _withParagraphNumbering(
        properties,
        _numberingForList(
          kind,
          properties?.numPr,
          // O formato escolhido na galeria da ribbon viaja no MESMO
          // vocabulário que o `w:lvl` usa; sem passá-lo adiante, um "I." ou
          // um "▪" viraria o "1." genérico ao salvar.
          numFmt: style?['numFmt'],
          lvlText: style?['lvlText'],
          ilvl: _intValue(node.attrs['indent']) ?? 0,
        ),
      );
    }
    if (properties?.styleId == null &&
        node.type.name == 'heading' &&
        level != null) {
      properties =
          _copyParagraphProperties(properties, styleId: 'Heading$level');
    }
    return WpParagraph(
      properties: properties,
      attributes:
          _paragraphAttributesFromJson(node.attrs['word']) ?? base?.attributes,
      inlines: inlines,
    );
  }

  static List<WpRunContent> _runContentFromPmText(String text) {
    final content = <WpRunContent>[];
    var textStart = 0;
    for (var index = 0; index < text.length; index++) {
      if (text.codeUnitAt(index) != 0x09) continue;
      if (index > textStart) {
        content.add(WpText(text.substring(textStart, index)));
      }
      content.add(WpTabChar());
      textStart = index + 1;
    }
    if (textStart < text.length) content.add(WpText(text.substring(textStart)));
    return content;
  }

  /// Conserva somente os campos rPr sem UI propria que sao seguros para um
  /// run regenerado. Nenhum conteudo/texto do run de origem e reutilizado.
  static WpRunProperties? _withPreservedRunProperties(
    WpRunProperties? edited,
    WpRunProperties? base,
  ) {
    if (base?.fontEastAsia == null && base?.boldCs == null) return edited;
    final preserved = WpRunProperties(
      fontEastAsia: base?.fontEastAsia,
      boldCs: base?.boldCs,
    );
    return edited == null ? preserved : preserved.mergedWith(edited);
  }

  /// O PM normalmente carrega autoSpaceDN em attrs.word. O fallback da
  /// ancora cobre tambem edicoes que recriam o no e perdem esse mapa.
  static WpParagraphProperties? _withPreservedParagraphProperties(
    WpParagraphProperties? edited,
    WpParagraphProperties? base,
  ) {
    if (edited?.autoSpaceDN != null || base?.autoSpaceDN == null) return edited;
    final json = _paragraphPropertiesToJson(edited) ?? <String, dynamic>{};
    json['autoSpaceDN'] = base!.autoSpaceDN;
    return _paragraphPropertiesFromJson(json);
  }

  WpParagraphProperties _withParagraphNumbering(
    WpParagraphProperties? properties,
    WpNumPr numPr,
  ) {
    final json = _paragraphPropertiesToJson(properties) ?? <String, dynamic>{};
    json['numPr'] = <String, dynamic>{
      'numId': numPr.numId,
      'ilvl': numPr.ilvl,
    };
    return _paragraphPropertiesFromJson(json)!;
  }

  /// O nível [level] de uma chave de lista que pode descrever um valor único
  /// ou um por NÍVEL — a mesma regra de `LayoutComposer._atListLevel`, para
  /// que arquivo e tela concordem sobre qual marcador pertence a qual nível.
  static String? _listSchemeAt(Object? raw, int level) {
    if (raw is String) return raw;
    if (raw is! List || raw.isEmpty) return null;
    final index =
        level < 0 ? 0 : (level >= raw.length ? raw.length - 1 : level);
    final value = raw[index];
    return value is String ? value : null;
  }

  static int _listSchemeLength(Object? raw) => raw is List ? raw.length : 1;

  /// Keeps a valid imported numbering reference when it already represents
  /// the requested format. UI-authored or format-switched lists receive a
  /// small generated definition that is added to the existing numbering part
  /// without rewriting its unknown XML.
  ///
  /// [numFmt] e [lvlText] aceitam String (um nível) ou List (um por nível,
  /// o caso da galeria "Lista de Vários Níveis"). [ilvl] é o nível DESTE
  /// parágrafo: sem ele, um item recuado sairia no nível zero e o Word
  /// desenharia a lista inteira achatada.
  WpNumPr _numberingForList(
    String kind,
    WpNumPr? current, {
    Object? numFmt,
    Object? lvlText,
    int ilvl = 0,
  }) {
    final file = _activeFile;
    if (file == null) {
      throw StateError('lista DOCX exportada sem pacote ativo');
    }
    final bullet = kind == 'bullet';
    final levelCount = [
      _listSchemeLength(numFmt),
      _listSchemeLength(lvlText),
      ilvl + 1,
    ].reduce((a, b) => a > b ? a : b);
    final scheme = [
      for (var level = 0; level < levelCount; level++)
        (
          numFmt:
              _listSchemeAt(numFmt, level) ?? (bullet ? 'bullet' : 'decimal'),
          lvlText: _listSchemeAt(lvlText, level) ?? (bullet ? '•' : '%1.'),
        ),
    ];
    final wanted = scheme[ilvl];

    final currentId = current?.numId;
    if (currentId != null && currentId != 0) {
      final level = file.numbering.levelOf(currentId, current!.ilvl);
      // A definição importada só é preservada quando ela JÁ desenha o mesmo
      // rótulo. Comparar só bullet/ordered devolvia "1." para um parágrafo
      // que a galeria acabou de mudar para "I." — o modelo dizia uma coisa e
      // o arquivo saía com outra.
      if (level != null &&
          level.numFmt == wanted.numFmt &&
          level.lvlText == wanted.lvlText) {
        return current;
      }
    }

    // A chave é o ESQUEMA inteiro: um documento com marcadores "•" e "▪"
    // precisa de duas definições, não de uma que a segunda escolha
    // sobrescreve. Dois itens do mesmo esquema em níveis diferentes, ao
    // contrário, têm de compartilhar o `numId` — senão cada nível vira uma
    // sequência própria.
    final cacheKey =
        scheme.map((level) => '${level.numFmt}|${level.lvlText}').join(' ');
    final cached = _generatedListNumIds[cacheKey];
    if (cached != null) return WpNumPr(numId: cached, ilvl: ilvl);

    var abstractNumId = 0;
    for (final id in file.numbering.abstractNums.keys) {
      if (id >= abstractNumId) abstractNumId = id + 1;
    }
    var numId = 1;
    for (final id in file.numbering.nums.keys) {
      if (id >= numId) numId = id + 1;
    }

    file.numbering.abstractNums[abstractNumId] = WpAbstractNum(
      id: abstractNumId,
      multiLevelType: levelCount > 1 ? 'hybridMultilevel' : 'singleLevel',
      levels: {
        for (var level = 0; level < levelCount; level++)
          level: WpNumberingLevel(
            ilvl: level,
            numFmt: scheme[level].numFmt,
            lvlText: scheme[level].lvlText,
            lvlJc: 'left',
            indent: WpIndent(
                leftTwips: _listLevelIndentTwips * (level + 1),
                hangingTwips: 360),
            runProperties: scheme[level].numFmt == 'bullet'
                ? const WpRunProperties(fontAscii: 'Arial')
                : null,
          ),
      },
    );
    file.numbering.nums[numId] = WpNum(
      numId: numId,
      abstractNumId: abstractNumId,
    );
    _appendNumberingDefinition(
      file,
      abstractNumId: abstractNumId,
      numId: numId,
      levels: scheme,
    );
    _generatedListNumIds[cacheKey] = numId;
    return WpNumPr(numId: numId, ilvl: ilvl);
  }

  /// A escada de recuo de lista gravada no `w:lvl` (o padrão do Word).
  static const int _listLevelIndentTwips = 720;

  void _appendNumberingDefinition(
    DocxFile file, {
    required int abstractNumId,
    required int numId,
    required List<({String numFmt, String lvlText})> levels,
  }) {
    const partName = 'word/numbering.xml';
    const contentType =
        'application/vnd.openxmlformats-officedocument.wordprocessingml.numbering+xml';
    final package = file.package;
    final buffer =
        StringBuffer('<w:abstractNum w:abstractNumId="$abstractNumId">'
            '<w:multiLevelType w:val="'
            '${levels.length > 1 ? 'hybridMultilevel' : 'singleLevel'}"/>');
    for (var level = 0; level < levels.length; level++) {
      final indent = _listLevelIndentTwips * (level + 1);
      buffer
        ..write('<w:lvl w:ilvl="$level">')
        ..write('<w:start w:val="1"/>')
        ..write('<w:numFmt w:val="'
            '${XmlEscape.attribute(levels[level].numFmt)}"/>')
        ..write('<w:lvlText w:val="'
            '${XmlEscape.attribute(levels[level].lvlText)}"/>')
        ..write('<w:lvlJc w:val="left"/>')
        ..write('<w:pPr><w:tabs><w:tab w:val="num" w:pos="$indent"/>'
            '</w:tabs><w:ind w:left="$indent" w:hanging="360"/></w:pPr>')
        ..write(levels[level].numFmt == 'bullet'
            ? '<w:rPr><w:rFonts w:ascii="Arial" w:hAnsi="Arial"/></w:rPr>'
            : '')
        ..write('</w:lvl>');
    }
    buffer
      ..write('</w:abstractNum>')
      ..write('<w:num w:numId="$numId">')
      ..write('<w:abstractNumId w:val="$abstractNumId"/>')
      ..write('</w:num>');
    final fragment = buffer.toString();

    final source = package.partString(partName);
    if (source == null) {
      package.setPartString(
          partName,
          '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
          '<w:numbering xmlns:w="http://schemas.openxmlformats.org/'
          'wordprocessingml/2006/main">$fragment</w:numbering>');
    } else {
      final close = RegExp(r'</w:numbering\s*>').firstMatch(source);
      if (close == null) {
        throw const FormatException(
            'word/numbering.xml sem fechamento w:numbering');
      }
      package.setPartString(
        partName,
        source.replaceRange(close.start, close.start, fragment),
      );
    }

    if (package.contentTypes.typeOf(partName) != contentType) {
      package.contentTypes.setOverride(partName, contentType);
      package.setPartString(
          '[Content_Types].xml', package.contentTypes.toXmlString());
    }
    final relationships = package.relationshipsFor(file.mainPartName);
    if (relationships.firstOfType(RelType.numbering) == null) {
      relationships.add(Relationship(
        id: relationships.nextId(),
        type: RelType.numbering,
        target: 'numbering.xml',
      ));
      package.setRelationshipsFor(file.mainPartName, relationships);
    }
  }

  WpTable _nodeToTable(PMNode node, {WpTable? base}) {
    final rows = <WpTableRow>[];
    for (var r = 0; r < node.childCount; r++) {
      final row = node.child(r);
      final rowWord = row.attrs['word'];
      final sourceRowIndex =
          rowWord is Map ? _intValue(rowWord['sourceRowIndex']) : null;
      final baseRow = sourceRowIndex != null &&
              sourceRowIndex >= 0 &&
              sourceRowIndex < (base?.rows.length ?? 0)
          ? base!.rows[sourceRowIndex]
          : null;
      final sourceRowSignature =
          rowWord is Map ? rowWord['sourceSignature'] as String? : null;

      // The TR corpus has a 1,367-row table. Rewriting all of it after one
      // keystroke costs seconds and needlessly risks vendor-specific XML.
      // Reuse every untouched row verbatim and rebuild only the edited row.
      if (baseRow != null &&
          sourceRowSignature != null &&
          sourceRowSignature == _semanticSignature(row)) {
        rows.add(baseRow);
        continue;
      }

      final cells = <WpTableCell>[];
      for (var c = 0; c < row.childCount; c++) {
        final cell = row.child(c);
        final cellWord = cell.attrs['word'];
        final sourceCellIndex =
            cellWord is Map ? _intValue(cellWord['sourceCellIndex']) : null;
        final baseCell = sourceCellIndex != null &&
                sourceCellIndex >= 0 &&
                sourceCellIndex < (baseRow?.cells.length ?? 0)
            ? baseRow!.cells[sourceCellIndex]
            : null;
        final sourceCellSignature =
            cellWord is Map ? cellWord['sourceSignature'] as String? : null;
        if (baseCell != null &&
            sourceCellSignature != null &&
            sourceCellSignature == _semanticSignature(cell)) {
          cells.add(baseCell);
          continue;
        }
        final cellBlocks = <WpBlock>[];
        for (var b = 0; b < cell.childCount; b++) {
          final block = cell.child(b);
          final blockWord = _asMap(block.attrs['word']);
          final sourceBlockIndex = _intValue(blockWord?['sourceBlockIndex']);
          final baseBlock = sourceBlockIndex != null &&
                  sourceBlockIndex >= 0 &&
                  sourceBlockIndex < (baseCell?.blocks.length ?? 0)
              ? baseCell!.blocks[sourceBlockIndex]
              : null;
          final sourceBlockSignature = blockWord?['sourceSignature'];
          if (baseBlock != null &&
              sourceBlockSignature is String &&
              sourceBlockSignature == _semanticSignature(block)) {
            // Uma célula pode conter vários parágrafos (e até tabelas
            // aninhadas). Uma tecla no primeiro bloco não autoriza regravar
            // os demais: bookmarks, rsids e extensões continuam no XML cru.
            cellBlocks.add(baseBlock);
          } else {
            cellBlocks.add(_nodeToBlock(block, base: baseBlock));
          }
        }
        cells.add(WpTableCell(
          properties: _tableCellPropertiesFromJson(cellWord),
          blocks: cellBlocks,
        ));
      }
      rows.add(WpTableRow(
        properties: _tableRowPropertiesFromJson(rowWord),
        cells: cells,
      ));
    }
    final rawWidths = node.attrs['colWidths'];
    final widths = rawWidths is List
        ? [
            for (final value in rawWidths)
              if (_widthTwipsOf(value) != null) _widthTwipsOf(value)!
          ]
        : const <int>[];
    return WpTable(
      properties: _tablePropertiesFromJson(node.attrs['word']),
      gridColumnsTwips: widths,
      rows: rows,
      childOrder: _tableChildOrderFromJson(node.attrs['word']),
    );
  }

  Future<WpTable> _nodeToTableAsync(
    PMNode node, {
    WpTable? base,
    required _CooperativeImportClock clock,
  }) async {
    final rows = <WpTableRow>[];
    for (var r = 0; r < node.childCount; r++) {
      if (clock.expired) await clock.yieldNow();
      final row = node.child(r);
      final rowWord = row.attrs['word'];
      final sourceRowIndex =
          rowWord is Map ? _intValue(rowWord['sourceRowIndex']) : null;
      final baseRow = sourceRowIndex != null &&
              sourceRowIndex >= 0 &&
              sourceRowIndex < (base?.rows.length ?? 0)
          ? base!.rows[sourceRowIndex]
          : null;
      final sourceRowSignature =
          rowWord is Map ? rowWord['sourceSignature'] as String? : null;
      final rowSignature =
          sourceRowSignature == null ? null : _semanticSignature(row);
      if (clock.expired) await clock.yieldNow();
      if (baseRow != null &&
          sourceRowSignature != null &&
          sourceRowSignature == rowSignature) {
        rows.add(baseRow);
        continue;
      }

      final cells = <WpTableCell>[];
      for (var c = 0; c < row.childCount; c++) {
        if (clock.expired) await clock.yieldNow();
        final cell = row.child(c);
        final cellWord = cell.attrs['word'];
        final sourceCellIndex =
            cellWord is Map ? _intValue(cellWord['sourceCellIndex']) : null;
        final baseCell = sourceCellIndex != null &&
                sourceCellIndex >= 0 &&
                sourceCellIndex < (baseRow?.cells.length ?? 0)
            ? baseRow!.cells[sourceCellIndex]
            : null;
        final sourceCellSignature =
            cellWord is Map ? cellWord['sourceSignature'] as String? : null;
        final cellSignature =
            sourceCellSignature == null ? null : _semanticSignature(cell);
        if (clock.expired) await clock.yieldNow();
        if (baseCell != null &&
            sourceCellSignature != null &&
            sourceCellSignature == cellSignature) {
          cells.add(baseCell);
          continue;
        }

        final cellBlocks = <WpBlock>[];
        for (var b = 0; b < cell.childCount; b++) {
          if (clock.expired) await clock.yieldNow();
          final block = cell.child(b);
          final blockWord = _asMap(block.attrs['word']);
          final sourceBlockIndex = _intValue(blockWord?['sourceBlockIndex']);
          final baseBlock = sourceBlockIndex != null &&
                  sourceBlockIndex >= 0 &&
                  sourceBlockIndex < (baseCell?.blocks.length ?? 0)
              ? baseCell!.blocks[sourceBlockIndex]
              : null;
          final sourceBlockSignature = blockWord?['sourceSignature'];
          if (baseBlock != null &&
              sourceBlockSignature is String &&
              sourceBlockSignature == _semanticSignature(block)) {
            cellBlocks.add(baseBlock);
          } else if (block.type.name == 'table') {
            cellBlocks.add(await _nodeToTableAsync(
              block,
              base: baseBlock is WpTable ? baseBlock : null,
              clock: clock,
            ));
          } else {
            cellBlocks.add(_nodeToBlock(block, base: baseBlock));
          }
        }
        cells.add(WpTableCell(
          properties: _tableCellPropertiesFromJson(cellWord),
          blocks: cellBlocks,
        ));
      }
      rows.add(WpTableRow(
        properties: _tableRowPropertiesFromJson(rowWord),
        cells: cells,
      ));
    }
    final rawWidths = node.attrs['colWidths'];
    final widths = rawWidths is List
        ? [
            for (final value in rawWidths)
              if (_widthTwipsOf(value) != null) _widthTwipsOf(value)!
          ]
        : const <int>[];
    return WpTable(
      properties: _tablePropertiesFromJson(node.attrs['word']),
      gridColumnsTwips: widths,
      rows: rows,
      childOrder: _tableChildOrderFromJson(node.attrs['word']),
    );
  }

  WpRunProperties? _runPropertiesFromMarks(List<Mark> marks) {
    bool? bold, italic, strike;
    String? underline, font, color, highlight, vertAlign;
    String? styleId, fontEastAsia;
    bool? caps, smallCaps, boldCs;
    int? sizeHalfPoints, spacingTwips;
    WpShading? shading;
    for (final mark in marks) {
      switch (mark.type.name) {
        case 'bold':
          bold = true;
        case 'italic':
          italic = true;
        case 'strike':
          strike = true;
        case 'underline':
          underline = 'single';
        case 'font':
          font = '${mark.attrs['value']}';
        case 'size':
          final raw = '${mark.attrs['value']}'.trim();
          final match = RegExp(r'^([\d.]+)(pt|px)?$').firstMatch(raw);
          final value = match == null ? null : double.tryParse(match.group(1)!);
          if (value != null) {
            final pt = match!.group(2) == 'px' ? value * .75 : value;
            sizeHalfPoints = (pt * 2).round();
          }
        case 'letterSpacing':
          spacingTwips = _intValue(mark.attrs['twips']);
        case 'color':
          color = _hex('${mark.attrs['value']}');
        case 'background':
          final fill = _hex('${mark.attrs['value']}');
          if (fill != null) {
            shading = WpShading(val: 'clear', color: 'auto', fill: fill);
          }
        case 'script':
          vertAlign = switch ('${mark.attrs['value']}') {
            'super' => 'superscript',
            'sub' => 'subscript',
            final value => value,
          };
        case 'opaqueAttrs':
          final attrs = mark.attrs['attrs'];
          if (attrs is Map && attrs['wordHighlight'] is String) {
            highlight = attrs['wordHighlight'] as String;
          }
          if (attrs is Map) {
            styleId = attrs['wordStyleId'] as String?;
            caps = attrs['wordCaps'] as bool?;
            smallCaps = attrs['wordSmallCaps'] as bool?;
            fontEastAsia = attrs['wordFontEastAsia'] as String?;
            boldCs = attrs['wordBoldCs'] as bool?;
          }
      }
    }
    if (bold == null &&
        italic == null &&
        strike == null &&
        underline == null &&
        font == null &&
        color == null &&
        highlight == null &&
        vertAlign == null &&
        styleId == null &&
        fontEastAsia == null &&
        caps == null &&
        smallCaps == null &&
        boldCs == null &&
        sizeHalfPoints == null &&
        spacingTwips == null &&
        shading == null) {
      return null;
    }
    return WpRunProperties(
      styleId: styleId,
      fontAscii: font,
      fontHAnsi: font,
      fontEastAsia: fontEastAsia,
      bold: bold,
      boldCs: boldCs,
      italic: italic,
      strike: strike,
      caps: caps,
      smallCaps: smallCaps,
      underline: underline,
      sizeHalfPoints: sizeHalfPoints,
      color: color,
      highlight: highlight,
      shading: shading,
      vertAlign: vertAlign,
      spacingTwips: spacingTwips,
    );
  }

  String _relIdForUrl(String url) {
    final file = _activeFile;
    if (file == null) return '';
    final rels = file.package.relationshipsFor(file.mainPartName);
    for (final rel in rels.items) {
      if (rel.isExternal && rel.target == url) return rel.id;
    }
    final id = rels.nextId();
    rels.add(Relationship(
      id: id,
      type: RelType.hyperlink,
      target: url,
      isExternal: true,
    ));
    file.package.setRelationshipsFor(file.mainPartName, rels);
    return id;
  }

  WpDrawing? _drawingFromNode(PMNode node) {
    final file = _activeFile;
    if (file == null) return null;
    final image = _imageDataFromSource(node.attrs['src']);
    final extra = node.attrs['extra'];
    final rawXml = extra is Map && extra['wordDrawing'] is String
        ? extra['wordDrawing'] as String
        : null;
    final rawEmbedRelId = rawXml == null ? null : _drawingEmbedRelId(rawXml);
    final rawLinkRelId = rawXml == null ? null : _drawingLinkRelId(rawXml);
    final widthTwips = _imageDimensionTwips(node.attrs['width']);
    final heightTwips = _imageDimensionTwips(node.attrs['height']);

    // A linked image has no bytes to materialize. It remains valid only while
    // the active part still owns its exact external image relationship.
    if (rawEmbedRelId == null && rawLinkRelId != null && image == null) {
      if (!_hasExternalImageRelationship(file, rawLinkRelId)) return null;
      final id = _docPrId++;
      final rewritten = _rewriteDrawingXml(
        rawXml!,
        linkRelId: rawLinkRelId,
        docPrId: id,
        widthTwips: widthTwips,
        heightTwips: heightTwips,
      );
      if (rewritten == null) return null;
      return WpDrawing(
        embedRelId: rawLinkRelId,
        widthEmu: widthTwips == null ? null : widthTwips * 635.0,
        heightEmu: heightTwips == null ? null : heightTwips * 635.0,
        isInline: extra is Map && extra['wordDrawingInline'] != false,
        rawXml: rewritten,
      );
    }

    if (image == null) return null;

    // Pasted DOCX drawings routinely collide on names such as rId2. The
    // data URI is the source of truth; raw XML is reusable only when target,
    // relationship type, MIME and SHA-256 all agree with it.
    final relId = rawEmbedRelId != null &&
            _embeddedImageMatches(file, rawEmbedRelId, image)
        ? rawEmbedRelId
        : _ensureEmbeddedImage(file, image);
    final id = _docPrId++;

    if (rawXml != null && rawEmbedRelId != null) {
      final rewritten = _rewriteDrawingXml(
        rawXml,
        embedRelId: relId,
        docPrId: id,
        widthTwips: widthTwips,
        heightTwips: heightTwips,
      );
      if (rewritten != null) {
        return WpDrawing(
          embedRelId: relId,
          widthEmu: widthTwips == null ? null : widthTwips * 635.0,
          heightEmu: heightTwips == null ? null : heightTwips * 635.0,
          isInline: extra is Map && extra['wordDrawingInline'] != false,
          rawXml: rewritten,
        );
      }
    }

    final generatedWidthTwips = widthTwips ?? 1440;
    final generatedHeightTwips = heightTwips ?? generatedWidthTwips;
    final cx = generatedWidthTwips * 635;
    final cy = generatedHeightTwips * 635;
    return WpDrawing(
      embedRelId: relId,
      widthEmu: cx.toDouble(),
      heightEmu: cy.toDouble(),
      isInline: true,
      rawXml: _newDrawingXml(relId, id, cx, cy),
    );
  }

  static String? _drawingEmbedRelId(String xml) =>
      RegExp(r'\br:embed="([^"]+)"').firstMatch(xml)?.group(1);

  static String? _drawingLinkRelId(String xml) =>
      RegExp(r'\br:link="([^"]+)"').firstMatch(xml)?.group(1);

  static _DocxImageData? _imageDataFromSource(dynamic value) {
    if (value is! String) return null;
    final match = RegExp(
      r'^data:(image/[a-zA-Z0-9.+-]+);base64,(.*)$',
      dotAll: true,
      caseSensitive: false,
    ).firstMatch(value);
    if (match == null) {
      if (value.toLowerCase().startsWith('data:image/')) {
        throw const FormatException(
            'Imagem data URI precisa usar codificação base64 válida.');
      }
      return null;
    }

    final bytes = base64Decode(match.group(2)!.replaceAll(RegExp(r'\s'), ''));
    final mimeType = _normalizeImageMime(match.group(1)!);
    return _DocxImageData(
      bytes: bytes,
      mimeType: mimeType,
      digest: sha256Hex(bytes),
      extension: _imageExtension(mimeType),
    );
  }

  static String _normalizeImageMime(String value) =>
      switch (value.trim().toLowerCase()) {
        'image/jpg' || 'image/pjpeg' => 'image/jpeg',
        'image/x-png' => 'image/png',
        'image/x-ms-bmp' => 'image/bmp',
        'image/tif' => 'image/tiff',
        String normalized => normalized,
      };

  static String? _imageExtension(String mimeType) => switch (mimeType) {
        'image/png' => 'png',
        'image/jpeg' => 'jpeg',
        'image/gif' => 'gif',
        'image/svg+xml' => 'svg',
        'image/webp' => 'webp',
        'image/bmp' => 'bmp',
        'image/tiff' => 'tiff',
        'image/x-emf' => 'emf',
        'image/x-wmf' => 'wmf',
        _ => null,
      };

  static bool _embeddedImageMatches(
      DocxFile file, String relId, _DocxImageData image) {
    final rel = file.package.relationshipsFor(file.mainPartName).byId(relId);
    if (rel == null || rel.isExternal || rel.type != RelType.image) {
      return false;
    }
    final partName = file.package.resolveTarget(file.mainPartName, rel.target);
    final bytes = file.package.partBytes(partName);
    final contentType = file.package.contentTypeOf(partName);
    return bytes != null &&
        contentType != null &&
        _normalizeImageMime(contentType) == image.mimeType &&
        sha256Hex(bytes) == image.digest;
  }

  String _ensureEmbeddedImage(DocxFile file, _DocxImageData image) {
    final extension = image.extension;
    if (extension == null) {
      throw UnsupportedError(
          'MIME de imagem não suportado para DOCX: ${image.mimeType}');
    }

    final mainSlash = file.mainPartName.lastIndexOf('/');
    final mainDirectory =
        mainSlash < 0 ? '' : file.mainPartName.substring(0, mainSlash + 1);
    final fileName = 'dq-${image.digest}.$extension';
    final partName = '${mainDirectory}media/$fileName';
    final target = 'media/$fileName';
    final existingBytes = file.package.partBytes(partName);
    if (existingBytes == null) {
      file.package.setPart(partName, image.bytes);
    } else if (sha256Hex(existingBytes) != image.digest) {
      throw StateError('Colisão SHA-256 na parte de imagem $partName');
    }

    var contentTypesChanged = false;
    final actualType = file.package.contentTypeOf(partName);
    if (actualType == null) {
      file.package.contentTypes.setDefault(extension, image.mimeType);
      contentTypesChanged = true;
    } else if (_normalizeImageMime(actualType) != image.mimeType) {
      // Do not replace a package-wide default used by pre-existing parts.
      // A precise override changes only the newly materialized hashed part.
      file.package.contentTypes.setOverride(partName, image.mimeType);
      contentTypesChanged = true;
    }
    if (contentTypesChanged) {
      file.package.setPartString(
          '[Content_Types].xml', file.package.contentTypes.toXmlString());
    }

    final rels = file.package.relationshipsFor(file.mainPartName);
    for (final rel in rels.items) {
      if (!rel.isExternal &&
          rel.type == RelType.image &&
          file.package.resolveTarget(file.mainPartName, rel.target) ==
              partName) {
        return rel.id;
      }
    }
    final relId = rels.nextId();
    rels.add(Relationship(id: relId, type: RelType.image, target: target));
    file.package.setRelationshipsFor(file.mainPartName, rels);
    return relId;
  }

  static bool _hasExternalImageRelationship(DocxFile file, String relId) {
    final rel = file.package.relationshipsFor(file.mainPartName).byId(relId);
    return rel != null && rel.isExternal && rel.type == RelType.image;
  }

  static int? _imageDimensionTwips(dynamic value) {
    final parsed = switch (value) {
      num number => number.round(),
      String text => num.tryParse(text)?.round(),
      _ => null,
    };
    return parsed != null && parsed > 0 ? parsed : null;
  }

  static String? _rewriteDrawingXml(
    String xml, {
    String? embedRelId,
    String? linkRelId,
    required int docPrId,
    int? widthTwips,
    int? heightTwips,
  }) {
    final XmlElement root;
    try {
      root = XmlDocument.parse(xml).rootElement;
    } on XmlParseException {
      return null;
    }

    final blip = root.descendantsNamed('a:blip').firstOrNull;
    if (embedRelId != null) {
      if (blip == null) return null;
      blip.setAttribute('r:embed', embedRelId);
    }
    if (linkRelId != null) {
      if (blip == null) return null;
      blip.setAttribute('r:link', linkRelId);
    }

    final container = root.firstChild('wp:inline') ??
        root.firstChild('wp:anchor') ??
        root.descendantsNamed('wp:inline').firstOrNull ??
        root.descendantsNamed('wp:anchor').firstOrNull;
    var docPr = root.descendantsNamed('wp:docPr').firstOrNull;
    if (docPr == null && container != null) {
      docPr = XmlElement('wp:docPr', [
        XmlAttribute('id', '$docPrId'),
        XmlAttribute('name', 'Imagem $docPrId'),
      ]);
      var insertion = container.children.length;
      for (var i = 0; i < container.children.length; i++) {
        final child = container.children[i];
        if (child is XmlElement &&
            const {'wp:cNvGraphicFramePr', 'a:graphic'}.contains(child.qname)) {
          insertion = i;
          break;
        }
      }
      container.insert(insertion, docPr);
    }
    docPr?.setAttribute('id', '$docPrId');
    root
        .descendantsNamed('pic:cNvPr')
        .firstOrNull
        ?.setAttribute('id', '$docPrId');

    final extent = container?.firstChild('wp:extent');
    if (widthTwips != null) extent?.setAttribute('cx', '${widthTwips * 635}');
    if (heightTwips != null) {
      extent?.setAttribute('cy', '${heightTwips * 635}');
    }
    final pictureExtent = root
        .descendantsNamed('pic:spPr')
        .firstOrNull
        ?.firstChild('a:xfrm')
        ?.firstChild('a:ext');
    if (widthTwips != null) {
      pictureExtent?.setAttribute('cx', '${widthTwips * 635}');
    }
    if (heightTwips != null) {
      pictureExtent?.setAttribute('cy', '${heightTwips * 635}');
    }

    return root.toXmlString();
  }

  static String _newDrawingXml(String relId, int id, int cx, int cy) =>
      '<w:drawing>'
      '<wp:inline xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing" '
      'distT="0" distB="0" distL="0" distR="0">'
      '<wp:extent cx="$cx" cy="$cy"/>'
      '<wp:docPr id="$id" name="Imagem $id"/>'
      '<a:graphic xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" '
      'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
      '<a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/picture">'
      '<pic:pic xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture">'
      '<pic:nvPicPr><pic:cNvPr id="$id" name="Imagem $id"/><pic:cNvPicPr/></pic:nvPicPr>'
      '<pic:blipFill><a:blip r:embed="$relId"/>'
      '<a:stretch><a:fillRect/></a:stretch></pic:blipFill>'
      '<pic:spPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="$cx" cy="$cy"/></a:xfrm>'
      '<a:prstGeom prst="rect"><a:avLst/></a:prstGeom></pic:spPr>'
      '</pic:pic></a:graphicData></a:graphic></wp:inline></w:drawing>';

  static String? _hex(String value) {
    final normalized = value.trim().replaceFirst('#', '');
    return RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(normalized)
        ? normalized.toUpperCase()
        : null;
  }

  static int? _widthTwipsOf(dynamic value) {
    if (value is num) return value.round();
    if (value is Map) {
      final raw = value['widthTwips'] ?? value['value'] ?? value['width'];
      if (raw is num) return raw.round();
      return int.tryParse('$raw');
    }
    return int.tryParse('$value');
  }

  static int? _intValue(dynamic value) => switch (value) {
        int number => number,
        num number => number.toInt(),
        _ => int.tryParse('$value'),
      };

  static Map<String, dynamic>? _asMap(dynamic value) =>
      value is Map ? value.cast<String, dynamic>() : null;

  static Map<String, dynamic>? _widthToJson(WpTableWidth? value) =>
      value == null ? null : {'value': value.value, 'type': value.type};

  static WpTableWidth? _widthFromJson(dynamic value) {
    final map = _asMap(value);
    if (map == null) return null;
    return WpTableWidth(
      value: (map['value'] as num?)?.toInt(),
      type: map['type'] as String?,
    );
  }

  static Map<String, dynamic>? _cellMarginsToJson(WpCellMargins? value) =>
      value == null
          ? null
          : {
              'top': _widthToJson(value.top),
              'left': _widthToJson(value.left),
              'bottom': _widthToJson(value.bottom),
              'right': _widthToJson(value.right),
            };

  static WpCellMargins? _cellMarginsFromJson(dynamic value) {
    final map = _asMap(value);
    if (map == null) return null;
    return WpCellMargins(
      top: _widthFromJson(map['top']),
      left: _widthFromJson(map['left']),
      bottom: _widthFromJson(map['bottom']),
      right: _widthFromJson(map['right']),
    );
  }

  static Map<String, dynamic>? _shadingToJson(WpShading? value) => value == null
      ? null
      : {'val': value.val, 'color': value.color, 'fill': value.fill};

  static WpShading? _shadingFromJson(dynamic value) {
    final map = _asMap(value);
    if (map == null) return null;
    return WpShading(
      val: map['val'] as String?,
      color: map['color'] as String?,
      fill: map['fill'] as String?,
    );
  }

  static Map<String, dynamic>? _borderToJson(WpBorder? value) => value == null
      ? null
      : {
          'val': value.val,
          'sizeEighths': value.sizeEighths,
          'color': value.color,
          'space': value.space,
        };

  static WpBorder? _borderFromJson(dynamic value) {
    final map = _asMap(value);
    if (map == null) return null;
    return WpBorder(
      val: map['val'] as String?,
      sizeEighths: (map['sizeEighths'] as num?)?.toInt(),
      color: map['color'] as String?,
      space: (map['space'] as num?)?.toInt(),
    );
  }

  static Map<String, dynamic>? _bordersToJson(WpBorders? value) => value == null
      ? null
      : {
          'top': _borderToJson(value.top),
          'left': _borderToJson(value.left),
          'bottom': _borderToJson(value.bottom),
          'right': _borderToJson(value.right),
          'insideH': _borderToJson(value.insideH),
          'insideV': _borderToJson(value.insideV),
        };

  static WpBorders? _bordersFromJson(dynamic value) {
    final map = _asMap(value);
    if (map == null) return null;
    return WpBorders(
      top: _borderFromJson(map['top']),
      left: _borderFromJson(map['left']),
      bottom: _borderFromJson(map['bottom']),
      right: _borderFromJson(map['right']),
      insideH: _borderFromJson(map['insideH']),
      insideV: _borderFromJson(map['insideV']),
    );
  }

  static Map<String, dynamic>? _runPropertiesToJson(WpRunProperties? value) =>
      value == null
          ? null
          : {
              'styleId': value.styleId,
              'fontAscii': value.fontAscii,
              'fontHAnsi': value.fontHAnsi,
              'fontEastAsia': value.fontEastAsia,
              'fontCs': value.fontCs,
              'bold': value.bold,
              'boldCs': value.boldCs,
              'italic': value.italic,
              'underline': value.underline,
              'strike': value.strike,
              'caps': value.caps,
              'smallCaps': value.smallCaps,
              'sizeHalfPoints': value.sizeHalfPoints,
              'color': value.color,
              'highlight': value.highlight,
              'shading': _shadingToJson(value.shading),
              'vertAlign': value.vertAlign,
              'spacingTwips': value.spacingTwips,
            };

  static WpRunProperties? _runPropertiesFromJson(dynamic value) {
    final map = _asMap(value);
    if (map == null) return null;
    return WpRunProperties(
      styleId: map['styleId'] as String?,
      fontAscii: map['fontAscii'] as String?,
      fontHAnsi: map['fontHAnsi'] as String?,
      fontEastAsia: map['fontEastAsia'] as String?,
      fontCs: map['fontCs'] as String?,
      bold: map['bold'] as bool?,
      boldCs: map['boldCs'] as bool?,
      italic: map['italic'] as bool?,
      underline: map['underline'] as String?,
      strike: map['strike'] as bool?,
      caps: map['caps'] as bool?,
      smallCaps: map['smallCaps'] as bool?,
      sizeHalfPoints: (map['sizeHalfPoints'] as num?)?.toInt(),
      color: map['color'] as String?,
      highlight: map['highlight'] as String?,
      shading: _shadingFromJson(map['shading']),
      vertAlign: map['vertAlign'] as String?,
      spacingTwips: (map['spacingTwips'] as num?)?.toInt(),
    );
  }

  static Map<String, dynamic>? _paragraphAttributesToJson(
      WpParagraphAttributes? value) {
    if (value == null || value.isEmpty) return null;
    return {
      'paraId': value.paraId,
      'textId': value.textId,
      if (value.revisionIds.isNotEmpty)
        'revisionIds': {
          for (final name in WpParagraphAttributes.revisionAttributeNames)
            if (value.revisionIds[name] != null) name: value.revisionIds[name],
        },
    };
  }

  static WpParagraphAttributes? _paragraphAttributesFromJson(dynamic value) {
    final word = _asMap(value);
    final map = _asMap(word?['paragraphAttributes']);
    if (map == null) return null;
    final rawRevisionIds = _asMap(map['revisionIds']);
    final revisionIds = <String, String>{};
    for (final name in WpParagraphAttributes.revisionAttributeNames) {
      final revision = rawRevisionIds?[name];
      if (revision is String) revisionIds[name] = revision;
    }
    final result = WpParagraphAttributes(
      paraId: map['paraId'] as String?,
      textId: map['textId'] as String?,
      revisionIds: revisionIds,
    );
    return result.isEmpty ? null : result;
  }

  static Map<String, dynamic>? _paragraphWordToJson(WpParagraph paragraph) {
    final result =
        _paragraphPropertiesToJson(paragraph.properties) ?? <String, dynamic>{};
    final attributes = _paragraphAttributesToJson(paragraph.attributes);
    if (attributes != null) result['paragraphAttributes'] = attributes;
    return result.isEmpty ? null : result;
  }

  static Map<String, dynamic>? _paragraphPropertiesToJson(
      WpParagraphProperties? value) {
    if (value == null) return null;
    return {
      'styleId': value.styleId,
      if (value.numPr != null)
        'numPr': {
          'numId': value.numPr!.numId,
          if (value.numPr!.hasIlvl) 'ilvl': value.numPr!.ilvl,
        },
      'jc': value.jc,
      if (value.spacing != null)
        'spacing': {
          'beforeTwips': value.spacing!.beforeTwips,
          'afterTwips': value.spacing!.afterTwips,
          'line': value.spacing!.line,
          'lineRule': value.spacing!.lineRule,
        },
      if (value.indent != null)
        'indent': {
          'leftTwips': value.indent!.leftTwips,
          'rightTwips': value.indent!.rightTwips,
          'firstLineTwips': value.indent!.firstLineTwips,
          'hangingTwips': value.indent!.hangingTwips,
        },
      if (value.tabs != null)
        'tabs': [
          for (final tab in value.tabs!)
            {'val': tab.val, 'posTwips': tab.posTwips, 'leader': tab.leader}
        ],
      'shading': _shadingToJson(value.shading),
      'borders': _bordersToJson(value.borders),
      'keepNext': value.keepNext,
      'keepLines': value.keepLines,
      'pageBreakBefore': value.pageBreakBefore,
      'widowControl': value.widowControl,
      'contextualSpacing': value.contextualSpacing,
      'autoSpaceDN': value.autoSpaceDN,
      'suppressAutoHyphens': value.suppressAutoHyphens,
      'outlineLvl': value.outlineLvl,
      'markRunProperties': _runPropertiesToJson(value.markRunProperties),
      if (value.sectionBreak?.sourceXml != null)
        'sectionBreakXml': value.sectionBreak!.sourceXml,
    };
  }

  static WpParagraphProperties? _paragraphPropertiesFromJson(dynamic value) {
    final map = _asMap(value);
    if (map == null) return null;
    final numPrMap = _asMap(map['numPr']);
    final spacing = _asMap(map['spacing']);
    final indent = _asMap(map['indent']);
    final tabs = map['tabs'];
    final sectionXml = map['sectionBreakXml'];
    return WpParagraphProperties(
      styleId: map['styleId'] as String?,
      numPr: numPrMap == null
          ? null
          : WpNumPr(
              numId: (numPrMap['numId'] as num?)?.toInt(),
              ilvl: (numPrMap['ilvl'] as num?)?.toInt(),
            ),
      jc: map['jc'] as String?,
      spacing: spacing == null
          ? null
          : WpSpacing(
              beforeTwips: (spacing['beforeTwips'] as num?)?.toInt(),
              afterTwips: (spacing['afterTwips'] as num?)?.toInt(),
              line: (spacing['line'] as num?)?.toInt(),
              lineRule: spacing['lineRule'] as String?,
            ),
      indent: indent == null
          ? null
          : WpIndent(
              leftTwips: (indent['leftTwips'] as num?)?.toInt(),
              rightTwips: (indent['rightTwips'] as num?)?.toInt(),
              firstLineTwips: (indent['firstLineTwips'] as num?)?.toInt(),
              hangingTwips: (indent['hangingTwips'] as num?)?.toInt(),
            ),
      tabs: tabs is List
          ? [
              for (final raw in tabs)
                if (_asMap(raw) case final tab?)
                  WpTabStop(
                    val: '${tab['val'] ?? 'left'}',
                    posTwips: (tab['posTwips'] as num?)?.toInt() ?? 0,
                    leader: tab['leader'] as String?,
                  )
            ]
          : null,
      shading: _shadingFromJson(map['shading']),
      borders: _bordersFromJson(map['borders']),
      keepNext: map['keepNext'] as bool?,
      keepLines: map['keepLines'] as bool?,
      pageBreakBefore: map['pageBreakBefore'] as bool?,
      widowControl: map['widowControl'] as bool?,
      contextualSpacing: map['contextualSpacing'] as bool?,
      autoSpaceDN: map['autoSpaceDN'] as bool?,
      suppressAutoHyphens: map['suppressAutoHyphens'] as bool?,
      outlineLvl: (map['outlineLvl'] as num?)?.toInt(),
      markRunProperties: _runPropertiesFromJson(map['markRunProperties']),
      sectionBreak: sectionXml is String
          ? WpSectionProperties(sourceXml: sectionXml)
          : null,
    );
  }

  static WpParagraphProperties? _paragraphPropertiesWithPresentation(
      WpParagraphProperties? base, dynamic rawStyle, dynamic rawAlign) {
    final json = _paragraphPropertiesToJson(base) ?? <String, dynamic>{};
    final style = _asMap(rawStyle);
    final align = style?['align'] ?? rawAlign;
    if (align is String) {
      json['jc'] = switch (align) {
        'justify' => 'both',
        'right' => 'right',
        'center' => 'center',
        _ => 'left',
      };
    }
    if (style != null) {
      final indent = (_asMap(json['indent']) ?? <String, dynamic>{});
      var touchedIndent = false;
      for (final (styleKey, wordKey) in const [
        ('indentTwips', 'leftTwips'),
        ('rightIndentTwips', 'rightTwips'),
        ('firstLineIndentTwips', 'firstLineTwips'),
      ]) {
        final value = style[styleKey];
        if (value is num) {
          indent[wordKey] = value.toInt();
          touchedIndent = true;
        }
      }
      if (touchedIndent) json['indent'] = indent;
      final spacing = (_asMap(json['spacing']) ?? <String, dynamic>{});
      var touchedSpacing = false;
      for (final (styleKey, wordKey) in const [
        ('spaceBeforeTwips', 'beforeTwips'),
        ('spaceAfterTwips', 'afterTwips'),
        ('lineTwips', 'line'),
      ]) {
        final value = style[styleKey];
        if (value is num) {
          spacing[wordKey] = value.toInt();
          touchedSpacing = true;
        }
      }
      if (style['lineRule'] is String) {
        spacing['lineRule'] = style['lineRule'];
        touchedSpacing = true;
      }
      if (touchedSpacing) json['spacing'] = spacing;
      for (final key in const [
        'keepNext',
        'keepLines',
        'pageBreakBefore',
        'widowControl',
      ]) {
        if (style[key] is bool) json[key] = style[key];
      }
    }
    return json.isEmpty ? null : _paragraphPropertiesFromJson(json);
  }

  static WpParagraphProperties _copyParagraphProperties(
      WpParagraphProperties? value,
      {String? styleId}) {
    final json = _paragraphPropertiesToJson(value) ?? <String, dynamic>{};
    json['styleId'] = styleId;
    return _paragraphPropertiesFromJson(json)!;
  }

  static Map<String, dynamic>? _tablePropertiesToJson(
          WpTableProperties? value) =>
      value == null
          ? null
          : {
              'styleId': value.styleId,
              'width': _widthToJson(value.width),
              'jc': value.jc,
              'borders': _bordersToJson(value.borders),
              'indentTwips': value.indentTwips,
              'layout': value.layout,
              'cellMargins': _cellMarginsToJson(value.cellMargins),
              'tableLookXml': value.tableLookXml,
            };

  static WpTableProperties? _tablePropertiesFromJson(dynamic value) {
    final map = _asMap(value);
    if (map == null) return null;
    return WpTableProperties(
      styleId: map['styleId'] as String?,
      width: _widthFromJson(map['width']),
      jc: map['jc'] as String?,
      borders: _bordersFromJson(map['borders']),
      indentTwips: (map['indentTwips'] as num?)?.toInt(),
      layout: map['layout'] as String?,
      cellMargins: _cellMarginsFromJson(map['cellMargins']),
      tableLookXml: map['tableLookXml'] as String?,
    );
  }

  static List<Map<String, dynamic>> _tableChildOrderToJson(
          List<WpTableChildToken> value) =>
      [
        for (final token in value)
          {
            'kind': token.kind.name,
            if (token.qname != null) 'qname': token.qname,
            if (token.xml != null) 'xml': token.xml,
          }
      ];

  static List<WpTableChildToken> _tableChildOrderFromJson(dynamic value) {
    final map = _asMap(value);
    final raw = map?['childOrder'];
    if (raw is! List) return const [];
    final result = <WpTableChildToken>[];
    for (final item in raw) {
      final token = _asMap(item);
      switch (token?['kind']) {
        case 'properties':
          result.add(const WpTableChildToken.properties());
        case 'grid':
          result.add(const WpTableChildToken.grid());
        case 'row':
          result.add(const WpTableChildToken.row());
        case 'preserved':
          final qname = token?['qname'];
          final xml = token?['xml'];
          if (qname is String && xml is String) {
            result.add(WpTableChildToken.preserved(qname, xml));
          }
      }
    }
    return result;
  }

  static Map<String, dynamic>? _tableRowPropertiesToJson(
          WpTableRowProperties? value) =>
      value == null
          ? null
          : {
              'heightTwips': value.heightTwips,
              'heightRule': value.heightRule,
              'tblHeader': value.tblHeader,
              'cantSplit': value.cantSplit,
              'gridBefore': value.gridBefore,
              'gridAfter': value.gridAfter,
              'widthBefore': _widthToJson(value.widthBefore),
              'widthAfter': _widthToJson(value.widthAfter),
              'jc': value.jc,
            };

  static WpTableRowProperties? _tableRowPropertiesFromJson(dynamic value) {
    final map = _asMap(value);
    if (map == null) return null;
    return WpTableRowProperties(
      heightTwips: (map['heightTwips'] as num?)?.toInt(),
      heightRule: map['heightRule'] as String?,
      tblHeader: map['tblHeader'] == true,
      cantSplit: map['cantSplit'] == true,
      gridBefore: (map['gridBefore'] as num?)?.toInt(),
      gridAfter: (map['gridAfter'] as num?)?.toInt(),
      widthBefore: _widthFromJson(map['widthBefore']),
      widthAfter: _widthFromJson(map['widthAfter']),
      jc: map['jc'] as String?,
    );
  }

  static Map<String, dynamic>? _tableCellPropertiesToJson(
          WpTableCellProperties? value) =>
      value == null
          ? null
          : {
              'width': _widthToJson(value.width),
              'gridSpan': value.gridSpan,
              'vMerge': value.vMerge,
              'borders': _bordersToJson(value.borders),
              'shading': _shadingToJson(value.shading),
              'vAlign': value.vAlign,
              'margins': _cellMarginsToJson(value.margins),
              'noWrap': value.noWrap,
              'hideMark': value.hideMark,
            };

  static WpTableCellProperties? _tableCellPropertiesFromJson(dynamic value) {
    final map = _asMap(value);
    if (map == null) return null;
    return WpTableCellProperties(
      width: _widthFromJson(map['width']),
      gridSpan: (map['gridSpan'] as num?)?.toInt(),
      vMerge: map['vMerge'] as String?,
      borders: _bordersFromJson(map['borders']),
      shading: _shadingFromJson(map['shading']),
      vAlign: map['vAlign'] as String?,
      margins: _cellMarginsFromJson(map['margins']),
      noWrap: map['noWrap'] as bool?,
      hideMark: map['hideMark'] as bool?,
    );
  }

  /// Exporta um `.docx` de um documento CRIADO NO EDITOR — sem pacote de
  /// origem para preservar.
  ///
  /// É o caminho da aba Arquivo para documento novo: parte do pacote mínimo
  /// (`DocxFile.createEmpty`) e serializa cada bloco da árvore. Quando o
  /// documento veio de um DOCX importado, o caminho certo continua sendo
  /// [exportEdited], que preserva o que não foi tocado.
  Uint8List exportDocument(PMNode doc, {PageSetupTwips? pageSetup}) {
    final empty = DocxReader.createEmpty();
    _activeFile = empty;
    _prepareDrawingExport(empty);
    _generatedListNumIds.clear();
    final blocks = <WpBlock>[
      for (var i = 0; i < doc.childCount; i++) _nodeToBlock(doc.child(i))
    ];
    return DocxWriter.write(DocxFile(
      package: empty.package,
      document: WpDocumentModel(
        body: blocks,
        section: _sectionWithPageSetup(
          empty.document.section,
          pageSetup,
          preserveExistingAncillary: false,
        ),
      ),
      styles: empty.styles,
      numbering: empty.numbering,
      settings: empty.settings,
      mainPartName: empty.mainPartName,
      documentBodyPrefix: empty.documentBodyPrefix,
      documentBodySuffix: empty.documentBodySuffix,
      headersByType: empty.headersByType,
      footersByType: empty.footersByType,
      fidelityNotes: const [],
    ));
  }

  // -- corpo -----------------------------------------------------------------

  /// Um bloco Word vira nó editável, ou `null` quando ainda não sabemos
  /// representá-lo — e nesse caso ele continua vivo nas partes opacas.
  PMNode? _blockToNode(
      WpBlock block, OfficeCompatibilityReport report, String nodeId,
      {required String fromPart}) {
    switch (block) {
      case WpParagraph():
        return _paragraphToNode(block, nodeId, report, fromPart);
      case WpTable():
        return _tableToNode(block, report, nodeId, fromPart);
      case WpPreservedBlock():
        report.add('docx-block-opaque', 'bloco ${block.qname} preservado');
        return schema.node('opaque', {
          officeIdAttribute: nodeId,
          'insert': {'officeXml': block.xml, 'qname': block.qname},
        });
    }
  }

  PMNode _tableToNode(WpTable table, OfficeCompatibilityReport report,
      String nodeId, String fromPart) {
    final rows = <PMNode>[];
    for (var r = 0; r < table.rows.length; r++) {
      final sourceRow = table.rows[r];
      final cells = <PMNode>[];
      for (var c = 0; c < sourceRow.cells.length; c++) {
        final sourceCell = sourceRow.cells[c];
        final blocks = <PMNode>[];
        for (var b = 0; b < sourceCell.blocks.length; b++) {
          final converted = _blockToNode(
            sourceCell.blocks[b],
            report,
            '$nodeId-r$r-c$c-b$b',
            fromPart: fromPart,
          );
          if (converted != null) {
            blocks.add(_cellBlockWithSource(converted, b));
          }
        }
        cells.add(_tableCellToNode(
          sourceCell,
          sourceRow,
          blocks,
          nodeId,
          r,
          c,
        ));
      }
      rows.add(_tableRowToNode(sourceRow, cells, nodeId, r));
    }
    return _tableFromRows(table, rows, nodeId);
  }

  /// Versão cooperativa da tabela. Parágrafos continuam sendo convertidos
  /// sincronicamente dentro de uma fatia, enquanto linhas/células e tabelas
  /// aninhadas compartilham o mesmo relógio e devolvem o event loop quando o
  /// orçamento expira.
  Future<PMNode> _tableToNodeAsync(
    WpTable table,
    OfficeCompatibilityReport report,
    String nodeId,
    String fromPart,
    _CooperativeImportClock clock,
  ) async {
    final rows = <PMNode>[];
    for (var r = 0; r < table.rows.length; r++) {
      if (clock.expired) await clock.yieldNow();
      final sourceRow = table.rows[r];
      final cells = <PMNode>[];
      for (var c = 0; c < sourceRow.cells.length; c++) {
        if (clock.expired) await clock.yieldNow();
        final sourceCell = sourceRow.cells[c];
        final blocks = <PMNode>[];
        for (var b = 0; b < sourceCell.blocks.length; b++) {
          if (clock.expired) await clock.yieldNow();
          final sourceBlock = sourceCell.blocks[b];
          final childId = '$nodeId-r$r-c$c-b$b';
          final PMNode? converted;
          if (sourceBlock is WpTable) {
            converted = await _tableToNodeAsync(
              sourceBlock,
              report,
              childId,
              fromPart,
              clock,
            );
          } else {
            converted = _blockToNode(
              sourceBlock,
              report,
              childId,
              fromPart: fromPart,
            );
          }
          if (converted != null) {
            blocks.add(_cellBlockWithSource(converted, b));
          }
        }
        cells.add(_tableCellToNode(
          sourceCell,
          sourceRow,
          blocks,
          nodeId,
          r,
          c,
        ));
        if (clock.expired) await clock.yieldNow();
      }
      rows.add(_tableRowToNode(sourceRow, cells, nodeId, r));
      if (clock.expired) await clock.yieldNow();
    }
    return _tableFromRows(table, rows, nodeId);
  }

  /// Acrescenta a âncora granular do bloco dentro da célula.
  ///
  /// Os campos `source*` são metadados de preservação, não conteúdo do
  /// documento, e por isso são ignorados por [_semanticSignature]. Nós que
  /// não declaram `word` (o escape opaco) já carregam seu XML bruto em
  /// `insert` e não precisam desta âncora adicional.
  PMNode _cellBlockWithSource(PMNode node, int sourceBlockIndex) {
    if (!node.type.attrs.containsKey('word')) return node;
    final word = <String, dynamic>{
      ...?_asMap(node.attrs['word']),
      'sourceBlockIndex': sourceBlockIndex,
    };
    // sourceBlockIndex is one of the reserved preservation keys ignored by
    // semantic signatures.  When `word` is already a map, hashing [node] is
    // bit-identical to hashing a provisional clone with that key.  A null
    // `word`, however, emits a different token stream from a map containing
    // only an ignored key, so that edge case deliberately keeps the clone.
    final signatureNode = node.attrs['word'] is Map
        ? node
        : schema.node(
            node.type.name,
            {...node.attrs, 'word': word},
            node.content,
            node.marks,
          );
    final sourceSignature = _semanticSignature(signatureNode);
    final result = schema.node(
      node.type.name,
      {
        ...node.attrs,
        'word': {
          ...word,
          'sourceSignature': sourceSignature,
        },
      },
      node.content,
      node.marks,
    );
    _signatureContext?.aliasSemantic(result, signatureNode);
    return result;
  }

  PMNode _tableCellToNode(
    WpTableCell sourceCell,
    WpTableRow sourceRow,
    List<PMNode> blocks,
    String nodeId,
    int rowIndex,
    int cellIndex,
  ) {
    if (blocks.isEmpty) {
      blocks.add(schema.node(
          'paragraph',
          {
            officeIdAttribute: '$nodeId-r$rowIndex-c$cellIndex-empty',
          },
          Fragment.empty));
    }
    final tcPr = sourceCell.properties;
    final shadingFill = tcPr?.shading?.fill?.trim();
    final visibleShadingFill = shadingFill == null ||
            shadingFill.isEmpty ||
            shadingFill.toLowerCase() == 'auto'
        ? null
        : (shadingFill.startsWith('#') ? shadingFill : '#$shadingFill');
    final cellPresentation = <String, dynamic>{
      if (tcPr?.width?.value != null) 'widthTwips': tcPr!.width!.value,
      if (tcPr?.gridSpan != null) 'colspan': tcPr!.gridSpan,
      if (tcPr?.vMerge != null) 'vMerge': tcPr!.vMerge,
      if (tcPr?.vAlign != null) 'verticalAlign': tcPr!.vAlign,
      if (visibleShadingFill != null) 'background': visibleShadingFill,
    };
    final cellWord = <String, dynamic>{
      ...?_tableCellPropertiesToJson(tcPr),
      'sourceCellIndex': cellIndex,
    };
    final cellId = '$nodeId-r$rowIndex-c$cellIndex';
    final provisionalCell = schema.node(
      'tableCell',
      {
        officeIdAttribute: cellId,
        'cellId': cellId,
        'cell': cellPresentation.isEmpty ? null : cellPresentation,
        'tag': sourceRow.properties?.tblHeader == true ? 'th' : 'td',
        'word': cellWord,
      },
      Fragment.from(blocks),
    );
    final sourceSignature = _semanticSignature(provisionalCell);
    final result = schema.node(
      'tableCell',
      {
        ...provisionalCell.attrs,
        'word': {
          ...cellWord,
          'sourceSignature': sourceSignature,
        },
      },
      provisionalCell.content,
    );
    _signatureContext?.aliasSemantic(result, provisionalCell);
    return result;
  }

  PMNode _tableRowToNode(
    WpTableRow sourceRow,
    List<PMNode> cells,
    String nodeId,
    int rowIndex,
  ) {
    final rowWord = <String, dynamic>{
      ...?_tableRowPropertiesToJson(sourceRow.properties),
      'sourceRowIndex': rowIndex,
    };
    final provisionalRow = schema.node(
      'tableRow',
      {
        officeIdAttribute: '$nodeId-r$rowIndex',
        'rowId': '$nodeId-r$rowIndex',
        'word': rowWord,
      },
      Fragment.from(cells),
    );
    final sourceSignature = _semanticSignature(provisionalRow);
    final result = schema.node(
      'tableRow',
      {
        ...provisionalRow.attrs,
        'word': {
          ...rowWord,
          'sourceSignature': sourceSignature,
        },
      },
      provisionalRow.content,
    );
    _signatureContext?.aliasSemantic(result, provisionalRow);
    return result;
  }

  PMNode _tableFromRows(WpTable table, List<PMNode> rows, String nodeId) {
    final tableWord = <String, dynamic>{
      ...?_tablePropertiesToJson(table.properties),
      if (table.childOrder.isNotEmpty)
        'childOrder': _tableChildOrderToJson(table.childOrder),
    };
    return schema.node(
      'table',
      {
        officeIdAttribute: nodeId,
        'colWidths': table.gridColumnsTwips,
        'word': tableWord.isEmpty ? null : tableWord,
      },
      Fragment.from(rows),
    );
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
    final effectiveStyleId =
        paragraph.properties?.styleId ?? styles?.defaultOf('paragraph')?.id;
    final pPr = _effectiveParagraphProperties(paragraph.properties);
    final settings = _activeFile?.settings;
    final autoHyphenation =
        settings?.autoHyphenation == true && pPr?.suppressAutoHyphens != true;
    var rPr = _paragraphRunProperties(effectiveStyleId);
    // With no visible run, Word derives the blank line box from the paragraph
    // mark (`pPr/rPr`). Ignoring it made the 5 pt/10 pt spacer paragraphs in
    // the production TR/ETP fall back to Normal 12 pt and shifted the first
    // tables by up to a full text line. Runs keep their existing cascade; the
    // mark override is deliberately limited to text-empty paragraphs.
    final markRunProperties = paragraph.properties?.markRunProperties;
    if (paragraph.text.isEmpty && markRunProperties != null) {
      rPr = _effectiveRunProperties(rPr, markRunProperties);
    }
    final size = rPr?.sizeHalfPoints;
    final spacing = pPr?.spacing;
    final numPr = pPr?.numPr;
    final numberingIndent = numPr?.numId == null || numPr!.numId == 0
        ? null
        : _activeFile?.numbering.levelOf(numPr.numId!, numPr.ilvl)?.indent;
    WpIndent? indent = pPr?.indent;
    if (numberingIndent != null) {
      indent =
          indent == null ? numberingIndent : numberingIndent.mergedWith(indent);
    }
    return {
      if (size != null) 'sizePt': size / 2.0,
      if (rPr?.bold != null) 'bold': rPr!.bold,
      if (rPr?.fontAscii != null || rPr?.fontHAnsi != null)
        'family': rPr!.fontAscii ?? rPr.fontHAnsi,
      if (pPr?.jc != null) 'align': _alignOf(pPr!.jc!),
      if (indent?.leftTwips != null) 'indentTwips': indent!.leftTwips,
      if (indent?.rightTwips != null) 'rightIndentTwips': indent!.rightTwips,
      if (indent?.firstLineTwips != null)
        'firstLineIndentTwips': indent!.firstLineTwips,
      if (indent?.hangingTwips != null)
        'firstLineIndentTwips': -indent!.hangingTwips!,
      if (spacing?.beforeTwips != null)
        'spaceBeforeTwips': spacing!.beforeTwips,
      if (spacing?.afterTwips != null) 'spaceAfterTwips': spacing!.afterTwips,
      if (spacing?.line != null) 'lineTwips': spacing!.line,
      if (spacing?.lineRule != null) 'lineRule': spacing!.lineRule,
      if (pPr?.tabs != null)
        'tabs': [
          for (final tab in pPr!.tabs!)
            {
              'val': tab.val,
              'posTwips': tab.posTwips,
              if (tab.leader != null) 'leader': tab.leader,
            }
        ],
      if (pPr?.keepNext != null) 'keepNext': pPr!.keepNext,
      if (pPr?.keepLines != null) 'keepLines': pPr!.keepLines,
      if (pPr?.pageBreakBefore != null) 'pageBreakBefore': pPr!.pageBreakBefore,
      if (pPr?.widowControl != null) 'widowControl': pPr!.widowControl,
      if (pPr?.contextualSpacing != null)
        'contextualSpacing': pPr!.contextualSpacing,
      if (autoHyphenation) 'autoHyphenation': true,
      if (autoHyphenation)
        'hyphenationZoneTwips': settings!.hyphenationZoneTwips,
      if (effectiveStyleId != null) 'wordStyleId': effectiveStyleId,
    };
  }

  WpParagraphProperties? _effectiveParagraphProperties(
      WpParagraphProperties? direct) {
    final styles = _styles;
    if (styles == null) return direct;
    WpParagraphProperties? result = styles.docDefaultsParagraph;
    final styleId = direct?.styleId ?? styles.defaultOf('paragraph')?.id;
    for (final style in _styleChain(styleId, styles)) {
      final value = style.paragraphProperties;
      if (value != null) {
        result = result == null ? value : result.mergedWith(value);
      }
    }
    if (direct != null) {
      result = result == null ? direct : result.mergedWith(direct);
    }
    return result;
  }

  WpRunProperties? _paragraphRunProperties(String? paragraphStyleId) {
    final styles = _styles;
    if (styles == null) return null;
    WpRunProperties? result = styles.docDefaultsRun;
    for (final style in _styleChain(paragraphStyleId, styles)) {
      final value = style.runProperties;
      if (value != null)
        result = result == null ? value : result.mergedWith(value);
    }
    return result;
  }

  WpRunProperties? _effectiveRunProperties(
      WpRunProperties? paragraphBase, WpRunProperties? direct) {
    WpRunProperties? result = paragraphBase;
    final styles = _styles;
    if (styles != null && direct?.styleId != null) {
      for (final style in _styleChain(direct!.styleId, styles)) {
        final value = style.runProperties;
        if (value != null) {
          result = result == null ? value : result.mergedWith(value);
        }
      }
    }
    if (direct != null) {
      result = result == null ? direct : result.mergedWith(direct);
    }
    return result;
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

  PMNode _paragraphToNode(WpParagraph paragraph, String nodeId,
      OfficeCompatibilityReport report, String fromPart) {
    final inline = <PMNode>[];
    // Ausência de w:pStyle significa o estilo de parágrafo marcado como
    // w:default="1" (normalmente `Normal`), não apenas docDefaults. A
    // apresentação do bloco já seguia essa regra; os marks dos runs também
    // precisam da mesma base ou acabam sobrescrevendo-a com a fonte de
    // docDefaults (Times no ETP real).
    final baseRun = _paragraphRunProperties(
      paragraph.properties?.styleId ?? _styles?.defaultOf('paragraph')?.id,
    );
    final fieldStack = <_FieldProjectionState>[];
    var textBoxIndex = 0;

    void appendText(String value, List<Mark> marks) {
      if (value.isNotEmpty) inline.add(schema.text(value, marks));
    }

    void appendRunMarker(
      String qname,
      String xml,
      List<Mark> marks, {
      String? fieldMarker,
      String? fieldCommand,
    }) {
      inline.add(schema.node(
          'opaqueInline',
          {
            'insert': {
              'qname': qname,
              'officeXml': xml,
              'runContent': true,
              if (fieldMarker != null) 'fieldMarker': fieldMarker,
              if (fieldCommand != null) 'fieldCommand': fieldCommand,
            }
          },
          null,
          marks));
    }

    String textRunContentXml(String value) {
      final preserve = value.trim() != value;
      return preserve
          ? '<w:t xml:space="preserve">${XmlEscape.text(value)}</w:t>'
          : '<w:t>${XmlEscape.text(value)}</w:t>';
    }

    String fieldCharXml(WpFieldChar value) =>
        value.rawXml ??
        '<w:fldChar w:fldCharType="${XmlEscape.attribute(value.fldCharType)}"/>';

    String instructionXml(WpInstrText value) =>
        value.rawXml ??
        '<w:instrText xml:space="preserve">${XmlEscape.text(value.text)}</w:instrText>';

    void appendRun(WpRun run, {String? link}) {
      final marks =
          _marksOf(run.properties, paragraphBase: baseRun, link: link);
      for (final content in run.content) {
        switch (content) {
          case WpText text:
            final field = fieldStack.lastOrNull;
            if (field != null && !field.inResult) {
              // Some producers put field-code text in w:t rather than
              // w:instrText. Keep it structural/invisible, but retain it in
              // the regenerated run sequence.
              field.instruction.write(text.text);
              appendRunMarker('w:t', textRunContentXml(text.text), marks,
                  fieldMarker: 'instruction');
            } else {
              appendText(text.text, marks);
            }
          case WpInstrText instruction:
            final field = fieldStack.lastOrNull;
            if (field != null && !field.inResult) {
              field.instruction.write(instruction.text);
            }
            appendRunMarker('w:instrText', instructionXml(instruction), marks,
                fieldMarker: 'instruction');
          case WpFieldChar char:
            final type = char.fldCharType.toLowerCase();
            switch (type) {
              case 'begin':
                appendRunMarker('w:fldChar', fieldCharXml(char), marks,
                    fieldMarker: 'begin');
                fieldStack.add(_FieldProjectionState());
              case 'separate':
                final field = fieldStack.lastOrNull;
                if (field != null) {
                  field
                    ..command = _fieldCommand(field.instruction.toString())
                    ..inResult = true;
                }
                appendRunMarker('w:fldChar', fieldCharXml(char), marks,
                    fieldMarker: 'separate', fieldCommand: field?.command);
              case 'end':
                appendRunMarker('w:fldChar', fieldCharXml(char), marks,
                    fieldMarker: 'end');
                if (fieldStack.isNotEmpty) fieldStack.removeLast();
              case _:
                appendRunMarker('w:fldChar', fieldCharXml(char), marks,
                    fieldMarker: type);
            }
          case WpDrawing drawing:
            final relId = drawing.embedRelId;
            final bytes = relId == null
                ? null
                : _activeFile!.imageBytes(relId, fromPart: fromPart);
            final contentType = relId == null
                ? null
                : _activeFile!.imageContentType(relId, fromPart: fromPart);
            if (bytes == null) {
              // `r:link` deliberately has no package bytes. Keeping the
              // drawing as a protected run atom means an edit to neighbouring
              // text cannot delete it or its still-live external relation.
              // The same fallback also avoids making an already unresolved
              // embedded drawing disappear merely because its paragraph was
              // regenerated.
              appendRunMarker('w:drawing', drawing.rawXml, marks);
              report.add(
                _drawingLinkRelId(drawing.rawXml) == null
                    ? 'docx-image-missing'
                    : 'docx-image-linked-opaque',
                'drawing sem bytes incorporados preservado em $fromPart',
              );
              continue;
            }
            if (contentType == null ||
                !contentType.toLowerCase().startsWith('image/')) {
              appendRunMarker('w:drawing', drawing.rawXml, marks);
              report.add('docx-image-content-type-missing',
                  'drawing sem MIME de imagem preservado em $fromPart');
              continue;
            }
            final width = drawing.widthEmu == null
                ? null
                : (drawing.widthEmu! / 635).round();
            final height = drawing.heightEmu == null
                ? null
                : (drawing.heightEmu! / 635).round();
            inline.add(schema.node('image', {
              'src': 'data:$contentType;base64,${base64Encode(bytes)}',
              'width': width,
              'height': height,
              'extra': {
                'wordDrawing': drawing.rawXml,
                'wordDrawingInline': drawing.isInline,
              },
            }));
          case WpTabChar _:
            appendText('\t', marks);
          case WpNoBreakHyphen _:
            appendText('-', marks);
          case WpBreak breakValue:
            // A page/column break is an inline atom in OOXML.  Promoting a
            // mid-paragraph page break to pPr/pageBreakBefore changes both
            // its position and its meaning on the next save.
            inline.add(schema.node(
                'hardBreak',
                {
                  'breakType': breakValue.breakType,
                },
                null,
                marks));
          case WpSymbol symbol:
            final code = int.tryParse(symbol.charHex ?? '', radix: 16);
            if (code != null) {
              inline.add(schema.text(_unicodeSymbol(code), marks));
            }
          case WpTextBox textBox:
            final text = textBox.blocks
                .whereType<WpParagraph>()
                .map((block) => block.text)
                .join('\n');
            final textBoxDoc = _textBoxDocument(
              textBox,
              '$nodeId-tb${textBoxIndex++}',
              report,
              fromPart,
            );
            int emuToTwips(int emu) => (emu / 635).round();

            inline.add(schema.node(
                'textBox',
                {
                  'text': text,
                  'textBoxDoc': textBoxDoc?.toJSON(),
                  'textBoxSourceSignature': textBoxDoc == null
                      ? null
                      : OfficeDocxCodec.nodeSignature(textBoxDoc),
                  'width': textBox.extentCxEmu == null
                      ? null
                      : emuToTwips(textBox.extentCxEmu!),
                  'height': textBox.extentCyEmu == null
                      ? null
                      : emuToTwips(textBox.extentCyEmu!),
                  // Defaults definidos pelo DrawingML quando o produtor
                  // omite os atributos de wps:bodyPr: 0.1" nas laterais e
                  // 0.05" em cima/baixo. Snapshots antigos sem estes attrs
                  // continuam com o fallback de layout igual a zero.
                  'insetLeft': emuToTwips(textBox.insetLeftEmu ?? 91440),
                  'insetTop': emuToTwips(textBox.insetTopEmu ?? 45720),
                  'insetRight': emuToTwips(textBox.insetRightEmu ?? 91440),
                  'insetBottom': emuToTwips(textBox.insetBottomEmu ?? 45720),
                  'offsetX': textBox.offsetXEmu == null
                      ? null
                      : emuToTwips(textBox.offsetXEmu!),
                  'offsetY': textBox.offsetYEmu == null
                      ? null
                      : emuToTwips(textBox.offsetYEmu!),
                  'positionHAlign': textBox.positionHAlign,
                  'positionVRelativeFrom': textBox.positionVRelativeFrom,
                  'borderWidth': textBox.borderWidthEmu == null
                      ? null
                      : emuToTwips(textBox.borderWidthEmu!),
                  'borderColor': textBox.borderColorHex == null
                      ? null
                      : '#${textBox.borderColorHex}',
                  'background': textBox.fillColorHex == null
                      ? null
                      : '#${textBox.fillColorHex}',
                  'wrapMode': textBox.wrapMode,
                  'wrapSide': textBox.wrapSide,
                  'wrapDistLeft': textBox.wrapDistLeftEmu == null
                      ? null
                      : emuToTwips(textBox.wrapDistLeftEmu!),
                  'wrapDistTop': textBox.wrapDistTopEmu == null
                      ? null
                      : emuToTwips(textBox.wrapDistTopEmu!),
                  'wrapDistRight': textBox.wrapDistRightEmu == null
                      ? null
                      : emuToTwips(textBox.wrapDistRightEmu!),
                  'wrapDistBottom': textBox.wrapDistBottomEmu == null
                      ? null
                      : emuToTwips(textBox.wrapDistBottomEmu!),
                  'word': textBox.rawXml,
                },
                null,
                marks));
          case WpPreservedRunContent preserved:
            inline.add(schema.node(
                'opaqueInline',
                {
                  'insert': {
                    'qname': preserved.qname,
                    'officeXml': preserved.xml,
                    'runContent': true,
                    if (_validatedRenderedPageBreaks &&
                        preserved.qname == 'w:lastRenderedPageBreak')
                      'renderedPageBreakHint': true,
                  }
                },
                null,
                marks));
        }
      }
    }

    void appendSimpleField(WpSimpleField field) {
      // fldSimple is normalized to the equivalent complex sequence. This
      // gives every boundary its own protected PM atom while leaving the
      // cached result as ordinary editable text.
      final properties = field.runs.firstOrNull?.properties;
      final beginXml = StringBuffer('<w:fldChar w:fldCharType="begin"');
      if (field.fieldLockValue != null) {
        beginXml.write(
            ' w:fldLock="${XmlEscape.attribute(field.fieldLockValue!)}"');
      }
      if (field.dirtyValue != null) {
        beginXml.write(' w:dirty="${XmlEscape.attribute(field.dirtyValue!)}"');
      }
      beginXml.write('/>');
      appendRun(WpRun(
          properties: properties,
          content: [WpFieldChar('begin', rawXml: beginXml.toString())]));
      appendRun(WpRun(
          properties: properties, content: [WpInstrText(field.instruction)]));
      appendRun(
          WpRun(properties: properties, content: [WpFieldChar('separate')]));
      for (final run in field.runs) {
        appendRun(run);
      }
      appendRun(WpRun(properties: properties, content: [WpFieldChar('end')]));
    }

    for (final child in paragraph.inlines) {
      switch (child) {
        case WpRun run:
          appendRun(run);
        case WpHyperlink link:
          final href = link.anchor != null
              ? '#${link.anchor}'
              : link.relId == null
                  ? null
                  : _activeFile?.hyperlinkUrl(link.relId!, fromPart: fromPart);
          for (final run in link.runs) {
            appendRun(run, link: href);
          }
        case WpSimpleField field:
          appendSimpleField(field);
        case WpPreservedInline preserved:
          inline.add(schema.node('opaqueInline', {
            'insert': {
              'qname': preserved.qname,
              'officeXml': preserved.xml,
            }
          }));
      }
    }
    final effectiveParagraph =
        _effectiveParagraphProperties(paragraph.properties);
    final outline = effectiveParagraph?.outlineLvl;
    final level = _headingLevelOf(paragraph.properties?.styleId) ??
        (outline != null && outline >= 0 && outline < 6 ? outline + 1 : null);
    final listNumPr = effectiveParagraph?.numPr;
    final listKind = _listKindOf(listNumPr);
    final presentation = _resolvePresentation(paragraph);
    // O rótulo é PROJEÇÃO: vai para `style.marker`, não para o texto. Se
    // virasse texto, editar o parágrafo o corromperia e salvar gravaria o
    // número literal por cima da numeração automática do Word.
    final label = _counter?.labelFor(WpParagraph(
      properties: effectiveParagraph,
      inlines: paragraph.inlines,
    ));
    final markerSuffix = listNumPr?.numId == null || listNumPr!.numId == 0
        ? null
        : _activeFile?.numbering
            .levelOf(listNumPr.numId!, listNumPr.ilvl)
            ?.suffix;
    // O `sectPr` do parágrafo ENCERRA a seção corrente. Registrar aqui,
    // durante a travessia, é o que mantém a ORDEM das seções — e a ordem é
    // o que liga cada geometria ao trecho certo do documento.
    final sectionBreak = paragraph.properties?.sectionBreak;
    if (sectionBreak != null) _sectionBreaks.add(sectionBreak);

    final resolved = <String, dynamic>{
      ...?presentation,
      if (label != null && label.isNotEmpty) 'marker': label,
      if (label != null && label.isNotEmpty && markerSuffix != null)
        'markerSuffix': markerSuffix,
      if (_validatedRenderedPageBreakNodeIds.contains(nodeId))
        'renderedPageBreakBefore': true,
      if (sectionBreak != null) 'sectionBreak': true,
    };
    if (level != null) {
      return schema.node(
          'heading',
          {
            officeIdAttribute: nodeId,
            'level': level,
            'style': resolved.isEmpty ? null : resolved,
            'word': _paragraphWordToJson(paragraph),
          },
          Fragment.from(inline));
    }
    if (listKind != null) {
      return schema.node(
          'listItem',
          {
            officeIdAttribute: nodeId,
            'kind': listKind,
            'indent': listNumPr?.ilvl,
            'style': resolved.isEmpty ? null : resolved,
            'word': _paragraphWordToJson(paragraph),
          },
          Fragment.from(inline));
    }
    return schema.node(
        'paragraph',
        {
          officeIdAttribute: nodeId,
          'style': resolved.isEmpty ? null : resolved,
          'word': _paragraphWordToJson(paragraph),
        },
        Fragment.from(inline));
  }

  /// Converte o conteúdo interno de uma caixa de texto numa árvore PM
  /// destacada. Ela é uma projeção edit-ready, mas ainda não substitui o XML
  /// bruto no save: a regeneração segura do DrawingML pertence à etapa B.
  ///
  /// A travessia não pode avançar a numeração nem registrar seções do fluxo
  /// externo. Esses dois estados são deliberadamente isolados e restaurados.
  PMNode? _textBoxDocument(
    WpTextBox textBox,
    String nodeId,
    OfficeCompatibilityReport report,
    String fromPart,
  ) {
    if (textBox.blocks.isEmpty) return null;
    final outerCounter = _counter;
    final outerSectionCount = _sectionBreaks.length;
    _counter = null;
    try {
      final blocks = <PMNode>[];
      for (var i = 0; i < textBox.blocks.length; i++) {
        final block = _blockToNode(
          textBox.blocks[i],
          report,
          '$nodeId-b$i',
          fromPart: fromPart,
        );
        if (block != null) blocks.add(block);
      }
      return blocks.isEmpty
          ? null
          : schema.node('doc', null, Fragment.from(blocks));
    } finally {
      _counter = outerCounter;
      if (_sectionBreaks.length > outerSectionCount) {
        _sectionBreaks.removeRange(outerSectionCount, _sectionBreaks.length);
      }
    }
  }

  /// Semantic list kind for an OOXML numbering reference. Unknown custom
  /// formats remain ordered instead of silently becoming plain paragraphs;
  /// the original numPr/numbering part still carries the exact format.
  String? _listKindOf(WpNumPr? numPr) {
    final numId = numPr?.numId;
    if (numId == null || numId == 0) return null;
    final level = _activeFile?.numbering.levelOf(numId, numPr!.ilvl);
    if (level == null || level.numFmt == 'none') return null;
    return level.numFmt == 'bullet' ? 'bullet' : 'ordered';
  }

  List<Mark> _marksOf(WpRunProperties? properties,
      {WpRunProperties? paragraphBase, String? link}) {
    final effective = _effectiveRunProperties(paragraphBase, properties);
    if (effective == null && link == null) return const [];
    final marks = <Mark>[];
    void add(String name, bool? on) {
      if (on != true) return;
      final type = schema.marks[name];
      if (type != null) marks.add(type.create());
    }

    add('bold', effective?.bold);
    add('italic', effective?.italic);
    add('strike', effective?.strike);
    if (effective?.underline != null && effective!.underline != 'none') {
      final type = schema.marks['underline'];
      if (type != null) marks.add(type.create());
    }
    final family = effective?.fontAscii ?? effective?.fontHAnsi;
    if (family != null) {
      marks.add(schema.marks['font']!.create({'value': family}));
    }
    if (effective?.sizeHalfPoints != null) {
      marks.add(schema.marks['size']!
          .create({'value': '${effective!.sizeHalfPoints! / 2}pt'}));
    }
    if (effective?.spacingTwips != null) {
      marks.add(schema.marks['letterSpacing']!
          .create({'twips': effective!.spacingTwips}));
    }
    if (effective?.color != null && effective!.color != 'auto') {
      marks
          .add(schema.marks['color']!.create({'value': '#${effective.color}'}));
    }
    final background =
        effective?.shading?.fill ?? _highlightColor(effective?.highlight);
    if (background != null && background != 'auto') {
      marks.add(schema.marks['background']!.create({'value': '#$background'}));
    }
    if (effective?.vertAlign != null && effective!.vertAlign != 'baseline') {
      marks.add(schema.marks['script']!.create({
        'value': effective.vertAlign == 'superscript' ? 'super' : 'sub',
      }));
    }
    if (link != null && link.isNotEmpty) {
      marks.add(schema.marks['link']!.create({'href': link}));
    }
    final opaque = <String, dynamic>{
      if (effective?.styleId != null) 'wordStyleId': effective!.styleId,
      if (effective?.caps != null) 'wordCaps': effective!.caps,
      if (effective?.smallCaps != null) 'wordSmallCaps': effective!.smallCaps,
      if (effective?.highlight != null) 'wordHighlight': effective!.highlight,
      // Estes dois campos sao preservacao DIRETA do rPr do run. Usar
      // [effective] aqui materializaria valores herdados do estilo.
      if (properties?.fontEastAsia != null)
        'wordFontEastAsia': properties!.fontEastAsia,
      if (properties?.boldCs != null) 'wordBoldCs': properties!.boldCs,
    };
    if (opaque.isNotEmpty) {
      marks.add(schema.marks['opaqueAttrs']!.create({'attrs': opaque}));
    }
    return marks;
  }

  /// First field-code command, without substring heuristics. PAGE and
  /// NUMPAGES are dynamic; PAGEREF must remain a distinct command.
  static String? _fieldCommand(String instruction) {
    final match =
        RegExp(r'^\s*([A-Za-z][A-Za-z0-9_-]*)\b', caseSensitive: false)
            .firstMatch(instruction);
    return match?.group(1)?.toUpperCase();
  }

  static String? _highlightColor(String? value) => switch (value) {
        'yellow' => 'FFFF00',
        'green' => '00FF00',
        'cyan' => '00FFFF',
        'magenta' => 'FF00FF',
        'blue' => '0000FF',
        'red' => 'FF0000',
        'darkBlue' => '000080',
        'darkCyan' => '008080',
        'darkGreen' => '008000',
        'darkMagenta' => '800080',
        'darkRed' => '800000',
        'darkYellow' => '808000',
        'darkGray' => '808080',
        'lightGray' => 'C0C0C0',
        'black' => '000000',
        _ => null,
      };

  static String _unicodeSymbol(int code) => switch (code) {
        0xF0B7 || 0x00B7 => '•',
        0xF0A7 || 0x00A7 => '■',
        0xF06F || 0x006F => '○',
        0xF0FC => '✓',
        0xF0D8 => '➢',
        _ => String.fromCharCode(code),
      };

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

  static Future<Map<String, dynamic>> _nodeToJsonAsync(
      PMNode node, _CooperativeImportClock clock) async {
    Map<String, dynamic> jsonOf(PMNode value) {
      final json = <String, dynamic>{'type': value.type.name};
      if (value.attrs.isNotEmpty) json['attrs'] = value.attrs;
      if (value.childCount > 0) json['content'] = <dynamic>[];
      if (value.marks.isNotEmpty) {
        json['marks'] = [for (final mark in value.marks) mark.toJSON()];
      }
      final text = value.text;
      if (text != null) json['text'] = text;
      return json;
    }

    final root = jsonOf(node);
    final stack = <_NodeJsonFrame>[_NodeJsonFrame(node, root)];
    while (stack.isNotEmpty) {
      if (clock.expired) await clock.yieldNow();
      final frame = stack.last;
      if (frame.nextChild >= frame.node.childCount) {
        stack.removeLast();
        continue;
      }
      final child = frame.node.child(frame.nextChild++);
      final childJson = jsonOf(child);
      (frame.json['content'] as List<dynamic>).add(childJson);
      if (child.childCount > 0) {
        stack.add(_NodeJsonFrame(child, childJson));
      }
    }
    return root;
  }

  Future<String> _nodeSignatureAsync(
    PMNode node, {
    required bool ignoreSourceSignature,
    required _CooperativeImportClock clock,
  }) =>
      (_signatureContext ?? _SignatureContext()).signatureAsync(
        node,
        ignoreSourceSignature: ignoreSourceSignature,
        clock: clock,
      );

  String _nodeSignature(PMNode node) =>
      (_signatureContext ?? _SignatureContext()).signatureSync(
        node,
        ignoreSourceSignature: false,
      );

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
  static String nodeSignature(PMNode node) => _SignatureContext().signatureSync(
        node,
        ignoreSourceSignature: false,
      );

  String _semanticSignature(PMNode node) =>
      (_signatureContext ?? _SignatureContext()).signatureSync(
        node,
        ignoreSourceSignature: true,
      );
}
