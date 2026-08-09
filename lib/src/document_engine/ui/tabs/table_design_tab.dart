/// Aba contextual "Design da Tabela" — a APARÊNCIA das células: bordas e
/// sombreamento.
///
/// **Por que não há galeria de estilos de tabela aqui.** No Word a galeria
/// aplica um `w:tblStyle`, e o estilo é resolvido em cascata (tabela → banda
/// → linha de cabeçalho → célula) na hora de desenhar. Nada disso existe no
/// compositor: `layout_composer` lê bordas e sombreamento DIRETOS da célula
/// (`word.borders`, `cell.background`) e ignora qualquer `tblStyle`. Uma
/// galeria seria um controle que grava um atributo que o layout descarta —
/// clicar mudaria o modelo e a tela continuaria igual. Ela entra quando o
/// catálogo de estilos (F8) existir e o compositor resolver a cascata.
///
/// O que está aqui é honrado ponta a ponta: as bordas viram `w:tcBorders`
/// e o sombreamento vira `w:shd` na exportação, e os dois são lidos pelo
/// compositor na projeção.
library;

import '../../../platform/dom.dart';
import '../ribbon.dart';
import '../table_ops.dart' as ops;

/// As cores de sombreamento do Word (primeira linha da paleta padrão), com
/// "Sem cor" na frente. É a mesma paleta de realce de texto, porque no Word
/// é literalmente a mesma grade de amostras.
const List<String?> officeTableShadingColors = [
  null, // Sem cor — remove o sombreamento
  '#000000', '#c00000', '#ff0000', '#ffc000', '#ffff00', '#92d050',
  '#00b050', '#00b0f0', '#0070c0', '#002060', '#7030a0',
  '#ffffff', '#d9d9d9', '#bfbfbf', '#a6a6a6', '#808080', '#404040',
];

List<DomElement> buildTableDesignTab(RibbonContext ctx) {
  final c = ctx.controller;
  final kit = ctx.kit;
  void run(void Function() action) {
    c.syncSelection();
    action();
  }

  return [
    kit.group('Sombreamento', [
      kit.row([
        buildCellShadingButton(ctx),
      ]),
    ]),
    kit.group('Bordas', [
      kit.row([
        for (final (which, text, title, icon) in const [
          (ops.OfficeCellBorders.all, '⊞', 'Todas as bordas', 'border-all'),
          (ops.OfficeCellBorders.none, '⊡', 'Sem bordas', 'border-no'),
          (ops.OfficeCellBorders.outside, '▢', 'Bordas externas', 'border-out'),
          (
            ops.OfficeCellBorders.inside,
            '┼',
            'Bordas internas',
            'border-inside'
          ),
        ])
          kit.button(
              text,
              title,
              () => run(
                  () => ops.setCellBorders(c.view.state, c.dispatch, which)),
              icon: icon),
      ]),
      kit.row([
        for (final (which, text, title, icon) in const [
          (ops.OfficeCellBorders.top, '▔', 'Borda superior', 'border-top'),
          (
            ops.OfficeCellBorders.bottom,
            '▁',
            'Borda inferior',
            'border-bottom'
          ),
          (ops.OfficeCellBorders.left, '▏', 'Borda esquerda', 'border-left'),
          (ops.OfficeCellBorders.right, '▕', 'Borda direita', 'border-right'),
        ])
          kit.button(
              text,
              title,
              () => run(
                  () => ops.setCellBorders(c.view.state, c.dispatch, which)),
              icon: icon),
      ]),
    ]),
  ];
}

/// Botão de sombreamento com paleta.
///
/// É o mesmo popup de `buildPaletteButton` (`home_tab.dart`) — grade de
/// amostras no overlay, clicar de novo fecha, a amostra riscada limpa. O que
/// muda é o destinatário: lá a cor vira uma MARCA sobre o texto, aqui vira
/// atributo da CÉLULA, então a função não pôde ser reusada como está.
DomElement buildCellShadingButton(RibbonContext ctx) {
  final kit = ctx.kit;
  final c = ctx.controller;
  final wrap = kit.el('span', 'dq-office-colorwrap');
  const group = 'palette:cellShading';

  DomElement buildPalette() {
    final palette = kit.el('div', 'dq-office-palette');
    for (final color in officeTableShadingColors) {
      final swatch = kit.el('button',
          'dq-office-swatch${color == null ? ' dq-office-swatch-none' : ''}');
      swatch.setAttribute('type', 'button');
      swatch.setAttribute('title', color ?? 'Sem cor');
      if (color != null) swatch.setAttribute('style', 'background:$color;');
      swatch.addEventListener('click', (event) {
        event.preventDefault();
        c.overlay.closeGroup(group);
        c.syncSelection();
        ops.setCellShading(c.view.state, c.dispatch, color);
      });
      palette.append(swatch);
    }
    return palette;
  }

  wrap.append(kit.button('▩', 'Sombreamento', () {
    if (c.overlay.closeGroup(group)) return;
    c.overlay.open(group, buildPalette(), anchor: wrap);
  }, icon: 'paracolor'));
  return wrap;
}
