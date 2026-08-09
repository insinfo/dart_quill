/// OfficeWordEditor — o editor Word completo como componente da biblioteca.
///
/// O consumidor faz UMA chamada e recebe a experiência inteira:
///
/// ```dart
/// final editor = OfficeWordEditor.mount(
///   host: adapter.document.querySelector('#editor')!,
///   adapter: adapter,
///   document: doc,
///   options: const OfficeWordEditorOptions(mode: OfficeWordMode.word),
/// );
/// ```
///
/// **CSS e ícones são ASSETS do pacote**, não strings embutidas — a
/// aplicação inclui (e pode substituir por temas/ícones próprios):
///
/// ```html
/// <link rel="stylesheet"
///       href="packages/dart_quill/assets/office_word_editor.css">
/// <link rel="stylesheet"
///       href="packages/dart_quill/assets/office_word_icons.css">
/// ```
///
/// **Arquitetura:** este arquivo é só o ORQUESTRADOR. Cada peça do chrome é
/// um componente próprio que fala com o editor pela interface
/// [OfficeWordController]:
///
/// * `ribbon.dart` + `tabs/*.dart` — abas (inclusive a contextual de
///   tabela) e realce de estado;
/// * `rulers.dart` — réguas com marcadores de recuo arrastáveis;
/// * `title_bar.dart`, `status_bar.dart` — chrome auxiliar;
/// * `ribbon_actions.dart`, `table_ops.dart` — as ações como funções
///   puras, testáveis sem chrome.
///
/// Três modos ([OfficeWordMode]): `view` (somente leitura), `flow` (edição
/// contínua sem paginação visível) e `word` (completo). A ribbon usa os
/// MESMOS comandos dos atalhos; a aba Layout repagina de verdade
/// ([setPageSetup]); o zoom muda apenas a escala twips→px da projeção.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import '../../platform/dom.dart';
import '../diagnostics/open_document_timing.dart';
import '../layout/dom_renderer.dart';
import '../layout/layout_composer.dart';
import '../layout/page_graph.dart';
import '../model/index.dart';
import '../office/docx_codec.dart';
import '../office/pdf_service.dart';
import '../office/schema.dart';
import '../office/snapshot.dart';
import '../state/index.dart';
import '../view/editor_view.dart';
import '../view/extension.dart';
import 'controller.dart';
import 'ribbon.dart';
import 'ribbon_actions.dart' as ribbon_actions;
import 'rulers.dart';
import 'status_bar.dart';
import 'title_bar.dart';
import 'word_options.dart';

export 'controller.dart' show OfficeWordController, OfficeDomKit;
export 'ribbon.dart' show OfficeRibbon, RibbonContext;
export 'rulers.dart' show OfficeHorizontalRuler, OfficeVerticalRuler;
export 'word_options.dart';

class OfficeWordEditor implements OfficeWordController {
  OfficeWordEditor._(this.host, this.adapter, this.options, this._schema)
      : _kit = OfficeDomKit(adapter);

  /// Monta o editor completo dentro de [host].
  static OfficeWordEditor mount({
    required DomElement host,
    required DomAdapter adapter,
    required PMNode document,
    OfficeWordEditorOptions options = const OfficeWordEditorOptions(),
    Schema? schema,
  }) {
    final editor = OfficeWordEditor._(
        host, adapter, options, schema ?? officeQuillSchema());
    editor._build(document);
    return editor;
  }

  final DomElement host;
  @override
  final DomAdapter adapter;
  @override
  final OfficeWordEditorOptions options;
  final Schema _schema;
  final OfficeDomKit _kit;

  late OfficeEditorView _view;
  late DomElement _pagesHost;
  late DomElement _canvas;

  OfficeRibbon? _ribbon;
  OfficeHorizontalRuler? _hRuler;
  OfficeVerticalRuler? _vRuler;
  OfficeStatusBar? _statusBar;
  DomElement? _hRulerSlot;
  DomElement? _vRulerSlot;

  double _zoom = 1.0;
  int _lastCanvasScrollLeft = 0;
  bool _disposed = false;
  bool _viewReady = false;
  bool _dirty = false;
  bool _saveInFlight = false;
  bool _pdfExportInFlight = false;
  int _changeRevision = 0;
  PMNode? _observedDoc;
  late final List<OfficeExtension> _extensions;
  final LayoutMeasurementCache _layoutMeasurementCache =
      LayoutMeasurementCache();
  final LayoutTableCache _layoutTableCache = LayoutTableCache();
  final LayoutTableLineCache _layoutTableLineCache = LayoutTableLineCache();
  late final DomEventListener _saveShortcut;

