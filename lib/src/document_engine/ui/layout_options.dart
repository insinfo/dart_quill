/// O popover "Opções de Layout" — o botãozinho que o Word mostra colado ao
/// canto superior direito do objeto selecionado.
///
/// Ele existe separado da quickbar porque responde a uma pergunta diferente:
/// a quickbar formata, este decide COMO o texto se comporta em volta do
/// objeto. Os dois abrem o mesmo menu, montado aqui uma única vez.
///
/// Regra dura desta tela: **nenhum item grava um atributo que o compositor
/// ignora**. Um modo que o layout não sabe honrar aparece desabilitado com o
/// motivo real na descrição, e não como um botão que não muda nada. Os modos
/// habilitados são exatamente os que `layout_composer.dart` lê em
/// `_wrapModeOf` e converte em exclusão (`_WrapField.insetsFor`) ou em
/// deslocamento de cursor (`_topAndBottomBottomTwips`).
library;

import '../../platform/dom.dart';
import '../state/index.dart';
import 'controller.dart';
import 'menu.dart';
import 'overlay.dart';
import 'ribbon_actions.dart' as actions;

/// Grupo de popup próprio: abrir as opções de layout não deve fechar a
/// moldura do objeto, mas deve fechar outro popover de layout.
const String officeLayoutOptionsGroup = 'layout-options';

/// Um modo de disposição, na ordem em que o Word os lista.
class _WrapChoice {
  const _WrapChoice(this.mode, this.label, this.icon, {this.disabledReason});

  final String mode;
  final String label;
  final String icon;

  /// Não nulo quando o compositor NÃO honra o modo: vira a descrição do item
  /// desabilitado, com o motivo verdadeiro.
  final String? disabledReason;
}

const List<_WrapChoice> _choices = [
  _WrapChoice(
    'inline',
    'Em linha com o texto',
    'wrap-inline',
    disabledReason: 'a caixa de texto é sempre flutuante no motor; '
        'não há projeção dela dentro da linha',
  ),
  _WrapChoice('square', 'Quadrado', 'wrap-square'),
  _WrapChoice('tight', 'Próximo', 'wrap-tight'),
  _WrapChoice('through', 'Através', 'wrap-through'),
  _WrapChoice('topAndBottom', 'Superior e inferior', 'wrap-topbottom'),
  _WrapChoice('behindText', 'Atrás do texto', 'wrap-behind'),
  _WrapChoice('inFrontOfText', 'Na frente do texto', 'wrap-infront'),
];

/// As entradas do menu para a seleção corrente.
///
/// Público para o teste: provar que um modo não suportado sai VISÍVEL e
/// desabilitado é tão importante quanto provar que o suportado grava.
List<OfficeMenuEntry> buildLayoutOptionsEntries(OfficeWordController c) {
  final selection = c.activeView.state.selection;
  final node = selection is NodeSelection ? selection.node : null;
  // Imagem não tem âncora flutuante no modelo: a importação achata
  // `wp:anchor` em inline (`docx/reader.dart` registra a nota
  // "drawing flutuante (anchor) tratado como inline"). Mostrar os modos
  // habilitados aqui gravaria um atributo que ninguém lê.
  final imageReason = 'imagem é importada sempre em linha; '
      'o motor não modela âncora flutuante de imagem';
  final isImage = node?.type.name == 'image';
  final current = actions.objectWrapMode(c);
  return [
    for (final choice in _choices)
      OfficeMenuEntry(
        label: choice.label,
        icon: choice.icon,
        // Numa imagem, "Em linha com o texto" é o modo VIGENTE — e o Word o
        // mostra marcado. Deixar a lista inteira apagada dizia ao usuário
        // que o editor não sabe o que a imagem é; ela sabe, e é este.
        checked: isImage ? choice.mode == 'inline' : choice.mode == current,
        enabled: !isImage && choice.disabledReason == null,
        description: isImage
            ? (choice.mode == 'inline'
                ? 'a imagem já está em linha com o texto'
                : imageReason)
            : choice.disabledReason,
        onSelect: () => actions.setObjectWrap(c, choice.mode),
      ),
  ];
}

/// Abre o popover nas coordenadas dadas (o canto do objeto).
OfficePopupHandle openLayoutOptionsPopover(
  OfficeWordController c, {
  required num x,
  required num y,
}) =>
    c.overlay.open(
      officeLayoutOptionsGroup,
      buildMenu(c, buildLayoutOptionsEntries(c),
          extraClass: 'dq-office-layout-options'),
      placement: OfficePopupPlacement.atPoint,
      x: x,
      y: y,
    );

/// Botão "Disposição do Texto" para barras contextuais.
///
/// Ele abre o MESMO menu do popover do objeto, ancorado no próprio botão.
DomElement layoutOptionsButton(OfficeWordController c) {
  final kit = OfficeDomKit(c.adapter);
  final wrap = kit.el('span', 'dq-office-menuwrap');
  wrap.append(kit.button(
    '⧉',
    'Disposição do Texto',
    () => openMenu(
      c,
      officeLayoutOptionsGroup,
      wrap,
      buildLayoutOptionsEntries(c),
      extraClass: 'dq-office-layout-options',
    ),
    icon: 'img-wrap',
    extraClass: 'dq-office-btn-menu',
  ));
  return wrap;
}
