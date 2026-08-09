/// OfficeEditorView — o laço de edição do modo avançado (Fase 2).
///
/// Fecha o ciclo que as peças anteriores prepararam:
///
/// ```text
/// beforeinput → posição (PositionMap) → OfficeTransaction → novo estado
///             → PageGraph recomposto → projeção DOM → seleção restaurada
/// ```
///
/// A decisão estrutural: **o browser nunca muta a projeção**. Todo
/// `beforeinput` é cancelado e a mudança entra pelo modelo, que reprojeta.
/// Isso vale inclusive para os `inputType` que ainda não sabemos tratar —
/// deixar o browser editar sozinho um DOM cuja verdade mora em outro lugar
/// corrompe o mapeamento em silêncio, e o bug aparece três interações
/// depois. Cancelar e não fazer nada é uma perda visível; não cancelar é
/// uma corrupção invisível.
///
/// A composição IME é a exceção conhecida: `beforeinput` durante composição
/// não é cancelável de forma confiável em todos os browsers, então ela é
/// deixada passar e tratada pelo caminho de reconciliação — que ainda não
/// existe. Enquanto não existir, a view IGNORA a composição em vez de
/// fingir suporte (o gate de IME é explícito no plano).
library;

import 'dart:async' show unawaited;

import '../../platform/dom.dart';
import '../diagnostics/open_document_timing.dart';
import '../layout/dom_position_map.dart';
import '../layout/dom_renderer.dart';
import '../layout/layout_composer.dart';
import '../layout/page_graph.dart';
import '../model/index.dart';
import '../state/index.dart';
import 'clipboard.dart';
import 'extension.dart';
import 'reconciler.dart';

/// Política de virtualização: quantas páginas montar em volta da visível.
///
/// A ordem do §7.9 é deliberada — posição modelo↔DOM, índice de página e
/// placeholders exatos vêm ANTES da janela. Virtualizar sem eles produz
/// bugs de caret difíceis de reproduzir, porque a página onde o cursor
/// está pode simplesmente não existir no DOM.
class OfficeVirtualization {
  const OfficeVirtualization({this.radius = 3});

  /// Páginas montadas para cada lado da visível. O padrão ±3 é o do plano.
  final int radius;
}

/// Paginação progressiva estilo Word: a abertura compõe só as primeiras
/// páginas ([initialPages]), projeta imediatamente e continua paginando em
/// fatias de [pagesPerSlice] no event loop — a contagem de páginas e a
/// barra de rolagem crescem como no Word. As fatias param em fronteiras
/// LIMPAS de bloco, então um bloco que atravessa páginas (uma tabela longa)
/// alonga a fatia em vez de corrompê-la.
class OfficeProgressivePagination {
  const OfficeProgressivePagination({
    this.initialPages = 12,
    this.pagesPerSlice = 24,
  });

  final int initialPages;
  final int pagesPerSlice;
}

/// Um `inputType` que a view reconhece e roteia pelo modelo.
enum OfficeInputAction {
  insertText,
  insertParagraph,
  insertLineBreak,
  deleteBackward,
  deleteWordBackward,
  deleteSoftLineBackward,
  deleteForward,
}

/// O laço de edição sobre uma projeção paginada.
class OfficeEditorView {
  OfficeEditorView({
    required this.host,
    required EditorState state,
    required DomAdapter adapter,
    LayoutComposer? composer,
    PageGraphDomRenderer? renderer,
    List<OfficeExtension> extensions = const [],
    this.virtualization,
    this.progressive,
    DomElement? scrollContainer,
    bool honorRenderedPageBreaks = true,
    this.onStateChange,
    this.onVisiblePageChange,
    this.onPaginationProgress,
  })  : _state = state,
        _scrollContainer = scrollContainer,
        _adapter = adapter,
        _renderedPageBreakHintsValid = honorRenderedPageBreaks,
        _composer = composer ?? LayoutComposer(),
        _extensions = OfficeExtensionSet(extensions),
        _renderer = renderer ??
            PageGraphDomRenderer(document: adapter.document, editable: true) {
    _beforeInput = _handleBeforeInput;
    _keyDown = _handleKeyDown;
    _pointerDown = _handlePointerDown;
    _copy = _handleCopy;
    _cut = _handleCut;
    _paste = _handlePaste;
    _compositionStart = _handleCompositionStart;
    _compositionEnd = _handleCompositionEnd;
    host.addEventListener('beforeinput', _beforeInput);
    host.addEventListener('keydown', _keyDown);
    host.addEventListener('pointerdown', _pointerDown);
    host.addEventListener('copy', _copy);
    host.addEventListener('cut', _cut);
    host.addEventListener('paste', _paste);
    host.addEventListener('compositionstart', _compositionStart);
    host.addEventListener('compositionend', _compositionEnd);
    if (virtualization != null || onVisiblePageChange != null) {
      _scroll = _handleScroll;
      (_scrollContainer ?? host).addEventListener('scroll', _scroll!);
    }
    // Mover o caret não gera transação — é o selectionchange do DOCUMENTO
    // que mantém o modelo (e a UI contextual: realce da ribbon, marcadores
    // da régua) em dia com onde o usuário está. O guard de host em
    // readNativeSelection ignora seleções fora deste editor.
    _selectionChange = (_) {
      if (_disposed || _composing) return;
      if (syncSelectionFromDom()) onStateChange?.call(_state);
    };
    _adapter.document.addEventListener('selectionchange', _selectionChange!);
    measureOpenDocumentPhase<void>('compose', _compose);
    // Resolve the current page against the existing projection before
    // replacing it. Reading geometry immediately after render forces a full
    // browser layout; the scroll handler keeps this cached value current.
    _visiblePage = measureOpenDocumentPhase<int>('geometry', _visiblePageIndex);
    measureOpenDocumentPhase<void>('project', () => _project(_visiblePage));
  }