  late PageSetupTwips _setup = options.setup;
  late String _documentBaseName = _fileStem(options.title);
  List<PageSetupTwips> _sections = const [];
  PMNode? _header;
  PMNode? _footer;
  Map<String, PMNode> _headerVariants = const {};
  Map<String, PMNode> _footerVariants = const {};
  bool _titlePage = false;
  bool _evenAndOddHeaders = false;
  OfficeDocumentSnapshot? _sourceSnapshot;
  Uint8List? _sourceDocxBytes;
  Map<String, dynamic>? _sourceMap;

  /// `lastRenderedPageBreak` é um cache do Word válido apenas para o estado
  /// recém-aberto. A primeira edição ou alteração de papel/margens o invalida
  /// por toda a sessão; salvar e trocar o zoom não o tornam válido novamente.
  bool _renderedPageBreakHintsValid = true;

  /// Um documento novo sempre grava o setup corrente. Num DOCX aberto, o
  /// `sectPr` original fica byte a byte até a aba Layout ser realmente usada.
  bool _pageSetupDirty = true;

  // -- OfficeWordController ---------------------------------------------------

  @override
  Schema get schema => _schema;
  @override
  OfficeEditorView get view => _view;
  @override
  bool get viewReady => _viewReady;
  @override
  PageSetupTwips get pageSetup => _setup;
  @override
  double get zoom => _zoom;
  @override
  double get pxPerTwip => 96 / 72 / 20 * _zoom;
  @override
  String get documentBaseName => _documentBaseName;
  @override
  bool get isDirty => _dirty;

  PageGraph get pageGraph => _view.pageGraph;
  EditorState get state => _view.state;

  @override
  void dispatch(Transaction tr) => _view.dispatch(tr);

  @override
  bool runCommand(String name) => _view.runCommand(name);

  @override
  void syncSelection() => _view.syncSelectionFromDom();

  @override
  Map? currentBlockStyle() {
    final style = _view.state.selection.fromRes.parent.attrs['style'];
    return style is Map ? style : null;
  }

  @override
  void applyBlockStyle(Map<String, dynamic> patch) {
    final state = _view.state;
    final tr = state.tr;
    state.doc.nodesBetween(state.selection.from, state.selection.to,
        (node, pos, parent, index) {
      if (!node.isTextblock) return true;
      final style = node.attrs['style'];
      tr.setNodeMarkup(pos, null, {
        ...node.attrs,
        'style': {if (style is Map) ...style.cast<String, dynamic>(), ...patch},
      });
      return false;
    });
    if (tr.docChanged) _view.dispatch(tr);
  }

  /// O PDF da MESMA paginação que está na tela — não há segunda composição.
  @override
  Uint8List exportPdf() =>
      OfficePdfService(title: documentBaseName, fonts: options.fonts)
          .fromPageGraph(_view.pageGraph)
          .bytes;

  @override
  Future<Uint8List> exportPdfAsync({Map<String, int>? timings}) async =>
      (await OfficePdfService(title: documentBaseName, fonts: options.fonts)
              .fromPageGraphAsync(
        _view.pageGraph,
        timings: timings,
      ))
          .bytes;

  @override
  Future<void> savePdf() async {
    if (_disposed || _pdfExportInFlight) return;
    _pdfExportInFlight = true;
    final filename = '$documentBaseName.pdf';
    final timings = <String, int>{};
    final watch = Stopwatch()..start();
    adapter.document.body.setAttribute(
      'data-dq-office-export-timings',
      '{}',
    );
    try {
      final bytes = await exportPdfAsync(timings: timings);
      // Give the browser one paint opportunity after the cooperative renderer
      // has completed before allocating the native Blob.
      await Future<void>.delayed(Duration.zero);
      final handoffWatch = Stopwatch()..start();
      await adapter.downloadBytesAsync(
        filename,
        'application/pdf',
        bytes,
        timings: timings,
      );
      handoffWatch.stop();
      timings['downloadHandoffUs'] = handoffWatch.elapsedMicroseconds;
      watch.stop();
      adapter.document.body.setAttribute(
        'data-dq-office-export-timings',
        jsonEncode({
          'totalMs': watch.elapsedMicroseconds / 1000,
          for (final entry in timings.entries)
            entry.key:
                entry.key.endsWith('Us') ? entry.value / 1000 : entry.value,
        }),
      );
    } finally {
      _pdfExportInFlight = false;
    }
  }

