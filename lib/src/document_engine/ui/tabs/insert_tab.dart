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
import '../../model/index.dart';
import '../controller.dart';
import '../cover_page.dart';
import '../dialogs/link_dialog.dart';
import '../header_footer.dart';
import '../image_insert.dart';
import '../menu.dart';
import '../ribbon.dart';
import '../ribbon_actions.dart' as actions;
import '../symbol_picker.dart';
import '../text_box_insert.dart';

/// Dimensões do grid do Word: 10 colunas × 8 linhas.
const int _gridColumns = 10;
const int _gridRows = 8;

List<DomElement> buildInsertTab(RibbonContext ctx) {
  final c = ctx.controller;
  final kit = ctx.kit;
  return [
    kit.group('Páginas', [
      kit.row([
        menuButton(c, 'Folha de Rosto', 'Folha de Rosto', 'insert:cover',
            () => _coverEntries(c),
            icon: 'blankpage'),
      ]),
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
    kit.group('Cabeçalho e Rodapé', [
      kit.row([
        menuButton(c, 'Cabeçalho', 'Cabeçalho', 'insert:header',
            () => _regionEntries(c, header: true),
            icon: 'editheader'),
        menuButton(c, 'Rodapé', 'Rodapé', 'insert:footer',
            () => _regionEntries(c, header: false),
            icon: 'menu-header'),
      ]),
      kit.row([
        menuButton(c, 'Número de Página', 'Número de Página',
            'insert:pagenumber', () => _pageNumberEntries(c),
            icon: 'pagenum'),
      ]),
    ]),
    kit.group('Texto', [
      kit.row([
        kit.button(
            '▭',
            'Caixa de Texto (um quadro flutuante, na frente do texto — '
                'o cursor entra nele)',
            () => insertTextBox(c),
            extraClass: 'dq-office-btn-labeled',
            icon: 'text'),
      ]),
    ]),
    kit.group('Símbolos', [
      kit.row([_symbolButton(ctx)]),
    ]),
  ];
}

/// A galeria de Folha de Rosto.
///
/// Duas capas TIPOGRÁFICAS, e o menu diz isso: as galerias com faixas
/// coloridas do Word dependem de formas decorativas que o compositor não
/// desenha, e gravá-las produziria um arquivo diferente do que está na tela
/// (ver `cover_page.dart`).
List<OfficeMenuEntry> _coverEntries(OfficeWordController c) => [
      for (final layout in officeCoverPageLayouts)
        OfficeMenuEntry(
          label: layout.name,
          description: layout.description,
          onSelect: () => insertCoverPage(c, layout.id),
        ),
    ];

/// Os dropdowns Cabeçalho e Rodapé.
///
/// Não há motor novo aqui: "Editar" é a MESMA sessão que o duplo clique na
/// região abre ([OfficeHeaderFooterSession]), e é assim de propósito — dois
/// caminhos para entrar no cabeçalho têm de terminar no mesmo estado, senão
/// um deles vira o caminho com bugs.
///
/// A página é a VISÍVEL, não a primeira: com `w:titlePg` ou páginas
/// pares/ímpares diferentes, cada página tem a sua variante, e abrir sempre
/// a da página 1 faria o usuário editar um cabeçalho que não está na tela.
List<OfficeMenuEntry> _regionEntries(
  OfficeWordController c, {
  required bool header,
}) {
  final name = header ? 'Cabeçalho' : 'Rodapé';
  final pageIndex = c.viewReady ? c.view.visiblePageIndex : 0;
  final ref = c.viewReady ? c.regionForPage(pageIndex, isHeader: header) : null;
  final hasContent = (ref?.doc?.textContent ?? '').isNotEmpty;
  return [
    OfficeMenuEntry(
      label: 'Editar $name',
      description: 'Abre a região para edição, como o duplo clique nela',
      onSelect: () =>
          c.headerFooter.enter(header: header, pageIndex: pageIndex),
    ),
    OfficeMenuEntry(
      label: 'Remover $name',
      description: hasContent
          ? 'Esvazia a região desta página'
          : 'A região já está vazia',
      enabled: hasContent,
      onSelect: ref == null ? null : () => _clearRegion(c, ref),
    ),
  ];
}

/// Esvazia a região: um documento de um parágrafo vazio, que é o que o
/// compositor e a exportação sabem tratar. Remover a PARTE do pacote seria
/// outra operação (e mexeria nas referências de `sectPr`).
void _clearRegion(OfficeWordController c, OfficeRegionRef ref) {
  c.headerFooter.exit();
  c.setRegionDocument(
    ref,
    c.schema.node('doc', null, Fragment.from([c.schema.node('paragraph')])),
    recompose: true,
  );
}

/// O dropdown Número de Página.
///
/// Os quatro itens inserem o CAMPO `PAGE`/`NUMPAGES`
/// ([actions.insertPageField]), nunca o número como texto: o compositor
/// resolve o valor por página e o Word reconhece o campo no arquivo. As duas
/// primeiras opções abrem a região antes de inserir — é o que a posição
/// "Início/Fim da Página" significa no Word.
List<OfficeMenuEntry> _pageNumberEntries(OfficeWordController c) {
  final pageIndex = c.viewReady ? c.view.visiblePageIndex : 0;

  void insertInRegion({required bool header}) {
    c.headerFooter.enter(header: header, pageIndex: pageIndex);
    actions.insertPageField(c);
  }

  return [
    OfficeMenuEntry(
      label: 'Início da Página',
      description: 'Abre o cabeçalho e insere o campo PAGE',
      onSelect: () => insertInRegion(header: true),
    ),
    OfficeMenuEntry(
      label: 'Fim da Página',
      description: 'Abre o rodapé e insere o campo PAGE',
      onSelect: () => insertInRegion(header: false),
    ),
    OfficeMenuEntry(
      label: 'Posição Atual',
      description: 'Insere o campo PAGE onde o cursor está',
      onSelect: () => actions.insertPageField(c),
    ),
    const OfficeMenuEntry.separator(),
    OfficeMenuEntry(
      label: 'Total de Páginas',
      description: 'Campo NUMPAGES (para "página 1 de N")',
      onSelect: () => actions.insertPageField(c, command: 'NUMPAGES'),
    ),
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
