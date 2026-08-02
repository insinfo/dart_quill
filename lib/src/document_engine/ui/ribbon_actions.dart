/// As ações que a ribbon dispara e os atalhos de teclado não têm.
///
/// Funções livres sobre [OfficeWordController]: as abas as chamam, os
/// testes as exercitam sem chrome, e nenhuma delas tem caminho próprio para
/// mudar o documento — tudo vira transação.
library;

import '../commands/index.dart' as cmd;
import '../layout/page_graph.dart';
import '../model/index.dart';
import '../state/index.dart';
import 'controller.dart';

/// Aplica uma marca com atributos sobre a seleção nativa (fonte/tamanho).
void addMarkOverSelection(
    OfficeWordController c, String markName, Map<String, dynamic> attrs) {
  final type = c.schema.marks[markName];
  if (type == null) return;
  c.syncSelection();
  final selection = c.view.state.selection;
  if (selection.empty) return;
  c.dispatch(
      c.view.state.tr..addMark(selection.from, selection.to, type.create(attrs)));
}

/// Alinha os BLOCOS cobertos pela seleção.
void setAlign(OfficeWordController c, String align) {
  c.syncSelection();
  final state = c.view.state;
  final tr = state.tr;
  state.doc.nodesBetween(state.selection.from, state.selection.to,
      (node, pos, parent, index) {
    if (!node.isTextblock) return true;
    tr.setNodeMarkup(pos, null, {...node.attrs, 'align': align});
    return false;
  });
  if (tr.docChanged) c.dispatch(tr);
}

/// Alterna lista no bloco: parágrafo vira `listItem` do tipo pedido, o
/// mesmo tipo volta a parágrafo, e outro tipo troca o marcador — o
/// comportamento do Word.
void toggleList(OfficeWordController c, String kind) {
  c.syncSelection();
  final block = c.view.state.selection.fromRes.parent;
  final isSame = block.type.name == 'listItem' && block.attrs['kind'] == kind;
  final command = isSame
      ? cmd.setBlockType(c.schema.nodes['paragraph']!)
      : cmd.setBlockType(c.schema.nodes['listItem']!, {'kind': kind});
  command(c.view.state, c.dispatch);
}

void applyNamedStyle(OfficeWordController c, String name) {
  c.syncSelection();
  final level = switch (name) {
    'Título 1' => 1,
    'Título 2' => 2,
    'Título 3' => 3,
    _ => null,
  };
  final command = level == null
      ? cmd.setBlockType(c.schema.nodes['paragraph']!)
      : cmd.setBlockType(c.schema.nodes['heading']!, {'level': level});
  command(c.view.state, c.dispatch);
}

/// Ctrl+Enter do Word: divide o parágrafo no cursor e o bloco novo abre a
/// página seguinte. A quebra é um ATRIBUTO do bloco, não um nó — o composer
/// fecha a página ao encontrá-lo, e o PDF sai igual.
void insertPageBreak(OfficeWordController c) {
  c.syncSelection();
  final state = c.view.state;
  final tr = state.tr;
  final from = state.selection.from;
  tr.split(from);
  final resolved = tr.doc.resolve(tr.mapping.map(from));
  final blockPos = resolved.before(resolved.depth);
  final block = tr.doc.nodeAt(blockPos);
  if (block == null) return;
  final style = block.attrs['style'];
  tr.setNodeMarkup(blockPos, null, {
    ...block.attrs,
    'style': {
      if (style is Map) ...style.cast<String, dynamic>(),
      'pageBreakBefore': true,
    },
  });
  c.dispatch(tr);
}

/// Insere uma tabela vazia no cursor, com o caret na PRIMEIRA célula —
/// como no Word (e é o que faz a aba contextual aparecer imediatamente).
void insertTable(OfficeWordController c, int rows, int cols) {
  c.syncSelection();
  PMNode cell() => c.schema
      .node('tableCell', null, Fragment.from([c.schema.node('paragraph')]));
  PMNode row() => c.schema.node(
      'tableRow', null, Fragment.from([for (var i = 0; i < cols; i++) cell()]));
  final table = c.schema.node(
      'table', null, Fragment.from([for (var r = 0; r < rows; r++) row()]));

  final from = c.view.state.selection.from;
  final tr = c.view.state.tr..replaceSelectionWith(table);
  final around = tr.mapping.map(from);
  int? cellText;
  tr.doc.nodesBetween(
      around - table.nodeSize < 0 ? 0 : around - table.nodeSize,
      around + 2 > tr.doc.content.size ? tr.doc.content.size : around + 2,
      (node, pos, parent, index) {
    if (cellText == null && node.type.name == 'table') {
      cellText = pos + 4; // table > row > cell > paragraph > texto
    }
    return cellText == null;
  });
  if (cellText != null) {
    tr.setSelection(TextSelection.create(tr.doc, cellText!));
  }
  c.dispatch(tr);
}

// -- aba Layout ---------------------------------------------------------------

String paperName(OfficeWordController c) {
  final setup = c.pageSetup;
  final w = setup.widthTwips < setup.heightTwips
      ? setup.widthTwips
      : setup.heightTwips;
  final h = setup.widthTwips < setup.heightTwips
      ? setup.heightTwips
      : setup.widthTwips;
  if (w == 12240) return h == 20160 ? 'Ofício' : 'Carta';
  return 'A4';
}

void setOrientation(OfficeWordController c, {required bool portrait}) {
  final setup = c.pageSetup;
  final w = setup.widthTwips, h = setup.heightTwips;
  final needSwap = portrait ? w > h : h > w;
  if (!needSwap) return;
  c.setPageSetup(_copySetup(setup, width: h, height: w));
}

void setPaper(OfficeWordController c, String name) {
  final (w, h) = switch (name) {
    'Ofício' => (12240, 20160), // 8,5 × 14 pol (legal)
    'Carta' => (12240, 15840), // 8,5 × 11 pol
    _ => (11906, 16838), // A4
  };
  final setup = c.pageSetup;
  final portrait = setup.heightTwips >= setup.widthTwips;
  c.setPageSetup(
      _copySetup(setup, width: portrait ? w : h, height: portrait ? h : w));
}

void setMargins(OfficeWordController c, String name) {
  final (vertical, horizontal) = switch (name) {
    'Estreita' => (720, 720), // 1,27 cm
    'Larga' => (1418, 2880), // 2,5 cm × 5,08 cm
    _ => (1418, 1418), // Normal: 2,5 cm
  };
  final setup = c.pageSetup;
  c.setPageSetup(PageSetupTwips(
    widthTwips: setup.widthTwips,
    heightTwips: setup.heightTwips,
    marginTopTwips: vertical,
    marginBottomTwips: vertical,
    marginLeftTwips: horizontal,
    marginRightTwips: horizontal,
    headerDistanceTwips: setup.headerDistanceTwips,
    footerDistanceTwips: setup.footerDistanceTwips,
  ));
}

PageSetupTwips _copySetup(PageSetupTwips setup,
        {required int width, required int height}) =>
    PageSetupTwips(
      widthTwips: width,
      heightTwips: height,
      marginTopTwips: setup.marginTopTwips,
      marginRightTwips: setup.marginRightTwips,
      marginBottomTwips: setup.marginBottomTwips,
      marginLeftTwips: setup.marginLeftTwips,
      headerDistanceTwips: setup.headerDistanceTwips,
      footerDistanceTwips: setup.footerDistanceTwips,
    );
