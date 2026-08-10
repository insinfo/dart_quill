import 'dart:typed_data';

import '../../ce_xml.dart';

import 'model.dart';
import 'reader.dart';

/// Writer DOCX (roteiro_editor_profissional, Fase 3).
///
/// Estratégia D1: blocos com [WpParagraph.sourceXml]/[WpTable.sourceXml]
/// preenchidos (intocados desde a leitura) são re-emitidos **byte a byte**;
/// blocos com `sourceXml == null` (editados/novos) são serializados a partir
/// do modelo. Metadados seguros explicitamente modelados (como ids do
/// paragrafo e rsids) acompanham o conteudo regenerado.
class DocxWriter {
  DocxWriter._();

  /// Gera o `document.xml` completo.
  static String buildDocumentXml(DocxFile file) {
    final buffer = StringBuffer(file.documentBodyPrefix);
    for (final block in file.document.body) {
      buffer.write(serializeBlock(block));
    }
    final section = file.document.section;
    if (section != null) {
      buffer.write(_sectionXml(section));
    }
    buffer.write(file.documentBodySuffix);
    return buffer.toString();
  }

  /// Monta o XML em fatias por bloco. Blocos preservados continuam sendo
  /// copiados verbatim; somente a entrega ao `StringBuffer` é cooperativa.
  static Future<String> buildDocumentXmlAsync(DocxFile file) async {
    final buffer = StringBuffer(file.documentBodyPrefix);
    final slice = Stopwatch()..start();
    for (final block in file.document.body) {
      buffer.write(serializeBlock(block));
      if (slice.elapsedMilliseconds >= 16) {
        await Future<void>.delayed(Duration.zero);
        slice
          ..reset()
          ..start();
      }
    }
    final section = file.document.section;
    if (section != null) {
      buffer.write(_sectionXml(section));
    }
    buffer.write(file.documentBodySuffix);
    return buffer.toString();
  }

  /// Serializa o pacote inteiro. Se nada mudou, o resultado é byte-idêntico
  /// ao arquivo aberto (passthrough integral do ZIP).
  static Uint8List write(
    DocxFile file, {
    bool invalidateRenderedPageBreaks = false,
  }) {
    var xml = buildDocumentXml(file);
    if (invalidateRenderedPageBreaks) {
      xml = _withoutLastRenderedPageBreaks(xml);
    }
    if (xml != file.package.partString(file.mainPartName)) {
      file.package.setPartString(file.mainPartName, xml);
    }
    return file.package.save();
  }

  /// Writer cooperativo usado pela UI. [timings] recebe microssegundos das
  /// duas fases para distinguir serialização OOXML de empacotamento ZIP.
  static Future<Uint8List> writeAsync(
    DocxFile file, {
    Map<String, int>? timings,
    bool invalidateRenderedPageBreaks = false,
  }) async {
    final xmlWatch = Stopwatch()..start();
    var xml = await buildDocumentXmlAsync(file);
    if (invalidateRenderedPageBreaks) {
      xml = _withoutLastRenderedPageBreaks(xml);
    }
    xmlWatch.stop();
    timings?['writerXmlUs'] = xmlWatch.elapsedMicroseconds;

    await Future<void>.delayed(Duration.zero);
    final source = file.package.partString(file.mainPartName);
    if (xml != source) {
      file.package.setPartString(file.mainPartName, xml);
    }

    await Future<void>.delayed(Duration.zero);
    final packageWatch = Stopwatch()..start();
    final bytes = file.package.save();
    packageWatch.stop();
    timings?['writerPackageUs'] = packageWatch.elapsedMicroseconds;
    return bytes;
  }

  static String _withoutLastRenderedPageBreaks(String xml) => xml.replaceAll(
        RegExp(r'<w:lastRenderedPageBreak\b[^>]*/>'),
        '',
      );

  // ---- Blocos ----

