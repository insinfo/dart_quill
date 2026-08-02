/// PageGraph — o modelo de LAYOUT do modo avançado (Fase 5).
///
/// Três modelos separados, por decisão de arquitetura: o semântico
/// (OfficeNode), o de layout (ESTE — páginas, fragments, line boxes) e a
/// projeção DOM. O editor visual e o PdfRenderer consomem EXATAMENTE este
/// grafo: a linha que aparece na página 18 do editor é a linha escrita na
/// página 18 do PDF.
///
/// Unidades canônicas: TWIPS (1/20 pt) em todo o grafo. Pixel só existe na
/// borda da view; pt só na borda do PDF (`twips / 20`).
library;

/// Nível de qualidade do MESMO paginador — não há dois paginadores.
enum LayoutQuality { draft, fidelity }

/// Geometria da página em twips (A4 retrato por padrão; 1 cm ≈ 567 twips).
class PageSetupTwips {
  const PageSetupTwips({
    this.widthTwips = 11906, // 21,0 cm
    this.heightTwips = 16838, // 29,7 cm
    this.marginTopTwips = 1134, // 2 cm
    this.marginRightTwips = 1134,
    this.marginBottomTwips = 1134,
    this.marginLeftTwips = 1134,
    this.headerDistanceTwips = 709, // 1,25 cm da borda
    this.footerDistanceTwips = 709,
  });

  final int widthTwips;
  final int heightTwips;
  final int marginTopTwips;
  final int marginRightTwips;
  final int marginBottomTwips;
  final int marginLeftTwips;

  /// Distância do cabeçalho/rodapé até a BORDA da página, não até a margem.
  /// É como o Word mede (`w:headerReference` + `w:pgMar/@header`).
  final int headerDistanceTwips;
  final int footerDistanceTwips;

  int get contentWidthTwips => widthTwips - marginLeftTwips - marginRightTwips;
  int get contentHeightTwips =>
      heightTwips - marginTopTwips - marginBottomTwips;
}

/// Estilo resolvido de um run (a saída do StyleResolver para uma fatia de
/// texto contígua com as mesmas marcas).
class ResolvedRunStyle {
  const ResolvedRunStyle({
    required this.family,
    required this.sizePt,
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.strike = false,
    this.color = '#000000',
    this.link,
  });

  final String family;
  final double sizePt;
  final bool bold;
  final bool italic;
  final bool underline;
  final bool strike;
  final String color;
  final String? link;
}

/// Um segmento de linha: texto contíguo com um único estilo.
class LineSegment {
  const LineSegment({
    required this.text,
    required this.style,
    required this.widthTwips,
  });

  final String text;
  final ResolvedRunStyle style;
  final int widthTwips;
}

/// Alinhamento de bloco.
enum LayoutAlign { left, center, right, justify }

/// Uma linha composta: a unidade atômica da paginação.
class LineBox {
  const LineBox({
    required this.segments,
    required this.widthTwips,
    required this.ascentTwips,
    required this.heightTwips,
    required this.charStart,
    required this.charEnd,
    this.indentTwips = 0,
  });

  /// Deslocamento X DESTA linha dentro do bloco — o recuo de primeira
  /// linha do Word. Negativo é o recuo pendente (hanging): a primeira
  /// linha fica à esquerda das demais.
  final int indentTwips;

  final List<LineSegment> segments;
  final int widthTwips;
  final int ascentTwips;
  final int heightTwips;

  /// Offsets de caractere DENTRO do bloco de origem (para o PositionMap).
  final int charStart;
  final int charEnd;
}

/// Fragmento de layout numa página. Um nó que atravessa páginas continua
/// sendo UM nó no documento — produz vários fragments.
sealed class PageFragment {
  const PageFragment({
    required this.nodeId,
    required this.docPos,
    required this.yTwips,
    required this.heightTwips,
    this.continuesFromPreviousPage = false,
    this.continuesOnNextPage = false,
  });

  /// Id estável do nó de origem (officeIdsPlugin) — a chave do cache
  /// tipográfico e da invalidação incremental.
  final String? nodeId;

  /// Posição PM do nó no documento (início do bloco).
  final int docPos;

  /// Topo do fragment, relativo ao content box da página.
  final int yTwips;
  final int heightTwips;

  final bool continuesFromPreviousPage;
  final bool continuesOnNextPage;

