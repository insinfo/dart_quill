/// As ações que a ribbon dispara e os atalhos de teclado não têm.
///
/// Funções livres sobre [OfficeWordController]: as abas as chamam, os
/// testes as exercitam sem chrome, e nenhuma delas tem caminho próprio para
/// mudar o documento — tudo vira transação.
library;

import '../commands/index.dart' as cmd;
import '../layout/layout_composer.dart';
import '../layout/page_graph.dart';
import '../model/index.dart';
import '../office/style_catalog.dart';
import '../state/index.dart';
import 'controller.dart';

/// Aplica uma marca com atributos sobre a seleção nativa (fonte/tamanho).
///
/// Todas as ações deste arquivo leem `c.activeView`, não `c.view`: com o
/// modo cabeçalho/rodapé aberto, formatar tem de agir na REGIÃO que o
/// usuário está editando, e não no corpo que ficou parado atrás dela.
void addMarkOverSelection(
    OfficeWordController c, String markName, Map<String, dynamic> attrs) {
  final type = c.schema.marks[markName];
  if (type == null) return;
  c.syncSelection();
  final selection = c.activeView.state.selection;
  final mark = type.create(attrs);
  if (selection.empty) {
    c.dispatch(c.activeView.state.tr..addStoredMark(mark));
  } else {
    c.dispatch(
        c.activeView.state.tr..addMark(selection.from, selection.to, mark));
  }
}

/// O valor da marca [markName] vigente na seleção (caret: o que a próxima
/// digitação usará), ou null.
String? currentMarkValue(OfficeWordController c, String markName) {
  final type = c.schema.marks[markName];
  if (type == null) return null;
  final state = c.activeView.state;
  final selection = state.selection;
  final marks = selection.empty
      ? (state.storedMarks ?? selection.fromRes.marks())
      : state.doc.resolve(selection.from + 1).marks();
  for (final mark in marks) {
    if (mark.type == type) return mark.attrs['value'] as String?;
  }
  return null;
}

/// A fonte/tamanho EFETIVOS da seleção, como o Word os mostra na ribbon.
///
/// Duas diferenças em relação a [currentMarkValue], e as duas importam:
///
/// * **Seleção mista devolve null.** Ler só o primeiro caractere anunciaria
///   "Arial" numa seleção meio Arial meio Times; o Word deixa o controle
///   VAZIO, que é a informação honesta.
/// * **Sem marca, vale o estilo do parágrafo.** Num DOCX importado a fonte
///   costuma vir da cascata de estilos (`attrs['style']`), não de formatação
///   direta — o fallback fixo "Arial/12" mentia em todo documento real.
///
/// [markName] é `font` (família) ou `size` (corpo em pontos, sem `pt`).
String? effectiveInlineValue(OfficeWordController c, String markName) {
  final type = c.schema.marks[markName];
  if (type == null) return null;
  final state = c.activeView.state;
  final selection = state.selection;

  String? fromMarks(Iterable<Mark> marks) {
    for (final mark in marks) {
      if (mark.type == type) {
        return _normalizeInlineValue(markName, mark.attrs['value']);
      }
    }
    return null;
  }

  String? fromBlock(PMNode? block) {
    final style = block?.attrs['style'];
    if (style is! Map) return null;
    return _normalizeInlineValue(
        markName, style[markName == 'font' ? 'family' : 'sizePt']);
  }

  // Sem marca e sem estilo, o valor efetivo é o PADRÃO com que o layout
  // realmente desenhou o texto. Deixar o controle vazio aqui seria mentir
  // por omissão: vazio significa "seleção mista", não "não sei".
  final documentDefault = _normalizeInlineValue(
    markName,
    markName == 'font'
        ? LayoutComposer.defaultBaseFontFamily
        : LayoutComposer.defaultBaseFontSizePt,
  );

  if (selection.empty) {
    final marks = state.storedMarks ?? selection.fromRes.marks();
    return fromMarks(marks) ??
        fromBlock(selection.fromRes.parent) ??
        documentDefault;
  }

  String? result;
  var sawText = false;
  var mixed = false;
  state.doc.nodesBetween(selection.from, selection.to,
      (node, pos, parent, index) {
    if (mixed) return false;
    if (!node.isText) return true;
    final value = fromMarks(node.marks) ?? fromBlock(parent) ?? documentDefault;
    if (!sawText) {
      result = value;
      sawText = true;
    } else if (value != result) {
      mixed = true;
    }
    return false;
  });
  if (mixed) return null;
  // Seleção sem run de texto (só um bloco vazio): vale o estilo do bloco.
  return sawText
      ? result
      : (fromBlock(selection.fromRes.parent) ?? documentDefault);
}

/// `10.0` → `10`, `11.5` → `11.5`, `'12pt'` → `12`; família passa direto.
String? _normalizeInlineValue(String markName, Object? raw) {
  if (raw == null) return null;
  if (markName == 'font') {
    final family = '$raw'.trim();
    return family.isEmpty ? null : family;
  }
  final points = raw is num
      ? raw.toDouble()
      : double.tryParse('$raw'.replaceAll('pt', '').trim());
  if (points == null || points <= 0) return null;
  return points == points.roundToDouble() ? '${points.round()}' : '$points';
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
  final selection = c.activeView.state.selection;
  final tr = c.activeView.state.tr;
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
  final selection = c.activeView.state.selection;
  final tr = c.activeView.state.tr;
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
  final selection = c.activeView.state.selection;
  final tr = c.activeView.state.tr;
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
  final state = c.activeView.state;
  final selection = state.selection;
  if (selection.empty) return;
  final text = state.doc.textBetween(selection.from, selection.to);
  if (text.isEmpty) return;
  final next =
      text == text.toUpperCase() ? text.toLowerCase() : text.toUpperCase();
  c.dispatch(state.tr..insertText(next, selection.from, selection.to));
}

// -- grupo Parágrafo: entrelinha e espaçamento --------------------------------

/// A escada do menu "Espaçamento entre Linhas e Parágrafos" do Word.
///
/// O valor é `w:spacing/@line` com regra `auto`, onde **240 = uma linha**:
/// apesar do nome histórico `lineTwips`, nessa regra o número é um múltiplo
/// em vinte avos de linha, não uma distância absoluta (é como o compositor o
/// interpreta em `layout_composer.dart`, `_resolvedLineHeightTwips`).
///
/// Esta tabela é a fonte única: o dropdown da ribbon e o campo Entrelinha do
/// diálogo Parágrafo… leem daqui. Duas listas para a mesma propriedade
/// acabariam mostrando "Simples" num parágrafo que a ribbon deixou em 1,15.
const List<({String label, int twips})> officeLineSpacingSteps = [
  (label: '1,0', twips: 240),
  (label: '1,15', twips: 276),
  (label: '1,5', twips: 360),
  (label: '2,0', twips: 480),
  (label: '2,5', twips: 600),
  (label: '3,0', twips: 720),
];