  /// Monta um editor a partir do DOCUMENTO, instalando os plugins que as
  /// extensões pedem.
  ///
  /// É a forma correta quando há extensões: um plugin (o histórico, por
  /// exemplo) precisa existir no `EditorState` desde a criação — instalar
  /// depois deixaria o undo sem as transações já aplicadas.
  factory OfficeEditorView.withExtensions({
    required DomElement host,
    required PMNode doc,
    required DomAdapter adapter,
    required List<OfficeExtension> extensions,
    LayoutComposer? composer,
    PageGraphDomRenderer? renderer,
    OfficeVirtualization? virtualization,
    OfficeProgressivePagination? progressive,
    DomElement? scrollContainer,
    bool honorRenderedPageBreaks = true,
    void Function(EditorState state)? onStateChange,
    void Function(int pageIndex)? onVisiblePageChange,
    void Function(int pages, bool complete)? onPaginationProgress,
  }) {
    final set = OfficeExtensionSet(extensions);
    return OfficeEditorView(
      host: host,
      state:
          EditorState.create(EditorStateConfig(doc: doc, plugins: set.plugins)),
      adapter: adapter,
      composer: composer,
      renderer: renderer,
      extensions: extensions,
      virtualization: virtualization,
      progressive: progressive,
      scrollContainer: scrollContainer,
      honorRenderedPageBreaks: honorRenderedPageBreaks,
      onStateChange: onStateChange,
      onVisiblePageChange: onVisiblePageChange,
      onPaginationProgress: onPaginationProgress,
    );
  }

  final DomElement host;
  final DomAdapter _adapter;
  final LayoutComposer _composer;
  final PageGraphDomRenderer _renderer;
  final OfficeExtensionSet _extensions;

  /// Null monta o documento inteiro (o padrão, e o certo para documentos
  /// pequenos: virtualizar tem custo próprio).
  final OfficeVirtualization? virtualization;

  /// Paginação progressiva na abertura. Null compõe tudo antes de projetar.
  final OfficeProgressivePagination? progressive;

  /// Progresso da paginação progressiva: contagem corrente de páginas e se
  /// o documento terminou de paginar. A barra de status vive disto.
  final void Function(int pages, bool complete)? onPaginationProgress;

  final DomElement? _scrollContainer;
  final OfficeDomPositionMap _positions = const OfficeDomPositionMap();

  /// Notificação de mudança de estado (a aplicação persiste a partir daqui).
  final void Function(EditorState state)? onStateChange;

  /// Notifica somente quando o topo do viewport cruza uma página. Isso
  /// alimenta a barra de status sem atualizá-la a cada pixel de scroll.
  final void Function(int pageIndex)? onVisiblePageChange;

  EditorState _state;
  late PageGraph _pageGraph;
  bool _renderedPageBreakHintsValid;
  late DomEventListener _beforeInput;
  late DomEventListener _keyDown;
  late DomEventListener _pointerDown;
  late DomEventListener _copy;
  late DomEventListener _cut;
  late DomEventListener _paste;
  late DomEventListener _compositionStart;
  late DomEventListener _compositionEnd;
  final OfficeClipboard _clipboard = const OfficeClipboard();
  final OfficeDomReconciler _reconciler = const OfficeDomReconciler();
  DomEventListener? _scroll;
  DomEventListener? _selectionChange;
  bool _disposed = false;
  bool _composing = false;
  int _visiblePage = 0;
  PageWindow? _window;

  /// Geração das fatias de paginação em curso: qualquer troca de grafo fora
  /// do laço progressivo (edição, dispose) o cancela incrementando isto.
  int _paginationGeneration = 0;

  EditorState get state => _state;
  PageGraph get pageGraph => _pageGraph;
  bool get renderedPageBreakHintsValid => _renderedPageBreakHintsValid;
  int get visiblePageIndex => _visiblePage;
  OfficeExtensionSet get extensions => _extensions;

  /// Roda um comando nomeado de extensão (o caminho da UI: botão de negrito,
  /// item de menu, barra de ferramentas).
  ///
  /// Devolve false quando o comando não existe OU não se aplica ao estado
  /// atual — a UI usa isso para desabilitar o botão em vez de fingir que a
  /// ação funcionou.
  bool runCommand(String name) {
    if (_disposed) return false;
    final command = _extensions.command(name);
    if (command == null) return false;
    syncSelectionFromDom();
    return command(_state, dispatch);
  }

  /// Puxa a seleção NATIVA para o modelo.
  ///
  /// Sem isto um comando agiria na seleção que o modelo guardou da última
  /// transação, não em onde o usuário está agora: o caminho do
  /// `beforeinput` lê a seleção nativa explicitamente, mas um comando
  /// (negrito, atalho, botão da barra) usa `state.selection`. Mover o
  /// cursor não gera transação — então, sem esta sincronização, o negrito
  /// cairia na posição errada em silêncio.
  ///
  /// Só a SELEÇÃO muda, nunca o documento; por isso não reprojeta.
  bool syncSelectionFromDom() {
    if (_disposed) return false;
    final range = readNativeSelection();
    if (range == null) return false;
    final current = _state.selection;
    if (current.from == range.from && current.to == range.to) return false;
    _state = _state.apply(_state.tr
      ..setSelection(TextSelection.create(_state.doc, range.from, range.to)));
    return true;
  }

