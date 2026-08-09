/// A moldura de seleção de OBJETO (imagem, caixa de texto) com as oito
/// âncoras de redimensionamento do Word.
///
/// O objeto selecionado não é um intervalo de texto: é um nó. O motor já
/// tem [NodeSelection] para isso; o que faltava era a parte visível — a
/// moldura, as alças e o arrasto que as transforma numa transação.
///
/// Duas decisões que evitam bugs conhecidos:
///
/// * **A projeção não é reconstruída durante o arrasto.** Enquanto a alça se
///   move, só o adorno muda (e um retângulo-guia). A transação sai UMA vez,
///   no `pointerup` — a mesma regra que vale para a composição IME, e o que
///   impede o DOM de ser recomposto embaixo do ponteiro que o usuário está
///   arrastando.
/// * **A geometria vem do DOM projetado**, não de um cálculo paralelo em
///   twips: o objeto já está desenhado, e medir o que está na tela é a única
///   fonte que não pode divergir do que o usuário vê.
library;

import '../../platform/dom.dart';
import '../layout/dom_position_map.dart';
import '../layout/dom_renderer.dart';
import '../model/index.dart';
import '../state/index.dart';
import 'controller.dart';

/// As oito alças, na ordem em que o Word as desenha.
const List<String> _handleKinds = ['nw', 'n', 'ne', 'e', 'se', 's', 'sw', 'w'];

/// Tipos de nó que aceitam moldura/alças.
const Set<String> officeResizableNodeTypes = {'image', 'textBox'};

class OfficeObjectAdorner {
  OfficeObjectAdorner(this.controller)
      : _kit = OfficeDomKit(controller.adapter);

  final OfficeWordController controller;
  final OfficeDomKit _kit;
  static const OfficeDomPositionMap _positions = OfficeDomPositionMap();

  DomElement? _frame;
  final Map<String, DomElement> _handles = {};

  /// Arrasto em curso: alça, ponto inicial, retângulo inicial (px) e a
  /// posição do nó no modelo (que não muda durante o arrasto).
  ({
    String kind,
    num startX,
    num startY,
    double left,
    double top,
    double width,
    double height,
    int nodePos,
    PMNode node,
  })? _drag;

  bool get isDragging => _drag != null;

  /// Redesenha o adorno para a seleção corrente. Chamado a cada refresh do
  /// editor e no scroll do canvas (a camada de overlay não rola junto com as
  /// páginas, então a moldura precisa reacompanhar).
  void refresh() {
    if (_drag != null) return; // durante o arrasto quem manda é o ponteiro
    final target = selectedObject();
    if (target == null) {
      clear();
      return;
    }
    final element = elementFor(target.pos);
    if (element == null) {
      clear();
      return;
    }
    final bounds = controller.adapter
        .getElementBounds(element, relativeTo: controller.overlay.layer);
    if (bounds == null) {
      clear();
      return;
    }
    _ensureFrame();
    _place(
      _numOf(bounds['left']),
      _numOf(bounds['top']),
      _numOf(bounds['width']),
      _numOf(bounds['height']),
    );
  }

  void clear() {
    _frame?.remove();
    _frame = null;
    _handles.clear();
  }

  /// O nó de objeto selecionado agora, ou null.
  ({int pos, PMNode node})? selectedObject() {
    if (!controller.viewReady) return null;
    final selection = controller.view.state.selection;
    if (selection is! NodeSelection) return null;
    if (!officeResizableNodeTypes.contains(selection.node.type.name)) {
      return null;
    }
    return (pos: selection.from, node: selection.node);
  }

  /// O elemento projetado do objeto que começa em [pos].
  ///
  /// A busca é pela projeção porque é ela que tem a geometria; o mapa de
  /// posições faz a ponte de volta. Só existem alguns objetos por página, e
  /// a virtualização já limitou o DOM montado.
  DomElement? elementFor(int pos) {
    final host = controller.view.host;
    for (final selector in const [
      '.$officeCssPrefix-image',
      '.$officeCssPrefix-text-box',
    ]) {
      for (final element in host.querySelectorAll(selector)) {
        if (_positions.modelPositionAt(element, 0) == pos) return element;
      }
    }
    return null;
  }

  void _ensureFrame() {
    if (_frame != null) return;
    final frame = _kit.el('div', 'dq-office-objframe');
    for (final kind in _handleKinds) {
      final handle =
          _kit.el('div', 'dq-office-objhandle dq-office-objhandle-$kind');
      handle.setAttribute('data-handle', kind);
      handle.addEventListener(
          'pointerdown', (event) => _startDrag(kind, event));
      _handles[kind] = handle;
      frame.append(handle);
    }
    _frame = frame;
    controller.overlay.layer.append(frame);
  }

  void _place(double left, double top, double width, double height) {
    _frame?.setAttribute(
      'style',
      'left:${left.toStringAsFixed(1)}px;top:${top.toStringAsFixed(1)}px;'
          'width:${width.toStringAsFixed(1)}px;'
          'height:${height.toStringAsFixed(1)}px;',
    );
  }

