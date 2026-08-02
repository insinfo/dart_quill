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
  });

  final DomDocument document;

  /// Escala explícita twips→px na borda da view (nunca implícita).
  final double pxPerPt;

  /// Marca o content box das páginas como `contenteditable`. A entrada em si
  /// (beforeinput/IME/seleção) é a Fase 2 completa; aqui a superfície já
  /// nasce com o atributo certo para o hardening começar.
  final bool editable;

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
        'height:${_n(_px(setup.heightTwips))}px;');

    final content = document.createElement('div');
    content.classes.add('$officeCssPrefix-page-content');
    if (editable) {
      content.setAttribute('contenteditable', 'true');
      // A superfície do Word Web também desliga o spellcheck nativo: o
      // sublinhado do browser desalinha do nosso layout próprio.
      content.setAttribute('spellcheck', 'false');
    }
    content.setAttribute(
        'style',
        'position:absolute;'
        'left:${_n(_px(setup.marginLeftTwips))}px;'
        'top:${_n(_px(setup.marginTopTwips))}px;'
        'width:${_n(_px(setup.contentWidthTwips))}px;'
        'height:${_n(_px(setup.contentHeightTwips))}px;');
    pageElement.append(content);

    for (final fragment in page.fragments) {
      switch (fragment) {
        case BlockFragment():
          content.append(_renderBlock(fragment,
              availableTwips: setup.contentWidthTwips, withMarker: true));
        case TableFragment():
          content.append(_renderTable(fragment));
      }
    }
    return pageElement;
  }

  DomElement _renderTable(TableFragment fragment) {
    final element = document.createElement('div');
    element.classes.add('$officeCssPrefix-table');
    _anchor(element, fragment);
    element.setAttribute(
        'style',
        'position:absolute;left:0;'
        'top:${_n(_px(fragment.yTwips))}px;'
        'height:${_n(_px(fragment.heightTwips))}px;');

    var y = 0;
    for (final row in fragment.rows) {
      final rowElement = document.createElement('div');
      rowElement.classes.add('$officeCssPrefix-table-row');
      rowElement.setAttribute(
          'style',
          'position:absolute;left:0;'
          'top:${_n(_px(y))}px;'
          'height:${_n(_px(row.heightTwips))}px;');
      for (final cell in row.cells) {
        final cellElement = document.createElement('div');
        cellElement.classes.add('$officeCssPrefix-table-cell');
        cellElement.setAttribute(
            'style',
            'position:absolute;'
            'left:${_n(_px(cell.xTwips))}px;top:0;'
            'width:${_n(_px(cell.widthTwips))}px;'
            'height:${_n(_px(row.heightTwips))}px;'
            'border:1px solid #000;box-sizing:border-box;');
        for (final block in cell.blocks) {
          cellElement.append(_renderBlock(block,
              availableTwips: cell.widthTwips, withMarker: false));
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
  }) {
    final element = document.createElement('div');
    element.classes.add('$officeCssPrefix-block');
    element.classes.add('$officeCssPrefix-block-${fragment.kind}');
    _anchor(element, fragment);
    if (fragment.continuesFromPreviousPage) {
      element.setAttribute('data-continues-from', 'true');
    }
    if (fragment.continuesOnNextPage) {
      element.setAttribute('data-continues-on', 'true');
    }
    element.setAttribute(
        'style',
        'position:absolute;'
        'left:${_n(_px(fragment.indentTwips))}px;'
        'top:${_n(_px(fragment.yTwips))}px;'
        'width:${_n(_px(availableTwips - fragment.indentTwips))}px;'
        'height:${_n(_px(fragment.heightTwips))}px;');

    if (withMarker && fragment.marker != null) {
      final marker = document.createElement('span');
      marker.classes.add('$officeCssPrefix-marker');
      // Marcador é PROJEÇÃO do modelo (o rótulo vem do layout, nunca é
      // texto do documento): fora da edição e da árvore de acessibilidade.
      marker.setAttribute('contenteditable', 'false');
      marker.setAttribute('aria-hidden', 'true');
      marker.setAttribute('style',
          'position:absolute;right:100%;padding-right:4px;white-space:pre;');
      marker.appendText(fragment.marker!);
      element.append(marker);
    }

    // Bloco VAZIO ainda precisa de uma linha na projeção: é onde o caret
    // pousa num parágrafo em branco — o estado inicial de um documento novo
    // e o resultado de todo Enter. Sem este alvo, o mapa de posições não
    // tem âncora e o editor não consegue nem começar a digitar.
    if (fragment.lines.isEmpty) {
      final empty = document.createElement('div');
      empty.classes.add('$officeCssPrefix-line');
      empty.classes.add('$officeCssPrefix-line-empty');
      empty.setAttribute('data-char-start', '0');
      empty.setAttribute('data-char-end', '0');
      empty.setAttribute(
          'style',
          'position:absolute;left:0;right:0;top:0;'
          'height:${_n(_px(fragment.heightTwips))}px;'
          'line-height:${_n(_px(fragment.heightTwips))}px;'
          'white-space:pre;');
      element.append(empty);
      return element;
    }

    var y = 0;
    for (final line in fragment.lines) {
      final lineElement = document.createElement('div');
      lineElement.classes.add('$officeCssPrefix-line');
      lineElement.setAttribute('data-char-start', '${line.charStart}');
      lineElement.setAttribute('data-char-end', '${line.charEnd}');
      lineElement.setAttribute(
          'style',
          'position:absolute;left:0;right:0;'
          'top:${_n(_px(y))}px;'
          'height:${_n(_px(line.heightTwips))}px;'
          'line-height:${_n(_px(line.heightTwips))}px;'
          'white-space:pre;'
          'text-align:${_alignCss(fragment.align)};');
      for (final segment in line.segments) {
        lineElement.append(_renderSegment(segment));
      }
      element.append(lineElement);
      y += line.heightTwips;
    }
    return element;
  }

  DomElement _renderSegment(LineSegment segment) {
    final style = segment.style;
    final span = document.createElement('span');
    span.classes.add('$officeCssPrefix-run');
    final css = StringBuffer()
      ..write('font-family:${_cssFontFamily(style.family)};')
      ..write('font-size:${_n(style.sizePt * pxPerPt)}px;')
      ..write('color:${style.color};');
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

  void _anchor(DomElement element, PageFragment fragment) {
    element.setAttribute('data-doc-pos', '${fragment.docPos}');
    final nodeId = fragment.nodeId;
    if (nodeId != null) element.setAttribute('data-node-id', nodeId);
  }

  static String _alignCss(LayoutAlign align) => switch (align) {
        LayoutAlign.center => 'center',
        LayoutAlign.right => 'right',
        LayoutAlign.justify => 'justify',
        LayoutAlign.left => 'left',
      };

  /// Uma família com espaço precisa de aspas no CSS; o resto passa direto.
  static String _cssFontFamily(String family) =>
      family.contains(' ') ? "'$family'" : family;
}
