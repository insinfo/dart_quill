/// Mostrar/Ocultar Marcas de Formatação (¶).
///
/// A regra que governa este arquivo: **um adorno não pode virar conteúdo**.
/// O mapa de posições soma o comprimento LÓGICO dos nós projetados
/// (`layout/dom_position_map.dart:199`, `data-model-length` com fallback no
/// `textContent`), então qualquer pilcrow inserido como nó de texto entraria
/// na conta e deslocaria toda seleção depois dele — o caret cairia um
/// caractere adiante por parágrafo. Por isso a revelação é feita
/// exclusivamente por PSEUDO-ELEMENTO CSS: `::after` não existe no DOM, não
/// tem `textContent`, não é varrido por `childNodes` e não muda uma vírgula
/// do documento nem do que o motor mede.
///
/// O que isso permite entregar, e o que não permite:
///
/// * ¶ no fim de cada parágrafo — sim: o último `.dq-office-line` do bloco
///   recebe o `::after`. O bloco continuado na página seguinte é excluído
///   pelo `data-continues-on` que o renderer já escreve
///   (`layout/dom_renderer.dart:381`), então a marca aparece uma vez só, no
///   fim de verdade do parágrafo.
/// * seta de tabulação — sim: o run de tab é um elemento próprio
///   (`.dq-office-tab`), e o `::before` absoluto marca a faixa sem empurrar
///   o caractere `\t` que sustenta o offset.
/// * ponto médio no espaço — **não**. Não existe seletor de CARACTERE em
///   CSS; revelar espaço a espaço exigiria o renderer quebrar cada run em
///   um elemento por espaço, isto é, exatamente a inserção de nós que este
///   arquivo existe para evitar. Fica pendente, com essa evidência.
library;

import '../../platform/dom.dart';
import 'controller.dart';

/// A classe que o CSS de marcas observa, no host do editor.
const String officeFormattingMarksClass = 'dq-office-marks';

bool officeFormattingMarksVisible(OfficeWordController c) =>
    c.hostElement.classes.contains(officeFormattingMarksClass);

/// Alterna e devolve o estado NOVO (o chamador acende o botão com isso).
bool officeToggleFormattingMarks(OfficeWordController c) {
  final visible = !officeFormattingMarksVisible(c);
  officeSetFormattingMarks(c, visible);
  return visible;
}

void officeSetFormattingMarks(OfficeWordController c, bool visible) {
  if (visible) {
    c.hostElement.classes.add(officeFormattingMarksClass);
  } else {
    c.hostElement.classes.remove(officeFormattingMarksClass);
  }
}

/// O botão ¶ da ribbon, pronto para qualquer aba.
///
/// Ele mora aqui, e não na aba, porque é um botão de ESTADO cujo estado não
/// está no documento (é uma classe no host) — o realce de estado da ribbon
/// (`OfficeRibbon.refreshState`) só sabe ler marcas e atributos do modelo, e
/// não teria como acender este. Assim a aba que o hospedar é uma linha, e
/// mover o botão para a Página Inicial (onde o Word o põe) não duplica nada.
DomElement buildFormattingMarksButton(OfficeWordController c) {
  final kit = OfficeDomKit(c.adapter);
  late final DomElement button;
  void paint(bool visible) {
    if (visible) {
      button.classes.add('dq-office-btn-active');
    } else {
      button.classes.remove('dq-office-btn-active');
    }
  }

  button = kit.button('¶', 'Mostrar Tudo — marcas de parágrafo e de tabulação',
      () => paint(officeToggleFormattingMarks(c)),
      icon: 'paragraph-marks');
  paint(officeFormattingMarksVisible(c));
  return button;
}