  /// Aplica uma transação: novo estado → recompõe → reprojeta → restaura a
  /// seleção. É o ÚNICO caminho de mudança; a UI, os comandos e a entrada
  /// do teclado passam todos por aqui.
  void dispatch(Transaction transaction) {
    if (_disposed) return;
    _state = _state.apply(transaction);
    if (transaction.docChanged) {
      // `lastRenderedPageBreak` descreve o layout da última gravação feita
      // pelo Word. Qualquer mutação do documento torna o conjunto inteiro
      // obsoleto, inclusive mudanças de marca que não produzem StepMap.
      _renderedPageBreakHintsValid = false;
      // Recomposição INCREMENTAL: as páginas antes da menor posição tocada
      // pela transação são reusadas. Digitar na página 180 de 200 custa as
      // páginas 180+, não as 200.
      _composeAfter(transaction);
    }
    // Durante a composição a projeção pertence ao BROWSER: reconstruí-la
    // aqui destruiria os nós que o IME está usando para desenhar o
    // candidato, e a composição morreria no meio da palavra.
    if (!_composing) {
      _project();
      _writeSelection();
    }
    onStateChange?.call(_state);
  }

  /// Lê a seleção NATIVA e devolve o range no espaço do modelo, ou null
  /// quando o caret não está dentro da projeção (chrome da página,
  /// placeholder de uma página desmontada, fora do host).
  ({int from, int to})? readNativeSelection() {
    final native = _adapter.getNativeSelectionRange();
    if (native == null) return null;
    // A seleção nativa é GLOBAL: pode pertencer a outro editor na página ou
    // apontar para uma projeção já substituída. Fora do host, ela não diz
    // nada sobre ESTE documento — mesma guarda do reconciliador.
    if (!_containsNode(host, native.startContainer)) return null;
    final anchor =
        _positions.modelPositionAt(native.startContainer, native.startOffset);
    final head =
        _positions.modelPositionAt(native.endContainer, native.endOffset);
    if (anchor == null || head == null) return null;
    return (
      from: anchor < head ? anchor : head,
      to: anchor < head ? head : anchor
    );
  }

  /// [ancestor] contém [node]? Igualdade de nó, nunca identidade — o
  /// adaptador web cunha wrapper novo a cada acesso.
  static bool _containsNode(DomNode ancestor, DomNode node) {
    DomNode? current = node;
    while (current != null) {
      if (current == ancestor) return true;
      current = current.parentNode;
    }
    return false;
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _paginationGeneration++;
    host.removeEventListener('beforeinput', _beforeInput);
    host.removeEventListener('keydown', _keyDown);
    host.removeEventListener('pointerdown', _pointerDown);
    host.removeEventListener('copy', _copy);
    host.removeEventListener('cut', _cut);
    host.removeEventListener('paste', _paste);
    host.removeEventListener('compositionstart', _compositionStart);
    host.removeEventListener('compositionend', _compositionEnd);
    if (_scroll != null) {
      (_scrollContainer ?? host).removeEventListener('scroll', _scroll!);
    }
    if (_selectionChange != null) {
      _adapter.document
          .removeEventListener('selectionchange', _selectionChange!);
    }
  }

  /// A janela de páginas montada agora. Null quando tudo está montado.
  PageWindow? get mountedWindow => _window;

  /// True enquanto uma composição IME está em curso. Enquanto for true, a
  /// projeção NÃO é reconstruída.
  bool get isComposing => _composing;

  // -- laço -----------------------------------------------------------------

  void _compose() {
    final policy = progressive;
    if (policy == null) {
      _pageGraph = _composer.compose(
        _state.doc,
        honorRenderedPageBreaks: _renderedPageBreakHintsValid,
      );
      return;
    }
    // Progressivo: compõe só as primeiras páginas, projeta, e o laço de
    // fatias completa o resto no event loop — a contagem cresce como no
    // Word.
    _pageGraph = _composer.compose(
      _state.doc,
      honorRenderedPageBreaks: _renderedPageBreakHintsValid,
      maxPages: policy.initialPages,
    );
    if (_pageGraph.isPartial) {
      _schedulePaginationSlices(policy);
    } else {
      onPaginationProgress?.call(_pageGraph.pages.length, true);
    }
  }

  void _schedulePaginationSlices(OfficeProgressivePagination policy) {
    final generation = ++_paginationGeneration;
    onPaginationProgress?.call(_pageGraph.pages.length, false);
    Future<void> run() async {
      while (!_disposed &&
          generation == _paginationGeneration &&
          _pageGraph.isPartial) {
        await Future<void>.delayed(Duration.zero);
        if (_disposed ||
            generation != _paginationGeneration ||
            !_pageGraph.isPartial) {
          return;
        }
        // Durante composição IME a projeção pertence ao browser; a fatia
        // espera a próxima volta do event loop.
        if (_composing) continue;
        _pageGraph = _composer.composeContinue(
          _state.doc,
          _pageGraph,
          maxPages: _pageGraph.pages.length + policy.pagesPerSlice,
        );
        _project();
        _writeSelection();
        onPaginationProgress?.call(
            _pageGraph.pages.length, !_pageGraph.isPartial);
      }
    }

    unawaited(run());
  }

  /// Recompõe a partir da menor posição que a transação tocou.
  void _composeAfter(Transaction transaction) {
    if (_pageGraph.isPartial) {
      // Uma edição no meio da paginação progressiva: o reuso incremental
      // convergiria contra um grafo SEM cauda e declararia o documento
      // completo faltando páginas. Cancela as fatias e recompõe inteiro —
      // a edição já invalidou os hints, então é a composição natural.
      _paginationGeneration++;
      _pageGraph = _composer.compose(
        _state.doc,
        honorRenderedPageBreaks: false,
      );
      onPaginationProgress?.call(_pageGraph.pages.length, true);
      return;
    }
    final changedFrom = _changedFrom(transaction);
    if (changedFrom == null) {
      // AddMark/RemoveMark e passos de atributo mudam o documento sem mudar
      // posições, portanto seus StepMaps são vazios. Voltar a `compose()`
      // aqui reativaria os hints obsoletos; posição zero é o fallback global
      // conservador do compositor incremental.
      _pageGraph = _composer.composeIncremental(
        _state.doc,
        previous: _pageGraph,
        changedFromDocPos: 0,
      );
      return;
    }
    _pageGraph = _composer.composeIncremental(
      _state.doc,
      previous: _pageGraph,
      changedFromDocPos: changedFrom,
    );
  }