/// Quanto vale "Adicionar Espaço Antes/Depois do Parágrafo" no menu do Word:
/// 12 pt, o mesmo valor que o comando aplica lá.
const int officeParagraphSpaceStepTwips = 240;

/// Entrelinha dos blocos da seleção.
void setLineSpacing(OfficeWordController c, int twips) {
  c.syncSelection();
  // A regra viaja junto: sem `auto`, um parágrafo importado com
  // `lineRule="exact"` interpretaria 360 como 18 pt fixos em vez de 1,5 linha.
  c.applyBlockStyle({'lineTwips': twips, 'lineRule': 'auto'});
}

/// A entrelinha vigente (em `w:line`), ou null quando o bloco não opinou.
int? currentLineTwips(OfficeWordController c) {
  if (!c.viewReady) return null;
  final value = c.currentBlockStyle()?['lineTwips'];
  return value is num ? value.toInt() : null;
}

/// "Adicionar/Remover Espaço Antes (ou Depois) do Parágrafo".
void setParagraphSpace(OfficeWordController c,
    {required bool before, required int twips}) {
  c.syncSelection();
  c.applyBlockStyle({before ? 'spaceBeforeTwips' : 'spaceAfterTwips': twips});
}

/// O espaçamento vigente antes/depois, em twips (0 quando ausente).
int currentParagraphSpace(OfficeWordController c, {required bool before}) {
  if (!c.viewReady) return 0;
  final value =
      c.currentBlockStyle()?[before ? 'spaceBeforeTwips' : 'spaceAfterTwips'];
  return value is num ? value.toInt() : 0;
}

// -- grupo Parágrafo: sombreamento e bordas -----------------------------------

/// Uma aresta visível de parágrafo — meio ponto, preta, como o padrão do
/// Word (`w:sz` é medido em oitavos de ponto).
const Map<String, dynamic> officeVisibleParagraphBorder = {
  'val': 'single',
  'sizeEighths': 4,
  'color': 'auto',
};

/// Ausência EXPLÍCITA de aresta, pela mesma razão de `officeNoCellBorder`:
/// omitir a chave é "não opinei" e deixaria a aresta herdada de pé; `nil`
/// é "não quero", que é o que "Sem Bordas" precisa dizer ao Word.
const Map<String, dynamic> officeNoParagraphBorder = {'val': 'nil'};

/// As combinações de borda de parágrafo oferecidas pela ribbon.
enum OfficeParagraphBorders {
  none,
  box,
  top,
  bottom,
  left,
  right,
  topAndBottom
}

/// Bordas nos parágrafos da seleção.
///
/// Grava em `attrs['word']['borders']` — o MESMO mapa que
/// `LayoutComposer._blockDecorationOf` lê e que `docx_codec` devolve para o
/// `w:pBdr`. Não existe um segundo dialeto: o que aparece na tela é o que sai
/// no arquivo.
void setParagraphBorders(OfficeWordController c, OfficeParagraphBorders which) {
  const visible = officeVisibleParagraphBorder;
  const hidden = officeNoParagraphBorder;
  final sides = switch (which) {
    OfficeParagraphBorders.none => {
        for (final side in _paragraphBorderSides) side: hidden,
      },
    OfficeParagraphBorders.box => {
        for (final side in _paragraphBorderSides) side: visible,
      },
    OfficeParagraphBorders.topAndBottom => {
        'top': visible,
        'bottom': visible,
        'left': hidden,
        'right': hidden,
      },
    OfficeParagraphBorders.top => {'top': visible},
    OfficeParagraphBorders.bottom => {'bottom': visible},
    OfficeParagraphBorders.left => {'left': visible},
    OfficeParagraphBorders.right => {'right': visible},
  };
  _patchBlockWord(c, (word) {
    final current = word['borders'];
    return {
      ...word,
      // As arestas não mencionadas ficam intactas: pedir "borda superior" não
      // apaga a inferior, como no Word.
      'borders': {
        if (current is Map) ...current.cast<String, dynamic>(),
        ...sides,
      },
    };
  });
}

const List<String> _paragraphBorderSides = ['top', 'bottom', 'left', 'right'];

/// Sombreamento dos parágrafos da seleção. [color] em `#rrggbb`; null limpa.
///
/// O OOXML quer o hexa SEM `#` (`w:fill="D9D9D9"`), e é essa a forma gravada;
/// o compositor normaliza de volta para CSS ao compor.
void setParagraphShading(OfficeWordController c, String? color) {
  final fill = color == null
      ? null
      : (color.startsWith('#') ? color.substring(1) : color).toUpperCase();
  _patchBlockWord(c, (word) {
    final next = {...word};
    if (fill == null) {
      next.remove('shading');
    } else {
      next['shading'] = {'val': 'clear', 'color': 'auto', 'fill': fill};
    }
    return next;
  });
}

/// O sombreamento vigente do bloco do cursor, em `#rrggbb`, ou null.
String? currentParagraphShading(OfficeWordController c) {
  if (!c.viewReady) return null;
  final word = c.activeView.state.selection.fromRes.parent.attrs['word'];
  if (word is! Map) return null;
  final shading = word['shading'];
  if (shading is! Map) return null;
  final fill = shading['fill'];
  if (fill is! String || fill.isEmpty || fill.toLowerCase() == 'auto') {
    return null;
  }
  return fill.startsWith('#') ? fill : '#$fill';
}

/// Reescreve `attrs['word']` dos blocos da seleção numa transação só.
///
/// Existe aqui, e não como método do controller, porque `applyBlockStyle`
/// governa o mapa de APRESENTAÇÃO (`attrs['style']`) e este governa o mapa
/// OOXML — misturar os dois num único ponto de escrita faria uma paleta de
/// cor apagar um `w:pBdr` importado sem querer.
void _patchBlockWord(OfficeWordController c,
    Map<String, dynamic> Function(Map<String, dynamic> word) patch) {
  c.syncSelection();
  final state = c.activeView.state;
  final tr = state.tr;
  var changed = false;
  state.doc.nodesBetween(state.selection.from, state.selection.to,
      (node, pos, parent, index) {
    if (!node.isTextblock) return true;
    final raw = node.attrs['word'];
    final word = raw is Map
        ? Map<String, dynamic>.from(raw.cast<String, dynamic>())
        : <String, dynamic>{};
    tr.setNodeMarkup(pos, null, {...node.attrs, 'word': patch(word)});
    changed = true;
    return false;
  });
  if (changed) c.dispatch(tr);
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
  final selection = c.activeView.state.selection;
  if (selection.empty) return;
  _internalClipboard = selection.content();
}

