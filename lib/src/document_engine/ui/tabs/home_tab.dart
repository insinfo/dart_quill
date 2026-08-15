/// Aba Página Inicial — os grupos do Word: Área de Transferência, Fonte,
/// Parágrafo, Estilos (galeria de cartões) e Edição.
///
/// Tudo aqui passa pelo [OfficeWordController]; nenhum controle tem caminho
/// próprio para mudar o documento. Os botões de cor abrem uma PALETA
/// (popup do componente, sem dependência de browser).
library;

import '../../../platform/dom.dart';
import '../../office/style_catalog.dart';
import '../controller.dart';
import '../find_replace.dart';
import '../formatting_marks.dart';
import '../dialogs/dialog.dart';
import '../dialogs/paragraph_dialog.dart';
import '../dialogs/style_dialog.dart';
import '../menu.dart';
import '../ribbon.dart';
import '../ribbon_actions.dart' as actions;

/// Cores de fonte do Word (primeira linha da paleta padrão).
const List<String?> officeFontColors = [
  null, // Automático — remove a marca
  '#000000', '#c00000', '#ff0000', '#ffc000', '#ffff00', '#92d050',
  '#00b050', '#00b0f0', '#0070c0', '#002060', '#7030a0',
];

/// Cores de realce do Word.
const List<String?> officeHighlightColors = [
  null, // Sem cor
  '#ffff00', '#00ff00', '#00ffff', '#ff00ff', '#0000ff', '#ff0000',
  '#000080', '#008080', '#008000', '#800080', '#800000', '#808000',
  '#808080', '#c0c0c0',
];

List<DomElement> buildHomeTab(RibbonContext ctx) {
  final c = ctx.controller;
  final kit = ctx.kit;
  return [
    kit.group('Desfazer', [
      kit.row([
        kit.button('↶', 'Desfazer (Ctrl+Z)', () => c.runCommand('undo'),
            icon: 'undo'),
        kit.button('↷', 'Refazer (Ctrl+Y)', () => c.runCommand('redo'),
            icon: 'redo'),
      ]),
    ]),
    kit.group('Área de Transferência', [
      kit.row([
        kit.button(
            'Colar',
            'Colar (conteúdo copiado no editor; Ctrl+V '
                'cola do sistema)',
            () => actions.pasteInternal(c),
            extraClass: 'dq-office-btn-big dq-office-btn-labeled',
            icon: 'paste'),
        _column(kit, [
          kit.button(
              'Recortar', 'Recortar (Ctrl+X)', () => actions.cutSelection(c),
              extraClass: 'dq-office-btn-labeled dq-office-btn-small',
              icon: 'cut'),
          kit.button(
              'Copiar', 'Copiar (Ctrl+C)', () => actions.copySelection(c),
              extraClass: 'dq-office-btn-labeled dq-office-btn-small',
              icon: 'copy'),
          kit.button(
              'Pincel',
              'Pincel de Formatação — copia a formatação '
                  'e aplica na próxima seleção',
              () => actions.armFormatPainter(c),
              extraClass: 'dq-office-btn-labeled dq-office-btn-small',
              icon: 'copystyle'),
        ]),
      ]),
    ]),
    kit.group('Fonte', [
      kit.row([
        buildFontFamilyCombo(ctx),
        buildFontSizeCombo(ctx),
        kit.button(
            'A^', 'Aumentar Fonte', () => actions.stepFontSize(c, up: true),
            icon: 'incfont'),
        kit.button(
            'A˅', 'Diminuir Fonte', () => actions.stepFontSize(c, up: false),
            icon: 'decfont'),
        kit.button(
            'Aa', 'Alternar maiúsculas/minúsculas', () => actions.toggleCase(c),
            icon: 'change-case'),
        kit.button(
            '⌫a', 'Limpar Toda a Formatação', () => actions.clearFormatting(c),
            icon: 'clearstyle'),
      ]),
      kit.row([
        ctx.markButton('bold', 'N', 'Negrito (Ctrl+B)', 'dq-office-b',
            icon: 'bold'),
        ctx.markButton('italic', 'I', 'Itálico (Ctrl+I)', 'dq-office-i',
            icon: 'italic'),
        ctx.markButton('underline', 'S', 'Sublinhado (Ctrl+U)', 'dq-office-u',
            icon: 'underline'),
        ctx.markButton('strike', 'abc', 'Tachado', 'dq-office-s',
            icon: 'strikeout'),
        () {
          final button = kit.button(
              'x₂', 'Subscrito', () => actions.toggleScript(c, 'sub'),
              icon: 'subscript');
          ctx.registerMarkValueButton('script', 'sub', button);
          return button;
        }(),
        () {
          final button = kit.button(
              'x²', 'Sobrescrito', () => actions.toggleScript(c, 'super'),
              icon: 'superscript');
          ctx.registerMarkValueButton('script', 'super', button);
          return button;
        }(),
        buildPaletteButton(ctx,
            icon: 'highlight',
            text: 'ab',
            title: 'Cor do Realce do Texto',
            mark: 'background',
            colors: officeHighlightColors),
        buildPaletteButton(ctx,
            icon: 'fontcolor',
            text: 'A',
            title: 'Cor da Fonte',
            mark: 'color',
            colors: officeFontColors),
      ]),
    ]),
    kit.group('Parágrafo', [
      kit.row([
        _splitButton(
          ctx,
          text: '•—',
          title: 'Marcadores',
          icon: 'setmarkers',
          onClick: () => actions.toggleList(c, 'bullet'),
          menuGroup: 'home:bullets',
          menuTitle: 'Biblioteca de Marcadores',
          entries: () => _bulletEntries(c),
        ),
        _splitButton(
          ctx,
          text: '1—',
          title: 'Numeração',
          icon: 'numbering',
          onClick: () => actions.toggleList(c, 'ordered'),
          menuGroup: 'home:numbering',
          menuTitle: 'Biblioteca de Numeração',
          entries: () => _numberingEntries(c),
        ),
        menuButton(c, '⋮≡', 'Lista de Vários Níveis', 'home:multilevel',
            () => _multilevelEntries(c),
            icon: 'multilevels'),
        kit.button('⇤', 'Diminuir Recuo', () => actions.indentBy(c, -720),
            icon: 'decoffset'),
        kit.button('⇥', 'Aumentar Recuo', () => actions.indentBy(c, 720),
            icon: 'incoffset'),
        buildFormattingMarksButton(c),
      ]),
      kit.row([
        kit.button('⯇', 'Alinhar à esquerda', () => actions.setAlign(c, 'left'),
            icon: 'align-left'),
        kit.button('☰', 'Centralizar', () => actions.setAlign(c, 'center'),
            icon: 'align-center'),
        kit.button('⯈', 'Alinhar à direita', () => actions.setAlign(c, 'right'),
            icon: 'align-right'),
        kit.button('▤', 'Justificar', () => actions.setAlign(c, 'justify'),
            icon: 'align-just'),
        menuButton(c, '↕≡', 'Espaçamento entre Linhas e Parágrafos',
            'home:linespacing', () => _lineSpacingEntries(c),
            icon: 'linespace'),
        buildParagraphShadingButton(ctx),
        menuButton(c, '▤', 'Bordas', 'home:paraborders',
            () => _paragraphBorderEntries(c),
            icon: 'border-all'),
      ]),
    ]),
    kit.group('Estilos', [
      kit.row(buildStyleGallery(ctx)),
    ]),
    kit.group('Edição', [
      kit.row([
        kit.button('Selecionar Tudo', 'Selecionar Tudo (Ctrl+A)',
            () => c.runCommand('selectAll')),
        kit.button('🔍', 'Localizar (Ctrl+F)',
            () => officeFindPanel(c).open(withReplace: false),
            icon: 'search'),
        kit.button('⇄', 'Substituir (Ctrl+H)',
            () => officeFindPanel(c).open(withReplace: true),
            icon: 'replace'),
      ]),
    ]),
  ];
}