  void _startDrag(String kind, DomEvent event) {
    final target = selectedObject();
    final frame = _frame;
    if (target == null || frame == null || event is! DomMouseEvent) return;
    final element = elementFor(target.pos);
    if (element == null) return;
    final bounds = controller.adapter
        .getElementBounds(element, relativeTo: controller.overlay.layer);
    if (bounds == null) return;
    event.preventDefault();
    _drag = (
      kind: kind,
      startX: event.clientX,
      startY: event.clientY,
      left: _numOf(bounds['left']),
      top: _numOf(bounds['top']),
      width: _numOf(bounds['width']),
      height: _numOf(bounds['height']),
      nodePos: target.pos,
      node: target.node,
    );
    frame.classes.add('dq-office-objframe-dragging');
  }

  /// Chamado pelo orquestrador no `pointermove` do canvas: só desenha.
  void handlePointerMove(DomEvent event) {
    final drag = _drag;
    if (drag == null || event is! DomMouseEvent) return;
    event.preventDefault();
    final size =
        _sizeFor(drag, event.clientX, event.clientY, keepRatio: event.shiftKey);
    _place(
      // Alças do lado esquerdo/superior movem a borda oposta; a moldura
      // acompanha para o feedback bater com o resultado.
      drag.kind.contains('w')
          ? drag.left + (drag.width - size.width)
          : drag.left,
      drag.kind.contains('n')
          ? drag.top + (drag.height - size.height)
          : drag.top,
      size.width,
      size.height,
    );
  }

  /// `pointerup`: UMA transação com o tamanho final.
  void handlePointerUp(DomEvent event) {
    final drag = _drag;
    if (drag == null) return;
    _drag = null;
    _frame?.classes.remove('dq-office-objframe-dragging');
    if (event is! DomMouseEvent) {
      refresh();
      return;
    }
    final size =
        _sizeFor(drag, event.clientX, event.clientY, keepRatio: event.shiftKey);
    if (size.width == drag.width && size.height == drag.height) {
      refresh();
      return;
    }
    resizeTo(
      drag.nodePos,
      drag.node,
      widthPx: size.width,
      heightPx: size.height,
    );
  }

  /// Grava o tamanho no modelo (twips), preservando a seleção do nó.
  ///
  /// Público porque o mesmo caminho serve ao diálogo de tamanho e aos testes
  /// — que não têm ponteiro, mas precisam exercitar a transação real.
  void resizeTo(
    int pos,
    PMNode node, {
    required double widthPx,
    required double heightPx,
  }) {
    final pxPerTwip = controller.pxPerTwip;
    if (pxPerTwip <= 0) return;
    final widthTwips = (widthPx / pxPerTwip).round();
    final heightTwips = (heightPx / pxPerTwip).round();
    if (widthTwips <= 0 || heightTwips <= 0) return;
    final state = controller.view.state;
    final tr = state.tr;
    tr.setNodeMarkup(pos, null, {
      ...node.attrs,
      'width': widthTwips,
      'height': heightTwips,
    });
    // A seleção continua no NÓ: redimensionar não é motivo para o usuário
    // perder o objeto que estava manipulando.
    tr.setSelection(NodeSelection.create(tr.doc, pos));
    controller.dispatch(tr);
  }

  /// O tamanho durante/depois do arrasto. Shift mantém a proporção — e as
  /// alças de aresta (n/s/e/w) só mudam uma dimensão, como no Word.
  ({double width, double height}) _sizeFor(
    ({
      String kind,
      num startX,
      num startY,
      double left,
      double top,
      double width,
      double height,
      int nodePos,
      PMNode node,
    }) drag,
    num x,
    num y, {
    required bool keepRatio,
  }) {
    final dx = (x - drag.startX).toDouble();
    final dy = (y - drag.startY).toDouble();
    var width = drag.width;
    var height = drag.height;
    if (drag.kind.contains('e')) width = drag.width + dx;
    if (drag.kind.contains('w')) width = drag.width - dx;
    if (drag.kind.contains('s')) height = drag.height + dy;
    if (drag.kind.contains('n')) height = drag.height - dy;

    const minimum = 8.0;
    if (width < minimum) width = minimum;
    if (height < minimum) height = minimum;

    // Alça de CANTO com Shift (ou proporção travada): a dimensão dominante
    // manda e a outra segue o aspecto original.
    final isCorner = drag.kind.length == 2;
    if (keepRatio && isCorner && drag.width > 0 && drag.height > 0) {
      final ratio = drag.height / drag.width;
      if ((width - drag.width).abs() >= (height - drag.height).abs()) {
        height = width * ratio;
      } else {
        width = height / ratio;
      }
    }
    return (width: width, height: height);
  }

  static double _numOf(Object? value) => value is num ? value.toDouble() : 0.0;
}
