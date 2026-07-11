import 'dart:convert';
import 'dart:typed_data';

import '../../ce_opc.dart';
import '../../ce_xml.dart';
import '../../ce_zip.dart';

import 'model.dart';
import 'numbering.dart';
import 'styles.dart';

/// Resultado da leitura de um .docx (roteiro_editor_profissional, F2.1).
class DocxFile {
  final OpcPackage package;
  final WpDocumentModel document;
  final WpStyleSheet styles;
  final WpNumbering numbering;
  final WpSettings settings;

  /// Nome da parte principal (normalmente `word/document.xml`).
  final String mainPartName;

  /// document.xml original até (e incluindo) `<w:body>` — re-emitido
  /// byte a byte no save (D1).
  final String documentBodyPrefix;

  /// document.xml original a partir de `</w:body>`.
  final String documentBodySuffix;

  /// Headers/footers da seção única do corpus, por tipo (default/first/even).
  final Map<String, WpHeaderFooter> headersByType;
  final Map<String, WpHeaderFooter> footersByType;

  /// Notas de fidelidade: qnames preservados-sem-mapeamento e avisos.
  final List<String> fidelityNotes;

  DocxFile({
    required this.package,
    required this.document,
    required this.styles,
    required this.numbering,
    required this.settings,
    required this.mainPartName,
    required this.documentBodyPrefix,
    required this.documentBodySuffix,
    required this.headersByType,
    required this.footersByType,
    required this.fidelityNotes,
  });

  /// Bytes de uma imagem referenciada por `r:embed` a partir de uma parte.
  Uint8List? imageBytes(String relId, {String fromPart = 'word/document.xml'}) {
    final rel = package.relationshipsFor(fromPart).byId(relId);
    if (rel == null || rel.isExternal) return null;
    return package.partBytes(package.resolveTarget(fromPart, rel.target));
  }

  /// Content type de uma imagem referenciada por `r:embed`.
  String? imageContentType(String relId,
      {String fromPart = 'word/document.xml'}) {
    final rel = package.relationshipsFor(fromPart).byId(relId);
    if (rel == null || rel.isExternal) return null;
    return package.contentTypeOf(package.resolveTarget(fromPart, rel.target));
  }

  /// URL de um hyperlink externo (`r:id`) de uma parte.
  String? hyperlinkUrl(String relId, {String fromPart = 'word/document.xml'}) {
    final rel = package.relationshipsFor(fromPart).byId(relId);
    return rel != null && rel.isExternal ? rel.target : null;
  }
}

String _buildWordDefaultStyles() {
  const List<int> sizes = <int>[32, 26, 24, 22, 22, 22];
  const List<String> colors = <String>[
    '2F5496',
    '2F5496',
    '1F4E79',
    '2F5496',
    '2F5496',
    '1F4E79'
  ];
  final StringBuffer styles =
      StringBuffer('''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:docDefaults><w:rPrDefault><w:rPr><w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/><w:sz w:val="22"/><w:szCs w:val="22"/></w:rPr></w:rPrDefault><w:pPrDefault><w:pPr/></w:pPrDefault></w:docDefaults>
  <w:style w:type="paragraph" w:default="1" w:styleId="Normal"><w:name w:val="Normal"/><w:qFormat/></w:style>''');
  for (int index = 0; index < 6; index++) {
    final int number = index + 1;
    styles.write('''
  <w:style w:type="paragraph" w:styleId="Heading$number">
    <w:name w:val="heading $number"/><w:aliases w:val="Título $number"/><w:basedOn w:val="Normal"/><w:next w:val="Normal"/><w:uiPriority w:val="${9 + index}"/><w:qFormat/>
    <w:pPr><w:keepNext/><w:keepLines/><w:spacing w:before="${number <= 2 ? 240 : 120}" w:after="0"/><w:outlineLvl w:val="$index"/></w:pPr>
    <w:rPr><w:rFonts w:ascii="Calibri Light" w:hAnsi="Calibri Light"/><w:color w:val="${colors[index]}"/><w:sz w:val="${sizes[index]}"/><w:szCs w:val="${sizes[index]}"/></w:rPr>
  </w:style>''');
  }
  styles.write('\n</w:styles>');
  return styles.toString();
}

/// Reader DOCX → modelo tipado.
class DocxReader {
  final List<String> _notes = [];

  DocxReader._();