  /// O DOCX do documento atual. Documentos importados são gravados sobre o
  /// snapshot de origem, preservando partes e blocos que o editor não
  /// representa; documentos novos partem de um pacote mínimo.
  @override
  Uint8List exportDocx() {
    final codec = OfficeDocxCodec(schema: _schema);
    final pageSetupOverride = _pageSetupDirty ? _setup : null;
    final sourceBytes = _sourceDocxBytes;
    final sourceMap = _sourceMap;
    if (sourceBytes != null && sourceMap != null) {
      return codec.exportEditedFromDocx(
        sourceBytes,
        sourceMap,
        _view.state.doc,
        pageSetup: pageSetupOverride,
      );
    }
    final source = _sourceSnapshot;
    return source == null
        ? codec.exportDocument(_view.state.doc, pageSetup: _setup)
        : codec.exportEdited(
            source,
            _view.state.doc,
            pageSetup: pageSetupOverride,
          );
  }

  @override
  Future<Uint8List> exportDocxAsync({Map<String, int>? timings}) async {
    final sourceBytes = _sourceDocxBytes;
    final sourceMap = _sourceMap;
    if (sourceBytes != null && sourceMap != null) {
      return OfficeDocxCodec(schema: _schema).exportEditedFromDocxAsync(
        sourceBytes,
        sourceMap,
        _view.state.doc,
        pageSetup: _pageSetupDirty ? _setup : null,
        timings: timings,
      );
    }
    return exportDocx();
  }

  /// Caminho único de Save usado pelo botão DOCX e por Ctrl/Cmd+S.
  @override
  Future<void> saveDocx() async {
    if (_disposed || _saveInFlight) return;
    _saveInFlight = true;
    final saveRevision = _changeRevision;
    final filename = '$documentBaseName.docx';
    final timings = <String, int>{};
    final watch = Stopwatch()..start();
    adapter.document.body.setAttribute(
      'data-dq-office-export-timings',
      '{}',
    );
    try {
      final bytes = await exportDocxAsync(timings: timings);
      // The DOCX reader/signature context becomes collectible when export
      // returns. A few separate tasks give V8 incremental-cleanup windows
      // before Blob allocation without adding a fixed wall-clock delay.
      for (var turn = 0; turn < 4; turn++) {
        await Future<void>.delayed(Duration.zero);
      }
      final handoffWatch = Stopwatch()..start();
      await adapter.downloadBytesAsync(
        filename,
        'application/vnd.openxmlformats-officedocument'
        '.wordprocessingml.document',
        bytes,
        timings: timings,
      );
      handoffWatch.stop();
      timings['downloadHandoffUs'] = handoffWatch.elapsedMicroseconds;
      watch.stop();
      adapter.document.body.setAttribute(
        'data-dq-office-export-timings',
        jsonEncode({
          'totalMs': watch.elapsedMicroseconds / 1000,
          for (final entry in timings.entries)
            entry.key:
                entry.key.endsWith('Us') ? entry.value / 1000 : entry.value,
        }),
      );
      // Uma edição/abertura ocorrida enquanto a serialização aguardava não
      // pode ser marcada como salva por um download do estado anterior.
      if (_changeRevision == saveRevision) _setDirty(false);
    } finally {
      _saveInFlight = false;
    }
  }

  /// Troca a escala da projeção. Só a borda twips→px muda: grafo, mapa de
  /// posições e PDF ficam idênticos — e o histórico de undo sobrevive,
  /// porque o `EditorState` é reaproveitado.
  @override
  void setZoom(double zoom) {
    if (_disposed || zoom <= 0) return;
    _zoom = zoom;
    _remountPreservingState();
  }

