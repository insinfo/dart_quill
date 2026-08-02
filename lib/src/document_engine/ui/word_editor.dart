/// OfficeWordEditor — o editor Word COMPLETO como componente da biblioteca.
///
/// A UI pertence à biblioteca, não à aplicação. O consumidor faz UMA
/// chamada e recebe a experiência inteira:
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
/// O visual segue o padrão do shell Word do `docx_rendering` (a referência
/// apontada pelo mantenedor): title bar azul #185abd com o nome do
/// documento, abas de 30 px com o ativo marcado por barra inferior, ribbon
/// de ~100 px com grupos de DUAS linhas e o rótulo do grupo embaixo,
/// canvas #e9eef2, página branca com sombra grande, réguas com banda de
/// ticks de 0,25/0,5 cm e números de 9 px alinhadas À PÁGINA, e barra de
/// status azul. Tudo escopado em `dq-office-*` — nada alcança `.ql-editor`,
/// então o Quill simples e este editor coexistem na mesma página.
///
/// Três modos ([OfficeWordMode]): `view` (somente leitura), `flow` (edição
/// contínua sem paginação visível, como o modo rascunho) e `word`
/// (completo). A ribbon usa EXATAMENTE os mesmos comandos dos atalhos — a
/// UI não tem caminho próprio para mudar o documento. A aba Layout muda a
/// geometria de verdade (`setPageSetup`): o documento repagina, o conteúdo
/// e o histórico ficam. O zoom muda apenas a escala twips→px da projeção.
library;

import 'dart:typed_data';

import '../../platform/dom.dart';
import '../commands/index.dart' as cmd;
import '../layout/dom_renderer.dart';
import '../layout/layout_composer.dart';
import '../layout/page_graph.dart';
import '../model/index.dart';
import '../office/pdf_service.dart';
import '../office/schema.dart';
import '../state/index.dart';
import '../view/editor_view.dart';
import '../view/extension.dart';

/// O modo de apresentação do editor.
enum OfficeWordMode {
  /// Somente leitura, paginado. Sem ribbon, sem régua, sem caret.
  view,

  /// Edição contínua sem paginação visível — o modo rascunho.
  flow,

  /// A experiência Word completa.
  word,
}

/// Configuração do componente.
class OfficeWordEditorOptions {
  const OfficeWordEditorOptions({
    this.mode = OfficeWordMode.word,
    this.setup = const PageSetupTwips(),
    this.headerText,
    this.footerText,
    this.zoom = 1.0,
    this.virtualization = const OfficeVirtualization(radius: 3),
    this.title = 'Documento',
  });

  final OfficeWordMode mode;
  final PageSetupTwips setup;

  /// Texto do cabeçalho/rodapé repetido em toda página. Aceita os campos
  /// `{PAGE}` e `{NUMPAGES}`.
  final String? headerText;
  final String? footerText;

  /// Escala inicial (1.0 = 100%).
  final double zoom;

  final OfficeVirtualization? virtualization;

  /// Nome do documento, mostrado na title bar.
  final String title;
}

class OfficeWordEditor {
  OfficeWordEditor._(this.host, this.adapter, this.options, this._schema);

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
  final DomAdapter adapter;
  final OfficeWordEditorOptions options;
  final Schema _schema;

  late OfficeEditorView _view;
  late DomElement _pagesHost;
  late DomElement _canvas;
  DomElement? _statusPage;
  DomElement? _statusWords;
  DomElement? _hRulerSlot;
  DomElement? _vRulerSlot;
  DomElement? _ribbonBody;
  final Map<String, DomElement> _ribbonTabs = {};
  final Map<String, DomElement> _markButtons = {};
  DomElement? _styleSelect;
  double _zoom = 1.0;
  bool _disposed = false;

  /// A ribbon é construída ANTES da view (a ordem visual do chrome manda);
  /// os refreshes de estado só valem depois que a view existe.
  bool _viewReady = false;

  /// Geometria corrente — a aba Layout a altera (orientação, papel, margens).
  late PageSetupTwips _setup = options.setup;

  /// O laço de edição por baixo do chrome — exposto para integrações.
  OfficeEditorView get view => _view;
  PageGraph get pageGraph => _view.pageGraph;
  EditorState get state => _view.state;
  double get zoom => _zoom;
  PageSetupTwips get pageSetup => _setup;

