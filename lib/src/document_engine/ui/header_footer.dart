/// F6 — o MODO cabeçalho/rodapé do Word: duplo clique na região, corpo
/// esmaecido e travado, região da página ativa editável, tracejado + etiqueta
/// no overlay e a aba contextual "Cabeçalho e Rodapé".
///
/// **A regra estrutural desta fase** (§6 do plano): a região NÃO ganha um
/// segundo laço de edição. A mesma [OfficeEditorView] é montada sobre outra
/// RAIZ — outro host, outro `EditorState`, outro [LayoutComposer], outro
/// [PageGraphDomRenderer]. Tudo que a view já resolve (beforeinput cancelado,
/// IME reconciliado, clipboard pelo modelo, undo/redo pelas extensões, mapa
/// de posições) vale de graça na região. Bifurcar a classe significaria
/// corrigir cada bug de edição duas vezes, e a segunda cópia sempre fica para
/// trás.
///
/// Três decisões que valem explicação:
///
/// * **A região vive no OVERLAY, não dentro da página.** Se o host da região
///   fosse filho de `.dq-office-pages`, todo `beforeinput`/`keydown` dela
///   subiria por bubbling até os listeners da view do CORPO, e as duas
///   tratariam o mesmo evento. Na camada de overlay (irmã do canvas) os dois
///   laços ficam realmente isolados; o preço é reposicionar no scroll, que é
///   o que os adornos de objeto e de tabela já fazem.
/// * **O corpo perde o `contenteditable`, não só a opacidade.** Esmaecer é
///   feedback; o que impede a digitação de cair no corpo é o atributo. Ele é
///   escrito pelo renderer, então a troca é uma REPROJEÇÃO, sem recompor.
/// * **O documento da região é gravado a cada tecla, mas a recomposição do
///   corpo acontece ao FECHAR.** Recompor 140 páginas por caractere digitado
///   no cabeçalho travaria a digitação; guardar só no fechamento perderia a
///   edição se a sessão morresse. Guardar sempre e recompor uma vez tem as
///   duas propriedades — o custo é o corpo mostrar o cabeçalho antigo nas
///   outras páginas enquanto o modo está aberto (a página ativa mostra o
///   novo, porque a superfície da região cobre a projeção antiga).
library;

import '../../platform/dom.dart';
import '../layout/dom_renderer.dart';
import '../layout/layout_composer.dart';
import '../layout/page_graph.dart';
import '../model/index.dart';
import '../state/index.dart';
import '../view/editor_view.dart';
import '../view/extension.dart';
import 'controller.dart';

/// Qual região vale para UMA página, e de onde ela veio.
///
/// A variante importa na hora de GRAVAR: uma edição no cabeçalho da primeira
/// página de um documento com `w:titlePg` não pode substituir o cabeçalho
/// padrão de todas as outras. [variant] é a chave em
/// `headerVariants`/`footerVariants`; `null` significa que o compositor caiu
/// no `header`/`footer` simples, e é lá que a edição deve ser gravada.
final class OfficeRegionRef {
  const OfficeRegionRef({
    required this.isHeader,
    required this.variant,
    required this.doc,
  });

  final bool isHeader;
  final String? variant;
  final PMNode? doc;

  /// Identidade de DESTINO (não de conteúdo): duas refs iguais gravam no
  /// mesmo lugar.
  bool sameTarget(OfficeRegionRef other) =>
      other.isHeader == isHeader && other.variant == variant;
}

/// A sessão de edição de cabeçalho/rodapé. Uma por editor; inativa por
/// padrão e sem custo nenhum enquanto ninguém entra no modo.
class OfficeHeaderFooterSession {
  OfficeHeaderFooterSession(this.controller, {required this.onChanged})
      : _kit = OfficeDomKit(controller.adapter);

  final OfficeWordController controller;

  /// Chamado quando o modo entra, troca de região/página ou sai — o
  /// orquestrador reage atualizando ribbon, réguas e status bar.
  final void Function() onChanged;

  final OfficeDomKit _kit;

  bool _active = false;
  bool _isHeader = true;
  int _pageIndex = 0;
  OfficeRegionRef? _ref;
  PMNode? _mountedDoc;

  /// Há edição gravada no modelo que o CORPO ainda não repaginou. É o que
  /// separa "guardar a cada tecla" de "repaginar uma vez ao fechar": sem esta
  /// marca, o fechamento compararia o documento com ele mesmo (já gravado) e
  /// nunca dispararia a repaginação.
  bool _pendingRecompose = false;

