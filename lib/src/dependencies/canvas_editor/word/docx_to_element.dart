// Conversor WordprocessingML → IElement[] do editor
// (roteiro_editor_profissional, F2.3).
//
// Mantém-se puro (sem dart:html): importa apenas as interfaces/enums do
// modelo do editor, para poder rodar em testes VM.

import 'dart:convert';

import '../ce_docx.dart';

import '../editor/dataset/enum/element.dart';
import '../editor/dataset/enum/row.dart';
import '../editor/dataset/enum/table/table.dart';
import '../editor/dataset/enum/title.dart';
import '../editor/dataset/enum/vertical_align.dart';
import '../editor/interface/element.dart';
import '../editor/interface/table/td.dart';

/// Resultado da conversão de um DOCX para o modelo do editor.
class DocxConversionResult {
  final List<IElement> header;
  final List<IElement> main;
  final List<IElement> footer;
  final double pageWidthPx;
  final double pageHeightPx;

  /// Margens em px na ordem do editor: [top, right, bottom, left].
  final List<double> marginsPx;

  /// Distâncias de header/footer do `w:pgMar` (px).
  final double headerDistancePx;
  final double footerDistancePx;

  /// Campos PAGE/NUMPAGES do rodapé (F4.7): formato no padrão do editor
  /// (`Página {pageNo} | {pageCount}`) + estilo do parágrafo do campo.
  /// `null` quando o rodapé não tem campos de página.
  final String? pageNumberFormat;
  final RowFlex? pageNumberRowFlex;
  final int? pageNumberSize;
  final String? pageNumberFont;
  final String? pageNumberColor;

  /// Caixas de texto flutuantes do cabeçalho (carimbos, F4.8).
  final List<DocxTextBox> headerTextBoxes;

  /// Notas de fidelidade (o que foi substituído/só preservado).
  final List<String> notes;

  DocxConversionResult({
    required this.header,
    required this.main,
    required this.footer,
    this.headerTextBoxes = const [],
    required this.pageWidthPx,
    required this.pageHeightPx,
    required this.marginsPx,
    required this.headerDistancePx,
    required this.footerDistancePx,
    this.pageNumberFormat,
    this.pageNumberRowFlex,
    this.pageNumberSize,
    this.pageNumberFont,
    this.pageNumberColor,
    required this.notes,
  });
}

/// Caixa de texto flutuante convertida (carimbo, F4.8): conteúdo já em
/// IElement[] + geometria em px para o render posicionar/desenhar a borda.
class DocxTextBox {
  final List<IElement> elements;
  final bool alignRight;
  final double offsetYPx;
  final double widthPx;
  final double heightPx;
  final String? borderColor;
  final double borderWidthPx;
  final String? fillColor;

  DocxTextBox({
    required this.elements,
    required this.alignRight,
    required this.offsetYPx,
    required this.widthPx,
    required this.heightPx,
    required this.borderColor,
    required this.borderWidthPx,
    required this.fillColor,
  });
}

/// Cores de `w:highlight` → hex CSS.
const Map<String, String> _highlightColors = {
  'yellow': '#FFFF00',
  'green': '#00FF00',
  'cyan': '#00FFFF',
  'magenta': '#FF00FF',
  'blue': '#0000FF',
  'red': '#FF0000',
  'darkBlue': '#00008B',
  'darkCyan': '#008B8B',
  'darkGreen': '#006400',
  'darkMagenta': '#8B008B',
  'darkRed': '#8B0000',
  'darkYellow': '#808000',
  'darkGray': '#A9A9A9',
  'lightGray': '#D3D3D3',
  'black': '#000000',
  'white': '#FFFFFF',
};

class DocxToElementConverter {
  final DocxFile file;
  final FormatResolver _resolver;
  final NumberingCounters _counters;
  final List<String> _notes = [];
  final List<DocxTextBox> _textBoxes = [];

  DocxToElementConverter._(this.file)
      : _resolver = FormatResolver(file.styles),
        _counters = NumberingCounters(file.numbering);

  static DocxConversionResult convert(DocxFile file) =>
      DocxToElementConverter._(file)._convert();