  /// A MENOR posição tocada pela transação, no documento NOVO.
  ///
  /// Null quando a transação não declara faixas (nada a reusar com
  /// segurança, então recompõe tudo).
  static int? _changedFrom(Transaction transaction) {
    int? smallest;
    for (final map in transaction.mapping.maps) {
      map.forEach((oldStart, oldEnd, newStart, newEnd) {
        if (smallest == null || newStart < smallest!) smallest = newStart;
      });
    }
    return smallest;
  }

  void _project([int? visiblePage]) {
    _window = _computeWindow(visiblePage ?? _visiblePage);
    _renderer.render(_pageGraph, host, window: _window);
  }

  /// A janela em volta da página visível, mais as páginas FIXADAS.
  ///
  /// Nunca desmontar a página da seleção é o que impede o caret de sumir: o
  /// mapa de posições devolve null em página desmontada, e o contrato é que
  /// o chamador monte — aqui o chamador somos nós. Mas a seleção FIXA a
  /// página, não estica a faixa: um caret na página 0 com o viewport na 150
  /// manteria 151 páginas montadas, e a virtualização não serviria para
  /// nada.
  PageWindow? _computeWindow([int? visiblePage]) {
    final policy = virtualization;
    if (policy == null) return null;
    final total = _pageGraph.pages.length;
    if (total == 0) return null;

    final visible = visiblePage ?? _visiblePageIndex();
    var first = visible - policy.radius;
    var last = visible + policy.radius;
    if (first < 0) first = 0;
    if (last > total - 1) last = total - 1;

    final pinned = <int>{};
    for (final position in [_state.selection.from, _state.selection.to]) {
      final page = _pageGraph.positionMap.pageOf(position);
      if (page < first || page > last) pinned.add(page);
    }
    return PageWindow(firstPage: first, lastPage: last, pinned: pinned);
  }

  /// Qual página está no topo do viewport.
  ///
  /// A geometria do DOM é autoritativa. Um DOCX pode trocar o tamanho da
  /// folha entre seções; dividir o scroll pela altura da primeira página
  /// acumula erro e passa a anunciar a página anterior em documentos longos.
  /// A busca binária mede no máximo O(log n) folhas/placeholders e funciona
  /// igualmente com a janela virtualizada, pois os placeholders preservam a
  /// geometria real de cada página.
  int _visiblePageIndex() {
    if (_pageGraph.pages.isEmpty) return 0;
    final container = _scrollContainer ?? host;
    final scrollTop = container.scrollTop;
    if (scrollTop <= _renderer.scrollTopInsetPx) return 0;
    final measured = _visiblePageIndexFromDom(container);
    if (measured != null) return measured;

    // Adaptadores sem layout (VM/fakes) não oferecem retângulos DOM. O
    // fallback reproduz a projeção página a página, inclusive seções com
    // alturas distintas, usando a mesma precisão serializada pelo renderer.
    final relativeScroll =
        scrollTop - _renderer.scrollTopInsetPx + _pageCrossingTolerancePx;
    var nextPageTop = 0.0;
    for (var index = 1; index < _pageGraph.pages.length; index++) {
      final previous = _pageGraph.pages[index - 1];
      final projectedHeight =
          previous.setup.heightTwips / 20.0 * _renderer.pxPerPt;
      nextPageTop +=
          (projectedHeight * 100).round() / 100.0 + _renderer.pageGapPx;
      if (relativeScroll < nextPageTop) return index - 1;
    }
    return _pageGraph.pages.length - 1;
  }

  static const double _pageCrossingTolerancePx = 1.0;

  int? _visiblePageIndexFromDom(DomElement container) {
    final pages = <DomElement>[];
    for (final node in host.childNodes) {
      if (node is DomElement && node.getAttribute('data-page') != null) {
        pages.add(node);
      }
    }
    if (pages.isEmpty) return null;

    int pageNumberAt(int index) =>
        int.tryParse(pages[index].getAttribute('data-page') ?? '') ?? index;
    double? topAt(int index) {
      final bounds =
          _adapter.getElementBounds(pages[index], relativeTo: container);
      final top = bounds?['top'];
      return top is num ? top.toDouble() : null;
    }

    if (pages.length == 1) return pageNumberAt(0);
    final firstTop = topAt(0);
    final lastTop = topAt(pages.length - 1);
    // O fake DOM devolve o mesmo retângulo para todos os elementos. Isso não
    // é geometria utilizável e deve seguir para o fallback determinístico.
    if (firstTop == null || lastTop == null || lastTop <= firstTop) return null;

    var low = 0;
    var high = pages.length - 1;
    var visible = 0;
    while (low <= high) {
      final middle = low + ((high - low) >> 1);
      final top = topAt(middle);
      if (top == null) return null;
      if (top <= _pageCrossingTolerancePx) {
        visible = middle;
        low = middle + 1;
      } else {
        high = middle - 1;
      }
    }
    return pageNumberAt(visible).clamp(0, _pageGraph.pages.length - 1);
  }

  void _handleScroll(DomEvent event) {
    if (_disposed || _composing) return;
    final visible = _visiblePageIndex();
    if (visible != _visiblePage) {
      _visiblePage = visible;
      onVisiblePageChange?.call(visible);
    }
    final next = _computeWindow(visible);
    if (next == null || next == _window) return;
    _renderer.render(_pageGraph, host, window: next);
    _window = next;
    _writeSelection();
  }

