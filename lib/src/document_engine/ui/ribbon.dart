/// A ribbon do editor Word: abas, painel de grupos, aba CONTEXTUAL de
/// tabela e o realce de estado (B aceso quando a seleção está em negrito).
///
/// Cada aba constrói seus grupos em `tabs/*.dart`; a ribbon só orquestra —
/// registro de abas, troca de painel, visibilidade contextual e reflexo do
/// estado do modelo nos controles.
library;

import '../../platform/dom.dart';
import 'controller.dart';
import 'ribbon_actions.dart' as actions;
import 'table_ops.dart' as table_ops;
import 'tabs/file_tab.dart';
import 'tabs/header_footer_tab.dart';
import 'tabs/home_tab.dart';
import 'tabs/insert_tab.dart';
import 'tabs/design_tab.dart';
import 'tabs/layout_tab.dart';
import 'tabs/object_format_tab.dart';
import 'tabs/table_design_tab.dart';
import 'tabs/table_layout_tab.dart';

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

  /// Combobox de fonte/tamanho: o realce de estado escreve nele o valor
  /// EFETIVO da seleção (marca → estilo do parágrafo), ou VAZIO quando a
  /// seleção mistura valores — o comportamento do Word.
  void registerInlineCombo(String mark, OfficeComboBox combo) {
    _ribbon._inlineCombos[mark] = combo;
  }

  /// Campo numérico ligado a uma chave de `attrs['style']` do parágrafo
  /// (recuos e espaçamento da aba Layout). O realce de estado escreve o
  /// valor do bloco corrente convertido para a unidade do campo:
  /// [toPoints] = pontos (espaçamento), senão centímetros (recuo).
  void registerBlockStyleField(String styleKey, DomElement input,
      {required bool toPoints}) {
    _ribbon._blockStyleFields[styleKey] = (element: input, points: toPoints);
  }

  /// Botão de uma variante de marca (subscrito/sobrescrito).
  void registerMarkValueButton(String mark, String value, DomElement button) {
    _ribbon._markValueButtons[(mark: mark, value: value)] = button;
  }

  /// Controle cujo realce NÃO vem de uma marca, de um estilo ou de uma chave
  /// de `attrs['style']` — é o caso dos botões e campos de tabela, que
  /// refletem atributos do nó `tableRow`/`tableCell` da seleção.
  ///
  /// O hook roda a cada [OfficeRibbon.refreshState] e só pode LER o modelo:
  /// a UI reflete o documento, nunca o contrário. Sem ele, cada aba
  /// contextual teria de reimplementar "o botão está aceso?" com um listener
  /// próprio de seleção.
  void registerRefresh(void Function() hook) => _ribbon._refreshHooks.add(hook);

  /// Cartão da GALERIA de estilos, indexado pelo `w:styleId`.
  ///
  /// Pelo ID e não pelo NOME: o nome é rótulo e muda (o menu do cartão
  /// renomeia), enquanto o id é o que o bloco carrega em `word.styleId`.
  /// Comparar nomes também quebraria em qualquer DOCX não-português, onde o
  /// "Título 1" da galeria se chama `Heading1` no modelo.
  void registerStyleCard(String styleId, DomElement card) {
    _ribbon._styleCards[styleId] = card;
  }
}

class OfficeRibbon {
  OfficeRibbon(this.controller) : kit = OfficeDomKit(controller.adapter);

  final OfficeWordController controller;
  final OfficeDomKit kit;

  /// As abas que só existem com a seleção dentro de uma tabela. São DUAS,
  /// como no Word: a estrutura ("Tabela Layout") e a aparência ("Design da
  /// Tabela") são grupos grandes demais para caber numa aba só.
  static const List<String> tableTabKeys = ['tableDesign', 'tableLayout'];

  /// A aba de OBJETO (imagem ou caixa de texto selecionada). O rótulo troca
  /// com o tipo do objeto, como no Word ("Formato de Imagem" × "Formato da
  /// Forma"), e por isso ele é escrito em [refreshContextual], não na
  /// construção.
  static const String objectTabKey = 'objectFormat';

  /// Todas as abas que nascem escondidas e aparecem por CONTEXTO: as duas de
  /// tabela, a de cabeçalho/rodapé e a de objeto.
  static const List<String> contextualTabKeys = [
    ...tableTabKeys,
    'headerfooter',
    objectTabKey,
  ];

