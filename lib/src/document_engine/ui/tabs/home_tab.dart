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
const List<String?> _fontColors = [
  null, // Automático — remove a marca
  '#000000', '#c00000', '#ff0000', '#ffc000', '#ffff00', '#92d050',
  '#00b050', '#00b0f0', '#0070c0', '#002060', '#7030a0',
];

/// Cores de realce do Word.
const List<String?> _highlightColors = [
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
        () {
          final select = kit.select(
            'dq-office-font-family',
            const ['Arial', 'Calibri', 'Times New Roman', 'Courier New'],
            'Arial',
            (value) =>
                actions.addMarkOverSelection(c, 'font', {'value': value}),
          );
          ctx.registerMarkValueSelect('font', select, 'Arial');
          return select;
        }(),
        () {
          final select = kit.select(
            'dq-office-font-size',
            const [
              '8',
              '9',
              '10',
              '11',
              '12',
              '14',
              '16',
              '18',
              '20',
              '24',
              '28',
              '36',
              '48',
              '72'
            ],
            '12',
            (value) => actions
                .addMarkOverSelection(c, 'size', {'value': '${value}pt'}),
          );
          ctx.registerMarkValueSelect('size', select, '12');
          return select;
        }(),
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
        _paletteButton(ctx,
            icon: 'highlight',
            text: 'ab',
            title: 'Cor do Realce do Texto',
            mark: 'background',
            colors: _highlightColors),
        _paletteButton(ctx,
            icon: 'fontcolor',
            text: 'A',
            title: 'Cor da Fonte',
            mark: 'color',
            colors: _fontColors),
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
DomElement _paletteButton(RibbonContext ctx,
    {required String icon,
    required String text,
    required String title,
    required String mark,
    required List<String?> colors}) {
  final kit = ctx.kit;
  final wrap = kit.el('span', 'dq-office-colorwrap');
  final palette = kit.el('div', 'dq-office-palette dq-office-palette-hidden');
  for (final color in colors) {
    final swatch = kit.el('button',
        'dq-office-swatch${color == null ? ' dq-office-swatch-none' : ''}');
    swatch.setAttribute('type', 'button');
    swatch.setAttribute('title', color ?? 'Sem cor');
    if (color != null) swatch.setAttribute('style', 'background:$color;');
    swatch.addEventListener('click', (event) {
      event.preventDefault();
      palette.classes.add('dq-office-palette-hidden');
      actions.applyMarkColor(ctx.controller, mark, color);
    });
    palette.append(swatch);
  }
  wrap.append(kit.button(text, title, () {
    if (palette.classes.contains('dq-office-palette-hidden')) {
      palette.classes.remove('dq-office-palette-hidden');
    } else {
      palette.classes.add('dq-office-palette-hidden');
    }
  }, icon: icon));
  wrap.append(palette);
  return wrap;
}

/// Cartão da galeria de Estilos (AaBbCcD + rótulo), com realce do ativo.
DomElement _styleCard(RibbonContext ctx, String name, String preview) {
  final kit = ctx.kit;
  final card = kit.el(
      'button', 'dq-office-stylecard dq-office-stylecard-${_slug(name)}');
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

String _slug(String name) =>
    name.toLowerCase().replaceAll('í', 'i').replaceAll(' ', '-');

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
