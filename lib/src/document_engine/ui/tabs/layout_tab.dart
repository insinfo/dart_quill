/// Aba Layout — Margens, Orientação, Tamanho e Recuar/Espaçamento.
///
/// Os três primeiros são DROPDOWNS como no Word (item grande + as medidas
/// embaixo, e o item vigente marcado), não `<select>`s: o usuário escolhe
/// "Estreita 1,27 cm" lendo a medida, não decorando o nome. Cada escolha
/// vira `setPageSetup` e o documento REPAGINA de verdade, com conteúdo e
/// histórico intactos.
///
/// O grupo Recuar/Espaçamento usa spinners que agem sobre os blocos da
/// seleção — o mesmo caminho de `applyBlockStyle` da régua, então arrastar
/// o marcador e digitar o valor produzem exatamente a mesma transação.
library;

import '../../../platform/dom.dart';
import '../controller.dart';
import '../menu.dart';
import '../ribbon.dart';
import '../ribbon_actions.dart' as actions;

/// Predefinições de margem do Word (em twips), na ordem do menu.
const List<({String name, int top, int bottom, int left, int right})>
    marginPresets = [
  (name: 'Normal', top: 1418, bottom: 1418, left: 1701, right: 1701),
  (name: 'Estreita', top: 720, bottom: 720, left: 720, right: 720),
  (name: 'Moderada', top: 1440, bottom: 1440, left: 1080, right: 1080),
  (name: 'Larga', top: 1440, bottom: 1440, left: 2880, right: 2880),
];

/// Papéis do menu Tamanho (twips no formato retrato).
const List<({String name, int width, int height})> paperSizes = [
  (name: 'Carta', width: 12240, height: 15840),
  (name: 'Ofício', width: 12240, height: 20160),
  (name: 'Tablóide', width: 15840, height: 24480),
  (name: 'Executivo', width: 10440, height: 15120),
  (name: 'A3', width: 16838, height: 23814),
  (name: 'A4', width: 11906, height: 16838),
  (name: 'A5', width: 8391, height: 11906),
  (name: 'B5 (JIS)', width: 10318, height: 14570),
];

List<DomElement> buildLayoutTab(RibbonContext ctx) {
  final c = ctx.controller;
  final kit = ctx.kit;
  return [
    kit.group('Configurar Página', [
      kit.row([
        menuButton(
            c, 'Margens', 'Margens', 'layout:margins', () => _marginEntries(c),
            icon: 'pagemargins', extraClass: 'dq-office-menuwrap-big'),
        menuButton(c, 'Orientação', 'Orientação da Página',
            'layout:orientation', () => _orientationEntries(c),
            icon: 'pageorient', extraClass: 'dq-office-menuwrap-big'),
        menuButton(c, 'Tamanho', 'Tamanho do Papel', 'layout:size',
            () => _paperEntries(c),
            icon: 'pagesize', extraClass: 'dq-office-menuwrap-big'),
      ]),
    ]),
    kit.group('Parágrafo', [
      kit.row([
        _spinner(ctx, 'À Esquerda', 'indentTwips'),
        _spinner(ctx, 'Antes', 'spaceBeforeTwips'),
      ]),
      kit.row([
        _spinner(ctx, 'À Direita', 'rightIndentTwips'),
        _spinner(ctx, 'Depois', 'spaceAfterTwips'),
      ]),
    ]),
  ];
}

/// O menu Margens, com a medida de cada predefinição e o ✓ na vigente.
List<OfficeMenuEntry> _marginEntries(OfficeWordController c) {
  final setup = c.pageSetup;
  return [
    for (final preset in marginPresets)
      OfficeMenuEntry(
        label: preset.name,
        description: 'Sup.: ${_cm(preset.top)}  Inf.: ${_cm(preset.bottom)}  '
            'Esq.: ${_cm(preset.left)}  Dir.: ${_cm(preset.right)}',
        checked: setup.marginTopTwips == preset.top &&
            setup.marginBottomTwips == preset.bottom &&
            setup.marginLeftTwips == preset.left &&
            setup.marginRightTwips == preset.right,
        onSelect: () => actions.setMarginsTwips(
          c,
          top: preset.top,
          bottom: preset.bottom,
          left: preset.left,
          right: preset.right,
        ),
      ),
  ];
}

List<OfficeMenuEntry> _orientationEntries(OfficeWordController c) {
  final portrait = c.pageSetup.heightTwips >= c.pageSetup.widthTwips;
  return [
    OfficeMenuEntry(
      label: 'Retrato',
      icon: 'pageorient',
      checked: portrait,
      onSelect: () => actions.setOrientation(c, portrait: true),
    ),
    OfficeMenuEntry(
      label: 'Paisagem',
      checked: !portrait,
      onSelect: () => actions.setOrientation(c, portrait: false),
    ),
  ];
}

List<OfficeMenuEntry> _paperEntries(OfficeWordController c) {
  final setup = c.pageSetup;
  final shorter = setup.widthTwips < setup.heightTwips
      ? setup.widthTwips
      : setup.heightTwips;
  final longer = setup.widthTwips < setup.heightTwips
      ? setup.heightTwips
      : setup.widthTwips;
  return [
    for (final paper in paperSizes)
      OfficeMenuEntry(
        label: paper.name,
        description: '${_cm(paper.width)} x ${_cm(paper.height)}',
        // A comparação ignora a orientação: A4 paisagem continua sendo A4.
        checked: shorter == paper.width && longer == paper.height,
        onSelect: () => actions.setPaperTwips(c, paper.width, paper.height),
      ),
  ];
}

/// Spinner de recuo/espaçamento em CENTÍMETROS (recuos) ou PONTOS
/// (espaçamento), como o Word rotula os dois grupos.
DomElement _spinner(RibbonContext ctx, String label, String styleKey) {
  final c = ctx.controller;
  final kit = ctx.kit;
  final isSpacing = styleKey.startsWith('space');
  final wrap = kit.el('label', 'dq-office-spinner');
  final caption = kit.el('span', 'dq-office-spinner-label');
  caption.appendText(label);
  wrap.append(caption);

  final input = kit.el('input', 'dq-office-spinner-input');
  input.setAttribute('type', 'number');
  input.setAttribute('step', isSpacing ? '2' : '0.25');
  input.setAttribute('min', '0');
  input.setAttribute('title', label);
  input.addEventListener('change', (_) {
    final typed = double.tryParse(input.value.replaceAll(',', '.'));
    if (typed == null || typed < 0) return;
    c.syncSelection();
    // Espaçamento em pontos → twips (1 pt = 20 twips); recuo em cm → twips.
    final twips = isSpacing ? (typed * 20).round() : (typed * 567).round();
    c.applyBlockStyle({styleKey: twips});
  });
  wrap.append(input);
  ctx.registerBlockStyleField(styleKey, input, toPoints: isSpacing);
  return wrap;
}

/// twips → "2,5 cm" (uma casa, vírgula decimal — o formato do Word em pt-BR).
String _cm(int twips) {
  final value = twips / 567.0;
  final rounded = (value * 100).round() / 100;
  return '${rounded.toStringAsFixed(2).replaceAll('.', ',')} cm';
}
