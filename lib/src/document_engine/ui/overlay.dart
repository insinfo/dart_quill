/// A camada de OVERLAY do editor Word e o host único de popups.
///
/// Tudo que flutua sobre o documento — dropdowns da ribbon, paletas de cor,
/// combobox de fonte, quickbars, menu de contexto, molduras e handles de
/// objeto — vive aqui, e não solto dentro do controle que o abriu.
///
/// A razão é comportamental, não estética: um popup filho de um botão da
/// ribbon herda `overflow`, `z-index` e recorte do grupo, e o Word não tem
/// nenhum popup recortado. Com um host único também existe UMA regra de
/// fechamento (clique fora, Esc, scroll, outro popup do mesmo grupo) em vez
/// de cada controle inventar a sua — que é como aparecem os dois menus
/// abertos ao mesmo tempo.
///
/// **Nenhum popup rouba a seleção**: cada um cancela o `mousedown` no
/// próprio contêiner, então o caret do `contenteditable` continua onde
/// estava enquanto o usuário escolhe uma cor ou uma fonte.
library;

import '../../platform/dom.dart';
import 'controller.dart';

/// Onde o popup se ancora em relação ao elemento que o abriu.
enum OfficePopupPlacement {
  /// Abaixo, alinhado à esquerda do âncora (dropdowns da ribbon).
  below,

  /// Acima, centralizado no âncora (quickbar de seleção).
  aboveCentered,

  /// Nas coordenadas exatas dadas (menu de contexto).
  atPoint,

  /// ACIMA das coordenadas dadas (quickbar sobre uma seleção de texto).
  ///
  /// A altura é MEDIDA depois de anexar, não estimada: uma barra de duas
  /// linhas com altura chutada cobre exatamente o texto que o usuário
  /// acabou de selecionar.
  abovePoint,
}

/// Um popup aberto. O chamador guarda isto para fechá-lo por conta própria
/// (o normal é deixar o host fechar).
class OfficePopupHandle {
  OfficePopupHandle._(this.group, this.element, this._host,
      {this.persistent = false});

  /// Popups do MESMO grupo se excluem: abrir um fecha o outro, como as
  /// galerias da ribbon do Word.
  final String group;
  final DomElement element;

  /// Sobrevive à rolagem do documento.
  ///
  /// A regra normal é a do Word: rolar tira o popup do lugar a que ele se
  /// ancorou, então ele fecha em vez de flutuar órfão. O painel
  /// Localizar/Substituir é o contrário — ele NÃO tem âncora e é justamente
  /// ele quem manda o documento rolar até a ocorrência; fechá-lo no
  /// resultado do próprio comando seria absurdo.
  final bool persistent;

  final OfficeOverlay _host;

  bool get isOpen => _host._open.contains(this);

  void close() => _host.close(this);
}

/// A camada de overlay do editor. Uma por editor, montada pelo orquestrador.
class OfficeOverlay {
  OfficeOverlay(this.controller) : _kit = OfficeDomKit(controller.adapter);

  final OfficeWordController controller;
  final OfficeDomKit _kit;

  DomElement? _layer;
  final List<OfficePopupHandle> _open = [];

  /// Elementos "âncora" dos popups abertos: um clique dentro deles NÃO
  /// fecha o popup (senão o próprio clique que abre fecharia em seguida,
  /// pelo bubbling até o documento).
  final Map<OfficePopupHandle, DomElement?> _anchors = {};

  DomEventListener? _documentPointerDown;
  DomEventListener? _documentKeyDown;

  DomElement get layer => _layer!;
  bool get hasOpenPopups => _open.isNotEmpty;

  /// Monta a camada. Fica DEPOIS das páginas no host, sem capturar eventos
  /// onde não há popup (`pointer-events:none` na camada, `auto` no popup).
  DomElement build() {
    final layer = _kit.el('div', 'dq-office-overlay');
    _layer = layer;
    _documentPointerDown = _handleDocumentPointerDown;
    _documentKeyDown = _handleDocumentKeyDown;
    controller.adapter.document
        .addEventListener('pointerdown', _documentPointerDown!);
    controller.adapter.document.addEventListener('keydown', _documentKeyDown!);
    return layer;
  }

  /// Abre [content] como popup do [group], ancorado em [anchor] (ou em
  /// [x]/[y] com [OfficePopupPlacement.atPoint]).
  OfficePopupHandle open(
    String group,
    DomElement content, {
    DomElement? anchor,
    OfficePopupPlacement placement = OfficePopupPlacement.below,
    num? x,
    num? y,
    String? extraClass,
    bool persistent = false,
  }) {
    closeGroup(group);
    final layer = _layer;
    final popup = _kit.el(
        'div', 'dq-office-popup${extraClass == null ? '' : ' $extraClass'}');
    popup.setAttribute('data-popup-group', group);
    // A regra que mantém o caret: interagir com o popup nunca tira o foco do
    // documento, então o comando age na seleção que o usuário está vendo.
    popup.addEventListener('pointerdown', (event) => event.preventDefault());
    popup.append(content);
    layer?.append(popup);

    final handle =
        OfficePopupHandle._(group, popup, this, persistent: persistent);
    _open.add(handle);
    _anchors[handle] = anchor;
    _position(popup, anchor, placement, x, y);
    return handle;
  }

