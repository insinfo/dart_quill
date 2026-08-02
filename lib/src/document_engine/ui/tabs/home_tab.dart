/// Aba Página Inicial — grupos de DUAS linhas como o Word: Desfazer, Fonte,
/// Parágrafo (listas + alinhamentos), Estilos.
library;

import '../../../platform/dom.dart';
import '../ribbon.dart';
import '../ribbon_actions.dart' as actions;

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
    kit.group('Fonte', [
      kit.row([
        kit.select(
          'dq-office-font-family',
          const ['Arial', 'Calibri', 'Times New Roman', 'Courier New'],
          'Arial',
          (value) => actions.addMarkOverSelection(c, 'font', {'value': value}),
        ),
        kit.select(
          'dq-office-font-size',
          const ['8', '9', '10', '11', '12', '14', '16', '18', '24', '36'],
          '12',
          (value) =>
              actions.addMarkOverSelection(c, 'size', {'value': '${value}pt'}),
        ),
      ]),
      kit.row([
        ctx.markButton('bold', 'B', 'Negrito (Ctrl+B)', 'dq-office-b',
            icon: 'bold'),
        ctx.markButton('italic', 'I', 'Itálico (Ctrl+I)', 'dq-office-i',
            icon: 'italic'),
        ctx.markButton('underline', 'U', 'Sublinhado (Ctrl+U)', 'dq-office-u',
            icon: 'underline'),
        ctx.markButton('strike', 'S', 'Tachado', 'dq-office-s',
            icon: 'strikeout'),
      ]),
    ]),
    kit.group('Parágrafo', [
      kit.row([
        kit.button('•—', 'Lista com marcadores',
            () => actions.toggleList(c, 'bullet'),
            icon: 'setmarkers'),
        kit.button('1—', 'Lista numerada', () => actions.toggleList(c, 'ordered'),
            icon: 'numbering'),
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
      ]),
    ]),
  ];
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
    ctx.markButton('strike', 'S', 'Tachado', 'dq-office-s',
            icon: 'strikeout'),
  ];
}
