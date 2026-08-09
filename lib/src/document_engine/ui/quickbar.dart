/// A mini-UI contextual do Word: a barra flutuante que aparece logo acima
/// do texto assim que o usuário termina de selecionar.
///
/// Ela não é um atalho para a ribbon — é o que evita a viagem até o topo da
/// tela a cada formatação. Por isso carrega só o que se usa em cima de uma
/// seleção recém-feita: fonte, tamanho, negrito/itálico/sublinhado, realce,
/// cor, listas e estilos.
///
/// Regras de comportamento copiadas do Word (e do DocumentHolder do
/// ONLYOFFICE), porque cada uma existe por um motivo:
///
/// * nasce no `mouseup`/`keyup` que TERMINA uma seleção não vazia — durante
///   o arrasto ela atrapalharia a mira;
/// * some ao digitar, ao clicar fora e ao colapsar a seleção;
/// * nunca rouba o foco: todo controle cancela o `mousedown`, então o texto
///   selecionado continua selecionado enquanto se escolhe a formatação;
/// * é reconstruída a cada abertura para refletir o estado da seleção nova.
///
/// Reaproveita os MESMOS controles e ações da ribbon (`ribbon_actions.dart`,
/// `home_tab.dart`): nenhuma formatação tem duas implementações.
library;

import '../../platform/dom.dart';
import 'controller.dart';
import 'overlay.dart';
import 'ribbon.dart';
import 'ribbon_actions.dart' as actions;
import 'table_ops.dart' as table_ops;
import 'tabs/home_tab.dart';

/// Grupo de popup da quickbar — um só, então abrir uma fecha a anterior.
const String officeQuickbarGroup = 'quickbar';

class OfficeSelectionQuickbar {
  OfficeSelectionQuickbar(this.controller)
      : _kit = OfficeDomKit(controller.adapter);

  final OfficeWordController controller;
  final OfficeDomKit _kit;

  OfficePopupHandle? _handle;

  /// A instância de ribbon que hospeda os CONTROLES da barra (só o registro
  /// de estado; nenhuma aba é construída). É o que faz o N/I/S da quickbar
  /// acender pela mesma leitura de modelo da ribbon.
  OfficeRibbon? _controls;

  bool get isOpen => _handle?.isOpen ?? false;

  /// Reflete o estado da seleção nos controles abertos.
  void refreshState() {
    if (!isOpen) return;
    _controls?.refreshState();
  }

  /// Mostra a barra do OBJETO selecionado (imagem/caixa de texto), ancorada
  /// no canto superior direito dele — a posição do botão "Opções de Layout"
  /// do Word.
  ///
  /// Traz só o que a projeção realmente honra hoje: alinhamento do objeto e
  /// excluir. Disposição do texto (quadrado/atrás/na frente) espera o
  /// compositor ganhar wrap de verdade; oferecer o controle antes disso
  /// seria um botão que não muda nada.
  void showForObject({required num x, required num y}) {
    if (!controller.viewReady) return;
    hide();
    _handle = controller.overlay.open(
      officeQuickbarGroup,
      _buildObjectBar(),
      placement: OfficePopupPlacement.atPoint,
      x: x,
      y: y,
      extraClass: 'dq-office-quickbar',
    );
  }

  DomElement _buildObjectBar() {
    final bar = _kit.el('div', 'dq-office-quickbar-bar');
    final row = _kit.el('div', 'dq-office-quickbar-row');
    row.append(_kit.button('⯇', 'Alinhar objeto à esquerda',
        () => actions.setObjectAlign(controller, 'left'),
        icon: 'align-left'));
    row.append(_kit.button('☰', 'Centralizar objeto',
        () => actions.setObjectAlign(controller, 'center'),
        icon: 'align-center'));
    row.append(_kit.button('⯈', 'Alinhar objeto à direita',
        () => actions.setObjectAlign(controller, 'right'),
        icon: 'align-right'));
    row.append(_kit.el('span', 'dq-office-ribbon-sep'));
    row.append(_kit.button(
        '✕', 'Excluir objeto', () => actions.deleteSelectedObject(controller),
        icon: 'delcell'));
    bar.append(row);
    return bar;
  }

  /// A barra de TABELA: aparece com a seleção retangular de células, com o
  /// que o Word oferece ali — inserir/excluir linha e coluna, mesclar e
  /// dividir. Reusa `table_ops.dart`, as mesmas funções da aba contextual.
  void showForTable({required num x, required num y}) {
    if (!controller.viewReady) return;
    hide();
    _handle = controller.overlay.open(
      officeQuickbarGroup,
      _buildTableBar(),
      placement: OfficePopupPlacement.atPoint,
      x: x,
      y: y,
      extraClass: 'dq-office-quickbar',
    );
  }