// -- grupo Parágrafo: galerias de lista, entrelinha, sombreamento e bordas ----

/// A biblioteca de marcadores.
///
/// São caracteres Unicode, não os code points da faixa privada de
/// Wingdings/Symbol que o Word grava: o navegador desenha um quadrado vazio
/// para aqueles (é a mesma razão de `OfficeNumberingCounter._unicodeBullet`
/// traduzir os importados).
const List<({String char, String name})> officeBulletGallery = [
  (char: '•', name: 'Círculo cheio'),
  (char: '○', name: 'Círculo vazado'),
  (char: '▪', name: 'Quadrado cheio'),
  (char: '◦', name: 'Círculo pequeno'),
  (char: '➢', name: 'Seta'),
  (char: '✓', name: 'Marca de seleção'),
  (char: '❖', name: 'Losango'),
];

/// A biblioteca de numeração: o `w:numFmt` e o `w:lvlText` de cada formato.
const List<({String sample, String numFmt, String lvlText})>
    officeNumberingGallery = [
  (sample: '1.  2.  3.', numFmt: 'decimal', lvlText: '%1.'),
  (sample: '1)  2)  3)', numFmt: 'decimal', lvlText: '%1)'),
  (sample: 'I.  II.  III.', numFmt: 'upperRoman', lvlText: '%1.'),
  (sample: 'i.  ii.  iii.', numFmt: 'lowerRoman', lvlText: '%1.'),
  (sample: 'A.  B.  C.', numFmt: 'upperLetter', lvlText: '%1.'),
  (sample: 'a)  b)  c)', numFmt: 'lowerLetter', lvlText: '%1)'),
];

/// Os esquemas de "Lista de Vários Níveis" que o editor entrega.
///
/// São todos de MARCADOR, e não por gosto: um esquema numerado precisaria de
/// um contador POR NÍVEL, e o compositor mantém um só para o documento
/// inteiro (`layout_composer.dart`, `listOrdinal`). Os esquemas numerados
/// aparecem no menu desabilitados, com o motivo escrito — ver
/// [_multilevelEntries].
const List<({String name, List<String> levels})> officeMultilevelBulletSchemes =
    [
  (name: '●  ○  ▪', levels: ['•', '○', '▪']),
  (name: '▪  •  ◦', levels: ['▪', '•', '◦']),
  (name: '➢  ▪  ◦', levels: ['➢', '▪', '◦']),
];