  bool get _editable => options.mode != OfficeWordMode.view;
  double get _pxPerTwip => 96 / 72 / 20 * _zoom;

  // -- montagem ---------------------------------------------------------------

  void _build(PMNode document) {
    _zoom = options.zoom;
    host.classes.add('dq-office-app');
    if (options.mode == OfficeWordMode.flow) {
      host.classes.add('dq-office-app-flow');
    }

    _injectStyles();

    if (options.mode == OfficeWordMode.word) {
      host.append(_buildTitleBar());
      host.append(_buildRibbon(full: true));
      _hRulerSlot = _el('div', 'dq-office-ruler-slot');
      _hRulerSlot!.append(_buildRuler());
      host.append(_hRulerSlot!);
    } else if (options.mode == OfficeWordMode.flow) {
      host.append(_buildRibbon(full: false));
    }

    _canvas = _el('div', 'dq-office-canvas');
    if (options.mode == OfficeWordMode.word) {
      _vRulerSlot = _el('div', 'dq-office-vruler-slot');
      _vRulerSlot!.append(_buildVerticalRuler());
      _canvas.append(_vRulerSlot!);
    }
    _pagesHost = _el('div', 'dq-office-pages');
    _canvas.append(_pagesHost);
    host.append(_canvas);

    host.append(_buildStatusBar());

    _mountView(EditorState.create(EditorStateConfig(
      doc: document,
      plugins: OfficeExtensionSet(officeDefaultExtensions(_schema)).plugins,
    )));

    // A página corrente muda com clique e navegação, não só com transação.
    _canvas.addEventListener('click', (_) => _refreshStatus());
    _canvas.addEventListener('keyup', (_) => _refreshStatus());
  }

  void _mountView(EditorState state) {
    _view = OfficeEditorView(
      host: _pagesHost,
      state: state,
      adapter: adapter,
      extensions: officeDefaultExtensions(_schema),
      composer: _composer(),
      renderer: PageGraphDomRenderer(
        document: adapter.document,
        editable: _editable,
        pxPerPt: 96 / 72 * _zoom,
      ),
      virtualization: options.virtualization,
      scrollContainer: _canvas,
      onStateChange: (_) => _refreshStatus(),
    );
    _viewReady = true;
    _refreshStatus();
  }

  LayoutComposer _composer() => LayoutComposer(
        setup: _setup,
        header: _regionOf(options.headerText),
        footer: _regionOf(options.footerText),
      );

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

  // -- API pública ------------------------------------------------------------

  /// O PDF da MESMA paginação que está na tela — não há segunda composição.
  Uint8List exportPdf() =>
      OfficePdfService(title: options.title).fromPageGraph(_view.pageGraph).bytes;

  /// Troca a escala da projeção. Só a borda twips→px muda: grafo, mapa de
  /// posições e PDF ficam idênticos — e o histórico de undo sobrevive,
  /// porque o `EditorState` é reaproveitado.
  void setZoom(double zoom) {
    if (_disposed || zoom <= 0) return;
    _zoom = zoom;
    _remountPreservingState();
  }

  /// Troca a geometria da página — orientação, papel, margens (aba Layout).
  ///
  /// Diferente do zoom, aqui o documento REPAGINA de verdade: grafo novo,
  /// PDF novo. Conteúdo e histórico ficam intactos.
  void setPageSetup(PageSetupTwips setup) {
    if (_disposed) return;
    _setup = setup;
    _remountPreservingState();
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _view.dispose();
    while (host.firstChild != null) {
      host.firstChild!.remove();
    }
    host.classes.remove('dq-office-app');
    host.classes.remove('dq-office-app-flow');
  }

  void _remountPreservingState() {
    final state = _view.state;
    _view.dispose();
    _rebuildRulers();
    _mountView(state);
  }

  /// Réguas refletem geometria E zoom: mudou um dos dois, elas são
  /// reconstruídas nos slots. Sem isso a régua fica na escala antiga
  /// enquanto a página muda — foi um bug real do primeiro setZoom.
  void _rebuildRulers() {
    final hSlot = _hRulerSlot;
    if (hSlot != null) {
      while (hSlot.firstChild != null) {
        hSlot.firstChild!.remove();
      }
      hSlot.append(_buildRuler());
    }
    final vSlot = _vRulerSlot;
    if (vSlot != null) {
      while (vSlot.firstChild != null) {
        vSlot.firstChild!.remove();
      }
      vSlot.append(_buildVerticalRuler());
    }
  }