  /// Troca a geometria da página (aba Layout). Diferente do zoom, o
  /// documento REPAGINA de verdade; conteúdo e histórico ficam intactos.
  @override
  void setPageSetup(PageSetupTwips setup) {
    if (_disposed) return;
    _setup = setup;
    _renderedPageBreakHintsValid = false;
    _pageSetupDirty = true;
    _markDirty();
    // A aba Layout hoje altera o documento inteiro. Uma escolha explícita do
    // usuário portanto substitui a sequência de seções importada pelo setup
    // único escolhido, em vez de parecer funcionar e continuar usando as
    // geometrias antigas.
    _sections = const [];
    _remountPreservingState();
  }

  /// Abre um documento NOVO (aba Arquivo): estado e histórico recomeçam.
  @override
  void openDocument(
    PMNode doc, {
    PageSetupTwips? setup,
    List<PageSetupTwips>? sections,
    PMNode? header,
    PMNode? footer,
    Map<String, PMNode>? headerVariants,
    Map<String, PMNode>? footerVariants,
    bool titlePage = false,
    bool evenAndOddHeaders = false,
    OfficeDocumentSnapshot? sourceSnapshot,
    Uint8List? sourceDocxBytes,
    Map<String, dynamic>? sourceMap,
    String? sourceFileName,
  }) {
    if (_disposed) return;
    _changeRevision++;
    // Só um novo DOCX inicia outro ciclo de validade. Abrir Delta ou outro
    // documento sem pacote de origem não pode ressuscitar hints herdados da
    // sessão anterior.
    _renderedPageBreakHintsValid =
        sourceDocxBytes != null || sourceSnapshot != null;
    if (sourceFileName != null) {
      _documentBaseName = _fileStem(
        sourceFileName,
        fallback: _fileStem(options.title),
      );
    }
    if (setup != null) _setup = setup;
    _sections = sections == null
        ? const []
        : List<PageSetupTwips>.unmodifiable(sections);
    _header = header;
    _footer = footer;
    _headerVariants = headerVariants == null
        ? const {}
        : Map<String, PMNode>.unmodifiable(headerVariants);
    _footerVariants = footerVariants == null
        ? const {}
        : Map<String, PMNode>.unmodifiable(footerVariants);
    _titlePage = titlePage;
    _evenAndOddHeaders = evenAndOddHeaders;
    _sourceSnapshot = sourceSnapshot;
    _sourceDocxBytes =
        sourceDocxBytes == null ? null : Uint8List.fromList(sourceDocxBytes);
    _sourceMap =
        sourceMap == null ? null : Map<String, dynamic>.unmodifiable(sourceMap);
    _pageSetupDirty = sourceSnapshot == null && sourceDocxBytes == null;
    _setDirty(false);
    _updateTitleBar();
    _view.dispose();
    _canvas.scrollTop = 0;
    _canvas.scrollLeft = 0;
    _lastCanvasScrollLeft = 0;
    _rebuildRulers();
    _mountView(EditorState.create(EditorStateConfig(
      doc: doc,
      plugins: OfficeExtensionSet(_extensions).plugins,
    )));
  }

  @override
  Future<int> prewarmLayout(
    PMNode document, {
    required PageSetupTwips setup,
    List<PageSetupTwips> sections = const [],
    PMNode? header,
    PMNode? footer,
    Map<String, PMNode> headerVariants = const {},
    Map<String, PMNode> footerVariants = const {},
    bool titlePage = false,
    bool evenAndOddHeaders = false,
    bool honorRenderedPageBreaks = true,
    Map<String, int>? timings,
  }) async {
    if (_disposed) return 0;
    // A new import replaces the prior table working set. Measurements remain
    // useful across documents and are independently bounded by authority.
    _layoutTableCache.clear();
    _layoutTableLineCache.clear();
    final composer = LayoutComposer(
      setup: setup,
      sections: sections,
      header: header,
      footer: footer,
      headerVariants: headerVariants,
      footerVariants: footerVariants,
      titlePage: titlePage,
      evenAndOddHeaders: evenAndOddHeaders,
      fonts: options.fonts,
      measurementCache: _layoutMeasurementCache,
      tableCache: _layoutTableCache,
      tableLineCache: _layoutTableLineCache,
    );
    final measurementYields = await composer.prewarmMeasurementsAsync([
      document,
      if (header != null) header,
      if (footer != null) footer,
      ...headerVariants.values,
      ...footerVariants.values,
    ]);
    final tableTimings = <String, int>{};
    final tableYields = await composer.prewarmTableLayoutsAsync(
      document,
      honorRenderedPageBreaks: honorRenderedPageBreaks,
      timings: tableTimings,
    );
    timings?['measurementCooperativeYields'] = measurementYields;
    if (timings != null) timings.addAll(tableTimings);
    return measurementYields + tableYields;
  }