  DocxConversionResult _convert() {
    final mainPart = file.package.mainDocumentPartName;
    final main = _convertBlocks(file.document.body,
        fromPart: mainPart, stampBlocks: true);

    // Descarta text boxes coletadas no corpo (não renderizadas ainda); só as do
    // cabeçalho são posicionadas (F4.8).
    _textBoxes.clear();
    final headerBlocks = file.headersByType['default'];
    final footerBlocks = file.footersByType['default'];
    final header = headerBlocks == null
        ? <IElement>[]
        : _convertBlocks(headerBlocks.blocks, fromPart: headerBlocks.partName);
    final headerTextBoxes = List<DocxTextBox>.from(_textBoxes);

    // F4.7: parágrafos do rodapé com campos PAGE/NUMPAGES viram o formato
    // dinâmico do pageNumber do editor (em vez do resultado em cache).
    final pageNumber =
        footerBlocks == null ? null : _extractPageNumber(footerBlocks);
    final footer = footerBlocks == null
        ? <IElement>[]
        : _convertFooterBlocks(footerBlocks.blocks, footerBlocks.partName,
            pageNumber?.paragraphs ?? const <WpParagraph>{});
    if (pageNumber != null) {
      _stripCachedPageNumberLines(footer);
    }
    if (file.headersByType.length > 1) {
      _notes.add('headers first/even convertidos apenas como default '
          '(seleção por tipo na Fase 4.6)');
    }

    final section = file.document.section;
    return DocxConversionResult(
      header: header,
      main: main,
      footer: footer,
      headerTextBoxes: headerTextBoxes,
      pageWidthPx: Units.twipToPx(section?.pageWidthTwips ?? 11906),
      pageHeightPx: Units.twipToPx(section?.pageHeightTwips ?? 16838),
      marginsPx: [
        Units.twipToPx(section?.marginTopTwips ?? 1440),
        Units.twipToPx(section?.marginRightTwips ?? 1800),
        Units.twipToPx(section?.marginBottomTwips ?? 1440),
        Units.twipToPx(section?.marginLeftTwips ?? 1800),
      ],
      headerDistancePx: Units.twipToPx(section?.headerDistanceTwips ?? 708),
      footerDistancePx: Units.twipToPx(section?.footerDistanceTwips ?? 708),
      pageNumberFormat: pageNumber?.format,
      pageNumberRowFlex: pageNumber?.rowFlex,
      pageNumberSize: pageNumber?.size,
      pageNumberFont: pageNumber?.font,
      pageNumberColor: pageNumber?.color,
      notes: _notes,
    );
  }

  /// Extrai dos parágrafos do rodapé o formato de numeração de página
  /// (`PAGE` → `{pageNo}`, `NUMPAGES` → `{pageCount}`).
  _PageNumberSpec? _extractPageNumber(WpHeaderFooter footer) {
    for (final block in footer.blocks) {
      if (block is! WpParagraph) continue;
      var hasField = false;
      final format = StringBuffer();
      var state = _FieldState.none;
      String instruction = '';
      WpRunProperties? styleRun;

      for (final inline in block.inlines) {
        switch (inline) {
          case WpSimpleField field:
            final instr = field.instruction.toUpperCase();
            if (instr.contains('NUMPAGES')) {
              format.write('{pageCount}');
              hasField = true;
            } else if (instr.contains('PAGE')) {
              format.write('{pageNo}');
              hasField = true;
            } else {
              for (final run in field.runs) {
                format.write(run.text);
                styleRun ??= _resolver.resolveRun(block, run.properties);
              }
            }
          case WpRun run:
            for (final content in run.content) {
              switch (content) {
                case WpFieldChar fieldChar:
                  switch (fieldChar.fldCharType) {
                    case 'begin':
                      state = _FieldState.instruction;
                      instruction = '';
                    case 'separate':
                      state = _FieldState.result;
                    case _: // end
                      final instr = instruction.toUpperCase();
                      if (instr.contains('NUMPAGES')) {
                        format.write('{pageCount}');
                        hasField = true;
                      } else if (instr.contains('PAGE')) {
                        format.write('{pageNo}');
                        hasField = true;
                      }
                      state = _FieldState.none;
                  }
                case WpInstrText instr:
                  if (state == _FieldState.instruction) {
                    instruction += instr.text;
                  }
                case WpText text:
                  if (state == _FieldState.none) {
                    format.write(text.text);
                    styleRun ??= _resolver.resolveRun(block, run.properties);
                  }
                case _:
                  break;
              }
            }
          case WpHyperlink link:
            for (final run in link.runs) {
              if (state == _FieldState.none) {
                format.write(run.text);
                styleRun ??= _resolver.resolveRun(block, run.properties);
              }
            }
          case WpPreservedInline _:
            break;
        }
      }

      if (!hasField) continue;
      final pPr = _resolver.resolveParagraph(block);
      final style = styleRun ?? _resolver.resolveRun(block, null);
      _notes.add('campos PAGE/NUMPAGES do rodapé renderizados '
          'dinamicamente (formato "${format.toString()}")');
      return _PageNumberSpec(
        format: format.toString(),
        rowFlex: _rowFlex(pPr.jc),
        size: style.sizeHalfPoints == null
            ? null
            : Units.halfPointToPx(style.sizeHalfPoints!).round(),
        font: style.fontAscii ?? style.fontHAnsi,
        color: _hexColor(style.color),
        paragraphs: {block},
      );
    }
    return null;
  }

