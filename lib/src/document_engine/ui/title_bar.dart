/// Title bar do editor Word — opcional ([OfficeWordEditorOptions.showTitleBar]).
library;

import '../../platform/dom.dart';
import 'controller.dart';

class OfficeTitleBar {
  OfficeTitleBar(this.controller) : _kit = OfficeDomKit(controller.adapter);

  final OfficeWordController controller;
  final OfficeDomKit _kit;

  DomElement build() {
    final bar = _kit.el('div', 'dq-office-titlebar');

    final brand = _kit.el('div', 'dq-office-brand');
    final mark = _kit.el('div', 'dq-office-brand-mark');
    for (var i = 0; i < 3; i++) {
      mark.append(_kit.el('i', ''));
    }
    brand.append(mark);
    final name = _kit.el('span', '');
    name.appendText('Word');
    brand.append(name);
    bar.append(brand);

    final title = _kit.el('div', 'dq-office-doc-title');
    title.appendText(controller.documentBaseName);
    bar.append(title);

    bar.append(_kit.el('div', 'dq-office-titlebar-actions'));
    return bar;
  }
}
