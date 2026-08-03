/// A ribbon do editor Word: abas, painel de grupos, aba CONTEXTUAL de
/// tabela e o realce de estado (B aceso quando a seleção está em negrito).
///
/// Cada aba constrói seus grupos em `tabs/*.dart`; a ribbon só orquestra —
/// registro de abas, troca de painel, visibilidade contextual e reflexo do
/// estado do modelo nos controles.
library;

import '../../platform/dom.dart';
import 'controller.dart';
import 'table_ops.dart' as table_ops;
import 'tabs/file_tab.dart';
import 'tabs/home_tab.dart';
import 'tabs/insert_tab.dart';
import 'tabs/layout_tab.dart';
import 'tabs/table_tab.dart';

/// O que um builder de aba recebe: o controlador, o kit de DOM e os
/// registradores de controles com estado (botões de marca, select de
/// estilos).
final class RibbonContext {
  RibbonContext(this.controller, this.kit, this._ribbon);

  final OfficeWordController controller;
  final OfficeDomKit kit;
  final OfficeRibbon _ribbon;

  /// Botão de marca (negrito, itálico…): roda o MESMO comando do atalho e
  /// fica registrado para o realce de estado.
  DomElement markButton(String mark, String text, String title, String cssClass,
      {String? icon}) {
    final button = kit.button(
        text, title, () => _ribbon.controller.runCommand(mark),
        extraClass: cssClass, icon: icon);
    _ribbon._markButtons[mark] = button;
    return button;
  }

  void registerStyleSelect(DomElement select) {
    _ribbon._styleSelect = select;
  }

  /// Select cujo valor acompanha uma marca com atributo `value` (família e
  /// tamanho da fonte). A seleção nativa é sincronizada antes de cada ação,
  /// e o `selectionchange` atualiza estes controles sem editar o documento.
  void registerMarkValueSelect(
      String mark, DomElement select, String fallback) {
    _ribbon._markValueSelects[mark] = (element: select, fallback: fallback);
  }

  /// Botão de uma variante de marca (subscrito/sobrescrito).
  void registerMarkValueButton(String mark, String value, DomElement button) {
    _ribbon._markValueButtons[(mark: mark, value: value)] = button;
  }

  /// Cartão da GALERIA de estilos (Normal, Título 1…): registrado para o
  /// realce do estilo do bloco corrente.
  void registerStyleCard(String name, DomElement card) {
    _ribbon._styleCards[name] = card;
  }
}

class OfficeRibbon {
  OfficeRibbon(this.controller) : kit = OfficeDomKit(controller.adapter);

  final OfficeWordController controller;
  final OfficeDomKit kit;

  final Map<String, DomElement> _tabs = {};
  final Map<String, DomElement> _markButtons = {};
  final Map<String, ({DomElement element, String fallback})> _markValueSelects =
      {};
  final Map<({String mark, String value}), DomElement> _markValueButtons = {};
  final Map<String, DomElement> _styleCards = {};
  DomElement? _styleSelect;
  DomElement? _body;

  /// A ribbon completa (modo word), com abas.
  DomElement build() {
    final ribbon = kit.el('div', 'dq-office-ribbon');

    final tabs = kit.el('div', 'dq-office-ribbon-tabs');
    for (final (key, label) in const [
      ('file', 'Arquivo'),
      ('home', 'Página Inicial'),
      ('insert', 'Inserir'),
      ('layout', 'Layout'),
      ('table', 'Tabela'),
    ]) {
      final tab = kit.el('button', 'dq-office-ribbon-tab');
      tab.setAttribute('type', 'button');
      tab.appendText(label);
      _tabs[key] = tab;
      if (key == 'table') {
        // Contextual: só existe enquanto a seleção está numa tabela.
        tab.classes.add('dq-office-ribbon-tab-contextual');
        tab.classes.add('dq-office-ribbon-tab-hidden');
      }
      tab.addEventListener('click', (_) => showTab(key));
      tabs.append(tab);
    }
    ribbon.append(tabs);

    _body = kit.el('div', 'dq-office-ribbon-content');
    ribbon.append(_body!);
    showTab('home');
    return ribbon;
  }