  DomElement _buildTableBar() {
    final bar = _kit.el('div', 'dq-office-quickbar-bar');
    final row = _kit.el('div', 'dq-office-quickbar-row');
    void run(bool Function() action) {
      controller.syncSelection();
      action();
    }

    row.append(_kit.button(
        '⬆+',
        'Inserir linha acima',
        () => table_ops.tableInsertRow(
            controller.view.state, controller.dispatch, controller.schema,
            above: true),
        icon: 'addcell'));
    row.append(_kit.button(
        '⬇+',
        'Inserir linha abaixo',
        () => table_ops.tableInsertRow(
            controller.view.state, controller.dispatch, controller.schema,
            above: false)));
    row.append(_kit.button(
        '➡+',
        'Inserir coluna à direita',
        () => table_ops.tableInsertColumn(
            controller.view.state, controller.dispatch, controller.schema,
            before: false)));
    row.append(_kit.el('span', 'dq-office-ribbon-sep'));
    row.append(_kit.button(
        '⧉',
        'Mesclar células',
        () => run(() => table_ops.mergeSelectedCells(
            controller.view.state, controller.dispatch)),
        icon: 'merge-cells'));
    row.append(_kit.button(
        '⫯',
        'Dividir célula',
        () => run(() => table_ops.splitSelectedCell(
            controller.view.state, controller.dispatch)),
        icon: 'rows-and-columns'));
    row.append(_kit.el('span', 'dq-office-ribbon-sep'));
    row.append(_kit.button(
        '⬚✕',
        'Excluir linha',
        () => table_ops.tableDeleteRow(
            controller.view.state, controller.dispatch),
        icon: 'delcell'));
    row.append(_kit.button(
        '▯✕',
        'Excluir coluna',
        () => table_ops.tableDeleteColumn(
            controller.view.state, controller.dispatch)));
    bar.append(row);
    return bar;
  }

  /// Mostra a quickbar sobre a seleção corrente, ou a esconde quando não há
  /// seleção de texto. [anchorX]/[anchorY] são as coordenadas do ponteiro
  /// quando a seleção veio do mouse; sem elas a barra se ancora na
  /// geometria da própria seleção.
  void showForSelection({num? anchorX, num? anchorY}) {
    if (!controller.viewReady) return;
    final selection = controller.view.state.selection;
    if (selection.empty) {
      hide();
      return;
    }
    final bounds = _selectionBounds();
    // Sem geometria (VM/fake DOM) a barra abre ancorada no ponteiro; sem
    // nenhum dos dois ela ainda abre, no canto da camada — o que importa é
    // que os controles existam e ajam sobre a seleção.
    hide();
    _handle = controller.overlay.open(
      officeQuickbarGroup,
      _build(),
      // ACIMA do topo da seleção: a altura real da barra é medida pelo
      // overlay depois de anexá-la, então duas linhas de controles não
      // cobrem o texto selecionado.
      placement: OfficePopupPlacement.abovePoint,
      x: bounds?['left'] ?? anchorX ?? 0,
      y: bounds?['top'] ?? anchorY ?? 0,
      extraClass: 'dq-office-quickbar',
    );
  }

  void hide() {
    controller.overlay.closeGroup(officeQuickbarGroup);
    _handle = null;
    _controls = null;
  }

  Map<String, dynamic>? _selectionBounds() {
    final native = controller.adapter.getNativeSelectionRange();
    if (native == null) return null;
    return controller.adapter.getRangeBounds(
      native.startContainer,
      native.startOffset,
      native.endContainer,
      native.endOffset,
    );
  }

  DomElement _build() {
    final bar = _kit.el('div', 'dq-office-quickbar-bar');
    // O contexto é o MESMO da ribbon: os controles se registram e o
    // refreshState os atualiza sem nenhuma duplicação de lógica.
    final ribbon = OfficeRibbon(controller);
    _controls = ribbon;
    final ctx = ribbon.contextFor();

    final firstRow = _kit.el('div', 'dq-office-quickbar-row');
    firstRow.append(buildFontFamilyCombo(ctx, extraClass: 'dq-office-qb-font'));
    firstRow.append(buildFontSizeCombo(ctx, extraClass: 'dq-office-qb-size'));
    firstRow.append(_kit.button('A^', 'Aumentar Fonte',
        () => actions.stepFontSize(controller, up: true),
        icon: 'incfont'));
    firstRow.append(_kit.button('A˅', 'Diminuir Fonte',
        () => actions.stepFontSize(controller, up: false),
        icon: 'decfont'));
    firstRow.append(_kit.button('⌫a', 'Limpar Toda a Formatação',
        () => actions.clearFormatting(controller),
        icon: 'clearstyle'));
    bar.append(firstRow);

    final secondRow = _kit.el('div', 'dq-office-quickbar-row');
    secondRow.append(ctx.markButton(
        'bold', 'N', 'Negrito (Ctrl+B)', 'dq-office-b',
        icon: 'bold'));
    secondRow.append(ctx.markButton(
        'italic', 'I', 'Itálico (Ctrl+I)', 'dq-office-i',
        icon: 'italic'));
    secondRow.append(ctx.markButton(
        'underline', 'S', 'Sublinhado (Ctrl+U)', 'dq-office-u',
        icon: 'underline'));
    secondRow.append(buildPaletteButton(ctx,
        icon: 'highlight',
        text: 'ab',
        title: 'Cor do Realce do Texto',
        mark: 'background',
        colors: officeHighlightColors));
    secondRow.append(buildPaletteButton(ctx,
        icon: 'fontcolor',
        text: 'A',
        title: 'Cor da Fonte',
        mark: 'color',
        colors: officeFontColors));
    secondRow.append(_kit.button('•—', 'Lista com marcadores',
        () => actions.toggleList(controller, 'bullet'),
        icon: 'setmarkers'));
    secondRow.append(_kit.button(
        '1—', 'Lista numerada', () => actions.toggleList(controller, 'ordered'),
        icon: 'numbering'));
    bar.append(secondRow);

    // Estado inicial: os botões já nascem acesos conforme a seleção.
    ribbon.refreshState();
    return bar;
  }
}
