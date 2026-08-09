/// Aba Página Inicial — os grupos do Word: Área de Transferência, Fonte,
/// Parágrafo, Estilos (galeria de cartões) e Edição.
///
/// Tudo aqui passa pelo [OfficeWordController]; nenhum controle tem caminho
/// próprio para mudar o documento. Os botões de cor abrem uma PALETA
/// (popup do componente, sem dependência de browser).
library;

import '../../../platform/dom.dart';
import '../controller.dart';
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
        kit.button(
            '•—', 'Lista com marcadores', () => actions.toggleList(c, 'bullet'),
            icon: 'setmarkers'),
        kit.button(
            '1—', 'Lista numerada', () => actions.toggleList(c, 'ordered'),
            icon: 'numbering'),
        kit.button('⇤', 'Diminuir Recuo', () => actions.indentBy(c, -720),
            icon: 'decoffset'),
        kit.button('⇥', 'Aumentar Recuo', () => actions.indentBy(c, 720),
            icon: 'incoffset'),
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
      ]),
    ]),
    kit.group('Estilos', [
      kit.row([
        for (final (name, preview) in const [
          ('Normal', 'AaBbCcD'),
          ('Título 1', 'AaBbC'),
          ('Título 2', 'AaBbCcD'),
          ('Título 3', 'AaBbCcD'),
        ])
          _styleCard(ctx, name, preview),
      ]),
    ]),
    kit.group('Edição', [
      kit.row([
        kit.button('Selecionar Tudo', 'Selecionar Tudo (Ctrl+A)',
            () => c.runCommand('selectAll')),
      ]),
    ]),
  ];
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

/// Cartão da galeria de Estilos (AaBbCcD + rótulo), com realce do ativo.
DomElement _styleCard(RibbonContext ctx, String name, String preview) {
  final kit = ctx.kit;
  final card = kit.el(
      'button', 'dq-office-stylecard dq-office-stylecard-${styleSlug(name)}');
  card.setAttribute('type', 'button');
  card.setAttribute('title', name);
  final sample = kit.el('span', 'dq-office-stylecard-sample');
  sample.appendText(preview);
  card.append(sample);
  final label = kit.el('span', 'dq-office-stylecard-label');
  label.appendText(name);
  card.append(label);
  card.addEventListener('click', (event) {
    event.preventDefault();
    actions.applyNamedStyle(ctx.controller, name);
  });
  ctx.registerStyleCard(name, card);
  return card;
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