/// Cores de sombreamento de parágrafo. É a mesma grade do sombreamento de
/// célula — no Word é literalmente a mesma paleta.
const List<String?> officeParagraphShadingColors = [
  null, // Sem cor — remove o `w:shd`
  '#000000', '#c00000', '#ff0000', '#ffc000', '#ffff00', '#92d050',
  '#00b050', '#00b0f0', '#0070c0', '#002060', '#7030a0',
  '#ffffff', '#f2f2f2', '#d9d9d9', '#bfbfbf', '#a6a6a6', '#808080',
];

/// A biblioteca de marcadores: cada item aplica um `lvlText` diferente.
List<OfficeMenuEntry> _bulletEntries(OfficeWordController c) {
  c.syncSelection();
  final current = actions.currentListLvlText(c);
  return [
    OfficeMenuEntry(
      label: 'Nenhum',
      description: 'O parágrafo deixa de ser item de lista',
      checked: !actions.selectionIsList(c),
      onSelect: () => actions.removeList(c),
    ),
    const OfficeMenuEntry.separator(),
    for (final bullet in officeBulletGallery)
      OfficeMenuEntry(
        label: '${bullet.char}   ${bullet.char}   ${bullet.char}',
        description: bullet.name,
        checked: current == bullet.char,
        onSelect: () => actions.applyListFormat(
          c,
          kind: 'bullet',
          lvlText: bullet.char,
          numFmt: 'bullet',
        ),
      ),
  ];
}

/// A biblioteca de numeração.
List<OfficeMenuEntry> _numberingEntries(OfficeWordController c) {
  c.syncSelection();
  final current = actions.currentListLvlText(c);
  return [
    OfficeMenuEntry(
      label: 'Nenhum',
      description: 'O parágrafo deixa de ser item de lista',
      checked: !actions.selectionIsList(c),
      onSelect: () => actions.removeList(c),
    ),
    const OfficeMenuEntry.separator(),
    for (final format in officeNumberingGallery)
      OfficeMenuEntry(
        label: format.sample,
        // O ✓ compara o PAR: "1." e "I." têm o mesmo `lvlText` e só o
        // `numFmt` os separa.
        checked: current == format.lvlText &&
            actions.currentListNumFmt(c) == format.numFmt,
        onSelect: () => actions.applyListFormat(
          c,
          kind: 'ordered',
          lvlText: format.lvlText,
          numFmt: format.numFmt,
        ),
      ),
  ];
}

/// O menu "Lista de Vários Níveis".
///
/// Os esquemas de marcador funcionam ponta a ponta: o marcador de cada nível
/// é resolvido na composição a partir da lista gravada em `style.lvlText`, e
/// a exportação gera um `w:abstractNum` `hybridMultilevel` com um `w:lvl` por
/// nível — Tab/Aumentar Nível troca o marcador sem reescrever o parágrafo.
///
/// Os esquemas NUMERADOS ("1.1.1") ficam visíveis e desabilitados. O motivo é
/// verificável: o compositor mantém UM contador de lista para o documento
/// (`layout_composer.dart`, a variável `listOrdinal`, que também viaja na
/// assinatura de página e no resume da paginação progressiva). Sem um
/// contador por nível, "1.1" sairia como "1.2" no primeiro subitem — um
/// número errado é pior que um item indisponível.
List<OfficeMenuEntry> _multilevelEntries(OfficeWordController c) {
  c.syncSelection();
  final isList = actions.selectionIsList(c);
  final current = actions.currentListLvlText(c);
  const numberedReason = 'Precisa de um contador por NÍVEL; o compositor '
      'mantém um só para o documento inteiro';
  return [
    for (final scheme in officeMultilevelBulletSchemes)
      OfficeMenuEntry(
        label: scheme.name,
        description: 'Um marcador por nível',
        checked: current is List &&
            current.length == scheme.levels.length &&
            List.generate(
                    scheme.levels.length, (i) => current[i] == scheme.levels[i])
                .every((equal) => equal),
        onSelect: () => actions.applyListFormat(
          c,
          kind: 'bullet',
          lvlText: List<String>.from(scheme.levels),
          numFmt: List<String>.filled(scheme.levels.length, 'bullet'),
        ),
      ),
    const OfficeMenuEntry.separator(),
    OfficeMenuEntry(
      label: 'Aumentar Nível da Lista',
      icon: 'incoffset',
      enabled: isList,
      onSelect: () => actions.changeListLevel(c, 1),
    ),
    OfficeMenuEntry(
      label: 'Diminuir Nível da Lista',
      icon: 'decoffset',
      enabled: isList,
      onSelect: () => actions.changeListLevel(c, -1),
    ),
    const OfficeMenuEntry.separator(),
    const OfficeMenuEntry(
      label: '1.  1.1.  1.1.1.',
      description: numberedReason,
      enabled: false,
    ),
    const OfficeMenuEntry(
      label: 'I.  A.  1.',
      description: numberedReason,
      enabled: false,
    ),
  ];
}

