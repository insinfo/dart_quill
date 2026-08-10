/// O diálogo "Propriedades da Tabela" do Word, nas quatro abas dele:
/// Tabela, Linha, Coluna e Célula.
///
/// **O que NÃO está aqui e por quê.** O Word oferece, nas mesmas abas,
/// alinhamento da tabela na página, recuo à esquerda, quebra automática de
/// texto ao redor e direção do texto na célula. Nenhum dos quatro é lido em
/// `lib/src/document_engine/layout/`: o compositor posiciona toda tabela na
/// borda esquerda da área útil (`layout_composer.dart:3639-3660`, onde o x da
/// primeira coluna vem só de `gridBefore`/`widthBefore`), não tem fluxo de
/// texto ao redor de bloco, e escreve todo run na horizontal. Um campo que
/// gravasse `w:jc`, `w:tblInd` ou `w:textDirection` seria uma caixinha que
/// não muda um pixel — e mentiria também no DOCX, porque o arquivo passaria
/// a dizer algo que a tela nunca mostrou.
///
/// O que está aqui é honrado ponta a ponta; a lista com o `arquivo:linha` de
/// cada leitura está em `table_ops.applyTableProperties`.
///
/// Os valores iniciais vêm da PROJEÇÃO (o `PageGraph` recém-composto) sempre
/// que existe uma resolução em jogo — largura de coluna e margens internas —
/// e do modelo quando o que importa é a DECLARAÇÃO (altura da linha, quebra,
/// cabeçalho). É a mesma escolha de "Distribuir Linhas": mostrar um número
/// que não é o da tela seria pior do que não mostrar nenhum.
library;

import '../../layout/page_graph.dart';
import '../controller.dart';
import '../table_geometry.dart';
import '../table_map.dart';
import '../table_ops.dart' as ops;
import 'dialog.dart';

/// As abas, na ordem do Word.
const String officeTableTab = 'Tabela';
const String officeRowTab = 'Linha';
const String officeColumnTab = 'Coluna';
const String officeCellTab = 'Célula';

