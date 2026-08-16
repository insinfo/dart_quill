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
/// A marca-d'água de TEXTO de uma seção ("MINUTA", "RASCUNHO", "CÓPIA").
///
/// É o recurso da aba Design que mais aparece em documento administrativo, e
/// no Word ele não é conteúdo: é um desenho atrás do texto, repetido em toda
/// página, que o cursor não alcança. Aqui vale o mesmo — a marca vive na
/// GEOMETRIA da seção, não na árvore, então ela não ocupa posição, não entra
/// na seleção, não é apagada por Ctrl+A e não muda a paginação.
final class OfficePageWatermark {
  const OfficePageWatermark({
    required this.text,
    this.color = '#C8C8C8',
    this.fontFamily = 'Calibri',
    this.sizePt = 72,
    this.diagonal = true,
  });

  final String text;
  final String color;
  final String fontFamily;
  final double sizePt;

  /// Diagonal (o padrão do Word, −45°) ou horizontal.
  final bool diagonal;

  bool get isEmpty => text.trim().isEmpty;

  OfficePageWatermark copyWith({
    String? text,
    String? color,
    String? fontFamily,
    double? sizePt,
    bool? diagonal,
  }) =>
      OfficePageWatermark(
        text: text ?? this.text,
        color: color ?? this.color,
        fontFamily: fontFamily ?? this.fontFamily,
        sizePt: sizePt ?? this.sizePt,
        diagonal: diagonal ?? this.diagonal,
      );

  Map<String, dynamic> toJson() => {
        'text': text,
        'color': color,
        'fontFamily': fontFamily,
        'sizePt': sizePt,
        'diagonal': diagonal,
      };

  static OfficePageWatermark? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final text = raw['text'];
    if (text is! String || text.trim().isEmpty) return null;
    return OfficePageWatermark(
      text: text,
      color: raw['color'] is String ? raw['color'] as String : '#C8C8C8',
      fontFamily:
          raw['fontFamily'] is String ? raw['fontFamily'] as String : 'Calibri',
      sizePt: raw['sizePt'] is num ? (raw['sizePt'] as num).toDouble() : 72,
      diagonal: raw['diagonal'] != false,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is OfficePageWatermark &&
      other.text == text &&
      other.color == color &&
      other.fontFamily == fontFamily &&
      other.sizePt == sizePt &&
      other.diagonal == diagonal;

  @override
  int get hashCode => Object.hash(text, color, fontFamily, sizePt, diagonal);
}

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
    this.documentGridLinePitchTwips,
    this.documentGridType,
    this.columnCount,
    this.columnSpacingTwips = 720,
    this.pageColor,
    this.pageBorders,
    this.pageBorderSpacePt = 24,
    this.watermark,
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

  /// Passo da grade vertical de texto (`w:docGrid/@linePitch`). Quando
  /// presente, linhas do corpo que usam `snapToGrid` ocupam múltiplos deste
  /// valor. Tabelas não usam a grade sem `adjustLineHeightInTable`.
  final int? documentGridLinePitchTwips;

  /// `w:docGrid/@type`. Ausente equivale a `default`, isto é, SEM grade.
  /// Só `lines` e `linesAndChars` ativam o passo vertical; `snapToChars`
  /// afeta apenas a grade horizontal.
  final String? documentGridType;

  int? get activeDocumentGridLinePitchTwips {
    final type = documentGridType?.toLowerCase();
    return type == 'lines' || type == 'linesandchars'
        ? documentGridLinePitchTwips
        : null;
  }

  /// Colunas da seção (`w:cols/@num`), ou null quando NÃO foi declarado.
  ///
  /// A distinção entre null e 1 é o que impede a exportação de achatar um
  /// `w:cols w:num="2"` importado quando o chamador montou a geometria só
  /// para trocar margens: null significa "não mexi", e o `w:cols` de origem
  /// segue intacto. Para compor, use [columns].
  ///
  ///
  /// Só colunas de largura IGUAL são modeladas. `w:cols` permite declarar
  /// cada coluna com sua largura (`w:col/@w`), e o Word usa isso em layouts
  /// de revista; aqui a contagem e o espaçamento cobrem o que a ribbon
  /// oferece, e uma seção importada com larguras desiguais é composta com a
  /// contagem dela e larguras iguais — o texto fica na coluna certa, com a
  /// divisão errada, que é melhor que ignorar as colunas e empilhar tudo
  /// numa só.
  final int? columnCount;

  /// A contagem EFETIVA para compor: sem declaração, uma coluna.
  int get columns => columnCount ?? 1;