void cutSelection(OfficeWordController c) {
  c.syncSelection();
  final selection = c.activeView.state.selection;
  if (selection.empty) return;
  _internalClipboard = selection.content();
  c.dispatch(c.activeView.state.tr..deleteSelection());
}

/// Há algo copiado NO editor para colar? (O menu de contexto desabilita o
/// item em vez de oferecer uma colagem que não faria nada.)
bool get hasInternalClipboard => _internalClipboard != null;

void pasteInternal(OfficeWordController c) {
  final slice = _internalClipboard;
  if (slice == null) return;
  c.syncSelection();
  c.dispatch(c.activeView.state.tr..replaceSelection(slice));
}

/// Pincel de Formatação: copia as marcas vigentes; a próxima seleção as
/// recebe (one-shot, como um clique no pincel do Word).
void armFormatPainter(OfficeWordController c) {
  c.syncSelection();
  final state = c.activeView.state;
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
  final selection = c.activeView.state.selection;
  if (selection.empty) return;
  final tr = c.activeView.state.tr;
  tr.removeMark(selection.from, selection.to);
  for (final mark in marks) {
    tr.addMark(selection.from, selection.to, mark);
  }
  c.dispatch(tr);
}

/// Alinha os BLOCOS cobertos pela seleção.
void setAlign(OfficeWordController c, String align) {
  c.syncSelection();
  final state = c.activeView.state;
  final tr = state.tr;
  state.doc.nodesBetween(state.selection.from, state.selection.to,
      (node, pos, parent, index) {
    if (!node.isTextblock) return true;
    tr.setNodeMarkup(pos, null, {...node.attrs, 'align': align});
    return false;
  });
  if (tr.docChanged) c.dispatch(tr);
}

/// Alinha o OBJETO selecionado.
///
/// Uma caixa de texto flutuante tem alinhamento próprio (`positionHAlign`,
/// que o renderer honra); uma imagem em linha herda o alinhamento do
/// parágrafo que a contém — que é exatamente como o Word se comporta nos
/// dois casos.
void setObjectAlign(OfficeWordController c, String align) {
  final state = c.activeView.state;
  final selection = state.selection;
  if (selection is! NodeSelection) return;
  final node = selection.node;
  if (node.type.name == 'textBox') {
    final tr = state.tr
      ..setNodeMarkup(selection.from, null, {
        ...node.attrs,
        'positionHAlign': align,
      });
    // `tr.doc`, NUNCA `state.doc`: depois do `setNodeMarkup` a seleção tem de
    // apontar para o documento que a transação produziu. Com o doc antigo,
    // alinhar uma caixa de texto lançava "Selection passed to setSelection
    // must point at the current document" — o botão simplesmente não
    // funcionava, e o erro morria dentro do handler do clique.
    tr.setSelection(NodeSelection.create(tr.doc, selection.from));
    c.dispatch(tr);
    return;
  }
  // Imagem em linha: alinhar o parágrafo que a contém, preservando a
  // seleção do objeto.
  final resolved = state.doc.resolve(selection.from);
  if (resolved.depth == 0) return;
  final blockPos = resolved.before(resolved.depth);
  final block = state.doc.nodeAt(blockPos);
  if (block == null) return;
  final tr = state.tr
    ..setNodeMarkup(blockPos, null, {...block.attrs, 'align': align});
  tr.setSelection(NodeSelection.create(tr.doc, selection.from));
  c.dispatch(tr);
}

/// O objeto (imagem/caixa) selecionado agora, ou null.
///
/// Existe aqui, e não só no adorno, porque a aba contextual "Formato de
/// Imagem" precisa da mesma resposta sem depender do chrome que desenha as
/// alças.
({int pos, PMNode node})? selectedObject(OfficeWordController c) {
  final selection = c.activeView.state.selection;
  if (selection is! NodeSelection) return null;
  final name = selection.node.type.name;
  if (name != 'image' && name != 'textBox') return null;
  return (pos: selection.from, node: selection.node);
}

/// Tamanho do objeto selecionado em twips, ou null.
({int width, int height})? objectSizeTwips(OfficeWordController c) {
  final target = selectedObject(c);
  if (target == null) return null;
  final width = _twipsOf(target.node.attrs['width']);
  final height = _twipsOf(target.node.attrs['height']);
  if (width <= 0 || height <= 0) return null;
  return (width: width, height: height);
}

int _twipsOf(Object? value) => switch (value) {
      num number => number.toInt(),
      _ => int.tryParse('$value') ?? 0,
    };

/// Grava o tamanho do objeto (twips), preservando a seleção do nó.
///
/// É o caminho ÚNICO de tamanho: a alça de redimensionamento
/// (`ui/object_adorner.dart`) e os campos Altura/Largura da aba contextual
/// chamam esta função. [pos]/[node] são opcionais e existem para o arrasto,
/// que já resolveu o alvo antes de o ponteiro subir.
void setObjectSizeTwips(
  OfficeWordController c, {
  int? pos,
  PMNode? node,
  int? widthTwips,
  int? heightTwips,
}) {
  final target = pos != null && node != null
      ? (pos: pos, node: node)
      : selectedObject(c);
  if (target == null) return;
  final width = widthTwips ?? _twipsOf(target.node.attrs['width']);
  final height = heightTwips ?? _twipsOf(target.node.attrs['height']);
  if (width <= 0 || height <= 0) return;
  if (width == _twipsOf(target.node.attrs['width']) &&
      height == _twipsOf(target.node.attrs['height'])) {
    return;
  }
  // A view do OBJETO: no modo cabeçalho/rodapé ele pertence ao documento da
  // região, e `activeView` é justamente quem sabe disso.
  final view = c.activeView;
  final tr = view.state.tr;
  tr.setNodeMarkup(target.pos, null, {
    ...target.node.attrs,
    'width': width,
    'height': height,
  });
  // A seleção continua no NÓ: redimensionar não é motivo para o usuário
  // perder o objeto que estava manipulando.
  tr.setSelection(NodeSelection.create(tr.doc, target.pos));
  view.dispatch(tr);
}