  // ---- Blocos ----

  List<IElement> _convertBlocks(List<WpBlock> blocks,
      {required String fromPart, bool stampBlocks = false}) {
    final elements = <IElement>[];
    var first = true;
    for (var index = 0; index < blocks.length; index++) {
      final block = blocks[index];
      final startLength = elements.length;
      switch (block) {
        case WpParagraph paragraph:
          final pPr = _resolver.resolveParagraph(paragraph);
          if (!first) {
            elements.add(_paragraphBreak(paragraph, pPr));
          }
          elements.addAll(_convertParagraph(paragraph, pPr, fromPart));
          first = false;
        case WpTable table:
          if (!first) elements.add(IElement(value: '\n'));
          final converted = _convertTable(table, fromPart);
          if (converted != null) elements.add(converted);
          first = false;
        case WpPreservedBlock preserved:
          _notes.add('bloco preservado não renderizado: ${preserved.qname}');
      }
      if (stampBlocks) {
        for (var i = startLength; i < elements.length; i++) {
          _stampBlockIndex(elements[i], index);
        }
      }
    }
    return elements;
  }

  /// Converte os blocos do rodapé preservando o banner (imagem com logos/
  /// endereço) e removendo APENAS a última linha dos parágrafos que contêm o
  /// campo PAGE/NUMPAGES — essa linha ("Página X | Y") é renderizada
  /// dinamicamente pelo pageNumber do editor. Antes, o parágrafo inteiro era
  /// descartado, sumindo com o banner (rodapé ficava só com o número de página).
  List<IElement> _convertFooterBlocks(
      List<WpBlock> blocks, String fromPart, Set<WpParagraph> pageNumParas) {
    final result = <IElement>[];
    var first = true;
    for (final block in blocks) {
      switch (block) {
        case WpParagraph paragraph:
          final pPr = _resolver.resolveParagraph(paragraph);
          if (!first) result.add(_paragraphBreak(paragraph, pPr));
          var converted = _convertParagraph(paragraph, pPr, fromPart);
          if (pageNumParas.contains(paragraph)) {
            // A linha do número vem após o último <w:br> — corta a partir dele.
            var cut = converted.length;
            for (var i = converted.length - 1; i >= 0; i--) {
              if (converted[i].value == '\n') {
                cut = i;
                break;
              }
            }
            converted = converted.sublist(0, cut);
          }
          result.addAll(converted);
          first = false;
        case WpTable table:
          if (!first) result.add(IElement(value: '\n'));
          final t = _convertTable(table, fromPart);
          if (t != null) result.add(t);
          first = false;
        case WpPreservedBlock preserved:
          _notes.add('bloco de rodapé preservado não renderizado: '
              '${preserved.qname}');
      }
    }
    if (result.isEmpty) result.add(IElement(value: ''));
    return result;
  }

  /// Remove resultados em cache de PAGE/NUMPAGES que o Word deixa como texto
  /// visível ("Página 2 | 15"). A numeração real já é desenhada pelo
  /// PageNumber dinâmico do editor; manter o cache cria dois rodapés.
  void _stripCachedPageNumberLines(List<IElement> elements) {
    var lineStart = 0;
    for (var i = 0; i <= elements.length; i++) {
      final isBreak = i == elements.length || elements[i].value == '\n';
      if (!isBreak) continue;

      final lineEnd = i;
      final text = _lineText(elements, lineStart, lineEnd)
          .replaceAll('\u00a0', ' ')
          .trim();
      if (_looksLikeCachedPageNumber(text)) {
        final removeStart =
            lineStart > 0 && elements[lineStart - 1].value == '\n'
                ? lineStart - 1
                : lineStart;
        final removeEnd = i < elements.length ? i + 1 : i;
        elements.removeRange(removeStart, removeEnd);
        i = removeStart - 1;
        lineStart = removeStart;
        continue;
      }

      lineStart = i + 1;
    }

    if (elements.isEmpty) {
      elements.add(IElement(value: ''));
    }
  }