/// O menu "Espaçamento entre Linhas e Parágrafos".
List<OfficeMenuEntry> _lineSpacingEntries(OfficeWordController c) {
  c.syncSelection();
  final current = actions.currentLineTwips(c);
  final before = actions.currentParagraphSpace(c, before: true);
  final after = actions.currentParagraphSpace(c, before: false);
  return [
    for (final step in actions.officeLineSpacingSteps)
      OfficeMenuEntry(
        label: step.label,
        // Sem `w:line` o parágrafo usa a caixa real da fonte, que é
        // exatamente o que 1,0 significa — por isso o ✓ cai em 1,0 quando o
        // bloco não opinou.
        checked: current == null ? step.twips == 240 : current == step.twips,
        onSelect: () => actions.setLineSpacing(c, step.twips),
      ),
    const OfficeMenuEntry.separator(),
    OfficeMenuEntry(
      label: before > 0
          ? 'Remover Espaço Antes do Parágrafo'
          : 'Adicionar Espaço Antes do Parágrafo',
      description: '12 pt, como o comando do Word',
      onSelect: () => actions.setParagraphSpace(
        c,
        before: true,
        twips: before > 0 ? 0 : actions.officeParagraphSpaceStepTwips,
      ),
    ),
    OfficeMenuEntry(
      label: after > 0
          ? 'Remover Espaço Depois do Parágrafo'
          : 'Adicionar Espaço Depois do Parágrafo',
      description: '12 pt, como o comando do Word',
      onSelect: () => actions.setParagraphSpace(
        c,
        before: false,
        twips: after > 0 ? 0 : actions.officeParagraphSpaceStepTwips,
      ),
    ),
    const OfficeMenuEntry.separator(),
    OfficeMenuEntry(
      label: 'Opções de Espaçamento de Linha…',
      onSelect: () => openParagraphDialog(c),
    ),
  ];
}

/// O menu Bordas do grupo Parágrafo.
///
/// "Todas as Bordas" do Word desenha também a linha ENTRE parágrafos vizinhos
/// com a mesma moldura (`w:between`). O modelo importa a chave, mas nem o
/// compositor nem os renderers desenham essa aresta — cada parágrafo é uma
/// caixa independente no `PageGraph`. O item fica visível e desabilitado; as
/// sete combinações restantes são desenhadas de verdade, na tela e no PDF.
List<OfficeMenuEntry> _paragraphBorderEntries(OfficeWordController c) {
  return [
    for (final (which, label, icon) in const [
      (actions.OfficeParagraphBorders.none, 'Sem Borda', 'border-no'),
      (actions.OfficeParagraphBorders.box, 'Caixa', 'border-out'),
      (
        actions.OfficeParagraphBorders.topAndBottom,
        'Bordas Superior e Inferior',
        'border-insidehor'
      ),
      (actions.OfficeParagraphBorders.top, 'Borda Superior', 'border-top'),
      (
        actions.OfficeParagraphBorders.bottom,
        'Borda Inferior',
        'border-bottom'
      ),
      (actions.OfficeParagraphBorders.left, 'Borda Esquerda', 'border-left'),
      (actions.OfficeParagraphBorders.right, 'Borda Direita', 'border-right'),
    ])
      OfficeMenuEntry(
        label: label,
        icon: icon,
        onSelect: () => actions.setParagraphBorders(c, which),
      ),
    const OfficeMenuEntry.separator(),
    const OfficeMenuEntry(
      label: 'Todas as Bordas',
      description: 'Exigiria a aresta w:between entre parágrafos vizinhos, '
          'que o compositor não desenha',
      icon: 'border-all',
      enabled: false,
    ),
  ];
}

