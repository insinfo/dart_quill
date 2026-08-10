import '../../ce_xml.dart';

import 'model.dart';

/// Um estilo de `styles.xml` (parágrafo, caractere, tabela ou numeração).
class WpStyle {
  final String id;
  final String type; // paragraph | character | table | numbering
  final String? name;
  final String? basedOn;
  final String? link;
  final bool isDefault;

  /// `w:qFormat` — o estilo é "recomendado", e é ISSO que o Word usa para
  /// decidir quem aparece na galeria da faixa de opções. Sem esta leitura a
  /// galeria mostraria os ~90 estilos de um DOCX real (inclusive os
  /// `Char` de caractere e os de comentário), que não é o que o Word faz.
  final bool qFormat;

  /// `w:uiPriority` — a ORDEM da galeria. Ausente vale 0, o default do
  /// elemento em ECMA-376: um estilo local do documento (que costuma vir sem
  /// a marca) aparece antes dos internos do Word, como no Word.
  final int uiPriority;

  final WpParagraphProperties? paragraphProperties;
  final WpRunProperties? runProperties;

  /// `w:tblPr` de estilos de tabela (bordas do "Grid Table Light" etc.).
  final WpTableProperties? tableProperties;

  const WpStyle({
    required this.id,
    required this.type,
    this.name,
    this.basedOn,
    this.link,
    this.isDefault = false,
    this.qFormat = false,
    this.uiPriority = 0,
    this.paragraphProperties,
    this.runProperties,
    this.tableProperties,
  });
}

/// `w:val` on/off de um elemento-flag do OOXML: ausente = falso, presente
/// sem `w:val` = verdadeiro, e `0`/`false` desligam explicitamente.
bool _onOffElement(XmlElement? el) {
  if (el == null) return false;
  final value = el.getAttribute('w:val');
  return value == null || value == '1' || value == 'true' || value == 'on';
}

/// Catálogo de estilos (`styles.xml`) com docDefaults e cadeias basedOn
/// (roteiro_editor_profissional, D2/F2.1).
class WpStyleSheet {
  final WpRunProperties? docDefaultsRun;
  final WpParagraphProperties? docDefaultsParagraph;
  final Map<String, WpStyle> byId;

  WpStyleSheet({
    this.docDefaultsRun,
    this.docDefaultsParagraph,
    Map<String, WpStyle>? byId,
  }) : byId = byId ?? <String, WpStyle>{};

  static WpStyleSheet parse(String xml) {
    final root = XmlDocument.parse(xml).rootElement;

    WpRunProperties? docDefaultsRun;
    WpParagraphProperties? docDefaultsParagraph;
    final docDefaults = root.firstChild('w:docDefaults');
    if (docDefaults != null) {
      docDefaultsRun = WpRunProperties.fromXml(
          docDefaults.firstChild('w:rPrDefault')?.firstChild('w:rPr'));
      docDefaultsParagraph = WpParagraphProperties.fromXml(
          docDefaults.firstChild('w:pPrDefault')?.firstChild('w:pPr'));
    }

    final byId = <String, WpStyle>{};
    for (final styleEl in root.childrenNamed('w:style')) {
      final id = styleEl.getAttribute('w:styleId');
      if (id == null) continue;
      byId[id] = WpStyle(
        id: id,
        type: styleEl.getAttribute('w:type') ?? 'paragraph',
        name: styleEl.firstChild('w:name')?.getAttribute('w:val'),
        basedOn: styleEl.firstChild('w:basedOn')?.getAttribute('w:val'),
        link: styleEl.firstChild('w:link')?.getAttribute('w:val'),
        isDefault: styleEl.getAttribute('w:default') == '1' ||
            styleEl.getAttribute('w:default') == 'true',
        // `<w:qFormat/>` sem atributo é ligado; `w:val="0"` desliga — a
        // convenção on/off do OOXML, não a presença do elemento.
        qFormat: _onOffElement(styleEl.firstChild('w:qFormat')),
        uiPriority:
            int.tryParse(styleEl.firstChild('w:uiPriority')?.getAttribute(
                          'w:val',
                        ) ??
                    '') ??
                0,
        paragraphProperties:
            WpParagraphProperties.fromXml(styleEl.firstChild('w:pPr')),
        runProperties: WpRunProperties.fromXml(styleEl.firstChild('w:rPr')),
        tableProperties:
            WpTableProperties.fromXml(styleEl.firstChild('w:tblPr')),
      );
    }

    return WpStyleSheet(
      docDefaultsRun: docDefaultsRun,
      docDefaultsParagraph: docDefaultsParagraph,
      byId: byId,
    );
  }

  WpStyle? operator [](String? id) => id == null ? null : byId[id];

  /// Estilo default de um tipo (`w:default="1"`), ex.: Normal.
  WpStyle? defaultOf(String type) {
    for (final style in byId.values) {
      if (style.isDefault && style.type == type) return style;
    }
    return null;
  }

  /// Cadeia basedOn do estilo, da RAIZ para o mais derivado (ordem de
  /// aplicação do Word). Protegida contra ciclos.
  List<WpStyle> chainOf(String? styleId) {
    final chain = <WpStyle>[];
    final seen = <String>{};
    var current = this[styleId];
    while (current != null && seen.add(current.id)) {
      chain.insert(0, current);
      current = this[current.basedOn];
    }
    return chain;
  }
}