  String _lineText(List<IElement> elements, int start, int end) {
    final buffer = StringBuffer();
    for (var i = start; i < end; i++) {
      final element = elements[i];
      if (element.type == null ||
          element.type == ElementType.superscript ||
          element.type == ElementType.subscript ||
          element.type == ElementType.hyperlink) {
        buffer.write(element.value);
      }
      final children = element.valueList;
      if (children != null) {
        buffer.write(_lineText(children, 0, children.length));
      }
    }
    return buffer.toString();
  }

  bool _looksLikeCachedPageNumber(String text) {
    if (text.isEmpty) return false;
    return RegExp(r'^(?:Página|Page)\s+\d+\s*(?:\||/|de|of)\s*\d+$',
            caseSensitive: false)
        .hasMatch(text);
  }

  /// Marca o elemento (e descendentes) com o índice do bloco de origem no
  /// body — usado pelo bridge editor→docx para o passthrough D1 no save.
  static void _stampBlockIndex(IElement element, int index) {
    element.externalId ??= 'wp:$index';
    final children = element.valueList;
    if (children != null) {
      for (final child in children) {
        _stampBlockIndex(child, index);
      }
    }
    final trList = element.trList;
    if (trList != null) {
      for (final tr in trList) {
        for (final td in tr.tdList) {
          for (final child in td.value) {
            _stampBlockIndex(child, index);
          }
        }
      }
    }
  }

  /// Elemento '\n' que inicia a linha do parágrafo, carregando o alinhamento,
  /// o espaçamento efetivo do `w:spacing` e a FONTE efetiva do parágrafo
  /// (F4.3) — sem fonte o ZERO cairia no defaultFont da shell e a altura dele
  /// dominaria a primeira linha de cada parágrafo.
  IElement _paragraphBreak(WpParagraph paragraph, WpParagraphProperties pPr) {
    final style = _resolver.resolveRun(paragraph, null);
    final sizeHalf = style.sizeHalfPoints;
    final element = IElement(
      value: '\n',
      rowFlex: _rowFlex(pPr.jc),
      font: style.fontAscii ?? style.fontHAnsi,
      size: sizeHalf == null ? null : Units.halfPointToPx(sizeHalf).round(),
    );
    _applySpacing(element, _paraSpacing(pPr));
    return element;
  }

  // ---- Parágrafo ----

  List<IElement> _convertParagraph(
      WpParagraph paragraph, WpParagraphProperties pPr, String fromPart) {
    final rowFlex = _rowFlex(pPr.jc);
    final spacing = _paraSpacing(pPr);
    final elements = <IElement>[];

    // Numeração multinível → marcador textual inline (motor real na F4.2).
    final numPr = pPr.numPr;
    if (numPr != null && numPr.numId != null && numPr.numId != 0) {
      final marker = _counters.next(numPr.numId!, numPr.ilvl);
      if (marker != null && marker.isNotEmpty) {
        final markerStyle = _resolver.resolveRun(paragraph, null);
        elements.add(_styledText('$marker ', markerStyle, rowFlex, spacing)
          ..extension = const {'wpMarker': true});
      }
    }

    var fieldState = _FieldState.none;
    for (final inline in paragraph.inlines) {
      switch (inline) {
        case WpRun run:
          fieldState = _convertRun(
              paragraph, run, elements, fieldState, rowFlex, spacing,
              fromPart: fromPart);
        case WpHyperlink link:
          final valueList = <IElement>[];
          var linkFieldState = _FieldState.none;
          for (final run in link.runs) {
            linkFieldState = _convertRun(
                paragraph, run, valueList, linkFieldState, null, spacing,
                fromPart: fromPart);
          }
          if (valueList.isEmpty) break;
          final url = link.relId != null
              ? file.hyperlinkUrl(link.relId!, fromPart: fromPart)
              : (link.anchor != null ? '#${link.anchor}' : null);
          final hyperlink = IElement(
            type: ElementType.hyperlink,
            value: '',
            url: url ?? '',
            valueList: valueList,
            rowFlex: rowFlex,
          );
          _applySpacing(hyperlink, spacing);
          elements.add(hyperlink);
        case WpSimpleField field:
          // Campo simples: usa o resultado em cache (motor real na F4.7).
          _notes.add('fldSimple com resultado em cache: '
              '${field.instruction.trim()}');
          var innerState = _FieldState.none;
          for (final run in field.runs) {
            innerState = _convertRun(
                paragraph, run, elements, innerState, rowFlex, spacing,
                fromPart: fromPart);
          }
        case WpPreservedInline preserved:
          if (preserved.qname == 'mc:AlternateContent') {
            _notes.add('text box (carimbo) preservado, sem render '
                '(placeholder na Fase 4.8)');
          }
      }
    }

    // Título: outlineLvl efetivo vira TITLE (catálogo/navegação).
    final outline = pPr.outlineLvl;
    if (outline != null && outline >= 0 && elements.isNotEmpty) {
      final title = IElement(
        type: ElementType.title,
        value: '',
        level: _titleLevel(outline),
        valueList: elements,
        rowFlex: rowFlex,
      );
      _applySpacing(title, spacing);
      return [title];
    }
    return elements;
  }

