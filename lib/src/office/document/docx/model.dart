import '../../ce_xml.dart';

/// Modelo WordprocessingML tipado (roteiro_editor_profissional, F2.1).
///
/// Regra de ouro (D1): o que o modelo não entende vira nó *preservado*
/// ([WpPreservedBlock]/[WpPreservedInline]/[WpPreservedRunContent]) com o
/// XML bruto — nunca é descartado silenciosamente.

// ---------------------------------------------------------------------------
// Helpers de parse
// ---------------------------------------------------------------------------

String? _val(XmlElement? el) => el?.getAttribute('w:val');

int? _intVal(XmlElement? el, [String attr = 'w:val']) {
  final raw = el?.getAttribute(attr);
  return raw == null ? null : int.tryParse(raw);
}

/// Elementos on/off do OOXML: presença = true, `w:val="0|false|none"` = false.
bool? _onOff(XmlElement? el) {
  if (el == null) return null;
  final raw = _val(el);
  if (raw == null) return true;
  return !(raw == '0' || raw == 'false' || raw == 'none');
}

// ---------------------------------------------------------------------------
// Propriedades compartilhadas
// ---------------------------------------------------------------------------

/// `<w:spacing>` de parágrafo (twips; line pode ser 240-avos quando auto).
class WpSpacing {
  final int? beforeTwips;
  final int? afterTwips;
  final int? line;
  final String? lineRule; // auto | atLeast | exact

  const WpSpacing(
      {this.beforeTwips, this.afterTwips, this.line, this.lineRule});

  static WpSpacing? fromXml(XmlElement? el) {
    if (el == null) return null;
    return WpSpacing(
      beforeTwips: _intVal(el, 'w:before'),
      afterTwips: _intVal(el, 'w:after'),
      line: _intVal(el, 'w:line'),
      lineRule: el.getAttribute('w:lineRule'),
    );
  }
}

/// `<w:ind>` (twips).
class WpIndent {
  final int? leftTwips;
  final int? rightTwips;
  final int? firstLineTwips;
  final int? hangingTwips;

  const WpIndent(
      {this.leftTwips,
      this.rightTwips,
      this.firstLineTwips,
      this.hangingTwips});

  static WpIndent? fromXml(XmlElement? el) {
    if (el == null) return null;
    return WpIndent(
      leftTwips: _intVal(el, 'w:left') ?? _intVal(el, 'w:start'),
      rightTwips: _intVal(el, 'w:right') ?? _intVal(el, 'w:end'),
      firstLineTwips: _intVal(el, 'w:firstLine'),
      hangingTwips: _intVal(el, 'w:hanging'),
    );
  }
}

/// `<w:tab>` dentro de `<w:tabs>` (tab stop).
class WpTabStop {
  final String val; // left | center | right | decimal | clear | ...
  final int posTwips;
  final String? leader; // dot | underscore | ...

  const WpTabStop({required this.val, required this.posTwips, this.leader});
}

/// `<w:shd>` (sombreamento de parágrafo/célula/run).
class WpShading {
  final String? val; // clear | pct10 | ...
  final String? color;
  final String? fill; // cor de fundo (hex ou "auto")

  const WpShading({this.val, this.color, this.fill});

  static WpShading? fromXml(XmlElement? el) {
    if (el == null) return null;
    return WpShading(
      val: _val(el),
      color: el.getAttribute('w:color'),
      fill: el.getAttribute('w:fill'),
    );
  }
}

/// Uma borda (`<w:top/>` etc. dentro de tcBorders/pBdr/tblBorders).
class WpBorder {
  final String? val; // single | none | double | ...
  final int? sizeEighths; // w:sz em 1/8 pt
  final String? color;
  final int? space;

  const WpBorder({this.val, this.sizeEighths, this.color, this.space});

  static WpBorder? fromXml(XmlElement? el) {
    if (el == null) return null;
    return WpBorder(
      val: _val(el),
      sizeEighths: _intVal(el, 'w:sz'),
      color: el.getAttribute('w:color'),
      space: _intVal(el, 'w:space'),
    );
  }
}

/// Conjunto de bordas (célula/parágrafo/tabela).
class WpBorders {
  final WpBorder? top;
  final WpBorder? left;
  final WpBorder? bottom;
  final WpBorder? right;
  final WpBorder? insideH;
  final WpBorder? insideV;

  const WpBorders(
      {this.top,
      this.left,
      this.bottom,
      this.right,
      this.insideH,
      this.insideV});

