/// Aba Inserir — quebra de página e tabela.
library;

import '../../../platform/dom.dart';
import '../ribbon.dart';
import '../ribbon_actions.dart' as actions;

List<DomElement> buildInsertTab(RibbonContext ctx) {
  final c = ctx.controller;
  final kit = ctx.kit;
  return [
    kit.group('Páginas', [
      kit.row([
        kit.button(
            '⤓┄',
            'Quebra de Página (o texto após o cursor vai para a próxima '
            'página)',
            () => actions.insertPageBreak(c),
            icon: 'pagebreak'),
      ]),
    ]),
    kit.group('Tabelas', [
      kit.row([
        kit.button('⊞', 'Inserir tabela 3×3', () => actions.insertTable(c, 3, 3),
            icon: 'inserttable'),
      ]),
    ]),
  ];
}
