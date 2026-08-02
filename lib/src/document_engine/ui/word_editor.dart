/// OfficeWordEditor — o editor Word COMPLETO como componente da biblioteca.
///
/// A UI pertence à biblioteca, não à aplicação. O consumidor faz UMA
/// chamada e recebe a experiência inteira — ribbon, régua, páginas, barra
/// de status, zoom:
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
/// Nenhum HTML, CSS ou toolbar do lado da aplicação: o CSS é injetado pelo
/// próprio componente, escopado em `dq-office-*`, e não toca `.ql-editor`
/// nem os temas do Quill simples — os dois podem coexistir na página.
///
/// Três modos, como produto exige:
///
/// * [OfficeWordMode.view] — somente leitura, paginado, sem chrome de
///   edição;
/// * [OfficeWordMode.flow] — edição contínua sem paginação visível
///   (as quebras de página existem no grafo, mas a superfície é um fluxo
///   único, como o modo rascunho do Word);
/// * [OfficeWordMode.word] — a experiência completa: ribbon com grupos,
///   régua horizontal com margens, páginas com sombra, barra de status com
///   página corrente e zoom.
///
/// A ribbon usa EXATAMENTE os mesmos comandos dos atalhos de teclado
/// (`runCommand`/transações) — a UI não tem um caminho próprio para mudar o
/// documento. O zoom muda apenas a escala twips→px da PROJEÇÃO
/// (`pxPerPt`): o grafo, o mapa de posições e o PDF não mudam com ele.
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

