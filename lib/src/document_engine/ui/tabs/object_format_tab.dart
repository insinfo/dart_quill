/// Aba contextual "Formato de Imagem" / "Formato da Forma" — a faixa que o
/// Word abre quando um objeto está selecionado.
///
/// **A regra do plano vale aqui como em todo o resto: nenhum controle grava
/// um atributo que o compositor ignora.** Por isso a aba é curta e cada
/// controle foi conferido contra `layout/layout_composer.dart` e
/// `layout/dom_renderer.dart`:
///
/// * **Tamanho** (`width`/`height` em twips) — é o que a alça de
///   redimensionamento já grava, pela MESMA função
///   (`ribbon_actions.setObjectSizeTwips`). O spinner e a alça não podem ter
///   dois caminhos: só um deles preservaria a seleção do nó.
/// * **Alinhar** — `positionHAlign` na caixa de texto (o renderer o lê em
///   `_renderTextBox`) e alinhamento do PARÁGRAFO na imagem em linha, que são
///   os dois comportamentos do Word.
/// * **Disposição do texto** — abre o MESMO menu do popover do objeto
///   (`ui/layout_options.dart`), com os modos que o compositor não honra
///   visíveis e desabilitados, com o motivo escrito.
///
/// O que o Word tem aqui e esta aba NÃO tem, com motivo: correções, cor,
/// efeitos artísticos, moldura/estilos de imagem e recorte — nada disso
/// existe no `PageGraph` (a imagem é projetada por `_renderSegment` com
/// `src`, largura e altura, e mais nada), então cada um seria um botão que
/// não muda um pixel. Preenchimento/contorno da caixa de texto ficam de fora
/// por outra razão, igualmente concreta: o renderer os desenha, mas a
/// exportação carimba o XML preservado da forma
/// (`office/docx_codec._textBoxRawXml`), então a troca não chegaria ao
/// arquivo — mudar a tela e não mudar o DOCX é pior que não oferecer.
library;

import '../../../platform/dom.dart';
import '../controller.dart';
import '../layout_options.dart';
import '../ribbon.dart';
import '../ribbon_actions.dart' as actions;

/// Rótulo da aba para o objeto selecionado — o vocabulário do Word.
String officeObjectFormatTabLabel(OfficeWordController c) {
  final target = actions.selectedObject(c);
  return target?.node.type.name == 'textBox'
      ? 'Formato da Forma'
      : 'Formato de Imagem';
}

List<DomElement> buildObjectFormatTab(RibbonContext ctx) {
  final c = ctx.controller;
  final kit = ctx.kit;
  return [
    kit.group('Organizar', [
      kit.row([
        kit.button('⯇', 'Alinhar objeto à esquerda',
            () => actions.setObjectAlign(c, 'left'),
            icon: 'align-left'),
        kit.button(
            '☰', 'Centralizar objeto', () => actions.setObjectAlign(c, 'center'),
            icon: 'align-center'),
        kit.button('⯈', 'Alinhar objeto à direita',
            () => actions.setObjectAlign(c, 'right'),
            icon: 'align-right'),
      ]),
      kit.row([
        layoutOptionsButton(c),
        kit.button('Excluir', 'Excluir o objeto selecionado',
            () => actions.deleteSelectedObject(c),
            extraClass: 'dq-office-btn-labeled', icon: 'delcell'),
      ]),
    ]),
    kit.group('Tamanho', [
      kit.row([_sizeField(ctx, isHeight: true)]),
      kit.row([_sizeField(ctx, isHeight: false), _ratioLock(ctx)]),
    ]),
  ];
}

/// Trava de proporção da aba (não é do modelo: é uma preferência da UI, como
/// a caixa "Bloquear taxa de proporção" do Word).
///
/// Estática porque a aba é RECONSTRUÍDA a cada troca de contexto; guardar a
/// escolha no elemento a perderia no primeiro clique fora do objeto.
bool _keepRatio = true;

DomElement _ratioLock(RibbonContext ctx) {
  final kit = ctx.kit;
  final wrap = kit.el('label', 'dq-office-checkfield');
  final input = kit.el('input', 'dq-office-checkfield-input');
  input.setAttribute('type', 'checkbox');
  // O estado mora no `value`, como nos diálogos e no painel Localizar: um
  // caminho só de leitura para todo controle, sem um ramo por tipo.
  input.value = _keepRatio ? 'true' : 'false';
  if (_keepRatio) input.setAttribute('checked', 'checked');
  input.addEventListener('change', (_) {
    _keepRatio = input.value != 'true';
    input.value = _keepRatio ? 'true' : 'false';
  });
  wrap.append(input);
  final caption = kit.el('span', 'dq-office-checkfield-label');
  caption.appendText('Proporção');
  wrap.append(caption);
  return wrap;
}

/// Altura/Largura em CENTÍMETROS, como o Word rotula os dois campos.
///
/// O valor exibido vem do modelo a cada refresh (`registerRefresh`): a UI
/// reflete o documento, e arrastar a alça tem de mudar o número aqui sem que
/// este arquivo saiba que existe uma alça.
DomElement _sizeField(RibbonContext ctx, {required bool isHeight}) {
  final c = ctx.controller;
  final kit = ctx.kit;
  final label = isHeight ? 'Altura' : 'Largura';
  final wrap = kit.el('label', 'dq-office-spinner');
  final caption = kit.el('span', 'dq-office-spinner-label');
  caption.appendText(label);
  wrap.append(caption);

  final input = kit.el('input', 'dq-office-spinner-input');
  input.setAttribute('type', 'number');
  input.setAttribute('step', '0.1');
  input.setAttribute('min', '0.1');
  input.setAttribute('title', '$label do objeto, em cm');
  input.addEventListener('change', (_) {
    final typed = double.tryParse(input.value.replaceAll(',', '.'));
    final size = actions.objectSizeTwips(c);
    if (typed == null || typed <= 0 || size == null) return;
    final twips = (typed * 567).round();
    if (twips <= 0) return;
    // Com a proporção travada, a outra dimensão acompanha — é o
    // comportamento padrão do Word para imagem.
    final ratio = size.height / size.width;
    actions.setObjectSizeTwips(
      c,
      widthTwips: isHeight
          ? (_keepRatio ? (twips / (ratio == 0 ? 1 : ratio)).round() : null)
          : twips,
      heightTwips: isHeight ? twips : (_keepRatio ? (twips * ratio).round() : null),
    );
  });
  wrap.append(input);

  ctx.registerRefresh(() {
    final size = actions.objectSizeTwips(c);
    if (size == null) {
      input.value = '';
      return;
    }
    final cm = (isHeight ? size.height : size.width) / 567.0;
    input.value = cm.toStringAsFixed(2);
  });
  return wrap;
}