  static WpBorders? fromXml(XmlElement? el) {
    if (el == null) return null;
    return WpBorders(
      top: WpBorder.fromXml(el.firstChild('w:top')),
      left:
          WpBorder.fromXml(el.firstChild('w:left') ?? el.firstChild('w:start')),
      bottom: WpBorder.fromXml(el.firstChild('w:bottom')),
      right:
          WpBorder.fromXml(el.firstChild('w:right') ?? el.firstChild('w:end')),
      insideH: WpBorder.fromXml(el.firstChild('w:insideH')),
      insideV: WpBorder.fromXml(el.firstChild('w:insideV')),
    );
  }
}

// ---------------------------------------------------------------------------
// Run properties (rPr)
// ---------------------------------------------------------------------------

class WpRunProperties {
  final String? styleId; // w:rStyle
  final String? fontAscii;
  final String? fontHAnsi;
  final String? fontCs;
  final bool? bold;
  final bool? italic;
  final String? underline; // single | none | ...
  final bool? strike;
  final bool? caps;
  final bool? smallCaps;
  final int? sizeHalfPoints; // w:sz
  final String? color; // hex ou "auto"
  final String? highlight; // yellow | green | ...
  final WpShading? shading;
  final String? vertAlign; // superscript | subscript | baseline

  const WpRunProperties({
    this.styleId,
    this.fontAscii,
    this.fontHAnsi,
    this.fontCs,
    this.bold,
    this.italic,
    this.underline,
    this.strike,
    this.caps,
    this.smallCaps,
    this.sizeHalfPoints,
    this.color,
    this.highlight,
    this.shading,
    this.vertAlign,
  });

  static WpRunProperties? fromXml(XmlElement? el) {
    if (el == null) return null;
    final rFonts = el.firstChild('w:rFonts');
    return WpRunProperties(
      styleId: _val(el.firstChild('w:rStyle')),
      fontAscii: rFonts?.getAttribute('w:ascii'),
      fontHAnsi: rFonts?.getAttribute('w:hAnsi'),
      fontCs: rFonts?.getAttribute('w:cs'),
      bold: _onOff(el.firstChild('w:b')),
      italic: _onOff(el.firstChild('w:i')),
      underline: _val(el.firstChild('w:u')),
      strike: _onOff(el.firstChild('w:strike')),
      caps: _onOff(el.firstChild('w:caps')),
      smallCaps: _onOff(el.firstChild('w:smallCaps')),
      sizeHalfPoints: _intVal(el.firstChild('w:sz')),
      color: _val(el.firstChild('w:color')),
      highlight: _val(el.firstChild('w:highlight')),
      shading: WpShading.fromXml(el.firstChild('w:shd')),
      vertAlign: _val(el.firstChild('w:vertAlign')),
    );
  }

  /// Overlay: valores de [other] (mais específico) vencem os deste.
  WpRunProperties mergedWith(WpRunProperties other) => WpRunProperties(
        styleId: other.styleId ?? styleId,
        fontAscii: other.fontAscii ?? fontAscii,
        fontHAnsi: other.fontHAnsi ?? fontHAnsi,
        fontCs: other.fontCs ?? fontCs,
        bold: other.bold ?? bold,
        italic: other.italic ?? italic,
        underline: other.underline ?? underline,
        strike: other.strike ?? strike,
        caps: other.caps ?? caps,
        smallCaps: other.smallCaps ?? smallCaps,
        sizeHalfPoints: other.sizeHalfPoints ?? sizeHalfPoints,
        color: other.color ?? color,
        highlight: other.highlight ?? highlight,
        shading: other.shading ?? shading,
        vertAlign: other.vertAlign ?? vertAlign,
      );
}

// ---------------------------------------------------------------------------
// Paragraph properties (pPr)
// ---------------------------------------------------------------------------

class WpNumPr {
  /// `numId=0` remove numeração herdada do estilo.
  final int? numId;
  final int ilvl;

  const WpNumPr({this.numId, this.ilvl = 0});
}

class WpParagraphProperties {
  final String? styleId; // w:pStyle
  final WpNumPr? numPr;
  final String? jc; // left | center | right | both | ...
  final WpSpacing? spacing;
  final WpIndent? indent;
  final List<WpTabStop>? tabs;
  final WpShading? shading;
  final WpBorders? borders; // w:pBdr
  final bool? keepNext;
  final bool? keepLines;
  final bool? pageBreakBefore;
  final bool? widowControl;
  final bool? contextualSpacing;
  final int? outlineLvl;

