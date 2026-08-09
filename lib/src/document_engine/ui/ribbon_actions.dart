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
  final mark = type.create(attrs);
  if (selection.empty) {
    c.dispatch(c.view.state.tr..addStoredMark(mark));
  } else {
    c.dispatch(c.view.state.tr..addMark(selection.from, selection.to, mark));
  }
}

/// O valor da marca [markName] vigente na seleção (caret: o que a próxima
/// digitação usará), ou null.
String? currentMarkValue(OfficeWordController c, String markName) {
  final type = c.schema.marks[markName];
  if (type == null) return null;
  final state = c.view.state;
  final selection = state.selection;
  final marks = selection.empty
      ? (state.storedMarks ?? selection.fromRes.marks())
      : state.doc.resolve(selection.from + 1).marks();
  for (final mark in marks) {
    if (mark.type == type) return mark.attrs['value'] as String?;
  }
  return null;
}

/// A escada de tamanhos do Word (o que A^ e A˅ percorrem).
const List<int> wordFontSizes = [
  8,
  9,
  10,
  11,
  12,
  14,
  16,
  18,
  20,
  24,
  28,
  36,
  48,
  72
];

/// Aumentar/Diminuir Fonte: um degrau na escada a partir do tamanho vigente.
void stepFontSize(OfficeWordController c, {required bool up}) {
  c.syncSelection();
  final raw = currentMarkValue(c, 'size') ?? '12pt';
  final current = int.tryParse(raw.replaceAll('pt', '')) ?? 12;
  int next = current;
  if (up) {
    next = wordFontSizes.firstWhere((s) => s > current, orElse: () => current);
  } else {
    next = wordFontSizes.lastWhere((s) => s < current, orElse: () => current);
  }
  if (next != current) {
    addMarkOverSelection(c, 'size', {'value': '${next}pt'});
  }
}

/// x₂/x² do Word: liga sub/sobrescrito, desliga se já era o mesmo.
void toggleScript(OfficeWordController c, String value) {
  final type = c.schema.marks['script'];
  if (type == null) return;
  c.syncSelection();
  final selection = c.view.state.selection;
  final tr = c.view.state.tr;
  if (currentMarkValue(c, 'script') == value) {
    if (selection.empty) {
      tr.removeStoredMark(type);
    } else {
      tr.removeMark(selection.from, selection.to, type);
    }
  } else {
    final mark = type.create({'value': value});
    if (selection.empty) {
      tr.addStoredMark(mark);
    } else {
      tr.addMark(selection.from, selection.to, mark);
    }
  }
  c.dispatch(tr);
}

/// A borracha do Word: remove TODAS as marcas da seleção.
void clearFormatting(OfficeWordController c) {
  c.syncSelection();
  final selection = c.view.state.selection;
  final tr = c.view.state.tr;
  if (selection.empty) {
    tr.setStoredMarks([]);
  } else {
    tr.removeMark(selection.from, selection.to);
  }
  c.dispatch(tr);
}

/// Cor da fonte / realce: aplica a marca, ou a remove com [color] null.
void applyMarkColor(OfficeWordController c, String markName, String? color) {
  final type = c.schema.marks[markName];
  if (type == null) return;
  c.syncSelection();
  final selection = c.view.state.selection;
  final tr = c.view.state.tr;
  if (color == null) {
    if (selection.empty) {
      tr.removeStoredMark(type);
    } else {
      tr.removeMark(selection.from, selection.to, type);
    }
  } else {
    final mark = type.create({'value': color});
    if (selection.empty) {
      tr.addStoredMark(mark);
    } else {
      tr.addMark(selection.from, selection.to, mark);
    }
  }
  c.dispatch(tr);
}

/// Aa do Word (simplificado): alterna a seleção entre MAIÚSCULAS e
/// minúsculas.
void toggleCase(OfficeWordController c) {
  c.syncSelection();
  final state = c.view.state;
  final selection = state.selection;
  if (selection.empty) return;
  final text = state.doc.textBetween(selection.from, selection.to);
  if (text.isEmpty) return;
  final next =
      text == text.toUpperCase() ? text.toLowerCase() : text.toUpperCase();
  c.dispatch(state.tr..insertText(next, selection.from, selection.to));
}

/// Aumentar/Diminuir Recuo (o passo de 1,27 cm do Word).
void indentBy(OfficeWordController c, int deltaTwips) {
  c.syncSelection();
  final style = c.currentBlockStyle();
  final current =
      style?['indentTwips'] is num ? (style!['indentTwips'] as num).toInt() : 0;
  final content = c.pageSetup.contentWidthTwips;
  c.applyBlockStyle(
      {'indentTwips': (current + deltaTwips).clamp(0, content - 567)});
}

