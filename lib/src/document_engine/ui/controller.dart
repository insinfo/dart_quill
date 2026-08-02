/// O contrato entre o orquestrador ([OfficeWordEditor]) e os componentes do
/// chrome (ribbon, réguas, barra de status, abas).
///
/// Os componentes NUNCA falam com o motor diretamente: tudo passa por esta
/// interface. É o que mantém cada arquivo pequeno, testável isoladamente e
/// sem dependência circular de implementação — a regra do mini-framework.
library;

import 'dart:typed_data';

import '../../platform/dom.dart';
import '../layout/page_graph.dart';
import '../model/index.dart';
import '../state/index.dart';
import '../view/editor_view.dart';
import 'word_options.dart';

abstract interface class OfficeWordController {
  DomAdapter get adapter;
  Schema get schema;
  OfficeWordEditorOptions get options;

  /// O laço de edição. Só é válido depois de [viewReady].
  OfficeEditorView get view;

  /// A ribbon nasce ANTES da view (a ordem visual do chrome manda); os
  /// refreshes de estado só valem quando isto for true.
  bool get viewReady;

  /// Geometria corrente (a aba Layout a altera).
  PageSetupTwips get pageSetup;

  double get zoom;
  double get pxPerTwip;

  void dispatch(Transaction tr);
  bool runCommand(String name);

  /// Puxa a seleção nativa para o modelo (guardada pelo host da view).
  void syncSelection();

  /// O mapa `style` do bloco corrente, ou null.
  Map? currentBlockStyle();

  /// Grava chaves de apresentação nos blocos da seleção — o mesmo mapa
  /// PARCIAL da cascata de estilos, então nada além do que foi pedido muda.
  void applyBlockStyle(Map<String, dynamic> patch);

  void setZoom(double zoom);
  void setPageSetup(PageSetupTwips setup);

  Uint8List exportPdf();
  Uint8List exportDocx();
}

/// Helpers de construção de DOM compartilhados pelos componentes.
///
/// Não é um framework de verdade — é o mínimo que evita cada componente
/// reinventar `createElement` + classes + listeners.
final class OfficeDomKit {
  const OfficeDomKit(this.adapter);

  final DomAdapter adapter;

  DomElement el(String tag, String cssClass) {
    final element = adapter.document.createElement(tag);
    if (cssClass.isNotEmpty) {
      for (final name in cssClass.split(' ')) {
        element.classes.add(name);
      }
    }
    return element;
  }

  void setText(DomElement element, String text) {
    while (element.firstChild != null) {
      element.firstChild!.remove();
    }
    element.appendText(text);
  }

  void clear(DomElement element) {
    while (element.firstChild != null) {
      element.firstChild!.remove();
    }
  }

  /// Botão da ribbon. Com [icon], o botão exibe a classe `dq-icon-<icon>`
  /// do stylesheet de ícones e o TEXTO vira fallback: o CSS de ícones o
  /// esconde quando o ícone existe, e sem o stylesheet o texto aparece —
  /// o consumidor pode trocar (ou omitir) o asset de ícones livremente.
  DomElement button(String text, String title, void Function() action,
      {String? extraClass, String? icon}) {
    final button =
        el('button', 'dq-office-btn${extraClass == null ? '' : ' $extraClass'}');
    button.setAttribute('type', 'button');
    button.setAttribute('title', title);
    button.setAttribute('aria-label', title);
    if (icon != null) {
      button.append(el('span', 'dq-icon dq-icon-$icon'));
      final label = el('span', 'dq-office-btn-text');
      label.appendText(text);
      button.append(label);
    } else {
      button.appendText(text);
    }
    button.addEventListener('click', (event) {
      event.preventDefault();
      action();
    });
    return button;
  }

  DomElement select(String cssClass, List<String> items, String selected,
      void Function(String value) onChange) {
    final select = el('select', 'dq-office-select $cssClass');
    for (final item in items) {
      final option = el('option', '');
      option.setAttribute('value', item);
      if (item == selected) option.setAttribute('selected', 'selected');
      option.appendText(item);
      select.append(option);
    }
    select.addEventListener('change', (_) => onChange(select.value));
    return select;
  }

  DomElement group(String label, List<DomElement> rows) {
    final group = el('div', 'dq-office-ribbon-group');
    group.setAttribute('data-group-label', label);
    final content = el('div', 'dq-office-ribbon-rows');
    for (final row in rows) {
      content.append(row);
    }
    group.append(content);
    return group;
  }

  DomElement row(List<DomElement> controls) {
    final row = el('div', 'dq-office-ribbon-row');
    for (final control in controls) {
      row.append(control);
    }
    return row;
  }
}