  /// Fecha e devolve true quando ALGO estava aberto — o chamador usa isso
  /// para fazer o botão alternar (clicar de novo fecha, como no Word).
  bool closeGroup(String group) {
    final matches = _open.where((handle) => handle.group == group).toList();
    for (final handle in matches) {
      close(handle);
    }
    return matches.isNotEmpty;
  }

  void close(OfficePopupHandle handle) {
    if (!_open.remove(handle)) return;
    _anchors.remove(handle);
    handle.element.remove();
  }

  void closeAll() {
    for (final handle in [..._open]) {
      close(handle);
    }
  }

  /// Fecha só o que a rolagem invalida: tudo que se ancorou num controle.
  /// Os popups [OfficePopupHandle.persistent] ficam.
  void closeTransient() {
    for (final handle in [..._open]) {
      if (handle.persistent) continue;
      close(handle);
    }
  }

  void dispose() {
    closeAll();
    final down = _documentPointerDown;
    if (down != null) {
      controller.adapter.document.removeEventListener('pointerdown', down);
    }
    final key = _documentKeyDown;
    if (key != null) {
      controller.adapter.document.removeEventListener('keydown', key);
    }
    _layer?.remove();
    _layer = null;
  }

  /// Posiciona em coordenadas da CAMADA (que cobre o host do editor), então
  /// o popup acompanha o editor mesmo dentro de uma aplicação com layout
  /// próprio. Sem geometria (VM/fake DOM) o popup fica no canto — os testes
  /// verificam existência e comportamento, nunca pixels.
  void _position(
    DomElement popup,
    DomElement? anchor,
    OfficePopupPlacement placement,
    num? x,
    num? y,
  ) {
    final layer = _layer;
    if (layer == null) return;
    double left;
    double top;
    if (placement == OfficePopupPlacement.atPoint ||
        placement == OfficePopupPlacement.abovePoint) {
      final layerBounds = controller.adapter.getElementBounds(layer);
      left = (x ?? 0).toDouble() - _numOf(layerBounds?['left']);
      top = (y ?? 0).toDouble() - _numOf(layerBounds?['top']);
      if (placement == OfficePopupPlacement.abovePoint) {
        top -= popup.offsetHeight.toDouble() + _abovePointGapPx;
      }
    } else {
      if (anchor == null) return;
      final bounds =
          controller.adapter.getElementBounds(anchor, relativeTo: layer);
      if (bounds == null) return;
      left = _numOf(bounds['left']);
      top = _numOf(bounds['top']);
      final width = _numOf(bounds['width']);
      final height = _numOf(bounds['height']);
      if (placement == OfficePopupPlacement.below) {
        top += height;
      } else {
        // aboveCentered: o quickbar do Word nasce acima e centralizado; a
        // largura real só existe depois de anexado, por isso medimos agora.
        final popupWidth = popup.offsetWidth.toDouble();
        final popupHeight = popup.offsetHeight.toDouble();
        left += (width - popupWidth) / 2;
        top -= popupHeight + 6;
      }
    }
    if (left < 0) left = 0;
    if (top < 0) top = 0;
    popup.setAttribute(
      'style',
      'left:${left.toStringAsFixed(1)}px;top:${top.toStringAsFixed(1)}px;',
    );
  }

  /// Folga entre a barra e o topo da seleção (o respiro do Word).
  static const double _abovePointGapPx = 6;

  static double _numOf(Object? value) => value is num ? value.toDouble() : 0.0;

  void _handleDocumentPointerDown(DomEvent event) {
    if (_open.isEmpty) return;
    final target = event.target;
    for (final handle in [..._open]) {
      if (_containsTarget(handle.element, target)) continue;
      if (_containsTarget(_anchors[handle], target)) continue;
      close(handle);
    }
  }

  void _handleDocumentKeyDown(DomEvent event) {
    if (_open.isEmpty || event is! DomKeyboardEvent) return;
    if (event.key != 'Escape') return;
    // Esc fecha o popup do TOPO, não todos: menus aninhados fecham um nível
    // por vez, como no Word.
    close(_open.last);
    event.preventDefault();
    event.stopPropagation();
  }

  static bool _containsTarget(DomElement? ancestor, DomNode? node) {
    if (ancestor == null || node == null) return false;
    DomNode? current = node;
    while (current != null) {
      if (current == ancestor) return true;
      current = current.parentNode;
    }
    return false;
  }
}
