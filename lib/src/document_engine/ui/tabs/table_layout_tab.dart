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
import '../dialogs/table_properties_dialog.dart';
import '../menu.dart';
import '../ribbon.dart';
import '../table_geometry.dart';
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
                  final from = c.activeView.state.selection.from;
                  ops.selectCellRange(c.activeView.state, c.dispatch, from, from);
                }),
            extraClass: 'dq-office-btn-labeled',
            icon: 'select-tool'),
        kit.button('Linha', 'Selecionar linha',
            () => run(() => ops.selectTableRow(c.activeView.state, c.dispatch)),
            extraClass: 'dq-office-btn-labeled'),
        kit.button('Coluna', 'Selecionar coluna',
            () => run(() => ops.selectTableColumn(c.activeView.state, c.dispatch)),
            extraClass: 'dq-office-btn-labeled'),
        kit.button('Tabela', 'Selecionar tabela',
            () => run(() => ops.selectWholeTable(c.activeView.state, c.dispatch)),
            extraClass: 'dq-office-btn-labeled'),
      ]),
      kit.row([
        kit.button('Propriedades', 'Propriedades da Tabela',
            () => run(() => openTablePropertiesDialog(c)),
            extraClass: 'dq-office-btn-labeled'),
      ]),
    ]),
    kit.group('Linhas e Colunas', [
      kit.row([
        kit.button(
            'Acima',
            'Inserir linha acima',
            () => run(() => ops.tableInsertRow(
                c.activeView.state, c.dispatch, c.schema,
                above: true)),
            extraClass: 'dq-office-btn-labeled',
            icon: 'addcell'),
        kit.button(
            'Abaixo',
            'Inserir linha abaixo',
            () => run(() => ops.tableInsertRow(
                c.activeView.state, c.dispatch, c.schema,
                above: false)),
            extraClass: 'dq-office-btn-labeled'),
        kit.button(
            'À Esquerda',
            'Inserir coluna à esquerda',
            () => run(() => ops.tableInsertColumn(
                c.activeView.state, c.dispatch, c.schema,
                before: true)),
            extraClass: 'dq-office-btn-labeled'),
        kit.button(
            'À Direita',
            'Inserir coluna à direita',
            () => run(() => ops.tableInsertColumn(
                c.activeView.state, c.dispatch, c.schema,
                before: false)),
            extraClass: 'dq-office-btn-labeled'),
      ]),
      kit.row([
        kit.button('Excluir Linha', 'Excluir linha',
            () => run(() => ops.tableDeleteRow(c.activeView.state, c.dispatch)),
            extraClass: 'dq-office-btn-labeled', icon: 'delcell'),
        kit.button('Excluir Coluna', 'Excluir coluna',
            () => run(() => ops.tableDeleteColumn(c.activeView.state, c.dispatch)),
            extraClass: 'dq-office-btn-labeled'),
        kit.button('Excluir Tabela', 'Excluir tabela',
            () => run(() => ops.tableDelete(c.activeView.state, c.dispatch)),
            extraClass: 'dq-office-btn-labeled'),
      ]),
    ]),
    kit.group('Mesclar', [
      kit.row([
        kit.button('Mesclar', 'Mesclar células',
            () => run(() => ops.mergeSelectedCells(c.activeView.state, c.dispatch)),
            extraClass: 'dq-office-btn-labeled', icon: 'merge-cells'),
        kit.button('Dividir', 'Dividir célula',
            () => run(() => ops.splitSelectedCell(c.activeView.state, c.dispatch)),
            extraClass: 'dq-office-btn-labeled', icon: 'rows-and-columns'),
      ]),
    ]),
    kit.group('Tamanho da Célula', [
      kit.row([
        _rowHeightSpinner(ctx),
        _columnWidthSpinner(ctx),
      ]),
      kit.row([
        kit.button('Distribuir Linhas', 'Distribuir linhas uniformemente',
            () => run(() => _distributeRows(c)),
            extraClass: 'dq-office-btn-labeled', icon: 'distribute-rows'),
        kit.button('Distribuir Colunas', 'Distribuir colunas uniformemente',
            () => run(() => _distributeColumns(c)),
            extraClass: 'dq-office-btn-labeled', icon: 'distribute-columns'),
        menuButton(c, 'AutoAjuste', 'AutoAjuste', 'table:autofit',
            () => _autoFitEntries(c),
            icon: 'advanced-ratio'),
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
                  ops.setCellVerticalAlign(c.activeView.state, c.dispatch, value)),
              icon: icon),
      ]),
      kit.row([
        kit.button(
            'Margens da Célula',
            'Margens internas da célula (w:tcMar)',
            () => run(() =>
                openTablePropertiesDialog(c, initialGroup: officeCellTab)),
            extraClass: 'dq-office-btn-labeled'),
        menuButton(c, 'Direção do Texto', 'Direção do Texto',
            'table:textdirection', _textDirectionEntries),
      ]),
    ]),
    kit.group('Dados', [
      kit.row([
        _repeatHeaderButton(ctx),
      ]),
    ]),
  ];
}