/// Disposição do texto do objeto selecionado, ou null quando não há objeto.
///
/// Lê o MESMO atributo que o compositor consome (`wrapMode`), com a mesma
/// farejada do XML bruto para snapshots gravados antes dele — a UI marcando
/// um modo que o layout não usa seria pior do que não marcar nenhum.
String? objectWrapMode(OfficeWordController c) {
  final selection = c.activeView.state.selection;
  if (selection is! NodeSelection) return null;
  final node = selection.node;
  if (node.type.name != 'textBox') return null;
  final declared = node.attrs['wrapMode'];
  if (declared is String && declared.isNotEmpty) return declared;
  final raw = node.attrs['word']?.toString() ?? '';
  if (raw.contains('wrapTopAndBottom')) return 'topAndBottom';
  if (raw.contains('wrapSquare')) return 'square';
  if (raw.contains('wrapTight')) return 'tight';
  if (raw.contains('wrapThrough')) return 'through';
  return 'inFrontOfText';
}

/// Troca a disposição do texto do objeto selecionado.
///
/// Só a caixa de texto aceita: ela é o único objeto que o motor modela como
/// flutuante. A imagem chega do DOCX já achatada em inline
/// (`office/document/docx/reader.dart`, "drawing flutuante (anchor) tratado
/// como inline"), então não existe âncora para reposicionar nem exclusão
/// para calcular.
void setObjectWrap(OfficeWordController c, String mode) {
  final state = c.activeView.state;
  final selection = state.selection;
  if (selection is! NodeSelection) return;
  final node = selection.node;
  if (node.type.name != 'textBox') return;
  if (objectWrapMode(c) == mode) return;
  final tr = state.tr
    ..setNodeMarkup(selection.from, null, {
      ...node.attrs,
      'wrapMode': mode,
    });
  tr.setSelection(NodeSelection.create(tr.doc, selection.from));
  c.dispatch(tr);
}

/// Apaga o objeto selecionado, deixando o caret onde ele estava.
void deleteSelectedObject(OfficeWordController c) {
  final state = c.activeView.state;
  final selection = state.selection;
  if (selection is! NodeSelection) return;
  final tr = state.tr..delete(selection.from, selection.to);
  final position = selection.from.clamp(0, tr.doc.content.size);
  tr.setSelection(Selection.near(tr.doc.resolve(position)));
  c.dispatch(tr);
}

/// Alterna lista no bloco: parágrafo vira `listItem` do tipo pedido, o
/// mesmo tipo volta a parágrafo, e outro tipo troca o marcador — o
/// comportamento do Word.
void toggleList(OfficeWordController c, String kind) {
  c.syncSelection();
  final block = c.activeView.state.selection.fromRes.parent;
  final isSame = block.type.name == 'listItem' && block.attrs['kind'] == kind;
  final command = isSame
      ? cmd.setBlockType(c.schema.nodes['paragraph']!, (PMNode node) {
          return {
            'word': _wordAttrs(node, clearNumbering: true),
            // Desligar a lista leva junto o formato escolhido na galeria:
            // deixá-lo no parágrafo faria o próximo clique no botão ressuscitar
            // um marcador que o usuário não pediu de novo.
            'style': _styleWithoutListFormat(node),
          };
        })
      : cmd.setBlockType(c.schema.nodes['listItem']!, (PMNode node) {
          return {
            'kind': kind,
            'style': _styleWithoutListMarker(node),
          };
        });
  command(c.activeView.state, c.dispatch);
}

/// Aplica um formato das galerias de Marcadores/Numeração/Vários Níveis.
///
/// [lvlText] e [numFmt] são o vocabulário do `w:lvl` do OOXML — um valor por
/// esquema, ou uma LISTA com um valor por nível (a galeria de vários níveis).
/// São exatamente as chaves que `LayoutComposer._listMarkerOf` desenha e que
/// `docx_codec._numberingForList` grava no `numbering.xml` gerado; escolher
/// "▪" ou "I." muda a tela e o arquivo pelo mesmo dado.
///
/// O `marker` congelado da IMPORTAÇÃO é removido de propósito: ele é o rótulo
/// que o `numbering.xml` de origem produzia e ganharia do formato novo,
/// deixando o usuário clicando numa galeria que não muda nada.
void applyListFormat(
  OfficeWordController c, {
  required String kind,
  required Object lvlText,
  required Object numFmt,
}) {
  c.syncSelection();
  final command = cmd.setBlockType(c.schema.nodes['listItem']!, (PMNode node) {
    final raw = node.attrs['style'];
    final style = <String, dynamic>{
      if (raw is Map) ...raw.cast<String, dynamic>(),
      'lvlText': lvlText,
      'numFmt': numFmt,
    }..remove('marker');
    return {
      'kind': kind,
      // Um parágrafo comum vira item de nível 0; um item que já era lista
      // conserva o nível dele — trocar a galeria não pode desmontar o recuo.
      'indent': node.type.name == 'listItem' ? node.attrs['indent'] : null,
      'style': style,
    };
  });
  command(c.activeView.state, c.dispatch);
}

/// "Nenhum" das galerias: o item volta a ser parágrafo.
void removeList(OfficeWordController c) {
  c.syncSelection();
  final command = cmd.setBlockType(c.schema.nodes['paragraph']!, (PMNode node) {
    return {
      'word': _wordAttrs(node, clearNumbering: true),
      'style': _styleWithoutListFormat(node),
    };
  });
  command(c.activeView.state, c.dispatch);
}

/// "Aumentar/Diminuir Nível da Lista".
///
/// Muda só `attrs['indent']` — o nível OOXML (`w:ilvl`). O recuo visual sai
/// dele (`layout_composer._heuristicStyleOf`, caso `listItem`) e, num esquema
/// de vários níveis, o MARCADOR também: as chaves por nível são resolvidas na
/// composição, então o rótulo acompanha sem a ação reescrever nada.
///
/// Devolve false quando não há item de lista na seleção — o chamador
/// desabilita o comando em vez de oferecer um clique inerte.
bool changeListLevel(OfficeWordController c, int delta) {
  c.syncSelection();
  final state = c.activeView.state;
  final tr = state.tr;
  var changed = false;
  state.doc.nodesBetween(state.selection.from, state.selection.to,
      (node, pos, parent, index) {
    if (!node.isTextblock) return true;
    if (node.type.name != 'listItem') return false;
    final raw = node.attrs['indent'];
    final level = raw is num ? raw.toInt() : int.tryParse('$raw') ?? 0;
    // O Word para em 0 e em 8 (nove níveis); passar disso geraria um `w:ilvl`
    // que o próprio Word recusa.
    final next = (level + delta).clamp(0, 8);
    if (next == level) return false;
    tr.setNodeMarkup(pos, null, {...node.attrs, 'indent': next});
    changed = true;
    return false;
  });
  if (changed) c.dispatch(tr);
  return changed;
}