  /// rPr da marca de parágrafo (formata o pilcrow; útil para parágrafo vazio).
  final WpRunProperties? markRunProperties;

  const WpParagraphProperties({
    this.styleId,
    this.numPr,
    this.jc,
    this.spacing,
    this.indent,
    this.tabs,
    this.shading,
    this.borders,
    this.keepNext,
    this.keepLines,
    this.pageBreakBefore,
    this.widowControl,
    this.contextualSpacing,
    this.outlineLvl,
    this.markRunProperties,
  });

  static WpParagraphProperties? fromXml(XmlElement? el) {
    if (el == null) return null;
    final numPrEl = el.firstChild('w:numPr');
    WpNumPr? numPr;
    if (numPrEl != null) {
      numPr = WpNumPr(
        numId: _intVal(numPrEl.firstChild('w:numId')),
        ilvl: _intVal(numPrEl.firstChild('w:ilvl')) ?? 0,
      );
    }
    List<WpTabStop>? tabs;
    final tabsEl = el.firstChild('w:tabs');
    if (tabsEl != null) {
      tabs = [
        for (final tab in tabsEl.childrenNamed('w:tab'))
          WpTabStop(
            val: tab.getAttribute('w:val') ?? 'left',
            posTwips: _intVal(tab, 'w:pos') ?? 0,
            leader: tab.getAttribute('w:leader'),
          )
      ];
    }
    return WpParagraphProperties(
      styleId: _val(el.firstChild('w:pStyle')),
      numPr: numPr,
      jc: _val(el.firstChild('w:jc')),
      spacing: WpSpacing.fromXml(el.firstChild('w:spacing')),
      indent: WpIndent.fromXml(el.firstChild('w:ind')),
      tabs: tabs,
      shading: WpShading.fromXml(el.firstChild('w:shd')),
      borders: WpBorders.fromXml(el.firstChild('w:pBdr')),
      keepNext: _onOff(el.firstChild('w:keepNext')),
      keepLines: _onOff(el.firstChild('w:keepLines')),
      pageBreakBefore: _onOff(el.firstChild('w:pageBreakBefore')),
      widowControl: _onOff(el.firstChild('w:widowControl')),
      contextualSpacing: _onOff(el.firstChild('w:contextualSpacing')),
      outlineLvl: _intVal(el.firstChild('w:outlineLvl')),
      markRunProperties: WpRunProperties.fromXml(el.firstChild('w:rPr')),
    );
  }

  /// Overlay: valores de [other] (mais específico) vencem os deste.
  /// [styleId] e [markRunProperties] não participam da cascata.
  WpParagraphProperties mergedWith(WpParagraphProperties other) =>
      WpParagraphProperties(
        styleId: other.styleId ?? styleId,
        numPr: other.numPr ?? numPr,
        jc: other.jc ?? jc,
        spacing: other.spacing ?? spacing,
        indent: other.indent ?? indent,
        tabs: other.tabs ?? tabs,
        shading: other.shading ?? shading,
        borders: other.borders ?? borders,
        keepNext: other.keepNext ?? keepNext,
        keepLines: other.keepLines ?? keepLines,
        pageBreakBefore: other.pageBreakBefore ?? pageBreakBefore,
        widowControl: other.widowControl ?? widowControl,
        contextualSpacing: other.contextualSpacing ?? contextualSpacing,
        outlineLvl: other.outlineLvl ?? outlineLvl,
        markRunProperties: other.markRunProperties ?? markRunProperties,
      );
}

// ---------------------------------------------------------------------------
// Conteúdo de run
// ---------------------------------------------------------------------------

sealed class WpRunContent {}

class WpText extends WpRunContent {
  final String text;
  WpText(this.text);
}

class WpTabChar extends WpRunContent {}

class WpBreak extends WpRunContent {
  final String? breakType; // page | column | textWrapping (null = linha)
  WpBreak([this.breakType]);
}

class WpNoBreakHyphen extends WpRunContent {}

class WpSymbol extends WpRunContent {
  final String? font;
  final String? charHex;
  WpSymbol({this.font, this.charHex});
}

/// `<w:drawing>` inline: imagem via `a:blip r:embed`.
class WpDrawing extends WpRunContent {
  final String? embedRelId;
  final double? widthEmu;
  final double? heightEmu;
  final bool isInline;