  static DocxFile read(Uint8List bytes) => DocxReader._()._read(bytes);

  /// Cria um DOCX mínimo e válido para exportar documentos iniciados no
  /// editor, sem exigir que o usuário tenha aberto previamente um template.
  static DocxFile createEmpty() {
    final ZipArchive archive = ZipArchive()
      ..setFile('[Content_Types].xml',
          utf8.encode('''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
  <Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>
</Types>'''))
      ..setFile('_rels/.rels',
          utf8.encode('''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>'''))
      ..setFile('word/document.xml',
          utf8.encode('''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <w:body><w:p/><w:sectPr><w:pgSz w:w="11906" w:h="16838"/><w:pgMar w:top="1440" w:right="1440" w:bottom="1440" w:left="1440" w:header="720" w:footer="720" w:gutter="0"/></w:sectPr></w:body>
</w:document>'''));
    archive
      ..setFile('word/_rels/document.xml.rels',
          utf8.encode('''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
</Relationships>'''))
      ..setFile('word/styles.xml', utf8.encode(_buildWordDefaultStyles()));
    return read(archive.encode());
  }

  DocxFile _read(Uint8List bytes) {
    final package = OpcPackage.decode(bytes);
    final mainPart = package.mainDocumentPartName;

    final documentXml = package.partString(mainPart);
    if (documentXml == null) {
      throw FormatException('Parte principal ausente: $mainPart');
    }
    final documentRoot = XmlDocument.parse(documentXml).rootElement;
    final bodyEl = documentRoot.firstChild('w:body');
    if (bodyEl == null) {
      throw const FormatException('document.xml sem <w:body>.');
    }

    // Prefixo/sufixo do body para o writer (passthrough D1): tudo antes do
    // conteúdo do body e tudo a partir de </w:body> são re-emitidos como no
    // original. O corpus usa <w:body> sem atributos.
    final bodyOpen = documentXml.indexOf('<w:body>');
    final bodyClose = documentXml.lastIndexOf('</w:body>');
    if (bodyOpen < 0 || bodyClose < 0) {
      throw const FormatException(
          'document.xml com <w:body> em formato não suportado.');
    }
    final bodyPrefix = documentXml.substring(0, bodyOpen + '<w:body>'.length);
    final bodySuffix = documentXml.substring(bodyClose);

    final section = WpSectionProperties.fromXml(bodyEl.firstChild('w:sectPr'));
    final body = _parseBlocks(bodyEl, skip: const {'w:sectPr'});

    final styles = _parsePart(package, 'word/styles.xml', WpStyleSheet.parse,
        orElse: WpStyleSheet.new);
    final numbering = _parsePart(
        package, 'word/numbering.xml', WpNumbering.parse,
        orElse: WpNumbering.new);
    final settingsXml = package.partString('word/settings.xml');
    final settings = WpSettings.fromXml(settingsXml == null
        ? null
        : XmlDocument.parse(settingsXml).rootElement);

    final headers = <String, WpHeaderFooter>{};
    final footers = <String, WpHeaderFooter>{};
    if (section != null) {
      final rels = package.relationshipsFor(mainPart);
      for (final (refs, into, rootName) in [
        (section.headerReferences, headers, 'w:hdr'),
        (section.footerReferences, footers, 'w:ftr'),
      ]) {
        for (final ref in refs) {
          final rel = rels.byId(ref.relId);
          if (rel == null) {
            _notes.add('referência de header/footer sem rel: ${ref.relId}');
            continue;
          }
          final partName = package.resolveTarget(mainPart, rel.target);
          final xml = package.partString(partName);
          if (xml == null) {
            _notes.add('parte de header/footer ausente: $partName');
            continue;
          }
          final root = XmlDocument.parse(xml).rootElement;
          if (root.qname != rootName) {
            _notes.add('raiz inesperada em $partName: ${root.qname}');
          }
          into[ref.type] =
              WpHeaderFooter(partName: partName, blocks: _parseBlocks(root));
        }
      }
    }

    return DocxFile(
      package: package,
      document: WpDocumentModel(body: body, section: section),
      styles: styles,
      numbering: numbering,
      settings: settings,
      mainPartName: mainPart,
      documentBodyPrefix: bodyPrefix,
      documentBodySuffix: bodySuffix,
      headersByType: headers,
      footersByType: footers,
      fidelityNotes: _notes,
    );
  }

