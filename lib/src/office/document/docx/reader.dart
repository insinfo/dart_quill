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
  final bool _captureSourceXml;
  final Map<String, int>? _timings;

  DocxReader._({
    required bool captureSourceXml,
    Map<String, int>? timings,
  })  : _captureSourceXml = captureSourceXml,
        _timings = timings;

  /// [timings] is an opt-in diagnostic sink, in microseconds. Production
  /// callers pay no stopwatch/logging cost when it is omitted.
  static DocxFile read(
    Uint8List bytes, {
    bool captureSourceXml = true,
    Map<String, int>? timings,
  }) {
    final watch = timings == null ? null : (Stopwatch()..start());
    final file = DocxReader._(
      captureSourceXml: captureSourceXml,
      timings: timings,
    )._read(bytes);
    if (watch != null) {
      watch.stop();
      timings!['totalUs'] = watch.elapsedMicroseconds;
    }
    return file;
  }

  /// Variante cooperativa para a thread principal do browser.
  ///
  /// Cada parser continua sendo exatamente o mesmo do caminho síncrono, mas
  /// ZIP, XML principal, body, estilos, numeração, settings e regiões ficam em
  /// tarefas separadas. Isso evita somar todos os custos num único long task;
  /// [read] permanece a API de baixa latência para VM e persistência.
  static Future<DocxFile> readAsync(
    Uint8List bytes, {
    bool captureSourceXml = true,
    Map<String, int>? timings,
  }) async {
    final watch = timings == null ? null : (Stopwatch()..start());
    final file = await DocxReader._(
      captureSourceXml: captureSourceXml,
      timings: timings,
    )._readAsync(bytes);
    if (watch != null) {
      watch.stop();
      timings!['totalUs'] = watch.elapsedMicroseconds;
    }
    return file;
  }

  T _measure<T>(String name, T Function() operation) {
    final timings = _timings;
    if (timings == null) return operation();
    final watch = Stopwatch()..start();
    final result = operation();
    watch.stop();
    timings[name] = watch.elapsedMicroseconds;
    return result;
  }

  Future<T> _measureAsync<T>(
      String name, Future<T> Function() operation) async {
    final timings = _timings;
    if (timings == null) return operation();
    final watch = Stopwatch()..start();
    final result = await operation();
    watch.stop();
    timings[name] = watch.elapsedMicroseconds;
    return result;
  }

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
    final package = _measure('opcDecodeUs', () => OpcPackage.decode(bytes));
    final mainPart = package.mainDocumentPartName;

    final documentXml = package.partString(mainPart);
    if (documentXml == null) {
      throw FormatException('Parte principal ausente: $mainPart');
    }
    final documentRoot = _measure(
      'documentXmlParseUs',
      () => XmlDocument.parse(documentXml).rootElement,
    );
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

    final section = _measure(
      'sectionParseUs',
      () => WpSectionProperties.fromXml(bodyEl.firstChild('w:sectPr')),
    );
    final body = _measure(
      'bodyParseUs',
      () => _parseBlocks(bodyEl, skip: const {'w:sectPr'}),
    );

    final styles = _measure(
      'stylesParseUs',
      () => _parsePart(
        package,
        'word/styles.xml',
        WpStyleSheet.parse,
        orElse: WpStyleSheet.new,
      ),
    );
    final numbering = _measure(
      'numberingParseUs',
      () => _parsePart(
        package,
        'word/numbering.xml',
        WpNumbering.parse,
        orElse: WpNumbering.new,
      ),
    );
    final settings = _measure('settingsParseUs', () {
      final settingsXml = package.partString('word/settings.xml');
      return WpSettings.fromXml(settingsXml == null
          ? null
          : XmlDocument.parse(settingsXml).rootElement);
    });

    final headers = <String, WpHeaderFooter>{};
    final footers = <String, WpHeaderFooter>{};
    _measure('regionsParseUs', () {
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
    });

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

  Future<DocxFile> _readAsync(Uint8List bytes) async {
    final package = _measure('opcDecodeUs', () => OpcPackage.decode(bytes));
    await Future<void>.delayed(Duration.zero);
    final mainPart = package.mainDocumentPartName;

    final documentXml = package.partString(mainPart);
    if (documentXml == null) {
      throw FormatException('Parte principal ausente: $mainPart');
    }
    final documentRoot = await _measureAsync(
      'documentXmlParseUs',
      () async => (await XmlDocument.parseAsync(documentXml)).rootElement,
    );
    await Future<void>.delayed(Duration.zero);
    final bodyEl = documentRoot.firstChild('w:body');
    if (bodyEl == null) {
      throw const FormatException('document.xml sem <w:body>.');
    }

    final bodyOpen = documentXml.indexOf('<w:body>');
    final bodyClose = documentXml.lastIndexOf('</w:body>');
    if (bodyOpen < 0 || bodyClose < 0) {
      throw const FormatException(
          'document.xml com <w:body> em formato não suportado.');
    }
    final bodyPrefix = documentXml.substring(0, bodyOpen + '<w:body>'.length);
    final bodySuffix = documentXml.substring(bodyClose);

    final section = _measure(
      'sectionParseUs',
      () => WpSectionProperties.fromXml(bodyEl.firstChild('w:sectPr')),
    );
    await Future<void>.delayed(Duration.zero);
    final body = _measure(
      'bodyParseUs',
      () => _parseBlocks(bodyEl, skip: const {'w:sectPr'}),
    );
    await Future<void>.delayed(Duration.zero);

    final styles = _measure(
      'stylesParseUs',
      () => _parsePart(
        package,
        'word/styles.xml',
        WpStyleSheet.parse,
        orElse: WpStyleSheet.new,
      ),
    );
    await Future<void>.delayed(Duration.zero);
    final numbering = _measure(
      'numberingParseUs',
      () => _parsePart(
        package,
        'word/numbering.xml',
        WpNumbering.parse,
        orElse: WpNumbering.new,
      ),
    );
    await Future<void>.delayed(Duration.zero);
    final settings = _measure('settingsParseUs', () {
      final settingsXml = package.partString('word/settings.xml');
      return WpSettings.fromXml(settingsXml == null
          ? null
          : XmlDocument.parse(settingsXml).rootElement);
    });
    await Future<void>.delayed(Duration.zero);

    final headers = <String, WpHeaderFooter>{};
    final footers = <String, WpHeaderFooter>{};
    _measure('regionsParseUs', () {
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
    });
    await Future<void>.delayed(Duration.zero);

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
            fieldLockValue: child.getAttribute('w:fldLock'),
            dirtyValue: child.getAttribute('w:dirty'),
            runs: [
              for (final run in child.childrenNamed('w:r')) _parseRun(run)
            ],
          ));
        case _:
          inlines.add(WpPreservedInline(child.qname, child.toXmlString()));
      }
    }
    return WpParagraph(
      properties: properties,
      attributes: WpParagraphAttributes.fromXml(el),
      inlines: inlines,
      sourceXml: _captureSourceXml ? el.toXmlString() : null,
    );
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
          content.add(WpFieldChar(
            child.getAttribute('w:fldCharType') ?? 'begin',
            rawXml: child.toXmlString(),
          ));
        case 'w:instrText':
          content.add(WpInstrText(child.text, rawXml: child.toXmlString()));
        case 'w:lastRenderedPageBreak':
          // Cache de paginação do último layout do Word. Ele não é conteúdo
          // nem uma quebra manual, mas sua posição inline é a única pista
          // exata para reconstruir a fronteira original no primeiro render.
          // Preserve-o como run content opaco; o codec decide se o conjunto
          // é confiável e o writer o remove assim que o documento é editado.
          content.add(WpPreservedRunContent(child.qname, child.toXmlString()));
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

    String? hAlign, vRelativeFrom;
    int? offX, offY, cx, cy;
    String? wrapMode, wrapSide;
    int? distL, distT, distR, distB;
    XmlElement? anchor;
    for (final a in el.descendantsNamed('wp:anchor')) {
      anchor = a;
      break;
    }
    if (anchor != null) {
      final wrap = _wrapElementOf(anchor);
      // `wp:wrapNone` (ou a ausência de qualquer wrap) só diz que o texto não
      // desvia; quem separa "atrás" de "na frente" é `behindDoc` na âncora.
      final behind = anchor.getAttribute('behindDoc');
      wrapMode = switch (wrap?.qname) {
        'wp:wrapSquare' => 'square',
        'wp:wrapTight' => 'tight',
        'wp:wrapThrough' => 'through',
        'wp:wrapTopAndBottom' => 'topAndBottom',
        _ => behind == '1' || behind == 'true' ? 'behindText' : 'inFrontOfText',
      };
      wrapSide = wrap?.getAttribute('wrapText');
      distL = int.tryParse(
          wrap?.getAttribute('distL') ?? anchor.getAttribute('distL') ?? '');
      distT = int.tryParse(
          wrap?.getAttribute('distT') ?? anchor.getAttribute('distT') ?? '');
      distR = int.tryParse(
          wrap?.getAttribute('distR') ?? anchor.getAttribute('distR') ?? '');
      distB = int.tryParse(
          wrap?.getAttribute('distB') ?? anchor.getAttribute('distB') ?? '');
      final posH = anchor.firstChild('wp:positionH');
      hAlign = posH?.firstChild('wp:align')?.text.trim();
      offX = int.tryParse(posH?.firstChild('wp:posOffset')?.text.trim() ?? '');
      final posV = anchor.firstChild('wp:positionV');
      vRelativeFrom = posV?.getAttribute('relativeFrom');
      offY = int.tryParse(posV?.firstChild('wp:posOffset')?.text.trim() ?? '');
      final extent = anchor.firstChild('wp:extent');
      cx = int.tryParse(extent?.getAttribute('cx') ?? '');
      cy = int.tryParse(extent?.getAttribute('cy') ?? '');
    }

    int? insetLeft, insetTop, insetRight, insetBottom;
    final bodyPr = wsp.firstChild('wps:bodyPr');
    if (bodyPr != null) {
      insetLeft = int.tryParse(bodyPr.getAttribute('lIns') ?? '');
      insetTop = int.tryParse(bodyPr.getAttribute('tIns') ?? '');
      insetRight = int.tryParse(bodyPr.getAttribute('rIns') ?? '');
      insetBottom = int.tryParse(bodyPr.getAttribute('bIns') ?? '');
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
      positionVRelativeFrom: vRelativeFrom,
      offsetXEmu: offX,
      offsetYEmu: offY,
      extentCxEmu: cx,
      extentCyEmu: cy,
      insetLeftEmu: insetLeft,
      insetTopEmu: insetTop,
      insetRightEmu: insetRight,
      insetBottomEmu: insetBottom,
      borderWidthEmu: borderW,
      borderColorHex: borderColor,
      fillColorHex: fillColor,
      wrapMode: wrapMode,
      wrapSide: wrapSide,
      wrapDistLeftEmu: distL,
      wrapDistTopEmu: distT,
      wrapDistRightEmu: distR,
      wrapDistBottomEmu: distB,
      blocks: _parseBlocks(txbx),
      rawXml: el.toXmlString(),
    );
  }

  /// O elemento de disposição do texto de uma âncora DrawingML.
  ///
  /// A busca é entre os filhos DIRETOS: `wp:wrapPolygon` também tem `distL`,
  /// e uma varredura por descendentes acharia o polígono antes do wrap.
  static XmlElement? _wrapElementOf(XmlElement anchor) {
    const wrapNames = {
      'wp:wrapSquare',
      'wp:wrapTight',
      'wp:wrapThrough',
      'wp:wrapTopAndBottom',
      'wp:wrapNone',
    };
    for (final child in anchor.childElements) {
      if (wrapNames.contains(child.qname)) return child;
    }
    return null;
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
    final childOrder = <WpTableChildToken>[];
    for (final child in el.childElements) {
      switch (child.qname) {
        case 'w:tblPr':
          properties = WpTableProperties.fromXml(child);
          childOrder.add(const WpTableChildToken.properties());
        case 'w:tblGrid':
          for (final col in child.childrenNamed('w:gridCol')) {
            grid.add(int.tryParse(col.getAttribute('w:w') ?? '') ?? 0);
          }
          childOrder.add(const WpTableChildToken.grid());
        case 'w:tr':
          rows.add(_parseRow(child));
          childOrder.add(const WpTableChildToken.row());
        case _:
          _notes.add('filho de tabela preservado: ${child.qname}');
          childOrder.add(WpTableChildToken.preserved(
            child.qname,
            child.toXmlString(),
          ));
      }
    }
    return WpTable(
        properties: properties,
        gridColumnsTwips: grid,
        rows: rows,
        childOrder: childOrder,
        sourceXml: _captureSourceXml ? el.toXmlString() : null);
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
            sourceXml: _captureSourceXml ? child.toXmlString() : null,
          ));
        case 'w:tblPrEx':
          _notes.add('tblPrEx ignorado em linha de tabela');
        case _:
          _notes.add('filho de linha ignorado: ${child.qname}');
      }
    }
    return WpTableRow(
      properties: properties,
      cells: cells,
      sourceXml: _captureSourceXml ? el.toXmlString() : null,
    );
  }
}