  /// XML bruto para preservação (D1).
  final String rawXml;

  WpDrawing({
    this.embedRelId,
    this.widthEmu,
    this.heightEmu,
    required this.isInline,
    required this.rawXml,
  });
}

class WpFieldChar extends WpRunContent {
  final String fldCharType; // begin | separate | end
  WpFieldChar(this.fldCharType);
}

class WpInstrText extends WpRunContent {
  final String text;
  WpInstrText(this.text);
}

/// Conteúdo de run não mapeado — preservado como XML bruto (D1).
class WpPreservedRunContent extends WpRunContent {
  final String qname;
  final String xml;
  WpPreservedRunContent(this.qname, this.xml);
}

/// Caixa de texto flutuante (shape `wps:wsp` dentro de `mc:AlternateContent`),
/// ex.: o carimbo "Continuação de Processo" no cabeçalho (F4.8). Guarda a
/// geometria da âncora, a borda/preenchimento e os blocos de texto internos,
/// além do XML bruto para preservação no save.
class WpTextBox extends WpRunContent {
  /// Alinhamento horizontal da âncora: 'left' | 'center' | 'right' | null.
  final String? positionHAlign;
  final int? offsetXEmu;
  final int? offsetYEmu;
  final int? extentCxEmu;
  final int? extentCyEmu;
  final int? borderWidthEmu;
  final String? borderColorHex; // sem '#'
  final String? fillColorHex; // sem '#'
  final List<WpBlock> blocks;
  final String rawXml;

  WpTextBox({
    this.positionHAlign,
    this.offsetXEmu,
    this.offsetYEmu,
    this.extentCxEmu,
    this.extentCyEmu,
    this.borderWidthEmu,
    this.borderColorHex,
    this.fillColorHex,
    required this.blocks,
    required this.rawXml,
  });
}

// ---------------------------------------------------------------------------
// Inlines de parágrafo
// ---------------------------------------------------------------------------

sealed class WpInline {}

class WpRun extends WpInline {
  final WpRunProperties? properties;
  final List<WpRunContent> content;

  WpRun({this.properties, required this.content});

  String get text => content.whereType<WpText>().map((t) => t.text).join();
}

class WpHyperlink extends WpInline {
  final String? relId; // r:id (externo, resolve via rels)
  final String? anchor; // w:anchor (interno)
  final List<WpRun> runs;

  WpHyperlink({this.relId, this.anchor, required this.runs});

  String get text => runs.map((r) => r.text).join();
}

/// `<w:fldSimple w:instr="...">`.
class WpSimpleField extends WpInline {
  final String instruction;
  final List<WpRun> runs;

  WpSimpleField({required this.instruction, required this.runs});
}

/// Inline não mapeado (bookmarks, proofErr, AlternateContent...) — preservado.
class WpPreservedInline extends WpInline {
  final String qname;
  final String xml;
  WpPreservedInline(this.qname, this.xml);
}

// ---------------------------------------------------------------------------
// Blocos
// ---------------------------------------------------------------------------

sealed class WpBlock {}

class WpParagraph extends WpBlock {
  final WpParagraphProperties? properties;
  final List<WpInline> inlines;

  /// Hash do XML original do parágrafo (passthrough por parágrafo na F3).
  final String? sourceXml;

  WpParagraph({this.properties, required this.inlines, this.sourceXml});

  String get text => inlines
      .map((inline) => switch (inline) {
            WpRun run => run.text,
            WpHyperlink link => link.text,
            WpSimpleField field => field.runs.map((r) => r.text).join(),
            WpPreservedInline _ => '',
          })
      .join();

  Iterable<WpRun> get allRuns sync* {
    for (final inline in inlines) {
      switch (inline) {
        case WpRun run:
          yield run;
        case WpHyperlink link:
          yield* link.runs;
        case WpSimpleField field:
          yield* field.runs;
        case WpPreservedInline _:
          break;
      }
    }
  }
}

/// Largura OOXML (`w:tblW`/`w:tcW`): dxa (twips), pct (50-avos de %), auto.
class WpTableWidth {
  final int? value;
  final String? type;

  const WpTableWidth({this.value, this.type});

  static WpTableWidth? fromXml(XmlElement? el) {
    if (el == null) return null;
    return WpTableWidth(
        value: _intVal(el, 'w:w'), type: el.getAttribute('w:type'));
  }
}

