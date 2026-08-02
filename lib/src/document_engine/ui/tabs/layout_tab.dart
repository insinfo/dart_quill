/// Aba Layout — orientação, papel e margens. Cada escolha vira
/// `setPageSetup`: o documento REPAGINA de verdade, com conteúdo e
/// histórico intactos.
library;

import '../../../platform/dom.dart';
import '../ribbon.dart';
import '../ribbon_actions.dart' as actions;

List<DomElement> buildLayoutTab(RibbonContext ctx) {
  final c = ctx.controller;
  final kit = ctx.kit;
  return [
    kit.group('Orientação', [
      kit.row([
        kit.button(
            '▯', 'Retrato', () => actions.setOrientation(c, portrait: true),
            icon: 'pageorient'),
        kit.button(
            '▭', 'Paisagem', () => actions.setOrientation(c, portrait: false)),
      ]),
    ]),
    kit.group('Tamanho', [
      kit.row([
        kit.select('dq-office-paper', const ['A4', 'Ofício', 'Carta'],
            actions.paperName(c), (value) => actions.setPaper(c, value)),
      ]),
    ]),
    kit.group('Margens', [
      kit.row([
        kit.select('dq-office-margins', const ['Normal', 'Estreita', 'Larga'],
            'Normal', (value) => actions.setMargins(c, value)),
      ]),
    ]),
  ];
}