  _FieldState _convertRun(
    WpParagraph paragraph,
    WpRun run,
    List<IElement> into,
    _FieldState fieldState,
    RowFlex? rowFlex,
    _ParaSpacing? spacing, {
    required String fromPart,
  }) {
    final rPr = _resolver.resolveRun(paragraph, run.properties);
    var state = fieldState;
    for (final content in run.content) {
      switch (content) {
        case WpFieldChar fieldChar:
          state = switch (fieldChar.fldCharType) {
            'begin' => _FieldState.instruction,
            'separate' => _FieldState.result,
            _ => _FieldState.none, // end
          };
        case WpInstrText instr:
          if (state == _FieldState.instruction) {
            _notes.add('campo com resultado em cache: ${instr.text.trim()} '
                '(motor de campos na Fase 4.7)');
          }
        case WpText text:
          // Dentro da instrução do campo o texto não é visível.
          if (state != _FieldState.instruction && text.text.isNotEmpty) {
            into.add(_styledText(text.text, rPr, rowFlex, spacing));
          }
        case WpTabChar _:
          final tab =
              IElement(type: ElementType.tab, value: '', rowFlex: rowFlex);
          _applySpacing(tab, spacing);
          into.add(tab);
        case WpBreak brk:
          if (brk.breakType == 'page') {
            into.add(IElement(type: ElementType.pageBreak, value: ''));
          } else {
            // Quebra de linha (w:br) ≠ fim de parágrafo: marcada para o
            // bridge editor→docx não dividir o parágrafo no save. Recebe o
            // line spacing (altura da linha), mas o layout NÃO aplica
            // before/after nela (guarda pelo extension wpBr).
            final br = IElement(value: '\n')..extension = const {'wpBr': true};
            _applySpacing(br, spacing);
            into.add(br);
          }
        case WpNoBreakHyphen _:
          into.add(_styledText('‑', rPr, rowFlex, spacing));
        case WpSymbol symbol:
          into.add(_styledText(_symbolChar(symbol), rPr, rowFlex, spacing));
        case WpDrawing drawing:
          final image = _convertDrawing(drawing, fromPart);
          if (image != null) into.add(image);
        case WpTextBox textBox:
          // Caixa de texto flutuante (carimbo, F4.8): não flui inline — é
          // coletada e renderizada como float posicionado (top-right do header).
          _notes.add('text box (carimbo) renderizado como caixa flutuante '
              '(edição direta fica para F4.8)');
          _textBoxes.add(_convertTextBox(textBox, fromPart));
        case WpPreservedRunContent preserved:
          if (preserved.qname == 'mc:AlternateContent' ||
              preserved.qname == 'w:pict') {
            _notes.add('shape preservado, sem render (Fase 4.8): '
                '${preserved.qname}');
          }
      }
    }
    return state;
  }

  /// Converte um [WpTextBox] em [DocxTextBox] renderizável: os blocos internos
  /// viram IElement[] e a geometria EMU vira px.
  DocxTextBox _convertTextBox(WpTextBox tb, String fromPart) {
    return DocxTextBox(
      elements: _convertBlocks(tb.blocks, fromPart: fromPart),
      alignRight: tb.positionHAlign == 'right',
      offsetYPx: tb.offsetYEmu == null ? 0 : Units.emuToPx(tb.offsetYEmu!),
      widthPx: tb.extentCxEmu == null ? 180 : Units.emuToPx(tb.extentCxEmu!),
      heightPx: tb.extentCyEmu == null ? 0 : Units.emuToPx(tb.extentCyEmu!),
      borderColor: tb.borderColorHex == null ? null : '#${tb.borderColorHex}',
      borderWidthPx:
          tb.borderWidthEmu == null ? 1 : Units.emuToPx(tb.borderWidthEmu!),
      fillColor: tb.fillColorHex == null ? null : '#${tb.fillColorHex}',
    );
  }