  /// Escreve a seleção do MODELO na seleção nativa. Uma posição em página
  /// não montada simplesmente não é escrita — a virtualização monta a
  /// janela e a próxima projeção resolve.
  void _writeSelection() {
    final selection = _state.selection;
    final from = _positions.domPositionFor(host, selection.from);
    final to = selection.from == selection.to
        ? from
        : _positions.domPositionFor(host, selection.to);
    if (from == null || to == null) return;
    _adapter.setSelectionByNodes(from.node, from.offset, to.node, to.offset);
  }

  // -- entrada --------------------------------------------------------------

  /// Clicar num OBJETO (imagem, caixa de texto) seleciona o NÓ, como no
  /// Word — não um ponto de texto ao lado dele.
  ///
  /// Sem isto, clicar numa imagem colocava o caret num dos lados e todo o
  /// vocabulário de objeto (moldura, alças, Delete que apaga a figura)
  /// ficava inacessível. Os objetos são `contenteditable=false`, então o
  /// browser sozinho não produz nenhuma seleção útil sobre eles.
  void _handlePointerDown(DomEvent event) {
    if (_disposed || _composing) return;
    final target = event.target;
    if (target == null) return;
    final element = _objectElementAt(target);
    if (element == null) return;
    final pos = _positions.modelPositionAt(element, 0);
    if (pos == null) return;
    final resolved = _state.doc.resolve(_clamp(pos, _state.doc));
    final node = resolved.nodeAfter;
    if (node == null || !NodeSelection.isSelectable(node)) return;
    // O browser não deve iniciar uma seleção de texto por cima do objeto: o
    // arrasto a partir daqui pertence ao redimensionamento/reposicionamento.
    event.preventDefault();
    dispatch(_state.tr..setSelection(NodeSelection.create(_state.doc, pos)));
  }

  /// O elemento de objeto que contém [node], ou null.
  DomElement? _objectElementAt(DomNode node) {
    DomNode? current = node;
    while (current != null) {
      if (current is DomElement &&
          (current.classes.contains('$officeCssPrefix-image') ||
              current.classes.contains('$officeCssPrefix-text-box'))) {
        return current;
      }
      if (current == host) break;
      current = current.parentNode;
    }
    return null;
  }

  /// Atalhos das extensões. Só cancela o evento quando um comando REALMENTE
  /// tratou a tecla — cancelar o que não se tratou quebraria navegação,
  /// atalhos do browser e acessibilidade.
  void _handleKeyDown(DomEvent event) {
    if (_disposed || event is! DomKeyboardEvent) return;
    // Com um OBJETO selecionado o teclado age sobre o nó, não sobre texto:
    // Delete/Backspace apagam a figura e as setas saem dela para o texto
    // vizinho. O `beforeinput` não cobre isso de forma confiável porque o
    // objeto é `contenteditable=false`.
    if (!event.isComposing && _handleObjectKey(event)) {
      event.preventDefault();
      return;
    }
    // Durante composição IME o keydown carrega a tecla física (keyCode 229
    // em vários browsers): disparar atalho aqui agiria no meio de uma
    // palavra sendo composta.
    if (event.isComposing) return;
    syncSelectionFromDom();
    // Dentro de tabela, Tab pertence ao documento: ele percorre as celulas
    // editaveis. Na ultima celula mantemos o caret e cancelamos o default;
    // criar uma linha implicitamente aqui seria uma mutacao estrutural
    // arriscada e diferente entre browsers.
    if (event.key == 'Tab' &&
        !event.ctrlKey &&
        !event.metaKey &&
        !event.altKey &&
        _moveAcrossTableCell(backward: event.shiftKey)) {
      event.preventDefault();
      return;
    }
    final handled = _extensions.handleKey(
      key: event.key,
      ctrl: event.ctrlKey,
      meta: event.metaKey,
      shift: event.shiftKey,
      alt: event.altKey,
      state: _state,
      dispatch: dispatch,
    );
    if (handled) event.preventDefault();
  }

  /// Teclas que agem sobre o OBJETO selecionado. Devolve true quando tratou.
  bool _handleObjectKey(DomKeyboardEvent event) {
    final selection = _state.selection;
    if (selection is! NodeSelection) return false;
    if (event.ctrlKey || event.metaKey || event.altKey) return false;
    switch (event.key) {
      case 'Delete':
      case 'Backspace':
        final tr = _state.tr..delete(selection.from, selection.to);
        tr.setSelection(
            Selection.near(tr.doc.resolve(_clamp(selection.from, tr.doc))));
        dispatch(tr);
        return true;
      case 'ArrowLeft':
      case 'ArrowUp':
        _escapeObject(backward: true);
        return true;
      case 'ArrowRight':
      case 'ArrowDown':
        _escapeObject(backward: false);
        return true;
      case 'Escape':
        _escapeObject(backward: false);
        return true;
      default:
        return false;
    }
  }

  /// Sai do objeto para o texto vizinho, com o caret do lado pedido.
  void _escapeObject({required bool backward}) {
    final selection = _state.selection;
    final anchor = backward ? selection.from : selection.to;
    final found = Selection.findFrom(
      _state.doc.resolve(_clamp(anchor, _state.doc)),
      backward ? -1 : 1,
      true,
    );
    if (found == null) return;
    dispatch(_state.tr..setSelection(found));
  }

  // -- composição IME --------------------------------------------------------

  void _handleCompositionStart(DomEvent event) {
    if (_disposed) return;
    _composing = true;
  }

