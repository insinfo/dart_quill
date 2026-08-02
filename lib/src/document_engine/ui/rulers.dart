/// Réguas horizontal e vertical do editor Word.
///
/// Comportamento de referência (shell do docx_rendering / DocumentServer):
/// banda com a área útil branca sobre trilho cinza, tick de 0,25 cm, tick
/// médio de 0,5 cm, número por centímetro CONTADO A PARTIR DA MARGEM, caixa
/// de canto (seletor de tabulação) e marcadores de recuo ARRASTÁVEIS —
/// primeira linha no topo, recuo esquerdo embaixo, recuo direito na margem
/// direita.
///
/// O alinhamento com a página é estrutural: o centro da régua tem a largura
/// exata da página e compartilha a centralização do canvas, então nenhum
/// JavaScript de medição é necessário e o zoom realinha sozinho.
library;

import '../../platform/dom.dart';
import 'controller.dart';

const int _quarterCmTwips = 142; // 0,25 cm

class OfficeHorizontalRuler {
  OfficeHorizontalRuler(this.controller) : _kit = OfficeDomKit(controller.adapter);

  final OfficeWordController controller;
  final OfficeDomKit _kit;

  DomElement? _first;
  DomElement? _left;
  DomElement? _right;

  /// Drag de marcador em curso: tipo, X inicial e valor inicial em twips.
  ({String kind, num startX, int startTwips})? _drag;

  DomElement build() {
    double px(int twips) => twips * controller.pxPerTwip;
    final setup = controller.pageSetup;

    final track = _kit.el('div', 'dq-office-ruler');
    final center = _kit.el('div', 'dq-office-ruler-center');
    center.setAttribute('style', 'width:${px(setup.widthTwips)}px;');

    final corner = _kit.el('div', 'dq-office-ruler-corner');
    corner.appendText('L');
    center.append(corner);

    final band = _kit.el('div', 'dq-office-ruler-band');
    final content = _kit.el('div', 'dq-office-ruler-content');
    content.setAttribute(
        'style',
        'left:${px(setup.marginLeftTwips)}px;'
        'width:${px(setup.contentWidthTwips)}px;');
    band.append(content);
    center.append(band);

    final totalQuarters = setup.widthTwips ~/ _quarterCmTwips;
    for (var q = 1; q < totalQuarters; q++) {
      final twips = q * _quarterCmTwips;
      final sinceMargin = twips - setup.marginLeftTwips;
      if (q % 4 == 0) {
        final cm = sinceMargin ~/ (_quarterCmTwips * 4);
        final insideContent = sinceMargin > 0 &&
            twips < setup.widthTwips - setup.marginRightTwips &&
            cm >= 1;
        if (insideContent) {
          final number = _kit.el('span', 'dq-office-ruler-number');
          number.setAttribute('style', 'left:${px(twips)}px;');
          number.appendText('$cm');
          center.append(number);
          continue;
        }
      }
      final tick = _kit.el(
          'span',
          q.isEven
              ? 'dq-office-ruler-tick dq-office-ruler-tick-half'
              : 'dq-office-ruler-tick');
      tick.setAttribute('style', 'left:${px(twips)}px;');
      center.append(tick);
    }

    _first = _marker('dq-office-indent-first', 'Recuo da primeira linha', 'first');
    _left = _marker('dq-office-indent-left', 'Recuo à esquerda', 'left');
    _right = _marker('dq-office-indent-right', 'Recuo à direita', 'right');
    center.append(_first!);
    center.append(_left!);
    center.append(_right!);

    track.append(center);
    positionMarkers();
    return track;
  }

  DomElement _marker(String cssClass, String title, String kind) {
    final marker = _kit.el('span', 'dq-office-indent $cssClass');
    marker.setAttribute('title', title);
    marker.addEventListener('pointerdown', (event) {
      if (event is! DomMouseEvent) return;
      event.preventDefault();
      controller.syncSelection();
      final style = controller.currentBlockStyle();
      _drag = (
        kind: kind,
        startX: event.clientX,
        startTwips: _styleInt(style, _keyOf(kind)),
      );
    });
    return marker;
  }

  static String _keyOf(String kind) => switch (kind) {
        'first' => 'firstLineIndentTwips',
        'right' => 'rightIndentTwips',
        _ => 'indentTwips',
      };

