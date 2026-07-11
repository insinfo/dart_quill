import 'dart:typed_data';

import '../../ce_xml.dart';

import 'model.dart';
import 'reader.dart';

/// Writer DOCX (roteiro_editor_profissional, Fase 3).
///
/// Estratégia D1: blocos com [WpParagraph.sourceXml]/[WpTable.sourceXml]
/// preenchidos (intocados desde a leitura) são re-emitidos **byte a byte**;
/// blocos com `sourceXml == null` (editados/novos) são serializados a partir
/// do modelo — sem `rsid`/`paraId` (o Word tolera).
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
      buffer.write(section.sourceXml ?? serializeSection(section));
    }
    buffer.write(file.documentBodySuffix);
    return buffer.toString();
  }

  /// Serializa o pacote inteiro. Se nada mudou, o resultado é byte-idêntico
  /// ao arquivo aberto (passthrough integral do ZIP).
  static Uint8List write(DocxFile file) {
    final xml = buildDocumentXml(file);
    if (xml != file.package.partString(file.mainPartName)) {
      file.package.setPartString(file.mainPartName, xml);
    }
    return file.package.save();
  }

  // ---- Blocos ----

  static String serializeBlock(WpBlock block) => switch (block) {
        WpParagraph p => p.sourceXml ?? serializeParagraph(p),
        WpTable t => t.sourceXml ?? serializeTable(t),
        WpPreservedBlock preserved => preserved.xml,
      };

  static String serializeParagraph(WpParagraph paragraph) {
    final buffer = StringBuffer();
    final pPr = _paragraphProperties(paragraph.properties);
    if (pPr.isEmpty && paragraph.inlines.isEmpty) {
      return '<w:p/>';
    }
    buffer
      ..write('<w:p>')
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
              'w:instr="${XmlEscape.attribute(field.instruction)}">');
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
          buffer.write('<w:fldChar w:fldCharType="${fieldChar.fldCharType}"/>');
        case WpInstrText instr:
          buffer
            ..write('<w:instrText xml:space="preserve">')
            ..write(XmlEscape.text(instr.text))
            ..write('</w:instrText>');
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
      if (numPr.ilvl != 0) {
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
    final content = buffer.toString();
    return content.isEmpty ? '' : '<w:pPr>$content</w:pPr>';
  }

  static String _runProperties(WpRunProperties? rPr) {
    if (rPr == null) return '';
    final buffer = StringBuffer();
    if (rPr.styleId != null) {
      buffer.write('<w:rStyle w:val="${XmlEscape.attribute(rPr.styleId!)}"/>');
    }
    if (rPr.fontAscii != null || rPr.fontHAnsi != null || rPr.fontCs != null) {
      buffer.write('<w:rFonts');
      if (rPr.fontAscii != null) {
        buffer.write(' w:ascii="${XmlEscape.attribute(rPr.fontAscii!)}"');
      }
      if (rPr.fontHAnsi != null) {
        buffer.write(' w:hAnsi="${XmlEscape.attribute(rPr.fontHAnsi!)}"');
      }
      if (rPr.fontCs != null) {
        buffer.write(' w:cs="${XmlEscape.attribute(rPr.fontCs!)}"');
      }
      buffer.write('/>');
    }
    _writeOnOff(buffer, 'w:b', rPr.bold);
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

  // ---- Tabela ----

  static String serializeTable(WpTable table) {
    final buffer = StringBuffer('<w:tbl>');
    final tblPr = table.properties;
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
    buffer.write('</w:tblPr>');

    buffer.write('<w:tblGrid>');
    for (final col in table.gridColumnsTwips) {
      buffer.write('<w:gridCol w:w="$col"/>');
    }
    buffer.write('</w:tblGrid>');

    for (final row in table.rows) {
      buffer.write('<w:tr>');
      final trPr = row.properties;
      if (trPr != null &&
          (trPr.heightTwips != null || trPr.tblHeader || trPr.cantSplit)) {
        buffer.write('<w:trPr>');
        if (trPr.cantSplit) buffer.write('<w:cantSplit/>');
        if (trPr.heightTwips != null) {
          buffer.write('<w:trHeight');
          if (trPr.heightRule != null) {
            buffer.write(' w:hRule="${trPr.heightRule}"');
          }
          buffer.write(' w:val="${trPr.heightTwips}"/>');
        }
        if (trPr.tblHeader) buffer.write('<w:tblHeader/>');
        buffer.write('</w:trPr>');
      }
      for (final cell in row.cells) {
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
          if (tcPr.vAlign != null) {
            buffer.write('<w:vAlign w:val="${tcPr.vAlign}"/>');
          }
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
      buffer.write('</w:tr>');
    }
    buffer.write('</w:tbl>');
    return buffer.toString();
  }

  // ---- Seção ----

  static String serializeSection(WpSectionProperties section) {
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
    buffer.write('</w:sectPr>');
    return buffer.toString();
  }
}