  // -- title bar --------------------------------------------------------------

  DomElement _buildTitleBar() {
    final bar = _el('div', 'dq-office-titlebar');

    final brand = _el('div', 'dq-office-brand');
    final mark = _el('div', 'dq-office-brand-mark');
    for (var i = 0; i < 3; i++) {
      mark.append(_el('i', ''));
    }
    brand.append(mark);
    final name = _el('span', '');
    name.appendText('Word');
    brand.append(name);
    bar.append(brand);

    final title = _el('div', 'dq-office-doc-title');
    title.appendText(options.title);
    bar.append(title);

    bar.append(_el('div', 'dq-office-titlebar-actions'));
    return bar;
  }

  // -- ribbon -----------------------------------------------------------------

  DomElement _buildRibbon({required bool full}) {
    final ribbon = _el('div', 'dq-office-ribbon');

    if (full) {
      final tabs = _el('div', 'dq-office-ribbon-tabs');
      for (final (key, label, enabled) in [
        ('file', 'Arquivo', false),
        ('home', 'Página Inicial', true),
        ('insert', 'Inserir', false),
        ('layout', 'Layout', true),
      ]) {
        final tab = _el('button', 'dq-office-ribbon-tab');
        tab.setAttribute('type', 'button');
        tab.appendText(label);
        if (enabled) {
          _ribbonTabs[key] = tab;
          tab.addEventListener('click', (_) => _showTab(key));
        } else {
          tab.classes.add('dq-office-ribbon-tab-disabled');
          tab.setAttribute('disabled', 'disabled');
        }
        tabs.append(tab);
      }
      ribbon.append(tabs);

      _ribbonBody = _el('div', 'dq-office-ribbon-content');
      ribbon.append(_ribbonBody!);
      _showTab('home');
      return ribbon;
    }

    // Flow: toolbar compacta de uma linha, sem abas.
    final content = _el('div', 'dq-office-ribbon-compact');
    content
        .append(_button('↶', 'Desfazer (Ctrl+Z)', () => _view.runCommand('undo')));
    content
        .append(_button('↷', 'Refazer (Ctrl+Y)', () => _view.runCommand('redo')));
    content.append(_el('span', 'dq-office-ribbon-sep'));
    content.append(_markButton('bold', 'B', 'Negrito (Ctrl+B)', 'dq-office-b'));
    content.append(_markButton('italic', 'I', 'Itálico (Ctrl+I)', 'dq-office-i'));
    content.append(
        _markButton('underline', 'U', 'Sublinhado (Ctrl+U)', 'dq-office-u'));
    content.append(_markButton('strike', 'S', 'Tachado', 'dq-office-s'));
    ribbon.append(content);
    return ribbon;
  }

  void _showTab(String key) {
    final body = _ribbonBody;
    if (body == null) return;
    _ribbonTabs.forEach((tabKey, tab) {
      if (tabKey == key) {
        tab.classes.add('dq-office-ribbon-tab-active');
      } else {
        tab.classes.remove('dq-office-ribbon-tab-active');
      }
    });
    while (body.firstChild != null) {
      body.firstChild!.remove();
    }
    for (final group in key == 'layout' ? _layoutGroups() : _homeGroups()) {
      body.append(group);
    }
    _refreshRibbonState();
  }

  /// Página Inicial — grupos de DUAS linhas como o Word.
  List<DomElement> _homeGroups() {
    _markButtons.clear();
    return [
      _group('Desfazer', [
        _row([
          _button('↶', 'Desfazer (Ctrl+Z)', () => _view.runCommand('undo')),
          _button('↷', 'Refazer (Ctrl+Y)', () => _view.runCommand('redo')),
        ]),
      ]),
      _group('Fonte', [
        _row([
          _select(
            'dq-office-font-family',
            const ['Arial', 'Calibri', 'Times New Roman', 'Courier New'],
            'Arial',
            (value) => _addMarkOverSelection('font', {'value': value}),
          ),
          _select(
            'dq-office-font-size',
            const ['8', '9', '10', '11', '12', '14', '16', '18', '24', '36'],
            '12',
            (value) => _addMarkOverSelection('size', {'value': '${value}pt'}),
          ),
        ]),
        _row([
          _markButton('bold', 'B', 'Negrito (Ctrl+B)', 'dq-office-b'),
          _markButton('italic', 'I', 'Itálico (Ctrl+I)', 'dq-office-i'),
          _markButton('underline', 'U', 'Sublinhado (Ctrl+U)', 'dq-office-u'),
          _markButton('strike', 'S', 'Tachado', 'dq-office-s'),
        ]),
      ]),
      _group('Parágrafo', [
        _row([
          _button('⯇', 'Alinhar à esquerda', () => _setAlign('left')),
          _button('☰', 'Centralizar', () => _setAlign('center')),
          _button('⯈', 'Alinhar à direita', () => _setAlign('right')),
          _button('▤', 'Justificar', () => _setAlign('justify')),
        ]),
      ]),
      _group('Estilos', [
        _row([
          _styleSelect = _select(
            'dq-office-style',
            const ['Normal', 'Título 1', 'Título 2', 'Título 3'],
            'Normal',
            _applyNamedStyle,
          ),
        ]),
      ]),
    ];
  }