  /// O MESMO fragmento com as posições deslocadas.
  ///
  /// É o que torna a convergência de sufixo possível: quando a composição
  /// nova reencontra o estado de uma página antiga, o conteúdo dali para
  /// frente é idêntico e só as POSIÇÕES mudaram, pelo tamanho do que a
  /// edição acrescentou ou removeu antes.
  PageFragment shifted(int docPosDelta);
}

/// Fragmento de bloco textual (parágrafo, heading, item de lista...).
class BlockFragment extends PageFragment {
  const BlockFragment({
    required super.nodeId,
    required super.docPos,
    required this.kind,
    required this.lines,
    required super.yTwips,
    required super.heightTwips,
    this.indentTwips = 0,
    this.rightIndentTwips = 0,
    this.align = LayoutAlign.left,
    this.marker,
    super.continuesFromPreviousPage,
    super.continuesOnNextPage,
  });

  /// Nome do tipo do nó ('paragraph', 'heading', 'listItem', ...).
  final String kind;

  final List<LineBox> lines;
  final int indentTwips;
  final LayoutAlign align;

  @override
  BlockFragment shifted(int docPosDelta) => BlockFragment(
        nodeId: nodeId,
        docPos: docPos + docPosDelta,
        kind: kind,
        lines: lines,
        yTwips: yTwips,
        heightTwips: heightTwips,
        indentTwips: indentTwips,
        rightIndentTwips: rightIndentTwips,
        align: align,
        marker: marker,
        continuesFromPreviousPage: continuesFromPreviousPage,
        continuesOnNextPage: continuesOnNextPage,
      );

  /// Recuo DIREITO do parágrafo, em twips: as linhas quebram antes e o
  /// alinhamento center/right respeita a borda recuada.
  final int rightIndentTwips;

  /// Marcador de lista ('1. ', '• ') quando o fragment abre o item.
  final String? marker;
}

/// Célula composta: blocos internos com posição relativa ao topo da célula.
class TableCellBox {
  const TableCellBox({
    required this.xTwips,
    required this.widthTwips,
    required this.blocks,
    required this.contentHeightTwips,
  });

  /// x relativo ao content box da página.
  final int xTwips;
  final int widthTwips;

  /// Blocos internos (yTwips relativo ao TOPO da célula).
  final List<BlockFragment> blocks;
  final int contentHeightTwips;
}

/// Linha de tabela composta.
class TableRowBox {
  const TableRowBox({required this.heightTwips, required this.cells});

  final int heightTwips;
  final List<TableCellBox> cells;
}

/// Fragmento de tabela: as linhas desta página (granularidade de LINHA DE
/// TABELA no draft; a fragmentação fina de célula fica com o fidelity).
class TableFragment extends PageFragment {
  const TableFragment({
    required super.nodeId,
    required super.docPos,
    required this.rows,
    required super.yTwips,
    required super.heightTwips,
    super.continuesFromPreviousPage,
    super.continuesOnNextPage,
  });

  final List<TableRowBox> rows;

  @override
  TableFragment shifted(int docPosDelta) => TableFragment(
        nodeId: nodeId,
        docPos: docPos + docPosDelta,
        rows: rows,
        yTwips: yTwips,
        heightTwips: heightTwips,
        continuesFromPreviousPage: continuesFromPreviousPage,
        continuesOnNextPage: continuesOnNextPage,
      );
}

/// Uma página composta.
/// Identidade de layout de uma página — o que permite REUSAR a página em
/// vez de recompô-la.
///
/// Guarda o estado de ENTRADA da página (onde ela começa no documento e o
/// que a numeração de lista carregava) e o de SAÍDA (onde ela termina).
/// Recompor a partir de uma página só é correto se ela começar num bloco
/// fresco: uma página que continua um parágrafo da anterior não conhece as
/// linhas que já foram consumidas.
class PageSignature {
  const PageSignature({
    required this.firstBlockIndex,
    required this.firstBlockOffset,
    required this.carryListOrdinal,
    required this.startsFreshBlock,
    required this.lastDocPos,
  });

  /// Índice do bloco (filho do doc) em que a página começa.
  final int firstBlockIndex;

  /// Offset desse bloco no documento — evita re-somar nodeSize do começo.
  final int firstBlockOffset;

  /// Estado da numeração de lista ao entrar na página.
  final int carryListOrdinal;

  /// A página começa um bloco NOVO (não é continuação de parágrafo/tabela)?
  final bool startsFreshBlock;