  IElement _styledText(String text, WpRunProperties rPr, RowFlex? rowFlex,
      _ParaSpacing? spacing) {
    final sizeHalf = rPr.sizeHalfPoints;
    final underline = rPr.underline;
    final highlight = rPr.highlight != null
        ? _highlightColors[rPr.highlight!]
        : _shadingFill(rPr.shading);
    final element = IElement(
      value: rPr.caps == true ? text.toUpperCase() : text,
      font: rPr.fontAscii ?? rPr.fontHAnsi,
      size: sizeHalf == null ? null : Units.halfPointToPx(sizeHalf).round(),
      bold: rPr.bold,
      italic: rPr.italic,
      underline: underline != null && underline != 'none' ? true : null,
      strikeout: rPr.strike,
      color: _hexColor(rPr.color),
      highlight: highlight,
      rowFlex: rowFlex,
    );
    _applySpacing(element, spacing);
    if (rPr.vertAlign == 'superscript') {
      element.type = ElementType.superscript;
    } else if (rPr.vertAlign == 'subscript') {
      element.type = ElementType.subscript;
    }
    return element;
  }

  IElement? _convertDrawing(WpDrawing drawing, String fromPart) {
    final relId = drawing.embedRelId;
    if (relId == null) {
      _notes.add('drawing sem blip embed ignorado');
      return null;
    }
    final bytes = file.imageBytes(relId, fromPart: fromPart);
    if (bytes == null) {
      _notes.add('imagem não encontrada para rel $relId de $fromPart');
      return null;
    }
    final contentType =
        file.imageContentType(relId, fromPart: fromPart) ?? 'image/png';
    if (!drawing.isInline) {
      _notes.add('imagem flutuante renderizada como inline (Fase 4)');
    }
    return IElement(
      type: ElementType.image,
      value: 'data:$contentType;base64,${base64Encode(bytes)}',
      width: drawing.widthEmu == null ? 100 : Units.emuToPx(drawing.widthEmu!),
      height:
          drawing.heightEmu == null ? 100 : Units.emuToPx(drawing.heightEmu!),
    )..extension = {'wpDrawing': drawing.rawXml};
  }

  // ---- Tabela ----