  /// Fim da composição: o browser JÁ escreveu na projeção. Lemos o bloco
  /// afetado e reconstruímos a diferença como transação normal — o modelo
  /// volta a ser a fonte de verdade e o histórico vê UMA edição.
  void _handleCompositionEnd(DomEvent event) {
    if (_disposed) return;
    _composing = false;
    final native = _adapter.getNativeSelectionRange();
    if (native == null) {
      _project();
      return;
    }
    final transaction = _reconciler.reconcile(
      host: host,
      node: native.startContainer,
      state: _state,
    );
    if (transaction == null) {
      // Nada mudou no modelo, mas o DOM pode ter ficado com nós próprios do
      // IME: reprojetar devolve a projeção canônica.
      _project();
      _writeSelection();
      return;
    }
    dispatch(transaction);
  }

  // -- clipboard -------------------------------------------------------------

  /// Escreve o recorte na área de transferência. Devolve false quando não há
  /// nada selecionado — aí o evento segue seu curso normal.
  bool _writeClipboard(DomClipboardEvent event) {
    syncSelectionFromDom();
    final selection = _state.selection;
    if (selection.empty) return false;
    final data = event.clipboardData;
    if (data == null) return false;
    final payload = _clipboard.serialize(selection.content());
    data.setData('text/plain', payload.text);
    data.setData('text/html', payload.html);
    return true;
  }

  void _handleCopy(DomEvent event) {
    if (_disposed || event is! DomClipboardEvent) return;
    // Copiar é do MODELO, não do DOM: a projeção tem marcadores de lista e
    // quebras de página que não são texto do documento, e o serializador
    // nativo os arrastaria junto.
    if (_writeClipboard(event)) event.preventDefault();
  }

  void _handleCut(DomEvent event) {
    if (_disposed || event is! DomClipboardEvent) return;
    syncSelectionFromDom();
    final selection = _state.selection;
    if (!selection.empty && !_isSafeCellRange(selection.from, selection.to)) {
      // Nunca deixe o fallback nativo cortar o DOM projetado: uma seleção
      // entre células destruiria wrappers de tabela sem transação válida.
      event.preventDefault();
      return;
    }
    if (!_writeClipboard(event)) return;
    event.preventDefault();
    dispatch(_state.tr..delete(selection.from, selection.to));
  }

  void _handlePaste(DomEvent event) {
    if (_disposed || event is! DomClipboardEvent) return;
    // SEMPRE cancela: deixar o browser colar HTML arbitrário na projeção
    // escreveria no DOM um conteúdo que o modelo não conhece.
    event.preventDefault();
    syncSelectionFromDom();
    final selection = _state.selection;
    if (!_isSafeCellRange(selection.from, selection.to)) return;
    final data = event.clipboardData;
    if (data == null) return;
    final slice = _clipboard.parse(
      html: data.getData('text/html'),
      text: data.getData('text/plain'),
      schema: _state.schema,
    );
    if (slice == null) return;
    dispatch(_state.tr..replaceSelection(slice));
  }

  void _handleBeforeInput(DomEvent event) {
    if (_disposed || event is! DomInputEvent) return;

    // Composição IME: NÃO cancelar. O browser precisa dos próprios nós para
    // desenhar o candidato, e cancelar aqui quebraria CJK, acentos mortos e
    // a autocorreção do mobile. O que ele escrever é reconciliado no
    // `compositionend`.
    if (event.isComposing || _composing) return;

    // Tudo que chega aqui é cancelado: o browser não escreve na projeção.
    event.preventDefault();

    final action = _actionFor(event.inputType);
    if (action == null) return;

    var range = readNativeSelection();
    if (range == null) return;

    // Para apagamentos colapsados, getTargetRanges e a fonte mais fiel: o
    // browser ja calculou o grafema, a palavra ou a linha visual atingida.
    // Eventos sinteticos e alguns browsers nao o fornecem; nesses casos os
    // fallbacks abaixo trabalham somente no textblock atual.
    if (range.from == range.to && _isDeleteAction(action)) {
      var targetWasProvided = false;
      ({int from, int to})? targetRange;
      for (final target in event.getTargetRanges()) {
        if (target.collapsed) continue;
        targetWasProvided = true;
        targetRange = _modelRangeFor(target);
        break;
      }
      if (targetWasProvided) {
        // Um target range fora da projecao ou entre celulas e rejeitado; nao
        // adivinhamos outro intervalo e arriscamos apagar estrutura.
        if (targetRange == null) return;
        range = targetRange;
      } else if (action == OfficeInputAction.deleteWordBackward) {
        final fallback = _wordBackwardRange(range.from);
        if (fallback == null) return;
        range = fallback;
      } else if (action == OfficeInputAction.deleteSoftLineBackward) {
        final fallback = _softLineBackwardRange(range.from);
        if (fallback == null) return;
        range = fallback;
      }
    }

    final transaction = _transactionFor(action, range, event.data);
    if (transaction != null) dispatch(transaction);
  }

  static OfficeInputAction? _actionFor(String? inputType) =>
      switch (inputType) {
        'insertText' => OfficeInputAction.insertText,
        'insertParagraph' => OfficeInputAction.insertParagraph,
        'insertLineBreak' => OfficeInputAction.insertLineBreak,
        'deleteContentBackward' => OfficeInputAction.deleteBackward,
        'deleteWordBackward' => OfficeInputAction.deleteWordBackward,
        'deleteSoftLineBackward' => OfficeInputAction.deleteSoftLineBackward,
        'deleteContentForward' ||
        'deleteWordForward' ||
        'deleteContent' =>
          OfficeInputAction.deleteForward,
        _ => null,
      };