class WpTableProperties {
  final String? styleId; // w:tblStyle
  final WpTableWidth? width;
  final String? jc;
  final WpBorders? borders; // w:tblBorders
  final int? indentTwips; // w:tblInd
  final String? layout; // fixed | autofit

  const WpTableProperties(
      {this.styleId,
      this.width,
      this.jc,
      this.borders,
      this.indentTwips,
      this.layout});

  static WpTableProperties? fromXml(XmlElement? el) {
    if (el == null) return null;
    return WpTableProperties(
      styleId: _val(el.firstChild('w:tblStyle')),
      width: WpTableWidth.fromXml(el.firstChild('w:tblW')),
      jc: _val(el.firstChild('w:jc')),
      borders: WpBorders.fromXml(el.firstChild('w:tblBorders')),
      indentTwips: _intVal(el.firstChild('w:tblInd'), 'w:w'),
      layout: el.firstChild('w:tblLayout')?.getAttribute('w:type'),
    );
  }
}

class WpTableRowProperties {
  final int? heightTwips;
  final String? heightRule; // atLeast | exact
  final bool tblHeader; // repete em cada página
  final bool cantSplit;

  const WpTableRowProperties(
      {this.heightTwips,
      this.heightRule,
      this.tblHeader = false,
      this.cantSplit = false});

  static WpTableRowProperties? fromXml(XmlElement? el) {
    if (el == null) return null;
    final trHeight = el.firstChild('w:trHeight');
    return WpTableRowProperties(
      heightTwips: _intVal(trHeight),
      heightRule: trHeight?.getAttribute('w:hRule'),
      tblHeader: _onOff(el.firstChild('w:tblHeader')) ?? false,
      cantSplit: _onOff(el.firstChild('w:cantSplit')) ?? false,
    );
  }
}

class WpTableCellProperties {
  final WpTableWidth? width;
  final int? gridSpan;

  /// null = sem vMerge; 'restart' = início do merge; 'continue' = continuação.
  final String? vMerge;
  final WpBorders? borders; // w:tcBorders
  final WpShading? shading;
  final String? vAlign; // top | center | bottom

  const WpTableCellProperties(
      {this.width,
      this.gridSpan,
      this.vMerge,
      this.borders,
      this.shading,
      this.vAlign});

  static WpTableCellProperties? fromXml(XmlElement? el) {
    if (el == null) return null;
    final vMergeEl = el.firstChild('w:vMerge');
    return WpTableCellProperties(
      width: WpTableWidth.fromXml(el.firstChild('w:tcW')),
      gridSpan: _intVal(el.firstChild('w:gridSpan')),
      vMerge: vMergeEl == null ? null : (_val(vMergeEl) ?? 'continue'),
      borders: WpBorders.fromXml(el.firstChild('w:tcBorders')),
      shading: WpShading.fromXml(el.firstChild('w:shd')),
      vAlign: _val(el.firstChild('w:vAlign')),
    );
  }
}

class WpTableCell {
  final WpTableCellProperties? properties;
  final List<WpBlock> blocks;

  WpTableCell({this.properties, required this.blocks});
}

class WpTableRow {
  final WpTableRowProperties? properties;
  final List<WpTableCell> cells;

  WpTableRow({this.properties, required this.cells});
}

class WpTable extends WpBlock {
  final WpTableProperties? properties;

  /// Larguras do `<w:tblGrid>` em twips.
  final List<int> gridColumnsTwips;
  final List<WpTableRow> rows;

  /// XML original da tabela (passthrough D1 quando intocada; `null` para
  /// tabelas novas/regeneradas).
  final String? sourceXml;

  WpTable(
      {this.properties,
      required this.gridColumnsTwips,
      required this.rows,
      this.sourceXml});
}

/// Bloco não mapeado — preservado como XML bruto (D1).
class WpPreservedBlock extends WpBlock {
  final String qname;
  final String xml;
  WpPreservedBlock(this.qname, this.xml);
}

// ---------------------------------------------------------------------------
// Seção
// ---------------------------------------------------------------------------

class WpHeaderFooterReference {
  final String type; // default | first | even
  final String relId;

  const WpHeaderFooterReference({required this.type, required this.relId});
}

class WpSectionProperties {
  final int? pageWidthTwips;
  final int? pageHeightTwips;
  final String? orientation;
  final int? marginTopTwips;
  final int? marginRightTwips;
  final int? marginBottomTwips;
  final int? marginLeftTwips;
  final int? headerDistanceTwips;
  final int? footerDistanceTwips;
  final int? gutterTwips;
  final bool titlePage; // w:titlePg — header/footer "first" ativo
  final List<WpHeaderFooterReference> headerReferences;
  final List<WpHeaderFooterReference> footerReferences;

