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

import 'dart:typed_data';

import '../../platform/dom.dart';
import '../layout/dom_renderer.dart';
import '../layout/layout_composer.dart';
import '../layout/page_graph.dart';
import '../model/index.dart';
import '../office/docx_codec.dart';
import '../office/pdf_service.dart';
import '../office/schema.dart';
import '../state/index.dart';
import '../view/editor_view.dart';
import '../view/extension.dart';
import 'controller.dart';
import 'ribbon.dart';
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
  bool _disposed = false;
  bool _viewReady = false;

  late PageSetupTwips _setup = options.setup;

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
      OfficePdfService(title: options.title).fromPageGraph(_view.pageGraph).bytes;

  /// O DOCX do documento atual (pacote montado do zero — o caminho para
  /// documento nascido no editor; DOCX importado preserva pelo
  /// `exportEdited` da camada de sessão).
  @override
  Uint8List exportDocx() =>
      OfficeDocxCodec(schema: _schema).exportDocument(_view.state.doc);

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
    _remountPreservingState();
  }

  // -- montagem ---------------------------------------------------------------

  void _build(PMNode document) {
    _zoom = options.zoom;
    host.classes.add('dq-office-app');
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
      // As réguas vivem DENTRO da área do documento, como no Word: a
      // horizontal é sticky no topo do canvas e compartilha a centralização
      // da página (alinham por construção e rolam juntas); a vertical fica
      // à esquerda da página.
      _hRuler = OfficeHorizontalRuler(this);
      _hRulerSlot = _kit.el('div', 'dq-office-ruler-wrap');
      _hRulerSlot!.append(_hRuler!.build());
      _canvas.append(_hRulerSlot!);
      _vRuler = OfficeVerticalRuler(this);
      _vRulerSlot = _kit.el('div', 'dq-office-vruler-slot');
      _vRulerSlot!.append(_vRuler!.build());
      _canvas.append(_vRulerSlot!);
      _canvas.addEventListener(
          'pointermove', (event) => _hRuler?.handlePointerMove(event));
      _canvas.addEventListener(
          'pointerup', (event) => _hRuler?.handlePointerUp(event));
    }
    _pagesHost = _kit.el('div', 'dq-office-pages');
    _canvas.append(_pagesHost);
    host.append(_canvas);

    _statusBar = OfficeStatusBar(this);
    host.append(_statusBar!.build());

    _mountView(EditorState.create(EditorStateConfig(
      doc: document,
      plugins: OfficeExtensionSet(officeDefaultExtensions(_schema)).plugins,
    )));

    // A página corrente muda com clique e navegação, não só com transação.
    _canvas.addEventListener('click', (_) => _refresh());
    _canvas.addEventListener('keyup', (_) => _refresh());
  }

  void _mountView(EditorState state) {
    _view = OfficeEditorView(
      host: _pagesHost,
      state: state,
      adapter: adapter,
      extensions: officeDefaultExtensions(_schema),
      composer: LayoutComposer(
        setup: _setup,
        header: _regionOf(options.headerText),
        footer: _regionOf(options.footerText),
      ),
      renderer: PageGraphDomRenderer(
        document: adapter.document,
        editable: options.mode != OfficeWordMode.view,
        pxPerPt: 96 / 72 * _zoom,
      ),
      virtualization: options.virtualization,
      scrollContainer: _canvas,
      onStateChange: (_) => _refresh(),
    );
    _viewReady = true;
    _refresh();
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
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _view.dispose();
    _kit.clear(host);
    host.classes.remove('dq-office-app');
    host.classes.remove('dq-office-app-flow');
  }
}