  static String serializeBlock(WpBlock block) => switch (block) {
        WpParagraph p => p.sourceXml ?? serializeParagraph(p),
        WpTable t => t.sourceXml ?? serializeTable(t),
        WpPreservedBlock preserved => preserved.xml,
      };

  static String serializeParagraph(WpParagraph paragraph) {
    final buffer = StringBuffer();
    final pPr = _paragraphProperties(paragraph.properties);
    final attributes = _paragraphAttributes(paragraph.attributes);
    if (attributes.isEmpty && pPr.isEmpty && paragraph.inlines.isEmpty) {
      return '<w:p/>';
    }
    buffer
      ..write('<w:p')
      ..write(attributes)
      ..write('>')
      ..write(pPr);
    for (final inline in paragraph.inlines) {
      switch (inline) {
        case WpRun run:
          buffer.write(serializeRun(run));
        case WpHyperlink link:
          buffer.write('<w:hyperlink');
          if (link.relId != null) {
            buffer.write(' r:id="${XmlEscape.attribute(link.relId!)}"');
          }
          if (link.anchor != null) {
            buffer.write(' w:anchor="${XmlEscape.attribute(link.anchor!)}"');
          }
          buffer.write('>');
          for (final run in link.runs) {
            buffer.write(serializeRun(run));
          }
          buffer.write('</w:hyperlink>');
        case WpSimpleField field:
          buffer.write('<w:fldSimple '
              'w:instr="${XmlEscape.attribute(field.instruction)}"');
          if (field.fieldLockValue != null) {
            buffer.write(
                ' w:fldLock="${XmlEscape.attribute(field.fieldLockValue!)}"');
          }
          if (field.dirtyValue != null) {
            buffer
                .write(' w:dirty="${XmlEscape.attribute(field.dirtyValue!)}"');
          }
          buffer.write('>');
          for (final run in field.runs) {
            buffer.write(serializeRun(run));
          }
          buffer.write('</w:fldSimple>');
        case WpPreservedInline preserved:
          buffer.write(preserved.xml);
      }
    }
    buffer.write('</w:p>');
    return buffer.toString();
  }

  static String _paragraphAttributes(WpParagraphAttributes? attributes) {
    if (attributes == null || attributes.isEmpty) return '';
    final buffer = StringBuffer();
    void write(String qname, String? value) {
      if (value == null) return;
      buffer.write(' $qname="${XmlEscape.attribute(value)}"');
    }

    write('w14:paraId', attributes.paraId);
    write('w14:textId', attributes.textId);
    for (final name in WpParagraphAttributes.revisionAttributeNames) {
      write(name, attributes.revisionIds[name]);
    }
    return buffer.toString();
  }

  static String serializeRun(WpRun run) {
    final buffer = StringBuffer('<w:r>');
    final rPr = _runProperties(run.properties);
    buffer.write(rPr);
    for (final content in run.content) {
      switch (content) {
        case WpText text:
          if (text.text.isEmpty) break;
          final needsPreserve = text.text.trim() != text.text;
          buffer
            ..write(needsPreserve ? '<w:t xml:space="preserve">' : '<w:t>')
            ..write(XmlEscape.text(text.text))
            ..write('</w:t>');
        case WpTabChar _:
          buffer.write('<w:tab/>');
        case WpBreak brk:
          buffer.write(brk.breakType == null
              ? '<w:br/>'
              : '<w:br w:type="${brk.breakType}"/>');
        case WpNoBreakHyphen _:
          buffer.write('<w:noBreakHyphen/>');
        case WpSymbol symbol:
          buffer.write('<w:sym');
          if (symbol.font != null) {
            buffer.write(' w:font="${XmlEscape.attribute(symbol.font!)}"');
          }
          if (symbol.charHex != null) {
            buffer.write(' w:char="${symbol.charHex}"');
          }
          buffer.write('/>');
        case WpDrawing drawing:
          buffer.write(drawing.rawXml);
        case WpTextBox textBox:
          // Caixa de texto (carimbo): re-emite o XML bruto (preservação D1).
          buffer.write(textBox.rawXml);
        case WpFieldChar fieldChar:
          buffer.write(fieldChar.rawXml ??
              '<w:fldChar w:fldCharType="${fieldChar.fldCharType}"/>');
        case WpInstrText instr:
          if (instr.rawXml != null) {
            buffer.write(instr.rawXml);
          } else {
            buffer
              ..write('<w:instrText xml:space="preserve">')
              ..write(XmlEscape.text(instr.text))
              ..write('</w:instrText>');
          }
        case WpPreservedRunContent preserved:
          buffer.write(preserved.xml);
      }
    }
    buffer.write('</w:r>');
    return buffer.toString();
  }