  /// XML original do `<w:sectPr>` (re-emitido byte a byte no save).
  final String? sourceXml;

  const WpSectionProperties({
    this.pageWidthTwips,
    this.pageHeightTwips,
    this.orientation,
    this.marginTopTwips,
    this.marginRightTwips,
    this.marginBottomTwips,
    this.marginLeftTwips,
    this.headerDistanceTwips,
    this.footerDistanceTwips,
    this.gutterTwips,
    this.titlePage = false,
    this.headerReferences = const [],
    this.footerReferences = const [],
    this.sourceXml,
  });

  static WpSectionProperties? fromXml(XmlElement? el) {
    if (el == null) return null;
    final pgSz = el.firstChild('w:pgSz');
    final pgMar = el.firstChild('w:pgMar');
    List<WpHeaderFooterReference> refs(String qname) => [
          for (final ref in el.childrenNamed(qname))
            WpHeaderFooterReference(
              type: ref.getAttribute('w:type') ?? 'default',
              relId: ref.getAttribute('r:id') ?? '',
            )
        ];
    return WpSectionProperties(
      pageWidthTwips: _intVal(pgSz, 'w:w'),
      pageHeightTwips: _intVal(pgSz, 'w:h'),
      orientation: pgSz?.getAttribute('w:orient'),
      marginTopTwips: _intVal(pgMar, 'w:top'),
      marginRightTwips: _intVal(pgMar, 'w:right'),
      marginBottomTwips: _intVal(pgMar, 'w:bottom'),
      marginLeftTwips: _intVal(pgMar, 'w:left'),
      headerDistanceTwips: _intVal(pgMar, 'w:header'),
      footerDistanceTwips: _intVal(pgMar, 'w:footer'),
      gutterTwips: _intVal(pgMar, 'w:gutter'),
      titlePage: _onOff(el.firstChild('w:titlePg')) ?? false,
      headerReferences: refs('w:headerReference'),
      footerReferences: refs('w:footerReference'),
      sourceXml: el.toXmlString(),
    );
  }
}

// ---------------------------------------------------------------------------
// Documento / header / footer / settings
// ---------------------------------------------------------------------------

class WpDocumentModel {
  final List<WpBlock> body;
  final WpSectionProperties? section;

  WpDocumentModel({required this.body, this.section});

  Iterable<WpParagraph> get allParagraphs sync* {
    yield* _paragraphsIn(body);
  }

  Iterable<WpTable> get allTables sync* {
    yield* _tablesIn(body);
  }

  static Iterable<WpParagraph> _paragraphsIn(List<WpBlock> blocks) sync* {
    for (final block in blocks) {
      if (block is WpParagraph) yield block;
      if (block is WpTable) {
        for (final row in block.rows) {
          for (final cell in row.cells) {
            yield* _paragraphsIn(cell.blocks);
          }
        }
      }
    }
  }

  static Iterable<WpTable> _tablesIn(List<WpBlock> blocks) sync* {
    for (final block in blocks) {
      if (block is WpTable) {
        yield block;
        for (final row in block.rows) {
          for (final cell in row.cells) {
            yield* _tablesIn(cell.blocks);
          }
        }
      }
    }
  }
}

/// Conteúdo de um header (`w:hdr`) ou footer (`w:ftr`).
class WpHeaderFooter {
  final String partName;
  final List<WpBlock> blocks;

  WpHeaderFooter({required this.partName, required this.blocks});
}

/// `word/settings.xml` (subset relevante ao corpus).
class WpSettings {
  final bool autoHyphenation;
  final bool evenAndOddHeaders;
  final int defaultTabStopTwips;

  const WpSettings({
    this.autoHyphenation = false,
    this.evenAndOddHeaders = false,
    this.defaultTabStopTwips = 708,
  });

  static WpSettings fromXml(XmlElement? root) {
    if (root == null) return const WpSettings();
    return WpSettings(
      autoHyphenation: _onOff(root.firstChild('w:autoHyphenation')) ?? false,
      evenAndOddHeaders:
          _onOff(root.firstChild('w:evenAndOddHeaders')) ?? false,
      defaultTabStopTwips: _intVal(root.firstChild('w:defaultTabStop')) ?? 708,
    );
  }
}