  /// Layout — orientação, papel e margens. Cada escolha vira `setPageSetup`.
  List<DomElement> _layoutGroups() {
    _markButtons.clear();
    _styleSelect = null;
    return [
      _group('Orientação', [
        _row([
          _button('▯', 'Retrato', () => _setOrientation(portrait: true)),
          _button('▭', 'Paisagem', () => _setOrientation(portrait: false)),
        ]),
      ]),
      _group('Tamanho', [
        _row([
          _select('dq-office-paper', const ['A4', 'Ofício', 'Carta'],
              _paperName(), _setPaper),
        ]),
      ]),
      _group('Margens', [
        _row([
          _select('dq-office-margins', const ['Normal', 'Estreita', 'Larga'],
              'Normal', _setMargins),
        ]),
      ]),
    ];
  }

  DomElement _group(String label, List<DomElement> rows) {
    final group = _el('div', 'dq-office-ribbon-group');
    group.setAttribute('data-group-label', label);
    final content = _el('div', 'dq-office-ribbon-rows');
    for (final row in rows) {
      content.append(row);
    }
    group.append(content);
    return group;
  }

  DomElement _row(List<DomElement> controls) {
    final row = _el('div', 'dq-office-ribbon-row');
    for (final control in controls) {
      row.append(control);
    }
    return row;
  }

  DomElement _markButton(
      String mark, String text, String title, String cssClass) {
    final button =
        _button(text, title, () => _view.runCommand(mark), extraClass: cssClass);
    _markButtons[mark] = button;
    return button;
  }

  DomElement _button(String text, String title, void Function() action,
      {String? extraClass}) {
    final button =
        _el('button', 'dq-office-btn${extraClass == null ? '' : ' $extraClass'}');
    button.setAttribute('type', 'button');
    button.setAttribute('title', title);
    button.appendText(text);
    button.addEventListener('click', (event) {
      event.preventDefault();
      action();
    });
    return button;
  }

  DomElement _select(String cssClass, List<String> items, String selected,
      void Function(String value) onChange) {
    final select = _el('select', 'dq-office-select $cssClass');
    for (final item in items) {
      final option = _el('option', '');
      option.setAttribute('value', item);
      if (item == selected) option.setAttribute('selected', 'selected');
      option.appendText(item);
      select.append(option);
    }
    select.addEventListener('change', (_) => onChange(select.value));
    return select;
  }

  // -- comandos que a ribbon precisa e os atalhos não têm ---------------------

  void _addMarkOverSelection(String markName, Map<String, dynamic> attrs) {
    final type = _schema.marks[markName];
    if (type == null) return;
    _view.syncSelectionFromDom();
    final selection = _view.state.selection;
    if (selection.empty) return;
    _view.dispatch(
        _view.state.tr..addMark(selection.from, selection.to, type.create(attrs)));
  }

  void _setAlign(String align) {
    _view.syncSelectionFromDom();
    final state = _view.state;
    final tr = state.tr;
    state.doc.nodesBetween(state.selection.from, state.selection.to,
        (node, pos, parent, index) {
      if (!node.isTextblock) return true;
      tr.setNodeMarkup(pos, null, {...node.attrs, 'align': align});
      return false;
    });
    if (tr.docChanged) _view.dispatch(tr);
  }