/// O menu AutoAjuste.
///
/// "À Janela" e "Largura Fixa" são as duas que este motor sabe honrar, e as
/// duas partem da grade REALMENTE projetada (`table_geometry.dart`), não dos
/// atributos crus — uma tabela sem `w:tblGrid` completo tem colunas que o
/// compositor preenche com a sobra da página.
///
/// "Ao Conteúdo" fica visível e DESABILITADA: o compositor resolve largura de
/// coluna só a partir de `colWidths` e da área útil
/// (`layout_composer.dart:3384-3416`) e nunca mede o conteúdo para decidir a
/// grade. Habilitá-la exigiria calcular largura mínima/máxima de texto por
/// coluna dentro do compositor; até lá, o item explica o motivo em vez de
/// gravar um `w:tblLayout` que a tela ignora.
List<OfficeMenuEntry> _autoFitEntries(OfficeWordController c) => [
      OfficeMenuEntry(
        label: 'AutoAjuste à Janela',
        description: 'Estica a tabela até a margem, mantendo a proporção '
            'entre as colunas',
        onSelect: () => _autoFit(c, ops.OfficeTableAutoFit.window),
      ),
      OfficeMenuEntry(
        label: 'Largura Fixa da Coluna',
        description: 'Congela na tabela a grade que está na tela — mudar a '
            'margem ou o papel deixa de redistribuir as colunas',
        onSelect: () => _autoFit(c, ops.OfficeTableAutoFit.fixed),
      ),
      const OfficeMenuEntry(
        label: 'AutoAjuste ao Conteúdo',
        description: 'O compositor nunca mede o conteúdo para decidir a '
            'largura das colunas',
        enabled: false,
      ),
    ];

/// O menu Direção do Texto — inteiro desabilitado, de propósito.
///
/// `w:textDirection` não é lido em lugar nenhum de
/// `lib/src/document_engine/layout/`: o compositor mede e posiciona todo run
/// na horizontal (o `LineBox` só tem largura e altura, sem eixo), e o
/// renderer desenha a célula sem transformação. Gravar o atributo giraria o
/// texto no Word e não giraria nada aqui — o pior defeito possível, porque o
/// arquivo passaria a discordar da tela.
List<OfficeMenuEntry> _textDirectionEntries() {
  const pending = 'O compositor escreve todo run na horizontal '
      '(w:textDirection não é lido em layout/)';
  return const [
    OfficeMenuEntry(
      label: 'Horizontal',
      description: 'O layout atual do editor',
      checked: true,
      enabled: false,
    ),
    OfficeMenuEntry(
      label: 'Girar todo o texto em 90°',
      description: pending,
      enabled: false,
    ),
    OfficeMenuEntry(
      label: 'Girar todo o texto em 270°',
      description: pending,
      enabled: false,
    ),
  ];
}

void _autoFit(OfficeWordController c, ops.OfficeTableAutoFit mode) {
  final state = c.activeView.state;
  final map = OfficeTableMap.at(state.doc, state.selection.from);
  if (map == null) return;
  ops.setTableAutoFit(
    state,
    c.dispatch,
    mode: mode,
    currentWidths: officeTableColumnWidths(c.view.pageGraph, map.tablePos,
        columns: map.columns),
    availableTwips: c.pageSetup.contentWidthTwips,
  );
}

/// O botão "Repetir Linhas de Cabeçalho", com o realce ligado ao modelo.
///
/// Ele ACENDE quando a seleção está na faixa de cabeçalho, como no Word — e
/// o realce vem de `registerRefresh`, então mover o cursor para outra tabela
/// atualiza o botão sem que esta aba tenha um listener próprio.
DomElement _repeatHeaderButton(RibbonContext ctx) {
  final c = ctx.controller;
  late final DomElement button;
  button = ctx.kit.button(
    'Repetir Linhas de Cabeçalho',
    'Repetir a(s) linha(s) de cabeçalho no topo de cada página',
    () {
      c.syncSelection();
      ops.setTableHeaderRows(c.activeView.state, c.dispatch,
          repeat: !ops.tableHeaderRowsActive(c.activeView.state));
    },
    extraClass: 'dq-office-btn-labeled',
    icon: 'menu-header',
  );
  ctx.registerRefresh(() {
    if (!c.viewReady) return;
    if (ops.tableHeaderRowsActive(c.activeView.state)) {
      button.classes.add('dq-office-btn-active');
    } else {
      button.classes.remove('dq-office-btn-active');
    }
  });
  return button;
}