  // ---- Propriedades (ordem do schema OOXML) ----

  static String _paragraphProperties(WpParagraphProperties? pPr) {
    if (pPr == null) return '';
    final buffer = StringBuffer();
    if (pPr.styleId != null) {
      buffer.write('<w:pStyle w:val="${XmlEscape.attribute(pPr.styleId!)}"/>');
    }
    _writeOnOff(buffer, 'w:keepNext', pPr.keepNext);
    _writeOnOff(buffer, 'w:keepLines', pPr.keepLines);
    _writeOnOff(buffer, 'w:pageBreakBefore', pPr.pageBreakBefore);
    _writeOnOff(buffer, 'w:widowControl', pPr.widowControl);
    final numPr = pPr.numPr;
    if (numPr != null) {
      buffer.write('<w:numPr>');
      if (numPr.hasIlvl) {
        buffer.write('<w:ilvl w:val="${numPr.ilvl}"/>');
      }
      if (numPr.numId != null) {
        buffer.write('<w:numId w:val="${numPr.numId}"/>');
      }
      buffer.write('</w:numPr>');
    }
    if (pPr.borders != null) {
      buffer.write(_borders('w:pBdr', pPr.borders!));
    }
    if (pPr.shading != null) buffer.write(_shading(pPr.shading!));
    final tabs = pPr.tabs;
    if (tabs != null && tabs.isNotEmpty) {
      buffer.write('<w:tabs>');
      for (final tab in tabs) {
        buffer.write('<w:tab w:val="${tab.val}"');
        if (tab.leader != null) buffer.write(' w:leader="${tab.leader}"');
        buffer.write(' w:pos="${tab.posTwips}"/>');
      }
      buffer.write('</w:tabs>');
    }
    _writeOnOff(buffer, 'w:suppressAutoHyphens', pPr.suppressAutoHyphens);
    // CT_PPr ordena autoSpaceDN antes de spacing/ind.
    _writeOnOff(buffer, 'w:autoSpaceDN', pPr.autoSpaceDN);
    final spacing = pPr.spacing;
    if (spacing != null) {
      buffer.write('<w:spacing');
      if (spacing.beforeTwips != null) {
        buffer.write(' w:before="${spacing.beforeTwips}"');
      }
      if (spacing.afterTwips != null) {
        buffer.write(' w:after="${spacing.afterTwips}"');
      }
      if (spacing.line != null) buffer.write(' w:line="${spacing.line}"');
      if (spacing.lineRule != null) {
        buffer.write(' w:lineRule="${spacing.lineRule}"');
      }
      buffer.write('/>');
    }
    final indent = pPr.indent;
    if (indent != null) {
      buffer.write('<w:ind');
      if (indent.leftTwips != null) {
        buffer.write(' w:left="${indent.leftTwips}"');
      }
      if (indent.rightTwips != null) {
        buffer.write(' w:right="${indent.rightTwips}"');
      }
      if (indent.firstLineTwips != null) {
        buffer.write(' w:firstLine="${indent.firstLineTwips}"');
      }
      if (indent.hangingTwips != null) {
        buffer.write(' w:hanging="${indent.hangingTwips}"');
      }
      buffer.write('/>');
    }
    _writeOnOff(buffer, 'w:contextualSpacing', pPr.contextualSpacing);
    if (pPr.jc != null) buffer.write('<w:jc w:val="${pPr.jc}"/>');
    if (pPr.outlineLvl != null) {
      buffer.write('<w:outlineLvl w:val="${pPr.outlineLvl}"/>');
    }
    final markRPr = _runProperties(pPr.markRunProperties);
    buffer.write(markRPr);
    final sectionBreak = pPr.sectionBreak;
    if (sectionBreak != null) {
      buffer.write(_sectionXml(sectionBreak));
    }
    final content = buffer.toString();
    return content.isEmpty ? '' : '<w:pPr>$content</w:pPr>';
  }

