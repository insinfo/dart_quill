/// Aba Design — o chrome da FOLHA: marca-d'água, cor da página e bordas de
/// página.
///
/// **Por que ela cabe aqui e não no motor.** As três propriedades desta aba
/// não reflowam uma linha sequer: no Word, pintar a folha, marcar "MINUTA" ou
/// pôr uma moldura não muda onde o texto quebra. Por isso elas vivem na
/// GEOMETRIA da seção (`PageSetupTwips`) e são consumidas direto pelos dois
/// renderers — o compositor nem as enxerga. É o que garante que ligar a
/// marca-d'água não repagine o documento nem mova uma vírgula.
///
/// **A marca-d'água não é conteúdo.** Ela não ocupa posição no documento, não
/// entra na seleção, não é apagada por Ctrl+A e o caret não cai dentro dela
/// (as camadas são `contenteditable=false`, `pointer-events:none` e
/// `data-model-length=0`). Um editor que a inserisse como parágrafo faria o
/// usuário apagá-la sem entender o que apagou — e ela reapareceria em todas
/// as páginas, porque no Word ela é da folha, não do texto.
///
/// **O que fica de fora, com o motivo:** marca-d'água de IMAGEM (o compositor
/// não desenha figura de página, só as duas camadas de texto/borda), arte de
/// borda (`w:pgBorderArt`, as molduras decorativas do Word, que são um
/// catálogo de bitmaps) e temas/conjuntos de cores — trocar tema significa
/// reescrever `theme1.xml` e recalcular a cascata inteira, que é motor, não
/// chrome.
library;

import '../../../platform/dom.dart';
import '../controller.dart';
import '../menu.dart';
import '../ribbon.dart';
import '../ribbon_actions.dart' as actions;
import 'home_tab.dart' show officeParagraphShadingColors;

List<DomElement> buildDesignTab(RibbonContext ctx) {
  final c = ctx.controller;
  final kit = ctx.kit;
  return [
    kit.group('Plano de Fundo da Página', [
      kit.row([
        menuButton(c, '≋', 'Marca-d\'Água', 'design:watermark',
            () => _watermarkEntries(c),
            icon: 'watermark'),
        _pageColorButton(ctx),
        menuButton(c, '▢', 'Bordas de Página', 'design:pageborders',
            () => _pageBorderEntries(c),
            icon: 'border-all'),
      ]),
    ]),
  ];
}

/// A galeria de marca-d'água: os textos prontos, o item vigente marcado, a
/// orientação e a remoção.
List<OfficeMenuEntry> _watermarkEntries(OfficeWordController c) {
  final current = c.pageSetup.watermark;
  return [
    OfficeMenuEntry(
      label: 'Nenhuma',
      description: 'Remove a marca-d\'água da seção',
      checked: current == null,
      onSelect: () => actions.setWatermarkText(c, null),
    ),
    const OfficeMenuEntry.separator(),
    for (final preset in actions.officeWatermarkPresets)
      OfficeMenuEntry(
        label: preset,
        checked: current?.text == preset,
        onSelect: () => actions.setWatermarkText(c, preset),
      ),
    const OfficeMenuEntry.separator(),
    OfficeMenuEntry(
      label: 'Diagonal',
      description: 'A inclinação padrão do Word (−45°)',
      checked: current?.diagonal ?? true,
      enabled: current != null,
      onSelect: () => actions.setWatermarkDiagonal(c, true),
    ),
    OfficeMenuEntry(
      label: 'Horizontal',
      checked: current != null && !current.diagonal,
      enabled: current != null,
      onSelect: () => actions.setWatermarkDiagonal(c, false),
    ),
    const OfficeMenuEntry.separator(),
    OfficeMenuEntry(
      label: 'Marca-d\'Água Personalizada…',
      description: 'Escreve o texto que aparecerá em todas as páginas',
      onSelect: () => _openCustomWatermark(c),
    ),
  ];
}

