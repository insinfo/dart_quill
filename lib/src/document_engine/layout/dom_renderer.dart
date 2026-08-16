/// DOMRenderer — projeta um [PageGraph] no DOM (Fase 2 / lado editor do
/// gate da Fase 5).
///
/// O par do [PageGraphPdfRenderer]: consome EXATAMENTE o mesmo grafo e,
/// como ele, NÃO decide layout — transcreve. É o que faz a linha da página
/// 18 do editor ser a mesma linha da página 18 do PDF.
///
/// Três regras da arquitetura materializadas aqui:
///
/// * o DOM é PROJEÇÃO, nunca fonte de verdade — nada é lido de volta dele
///   para o modelo; a reconciliação de entrada (Fase 2 completa) entra por
///   `beforeinput`/MutationObserver sobre este mesmo mapeamento;
/// * PIXEL só existe nesta borda: o grafo é todo em twips e a conversão usa
///   uma escala explícita (`pxPerPt`, padrão 96/72);
/// * seletores próprios `dq-office-*` — o CSS do modo Office nunca toca
///   `.ql-editor`, temas ou a aplicação consumidora.
///
/// Cada elemento carrega as âncoras do [PositionMap] (`data-doc-pos`,
/// `data-node-id`, `data-char-start`/`data-char-end`), que são a ponte
/// posição-do-modelo ↔ posição-no-DOM usada por seleção, hit-testing e
/// scroll-to-selection.
library;

import '../../platform/dom.dart';
import '../../office/document/fonts/font_registry.dart';
import 'page_graph.dart';

/// Prefixo de TODAS as classes emitidas (isolamento de CSS).
const String officeCssPrefix = 'dq-office';

/// Janela de páginas montadas (virtualização). `null` monta tudo.
class PageWindow {
  const PageWindow({
    required this.firstPage,
    required this.lastPage,
    this.pinned = const {},
  });

  final int firstPage;
  final int lastPage;

  /// Páginas montadas FORA da faixa contígua — a seleção, a composição IME,
  /// uma operação em curso.
  ///
  /// São fixadas, não esticam a faixa: um caret na página 0 com o viewport
  /// na 150 manteria 151 páginas montadas se o intervalo fosse esticado, e
  /// aí a virtualização não serviria para nada.
  final Set<int> pinned;

  bool contains(int pageIndex) =>
      (pageIndex >= firstPage && pageIndex <= lastPage) ||
      pinned.contains(pageIndex);

  /// Igualdade ESTRUTURAL: a view compara a janela nova com a montada para
  /// não reprojetar a cada pixel de scroll.
  @override
  bool operator ==(Object other) =>
      other is PageWindow &&
      other.firstPage == firstPage &&
      other.lastPage == lastPage &&
      other.pinned.length == pinned.length &&
      other.pinned.containsAll(pinned);

  @override
  int get hashCode =>
      Object.hash(firstPage, lastPage, Object.hashAllUnordered(pinned));

  @override
  String toString() => 'PageWindow($firstPage..$lastPage, pinned=$pinned)';
}

class PageGraphDomRenderer {
  PageGraphDomRenderer({
    required this.document,
    this.pxPerPt = 96 / 72,
    this.editable = false,
    this.spellcheck = false,
    this.pageGapPx = 0,
    this.scrollTopInsetPx = 0,
  });

  final DomDocument document;

  /// Escala explícita twips→px na borda da view (nunca implícita).
  final double pxPerPt;

  /// Marca o content box das páginas como `contenteditable`. A entrada em si
  /// (beforeinput/IME/seleção) é a Fase 2 completa; aqui a superfície já
  /// nasce com o atributo certo para o hardening começar.
  ///
  /// NÃO é final: o modo cabeçalho/rodapé (F6) suspende a edição do CORPO
  /// enquanto a região é editada. Desligar o atributo é o que impede o caret
  /// de voltar ao texto por teclado — só esmaecer com CSS deixaria a
  /// digitação cair no lugar errado. Quem troca o valor precisa reprojetar
  /// ([OfficeEditorView.reproject]); o grafo não muda.
  bool editable;

  /// Corretor ortográfico NATIVO do browser na superfície editável (F10).
  ///
  /// DESLIGADO por padrão, e a razão não é preguiça. O sublinhado é pintado
  /// pelo browser, não escrito no DOM, então ele não fere a regra de ouro —
  /// mas aceitar uma sugestão do menu do browser chega como `beforeinput`
  /// com `inputType: insertReplacementText`, e esse evento **não é
  /// cancelável em todos os browsers** (o WebKit o entrega sem
  /// cancelabilidade). Onde não for, o browser reescreve a projeção por
  /// baixo do modelo — a corrupção silenciosa que o `editor_view` existe
  /// para impedir.
  ///
  /// Onde ELE É cancelável (Chromium e Gecko) o caminho está fechado: a view
  /// converte `insertReplacementText` numa transação sobre o intervalo que o
  /// browser aponta, então a correção entra pelo modelo como qualquer outra
  /// edição. Por isso a opção existe e é do hospedeiro: quem sabe em que
  /// browser o produto roda é ele.
  final bool spellcheck;

