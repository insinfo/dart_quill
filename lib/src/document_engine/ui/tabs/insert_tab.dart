/// Aba Inserir — páginas, tabela (com o grid picker do Word), ilustrações,
/// link, símbolo e a caixa de Localizar/Substituir.
///
/// O grid picker é o controle que o Word usa para dizer o tamanho da tabela
/// antes de criá-la: passar o mouse pinta N×M células e o rótulo mostra
/// "3×4 Tabela". Um botão fixo "3×3" obrigava o usuário a inserir e depois
/// consertar com Inserir Linha/Coluna, que é trabalho manual para uma
/// informação que ele já tinha.
///
/// **Nota de arrumação:** no Word, "Localizar", "Substituir" e "Mostrar
/// Tudo (¶)" moram na Página Inicial (grupos Edição e Parágrafo), não aqui.
/// Eles estão nesta aba porque a Página Inicial está sendo editada em
/// paralelo; os três são funções livres (`find_replace.dart`,
/// `formatting_marks.dart`) e mudam de aba trocando a linha que os monta.
library;

import '../../../platform/dom.dart';
import '../dialogs/link_dialog.dart';
import '../image_insert.dart';
import '../ribbon.dart';
import '../ribbon_actions.dart' as actions;
import '../symbol_picker.dart';

/// Dimensões do grid do Word: 10 colunas × 8 linhas.
const int _gridColumns = 10;
const int _gridRows = 8;

List<DomElement> buildInsertTab(RibbonContext ctx) {
  final c = ctx.controller;
  final kit = ctx.kit;
  return [
    kit.group('Páginas', [
      kit.row([
        kit.button('▤', 'Página em Branco (insere uma página vazia)',
            () => actions.insertBlankPage(c),
            extraClass: 'dq-office-btn-labeled', icon: 'blankpage'),
        kit.button(
            '⤓┄',
            'Quebra de Página (o texto após o cursor vai para a próxima '
                'página) — Ctrl+Enter',
            () => actions.insertPageBreak(c),
            extraClass: 'dq-office-btn-labeled',
            icon: 'pagebreak'),
      ]),
    ]),
    kit.group('Tabelas', [
      kit.row([_tableGridButton(ctx)]),
    ]),
    kit.group('Ilustrações', [
      kit.row([
        kit.button('🖼', 'Imagens (do arquivo)', () => pickAndInsertImage(c),
            extraClass: 'dq-office-btn-labeled', icon: 'insertimage'),
      ]),
    ]),
    kit.group('Links', [
      kit.row([
        kit.button('🔗', 'Link (inserir ou editar o hiperlink) — Ctrl+K',
            () => openLinkDialog(c),
            extraClass: 'dq-office-btn-labeled', icon: 'hyperlink'),
      ]),
    ]),
    kit.group('Símbolos', [
      kit.row([_symbolButton(ctx)]),
    ]),
  ];
}

/// Símbolo: a galeria abre no overlay, ancorada no botão.
DomElement _symbolButton(RibbonContext ctx) {
  final c = ctx.controller;
  final kit = ctx.kit;
  final wrap = kit.el('span', 'dq-office-menuwrap');
  wrap.append(kit.button('Ω', 'Símbolo', () => openSymbolGallery(c, wrap),
      icon: 'symbol', extraClass: 'dq-office-btn-menu'));
  return wrap;
}

/// O botão Tabela: abre o grid picker e insere no clique.
DomElement _tableGridButton(RibbonContext ctx) {
  final c = ctx.controller;
  final kit = ctx.kit;
  final wrap = kit.el('span', 'dq-office-menuwrap');
  const group = 'insert:table';
  wrap.append(kit.button('⊞', 'Tabela', () {
    if (c.overlay.closeGroup(group)) return;
    c.overlay.open(
        group,
        buildTableGridPicker(ctx, (rows, columns) {
          c.overlay.closeGroup(group);
          c.syncSelection();
          actions.insertTable(c, rows, columns);
        }),
        anchor: wrap);
  }, icon: 'inserttable', extraClass: 'dq-office-btn-menu'));
  return wrap;
}

/// O grid picker propriamente dito, isolado para a quickbar de tabela e os
/// testes o usarem sem a ribbon.
DomElement buildTableGridPicker(
  RibbonContext ctx,
  void Function(int rows, int columns) onPick,
) {
  final kit = ctx.kit;
  final picker = kit.el('div', 'dq-office-gridpicker');
  final label = kit.el('div', 'dq-office-gridpicker-label');
  label.appendText('Inserir Tabela');
  final grid = kit.el('div', 'dq-office-gridpicker-grid');

  final cells = <DomElement>[];
  void highlight(int rows, int columns) {
    for (var index = 0; index < cells.length; index++) {
      final row = index ~/ _gridColumns + 1;
      final column = index % _gridColumns + 1;
      if (row <= rows && column <= columns) {
        cells[index].classes.add('dq-office-gridcell-on');
      } else {
        cells[index].classes.remove('dq-office-gridcell-on');
      }
    }
    kit.setText(label, '$columns × $rows Tabela');
  }

  for (var row = 1; row <= _gridRows; row++) {
    for (var column = 1; column <= _gridColumns; column++) {
      final cell = kit.el('button', 'dq-office-gridcell');
      cell.setAttribute('type', 'button');
      cell.setAttribute('data-rows', '$row');
      cell.setAttribute('data-columns', '$column');
      cell.setAttribute('title', '$column × $row');
      cell.addEventListener('mouseover', (_) => highlight(row, column));
      cell.addEventListener('mousedown', (event) => event.preventDefault());
      cell.addEventListener('click', (event) {
        event.preventDefault();
        onPick(row, column);
      });
      cells.add(cell);
      grid.append(cell);
    }
  }

  picker.append(label);
  picker.append(grid);
  return picker;
}