/// Abre o diálogo para a tabela da seleção. Sem tabela, não abre.
void openTablePropertiesDialog(
  OfficeWordController controller, {
  String? initialGroup,
}) {
  final state = controller.view.state;
  final scope = ops.tableFormatScope(state);
  if (scope == null) return;
  final map = scope.map;
  final cell = scope.cells.first;
  final graph = controller.view.pageGraph;
  final box = officeTableCellBox(graph, cell.pos);

  final columnWidths =
      officeTableColumnWidths(graph, map.tablePos, columns: map.columns);
  final columnWidth = cell.column < columnWidths.length
      ? columnWidths[cell.column]
      : (box?.widthTwips ?? 0);

  // A aba Linha mostra a PRIMEIRA linha da seleção; o OK aplica a todas
  // elas, como o Word faz com várias linhas selecionadas.
  final rowPositions = ops.selectedRowPositions(state);
  final row =
      rowPositions.isEmpty ? null : state.doc.nodeAt(rowPositions.first);
  final rowWord = row?.attrs['word'];
  final rowMap = rowWord is Map ? rowWord : const {};
  final heightTwips = rowMap['heightTwips'];

  // A margem interna EFETIVA da célula é a que o compositor resolveu (tcMar
  // → tblCellMar → padrão), e é ela que o usuário vê. Sem projeção (documento
  // ainda não composto) o campo fica vazio em vez de inventar um número.
  String margin(int? twips) => twips == null ? '' : _cm(twips);

  // A aba Linha só oferece "repetir como cabeçalho" quando a seleção alcança
  // a primeira linha — fora daí a caixinha não teria efeito nenhum, porque o
  // compositor só honra a corrida INICIAL de `w:tblHeader`.
  final headerAvailable = scope.cells.any((cell) => cell.row == 0);

  OfficeDialog(
    controller: controller,
    title: 'Propriedades da Tabela',
    initialGroup: initialGroup,
    fields: [
      for (final (key, label) in const [
        ('tableMarginTop', 'Margem interna padrão: superior'),
        ('tableMarginBottom', 'Margem interna padrão: inferior'),
        ('tableMarginLeft', 'Margem interna padrão: esquerda'),
        ('tableMarginRight', 'Margem interna padrão: direita'),
      ])
        OfficeDialogField(
          key: key,
          label: label,
          kind: 'number',
          step: '0.05',
          min: '0',
          group: officeTableTab,
          value: margin(_tableMargin(map, key)),
          hint: 'cm — vale nas células que não declaram a sua',
        ),
      OfficeDialogField(
        key: 'rowHeight',
        label: 'Altura da linha',
        kind: 'number',
        step: '0.1',
        min: '0',
        group: officeRowTab,
        value: heightTwips is num ? _cm(heightTwips.toInt()) : '0',
        hint: 'cm — 0 deixa a altura automática',
      ),
      OfficeDialogField(
        key: 'rowHeightRule',
        label: 'Regra da altura',
        kind: 'select',
        options: const ['Pelo menos', 'Exatamente'],
        group: officeRowTab,
        value: rowMap['heightRule'] == 'exact' ? 'Exatamente' : 'Pelo menos',
        hint: '"Exatamente" corta o conteúdo que não couber, como no Word',
      ),
      OfficeDialogField(
        key: 'rowCantSplit',
        label: 'Permitir quebra da linha entre páginas',
        kind: 'check',
        group: officeRowTab,
        value: rowMap['cantSplit'] == true ? 'false' : 'true',
      ),
      if (headerAvailable)
        OfficeDialogField(
          key: 'repeatHeader',
          label: 'Repetir como linha de cabeçalho em cada página',
          kind: 'check',
          group: officeRowTab,
          value: ops.tableHeaderRowCount(map) > 0 ? 'true' : 'false',
        ),
      OfficeDialogField(
        key: 'columnWidth',
        label: 'Largura da coluna',
        kind: 'number',
        step: '0.1',
        min: '0',
        group: officeColumnTab,
        value: columnWidth > 0 ? _cm(columnWidth) : '',
        hint: 'cm — grava a grade (w:tblGrid) e o w:tcW das células dela',
      ),
      OfficeDialogField(
        key: 'cellWidth',
        label: 'Largura preferida da célula',
        kind: 'number',
        step: '0.1',
        min: '0',
        group: officeCellTab,
        value: box == null ? '' : _cm(box.widthTwips),
        hint: 'cm',
      ),
      OfficeDialogField(
        key: 'cellVerticalAlign',
        label: 'Alinhamento vertical',
        kind: 'select',
        options: const ['Superior', 'Centro', 'Inferior'],
        group: officeCellTab,
        value: switch (box?.verticalAlign) {
          TableCellVerticalAlign.center => 'Centro',
          TableCellVerticalAlign.bottom => 'Inferior',
          _ => 'Superior',
        },
      ),
      for (final (key, label, twips) in [
        ('cellMarginTop', 'Margem interna: superior', box?.marginTopTwips),
        (
          'cellMarginBottom',
          'Margem interna: inferior',
          box?.marginBottomTwips
        ),
        ('cellMarginLeft', 'Margem interna: esquerda', box?.marginLeftTwips),
        ('cellMarginRight', 'Margem interna: direita', box?.marginRightTwips),
      ])
        OfficeDialogField(
          key: key,
          label: label,
          kind: 'number',
          step: '0.05',
          min: '0',
          group: officeCellTab,
          value: margin(twips),
          hint: 'cm',
        ),
    ],
    onApply: (values) {
      int? twips(String key) {
        final raw = (values[key] ?? '').trim().replaceAll(',', '.');
        if (raw.isEmpty) return null;
        final parsed = double.tryParse(raw);
        if (parsed == null || parsed < 0) return null;
        return (parsed * 567).round();
      }

      Map<String, int> margins(String prefix) {
        final sides = <String, int>{};
        for (final side in const ['Top', 'Bottom', 'Left', 'Right']) {
          final value = twips('$prefix$side');
          if (value != null) sides[side.toLowerCase()] = value;
        }
        return sides;
      }

      ops.applyTableProperties(
        controller.view.state,
        controller.dispatch,
        tableCellMargins: margins('tableMargin'),
        rowHeightTwips: twips('rowHeight'),
        rowHeightRule:
            values['rowHeightRule'] == 'Exatamente' ? 'exact' : 'atLeast',
        rowCantSplit: values['rowCantSplit'] != 'true',
        // Ausente quando a aba Linha não ofereceu a caixinha: aí a seleção
        // não alcança a primeira linha e não há cabeçalho a decidir.
        repeatHeaderRows: values.containsKey('repeatHeader')
            ? values['repeatHeader'] == 'true'
            : null,
        columnWidthTwips: twips('columnWidth'),
        cellWidthTwips: twips('cellWidth'),
        cellVerticalAlign: switch (values['cellVerticalAlign']) {
          'Centro' => 'center',
          'Inferior' => 'bottom',
          _ => 'top',
        },
        cellMargins: margins('cellMargin'),
        projectedColumnWidths: columnWidths,
      );
    },
  ).open();
}

/// A margem padrão DECLARADA pela tabela, ou null quando ela não declara.
int? _tableMargin(OfficeTableMap map, String key) {
  final word = map.table.attrs['word'];
  if (word is! Map) return null;
  final margins = word['cellMargins'];
  if (margins is! Map) return null;
  final side = switch (key) {
    'tableMarginTop' => 'top',
    'tableMarginBottom' => 'bottom',
    'tableMarginLeft' => 'left',
    _ => 'right',
  };
  final value = margins[side];
  if (value is! Map) return null;
  final raw = value['value'];
  return raw is num ? raw.toInt() : int.tryParse('$raw');
}

/// twips → cm com duas casas, o formato dos campos do Word em pt-BR.
String _cm(int twips) {
  final value = twips / 567.0;
  return value == value.roundToDouble()
      ? '${value.round()}'
      : value.toStringAsFixed(2);
}