  IElement? _convertTable(WpTable table, String fromPart) {
    if (table.rows.isEmpty) return null;

    // Grid: larguras das colunas em px.
    final colgroup = [
      for (final twips in table.gridColumnsTwips)
        IColgroup(width: Units.twipToPx(twips))
    ];

    // Mapeia células a colunas do grid para resolver vMerge → rowspan.
    // startCols[r][i] = coluna inicial da célula i da linha r.
    final startCols = <List<int>>[];
    for (final row in table.rows) {
      final cols = <int>[];
      var col = 0;
      for (final cell in row.cells) {
        cols.add(col);
        col += cell.properties?.gridSpan ?? 1;
      }
      startCols.add(cols);
    }

    int rowspanOf(int rowIndex, int cellIndex) {
      final col = startCols[rowIndex][cellIndex];
      var span = 1;
      for (var r = rowIndex + 1; r < table.rows.length; r++) {
        final cells = table.rows[r].cells;
        var found = false;
        for (var i = 0; i < cells.length; i++) {
          if (startCols[r][i] != col) continue;
          if (cells[i].properties?.vMerge == 'continue') {
            span++;
            found = true;
          }
          break;
        }
        if (!found) break;
      }
      return span;
    }

    final trList = <ITr>[];
    for (var r = 0; r < table.rows.length; r++) {
      final row = table.rows[r];
      final trPr = row.properties;
      final heightPx =
          trPr?.heightTwips != null ? Units.twipToPx(trPr!.heightTwips!) : 40.0;
      final tdList = <ITd>[];
      for (var i = 0; i < row.cells.length; i++) {
        final cell = row.cells[i];
        final tcPr = cell.properties;
        if (tcPr?.vMerge == 'continue') continue; // absorvida pelo restart
        final value = _convertCellBlocks(cell.blocks, fromPart);
        tdList.add(ITd(
          colspan: tcPr?.gridSpan ?? 1,
          rowspan: tcPr?.vMerge == 'restart' ? rowspanOf(r, i) : 1,
          value: value,
          backgroundColor: _shadingFill(tcPr?.shading),
          verticalAlign: switch (tcPr?.vAlign) {
            'center' => VerticalAlign.middle,
            'bottom' => VerticalAlign.bottom,
            'top' => VerticalAlign.top,
            _ => null,
          },
          borderTypes: _borderTypes(tcPr?.borders),
        ));
      }
      if (tdList.isEmpty) continue;
      trList.add(ITr(
        height: heightPx.clamp(20.0, double.infinity),
        tdList: tdList,
        // OOXML: hRule ausente = atLeast; 'exact' aproximado como mínimo
        // (o modelo do editor não trunca conteúdo de célula). Sem trHeight,
        // 20px evita o piso de 42px do editor (defaultTrMinHeight) — o Word
        // dimensiona a linha pelo conteúdo (~21px para 1 linha de 12pt).
        minHeight: trPr?.heightTwips != null ? heightPx : 16.0,
        pagingRepeat: trPr?.tblHeader == true ? true : null,
      ));
    }
    if (trList.isEmpty) return null;

    // F4.5: bordas efetivas — tblBorders direto ou do estilo de tabela
    // (Grid Table Light etc.); sem bordas de tabela, as células desenham
    // as próprias bordas via borderTypes (TableBorder.empty).
    final effectiveBorders = _resolver.resolveTableBorders(table);
    bool visible(WpBorder? side) =>
        side != null &&
        side.val != null &&
        side.val != 'none' &&
        side.val != 'nil';
    final hasTableBorders = effectiveBorders != null &&
        (visible(effectiveBorders.top) ||
            visible(effectiveBorders.bottom) ||
            visible(effectiveBorders.left) ||
            visible(effectiveBorders.right) ||
            visible(effectiveBorders.insideH) ||
            visible(effectiveBorders.insideV));
    String? borderColor;
    if (hasTableBorders) {
      final sample = effectiveBorders.insideH ??
          effectiveBorders.top ??
          effectiveBorders.left;
      borderColor = _hexColor(sample?.color);
    }

    return IElement(
      type: ElementType.table,
      value: '',
      colgroup: colgroup,
      trList: trList,
      borderType: hasTableBorders ? TableBorder.all : TableBorder.empty,
      borderColor: borderColor,
    );
  }

  List<IElement> _convertCellBlocks(List<WpBlock> blocks, String fromPart) {
    // Tabela aninhada em célula não é suportada pelo modelo do editor:
    // achata o conteúdo textual e registra na nota de fidelidade.
    final flattened = <WpBlock>[];
    for (final block in blocks) {
      if (block is WpTable) {
        _notes.add('tabela aninhada achatada em célula (não suportada)');
        for (final row in block.rows) {
          for (final cell in row.cells) {
            flattened.addAll(cell.blocks);
          }
        }
      } else {
        flattened.add(block);
      }
    }
    final elements = _convertBlocks(flattened, fromPart: fromPart);
    if (elements.isEmpty) {
      elements.add(IElement(value: ''));
    }
    return elements;
  }

  List<TdBorder>? _borderTypes(WpBorders? borders) {
    if (borders == null) return null;
    bool visible(WpBorder? side) =>
        side != null &&
        side.val != null &&
        side.val != 'none' &&
        side.val != 'nil';
    final types = <TdBorder>[
      if (visible(borders.top)) TdBorder.top,
      if (visible(borders.right)) TdBorder.right,
      if (visible(borders.bottom)) TdBorder.bottom,
      if (visible(borders.left)) TdBorder.left,
    ];
    return types.isEmpty ? null : types;
  }

  // ---- Helpers de estilo ----

  static RowFlex? _rowFlex(String? jc) => switch (jc) {
        'center' => RowFlex.center,
        'right' || 'end' => RowFlex.right,
        'both' => RowFlex.alignment,
        'distribute' => RowFlex.justify,
        _ => null,
      };