  // -- montagem ---------------------------------------------------------------

  void _build(PMNode document) {
    _zoom = options.zoom;
    _extensions = officeDefaultExtensions(_schema);
    host.classes.add('dq-office-app');
    _setDirty(false);
    _saveShortcut = _handleSaveShortcut;
    host.addEventListener('keydown', _saveShortcut);
    if (options.mode == OfficeWordMode.flow) {
      host.classes.add('dq-office-app-flow');
    }

    if (options.mode == OfficeWordMode.word) {
      if (options.showTitleBar) {
        host.append(OfficeTitleBar(this).build());
      }
      _ribbon = OfficeRibbon(this);
      host.append(_ribbon!.build());
    } else if (options.mode == OfficeWordMode.flow) {
      _ribbon = OfficeRibbon(this);
      host.append(_ribbon!.buildCompact());
    }

    _canvas = _kit.el('div', 'dq-office-canvas');
    if (options.mode == OfficeWordMode.word) {
      // A régua horizontal é uma faixa do chrome: fica imediatamente abaixo
      // da ribbon e NÃO passeia junto das páginas.
      _hRuler = OfficeHorizontalRuler(this);
      _hRulerSlot = _kit.el('div', 'dq-office-ruler-wrap');
      _hRulerSlot!.append(_hRuler!.build());
      host.append(_hRulerSlot!);

      // A vertical continua no canvas porque acompanha a página da seleção,
      // mas é ancorada no lado esquerdo do VIEWPORT, não ao lado da folha.
      _vRuler = OfficeVerticalRuler(this);
      _vRulerSlot = _kit.el('div', 'dq-office-vruler-slot');
      _vRulerSlot!.append(_vRuler!.build());
      _canvas.append(_vRulerSlot!);
      _canvas.addEventListener(
          'pointermove', (event) => _hRuler?.handlePointerMove(event));
      _canvas.addEventListener(
          'pointerup', (event) => _hRuler?.handlePointerUp(event));
      _canvas.addEventListener('scroll', (_) {
        _lastCanvasScrollLeft = _canvas.scrollLeft;
        _positionVerticalRuler();
      });
      _canvas.addEventListener(
          'mouseup', (_) => ribbon_actions.maybeApplyFormatPainter(this));
    }
    _pagesHost = _kit.el('div', 'dq-office-pages');
    _canvas.append(_pagesHost);
    host.append(_canvas);

    _statusBar = OfficeStatusBar(this);
    host.append(_statusBar!.build());

    _mountView(EditorState.create(EditorStateConfig(
      doc: document,
      plugins: OfficeExtensionSet(_extensions).plugins,
    )));

    // A página corrente muda com clique e navegação, não só com transação.
    _canvas.addEventListener('click', (_) => _refresh());
    _canvas.addEventListener('keyup', (_) => _refresh());
  }

  void _mountView(EditorState state) {
    _observedDoc = state.doc;
    _view = OfficeEditorView(
      host: _pagesHost,
      state: state,
      adapter: adapter,
      extensions: _extensions,
      composer: LayoutComposer(
        setup: _setup,
        sections: _sections,
        header: _header ?? _regionOf(options.headerText),
        footer: _footer ?? _regionOf(options.footerText),
        headerVariants: _headerVariants,
        footerVariants: _footerVariants,
        titlePage: _titlePage,
        evenAndOddHeaders: _evenAndOddHeaders,
        fonts: options.fonts,
        measurementCache: _layoutMeasurementCache,
        tableCache: _layoutTableCache,
        tableLineCache: _layoutTableLineCache,
      ),
      renderer: PageGraphDomRenderer(
        document: adapter.document,
        editable: options.mode != OfficeWordMode.view,
        pxPerPt: 96 / 72 * _zoom,
        pageGapPx: options.mode == OfficeWordMode.flow ? 0 : 26,
        scrollTopInsetPx: 26,
      ),
      virtualization: options.virtualization,
      scrollContainer: _canvas,
      honorRenderedPageBreaks: _renderedPageBreakHintsValid,
      onStateChange: _handleStateChange,
      onVisiblePageChange: (_) => _statusBar?.update(),
    );
    _viewReady = true;
    measureOpenDocumentPhase<void>('refresh', _refresh);
  }

