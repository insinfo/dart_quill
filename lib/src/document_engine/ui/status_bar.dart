/// Barra de status do editor Word: página corrente, palavras e zoom.
///
/// Como no Word: faixa clara e baixa, "Página X de Y" e contagem de
/// palavras à esquerda, slider de zoom (−/+) com o percentual à direita.
library;

import '../../platform/dom.dart';
import '../model/index.dart' show PMNode;
import 'controller.dart';
import 'word_options.dart';

class OfficeStatusBar {
  OfficeStatusBar(this.controller) : _kit = OfficeDomKit(controller.adapter);

  final OfficeWordController controller;
  final OfficeDomKit _kit;

  DomElement? _page;
  DomElement? _words;
  DomElement? _zoomSlider;
  DomElement? _zoomLabel;

  /// Contagem de palavras cacheada por identidade do documento: contar
  /// 78 mil palavras a cada clique custaria uma travessia completa da
  /// árvore por interação.
  PMNode? _countedDoc;
  int _wordCount = 0;

  static final RegExp _wordPattern = RegExp(r'\S+');

  DomElement build() {
    final bar = _kit.el('div', 'dq-office-statusbar');
    _page = _kit.el('span', 'dq-office-status-item');
    bar.append(_page!);
    _words = _kit.el('span', 'dq-office-status-item');
    bar.append(_words!);

    if (controller.options.mode == OfficeWordMode.word) {
      bar.append(_kit.el('span', 'dq-office-status-spacer'));
      bar.append(_buildZoomControl());
    }
    return bar;
  }

  /// Slider de zoom do Word: − trilho +, e o percentual clicável ao lado.
  /// `input` só atualiza o rótulo; a REPROJEÇÃO acontece no `change`
  /// (soltar o cursor) — remontar 140 páginas a cada pixel de arrasto
  /// travaria o arrasto.
  DomElement _buildZoomControl() {
    final wrap = _kit.el('div', 'dq-office-zoom');

    final minus = _kit.el('button', 'dq-office-zoom-step');
    minus.setAttribute('type', 'button');
    minus.setAttribute('title', 'Reduzir zoom');
    minus.appendText('−');
    minus.addEventListener('click', (_) => _stepZoom(-10));
    wrap.append(minus);

    final slider = _kit.el('input', 'dq-office-zoom-slider');
    slider.setAttribute('type', 'range');
    slider.setAttribute('min', '50');
    slider.setAttribute('max', '200');
    slider.setAttribute('step', '10');
    slider.setAttribute('title', 'Zoom');
    slider.value = '${(controller.zoom * 100).round()}';
    slider.addEventListener('input', (_) => _updateZoomLabel());
    slider.addEventListener('change', (_) => _applySliderZoom());
    _zoomSlider = slider;
    wrap.append(slider);

    final plus = _kit.el('button', 'dq-office-zoom-step');
    plus.setAttribute('type', 'button');
    plus.setAttribute('title', 'Ampliar zoom');
    plus.appendText('+');
    plus.addEventListener('click', (_) => _stepZoom(10));
    wrap.append(plus);

    _zoomLabel = _kit.el('span', 'dq-office-zoom-label');
    _kit.setText(_zoomLabel!, '${(controller.zoom * 100).round()}%');
    wrap.append(_zoomLabel!);
    return wrap;
  }

  void _stepZoom(int deltaPercent) {
    final current = (controller.zoom * 100).round();
    final next = (current + deltaPercent).clamp(50, 200);
    if (next == current) return;
    _zoomSlider?.value = '$next';
    _updateZoomLabel();
    controller.setZoom(next / 100);
  }

  void _applySliderZoom() {
    final value = int.tryParse(_zoomSlider?.value ?? '');
    if (value == null) return;
    _updateZoomLabel();
    controller.setZoom(value.clamp(50, 200) / 100);
  }

  void _updateZoomLabel() {
    final label = _zoomLabel;
    if (label == null) return;
    final value = int.tryParse(_zoomSlider?.value ?? '');
    if (value != null) _kit.setText(label, '$value%');
  }

  void update() {
    if (_page == null || !controller.viewReady) return;
    final graph = controller.view.pageGraph;
    final current = controller.view.visiblePageIndex + 1;
    _kit.setText(_page!, 'Página $current de ${graph.pages.length}');
    final doc = controller.view.state.doc;
    if (!identical(doc, _countedDoc)) {
      _countedDoc = doc;
      _wordCount = _wordPattern.allMatches(doc.textContent).length;
    }
    _kit.setText(_words!, '$_wordCount palavras');
  }
}