  /// Espaço ENTRE colunas (`w:cols/@space`). O padrão do Word é 0,5".
  final int columnSpacingTwips;

  // -- chrome da PÁGINA (aba Design) ------------------------------------------
  //
  // As três propriedades abaixo pintam a folha e NÃO mexem na área útil: no
  // Word, cor, borda e marca-d'água não reflowam uma linha sequer. Por isso
  // elas vivem na geometria e são consumidas direto pelos dois renderers, sem
  // passar pelo compositor — nenhuma delas pode mudar onde o texto quebra.

  /// Cor de fundo da folha (`w:background/@w:color`), ou null.
  final String? pageColor;

  /// Bordas de página (`w:pgBorders`), ou null.
  final BlockBorders? pageBorders;

  /// Distância da borda de página até a BORDA DO PAPEL, em pontos
  /// (`w:pgBorders/w:top/@w:space`). O padrão do Word é 24 pt.
  final int pageBorderSpacePt;

  /// Marca-d'água de texto da seção, ou null.
  final OfficePageWatermark? watermark;

  int get contentWidthTwips => widthTwips - marginLeftTwips - marginRightTwips;

  /// Largura de UMA coluna. O espaçamento entra `columnCount - 1` vezes.
  int get columnWidthTwips {
    if (columns <= 1) return contentWidthTwips;
    final usable = contentWidthTwips - columnSpacingTwips * (columns - 1);
    final each = usable ~/ columns;
    // Colunas demais para a largura do papel: uma coluna de largura zero (ou
    // negativa) faria toda palavra estourar a linha e o compositor entraria
    // em laço. Um piso mínimo mantém a composição terminando, e a página sai
    // visivelmente errada — que é o sintoma certo para uma configuração
    // impossível.
    return each > _minimumColumnTwips ? each : _minimumColumnTwips;
  }

  /// Deslocamento horizontal da coluna [index] dentro do content box.
  int columnLeftTwips(int index) {
    if (columns <= 1 || index <= 0) return 0;
    final clamped = index < columns ? index : columns - 1;
    return clamped * (columnWidthTwips + columnSpacingTwips);
  }

  /// Meia polegada: abaixo disso não cabe nem uma palavra média.
  static const int _minimumColumnTwips = 720;
  int get contentHeightTwips =>
      heightTwips - marginTopTwips - marginBottomTwips;

  /// A mesma geometria com alguns campos trocados.
  ///
  /// Existe para que acrescentar uma propriedade de página não continue sendo
  /// uma armadilha: o comando de orientação, de papel e de colunas copiavam a
  /// geometria campo a campo, e cada campo novo nascia sendo APAGADO por eles
  /// em silêncio — foi assim que a grade de texto do documento se perdeu ao
  /// trocar o papel. Com um `copyWith`, quem não fala de um campo o preserva.
  ///
  /// Os anuláveis usam sentinelas (`clearX`) porque `null` aqui significa
  /// "não mexi", e sem elas seria impossível REMOVER uma marca-d'água.
  PageSetupTwips copyWith({
    int? widthTwips,
    int? heightTwips,
    int? marginTopTwips,
    int? marginRightTwips,
    int? marginBottomTwips,
    int? marginLeftTwips,
    int? headerDistanceTwips,
    int? footerDistanceTwips,
    int? documentGridLinePitchTwips,
    String? documentGridType,
    int? columnCount,
    int? columnSpacingTwips,
    String? pageColor,
    BlockBorders? pageBorders,
    int? pageBorderSpacePt,
    OfficePageWatermark? watermark,
    bool clearPageColor = false,
    bool clearPageBorders = false,
    bool clearWatermark = false,
  }) =>
      PageSetupTwips(
        widthTwips: widthTwips ?? this.widthTwips,
        heightTwips: heightTwips ?? this.heightTwips,
        marginTopTwips: marginTopTwips ?? this.marginTopTwips,
        marginRightTwips: marginRightTwips ?? this.marginRightTwips,
        marginBottomTwips: marginBottomTwips ?? this.marginBottomTwips,
        marginLeftTwips: marginLeftTwips ?? this.marginLeftTwips,
        headerDistanceTwips: headerDistanceTwips ?? this.headerDistanceTwips,
        footerDistanceTwips: footerDistanceTwips ?? this.footerDistanceTwips,
        documentGridLinePitchTwips:
            documentGridLinePitchTwips ?? this.documentGridLinePitchTwips,
        documentGridType: documentGridType ?? this.documentGridType,
        columnCount: columnCount ?? this.columnCount,
        columnSpacingTwips: columnSpacingTwips ?? this.columnSpacingTwips,
        pageColor: clearPageColor ? null : (pageColor ?? this.pageColor),
        pageBorders:
            clearPageBorders ? null : (pageBorders ?? this.pageBorders),
        pageBorderSpacePt: pageBorderSpacePt ?? this.pageBorderSpacePt,
        watermark: clearWatermark ? null : (watermark ?? this.watermark),
      );
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
    this.letterSpacingTwips = 0,
  });

  final String family;
  final double sizePt;
  final bool bold;
  final bool italic;
  final bool underline;
  final bool strike;
  final String color;
  final String? link;

  /// Espaçamento adicional após cada caractere (`w:rPr/w:spacing`), em
  /// twips assinados. Zero e valores negativos são semânticos, não ausência.
  final int letterSpacingTwips;
}

