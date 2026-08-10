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
import '../office/style_catalog.dart';
import '../office/pdf_service.dart';
import '../office/snapshot.dart';
import '../state/index.dart';
import '../view/editor_view.dart';
import '../view/extension.dart';
import 'context_menu.dart';
import 'controller.dart';
import 'header_footer.dart';
import 'object_adorner.dart';
import 'overlay.dart';
import 'quickbar.dart';
import 'ribbon.dart';
import 'ribbon_actions.dart' as ribbon_actions;
import 'rulers.dart';
import 'status_bar.dart';
import 'table_adorner.dart';
import 'text_box_session.dart';
import 'title_bar.dart';
import 'word_options.dart';

export 'controller.dart'
    show OfficeWordController, OfficeDomKit, OfficeComboBox;
export 'context_menu.dart' show OfficeContextMenu;
export 'header_footer.dart' show OfficeHeaderFooterSession, OfficeRegionRef;
export 'image_insert.dart'
    show
        insertImage,
        pickAndInsertImage,
        imagePixelSize,
        imageMimeType,
        officeImageNode,
        officeImageAccept,
        officeTwipsPerPixel;
export 'menu.dart' show OfficeMenuEntry, buildMenu, openMenu, openMenuAt;
export 'object_adorner.dart' show OfficeObjectAdorner, officeResizableNodeTypes;
export 'overlay.dart'
    show OfficeOverlay, OfficePopupHandle, OfficePopupPlacement;
export 'quickbar.dart' show OfficeSelectionQuickbar;
export 'ribbon.dart' show OfficeRibbon, RibbonContext;
export 'rulers.dart' show OfficeHorizontalRuler, OfficeVerticalRuler;
export 'table_adorner.dart'
    show OfficeTableAdorner, officeColumnResizeTolerancePx;
export 'table_map.dart' show OfficeTableMap, OfficeTableCell;
export 'word_options.dart';

class OfficeWordEditor implements OfficeWordController {
  OfficeWordEditor._(this.host, this.adapter, this.options, this._schema)
      : _kit = OfficeDomKit(adapter);