  Transaction? _transactionFor(
    OfficeInputAction action,
    ({int from, int to}) range,
    String? data,
  ) {
    final transaction = _state.tr;
    final docSize = _state.doc.content.size;
    switch (action) {
      case OfficeInputAction.insertText:
        if (!_isSafeCellRange(range.from, range.to)) return null;
        final text = data;
        if (text == null || text.isEmpty) return null;
        transaction.insertText(text, range.from, range.to);
      case OfficeInputAction.insertParagraph:
        if (!_isSafeCellRange(range.from, range.to)) return null;
        if (range.from != range.to) transaction.delete(range.from, range.to);
        transaction.split(range.from);
      case OfficeInputAction.insertLineBreak:
        if (!_isSafeCellRange(range.from, range.to)) return null;
        final type = _state.schema.nodes['hardBreak'];
        if (type == null) return null;
        final marks = _state.doc.resolve(range.from).marks();
        transaction.replaceRangeWith(
            range.from, range.to, type.create(null, null, marks));
      case OfficeInputAction.deleteBackward ||
            OfficeInputAction.deleteWordBackward ||
            OfficeInputAction.deleteSoftLineBackward:
        if (range.from != range.to) {
          if (!_isSafeCellRange(range.from, range.to)) return null;
          transaction.delete(range.from, range.to);
        } else {
          if (range.from <= 1) return null;
          if (_atProtectedCellBoundary(range.from, backward: true)) {
            return null;
          }
          final deletion = _backwardVisibleUnitRange(range.from);
          if (deletion == null ||
              !_isSafeCellRange(deletion.from, deletion.to)) {
            return null;
          }
          transaction.delete(deletion.from, deletion.to);
        }
      case OfficeInputAction.deleteForward:
        if (range.from != range.to) {
          if (!_isSafeCellRange(range.from, range.to)) return null;
          transaction.delete(range.from, range.to);
        } else {
          if (range.to >= docSize) return null;
          if (_atProtectedCellBoundary(range.to, backward: false)) {
            return null;
          }
          final deletion = _forwardVisibleUnitRange(range.to);
          if (deletion == null ||
              !_isSafeCellRange(deletion.from, deletion.to)) {
            return null;
          }
          transaction.delete(deletion.from, deletion.to);
        }
    }
    // A seleção segue o mapeamento da própria transação (é o que mantém o
    // caret no lugar certo depois de uma edição que muda tamanhos).
    final mapped = transaction.mapping.map(range.from);
    transaction.setSelection(Selection.near(
        transaction.doc.resolve(_clamp(mapped, transaction.doc))));
    return transaction;
  }

  static bool _isDeleteAction(OfficeInputAction action) =>
      action == OfficeInputAction.deleteBackward ||
      action == OfficeInputAction.deleteWordBackward ||
      action == OfficeInputAction.deleteSoftLineBackward ||
      action == OfficeInputAction.deleteForward;

  ({int from, int to})? _modelRangeFor(DomNativeRange native) {
    if (!_containsNode(host, native.startContainer) ||
        !_containsNode(host, native.endContainer)) {
      return null;
    }
    final anchor =
        _positions.modelPositionAt(native.startContainer, native.startOffset);
    final head =
        _positions.modelPositionAt(native.endContainer, native.endOffset);
    if (anchor == null || head == null || anchor == head) return null;
    final range = (
      from: anchor < head ? anchor : head,
      to: anchor < head ? head : anchor,
    );
    return _isSafeCellRange(range.from, range.to) ? range : null;
  }

  /// Fallback de Ctrl+Backspace/Option+Backspace. Usa offsets UTF-16, como
  /// as posicoes do modelo, e considera letras acentuadas/combining marks
  /// parte da palavra (somente espaco e pontuacao separam palavras).
  ({int from, int to})? _wordBackwardRange(int caret) {
    final resolved = _state.doc.resolve(_clamp(caret, _state.doc));
    if (!resolved.parent.inlineContent || resolved.parentOffset <= 0) {
      return null;
    }
    final prefix = resolved.parent.textBetween(
      0,
      resolved.parentOffset,
      leafText: _logicalLeafText,
    );
    var start = prefix.length;
    while (start > 0 && _isSpace(prefix.substring(start - 1, start))) {
      start--;
    }
    if (start > 0) {
      final removeWord = !_isPunctuation(prefix.substring(start - 1, start));
      while (start > 0) {
        final character = prefix.substring(start - 1, start);
        if (_isSpace(character) || (_isPunctuation(character) == removeWord)) {
          break;
        }
        start--;
      }
      if (!removeWord) {
        while (
            start > 0 && _isPunctuation(prefix.substring(start - 1, start))) {
          start--;
        }
      }
    }
    final from = resolved.start() + start;
    if (from >= caret || !_isSafeCellRange(from, caret)) return null;
    return (from: from, to: caret);
  }

  /// Fallback de deleteSoftLineBackward. Primeiro usa a linha visual
  /// projetada (inclusive em wrap); sem uma ancora DOM valida, recua ate a
  /// ultima quebra manual ou ao inicio do textblock.
  ({int from, int to})? _softLineBackwardRange(int caret) {
    var from = _visualLineStart(caret);
    final resolved = _state.doc.resolve(_clamp(caret, _state.doc));
    if (from == null || from < resolved.start() || from > caret) {
      if (!resolved.parent.inlineContent) return null;
      final prefix = resolved.parent.textBetween(
        0,
        resolved.parentOffset,
        leafText: _logicalLeafText,
      );
      final breakAt = prefix.lastIndexOf('\n');
      from = resolved.start() + (breakAt < 0 ? 0 : breakAt + 1);
    }
    if (from >= caret || !_isSafeCellRange(from, caret)) return null;
    return (from: from, to: caret);
  }

