/// Aba contextual "Cabeçalho e Rodapé" (F6).
///
/// Existe apenas enquanto a sessão [OfficeHeaderFooterSession] está aberta —
/// como no Word, onde ela nasce do duplo clique na região e some ao fechar.
///
/// Os controles são os do Word, na mesma ordem: navegação entre as duas
/// regiões, as duas opções de variante (`w:titlePg` e `w:evenAndOddHeaders`),
/// as distâncias até a borda e o Fechar. Nada aqui tem caminho próprio para
/// mudar o documento: navegação e fechamento falam com a sessão, as opções e
/// as distâncias passam pelo controlador, e o controlador repagina.
///
/// **Nº de Página** insere o CAMPO, não o texto: uma sequência de field
/// markers (`begin`, instrução, `separate`, `end`) idêntica à que a
/// importação produz. Escrever "1" como texto daria um cabeçalho que diz
/// "1" em todas as páginas; com o campo, o compositor resolve o número por
/// página (`layout_composer._resolveFields`) e o Word reconhece o resultado
/// no arquivo exportado.
library;

import '../../../platform/dom.dart';
import '../../layout/page_graph.dart';
import '../controller.dart';
import '../ribbon.dart';
import '../ribbon_actions.dart' as actions;

List<DomElement> buildHeaderFooterTab(RibbonContext ctx) {
  final c = ctx.controller;
  final kit = ctx.kit;
  final session = c.headerFooter;
  return [
    kit.group('Navegação', [
      kit.row([
        _navButton(ctx, 'Ir para Cabeçalho', header: true, icon: 'editheader'),
        _navButton(ctx, 'Ir para Rodapé', header: false, icon: 'menu-header'),
      ]),
    ]),
    kit.group('Opções', [
      kit.row([
        _toggle(
          ctx,
          'Primeira Página Diferente',
          'dq-office-hf-titlepage',
          active: c.titlePage,
          onToggle: () => c.setHeaderFooterFlags(titlePage: !c.titlePage),
        ),
      ]),
      kit.row([
        _toggle(
          ctx,
          'Páginas Pares e Ímpares Diferentes',
          'dq-office-hf-evenodd',
          active: c.evenAndOddHeaders,
          onToggle: () =>
              c.setHeaderFooterFlags(evenAndOddHeaders: !c.evenAndOddHeaders),
        ),
      ]),
    ]),
    kit.group('Posição', [
      kit.row([
        _distanceSpinner(
            ctx, 'Cabeçalho a partir do Topo', 'dq-office-hf-header-distance',
            isHeader: true),
      ]),
      kit.row([
        _distanceSpinner(
            ctx, 'Rodapé a partir da Base', 'dq-office-hf-footer-distance',
            isHeader: false),
      ]),
    ]),
    kit.group('Inserir', [
      kit.row([
        kit.button(
          'Nº de Página',
          'Inserir o campo Número de Página (resolve por página, '
              'não é texto fixo)',
          () => actions.insertPageField(c),
          extraClass: 'dq-office-btn-labeled',
          icon: 'pagenum',
        ),
      ]),
      kit.row([
        kit.button(
          'Total de Páginas',
          'Inserir o campo NUMPAGES (total de páginas do documento)',
          () => actions.insertPageField(c, command: 'NUMPAGES'),
          extraClass: 'dq-office-btn-labeled',
        ),
      ]),
    ]),
    kit.group('Fechar', [
      kit.row([
        kit.button(
          'Fechar Cabeçalho e Rodapé',
          'Fechar Cabeçalho e Rodapé',
          session.exit,
          extraClass: 'dq-office-hf-close',
        ),
      ]),
    ]),
  ];
}

/// "Ir para Cabeçalho"/"Ir para Rodapé". A região CORRENTE fica acesa em vez
/// de desabilitada: o Word marca onde você está, e um botão apagado não
/// diria qual das duas regiões está sendo editada.
DomElement _navButton(
  RibbonContext ctx,
  String label, {
  required bool header,
  required String icon,
}) {
  final session = ctx.controller.headerFooter;
  final button = ctx.kit.button(
    label,
    label,
    () => session.goTo(header: header),
    icon: icon,
    extraClass: 'dq-office-menuwrap-big',
  );
  if (session.isActive && session.isHeader == header) {
    button.classes.add('dq-office-btn-active');
  }
  return button;
}

/// Opção liga/desliga. O estado vem do MODELO (`titlePage`,
/// `evenAndOddHeaders`) a cada construção da aba; a repaginação disparada
/// pelo clique reconstrói a aba, então o realce nunca fica defasado.
DomElement _toggle(
  RibbonContext ctx,
  String label,
  String cssClass, {
  required bool active,
  required void Function() onToggle,
}) {
  final button = ctx.kit.button(label, label, onToggle, extraClass: cssClass);
  button.setAttribute('aria-pressed', active ? 'true' : 'false');
  if (active) button.classes.add('dq-office-btn-active');
  return button;
}

/// Distância da região até a BORDA da página, em centímetros — a mesma
/// medida do `w:pgMar/@header` e do `@footer`, e a que o Word mostra.
///
/// As demais medidas do setup são copiadas verbatim: mudar a distância do
/// cabeçalho não pode mexer em margem, papel ou orientação.
DomElement _distanceSpinner(
  RibbonContext ctx,
  String label,
  String cssClass, {
  required bool isHeader,
}) {
  final c = ctx.controller;
  final kit = ctx.kit;
  final wrap = kit.el('label', 'dq-office-spinner');
  final caption = kit.el('span', 'dq-office-spinner-label');
  caption.appendText(label);
  wrap.append(caption);

  final input = kit.el('input', 'dq-office-spinner-input $cssClass');
  input.setAttribute('type', 'number');
  input.setAttribute('step', '0.25');
  input.setAttribute('min', '0');
  input.setAttribute('title', label);
  final current = isHeader
      ? c.pageSetup.headerDistanceTwips
      : c.pageSetup.footerDistanceTwips;
  input.value = _cm(current);
  input.addEventListener('change', (_) {
    final typed = double.tryParse(input.value.replaceAll(',', '.'));
    if (typed == null || typed < 0) return;
    setRegionDistanceTwips(c, (typed * 567).round(), isHeader: isHeader);
  });
  wrap.append(input);
  return wrap;
}

/// Grava a distância no setup de página. Público porque é o caminho REAL da
/// ação (a mesma função que um diálogo "Configurar Página" usaria) e porque
/// os testes precisam exercitá-lo sem digitar num `<input>`.
void setRegionDistanceTwips(
  OfficeWordController c,
  int twips, {
  required bool isHeader,
}) {
  final setup = c.pageSetup;
  c.setPageSetup(PageSetupTwips(
    widthTwips: setup.widthTwips,
    heightTwips: setup.heightTwips,
    marginTopTwips: setup.marginTopTwips,
    marginRightTwips: setup.marginRightTwips,
    marginBottomTwips: setup.marginBottomTwips,
    marginLeftTwips: setup.marginLeftTwips,
    headerDistanceTwips: isHeader ? twips : setup.headerDistanceTwips,
    footerDistanceTwips: isHeader ? setup.footerDistanceTwips : twips,
    documentGridLinePitchTwips: setup.documentGridLinePitchTwips,
    documentGridType: setup.documentGridType,
  ));
}

/// twips → o número em centímetros que o spinner exibe (ponto decimal, que é
/// o que um `<input type=number>` aceita).
String _cm(int twips) {
  final value = (twips / 567.0 * 100).round() / 100;
  return value == value.roundToDouble()
      ? '${value.round()}'
      : value.toStringAsFixed(2);
}