  /// Geometria externa da projeção, usada pela virtualização para mapear
  /// `scrollTop` em página sem medir o DOM a cada evento.
  final double pageGapPx;
  final double scrollTopInsetPx;

  double _px(int twips) => twips / 20.0 * pxPerPt;

  String _n(double value) {
    final rounded = (value * 100).round() / 100;
    return rounded == rounded.roundToDouble()
        ? rounded.toStringAsFixed(0)
        : rounded.toString();
  }

  /// Renderiza [graph] dentro de [host], substituindo o conteúdo anterior.
  ///
  /// [window] limita as páginas MONTADAS; as demais viram placeholders de
  /// altura exata, para o scroll não pular (a virtualização da Fase 7 troca
  /// a janela sem mexer no grafo).
  void render(PageGraph graph, DomElement host, {PageWindow? window}) {
    while (host.firstChild != null) {
      host.firstChild!.remove();
    }
    host.classes.add('$officeCssPrefix-root');
    for (final page in graph.pages) {
      host.append(window == null || window.contains(page.index)
          ? _renderPage(page)
          : _renderPlaceholder(page));
    }
  }

  DomElement _renderPlaceholder(PageLayout page) {
    final element = document.createElement('div');
    element.classes.add('$officeCssPrefix-page-placeholder');
    element.setAttribute('data-page', '${page.index}');
    element.setAttribute('aria-hidden', 'true');
    element.setAttribute(
        'style',
        'width:${_n(_px(page.setup.widthTwips))}px;'
            'height:${_n(_px(page.setup.heightTwips))}px;');
    return element;
  }

  DomElement _renderPage(PageLayout page) {
    final setup = page.setup;
    final pageElement = document.createElement('div');
    pageElement.classes.add('$officeCssPrefix-page');
    pageElement.setAttribute('data-page', '${page.index}');
    pageElement.setAttribute(
        'style',
        'position:relative;'
            'width:${_n(_px(setup.widthTwips))}px;'
            'height:${_n(_px(setup.heightTwips))}px;'
            // Cor da página (`w:background`): é a FOLHA que muda de cor, não
            // o conteúdo; o CSS da folha define o branco padrão e este
            // inline o sobrescreve só quando a seção declara uma cor.
            '${setup.pageColor == null ? '' : 'background:${setup.pageColor};'}');

    // Marca-d'água e borda de página são camadas INERTES: elas pertencem à
    // folha, não ao documento. Sem `contenteditable=false` +
    // `pointer-events:none` o caret cairia dentro da marca-d'água (que é
    // texto de verdade no DOM) e o usuário a apagaria sem entender o quê.
    final watermark = _watermarkLayer(setup);
    if (watermark != null) pageElement.append(watermark);

    final content = document.createElement('div');
    content.classes.add('$officeCssPrefix-page-content');
    if (editable) {
      content.setAttribute('contenteditable', 'true');
      // O atributo é escrito nos DOIS casos (não só quando falso): num
      // contenteditable o padrão do browser é herdar `spellcheck` do
      // ancestral, e deixar de escrever deixaria a decisão com a página
      // hospedeira em vez de com o editor.
      content.setAttribute('spellcheck', spellcheck ? 'true' : 'false');
    }
    content.setAttribute(
        'style',
        'position:absolute;'
            'left:${_n(_px(setup.marginLeftTwips))}px;'
            'top:${_n(_px(setup.marginTopTwips))}px;'
            'width:${_n(_px(setup.contentWidthTwips))}px;'
            'height:${_n(_px(setup.contentHeightTwips))}px;');
    // Cabeçalho e rodapé ficam FORA do content box, nos boxes de margem, e
    // são explicitamente NÃO editáveis: a mesma região aparece em todas as
    // páginas, e deixar editar aqui criaria N edições concorrentes do mesmo
    // nó. A edição acontece numa região autoritativa própria.
    if (page.header.isNotEmpty) {
      pageElement
          .append(_renderRegion(page.header, page.setup, isHeader: true));
    }
    if (page.footer.isNotEmpty) {
      pageElement
          .append(_renderRegion(page.footer, page.setup, isHeader: false));
    }

    // O corpo vem depois na ordem de pintura. Imagens opacas do timbre podem
    // invadir a margem do texto sem apagar seus glifos; objetos realmente
    // flutuantes (como textBox) mantêm o z-index explícito e continuam acima.
    pageElement.append(content);

    for (final fragment in page.fragments) {
      // O x vem do ÍNDICE da coluna resolvido pela mesma geometria que o
      // compositor usou. Dois fragmentos de colunas diferentes têm o mesmo
      // `yTwips` — é o deslocamento horizontal que os põe lado a lado.
      final columnLeft = setup.columnLeftTwips(fragment.columnIndex);
      switch (fragment) {
        case BlockFragment():
          content.append(_renderBlock(fragment,
              availableTwips: setup.columnWidthTwips,
              withMarker: true,
              leftOffsetTwips: columnLeft));
        case TableFragment():
          content.append(_renderTable(fragment, leftOffsetTwips: columnLeft));
      }
    }

    // A borda da página vem por ÚLTIMO: no Word ela é desenhada por cima de
    // tudo (um texto que invada a margem passa por baixo dela, não a apaga).
    final border = _pageBorderLayer(setup);
    if (border != null) pageElement.append(border);
    return pageElement;
  }