/// Disposição do texto em torno de um objeto flutuante.
///
/// Espelha 1:1 o DrawingML: `wp:wrapSquare`, `wp:wrapTight`,
/// `wp:wrapThrough`, `wp:wrapTopAndBottom` e `wp:wrapNone` — este último
/// desdobrado em dois pelo atributo `wp:anchor/@behindDoc`, porque "atrás do
/// texto" e "na frente do texto" são o MESMO wrap (nenhum) e diferem apenas
/// na ordem de pintura.
enum TextWrapMode {
  /// `wp:wrapSquare` — exclusão retangular pela caixa delimitadora.
  square,

  /// `wp:wrapTight` — no Word, exclusão pelo polígono `wp:wrapPolygon`.
  ///
  /// Aqui a exclusão usa a MESMA caixa delimitadora do [square]: sem
  /// rasterizar o contorno do objeto não há polígono confiável, e aproximar
  /// pelo retângulo erra para fora (o texto nunca invade o objeto), que é o
  /// lado seguro do erro.
  tight,

  /// `wp:wrapThrough` — idem [tight], mais os vazios internos do polígono.
  /// Também aproximado pela caixa delimitadora.
  through,

  /// `wp:wrapTopAndBottom` — nenhuma linha divide a faixa vertical do objeto.
  topAndBottom,

  /// `wp:wrapNone` com `behindDoc="1"`: sem exclusão, atrás do texto.
  behindText,

  /// `wp:wrapNone` com `behindDoc="0"`: sem exclusão, na frente do texto.
  inFrontOfText,
}

/// `wp:wrapSquare/@wrapText` — de que lado do objeto o texto pode correr.
enum TextWrapSide {
  /// `bothSides`. O PageGraph tem UMA caixa de linha por linha, então não há
  /// como emitir a mesma linha dos dois lados do objeto; degrada para
  /// [largest], que é o que o Word acaba fazendo quando um dos lados não
  /// comporta nem uma palavra.
  bothSides,
  left,
  right,
  largest,
}

/// Caixa de texto ancorada a um run, mas fora do fluxo tipográfico.
///
/// Todas as medidas já estão em twips. A caixa é metadado visual do segmento:
/// ocupa largura zero e não participa da altura/quebra da linha âncora.
class FloatingTextBoxLayout {
  const FloatingTextBoxLayout({
    required this.text,
    required this.widthTwips,
    required this.heightTwips,
    this.contentBlocks = const <BlockFragment>[],
    this.insetLeftTwips = 0,
    this.insetTopTwips = 0,
    this.insetRightTwips = 0,
    this.insetBottomTwips = 0,
    this.offsetXTwips = 0,
    this.offsetYTwips = 0,
    this.positionHAlign,
    this.positionVRelativeFrom,
    this.borderWidthTwips = 0,
    this.borderColor = '#000000',
    this.backgroundColor,
    this.wrapMode = TextWrapMode.inFrontOfText,
    this.wrapSide = TextWrapSide.bothSides,
    this.wrapDistLeftTwips = 0,
    this.wrapDistTopTwips = 0,
    this.wrapDistRightTwips = 0,
    this.wrapDistBottomTwips = 0,
    this.charStartInBlock = 0,
  });

  final String text;
  final int widthTwips;
  final int heightTwips;

  /// Projeção rica dos blocos de `w:txbxContent`. Vazia em snapshots
  /// legados, que continuam usando [text] como fallback visual.
  final List<BlockFragment> contentBlocks;
  final int insetLeftTwips;
  final int insetTopTwips;
  final int insetRightTwips;
  final int insetBottomTwips;
  final int offsetXTwips;
  final int offsetYTwips;
  final String? positionHAlign;
  final String? positionVRelativeFrom;
  final int borderWidthTwips;
  final String borderColor;
  final String? backgroundColor;