  OfficeEditorView? _regionView;
  DomElement? _surface;
  DomElement? _frame;
  DomElement? _label;

  bool get isActive => _active;
  bool get isHeader => _isHeader;
  int get pageIndex => _pageIndex;

  /// A view da região — a MESMA classe do corpo, outra raiz. Null fora do
  /// modo.
  OfficeEditorView? get regionView => _regionView;

  /// A ref cuja edição está em curso (útil para testes e para a aba).
  OfficeRegionRef? get regionRef => _ref;

  /// Rótulo da etiqueta, no vocabulário do Word.
  String get label {
    final base = _isHeader ? 'Cabeçalho' : 'Rodapé';
    return switch (_ref?.variant) {
      'first' => '$base da Primeira Página',
      'even' => '$base de Página Par',
      _ => base,
    };
  }

  // -- entrada e saída --------------------------------------------------------

  /// Roteia o duplo clique do canvas. Devolve true quando o modo mudou.
  ///
  /// Duplo clique NA região entra (ou troca de página/região); duplo clique
  /// em qualquer outro lugar do canvas, com o modo aberto, sai — é o gesto do
  /// Word, e o simétrico dele.
  bool handleDoubleClick(DomEvent event) {
    final target = event.target;
    final region = target == null ? null : _regionElementAt(target);
    if (region != null) {
      final header = region.classes.contains('$officeCssPrefix-header');
      enter(header: header, pageIndex: _pageIndexOfElement(region) ?? 0);
      return true;
    }
    if (!_active) return false;
    exit();
    return true;
  }

  /// Entra no modo (ou troca a região/página editada).
  void enter({required bool header, required int pageIndex}) {
    if (!controller.viewReady) return;
    final pages = controller.view.pageGraph.pages;
    if (pages.isEmpty) return;
    final page = pageIndex.clamp(0, pages.length - 1);
    if (_active && _isHeader == header && _pageIndex == page) return;

    _commit(recompose: false);
    _disposeRegionView();
    _isHeader = header;
    _pageIndex = page;
    // Suspender o corpo ANTES de montar a região: a reprojeção do corpo
    // reescreve a seleção nativa nele, e fazê-la depois roubaria o foco que
    // acabamos de dar à região.
    if (!_active) {
      _active = true;
      controller.setBodyEditingSuspended(true);
    }
    _mountRegion();
    reposition();
    onChanged();
  }

  /// Botão "Ir para Cabeçalho"/"Ir para Rodapé" da aba contextual.
  void goTo({required bool header}) {
    if (!_active) return;
    enter(header: header, pageIndex: _pageIndex);
  }

  /// Sai do modo: grava a edição, recompõe o corpo uma vez e devolve o
  /// `contenteditable` às páginas.
  void exit() {
    if (!_active) return;
    _active = false;
    // Devolver o `contenteditable` primeiro custa UMA reprojeção barata; na
    // ordem inversa, a repaginação do commit produziria páginas ainda
    // travadas e obrigaria a uma segunda projeção logo depois.
    controller.setBodyEditingSuspended(false);
    _commit(recompose: true);
    _disposeRegionView();
    _ref = null;
    _mountedDoc = null;
    onChanged();
  }

  /// Encerra a sessão SEM gravar — é o caminho de `openDocument`/`dispose`,
  /// onde a região que estava sendo editada deixou de existir.
  void dispose() {
    _active = false;
    _pendingRecompose = false;
    _ref = null;
    _mountedDoc = null;
    _disposeRegionView();
  }

  // -- geometria --------------------------------------------------------------