  /// Maior posição do documento tocada por esta página.
  final int lastDocPos;
}

class PageLayout {
  const PageLayout({
    required this.index,
    required this.setup,
    required this.fragments,
    required this.signature,
    this.header = const [],
    this.footer = const [],
  });

  final int index;
  final PageSetupTwips setup;
  final List<PageFragment> fragments;
  final PageSignature signature;

  /// Cabeçalho e rodapé desta página.
  ///
  /// São fragmentos INERTES: a mesma região aparece em todas as páginas, e
  /// tratá-los como conteúdo editável criaria N edições concorrentes do
  /// MESMO nó (§7.4 do plano). A edição de header/footer é uma região
  /// autoritativa própria, não estas cópias.
  ///
  /// Ficam FORA do `positionMap`: uma posição do documento nunca aponta
  /// para eles, então o caret não pode cair aqui por engano.
  final List<BlockFragment> header;
  final List<BlockFragment> footer;

  /// A mesma página com outro índice (reuso ao recompor incrementalmente).
  PageLayout withIndex(int newIndex) => PageLayout(
        index: newIndex,
        setup: setup,
        fragments: fragments,
        signature: signature,
        header: header,
        footer: footer,
      );

  /// A mesma página noutro índice e com as posições deslocadas — o reuso do
  /// SUFIXO depois da convergência.
  PageLayout shifted({
    required int newIndex,
    required int docPosDelta,
    required int blockIndexDelta,
  }) {
    // Edição que não muda tamanho nem contagem: a página reusada é a
    // MESMA, não uma cópia igual. Preservar a identidade importa — é o que
    // permite provar em teste que houve reuso, e evita alocar 200 páginas
    // para não mudar nada.
    if (docPosDelta == 0 && blockIndexDelta == 0 && newIndex == index) {
      return this;
    }
    return PageLayout(
        index: newIndex,
        setup: setup,
        header: header,
        footer: footer,
        fragments: docPosDelta == 0
            ? fragments
            : [for (final f in fragments) f.shifted(docPosDelta)],
        signature: PageSignature(
          firstBlockIndex: signature.firstBlockIndex + blockIndexDelta,
          firstBlockOffset: signature.firstBlockOffset + docPosDelta,
          carryListOrdinal: signature.carryListOrdinal,
          startsFreshBlock: signature.startsFreshBlock,
          lastDocPos: signature.lastDocPos + docPosDelta,
        ),
      );
  }
}

/// Mapeia posição do documento ↔ página (v1: granularidade de linha).
class PositionMap {
  PositionMap(this._entries);

  /// Entradas ordenadas por posição inicial.
  final List<PositionMapEntry> _entries;

  /// A página onde a posição [docPos] está desenhada, ou a última anterior.
  int pageOf(int docPos) {
    var low = 0, high = _entries.length - 1, best = 0;
    while (low <= high) {
      final mid = (low + high) >> 1;
      if (_entries[mid].docPosStart <= docPos) {
        best = mid;
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }
    return _entries.isEmpty ? 0 : _entries[best].pageIndex;
  }

  List<PositionMapEntry> get entries => List.unmodifiable(_entries);
}

class PositionMapEntry {
  const PositionMapEntry({
    required this.docPosStart,
    required this.docPosEnd,
    required this.pageIndex,
  });

  final int docPosStart;
  final int docPosEnd;
  final int pageIndex;

  PositionMapEntry shifted({required int docPosDelta, required int pageDelta}) =>
      PositionMapEntry(
        docPosStart: docPosStart + docPosDelta,
        docPosEnd: docPosEnd + docPosDelta,
        pageIndex: pageIndex + pageDelta,
      );
}

/// Avisos do layout (tabela não fragmentável, fonte ausente...).
class LayoutDiagnostics {
  final List<String> warnings = [];
}

/// O resultado completo da composição: o que editor e PDF consomem.
class PageGraph {
  const PageGraph({
    required this.pages,
    required this.positionMap,
    required this.diagnostics,
    required this.quality,
    this.docSize = 0,
    this.blockCount = 0,
  });

  final List<PageLayout> pages;
  final PositionMap positionMap;
  final LayoutDiagnostics diagnostics;
  final LayoutQuality quality;

  /// Tamanho e contagem de blocos do documento que gerou este grafo.
  ///
  /// A recomposição incremental compara com o documento novo para saber
  /// QUANTO deslocar o sufixo reusado.
  final int docSize;
  final int blockCount;
}