  /// Disposição do texto: quem decide se — e como — o corpo desvia da caixa.
  final TextWrapMode wrapMode;

  /// Lado permitido ao texto nos modos com exclusão lateral.
  final TextWrapSide wrapSide;

  /// `distL/distT/distR/distB` do wrap: a folga entre o objeto e o texto.
  /// Ela infla o retângulo de exclusão, não o objeto desenhado.
  final int wrapDistLeftTwips;
  final int wrapDistTopTwips;
  final int wrapDistRightTwips;
  final int wrapDistBottomTwips;

  /// DrawingML `wp:wrapTopAndBottom`: a caixa continua flutuante na linha
  /// âncora, mas cria uma exclusão vertical para o corpo da página.
  bool get wrapTopAndBottom => wrapMode == TextWrapMode.topAndBottom;

  /// Modos que ENCURTAM a linha do corpo em vez de só empurrá-la para baixo.
  bool get createsSideExclusion =>
      wrapMode == TextWrapMode.square ||
      wrapMode == TextWrapMode.tight ||
      wrapMode == TextWrapMode.through;

  /// Deslocamento do nó `textBox` dentro do CONTEÚDO do bloco âncora.
  ///
  /// O visual flutuante é filho do fragmento, não da linha, então ele não
  /// herda os offsets de caractere que o mapa de posições usa. Guardar aqui
  /// o offset é o que permite ao renderer marcar a caixa com o
  /// `data-doc-pos` do nó — e sem isso não há como um duplo clique saber
  /// QUAL caixa abrir.
  final int charStartInBlock;
}

/// Um segmento de linha: texto contíguo com um único estilo.
class LineSegment {
  const LineSegment({
    required this.text,
    required this.style,
    required this.widthTwips,
    this.imageSrc,
    this.imageHeightTwips,
    this.hardBreak = false,
    this.isTab = false,
    this.tabLeader,
    this.isOpaqueInline = false,
    this.isDiscretionaryHyphen = false,
    this.textBox,
  });

  final String text;
  final ResolvedRunStyle style;
  final int widthTwips;

  /// Non-null for an inline DOCX image. The placeholder text remains in
  /// [text] for stable character offsets, while the DOM renders the image.
  final String? imageSrc;
  final int? imageHeightTwips;

  /// Quebra manual de linha (`w:br`/nó `hardBreak`). [text] mantém um único
  /// caractere lógico para que os offsets PM atravessem a quebra, mas os
  /// renderers projetam `<br>`/nenhum glifo em vez do caractere substituto.
  final bool hardBreak;

  /// Tabulação lógica. [widthTwips] é o avanço já resolvido até o stop.
  final bool isTab;
  final String? tabLeader;

  /// Conteúdo OOXML preservado sem representação visual (bookmarks etc.).
  final bool isOpaqueInline;

  /// Hífen projetado pelo compositor em uma quebra automática. Ele ocupa
  /// largura visual, mas zero caracteres no modelo — ao editar/salvar, a
  /// palavra original continua intacta e pode ser recomposta em outra linha.
  final bool isDiscretionaryHyphen;