  /// `w:spacing` efetivo → espaçamento Word-fiel (F4.3): rowMargin 0 (sem o
  /// padding fixo do editor), altura de linha pela fonte (auto = múltiplo de
  /// 240; atLeast/exact em twips → px, /15) e before/after em px.
  _ParaSpacing _paraSpacing(WpParagraphProperties pPr) {
    final spacing = pPr.spacing;
    // F4.2: o indent efetivo dos parágrafos numerados vem do w:ind do nível
    // de numeração (numbering.xml), com o pPr direto vencendo campo a campo.
    WpIndent? numIndent;
    final numPr = pPr.numPr;
    if (numPr != null && numPr.numId != null && numPr.numId != 0) {
      numIndent = file.numbering.levelOf(numPr.numId!, numPr.ilvl)?.indent;
    }
    final direct = pPr.indent;
    final int? leftTwips = direct?.leftTwips ?? numIndent?.leftTwips;
    final int? firstLineTwips =
        direct?.firstLineTwips ?? numIndent?.firstLineTwips;
    final int? hangingTwips = direct?.hangingTwips ?? numIndent?.hangingTwips;
    final line = spacing?.line;
    final rule = spacing?.lineRule ?? 'auto';
    String lineRule = 'auto';
    double lineValue = 1.0;
    if (line != null && line > 0) {
      if (rule == 'atLeast' || rule == 'exact') {
        lineRule = rule;
        lineValue = line / 15.0;
      } else {
        lineValue = line / 240.0;
      }
    }
    return _ParaSpacing(
      lineSpacingRule: lineRule,
      lineSpacingValue: lineValue,
      beforePx:
          spacing?.beforeTwips == null ? null : spacing!.beforeTwips! / 15.0,
      afterPx: spacing?.afterTwips == null ? null : spacing!.afterTwips! / 15.0,
      indentLeftPx: leftTwips == null ? null : leftTwips / 15.0,
      indentFirstLinePx: ((firstLineTwips ?? 0) - (hangingTwips ?? 0)) == 0
          ? null
          : ((firstLineTwips ?? 0) - (hangingTwips ?? 0)) / 15.0,
    );
  }

  static void _applySpacing(IElement element, _ParaSpacing? spacing) {
    if (spacing == null) return;
    element.rowMargin = 0;
    element.lineSpacingRule = spacing.lineSpacingRule;
    element.lineSpacingValue = spacing.lineSpacingValue;
    element.paraSpacingBefore = spacing.beforePx;
    element.paraSpacingAfter = spacing.afterPx;
    element.paraIndentLeft = spacing.indentLeftPx;
    element.paraIndentFirstLine = spacing.indentFirstLinePx;
  }

  static String? _hexColor(String? color) {
    if (color == null || color == 'auto') return null;
    return '#$color';
  }

  static String? _shadingFill(WpShading? shading) {
    final fill = shading?.fill;
    if (fill == null || fill == 'auto') return null;
    return '#$fill';
  }

  static TitleLevel _titleLevel(int outlineLvl) => switch (outlineLvl) {
        0 => TitleLevel.first,
        1 => TitleLevel.second,
        2 => TitleLevel.third,
        3 => TitleLevel.fourth,
        4 => TitleLevel.fifth,
        _ => TitleLevel.sixth,
      };

  static String _symbolChar(WpSymbol symbol) {
    final hex = symbol.charHex;
    if (hex == null) return '•';
    final code = int.tryParse(hex, radix: 16);
    if (code == null) return '•';
    return switch (code) {
      0xF0B7 => '•',
      0xF0A7 => '■',
      0xF06F => '○',
      0xF0FC => '✓',
      0xF0D8 => '➢',
      _ => code >= 0xF000 && code <= 0xF0FF ? '•' : String.fromCharCode(code),
    };
  }
}

enum _FieldState { none, instruction, result }

/// Especificação extraída do rodapé para o pageNumber do editor (F4.7).
class _PageNumberSpec {
  final String format;
  final RowFlex? rowFlex;
  final int? size;
  final String? font;
  final String? color;

  /// Parágrafos do rodapé representados pelo campo dinâmico (excluídos da
  /// conversão estática para não duplicar).
  final Set<WpParagraph> paragraphs;

  _PageNumberSpec({
    required this.format,
    this.rowFlex,
    this.size,
    this.font,
    this.color,
    required this.paragraphs,
  });
}

/// Espaçamento efetivo de parágrafo (F4.3) já convertido para o modelo do
/// editor: regra/valor de altura de linha + before/after em px.
class _ParaSpacing {
  final String lineSpacingRule; // 'auto' | 'atLeast' | 'exact'
  final double lineSpacingValue; // múltiplo (auto) ou px (atLeast/exact)
  final double? beforePx;
  final double? afterPx;
  final double? indentLeftPx;
  final double? indentFirstLinePx;

  const _ParaSpacing({
    required this.lineSpacingRule,
    required this.lineSpacingValue,
    this.beforePx,
    this.afterPx,
    this.indentLeftPx,
    this.indentFirstLinePx,
  });
}
