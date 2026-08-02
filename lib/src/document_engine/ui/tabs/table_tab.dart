/// Aba contextual Tabela — só aparece com a seleção dentro de uma tabela.
///
/// As operações são as funções puras de `table_ops.dart`: a mesma lógica
/// serve a uma futura quickbar flutuante sem duplicação.
library;

import '../../../platform/dom.dart';
import '../ribbon.dart';
import '../table_ops.dart' as ops;

List<DomElement> buildTableTab(RibbonContext ctx) {
  final c = ctx.controller;
  final kit = ctx.kit;
  void run(void Function() action) {
    c.syncSelection();
    action();
  }

  return [
    kit.group('Linhas', [
      kit.row([
        kit.button('⬆+', 'Inserir linha acima', () => run(() =>
            ops.tableInsertRow(c.view.state, c.dispatch, c.schema, above: true)),
            icon: 'addcell'),
        kit.button('⬇+', 'Inserir linha abaixo', () => run(() =>
            ops.tableInsertRow(c.view.state, c.dispatch, c.schema,
                above: false))),
        kit.button('⬚✕', 'Excluir linha',
            () => run(() => ops.tableDeleteRow(c.view.state, c.dispatch)),
            icon: 'delcell'),
      ]),
    ]),
    kit.group('Colunas', [
      kit.row([
        kit.button('⬅+', 'Inserir coluna à esquerda', () => run(() =>
            ops.tableInsertColumn(c.view.state, c.dispatch, c.schema,
                before: true))),
        kit.button('➡+', 'Inserir coluna à direita', () => run(() =>
            ops.tableInsertColumn(c.view.state, c.dispatch, c.schema,
                before: false))),
        kit.button('▯✕', 'Excluir coluna',
            () => run(() => ops.tableDeleteColumn(c.view.state, c.dispatch))),
      ]),
    ]),
    kit.group('Tabela', [
      kit.row([
        kit.button('⊞✕', 'Excluir tabela',
            () => run(() => ops.tableDelete(c.view.state, c.dispatch))),
      ]),
    ]),
  ];
}