  int? _visualLineStart(int caret) {
    final native = _adapter.getNativeSelectionRange();
    if (native == null) return null;
    final line =
        _ancestorWithClass(native.startContainer, '$officeCssPrefix-line');
    final block = line == null
        ? null
        : _ancestorWithClass(line, '$officeCssPrefix-block');
    if (line == null || block == null) return null;
    final docPos = int.tryParse(block.getAttribute('data-doc-pos') ?? '');
    final charStart = int.tryParse(line.getAttribute('data-char-start') ?? '');
    if (docPos == null || charStart == null) return null;
    final result = docPos + charStart;
    return result <= caret ? result : null;
  }

  DomElement? _ancestorWithClass(DomNode node, String className) {
    DomNode? current = node;
    while (current != null) {
      if (current is DomElement && current.classes.contains(className)) {
        return current;
      }
      if (current == host) break;
      current = current.parentNode;
    }
    return null;
  }

  static String? _logicalLeafText(PMNode node) =>
      node.type.name == 'hardBreak' ? '\n' : '\u{fffc}';

  static bool _isSpace(String character) =>
      character.trim().isEmpty || character == '\u00a0';

  static final RegExp _punctuation =
      RegExp(r'''[.,;:!?…“”"'‘’()\[\]{}<>/\\|@#$%^&*+=~`—–-]''');

  static bool _isPunctuation(String character) =>
      _punctuation.hasMatch(character);

  /// Localiza a tabela/celula MAIS interna que contem [position].
  ({int tableStart, int cellStart, PMNode table, PMNode cell})? _tableContextAt(
      int position) {
    final resolved = _state.doc.resolve(_clamp(position, _state.doc));
    int? cellDepth;
    for (var depth = resolved.depth; depth > 0; depth--) {
      final node = resolved.node(depth);
      if (cellDepth == null && node.type.name == 'tableCell') {
        cellDepth = depth;
      } else if (cellDepth != null && node.type.name == 'table') {
        return (
          tableStart: resolved.before(depth),
          cellStart: resolved.before(cellDepth),
          table: node,
          cell: resolved.node(cellDepth),
        );
      }
    }
    return null;
  }

  bool _isSafeCellRange(int from, int to) {
    final left = _tableContextAt(from);
    final right = _tableContextAt(to);
    if (left == null && right == null) return true;
    return left != null &&
        right != null &&
        left.tableStart == right.tableStart &&
        left.cellStart == right.cellStart;
  }

  /// Backspace/Delete operam sobre a unidade VISÍVEL adjacente. Metadados
  /// OOXML (`bookmark*`, proof/range markers) são atoms `opaqueInline`
  /// escondidos e não podem desaparecer só porque o caret encostou neles.
  ({int from, int to})? _backwardVisibleUnitRange(int caret) {
    var end = _clamp(caret, _state.doc);
    while (end > 1) {
      final before = _state.doc.resolve(end).nodeBefore;
      if (before?.type.name != 'opaqueInline') break;
      end -= before!.nodeSize;
    }
    if (end <= 1) return null;
    return (from: end - 1, to: end);
  }

  ({int from, int to})? _forwardVisibleUnitRange(int caret) {
    final docSize = _state.doc.content.size;
    var start = _clamp(caret, _state.doc);
    while (start < docSize) {
      final after = _state.doc.resolve(start).nodeAfter;
      if (after?.type.name != 'opaqueInline') break;
      start += after!.nodeSize;
    }
    if (start >= docSize) return null;
    return (from: start, to: start + 1);
  }

  bool _atProtectedCellBoundary(int position, {required bool backward}) {
    if (_tableContextAt(position) == null) return false;
    final resolved = _state.doc.resolve(_clamp(position, _state.doc));
    if (!resolved.parent.inlineContent) return true;
    return backward
        ? resolved.parentOffset == 0
        : resolved.parentOffset == resolved.parent.content.size;
  }

  /// Move Tab/Shift+Tab entre celulas da tabela interna. Retorna true mesmo
  /// nas bordas para que o browser nao tire o foco nem crie estrutura.
  bool _moveAcrossTableCell({required bool backward}) {
    final context = _tableContextAt(_state.selection.head);
    if (context == null) return false;
    final cells = <({int position, PMNode node})>[];
    var rowOffset = 0;
    for (final row in context.table.children) {
      if (row.type.name != 'tableRow') {
        rowOffset += row.nodeSize;
        continue;
      }
      var cellOffset = 0;
      for (final cell in row.children) {
        final position = context.tableStart + 1 + rowOffset + 1 + cellOffset;
        if (cell.type.name == 'tableCell' && !_isMergeContinuation(cell)) {
          cells.add((position: position, node: cell));
        }
        cellOffset += cell.nodeSize;
      }
      rowOffset += row.nodeSize;
    }
    final current = cells
        .indexWhere((candidate) => candidate.position == context.cellStart);
    if (current < 0) return true;
    final next = current + (backward ? -1 : 1);
    if (next < 0 || next >= cells.length) return true;
    final target = cells[next];
    final found =
        Selection.findFrom(_state.doc.resolve(target.position + 1), 1, true);
    if (found == null) return true;
    final targetContext = _tableContextAt(found.from);
    if (targetContext == null || targetContext.cellStart != target.position) {
      return true;
    }
    dispatch(_state.tr..setSelection(found));
    return true;
  }

  static bool _isMergeContinuation(PMNode cell) {
    for (final key in const ['word', 'cell']) {
      final attrs = cell.attrs[key];
      if (attrs is! Map) continue;
      final value = attrs['vMerge'];
      if (value is String && value.toLowerCase() == 'continue') return true;
      if (value is Map &&
          '${value['value'] ?? value['val'] ?? ''}'.toLowerCase() ==
              'continue') {
        return true;
      }
    }
    return false;
  }

  static int _clamp(int position, PMNode doc) {
    if (position < 0) return 0;
    final max = doc.content.size;
    return position > max ? max : position;
  }
}