  /// Reacompanha a página: chamado a cada refresh e no scroll do canvas.
  ///
  /// Também detecta que a região VÁLIDA para a página mudou — é o que
  /// acontece quando "Primeira Página Diferente" ou "Pares/Ímpares" são
  /// ligados com o modo aberto: a página passa a projetar outra variante, e a
  /// superfície tem de passar a editar essa.
  void reposition() {
    if (!_active) return;
    final current = controller.regionForPage(_pageIndex, isHeader: _isHeader);
    final previous = _ref;
    if (previous != null && !current.sameTarget(previous)) {
      _commit(recompose: false);
      _disposeRegionView();
      _mountRegion();
    }
    final surface = _surface;
    final frame = _frame;
    if (surface == null || frame == null) return;

    final setup = _setupOfPage();
    final px = controller.pxPerTwip;
    final band = _bandTwips(setup);
    final pageElement = _pageElementFor(_pageIndex);
    // Com virtualização, rolar para longe troca a página editada por um
    // placeholder: sem elemento não há geometria, e posicionar em (0,0) jogaria
    // a superfície para o canto do editor. Some até a página voltar.
    final offscreen = pageElement == null;
    for (final element in [surface, frame]) {
      if (offscreen) {
        element.classes.add('dq-office-hf-offscreen');
      } else {
        element.classes.remove('dq-office-hf-offscreen');
      }
    }
    final bounds = pageElement == null
        ? null
        : controller.adapter.getElementBounds(
            pageElement,
            relativeTo: controller.overlay.layer,
          );
    final left = _numOf(bounds?['left']);
    final top = _numOf(bounds?['top']);
    final bandTop = _isHeader
        ? setup.headerDistanceTwips * px
        : (setup.heightTwips - setup.footerDistanceTwips - band) * px;
    final box = 'left:${left.toStringAsFixed(1)}px;'
        'top:${(top + bandTop).toStringAsFixed(1)}px;'
        'width:${(setup.widthTwips * px).toStringAsFixed(1)}px;'
        'height:${(band * px).toStringAsFixed(1)}px;';
    surface.setAttribute('style', box);
    frame.setAttribute('style', box);
    if (_label != null) _kit.setText(_label!, label);
  }

  /// A altura da FAIXA da região.
  ///
  /// No Word a área do cabeçalho vai da distância até a borda até a margem
  /// superior, mas cresce quando o conteúdo é mais alto — o cabeçalho empurra
  /// o corpo, e é isso que o compositor já faz com `_headerBodyInsetTwips`. O
  /// piso da faixa é a área natural para que um cabeçalho VAZIO ainda tenha
  /// onde ser clicado.
  int _bandTwips(PageSetupTwips setup) {
    final natural = _isHeader
        ? setup.marginTopTwips - setup.headerDistanceTwips
        : setup.marginBottomTwips - setup.footerDistanceTwips;
    final content = _regionContentHeightTwips();
    final floor = natural > _minimumBandTwips ? natural : _minimumBandTwips;
    return content > floor ? content : floor;
  }

  /// Piso absoluto da faixa (≈0,7 cm): uma seção com margem menor que a
  /// distância do cabeçalho produziria faixa negativa e nada clicável.
  static const int _minimumBandTwips = 400;

  /// Altura do conteúdo COMPOSTO da região, lida do grafo da própria view —
  /// nunca de um cálculo paralelo em twips, que divergiria do desenho.
  int _regionContentHeightTwips() {
    final graph = _regionView?.pageGraph;
    if (graph == null || graph.pages.isEmpty) return 0;
    var bottom = 0;
    for (final fragment in graph.pages.first.fragments) {
      final end = fragment.yTwips + fragment.heightTwips;
      if (end > bottom) bottom = end;
    }
    return bottom;
  }

  PageSetupTwips _setupOfPage() {
    final pages = controller.view.pageGraph.pages;
    if (_pageIndex >= 0 && _pageIndex < pages.length) {
      return pages[_pageIndex].setup;
    }
    return controller.pageSetup;
  }

  // -- montagem da região -----------------------------------------------------

  void _mountRegion() {
    final ref = controller.regionForPage(_pageIndex, isHeader: _isHeader);
    _ref = ref;
    final doc = ref.doc ?? _emptyRegionDoc();
    _mountedDoc = doc;

    final surface = _kit.el('div', 'dq-office-hf-surface');
    surface.setAttribute(
        'data-dq-office-region', _isHeader ? 'header' : 'footer');
    surface.setAttribute('data-dq-office-region-page', '$_pageIndex');
    if (ref.variant != null) {
      surface.setAttribute('data-dq-office-region-variant', ref.variant!);
    }
    controller.overlay.layer.append(surface);
    _surface = surface;

    final frame = _kit.el('div',
        'dq-office-hf-frame dq-office-hf-frame-${_isHeader ? 'header' : 'footer'}');
    final labelElement = _kit.el('span', 'dq-office-hf-label');
    labelElement.appendText(label);
    frame.append(labelElement);
    controller.overlay.layer.append(frame);
    _frame = frame;
    _label = labelElement;

    final extensions = officeDefaultExtensions(controller.schema);
    _regionView = OfficeEditorView(
      host: surface,
      state: EditorState.create(EditorStateConfig(
        doc: doc,
        plugins: OfficeExtensionSet(extensions).plugins,
      )),
      adapter: controller.adapter,
      extensions: extensions,
      composer: LayoutComposer(
        setup: _regionSetup(),
        fonts: controller.options.fonts,
      ),
      renderer: PageGraphDomRenderer(
        document: controller.adapter.document,
        editable: true,
        pxPerPt: 96 / 72 * controller.zoom,
      ),
      // Os hints `lastRenderedPageBreak` descrevem o CORPO gravado pelo Word;
      // não existem para uma região e honrá-los aqui não faria sentido.
      honorRenderedPageBreaks: false,
      onStateChange: _handleRegionChange,
    );

    final content = surface.querySelector('.$officeCssPrefix-page-content');
    if (content != null) controller.adapter.focus(content);
  }

