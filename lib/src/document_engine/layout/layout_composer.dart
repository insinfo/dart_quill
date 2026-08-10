/// LayoutComposer — compõe o [PageGraph] a partir da árvore Office (Fase 5).
///
/// UM paginador, dois níveis de qualidade ([LayoutQuality]): `draft`
/// simplifica widow/orphan e tabelas; `fidelity` aplica as regras
/// completas. O documento, a seleção, os IDs e o snapshot NUNCA mudam com o
/// nível — só o refinamento do grafo.
///
/// Medição: [FontMetrics] embarcadas (as mesmas do exportador de PDF), a
/// autoridade de largura nas duas saídas — é o que garante que a linha do
/// editor e a do PDF quebram no mesmo lugar. O TextShaper (etapa 1:
/// latino/kerning/ligaturas) entra depois, atrás da mesma interface de
/// medição.
///
/// v1 cobre o perfil Quill: paragraph/heading/listItem/blockquote/codeBlock
/// com quebra por linha e fragmentação ENTRE páginas em granularidade de
/// LINHA (um parágrafo pode atravessar páginas — a limitação do exportador
/// Delta linear não existe aqui). Tabelas: granularidade de linha-de-tabela
/// no draft, com aviso; a fragmentação fina fica com o fidelity da Fase 6.
library;

import 'dart:collection';

import '../../office/document/fonts/font_metrics.dart';
import '../../office/document/fonts/font_registry.dart';
import '../model/index.dart';
import '../office/ids.dart';
import 'fonts.dart';
import 'page_graph.dart';

/// Converte pt→twips.
int _ptToTwips(double pt) => (pt * 20).round();

/// Cache bounded and safe to share between [LayoutComposer] instances.
///
/// The key stores the concrete measurement authority ([LayoutFontFace] or
/// [FontMetrics]), not just the family name. An application can therefore
/// reuse one cache while opening documents without accidentally carrying an
/// Arial fallback width into a subsequently loaded embedded font.
class LayoutMeasurementCache {
  LayoutMeasurementCache({
    this.maxEntries = 50000,
    this.maxTextLength = 256,
  })  : assert(maxEntries > 0),
        assert(maxTextLength > 0);

  final int maxEntries;

  /// Very long opaque tokens are deliberately not retained. Besides being
  /// rare in prose, keeping all their progressively split substrings can pin
  /// several megabytes in a long-lived editor.
  final int maxTextLength;

  final LinkedHashMap<_MeasurementKey, double> _values =
      LinkedHashMap<_MeasurementKey, double>();

  int get length => _values.length;

  void clear() => _values.clear();

  double? _lookup(_MeasurementKey key) {
    if (key.text.length > maxTextLength) return null;
    return _values[key];
  }

  void _store(_MeasurementKey key, double value) {
    if (key.text.length > maxTextLength) return;
    if (!_values.containsKey(key) && _values.length >= maxEntries) {
      _values.remove(_values.keys.first);
    }
    _values[key] = value;
  }
}

class _MeasurementKey {
  const _MeasurementKey({
    required this.authority,
    required this.sizePt,
    required this.letterSpacingTwips,
    required this.text,
  });

  /// Identity is intentional: two independently loaded faces or metric
  /// tables may use the same family name while having different advances.
  final Object authority;
  final double sizePt;
  final int letterSpacingTwips;
  final String text;

  @override
  bool operator ==(Object other) =>
      other is _MeasurementKey &&
      identical(authority, other.authority) &&
      sizePt == other.sizePt &&
      letterSpacingTwips == other.letterSpacingTwips &&
      text == other.text;

  @override
  int get hashCode => Object.hash(
        identityHashCode(authority),
        sizePt,
        letterSpacingTwips,
        text,
      );
}

/// Bounded cache for the expensive, page-independent part of table layout.
///
/// A table's rows are measured before pagination decides which rows belong on
/// each page.  Keeping that immutable base geometry lets an imported document
/// prepare very large tables in cooperative slices, then perform only the
/// comparatively cheap pagination in the synchronous editor mount.
class LayoutTableCache {
  LayoutTableCache({
    this.maxEntries = 64,
    this.maxRows = 10000,
  })  : assert(maxEntries > 0),
        assert(maxRows > 0);

  final int maxEntries;
  final int maxRows;

  final LinkedHashMap<_TableLayoutKey, _CachedTableLayout> _values =
      LinkedHashMap<_TableLayoutKey, _CachedTableLayout>();
  int _rowCount = 0;

  int get length => _values.length;
  int get rowCount => _rowCount;

  void clear() {
    _values.clear();
    _rowCount = 0;
  }

  _CachedTableLayout? _lookup(_TableLayoutKey key) => _values[key];

  void _store(_TableLayoutKey key, _CachedTableLayout value) {
    final rows = value.rows.length;
    if (rows > maxRows) return;
    final previous = _values.remove(key);
    if (previous != null) _rowCount -= previous.rows.length;
    while (_values.isNotEmpty &&
        (_values.length >= maxEntries || _rowCount + rows > maxRows)) {
      final oldest = _values.keys.first;
      _rowCount -= _values.remove(oldest)!.rows.length;
    }
    _values[key] = value;
    _rowCount += rows;
  }
}

class _TableLayoutKey {
  const _TableLayoutKey({
    required this.table,
    required this.tableDocPos,
    required this.availableTwips,
    required this.honorRenderedPageBreaks,
    required this.fontSignature,
    required this.baseFontFamily,
    required this.baseFontSizePt,
    required this.quality,
    required this.fontRegistryGeneration,
  });

  /// PM nodes and font sets are immutable. Identity therefore distinguishes
  /// both edits and independently loaded embedded faces without hashing a
  /// potentially multi-megabyte table on every lookup.
  final PMNode table;
  final int tableDocPos;
  final int availableTwips;
  final bool honorRenderedPageBreaks;
  final _FontSetSignature fontSignature;
  final String baseFontFamily;
  final double baseFontSizePt;
  final LayoutQuality quality;
  final int fontRegistryGeneration;

  @override
  bool operator ==(Object other) =>
      other is _TableLayoutKey &&
      identical(table, other.table) &&
      tableDocPos == other.tableDocPos &&
      availableTwips == other.availableTwips &&
      honorRenderedPageBreaks == other.honorRenderedPageBreaks &&
      fontSignature == other.fontSignature &&
      baseFontFamily == other.baseFontFamily &&
      baseFontSizePt == other.baseFontSizePt &&
      quality == other.quality &&
      fontRegistryGeneration == other.fontRegistryGeneration;

  @override
  int get hashCode => Object.hash(
        identityHashCode(table),
        tableDocPos,
        availableTwips,
        honorRenderedPageBreaks,
        fontSignature,
        baseFontFamily,
        baseFontSizePt,
        quality,
        fontRegistryGeneration,
      );
}

class _FontSetSignature {
  _FontSetSignature(LayoutFontSet fonts)
      : faces = List<LayoutFontFace>.unmodifiable(fonts.faces);

  final List<LayoutFontFace> faces;