// -- área de transferência interna + pincel de formatação ---------------------

/// Clipboard INTERNO do componente (os botões da ribbon não têm acesso ao
/// clipboard do sistema sem permissão do browser — Ctrl+C/V continuam sendo
/// o caminho nativo, como no Word Online).
Slice? _internalClipboard;

/// Marcas armadas pelo Pincel de Formatação, aplicadas à PRÓXIMA seleção.
List<Mark>? _painterMarks;

void copySelection(OfficeWordController c) {
  c.syncSelection();
  final selection = c.view.state.selection;
  if (selection.empty) return;
  _internalClipboard = selection.content();
}

void cutSelection(OfficeWordController c) {
  c.syncSelection();
  final selection = c.view.state.selection;
  if (selection.empty) return;
  _internalClipboard = selection.content();
  c.dispatch(c.view.state.tr..deleteSelection());
}

void pasteInternal(OfficeWordController c) {
  final slice = _internalClipboard;
  if (slice == null) return;
  c.syncSelection();
  c.dispatch(c.view.state.tr..replaceSelection(slice));
}

/// Pincel de Formatação: copia as marcas vigentes; a próxima seleção as
/// recebe (one-shot, como um clique no pincel do Word).
void armFormatPainter(OfficeWordController c) {
  c.syncSelection();
  final state = c.view.state;
  final selection = state.selection;
  _painterMarks = List.of(selection.empty
      ? (state.storedMarks ?? selection.fromRes.marks())
      : state.doc.resolve(selection.from + 1).marks());
}

bool get formatPainterArmed => _painterMarks != null;

/// Chamado pelo orquestrador no mouseup do canvas: aplica e desarma.
void maybeApplyFormatPainter(OfficeWordController c) {
  final marks = _painterMarks;
  if (marks == null) return;
  _painterMarks = null;
  c.syncSelection();
  final selection = c.view.state.selection;
  if (selection.empty) return;
  final tr = c.view.state.tr;
  tr.removeMark(selection.from, selection.to);
  for (final mark in marks) {
    tr.addMark(selection.from, selection.to, mark);
  }
  c.dispatch(tr);
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
      ? cmd.setBlockType(c.schema.nodes['paragraph']!, (PMNode node) {
          return {
            'word': _wordAttrs(node, clearNumbering: true),
            'style': _styleWithoutListMarker(node),
          };
        })
      : cmd.setBlockType(c.schema.nodes['listItem']!, (PMNode node) {
          return {
            'kind': kind,
            'style': _styleWithoutListMarker(node),
          };
        });
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
  final styleId = level == null ? 'Normal' : 'Heading$level';
  final target =
      level == null ? c.schema.nodes['paragraph']! : c.schema.nodes['heading']!;
  final command = cmd.setBlockType(target, (PMNode node) {
    return {
      if (level != null) 'level': level,
      'word': _wordAttrs(
        node,
        styleId: styleId,
        clearNumbering: node.type.name == 'listItem',
      ),
      if (node.type.name == 'listItem') 'style': _styleWithoutListMarker(node),
    };
  });
  command(c.view.state, c.dispatch);
}

/// Keeps imported paragraph properties while changing only what the ribbon
/// action explicitly means to change. `numId=0` is OOXML's explicit
/// "numbering off" value, including when numbering came from a paragraph
/// style rather than direct formatting.
Map<String, dynamic> _wordAttrs(
  PMNode node, {
  String? styleId,
  bool clearNumbering = false,
}) {
  final raw = node.attrs['word'];
  final word = raw is Map
      ? Map<String, dynamic>.from(raw.cast<String, dynamic>())
      : <String, dynamic>{};
  if (styleId != null) word['styleId'] = styleId;
  if (clearNumbering) {
    word['numPr'] = <String, dynamic>{'numId': 0, 'ilvl': 0};
  }
  return word;
}

dynamic _styleWithoutListMarker(PMNode node) {
  final raw = node.attrs['style'];
  if (raw is! Map) return raw;
  final style = Map<String, dynamic>.from(raw.cast<String, dynamic>());
  style.remove('marker');
  return style.isEmpty ? null : style;
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
  tr.doc.nodesBetween(around - table.nodeSize < 0 ? 0 : around - table.nodeSize,
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