  /// A geometria em que a região é composta.
  ///
  /// Largura e margens laterais são as da PÁGINA — é o que faz o texto do
  /// cabeçalho quebrar exatamente onde quebra na projeção do corpo. A altura
  /// é deliberadamente generosa e as margens verticais são zero: a região é
  /// uma faixa empilhada a partir do topo do próprio box, e paginar um
  /// cabeçalho não significaria nada. A faixa VISÍVEL é recortada pela
  /// superfície (`overflow:hidden`), não pela composição.
  PageSetupTwips _regionSetup() {
    final setup = _setupOfPage();
    return PageSetupTwips(
      widthTwips: setup.widthTwips,
      heightTwips: _regionCanvasHeightTwips,
      marginTopTwips: 0,
      marginRightTwips: setup.marginRightTwips,
      marginBottomTwips: 0,
      marginLeftTwips: setup.marginLeftTwips,
    );
  }

  /// 22 polegadas: alto o bastante para que nenhuma região real pagine.
  static const int _regionCanvasHeightTwips = 31680;

  PMNode _emptyRegionDoc() => controller.schema.node(
        'doc',
        null,
        Fragment.from([
          controller.schema.node('paragraph', null, Fragment.empty),
        ]),
      );

  /// Cada transação da região grava o documento no orquestrador (sem
  /// recompor) e reajusta a faixa, que pode ter mudado de altura. O
  /// [onChanged] mantém a ribbon acesa pela seleção DA REGIÃO.
  void _handleRegionChange(EditorState state) {
    _commit(recompose: false);
    onChanged();
  }

  /// Grava o documento da região no orquestrador quando ele MUDOU.
  ///
  /// A comparação é por identidade contra o nó montado: entrar no modo, olhar
  /// e sair não pode marcar o documento como sujo nem criar um cabeçalho
  /// vazio onde não havia nenhum.
  void _commit({required bool recompose}) {
    final ref = _ref;
    final view = _regionView;
    if (ref == null || view == null) return;
    final doc = view.state.doc;
    if (!identical(doc, _mountedDoc)) {
      _mountedDoc = doc;
      _pendingRecompose = true;
    }
    if (!_pendingRecompose) return;
    if (!recompose) {
      // O modelo é gravado JÁ: a edição não pode depender de a sessão ser
      // fechada corretamente para sobreviver.
      controller.setRegionDocument(ref, doc);
      return;
    }
    _pendingRecompose = false;
    controller.setRegionDocument(ref, doc, recompose: true);
  }

  void _disposeRegionView() {
    _regionView?.dispose();
    _regionView = null;
    _surface?.remove();
    _surface = null;
    _frame?.remove();
    _frame = null;
    _label = null;
  }

  // -- hit-testing ------------------------------------------------------------

  /// A região projetada que contém [node], ou null.
  DomElement? _regionElementAt(DomNode node) {
    final host = controller.view.host;
    DomNode? current = node;
    while (current != null) {
      if (current is DomElement &&
          (current.classes.contains('$officeCssPrefix-header') ||
              current.classes.contains('$officeCssPrefix-footer'))) {
        return current;
      }
      if (current == host) break;
      current = current.parentNode;
    }
    return null;
  }

  int? _pageIndexOfElement(DomElement element) {
    DomNode? current = element;
    while (current != null) {
      if (current is DomElement) {
        final page = current.getAttribute('data-page');
        if (page != null) return int.tryParse(page);
      }
      current = current.parentNode;
    }
    return null;
  }

  /// O elemento da página [index]. O fake DOM só entende seletores simples,
  /// então a filtragem por `data-page` é feita aqui, e não no seletor.
  DomElement? _pageElementFor(int index) {
    for (final element
        in controller.view.host.querySelectorAll('.$officeCssPrefix-page')) {
      if (element.getAttribute('data-page') == '$index') return element;
    }
    return null;
  }

  static double _numOf(Object? value) => value is num ? value.toDouble() : 0.0;
}