  static String _runProperties(WpRunProperties? rPr) {
    if (rPr == null) return '';
    final buffer = StringBuffer();
    if (rPr.styleId != null) {
      buffer.write('<w:rStyle w:val="${XmlEscape.attribute(rPr.styleId!)}"/>');
    }
    if (rPr.fontAscii != null ||
        rPr.fontHAnsi != null ||
        rPr.fontEastAsia != null ||
        rPr.fontCs != null) {
      buffer.write('<w:rFonts');
      if (rPr.fontAscii != null) {
        buffer.write(' w:ascii="${XmlEscape.attribute(rPr.fontAscii!)}"');
      }
      if (rPr.fontHAnsi != null) {
        buffer.write(' w:hAnsi="${XmlEscape.attribute(rPr.fontHAnsi!)}"');
      }
      if (rPr.fontEastAsia != null) {
        buffer.write(' w:eastAsia="${XmlEscape.attribute(rPr.fontEastAsia!)}"');
      }
      if (rPr.fontCs != null) {
        buffer.write(' w:cs="${XmlEscape.attribute(rPr.fontCs!)}"');
      }
      buffer.write('/>');
    }
    _writeOnOff(buffer, 'w:b', rPr.bold);
    _writeOnOff(buffer, 'w:bCs', rPr.boldCs);
    _writeOnOff(buffer, 'w:i', rPr.italic);
    _writeOnOff(buffer, 'w:caps', rPr.caps);
    _writeOnOff(buffer, 'w:smallCaps', rPr.smallCaps);
    _writeOnOff(buffer, 'w:strike', rPr.strike);
    if (rPr.color != null) {
      buffer.write('<w:color w:val="${rPr.color}"/>');
    }
    if (rPr.sizeHalfPoints != null) {
      buffer.write('<w:sz w:val="${rPr.sizeHalfPoints}"/>');
      buffer.write('<w:szCs w:val="${rPr.sizeHalfPoints}"/>');
    }
    if (rPr.spacingTwips != null) {
      buffer.write('<w:spacing w:val="${rPr.spacingTwips}"/>');
    }
    if (rPr.highlight != null) {
      buffer.write('<w:highlight w:val="${rPr.highlight}"/>');
    }
    if (rPr.underline != null) {
      buffer.write('<w:u w:val="${rPr.underline}"/>');
    }
    if (rPr.shading != null) buffer.write(_shading(rPr.shading!));
    if (rPr.vertAlign != null) {
      buffer.write('<w:vertAlign w:val="${rPr.vertAlign}"/>');
    }
    final content = buffer.toString();
    return content.isEmpty ? '' : '<w:rPr>$content</w:rPr>';
  }

  static void _writeOnOff(StringBuffer buffer, String qname, bool? value) {
    if (value == null) return;
    buffer.write(value ? '<$qname/>' : '<$qname w:val="0"/>');
  }

  static String _shading(WpShading shd) {
    final buffer = StringBuffer('<w:shd');
    buffer.write(' w:val="${shd.val ?? 'clear'}"');
    buffer.write(' w:color="${shd.color ?? 'auto'}"');
    buffer.write(' w:fill="${shd.fill ?? 'auto'}"');
    buffer.write('/>');
    return buffer.toString();
  }