/// O diálogo de texto livre — o "Personalizada…" do Word.
void _openCustomWatermark(OfficeWordController c) {
  final kit = OfficeDomKit(c.adapter);
  final panel = kit.el('div', 'dq-office-watermark-panel');
  final label = kit.el('label', 'dq-office-spinner');
  final caption = kit.el('span', 'dq-office-spinner-label');
  caption.appendText('Texto');
  label.append(caption);
  final input = kit.el('input', 'dq-office-watermark-input');
  input.setAttribute('type', 'text');
  input.setAttribute('spellcheck', 'false');
  input.value = c.pageSetup.watermark?.text ?? '';
  // O overlay cancela o `mousedown` do popup inteiro para nenhum controle
  // roubar o caret do documento; num CAMPO isso é o contrário do que se
  // quer, então a propagação para aqui.
  input.addEventListener('mousedown', (event) => event.stopPropagation());
  label.append(input);
  panel.append(label);

  void apply() {
    actions.setWatermarkText(c, input.value.trim().isEmpty ? null : input.value);
    c.overlay.closeGroup('design:watermark-custom');
  }

  input.addEventListener('keydown', (event) {
    if (event is! DomKeyboardEvent) return;
    if (event.key == 'Enter') {
      event.preventDefault();
      apply();
    } else if (event.key == 'Escape') {
      c.overlay.closeGroup('design:watermark-custom');
    }
  });
  final row = kit.el('div', 'dq-office-watermark-actions');
  row.append(kit.button('Aplicar', 'Aplicar a marca-d\'água', apply));
  panel.append(row);
  c.overlay.open('design:watermark-custom', panel, anchor: c.hostElement);
  c.adapter.focus(input);
}

/// A paleta de cor da folha, com "Sem cor" no lugar do Word.
DomElement _pageColorButton(RibbonContext ctx) {
  final c = ctx.controller;
  final kit = ctx.kit;
  const group = 'design:pagecolor';
  final wrap = kit.el('span', 'dq-office-menuwrap');

  DomElement buildPalette() {
    final palette = kit.el('div', 'dq-office-palette');
    for (final color in officeParagraphShadingColors) {
      final swatch = kit.el('button', 'dq-office-swatch');
      swatch.setAttribute('type', 'button');
      swatch.setAttribute('title', color ?? 'Sem cor');
      if (color == null) {
        swatch.classes.add('dq-office-swatch-none');
      } else {
        swatch.setAttribute('style', 'background:$color;');
      }
      if (c.pageSetup.pageColor == color) {
        swatch.classes.add('dq-office-swatch-active');
      }
      swatch.addEventListener('mousedown', (event) => event.preventDefault());
      swatch.addEventListener('click', (event) {
        event.preventDefault();
        c.overlay.closeGroup(group);
        actions.setPageColor(c, color);
      });
      palette.append(swatch);
    }
    return palette;
  }

  wrap.append(kit.button('▤', 'Cor da Página', () {
    if (c.overlay.closeGroup(group)) return;
    c.overlay.open(group, buildPalette(), anchor: wrap);
  }));
  return wrap;
}

/// As molduras de página, com a vigente marcada.
List<OfficeMenuEntry> _pageBorderEntries(OfficeWordController c) {
  final current = actions.currentPageBorderName(c);
  return [
    for (final kind in actions.officePageBorderKinds)
      OfficeMenuEntry(
        label: kind.name,
        description: kind.style == null
            ? 'Remove a moldura da página'
            : '${(kind.sizeEighths / 8).toStringAsFixed(kind.sizeEighths % 8 == 0 ? 0 : 1).replaceAll('.', ',')} pt',
        checked: kind.name == current,
        onSelect: () => actions.setPageBorder(
          c,
          style: kind.style,
          sizeEighths: kind.sizeEighths,
        ),
      ),
  ];
}