  final Map<String, DomElement> _tabs = {};
  final Map<String, DomElement> _markButtons = {};
  final Map<String, ({DomElement element, String fallback})> _markValueSelects =
      {};
  final Map<String, OfficeComboBox> _inlineCombos = {};
  final Map<String, ({DomElement element, bool points})> _blockStyleFields = {};
  final Map<({String mark, String value}), DomElement> _markValueButtons = {};
  final Map<String, DomElement> _styleCards = {};
  final List<void Function()> _refreshHooks = [];
  DomElement? _styleSelect;
  DomElement? _body;

  /// A aba em exibição — para [rebuildActiveTab] refazer a MESMA aba quando
  /// o catálogo de estilos muda por fora de uma transação.
  String _activeTabKey = 'home';

  /// Estado anterior da sessão de cabeçalho/rodapé — a aba contextual só é
  /// forçada na TRANSIÇÃO para ativa.
  bool _headerFooterWasActive = false;

  /// O mesmo, para a seleção de objeto; e o rótulo em exibição na aba dele.
  bool _objectWasSelected = false;
  String _objectTabLabel = 'Formato de Imagem';

  /// A ribbon completa (modo word), com abas.
  DomElement build() {
    final ribbon = kit.el('div', 'dq-office-ribbon');

    final tabs = kit.el('div', 'dq-office-ribbon-tabs');
    for (final (key, label) in const [
      ('file', 'Arquivo'),
      ('home', 'Página Inicial'),
      ('insert', 'Inserir'),
      ('design', 'Design'),
      ('layout', 'Layout'),
      ('tableDesign', 'Design da Tabela'),
      ('tableLayout', 'Tabela Layout'),
      ('headerfooter', 'Cabeçalho e Rodapé'),
      (objectTabKey, 'Formato de Imagem'),
    ]) {
      final tab = kit.el('button', 'dq-office-ribbon-tab');
      tab.setAttribute('type', 'button');
      tab.appendText(label);
      _tabs[key] = tab;
      if (contextualTabKeys.contains(key)) {
        // Contextual: só existe enquanto a seleção está numa tabela, ou
        // enquanto o modo cabeçalho/rodapé está aberto.
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

  /// Um contexto de construção SEM painel de abas.
  ///
  /// É o que permite a quickbar (e qualquer outra mini-UI) usar os mesmos
  /// construtores de controle da ribbon e herdar de graça o realce de
  /// estado: os controles se registram nesta instância e [refreshState] os
  /// atualiza. Sem isto, cada mini-UI reimplementaria "o B está aceso?".
  RibbonContext contextFor() => RibbonContext(controller, kit, this);

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

  /// Reconstrói a aba corrente. É o caminho de quem mexeu numa FONTE de
  /// dados da ribbon (a galeria de estilos), não no estado da seleção —
  /// [refreshState] só reflete o modelo nos controles que já existem.
  void rebuildActiveTab() {
    if (_body != null) showTab(_activeTabKey);
  }

  void showTab(String key) {
    final body = _body;
    if (body == null) return;
    _activeTabKey = key;
    _tabs.forEach((tabKey, tab) {
      if (tabKey == key) {
        tab.classes.add('dq-office-ribbon-tab-active');
      } else {
        tab.classes.remove('dq-office-ribbon-tab-active');
      }
    });
    kit.clear(body);
    // A aba anterior foi descartada: qualquer popup ancorado nela (paleta,
    // lista de fontes) perdeu o âncora e não pode continuar aberto.
    controller.overlay.closeAll();
    _markButtons.clear();
    _markValueSelects.clear();
    _inlineCombos.clear();
    _blockStyleFields.clear();
    _markValueButtons.clear();
    _styleCards.clear();
    _refreshHooks.clear();
    _styleSelect = null;

    final context = RibbonContext(controller, kit, this);
    final groups = switch (key) {
      'design' => buildDesignTab(context),
      'layout' => buildLayoutTab(context),
      'insert' => buildInsertTab(context),
      'file' => buildFileTab(context),
      'tableDesign' => buildTableDesignTab(context),
      'tableLayout' => buildTableLayoutTab(context),
      'headerfooter' => buildHeaderFooterTab(context),
      objectTabKey => buildObjectFormatTab(context),
      _ => buildHomeTab(context),
    };
    for (final group in groups) {
      body.append(group);
    }
    refreshState();
  }

  /// A shell é CONTEXTUAL: as duas abas de tabela existem enquanto a
  /// seleção está numa tabela, e a de "Cabeçalho e Rodapé" segue a sessão de
  /// edição da região. Todas somem fora do contexto — voltando para Página
  /// Inicial se a que sumiu estava ativa.
  void refreshContextual() {
    if (!controller.viewReady) return;
    // A view ATIVA: uma tabela dentro do cabeçalho/rodapé em edição é uma
    // tabela como qualquer outra, e as abas dela têm de aparecer. Com a view
    // do corpo fixa aqui, editar o rodapé em tabela (o timbre do TR é um)
    // deixava o usuário sem nenhum comando de tabela.
    final inTable = table_ops.tableDepthOf(controller.activeView.state) != null;
    for (final key in tableTabKeys) {
      final tab = _tabs[key];
      if (tab != null) _setContextualVisible(tab, inTable);
    }

    // Aba de OBJETO: existe enquanto há imagem/caixa selecionada, e o rótulo
    // segue o tipo — o Word chama a mesma faixa de "Formato de Imagem" ou
    // "Formato da Forma" conforme o que está selecionado.
    final objectTab = _tabs[objectTabKey];
    if (objectTab != null) {
      final target = actions.selectedObject(controller);
      if (target != null) {
        final label = officeObjectFormatTabLabel(controller);
        if (_objectTabLabel != label) {
          _objectTabLabel = label;
          kit.setText(objectTab, label);
          // A aba visível descreve o objeto ERRADO enquanto não é refeita:
          // trocar de uma imagem para uma caixa muda o rótulo e os controles.
          if (_activeTabKey == objectTabKey) showTab(objectTabKey);
        }
      }
      _setContextualVisible(objectTab, target != null);
      // Selecionar um objeto TROCA a aba, como no Word. Só na transição, para
      // não impedir o usuário de olhar outra aba com o objeto selecionado.
      if (target != null && !_objectWasSelected) showTab(objectTabKey);
      _objectWasSelected = target != null;
    }

    final region = _tabs['headerfooter'];
    if (region == null) return;
    final active = controller.headerFooter.isActive;
    _setContextualVisible(region, active);
    // Entrar no modo TROCA a aba, como no Word — o usuário não deveria ter de
    // procurar os comandos de cabeçalho depois do duplo clique. Só na
    // TRANSIÇÃO: forçar a aba a cada refresh impediria olhar outra aba com o
    // modo aberto.
    if (active && !_headerFooterWasActive) showTab('headerfooter');
    _headerFooterWasActive = active;
  }

  void _setContextualVisible(DomElement tab, bool visible) {
    if (visible) {
      tab.classes.remove('dq-office-ribbon-tab-hidden');
      return;
    }
    tab.classes.add('dq-office-ribbon-tab-hidden');
    if (tab.classes.contains('dq-office-ribbon-tab-active')) showTab('home');
  }

  /// Acende os botões conforme a seleção. Leitura pura do estado: a UI
  /// reflete o modelo, nunca o contrário.
  void refreshState() {
    if (!controller.viewReady) return;
    // A view ATIVA: com o modo cabeçalho/rodapé aberto, o N aceso tem de
    // descrever a seleção que está dentro da região, não a que ficou parada
    // no corpo.
    final state = controller.activeView.state;
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

    // Fonte/tamanho: valor EFETIVO (marca direta → cascata de estilos do
    // documento) e VAZIO em seleção mista, como o Word mostra.
    _inlineCombos.forEach((name, combo) {
      combo.setValue(actions.effectiveInlineValue(controller, name));
    });

    if (_blockStyleFields.isNotEmpty) {
      final blockStyle = controller.currentBlockStyle();
      _blockStyleFields.forEach((key, field) {
        final raw = blockStyle?[key];
        final twips = raw is num ? raw.toDouble() : 0.0;
        final value = field.points ? twips / 20 : twips / 567;
        // Sem casas decimais quando o valor é redondo — "0" e não "0.00",
        // que é o que o Word mostra nesses spinners.
        field.element.value = value == value.roundToDouble()
            ? '${value.round()}'
            : value.toStringAsFixed(2);
      });
    }

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

    // O cartão aceso é o do ESTILO do bloco, resolvido pelo id — o nome do
    // cartão pode ter sido trocado pelo menu de contexto e não identifica
    // mais nada.
    final currentStyleId = actions.currentStyleId(controller);
    _styleCards.forEach((styleId, card) {
      if (styleId == currentStyleId) {
        card.classes.add('dq-office-stylecard-active');
      } else {
        card.classes.remove('dq-office-stylecard-active');
      }
    });

    for (final hook in _refreshHooks) {
      hook();
    }
  }
}
