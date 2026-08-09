/// Barra de status do editor Word: página corrente, blocos e zoom.
library;

import '../../platform/dom.dart';
import 'controller.dart';
import 'word_options.dart';

class OfficeStatusBar {
  OfficeStatusBar(this.controller) : _kit = OfficeDomKit(controller.adapter);

  final OfficeWordController controller;
  final OfficeDomKit _kit;

  DomElement? _page;
  DomElement? _blocks;

  DomElement build() {
    final bar = _kit.el('div', 'dq-office-statusbar');
    _page = _kit.el('span', 'dq-office-status-item');
    bar.append(_page!);
    _blocks = _kit.el('span', 'dq-office-status-item');
    bar.append(_blocks!);

    if (controller.options.mode == OfficeWordMode.word) {
      bar.append(_kit.el('span', 'dq-office-status-spacer'));
      bar.append(_kit.select(
        'dq-office-zoom',
        const ['50%', '75%', '100%', '125%', '150%', '200%'],
        '${(controller.options.zoom * 100).round()}%',
        (value) =>
            controller.setZoom(int.parse(value.replaceAll('%', '')) / 100),
      ));
    }
    return bar;
  }

  void update() {
    if (_page == null || !controller.viewReady) return;
    final graph = controller.view.pageGraph;
    final current = controller.view.visiblePageIndex + 1;
    _kit.setText(_page!, 'Página $current de ${graph.pages.length}');
    _kit.setText(_blocks!, '${controller.view.state.doc.childCount} blocos');
  }
}