  /// Monta o editor completo dentro de [host].
  ///
  /// Sem [schema], vale o schema DO DOCUMENTO. Isso não é um detalhe: cada
  /// chamada de `officeQuillSchema()` constrói uma instância nova, e um
  /// editor com schema diferente do documento rejeita silenciosamente toda
  /// inserção posterior (o content matching compara tipos por identidade).
  /// O sintoma é uma transação que "não faz nada" — caro de diagnosticar.
  static OfficeWordEditor mount({
    required DomElement host,
    required DomAdapter adapter,
    required PMNode document,
    OfficeWordEditorOptions options = const OfficeWordEditorOptions(),
    Schema? schema,
  }) {
    final resolved = schema ?? document.type.schema;
    if (schema != null && !identical(schema, document.type.schema)) {
      throw ArgumentError.value(
        schema,
        'schema',
        'o documento foi construído com OUTRA instância de Schema; '
            'tipos de nó são comparados por identidade e toda edição '
            'posterior seria descartada em silêncio',
      );
    }
    final editor = OfficeWordEditor._(host, adapter, options, resolved);
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
  late PageGraphDomRenderer _renderer;
  late DomElement _pagesHost;
  late DomElement _canvas;

  late final OfficeOverlay _overlay = OfficeOverlay(this);
  late final OfficeObjectAdorner _objectAdorner = OfficeObjectAdorner(this);
  late final OfficeTableAdorner _tableAdorner = OfficeTableAdorner(this);
  late final OfficeHeaderFooterSession _headerFooter =
      OfficeHeaderFooterSession(this, onChanged: _refresh);
  late final OfficeTextBoxSession _textBox =
      OfficeTextBoxSession(this, onChanged: _refresh);
  OfficeSelectionQuickbar? _quickbar;
  OfficeContextMenu? _contextMenu;
  DomEventListener? _contextMenuListener;
  OfficeRibbon? _ribbon;
  OfficeHorizontalRuler? _hRuler;
  OfficeVerticalRuler? _vRuler;
  OfficeStatusBar? _statusBar;
  DomElement? _hRulerSlot;
  DomElement? _vRulerSlot;

  double _zoom = 1.0;
  int _lastCanvasScrollLeft = 0;
  int _busyDepth = 0;
  DomElement? _busyOverlay;
  DomElement? _busyLabel;
  bool _disposed = false;
  bool _viewReady = false;

  /// Falso enquanto o modo cabeçalho/rodapé está aberto: as páginas do corpo
  /// nascem SEM `contenteditable`.
  bool _bodyEditable = true;
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
  OfficeStyleCatalog? _styleCatalog;

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
  OfficeOverlay get overlay => _overlay;
  @override
  OfficeEditorView get view => _view;

  /// A edição corrente pode estar na região: comandos, undo e a quickbar
  /// seguem para lá enquanto o modo cabeçalho/rodapé está aberto. Réguas,
  /// status bar e adornos continuam usando [view] — eles falam da PÁGINA.
  @override
  OfficeEditorView get activeView =>
      _textBox.boxView ?? _headerFooter.regionView ?? _view;
  @override
  OfficeHeaderFooterSession get headerFooter => _headerFooter;

  /// A sessão de edição de caixa de texto (F9).
  OfficeTextBoxSession get textBoxSession => _textBox;
  @override
  bool get titlePage => _titlePage;
  @override
  bool get evenAndOddHeaders => _evenAndOddHeaders;
  @override
  bool get viewReady => _viewReady;

  /// A geometria da seção onde o cursor está.
  ///
  /// Com `_sections` preenchida o compositor usa `sections[i]` e IGNORA
  /// `_setup` — devolver `_setup` aqui fazia a régua e os dropdowns de
  /// Layout descreverem uma página que não é a que está na tela num
  /// documento com seção paisagem no meio.
  @override
  PageSetupTwips get pageSetup =>
      _sections.isEmpty ? _setup : _sections[_selectionSectionIndex()];

  /// Índice da seção que contém a seleção, contando as quebras anteriores —
  /// a mesma regra do compositor (`_endsSection`).
  int _selectionSectionIndex() {
    if (_sections.length <= 1 || !_viewReady) return 0;
    final doc = _view.state.doc;
    final target = _view.state.selection.from;
    var offset = 0;
    var section = 0;
    for (var i = 0; i < doc.childCount; i++) {
      final block = doc.child(i);
      // O bloco que CARREGA a quebra ainda pertence à seção que termina
      // nele — é a mesma regra do compositor ("o `sectPr` descreve a seção
      // que termina NELE"). Por isso a checagem vem antes da contagem.
      if (target < offset + block.nodeSize) return section;
      offset += block.nodeSize;
      final style = block.attrs['style'];
      if (style is Map &&
          style['sectionBreak'] == true &&
          section + 1 < _sections.length) {
        section++;
      }
    }
    return section;
  }

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
  void dispatch(Transaction tr) => activeView.dispatch(tr);

  @override
  bool runCommand(String name) => activeView.runCommand(name);

  @override
  void syncSelection() => activeView.syncSelectionFromDom();

  @override
  OfficeStyleCatalog? get styleCatalog => _styleCatalog;

  @override
  void styleCatalogChanged() {
    // Renomear/tirar da galeria não produz transação, então o `dirty` e a
    // reconstrução do chrome precisam ser explícitos — senão a galeria
    // mostraria o nome antigo e o Salvar acharia que nada mudou.
    _markDirty();
    _ribbon?.rebuildActiveTab();
  }

  @override
  Map? currentBlockStyle() {
    final style = activeView.state.selection.fromRes.parent.attrs['style'];
    return style is Map ? style : null;
  }

  @override
  void applyBlockStyle(Map<String, dynamic> patch) {
    final target = activeView;
    final state = target.state;
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
    if (tr.docChanged) target.dispatch(tr);
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
    await runBusy('Exportando PDF…', () => _savePdfInner());
  }

  Future<void> _savePdfInner() async {
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
        headers: _editedRegions(_header, _headerVariants),
        footers: _editedRegions(_footer, _footerVariants),
        styleCatalog: _styleCatalog,
      );
    }
    final source = _sourceSnapshot;
    return source == null
        ? codec.exportDocument(_view.state.doc, pageSetup: _setup)
        : codec.exportEdited(
            source,
            _view.state.doc,
            pageSetup: pageSetupOverride,
            styleCatalog: _styleCatalog,
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
        headers: _editedRegions(_header, _headerVariants),
        footers: _editedRegions(_footer, _footerVariants),
        styleCatalog: _styleCatalog,
        timings: timings,
      );
    }
    return exportDocx();
  }

  /// As regiões editadas na sessão, por chave de variante, para a
  /// exportação reserializar a PARTE correspondente.
  ///
  /// Um documento sem variantes ainda tem a região `default` (o `_header`
  /// simples): mandá-la sob essa chave é o que faz a edição de um cabeçalho
  /// comum chegar ao arquivo. As variantes, quando existem, mandam sozinhas
  /// — `_header` nesse caso é apenas um apelido da `default`.
  Map<String, PMNode> _editedRegions(
      PMNode? single, Map<String, PMNode> variants) {
    if (variants.isNotEmpty) return variants;
    return single == null ? const {} : {'default': single};
  }

  /// Caminho único de Save usado pelo botão DOCX e por Ctrl/Cmd+S.
  @override
  Future<void> saveDocx() async {
    if (_disposed || _saveInFlight) return;
    _saveInFlight = true;
    await runBusy('Salvando DOCX…', () => _saveDocxInner());
  }

  Future<void> _saveDocxInner() async {
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

  /// Overlay de ocupado com spinner. Aparece na PRIMEIRA entrada e some na
  /// última saída (contador), então abrir + prewarm + compose exibem UM
  /// spinner contínuo. O trabalho pesado do editor é cooperativo (cede o
  /// event loop), então a animação CSS continua rodando.
  @override
  Future<T> runBusy<T>(String label, Future<T> Function() action) async {
    if (_disposed) return action();
    _busyDepth++;
    _showBusy(label);
    // Um frame para o browser PINTAR o overlay antes do primeiro slice de
    // trabalho síncrono.
    await Future<void>.delayed(Duration.zero);
    try {
      return await action();
    } finally {
      _busyDepth--;
      if (_busyDepth <= 0) {
        _busyDepth = 0;
        _hideBusy();
      }
    }
  }

  void _showBusy(String label) {
    var overlay = _busyOverlay;
    if (overlay == null) {
      overlay = _kit.el('div', 'dq-office-busy');
      final box = _kit.el('div', 'dq-office-busy-box');
      box.append(_kit.el('div', 'dq-office-busy-spinner'));
      _busyLabel = _kit.el('span', 'dq-office-busy-label');
      box.append(_busyLabel!);
      overlay.append(box);
      _busyOverlay = overlay;
    }
    if (_busyLabel != null) _kit.setText(_busyLabel!, label);
    if (overlay.parentNode == null) host.append(overlay);
    host.setAttribute('data-dq-office-busy', 'true');
  }

  void _hideBusy() {
    _busyOverlay?.remove();
    host.setAttribute('data-dq-office-busy', 'false');
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
    _renderedPageBreakHintsValid = false;
    _markDirty();

    if (_sections.length <= 1) {
      // Documento de uma seção: o setup É o do documento, e a exportação
      // regenera o `sectPr` final com ele.
      _setup = setup;
      _sections = const [];
      _pageSetupDirty = true;
      _remountPreservingState();
      return;
    }

    // Documento com várias seções (B3): a escolha vale para a seção do
    // cursor, e as outras ficam como estavam. Descartar a lista inteira —
    // o que este método fazia — jogava fora a paisagem do anexo por causa
    // de uma troca de margem feita na capa.
    final index = _selectionSectionIndex();
    final updated = List<PageSetupTwips>.of(_sections);
    updated[index] = setup;
    _sections = List.unmodifiable(updated);
    if (index == _sections.length - 1) {
      // Só a ÚLTIMA seção chega ao arquivo: `_editedFile` aplica o override
      // ao `sectPr` do corpo, que é o da última seção. Marcar sujo ao editar
      // uma seção intermediária faria a geometria dela ser gravada por cima
      // da última — corrupção silenciosa, pior que a limitação.
      _setup = setup;
      _pageSetupDirty = true;
    }
    _remountPreservingState();
  }

  @override
  void insertSectionAfterSelection() {
    if (_disposed) return;
    // A geometria de partida é a da seção onde o cursor está — inclusive
    // quando ainda não há lista nenhuma, caso em que a primeira seção é o
    // setup do documento.
    final base = pageSetup;
    final index = _sections.isEmpty ? 0 : _selectionSectionIndex();
    final updated = _sections.isEmpty
        ? <PageSetupTwips>[base, base]
        : (List<PageSetupTwips>.of(_sections)..insert(index + 1, base));
    _sections = List.unmodifiable(updated);
    // Os hints de quebra do Word descrevem a paginação ANTIGA; uma seção
    // nova muda onde as páginas terminam.
    _renderedPageBreakHintsValid = false;
    _markDirty();
    _remountPreservingState();
  }

  // -- cabeçalho/rodapé (F6) --------------------------------------------------

  @override
  OfficeRegionRef regionForPage(int pageIndex, {required bool isHeader}) {
    final variants = isHeader ? _headerVariants : _footerVariants;
    // A ordem tem de ser a MESMA de `LayoutComposer._regionForPage`: se a UI
    // resolvesse a variante por outra regra, o usuário editaria um cabeçalho
    // que não é o que está desenhado naquela página.
    if (variants.isNotEmpty) {
      for (final key in [
        if (_titlePage && pageIndex == 0) 'first',
        if (_evenAndOddHeaders && (pageIndex + 1).isEven) 'even',
        'default',
      ]) {
        final doc = variants[key];
        if (doc != null) {
          return OfficeRegionRef(isHeader: isHeader, variant: key, doc: doc);
        }
      }
    }
    return OfficeRegionRef(
      isHeader: isHeader,
      variant: null,
      doc: isHeader ? _header : _footer,
    );
  }

  @override
  void setRegionDocument(OfficeRegionRef ref, PMNode doc,
      {bool recompose = false}) {
    if (_disposed) return;
    final variant = ref.variant;
    if (variant == null) {
      if (ref.isHeader) {
        _header = doc;
      } else {
        _footer = doc;
      }
    } else {
      final variants = ref.isHeader ? _headerVariants : _footerVariants;
      final previous = variants[variant];
      final updated =
          Map<String, PMNode>.unmodifiable({...variants, variant: doc});
      if (ref.isHeader) {
        _headerVariants = updated;
        // O importador aponta `header`/`footer` para a variante `default`;
        // deixar o campo simples preso ao nó ANTIGO faria o prewarm e o
        // fallback medirem um cabeçalho que ninguém mais projeta.
        if (identical(_header, previous)) _header = doc;
      } else {
        _footerVariants = updated;
        if (identical(_footer, previous)) _footer = doc;
      }
    }
    // A região muda a altura do inset do corpo: os hints de quebra do Word
    // deixam de descrever este documento.
    _renderedPageBreakHintsValid = false;
    _markDirty();
    if (recompose) _remountPreservingState();
  }

  @override
  void setHeaderFooterFlags({bool? titlePage, bool? evenAndOddHeaders}) {
    if (_disposed) return;
    if (titlePage == null && evenAndOddHeaders == null) return;
    if (titlePage != null) _titlePage = titlePage;
    if (evenAndOddHeaders != null) _evenAndOddHeaders = evenAndOddHeaders;
    _renderedPageBreakHintsValid = false;
    _markDirty();
    _remountPreservingState();
  }

  @override
  void setBodyEditingSuspended(bool suspended) {
    if (_disposed) return;
    _bodyEditable = !suspended;
    if (suspended) {
      host.classes.add('dq-office-app-hf');
    } else {
      host.classes.remove('dq-office-app-hf');
    }
    if (!_viewReady) return;
    _renderer.editable = _rendererEditable;
    // Só a projeção muda; o grafo é o mesmo, então nada é recomposto.
    _view.reproject();
  }

  bool get _rendererEditable =>
      options.mode != OfficeWordMode.view && _bodyEditable;

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
    OfficeStyleCatalog? styleCatalog,
  }) {
    if (_disposed) return;
    _changeRevision++;
    // O modo cabeçalho/rodapé descreve o documento que está saindo: manter a
    // sessão viva editaria uma região que não existe mais.
    _headerFooter.dispose();
    _textBox.dispose();
    _bodyEditable = true;
    host.classes.remove('dq-office-app-hf');
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
    // Sem catálogo explícito, tenta o snapshot: um envelope persistido com
    // as partes opacas ainda carrega o `styles.xml`. O caminho rápido da UI
    // (que importa sem as partes) passa o catálogo por parâmetro.
    _styleCatalog = styleCatalog ??
        (sourceSnapshot == null
            ? null
            : OfficeStyleCatalog.fromSnapshot(sourceSnapshot));
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
    // A galeria de estilos é construída a partir do CATÁLOGO, e o catálogo
    // acabou de ser trocado: sem refazer a aba, abrir um DOCX deixaria na
    // tela os cartões do documento anterior. `refreshState` não bastaria —
    // ele reflete a seleção nos controles que já existem, não a fonte de
    // dados deles.
    _ribbon?.rebuildActiveTab();
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
      // O arrasto da régua (recuo, margem, parada de tabulação) começa na
      // FAIXA, que é irmã do canvas: um gesto curto, inteiramente contido na
      // régua, nunca produziria um `pointermove` no canvas. Os dois registros
      // cobrem o gesto inteiro sem duplicar evento (as duas caixas não se
      // contêm).
      for (final target in [_canvas, _hRulerSlot!]) {
        target.addEventListener(
            'pointermove', (event) => _hRuler?.handlePointerMove(event));
        target.addEventListener(
            'pointerup', (event) => _hRuler?.handlePointerUp(event));
      }
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

    // A camada de popups/adornos cobre o editor inteiro e vem por último:
    // dropdowns, comboboxes, quickbars e menus ficam acima de tudo sem
    // depender de z-index espalhado por componente.
    host.append(_overlay.build());
    // Rolar o documento tira o popup do lugar a que ele se ancorou; o Word
    // fecha em vez de deixar um menu órfão flutuando. A moldura do objeto
    // NÃO é popup: ela pertence ao objeto e apenas reacompanha a geometria.
    _canvas.addEventListener('scroll', (_) {
      _overlay.closeAll();
      _objectAdorner.refresh();
      _tableAdorner.refresh();
      _headerFooter.reposition();
      _textBox.reposition();
    });

    if (options.mode != OfficeWordMode.view) {
      // Duplo clique é o gesto do Word para entrar e sair do cabeçalho: na
      // região entra (ou troca de página/região), no corpo sai. Um único
      // handler no canvas mantém os dois lados simétricos.
      _canvas.addEventListener('dblclick', _handleDoubleClick);
    }

    if (options.mode != OfficeWordMode.view) {
      // O arrasto de alça pertence ao canvas inteiro: soltar o ponteiro fora
      // do objeto ainda tem de encerrar (e aplicar) o redimensionamento.
      // A divisa de coluna tem prioridade sobre a seleção de texto: o
      // ponteiro sobre a borda inicia o redimensionamento, como no Word.
      _canvas.addEventListener(
          'pointerdown', (event) => _tableAdorner.handlePointerDown(event));
      _canvas.addEventListener('pointermove', (event) {
        _objectAdorner.handlePointerMove(event);
        _tableAdorner.handlePointerMove(event);
      });
      _canvas.addEventListener('pointerup', (event) {
        _objectAdorner.handlePointerUp(event);
        _tableAdorner.handlePointerUp(event);
      });
    }

    if (options.mode != OfficeWordMode.view) {
      _quickbar = OfficeSelectionQuickbar(this);
      _contextMenu = OfficeContextMenu(this);
      _contextMenuListener = installContextMenu(this, _canvas, _contextMenu!);
      // A quickbar nasce quando o usuário TERMINA de selecionar — durante o
      // arrasto ela cobriria justamente o texto que ele está mirando.
      _canvas.addEventListener('mouseup', _handleSelectionFinished);
      _canvas.addEventListener('keyup', _handleSelectionFinishedByKeyboard);
      // Digitar/apagar dispensa a barra: a formatação é sobre uma seleção,
      // e ela deixou de existir no momento em que a tecla substituiu o
      // texto.
      _canvas.addEventListener('keydown', (_) => _quickbar?.hide());
    }

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
    _renderer = PageGraphDomRenderer(
      document: adapter.document,
      editable: _rendererEditable,
      pxPerPt: 96 / 72 * _zoom,
      pageGapPx: options.mode == OfficeWordMode.flow ? 0 : 26,
      scrollTopInsetPx: 26,
    );
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
      renderer: _renderer,
      virtualization: options.virtualization,
      progressive: options.progressivePagination,
      scrollContainer: _canvas,
      honorRenderedPageBreaks: _renderedPageBreakHintsValid,
      onStateChange: _handleStateChange,
      onVisiblePageChange: (_) => _statusBar?.update(),
      onPaginationProgress: _handlePaginationProgress,
    );
    _viewReady = true;
    if (options.progressivePagination != null) {
      host.setAttribute(
        'data-dq-office-pagination',
        _view.pageGraph.isPartial ? 'partial' : 'complete',
      );
    }
    measureOpenDocumentPhase<void>('refresh', _refresh);
  }

  /// A cada fatia da paginação progressiva: contagem na status bar e o
  /// atributo que integrações/e2e usam para saber quando o total é final.
  void _handlePaginationProgress(int pages, bool complete) {
    if (_disposed) return;
    host.setAttribute(
      'data-dq-office-pagination',
      complete ? 'complete' : 'partial',
    );
    _statusBar?.update();
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

  void _handleDoubleClick(DomEvent event) {
    if (_disposed) return;
    // A CAIXA vem antes: uma caixa desenhada sobre a faixa do cabeçalho é
    // clicada por cima dele, e é nela que o duplo clique cai no Word.
    if (_textBox.handleDoubleClick(event)) {
      event.preventDefault();
      return;
    }
    if (_headerFooter.handleDoubleClick(event)) event.preventDefault();
  }

  /// `mouseup` no documento: se sobrou seleção, a quickbar aparece sobre
  /// ela; senão, some. É também onde o pincel de formatação é aplicado, e a
  /// ordem importa — o pincel age primeiro para a barra já refletir o
  /// resultado.
  void _handleSelectionFinished(DomEvent event) {
    if (_disposed) return;
    // Explicitamente a view do CORPO: este handler vive no canvas e fala das
    // páginas, mesmo que a edição corrente esteja numa região.
    _view.syncSelectionFromDom();
    if (_view.state.selection.empty) {
      _quickbar?.hide();
      return;
    }
    // Com um OBJETO selecionado quem aparece é o adorno (moldura + alças)
    // mais a barra DO OBJETO — não a de formatação de TEXTO, que não teria
    // em que agir.
    if (_view.state.selection is NodeSelection) {
      _showObjectQuickbar();
      return;
    }
    // Seleção retangular de CÉLULAS: a barra é a de tabela.
    if (_view.state.selection is CellSelection) {
      final pointer = event is DomMouseEvent ? event : null;
      _quickbar?.showForTable(
        x: pointer?.clientX ?? 0,
        y: (pointer?.clientY ?? 0) + 12,
      );
      return;
    }
    final pointer = event is DomMouseEvent ? event : null;
    _quickbar?.showForSelection(
      anchorX: pointer?.clientX,
      anchorY: pointer?.clientY,
    );
  }

  /// Seleção pelo teclado (Shift+setas, Ctrl+A): só as teclas que de fato
  /// terminam uma seleção abrem a barra.
  void _handleSelectionFinishedByKeyboard(DomEvent event) {
    if (_disposed || event is! DomKeyboardEvent) return;
    final selecting = event.shiftKey ||
        ((event.ctrlKey || event.metaKey) && event.key.toLowerCase() == 'a');
    if (!selecting) return;
    _view.syncSelectionFromDom();
    if (_view.state.selection.empty) {
      _quickbar?.hide();
      return;
    }
    _quickbar?.showForSelection();
  }

  /// A barra do objeto nasce no canto superior direito dele, onde o Word põe
  /// o botão de Opções de Layout. Sem geometria (VM/fake DOM) ela ainda
  /// abre, no canto da camada.
  void _showObjectQuickbar() {
    final quickbar = _quickbar;
    if (quickbar == null) return;
    final target = _objectAdorner.selectedObject();
    if (target == null) {
      quickbar.hide();
      return;
    }
    final element = _objectAdorner.elementFor(target.pos);
    final bounds = element == null
        ? null
        : adapter.getElementBounds(element, relativeTo: _overlay.layer);
    final layerBounds = adapter.getElementBounds(_overlay.layer);
    // `open` trabalha em coordenadas de tela para `atPoint`; devolvemos a
    // origem da camada ao valor medido em relação a ela.
    final layerLeft = _numOf(layerBounds?['left']);
    final layerTop = _numOf(layerBounds?['top']);
    quickbar.showForObject(
      x: layerLeft + _numOf(bounds?['left']) + _numOf(bounds?['width']) + 6,
      y: layerTop + _numOf(bounds?['top']),
    );
  }

  static double _numOf(Object? value) => value is num ? value.toDouble() : 0.0;

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
    _quickbar?.refreshState();
    _objectAdorner.refresh();
    _tableAdorner.refresh();
    // A superfície da região vive no overlay, que não rola com as páginas —
    // ela reacompanha a página exatamente como os adornos.
    _headerFooter.reposition();
    _textBox.reposition();
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
    final contextMenu = _contextMenuListener;
    if (contextMenu != null) {
      _canvas.removeEventListener('contextmenu', contextMenu);
    }
    _objectAdorner.clear();
    _tableAdorner.clear();
    _headerFooter.dispose();
    _textBox.dispose();
    _overlay.dispose();
    _view.dispose();
    _kit.clear(host);
    host.classes.remove('dq-office-app');
    host.classes.remove('dq-office-app-flow');
  }
}
