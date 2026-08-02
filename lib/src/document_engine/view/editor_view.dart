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

import '../../platform/dom.dart';
import '../layout/dom_position_map.dart';
import '../layout/dom_renderer.dart';
import '../layout/layout_composer.dart';
import '../layout/page_graph.dart';
import '../model/index.dart';
import '../state/index.dart';
import 'clipboard.dart';
import 'extension.dart';
import 'reconciler.dart';

/// Um `inputType` que a view reconhece e roteia pelo modelo.
enum OfficeInputAction {
  insertText,
  insertParagraph,
  deleteBackward,
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
    this.onStateChange,
  })  : _state = state,
        _adapter = adapter,
        _composer = composer ?? LayoutComposer(),
        _extensions = OfficeExtensionSet(extensions),
        _renderer = renderer ??
            PageGraphDomRenderer(document: adapter.document, editable: true) {
    _beforeInput = _handleBeforeInput;
    _keyDown = _handleKeyDown;
    _copy = _handleCopy;
    _cut = _handleCut;
    _paste = _handlePaste;
    _compositionStart = _handleCompositionStart;
    _compositionEnd = _handleCompositionEnd;
    host.addEventListener('beforeinput', _beforeInput);
    host.addEventListener('keydown', _keyDown);
    host.addEventListener('copy', _copy);
    host.addEventListener('cut', _cut);
    host.addEventListener('paste', _paste);
    host.addEventListener('compositionstart', _compositionStart);
    host.addEventListener('compositionend', _compositionEnd);
    _compose();
    _project();
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
    void Function(EditorState state)? onStateChange,
  }) {
    final set = OfficeExtensionSet(extensions);
    return OfficeEditorView(
      host: host,
      state: EditorState.create(
          EditorStateConfig(doc: doc, plugins: set.plugins)),
      adapter: adapter,
      composer: composer,
      renderer: renderer,
      extensions: extensions,
      onStateChange: onStateChange,
    );
  }

  final DomElement host;
  final DomAdapter _adapter;
  final LayoutComposer _composer;
  final PageGraphDomRenderer _renderer;
  final OfficeExtensionSet _extensions;
  final OfficeDomPositionMap _positions = const OfficeDomPositionMap();

  /// Notificação de mudança de estado (a aplicação persiste a partir daqui).
  final void Function(EditorState state)? onStateChange;

  EditorState _state;
  late PageGraph _pageGraph;
  late DomEventListener _beforeInput;
  late DomEventListener _keyDown;
  late DomEventListener _copy;
  late DomEventListener _cut;
  late DomEventListener _paste;
  late DomEventListener _compositionStart;
  late DomEventListener _compositionEnd;
  final OfficeClipboard _clipboard = const OfficeClipboard();
  final OfficeDomReconciler _reconciler = const OfficeDomReconciler();
  bool _disposed = false;
  bool _composing = false;

  EditorState get state => _state;
  PageGraph get pageGraph => _pageGraph;
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
      // Recomposição TOTAL: correta e determinística, mas O(documento). A
      // invalidação incremental por PageSignature é a Fase 7 — até lá isto
      // é honesto para documentos de trabalho, não para 200 páginas.
      _compose();
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
    final anchor = _positions.modelPositionAt(
        native.startContainer, native.startOffset);
    final head =
        _positions.modelPositionAt(native.endContainer, native.endOffset);
    if (anchor == null || head == null) return null;
    return (from: anchor < head ? anchor : head, to: anchor < head ? head : anchor);
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    host.removeEventListener('beforeinput', _beforeInput);
    host.removeEventListener('keydown', _keyDown);
    host.removeEventListener('copy', _copy);
    host.removeEventListener('cut', _cut);
    host.removeEventListener('paste', _paste);
    host.removeEventListener('compositionstart', _compositionStart);
    host.removeEventListener('compositionend', _compositionEnd);
  }

  /// True enquanto uma composição IME está em curso. Enquanto for true, a
  /// projeção NÃO é reconstruída.
  bool get isComposing => _composing;

  // -- laço -----------------------------------------------------------------

  void _compose() => _pageGraph = _composer.compose(_state.doc);

  void _project() => _renderer.render(_pageGraph, host);

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

  /// Atalhos das extensões. Só cancela o evento quando um comando REALMENTE
  /// tratou a tecla — cancelar o que não se tratou quebraria navegação,
  /// atalhos do browser e acessibilidade.
  void _handleKeyDown(DomEvent event) {
    if (_disposed || event is! DomKeyboardEvent) return;
    // Durante composição IME o keydown carrega a tecla física (keyCode 229
    // em vários browsers): disparar atalho aqui agiria no meio de uma
    // palavra sendo composta.
    if (event.isComposing) return;
    syncSelectionFromDom();
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
    if (!_writeClipboard(event)) return;
    event.preventDefault();
    final selection = _state.selection;
    dispatch(_state.tr..delete(selection.from, selection.to));
  }

  void _handlePaste(DomEvent event) {
    if (_disposed || event is! DomClipboardEvent) return;
    // SEMPRE cancela: deixar o browser colar HTML arbitrário na projeção
    // escreveria no DOM um conteúdo que o modelo não conhece.
    event.preventDefault();
    final data = event.clipboardData;
    if (data == null) return;
    final slice = _clipboard.parse(
      html: data.getData('text/html'),
      text: data.getData('text/plain'),
      schema: _state.schema,
    );
    if (slice == null) return;
    syncSelectionFromDom();
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

    final range = readNativeSelection();
    if (range == null) return;

    final transaction = _transactionFor(action, range, event.data);
    if (transaction != null) dispatch(transaction);
  }

  static OfficeInputAction? _actionFor(String? inputType) => switch (inputType) {
        'insertText' => OfficeInputAction.insertText,
        'insertParagraph' || 'insertLineBreak' =>
          OfficeInputAction.insertParagraph,
        'deleteContentBackward' ||
        'deleteWordBackward' ||
        'deleteSoftLineBackward' =>
          OfficeInputAction.deleteBackward,
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
        final text = data;
        if (text == null || text.isEmpty) return null;
        transaction.insertText(text, range.from, range.to);
      case OfficeInputAction.insertParagraph:
        if (range.from != range.to) transaction.delete(range.from, range.to);
        transaction.split(range.from);
      case OfficeInputAction.deleteBackward:
        if (range.from != range.to) {
          transaction.delete(range.from, range.to);
        } else {
          if (range.from <= 1) return null;
          transaction.delete(range.from - 1, range.from);
        }
      case OfficeInputAction.deleteForward:
        if (range.from != range.to) {
          transaction.delete(range.from, range.to);
        } else {
          if (range.to >= docSize) return null;
          transaction.delete(range.to, range.to + 1);
        }
    }
    // A seleção segue o mapeamento da própria transação (é o que mantém o
    // caret no lugar certo depois de uma edição que muda tamanhos).
    final mapped = transaction.mapping.map(range.from);
    transaction.setSelection(
        Selection.near(transaction.doc.resolve(_clamp(mapped, transaction.doc))));
    return transaction;
  }

  static int _clamp(int position, PMNode doc) {
    if (position < 0) return 0;
    final max = doc.content.size;
    return position > max ? max : position;
  }
}