/// Configuração do componente. Tudo opcional além do que o construtor pede.
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

  /// Botões que refletem o estado da seleção (B aceso em negrito…).
  final Map<String, DomElement> _markButtons = {};
  DomElement? _styleSelect;
  double _zoom = 1.0;
  bool _disposed = false;

  /// O laço de edição por baixo do chrome — exposto para integrações.
  OfficeEditorView get view => _view;
  PageGraph get pageGraph => _view.pageGraph;
  EditorState get state => _view.state;
  double get zoom => _zoom;

  bool get _editable => options.mode != OfficeWordMode.view;

  // -- montagem ---------------------------------------------------------------

  void _build(PMNode document) {
    _zoom = options.zoom;
    host.classes.add('dq-office-app');
    if (options.mode == OfficeWordMode.flow) {
      host.classes.add('dq-office-app-flow');
    }

    _injectStyles();
    if (options.mode == OfficeWordMode.word) {
      host.append(_buildRibbon(full: true));
      host.append(_buildRuler());
    } else if (options.mode == OfficeWordMode.flow) {
      host.append(_buildRibbon(full: false));
    }

    _canvas = _el('div', 'dq-office-canvas');
    if (options.mode == OfficeWordMode.word) {
      // A régua vertical é STICKY dentro do canvas: fica visível enquanto o
      // documento rola, mostrando a escala da página como no Word.
      _canvas.append(_buildVerticalRuler());
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
    _refreshStatus();
  }

  LayoutComposer _composer() => LayoutComposer(
        setup: options.setup,
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
    final state = _view.state;
    _view.dispose();
    _mountView(state);
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _view.dispose();
    while (host.firstChild != null) {
      host.firstChild!.remove();
    }
    host.classes.remove('dq-office-app');
  }

  // -- ribbon -----------------------------------------------------------------

  DomElement _buildRibbon({required bool full}) {
    final ribbon = _el('div', 'dq-office-ribbon');

    if (full) {
      final tabs = _el('div', 'dq-office-ribbon-tabs');
      for (final (label, active) in [
        ('Arquivo', false),
        ('Página Inicial', true),
        ('Inserir', false),
        ('Layout', false),
      ]) {
        final tab = _el('span',
            'dq-office-ribbon-tab${active ? ' dq-office-ribbon-tab-active' : ''}');
        tab.appendText(label);
        tabs.append(tab);
      }
      ribbon.append(tabs);
    }

    final content = _el('div', 'dq-office-ribbon-content');

    content.append(_group('Desfazer', [
      _button('↶', 'Desfazer (Ctrl+Z)', () => _view.runCommand('undo')),
      _button('↷', 'Refazer (Ctrl+Y)', () => _view.runCommand('redo')),
    ]));

    final fontControls = <DomElement>[
      if (full)
        _select(
          'dq-office-font-family',
          const ['Arial', 'Calibri', 'Times New Roman', 'Courier New'],
          'Arial',
          (value) => _addMarkOverSelection('font', {'value': value}),
        ),
      if (full)
        _select(
          'dq-office-font-size',
          const ['8', '9', '10', '11', '12', '14', '16', '18', '24', '36'],
          '12',
          (value) => _addMarkOverSelection('size', {'value': '${value}pt'}),
        ),
      _markButton('bold', 'B', 'Negrito (Ctrl+B)', 'dq-office-b'),
      _markButton('italic', 'I', 'Itálico (Ctrl+I)', 'dq-office-i'),
      _markButton('underline', 'U', 'Sublinhado (Ctrl+U)', 'dq-office-u'),
      _markButton('strike', 'S', 'Tachado', 'dq-office-s'),
    ];
    content.append(_group('Fonte', fontControls));

    if (full) {
      content.append(_group('Parágrafo', [
        _button('⯇', 'Alinhar à esquerda', () => _setAlign('left')),
        _button('☰', 'Centralizar', () => _setAlign('center')),
        _button('⯈', 'Alinhar à direita', () => _setAlign('right')),
        _button('▤', 'Justificar', () => _setAlign('justify')),
      ]));

      _styleSelect = _select(
        'dq-office-style',
        const ['Normal', 'Título 1', 'Título 2', 'Título 3'],
        'Normal',
        _applyNamedStyle,
      );
      content.append(_group('Estilos', [_styleSelect!]));
    }

    ribbon.append(content);
    return ribbon;
  }

  DomElement _group(String label, List<DomElement> controls) {
    final group = _el('div', 'dq-office-ribbon-group');
    final row = _el('div', 'dq-office-ribbon-row');
    for (final control in controls) {
      row.append(control);
    }
    group.append(row);
    final caption = _el('div', 'dq-office-ribbon-label');
    caption.appendText(label);
    group.append(caption);
    return group;
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

  /// Aplica uma marca com atributos sobre a seleção nativa (fonte/tamanho).
  void _addMarkOverSelection(String markName, Map<String, dynamic> attrs) {
    final type = _schema.marks[markName];
    if (type == null) return;
    _view.syncSelectionFromDom();
    final selection = _view.state.selection;
    if (selection.empty) return;
    _view.dispatch(
        _view.state.tr..addMark(selection.from, selection.to, type.create(attrs)));
  }

  /// Alinha os BLOCOS cobertos pela seleção.
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

  // -- régua ------------------------------------------------------------------

  /// Régua horizontal com a área útil branca e as margens sombreadas, como
  /// no Word. Estática no v1 — arrastar recuos é uma fase posterior.
  DomElement _buildRuler() {
    final setup = options.setup;
    final pxPerTwip = 96 / 72 / 20 * _zoom;
    double px(int twips) => twips * pxPerTwip;

    final ruler = _el('div', 'dq-office-ruler');
    final track = _el('div', 'dq-office-ruler-track');
    track.setAttribute('style', 'width:${px(setup.widthTwips)}px;');

    final content = _el('div', 'dq-office-ruler-content');
    content.setAttribute(
        'style',
        'left:${px(setup.marginLeftTwips)}px;'
        'width:${px(setup.contentWidthTwips)}px;');
    track.append(content);

    // Números por centímetro DENTRO da área útil, contados a partir da
    // margem — é a numeração que o Word mostra.
    const twipsPerCm = 567;
    final usableCm = setup.contentWidthTwips ~/ twipsPerCm;
    for (var cm = 1; cm <= usableCm; cm++) {
      final mark = _el('span', 'dq-office-ruler-number');
      mark.setAttribute('style',
          'left:${px(setup.marginLeftTwips + cm * twipsPerCm)}px;');
      mark.appendText('$cm');
      track.append(mark);
      final tick = _el('span', 'dq-office-ruler-tick');
      tick.setAttribute('style',
          'left:${px(setup.marginLeftTwips + cm * twipsPerCm - twipsPerCm ~/ 2)}px;');
      track.append(tick);
    }

    ruler.append(track);
    return ruler;
  }

  DomElement _buildVerticalRuler() {
    final setup = options.setup;
    final pxPerTwip = 96 / 72 / 20 * _zoom;
    double px(int twips) => twips * pxPerTwip;

    final ruler = _el('div', 'dq-office-vruler');
    final track = _el('div', 'dq-office-vruler-track');
    track.setAttribute('style', 'height:${px(setup.heightTwips)}px;');

    final content = _el('div', 'dq-office-vruler-content');
    content.setAttribute(
        'style',
        'top:${px(setup.marginTopTwips)}px;'
        'height:${px(setup.contentHeightTwips)}px;');
    track.append(content);

    const twipsPerCm = 567;
    final usableCm = setup.contentHeightTwips ~/ twipsPerCm;
    for (var cm = 1; cm <= usableCm; cm++) {
      final mark = _el('span', 'dq-office-vruler-number');
      mark.setAttribute(
          'style', 'top:${px(setup.marginTopTwips + cm * twipsPerCm)}px;');
      mark.appendText('$cm');
      track.append(mark);
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
      final spacer = _el('span', 'dq-office-status-spacer');
      bar.append(spacer);
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
    final current =
        graph.positionMap.pageOf(_view.state.selection.from) + 1;
    _setText(_statusPage!, 'Página $current de ${graph.pages.length}');
    _setText(_statusWords!, '${_view.state.doc.childCount} blocos');
    _refreshRibbonState();
  }

  /// Acende os botões conforme a seleção — o B fica ativo quando o cursor
  /// está em negrito, como no Word. É leitura pura do estado: a UI reflete
  /// o modelo, nunca o contrário.
  void _refreshRibbonState() {
    if (_markButtons.isEmpty) return;
    final state = _view.state;
    final selection = state.selection;

    bool activeFor(String name) {
      final type = _schema.marks[name];
      if (type == null) return false;
      if (selection.empty) {
        // No caret valem as storedMarks (o que a PRÓXIMA digitação usará),
        // senão as marcas da posição.
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
      final level =
          block.type.name == 'heading' ? block.attrs['level'] : null;
      style.value = level is int && level >= 1 && level <= 3
          ? 'Título $level'
          : 'Normal';
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

  /// CSS do componente, injetado uma vez por host. Tudo `dq-office-*`:
  /// nenhuma regra alcança `.ql-editor`, temas ou a aplicação.
  void _injectStyles() {
    final style = adapter.document.createElement('style');
    style.setAttribute('data-dq-office-ui', 'true');
    style.appendText(_css);
    host.append(style);
  }

  static const String _css = '''
.dq-office-app{display:flex;flex-direction:column;height:100%;min-height:400px;
  font:13px/1.4 "Segoe UI",system-ui,sans-serif;color:#242424;background:#f5f5f5;}
.dq-office-ribbon{background:#fff;border-bottom:1px solid #d1d1d1;}
.dq-office-ribbon-tabs{display:flex;gap:2px;padding:4px 8px 0;background:#f3f2f1;}
.dq-office-ribbon-tab{padding:6px 14px;border-radius:4px 4px 0 0;color:#444;
  cursor:default;font-size:12.5px;}
.dq-office-ribbon-tab-active{background:#fff;color:#185abd;font-weight:600;
  border:1px solid #d1d1d1;border-bottom-color:#fff;}
.dq-office-ribbon-content{display:flex;align-items:stretch;padding:6px 8px;gap:4px;}
.dq-office-ribbon-group{display:flex;flex-direction:column;align-items:center;
  padding:0 10px;border-right:1px solid #e1e1e1;}
.dq-office-ribbon-group:last-child{border-right:none;}
.dq-office-ribbon-row{display:flex;gap:3px;align-items:center;flex:1;}
.dq-office-ribbon-label{font-size:10.5px;color:#777;margin-top:4px;}
.dq-office-btn{min-width:30px;height:28px;border:1px solid transparent;
  background:transparent;border-radius:3px;cursor:pointer;font:inherit;font-size:14px;}
.dq-office-btn:hover{background:#f0f6ff;border-color:#c7dcf8;}
.dq-office-btn:active{background:#dbe9fb;}
.dq-office-btn-active{background:#cfe4ff;border-color:#9dc3f0;}
.dq-office-b{font-weight:700;}
.dq-office-i{font-style:italic;}
.dq-office-u{text-decoration:underline;}
.dq-office-s{text-decoration:line-through;}
.dq-office-select{height:28px;border:1px solid #c8c8c8;border-radius:3px;
  background:#fff;font:inherit;padding:0 4px;}
.dq-office-ruler{background:#fff;border-bottom:1px solid #d1d1d1;
  display:flex;justify-content:center;padding:2px 0;}
.dq-office-ruler-track{position:relative;height:22px;background:#e8e6e4;
  border-radius:2px;overflow:hidden;}
.dq-office-ruler-content{position:absolute;top:0;bottom:0;background:#fff;}
.dq-office-ruler-number{position:absolute;top:3px;transform:translateX(-50%);
  font-size:9.5px;color:#666;user-select:none;}
.dq-office-ruler-tick{position:absolute;top:9px;width:1px;height:5px;background:#999;}
.dq-office-canvas{flex:1;overflow:auto;padding:20px 0 40px;
  display:flex;align-items:flex-start;justify-content:center;gap:8px;}
.dq-office-vruler{position:sticky;top:0;flex:0 0 auto;}
.dq-office-vruler-track{position:relative;width:22px;background:#e8e6e4;
  border-radius:2px;overflow:hidden;}
.dq-office-vruler-content{position:absolute;left:0;right:0;background:#fff;}
.dq-office-vruler-number{position:absolute;left:0;right:0;text-align:center;
  transform:translateY(-50%);font-size:9px;color:#666;user-select:none;}
.dq-office-pages{display:flex;flex-direction:column;align-items:center;gap:18px;
  flex:0 0 auto;}
.dq-office-page{background:#fff;box-shadow:0 2px 6px rgba(0,0,0,.25);}
.dq-office-page-placeholder{background:repeating-linear-gradient(45deg,
  #e6e4e2,#e6e4e2 10px,#dedcda 10px,#dedcda 20px);}
.dq-office-page-content:focus{outline:none;}
.dq-office-marker{color:#333;user-select:none;}
.dq-office-header,.dq-office-footer{color:#5a6b76;font-size:11px;user-select:none;}
.dq-office-statusbar{display:flex;align-items:center;gap:16px;
  background:#185abd;color:#fff;padding:3px 12px;font-size:12px;}
.dq-office-status-spacer{flex:1;}
.dq-office-statusbar .dq-office-select{height:22px;font-size:11.5px;}
/* Modo flow: superfície contínua — as páginas existem no grafo, mas a
   projeção as cola numa coluna sem chrome. */
.dq-office-app-flow .dq-office-pages{gap:0;}
.dq-office-app-flow .dq-office-page{box-shadow:none;}
''';
}