  /// A toolbar compacta do modo flow: uma linha, sem abas.
  DomElement buildCompact() {
    final ribbon = kit.el('div', 'dq-office-ribbon');
    final content = kit.el('div', 'dq-office-ribbon-compact');
    final context = RibbonContext(controller, kit, this);
    for (final control in buildCompactControls(context)) {
      content.append(control);
    }
    ribbon.append(content);
    return ribbon;
  }

  void showTab(String key) {
    final body = _body;
    if (body == null) return;
    _tabs.forEach((tabKey, tab) {
      if (tabKey == key) {
        tab.classes.add('dq-office-ribbon-tab-active');
      } else {
        tab.classes.remove('dq-office-ribbon-tab-active');
      }
    });
    kit.clear(body);
    _markButtons.clear();
    _markValueSelects.clear();
    _markValueButtons.clear();
    _styleCards.clear();
    _styleSelect = null;

    final context = RibbonContext(controller, kit, this);
    final groups = switch (key) {
      'layout' => buildLayoutTab(context),
      'insert' => buildInsertTab(context),
      'file' => buildFileTab(context),
      'table' => buildTableTab(context),
      _ => buildHomeTab(context),
    };
    for (final group in groups) {
      body.append(group);
    }
    refreshState();
  }

  /// A shell é CONTEXTUAL: a aba Tabela existe enquanto a seleção está numa
  /// tabela e some fora — voltando para Página Inicial se estava ativa.
  void refreshContextual() {
    final tab = _tabs['table'];
    if (tab == null || !controller.viewReady) return;
    final inTable = table_ops.tableDepthOf(controller.view.state) != null;
    if (inTable) {
      tab.classes.remove('dq-office-ribbon-tab-hidden');
    } else {
      tab.classes.add('dq-office-ribbon-tab-hidden');
      if (tab.classes.contains('dq-office-ribbon-tab-active')) {
        showTab('home');
      }
    }
  }

  /// Acende os botões conforme a seleção. Leitura pura do estado: a UI
  /// reflete o modelo, nunca o contrário.
  void refreshState() {
    if (!controller.viewReady) return;
    final state = controller.view.state;
    final selection = state.selection;

    bool activeFor(String name) {
      final type = controller.schema.marks[name];
      if (type == null) return false;
      if (selection.empty) {
        // No caret valem as storedMarks — o que a PRÓXIMA digitação usará.
        final marks = state.storedMarks ?? selection.fromRes.marks();
        return marks.any((mark) => mark.type == type);
      }
      return state.doc.rangeHasMark(selection.from, selection.to, type);
    }

    _markButtons.forEach((name, button) {
      if (activeFor(name)) {
        button.classes.add('dq-office-btn-active');
      } else {
        button.classes.remove('dq-office-btn-active');
      }
    });

    String? markValue(String name) {
      final type = controller.schema.marks[name];
      if (type == null) return null;
      final marks = selection.empty
          ? (state.storedMarks ?? selection.fromRes.marks())
          : state.doc.resolve(selection.from + 1).marks();
      for (final mark in marks) {
        if (mark.type == type) return mark.attrs['value'] as String?;
      }
      return null;
    }

    _markValueSelects.forEach((name, control) {
      var value = markValue(name) ?? control.fallback;
      if (name == 'size') value = value.replaceAll('pt', '');
      control.element.value = value;
    });

    _markValueButtons.forEach((key, button) {
      if (markValue(key.mark) == key.value) {
        button.classes.add('dq-office-btn-active');
      } else {
        button.classes.remove('dq-office-btn-active');
      }
    });

    final block = selection.fromRes.parent;
    final level = block.type.name == 'heading' ? block.attrs['level'] : null;
    final current =
        level is int && level >= 1 && level <= 3 ? 'Título $level' : 'Normal';

    final style = _styleSelect;
    if (style != null) style.value = current;

    _styleCards.forEach((name, card) {
      if (name == current) {
        card.classes.add('dq-office-stylecard-active');
      } else {
        card.classes.remove('dq-office-stylecard-active');
      }
    });
  }
}