  /// A camada da marca-d'água: texto inerte, atrás do conteúdo.
  DomElement? _watermarkLayer(PageSetupTwips setup) {
    final watermark = setup.watermark;
    if (watermark == null || watermark.isEmpty) return null;
    final element = document.createElement('div');
    element.classes.add('$officeCssPrefix-watermark');
    element.setAttribute('contenteditable', 'false');
    element.setAttribute('aria-hidden', 'true');
    // Fora do mapa de posições: `data-model-length=0` declara que esta
    // camada não consome NENHUMA posição do documento.
    element.setAttribute('data-model-length', '0');
    element.setAttribute(
        'style',
        'position:absolute;inset:0;z-index:0;'
            'display:flex;align-items:center;justify-content:center;'
            'pointer-events:none;user-select:none;overflow:hidden;'
            'font-family:${_cssFontFamily(watermark.fontFamily)};'
            'font-size:${_n(watermark.sizePt * pxPerPt)}px;'
            'line-height:1.1;white-space:pre;'
            'color:${watermark.color};'
            '${watermark.diagonal ? 'transform:rotate(-45deg);' : ''}');
    element.appendText(watermark.text);
    return element;
  }

  /// A moldura de página (`w:pgBorders`), inerte e recuada da borda do papel.
  DomElement? _pageBorderLayer(PageSetupTwips setup) {
    final borders = setup.pageBorders;
    if (borders == null || !borders.hasVisibleSide) return null;
    final element = document.createElement('div');
    element.classes.add('$officeCssPrefix-pageborder');
    element.setAttribute('contenteditable', 'false');
    element.setAttribute('aria-hidden', 'true');
    element.setAttribute('data-model-length', '0');
    // `w:space` é medido em PONTOS a partir da borda do papel — a mesma
    // unidade que o diálogo do Word mostra.
    final inset = setup.pageBorderSpacePt * pxPerPt;
    element.setAttribute(
        'style',
        'position:absolute;z-index:3;box-sizing:border-box;'
            'pointer-events:none;'
            'left:${_n(inset)}px;top:${_n(inset)}px;'
            'right:${_n(inset)}px;bottom:${_n(inset)}px;'
            'border-top:${_borderCssValue(borders.top)};'
            'border-right:${_borderCssValue(borders.right)};'
            'border-bottom:${_borderCssValue(borders.bottom)};'
            'border-left:${_borderCssValue(borders.left)};');
    return element;
  }

  DomElement _renderRegion(
    List<BlockFragment> fragments,
    PageSetupTwips setup, {
    required bool isHeader,
  }) {
    final element = document.createElement('div');
    element.classes.add('$officeCssPrefix-${isHeader ? 'header' : 'footer'}');
    element.setAttribute('contenteditable', 'false');
    // Projeção repetida: fora da árvore de acessibilidade, como o marcador
    // de lista. Um leitor de tela não deve ouvir o timbre 200 vezes.
    element.setAttribute('aria-hidden', 'true');

    final height = fragments.fold<int>(0, (sum, f) => sum + f.heightTwips);
    final top = isHeader
        ? setup.headerDistanceTwips
        : setup.heightTwips - setup.footerDistanceTwips - height;
    element.setAttribute(
        'style',
        'position:absolute;'
            'left:${_n(_px(setup.marginLeftTwips))}px;'
            'top:${_n(_px(top))}px;'
            'width:${_n(_px(setup.contentWidthTwips))}px;'
            'height:${_n(_px(height))}px;');

    for (final fragment in fragments) {
      element.append(_renderBlock(fragment,
          availableTwips: setup.contentWidthTwips, withMarker: false));
    }
    return element;
  }