/// A seleção está sobre um item de lista? (Os comandos de nível e o ✓ das
/// galerias dependem disto.)
bool selectionIsList(OfficeWordController c) {
  if (!c.viewReady) return false;
  return c.activeView.state.selection.fromRes.parent.type.name == 'listItem';
}

/// O `lvlText` gravado no item do cursor, para marcar o ✓ na galeria.
///
/// Devolve o valor CRU (String ou List) — comparar com o esquema da galeria é
/// responsabilidade de quem monta o menu, que é quem conhece os esquemas.
Object? currentListLvlText(OfficeWordController c) =>
    _currentListStyleKey(c, 'lvlText');

/// O `numFmt` gravado no item do cursor. Separa "1." de "I.", que têm o
/// mesmo `lvlText` e só divergem no formato do contador.
Object? currentListNumFmt(OfficeWordController c) =>
    _currentListStyleKey(c, 'numFmt');

Object? _currentListStyleKey(OfficeWordController c, String key) {
  if (!c.viewReady) return null;
  final block = c.activeView.state.selection.fromRes.parent;
  if (block.type.name != 'listItem') return null;
  final style = block.attrs['style'];
  return style is Map ? style[key] : null;
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
      if (node.type.name == 'listItem') 'style': _styleWithoutListFormat(node),
    };
  });
  command(c.activeView.state, c.dispatch);
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

/// O mesmo, mais o formato de galeria (`lvlText`/`numFmt`) — para quando o
/// bloco deixa de ser lista.
dynamic _styleWithoutListFormat(PMNode node) {
  final raw = node.attrs['style'];
  if (raw is! Map) return raw;
  final style = Map<String, dynamic>.from(raw.cast<String, dynamic>())
    ..remove('marker')
    ..remove('lvlText')
    ..remove('numFmt');
  return style.isEmpty ? null : style;
}

