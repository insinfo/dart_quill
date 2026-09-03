/// Os adornos de TABELA sobre a projeção: o realce da seleção retangular,
/// a âncora ⊞ do canto superior esquerdo e as alças de redimensionamento de
/// coluna.
///
/// Tudo vive no overlay, pelas mesmas razões do adorno de objeto: o DOM
/// projetado não pode ganhar elementos de chrome (o mapa de posições
/// contaria como conteúdo), e a geometria vem de medir a projeção, que é a
/// única fonte que não diverge do que o usuário vê.
///
/// Redimensionar coluna segue a regra do arrasto do editor: durante o
/// movimento só a GUIA se move; a transação sai uma vez, no `pointerup`.
library;

import '../../platform/dom.dart';
import '../layout/dom_renderer.dart';
import '../state/index.dart';
import 'controller.dart';
import 'table_geometry.dart';
import 'table_map.dart';
import 'table_ops.dart' as ops;

/// Distância (px) da borda de uma célula em que o ponteiro já conta como
/// "sobre a divisa" — a mesma tolerância generosa do Word.
const double officeColumnResizeTolerancePx = 4;

/// Deslocamento (px) a partir do qual a pressão na divisa vira arrasto.
const double officeColumnDragThresholdPx = 3;

/// Classe do host enquanto o ponteiro está sobre uma divisa de coluna: o
/// CSS troca o cursor para `col-resize`, como no Word.
const String officeColumnResizeHoverClass = 'dq-office-app-colresize';

class OfficeTableAdorner {
  OfficeTableAdorner(this.controller) : _kit = OfficeDomKit(controller.adapter);

  final OfficeWordController controller;
  final OfficeDomKit _kit;

  final List<DomElement> _cellHighlights = [];
  DomElement? _anchor;
  DomElement? _guide;

  /// Arrasto de coluna em curso.
  ({
    int tablePos,
    int columnIndex,
    num startX,
    double startWidthTwips,
    double guideLeft,
  })? _drag;

  /// O ponteiro já se afastou do ponto de pressão além de
  /// [officeColumnDragThresholdPx]: só então a guia aparece e o `pointerup`
  /// grava uma largura. Um clique parado na divisa NÃO é um arrasto — e era
  /// tratado como um: a transação de largura zero de deslocamento
  /// reescrevia a grade inteira a partir da projeção, mudava a largura das
  /// colunas e repaginava o documento (140 → 141 páginas) por um clique.
  bool _dragStarted = false;

  /// Chamado depois que a âncora ⊞ seleciona a tabela inteira, com o
  /// elemento da âncora — é onde o orquestrador abre a quickbar de tabela.
  void Function(DomElement anchor)? onWholeTableSelected;

  /// Célula onde um arrasto de SELEÇÃO começou (posição do nó), enquanto o
  /// botão está pressionado. Só vira seleção retangular quando o ponteiro
  /// entra em OUTRA célula — arrastar dentro de uma célula continua sendo
  /// seleção de texto normal, como no Word.
  int? _selectionAnchorCell;

  bool get isDragging => _drag != null;

  /// Redesenha realce e âncora para o estado atual.
  void refresh() {
    if (_drag != null) return;
    _clearHighlights();
    _clearAnchor();
    if (!controller.viewReady) return;

    _paintSelection();
    _paintAnchor();
  }

  void clear() {
    _clearHighlights();
    _clearAnchor();
    _guide?.remove();
    _guide = null;
    _drag = null;
    _dragStarted = false;
    _setResizeHover(false);
  }

  void _setResizeHover(bool over) {
    final classes = controller.hostElement.classes;
    if (over) {
      if (!classes.contains(officeColumnResizeHoverClass)) {
        classes.add(officeColumnResizeHoverClass);
      }
    } else if (classes.contains(officeColumnResizeHoverClass)) {
      classes.remove(officeColumnResizeHoverClass);
    }
  }

  // -- realce da seleção de células -------------------------------------------

  void _paintSelection() {
    final selection = controller.activeView.state.selection;
    if (selection is! CellSelection) return;
    for (final pos in selection.cellPositions) {
      final element = cellElementAt(pos);
      if (element == null) continue;
      final bounds = controller.adapter
          .getElementBounds(element, relativeTo: controller.overlay.layer);
      if (bounds == null) continue;
      final highlight = _kit.el('div', 'dq-office-cellmark');
      highlight.setAttribute(
        'style',
        'left:${_px(bounds['left'])}px;top:${_px(bounds['top'])}px;'
            'width:${_px(bounds['width'])}px;height:${_px(bounds['height'])}px;',
      );
      controller.overlay.layer.append(highlight);
      _cellHighlights.add(highlight);
    }
  }