  /// Caixa flutuante ancorada neste ponto; largura do segmento permanece 0.
  final FloatingTextBoxLayout? textBox;
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
    this.wrapLeftInsetTwips = 0,
    this.wrapRightInsetTwips = 0,
    this.wordSpacingTwips = 0,
    this.manualPageBreakBefore = false,
    this.columnBreakOnly = false,
    this.renderedPageBreakBefore = false,
  });

  /// A quebra manual desta linha é `<w:br w:type="column"/>`, não `page`.
  ///
  /// Num grafo monocoluna os dois davam no mesmo — a próxima coluna livre
  /// era a primeira da página seguinte. Com colunas de verdade eles deixam
  /// de ser sinônimos: a quebra de COLUNA continua na mesma página, e só a
  /// de PÁGINA fecha a folha com a coluna ao lado ainda vazia.
  final bool columnBreakOnly;

  /// Deslocamento X DESTA linha dentro do bloco — o recuo de primeira
  /// linha do Word. Negativo é o recuo pendente (hanging): a primeira
  /// linha fica à esquerda das demais.
  final int indentTwips;

  /// Encurtamento DESTA linha por um objeto flutuante com disposição do
  /// texto (`wp:wrapSquare` e afins).
  ///
  /// Fica separado de [indentTwips] e de `BlockFragment.rightIndentTwips`
  /// porque não é recuo de parágrafo: muda de linha para linha conforme a
  /// faixa vertical que o objeto ocupa, e some quando o objeto sai do
  /// caminho. Misturá-lo ao recuo faria uma edição de recuo herdar o desvio
  /// do objeto.
  final int wrapLeftInsetTwips;
  final int wrapRightInsetTwips;

  final List<LineSegment> segments;
  final int widthTwips;
  final int ascentTwips;
  final int heightTwips;

  /// Ajuste adicional aplicado depois de cada espaço U+0020 desta linha.
  ///
  /// O Word pode contrair espaços de uma linha justificada para fazê-la
  /// caber antes de decidir a quebra. Guardar o ajuste no PageGraph mantém
  /// DOM e PDF como projeções da mesma decisão tipográfica.
  final double wordSpacingTwips;

  /// A manual inline `<w:br w:type="page"/>` immediately before this line.
  /// Unlike [renderedPageBreakBefore], this is editable document content and
  /// must always be honored by pagination.
  final bool manualPageBreakBefore;

  /// Posição de um `<w:lastRenderedPageBreak/>` antes desta linha.
  ///
  /// É somente um hint do layout que salvou o DOCX: a composição inicial
  /// pode honrá-lo, mas ele nunca vira uma quebra manual editável/exportada.
  final bool renderedPageBreakBefore;

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
    this.columnIndex = 0,
  });

  /// Em qual COLUNA da seção este fragmento saiu.
  ///
  /// Guardar o índice, e não o x já calculado, mantém uma única fonte de
  /// verdade para a geometria: os renderers resolvem o deslocamento pela
  /// mesma `PageSetupTwips.columnLeftTwips` que o compositor usou. Um x
  /// carimbado por fragmento divergiria no primeiro caso de margem ou
  /// espaçamento que eu esquecesse de propagar.
  ///
  /// `yTwips` continua relativo ao topo do content box, então dois
  /// fragmentos de colunas diferentes podem ter o MESMO y — é justamente
  /// isso que os coloca lado a lado.
  final int columnIndex;

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
    this.markerPositionTwips = 0,
    this.markerStyle,
    this.widowControl = true,
    this.spaceBeforeTwips = 0,
    this.spaceAfterTwips = 0,
    this.backgroundColor,
    this.borders,
    super.continuesFromPreviousPage,
    super.continuesOnNextPage,
    super.columnIndex,
  });

  /// Nome do tipo do nó ('paragraph', 'heading', 'listItem', ...).
  final String kind;

  final List<LineBox> lines;
  final int indentTwips;
  final LayoutAlign align;

  /// Regra Word `w:widowControl`. Quando ausente na hierarquia OOXML, o
  /// padrão é ativo: a primeira ou a última linha do parágrafo não pode
  /// ficar isolada em outra página.
  final bool widowControl;

  /// Espaço de parágrafo efetivamente presente NESTE fragmento. O before só
  /// aparece no primeiro fragmento; o after, no último.
  final int spaceBeforeTwips;
  final int spaceAfterTwips;

  /// Sombreamento do parágrafo (`w:pBdr`/`w:shd`), já resolvido para uma cor
  /// CSS. Null quando o parágrafo não tem sombreamento próprio — `auto` do
  /// OOXML chega aqui como null, não como branco: pintar branco apagaria o
  /// sombreamento da célula ou da página por baixo.
  final String? backgroundColor;

  /// Bordas do parágrafo. Null (e não um [BlockBorders] vazio) quando o
  /// parágrafo não opinou: é o que distingue "sem `w:pBdr`" de "quatro
  /// arestas explicitamente `nil`".
  final BlockBorders? borders;

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
        markerPositionTwips: markerPositionTwips,
        markerStyle: markerStyle,
        widowControl: widowControl,
        spaceBeforeTwips: spaceBeforeTwips,
        spaceAfterTwips: spaceAfterTwips,
        backgroundColor: backgroundColor,
        borders: borders,
        continuesFromPreviousPage: continuesFromPreviousPage,
        continuesOnNextPage: continuesOnNextPage,
        columnIndex: columnIndex,
      );

  /// Recuo DIREITO do parágrafo, em twips: as linhas quebram antes e o
  /// alinhamento center/right respeita a borda recuada.
  final int rightIndentTwips;

  /// Marcador de lista ('1. ', '• ') quando o fragment abre o item.
  final String? marker;

  /// Posição do marcador desde a borda esquerda da caixa disponível.
  /// [indentTwips] é, separadamente, onde o texto começa.
  final int markerPositionTwips;

  /// Tipografia do rótulo quando ele não tem run textual próprio (caso
  /// comum em células numeradas vazias).
  final ResolvedRunStyle? markerStyle;
}