  static T _parsePart<T>(
      OpcPackage package, String partName, T Function(String) parse,
      {required T Function() orElse}) {
    final xml = package.partString(partName);
    return xml == null ? orElse() : parse(xml);
  }

  // ---- Blocos ----

  List<WpBlock> _parseBlocks(XmlElement parent, {Set<String> skip = const {}}) {
    final blocks = <WpBlock>[];
    for (final child in parent.childElements) {
      if (skip.contains(child.qname)) continue;
      switch (child.qname) {
        case 'w:p':
          blocks.add(_parseParagraph(child));
        case 'w:tbl':
          blocks.add(_parseTable(child));
        case _:
          _notes.add('bloco preservado: ${child.qname}');
          blocks.add(WpPreservedBlock(child.qname, child.toXmlString()));
      }
    }
    return blocks;
  }

  WpParagraph _parseParagraph(XmlElement el) {
    WpParagraphProperties? properties;
    final inlines = <WpInline>[];
    for (final child in el.childElements) {
      switch (child.qname) {
        case 'w:pPr':
          properties = WpParagraphProperties.fromXml(child);
        case 'w:r':
          inlines.add(_parseRun(child));
        case 'w:hyperlink':
          inlines.add(WpHyperlink(
            relId: child.getAttribute('r:id'),
            anchor: child.getAttribute('w:anchor'),
            runs: [
              for (final run in child.childrenNamed('w:r')) _parseRun(run)
            ],
          ));
        case 'w:fldSimple':
          inlines.add(WpSimpleField(
            instruction: child.getAttribute('w:instr') ?? '',
            runs: [
              for (final run in child.childrenNamed('w:r')) _parseRun(run)
            ],
          ));
        case _:
          inlines.add(WpPreservedInline(child.qname, child.toXmlString()));
      }
    }
    return WpParagraph(
        properties: properties, inlines: inlines, sourceXml: el.toXmlString());
  }

  WpRun _parseRun(XmlElement el) {
    WpRunProperties? properties;
    final content = <WpRunContent>[];
    for (final child in el.childElements) {
      switch (child.qname) {
        case 'w:rPr':
          properties = WpRunProperties.fromXml(child);
        case 'w:t':
          content.add(WpText(child.text));
        case 'w:tab':
          content.add(WpTabChar());
        case 'w:br':
          content.add(WpBreak(child.getAttribute('w:type')));
        case 'w:cr':
          content.add(WpBreak());
        case 'w:noBreakHyphen':
          content.add(WpNoBreakHyphen());
        case 'w:softHyphen':
          break; // hífen opcional: invisível fora da quebra
        case 'w:sym':
          content.add(WpSymbol(
            font: child.getAttribute('w:font'),
            charHex: child.getAttribute('w:char'),
          ));
        case 'w:drawing':
          content.add(_parseDrawing(child));
        case 'w:fldChar':
          content
              .add(WpFieldChar(child.getAttribute('w:fldCharType') ?? 'begin'));
        case 'w:instrText':
          content.add(WpInstrText(child.text));
        case 'w:lastRenderedPageBreak':
          break; // marcador transiente do Word — recalculado pelo layout
        case 'mc:AlternateContent':
          // Shape com caixa de texto (carimbo). Se não for, cai no preserved.
          final tb = _parseTextBox(child);
          content.add(
              tb ?? WpPreservedRunContent(child.qname, child.toXmlString()));
        case _:
          content.add(WpPreservedRunContent(child.qname, child.toXmlString()));
      }
    }
    return WpRun(properties: properties, content: content);
  }