  static String _borders(String wrapper, WpBorders borders) {
    final buffer = StringBuffer('<$wrapper>');
    void side(String qname, WpBorder? border) {
      if (border == null) return;
      buffer.write('<$qname');
      if (border.val != null) buffer.write(' w:val="${border.val}"');
      if (border.sizeEighths != null) {
        buffer.write(' w:sz="${border.sizeEighths}"');
      }
      if (border.space != null) buffer.write(' w:space="${border.space}"');
      if (border.color != null) buffer.write(' w:color="${border.color}"');
      buffer.write('/>');
    }

    side('w:top', borders.top);
    side('w:left', borders.left);
    side('w:bottom', borders.bottom);
    side('w:right', borders.right);
    side('w:insideH', borders.insideH);
    side('w:insideV', borders.insideV);
    buffer.write('</$wrapper>');
    return buffer.toString();
  }

  static String _cellMargins(String wrapper, WpCellMargins margins) {
    final buffer = StringBuffer('<$wrapper>');
    void side(String qname, WpTableWidth? width) {
      if (width == null) return;
      buffer.write('<$qname w:w="${width.value ?? 0}" '
          'w:type="${width.type ?? 'dxa'}"/>');
    }

    side('w:top', margins.top);
    side('w:left', margins.left);
    side('w:bottom', margins.bottom);
    side('w:right', margins.right);
    buffer.write('</$wrapper>');
    return buffer.toString();
  }

  // ---- Tabela ----

  static String serializeTable(WpTable table) {
    final buffer = StringBuffer('<w:tbl>');
    final order = table.childOrder;
    if (order.isEmpty) {
      _writeTableProperties(buffer, table.properties);
      _writeTableGrid(buffer, table.gridColumnsTwips);
      for (final row in table.rows) {
        _writeTableRow(buffer, row);
      }
      buffer.write('</w:tbl>');
      return buffer.toString();
    }

    var propertiesWritten = false;
    var gridWritten = false;
    var rowIndex = 0;
    var remainingRowSlots =
        order.where((token) => token.kind == WpTableChildTokenKind.row).length;

    // A malformed/source-minimal table may omit one of the canonical slots.
    // Keep generated OOXML valid without disturbing normal source order.
    if (!order.any((token) => token.kind == WpTableChildTokenKind.properties)) {
      _writeTableProperties(buffer, table.properties);
      propertiesWritten = true;
    }
    if (!order.any((token) => token.kind == WpTableChildTokenKind.grid)) {
      _writeTableGrid(buffer, table.gridColumnsTwips);
      gridWritten = true;
    }

    for (final token in order) {
      switch (token.kind) {
        case WpTableChildTokenKind.properties:
          if (!propertiesWritten) {
            _writeTableProperties(buffer, table.properties);
            propertiesWritten = true;
          }
        case WpTableChildTokenKind.grid:
          if (!gridWritten) {
            _writeTableGrid(buffer, table.gridColumnsTwips);
            gridWritten = true;
          }
        case WpTableChildTokenKind.row:
          remainingRowSlots--;
          if (rowIndex < table.rows.length) {
            _writeTableRow(buffer, table.rows[rowIndex++]);
          }
          // Newly inserted rows belong before source metadata that originally
          // followed the final row (not after a trailing bookmarkEnd).
          if (remainingRowSlots == 0) {
            while (rowIndex < table.rows.length) {
              _writeTableRow(buffer, table.rows[rowIndex++]);
            }
          }
        case WpTableChildTokenKind.preserved:
          final xml = token.xml;
          if (xml != null) buffer.write(xml);
      }
    }
    while (rowIndex < table.rows.length) {
      _writeTableRow(buffer, table.rows[rowIndex++]);
    }
    buffer.write('</w:tbl>');
    return buffer.toString();
  }