/// Ctrl+Enter do Word: divide o parágrafo no cursor e o bloco novo abre a
/// página seguinte. A quebra é um ATRIBUTO do bloco, não um nó — o composer
/// fecha a página ao encontrá-lo, e o PDF sai igual.
void insertPageBreak(OfficeWordController c) {
  c.syncSelection();
  final state = c.activeView.state;
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

/// A quebra de SEÇÃO "Próxima Página" do menu Quebras.
///
/// São duas coisas que só funcionam juntas, e é por isso que elas vivem na
/// mesma ação: a marca `style.sectionBreak` no bloco que TERMINA a seção, e
/// uma entrada nova em `sections` para a seção que começa. O compositor só
/// troca de geometria quando as duas existem (`_endsSection(block) &&
/// sectionIndex + 1 < sections.length`) — gravar só a marca produziria uma
/// quebra invisível.
///
/// A seção nova nasce com a geometria da anterior: a quebra sozinha não muda
/// nada na tela, exatamente como no Word. O que ela habilita é a aba Layout
/// passar a valer só daqui para a frente.
///
/// Devolve `false` quando o cursor não está num bloco de primeiro nível
/// (dentro de uma célula, por exemplo) — o Word também não secciona ali.
bool insertSectionBreak(OfficeWordController c) {
  c.syncSelection();
  final state = c.activeView.state;
  final tr = state.tr;
  final from = state.selection.from;
  tr.split(from);
  final resolved = tr.doc.resolve(tr.mapping.map(from));
  if (resolved.depth != 1) return false;
  final blockPos = resolved.before(resolved.depth);
  final ending = tr.doc.resolve(blockPos).nodeBefore;
  if (ending == null) return false;
  final endingPos = blockPos - ending.nodeSize;
  final style = ending.attrs['style'];
  tr.setNodeMarkup(endingPos, null, {
    ...ending.attrs,
    'style': {
      if (style is Map) ...style.cast<String, dynamic>(),
      'sectionBreak': true,
    },
  });
  c.dispatch(tr);
  c.insertSectionAfterSelection();
  return true;
}

/// As quebras INLINE do menu Quebras (`<w:br w:type="…"/>`).
///
/// Só dois tipos chegam aqui, e os dois têm efeito verificável no layout:
///
/// * `column` — o `PageGraph` é monocoluna, então a próxima coluna
///   disponível é a primeira da página seguinte. É exatamente o que o Word
///   faz num documento de uma coluna, e o compositor já trata o tipo
///   (`layout_composer.dart`, `pageBreak: breakType == 'page' || 'column'`).
/// * `textWrapping` — a quebra de linha simples ("Disposição do Texto" no
///   menu do Word): fecha a linha sem fechar o parágrafo.
///
/// O nó `hardBreak` é o mesmo que a importação cria, então o DOCX exportado
/// leva o `w:br` de volta com o tipo intacto.
void insertHardBreak(OfficeWordController c, String breakType) {
  final type = c.schema.nodes['hardBreak'];
  if (type == null) return;
  c.syncSelection();
  c.dispatch(c.activeView.state.tr
    ..replaceSelectionWith(type.create({'breakType': breakType})));
}

/// "Página em Branco" do Word: duas quebras em volta de um parágrafo vazio,
/// de modo que o conteúdo depois do cursor recomece na página seguinte à
/// nova página em branco.
void insertBlankPage(OfficeWordController c) {
  c.syncSelection();
  final state = c.activeView.state;
  final tr = state.tr;
  final from = state.selection.from;
  tr.split(from);

  Map<String, dynamic> withBreak(PMNode block) {
    final style = block.attrs['style'];
    return {
      ...block.attrs,
      'style': {
        if (style is Map) ...style.cast<String, dynamic>(),
        'pageBreakBefore': true,
      },
    };
  }

  // O bloco que ficou depois do corte abre a página seguinte…
  final afterPos = tr.doc.resolve(tr.mapping.map(from));
  final tailPos = afterPos.before(afterPos.depth);
  final tail = tr.doc.nodeAt(tailPos);
  if (tail == null) return;
  tr.setNodeMarkup(tailPos, null, withBreak(tail));

  // …e um parágrafo vazio, também com quebra, ocupa a página em branco.
  final blank = c.schema.node('paragraph', {
    'style': {'pageBreakBefore': true}
  });
  tr.insert(tailPos, blank);
  c.dispatch(tr);
}

/// Insere o campo `PAGE` (ou `NUMPAGES`) no cursor.
///
/// Um campo do Word não é texto: é uma SEQUÊNCIA de marcadores de run —
/// `begin`, a instrução, `separate` e `end` — e o valor visível é só o
/// resultado em cache. Escrever "1" como texto produziria um cabeçalho que
/// diz "1" em todas as páginas; o compositor resolve PAGE/NUMPAGES por
/// página justamente a partir destes marcadores
/// (`layout_composer._resolveFields`).
///
/// A forma criada aqui é IDÊNTICA à que a importação produz
/// (`docx_codec.appendRunMarker`), inclusive o `officeXml` verbatim de cada
/// marcador — é ele que a exportação devolve ao `w:fldChar`/`w:instrText`.
/// Inventar outra forma daria um campo que o layout resolve mas o Word não
/// reconhece.
void insertPageField(OfficeWordController c, {String command = 'PAGE'}) {
  final type = c.schema.nodes['opaqueInline'];
  if (type == null) return;
  c.syncSelection();
  final state = c.activeView.state;
  final marks = state.selection.empty
      ? (state.storedMarks ?? state.selection.fromRes.marks())
      : state.doc.resolve(state.selection.from + 1).marks();

  PMNode marker(String qname, String xml,
          {String? fieldMarker, String? fieldCommand}) =>
      type.create(
        {
          'insert': {
            'qname': qname,
            'officeXml': xml,
            'runContent': true,
            if (fieldMarker != null) 'fieldMarker': fieldMarker,
            if (fieldCommand != null) 'fieldCommand': fieldCommand,
          }
        },
        null,
        marks,
      );

  final field = Fragment.from([
    marker('w:fldChar', '<w:fldChar w:fldCharType="begin"/>',
        fieldMarker: 'begin'),
    marker('w:instrText',
        '<w:instrText xml:space="preserve"> $command </w:instrText>',
        fieldMarker: 'instruction'),
    marker('w:fldChar', '<w:fldChar w:fldCharType="separate"/>',
        fieldMarker: 'separate', fieldCommand: command),
    marker('w:fldChar', '<w:fldChar w:fldCharType="end"/>', fieldMarker: 'end'),
  ]);

  c.dispatch(state.tr..replaceSelection(Slice(field, 0, 0)));
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

  final from = c.activeView.state.selection.from;
  final tr = c.activeView.state.tr..replaceSelectionWith(table);
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
  setPaperTwips(c, w, h);
}

/// Papel por MEDIDA, preservando a orientação corrente: escolher "Ofício"
/// num documento em paisagem devolve ofício em paisagem, como no Word.
void setPaperTwips(
    OfficeWordController c, int portraitWidth, int portraitHeight) {
  final setup = c.pageSetup;
  final portrait = setup.heightTwips >= setup.widthTwips;
  c.setPageSetup(_copySetup(
    setup,
    width: portrait ? portraitWidth : portraitHeight,
    height: portrait ? portraitHeight : portraitWidth,
  ));
}

void setMargins(OfficeWordController c, String name) {
  final (vertical, horizontal) = switch (name) {
    'Estreita' => (720, 720), // 1,27 cm
    'Larga' => (1418, 2880), // 2,5 cm × 5,08 cm
    _ => (1418, 1418), // Normal: 2,5 cm
  };
  setMarginsTwips(
    c,
    top: vertical,
    bottom: vertical,
    left: horizontal,
    right: horizontal,
  );
}

/// Margens explícitas. As distâncias de cabeçalho/rodapé são PRESERVADAS:
/// elas pertencem à seção importada e não fazem parte da predefinição
/// escolhida — sobrescrevê-las moveria o cabeçalho de todo documento real.
void setMarginsTwips(
  OfficeWordController c, {
  required int top,
  required int bottom,
  required int left,
  required int right,
}) {
  final setup = c.pageSetup;
  c.setPageSetup(PageSetupTwips(
    widthTwips: setup.widthTwips,
    heightTwips: setup.heightTwips,
    marginTopTwips: top,
    marginBottomTwips: bottom,
    marginLeftTwips: left,
    marginRightTwips: right,
    headerDistanceTwips: setup.headerDistanceTwips,
    footerDistanceTwips: setup.footerDistanceTwips,
  ));
}

/// Copia a geometria trocando só o que foi pedido.
///
/// Tudo que a UI NÃO oferece tem de sobreviver: a grade de texto do
/// documento (`w:docGrid`) governa a altura das linhas e vem do arquivo —
/// perdê-la ao trocar o tamanho do papel mudaria a métrica de um documento
/// inteiro sem ninguém pedir.
PageSetupTwips _copySetup(
  PageSetupTwips setup, {
  required int width,
  required int height,
  int? columnCount,
  int? columnSpacingTwips,
}) =>
    PageSetupTwips(
      widthTwips: width,
      heightTwips: height,
      marginTopTwips: setup.marginTopTwips,
      marginRightTwips: setup.marginRightTwips,
      marginBottomTwips: setup.marginBottomTwips,
      marginLeftTwips: setup.marginLeftTwips,
      headerDistanceTwips: setup.headerDistanceTwips,
      footerDistanceTwips: setup.footerDistanceTwips,
      documentGridLinePitchTwips: setup.documentGridLinePitchTwips,
      documentGridType: setup.documentGridType,
      columnCount: columnCount ?? setup.columnCount,
      columnSpacingTwips: columnSpacingTwips ?? setup.columnSpacingTwips,
    );

/// Menu Colunas: quantas colunas a SEÇÃO do cursor tem.
///
/// Vale para a seção, não para o documento — é `setPageSetup` que resolve
/// isso desde o B3. Um documento de coluna única com um anexo em duas
/// colunas é o caso normal disto.
void setColumnCount(OfficeWordController c, int count, {int? spacingTwips}) {
  if (count < 1) return;
  final setup = c.pageSetup;
  c.setPageSetup(_copySetup(
    setup,
    width: setup.widthTwips,
    height: setup.heightTwips,
    columnCount: count,
    columnSpacingTwips: spacingTwips,
  ));
}

// -- estilos do documento (F8) ------------------------------------------------

/// As chaves de `attrs['style']` que um ESTILO governa.
///
/// É a interseção honesta entre o que [OfficeStyleCatalog] sabe resolver e o
/// que `LayoutComposer._resolvedStyleOf` sabe ler. Cor, itálico e sublinhado
/// ficam de fora porque `_BlockStyle` não tem esses campos: gravá-los aqui
/// mudaria o modelo sem mudar um pixel na tela.
const List<String> officeStyleGovernedKeys = [
  'family',
  'sizePt',
  'bold',
  'align',
  'indentTwips',
  'rightIndentTwips',
  'firstLineIndentTwips',
  'spaceBeforeTwips',
  'spaceAfterTwips',
  'lineTwips',
  'lineRule',
];

/// O `w:styleId` do bloco corrente.
///
/// A ordem é a da cascata: o `w:pStyle` DIRETO do parágrafo manda; sem ele
/// vale o id efetivo que a importação resolveu (que já cai no estilo
/// `w:default`); e num documento sem cascata nenhuma — Delta do Quill — o
/// nível do heading é tudo que existe.
String? currentStyleId(OfficeWordController c) {
  if (!c.viewReady) return null;
  final block = c.activeView.state.selection.fromRes.parent;
  return blockStyleId(block) ??
      c.styleCatalog?.defaultParagraphStyle?.id ??
      'Normal';
}

/// O `w:styleId` de um bloco qualquer, sem consultar o catálogo.
String? blockStyleId(PMNode block) {
  final word = block.attrs['word'];
  if (word is Map) {
    final id = word['styleId'];
    if (id is String && id.isNotEmpty) return id;
  }
  final style = block.attrs['style'];
  if (style is Map) {
    final id = style['wordStyleId'];
    if (id is String && id.isNotEmpty) return id;
  }
  final level = block.attrs['level'];
  if (block.type.name == 'heading' && level is int) return 'Heading$level';
  return null;
}

/// Aplica um estilo DO CATÁLOGO na seleção.
///
/// Três coisas viajam juntas e nenhuma delas é opcional:
/// * `word.styleId`, que é o que a exportação grava como `w:pStyle`;
/// * o mapa resolvido em `attrs['style']`, que é o que o compositor desenha
///   (sem ele o parágrafo continuaria com a apresentação do estilo antigo,
///   porque a cascata só é resolvida na IMPORTAÇÃO);
/// * as marcas de fonte/tamanho/negrito dos runs, pela regra de
///   [_retargetRunMarks] — um DOCX importado já carrega essas marcas
///   ACHATADAS do estilo antigo, e no compositor elas ganham do bloco.
void applyCatalogStyle(OfficeWordController c, String styleId) {
  final catalog = c.styleCatalog;
  final definition = catalog?[styleId];
  if (catalog == null || definition == null) return;
  c.syncSelection();
  final state = c.activeView.state;
  final tr = state.tr;
  final heading = officeHeadingLevelOfStyle(styleId, definition);
  final headingType = c.schema.nodes['heading'];
  final paragraphType = c.schema.nodes['paragraph'];

  var changed = false;
  state.doc.nodesBetween(state.selection.from, state.selection.to,
      (node, pos, parent, index) {
    if (!node.isTextblock) return true;
    final previous = catalog[blockStyleId(node)]?.formatting;
    // Um estilo de título transforma o bloco em `heading` (é o que dá o
    // outline e o que a exportação usa); qualquer outro devolve um heading
    // ao corpo do texto. `listItem` fica como está: aplicar "Nível 01" a um
    // item de lista não pode destruir a lista.
    final target = heading != null
        ? headingType
        : (node.type.name == 'heading' ? paragraphType : null);
    final word = <String, dynamic>{
      if (node.attrs['word'] is Map)
        ...(node.attrs['word'] as Map).cast<String, dynamic>(),
      'styleId': styleId,
    };
    tr.setNodeMarkup(pos, target == node.type ? null : target, {
      ...node.attrs,
      if (heading != null) 'level': heading,
      'word': word,
      'style': mergedCatalogBlockStyle(
        node.attrs['style'],
        previous: previous,
        next: definition.formatting,
        styleId: styleId,
      ),
    });
    _retargetRunMarks(c, tr, node, pos, previous, definition.formatting);
    changed = true;
    return false;
  });
  if (changed) c.dispatch(tr);
}

/// Grava a definição de um estilo e RE-RESOLVE os blocos que o usam.
///
/// A re-resolução é obrigatória porque a cascata do Word só roda na
/// importação: `attrs['style']` é o resultado achatado, e sem reescrevê-lo
/// "Modificar estilo" mudaria o `styles.xml` exportado sem mudar a tela.
///
/// Age só no CORPO. Cabeçalhos e rodapés são raízes próprias com sessão de
/// edição própria (F6); re-resolvê-los daqui exigiria um caminho de
/// transação por região que ainda não existe.
void applyStyleDefinition(
    OfficeWordController c, OfficeStyleDefinition definition) {
  final catalog = c.styleCatalog;
  if (catalog == null) return;
  final previous = catalog[definition.id]?.formatting;
  catalog.upsert(definition);

  final state = c.view.state;
  final tr = state.tr;
  var changed = false;
  state.doc.nodesBetween(0, state.doc.content.size, (node, pos, parent, index) {
    if (!node.isTextblock) return true;
    if (blockStyleId(node) != definition.id) return false;
    tr.setNodeMarkup(pos, null, {
      ...node.attrs,
      'style': mergedCatalogBlockStyle(
        node.attrs['style'],
        previous: previous,
        next: definition.formatting,
        styleId: definition.id,
      ),
    });
    _retargetRunMarks(c, tr, node, pos, previous, definition.formatting);
    changed = true;
    return false;
  });
  if (changed) {
    c.view.dispatch(tr);
  } else {
    // Nenhum parágrafo usa o estilo ainda (um estilo recém-criado): o
    // documento não muda, mas o catálogo e o `dirty` mudaram.
    c.styleCatalogChanged();
  }
}

/// "Atualizar para Corresponder à Seleção": o estilo passa a valer o que o
/// parágrafo do cursor mostra hoje.
void updateStyleToMatchSelection(OfficeWordController c, String styleId) {
  final catalog = c.styleCatalog;
  final definition = catalog?[styleId];
  if (catalog == null || definition == null) return;
  c.syncSelection();
  final formatting = styleFormattingOfSelection(c);
  applyStyleDefinition(
      c,
      definition.copyWith(
        formatting: formatting,
        preview: officeStylePreviewOf(formatting, definition.preview),
      ));
}

void renameCatalogStyle(OfficeWordController c, String styleId, String name) {
  final catalog = c.styleCatalog;
  if (catalog == null) return;
  catalog.rename(styleId, name);
  c.styleCatalogChanged();
}

/// "Remover da Galeria": tira o `w:qFormat`, nunca o estilo — os parágrafos
/// que o referenciam continuam válidos.
void removeStyleFromGallery(OfficeWordController c, String styleId) {
  final catalog = c.styleCatalog;
  if (catalog == null) return;
  catalog.setInGallery(styleId, false);
  c.styleCatalogChanged();
}

/// A formatação EFETIVA do bloco do cursor, no vocabulário do catálogo.
OfficeStyleFormatting styleFormattingOfSelection(OfficeWordController c) {
  final state = c.activeView.state;
  final selection = state.selection;
  final block = selection.fromRes.parent;
  final raw = block.attrs['style'];
  final style = raw is Map ? raw : const {};
  int? twips(String key) {
    final value = style[key];
    return value is num ? value.toInt() : null;
  }

  final size = effectiveInlineValue(c, 'size');
  final boldType = c.schema.marks['bold'];
  final marks = selection.empty
      ? (state.storedMarks ?? selection.fromRes.marks())
      : state.doc.resolve(selection.from + 1).marks();
  final bold = boldType != null && marks.any((mark) => mark.type == boldType);

  return OfficeStyleFormatting(
    family: effectiveInlineValue(c, 'font'),
    sizePt: size == null ? null : double.tryParse(size),
    bold: bold || style['bold'] == true,
    align: (style['align'] ?? block.attrs['align']) as String?,
    indentTwips: twips('indentTwips'),
    rightIndentTwips: twips('rightIndentTwips'),
    firstLineIndentTwips: twips('firstLineIndentTwips'),
    spaceBeforeTwips: twips('spaceBeforeTwips'),
    spaceAfterTwips: twips('spaceAfterTwips'),
    lineTwips: twips('lineTwips'),
    lineRule: style['lineRule'] as String?,
  );
}

/// O preview de um estilo cuja FORMATAÇÃO mudou: o que o editor governa vem
/// da formatação nova, o que ele não governa (itálico, sublinhado, cor)
/// continua descrevendo a definição original.
OfficeStylePreview officeStylePreviewOf(
        OfficeStyleFormatting formatting, OfficeStylePreview base) =>
    OfficeStylePreview(
      family: formatting.family ?? base.family,
      sizePt: formatting.sizePt ?? base.sizePt,
      bold: formatting.bold ?? base.bold,
      italic: base.italic,
      underline: base.underline,
      color: base.color,
      align: formatting.align ?? base.align,
    );

/// `Heading1`, `Ttulo2`, `heading 3`… — o nível vem do dígito no fim do id,
/// como no importador; o nome do estilo muda por idioma, o padrão do id não.
int? officeHeadingLevelOfStyle(String styleId, OfficeStyleDefinition? style) {
  final pattern = RegExp('heading|titulo|ttulo', caseSensitive: false);
  final basedOn = style?.basedOn;
  final source = pattern.hasMatch(styleId)
      ? styleId
      : (basedOn != null && pattern.hasMatch(basedOn) ? basedOn : null);
  if (source == null) return null;
  final digits = RegExp(r'(\d+)$').firstMatch(source)?.group(1);
  final level = digits == null ? null : int.tryParse(digits);
  return level != null && level >= 1 && level <= 6 ? level : null;
}

/// Funde o mapa de `attrs['style']` do bloco com o do estilo NOVO.
///
/// A regra decide quem vence chave a chave: um valor que ainda é o do estilo
/// ANTIGO (ou que nunca existiu) veio da cascata e é substituído; um valor
/// diferente é formatação DIRETA do usuário e sobrevive — que é exatamente o
/// que o Word faz ao modificar um estilo. Sem essa distinção, "Modificar"
/// apagaria em silêncio todo recuo e espaçamento ajustado à mão.
Map<String, dynamic> mergedCatalogBlockStyle(
  Object? existing, {
  required OfficeStyleFormatting? previous,
  required OfficeStyleFormatting next,
  required String styleId,
}) {
  final result = <String, dynamic>{
    if (existing is Map) ...existing.cast<String, dynamic>(),
  };
  final before = previous?.toBlockStyle() ?? const <String, dynamic>{};
  final after = next.toBlockStyle();
  for (final key in officeStyleGovernedKeys) {
    final current = result[key];
    if (current != null && !_sameStyleValue(current, before[key])) continue;
    if (after.containsKey(key)) {
      result[key] = after[key];
    } else {
      result.remove(key);
    }
  }
  result['wordStyleId'] = styleId;
  return result;
}

bool _sameStyleValue(Object? a, Object? b) {
  if (a is num && b is num) return a.toDouble() == b.toDouble();
  return a == b;
}

/// Reescreve as marcas `font`/`size`/`bold` dos runs de [block] quando o
/// estilo dele muda.
///
/// Por que isto é necessário: a importação ACHATA a cascata em marcas de
/// run, e no compositor a marca ganha do bloco
/// (`layout_composer._styleOfText`). Sem tocar nas marcas, mudar a fonte de
/// um estilo não mudaria uma letra de um DOCX importado.
///
/// Por que só as marcas que COINCIDEM com o estilo antigo: é o único sinal
/// disponível para separar "isto veio do estilo" de "isto o usuário pôs em
/// negrito à mão". Um run que já divergia do estilo é formatação direta e
/// fica intacto.
void _retargetRunMarks(
  OfficeWordController c,
  Transaction tr,
  PMNode block,
  int blockPos,
  OfficeStyleFormatting? previous,
  OfficeStyleFormatting next,
) {
  final fontType = c.schema.marks['font'];
  final sizeType = c.schema.marks['size'];
  final boldType = c.schema.marks['bold'];
  final familyChanged = previous?.family != next.family;
  final sizeChanged = previous?.sizePt != next.sizePt;
  final boldChanged = (previous?.bold ?? false) != (next.bold ?? false);
  if (!familyChanged && !sizeChanged && !boldChanged) return;

  var offset = 0;
  for (var i = 0; i < block.childCount; i++) {
    final child = block.child(i);
    final from = blockPos + 1 + offset;
    final to = from + child.nodeSize;
    offset += child.nodeSize;
    if (!child.isText) continue;

    String? valueOf(MarkType type) {
      for (final mark in child.marks) {
        if (mark.type == type) return '${mark.attrs['value']}';
      }
      return null;
    }

    if (familyChanged && fontType != null) {
      if (valueOf(fontType) == previous?.family) {
        tr.removeMark(from, to, fontType);
        if (next.family != null) {
          tr.addMark(from, to, fontType.create({'value': next.family}));
        }
      }
    }
    if (sizeChanged && sizeType != null) {
      if (_sizePtOf(valueOf(sizeType)) == previous?.sizePt) {
        tr.removeMark(from, to, sizeType);
        if (next.sizePt != null) {
          tr.addMark(from, to,
              sizeType.create({'value': officeSizeMarkValue(next.sizePt!)}));
        }
      }
    }
    if (boldChanged && boldType != null) {
      final current = child.marks.any((mark) => mark.type == boldType);
      if (current == (previous?.bold ?? false)) {
        if (next.bold == true) {
          tr.addMark(from, to, boldType.create());
        } else {
          tr.removeMark(from, to, boldType);
        }
      }
    }
  }
}

double? _sizePtOf(String? raw) =>
    raw == null ? null : double.tryParse(raw.replaceAll('pt', '').trim());

/// `14.0` → `14pt`, `10.5` → `10.5pt` — a mesma forma que a importação grava.
String officeSizeMarkValue(double points) =>
    points == points.roundToDouble() ? '${points.round()}pt' : '${points}pt';
