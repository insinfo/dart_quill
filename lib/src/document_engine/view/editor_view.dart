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
    this.onStateChange,
  })  : _state = state,
        _adapter = adapter,
        _composer = composer ?? LayoutComposer(),
        _renderer = renderer ??
            PageGraphDomRenderer(document: adapter.document, editable: true) {
    _beforeInput = _handleBeforeInput;
    host.addEventListener('beforeinput', _beforeInput);
    _compose();
    _project();
  }

  final DomElement host;
  final DomAdapter _adapter;
  final LayoutComposer _composer;
  final PageGraphDomRenderer _renderer;
  final OfficeDomPositionMap _positions = const OfficeDomPositionMap();

  /// Notificação de mudança de estado (a aplicação persiste a partir daqui).
  final void Function(EditorState state)? onStateChange;

  EditorState _state;
  late PageGraph _pageGraph;
  late DomEventListener _beforeInput;
  bool _disposed = false;

  EditorState get state => _state;
  PageGraph get pageGraph => _pageGraph;

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
    _project();
    _writeSelection();
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
  }

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

  void _handleBeforeInput(DomEvent event) {
    if (_disposed || event is! DomInputEvent) return;

    // Composição IME: não é cancelável de forma confiável e ainda não temos
    // o caminho de reconciliação. Ignorar é pior UX que suportar, mas é
    // honesto — fingir que funciona corromperia o documento.
    if (event.isComposing) return;

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