  static void _writeTableProperties(
      StringBuffer buffer, WpTableProperties? tblPr) {
    buffer.write('<w:tblPr>');
    if (tblPr?.styleId != null) {
      buffer.write(
          '<w:tblStyle w:val="${XmlEscape.attribute(tblPr!.styleId!)}"/>');
    }
    final width = tblPr?.width;
    if (width != null) {
      buffer.write('<w:tblW w:w="${width.value ?? 0}" '
          'w:type="${width.type ?? 'auto'}"/>');
    }
    if (tblPr?.jc != null) buffer.write('<w:jc w:val="${tblPr!.jc}"/>');
    if (tblPr?.indentTwips != null) {
      buffer.write('<w:tblInd w:w="${tblPr!.indentTwips}" w:type="dxa"/>');
    }
    if (tblPr?.borders != null) {
      buffer.write(_borders('w:tblBorders', tblPr!.borders!));
    }
    if (tblPr?.layout != null) {
      buffer.write('<w:tblLayout w:type="${tblPr!.layout}"/>');
    }
    if (tblPr?.cellMargins != null) {
      buffer.write(_cellMargins('w:tblCellMar', tblPr!.cellMargins!));
    }
    if (tblPr?.tableLookXml != null) buffer.write(tblPr!.tableLookXml);
    buffer.write('</w:tblPr>');
  }

  static void _writeTableGrid(StringBuffer buffer, List<int> columns) {
    buffer.write('<w:tblGrid>');
    for (final col in columns) {
      buffer.write('<w:gridCol w:w="$col"/>');
    }
    buffer.write('</w:tblGrid>');
  }

  static void _writeTableRow(StringBuffer buffer, WpTableRow row) {
    if (row.sourceXml != null) {
      buffer.write(row.sourceXml);
      return;
    }
    buffer.write('<w:tr>');
    final trPr = row.properties;
    if (trPr != null &&
        (trPr.heightTwips != null ||
            trPr.tblHeader ||
            trPr.cantSplit ||
            trPr.gridBefore != null ||
            trPr.gridAfter != null ||
            trPr.widthBefore != null ||
            trPr.widthAfter != null ||
            trPr.jc != null)) {
      buffer.write('<w:trPr>');
      if (trPr.gridBefore != null) {
        buffer.write('<w:gridBefore w:val="${trPr.gridBefore}"/>');
      }
      if (trPr.gridAfter != null) {
        buffer.write('<w:gridAfter w:val="${trPr.gridAfter}"/>');
      }
      if (trPr.widthBefore != null) {
        buffer.write('<w:wBefore w:w="${trPr.widthBefore!.value ?? 0}" '
            'w:type="${trPr.widthBefore!.type ?? 'auto'}"/>');
      }
      if (trPr.widthAfter != null) {
        buffer.write('<w:wAfter w:w="${trPr.widthAfter!.value ?? 0}" '
            'w:type="${trPr.widthAfter!.type ?? 'auto'}"/>');
      }
      if (trPr.cantSplit) buffer.write('<w:cantSplit/>');
      if (trPr.heightTwips != null) {
        buffer.write('<w:trHeight');
        if (trPr.heightRule != null) {
          buffer.write(' w:hRule="${trPr.heightRule}"');
        }
        buffer.write(' w:val="${trPr.heightTwips}"/>');
      }
      if (trPr.jc != null) buffer.write('<w:jc w:val="${trPr.jc}"/>');
      if (trPr.tblHeader) buffer.write('<w:tblHeader/>');
      buffer.write('</w:trPr>');
    }
    for (final cell in row.cells) {
      _writeTableCell(buffer, cell);
    }
    buffer.write('</w:tr>');
  }