  /// O elemento projetado da célula cujo nó começa em [cellPos].
  ///
  /// O renderer já publica `data-doc-from` em cada célula, e ele é
  /// exatamente a posição do NÓ (`docPos - 1`, ver `page_graph.dart`) — o
  /// chrome não precisa de atributo próprio.
  DomElement? cellElementAt(int cellPos) {
    for (final element in controller.activeView.host
        .querySelectorAll('.$officeCssPrefix-table-cell')) {
      final raw = element.getAttribute('data-doc-from');
      if (raw != null && int.tryParse(raw) == cellPos) return element;
    }
    return null;
  }

  void _clearHighlights() {
    for (final element in _cellHighlights) {
      element.remove();
    }
    _cellHighlights.clear();
  }

  // -- âncora ⊞ ---------------------------------------------------------------

  void _paintAnchor() {
    final state = controller.activeView.state;
    final map = OfficeTableMap.at(state.doc, state.selection.from);
    if (map == null) return;
    final first = map.cellCovering(0, 0);
    if (first == null) return;
    final element = cellElementAt(first.pos);
    if (element == null) return;
    final bounds = controller.adapter
        .getElementBounds(element, relativeTo: controller.overlay.layer);
    if (bounds == null) return;

    final anchor = _kit.el('button', 'dq-office-tableanchor');
    anchor.setAttribute('type', 'button');
    anchor.setAttribute('title', 'Selecionar tabela');
    anchor.setAttribute('aria-label', 'Selecionar tabela');
    anchor.setAttribute(
      'style',
      'left:${_px(bounds['left']) - 18}px;top:${_px(bounds['top']) - 18}px;',
    );
    anchor.addEventListener('mousedown', (event) => event.preventDefault());
    anchor.addEventListener('click', (event) {
      event.preventDefault();
      if (!ops.selectWholeTable(
          controller.activeView.state, controller.dispatch)) {
        return;
      }
      // A âncora que acabou de ser clicada foi redesenhada pelo refresh da
      // transação; quem recebe o callback é a nova, que está no lugar certo.
      final current = _anchor ?? anchor;
      onWholeTableSelected?.call(current);
    });
    controller.overlay.layer.append(anchor);
    _anchor = anchor;
  }

  void _clearAnchor() {
    _anchor?.remove();
    _anchor = null;
  }

  // -- redimensionamento de coluna --------------------------------------------

  /// O `pointerdown` no canvas: começa o arrasto quando o ponteiro está
  /// sobre a divisa DIREITA de uma célula. Devolve true quando assumiu o
  /// gesto (o chamador então não deixa a seleção de texto começar).
  bool handlePointerDown(DomEvent event) {
    if (!controller.viewReady || event is! DomMouseEvent) return false;
    final target = event.target;
    if (target == null) return false;
    final cellElement = _ancestorCell(target);
    if (cellElement == null) {
      _selectionAnchorCell = null;
      return false;
    }
    final bounds = controller.adapter.getElementBounds(cellElement);
    if (bounds == null) return false;
    final right = bounds['right'];
    if (right is! num) return false;
    if ((event.clientX - right).abs() > officeColumnResizeTolerancePx) {
      // Não é a divisa: o gesto pode virar uma seleção retangular se o
      // ponteiro alcançar outra célula.
      _selectionAnchorCell =
          int.tryParse(cellElement.getAttribute('data-doc-from') ?? '');
      return false;
    }
    _selectionAnchorCell = null;

    final cellPos =
        int.tryParse(cellElement.getAttribute('data-doc-from') ?? '');
    if (cellPos == null) return false;
    final state = controller.activeView.state;
    final map = OfficeTableMap.at(state.doc, cellPos + 1);
    final cell = map?.cellAt(cellPos + 1);
    if (map == null || cell == null) return false;

    // A divisa direita pertence à ÚLTIMA coluna que a célula ocupa.
    final columnIndex = cell.columnEnd - 1;
    final layerBounds =
        controller.adapter.getElementBounds(controller.overlay.layer);
    final widthTwips = _px(bounds['width']) / controller.pxPerTwip;

    event.preventDefault();
    _drag = (
      tablePos: map.tablePos,
      columnIndex: columnIndex,
      startX: event.clientX,
      startWidthTwips: widthTwips,
      guideLeft: (right - _px(layerBounds?['left'])).toDouble(),
    );
    // A guia só aparece quando o ponteiro de fato se move
    // (`officeColumnDragThresholdPx`): pressionar e soltar no mesmo lugar
    // não é um arrasto.
    _dragStarted = false;
    return true;
  }