  DomElement _renderTable(TableFragment fragment, {int leftOffsetTwips = 0}) {
    final element = document.createElement('div');
    element.classes.add('$officeCssPrefix-table');
    element.setAttribute('role', 'table');
    _nodeAnchor(
        element, fragment.docPos, fragment.nodeId ?? fragment.sourceTableId);
    _docRange(element, fragment.docFrom, fragment.docTo);
    _sourceIdentity(element, tableId: fragment.sourceTableId);
    var tableWidth = 0;
    for (final row in fragment.rows) {
      for (final cell in row.cells) {
        final right = cell.xTwips + cell.widthTwips;
        if (right > tableWidth) tableWidth = right;
      }
    }
    element.setAttribute(
        'style',
        'position:absolute;'
            'left:${_n(_px(leftOffsetTwips))}px;'
            'top:${_n(_px(fragment.yTwips))}px;'
            'width:${_n(_px(tableWidth))}px;'
            'height:${_n(_px(fragment.heightTwips))}px;');

    var y = 0;
    for (final row in fragment.rows) {
      final rowElement = document.createElement('div');
      rowElement.classes.add('$officeCssPrefix-table-row');
      rowElement.setAttribute('role', 'row');
      rowElement.setAttribute('data-height-twips', '${row.heightTwips}');
      _docRange(rowElement, row.docFrom, row.docTo);
      _sourceIdentity(
        rowElement,
        tableId: row.sourceTableId,
        rowId: row.sourceRowId,
        rowIndex: row.sourceRowIndex,
      );
      if (!row.isRepeatedHeader) {
        _nodeAnchor(rowElement, row.docPos, row.nodeId ?? row.sourceRowId);
      } else {
        rowElement.classes.add('$officeCssPrefix-table-row-repeated-header');
        rowElement.setAttribute('data-repeated-header', 'true');
        rowElement.setAttribute('contenteditable', 'false');
        rowElement.setAttribute('aria-hidden', 'true');
      }
      if (row.heightRule != null) {
        rowElement.setAttribute('data-height-rule', row.heightRule!);
      }
      if (row.cantSplit) rowElement.setAttribute('data-cant-split', 'true');
      if (row.repeatHeader) {
        rowElement.setAttribute('data-repeat-header', 'true');
      }
      if (row.continuesFromPreviousPage) {
        rowElement.setAttribute('data-continues-from', 'true');
      }
      if (row.continuesOnNextPage) {
        rowElement.setAttribute('data-continues-on', 'true');
      }
      if (row.gridBefore > 0) {
        rowElement.setAttribute('data-grid-before', '${row.gridBefore}');
      }
      if (row.gridAfter > 0) {
        rowElement.setAttribute('data-grid-after', '${row.gridAfter}');
      }
      rowElement.setAttribute(
          'style',
          'position:absolute;left:0;'
              'top:${_n(_px(y))}px;'
              'height:${_n(_px(row.heightTwips))}px;');
      for (final cell in row.cells) {
        final cellElement = document.createElement('div');
        cellElement.classes.add('$officeCssPrefix-table-cell');
        cellElement.setAttribute('role', 'cell');
        _docRange(cellElement, cell.docFrom, cell.docTo);
        _sourceIdentity(
          cellElement,
          tableId: cell.sourceTableId,
          rowId: cell.sourceRowId,
          cellId: cell.sourceCellId,
          rowIndex: cell.sourceRowIndex,
          cellIndex: cell.sourceCellIndex,
        );
        if (!row.isRepeatedHeader) {
          _nodeAnchor(
              cellElement, cell.docPos, cell.nodeId ?? cell.sourceCellId);
        }
        if (cell.columnSpan > 1) {
          cellElement.setAttribute('colspan', '${cell.columnSpan}');
          cellElement.setAttribute('aria-colspan', '${cell.columnSpan}');
        }
        if (cell.rowSpan > 1) {
          cellElement.setAttribute('rowspan', '${cell.rowSpan}');
          cellElement.setAttribute('aria-rowspan', '${cell.rowSpan}');
        }
        cellElement.setAttribute('data-column', '${cell.columnIndex}');
        cellElement.setAttribute(
            'data-vertical-align', cell.verticalAlign.name);
        cellElement.setAttribute(
            'data-margin-top-twips', '${cell.marginTopTwips}');
        cellElement.setAttribute(
            'data-margin-right-twips', '${cell.marginRightTwips}');
        cellElement.setAttribute(
            'data-margin-bottom-twips', '${cell.marginBottomTwips}');
        cellElement.setAttribute(
            'data-margin-left-twips', '${cell.marginLeftTwips}');
        if (cell.isMergeContinuation) {
          cellElement.classes
              .add('$officeCssPrefix-table-cell-merge-continuation');
          cellElement.setAttribute('data-vmerge', 'continue');
          cellElement.setAttribute('aria-hidden', 'true');
          cellElement.setAttribute('contenteditable', 'false');
          cellElement.setAttribute('style', 'display:none;');
          rowElement.append(cellElement);
          continue;
        }
        final background = cell.backgroundColor == null
            ? ''
            : 'background-color:${cell.backgroundColor};';
        cellElement.setAttribute(
            'style',
            'position:absolute;'
                'left:${_n(_px(cell.xTwips))}px;top:0;'
                'width:${_n(_px(cell.widthTwips))}px;'
                'height:${_n(_px(cell.heightTwips))}px;'
                '$background'
                '${_bordersCss(cell.borders)}'
                'box-sizing:border-box;');
        for (final block in cell.blocks) {
          cellElement.append(_renderBlock(block,
              availableTwips: cell.widthTwips,
              withMarker: true,
              topOffsetTwips: cell.contentOffsetTwips,
              projectedCopy: row.isRepeatedHeader));
        }
        rowElement.append(cellElement);
      }
      element.append(rowElement);
      y += row.heightTwips;
    }
    return element;
  }