/// Alinhamento vertical do conteúdo de uma célula.
enum TableCellVerticalAlign { top, center, bottom }

/// Uma borda resolvida de tabela/célula.
///
/// A espessura continua em twips; [style] usa os nomes CSS canônicos que os
/// renderers DOM/PDF sabem projetar (`solid`, `double`, `dashed`, `dotted` ou
/// `none`).
class TableBorder {
  const TableBorder({
    this.style = 'solid',
    this.widthTwips = 15,
    this.color = '#000000',
  });

  final String style;
  final int widthTwips;
  final String color;

  bool get isVisible => style != 'none' && widthTwips > 0;
}

/// Bordas já resolvidas para os quatro lados de uma célula.
class TableCellBorders {
  const TableCellBorders({this.top, this.right, this.bottom, this.left});

  final TableBorder? top;
  final TableBorder? right;
  final TableBorder? bottom;
  final TableBorder? left;

  /// Alguma aresta desenha alguma coisa? Sem isto, um `w:pBdr` inteiro com
  /// `val="nil"` (o que "Sem Bordas" grava) faria os renderers criarem uma
  /// moldura invisível em todo parágrafo do documento.
  bool get hasVisibleSide =>
      (top?.isVisible ?? false) ||
      (right?.isVisible ?? false) ||
      (bottom?.isVisible ?? false) ||
      (left?.isVisible ?? false);
}

/// Bordas de um BLOCO (`w:pBdr`).
///
/// É o mesmo dado das bordas de célula — quatro arestas já resolvidas — e os
/// dois renderers já sabem projetá-lo. Um tipo novo idêntico só produziria
/// duas funções de desenho para a mesma figura, que é como as bordas de
/// tabela e de parágrafo divergem em silêncio.
typedef BlockBorders = TableCellBorders;

/// Célula composta: blocos internos com posição relativa ao topo da célula.
class TableCellBox {
  const TableCellBox({
    this.nodeId,
    this.docPos = 0,
    this.docPosEnd = 0,
    this.sourceTableId,
    this.sourceRowId,
    this.sourceCellId,
    this.sourceRowIndex,
    this.sourceCellIndex,
    required this.xTwips,
    required this.widthTwips,
    required this.blocks,
    required this.contentHeightTwips,
    this.heightTwips = 0,
    this.columnIndex = 0,
    this.columnSpan = 1,
    this.rowSpan = 1,
    this.isMergeContinuation = false,
    this.backgroundColor,
    this.verticalAlign = TableCellVerticalAlign.top,
    this.contentOffsetTwips = 0,
    this.borders = const TableCellBorders(),
    this.marginTopTwips = 60,
    this.marginRightTwips = 60,
    this.marginBottomTwips = 60,
    this.marginLeftTwips = 60,
  });

  final String? nodeId;

  /// Posição PM do início/fim do CONTEÚDO da célula.
  final int docPos;
  final int docPosEnd;

  /// Identidade da árvore PM de origem. Diferentemente da posição, não muda
  /// quando a tabela é fragmentada ou quando um header é projetado de novo.
  final String? sourceTableId;
  final String? sourceRowId;
  final String? sourceCellId;
  final int? sourceRowIndex;
  final int? sourceCellIndex;

  int get docFrom => docPos - 1;
  int get docTo => docPosEnd + 1;

  /// x relativo ao content box da página.
  final int xTwips;
  final int widthTwips;

  /// Blocos internos (yTwips relativo ao TOPO da célula).
  final List<BlockFragment> blocks;
  final int contentHeightTwips;

  /// Altura visual, incluindo todas as linhas cobertas por [rowSpan].
  final int heightTwips;

  final int columnIndex;
  final int columnSpan;
  final int rowSpan;

  /// `w:vMerge continue`: a caixa permanece no grafo para preservar as
  /// posições PM, mas sua projeção visual pertence à célula `restart`.
  final bool isMergeContinuation;

  final String? backgroundColor;
  final TableCellVerticalAlign verticalAlign;

  /// Deslocamento adicional do conteúdo depois de conhecida a altura final
  /// da linha/mesclagem (0/top, metade/center, total/bottom).
  final int contentOffsetTwips;
  final TableCellBorders borders;