  /// Parseia um `mc:AlternateContent` que seja um shape com caixa de texto
  /// (`wps:wsp` + `w:txbxContent`), ex.: o carimbo do cabeçalho (F4.8).
  /// Retorna null (→ preserved) se não for uma caixa de texto.
  WpTextBox? _parseTextBox(XmlElement el) {
    XmlElement? wsp;
    for (final w in el.descendantsNamed('wps:wsp')) {
      wsp = w;
      break;
    }
    if (wsp == null) return null;
    XmlElement? txbx;
    for (final t in wsp.descendantsNamed('w:txbxContent')) {
      txbx = t;
      break;
    }
    if (txbx == null) return null;

    String? hAlign;
    int? offX, offY, cx, cy;
    XmlElement? anchor;
    for (final a in el.descendantsNamed('wp:anchor')) {
      anchor = a;
      break;
    }
    if (anchor != null) {
      final posH = anchor.firstChild('wp:positionH');
      hAlign = posH?.firstChild('wp:align')?.text.trim();
      offX = int.tryParse(posH?.firstChild('wp:posOffset')?.text.trim() ?? '');
      final posV = anchor.firstChild('wp:positionV');
      offY = int.tryParse(posV?.firstChild('wp:posOffset')?.text.trim() ?? '');
      final extent = anchor.firstChild('wp:extent');
      cx = int.tryParse(extent?.getAttribute('cx') ?? '');
      cy = int.tryParse(extent?.getAttribute('cy') ?? '');
    }

    int? borderW;
    String? borderColor, fillColor;
    final spPr = wsp.firstChild('wps:spPr');
    if (spPr != null) {
      final ln = spPr.firstChild('a:ln');
      borderW = int.tryParse(ln?.getAttribute('w') ?? '');
      if (ln != null) {
        for (final c in ln.descendantsNamed('a:srgbClr')) {
          borderColor = c.getAttribute('val');
          break;
        }
      }
      fillColor = spPr
          .firstChild('a:solidFill')
          ?.firstChild('a:srgbClr')
          ?.getAttribute('val');
    }

    return WpTextBox(
      positionHAlign: hAlign,
      offsetXEmu: offX,
      offsetYEmu: offY,
      extentCxEmu: cx,
      extentCyEmu: cy,
      borderWidthEmu: borderW,
      borderColorHex: borderColor,
      fillColorHex: fillColor,
      blocks: _parseBlocks(txbx),
      rawXml: el.toXmlString(),
    );
  }

  WpDrawing _parseDrawing(XmlElement el) {
    final inline = el.firstChild('wp:inline');
    final anchor = el.firstChild('wp:anchor');
    final container = inline ?? anchor;
    final extent = container?.firstChild('wp:extent');
    String? embed;
    for (final blip in el.descendantsNamed('a:blip')) {
      embed = blip.getAttribute('r:embed') ?? blip.getAttribute('r:link');
      if (embed != null) break;
    }
    if (anchor != null) {
      _notes.add('drawing flutuante (anchor) tratado como inline');
    }
    return WpDrawing(
      embedRelId: embed,
      widthEmu: double.tryParse(extent?.getAttribute('cx') ?? ''),
      heightEmu: double.tryParse(extent?.getAttribute('cy') ?? ''),
      isInline: inline != null,
      rawXml: el.toXmlString(),
    );
  }

  // ---- Tabela ----

  WpTable _parseTable(XmlElement el) {
    WpTableProperties? properties;
    final grid = <int>[];
    final rows = <WpTableRow>[];
    for (final child in el.childElements) {
      switch (child.qname) {
        case 'w:tblPr':
          properties = WpTableProperties.fromXml(child);
        case 'w:tblGrid':
          for (final col in child.childrenNamed('w:gridCol')) {
            grid.add(int.tryParse(col.getAttribute('w:w') ?? '') ?? 0);
          }
        case 'w:tr':
          rows.add(_parseRow(child));
        case _:
          _notes.add('filho de tabela ignorado: ${child.qname}');
      }
    }
    return WpTable(
        properties: properties,
        gridColumnsTwips: grid,
        rows: rows,
        sourceXml: el.toXmlString());
  }

  WpTableRow _parseRow(XmlElement el) {
    WpTableRowProperties? properties;
    final cells = <WpTableCell>[];
    for (final child in el.childElements) {
      switch (child.qname) {
        case 'w:trPr':
          properties = WpTableRowProperties.fromXml(child);
        case 'w:tc':
          WpTableCellProperties? tcPr;
          final tcPrEl = child.firstChild('w:tcPr');
          if (tcPrEl != null) {
            tcPr = WpTableCellProperties.fromXml(tcPrEl);
          }
          cells.add(WpTableCell(
            properties: tcPr,
            blocks: _parseBlocks(child, skip: const {'w:tcPr'}),
          ));
        case 'w:tblPrEx':
          _notes.add('tblPrEx ignorado em linha de tabela');
        case _:
          _notes.add('filho de linha ignorado: ${child.qname}');
      }
    }
    return WpTableRow(properties: properties, cells: cells);
  }
}