  DomElement _renderBlock(
    BlockFragment fragment, {
    required int availableTwips,
    required bool withMarker,
    int topOffsetTwips = 0,
    int leftOffsetTwips = 0,
    bool projectedCopy = false,
  }) {
    final element = document.createElement('div');
    element.classes.add('$officeCssPrefix-block');
    element.classes.add('$officeCssPrefix-block-${fragment.kind}');
    if (!projectedCopy) _anchor(element, fragment);
    if (fragment.continuesFromPreviousPage) {
      element.setAttribute('data-continues-from', 'true');
    }
    if (fragment.continuesOnNextPage) {
      element.setAttribute('data-continues-on', 'true');
    }
    element.setAttribute(
        'style',
        'position:absolute;'
            'left:${_n(_px(leftOffsetTwips + fragment.indentTwips))}px;'
            'top:${_n(_px(fragment.yTwips + topOffsetTwips))}px;'
            'width:${_n(_px(availableTwips - fragment.indentTwips))}px;'
            'height:${_n(_px(fragment.heightTwips))}px;');

    // Lossless OOXML range markers (`bookmarkEnd`, comment/permission
    // ranges, proof metadata) are represented by zero-height opaque block
    // fragments.  They retain their source anchor for round-trip/mapping,
    // but must not expose the generic empty-paragraph caret target.
    if (fragment.kind == 'opaque' && fragment.heightTwips == 0) {
      element.setAttribute('contenteditable', 'false');
      element.setAttribute('aria-hidden', 'true');
      element.setAttribute(
          'style', '${element.getAttribute('style')}display:none;');
      return element;
    }

    final decoration = _blockDecoration(fragment);
    if (decoration != null) element.append(decoration);

    if (withMarker && fragment.marker != null) {
      final marker = document.createElement('span');
      marker.classes.add('$officeCssPrefix-marker');
      // Marcador é PROJEÇÃO do modelo (o rótulo vem do layout, nunca é
      // texto do documento): fora da edição e da árvore de acessibilidade.
      marker.setAttribute('contenteditable', 'false');
      marker.setAttribute('aria-hidden', 'true');
      final firstLine = fragment.lines.isEmpty ? null : fragment.lines.first;
      final markerStyle = fragment.markerStyle ??
          (firstLine == null || firstLine.segments.isEmpty
              ? null
              : firstLine.segments.first.style) ??
          const ResolvedRunStyle(family: 'Arial', sizePt: 12);
      final markerLineHeight = firstLine?.heightTwips ??
          (fragment.heightTwips -
              fragment.spaceBeforeTwips -
              fragment.spaceAfterTwips);
      marker.setAttribute(
          'style',
          'position:absolute;'
              'left:${_n(_px(fragment.markerPositionTwips - fragment.indentTwips))}px;'
              'top:${_n(_px(fragment.spaceBeforeTwips))}px;'
              'height:${_n(_px(markerLineHeight))}px;'
              'line-height:${_n(_px(markerLineHeight))}px;'
              'font-family:${_cssFontFamily(markerStyle.family)};'
              'font-size:${_n(markerStyle.sizePt * pxPerPt)}px;'
              'font-weight:${markerStyle.bold ? 'bold' : 'normal'};'
              'color:${markerStyle.color};white-space:pre;');
      marker.appendText(fragment.marker!);
      element.append(marker);
    }

    // Bloco VAZIO ainda precisa de uma linha na projeção: é onde o caret
    // pousa num parágrafo em branco — o estado inicial de um documento novo
    // e o resultado de todo Enter. Sem este alvo, o mapa de posições não
    // tem âncora e o editor não consegue nem começar a digitar.
    if (fragment.lines.isEmpty) {
      final blankHeight = fragment.heightTwips -
          fragment.spaceBeforeTwips -
          fragment.spaceAfterTwips;
      final empty = document.createElement('div');
      empty.classes.add('$officeCssPrefix-line');
      empty.classes.add('$officeCssPrefix-line-empty');
      empty.setAttribute('data-char-start', '0');
      empty.setAttribute('data-char-end', '0');
      empty.setAttribute(
          'style',
          'position:absolute;left:0;right:0;'
              'top:${_n(_px(fragment.spaceBeforeTwips))}px;'
              'height:${_n(_px(blankHeight))}px;'
              'line-height:${_n(_px(blankHeight))}px;'
              'white-space:pre;');
      element.append(empty);
      return element;
    }

    var y = fragment.spaceBeforeTwips;
    for (final line in fragment.lines) {
      final lineElement = document.createElement('div');
      lineElement.classes.add('$officeCssPrefix-line');
      lineElement.setAttribute('data-char-start', '${line.charStart}');
      lineElement.setAttribute('data-char-end', '${line.charEnd}');
      lineElement.setAttribute(
          'style',
          'position:absolute;'
              // A exclusão do objeto flutuante encurta a caixa da LINHA, não
              // o recuo do parágrafo: some sozinha quando o objeto sai da
              // faixa vertical dela.
              'left:${_n(_px(line.indentTwips + line.wrapLeftInsetTwips))}px;'
              'right:${_n(_px(fragment.rightIndentTwips + line.wrapRightInsetTwips))}px;'
              'top:${_n(_px(y))}px;'
              'height:${_n(_px(line.heightTwips))}px;'
              'line-height:${_n(_px(line.heightTwips))}px;'
              'word-spacing:${_n(line.wordSpacingTwips / 20 * pxPerPt)}px;'
              'white-space:pre;'
              'text-align:${_alignCss(fragment.align)};');
      for (final segment in line.segments) {
        if (segment.textBox != null) {
          element.append(_renderTextBox(
            segment,
            lineTopTwips: y,
            lineIndentTwips: line.indentTwips,
            blockWidthTwips: availableTwips - fragment.indentTwips,
            rightIndentTwips: fragment.rightIndentTwips,
            // `docPos` do fragmento JÁ é o início do CONTEÚDO do bloco — é
            // dele que o mapa de posições parte ao somar `data-char-start`.
            blockContentPos: projectedCopy ? null : fragment.docPos,
          ));
          // The floating visual lives at block level, but its anchor still
          // occupies one inline model position at this exact place in the
          // line. Keeping an inert zero-size sibling is the only way the DOM
          // position map can distinguish text-before from text-after.
          final anchor = document.createElement('span');
          anchor.classes.add('$officeCssPrefix-text-box-anchor');
          anchor.setAttribute('contenteditable', 'false');
          anchor.setAttribute('aria-hidden', 'true');
          anchor.setAttribute('data-model-length', '1');
          anchor.setAttribute('style', 'display:none;');
          lineElement.append(anchor);
        } else {
          lineElement.append(_renderSegment(segment));
        }
      }
      element.append(lineElement);
      y += line.heightTwips;
    }
    return element;
  }

