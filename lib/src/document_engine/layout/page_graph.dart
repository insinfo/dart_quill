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
  });

  final int widthTwips;
  final int heightTwips;
  final int marginTopTwips;
  final int marginRightTwips;
  final int marginBottomTwips;
  final int marginLeftTwips;

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
  });

  final List<LineSegment> segments;
  final int widthTwips;
  final int ascentTwips;
  final int heightTwips;

  /// Offsets de caractere DENTRO do bloco de origem (para o PositionMap).
  final int charStart;
  final int charEnd;
}

/// Fragmento de um bloco numa página. Um parágrafo que atravessa páginas
/// continua sendo UM nó no documento — produz vários fragments.
class BlockFragment {
  const BlockFragment({
    required this.nodeId,
    required this.docPos,
    required this.kind,
    required this.lines,
    required this.yTwips,
    required this.heightTwips,
    this.indentTwips = 0,
    this.align = LayoutAlign.left,
    this.marker,
    this.continuesFromPreviousPage = false,
    this.continuesOnNextPage = false,
  });

  /// Id estável do nó de origem (officeIdsPlugin) — a chave do cache
  /// tipográfico e da invalidação incremental.
  final String? nodeId;

  /// Posição PM do nó no documento (início do bloco).
  final int docPos;

  /// Nome do tipo do nó ('paragraph', 'heading', 'listItem', ...).
  final String kind;

  final List<LineBox> lines;

  /// Topo do fragment, relativo ao content box da página.
  final int yTwips;
  final int heightTwips;
  final int indentTwips;
  final LayoutAlign align;

  /// Marcador de lista ('1. ', '• ') quando o fragment abre o item.
  final String? marker;

  final bool continuesFromPreviousPage;
  final bool continuesOnNextPage;
}

/// Uma página composta.
class PageLayout {
  const PageLayout({
    required this.index,
    required this.setup,
    required this.fragments,
  });

  final int index;
  final PageSetupTwips setup;
  final List<BlockFragment> fragments;
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
  });

  final List<PageLayout> pages;
  final PositionMap positionMap;
  final LayoutDiagnostics diagnostics;
  final LayoutQuality quality;
}