  void _handleStateChange(EditorState state) {
    if (!identical(_observedDoc, state.doc)) {
      _observedDoc = state.doc;
      _renderedPageBreakHintsValid = false;
      _markDirty();
    }
    _refresh();
  }

  void _handleSaveShortcut(DomEvent event) {
    if (_disposed || event is! DomKeyboardEvent || event.isComposing) return;
    if (event.key.toLowerCase() != 's' ||
        (!event.ctrlKey && !event.metaKey) ||
        event.altKey ||
        event.shiftKey) {
      return;
    }
    event.preventDefault();
    event.stopPropagation();
    unawaited(saveDocx());
  }

  void _markDirty() {
    _changeRevision++;
    _setDirty(true);
  }

  void _setDirty(bool value) {
    _dirty = value;
    host.setAttribute('data-dq-office-dirty', value ? 'true' : 'false');
  }

  void _updateTitleBar() {
    final title = host.querySelector('.dq-office-doc-title');
    if (title != null) _kit.setText(title, documentBaseName);
  }

  static String _fileStem(String raw, {String fallback = 'Documento'}) {
    var name = raw.trim().replaceAll('\\', '/').split('/').last.trim();
    name = name.replaceFirst(
      RegExp(r'\.(?:docx|pdf|json)$', caseSensitive: false),
      '',
    );
    name = name.trim();
    return name.isEmpty ? fallback : name;
  }

  PMNode? _regionOf(String? text) {
    if (text == null || text.isEmpty) return null;
    return _schema.node(
        'doc',
        null,
        Fragment.from([
          _schema.node('paragraph', {'align': 'center'},
              Fragment.from([_schema.text(text)]))
        ]));
  }

  void _remountPreservingState() {
    final state = _view.state;
    _view.dispose();
    _rebuildRulers();
    _mountView(state);
  }

  /// Réguas refletem geometria E zoom: mudou um dos dois, são reconstruídas
  /// nos slots.
  void _rebuildRulers() {
    final hSlot = _hRulerSlot;
    if (hSlot != null && _hRuler != null) {
      _kit.clear(hSlot);
      hSlot.append(_hRuler!.build());
    }
    final vSlot = _vRulerSlot;
    if (vSlot != null && _vRuler != null) {
      _kit.clear(vSlot);
      vSlot.append(_vRuler!.build());
    }
  }

  /// Um refresh por mudança de estado: status, realce da ribbon, aba
  /// contextual e marcadores da régua.
  void _refresh() {
    if (_disposed || !_viewReady) return;
    _statusBar?.update();
    _ribbon?.refreshState();
    _ribbon?.refreshContextual();
    _hRuler?.positionMarkers();
    _positionVerticalRuler();
  }

  /// Coloca a única régua vertical na página que contém o cursor/seleção.
  /// `left = scrollLeft` mantém a régua no canto esquerdo visível mesmo ao
  /// rolar horizontalmente. O topo é calculado no mesmo fluxo flex das
  /// páginas (padding do canvas + alturas + gaps).
  void _positionVerticalRuler() {
    final slot = _vRulerSlot;
    if (slot == null || !_viewReady || _view.pageGraph.pages.isEmpty) return;
    final pages = _view.pageGraph.pages;
    var pageIndex =
        _view.pageGraph.positionMap.pageOf(_view.state.selection.from);
    pageIndex = pageIndex.clamp(0, pages.length - 1);
    var top = 26.0;
    for (var i = 0; i < pageIndex; i++) {
      top += pages[i].setup.heightTwips * pxPerTwip + 26.0;
    }
    slot.setAttribute(
      'style',
      'top:${top.toStringAsFixed(2)}px;left:${_lastCanvasScrollLeft}px;',
    );
    slot.setAttribute('data-page', '$pageIndex');
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    host.removeEventListener('keydown', _saveShortcut);
    _view.dispose();
    _kit.clear(host);
    host.classes.remove('dq-office-app');
    host.classes.remove('dq-office-app-flow');
  }
}