  void _applyNamedStyle(String name) {
    _view.syncSelectionFromDom();
    final level = switch (name) {
      'Título 1' => 1,
      'Título 2' => 2,
      'Título 3' => 3,
      _ => null,
    };
    final command = level == null
        ? cmd.setBlockType(_schema.nodes['paragraph']!)
        : cmd.setBlockType(_schema.nodes['heading']!, {'level': level});
    command(_view.state, _view.dispatch);
  }

  // -- aba Layout -------------------------------------------------------------

  String _paperName() {
    final w = _setup.widthTwips < _setup.heightTwips
        ? _setup.widthTwips
        : _setup.heightTwips;
    final h = _setup.widthTwips < _setup.heightTwips
        ? _setup.heightTwips
        : _setup.widthTwips;
    if (w == 12240) return h == 20160 ? 'Ofício' : 'Carta';
    return 'A4';
  }

  void _setOrientation({required bool portrait}) {
    final w = _setup.widthTwips, h = _setup.heightTwips;
    final needSwap = portrait ? w > h : h > w;
    if (!needSwap) return;
    setPageSetup(_copySetup(width: h, height: w));
  }

  void _setPaper(String name) {
    final (w, h) = switch (name) {
      'Ofício' => (12240, 20160), // 8,5 × 14 pol (legal)
      'Carta' => (12240, 15840), // 8,5 × 11 pol
      _ => (11906, 16838), // A4
    };
    final portrait = _setup.heightTwips >= _setup.widthTwips;
    setPageSetup(_copySetup(width: portrait ? w : h, height: portrait ? h : w));
  }

  void _setMargins(String name) {
    final (vertical, horizontal) = switch (name) {
      'Estreita' => (720, 720), // 1,27 cm
      'Larga' => (1418, 2880), // 2,5 cm × 5,08 cm
      _ => (1418, 1418), // Normal: 2,5 cm
    };
    setPageSetup(PageSetupTwips(
      widthTwips: _setup.widthTwips,
      heightTwips: _setup.heightTwips,
      marginTopTwips: vertical,
      marginBottomTwips: vertical,
      marginLeftTwips: horizontal,
      marginRightTwips: horizontal,
      headerDistanceTwips: _setup.headerDistanceTwips,
      footerDistanceTwips: _setup.footerDistanceTwips,
    ));
  }

  PageSetupTwips _copySetup({required int width, required int height}) =>
      PageSetupTwips(
        widthTwips: width,
        heightTwips: height,
        marginTopTwips: _setup.marginTopTwips,
        marginRightTwips: _setup.marginRightTwips,
        marginBottomTwips: _setup.marginBottomTwips,
        marginLeftTwips: _setup.marginLeftTwips,
        headerDistanceTwips: _setup.headerDistanceTwips,
        footerDistanceTwips: _setup.footerDistanceTwips,
      );

  // -- réguas -----------------------------------------------------------------

  /// Régua horizontal no padrão Word: banda com a área útil branca e as
  /// margens cinza, tick pequeno a cada 0,25 cm, médio a 0,5 cm e número a
  /// cada centímetro — CONTADO A PARTIR DA MARGEM, como o Word numera.
  ///
  /// O alinhamento com a página é estrutural: o centro da régua tem a
  /// largura exata da página e usa a MESMA centralização do canvas (com a
  /// compensação da régua vertical), então nenhum JavaScript de medição é
  /// necessário e o zoom realinha sozinho.
  DomElement _buildRuler() {
    double px(int twips) => twips * _pxPerTwip;
    final setup = _setup;

    final track = _el('div', 'dq-office-ruler');
    final center = _el('div', 'dq-office-ruler-center');
    center.setAttribute('style', 'width:${px(setup.widthTwips)}px;');

    final band = _el('div', 'dq-office-ruler-band');
    final content = _el('div', 'dq-office-ruler-content');
    content.setAttribute(
        'style',
        'left:${px(setup.marginLeftTwips)}px;'
        'width:${px(setup.contentWidthTwips)}px;');
    band.append(content);
    center.append(band);

    const quarterCm = 142; // 0,25 cm em twips
    final totalQuarters = setup.widthTwips ~/ quarterCm;
    for (var q = 1; q < totalQuarters; q++) {
      final twips = q * quarterCm;
      final sinceMargin = twips - setup.marginLeftTwips;
      if (q % 4 == 0) {
        final cm = sinceMargin ~/ (quarterCm * 4);
        final insideContent = sinceMargin > 0 &&
            twips < setup.widthTwips - setup.marginRightTwips &&
            cm >= 1;
        if (insideContent) {
          final number = _el('span', 'dq-office-ruler-number');
          number.setAttribute('style', 'left:${px(twips)}px;');
          number.appendText('$cm');
          center.append(number);
          continue;
        }
      }
      final tick = _el(
          'span',
          q.isEven
              ? 'dq-office-ruler-tick dq-office-ruler-tick-half'
              : 'dq-office-ruler-tick');
      tick.setAttribute('style', 'left:${px(twips)}px;');
      center.append(tick);
    }

    track.append(center);
    return track;
  }