  @override
  bool operator ==(Object other) {
    if (other is! _FontSetSignature || faces.length != other.faces.length) {
      return false;
    }
    for (var index = 0; index < faces.length; index++) {
      if (!identical(faces[index], other.faces[index])) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(faces.map<Object>(identityHashCode));
}

class _CachedTableLayout {
  _CachedTableLayout(List<TableRowBox> rows, List<String> warnings)
      : rows = List<TableRowBox>.unmodifiable(rows),
        warnings = List<String>.unmodifiable(warnings);

  final List<TableRowBox> rows;
  final List<String> warnings;
}

/// Shared cache for paragraph line boxes inside tables.
///
/// Editing one table cell rebuilds the immutable PM path up through its row
/// and table, but all other paragraph nodes retain identity. Reusing their
/// line boxes keeps an edit in a 1,367-row table proportional to the changed
/// cell instead of re-breaking every paragraph in the table.
class LayoutTableLineCache {
  LayoutTableLineCache({
    this.maxEntries = 10000,
    this.maxLines = 50000,
  })  : assert(maxEntries > 0),
        assert(maxLines > 0);

  final int maxEntries;
  final int maxLines;
  final LinkedHashMap<_TableLineKey, _CachedTableLines> _values =
      LinkedHashMap<_TableLineKey, _CachedTableLines>();
  int _lineCount = 0;
  int _hits = 0;

  int get length => _values.length;
  int get lineCount => _lineCount;
  int get hitCount => _hits;

  void clear() {
    _values.clear();
    _lineCount = 0;
    _hits = 0;
  }

  _CachedTableLines? _lookup(_TableLineKey key) {
    final value = _values[key];
    if (value != null) _hits++;
    return value;
  }

  void _store(_TableLineKey key, _CachedTableLines value) {
    final lines = value.lines.length;
    if (lines > maxLines) return;
    final previous = _values.remove(key);
    if (previous != null) _lineCount -= previous.lines.length;
    while (_values.isNotEmpty &&
        (_values.length >= maxEntries || _lineCount + lines > maxLines)) {
      final oldest = _values.keys.first;
      _lineCount -= _values.remove(oldest)!.lines.length;
    }
    _values[key] = value;
    _lineCount += lines;
  }
}

class _TableLineKey {
  const _TableLineKey({
    required this.block,
    required this.widthTwips,
    required this.honorRenderedPageBreaks,
    required this.fontSignature,
    required this.baseFontFamily,
    required this.baseFontSizePt,
    required this.fontRegistryGeneration,
  });

  final PMNode block;
  final int widthTwips;
  final bool honorRenderedPageBreaks;
  final _FontSetSignature fontSignature;
  final String baseFontFamily;
  final double baseFontSizePt;
  final int fontRegistryGeneration;

  @override
  bool operator ==(Object other) =>
      other is _TableLineKey &&
      identical(block, other.block) &&
      widthTwips == other.widthTwips &&
      honorRenderedPageBreaks == other.honorRenderedPageBreaks &&
      fontSignature == other.fontSignature &&
      baseFontFamily == other.baseFontFamily &&
      baseFontSizePt == other.baseFontSizePt &&
      fontRegistryGeneration == other.fontRegistryGeneration;

  @override
  int get hashCode => Object.hash(
        identityHashCode(block),
        widthTwips,
        honorRenderedPageBreaks,
        fontSignature,
        baseFontFamily,
        baseFontSizePt,
        fontRegistryGeneration,
      );
}

class _CachedTableLines {
  _CachedTableLines(List<LineBox> lines, List<String> warnings)
      : lines = List<LineBox>.unmodifiable(lines),
        warnings = List<String>.unmodifiable(warnings);

  final List<LineBox> lines;
  final List<String> warnings;
}

class LayoutComposer {
  /// A face e o corpo usados quando o documento não diz nada — a mesma
  /// referência que a ribbon precisa para mostrar a fonte EFETIVA de um
  /// parágrafo sem formatação explícita (um Delta do Quill, por exemplo).
  /// Constantes para que layout e chrome não divirjam em silêncio.
  static const String defaultBaseFontFamily = 'Arial';
  static const double defaultBaseFontSizePt = 12;

  LayoutComposer({
    this.setup = const PageSetupTwips(),
    this.quality = LayoutQuality.draft,
    this.baseFontFamily = defaultBaseFontFamily,
    this.baseFontSizePt = defaultBaseFontSizePt,
    LayoutFontSet? fonts,
    this.header,
    this.footer,
    this.headerVariants = const {},
    this.footerVariants = const {},
    this.titlePage = false,
    this.evenAndOddHeaders = false,
    this.sections = const [],
    LayoutMeasurementCache? measurementCache,
    LayoutTableCache? tableCache,
    LayoutTableLineCache? tableLineCache,
  })  : fonts = fonts ?? const LayoutFontSet([]),
        _measureCache = measurementCache ?? LayoutMeasurementCache(),
        _tableCache = tableCache ?? LayoutTableCache(),
        _tableLineCache = tableLineCache ?? LayoutTableLineCache();

  final PageSetupTwips setup;
  final LayoutQuality quality;
  final String baseFontFamily;
  final double baseFontSizePt;

  /// Faces embutidas: quando presentes, a medição usa a hmtx REAL da face —
  /// a mesma que o renderer embute — e as duas saídas quebram igual.
  final LayoutFontSet fonts;

  /// Geometrias por SEÇÃO, na ordem do documento.
  ///
  /// Vazio significa "uma seção só", que é `setup`. Com várias, um bloco
  /// que carrega `style.sectionBreak` ENCERRA a seção corrente: o OOXML
  /// coloca o `sectPr` no parágrafo que TERMINA a seção, não no que
  /// começa a seguinte — ler ao contrário aplicaria a geometria errada ao
  /// documento inteiro.
  ///
  /// Sem isto, um anexo em paisagem seria paginado em retrato na tela E no
  /// PDF, porque os dois consomem o mesmo grafo.
  final List<PageSetupTwips> sections;

  /// Regiões de cabeçalho/rodapé — árvores próprias, não parte do corpo.
  ///
  /// Elas repetem em todas as páginas, então NÃO entram no `positionMap`:
  /// uma posição do documento apontaria para N lugares, e o caret cairia
  /// num deles por sorteio.
  final PMNode? header;
  final PMNode? footer;

  /// Variantes OOXML (`default`, `first`, `even`) das regiões.
  ///
  /// [header]/[footer] continuam sendo a API simples para documentos
  /// criados no editor. Quando este mapa não está vazio, a variante é
  /// escolhida por página, respeitando `w:titlePg` e
  /// `w:evenAndOddHeaders`; uma referência `first` inativa não pode vazar
  /// para todas as páginas só por ser a primeira entrada do mapa.
  final Map<String, PMNode> headerVariants;
  final Map<String, PMNode> footerVariants;
  final bool titlePage;
  final bool evenAndOddHeaders;

  /// Campos substituídos por página. `PAGE` é o número da página atual e
  /// `NUMPAGES` o total — os dois únicos que praticamente todo ofício usa.
  static final RegExp _pageField = RegExp(r'\{(PAGE|NUMPAGES)\}');

  /// Regiões são nós imutáveis e se repetem por todas as páginas.  Guardar a
  /// presença de campos e os insets estáticos evita recompor, por exemplo, o
  /// mesmo cabeçalho de nove parágrafos 140 vezes apenas para descobrir a
  /// mesma exclusão vertical.
  final Map<PMNode, bool> _pageFieldCache = {};
  final Map<PMNode, Map<PageSetupTwips, int>> _staticHeaderInsetCache = {};
  final Map<PMNode, Map<PageSetupTwips, int>> _staticFooterInsetCache = {};

  /// Recuo por nível de lista, em twips (21,6 pt como o exportador linear).
  static const int _listIndentTwips = 432;

  PageGraph compose(
    PMNode doc, {
    bool honorRenderedPageBreaks = true,
    int? maxPages,
  }) =>
      _composeFrom(
        doc,
        honorRenderedPageBreaks: honorRenderedPageBreaks,
        stopAfterPages: maxPages,
      );

  /// Continua uma composição PARCIAL (paginação progressiva, estilo Word):
  /// as páginas já compostas são reusadas como estão e a composição retoma
  /// do bloco registrado em [PageGraph.resume]. Com [maxPages], para de novo
  /// na próxima fronteira limpa após esse total.
  PageGraph composeContinue(
    PMNode doc,
    PageGraph partial, {
    int? maxPages,
  }) {
    final resume = partial.resume;
    if (resume == null) return partial;
    return _composeFrom(
      doc,
      reusedPages: partial.pages,
      reusedEntries: partial.positionMap.entries,
      startBlockIndex: resume.blockIndex,
      startOffset: resume.offset,
      startListOrdinal: resume.listOrdinal,
      startSuppressSpaceBeforeAtPageTop: resume.suppressSpaceBeforeAtPageTop,
      honorRenderedPageBreaks: resume.honorRenderedPageBreaks,
      stopAfterPages: maxPages,
    );
  }

  /// Warms the typographic cache cooperatively before a large document is
  /// paginated on the browser main isolate.
  ///
  /// This performs no layout and cannot change the resulting [PageGraph]. It
  /// resolves the same run styles and word/space tokens used by [_breakLines]
  /// while yielding between short slices, so the subsequent synchronous
  /// pagination spends its critical task on geometry rather than repeated
  /// font measurement.
  Future<int> prewarmMeasurementsAsync(
    Iterable<PMNode> roots, {
    int sliceBudgetMicroseconds = 8000,
  }) async {
    assert(sliceBudgetMicroseconds > 0);
    final stack = <PMNode>[...roots];
    final slice = Stopwatch()..start();
    var cooperativeYields = 0;

    while (stack.isNotEmpty) {
      final node = stack.removeLast();
      if (node.isTextblock) {
        final blockStyle = _blockStyleOf(node, 0);
        final marker = blockStyle.marker;
        if (marker != null && marker.isNotEmpty) {
          _measurePt(_markerStyleOf(blockStyle), marker.trimRight());
        }
        for (var index = 0; index < node.childCount; index++) {
          final child = node.child(index);
          if (child.isText) {
            final style = _styleOfText(child, blockStyle);
            for (final match in RegExp(r'(\t)|([^\S\t]+)|([^\s]+)')
                .allMatches(child.text!)) {
              if (match.group(1) != null) continue;
              final piece = match.group(0)!;
              _measurePt(style, piece);
              if (_isHangingPunctuation(piece) && piece.length > 1) {
                _measurePt(style, piece.substring(0, piece.length - 1));
              }
            }
            if (blockStyle.autoHyphenation) _measurePt(style, '-');
          } else if (child.type.name == 'textBox') {
            final raw = child.attrs['textBoxDoc'];
            if (raw is Map<String, dynamic>) {
              try {
                stack.add(PMNode.fromJSON(child.type.schema, raw));
              } catch (_) {
                // The compositor records a diagnostic and falls back to
                // plain text for an invalid opaque text-box payload.
              }
            }
          }
        }
      }

      for (var index = node.childCount - 1; index >= 0; index--) {
        stack.add(node.child(index));
      }
      if (slice.elapsedMicroseconds >= sliceBudgetMicroseconds) {
        cooperativeYields++;
        await Future<void>.delayed(Duration.zero);
        slice.reset();
      }
    }
    return cooperativeYields;
  }

  /// Prepares the page-independent geometry of top-level tables in bounded
  /// browser tasks. The synchronous [compose] that follows reuses these rows
  /// and only performs pagination/splitting.
  ///
  /// [timings] receives microseconds (and integer counters) so callers can
  /// expose performance telemetry without putting a stopwatch in the layout
  /// hot path. Only complete builds are published to the cache.
  Future<int> prewarmTableLayoutsAsync(
    PMNode doc, {
    bool honorRenderedPageBreaks = true,
    int sliceBudgetMicroseconds = 8000,
    Map<String, int>? timings,
  }) async {
    assert(sliceBudgetMicroseconds > 0);
    var cooperativeYields = 0;
    var maxSliceMicroseconds = 0;
    var tableCount = 0;
    var rowCount = 0;
    var cacheHits = 0;
    var sectionIndex = 0;
    var activeSetup = sections.isEmpty ? setup : sections.first;
    var offset = 0;
    final slice = Stopwatch()..start();

    for (var index = 0; index < doc.childCount; index++) {
      final block = doc.child(index);
      final docPos = offset + 1;
      offset += block.nodeSize;
      if (block.type.name == 'table') {
        tableCount++;
        rowCount += block.childCount;
        final key = _tableLayoutKey(
          block,
          tableDocPos: docPos,
          availableTwips: activeSetup.contentWidthTwips,
          honorRenderedPageBreaks: honorRenderedPageBreaks,
        );
        if (_tableCache._lookup(key) != null) {
          cacheHits++;
        } else {
          final localDiagnostics = LayoutDiagnostics();
          final build = _TableRowsBuild(
            table: block,
            diagnostics: localDiagnostics,
            tableDocPos: docPos,
            availableTwips: activeSetup.contentWidthTwips,
            honorRenderedPageBreaks: honorRenderedPageBreaks,
          );
          for (final _ in _composeTableRowsSteps(build)) {
            if (slice.elapsedMicroseconds < sliceBudgetMicroseconds) continue;
            if (slice.elapsedMicroseconds > maxSliceMicroseconds) {
              maxSliceMicroseconds = slice.elapsedMicroseconds;
            }
            cooperativeYields++;
            await Future<void>.delayed(Duration.zero);
            slice.reset();
          }
          if (slice.elapsedMicroseconds > maxSliceMicroseconds) {
            maxSliceMicroseconds = slice.elapsedMicroseconds;
          }
          final currentKey = _tableLayoutKey(
            block,
            tableDocPos: docPos,
            availableTwips: activeSetup.contentWidthTwips,
            honorRenderedPageBreaks: honorRenderedPageBreaks,
          );
          // A font registry and the supplied face list can change while this
          // method is suspended. Never publish mixed-authority geometry.
          if (currentKey == key) {
            _tableCache._store(
              key,
              _CachedTableLayout(build.result!, localDiagnostics.warnings),
            );
          }
        }
      }
      if (_endsSection(block) && sectionIndex + 1 < sections.length) {
        sectionIndex++;
        activeSetup = sections[sectionIndex];
      }
      // The budget spans table boundaries and top-level scanning. Restarting
      // it for every small table would let several sub-budget tables combine
      // into one unbounded browser task.
      if (slice.elapsedMicroseconds >= sliceBudgetMicroseconds) {
        if (slice.elapsedMicroseconds > maxSliceMicroseconds) {
          maxSliceMicroseconds = slice.elapsedMicroseconds;
        }
        cooperativeYields++;
        await Future<void>.delayed(Duration.zero);
        slice.reset();
      }
    }

    if (slice.elapsedMicroseconds > maxSliceMicroseconds) {
      maxSliceMicroseconds = slice.elapsedMicroseconds;
    }

    timings?['tableCount'] = tableCount;
    timings?['tableRowCount'] = rowCount;
    timings?['tableCacheHits'] = cacheHits;
    timings?['tableCooperativeYields'] = cooperativeYields;
    timings?['tableMaxSliceMicroseconds'] = maxSliceMicroseconds;
    return cooperativeYields;
  }

  /// Recompõe REUSANDO o prefixo de páginas que a edição não pode ter
  /// afetado.
  ///
  /// O ponto da Fase 7: digitar na página 180 de 200 não pode custar as 200.
  /// Uma página só é ponto de retomada se COMEÇAR um bloco fresco — uma
  /// página que continua um parágrafo não sabe quantas linhas dele já foram
  /// consumidas, e recompor a partir dela duplicaria conteúdo.
  ///
  /// [changedFromDocPos] é a MENOR posição tocada pela transação. Tudo antes
  /// dela é idêntico no documento novo e no antigo, inclusive as posições —
  /// é o que torna o reuso do prefixo seguro sem remapear nada.
  PageGraph composeIncremental(
    PMNode doc, {
    required PageGraph previous,
    required int changedFromDocPos,
  }) {
    // `lastRenderedPageBreak` é um cache do layout que produziu o DOCX, não
    // uma quebra manual. Depois da primeira edição ele fica obsoleto: faz a
    // recomposição sem hints e sem convergir num sufixo ainda paginado por
    // eles. O ETP real tem só 19 páginas, então este descarte é barato e,
    // sobretudo, determinístico.
    if (previous.honoredRenderedPageBreakHints) {
      return _composeFrom(doc, honorRenderedPageBreaks: false);
    }
    var resumeAt = 0;
    for (var p = 1; p < previous.pages.length; p++) {
      if (!previous.pages[p].signature.startsFreshBlock) continue;
      if (previous.pages[p - 1].signature.lastDocPos >= changedFromDocPos) {
        break;
      }
      resumeAt = p;
    }
    if (resumeAt == 0) {
      // Nenhum prefixo reusável — é o caso da edição na PRIMEIRA página.
      // Ainda assim passamos o grafo anterior: é justamente aqui que a
      // convergência de sufixo vale, porque é ela (e não o prefixo) que
      // impede recompor as 200 páginas por causa da primeira linha.
      return _composeFrom(
        doc,
        convergeAgainst: previous,
        honorRenderedPageBreaks: false,
      );
    }

    final signature = previous.pages[resumeAt].signature;
    return _composeFrom(
      doc,
      reusedPages: previous.pages.sublist(0, resumeAt),
      reusedEntries: previous.positionMap.entries
          .where((entry) => entry.pageIndex < resumeAt)
          .toList(),
      startBlockIndex: signature.firstBlockIndex,
      startOffset: signature.firstBlockOffset,
      startListOrdinal: signature.carryListOrdinal,
      startSuppressSpaceBeforeAtPageTop: signature.suppressSpaceBeforeAtPageTop,
      convergeAgainst: previous,
      convergeFromPage: resumeAt,
      honorRenderedPageBreaks: false,
    );
  }

  PageGraph _composeFrom(
    PMNode doc, {
    List<PageLayout> reusedPages = const [],
    List<PositionMapEntry> reusedEntries = const [],
    int startBlockIndex = 0,
    int startOffset = 0,
    int startListOrdinal = 0,
    bool startSuppressSpaceBeforeAtPageTop = false,
    PageGraph? convergeAgainst,
    int convergeFromPage = 0,
    bool honorRenderedPageBreaks = true,
    int? stopAfterPages,
  }) {
    final diagnostics = LayoutDiagnostics();
    final usesRenderedPaginationCache =
        honorRenderedPageBreaks && _hasRenderedPageBreakHints(doc);
    // Os markers `lastRenderedPageBreak` descrevem o layout que o WORD
    // calculou com as métricas dele. Quando as nossas medem o conteúdo mais
    // alto e uma página estoura ANTES do marker correspondente, todos os
    // markers seguintes ficam desalinhados: cada um fecharia uma
    // página-lasca logo depois da quebra física. Da primeira divergência em
    // diante os hints são descartados e o documento pagina naturalmente —
    // que é o que o Word faz ao repaginar um arquivo cujo cache não bate.
    var honorHints = honorRenderedPageBreaks;
    final pages = <PageLayout>[...reusedPages];
    final mapEntries = <PositionMapEntry>[...reusedEntries];

    var currentFragments = <PageFragment>[];
    var pendingMetadataFragments = <BlockFragment>[];
    // Retomando no meio do documento (incremental ou progressivo), a seção
    // ativa é a que os blocos anteriores já atravessaram — reiniciar na
    // primeira aplicaria a geometria errada ao restante.
    var sectionIndex = 0;
    if (startBlockIndex > 0 && sections.length > 1) {
      for (var i = 0; i < startBlockIndex && i < doc.childCount; i++) {
        if (_endsSection(doc.child(i)) && sectionIndex + 1 < sections.length) {
          sectionIndex++;
        }
      }
    }
    var activeSetup = sections.isEmpty ? setup : sections[sectionIndex];
    // O inset do rodapé é um limite FÍSICO e vale também quando os hints de
    // `lastRenderedPageBreak` são honrados: os markers do Word foram medidos
    // com as métricas do Word, e as nossas podem produzir linhas mais altas.
    // Sem o inset, uma página "cheia" pelos markers desenhava o corpo por
    // cima do rodapé (TR: overlap de ~383 twips na página 1).
    var capacity = activeSetup.contentHeightTwips -
        _footerBodyInsetTwips(
          activeSetup,
          _footerForPage(pages.length),
          pages.length,
        );
    if (capacity < 0) capacity = 0;
    var bodyTopInsetTwips = _headerBodyInsetTwips(
      activeSetup,
      _headerForPage(pages.length),
      pages.length,
    );
    var cursorTwips = bodyTopInsetTwips;

    // Estado de ENTRADA da página aberta (o que a assinatura registra).
    var pageStartBlockIndex = startBlockIndex;
    var pageStartOffset = startOffset;
    var pageStartListOrdinal = startListOrdinal;
    var pageStartSuppressSpaceBeforeAtPageTop =
        startSuppressSpaceBeforeAtPageTop;
    var suppressSpaceBeforeAtPageTop = startSuppressSpaceBeforeAtPageTop;
    void closePage({bool suppressSpaceBefore = false}) {
      final first = currentFragments.isEmpty ? null : currentFragments.first;
      pages.add(PageLayout(
        index: pages.length,
        setup: activeSetup,
        fragments: currentFragments,
        signature: PageSignature(
          firstBlockIndex: pageStartBlockIndex,
          firstBlockOffset: pageStartOffset,
          carryListOrdinal: pageStartListOrdinal,
          suppressSpaceBeforeAtPageTop: pageStartSuppressSpaceBeforeAtPageTop,
          startsFreshBlock: first == null || !_continuesFrom(first),
          lastDocPos: _lastDocPosOf(currentFragments),
        ),
      ));
      currentFragments = [];
      capacity = activeSetup.contentHeightTwips -
          _footerBodyInsetTwips(
            activeSetup,
            _footerForPage(pages.length),
            pages.length,
          );
      if (capacity < 0) capacity = 0;
      bodyTopInsetTwips = _headerBodyInsetTwips(
        activeSetup,
        _headerForPage(pages.length),
        pages.length,
      );
      cursorTwips = bodyTopInsetTwips;
      pageStartSuppressSpaceBeforeAtPageTop = suppressSpaceBefore;
      suppressSpaceBeforeAtPageTop = suppressSpaceBefore;
    }

    // Convergência de SUFIXO: quando a composição nova reencontra o estado
    // de entrada de uma página antiga, tudo dali para frente é o mesmo
    // conteúdo — só as posições mudaram, pelo tamanho do que a edição
    // acrescentou ou removeu ANTES. Sem isto, editar a primeira linha de um
    // documento de 200 páginas recomporia as 200.
    final blockIndexDelta = convergeAgainst == null
        ? 0
        : doc.childCount - convergeAgainst.blockCount;
    final docPosDelta = convergeAgainst == null
        ? 0
        : doc.content.size - convergeAgainst.docSize;
    var converged = false;

    /// Existe página antiga com este mesmo estado de entrada?
    int? _oldPageMatching(
      int blockIndex,
      int blockOffset,
      int ordinal,
      bool suppressSpaceBefore,
    ) {
      final old = convergeAgainst;
      if (old == null) return null;
      for (var m = convergeFromPage; m < old.pages.length; m++) {
        final sig = old.pages[m].signature;
        if (!sig.startsFreshBlock) continue;
        if (sig.firstBlockIndex + blockIndexDelta != blockIndex) continue;
        if (sig.firstBlockOffset + docPosDelta != blockOffset) continue;
        if (sig.carryListOrdinal != ordinal) continue;
        if (sig.suppressSpaceBeforeAtPageTop != suppressSpaceBefore) continue;
        return m;
      }
      return null;
    }

    var listOrdinal = startListOrdinal;

    // O estado de entrada de uma página só é conhecido quando o PRIMEIRO
    // fragmento dela entra: uma página nova nasce no MEIO de um bloco
    // (quando `closePage` dispara na quebra de linha), então capturar no
    // topo da iteração registraria o bloco da página anterior.
    void beginPage(int index, int blockOffset, int ordinalBefore) {
      if (currentFragments.isNotEmpty) return;
      pageStartBlockIndex = index;
      pageStartOffset = blockOffset;
      pageStartListOrdinal = ordinalBefore;
      if (pendingMetadataFragments.isNotEmpty) {
        currentFragments.addAll(pendingMetadataFragments);
        pendingMetadataFragments = <BlockFragment>[];
      }
      // A decisão de suprimir o before já foi tomada pelo primeiro fragmento
      // antes de chamar beginPage. Qualquer conteúdo iniciado agora deixa de
      // estar no topo automático para os blocos seguintes.
      suppressSpaceBeforeAtPageTop = false;
    }

    /// Tenta convergir numa FRONTEIRA de página, com o próximo bloco a
    /// entrar sendo [blockIndex]. Só vale com a página vazia: com
    /// fragmentos pendentes, a página em construção não é comparável.
    bool tryConverge(int blockIndex, int blockOffset, int ordinal) {
      if (currentFragments.isNotEmpty || pendingMetadataFragments.isNotEmpty) {
        return false;
      }
      final match = _oldPageMatching(
        blockIndex,
        blockOffset,
        ordinal,
        suppressSpaceBeforeAtPageTop,
      );
      if (match == null) return false;
      final old = convergeAgainst!;
      final pageDelta = pages.length - match;
      for (var m = match; m < old.pages.length; m++) {
        pages.add(old.pages[m].shifted(
          newIndex: pages.length,
          docPosDelta: docPosDelta,
          blockIndexDelta: blockIndexDelta,
        ));
      }
      for (final entry in old.positionMap.entries) {
        if (entry.pageIndex < match) continue;
        mapEntries
            .add(entry.shifted(docPosDelta: docPosDelta, pageDelta: pageDelta));
      }
      converged = true;
      return true;
    }

    // O Word não soma `spaceAfter` do parágrafo anterior com `spaceBefore`
    // do seguinte: o intervalo é o MAIOR dos dois. Como o after já pertence
    // ao fragmento anterior, o próximo before só precisa completar a
    // diferença. Ao retomar incrementalmente, recuperamos o after do bloco
    // imediatamente anterior para preservar a mesma geometria.
    int? previousParagraphAfterTwips;
    _BlockStyle? previousParagraphStyle;
    if (startBlockIndex > 0) {
      final previous = doc.child(startBlockIndex - 1);
      if (previous.type.name != 'table' && !_endsSection(previous)) {
        previousParagraphStyle = _blockStyleOf(previous, 0);
        previousParagraphAfterTwips = previousParagraphStyle.spaceAfterTwips;
        if (startBlockIndex < doc.childCount &&
            doc.child(startBlockIndex).type.name != 'table' &&
            _usesContextualSpacing(previousParagraphStyle,
                _blockStyleOf(doc.child(startBlockIndex), 0))) {
          previousParagraphAfterTwips = 0;
        }
      }
    }

    var offset = startOffset;
    PageGraphResume? partialResume;

    // Paginação progressiva: o alvo foi atingido e a próxima página nasceria
    // com um bloco FRESCO? Então este é um ponto de retomada válido — o
    // mesmo contrato das assinaturas `startsFreshBlock` do reuso
    // incremental. Blocos que atravessam páginas (uma tabela longa) não
    // param no meio: a fatia cresce, nunca corrompe o estado.
    bool shouldStopForSlice() =>
        stopAfterPages != null &&
        pages.length >= stopAfterPages &&
        currentFragments.isEmpty &&
        pendingMetadataFragments.isEmpty &&
        !converged;

    for (var index = startBlockIndex; index < doc.childCount; index++) {
      if (index > startBlockIndex && tryConverge(index, offset, listOrdinal)) {
        break;
      }
      if (index > startBlockIndex && shouldStopForSlice()) {
        partialResume = PageGraphResume(
          blockIndex: index,
          offset: offset,
          listOrdinal: listOrdinal,
          suppressSpaceBeforeAtPageTop: suppressSpaceBeforeAtPageTop,
          honorRenderedPageBreaks: honorHints,
        );
        break;
      }
      final block = doc.child(index);
      final blockOffset = offset;
      // Quebra de página MANUAL (Ctrl+Enter / aba Inserir): o bloco marcado
      // abre página nova. Processada antes de compor, para o bloco inteiro
      // cair na página seguinte — e antes da captura de estado, para a
      // assinatura registrar a página nova começando nele.
      final manualPageBreakBefore = _pageBreakBefore(block);
      final inlinePageBreakOnly = _isImportedPageBreakOnlyParagraph(block);
      final renderedPageBreakBefore = honorHints &&
          _renderedPageBreakBefore(block) &&
          !_hasInlineRenderedPageBreakHint(block);
      if ((manualPageBreakBefore || inlinePageBreakOnly) &&
          (_hasVisualPageContent(currentFragments) ||
              (inlinePageBreakOnly && currentFragments.isNotEmpty))) {
        // An inline `<w:br type="page"/>` consumes the top spacing of the
        // paragraph that follows it. `w:pageBreakBefore` is a paragraph
        // property and keeps that paragraph's own spacing.
        closePage(suppressSpaceBefore: inlinePageBreakOnly);
      }
      if (renderedPageBreakBefore && _hasVisualPageContent(currentFragments)) {
        // `lastRenderedPageBreak` records where Word already laid the page
        // out; it must not be treated as a newly calculated overflow. Word's
        // saved top spacing is part of that confirmed geometry.
        closePage();
      }
      // ANTES da atualização de numeração: retomar neste bloco tem de
      // reproduzir o mesmo incremento, não contá-lo duas vezes.
      final ordinalBefore = listOrdinal;
      final docPos = offset + 1;
      offset += block.nodeSize;
      final kind = block.type.name;

      // Range markers and proofing metadata are legal top-level Word nodes,
      // but they have no visual box.  Keeping them as ordinary empty blocks
      // fabricated one font line per marker and, in the TR corpus, two whole
      // pages before the annex.  They remain fragments/positions for stable
      // identity and round-trip; only their layout contribution is zero.
      if (_isZeroLayoutOpaqueBlock(block)) {
        final fragment = BlockFragment(
          nodeId: officeNodeId(block),
          docPos: docPos,
          kind: kind,
          lines: const [],
          yTwips: cursorTwips,
          heightTwips: 0,
        );
        if (currentFragments.isEmpty) {
          pendingMetadataFragments.add(fragment);
        } else {
          currentFragments.add(fragment);
        }
        mapEntries.add(PositionMapEntry(
          docPosStart: docPos,
          docPosEnd: docPos + block.nodeSize,
          pageIndex: pages.length,
        ));
        continue;
      }

      if (kind == 'table') {
        previousParagraphAfterTwips = null;
        previousParagraphStyle = null;
        listOrdinal = 0;
        final rows = _composeTableRows(
          block,
          diagnostics,
          tableDocPos: docPos,
          availableTwips: activeSetup.contentWidthTwips,
          honorRenderedPageBreaks: honorHints,
        );
        var headerCount = 0;
        while (headerCount < rows.length && rows[headerCount].repeatHeader) {
          headerCount++;
        }
        final headerHeight = rows
            .take(headerCount)
            .fold<int>(0, (sum, row) => sum + row.heightTwips);
        String rowKey(TableRowBox row) =>
            row.sourceRowId ??
            '${row.sourceRowIndex ?? row.nodeId ?? row.docPos}';

        // Quando uma row cruza a página, o Word costuma deixar dois markers
        // para a MESMA fronteira: um no meio da row e outro no começo da row
        // imediatamente seguinte. O primeiro produz o corte; o segundo é um
        // alias e precisa ser consumido, ou surgiria uma página extra.
        String? renderedInternalBreakSourceRow;
        final consumedRenderedStartRows = <String>{};
        var i = 0;
        var firstOfTable = true;
        while (i < rows.length) {
          // Ponto de retomada progressivo: a tabela inteira começaria numa
          // página fresca depois do alvo de páginas da fatia.
          if (i == 0 &&
              firstOfTable &&
              index > startBlockIndex &&
              shouldStopForSlice()) {
            partialResume = PageGraphResume(
              blockIndex: index,
              offset: blockOffset,
              listOrdinal: ordinalBefore,
              suppressSpaceBeforeAtPageTop: suppressSpaceBeforeAtPageTop,
              honorRenderedPageBreaks: honorHints,
            );
            break;
          }
          var repeatedHeaders =
              !firstOfTable && headerCount > 0 && i >= headerCount
                  ? [
                      for (final row in rows.take(headerCount))
                        row.asRepeatedHeader()
                    ]
                  : <TableRowBox>[];
          var repeatedHeight = repeatedHeaders.isEmpty ? 0 : headerHeight;
          var remaining = capacity - cursorTwips - repeatedHeight;
          var end = i;
          var bodyHeight = 0;
          var forcePageAfterRenderedRowCut = false;
          while (end < rows.length) {
            final groupEnd =
                _tableRowGroupEnd(rows, end, headerCount: headerCount);
            final row = rows[end];
            final key = rowKey(row);
            final renderedBreak = _pageBreakInTableRow(
              row,
              honorRenderedPageBreaks: honorHints,
            );

            if (renderedInternalBreakSourceRow != null &&
                key != renderedInternalBreakSourceRow) {
              if (renderedBreak.beforeRow) {
                consumedRenderedStartRows.add(key);
              }
              renderedInternalBreakSourceRow = null;
            }

            final forceBeforeRow = renderedBreak.beforeRow &&
                !consumedRenderedStartRows.contains(key);
            if (forceBeforeRow) {
              // Se já há corpo na página, finalize-o e reavalie esta row na
              // página vazia. Na página vazia o marker já está satisfeito.
              if (end > i || _hasVisualPageContent(currentFragments)) {
                break;
              }
              consumedRenderedStartRows.add(key);
            }

            final renderedCut = renderedBreak.internalCutTwips;
            if (groupEnd == end + 1 &&
                renderedCut != null &&
                bodyHeight + renderedCut <= remaining) {
              final split = _splitTableRow(
                row,
                renderedCut,
                renderedBreak: true,
              );
              if (split != null) {
                rows[end] = split.head;
                rows.insert(end + 1, split.tail);
                bodyHeight += split.head.heightTwips;
                renderedInternalBreakSourceRow = key;
                forcePageAfterRenderedRowCut = true;
                end++;
                break;
              }
            }

            var groupHeight = 0;
            for (var r = end; r < groupEnd; r++) {
              groupHeight += rows[r].heightTwips;
            }
            if (bodyHeight + groupHeight > remaining) {
              // `cantSplit=false` permite usar o restante da página e
              // continuar a MESMA row na seguinte. Rowspan/vMerge continuam
              // grupos indivisíveis e são rejeitados por `_splitTableRow`.
              if (groupEnd == end + 1) {
                final split = _splitTableRow(rows[end], remaining - bodyHeight);
                if (split != null) {
                  rows[end] = split.head;
                  rows.insert(end + 1, split.tail);
                  bodyHeight += split.head.heightTwips;
                  end++;
                }
              }
              break;
            }
            bodyHeight += groupHeight;
            end = groupEnd;
          }
          if (end == i) {
            if (!_hasVisualPageContent(currentFragments)) {
              final groupEnd =
                  _tableRowGroupEnd(rows, i, headerCount: headerCount);
              var groupHeight = 0;
              for (var r = i; r < groupEnd; r++) {
                groupHeight += rows[r].heightTwips;
              }
              // Se o grupo cabe sem a cópia do cabeçalho, é melhor omitir a
              // repetição nesta página do que cortar uma mesclagem vertical.
              if (repeatedHeaders.isNotEmpty &&
                  groupHeight <= capacity - bodyTopInsetTwips) {
                repeatedHeaders = [];
                repeatedHeight = 0;
                remaining = capacity;
                diagnostics.warnings.add(
                    'cabeçalho repetido omitido para manter grupo de linhas');
              }
              end = groupEnd;
              bodyHeight = groupHeight;
              if (bodyHeight + repeatedHeight > capacity - bodyTopInsetTwips) {
                diagnostics.warnings
                    .add('grupo de linhas de tabela mais alto que a página');
              }
            } else {
              // Quebra forçada pela CAPACIDADE física, não por um marker: as
              // métricas divergiram do cache do Word e os hints seguintes
              // fechariam páginas-lasca. Daqui em diante, paginação natural.
              honorHints = false;
              closePage(suppressSpaceBefore: true);
              if (i == 0 && tryConverge(index, blockOffset, ordinalBefore)) {
                break;
              }
              continue;
            }
          }
          final slice = rows.sublist(i, end);
          final renderedRows = <TableRowBox>[...repeatedHeaders, ...slice];
          final height = repeatedHeight + bodyHeight;
          beginPage(index, blockOffset, ordinalBefore);
          currentFragments.add(TableFragment(
            nodeId: officeNodeId(block),
            docPos: docPos,
            docPosEnd: docPos + block.content.size,
            sourceTableId: officeNodeId(block),
            rows: renderedRows,
            yTwips: cursorTwips,
            heightTwips: height,
            continuesFromPreviousPage: !firstOfTable,
            continuesOnNextPage: end < rows.length,
          ));
          mapEntries.addAll(_tablePositionEntries(slice, pages.length));
          cursorTwips += height;
          firstOfTable = false;
          i = end;
          if (forcePageAfterRenderedRowCut &&
              _hasVisualPageContent(currentFragments)) {
            closePage(suppressSpaceBefore: true);
          }
        }
        if (converged) break;
        if (partialResume != null) break;
        continue;
      }

      // Estado da numeração de lista ordenada.
      if (kind == 'listItem' && block.attrs['kind'] == 'ordered') {
        listOrdinal++;
      } else if (kind != 'listItem') {
        listOrdinal = 0;
      }

      final blockStyle = _blockStyleOf(block, listOrdinal);
      final contextualWithPrevious = previousParagraphStyle != null &&
          _usesContextualSpacing(previousParagraphStyle, blockStyle);
      final effectiveSpaceBefore =
          manualPageBreakBefore || renderedPageBreakBefore
              ? blockStyle.spaceBeforeTwips
              : contextualWithPrevious
                  ? 0
                  : _collapsedSpaceBefore(
                      blockStyle.spaceBeforeTwips,
                      previousParagraphAfterTwips,
                    );
      var effectiveSpaceAfter = blockStyle.spaceAfterTwips;
      if (!_endsSection(block) && index + 1 < doc.childCount) {
        final next = doc.child(index + 1);
        if (next.type.name != 'table' &&
            _usesContextualSpacing(blockStyle, _blockStyleOf(next, 0))) {
          effectiveSpaceAfter = 0;
        }
      }
      final blockFlow = _paragraphFlow(blockStyle);
      final importedPageBreakOnly = _isImportedPageBreakOnlyParagraph(block);
      final lines = importedPageBreakOnly
          ? <LineBox>[]
          : _breakLines(
              block,
              activeSetup.contentWidthTwips -
                  blockFlow.textIndentTwips -
                  blockStyle.rightIndentTwips,
              blockStyle,
              diagnostics,
              honorRenderedPageBreaks: honorHints,
              gridLinePitchTwips: activeSetup.activeDocumentGridLinePitchTwips,
            );

      // `keepLines`: se o parágrafo inteiro cabe numa página, não o corta.
      // `keepNext`: mantém este bloco e ao menos a primeira linha do próximo
      // juntos (regra típica de títulos). Blocos maiores que a página ainda
      // fragmentam para garantir progresso e nunca transbordar.
      final ownLineHeight = lines.isEmpty
          ? _resolvedLineHeightTwips(
              _lineHeightTwips(
                  blockStyle.family ?? baseFontFamily, blockStyle.baseSizePt),
              blockStyle,
              gridLinePitchTwips: activeSetup.activeDocumentGridLinePitchTwips,
            )
          : lines.fold<int>(0, (sum, line) => sum + line.heightTwips);
      final ownHeight =
          effectiveSpaceBefore + ownLineHeight + effectiveSpaceAfter;
      var keepRequiredHeight = blockStyle.keepLines ? ownHeight : 0;
      if (blockStyle.keepNext && index + 1 < doc.childCount) {
        final next = doc.child(index + 1);
        if (next.type.name != 'table') {
          final nextStyle = _blockStyleOf(next, 0);
          final nextFlow = _paragraphFlow(nextStyle);
          final nextLines = _breakLines(
            next,
            activeSetup.contentWidthTwips -
                nextFlow.textIndentTwips -
                nextStyle.rightIndentTwips,
            nextStyle,
            LayoutDiagnostics(),
            honorRenderedPageBreaks: honorHints,
            gridLinePitchTwips: activeSetup.activeDocumentGridLinePitchTwips,
          );
          final nextBlankHeight = _resolvedLineHeightTwips(
            _lineHeightTwips(
                nextStyle.family ?? baseFontFamily, nextStyle.baseSizePt),
            nextStyle,
            gridLinePitchTwips: activeSetup.activeDocumentGridLinePitchTwips,
          );
          final nextBefore = _usesContextualSpacing(blockStyle, nextStyle)
              ? 0
              : _collapsedSpaceBefore(
                  nextStyle.spaceBeforeTwips, effectiveSpaceAfter);

          // `keepNext` precisa reservar um PRIMEIRO FRAGMENTO VÁLIDO do
          // próximo parágrafo, não apenas sua primeira linha. Com
          // `widowControl`, duas ou três linhas não admitem uma divisão sem
          // deixar uma ponta isolada; nesse caso o parágrafo inteiro (inclusive
          // seu after) acompanha o título. Com quatro ou mais, duas linhas são
          // o menor fragmento válido.
          final keepWholeNext = nextLines.isEmpty ||
              nextStyle.keepLines ||
              (nextStyle.widowControl && nextLines.length <= 3);
          final nextLinesToKeep = nextLines.isEmpty
              ? nextBlankHeight
              : nextLines
                  .take(keepWholeNext
                      ? nextLines.length
                      : nextStyle.widowControl
                          ? 2
                          : 1)
                  .fold<int>(0, (sum, line) => sum + line.heightTwips);
          var nextAfter = 0;
          if (keepWholeNext) {
            nextAfter = nextStyle.spaceAfterTwips;
            if (index + 2 < doc.childCount) {
              final afterNext = doc.child(index + 2);
              if (afterNext.type.name != 'table' &&
                  _usesContextualSpacing(
                      nextStyle, _blockStyleOf(afterNext, 0))) {
                nextAfter = 0;
              }
            }
          }
          keepRequiredHeight =
              ownHeight + nextBefore + nextLinesToKeep + nextAfter;
        }
      }
      if (keepRequiredHeight > 0 &&
          keepRequiredHeight <= capacity - bodyTopInsetTwips &&
          cursorTwips + keepRequiredHeight > capacity &&
          _hasVisualPageContent(currentFragments)) {
        closePage(suppressSpaceBefore: true);
      }

      var firstLineOfBlock = true;
      var forcePageAfterBlock = false;
      var i = 0;
      while (i < lines.length) {
        // Ponto de retomada progressivo: o bloco inteiro começaria numa
        // página fresca depois do alvo de páginas da fatia.
        if (i == 0 &&
            firstLineOfBlock &&
            index > startBlockIndex &&
            shouldStopForSlice()) {
          partialResume = PageGraphResume(
            blockIndex: index,
            offset: blockOffset,
            listOrdinal: ordinalBefore,
            suppressSpaceBeforeAtPageTop: suppressSpaceBeforeAtPageTop,
            honorRenderedPageBreaks: honorHints,
          );
          break;
        }
        if ((lines[i].manualPageBreakBefore ||
                (honorHints && lines[i].renderedPageBreakBefore)) &&
            _hasVisualPageContent(currentFragments)) {
          closePage(
            suppressSpaceBefore: lines[i].manualPageBreakBefore,
          );
        }
        var spaceBefore = i == 0 ? effectiveSpaceBefore : 0;
        if (i == 0 &&
            !_hasVisualPageContent(currentFragments) &&
            suppressSpaceBeforeAtPageTop) {
          spaceBefore = 0;
          suppressSpaceBeforeAtPageTop = false;
        }
        var spaceAfter = 0;
        final remaining = capacity - cursorTwips;
        // Quantas linhas cabem nesta página.
        var take = 0;
        var linesHeight = 0;
        while (i + take < lines.length) {
          if (take > 0 &&
              (lines[i + take].manualPageBreakBefore ||
                  (honorHints && lines[i + take].renderedPageBreakBefore))) {
            break;
          }
          final candidate = lines[i + take].heightTwips;
          final isLast = i + take + 1 == lines.length;
          final candidateAfter = isLast ? effectiveSpaceAfter : 0;
          if (spaceBefore + linesHeight + candidate + candidateAfter <=
              remaining) {
            linesHeight += candidate;
            spaceAfter = candidateAfter;
            take++;
            continue;
          }
          // Espaçamento posterior não cria uma página vazia sozinho: se a
          // última linha cabe, consome o restante da página e a próxima
          // unidade começa na página seguinte.
          if (isLast && spaceBefore + linesHeight + candidate <= remaining) {
            linesHeight += candidate;
            take++;
            spaceAfter = remaining - spaceBefore - linesHeight;
            forcePageAfterBlock = spaceAfter < effectiveSpaceAfter;
          }
          break;
        }

        // `w:widowControl` (ativo por padrão no Word): não deixa a primeira
        // nem a última linha de um parágrafo isolada numa página. Ajustamos o
        // maior corte que coube antes de decidir fechar a página. Parágrafos
        // de três linhas, por exemplo, são atômicos quando o espaço restante
        // só permitiria uma divisão 1+2 ou 2+1.
        final stoppedAtExplicitBreak = i + take < lines.length &&
            (lines[i + take].manualPageBreakBefore ||
                (honorHints && lines[i + take].renderedPageBreakBefore));
        if (!stoppedAtExplicitBreak &&
            blockStyle.widowControl &&
            lines.length > 1 &&
            take > 0) {
          final linesAfter = lines.length - (i + take);
          if (linesAfter == 1 && take > 1) {
            take--;
            linesHeight -= lines[i + take].heightTwips;
            spaceAfter = 0;
          }
          final isolatesFirstLine =
              i == 0 && take == 1 && i + take < lines.length;
          final isolatesLastLine = lines.length - (i + take) == 1;
          if ((isolatesFirstLine || isolatesLastLine) &&
              _hasVisualPageContent(currentFragments)) {
            take = 0;
            linesHeight = 0;
            spaceAfter = 0;
          }
        }
        if (take == 0) {
          if (!_hasVisualPageContent(currentFragments)) {
            final lineHeight = lines[i].heightTwips;
            if (lineHeight <= remaining) {
              // Espaço anterior excessivo é truncado na borda da página;
              // nunca deixamos a primeira linha fora do content box.
              final maxBefore = remaining - lineHeight;
              if (spaceBefore > maxBefore) spaceBefore = maxBefore;
              linesHeight = lineHeight;
              take = 1;
              if (i + 1 == lines.length) {
                final availableAfter = capacity - spaceBefore - linesHeight;
                spaceAfter = effectiveSpaceAfter < availableAfter
                    ? effectiveSpaceAfter
                    : availableAfter;
                forcePageAfterBlock = spaceAfter < effectiveSpaceAfter;
              }
            } else {
              // Linha maior que a página inteira: entra mesmo assim (corte
              // estável, nunca loop) e o aviso registra a perda visual.
              spaceBefore = 0;
              spaceAfter = 0;
              take = 1;
              linesHeight = lineHeight;
              diagnostics.warnings
                  .add('linha mais alta que a página no nó ${block.type.name}');
            }
          } else {
            // Divergência física: a página encheu antes do marker do Word.
            // Os hints restantes fechariam páginas-lasca — paginação natural
            // daqui em diante.
            honorHints = false;
            closePage(suppressSpaceBefore: true);
            // A fronteira de página nasce AQUI quando o bloco inteiro não
            // cabe no que sobrou: é o ponto em que a página nova começa
            // num bloco fresco, e portanto o ponto de convergência.
            if (i == 0 && tryConverge(index, blockOffset, ordinalBefore)) {
              break;
            }
            continue;
          }
        }
        final height = spaceBefore + linesHeight + spaceAfter;
        final slice = lines.sublist(i, i + take);
        beginPage(index, blockOffset, ordinalBefore);
        currentFragments.add(BlockFragment(
          nodeId: officeNodeId(block),
          docPos: docPos,
          kind: kind,
          lines: slice,
          yTwips: cursorTwips,
          heightTwips: height,
          indentTwips: blockFlow.textIndentTwips,
          rightIndentTwips: blockStyle.rightIndentTwips,
          align: blockStyle.align,
          marker: firstLineOfBlock ? blockStyle.marker : null,
          markerPositionTwips: blockFlow.markerPositionTwips,
          markerStyle:
              blockStyle.marker == null ? null : _markerStyleOf(blockStyle),
          widowControl: blockStyle.widowControl,
          spaceBeforeTwips: spaceBefore,
          spaceAfterTwips: spaceAfter,
          continuesFromPreviousPage: !firstLineOfBlock,
          continuesOnNextPage: i + take < lines.length,
        ));
        for (final line in slice) {
          mapEntries.add(PositionMapEntry(
            docPosStart: docPos + line.charStart,
            docPosEnd: docPos + line.charEnd,
            pageIndex: pages.length,
          ));
        }
        cursorTwips += height;
        firstLineOfBlock = false;
        i += take;
      }
      if (converged) break;
      if (partialResume != null) break;
      if (forcePageAfterBlock && currentFragments.isNotEmpty) {
        closePage(suppressSpaceBefore: true);
      }
      // A quebra de seção é processada DEPOIS do bloco: o `sectPr` descreve
      // a seção que termina NELE, então ele ainda pertence à geometria
      // antiga.
      if (_endsSection(block) && sectionIndex + 1 < sections.length) {
        if (currentFragments.isNotEmpty) closePage();
        sectionIndex++;
        activeSetup = sections[sectionIndex];
        capacity = activeSetup.contentHeightTwips -
            _footerBodyInsetTwips(
              activeSetup,
              _footerForPage(pages.length),
              pages.length,
            );
        if (capacity < 0) capacity = 0;
        bodyTopInsetTwips = _headerBodyInsetTwips(
          activeSetup,
          _headerForPage(pages.length),
          pages.length,
        );
        cursorTwips = bodyTopInsetTwips;
      }
      if (lines.isEmpty) {
        // Bloco vazio: uma linha em branco na altura da fonte base.
        final natural = _lineHeightTwips(
            blockStyle.family ?? baseFontFamily, blockStyle.baseSizePt);
        final pageBreakOnly = importedPageBreakOnly;
        final blank = pageBreakOnly
            ? 0
            : _resolvedLineHeightTwips(
                natural,
                blockStyle,
                gridLinePitchTwips:
                    activeSetup.activeDocumentGridLinePitchTwips,
              );
        var before = pageBreakOnly ? 0 : effectiveSpaceBefore;
        var after = pageBreakOnly ? 0 : effectiveSpaceAfter;
        if (!pageBreakOnly &&
            !_hasVisualPageContent(currentFragments) &&
            suppressSpaceBeforeAtPageTop) {
          before = 0;
          suppressSpaceBeforeAtPageTop = false;
        }
        var total = before + blank + after;
        if (cursorTwips + total > capacity &&
            _hasVisualPageContent(currentFragments)) {
          closePage(suppressSpaceBefore: true);
          before = 0;
          total = blank + after;
        }
        final pageBodyCapacity = capacity - bodyTopInsetTwips;
        if (total > pageBodyCapacity && blank <= pageBodyCapacity) {
          final roomForSpacing = pageBodyCapacity - blank;
          if (before > roomForSpacing) before = roomForSpacing;
          final roomAfter = roomForSpacing - before;
          if (after > roomAfter) after = roomAfter;
          total = before + blank + after;
        }
        beginPage(index, blockOffset, ordinalBefore);
        currentFragments.add(BlockFragment(
          nodeId: officeNodeId(block),
          docPos: docPos,
          kind: kind,
          lines: const [],
          yTwips: cursorTwips,
          heightTwips: total,
          indentTwips: blockFlow.textIndentTwips,
          rightIndentTwips: blockStyle.rightIndentTwips,
          align: blockStyle.align,
          marker: blockStyle.marker,
          markerPositionTwips: blockFlow.markerPositionTwips,
          markerStyle:
              blockStyle.marker == null ? null : _markerStyleOf(blockStyle),
          widowControl: blockStyle.widowControl,
          spaceBeforeTwips: before,
          spaceAfterTwips: after,
        ));
        // The zero-height paragraph is only the imported page-break carrier;
        // the spacing rule belongs to the first visible paragraph after it.
        if (pageBreakOnly) suppressSpaceBeforeAtPageTop = true;
        mapEntries.add(PositionMapEntry(
          docPosStart: docPos,
          docPosEnd: docPos + block.nodeSize - 2,
          pageIndex: pages.length,
        ));
        cursorTwips += total;
      }
      previousParagraphAfterTwips =
          _endsSection(block) ? null : effectiveSpaceAfter;
      previousParagraphStyle = _endsSection(block) ? null : blockStyle;
    }

    if (!converged &&
        pendingMetadataFragments.isNotEmpty &&
        currentFragments.isEmpty) {
      currentFragments.addAll(pendingMetadataFragments);
      pendingMetadataFragments = <BlockFragment>[];
    }
    if (!converged &&
        (currentFragments.isNotEmpty || pages.length == reusedPages.length)) {
      closePage();
    }

    return PageGraph(
      pages: _withHeadersAndFooters(pages, diagnostics),
      positionMap: PositionMap(mapEntries),
      diagnostics: diagnostics,
      quality: quality,
      docSize: doc.content.size,
      blockCount: doc.childCount,
      honoredRenderedPageBreakHints: usesRenderedPaginationCache,
      resume: partialResume,
    );
  }

  /// Compõe cabeçalho e rodapé de cada página.
  ///
  /// Quando a região NÃO tem campo de página, ela é composta UMA vez e a
  /// mesma lista é reusada em todas as páginas — é conteúdo idêntico, e
  /// recompor 200 vezes seria desperdício puro. Com campo, o texto muda por
  /// página e a composição precisa acontecer por página; regiões de
  /// cabeçalho são pequenas, então o custo é aceitável e a alternativa
  /// (medir com o placeholder e desenhar outro texto) desalinharia.
  List<PageLayout> _withHeadersAndFooters(
      List<PageLayout> pages, LayoutDiagnostics diagnostics) {
    if (header == null &&
        footer == null &&
        headerVariants.isEmpty &&
        footerVariants.isEmpty) {
      return pages;
    }
    if (pages.isEmpty) return pages;

    final total = pages.length;
    final sharedHeaders = <PMNode, Map<PageSetupTwips, List<BlockFragment>>>{};
    final sharedFooters = <PMNode, Map<PageSetupTwips, List<BlockFragment>>>{};

    List<BlockFragment> compose(
      PMNode? region,
      PageLayout page,
      Map<PMNode, Map<PageSetupTwips, List<BlockFragment>>> cache,
    ) {
      if (region == null) return const [];
      if (_hasPageField(region)) {
        return _composeRegion(
          region,
          diagnostics,
          page.index,
          total,
          regionSetup: page.setup,
        );
      }
      final bySetup = cache.putIfAbsent(region, () => {});
      return bySetup.putIfAbsent(
        page.setup,
        () => _composeRegion(
          region,
          diagnostics,
          page.index,
          total,
          regionSetup: page.setup,
        ),
      );
    }

    return [
      for (final page in pages)
        PageLayout(
          index: page.index,
          setup: page.setup,
          fragments: page.fragments,
          signature: page.signature,
          header: compose(_headerForPage(page.index), page, sharedHeaders),
          footer: compose(_footerForPage(page.index), page, sharedFooters),
        )
    ];
  }

  PMNode? _headerForPage(int pageIndex) =>
      _regionForPage(headerVariants, header, pageIndex);

  PMNode? _footerForPage(int pageIndex) =>
      _regionForPage(footerVariants, footer, pageIndex);

  PMNode? _regionForPage(
    Map<String, PMNode> variants,
    PMNode? fallback,
    int pageIndex,
  ) {
    if (variants.isEmpty) return fallback;
    if (titlePage && pageIndex == 0) {
      return variants['first'] ?? variants['default'] ?? fallback;
    }
    if (evenAndOddHeaders && (pageIndex + 1).isEven) {
      return variants['even'] ?? variants['default'] ?? fallback;
    }
    return variants['default'] ?? fallback;
  }

  bool _hasPageField(PMNode? region) {
    if (region == null) return false;
    bool visit(PMNode node) {
      if (node.isText && _pageField.hasMatch(node.text ?? '')) return true;
      if (node.type.name == 'opaqueInline') {
        final insert = node.attrs['insert'];
        if (insert is Map && insert['fieldMarker'] == 'separate') {
          final command = '${insert['fieldCommand'] ?? ''}'.toUpperCase();
          if (command == 'PAGE' || command == 'NUMPAGES') return true;
        }
      }
      for (var i = 0; i < node.childCount; i++) {
        if (visit(node.child(i))) return true;
      }
      return false;
    }

    return _pageFieldCache.putIfAbsent(region, () => visit(region));
  }

  /// Uma região empilhada a partir do topo do seu box, com os campos de
  /// página já resolvidos para ESTA página.
  List<BlockFragment> _composeRegion(
    PMNode? region,
    LayoutDiagnostics diagnostics,
    int pageIndex,
    int totalPages, {
    PageSetupTwips? regionSetup,
  }) {
    if (region == null) return const [];
    final geometry = regionSetup ?? setup;
    final resolved = _resolveFields(region, pageIndex + 1, totalPages);
    final fragments = <BlockFragment>[];
    var y = 0;
    int? previousAfterTwips;
    for (var i = 0; i < resolved.childCount; i++) {
      final block = resolved.child(i);
      if (_isZeroLayoutOpaqueBlock(block)) {
        fragments.add(BlockFragment(
          nodeId: officeNodeId(block),
          docPos: -1,
          kind: block.type.name,
          lines: const [],
          yTwips: y,
          heightTwips: 0,
        ));
        continue;
      }
      final style = _blockStyleOf(block, 0);
      final flow = _paragraphFlow(style);
      final before =
          _collapsedSpaceBefore(style.spaceBeforeTwips, previousAfterTwips);
      final lines = _breakLines(
          block,
          geometry.contentWidthTwips - flow.textIndentTwips,
          style,
          diagnostics);
      final lineHeight = lines.isEmpty
          ? _resolvedLineHeightTwips(
              _lineHeightTwips(
                  style.family ?? baseFontFamily, style.baseSizePt),
              style)
          : lines.fold<int>(0, (sum, line) => sum + line.heightTwips);
      final height = before + lineHeight + style.spaceAfterTwips;
      fragments.add(BlockFragment(
        nodeId: officeNodeId(block),
        // Fora do espaço de posições do corpo: -1 declara que este fragmento
        // não corresponde a nenhuma posição do documento.
        docPos: -1,
        kind: block.type.name,
        lines: lines,
        yTwips: y,
        heightTwips: height,
        indentTwips: flow.textIndentTwips,
        rightIndentTwips: style.rightIndentTwips,
        align: style.align,
        marker: style.marker,
        markerPositionTwips: flow.markerPositionTwips,
        markerStyle: style.marker == null ? null : _markerStyleOf(style),
        widowControl: style.widowControl,
        spaceBeforeTwips: before,
        spaceAfterTwips: style.spaceAfterTwips,
      ));
      y += height;
      previousAfterTwips = style.spaceAfterTwips;
    }
    return fragments;
  }

  /// Compõe a árvore PM destacada de `w:txbxContent` no espaço interno da
  /// shape. Estes fragmentos são apenas projeção: `docPos == -1` impede que
  /// entrem no mapa de posições do documento externo.
  List<BlockFragment> _composeTextBoxContent(
    PMNode textBoxNode,
    int widthTwips,
    int insetLeftTwips,
    int insetRightTwips,
    LayoutDiagnostics diagnostics,
  ) {
    final raw = textBoxNode.attrs['textBoxDoc'];
    if (raw is! Map) return const [];

    final PMNode doc;
    try {
      doc = PMNode.fromJSON(textBoxNode.type.schema, raw);
    } catch (_) {
      diagnostics.warnings.add(
        'textBoxDoc inválido; usando fallback de texto plano',
      );
      return const [];
    }
    if (doc.type.name != 'doc') {
      diagnostics.warnings.add(
        'textBoxDoc não é um documento; usando fallback de texto plano',
      );
      return const [];
    }

    final rawContentWidth = widthTwips - insetLeftTwips - insetRightTwips;
    final contentWidth = rawContentWidth > 0 ? rawContentWidth : 1;
    final fragments = <BlockFragment>[];
    var y = 0;
    int? previousAfterTwips;
    for (var i = 0; i < doc.childCount; i++) {
      final block = doc.child(i);
      if (_isZeroLayoutOpaqueBlock(block)) {
        fragments.add(BlockFragment(
          nodeId: officeNodeId(block),
          docPos: -1,
          kind: block.type.name,
          lines: const [],
          yTwips: y,
          heightTwips: 0,
        ));
        continue;
      }
      if (block.type.name == 'table') {
        diagnostics.warnings.add(
          'tabela interna de textBox preservada, mas ainda não projetada',
        );
        continue;
      }

      final style = _blockStyleOf(block, 0);
      final flow = _paragraphFlow(style);
      final before =
          _collapsedSpaceBefore(style.spaceBeforeTwips, previousAfterTwips);
      final rawLineWidth =
          contentWidth - flow.textIndentTwips - style.rightIndentTwips;
      final lines = _breakLines(
        block,
        rawLineWidth > 0 ? rawLineWidth : 1,
        style,
        diagnostics,
        honorRenderedPageBreaks: false,
      );
      final lineHeight = lines.isEmpty
          ? _resolvedLineHeightTwips(
              _lineHeightTwips(
                style.family ?? baseFontFamily,
                style.baseSizePt,
              ),
              style,
            )
          : lines.fold<int>(0, (sum, line) => sum + line.heightTwips);
      final height = before + lineHeight + style.spaceAfterTwips;
      fragments.add(BlockFragment(
        nodeId: officeNodeId(block),
        docPos: -1,
        kind: block.type.name,
        lines: lines,
        yTwips: y,
        heightTwips: height,
        indentTwips: flow.textIndentTwips,
        rightIndentTwips: style.rightIndentTwips,
        align: style.align,
        marker: style.marker,
        markerPositionTwips: flow.markerPositionTwips,
        markerStyle: style.marker == null ? null : _markerStyleOf(style),
        widowControl: style.widowControl,
        spaceBeforeTwips: before,
        spaceAfterTwips: style.spaceAfterTwips,
      ));
      y += height;
      previousAfterTwips = style.spaceAfterTwips;
    }
    return fragments;
  }

  /// Quanto o fluxo do header invade a caixa do corpo.
  ///
  /// Conteúdo inline (inclusive imagens) participa da altura normal do
  /// cabeçalho no Word. Objetos flutuantes `behindDoc`, `inFrontOfText`,
  /// square/through continuam fora do fluxo; dentre eles, apenas a exclusão
  /// vertical explícita `wrapTopAndBottom` desloca o corpo.
  int _headerBodyInsetTwips(
    PageSetupTwips pageSetup,
    PMNode? pageHeader,
    int pageIndex,
  ) {
    if (pageHeader == null) return 0;
    if (!_hasPageField(pageHeader)) {
      final bySetup = _staticHeaderInsetCache.putIfAbsent(pageHeader, () => {});
      return bySetup.putIfAbsent(
        pageSetup,
        () => _computeHeaderBodyInsetTwips(
          pageSetup,
          pageHeader,
          pageIndex,
        ),
      );
    }
    return _computeHeaderBodyInsetTwips(pageSetup, pageHeader, pageIndex);
  }

  int _computeHeaderBodyInsetTwips(
    PageSetupTwips pageSetup,
    PMNode pageHeader,
    int pageIndex,
  ) {
    final resolvedHeader = _resolveFields(pageHeader, pageIndex + 1, 1);
    final fragments = _composeRegion(
      pageHeader,
      LayoutDiagnostics(),
      pageIndex,
      1,
      regionSetup: pageSetup,
    );
    var flowOrExclusionBottom = 0;
    for (var blockIndex = 0; blockIndex < fragments.length; blockIndex++) {
      final block = fragments[blockIndex];
      final sourceBlock = resolvedHeader.child(blockIndex);
      final blockStyle = _blockStyleOf(sourceBlock, 0);
      final flowBottom = block.yTwips + block.heightTwips;
      if (flowBottom > flowOrExclusionBottom) {
        flowOrExclusionBottom = flowBottom;
      }

      // `positionV relativeFrom="paragraph"` is based on the anchor
      // paragraph's typographic line, not on the top of its drawing.  A
      // floating image can make [LineBox.heightTwips] arbitrarily tall, so
      // derive this reference from text metrics.  Word uses docGrid's raw
      // linePitch for this anchor even when an omitted docGrid type leaves
      // ordinary body text unsnapped.
      final anchorLineHeight = _resolvedLineHeightTwips(
        _lineHeightTwips(
            blockStyle.family ?? baseFontFamily, blockStyle.baseSizePt),
        blockStyle,
        gridLinePitchTwips: pageSetup.documentGridLinePitchTwips,
      );
      var lineTop = block.yTwips + block.spaceBeforeTwips;
      for (final line in block.lines) {
        for (final segment in line.segments) {
          final box = segment.textBox;
          int? bottom;
          if (box != null && box.wrapTopAndBottom) {
            final paragraphReference =
                box.positionVRelativeFrom?.toLowerCase() == 'paragraph'
                    ? anchorLineHeight
                    : 0;
            bottom = lineTop +
                paragraphReference +
                box.offsetYTwips +
                box.heightTwips;
          }
          if (bottom == null) continue;
          if (bottom > flowOrExclusionBottom) {
            flowOrExclusionBottom = bottom;
          }
        }
        lineTop += line.heightTwips;
      }
    }
    final pageBottom = pageSetup.headerDistanceTwips + flowOrExclusionBottom;
    final inset = pageBottom - pageSetup.marginTopTwips;
    return inset > 0 ? inset : 0;
  }

  /// Quanto o rodapé sobe para dentro da caixa reservada ao corpo.
  ///
  /// O Word posiciona o rodapé a [footerDistanceTwips] da borda inferior,
  /// enquanto a caixa do corpo termina a [marginBottomTwips] dessa borda.
  /// Se a altura real da região ultrapassa o espaço entre esses dois
  /// referenciais, o corpo termina antes. Ignorar essa interseção deixava
  /// cada página usar alguns pontos pertencentes ao rodapé e comprimía uma
  /// tabela longa em várias páginas a menos.
  int _footerBodyInsetTwips(
    PageSetupTwips pageSetup,
    PMNode? pageFooter,
    int pageIndex,
  ) {
    if (pageFooter == null) return 0;
    if (!_hasPageField(pageFooter)) {
      final bySetup = _staticFooterInsetCache.putIfAbsent(pageFooter, () => {});
      return bySetup.putIfAbsent(
        pageSetup,
        () => _computeFooterBodyInsetTwips(
          pageSetup,
          pageFooter,
          pageIndex,
        ),
      );
    }
    return _computeFooterBodyInsetTwips(pageSetup, pageFooter, pageIndex);
  }

  int _computeFooterBodyInsetTwips(
    PageSetupTwips pageSetup,
    PMNode pageFooter,
    int pageIndex,
  ) {
    final fragments = _composeRegion(
      pageFooter,
      LayoutDiagnostics(),
      pageIndex,
      1,
      regionSetup: pageSetup,
    );
    var extent = 0;
    for (final fragment in fragments) {
      final bottom = fragment.yTwips + fragment.heightTwips;
      if (bottom > extent) extent = bottom;
    }
    final inset =
        pageSetup.footerDistanceTwips + extent - pageSetup.marginBottomTwips;
    return inset > 0 ? inset : 0;
  }

  /// Resolve PAGE/NUMPAGES somente no clone usado pelo layout.
  ///
  /// O PM persistente mantém os markers do campo e TODOS os runs do cached
  /// result. Isso permite salvar sem congelar o número da página e sem
  /// substituir o cache por um literal `{PAGE}`. Placeholders textuais
  /// antigos continuam suportados fora de campos estruturados.
  PMNode _resolveFields(PMNode region, int pageNumber, int totalPages) {
    if (!_hasPageField(region)) return region;
    String replace(String text) => text.replaceAllMapped(_pageField,
        (match) => match.group(1) == 'PAGE' ? '$pageNumber' : '$totalPages');

    String? dynamicValue(String? command) => switch (command) {
          'PAGE' => '$pageNumber',
          'NUMPAGES' => '$totalPages',
          _ => null,
        };

    PMNode mapNode(PMNode node) {
      if (node.isText) {
        return node.type.schema.text(replace(node.text ?? ''), node.marks);
      }
      if (node.isTextblock) {
        final result = <PMNode>[];
        final fields = <_LayoutFieldState>[];

        _LayoutFieldState? activeDynamicField() {
          for (final field in fields.reversed) {
            if (field.inResult && dynamicValue(field.command) != null) {
              return field;
            }
          }
          return null;
        }

        for (var i = 0; i < node.childCount; i++) {
          final child = node.child(i);
          final insert =
              child.type.name == 'opaqueInline' ? child.attrs['insert'] : null;
          final marker = insert is Map ? insert['fieldMarker'] : null;
          if (marker == 'begin') {
            result.add(child);
            fields.add(_LayoutFieldState());
            continue;
          }
          if (marker == 'separate') {
            if (fields.isNotEmpty) {
              fields.last
                ..command = '${insert is Map ? insert['fieldCommand'] : ''}'
                    .toUpperCase()
                ..inResult = true;
            }
            result.add(child);
            continue;
          }
          if (marker == 'end') {
            if (fields.isNotEmpty) {
              final field = fields.last;
              final value = dynamicValue(field.command);
              final outerDynamic = fields.take(fields.length - 1).any((outer) =>
                  outer.inResult && dynamicValue(outer.command) != null);
              if (value != null && !field.emitted && !outerDynamic) {
                result.add(node.type.schema.text(value, child.marks));
                field.emitted = true;
              }
            }
            result.add(child);
            if (fields.isNotEmpty) fields.removeLast();
            continue;
          }

          final dynamic = activeDynamicField();
          if (dynamic != null) {
            // Other protected markers have no visual box and remain in the
            // clone. Cached visible content is replaced once, regardless of
            // how many styled runs represented the result.
            if (child.type.name == 'opaqueInline') {
              result.add(child);
              continue;
            }
            if (!dynamic.emitted) {
              final value = dynamicValue(dynamic.command)!;
              result.add(node.type.schema
                  .text(value, child.isText ? child.marks : const []));
              dynamic.emitted = true;
            }
            continue;
          }
          result.add(mapNode(child));
        }
        return node.copy(Fragment.from(result));
      }
      final children = <PMNode>[
        for (var i = 0; i < node.childCount; i++) mapNode(node.child(i))
      ];
      return node.copy(Fragment.from(children));
    }

    return mapNode(region);
  }

  /// O bloco pede página nova antes de si (quebra manual ou
  /// `w:pageBreakBefore` importado).
  static bool _pageBreakBefore(PMNode block) {
    final style = block.attrs['style'];
    return style is Map && style['pageBreakBefore'] == true;
  }

  /// OOXML range/proof markers preserved as block nodes by the lossless
  /// reader. They carry metadata only and must never manufacture a line.
  static const Set<String> _zeroLayoutOpaqueBlockQNames = {
    'w:bookmarkStart',
    'w:bookmarkEnd',
    'w:commentRangeStart',
    'w:commentRangeEnd',
    'w:permStart',
    'w:permEnd',
    'w:proofErr',
    'w:moveFromRangeStart',
    'w:moveFromRangeEnd',
    'w:moveToRangeStart',
    'w:moveToRangeEnd',
    'w:customXmlInsRangeStart',
    'w:customXmlInsRangeEnd',
    'w:customXmlDelRangeStart',
    'w:customXmlDelRangeEnd',
    'w:customXmlMoveFromRangeStart',
    'w:customXmlMoveFromRangeEnd',
    'w:customXmlMoveToRangeStart',
    'w:customXmlMoveToRangeEnd',
  };

  static bool _isZeroLayoutOpaqueBlock(PMNode block) {
    if (block.type.name != 'opaque') return false;
    final insert = block.attrs['insert'];
    if (insert is! Map) return false;
    return _zeroLayoutOpaqueBlockQNames.contains('${insert['qname']}');
  }

  static bool _isCollapsedTrailingCellParagraph(
    PMNode cell,
    PMNode block,
    int blockIndex,
  ) {
    return cell.childCount > 1 &&
        blockIndex == cell.childCount - 1 &&
        block.type.name == 'paragraph' &&
        block.childCount == 0 &&
        block.attrs['word'] is Map;
  }

  static bool _renderedPageBreakBefore(PMNode block) {
    final style = block.attrs['style'];
    return style is Map && style['renderedPageBreakBefore'] == true;
  }

  static bool _hasInlineRenderedPageBreakHint(PMNode block) {
    for (var i = 0; i < block.childCount; i++) {
      final child = block.child(i);
      if (child.type.name != 'opaqueInline') continue;
      final insert = child.attrs['insert'];
      if (insert is Map && insert['renderedPageBreakHint'] == true) {
        return true;
      }
    }
    return false;
  }

  static bool _hasVisualPageContent(List<PageFragment> fragments) =>
      fragments.any((fragment) => fragment.heightTwips > 0);

  /// Parágrafo cujo único conteúdo visual é uma quebra forçada do Word.
  ///
  /// A quebra continua sendo um inline editável, mas o parágrafo que serve
  /// apenas de contêiner não pode fabricar uma linha em branco além da
  /// fronteira de página. Bookmarks/range markers permanecem sem caixa.
  static bool _isImportedPageBreakOnlyParagraph(PMNode block) {
    if (block.type.name != 'paragraph') return false;
    var forcedBreaks = 0;
    var hasNonMetadataContent = false;
    for (var i = 0; i < block.childCount; i++) {
      final child = block.child(i);
      if (child.type.name == 'opaqueInline') continue;
      final breakType = child.attrs['breakType'];
      if (child.type.name == 'hardBreak' &&
          (breakType == 'page' || breakType == 'column')) {
        forcedBreaks++;
        continue;
      }
      hasNonMetadataContent = true;
      break;
    }
    if (hasNonMetadataContent) return false;
    if (forcedBreaks == 1) return true;

    // O importador também representa `w:pageBreakBefore` num parágrafo
    // vazio pelo style resolvido. O mapa `word` distingue esse caso de um
    // parágrafo vazio criado pelo usuário no editor: o primeiro é só a
    // fronteira importada e não deve consumir uma linha em branco própria.
    return forcedBreaks == 0 &&
        _pageBreakBefore(block) &&
        block.attrs['word'] is Map;
  }

  static bool _hasRenderedPageBreakHints(PMNode doc) {
    bool visit(PMNode node) {
      if (_renderedPageBreakBefore(node)) return true;
      if (node.type.name == 'opaqueInline') {
        final insert = node.attrs['insert'];
        if (insert is Map && insert['renderedPageBreakHint'] == true) {
          return true;
        }
      }
      for (var i = 0; i < node.childCount; i++) {
        if (visit(node.child(i))) return true;
      }
      return false;
    }

    return visit(doc);
  }

  /// O bloco encerra uma seção?
  ///
  /// A marca vem da importação (`style.sectionBreak`), que a lê do
  /// `w:pPr/w:sectPr` — o lugar onde o OOXML registra a quebra.
  static bool _endsSection(PMNode block) {
    final style = block.attrs['style'];
    return style is Map && style['sectionBreak'] == true;
  }

  static bool _continuesFrom(PageFragment fragment) => switch (fragment) {
        BlockFragment(:final continuesFromPreviousPage) =>
          continuesFromPreviousPage,
        TableFragment(:final continuesFromPreviousPage) =>
          continuesFromPreviousPage,
      };

  static int _lastDocPosOf(List<PageFragment> fragments) {
    var last = 0;
    for (final fragment in fragments) {
      final end = switch (fragment) {
        BlockFragment(:final docPos, :final lines) =>
          lines.isEmpty ? docPos : docPos + lines.last.charEnd,
        TableFragment(:final docPos, :final rows) => rows
            .where((row) => !row.isRepeatedHeader)
            .fold<int>(docPos,
                (value, row) => row.docPosEnd > value ? row.docPosEnd : value),
      };
      if (end > last) last = end;
    }
    return last;
  }

  // -- Estilo de bloco -------------------------------------------------------

  _BlockStyle _blockStyleOf(PMNode block, int listOrdinal) {
    final resolved = _resolvedStyleOf(block, listOrdinal);
    if (resolved != null) return resolved;
    return _heuristicStyleOf(block, listOrdinal);
  }

  int _collapsedSpaceBefore(int before, int? previousAfter) {
    if (previousAfter == null || previousAfter <= 0) return before;
    return before > previousAfter ? before - previousAfter : 0;
  }

  bool _usesContextualSpacing(_BlockStyle first, _BlockStyle second) {
    final firstId = first.wordStyleId;
    final secondId = second.wordStyleId;
    return firstId != null &&
        firstId.isNotEmpty &&
        firstId == secondId &&
        (first.contextualSpacing || second.contextualSpacing);
  }

  /// A apresentação que veio RESOLVIDA da importação (`attrs['style']`).
  ///
  /// Quando existe, ela manda: é a cascata real do documento
  /// (docDefaults → basedOn → estilo → formatação direta), não um palpite.
  /// A heurística por nível de heading continua como fallback para
  /// documentos que nunca passaram por um importador — Delta do Quill, por
  /// exemplo, onde `header: 1` é tudo que se sabe.
  /// O `style` resolvido é um mapa PARCIAL: cada chave presente sobrepõe a
  /// heurística, as ausentes herdam dela. Exigir o mapa completo faria a
  /// régua (que só grava recuos) apagar o tamanho de fonte do documento.
  _BlockStyle? _resolvedStyleOf(PMNode block, int listOrdinal) {
    final rawAttribute = block.attrs['style'];
    final word = block.attrs['word'];
    final markCandidate = block.textContent.isEmpty && word is Map
        ? word['markRunProperties']
        : null;
    final mark = markCandidate is Map ? markCandidate : null;
    if (rawAttribute is! Map && mark == null) return null;
    final raw = rawAttribute is Map ? rawAttribute : const <String, dynamic>{};

    final heuristic = _heuristicStyleOf(block, listOrdinal);
    final markSizeHalfPoints = mark?['sizeHalfPoints'];
    final sizePt = markSizeHalfPoints is num && markSizeHalfPoints > 0
        ? markSizeHalfPoints / 2.0
        : raw['sizePt'];
    int intOr(String key, int fallback) =>
        raw[key] is num ? (raw[key] as num).toInt() : fallback;
    return _BlockStyle(
      align: switch (raw['align'] ?? block.attrs['align']) {
        'center' => LayoutAlign.center,
        'right' => LayoutAlign.right,
        'justify' => LayoutAlign.justify,
        'left' => LayoutAlign.left,
        _ => heuristic.align,
      },
      baseSizePt: sizePt is num && sizePt > 0
          ? sizePt.toDouble()
          : heuristic.baseSizePt,
      bold: mark?['bold'] is bool
          ? mark!['bold'] as bool
          : raw['bold'] is bool
              ? raw['bold'] as bool
              : heuristic.bold,
      indentTwips: intOr('indentTwips', heuristic.indentTwips),
      rightIndentTwips: intOr('rightIndentTwips', heuristic.rightIndentTwips),
      firstLineIndentTwips:
          intOr('firstLineIndentTwips', heuristic.firstLineIndentTwips),
      spaceBeforeTwips: intOr('spaceBeforeTwips', heuristic.spaceBeforeTwips),
      spaceAfterTwips: intOr('spaceAfterTwips', heuristic.spaceAfterTwips),
      lineTwips: raw['lineTwips'] is num
          ? (raw['lineTwips'] as num).toInt()
          : heuristic.lineTwips,
      lineRule: raw['lineRule'] is String
          ? raw['lineRule'] as String
          : heuristic.lineRule,
      contextualSpacing: raw['contextualSpacing'] is bool
          ? raw['contextualSpacing'] as bool
          : heuristic.contextualSpacing,
      autoHyphenation: raw['autoHyphenation'] is bool
          ? raw['autoHyphenation'] as bool
          : heuristic.autoHyphenation,
      hyphenationZoneTwips: intOr(
        'hyphenationZoneTwips',
        heuristic.hyphenationZoneTwips,
      ),
      wordStyleId: raw['wordStyleId'] is String
          ? raw['wordStyleId'] as String
          : heuristic.wordStyleId,
      keepLines: raw['keepLines'] is bool
          ? raw['keepLines'] as bool
          : heuristic.keepLines,
      keepNext: raw['keepNext'] is bool
          ? raw['keepNext'] as bool
          : heuristic.keepNext,
      widowControl: raw['widowControl'] is bool
          ? raw['widowControl'] as bool
          : heuristic.widowControl,
      tabs: raw['tabs'] is List
          ? [
              for (final entry in raw['tabs'] as List)
                if (entry is Map && entry['posTwips'] is num)
                  _TabStop(
                    val: '${entry['val'] ?? 'left'}',
                    posTwips: (entry['posTwips'] as num).toInt(),
                    leader: entry['leader']?.toString(),
                  ),
            ]
          : heuristic.tabs,
      // O rótulo de numeração resolvido do `numbering.xml` ganha do
      // marcador heurístico: ele é o que o Word desenharia.
      marker:
          raw['marker'] is String ? raw['marker'] as String : heuristic.marker,
      markerSuffix: raw['markerSuffix'] is String
          ? raw['markerSuffix'] as String
          : heuristic.markerSuffix,
      family: mark?['fontAscii'] is String || mark?['fontHAnsi'] is String
          ? '${mark!['fontAscii'] ?? mark['fontHAnsi']}'
          : raw['family'] is String
              ? raw['family'] as String
              : heuristic.family,
    );
  }

  _BlockStyle _heuristicStyleOf(PMNode block, int listOrdinal) {
    final align = switch (block.attrs['align']) {
      'center' => LayoutAlign.center,
      'right' => LayoutAlign.right,
      'justify' => LayoutAlign.justify,
      _ => LayoutAlign.left,
    };
    switch (block.type.name) {
      case 'heading':
        final level = (block.attrs['level'] as num?)?.toInt() ?? 1;
        final scale = switch (level) {
          1 => 2.0,
          2 => 1.5,
          3 => 1.17,
          4 => 1.0,
          5 => 0.83,
          _ => 0.67,
        };
        return _BlockStyle(
          align: align,
          baseSizePt: baseFontSizePt * scale,
          bold: true,
        );
      case 'listItem':
        final rawIndent = block.attrs['indent'];
        final level = rawIndent is num
            ? rawIndent.toInt()
            : int.tryParse('$rawIndent') ?? 0;
        final kind = block.attrs['kind'];
        return _BlockStyle(
          align: align,
          baseSizePt: baseFontSizePt,
          indentTwips: _listIndentTwips * (1 + level),
          marker: kind == 'ordered' ? '$listOrdinal. ' : '• ',
        );
      case 'blockquote':
        return _BlockStyle(
          align: align,
          baseSizePt: baseFontSizePt,
          indentTwips: _ptToTwips(14),
        );
      case 'codeBlock':
        return _BlockStyle(
          align: align,
          baseSizePt: baseFontSizePt,
          family: 'Courier New',
        );
      default:
        return _BlockStyle(align: align, baseSizePt: baseFontSizePt);
    }
  }

  // -- Quebra de linha -------------------------------------------------------

  FontMetrics _metricsFor(String family) =>
      FontRegistry.instance.lookup(family) ??
      FontRegistry.instance.lookup(null)!;

  /// Cache tipográfico: a MESMA palavra, no mesmo estilo, é medida uma vez.
  ///
  /// Medir domina a composição (uma medida por palavra por tentativa de
  /// quebra) e o texto de um documento repete muito — artigos, preposições,
  /// e as palavras que sobrevivem a uma edição. A chave inclui todo o
  /// estilo que afeta o avanço; a face entra por família/peso/itálico, que
  /// é como `faceFor` resolve.
  /// Cache opcionalmente compartilhado entre recomposições do mesmo editor.
  /// A largura depende somente da chave tipográfica abaixo, não de papel,
  /// margens ou conteúdo vizinho, portanto sobrevive com segurança a zoom,
  /// mudança de seção e abertura de outro documento com o mesmo font set.
  final LayoutMeasurementCache _measureCache;
  final LayoutTableCache _tableCache;
  final LayoutTableLineCache _tableLineCache;

  /// Quantas medições distintas o cache guarda. Diagnóstico — é o que
  /// permite testar o cache sem cronômetro (comparar tempo de parede num
  /// teste é instável e pisca na CI).
  int get measurementCacheSize => _measureCache.length;
  int get tableCacheSize => _tableCache.length;
  int get tableCacheRowCount => _tableCache.rowCount;
  int get tableLineCacheSize => _tableLineCache.length;
  int get tableLineCacheHits => _tableLineCache.hitCount;

  double _measurePt(ResolvedRunStyle style, String text) {
    final face =
        fonts.faceFor(style.family, bold: style.bold, italic: style.italic);
    final authority = face ?? _metricsFor(style.family);
    final key = _MeasurementKey(
      authority: authority,
      sizePt: style.sizePt,
      letterSpacingTwips: style.letterSpacingTwips,
      text: text,
    );
    final cached = _measureCache._lookup(key);
    if (cached != null) return cached;
    final glyphWidth = face != null
        ? face.measureWidthPt(text, style.sizePt)
        : (authority as FontMetrics).measureWidth(text, style.sizePt);
    // OOXML acrescenta `w:spacing` DEPOIS de cada caractere do run.
    final width =
        glyphWidth + style.letterSpacingTwips * text.runes.length / 20.0;
    _measureCache._store(key, width);
    return width;
  }

  ({double ascent, double descent, double lineGap}) _verticalPt(
      ResolvedRunStyle style) {
    final face =
        fonts.faceFor(style.family, bold: style.bold, italic: style.italic);
    if (face != null) {
      return (
        ascent: face.ascentPt(style.sizePt),
        descent: face.descentPt(style.sizePt),
        lineGap: face.lineGapPt(style.sizePt),
      );
    }
    final m = _metricsFor(style.family);
    return (
      ascent: m.ascentPx(style.sizePt),
      descent: m.descentPx(style.sizePt),
      lineGap: m.lineGapPx(style.sizePt),
    );
  }

  int _lineHeightTwips(String family, double sizePt) {
    final v = _verticalPt(ResolvedRunStyle(family: family, sizePt: sizePt));
    return _ptToTwips(v.ascent + v.descent + v.lineGap);
  }

  int _resolvedLineHeightTwips(
    int natural,
    _BlockStyle style, {
    int? gridLinePitchTwips,
  }) {
    final requested = style.lineTwips;
    // Sem `w:spacing/@line`, o Word usa a caixa vertical real da fonte.
    // Com regra `auto`, 240/360/480 são multiplicadores dessa MESMA caixa
    // real (simples/1,5/duplo), não de um piso CSS de 1,2 em. O piso nominal
    // inflava, por exemplo, Arial 10 com line=276 de ~13,3 pt para 13,8 pt e
    // acumulava quase uma página no documento TR antes do primeiro anexo.
    final resolved = requested == null || requested <= 0
        ? natural
        : switch (style.lineRule?.toLowerCase()) {
            'exact' => requested,
            'atleast' ||
            'at-least' =>
              requested > natural ? requested : natural,
            // OOXML usa 240 = simples, 360 = 1,5 e 480 = duplo quando a
            // regra é auto (ou ausente). Apesar do nome histórico
            // `lineTwips`, neste caso o valor NÃO é uma distância absoluta.
            _ => (natural * requested / 240).round(),
          };
    final pitch = gridLinePitchTwips;
    if (pitch == null || pitch <= 0) return resolved;
    // `snapToGrid` é default no Word: uma linha ocupa uma ou mais faixas da
    // grade, nunca uma fração. O codec só passa o pitch ao corpo; células de
    // tabela ficam sem ele, como exige o default OOXML.
    return ((resolved + pitch - 1) ~/ pitch) * pitch;
  }

  ResolvedRunStyle _styleOfText(PMNode text, _BlockStyle blockStyle) {
    var family = blockStyle.family ?? baseFontFamily;
    var sizePt = blockStyle.baseSizePt;
    var bold = blockStyle.bold;
    var italic = false, underline = false, strike = false;
    var color = '#000000';
    String? link;
    var letterSpacingTwips = 0;
    for (final mark in text.marks) {
      switch (mark.type.name) {
        case 'bold':
          bold = true;
        case 'italic':
          italic = true;
        case 'underline':
          underline = true;
        case 'strike':
          strike = true;
        case 'font':
          family = '${mark.attrs['value']}';
        case 'size':
          sizePt = _parseSizePt('${mark.attrs['value']}') ?? sizePt;
        case 'color':
          color = '${mark.attrs['value']}';
        case 'link':
          link = '${mark.attrs['href']}';
        case 'letterSpacing':
          final raw = mark.attrs['twips'];
          letterSpacingTwips = raw is num
              ? raw.toInt()
              : int.tryParse('$raw') ?? letterSpacingTwips;
      }
    }
    return ResolvedRunStyle(
      family: family,
      sizePt: sizePt,
      bold: bold,
      italic: italic,
      underline: underline,
      strike: strike,
      color: color,
      link: link,
      letterSpacingTwips: letterSpacingTwips,
    );
  }

  static double? _parseSizePt(String value) {
    final match = RegExp(r'^([\d.]+)(pt|px)?$').firstMatch(value.trim());
    if (match == null) return null;
    final number = double.tryParse(match.group(1)!);
    if (number == null) return null;
    return match.group(2) == 'px' ? number * 0.75 : number;
  }

  ResolvedRunStyle _markerStyleOf(_BlockStyle style) => ResolvedRunStyle(
        family: style.family ?? baseFontFamily,
        sizePt: style.baseSizePt,
        bold: style.bold,
      );

  static const int _defaultTabStopTwips = 708;

  /// Separa a posição do rótulo automático da posição onde o texto começa.
  /// O rótulo é projeção; portanto o hanging não pode deslocar o texto PM
  /// de volta para cima dele.
  ({
    int textIndentTwips,
    int firstLineIndentTwips,
    int markerPositionTwips,
  }) _paragraphFlow(_BlockStyle style) {
    if (style.marker == null) {
      return (
        textIndentTwips: style.indentTwips,
        firstLineIndentTwips: style.firstLineIndentTwips,
        markerPositionTwips: 0,
      );
    }

    if (style.firstLineIndentTwips < 0) {
      final rawMarker = style.indentTwips + style.firstLineIndentTwips;
      final marker = rawMarker > 0 ? rawMarker : 0;
      final continuationIndent = style.indentTwips > 0 ? style.indentTwips : 0;
      final preferredTextIndent = style.indentTwips > marker
          ? style.indentTwips
          : _nextTabStop(style, marker).posTwips;
      // The default OOXML numbering suffix is a TAB. Once a multi-level
      // label grows from one to two digits (4.81.9. -> 4.81.10.), its painted
      // width can cross the preferred text stop. Word then advances the text
      // to the *next* stop; keeping the old stop makes label and first word
      // touch/overlap. Ignore the synthetic trailing space in `marker`: it is
      // a semantic suffix, not part of the label glyph width.
      final markerText = style.marker!.trimRight();
      final markerEnd =
          marker + _ptToTwips(_measurePt(_markerStyleOf(style), markerText));
      final firstLineTextIndent = switch (style.markerSuffix.toLowerCase()) {
        'nothing' => markerEnd,
        'space' =>
          marker + _ptToTwips(_measurePt(_markerStyleOf(style), style.marker!)),
        _ => markerEnd < preferredTextIndent
            ? preferredTextIndent
            : _nextTabStop(style, markerEnd).posTwips,
      };
      return (
        // O left indent posiciona as linhas de continuação. O tab depois do
        // número pode posicionar SOMENTE o texto da primeira linha mais à
        // direita. Em parágrafos com override direto `left=0/firstLine=0`,
        // o Word desenha "4.73." na margem, o primeiro texto no tab de 708
        // twips e todas as continuações novamente na margem.
        textIndentTwips: continuationIndent,
        firstLineIndentTwips: firstLineTextIndent - continuationIndent,
        markerPositionTwips: marker,
      );
    }

    // Fallback para listas criadas diretamente no editor, sem `w:ind`.
    final marker = style.indentTwips > _defaultTabStopTwips
        ? style.indentTwips - _defaultTabStopTwips
        : 0;
    return (
      textIndentTwips: style.indentTwips,
      firstLineIndentTwips: style.firstLineIndentTwips,
      markerPositionTwips: marker,
    );
  }

  _TabStop _nextTabStop(_BlockStyle style, int absoluteXTwips) {
    final clears = <int>{
      for (final stop in style.tabs)
        if (stop.val.toLowerCase() == 'clear') stop.posTwips,
    };
    _TabStop? explicit;
    for (final stop in style.tabs) {
      if (stop.val.toLowerCase() == 'clear' ||
          stop.posTwips <= absoluteXTwips) {
        continue;
      }
      if (explicit == null || stop.posTwips < explicit.posTwips) {
        explicit = stop;
      }
    }

    var defaultPos = absoluteXTwips < 0
        ? 0
        : (absoluteXTwips ~/ _defaultTabStopTwips + 1) * _defaultTabStopTwips;
    while (clears.contains(defaultPos)) {
      defaultPos += _defaultTabStopTwips;
    }
    // A presença de tab stops personalizados substitui a malha de tabs
    // padrão até o último stop aplicável. Em especial, um parágrafo de
    // rodapé costuma declarar somente `center` e `right`: o primeiro TAB
    // deve saltar direto ao stop central, não parar antes nos defaults de
    // 708 twips. Os defaults voltam a valer quando não resta stop explícito
    // à direita (ECMA-376, comportamento interoperável do Word).
    if (explicit != null) return explicit;
    return _TabStop(val: 'left', posTwips: defaultPos);
  }

  int _tabLookaheadWidth(List<_Token> tokens, int tabIndex,
      {bool beforeDecimal = false}) {
    var width = 0;
    for (var i = tabIndex + 1; i < tokens.length; i++) {
      final token = tokens[i];
      if (token.isTab || token.hardBreak) break;
      if (token.isOpaqueInline || token.textBox != null) continue;
      if (beforeDecimal && token.text.isNotEmpty) {
        final match = RegExp(r'[\.,]').firstMatch(token.text);
        if (match != null) {
          final prefix = token.text.substring(0, match.start);
          width += _ptToTwips(_measurePt(token.style, prefix));
          break;
        }
      }
      width += token.widthTwips;
    }
    return width;
  }

  _Token _resolvedTabToken(
    _Token token,
    int tokenIndex,
    List<_Token> tokens,
    _BlockStyle style,
    int currentWidth,
    bool firstLine,
  ) {
    final flow = _paragraphFlow(style);
    final lineIndent = firstLine ? flow.firstLineIndentTwips : 0;
    final absoluteX = flow.textIndentTwips + lineIndent + currentWidth;
    final stop = _nextTabStop(style, absoluteX);
    final alignment = stop.val.toLowerCase();
    final lookahead = switch (alignment) {
      'center' => _tabLookaheadWidth(tokens, tokenIndex) ~/ 2,
      'right' => _tabLookaheadWidth(tokens, tokenIndex),
      'decimal' => _tabLookaheadWidth(tokens, tokenIndex, beforeDecimal: true),
      _ => 0,
    };
    final advance = stop.posTwips - absoluteX - lookahead;
    return _Token(
      text: token.text,
      style: token.style,
      isSpace: false,
      widthTwips: advance > 0 ? advance : 0,
      charStart: token.charStart,
      isTab: true,
      tabLeader: stop.leader,
      modelLength: token.modelLength,
    );
  }

  static bool _isLatinLetter(int codeUnit) =>
      (codeUnit >= 0x41 && codeUnit <= 0x5a) ||
      (codeUnit >= 0x61 && codeUnit <= 0x7a) ||
      (codeUnit >= 0xc0 && codeUnit <= 0xd6) ||
      (codeUnit >= 0xd8 && codeUnit <= 0xf6) ||
      (codeUnit >= 0xf8 && codeUnit <= 0xff);

  static bool _isHyphenationVowel(int codeUnit) {
    final char = String.fromCharCode(codeUnit).toLowerCase();
    return 'aeiouáéíóúâêôãõàü'.contains(char);
  }

  /// Pontos silábicos conservadores para palavras latinas.
  ///
  /// O DOCX não armazena os hífens automáticos; o Word os calcula a
  /// partir do idioma/dicionário. Aqui reproduzimos a parte determinística
  /// necessária ao layout: V-C-V quebra antes da consoante e, em grupos,
  /// preservamos ataques comuns (br, pr, tr, ch, lh, nh etc.). Pontos muito
  /// perto das extremidades são descartados para não fragmentar palavras
  /// curtas.
  static List<int> _automaticHyphenationPoints(String text) {
    var coreEnd = text.length;
    while (coreEnd > 0 && !_isLatinLetter(text.codeUnitAt(coreEnd - 1))) {
      coreEnd--;
    }
    if (coreEnd < 5) return const [];
    for (var i = 0; i < coreEnd; i++) {
      if (!_isLatinLetter(text.codeUnitAt(i))) return const [];
    }

    const onsetPairs = {
      'bl',
      'br',
      'ch',
      'cl',
      'cr',
      'dr',
      'fl',
      'fr',
      'gl',
      'gr',
      'gu',
      'lh',
      'nh',
      'pl',
      'pr',
      'qu',
      'tl',
      'tr',
      'vr',
    };
    final points = <int>[];
    var index = 0;
    while (index < coreEnd && !_isHyphenationVowel(text.codeUnitAt(index))) {
      index++;
    }
    while (index < coreEnd) {
      // Uma sequência de vogais é tratada como um único núcleo. Isso
      // evita inventar quebras em ditongos sem um dicionário linguístico.
      while (index < coreEnd && _isHyphenationVowel(text.codeUnitAt(index))) {
        index++;
      }
      final consonantStart = index;
      while (index < coreEnd && !_isHyphenationVowel(text.codeUnitAt(index))) {
        index++;
      }
      if (index >= coreEnd) break; // sem outro núcleo: sufixo final
      final consonantCount = index - consonantStart;
      if (consonantCount <= 0) continue;
      var cut = consonantStart;
      if (consonantCount > 1) {
        final pair = text.substring(index - 2, index).toLowerCase();
        cut = onsetPairs.contains(pair) ? index - 2 : index - 1;
      }
      if (cut >= 2 && coreEnd - cut >= 2) points.add(cut);
    }
    return points;
  }

  static bool _isHangingPunctuation(String text) {
    if (text.isEmpty) return false;
    return '.,;:!?)]}\u00bb”’'.contains(text.substring(text.length - 1));
  }

  List<LineBox> _breakTableLines(
    PMNode block,
    int widthTwips,
    _BlockStyle blockStyle,
    LayoutDiagnostics diagnostics, {
    required bool honorRenderedPageBreaks,
  }) {
    final effectiveRenderedHints =
        honorRenderedPageBreaks && _hasInlineRenderedPageBreakHint(block);
    final key = _TableLineKey(
      block: block,
      widthTwips: widthTwips,
      honorRenderedPageBreaks: effectiveRenderedHints,
      fontSignature: _FontSetSignature(fonts),
      baseFontFamily: baseFontFamily,
      baseFontSizePt: baseFontSizePt,
      fontRegistryGeneration: FontRegistry.instance.generation,
    );
    final cached = _tableLineCache._lookup(key);
    if (cached != null) {
      diagnostics.warnings.addAll(cached.warnings);
      return cached.lines;
    }
    final localDiagnostics = LayoutDiagnostics();
    final lines = _breakLines(
      block,
      widthTwips,
      blockStyle,
      localDiagnostics,
      honorRenderedPageBreaks: honorRenderedPageBreaks,
    );
    diagnostics.warnings.addAll(localDiagnostics.warnings);
    _tableLineCache._store(
      key,
      _CachedTableLines(lines, localDiagnostics.warnings),
    );
    return lines;
  }

  /// Quebra o conteúdo inline de [block] em linhas de até [widthTwips].
  List<LineBox> _breakLines(
    PMNode block,
    int widthTwips,
    _BlockStyle blockStyle,
    LayoutDiagnostics diagnostics, {
    bool honorRenderedPageBreaks = true,
    int? gridLinePitchTwips,
  }) {
    final flow = _paragraphFlow(blockStyle);
    // Tokens (palavra/espaço) com estilo, mantendo o offset de caractere.
    final tokens = <_Token>[];
    var charOffset = 0;
    block.content.forEach((child, offset, index) {
      if (child.isText) {
        final style = _styleOfText(child, blockStyle);
        final text = child.text!;
        // Tab é unidade própria: não pode ser colapsado junto com espaços,
        // especialmente quando abre o parágrafo.
        final re = RegExp(r'(\t)|([^\S\t]+)|([^\s]+)');
        for (final m in re.allMatches(text)) {
          final piece = m.group(0)!;
          final isTab = m.group(1) != null;
          tokens.add(_Token(
            text: piece,
            style: style,
            isSpace: m.group(2) != null,
            widthTwips: isTab ? 0 : _ptToTwips(_measurePt(style, piece)),
            charStart: charOffset + m.start,
            isTab: isTab,
          ));
        }
        charOffset += text.length;
      } else if (child.type.name == 'hardBreak') {
        final style = _styleOfText(child, blockStyle);
        final breakType = child.attrs['breakType'];
        tokens.add(_Token(
          text: '\n',
          style: style,
          isSpace: false,
          widthTwips: 0,
          charStart: charOffset,
          hardBreak: true,
          // O PageGraph atual é monocoluna. Nesse fluxo, a próxima coluna
          // disponível depois de `<w:br w:type="column"/>` é a primeira
          // coluna da página seguinte, exatamente como o Word.
          pageBreak: breakType == 'page' || breakType == 'column',
          modelLength: child.nodeSize,
        ));
        charOffset += child.nodeSize;
      } else if (child.type.name == 'opaqueInline') {
        final insert = child.attrs['insert'];
        tokens.add(_Token(
          text: '',
          style: _styleOfText(child, blockStyle),
          isSpace: false,
          widthTwips: 0,
          charStart: charOffset,
          isOpaqueInline: true,
          renderedPageBreakHint:
              insert is Map && insert['renderedPageBreakHint'] == true,
          modelLength: child.nodeSize,
        ));
        charOffset += child.nodeSize;
      } else if (child.type.name == 'textBox') {
        int integer(String key, int fallback) {
          final raw = child.attrs[key];
          return raw is num ? raw.toInt() : int.tryParse('$raw') ?? fallback;
        }

        final style = _styleOfText(child, blockStyle);
        final width = integer('width', 2880);
        final insetLeft = integer('insetLeft', 0);
        final insetTop = integer('insetTop', 0);
        final insetRight = integer('insetRight', 0);
        final insetBottom = integer('insetBottom', 0);
        tokens.add(_Token(
          text: '',
          style: style,
          isSpace: false,
          widthTwips: 0,
          charStart: charOffset,
          textBox: FloatingTextBoxLayout(
            text: '${child.attrs['text'] ?? ''}',
            widthTwips: width,
            heightTwips: integer('height', 720),
            contentBlocks: _composeTextBoxContent(
              child,
              width,
              insetLeft,
              insetRight,
              diagnostics,
            ),
            insetLeftTwips: insetLeft,
            insetTopTwips: insetTop,
            insetRightTwips: insetRight,
            insetBottomTwips: insetBottom,
            offsetXTwips: integer('offsetX', 0),
            offsetYTwips: integer('offsetY', 0),
            positionHAlign: child.attrs['positionHAlign']?.toString(),
            positionVRelativeFrom:
                child.attrs['positionVRelativeFrom']?.toString(),
            borderWidthTwips: integer('borderWidth', 0),
            borderColor: child.attrs['borderColor']?.toString() ?? '#000000',
            backgroundColor: child.attrs['background']?.toString(),
            wrapTopAndBottom: (child.attrs['word']?.toString() ?? '')
                .contains('wrapTopAndBottom'),
            charStartInBlock: charOffset,
          ),
          modelLength: child.nodeSize,
        ));
        charOffset += child.nodeSize;
      } else {
        // Embed inline (imagem etc.): v1 reserva uma caixa quadrada da
        // altura da linha; a medição real entra com o suporte a imagem.
        diagnostics.warnings
            .add('embed inline ${child.type.name} medido como caixa padrão');
        final style =
            ResolvedRunStyle(family: baseFontFamily, sizePt: baseFontSizePt);
        tokens.add(_Token(
          text: '￼',
          style: style,
          isSpace: false,
          widthTwips: child.type.name == 'image'
              ? (child.attrs['width'] as num?)?.toInt() ??
                  _ptToTwips(baseFontSizePt)
              : _ptToTwips(baseFontSizePt),
          charStart: charOffset,
          imageSrc:
              child.type.name == 'image' ? child.attrs['src'] as String? : null,
          imageHeightTwips: child.type.name == 'image'
              ? (child.attrs['height'] as num?)?.toInt()
              : null,
        ));
        charOffset += child.nodeSize;
      }
    });

    final lines = <LineBox>[];
    var current = <_Token>[];
    var currentWidth = 0;
    var currentCompressibleSpaceWidth = 0;
    var currentHangingPunctuationWidth = 0;
    var manualPageBreakBeforeNextLine = false;
    var renderedBreakBeforeNextLine = false;

    // A primeira linha tem largura própria: o recuo de primeira linha a
    // encurta (positivo) ou alarga (pendente, negativo).
    int lineWidthLimit() {
      if (lines.isNotEmpty) return widthTwips;
      final first = widthTwips - flow.firstLineIndentTwips;
      return first < 400 ? 400 : first;
    }

    int ordinarySpaceCount(String text) {
      var count = 0;
      for (final rune in text.runes) {
        if (rune == 0x20) count++;
      }
      return count;
    }

    int compressibleSpaceWidth(_Token token) {
      if (!token.isSpace) return 0;
      final runeCount = token.text.runes.length;
      if (runeCount == 0) return 0;
      final spaces = ordinarySpaceCount(token.text);
      if (spaces == 0) return 0;
      // Na prática tokens OOXML são sequências homogêneas de U+0020. A
      // proporção mantém correto também um token raro com whitespace misto.
      return (token.widthTwips * spaces / runeCount).round();
    }

    bool fitsWithWordJustification(int candidateWidth, int limit) {
      if (candidateWidth <= limit) return true;
      if (blockStyle.align != LayoutAlign.justify ||
          currentCompressibleSpaceWidth <= 0) {
        return false;
      }
      // O line breaker do Word admite no máximo 20% de contração do avanço
      // dos espaços. A conta inteira evita instabilidade de arredondamento.
      return candidateWidth * 5 - currentCompressibleSpaceWidth <= limit * 5;
    }

    bool fitsAutomaticHyphen(int candidateWidth, int limit) {
      if (candidateWidth <= limit) return true;
      if (blockStyle.align != LayoutAlign.justify ||
          currentCompressibleSpaceWidth <= 0) {
        return false;
      }
      // O Word evita escolher um ponto de hifenização que deixe a linha
      // excessivamente apertada, mesmo quando a contração-limite ainda
      // faria o texto caber. 20% reproduz essa escolha tipográfica e, por
      // exemplo, prefere `obriga-` a `obrigató-` no corpus de referência.
      return candidateWidth * 5 - currentCompressibleSpaceWidth <= limit * 5;
    }

    int hangingPunctuationWidth(_Token token) {
      if (!_isHangingPunctuation(token.text)) return 0;
      final prefix = token.text.substring(0, token.text.length - 1);
      final prefixWidth = _ptToTwips(_measurePt(token.style, prefix));
      final width = token.widthTwips - prefixWidth;
      return width > 0 ? width : 0;
    }

    void flush({bool wrappedByWidth = false}) {
      if (current.isEmpty) return;
      // Espaços separadores são mantidos no modelo/DOM para o PositionMap,
      // mas um espaço no fim da linha não participa da largura visual nem da
      // distribuição de justificação do Word.
      var lastVisibleToken = current.length - 1;
      while (lastVisibleToken >= 0 &&
          (current[lastVisibleToken].isSpace ||
              current[lastVisibleToken].hardBreak ||
              current[lastVisibleToken].isOpaqueInline ||
              current[lastVisibleToken].textBox != null)) {
        lastVisibleToken--;
      }
      var visibleWidth = 0;
      var visibleSpaceCount = 0;
      for (var i = 0; i <= lastVisibleToken; i++) {
        visibleWidth += current[i].widthTwips;
        visibleSpaceCount += ordinarySpaceCount(current[i].text);
      }
      var wordSpacingTwips = 0.0;
      final effectiveVisibleWidth =
          visibleWidth - currentHangingPunctuationWidth;
      if (blockStyle.align == LayoutAlign.justify &&
          visibleSpaceCount > 0 &&
          (wrappedByWidth || effectiveVisibleWidth > lineWidthLimit())) {
        wordSpacingTwips =
            (lineWidthLimit() - effectiveVisibleWidth) / visibleSpaceCount;
      }
      // Segmentos: funde tokens adjacentes com o mesmo estilo.
      final segments = <LineSegment>[];
      for (final token in current) {
        if (segments.isNotEmpty &&
            segments.last.imageSrc == null &&
            token.imageSrc == null &&
            !segments.last.hardBreak &&
            !token.hardBreak &&
            !segments.last.isTab &&
            !token.isTab &&
            !segments.last.isOpaqueInline &&
            !token.isOpaqueInline &&
            !segments.last.isDiscretionaryHyphen &&
            !token.isDiscretionaryHyphen &&
            segments.last.textBox == null &&
            token.textBox == null &&
            identical(segments.last.style, token.style)) {
          segments[segments.length - 1] = LineSegment(
            text: segments.last.text + token.text,
            style: segments.last.style,
            widthTwips: segments.last.widthTwips + token.widthTwips,
          );
        } else {
          segments.add(LineSegment(
            text: token.text,
            style: token.style,
            widthTwips: token.widthTwips,
            imageSrc: token.imageSrc,
            imageHeightTwips: token.imageHeightTwips,
            hardBreak: token.hardBreak,
            isTab: token.isTab,
            tabLeader: token.tabLeader,
            isOpaqueInline: token.isOpaqueInline,
            isDiscretionaryHyphen: token.isDiscretionaryHyphen,
            textBox: token.textBox,
          ));
        }
      }
      var ascent = 0, height = 0;
      for (final segment in segments) {
        if (segment.isOpaqueInline || segment.textBox != null) continue;
        final v = _verticalPt(segment.style);
        final gap = _ptToTwips(v.lineGap);
        final a = _ptToTwips(v.ascent) + gap ~/ 2;
        final h = _ptToTwips(v.ascent) + _ptToTwips(v.descent) + gap;
        if (a > ascent) ascent = a;
        if (h > height) height = h;
        if (segment.imageHeightTwips != null &&
            segment.imageHeightTwips! > height) {
          height = segment.imageHeightTwips!;
        }
      }
      if (height == 0) {
        height = _lineHeightTwips(baseFontFamily, blockStyle.baseSizePt);
        ascent = height;
      }
      final naturalHeight = height;
      height = _resolvedLineHeightTwips(
        naturalHeight,
        blockStyle,
        gridLinePitchTwips: gridLinePitchTwips,
      );
      ascent += (height - naturalHeight) ~/ 2;
      if (ascent < 0) ascent = 0;
      if (ascent > height) ascent = height;
      lines.add(LineBox(
        segments: segments,
        widthTwips: wordSpacingTwips == 0
            ? currentWidth
            : (visibleWidth + wordSpacingTwips * visibleSpaceCount).round(),
        ascentTwips: ascent,
        heightTwips: height,
        charStart: current.first.charStart,
        charEnd: current.last.charEnd,
        // O recuo de primeira linha só vale para a PRIMEIRA linha do bloco.
        indentTwips: lines.isEmpty ? flow.firstLineIndentTwips : 0,
        wordSpacingTwips: wordSpacingTwips,
        manualPageBreakBefore: manualPageBreakBeforeNextLine,
        renderedPageBreakBefore: renderedBreakBeforeNextLine,
      ));
      current = [];
      currentWidth = 0;
      currentCompressibleSpaceWidth = 0;
      currentHangingPunctuationWidth = 0;
      manualPageBreakBeforeNextLine = false;
      renderedBreakBeforeNextLine = false;
    }

    var endedWithHardBreak = false;
    bool currentHasFlow() =>
        current.any((token) => !token.isOpaqueInline && token.textBox == null);

    for (var tokenIndex = 0; tokenIndex < tokens.length; tokenIndex++) {
      var token = tokens[tokenIndex];
      if (token.hardBreak) {
        current.add(token);
        flush();
        if (token.pageBreak) manualPageBreakBeforeNextLine = true;
        endedWithHardBreak = true;
        continue;
      }
      if (token.isTab) {
        token = _resolvedTabToken(
            token, tokenIndex, tokens, blockStyle, currentWidth, lines.isEmpty);
        if (currentWidth + token.widthTwips > lineWidthLimit() &&
            currentHasFlow()) {
          flush(wrappedByWidth: true);
          token = _resolvedTabToken(
              token, tokenIndex, tokens, blockStyle, currentWidth, false);
        }
        current.add(token);
        currentWidth += token.widthTwips;
        endedWithHardBreak = false;
        continue;
      }
      if (token.renderedPageBreakHint && honorRenderedPageBreaks) {
        // O marker fica imediatamente ANTES do primeiro conteúdo da página
        // seguinte. Fechar a linha visível corrente aqui preserva inclusive
        // markers no meio de um run, sem dar largura ou glifo ao nó opaco.
        if (currentHasFlow()) flush();
        renderedBreakBeforeNextLine = true;
        current.add(token);
        endedWithHardBreak = false;
        continue;
      }
      if (token.isOpaqueInline || token.textBox != null) {
        current.add(token);
        endedWithHardBreak = false;
        continue;
      }
      if (token.isSpace) {
        if (!currentHasFlow()) continue; // colapsa espaço no início da linha
        current.add(token);
        currentWidth += token.widthTwips;
        currentCompressibleSpaceWidth += compressibleSpaceWidth(token);
        continue;
      }
      endedWithHardBreak = false;
      final candidateWidth = currentWidth + token.widthTwips;
      if (!fitsWithWordJustification(candidateWidth, lineWidthLimit()) &&
          currentHasFlow()) {
        final hangingWidth = hangingPunctuationWidth(token);
        if (hangingWidth > 0 &&
            fitsWithWordJustification(
                candidateWidth - hangingWidth, lineWidthLimit())) {
          // Pontuação pendurada ganha de hifenizar a palavra. O Word aplica
          // isso em toda margem de linha, não apenas no fim do parágrafo.
          currentHangingPunctuationWidth = hangingWidth;
        } else {
          var hyphenated = false;
          // `w:hyphenationZone` is the amount of ragged whitespace Word
          // accepts at the right edge before it tries a discretionary hyphen.
          // Hyphenating every overflowing word ignores that zone and creates
          // visibly more breaks than Word (for example demonstra-ção in the
          // production TR). The whitespace token immediately before the word
          // is trimmed when the line flushes, so exclude it from the gap.
          var trailingSpaceTwips = 0;
          for (final currentToken in current.reversed) {
            if (!currentToken.isSpace) break;
            trailingSpaceTwips += currentToken.widthTwips;
          }
          final raggedGap = lineWidthLimit() -
              (currentWidth - trailingSpaceTwips).clamp(0, currentWidth);
          if (blockStyle.autoHyphenation &&
              raggedGap > blockStyle.hyphenationZoneTwips &&
              token.modelLength == token.text.length) {
            final hyphenWidth = _ptToTwips(_measurePt(token.style, '-'));
            final points = _automaticHyphenationPoints(token.text);
            for (final cut in points.reversed) {
              final headText = token.text.substring(0, cut);
              final headWidth = _ptToTwips(_measurePt(token.style, headText));
              if (!fitsAutomaticHyphen(
                  currentWidth + headWidth + hyphenWidth, lineWidthLimit())) {
                continue;
              }
              current.add(_Token(
                text: headText,
                style: token.style,
                isSpace: false,
                widthTwips: headWidth,
                charStart: token.charStart,
                modelLength: cut,
              ));
              currentWidth += headWidth;
              current.add(_Token(
                text: '-',
                style: token.style,
                isSpace: false,
                widthTwips: hyphenWidth,
                charStart: token.charStart + cut,
                modelLength: 0,
                isDiscretionaryHyphen: true,
              ));
              currentWidth += hyphenWidth;
              flush(wrappedByWidth: true);
              final tailText = token.text.substring(cut);
              token = _Token(
                text: tailText,
                style: token.style,
                isSpace: false,
                widthTwips: _ptToTwips(_measurePt(token.style, tailText)),
                charStart: token.charStart + cut,
                modelLength: token.modelLength - cut,
              );
              hyphenated = true;
              break;
            }
          }
          if (!hyphenated) {
            flush(wrappedByWidth: true);
          }
        }
      }
      if (token.widthTwips > widthTwips && !currentHasFlow()) {
        // Palavra maior que a coluna: corte duro por caracteres.
        var rest = token;
        while (rest.widthTwips > widthTwips && rest.text.length > 1) {
          var cut = rest.text.length - 1;
          while (cut > 1 &&
              _ptToTwips(_measurePt(rest.style, rest.text.substring(0, cut))) >
                  widthTwips) {
            cut--;
          }
          final head = rest.text.substring(0, cut);
          current.add(_Token(
            text: head,
            style: rest.style,
            isSpace: false,
            widthTwips: _ptToTwips(_measurePt(rest.style, head)),
            charStart: rest.charStart,
          ));
          currentWidth += current.last.widthTwips;
          flush(wrappedByWidth: true);
          rest = _Token(
            text: rest.text.substring(cut),
            style: rest.style,
            isSpace: false,
            widthTwips:
                _ptToTwips(_measurePt(rest.style, rest.text.substring(cut))),
            charStart: rest.charStart + cut,
          );
        }
        current.add(rest);
        currentWidth += rest.widthTwips;
        continue;
      }
      current.add(token);
      currentWidth += token.widthTwips;
    }
    flush();
    if (endedWithHardBreak) {
      final natural = _lineHeightTwips(
          blockStyle.family ?? baseFontFamily, blockStyle.baseSizePt);
      final height = _resolvedLineHeightTwips(
        natural,
        blockStyle,
        gridLinePitchTwips: gridLinePitchTwips,
      );
      final ascent = natural + (height - natural) ~/ 2;
      lines.add(LineBox(
        segments: const [],
        widthTwips: 0,
        ascentTwips: ascent < 0 ? 0 : (ascent > height ? height : ascent),
        heightTwips: height,
        charStart: charOffset,
        charEnd: charOffset,
        manualPageBreakBefore: manualPageBreakBeforeNextLine,
      ));
    }
    return lines;
  }
}

extension _TableComposition on LayoutComposer {
  /// Larguras de coluna resolvidas em twips.
  ///
  /// DOCX importado entrega `List<int>` (o `w:tblGrid` já está em twips);
  /// Quill entrega mapas `{width: px}`. Confundir os dois encolhia uma grade
  /// Word de 2400 twips para 72px e era a principal causa de tabelas
  /// espremidas depois da importação.
  List<int> _tableColumnWidths(
    PMNode table,
    int available, {
    required int minimumColumns,
  }) {
    var widths = <int>[];
    final colWidths = table.attrs['colWidths'];
    if (colWidths is List && colWidths.isNotEmpty) {
      for (final col in colWidths) {
        final width = _columnWidthTwips(col);
        if (width != null && width > 0) widths.add(width);
      }
    }

    while (widths.length < minimumColumns) {
      final missing = minimumColumns - widths.length;
      final used = widths.fold<int>(0, (sum, width) => sum + width);
      final remainder = available - used;
      widths.add(remainder > 0 ? (remainder / missing).round() : 1080);
    }
    if (widths.isEmpty) widths = [available];

    final total = widths.fold<int>(0, (sum, width) => sum + width);
    if (total > available && total > 0) {
      widths = [
        for (final width in widths) (width * available / total).round()
      ];
      // Compensa o arredondamento para a borda direita continuar exata.
      final scaledTotal = widths.fold<int>(0, (sum, width) => sum + width);
      widths[widths.length - 1] += available - scaledTotal;
    }
    return widths;
  }

  int? _columnWidthTwips(dynamic value) {
    // `tblGrid` importado: o número já é twips.
    if (value is num) return value.round();
    if (value is! Map) return null;

    final explicitTwips = value['widthTwips'] ??
        (value['unit'] == 'twips' ? value['width'] : null);
    if (explicitTwips != null) {
      return explicitTwips is num
          ? explicitTwips.round()
          : int.tryParse('$explicitTwips');
    }

    // Dialeto table-better/Quill: `width` está em CSS px.
    final rawPx = value['width'];
    final px = rawPx is num ? rawPx.toDouble() : double.tryParse('$rawPx');
    return px == null ? null : (px * 15).round();
  }

  _TableLayoutKey _tableLayoutKey(
    PMNode table, {
    required int tableDocPos,
    required int availableTwips,
    required bool honorRenderedPageBreaks,
  }) =>
      _TableLayoutKey(
        table: table,
        tableDocPos: tableDocPos,
        availableTwips: availableTwips,
        honorRenderedPageBreaks: honorRenderedPageBreaks,
        fontSignature: _FontSetSignature(fonts),
        baseFontFamily: baseFontFamily,
        baseFontSizePt: baseFontSizePt,
        quality: quality,
        fontRegistryGeneration: FontRegistry.instance.generation,
      );

  List<TableRowBox> _composeTableRows(
    PMNode table,
    LayoutDiagnostics diagnostics, {
    required int tableDocPos,
    required int availableTwips,
    required bool honorRenderedPageBreaks,
  }) {
    final key = _tableLayoutKey(
      table,
      tableDocPos: tableDocPos,
      availableTwips: availableTwips,
      honorRenderedPageBreaks: honorRenderedPageBreaks,
    );
    final cached = _tableCache._lookup(key);
    if (cached != null) {
      diagnostics.warnings.addAll(cached.warnings);
      // Pagination splits rows by replacing/inserting entries. The cached
      // boxes themselves are immutable, so a shallow outer copy is enough.
      return List<TableRowBox>.of(cached.rows);
    }
    final localDiagnostics = LayoutDiagnostics();
    final rows = _composeTableRowsFresh(
      table,
      localDiagnostics,
      tableDocPos: tableDocPos,
      availableTwips: availableTwips,
      honorRenderedPageBreaks: honorRenderedPageBreaks,
    );
    diagnostics.warnings.addAll(localDiagnostics.warnings);
    _tableCache._store(
      key,
      _CachedTableLayout(rows, localDiagnostics.warnings),
    );
    return List<TableRowBox>.of(rows);
  }

  List<TableRowBox> _composeTableRowsFresh(
    PMNode table,
    LayoutDiagnostics diagnostics, {
    required int tableDocPos,
    required int availableTwips,
    required bool honorRenderedPageBreaks,
  }) {
    final build = _TableRowsBuild(
      table: table,
      diagnostics: diagnostics,
      tableDocPos: tableDocPos,
      availableTwips: availableTwips,
      honorRenderedPageBreaks: honorRenderedPageBreaks,
    );
    for (final _ in _composeTableRowsSteps(build)) {
      // The synchronous path intentionally drains the same state machine
      // used by cooperative import warmup.
    }
    return build.result!;
  }

  Iterable<bool> _composeTableRowsSteps(_TableRowsBuild build) sync* {
    final table = build.table;
    final diagnostics = build.diagnostics;
    final tableDocPos = build.tableDocPos;
    final availableTwips = build.availableTwips;
    final honorRenderedPageBreaks = build.honorRenderedPageBreaks;
    final tableWord = _map(table.attrs['word']);
    final sourceTableId = officeNodeId(table);
    final tableMargins = _map(tableWord?['cellMargins']);
    // Para tabelas Word, a ausência de tblCellMar usa o default da grade:
    // 0 em cima/baixo e 108 twips nas laterais. Tabelas Quill sem metadados
    // mantêm o padding histórico de 60 twips em todos os lados.
    final wordTable = tableWord != null;
    final tableMarginTop =
        _wordMarginTwips(tableMargins?['top'], wordTable ? 0 : 60);
    final tableMarginRight =
        _wordMarginTwips(tableMargins?['right'], wordTable ? 108 : 60);
    final tableMarginBottom =
        _wordMarginTwips(tableMargins?['bottom'], wordTable ? 0 : 60);
    final tableMarginLeft =
        _wordMarginTwips(tableMargins?['left'], wordTable ? 108 : 60);
    final rowSpecs = <_TableRowSpec>[];
    var hasWordVerticalMerge = false;

    var rowOffset = 0;
    for (var rowIndex = 0; rowIndex < table.childCount; rowIndex++) {
      final row = table.child(rowIndex);
      final rowWord = _map(row.attrs['word']);
      final rowDocPos = tableDocPos + rowOffset + 1;
      final rowSpec = _TableRowSpec(
        node: row,
        rowIndex: rowIndex,
        docPos: rowDocPos,
        sourceTableId: sourceTableId,
        sourceRowId: _sourceNodeId(row, 'rowId'),
        sourceRowIndex: _nonNegativeInt(rowWord?['sourceRowIndex']) ?? rowIndex,
        heightTwips: _positiveInt(rowWord?['heightTwips']),
        heightRule: rowWord?['heightRule'] as String?,
        cantSplit: rowWord?['cantSplit'] == true,
        repeatHeader: rowWord?['tblHeader'] == true,
        gridBefore: _positiveInt(rowWord?['gridBefore']) ?? 0,
        gridAfter: _positiveInt(rowWord?['gridAfter']) ?? 0,
        widthBeforeTwips: _wordWidthTwips(rowWord?['widthBefore']),
        widthAfterTwips: _wordWidthTwips(rowWord?['widthAfter']),
      );
      row.content.forEach((cell, cellOffset, cellIndex) {
        final cellMap = _map(cell.attrs['cell']);
        final word = _map(cell.attrs['word']);
        final cellMargins = _map(word?['margins']);
        final vMerge = '${cellMap?['vMerge'] ?? word?['vMerge'] ?? ''}'
            .trim()
            .toLowerCase();
        if (vMerge.isNotEmpty) hasWordVerticalMerge = true;
        final cellDocPos = rowDocPos + cellOffset + 1;
        rowSpec.cells.add(_TableCellSpec(
          node: cell,
          rowIndex: rowIndex,
          cellIndex: cellIndex,
          docPos: cellDocPos,
          sourceCellId: _sourceNodeId(cell, 'cellId'),
          sourceCellIndex:
              _nonNegativeInt(word?['sourceCellIndex']) ?? cellIndex,
          columnSpan:
              _positiveInt(cellMap?['colspan'] ?? word?['gridSpan']) ?? 1,
          rowSpan: _positiveInt(cellMap?['rowspan']) ?? 1,
          vMerge: vMerge.isEmpty ? null : vMerge,
          backgroundColor: _cellBackground(cellMap, word),
          verticalAlign: _verticalAlignOf(cellMap?['verticalAlign'] ??
              cellMap?['vertical-align'] ??
              word?['vAlign'] ??
              _cssValue(cellMap?['style'], 'vertical-align')),
          borderMap: _map(word?['borders']),
          marginTopTwips: _wordMarginTwips(cellMargins?['top'], tableMarginTop),
          marginRightTwips:
              _wordMarginTwips(cellMargins?['right'], tableMarginRight),
          marginBottomTwips:
              _wordMarginTwips(cellMargins?['bottom'], tableMarginBottom),
          marginLeftTwips:
              _wordMarginTwips(cellMargins?['left'], tableMarginLeft),
        ));
      });
      rowSpecs.add(rowSpec);
      rowOffset += row.nodeSize;
      yield true;
    }

    // Primeiro resolve a grade lógica. O DOCX materializa células
    // `vMerge=continue`; o Quill, ao contrário, omite os slots cobertos por
    // rowspan. Usar a mesma estratégia para ambos desloca todas as células
    // à direita depois da primeira mesclagem.
    var columnCount = 0;
    if (hasWordVerticalMerge) {
      for (final row in rowSpecs) {
        var column = row.gridBefore;
        for (final cell in row.cells) {
          cell.columnIndex = column;
          column += cell.columnSpan;
        }
        column += row.gridAfter;
        if (column > columnCount) columnCount = column;
        yield true;
      }
      _resolveWordVerticalMerges(rowSpecs, diagnostics);
    } else {
      final occupiedUntil = <int, int>{};
      for (final row in rowSpecs) {
        var column = row.gridBefore;
        for (final cell in row.cells) {
          while (_rangeOccupied(
              occupiedUntil, row.rowIndex, column, cell.columnSpan)) {
            column++;
          }
          cell.columnIndex = column;
          if (cell.rowSpan > 1) {
            final until = row.rowIndex + cell.rowSpan - 1;
            for (var c = column; c < column + cell.columnSpan; c++) {
              occupiedUntil[c] = until;
            }
          }
          column += cell.columnSpan;
        }
        column += row.gridAfter;
        if (column > columnCount) columnCount = column;
        yield true;
      }
    }

    final columnWidths =
        _tableColumnWidths(table, availableTwips, minimumColumns: columnCount);
    final gridWidthTwips =
        columnWidths.fold<int>(0, (sum, width) => sum + width);
    final remainingWidthTwips = availableTwips - gridWidthTwips;
    final tableJustification = '${tableWord?['jc'] ?? ''}'.toLowerCase();
    final tableOffsetTwips = switch (tableJustification) {
      'center' => remainingWidthTwips > 0 ? remainingWidthTwips ~/ 2 : 0,
      'right' || 'end' => remainingWidthTwips > 0 ? remainingWidthTwips : 0,
      // Word only applies tblInd to left-aligned tables.  Keeping the
      // default in this branch also covers documents that omit w:jc.
      _ => tableWord?['indentTwips'] is num
          ? (tableWord!['indentTwips'] as num).toInt()
          : int.tryParse('${tableWord?['indentTwips']}') ?? 0,
    };
    final columnX = <int>[tableOffsetTwips];
    for (final width in columnWidths) {
      columnX.add(columnX.last + width);
    }

    final tableBorders = _map(tableWord?['borders']);
    final defaultBorder = tableBorders == null ? const TableBorder() : null;
    final trailingBorderExtentTwips =
        _tableTrailingBorderExtents(rowSpecs, tableBorders);
    yield true;
    // Agora que a largura de cada span é conhecida, compõe o conteúdo.
    for (final row in rowSpecs) {
      var contentRowHeight = 0;
      for (final cell in row.cells) {
        final endColumn = cell.columnIndex + cell.columnSpan;
        final safeEnd =
            endColumn < columnX.length ? endColumn : columnX.length - 1;
        cell.xTwips = columnX[cell.columnIndex];
        cell.widthTwips = columnX[safeEnd] - cell.xTwips;
        final innerWidth =
            cell.widthTwips - cell.marginLeftTwips - cell.marginRightTwips;
        var y = cell.marginTopTwips;
        int? previousAfterTwips;
        cell.node.content.forEach((inner, innerOffset, innerIndex) {
          if (LayoutComposer._isZeroLayoutOpaqueBlock(inner)) {
            cell.blocks.add(BlockFragment(
              nodeId: officeNodeId(inner),
              docPos: cell.docPos + innerOffset + 1,
              kind: inner.type.name,
              lines: const [],
              yTwips: y,
              heightTwips: 0,
            ));
            return;
          }
          // Word keeps a mandatory paragraph terminator in every table cell.
          // When a cell already has visible block content, an additional,
          // completely empty final paragraph shares the preceding paragraph's
          // visual line instead of adding another one.  Preserve the PM node
          // (and its anchor) so typing into it makes it visible on the next
          // composition, but give the empty terminator no layout extent.
          if (LayoutComposer._isCollapsedTrailingCellParagraph(
              cell.node, inner, innerIndex)) {
            cell.blocks.add(BlockFragment(
              nodeId: officeNodeId(inner),
              docPos: cell.docPos + innerOffset + 1,
              kind: inner.type.name,
              lines: const [],
              yTwips: y,
              heightTwips: 0,
            ));
            return;
          }
          final style = _blockStyleOf(inner, 0);
          final flow = _paragraphFlow(style);
          final before =
              _collapsedSpaceBefore(style.spaceBeforeTwips, previousAfterTwips);
          var textWidth =
              innerWidth - flow.textIndentTwips - style.rightIndentTwips;
          if (textWidth < 400) textWidth = 400;
          final lines = _breakTableLines(
            inner,
            textWidth,
            style,
            diagnostics,
            honorRenderedPageBreaks: honorRenderedPageBreaks,
          );
          var height = 0;
          for (final line in lines) {
            height += line.heightTwips;
          }
          if (lines.isEmpty) {
            height = _resolvedLineHeightTwips(
                _lineHeightTwips(
                    style.family ?? baseFontFamily, style.baseSizePt),
                style);
          }
          final blockHeight = before + height + style.spaceAfterTwips;
          cell.blocks.add(BlockFragment(
            nodeId: officeNodeId(inner),
            docPos: cell.docPos + innerOffset + 1,
            kind: inner.type.name,
            lines: lines,
            yTwips: y,
            heightTwips: blockHeight,
            indentTwips: cell.marginLeftTwips + flow.textIndentTwips,
            rightIndentTwips: cell.marginRightTwips + style.rightIndentTwips,
            align: style.align,
            marker: style.marker,
            markerPositionTwips:
                cell.marginLeftTwips + flow.markerPositionTwips,
            markerStyle: style.marker == null ? null : _markerStyleOf(style),
            widowControl: style.widowControl,
            spaceBeforeTwips: before,
            spaceAfterTwips: style.spaceAfterTwips,
          ));
          y += blockHeight;
          previousAfterTwips = style.spaceAfterTwips;
        });
        cell.contentHeightTwips = y + cell.marginBottomTwips;
        if (!cell.isMergeContinuation &&
            cell.rowSpan == 1 &&
            cell.contentHeightTwips > contentRowHeight) {
          contentRowHeight = cell.contentHeightTwips;
        }
      }
      if (contentRowHeight == 0) {
        contentRowHeight = _lineHeightTwips(baseFontFamily, baseFontSizePt);
      }
      final requested = row.heightTwips;
      row.resolvedHeightTwips = row.heightRule == 'exact' && requested != null
          ? requested
          : requested != null && requested > contentRowHeight
              ? requested
              : contentRowHeight;
      // O clip do conteúdo não inclui a aresta colapsada posterior. A altura
      // externa da row inclui essa aresta uma única vez; `exact`, por outro
      // lado, já declara o tamanho externo completo.
      if (row.heightRule != 'exact') {
        row.resolvedHeightTwips += trailingBorderExtentTwips[row.rowIndex];
      }
      yield true;
    }

    // Conteúdo de uma célula mesclada usa a soma das linhas. Se ainda não
    // couber, cresce a última linha não-exata do grupo (o comportamento
    // `atLeast` do Word), sem violar uma altura explicitamente `exact`.
    for (final row in rowSpecs) {
      for (final cell in row.cells) {
        if (cell.isMergeContinuation || cell.rowSpan <= 1) continue;
        final end = _boundedRowEnd(rowSpecs, row.rowIndex, cell.rowSpan);
        var spanHeight = 0;
        for (var r = row.rowIndex; r < end; r++) {
          spanHeight += rowSpecs[r].resolvedHeightTwips;
        }
        if (cell.contentHeightTwips <= spanHeight) continue;
        for (var r = end - 1; r >= row.rowIndex; r--) {
          if (rowSpecs[r].heightRule == 'exact') continue;
          rowSpecs[r].resolvedHeightTwips +=
              cell.contentHeightTwips - spanHeight;
          break;
        }
      }
      yield true;
    }

    final result = <TableRowBox>[];
    for (final row in rowSpecs) {
      final cells = <TableCellBox>[];
      for (final cell in row.cells) {
        final end = _boundedRowEnd(rowSpecs, row.rowIndex, cell.rowSpan);
        var cellHeight = 0;
        for (var r = row.rowIndex; r < end; r++) {
          cellHeight += rowSpecs[r].resolvedHeightTwips;
        }
        if (cell.isMergeContinuation) {
          cellHeight = row.resolvedHeightTwips;
        }
        final free = cellHeight > cell.contentHeightTwips
            ? cellHeight - cell.contentHeightTwips
            : 0;
        final contentOffset = switch (cell.verticalAlign) {
          TableCellVerticalAlign.center => free ~/ 2,
          TableCellVerticalAlign.bottom => free,
          TableCellVerticalAlign.top => 0,
        };
        final spanEndRow = end - 1;
        final spanEndColumn = cell.columnIndex + cell.columnSpan;
        cells.add(TableCellBox(
          nodeId: officeNodeId(cell.node),
          docPos: cell.docPos,
          docPosEnd: cell.docPos + cell.node.content.size,
          sourceTableId: row.sourceTableId,
          sourceRowId: row.sourceRowId,
          sourceCellId: cell.sourceCellId,
          sourceRowIndex: row.sourceRowIndex,
          sourceCellIndex: cell.sourceCellIndex,
          xTwips: cell.xTwips,
          widthTwips: cell.widthTwips,
          blocks: cell.blocks,
          contentHeightTwips: cell.contentHeightTwips,
          heightTwips: cellHeight,
          columnIndex: cell.columnIndex,
          columnSpan: cell.columnSpan,
          rowSpan: cell.rowSpan,
          isMergeContinuation: cell.isMergeContinuation,
          backgroundColor: cell.backgroundColor,
          verticalAlign: cell.verticalAlign,
          contentOffsetTwips: contentOffset,
          marginTopTwips: cell.marginTopTwips,
          marginRightTwips: cell.marginRightTwips,
          marginBottomTwips: cell.marginBottomTwips,
          marginLeftTwips: cell.marginLeftTwips,
          borders: TableCellBorders(
            top: _resolvedCellBorder(
                cell.borderMap,
                'top',
                row.rowIndex == 0
                    ? _border(tableBorders?['top']) ?? defaultBorder
                    : _border(tableBorders?['insideH']) ?? defaultBorder),
            bottom: _resolvedCellBorder(
                cell.borderMap,
                'bottom',
                spanEndRow == rowSpecs.length - 1
                    ? _border(tableBorders?['bottom']) ?? defaultBorder
                    : _border(tableBorders?['insideH']) ?? defaultBorder),
            left: _resolvedCellBorder(
                cell.borderMap,
                'left',
                cell.columnIndex == 0
                    ? _border(tableBorders?['left']) ?? defaultBorder
                    : _border(tableBorders?['insideV']) ?? defaultBorder),
            right: _resolvedCellBorder(
                cell.borderMap,
                'right',
                spanEndColumn >= columnWidths.length
                    ? _border(tableBorders?['right']) ?? defaultBorder
                    : _border(tableBorders?['insideV']) ?? defaultBorder),
          ),
        ));
      }
      result.add(TableRowBox(
        nodeId: officeNodeId(row.node),
        docPos: row.docPos,
        docPosEnd: row.docPos + row.node.content.size,
        sourceTableId: row.sourceTableId,
        sourceRowId: row.sourceRowId,
        sourceRowIndex: row.sourceRowIndex,
        heightTwips: row.resolvedHeightTwips,
        cells: cells,
        heightRule: row.heightRule,
        cantSplit: row.cantSplit,
        repeatHeader: row.repeatHeader,
        gridBefore: row.gridBefore,
        gridAfter: row.gridAfter,
        widthBeforeTwips: row.widthBeforeTwips,
        widthAfterTwips: row.widthAfterTwips,
      ));
      yield true;
    }
    build.result = result;
  }

  /// Divide uma linha Word em uma fronteira que não corta nenhuma linha de
  /// texto nem isola a primeira/última linha de um parágrafo com
  /// `w:widowControl`. Grupos com rowspan continuam atômicos porque uma
  /// célula verticalmente mesclada precisa da geometria conjunta das rows.
  ({TableRowBox head, TableRowBox tail})? _splitTableRow(
    TableRowBox row,
    int availableTwips, {
    bool renderedBreak = false,
  }) {
    if (row.cantSplit ||
        row.repeatHeader ||
        availableTwips <= 0 ||
        availableTwips >= row.heightTwips ||
        row.cells
            .any((cell) => cell.rowSpan != 1 || cell.isMergeContinuation)) {
      return null;
    }

    final intervals = <({int start, int end})>[];
    for (final cell in row.cells) {
      final offset = cell.contentOffsetTwips;
      for (final block in cell.blocks) {
        final blockTop = offset + block.yTwips;
        if (block.lines.isEmpty) {
          final blank = block.heightTwips -
              block.spaceBeforeTwips -
              block.spaceAfterTwips;
          if (blank > 0) {
            final start = blockTop + block.spaceBeforeTwips;
            intervals.add((start: start, end: start + blank));
          }
          continue;
        }
        var lineTop = blockTop + block.spaceBeforeTwips;
        for (final line in block.lines) {
          intervals.add((start: lineTop, end: lineTop + line.heightTwips));
          lineTop += line.heightTwips;
        }
      }
    }
    if (intervals.isEmpty) return null;

    // Desce o corte enquanto ele atravessar uma linha em qualquer célula ou
    // criar uma órfã/viúva. A iteração converge porque cada ajuste escolhe
    // um início estritamente menor. Espaços/margens podem ser cortados.
    var cut = availableTwips;
    while (true) {
      var adjusted = cut;
      for (final interval in intervals) {
        if (interval.start < cut && cut < interval.end) {
          if (interval.start < adjusted) adjusted = interval.start;
        }
      }

      // O Word já aplicou widow/orphan quando gravou o marker. Reaplicar a
      // regra sobre uma fronteira renderizada deslocaria o corte confirmado.
      if (!renderedBreak) {
        for (final cell in row.cells) {
          final offset = cell.contentOffsetTwips;
          for (final block in cell.blocks) {
            if (!block.widowControl || block.lines.length < 2) continue;
            final blockTop = offset + block.yTwips;
            var lineTop = blockTop + block.spaceBeforeTwips;
            final starts = <int>[];
            var headCount = 0;
            for (final line in block.lines) {
              starts.add(lineTop);
              final lineBottom = lineTop + line.heightTwips;
              if (lineBottom <= cut) headCount++;
              lineTop = lineBottom;
            }
            final tailCount = block.lines.length - headCount;
            if (headCount == 0 || tailCount == 0) continue;
            final isolatesFirst =
                !block.continuesFromPreviousPage && headCount == 1;
            final isolatesLast = !block.continuesOnNextPage && tailCount == 1;
            if (isolatesFirst || isolatesLast) {
              final candidate =
                  isolatesFirst ? starts.first : starts[headCount - 1];
              if (candidate < adjusted) adjusted = candidate;
            }
          }
        }
      }
      if (adjusted == cut) break;
      cut = adjusted;
      if (cut <= 0) return null;
    }
    if (cut <= 0 || !intervals.any((interval) => interval.end <= cut)) {
      return null;
    }

    final headCells = <TableCellBox>[];
    final tailCells = <TableCellBox>[];
    for (final cell in row.cells) {
      final parts = _splitTableCellBlocks(cell, cut);
      headCells.add(_tableCellPart(
        cell,
        blocks: parts.head,
        heightTwips: cut,
        marginTopTwips: cell.marginTopTwips,
        marginBottomTwips: 0,
      ));
      tailCells.add(_tableCellPart(
        cell,
        blocks: parts.tail,
        heightTwips: row.heightTwips - cut,
        marginTopTwips: 0,
        marginBottomTwips: cell.marginBottomTwips,
      ));
    }

    TableRowBox part({
      required int height,
      required List<TableCellBox> cells,
      required bool from,
      required bool on,
    }) =>
        TableRowBox(
          nodeId: row.nodeId,
          docPos: row.docPos,
          docPosEnd: row.docPosEnd,
          sourceTableId: row.sourceTableId,
          sourceRowId: row.sourceRowId,
          sourceRowIndex: row.sourceRowIndex,
          heightTwips: height,
          cells: cells,
          heightRule: row.heightRule,
          cantSplit: row.cantSplit,
          repeatHeader: row.repeatHeader,
          gridBefore: row.gridBefore,
          gridAfter: row.gridAfter,
          widthBeforeTwips: row.widthBeforeTwips,
          widthAfterTwips: row.widthAfterTwips,
          continuesFromPreviousPage: from,
          continuesOnNextPage: on,
        );

    return (
      head: part(
        height: cut,
        cells: headCells,
        from: row.continuesFromPreviousPage,
        on: true,
      ),
      tail: part(
        height: row.heightTwips - cut,
        cells: tailCells,
        from: true,
        on: row.continuesOnNextPage,
      ),
    );
  }

  /// Classifica os markers de uma row sem confundir duas representações da
  /// mesma fronteira do Word:
  ///
  /// * marker antes do primeiro conteúdo da célula => quebra antes da row;
  /// * marker após conteúdo => corte interno na coordenada vertical da linha.
  ///
  /// A primeira linha de uma tail já fragmentada conserva o nó opaco para
  /// round-trip, mas o marker foi consumido pelo corte que criou essa tail.
  ({bool beforeRow, int? internalCutTwips}) _pageBreakInTableRow(
    TableRowBox row, {
    required bool honorRenderedPageBreaks,
  }) {
    var beforeRow = false;
    int? internalCut;
    for (final cell in row.cells) {
      var sawVisibleContent = false;
      final offset = cell.contentOffsetTwips;
      for (final block in cell.blocks) {
        var lineTop = offset + block.yTwips + block.spaceBeforeTwips;
        for (final line in block.lines) {
          if (line.manualPageBreakBefore ||
              (honorRenderedPageBreaks && line.renderedPageBreakBefore)) {
            if (!sawVisibleContent) {
              if (!row.continuesFromPreviousPage) beforeRow = true;
            } else if (lineTop > 0 &&
                lineTop < row.heightTwips &&
                (internalCut == null || lineTop < internalCut)) {
              internalCut = lineTop;
            }
          }
          sawVisibleContent = true;
          lineTop += line.heightTwips;
        }
      }
    }
    return (beforeRow: beforeRow, internalCutTwips: internalCut);
  }

  ({List<BlockFragment> head, List<BlockFragment> tail}) _splitTableCellBlocks(
      TableCellBox cell, int cut) {
    final head = <BlockFragment>[];
    final tail = <BlockFragment>[];
    final cellOffset = cell.contentOffsetTwips;

    BlockFragment copy(
      BlockFragment block, {
      required List<LineBox> lines,
      required int y,
      required int height,
      required int before,
      required int after,
      required bool from,
      required bool on,
      String? marker,
    }) =>
        BlockFragment(
          nodeId: block.nodeId,
          docPos: block.docPos,
          kind: block.kind,
          lines: lines,
          yTwips: y,
          heightTwips: height,
          indentTwips: block.indentTwips,
          rightIndentTwips: block.rightIndentTwips,
          align: block.align,
          marker: marker,
          markerPositionTwips: block.markerPositionTwips,
          markerStyle: block.markerStyle,
          widowControl: block.widowControl,
          spaceBeforeTwips: before,
          spaceAfterTwips: after,
          continuesFromPreviousPage: from,
          continuesOnNextPage: on,
        );

    for (final block in cell.blocks) {
      final blockTop = cellOffset + block.yTwips;
      final blockBottom = blockTop + block.heightTwips;
      if (blockBottom <= cut) {
        head.add(copy(
          block,
          lines: block.lines,
          y: blockTop,
          height: block.heightTwips,
          before: block.spaceBeforeTwips,
          after: block.spaceAfterTwips,
          from: block.continuesFromPreviousPage,
          on: block.continuesOnNextPage,
          marker: block.marker,
        ));
        continue;
      }
      if (blockTop >= cut) {
        tail.add(copy(
          block,
          lines: block.lines,
          y: blockTop - cut,
          height: block.heightTwips,
          before: block.spaceBeforeTwips,
          after: block.spaceAfterTwips,
          from: block.continuesFromPreviousPage,
          on: block.continuesOnNextPage,
          marker: block.marker,
        ));
        continue;
      }

      if (block.lines.isEmpty) {
        // Um bloco vazio foi incluído como intervalo indivisível; portanto
        // esta sobreposição só pode ser margem/spacing sem conteúdo.
        continue;
      }
      final headLines = <LineBox>[];
      final tailLines = <LineBox>[];
      var lineTop = blockTop + block.spaceBeforeTwips;
      var firstTailTop = -1;
      var lastHeadBottom = blockTop;
      for (final line in block.lines) {
        final lineBottom = lineTop + line.heightTwips;
        if (lineBottom <= cut) {
          headLines.add(line);
          lastHeadBottom = lineBottom;
        } else {
          if (firstTailTop < 0) firstTailTop = lineTop;
          tailLines.add(line);
        }
        lineTop = lineBottom;
      }
      if (headLines.isNotEmpty) {
        final headHeight = lastHeadBottom - blockTop;
        head.add(copy(
          block,
          lines: headLines,
          y: blockTop,
          height: headHeight,
          before: block.spaceBeforeTwips,
          after: 0,
          from: block.continuesFromPreviousPage,
          on: tailLines.isNotEmpty || block.continuesOnNextPage,
          marker: block.marker,
        ));
      }
      if (tailLines.isNotEmpty) {
        final tailY = blockTop >= cut ? blockTop - cut : 0;
        final before = firstTailTop - cut - tailY;
        final lineHeight =
            tailLines.fold<int>(0, (sum, line) => sum + line.heightTwips);
        final includesLastLine = tailLines.last == block.lines.last;
        final after = includesLastLine ? block.spaceAfterTwips : 0;
        tail.add(copy(
          block,
          lines: tailLines,
          y: tailY,
          height: before + lineHeight + after,
          before: before,
          after: after,
          from: headLines.isNotEmpty || block.continuesFromPreviousPage,
          on: block.continuesOnNextPage,
          marker: headLines.isEmpty ? block.marker : null,
        ));
      }
    }
    return (head: head, tail: tail);
  }

  TableCellBox _tableCellPart(
    TableCellBox cell, {
    required List<BlockFragment> blocks,
    required int heightTwips,
    required int marginTopTwips,
    required int marginBottomTwips,
  }) =>
      TableCellBox(
        nodeId: cell.nodeId,
        docPos: cell.docPos,
        docPosEnd: cell.docPosEnd,
        sourceTableId: cell.sourceTableId,
        sourceRowId: cell.sourceRowId,
        sourceCellId: cell.sourceCellId,
        sourceRowIndex: cell.sourceRowIndex,
        sourceCellIndex: cell.sourceCellIndex,
        xTwips: cell.xTwips,
        widthTwips: cell.widthTwips,
        blocks: blocks,
        contentHeightTwips: heightTwips,
        heightTwips: heightTwips,
        columnIndex: cell.columnIndex,
        columnSpan: cell.columnSpan,
        rowSpan: 1,
        isMergeContinuation: cell.isMergeContinuation,
        backgroundColor: cell.backgroundColor,
        verticalAlign: cell.verticalAlign,
        contentOffsetTwips: 0,
        borders: cell.borders,
        marginTopTwips: marginTopTwips,
        marginRightTwips: cell.marginRightTwips,
        marginBottomTwips: marginBottomTwips,
        marginLeftTwips: cell.marginLeftTwips,
      );

  void _resolveWordVerticalMerges(
      List<_TableRowSpec> rows, LayoutDiagnostics diagnostics) {
    final active = <int, _TableCellSpec>{};
    for (final row in rows) {
      final continued = <int>{};
      for (final cell in row.cells) {
        switch (cell.vMerge) {
          case 'restart':
            active[cell.columnIndex] = cell;
            continued.add(cell.columnIndex);
          case 'continue':
            final origin = active[cell.columnIndex];
            if (origin == null) {
              diagnostics.warnings
                  .add('vMerge continue sem restart na linha ${row.rowIndex}');
              continue;
            }
            cell.isMergeContinuation = true;
            cell.columnSpan = origin.columnSpan;
            origin.rowSpan = row.rowIndex - origin.rowIndex + 1;
            continued.add(cell.columnIndex);
          default:
            active.remove(cell.columnIndex);
        }
      }
      active.removeWhere((column, origin) =>
          origin.rowIndex < row.rowIndex && !continued.contains(column));
    }
  }

  bool _rangeOccupied(
      Map<int, int> occupiedUntil, int row, int column, int span) {
    for (var c = column; c < column + span; c++) {
      if ((occupiedUntil[c] ?? -1) >= row) return true;
    }
    return false;
  }

  int _boundedRowEnd(List<_TableRowSpec> rows, int start, int span) {
    final requested = start + span;
    return requested < rows.length ? requested : rows.length;
  }

  TableCellVerticalAlign _verticalAlignOf(dynamic raw) =>
      switch ('$raw'.trim().toLowerCase()) {
        'center' || 'middle' => TableCellVerticalAlign.center,
        'bottom' => TableCellVerticalAlign.bottom,
        _ => TableCellVerticalAlign.top,
      };

  String? _cellBackground(Map? cell, Map? word) {
    final direct = cell?['background'] ??
        cell?['background-color'] ??
        _cssValue(cell?['style'], 'background-color');
    final shading = _map(word?['shading']);
    return _cssColor(direct ?? shading?['fill']);
  }

  String? _cssValue(dynamic style, String property) {
    if (style is Map) return style[property]?.toString();
    if (style is! String) return null;
    for (final declaration in style.split(';')) {
      final colon = declaration.indexOf(':');
      if (colon < 0) continue;
      if (declaration.substring(0, colon).trim().toLowerCase() == property) {
        return declaration.substring(colon + 1).trim();
      }
    }
    return null;
  }

  String? _cssColor(dynamic raw) {
    if (raw == null) return null;
    final value = '$raw'.trim();
    final lower = value.toLowerCase();
    final keyword = lower.startsWith('#') ? lower.substring(1) : lower;
    if (value.isEmpty ||
        keyword == 'auto' ||
        keyword == 'none' ||
        lower == 'transparent') {
      return null;
    }
    if (value.startsWith('#')) return value;
    if (RegExp(r'^[0-9a-fA-F]{3,8}$').hasMatch(value)) return '#$value';
    return value;
  }

  TableBorder? _resolvedCellBorder(
      Map? cellBorders, String side, TableBorder? inherited) {
    if (cellBorders != null && cellBorders.containsKey(side)) {
      return _border(cellBorders[side]);
    }
    return inherited;
  }

  /// Espessura da aresta horizontal posterior de cada row.
  ///
  /// Sem `tblCellSpacing`, bordas adjacentes colapsam numa única aresta. Ela
  /// entra uma vez na altura externa, depois do clip de conteúdo, usando a
  /// maior espessura entre o `bottom` acima e o `top` abaixo.
  List<int> _tableTrailingBorderExtents(
      List<_TableRowSpec> rows, Map? tableBorders) {
    final result = List<int>.filled(rows.length, 0);

    void include(int rowIndex, TableBorder? border) {
      if (rowIndex < 0 ||
          rowIndex >= result.length ||
          border == null ||
          !border.isVisible) {
        return;
      }
      if (border.widthTwips > result[rowIndex]) {
        result[rowIndex] = border.widthTwips;
      }
    }

    for (final row in rows) {
      for (final cell in row.cells) {
        if (cell.isMergeContinuation) continue;
        final end = _boundedRowEnd(rows, row.rowIndex, cell.rowSpan);
        final inheritedBottom = end == rows.length
            ? _border(tableBorders?['bottom'])
            : _border(tableBorders?['insideH']);
        include(
          end - 1,
          _resolvedCellBorder(cell.borderMap, 'bottom', inheritedBottom),
        );
        if (row.rowIndex > 0) {
          include(
            row.rowIndex - 1,
            _resolvedCellBorder(
              cell.borderMap,
              'top',
              _border(tableBorders?['insideH']),
            ),
          );
        }
      }
    }
    return result;
  }

  TableBorder? _border(dynamic raw) {
    final border = _map(raw);
    if (border == null) return null;
    final val = '${border['val'] ?? 'single'}'.toLowerCase();
    if (val == 'none' || val == 'nil') {
      return const TableBorder(style: 'none', widthTwips: 0);
    }
    final size = (border['sizeEighths'] as num?)?.toDouble() ?? 4;
    final style = switch (val) {
      'double' => 'double',
      'dashed' || 'dashsmallgap' || 'dotdash' || 'dotdotdash' => 'dashed',
      'dotted' => 'dotted',
      _ => 'solid',
    };
    return TableBorder(
      style: style,
      widthTwips: (size * 2.5).round(),
      color: _cssColor(border['color']) ?? '#000000',
    );
  }

  static Map? _map(dynamic value) => value is Map ? value : null;

  static int? _positiveInt(dynamic value) {
    final parsed = value is num ? value.toInt() : int.tryParse('$value');
    return parsed != null && parsed > 0 ? parsed : null;
  }

  static int? _nonNegativeInt(dynamic value) {
    final parsed = value is num ? value.toInt() : int.tryParse('$value');
    return parsed != null && parsed >= 0 ? parsed : null;
  }

  /// Identidade semântica usada pelo adaptador Quill/Word. `rowId` e
  /// `cellId` sobrevivem a fragmentação e são a chave que a edição usa para
  /// voltar da projeção DOM ao mesmo nó PM; documentos Office também têm o
  /// `id` canônico como fallback.
  static String? _sourceNodeId(PMNode node, String attribute) {
    final source = node.attrs[attribute];
    if (source is String && source.trim().isNotEmpty) return source;
    return officeNodeId(node);
  }

  static int? _wordWidthTwips(dynamic value) {
    final width = _map(value);
    if (width == null || (width['type'] != null && width['type'] != 'dxa')) {
      return null;
    }
    return _positiveInt(width['value']);
  }

  static int _wordMarginTwips(dynamic value, int fallback) {
    final width = _map(value);
    if (width == null) return fallback;
    final type = '${width['type'] ?? 'dxa'}'.toLowerCase();
    if (type != 'dxa') return fallback;
    final raw = width['value'];
    final parsed = raw is num ? raw.toInt() : int.tryParse('$raw');
    return parsed != null && parsed >= 0 ? parsed : fallback;
  }
}

/// Fecha um grupo indivisível de paginação. Além de `rowSpan`/`vMerge`, o
/// cabeçalho inicial anda com pelo menos uma linha de dados para não deixar
/// um cabeçalho órfão no fim da página.
int _tableRowGroupEnd(List<TableRowBox> rows, int start,
    {required int headerCount}) {
  var end = start + 1;
  if (start == 0 && headerCount > 0 && headerCount < rows.length) {
    end = headerCount + 1;
  }
  var row = start;
  while (row < end && row < rows.length) {
    for (final cell in rows[row].cells) {
      if (cell.isMergeContinuation) continue;
      final cellEnd = row + cell.rowSpan;
      if (cellEnd > end) end = cellEnd;
    }
    if (end > rows.length) end = rows.length;
    row++;
  }
  return end;
}

Iterable<PositionMapEntry> _tablePositionEntries(
    List<TableRowBox> rows, int pageIndex) sync* {
  for (final row in rows) {
    if (row.isRepeatedHeader) continue;
    // A posição antes do primeiro row é também o início do conteúdo da
    // tabela. Esta pequena âncora cobre os tokens estruturais sem voltar ao
    // mapa monolítico que fazia qualquer célula apontar à última página.
    if (!row.continuesFromPreviousPage) {
      yield PositionMapEntry(
        docPosStart: row.docPos - 1,
        docPosEnd: row.docPos,
        pageIndex: pageIndex,
      );
    }
    for (final cell in row.cells) {
      if (!row.continuesFromPreviousPage) {
        yield PositionMapEntry(
          docPosStart: cell.docPos - 1,
          docPosEnd: cell.docPos,
          pageIndex: pageIndex,
        );
      }
      for (final block in cell.blocks) {
        if (block.lines.isEmpty) {
          yield PositionMapEntry(
            docPosStart: block.docPos,
            docPosEnd: block.docPos,
            pageIndex: pageIndex,
          );
          continue;
        }
        for (final line in block.lines) {
          yield PositionMapEntry(
            docPosStart: block.docPos + line.charStart,
            docPosEnd: block.docPos + line.charEnd,
            pageIndex: pageIndex,
          );
        }
      }
    }
  }
}

class _TableRowsBuild {
  _TableRowsBuild({
    required this.table,
    required this.diagnostics,
    required this.tableDocPos,
    required this.availableTwips,
    required this.honorRenderedPageBreaks,
  });

  final PMNode table;
  final LayoutDiagnostics diagnostics;
  final int tableDocPos;
  final int availableTwips;
  final bool honorRenderedPageBreaks;
  List<TableRowBox>? result;
}

class _TableRowSpec {
  _TableRowSpec({
    required this.node,
    required this.rowIndex,
    required this.docPos,
    required this.sourceTableId,
    required this.sourceRowId,
    required this.sourceRowIndex,
    required this.heightTwips,
    required this.heightRule,
    required this.cantSplit,
    required this.repeatHeader,
    required this.gridBefore,
    required this.gridAfter,
    required this.widthBeforeTwips,
    required this.widthAfterTwips,
  });

  final PMNode node;
  final int rowIndex;
  final int docPos;
  final String? sourceTableId;
  final String? sourceRowId;
  final int sourceRowIndex;
  final int? heightTwips;
  final String? heightRule;
  final bool cantSplit;
  final bool repeatHeader;
  final int gridBefore;
  final int gridAfter;
  final int? widthBeforeTwips;
  final int? widthAfterTwips;
  final List<_TableCellSpec> cells = [];
  int resolvedHeightTwips = 0;
}

class _TableCellSpec {
  _TableCellSpec({
    required this.node,
    required this.rowIndex,
    required this.cellIndex,
    required this.docPos,
    required this.sourceCellId,
    required this.sourceCellIndex,
    required this.columnSpan,
    required this.rowSpan,
    required this.vMerge,
    required this.backgroundColor,
    required this.verticalAlign,
    required this.borderMap,
    required this.marginTopTwips,
    required this.marginRightTwips,
    required this.marginBottomTwips,
    required this.marginLeftTwips,
  });

  final PMNode node;
  final int rowIndex;
  final int cellIndex;
  final int docPos;
  final String? sourceCellId;
  final int sourceCellIndex;
  int columnSpan;
  int rowSpan;
  final String? vMerge;
  final String? backgroundColor;
  final TableCellVerticalAlign verticalAlign;
  final Map? borderMap;
  final int marginTopTwips;
  final int marginRightTwips;
  final int marginBottomTwips;
  final int marginLeftTwips;

  int columnIndex = 0;
  int xTwips = 0;
  int widthTwips = 0;
  bool isMergeContinuation = false;
  final List<BlockFragment> blocks = [];
  int contentHeightTwips = 0;
}

class _BlockStyle {
  const _BlockStyle({
    required this.align,
    required this.baseSizePt,
    this.bold = false,
    this.indentTwips = 0,
    this.rightIndentTwips = 0,
    this.firstLineIndentTwips = 0,
    this.spaceBeforeTwips = 0,
    this.spaceAfterTwips = 0,
    this.lineTwips,
    this.lineRule,
    this.contextualSpacing = false,
    this.autoHyphenation = false,
    this.hyphenationZoneTwips = 360,
    this.wordStyleId,
    this.keepLines = false,
    this.keepNext = false,
    this.widowControl = true,
    this.tabs = const [],
    this.marker,
    this.markerSuffix = 'tab',
    this.family,
  });

  final LayoutAlign align;
  final double baseSizePt;
  final bool bold;
  final int indentTwips;

  /// Recuo direito (Word `w:ind/@right`).
  final int rightIndentTwips;

  /// Recuo de primeira linha (Word `w:ind/@firstLine`); negativo = pendente
  /// (`w:ind/@hanging`).
  final int firstLineIndentTwips;

  final int spaceBeforeTwips;
  final int spaceAfterTwips;

  /// Valor cru de `w:spacing/@line`. Com `auto`, são 240 avos da altura
  /// natural; com `exact`/`atLeast`, são twips.
  final int? lineTwips;
  final String? lineRule;
  final bool contextualSpacing;
  final bool autoHyphenation;
  final int hyphenationZoneTwips;
  final String? wordStyleId;
  final bool keepLines;
  final bool keepNext;
  final bool widowControl;
  final List<_TabStop> tabs;

  final String? marker;
  final String markerSuffix;
  final String? family;
}

class _TabStop {
  const _TabStop({
    required this.val,
    required this.posTwips,
    this.leader,
  });

  final String val;
  final int posTwips;
  final String? leader;
}

class _LayoutFieldState {
  String? command;
  bool inResult = false;
  bool emitted = false;
}

class _Token {
  const _Token({
    required this.text,
    required this.style,
    required this.isSpace,
    required this.widthTwips,
    required this.charStart,
    this.imageSrc,
    this.imageHeightTwips,
    this.hardBreak = false,
    this.pageBreak = false,
    this.isTab = false,
    this.tabLeader,
    this.isOpaqueInline = false,
    this.renderedPageBreakHint = false,
    this.isDiscretionaryHyphen = false,
    this.textBox,
    int? modelLength,
  }) : modelLength = modelLength ?? text.length;

  final String text;
  final ResolvedRunStyle style;
  final bool isSpace;
  final int widthTwips;
  final int charStart;
  final String? imageSrc;
  final int? imageHeightTwips;
  final bool hardBreak;
  final bool pageBreak;
  final bool isTab;
  final String? tabLeader;
  final bool isOpaqueInline;
  final bool renderedPageBreakHint;
  final bool isDiscretionaryHyphen;
  final FloatingTextBoxLayout? textBox;
  final int modelLength;

  int get charEnd => charStart + modelLength;
}