  /// Margens internas Word (`tblCellMar`, sobrescritas por `tcMar`).
  final int marginTopTwips;
  final int marginRightTwips;
  final int marginBottomTwips;
  final int marginLeftTwips;

  TableCellBox shifted(int docPosDelta) => TableCellBox(
        nodeId: nodeId,
        docPos: docPos + docPosDelta,
        docPosEnd: docPosEnd + docPosDelta,
        sourceTableId: sourceTableId,
        sourceRowId: sourceRowId,
        sourceCellId: sourceCellId,
        sourceRowIndex: sourceRowIndex,
        sourceCellIndex: sourceCellIndex,
        xTwips: xTwips,
        widthTwips: widthTwips,
        blocks: [for (final block in blocks) block.shifted(docPosDelta)],
        contentHeightTwips: contentHeightTwips,
        heightTwips: heightTwips,
        columnIndex: columnIndex,
        columnSpan: columnSpan,
        rowSpan: rowSpan,
        isMergeContinuation: isMergeContinuation,
        backgroundColor: backgroundColor,
        verticalAlign: verticalAlign,
        contentOffsetTwips: contentOffsetTwips,
        borders: borders,
        marginTopTwips: marginTopTwips,
        marginRightTwips: marginRightTwips,
        marginBottomTwips: marginBottomTwips,
        marginLeftTwips: marginLeftTwips,
      );
}

/// Linha de tabela composta.
class TableRowBox {
  const TableRowBox({
    this.nodeId,
    this.docPos = 0,
    this.docPosEnd = 0,
    this.sourceTableId,
    this.sourceRowId,
    this.sourceRowIndex,
    required this.heightTwips,
    required this.cells,
    this.heightRule,
    this.cantSplit = false,
    this.repeatHeader = false,
    this.isRepeatedHeader = false,
    this.gridBefore = 0,
    this.gridAfter = 0,
    this.widthBeforeTwips,
    this.widthAfterTwips,
    this.continuesFromPreviousPage = false,
    this.continuesOnNextPage = false,
  });

  final String? nodeId;

  /// Posição PM do início/fim do CONTEÚDO da linha.
  final int docPos;
  final int docPosEnd;

  final String? sourceTableId;
  final String? sourceRowId;
  final int? sourceRowIndex;

  int get docFrom => docPos - 1;
  int get docTo => docPosEnd + 1;

  final int heightTwips;
  final List<TableCellBox> cells;

  /// `exact` ou `atLeast`, quando veio de `w:trHeight`.
  final String? heightRule;
  final bool cantSplit;
  final bool repeatHeader;

  /// Cópia projetada de um header na continuação da tabela. Ela desenha e
  /// imprime, mas não cria uma segunda posição editável para o mesmo nó.
  final bool isRepeatedHeader;

  /// Colunas omitidas antes/depois das células (`w:gridBefore/gridAfter`).
  /// São essenciais em tabelas irregulares: a primeira célula nem sempre
  /// começa na coluna zero.
  final int gridBefore;
  final int gridAfter;
  final int? widthBeforeTwips;
  final int? widthAfterTwips;
  final bool continuesFromPreviousPage;
  final bool continuesOnNextPage;

  TableRowBox shifted(int docPosDelta) => TableRowBox(
        nodeId: nodeId,
        docPos: docPos + docPosDelta,
        docPosEnd: docPosEnd + docPosDelta,
        sourceTableId: sourceTableId,
        sourceRowId: sourceRowId,
        sourceRowIndex: sourceRowIndex,
        heightTwips: heightTwips,
        cells: [for (final cell in cells) cell.shifted(docPosDelta)],
        heightRule: heightRule,
        cantSplit: cantSplit,
        repeatHeader: repeatHeader,
        isRepeatedHeader: isRepeatedHeader,
        gridBefore: gridBefore,
        gridAfter: gridAfter,
        widthBeforeTwips: widthBeforeTwips,
        widthAfterTwips: widthAfterTwips,
        continuesFromPreviousPage: continuesFromPreviousPage,
        continuesOnNextPage: continuesOnNextPage,
      );

  TableRowBox asRepeatedHeader() => TableRowBox(
        nodeId: nodeId,
        docPos: docPos,
        docPosEnd: docPosEnd,
        sourceTableId: sourceTableId,
        sourceRowId: sourceRowId,
        sourceRowIndex: sourceRowIndex,
        heightTwips: heightTwips,
        cells: cells,
        heightRule: heightRule,
        cantSplit: cantSplit,
        repeatHeader: repeatHeader,
        isRepeatedHeader: true,
        gridBefore: gridBefore,
        gridAfter: gridAfter,
        widthBeforeTwips: widthBeforeTwips,
        widthAfterTwips: widthAfterTwips,
        continuesFromPreviousPage: continuesFromPreviousPage,
        continuesOnNextPage: continuesOnNextPage,
      );
}