/// Spinner de ALTURA da linha, em centímetros.
///
/// Grava `w:trHeight` com a regra `atLeast` — a mesma escolha de "Distribuir
/// Linhas": `exact` cortaria em silêncio o conteúdo que não coubesse. Zero
/// devolve a linha à altura automática.
DomElement _rowHeightSpinner(RibbonContext ctx) {
  final c = ctx.controller;
  return _cellSizeSpinner(
    ctx,
    'Altura',
    'Altura da linha (cm)',
    onCommit: (twips) => ops.setRowProperties(c.activeView.state, c.dispatch,
        heightTwips: twips, heightRule: 'atLeast'),
    read: () {
      final positions = ops.selectedRowPositions(c.activeView.state);
      if (positions.isEmpty) return null;
      final row = c.activeView.state.doc.nodeAt(positions.first);
      final word = row?.attrs['word'];
      final value = word is Map ? word['heightTwips'] : null;
      return value is num ? value.toInt() : 0;
    },
  );
}

/// Spinner de LARGURA da coluna, em centímetros.
///
/// O valor exibido é o PROJETADO (a largura que o compositor resolveu), e
/// não o declarado: numa tabela sem `w:tblGrid` completo os dois diferem, e
/// mostrar o declarado colocaria no campo um número que não corresponde a
/// nada na tela.
DomElement _columnWidthSpinner(RibbonContext ctx) {
  final c = ctx.controller;
  ({OfficeTableMap map, int column})? target() {
    final state = c.activeView.state;
    final map = OfficeTableMap.at(state.doc, state.selection.from);
    final cell = map?.cellAt(state.selection.from);
    if (map == null || cell == null) return null;
    return (map: map, column: cell.column);
  }

  return _cellSizeSpinner(
    ctx,
    'Largura',
    'Largura da coluna (cm)',
    onCommit: (twips) {
      final current = target();
      if (current == null || twips <= 0) return;
      ops.setTableColumnWidth(
        c.activeView.state,
        c.dispatch,
        tablePos: current.map.tablePos,
        columnIndex: current.column,
        widthTwips: twips,
        projectedWidths: officeTableColumnWidths(
            c.view.pageGraph, current.map.tablePos,
            columns: current.map.columns),
      );
    },
    read: () {
      final current = target();
      if (current == null) return null;
      final widths = officeTableColumnWidths(
          c.view.pageGraph, current.map.tablePos,
          columns: current.map.columns);
      return current.column < widths.length ? widths[current.column] : null;
    },
  );
}

/// O par de spinners de "Tamanho da Célula": rótulo, campo em cm e o mesmo
/// laço de reflexo do modelo dos spinners da aba Layout.
DomElement _cellSizeSpinner(
  RibbonContext ctx,
  String label,
  String title, {
  required void Function(int twips) onCommit,
  required int? Function() read,
}) {
  final c = ctx.controller;
  final kit = ctx.kit;
  final wrap = kit.el('label', 'dq-office-spinner');
  final caption = kit.el('span', 'dq-office-spinner-label');
  caption.appendText(label);
  wrap.append(caption);

  final input = kit.el('input', 'dq-office-spinner-input');
  input.setAttribute('type', 'number');
  input.setAttribute('step', '0.1');
  input.setAttribute('min', '0');
  input.setAttribute('title', title);
  input.addEventListener('change', (_) {
    final typed = double.tryParse(input.value.replaceAll(',', '.'));
    if (typed == null || typed < 0) return;
    c.syncSelection();
    onCommit((typed * 567).round());
  });
  wrap.append(input);

  ctx.registerRefresh(() {
    if (!c.viewReady) return;
    final twips = read();
    if (twips == null) {
      input.value = '';
      return;
    }
    final value = twips / 567.0;
    input.value = value == value.roundToDouble()
        ? '${value.round()}'
        : value.toStringAsFixed(2);
  });
  return wrap;
}

/// Distribui as colunas preservando a largura da tabela.
///
/// A área útil da página é o fallback de [ops.distributeTableColumns] para
/// tabelas sem `w:tblGrid` — o chrome conhece a geometria da seção, a função
/// pura não.
void _distributeColumns(OfficeWordController c) {
  final setup = c.pageSetup;
  ops.distributeTableColumns(
    c.activeView.state,
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
  final state = c.activeView.state;
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