  static int _styleInt(Map? style, String key) =>
      style?[key] is num ? (style![key] as num).toInt() : 0;

  /// Chamado pelo orquestrador nos pointermove/pointerup do canvas.
  void handlePointerMove(DomEvent event) {
    final drag = _drag;
    if (drag == null || event is! DomMouseEvent) return;
    event.preventDefault();
    positionMarkers(
        override: (kind: drag.kind, twips: _dragValue(drag, event.clientX)));
  }

  void handlePointerUp(DomEvent event) {
    final drag = _drag;
    if (drag == null || event is! DomMouseEvent) return;
    _drag = null;
    controller
        .applyBlockStyle({_keyOf(drag.kind): _dragValue(drag, event.clientX)});
  }

  /// O valor em twips durante/apos o arrasto, com os limites do Word: nada
  /// sai da área útil e recuo esquerdo + primeira linha nunca fica negativo
  /// em relação à margem.
  int _dragValue(({String kind, num startX, int startTwips}) drag, num x) {
    final deltaTwips = ((x - drag.startX) / controller.pxPerTwip).round() *
        (drag.kind == 'right' ? -1 : 1);
    var value = drag.startTwips + deltaTwips;
    final style = controller.currentBlockStyle();
    final content = controller.pageSetup.contentWidthTwips;
    switch (drag.kind) {
      case 'left':
        final first = _styleInt(style, 'firstLineIndentTwips');
        value = value.clamp(first < 0 ? -first : 0, content - 567);
      case 'first':
        final left = _styleInt(style, 'indentTwips');
        value = value.clamp(-left, content - left - 567);
      default: // right
        value = value.clamp(0, content - 567);
    }
    return value;
  }

  /// Posiciona os marcadores conforme o parágrafo corrente (ou o valor de
  /// um arrasto em curso, para feedback imediato).
  void positionMarkers({({String kind, int twips})? override}) {
    if (_left == null || !controller.viewReady) return;
    double px(int twips) => twips * controller.pxPerTwip;
    final setup = controller.pageSetup;
    final style = controller.currentBlockStyle();
    int value(String kind) => override != null && override.kind == kind
        ? override.twips
        : _styleInt(style, _keyOf(kind));

    final left = value('left');
    final first = value('first');
    final right = value('right');
    _left!.setAttribute(
        'style', 'left:${px(setup.marginLeftTwips + left)}px;');
    _first!.setAttribute(
        'style', 'left:${px(setup.marginLeftTwips + left + first)}px;');
    _right!.setAttribute('style',
        'left:${px(setup.widthTwips - setup.marginRightTwips - right)}px;');
  }
}

class OfficeVerticalRuler {
  OfficeVerticalRuler(this.controller) : _kit = OfficeDomKit(controller.adapter);

  final OfficeWordController controller;
  final OfficeDomKit _kit;

  DomElement build() {
    double px(int twips) => twips * controller.pxPerTwip;
    final setup = controller.pageSetup;

    final ruler = _kit.el('div', 'dq-office-vruler');
    // Encostada à esquerda da página centrada: o offset é -(largura da
    // página)/2 - largura da régua - respiro.
    ruler.setAttribute(
        'style', 'margin-left:${-(px(setup.widthTwips) / 2 + 30)}px;');
    final track = _kit.el('div', 'dq-office-vruler-track');
    track.setAttribute('style', 'height:${px(setup.heightTwips)}px;');

    final content = _kit.el('div', 'dq-office-vruler-content');
    content.setAttribute(
        'style',
        'top:${px(setup.marginTopTwips)}px;'
        'height:${px(setup.contentHeightTwips)}px;');
    track.append(content);

    final totalQuarters = setup.heightTwips ~/ _quarterCmTwips;
    for (var q = 1; q < totalQuarters; q++) {
      final twips = q * _quarterCmTwips;
      final sinceMargin = twips - setup.marginTopTwips;
      if (q % 4 == 0) {
        final cm = sinceMargin ~/ (_quarterCmTwips * 4);
        final insideContent = sinceMargin > 0 &&
            twips < setup.heightTwips - setup.marginBottomTwips &&
            cm >= 1;
        if (insideContent) {
          final number = _kit.el('span', 'dq-office-vruler-number');
          number.setAttribute('style', 'top:${px(twips)}px;');
          number.appendText('$cm');
          track.append(number);
          continue;
        }
      }
      final tick = _kit.el(
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
}