  /// Régua vertical com o mesmo desenho, à esquerda da página.
  DomElement _buildVerticalRuler() {
    double px(int twips) => twips * _pxPerTwip;
    final setup = _setup;

    final ruler = _el('div', 'dq-office-vruler');
    // Posição estrutural: encostada à esquerda da página centrada. O offset
    // é -(largura da página)/2 - largura da régua - respiro.
    ruler.setAttribute('style',
        'margin-left:${-(px(setup.widthTwips) / 2 + 30)}px;');
    final track = _el('div', 'dq-office-vruler-track');
    track.setAttribute('style', 'height:${px(setup.heightTwips)}px;');

    final content = _el('div', 'dq-office-vruler-content');
    content.setAttribute(
        'style',
        'top:${px(setup.marginTopTwips)}px;'
        'height:${px(setup.contentHeightTwips)}px;');
    track.append(content);

    const quarterCm = 142;
    final totalQuarters = setup.heightTwips ~/ quarterCm;
    for (var q = 1; q < totalQuarters; q++) {
      final twips = q * quarterCm;
      final sinceMargin = twips - setup.marginTopTwips;
      if (q % 4 == 0) {
        final cm = sinceMargin ~/ (quarterCm * 4);
        final insideContent = sinceMargin > 0 &&
            twips < setup.heightTwips - setup.marginBottomTwips &&
            cm >= 1;
        if (insideContent) {
          final number = _el('span', 'dq-office-vruler-number');
          number.setAttribute('style', 'top:${px(twips)}px;');
          number.appendText('$cm');
          track.append(number);
          continue;
        }
      }
      final tick = _el(
          'span',
          q.isEven
              ? 'dq-office-vruler-tick dq-office-vruler-tick-half'
              : 'dq-office-vruler-tick');
      tick.setAttribute('style', 'top:${px(twips)}px;');
      track.append(tick);
    }

    ruler.append(track);
    return ruler;
  }

  // -- barra de status --------------------------------------------------------

  DomElement _buildStatusBar() {
    final bar = _el('div', 'dq-office-statusbar');
    _statusPage = _el('span', 'dq-office-status-item');
    bar.append(_statusPage!);
    _statusWords = _el('span', 'dq-office-status-item');
    bar.append(_statusWords!);

    if (options.mode == OfficeWordMode.word) {
      bar.append(_el('span', 'dq-office-status-spacer'));
      bar.append(_select(
        'dq-office-zoom',
        const ['50%', '75%', '100%', '125%', '150%', '200%'],
        '${(options.zoom * 100).round()}%',
        (value) => setZoom(int.parse(value.replaceAll('%', '')) / 100),
      ));
    }
    return bar;
  }

  void _refreshStatus() {
    if (_disposed || _statusPage == null) return;
    final graph = _view.pageGraph;
    final current = graph.positionMap.pageOf(_view.state.selection.from) + 1;
    _setText(_statusPage!, 'Página $current de ${graph.pages.length}');
    _setText(_statusWords!, '${_view.state.doc.childCount} blocos');
    _refreshRibbonState();
  }

  /// Acende os botões conforme a seleção — o B fica ativo quando o cursor
  /// está em negrito, como no Word. Leitura pura do estado: a UI reflete o
  /// modelo, nunca o contrário.
  void _refreshRibbonState() {
    if (!_viewReady) return;
    if (_markButtons.isEmpty && _styleSelect == null) return;
    final state = _view.state;
    final selection = state.selection;

    bool activeFor(String name) {
      final type = _schema.marks[name];
      if (type == null) return false;
      if (selection.empty) {
        // No caret valem as storedMarks — o que a PRÓXIMA digitação usará.
        final marks = state.storedMarks ?? selection.fromRes.marks();
        return marks.any((mark) => mark.type == type);
      }
      return state.doc.rangeHasMark(selection.from, selection.to, type);
    }

    _markButtons.forEach((name, button) {
      if (activeFor(name)) {
        button.classes.add('dq-office-btn-active');
      } else {
        button.classes.remove('dq-office-btn-active');
      }
    });

    final style = _styleSelect;
    if (style != null) {
      final block = selection.fromRes.parent;
      final level = block.type.name == 'heading' ? block.attrs['level'] : null;
      style.value =
          level is int && level >= 1 && level <= 3 ? 'Título $level' : 'Normal';
    }
  }

