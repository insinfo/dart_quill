/// Menus do editor: os dropdowns da ribbon (Margens, Orientação, Tamanho,
/// Quebras…), o menu de botão direito e as galerias que abrem sobre o
/// documento.
///
/// Um único construtor para todos porque no Word eles SÃO o mesmo controle:
/// mesma tipografia, mesmo realce, mesmo comportamento de fechamento. Cada
/// aba descreve o menu como dados ([OfficeMenuEntry]) e a montagem, o
/// posicionamento e o fechamento ficam aqui e no [OfficeOverlay].
library;

import '../../platform/dom.dart';
import 'controller.dart';
import 'overlay.dart';

/// Um item de menu. `separator` desenha a linha divisória do Word.
class OfficeMenuEntry {
  const OfficeMenuEntry({
    required this.label,
    this.description,
    this.detail,
    this.icon,
    this.onSelect,
    this.checked = false,
    this.enabled = true,
  }) : isSeparator = false;

  const OfficeMenuEntry.separator()
      : label = '',
        description = null,
        detail = null,
        icon = null,
        onSelect = null,
        checked = false,
        enabled = false,
        isSeparator = true;

  final String label;

  /// Linha secundária (o "Sup.: 2,5 cm  Inf.: 2,5 cm" do menu Margens).
  final String? description;

  /// Texto à direita: atalho no menu de contexto, medida na galeria.
  final String? detail;

  final String? icon;
  final void Function()? onSelect;

  /// Marca de seleção à esquerda (o ✓ de Hifenização/Números de Linha).
  final bool checked;

  final bool enabled;
  final bool isSeparator;
}

/// Monta o corpo do menu. Não abre nada — quem abre é [openMenu] ou o
/// chamador, via `controller.overlay.open`.
DomElement buildMenu(
  OfficeWordController controller,
  List<OfficeMenuEntry> entries, {
  String? extraClass,
}) {
  final kit = OfficeDomKit(controller.adapter);
  final menu = kit.el(
      'div', 'dq-office-menu${extraClass == null ? '' : ' $extraClass'}');
  menu.setAttribute('role', 'menu');
  for (final entry in entries) {
    if (entry.isSeparator) {
      menu.append(kit.el('div', 'dq-office-menu-sep'));
      continue;
    }
    final item = kit.el(
        'button',
        'dq-office-menu-item'
            '${entry.checked ? ' dq-office-menu-item-checked' : ''}'
            '${entry.enabled ? '' : ' dq-office-menu-item-disabled'}');
    item.setAttribute('type', 'button');
    item.setAttribute('role', 'menuitem');
    if (!entry.enabled) item.setAttribute('disabled', 'disabled');

    final mark = kit.el('span', 'dq-office-menu-mark');
    if (entry.checked) mark.appendText('✓');
    item.append(mark);

    if (entry.icon != null) {
      item.append(kit.el('span', 'dq-icon dq-icon-${entry.icon}'));
    }

    final texts = kit.el('span', 'dq-office-menu-texts');
    final label = kit.el('span', 'dq-office-menu-label');
    label.appendText(entry.label);
    texts.append(label);
    if (entry.description != null) {
      final description = kit.el('span', 'dq-office-menu-description');
      description.appendText(entry.description!);
      texts.append(description);
    }
    item.append(texts);

    if (entry.detail != null) {
      final detail = kit.el('span', 'dq-office-menu-detail');
      detail.appendText(entry.detail!);
      item.append(detail);
    }

    if (entry.enabled) {
      // Escolher um item fecha o menu ANTES de agir: a ação pode repaginar o
      // documento e mover o âncora debaixo do menu.
      item.addEventListener('click', (event) {
        event.preventDefault();
        controller.overlay.closeAll();
        controller.syncSelection();
        entry.onSelect?.call();
      });
    }
    menu.append(item);
  }
  return menu;
}

/// Abre um menu ancorado num controle da ribbon. Clicar no mesmo controle
/// de novo fecha, como no Word.
OfficePopupHandle? openMenu(
  OfficeWordController controller,
  String group,
  DomElement anchor,
  List<OfficeMenuEntry> entries, {
  String? extraClass,
}) {
  if (controller.overlay.closeGroup(group)) return null;
  return controller.overlay.open(
    group,
    buildMenu(controller, entries, extraClass: extraClass),
    anchor: anchor,
  );
}

/// Abre um menu em coordenadas de tela (menu de contexto).
OfficePopupHandle openMenuAt(
  OfficeWordController controller,
  String group,
  num x,
  num y,
  List<OfficeMenuEntry> entries, {
  String? extraClass,
}) {
  controller.overlay.closeAll();
  return controller.overlay.open(
    group,
    buildMenu(controller, entries, extraClass: extraClass),
    placement: OfficePopupPlacement.atPoint,
    x: x,
    y: y,
  );
}

/// Botão da ribbon que ABRE um menu (com a setinha do Word).
DomElement menuButton(
  OfficeWordController controller,
  String text,
  String title,
  String group,
  List<OfficeMenuEntry> Function() entries, {
  String? icon,
  String? extraClass,
}) {
  final kit = OfficeDomKit(controller.adapter);
  final wrap = kit.el(
      'span', 'dq-office-menuwrap${extraClass == null ? '' : ' $extraClass'}');
  final button = kit.button(
    text,
    title,
    // As entradas são construídas na ABERTURA, não no build da aba: itens
    // marcados (papel atual, orientação atual) precisam refletir o estado
    // de agora, não o de quando a ribbon foi montada.
    () => openMenu(controller, group, wrap, entries(), extraClass: null),
    icon: icon,
    extraClass: 'dq-office-btn-menu',
  );
  wrap.append(button);
  return wrap;
}