  /// Sombreamento e bordas do parágrafo, numa camada PRÓPRIA atrás do texto.
  ///
  /// Não são CSS do elemento do bloco por duas razões concretas:
  /// * o bloco tem largura e altura em px derivadas do grafo, e uma `border`
  ///   nele deslocaria (ou inflaria) a caixa que o mapa de posições mede;
  /// * o Word desenha a moldura em volta das LINHAS, não do espaçamento antes
  ///   e depois — que é justamente o pedaço que a altura do bloco inclui.
  ///
  /// A camada é inerte (`contenteditable=false`, `data-model-length=0`), então
  /// não cria alvo de caret nem desloca um único offset do documento.
  DomElement? _blockDecoration(BlockFragment fragment) {
    final borders = fragment.borders;
    final background = fragment.backgroundColor;
    if (background == null && borders == null) return null;
    final height = fragment.heightTwips -
        fragment.spaceBeforeTwips -
        fragment.spaceAfterTwips;
    if (height <= 0) return null;

    final element = document.createElement('div');
    element.classes.add('$officeCssPrefix-block-decoration');
    element.setAttribute('contenteditable', 'false');
    element.setAttribute('aria-hidden', 'true');
    element.setAttribute('data-model-length', '0');
    final buffer = StringBuffer()
      ..write('position:absolute;left:0;')
      ..write('right:${_n(_px(fragment.rightIndentTwips))}px;')
      ..write('top:${_n(_px(fragment.spaceBeforeTwips))}px;')
      ..write('height:${_n(_px(height))}px;')
      ..write('box-sizing:border-box;pointer-events:none;');
    if (background != null) buffer.write('background-color:$background;');
    if (borders != null) {
      // Parágrafo partido entre páginas: o Word fecha a moldura só nas
      // extremidades REAIS. Repetir a aresta em cada fatia desenharia um
      // traço no meio do parágrafo, onde não há fim de nada.
      buffer
        ..write(
            'border-top:${fragment.continuesFromPreviousPage ? 'none' : _borderCssValue(borders.top)};')
        ..write('border-right:${_borderCssValue(borders.right)};')
        ..write(
            'border-bottom:${fragment.continuesOnNextPage ? 'none' : _borderCssValue(borders.bottom)};')
        ..write('border-left:${_borderCssValue(borders.left)};');
    }
    element.setAttribute('style', buffer.toString());
    return element;
  }