/// Fragmento de tabela: as linhas desta página (granularidade de LINHA DE
/// TABELA no draft; a fragmentação fina de célula fica com o fidelity).
class TableFragment extends PageFragment {
  const TableFragment({
    required super.nodeId,
    required super.docPos,
    required this.docPosEnd,
    required this.sourceTableId,
    required this.rows,
    required super.yTwips,
    required super.heightTwips,
    super.continuesFromPreviousPage,
    super.continuesOnNextPage,
    super.columnIndex,
  });

  final List<TableRowBox> rows;
  final int docPosEnd;
  final String? sourceTableId;

  int get docFrom => docPos - 1;
  int get docTo => docPosEnd + 1;

  @override
  TableFragment shifted(int docPosDelta) => TableFragment(
        nodeId: nodeId,
        docPos: docPos + docPosDelta,
        docPosEnd: docPosEnd + docPosDelta,
        sourceTableId: sourceTableId,
        rows: [for (final row in rows) row.shifted(docPosDelta)],
        yTwips: yTwips,
        heightTwips: heightTwips,
        continuesFromPreviousPage: continuesFromPreviousPage,
        continuesOnNextPage: continuesOnNextPage,
        columnIndex: columnIndex,
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
    required this.suppressSpaceBeforeAtPageTop,
    required this.startsFreshBlock,
    required this.lastDocPos,
  });

  /// Índice do bloco (filho do doc) em que a página começa.
  final int firstBlockIndex;

  /// Offset desse bloco no documento — evita re-somar nodeSize do começo.
  final int firstBlockOffset;

  /// Estado da numeração de lista ao entrar na página.
  final int carryListOrdinal;

  /// A fronteira que abriu esta página suprime o `spaceBefore` do primeiro
  /// bloco visual (overflow automático ou quebra inline explícita).
  ///
  /// Faz parte do estado de entrada: sem ele, retomar a composição nesta
  /// página pode restaurar o espaçamento e mudar toda a paginação seguinte.
  final bool suppressSpaceBeforeAtPageTop;

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
        suppressSpaceBeforeAtPageTop: signature.suppressSpaceBeforeAtPageTop,
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

  PositionMapEntry shifted(
          {required int docPosDelta, required int pageDelta}) =>
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
/// Estado de retomada de uma composição PARCIAL (paginação progressiva).
///
/// Existe apenas quando o compositor parou numa fronteira limpa (página
/// fechada exatamente no fim de um bloco). Todos os campos são o estado de
/// ENTRADA do próximo bloco — o mesmo contrato do resume incremental.
class PageGraphResume {
  const PageGraphResume({
    required this.blockIndex,
    required this.offset,
    required this.listOrdinal,
    required this.suppressSpaceBeforeAtPageTop,
    required this.honorRenderedPageBreaks,
  });

  /// Índice do próximo bloco de topo a compor.
  final int blockIndex;

  /// Offset do documento no início desse bloco.
  final int offset;

  /// Contador corrente de lista ordenada.
  final int listOrdinal;

  /// A página seguinte nasce suprimindo o spaceBefore automático?
  final bool suppressSpaceBeforeAtPageTop;

  /// Os hints `lastRenderedPageBreak` continuam válidos para o restante?
  /// (False quando uma divergência física já os descartou.)
  final bool honorRenderedPageBreaks;
}

class PageGraph {
  const PageGraph({
    required this.pages,
    required this.positionMap,
    required this.diagnostics,
    required this.quality,
    this.docSize = 0,
    this.blockCount = 0,
    this.honoredRenderedPageBreakHints = false,
    this.resume,
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

  /// A paginação deste grafo consumiu o cache `lastRenderedPageBreak`.
  ///
  /// Na primeira edição, o compositor usa isto para fazer UMA recomposição
  /// completa sem o cache obsoleto. O grafo seguinte volta a permitir reuso
  /// incremental mesmo que os nós opacos continuem preservados no modelo.
  final bool honoredRenderedPageBreakHints;

  /// Não nulo quando este grafo é PARCIAL (paginação progressiva em curso):
  /// as páginas existentes são definitivas, mas o documento continua em
  /// [PageGraphResume.blockIndex].
  final PageGraphResume? resume;

  bool get isPartial => resume != null;
}
