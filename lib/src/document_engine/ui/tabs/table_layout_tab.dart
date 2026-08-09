/// Aba contextual "Tabela Layout" — a ESTRUTURA da tabela: selecionar,
/// inserir/excluir linhas e colunas, mesclar/dividir, distribuir e alinhar
/// o conteúdo na célula.
///
/// A divisão em duas abas é a do Word: aqui fica o que muda a GRADE, em
/// "Design da Tabela" fica o que muda a APARÊNCIA (bordas e sombreamento).
/// Todas as ações são as funções puras de `table_ops.dart`, as mesmas que a
/// quickbar e o menu de contexto chamam — nenhuma operação de tabela tem
/// duas implementações.
library;

import '../../../platform/dom.dart';
import '../../layout/dom_renderer.dart';
import '../controller.dart';
import '../ribbon.dart';
import '../table_map.dart';
import '../table_ops.dart' as ops;

List<DomElement> buildTableLayoutTab(RibbonContext ctx) {
  final c = ctx.controller;
  final kit = ctx.kit;
  void run(void Function() action) {
    c.syncSelection();
    action();
  }

  return [
    kit.group('Tabela', [
      kit.row([
        kit.button(
            'Célula',
            'Selecionar célula',
            () => run(() {
                  final from = c.view.state.selection.from;
                  ops.selectCellRange(c.view.state, c.dispatch, from, from);
                }),
            extraClass: 'dq-office-btn-labeled',
            icon: 'select-tool'),
        kit.button('Linha', 'Selecionar linha',
            () => run(() => ops.selectTableRow(c.view.state, c.dispatch)),
            extraClass: 'dq-office-btn-labeled'),
        kit.button('Coluna', 'Selecionar coluna',
            () => run(() => ops.selectTableColumn(c.view.state, c.dispatch)),
            extraClass: 'dq-office-btn-labeled'),
        kit.button('Tabela', 'Selecionar tabela',
            () => run(() => ops.selectWholeTable(c.view.state, c.dispatch)),
            extraClass: 'dq-office-btn-labeled'),
      ]),
    ]),
    kit.group('Linhas e Colunas', [
      kit.row([
        kit.button(
            'Acima',
            'Inserir linha acima',
            () => run(() => ops.tableInsertRow(
                c.view.state, c.dispatch, c.schema,
                above: true)),
            extraClass: 'dq-office-btn-labeled',
            icon: 'addcell'),
        kit.button(
            'Abaixo',
            'Inserir linha abaixo',
            () => run(() => ops.tableInsertRow(
                c.view.state, c.dispatch, c.schema,
                above: false)),
            extraClass: 'dq-office-btn-labeled'),
        kit.button(
            'À Esquerda',
            'Inserir coluna à esquerda',
            () => run(() => ops.tableInsertColumn(
                c.view.state, c.dispatch, c.schema,
                before: true)),
            extraClass: 'dq-office-btn-labeled'),
        kit.button(
            'À Direita',
            'Inserir coluna à direita',
            () => run(() => ops.tableInsertColumn(
                c.view.state, c.dispatch, c.schema,
                before: false)),
            extraClass: 'dq-office-btn-labeled'),
      ]),
      kit.row([
        kit.button('Excluir Linha', 'Excluir linha',
            () => run(() => ops.tableDeleteRow(c.view.state, c.dispatch)),
            extraClass: 'dq-office-btn-labeled', icon: 'delcell'),
        kit.button('Excluir Coluna', 'Excluir coluna',
            () => run(() => ops.tableDeleteColumn(c.view.state, c.dispatch)),
            extraClass: 'dq-office-btn-labeled'),
        kit.button('Excluir Tabela', 'Excluir tabela',
            () => run(() => ops.tableDelete(c.view.state, c.dispatch)),
            extraClass: 'dq-office-btn-labeled'),
      ]),
    ]),
    kit.group('Mesclar', [
      kit.row([
        kit.button('Mesclar', 'Mesclar células',
            () => run(() => ops.mergeSelectedCells(c.view.state, c.dispatch)),
            extraClass: 'dq-office-btn-labeled', icon: 'merge-cells'),
        kit.button('Dividir', 'Dividir célula',
            () => run(() => ops.splitSelectedCell(c.view.state, c.dispatch)),
            extraClass: 'dq-office-btn-labeled', icon: 'rows-and-columns'),
      ]),
    ]),
    kit.group('Tamanho da Célula', [
      kit.row([
        kit.button('Distribuir Linhas', 'Distribuir linhas uniformemente',
            () => run(() => _distributeRows(c)),
            extraClass: 'dq-office-btn-labeled', icon: 'distribute-rows'),
        kit.button('Distribuir Colunas', 'Distribuir colunas uniformemente',
            () => run(() => _distributeColumns(c)),
            extraClass: 'dq-office-btn-labeled', icon: 'distribute-columns'),
      ]),
    ]),
    kit.group('Alinhamento', [
      kit.row([
        for (final (value, text, title, icon) in const [
          ('top', '⤒', 'Alinhar acima', 'align-top'),
          ('center', '⇳', 'Alinhar ao centro', 'align-middle'),
          ('bottom', '⤓', 'Alinhar abaixo', 'align-bottom'),
        ])
          kit.button(
              text,
              title,
              () => run(() =>
                  ops.setCellVerticalAlign(c.view.state, c.dispatch, value)),
              icon: icon),
      ]),
    ]),
  ];
}