  DomElement _renderSegment(LineSegment segment) {
    final style = segment.style;
    if (segment.hardBreak) {
      final br = document.createElement('br');
      br.classes.add('$officeCssPrefix-hard-break');
      br.setAttribute('data-model-length', '1');
      return br;
    }
    if (segment.isOpaqueInline) {
      final hidden = document.createElement('span');
      hidden.classes.add('$officeCssPrefix-opaque-inline');
      hidden.setAttribute('contenteditable', 'false');
      hidden.setAttribute('aria-hidden', 'true');
      hidden.setAttribute('data-model-length', '1');
      hidden.setAttribute('style', 'display:none;');
      return hidden;
    }
    if (segment.isTab) {
      final tab = document.createElement('span');
      tab.classes.add('$officeCssPrefix-tab');
      tab.setAttribute('data-model-length', '1');
      if (segment.tabLeader != null) {
        tab.setAttribute('data-leader', segment.tabLeader!);
      }
      final leaderCss = switch (segment.tabLeader?.toLowerCase()) {
        'underscore' => 'border-bottom:1px solid currentColor;',
        'dot' || 'middledot' => 'border-bottom:1px dotted currentColor;',
        'hyphen' => 'border-bottom:1px dashed currentColor;',
        _ => '',
      };
      tab.setAttribute(
          'style',
          'display:inline-block;overflow:hidden;vertical-align:baseline;'
              'width:${_n(_px(segment.widthTwips))}px;'
              'height:1em;white-space:pre;$leaderCss');
      // Um caractere lógico mantém o offset DOM/modelo; a largura visual é
      // inteiramente governada pelo stop calculado acima.
      tab.appendText('\t');
      return tab;
    }
    if (segment.imageSrc != null) {
      final image = document.createElement('img');
      image.classes.add('$officeCssPrefix-image');
      image.setAttribute('src', segment.imageSrc!);
      image.setAttribute('data-model-length', '1');
      image.setAttribute(
          'style',
          'display:inline-block;vertical-align:middle;'
              'width:${_n(_px(segment.widthTwips))}px;'
              'height:${_n(_px(segment.imageHeightTwips ?? segment.widthTwips))}px;');
      return image;
    }
    final span = document.createElement('span');
    span.classes.add('$officeCssPrefix-run');
    if (segment.isDiscretionaryHyphen) {
      span.classes.add('$officeCssPrefix-discretionary-hyphen');
      span.setAttribute('contenteditable', 'false');
      span.setAttribute('aria-hidden', 'true');
      span.setAttribute('data-model-length', '0');
    }
    final css = StringBuffer()
      ..write('font-family:${_cssFontFamily(style.family)};')
      ..write('font-size:${_n(style.sizePt * pxPerPt)}px;')
      ..write('color:${style.color};')
      ..write('letter-spacing:${_n(_px(style.letterSpacingTwips))}px;');
    if (style.bold) css.write('font-weight:bold;');
    if (style.italic) css.write('font-style:italic;');
    if (style.underline && style.strike) {
      css.write('text-decoration:underline line-through;');
    } else if (style.underline) {
      css.write('text-decoration:underline;');
    } else if (style.strike) {
      css.write('text-decoration:line-through;');
    }
    span.setAttribute('style', css.toString());
    if (style.link != null) {
      span.setAttribute('data-link', style.link!);
    }
    span.appendText(segment.text);
    return span;
  }

  DomElement _renderTextBox(
    LineSegment segment, {
    required int lineTopTwips,
    required int lineIndentTwips,
    required int blockWidthTwips,
    required int rightIndentTwips,
    int? blockContentPos,
  }) {
    final box = segment.textBox!;
    final width = box.widthTwips > 0 ? box.widthTwips : 1;
    final height = box.heightTwips > 0 ? box.heightTwips : 1;
    final usable = blockWidthTwips - rightIndentTwips;
    final left = switch (box.positionHAlign?.toLowerCase()) {
      'center' => (usable - width) ~/ 2 + box.offsetXTwips,
      'right' => usable - width + box.offsetXTwips,
      _ => lineIndentTwips + box.offsetXTwips,
    };
    final element = document.createElement('div');
    element.classes.add('$officeCssPrefix-text-box');
    element.setAttribute('contenteditable', 'false');
    element.setAttribute('data-model-length', '1');
    element.setAttribute('data-position-h-align', box.positionHAlign ?? 'left');
    // `docPos < 0` é a projeção REPETIDA de cabeçalho/rodapé: ela não
    // corresponde a nenhuma posição do corpo, e somar o offset de caractere
    // a -1 produziria uma posição positiva que apontaria para outro nó
    // qualquer. Sem âncora, o clique nessa cópia inerte não seleciona nada —
    // que é o certo: a caixa do cabeçalho é editada na sessão da REGIÃO.
    if (blockContentPos != null && blockContentPos >= 0) {
      // A posição do NÓ `textBox` no documento. O visual é filho do
      // fragmento, não da linha, então ele não herda os offsets de
      // caractere — sem esta âncora um duplo clique não saberia qual caixa
      // abrir nem onde gravar o que for digitado.
      element.setAttribute(
          'data-doc-pos', '${blockContentPos + box.charStartInBlock}');
    }
    final background =
        box.backgroundColor == null ? '' : 'background:${box.backgroundColor};';
    final border = box.borderWidthTwips > 0
        ? 'border:${_n(_px(box.borderWidthTwips))}px solid ${box.borderColor};'
        : 'border:none;';
    final style = segment.style;
    element.setAttribute(
        'style',
        'position:absolute;z-index:1;box-sizing:border-box;overflow:hidden;'
            'left:${_n(_px(left))}px;'
            'top:${_n(_px(lineTopTwips + box.offsetYTwips))}px;'
            'width:${_n(_px(width))}px;height:${_n(_px(height))}px;'
            'white-space:pre-wrap;'
            'font-family:${_cssFontFamily(style.family)};'
            'font-size:${_n(style.sizePt * pxPerPt)}px;'
            'line-height:${_n(style.sizePt * pxPerPt * 1.15)}px;'
            'color:${style.color};$background$border');
    if (box.contentBlocks.isEmpty) {
      // Compatibilidade com snapshots anteriores à projeção rica.
      element.appendText(box.text);
      return element;
    }

    final rawInnerWidth = width - box.insetLeftTwips - box.insetRightTwips;
    final rawInnerHeight = height - box.insetTopTwips - box.insetBottomTwips;
    final innerWidth = rawInnerWidth > 0 ? rawInnerWidth : 1;
    final innerHeight = rawInnerHeight > 0 ? rawInnerHeight : 1;
    final content = document.createElement('div');
    content.classes.add('$officeCssPrefix-text-box-content');
    content.setAttribute('aria-hidden', 'true');
    content.setAttribute(
        'style',
        'position:absolute;overflow:hidden;'
            'left:${_n(_px(box.insetLeftTwips))}px;'
            'top:${_n(_px(box.insetTopTwips))}px;'
            'width:${_n(_px(innerWidth))}px;'
            'height:${_n(_px(innerHeight))}px;');
    for (final block in box.contentBlocks) {
      content.append(_renderBlock(
        block,
        availableTwips: innerWidth,
        withMarker: true,
        projectedCopy: true,
      ));
    }
    element.append(content);
    return element;
  }