  // -- infra ------------------------------------------------------------------

  static void _setText(DomElement element, String text) {
    while (element.firstChild != null) {
      element.firstChild!.remove();
    }
    element.appendText(text);
  }

  DomElement _el(String tag, String cssClass) {
    final element = adapter.document.createElement(tag);
    if (cssClass.isNotEmpty) {
      for (final name in cssClass.split(' ')) {
        element.classes.add(name);
      }
    }
    return element;
  }

  /// CSS do componente, injetado uma vez por host. Tudo `dq-office-*`.
  void _injectStyles() {
    final style = adapter.document.createElement('style');
    style.setAttribute('data-dq-office-ui', 'true');
    style.appendText(_css);
    host.append(style);
  }

  /// Visual no padrão do shell Word do docx_rendering: title bar #185abd,
  /// abas de 30px, ribbon de ~100px com grupos de duas linhas e rótulo
  /// embaixo, canvas #e9eef2, página com sombra grande, réguas de 22px.
  static const String _css = '''
.dq-office-app{display:flex;flex-direction:column;height:100%;min-height:400px;
  font:13px/1.4 "Segoe UI",system-ui,sans-serif;color:#242424;background:#f8f8f7;}
.dq-office-app *{box-sizing:border-box;}

/* title bar */
.dq-office-titlebar{flex:0 0 44px;display:flex;align-items:center;gap:10px;
  padding:0 14px;color:#fff;background:#185abd;}
.dq-office-brand{flex:0 0 auto;display:flex;align-items:center;gap:8px;
  font-size:15px;font-weight:700;letter-spacing:-.02em;}
.dq-office-brand-mark{width:22px;display:grid;gap:2px;transform:rotate(-2deg);}
.dq-office-brand-mark i{display:block;height:4px;border-radius:8px;background:currentColor;}
.dq-office-brand-mark i:nth-child(1){width:15px;margin-left:2px;}
.dq-office-brand-mark i:nth-child(2){width:20px;}
.dq-office-brand-mark i:nth-child(3){width:13px;margin-left:4px;}
.dq-office-doc-title{flex:1 1 auto;overflow:hidden;text-align:center;
  font-size:13px;font-weight:600;text-overflow:ellipsis;white-space:nowrap;}
.dq-office-titlebar-actions{flex:0 0 auto;min-width:80px;}

/* abas */
.dq-office-ribbon{background:#fff;border-bottom:1px solid #d6d6d6;}
.dq-office-ribbon-tabs{display:flex;align-items:stretch;height:30px;
  padding:0 7px;background:#f7f9fb;border-bottom:1px solid #d6d6d6;}
.dq-office-ribbon-tab{border:0;padding:0 12px;background:transparent;
  color:#202020;font:inherit;font-size:12px;cursor:pointer;}
.dq-office-ribbon-tab-active{color:#185abd;background:#fff;
  box-shadow:inset 0 -2px #185abd;font-weight:600;}
.dq-office-ribbon-tab-disabled{color:#9a9a9a;cursor:default;}

/* ribbon: grupos de duas linhas, rotulo embaixo (padrao Word) */
.dq-office-ribbon-content{display:flex;align-items:stretch;height:92px;
  padding:5px 7px 15px;overflow-x:auto;overflow-y:hidden;}
.dq-office-ribbon-group{position:relative;flex:0 0 auto;height:72px;
  padding:0 9px 14px;border-right:1px solid #e1e1e1;}
.dq-office-ribbon-group::after{content:attr(data-group-label);position:absolute;
  left:4px;right:4px;bottom:0;height:13px;overflow:hidden;color:#616161;
  text-align:center;white-space:nowrap;text-overflow:ellipsis;
  font-size:10px;line-height:13px;}
.dq-office-ribbon-rows{height:62px;display:grid;
  grid-template-rows:repeat(auto-fit,30px);align-content:center;gap:2px;}
.dq-office-ribbon-row{height:30px;display:flex;align-items:center;gap:2px;}
.dq-office-ribbon-compact{display:flex;align-items:center;gap:3px;
  min-height:40px;padding:4px 10px;}
.dq-office-ribbon-sep{width:1px;height:24px;margin:0 5px;background:#d6d6d6;}

/* controles */
.dq-office-btn{min-width:29px;height:29px;padding:0 6px;border:0;
  border-radius:2px;background:transparent;color:#252525;
  display:grid;place-items:center;font:inherit;font-size:14px;cursor:pointer;}
.dq-office-btn:hover{background:#e5f1fb;}
.dq-office-btn:active{background:#dce9f8;}
.dq-office-btn-active{color:#185abd;background:#dce9f8;}
.dq-office-b{font-weight:700;}
.dq-office-i{font-style:italic;}
.dq-office-u{text-decoration:underline;}
.dq-office-s{text-decoration:line-through;}
.dq-office-select{height:26px;border:1px solid #c8c8c8;border-radius:2px;
  background:#fff;font:inherit;font-size:12px;padding:0 4px;}
.dq-office-select:hover{background:#f5f9fd;}

/* regua horizontal: track full-width; o CENTRO tem a largura da pagina e a
   mesma centralizacao do canvas, entao regua e pagina alinham sem
   JavaScript, inclusive no zoom. */
.dq-office-ruler-slot{background:#e9eef2;}
.dq-office-ruler{height:22px;overflow:hidden;user-select:none;}
.dq-office-ruler-center{position:relative;height:22px;margin:0 auto;}
.dq-office-ruler-band{position:absolute;left:0;right:0;top:4px;bottom:5px;
  background:#d9dee3;}
.dq-office-ruler-content{position:absolute;top:0;bottom:0;background:#fff;}
.dq-office-ruler-number{position:absolute;top:11px;transform:translate(-50%,-50%);
  font:9px/1 Arial,sans-serif;color:#555;}
.dq-office-ruler-tick{position:absolute;top:11px;width:1px;height:3px;
  transform:translate(-50%,-50%);background:#555;}
.dq-office-ruler-tick-half{height:5px;}

/* canvas e pagina */
.dq-office-canvas{position:relative;flex:1;overflow:auto;
  padding:26px 0 46px;background:#e9eef2;}
.dq-office-pages{display:flex;flex-direction:column;align-items:center;gap:26px;}
.dq-office-page{background:#fff;
  box-shadow:0 12px 38px rgba(30,28,25,.10),0 1px 3px rgba(30,28,25,.08);}
.dq-office-page-placeholder{background:repeating-linear-gradient(45deg,
  #dfe4e8,#dfe4e8 10px,#d7dce0 10px,#d7dce0 20px);}
.dq-office-page-content:focus{outline:none;}
.dq-office-marker{color:#333;user-select:none;}
.dq-office-header,.dq-office-footer{color:#5a6b76;font-size:11px;user-select:none;}

/* regua vertical: encostada a esquerda da pagina centrada, mesmo desenho */
.dq-office-vruler-slot{position:absolute;top:26px;left:50%;height:0;
  overflow:visible;pointer-events:none;}
.dq-office-vruler{user-select:none;}
.dq-office-vruler-track{position:relative;width:22px;}
.dq-office-vruler-track::before{content:'';position:absolute;top:0;bottom:0;
  left:4px;right:5px;background:#d9dee3;}
.dq-office-vruler-content{position:absolute;left:4px;right:5px;background:#fff;}
.dq-office-vruler-number{position:absolute;left:11px;transform:translate(-50%,-50%);
  font:9px/1 Arial,sans-serif;color:#555;}
.dq-office-vruler-tick{position:absolute;left:11px;width:3px;height:1px;
  transform:translate(-50%,-50%);background:#555;}
.dq-office-vruler-tick-half{width:5px;}

/* barra de status */
.dq-office-statusbar{flex:0 0 auto;display:flex;align-items:center;gap:16px;
  background:#185abd;color:#fff;padding:3px 12px;font-size:12px;}
.dq-office-status-spacer{flex:1;}
.dq-office-statusbar .dq-office-select{height:22px;font-size:11.5px;
  color:#242424;}

/* flow: superficie continua, sem chrome de pagina */
.dq-office-app-flow .dq-office-pages{gap:0;}
.dq-office-app-flow .dq-office-page{box-shadow:none;}
''';
}