/// Distribui as colunas preservando a largura da tabela.
///
/// A área útil da página é o fallback de [ops.distributeTableColumns] para
/// tabelas sem `w:tblGrid` — o chrome conhece a geometria da seção, a função
/// pura não.
void _distributeColumns(OfficeWordController c) {
  final setup = c.pageSetup;
  ops.distributeTableColumns(
    c.view.state,
    c.dispatch,
    totalWidthTwips:
        setup.widthTwips - setup.marginLeftTwips - setup.marginRightTwips,
  );
}

/// Distribui as linhas pela altura MEDIDA na projeção.
///
/// A altura real de uma linha sem `w:trHeight` é o conteúdo dela depois de
/// composto — não existe no modelo. O renderer já publica `data-height-twips`
/// em cada linha projetada, então a medida vem daí em vez de um segundo
/// cálculo de layout no chrome, que divergiria do que o usuário vê.
///
/// Sem projeção (nenhuma linha medida) o botão não faz nada: distribuir por
/// um palpite espremeria a tabela.
void _distributeRows(OfficeWordController c) {
  final state = c.view.state;
  final map = OfficeTableMap.at(state.doc, state.selection.from);
  if (map == null) return;
  final positions = ops.tableRowPositions(map).toSet();
  if (positions.isEmpty) return;

  var total = 0;
  var measured = 0;
  for (final element
      in c.view.host.querySelectorAll('.$officeCssPrefix-table-row')) {
    // A cópia de um cabeçalho repetido projeta a MESMA linha de novo; contá-la
    // dobraria a altura dela na média.
    if (element.getAttribute('data-repeated-header') == 'true') continue;
    final pos = int.tryParse(element.getAttribute('data-doc-from') ?? '');
    if (pos == null || !positions.contains(pos)) continue;
    final height =
        int.tryParse(element.getAttribute('data-height-twips') ?? '');
    if (height == null || height <= 0) continue;
    total += height;
    measured++;
  }
  if (measured == 0) return;
  // Linhas partidas entre páginas aparecem em mais de um fragmento; a soma
  // continua sendo a altura total da tabela, então dividir pelo NÚMERO DE
  // LINHAS (e não de fragmentos) preserva a altura da tabela.
  ops.distributeTableRows(
    state,
    c.dispatch,
    heightTwips: total ~/ positions.length,
  );
}
