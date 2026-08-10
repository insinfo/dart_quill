/// A geometria de uma tabela LIDA DA PROJEÇÃO, não recalculada.
///
/// Três controles precisam saber "onde estão as divisas das colunas" e
/// "quanto de margem interna esta célula tem de verdade": os marcadores de
/// coluna da régua, o AutoAjuste e o diálogo Propriedades da Tabela. A
/// resposta existe em UM lugar só — o `PageGraph` que o compositor acabou de
/// produzir — e é de lá que ela vem.
///
/// Recalcular a grade no chrome seria uma segunda implementação da resolução
/// de largura de `layout_composer._tableColumnWidths` (que preenche colunas
/// omitidas com a sobra da página e ESCALA a grade inteira quando ela não
/// cabe). Duas implementações divergem: o marcador da régua apareceria num
/// lugar e a divisa desenhada em outro, e o AutoAjuste "à janela" partiria de
/// uma largura que não é a da tela.
library;

import '../layout/page_graph.dart';

/// O fragmento composto da tabela que contém a posição [docPos].
///
/// Uma tabela longa aparece em VÁRIOS fragmentos (um por página); vale o
/// primeiro que contém a posição, que é a página onde o cursor está.
TableFragment? officeTableFragmentAt(PageGraph graph, int docPos) {
  for (final page in graph.pages) {
    for (final fragment in page.fragments) {
      if (fragment is! TableFragment) continue;
      if (docPos >= fragment.docFrom && docPos <= fragment.docTo) {
        return fragment;
      }
    }
  }
  return null;
}

/// Todos os fragmentos da tabela cujo nó começa em [tablePos].
///
/// A largura de coluna é a mesma em todas as páginas, mas o fragmento da
/// página onde o cursor está pode ser justamente o que só tem células
/// mescladas; varrer todos dá a grade completa.
List<TableFragment> officeTableFragments(PageGraph graph, int tablePos) => [
      for (final page in graph.pages)
        for (final fragment in page.fragments)
          if (fragment is TableFragment && fragment.docFrom == tablePos)
            fragment,
    ];

/// A caixa composta da célula cujo NÓ começa em [cellPos].
TableCellBox? officeTableCellBox(PageGraph graph, int cellPos) {
  for (final page in graph.pages) {
    for (final fragment in page.fragments) {
      if (fragment is! TableFragment) continue;
      for (final row in fragment.rows) {
        // Uma cópia de cabeçalho repetido projeta a MESMA célula de novo, com
        // a mesma posição de documento: responder com ela daria a geometria
        // da página errada.
        if (row.isRepeatedHeader) continue;
        for (final cell in row.cells) {
          if (cell.docFrom == cellPos) return cell;
        }
      }
    }
  }
  return null;
}

/// As larguras das colunas COMO PROJETADAS, em twips.
///
/// Só células de `columnSpan == 1` medem uma coluna; uma célula mesclada
/// mede a soma delas e não diz como a soma se divide. Colunas que nenhuma
/// célula simples cobre (acontece em tabelas que mesclam a coluna inteira)
/// entram com a sobra dividida igualmente entre elas, que é o mesmo critério
/// do compositor para grade incompleta.
List<int> officeTableColumnWidths(
  PageGraph graph,
  int tablePos, {
  required int columns,
}) {
  if (columns <= 0) return const [];
  final widths = List<int>.filled(columns, 0);
  final spans = <({int start, int span, int width})>[];
  for (final fragment in officeTableFragments(graph, tablePos)) {
    for (final row in fragment.rows) {
      if (row.isRepeatedHeader) continue;
      for (final cell in row.cells) {
        if (cell.columnIndex < 0 || cell.columnIndex >= columns) continue;
        if (cell.columnSpan == 1) {
          if (widths[cell.columnIndex] == 0) {
            widths[cell.columnIndex] = cell.widthTwips;
          }
          continue;
        }
        spans.add((
          start: cell.columnIndex,
          span: cell.columnSpan,
          width: cell.widthTwips,
        ));
      }
    }
  }

  // Colunas cobertas só por mesclagem: reparte o que sobra do span entre as
  // que ainda estão em zero.
  for (final span in spans) {
    final missing = <int>[
      for (var c = span.start; c < span.start + span.span; c++)
        if (c < columns && widths[c] == 0) c,
    ];
    if (missing.isEmpty) continue;
    var known = 0;
    for (var c = span.start; c < span.start + span.span; c++) {
      if (c < columns) known += widths[c];
    }
    final each = (span.width - known) ~/ missing.length;
    if (each <= 0) continue;
    for (final c in missing) {
      widths[c] = each;
    }
  }
  return widths;
}

/// As divisas das colunas em twips, contadas do CONTENT BOX da página.
///
/// A i-ésima entrada é a borda DIREITA da coluna i — exatamente o ponto que o
/// usuário agarra na régua para redimensioná-la.
List<int> officeTableColumnEdges(
  PageGraph graph,
  int tablePos, {
  required int columns,
}) {
  final widths = officeTableColumnWidths(graph, tablePos, columns: columns);
  if (widths.isEmpty) return const [];
  final left = officeTableLeftTwips(graph, tablePos);
  final edges = <int>[];
  var x = left;
  for (final width in widths) {
    x += width;
    edges.add(x);
  }
  return edges;
}

/// O x da borda esquerda da tabela, relativo ao content box da página.
///
/// Não é sempre zero: `w:gridBefore`/`w:widthBefore` deslocam a primeira
/// célula de linhas irregulares, e o compositor honra os dois.
int officeTableLeftTwips(PageGraph graph, int tablePos) {
  var left = 0;
  var found = false;
  for (final fragment in officeTableFragments(graph, tablePos)) {
    for (final row in fragment.rows) {
      for (final cell in row.cells) {
        if (!found || cell.xTwips < left) {
          left = cell.xTwips;
          found = true;
        }
      }
    }
  }
  return found ? left : 0;
}