  void handlePointerMove(DomEvent event) {
    if (event is! DomMouseEvent) return;
    final drag = _drag;
    if (drag != null) {
      event.preventDefault();
      final delta = (event.clientX - drag.startX).toDouble();
      if (!_dragStarted && delta.abs() < officeColumnDragThresholdPx) return;
      _dragStarted = true;
      _showGuide(drag.guideLeft + delta);
      return;
    }
    if (_selectionAnchorCell != null) {
      _extendCellSelection(event);
      return;
    }
    _updateResizeHover(event);
  }

  /// Sem botão pressionado: o cursor avisa quando está sobre uma divisa.
  void _updateResizeHover(DomMouseEvent event) {
    final target = event.target;
    final cellElement = target == null ? null : _ancestorCell(target);
    if (cellElement == null) {
      _setResizeHover(false);
      return;
    }
    final bounds = controller.adapter.getElementBounds(cellElement);
    final right = bounds?['right'];
    _setResizeHover(right is num &&
        (event.clientX - right).abs() <= officeColumnResizeTolerancePx);
  }

  /// Arrastar entre células: assim que o ponteiro entra numa célula
  /// DIFERENTE da âncora, a seleção deixa de ser de texto e vira o
  /// retângulo. O browser não conseguiria produzir essa seleção sozinho —
  /// e uma seleção crua entre células é justamente o que a view bloqueia
  /// para não destruir a grade.
  void _extendCellSelection(DomMouseEvent event) {
    final anchor = _selectionAnchorCell;
    if (anchor == null) return;
    // Sem botão pressionado não há arrasto (o `buttons` do DOM não está na
    // abstração; usar o alvo é suficiente porque só chegamos aqui entre um
    // pointerdown e o pointerup correspondentes).
    final target = event.target;
    if (target == null) return;
    final cellElement = _ancestorCell(target);
    if (cellElement == null) return;
    final headPos =
        int.tryParse(cellElement.getAttribute('data-doc-from') ?? '');
    if (headPos == null || headPos == anchor) return;
    event.preventDefault();
    ops.selectCellRange(
      controller.activeView.state,
      controller.dispatch,
      anchor + 1,
      headPos + 1,
    );
  }

  void handlePointerUp(DomEvent event) {
    final drag = _drag;
    _selectionAnchorCell = null;
    if (drag == null) return;
    _drag = null;
    _guide?.remove();
    _guide = null;
    final started = _dragStarted;
    _dragStarted = false;
    // Pressionou e soltou sem mover: nenhuma transação. Gravar a largura
    // "inalterada" aqui reescrevia a grade a partir da projeção e mudava o
    // documento por um clique.
    if (!started || event is! DomMouseEvent) {
      refresh();
      return;
    }
    final deltaTwips =
        (event.clientX - drag.startX).toDouble() / controller.pxPerTwip;
    final width = (drag.startWidthTwips + deltaTwips).round();
    // Mínimo de meio centímetro: uma coluna de 0 twips desaparece e não há
    // como pegá-la de volta com o ponteiro.
    if (width < 283) {
      refresh();
      return;
    }
    final state = controller.activeView.state;
    ops.setTableColumnWidth(
      state,
      controller.dispatch,
      tablePos: drag.tablePos,
      columnIndex: drag.columnIndex,
      widthTwips: width,
      // A grade das colunas que a tabela não declara vem da PROJEÇÃO: sem
      // ela sobrariam zeros no `w:tblGrid`, e o compositor descarta entradas
      // não positivas — a largura acabaria na coluna errada.
      projectedWidths: officeTableColumnWidths(
        controller.view.pageGraph,
        drag.tablePos,
        columns: OfficeTableMap.of(state.doc, drag.tablePos).columns,
      ),
    );
  }

  void _showGuide(double left) {
    var guide = _guide;
    if (guide == null) {
      guide = _kit.el('div', 'dq-office-colguide');
      controller.overlay.layer.append(guide);
      _guide = guide;
    }
    guide.setAttribute('style', 'left:${left.toStringAsFixed(1)}px;');
  }

  DomElement? _ancestorCell(DomNode node) {
    DomNode? current = node;
    while (current != null) {
      if (current is DomElement &&
          current.classes.contains('$officeCssPrefix-table-cell')) {
        return current;
      }
      if (current == controller.activeView.host) break;
      current = current.parentNode;
    }
    return null;
  }

  static double _px(Object? value) => value is num ? value.toDouble() : 0.0;
}