  static void _writeTableCell(StringBuffer buffer, WpTableCell cell) {
    if (cell.sourceXml != null) {
      buffer.write(cell.sourceXml);
      return;
    }
    buffer.write('<w:tc>');
    final tcPr = cell.properties;
    if (tcPr != null) {
      buffer.write('<w:tcPr>');
      final tcW = tcPr.width;
      if (tcW != null) {
        buffer.write('<w:tcW w:w="${tcW.value ?? 0}" '
            'w:type="${tcW.type ?? 'auto'}"/>');
      }
      if (tcPr.gridSpan != null) {
        buffer.write('<w:gridSpan w:val="${tcPr.gridSpan}"/>');
      }
      if (tcPr.vMerge != null) {
        buffer.write(tcPr.vMerge == 'restart'
            ? '<w:vMerge w:val="restart"/>'
            : '<w:vMerge/>');
      }
      if (tcPr.borders != null) {
        buffer.write(_borders('w:tcBorders', tcPr.borders!));
      }
      if (tcPr.shading != null) buffer.write(_shading(tcPr.shading!));
      if (tcPr.margins != null) {
        buffer.write(_cellMargins('w:tcMar', tcPr.margins!));
      }
      _writeOnOff(buffer, 'w:noWrap', tcPr.noWrap);
      if (tcPr.vAlign != null) {
        buffer.write('<w:vAlign w:val="${tcPr.vAlign}"/>');
      }
      _writeOnOff(buffer, 'w:hideMark', tcPr.hideMark);
      buffer.write('</w:tcPr>');
    }
    if (cell.blocks.isEmpty) {
      buffer.write('<w:p/>');
    } else {
      for (final block in cell.blocks) {
        buffer.write(serializeBlock(block));
      }
    }
    buffer.write('</w:tc>');
  }

  // ---- Seção ----

  static String _sectionXml(WpSectionProperties section) =>
      section.geometryOverridden
          ? serializeSection(section)
          : section.sourceXml ?? serializeSection(section);

  static String serializeSection(WpSectionProperties section) {
    if (section.geometryOverridden && section.sourceXml != null) {
      return _serializeSectionGeometryOverlay(section);
    }
    final buffer = StringBuffer('<w:sectPr>');
    for (final ref in section.headerReferences) {
      buffer.write('<w:headerReference w:type="${ref.type}" '
          'r:id="${XmlEscape.attribute(ref.relId)}"/>');
    }
    for (final ref in section.footerReferences) {
      buffer.write('<w:footerReference w:type="${ref.type}" '
          'r:id="${XmlEscape.attribute(ref.relId)}"/>');
    }
    buffer.write('<w:pgSz w:w="${section.pageWidthTwips ?? 11906}" '
        'w:h="${section.pageHeightTwips ?? 16838}"');
    if (section.orientation != null) {
      buffer.write(' w:orient="${section.orientation}"');
    }
    buffer.write('/>');
    buffer.write('<w:pgMar w:top="${section.marginTopTwips ?? 1440}" '
        'w:right="${section.marginRightTwips ?? 1800}" '
        'w:bottom="${section.marginBottomTwips ?? 1440}" '
        'w:left="${section.marginLeftTwips ?? 1800}" '
        'w:header="${section.headerDistanceTwips ?? 708}" '
        'w:footer="${section.footerDistanceTwips ?? 708}" '
        'w:gutter="${section.gutterTwips ?? 0}"/>');
    if (section.titlePage) buffer.write('<w:titlePg/>');
    if (section.documentGridType != null ||
        section.documentGridLinePitchTwips != null) {
      buffer.write('<w:docGrid');
      if (section.documentGridType != null) {
        buffer.write(' w:type="${section.documentGridType}"');
      }
      if (section.documentGridLinePitchTwips != null) {
        buffer.write(' w:linePitch="${section.documentGridLinePitchTwips}"');
      }
      buffer.write('/>');
    }
    buffer.write('</w:sectPr>');
    return buffer.toString();
  }