  void _anchor(DomElement element, PageFragment fragment) {
    _nodeAnchor(element, fragment.docPos, fragment.nodeId);
  }

  void _nodeAnchor(DomElement element, int docPos, String? nodeId) {
    element.setAttribute('data-doc-pos', '$docPos');
    if (nodeId != null) element.setAttribute('data-node-id', nodeId);
  }

  void _docRange(DomElement element, int from, int to) {
    element.setAttribute('data-doc-from', '$from');
    element.setAttribute('data-doc-to', '$to');
  }

  void _sourceIdentity(
    DomElement element, {
    String? tableId,
    String? rowId,
    String? cellId,
    int? rowIndex,
    int? cellIndex,
  }) {
    if (tableId != null) element.setAttribute('data-source-table', tableId);
    if (rowId != null) element.setAttribute('data-source-row', rowId);
    if (cellId != null) element.setAttribute('data-source-cell', cellId);
    if (rowIndex != null) {
      element.setAttribute('data-source-row-index', '$rowIndex');
    }
    if (cellIndex != null) {
      element.setAttribute('data-source-cell-index', '$cellIndex');
    }
  }

  String _bordersCss(TableCellBorders borders) {
    final sides = [borders.top, borders.right, borders.bottom, borders.left];
    final first = sides.first;
    if (first != null && sides.every((border) => _sameBorder(border, first))) {
      return 'border:${_borderCssValue(first)};';
    }
    return 'border-top:${_borderCssValue(borders.top)};'
        'border-right:${_borderCssValue(borders.right)};'
        'border-bottom:${_borderCssValue(borders.bottom)};'
        'border-left:${_borderCssValue(borders.left)};';
  }

  bool _sameBorder(TableBorder? a, TableBorder b) =>
      a != null &&
      a.style == b.style &&
      a.widthTwips == b.widthTwips &&
      a.color == b.color;

  String _borderCssValue(TableBorder? border) {
    if (border == null || !border.isVisible) return '0 none transparent';
    return '${_n(_px(border.widthTwips))}px ${border.style} ${border.color}';
  }

  static String _alignCss(LayoutAlign align) => switch (align) {
        LayoutAlign.center => 'center',
        LayoutAlign.right => 'right',
        LayoutAlign.justify => 'justify',
        LayoutAlign.left => 'left',
      };

  /// Mantém a família pedida como primeira opção, mas declara também a fonte
  /// metricamente equivalente usada pelo compositor e um fallback genérico.
  /// Sem a pilha explícita, Chrome escolhe serif para famílias DOCX ausentes,
  /// embora o PageGraph tenha sido medido com uma substituta compatível
  /// (caso real Ecofont -> Calibri/Carlito).
  static String _cssFontFamily(String family) {
    final requestedKey = family.trim().toLowerCase();
    final fallbacks = FontRegistry.instance.fallbackFamilyStack(family);
    final fallbackKey = fallbacks.last.toLowerCase();
    final stack = <String>[];
    // Uma família genérica não é uma fonte concreta. A equivalente métrica
    // precisa vir antes dela (`Courier New, monospace`, por exemplo).
    if (requestedKey != 'serif' &&
        requestedKey != 'sans-serif' &&
        requestedKey != 'monospace') {
      stack.add(_cssFontName(family));
    }
    for (final fallback in fallbacks) {
      final key = fallback.toLowerCase();
      if (key != requestedKey &&
          !stack.any((candidate) =>
              candidate.replaceAll("'", '').toLowerCase() == key)) {
        stack.add(_cssFontName(fallback));
      }
    }
    stack.add(switch (fallbackKey) {
      'times new roman' => 'serif',
      'courier new' => 'monospace',
      _ => 'sans-serif',
    });
    return stack.join(',');
  }

  static String _cssFontName(String family) {
    final escaped =
        family.trim().replaceAll(r'\', r'\\').replaceAll("'", r"\'");
    return escaped.contains(' ') ? "'$escaped'" : escaped;
  }
}