/// Botão de sombreamento de PARÁGRAFO, com a mesma paleta dos outros.
///
/// Não deu para reusar [buildPaletteButton]: lá a cor vira uma MARCA sobre o
/// texto e aqui vira `w:shd` do parágrafo — o popup é o mesmo, o
/// destinatário não.
DomElement buildParagraphShadingButton(RibbonContext ctx) {
  final kit = ctx.kit;
  final c = ctx.controller;
  final wrap = kit.el('span', 'dq-office-colorwrap');
  const group = 'palette:paragraphShading';

  DomElement buildPalette() {
    final palette = kit.el('div', 'dq-office-palette');
    for (final color in officeParagraphShadingColors) {
      final swatch = kit.el('button',
          'dq-office-swatch${color == null ? ' dq-office-swatch-none' : ''}');
      swatch.setAttribute('type', 'button');
      swatch.setAttribute('title', color ?? 'Sem cor');
      swatch.setAttribute('data-paragraph-shading', color ?? 'none');
      if (color != null) swatch.setAttribute('style', 'background:$color;');
      swatch.addEventListener('click', (event) {
        event.preventDefault();
        c.overlay.closeGroup(group);
        c.syncSelection();
        actions.setParagraphShading(c, color);
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

/// Botão dividido do Word: o corpo executa a ação padrão, a setinha ao lado
/// abre a galeria. Um botão só obrigaria dois cliques para ligar uma lista
/// simples, que é a operação mais comum do grupo.
DomElement _splitButton(
  RibbonContext ctx, {
  required String text,
  required String title,
  required String icon,
  required void Function() onClick,
  required String menuGroup,
  required String menuTitle,
  required List<OfficeMenuEntry> Function() entries,
}) {
  final kit = ctx.kit;
  final wrap = kit.el('span', 'dq-office-splitbtn');
  wrap.append(kit.button(text, title, onClick, icon: icon));
  final arrow = kit.el('span', 'dq-office-splitbtn-arrow');
  arrow.append(kit.button('', menuTitle, () {
    openMenu(ctx.controller, menuGroup, arrow, entries());
  }, extraClass: 'dq-office-btn-menu'));
  wrap.append(arrow);
  return wrap;
}

/// As famílias que o seletor de fonte oferece.
///
/// A lista do Word é a das fontes INSTALADAS; num editor web isso não
/// existe. Ficamos com as faces seguras de Office/web, e o combobox é
/// editável — a fonte que veio de um DOCX (`Ecofont`, `Aptos`…) é exibida e
/// preservada mesmo fora desta lista, que era o defeito do `<select>`.
const List<String> officeFontFamilies = [
  'Arial',
  'Arial Black',
  'Arial Narrow',
  'Bookman Old Style',
  'Calibri',
  'Cambria',
  'Candara',
  'Century Gothic',
  'Comic Sans MS',
  'Consolas',
  'Constantia',
  'Corbel',
  'Courier New',
  'Franklin Gothic Book',
  'Garamond',
  'Georgia',
  'Impact',
  'Lucida Console',
  'Lucida Sans Unicode',
  'Palatino Linotype',
  'Segoe UI',
  'Symbol',
  'Tahoma',
  'Times New Roman',
  'Trebuchet MS',
  'Verdana',
  'Wingdings',
];

/// Combobox de família, compartilhado pela ribbon e pela quickbar.
DomElement buildFontFamilyCombo(RibbonContext ctx, {String? extraClass}) {
  final combo = OfficeComboBox(
    controller: ctx.controller,
    cssClass:
        'dq-office-font-family${extraClass == null ? '' : ' $extraClass'}',
    items: officeFontFamilies,
    title: 'Fonte',
    previewFontPerItem: true,
    onCommit: (value) =>
        actions.addMarkOverSelection(ctx.controller, 'font', {'value': value}),
  );
  final element = combo.build();
  ctx.registerInlineCombo('font', combo);
  return element;
}

/// Combobox de tamanho: aceita digitar valores fora da escada (10,5 pt é
/// comum em ofícios) e rejeita entradas impossíveis devolvendo o valor do
/// modelo.
DomElement buildFontSizeCombo(RibbonContext ctx, {String? extraClass}) {
  final combo = OfficeComboBox(
    controller: ctx.controller,
    cssClass: 'dq-office-font-size${extraClass == null ? '' : ' $extraClass'}',
    items: const [
      '8',
      '9',
      '10',
      '10.5',
      '11',
      '12',
      '14',
      '16',
      '18',
      '20',
      '22',
      '24',
      '26',
      '28',
      '36',
      '48',
      '72',
    ],
    title: 'Tamanho da Fonte',
    parseValue: parseFontSize,
    onCommit: (value) => actions
        .addMarkOverSelection(ctx.controller, 'size', {'value': '${value}pt'}),
  );
  final element = combo.build();
  ctx.registerInlineCombo('size', combo);
  return element;
}

/// Normaliza o tamanho digitado. Aceita vírgula decimal (o teclado
/// brasileiro), corta em 1–1638 pt (o limite do Word) e devolve null para
/// qualquer coisa que não seja um corpo válido.
String? parseFontSize(String raw) {
  final points =
      double.tryParse(raw.replaceAll('pt', '').replaceAll(',', '.').trim());
  if (points == null || points < 1 || points > 1638) return null;
  // O Word grava meio ponto (half-points no OOXML): 10,3 vira 10,5.
  final snapped = (points * 2).round() / 2;
  return snapped == snapped.roundToDouble() ? '${snapped.round()}' : '$snapped';
}

/// Coluna de botões pequenos ao lado do botão grande (padrão do grupo Área
/// de Transferência do Word).
DomElement _column(OfficeDomKit kit, List<DomElement> buttons) {
  final column = kit.el('div', 'dq-office-btn-col');
  for (final button in buttons) {
    column.append(button);
  }
  return column;
}

/// Botão de cor com PALETA: clique abre/fecha o popup de amostras; escolher
/// uma aplica a marca ([mark]) na seleção. `null` = Automático/Sem cor.
///
/// A paleta abre no [OfficeOverlay] — não mais escondida por classe dentro
/// do grupo da ribbon, onde herdava recorte e ficava presa ao layout do
/// botão.
DomElement buildPaletteButton(RibbonContext ctx,
    {required String icon,
    required String text,
    required String title,
    required String mark,
    required List<String?> colors,
    String? extraClass}) {
  final kit = ctx.kit;
  final controller = ctx.controller;
  final wrap = kit.el(
      'span', 'dq-office-colorwrap${extraClass == null ? '' : ' $extraClass'}');
  final group = 'palette:$mark';

  DomElement buildPalette() {
    final palette = kit.el('div', 'dq-office-palette');
    for (final color in colors) {
      final swatch = kit.el('button',
          'dq-office-swatch${color == null ? ' dq-office-swatch-none' : ''}');
      swatch.setAttribute('type', 'button');
      swatch.setAttribute('title', color ?? 'Sem cor');
      if (color != null) swatch.setAttribute('style', 'background:$color;');
      swatch.addEventListener('click', (event) {
        event.preventDefault();
        controller.overlay.closeGroup(group);
        controller.syncSelection();
        actions.applyMarkColor(controller, mark, color);
      });
      palette.append(swatch);
    }
    return palette;
  }

  wrap.append(kit.button(text, title, () {
    // Clicar de novo fecha — comportamento de toda galeria da ribbon.
    if (controller.overlay.closeGroup(group)) return;
    controller.overlay.open(group, buildPalette(), anchor: wrap);
  }, icon: icon));
  return wrap;
}

/// A GALERIA de estilos: os do documento aberto, ou os quatro fixos.
///
/// Com um DOCX importado, os cartões são os estilos `w:qFormat` do próprio
/// arquivo, com o nome e o preview reais — é a diferença entre oferecer
/// "Título 1" a um documento cujo estilo se chama "Nível 01" e mostrar a
/// galeria que o Word mostraria.
///
/// Sem catálogo (documento novo, Delta do Quill) a galeria continua sendo a
/// fixa de Normal/Título 1–3. Não é um placeholder: um documento sem
/// `styles.xml` não TEM estilos nomeados, e esses quatro são exatamente os
/// que [actions.applyNamedStyle] sabe aplicar pela heurística de heading.
/// **A galeria é uma JANELA, não uma fileira.** Um DOCX real traz dezenas de
/// estilos `w:qFormat` (o ETP traz 20, o TR mais de 30); despejá-los todos
/// numa `dq-office-ribbon-row` fazia a faixa de opções crescer sem limite e
/// nascer com uma barra de rolagem horizontal atravessando a ribbon inteira —
/// o que o Word nunca faz. O Word mostra os cartões que cabem e oferece
/// ▲/▼ para percorrer, mais o botão "Mais" que abre a galeria completa num
/// painel. É exatamente esta a estrutura abaixo.
List<DomElement> buildStyleGallery(RibbonContext ctx) =>
    [_styleGalleryViewport(ctx)];

/// Os cartões da galeria, na ordem do Word (o `w:default` primeiro).
List<DomElement> _styleCards(RibbonContext ctx, {required bool register}) {
  final catalog = ctx.controller.styleCatalog;
  final gallery = catalog?.gallery ?? const <OfficeStyleDefinition>[];
  if (gallery.isEmpty) {
    return [
      for (final (name, styleId, preview) in const [
        ('Normal', 'Normal', 'AaBbCcD'),
        ('Título 1', 'Heading1', 'AaBbC'),
        ('Título 2', 'Heading2', 'AaBbCcD'),
        ('Título 3', 'Heading3', 'AaBbCcD'),
      ])
        _fixedStyleCard(ctx, name, styleId, preview, register: register),
    ];
  }
  return [
    for (final style in gallery)
      _catalogStyleCard(ctx, style, register: register),
    // "Criar um Estilo" do Word: só existe com catálogo, porque criar um
    // estilo sem `styles.xml` para gravá-lo seria um cartão que some no
    // próximo save.
    ctx.kit.button(
      '+ Estilo',
      'Criar Novo Estilo a partir da formatação da seleção',
      () => openCreateStyleDialog(ctx.controller),
      extraClass: 'dq-office-stylecard-new',
    ),
  ];
}

/// A janela: trilha recortada (`overflow:hidden`) + a coluna ▲ ▼ ⌄.
DomElement _styleGalleryViewport(RibbonContext ctx) {
  final kit = ctx.kit;
  final viewport = kit.el('div', 'dq-office-stylegallery');
  final track = kit.el('div', 'dq-office-stylegallery-track');
  for (final card in _styleCards(ctx, register: true)) {
    track.append(card);
  }
  viewport.append(track);

  // Uma "página" é a largura visível da trilha — o mesmo passo do ▲/▼ do
  // Word, que anda uma fileira inteira e não um cartão.
  void step(int direction) {
    final page = track.clientWidth > 0 ? track.clientWidth.toDouble() : 300.0;
    track.scrollBy(direction * page, 0);
  }

  final nav = kit.el('div', 'dq-office-stylegallery-nav');
  nav.append(kit.button('▲', 'Fileira anterior', () => step(-1),
      extraClass: 'dq-office-stylegallery-arrow'));
  nav.append(kit.button('▼', 'Próxima fileira', () => step(1),
      extraClass: 'dq-office-stylegallery-arrow'));
  nav.append(kit.button(
    '⌄',
    'Mais estilos',
    () => _openStyleGalleryPanel(ctx, viewport),
    extraClass: 'dq-office-stylegallery-arrow dq-office-stylegallery-more',
  ));
  viewport.append(nav);
  return viewport;
}

const String officeStyleGalleryGroup = 'home:stylegallery';

/// O painel "Mais" — a galeria inteira em grade, ancorada no próprio botão.
///
/// Os cartões daqui NÃO se registram no realce de estado: o mapa da ribbon é
/// indexado por `styleId`, e registrar os dois faria o cartão do painel
/// (descartado ao fechar) substituir o da faixa, apagando o realce da
/// galeria que fica na tela.
void _openStyleGalleryPanel(RibbonContext ctx, DomElement anchor) {
  final controller = ctx.controller;
  if (controller.overlay.closeGroup(officeStyleGalleryGroup)) return;
  final grid = ctx.kit.el('div', 'dq-office-stylegallery-panel');
  final current = actions.currentStyleId(controller);
  for (final card in _styleCards(ctx, register: false)) {
    if (card.getAttribute('data-style-id') == current) {
      card.classes.add('dq-office-stylecard-active');
    }
    card.addEventListener('click',
        (_) => controller.overlay.closeGroup(officeStyleGalleryGroup));
    grid.append(card);
  }
  controller.overlay.open(officeStyleGalleryGroup, grid, anchor: anchor);
}

/// Cartão dos quatro estilos embutidos (sem catálogo).
DomElement _fixedStyleCard(
    RibbonContext ctx, String name, String styleId, String preview,
    {bool register = true}) {
  final card = _cardShell(ctx, name, styleId, preview, register: register);
  card.addEventListener('click', (event) {
    event.preventDefault();
    actions.applyNamedStyle(ctx.controller, name);
  });
  return card;
}

/// Cartão de um estilo DO DOCUMENTO: preview com a fonte, o corpo, a cor e
/// os atributos reais, mais o menu de contexto de gestão.
DomElement _catalogStyleCard(RibbonContext ctx, OfficeStyleDefinition style,
    {bool register = true}) {
  final preview = style.preview;
  final card = _cardShell(
    ctx,
    style.name,
    style.id,
    // O Word encurta a amostra quando a fonte é grande, senão o cartão só
    // mostraria "Aa". A régua é o corpo do próprio estilo.
    (preview.sizePt ?? 12) >= 16 ? 'AaBbC' : 'AaBbCcDd',
    preview: preview,
    register: register,
  );
  card.addEventListener('click', (event) {
    event.preventDefault();
    actions.applyCatalogStyle(ctx.controller, style.id);
  });
  card.addEventListener('contextmenu', (event) {
    event.preventDefault();
    _openStyleCardMenu(ctx.controller, style, event);
  });
  return card;
}

DomElement _cardShell(
  RibbonContext ctx,
  String name,
  String styleId,
  String sampleText, {
  OfficeStylePreview? preview,
  bool register = true,
}) {
  final kit = ctx.kit;
  final card = kit.el(
      'button', 'dq-office-stylecard dq-office-stylecard-${styleSlug(name)}');
  card.setAttribute('type', 'button');
  card.setAttribute('title', name);
  // O id fica no DOM porque é a identidade do cartão para teste e
  // automação: o rótulo pode ser renomeado pelo menu de contexto.
  card.setAttribute('data-style-id', styleId);
  final sample = kit.el('span', 'dq-office-stylecard-sample');
  if (preview != null) {
    final css = _previewCss(preview);
    if (css.isNotEmpty) sample.setAttribute('style', css);
  }
  sample.appendText(sampleText);
  card.append(sample);
  final label = kit.el('span', 'dq-office-stylecard-label');
  label.appendText(name);
  card.append(label);
  if (register) ctx.registerStyleCard(styleId, card);
  return card;
}

/// O CSS da amostra do cartão.
///
/// O corpo é escalado e travado entre 9 e 20 px: um estilo de 36 pt
/// desenhado em tamanho real arrebentaria a altura da faixa de opções, e um
/// de 6 pt viraria um borrão. A proporção entre os cartões continua legível,
/// que é a informação que o preview carrega.
String _previewCss(OfficeStylePreview preview) {
  final buffer = StringBuffer();
  if (preview.family != null) {
    buffer.write("font-family:'${preview.family}';");
  }
  final size = preview.sizePt;
  if (size != null) {
    final px = (size * 96 / 72 * 0.62).clamp(9.0, 20.0);
    buffer.write('font-size:${px.toStringAsFixed(1)}px;');
  }
  if (preview.bold) buffer.write('font-weight:700;');
  if (preview.italic) buffer.write('font-style:italic;');
  if (preview.underline) buffer.write('text-decoration:underline;');
  if (preview.color != null) buffer.write('color:${preview.color};');
  if (preview.align == 'center') buffer.write('text-align:center;');
  if (preview.align == 'right') buffer.write('text-align:right;');
  return buffer.toString();
}

/// O menu de botão direito do cartão — os quatro comandos do Word.
void _openStyleCardMenu(
    OfficeWordController controller, OfficeStyleDefinition style, DomEvent e) {
  final position = e is DomMouseEvent ? (e.clientX, e.clientY) : (0.0, 0.0);
  openMenuAt(controller, 'stylecard:${style.id}', position.$1, position.$2, [
    OfficeMenuEntry(
      label: 'Atualizar ${style.name} para Corresponder à Seleção',
      icon: 'copystyle',
      onSelect: () => actions.updateStyleToMatchSelection(controller, style.id),
    ),
    OfficeMenuEntry(
      label: 'Modificar…',
      icon: 'clearstyle',
      onSelect: () => openModifyStyleDialog(controller, style.id),
    ),
    OfficeMenuEntry(
      label: 'Renomear…',
      onSelect: () => _openRenameDialog(controller, style),
    ),
    const OfficeMenuEntry.separator(),
    OfficeMenuEntry(
      label: 'Remover da Galeria',
      // Desabilitado no estilo default: sem "Normal" a galeria não teria
      // caminho de volta ao corpo do texto.
      enabled: !style.isDefault,
      onSelect: () => actions.removeStyleFromGallery(controller, style.id),
    ),
  ]);
}

void _openRenameDialog(
    OfficeWordController controller, OfficeStyleDefinition style) {
  OfficeDialog(
    controller: controller,
    title: 'Renomear Estilo',
    fields: [
      OfficeDialogField(
        key: 'name',
        label: 'Nome',
        kind: 'text',
        value: style.name,
        hint: 'o identificador do estilo (${style.id}) não muda — é ele que '
            'os parágrafos referenciam',
      ),
    ],
    onApply: (values) =>
        actions.renameCatalogStyle(controller, style.id, values['name'] ?? ''),
  ).open();
}

/// B4: nome de estilo → sufixo de classe CSS seguro.
///
/// Os nomes reais de um DOCX (`Nível 1-SemNum`, `Título 2 - Recuado`,
/// `Ênfase (forte)`) têm acentos, espaços, parênteses e barras; concatenar
/// isso numa classe produzia seletor inválido. Aqui: acentos são
/// transliterados, qualquer outro caractere fora de `a-z0-9` vira hífen, e
/// um nome que não sobra nada usável cai num hash estável — a classe é só um
/// gancho de estilização, nunca a identidade do estilo.
String styleSlug(String name) {
  const accents = {
    'á': 'a',
    'à': 'a',
    'â': 'a',
    'ã': 'a',
    'ä': 'a',
    'é': 'e',
    'ê': 'e',
    'è': 'e',
    'ë': 'e',
    'í': 'i',
    'ì': 'i',
    'î': 'i',
    'ï': 'i',
    'ó': 'o',
    'ò': 'o',
    'ô': 'o',
    'õ': 'o',
    'ö': 'o',
    'ú': 'u',
    'ù': 'u',
    'û': 'u',
    'ü': 'u',
    'ç': 'c',
    'ñ': 'n',
  };
  final buffer = StringBuffer();
  for (final character in name.toLowerCase().split('')) {
    buffer.write(accents[character] ?? character);
  }
  final slug = buffer
      .toString()
      .replaceAll(RegExp('[^a-z0-9]+'), '-')
      .replaceAll(RegExp('^-+|-+\$'), '');
  return slug.isEmpty ? 'estilo-${name.hashCode.toUnsigned(16)}' : slug;
}

/// Os controles da toolbar compacta do modo flow.
List<DomElement> buildCompactControls(RibbonContext ctx) {
  final c = ctx.controller;
  final kit = ctx.kit;
  return [
    kit.button('↶', 'Desfazer (Ctrl+Z)', () => c.runCommand('undo'),
        icon: 'undo'),
    kit.button('↷', 'Refazer (Ctrl+Y)', () => c.runCommand('redo'),
        icon: 'redo'),
    kit.el('span', 'dq-office-ribbon-sep'),
    ctx.markButton('bold', 'B', 'Negrito (Ctrl+B)', 'dq-office-b',
        icon: 'bold'),
    ctx.markButton('italic', 'I', 'Itálico (Ctrl+I)', 'dq-office-i',
        icon: 'italic'),
    ctx.markButton('underline', 'U', 'Sublinhado (Ctrl+U)', 'dq-office-u',
        icon: 'underline'),
    ctx.markButton('strike', 'S', 'Tachado', 'dq-office-s', icon: 'strikeout'),
    kit.el('span', 'dq-office-ribbon-sep'),
    () {
      final select = kit.select(
        'dq-office-style',
        const ['Normal', 'Título 1', 'Título 2', 'Título 3'],
        'Normal',
        (value) => actions.applyNamedStyle(c, value),
      );
      ctx.registerStyleSelect(select);
      return select;
    }(),
  ];
}