  /// Applies editable geometry to the parsed source element instead of
  /// rebuilding CT_SectPr. Unknown attributes and ordered ancillary children
  /// (for example `w:cols`, `w:pgNumType`, `w:type` and extensions) remain
  /// exactly where the source placed them.
  static String _serializeSectionGeometryOverlay(WpSectionProperties section) {
    final root = XmlDocument.parse(section.sourceXml!).rootElement;
    if (root.qname != 'w:sectPr') {
      throw const FormatException('sourceXml de seção não contém w:sectPr');
    }

    XmlElement ensureChild(String qname, Set<String> following) {
      final existing = root.firstChild(qname);
      if (existing != null) return existing;
      final created = XmlElement(qname);
      var index = root.children.length;
      for (var i = 0; i < root.children.length; i++) {
        final child = root.children[i];
        if (child is XmlElement && following.contains(child.qname)) {
          index = i;
          break;
        }
      }
      root.insert(index, created);
      return created;
    }

    void setIfPresent(XmlElement element, String qname, int? value) {
      if (value != null) element.setAttribute(qname, '$value');
    }

    final pgSz = ensureChild('w:pgSz', const {
      'w:pgMar',
      'w:paperSrc',
      'w:pgBorders',
      'w:lnNumType',
      'w:pgNumType',
      'w:cols',
      'w:formProt',
      'w:vAlign',
      'w:noEndnote',
      'w:titlePg',
      'w:textDirection',
      'w:bidi',
      'w:rtlGutter',
      'w:docGrid',
      'w:printerSettings',
      'w:sectPrChange',
    });
    setIfPresent(pgSz, 'w:w', section.pageWidthTwips);
    setIfPresent(pgSz, 'w:h', section.pageHeightTwips);
    if (section.orientation != null) {
      pgSz.setAttribute('w:orient', section.orientation!);
    }

    final pgMar = ensureChild('w:pgMar', const {
      'w:paperSrc',
      'w:pgBorders',
      'w:lnNumType',
      'w:pgNumType',
      'w:cols',
      'w:formProt',
      'w:vAlign',
      'w:noEndnote',
      'w:titlePg',
      'w:textDirection',
      'w:bidi',
      'w:rtlGutter',
      'w:docGrid',
      'w:printerSettings',
      'w:sectPrChange',
    });
    setIfPresent(pgMar, 'w:top', section.marginTopTwips);
    setIfPresent(pgMar, 'w:right', section.marginRightTwips);
    setIfPresent(pgMar, 'w:bottom', section.marginBottomTwips);
    setIfPresent(pgMar, 'w:left', section.marginLeftTwips);
    setIfPresent(pgMar, 'w:header', section.headerDistanceTwips);
    setIfPresent(pgMar, 'w:footer', section.footerDistanceTwips);
    setIfPresent(pgMar, 'w:gutter', section.gutterTwips);

    if (section.columnCount != null) {
      // As larguras individuais (`w:col`) ficam onde estavam: mudar a
      // CONTAGEM já invalida a divisão declarada, e o Word recalcula colunas
      // iguais quando `w:cols` não traz `w:col` coerente com `@num`. Apagar
      // os filhos aqui jogaria fora `w:equalWidth`/`w:sep` que o produtor
      // declarou e o editor não modela.
      final cols = ensureChild('w:cols', const {
        'w:formProt',
        'w:vAlign',
        'w:noEndnote',
        'w:titlePg',
        'w:textDirection',
        'w:bidi',
        'w:rtlGutter',
        'w:docGrid',
        'w:printerSettings',
        'w:sectPrChange',
      });
      cols.setAttribute('w:num', '${section.columnCount}');
      setIfPresent(cols, 'w:space', section.columnSpacingTwips);
    }

    if (section.documentGridType != null ||
        section.documentGridLinePitchTwips != null) {
      final docGrid = ensureChild('w:docGrid', const {
        'w:printerSettings',
        'w:sectPrChange',
      });
      if (section.documentGridType != null) {
        docGrid.setAttribute('w:type', section.documentGridType!);
      }
      setIfPresent(docGrid, 'w:linePitch', section.documentGridLinePitchTwips);
    }
    return root.toXmlString();
  }
}
