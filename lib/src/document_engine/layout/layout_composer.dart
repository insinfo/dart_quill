/// LayoutComposer — compõe o [PageGraph] a partir da árvore Office (Fase 5).
///
/// UM paginador, dois níveis de qualidade ([LayoutQuality]): `draft`
/// simplifica widow/orphan e tabelas; `fidelity` aplica as regras
/// completas. O documento, a seleção, os IDs e o snapshot NUNCA mudam com o
/// nível — só o refinamento do grafo.
///
/// Medição: [FontMetrics] embarcadas (as mesmas do exportador de PDF), a
/// autoridade de largura nas duas saídas — é o que garante que a linha do
/// editor e a do PDF quebram no mesmo lugar. O TextShaper (etapa 1:
/// latino/kerning/ligaturas) entra depois, atrás da mesma interface de
/// medição.
///
/// v1 cobre o perfil Quill: paragraph/heading/listItem/blockquote/codeBlock
/// com quebra por linha e fragmentação ENTRE páginas em granularidade de
/// LINHA (um parágrafo pode atravessar páginas — a limitação do exportador
/// Delta linear não existe aqui). Tabelas: granularidade de linha-de-tabela
/// no draft, com aviso; a fragmentação fina fica com o fidelity da Fase 6.
library;

import '../../office/document/fonts/font_metrics.dart';
import '../../office/document/fonts/font_registry.dart';
import '../model/index.dart';
import '../office/ids.dart';
import 'fonts.dart';
import 'page_graph.dart';

/// Converte pt→twips.
int _ptToTwips(double pt) => (pt * 20).round();

class LayoutComposer {
  LayoutComposer({
    this.setup = const PageSetupTwips(),
    this.quality = LayoutQuality.draft,
    this.baseFontFamily = 'Arial',
    this.baseFontSizePt = 12,
    LayoutFontSet? fonts,
  }) : fonts = fonts ?? LayoutFontSet(const []);

  final PageSetupTwips setup;
  final LayoutQuality quality;
  final String baseFontFamily;
  final double baseFontSizePt;

  /// Faces embutidas: quando presentes, a medição usa a hmtx REAL da face —
  /// a mesma que o renderer embute — e as duas saídas quebram igual.
  final LayoutFontSet fonts;

  /// Recuo por nível de lista, em twips (21,6 pt como o exportador linear).
  static const int _listIndentTwips = 432;

  PageGraph compose(PMNode doc) {
    final diagnostics = LayoutDiagnostics();
    final pages = <PageLayout>[];
    final mapEntries = <PositionMapEntry>[];

    var currentFragments = <PageFragment>[];
    var cursorTwips = 0;
    final capacity = setup.contentHeightTwips;

    void closePage() {
      pages.add(PageLayout(
        index: pages.length,
        setup: setup,
        fragments: currentFragments,
      ));
      currentFragments = [];
      cursorTwips = 0;
    }

    var listOrdinal = 0;

    doc.content.forEach((block, offset, index) {
      final docPos = offset + 1;
      final kind = block.type.name;

      if (kind == 'table') {
        listOrdinal = 0;
        final rows = _composeTableRows(block, diagnostics);
        var i = 0;
        var firstOfTable = true;
        while (i < rows.length) {
          final remaining = capacity - cursorTwips;
          var take = 0;
          var height = 0;
          while (i + take < rows.length &&
              height + rows[i + take].heightTwips <= remaining) {
            height += rows[i + take].heightTwips;
            take++;
          }
          if (take == 0) {
            if (cursorTwips == 0) {
              // Linha de tabela maior que a página: entra com corte estável.
              take = 1;
              height = rows[i].heightTwips;
              diagnostics.warnings
                  .add('linha de tabela mais alta que a página');
            } else {
              closePage();
              continue;
            }
          }
          final slice = rows.sublist(i, i + take);
          currentFragments.add(TableFragment(
            nodeId: officeNodeId(block),
            docPos: docPos,
            rows: slice,
            yTwips: cursorTwips,
            heightTwips: height,
            continuesFromPreviousPage: !firstOfTable,
            continuesOnNextPage: i + take < rows.length,
          ));
          mapEntries.add(PositionMapEntry(
            docPosStart: docPos,
            docPosEnd: docPos + block.nodeSize - 2,
            pageIndex: pages.length,
          ));
          cursorTwips += height;
          firstOfTable = false;
          i += take;
        }
        return;
      }

      // Estado da numeração de lista ordenada.
      if (kind == 'listItem' && block.attrs['kind'] == 'ordered') {
        listOrdinal++;
      } else if (kind != 'listItem') {
        listOrdinal = 0;
      }

      final blockStyle = _blockStyleOf(block, listOrdinal);
      final lines = _breakLines(
        block,
        setup.contentWidthTwips - blockStyle.indentTwips,
        blockStyle,
        diagnostics,
      );

      var firstLineOfBlock = true;
      var i = 0;
      while (i < lines.length) {
        final remaining = capacity - cursorTwips;
        // Quantas linhas cabem nesta página.
        var take = 0;
        var height = 0;
        while (i + take < lines.length &&
            height + lines[i + take].heightTwips <= remaining) {
          height += lines[i + take].heightTwips;
          take++;
        }
        if (take == 0) {
          if (cursorTwips == 0) {
            // Linha maior que a página inteira: entra mesmo assim (corte
            // estável, nunca loop) e o aviso registra a perda visual.
            take = 1;
            height = lines[i].heightTwips;
            diagnostics.warnings
                .add('linha mais alta que a página no nó ${block.type.name}');
          } else {
            closePage();
            continue;
          }
        }
        final slice = lines.sublist(i, i + take);
        currentFragments.add(BlockFragment(
          nodeId: officeNodeId(block),
          docPos: docPos,
          kind: kind,
          lines: slice,
          yTwips: cursorTwips,
          heightTwips: height,
          indentTwips: blockStyle.indentTwips,
          align: blockStyle.align,
          marker: firstLineOfBlock ? blockStyle.marker : null,
          continuesFromPreviousPage: !firstLineOfBlock,
          continuesOnNextPage: i + take < lines.length,
        ));
        mapEntries.add(PositionMapEntry(
          docPosStart: docPos + slice.first.charStart,
          docPosEnd: docPos + slice.last.charEnd,
          pageIndex: pages.length,
        ));
        cursorTwips += height;
        firstLineOfBlock = false;
        i += take;
      }
      if (lines.isEmpty) {
        // Bloco vazio: uma linha em branco na altura da fonte base.
        final blank = _lineHeightTwips(baseFontFamily, baseFontSizePt);
        if (cursorTwips + blank > capacity && currentFragments.isNotEmpty) {
          closePage();
        }
        currentFragments.add(BlockFragment(
          nodeId: officeNodeId(block),
          docPos: docPos,
          kind: kind,
          lines: const [],
          yTwips: cursorTwips,
          heightTwips: blank,
          align: blockStyle.align,
        ));
        mapEntries.add(PositionMapEntry(
          docPosStart: docPos,
          docPosEnd: docPos + block.nodeSize - 2,
          pageIndex: pages.length,
        ));
        cursorTwips += blank;
      }
    });

    if (currentFragments.isNotEmpty || pages.isEmpty) closePage();

    return PageGraph(
      pages: pages,
      positionMap: PositionMap(mapEntries),
      diagnostics: diagnostics,
      quality: quality,
    );
  }

  // -- Estilo de bloco -------------------------------------------------------

  _BlockStyle _blockStyleOf(PMNode block, int listOrdinal) {
    final align = switch (block.attrs['align']) {
      'center' => LayoutAlign.center,
      'right' => LayoutAlign.right,
      'justify' => LayoutAlign.justify,
      _ => LayoutAlign.left,
    };
    switch (block.type.name) {
      case 'heading':
        final level = (block.attrs['level'] as num?)?.toInt() ?? 1;
        final scale = switch (level) {
          1 => 2.0,
          2 => 1.5,
          3 => 1.17,
          4 => 1.0,
          5 => 0.83,
          _ => 0.67,
        };
        return _BlockStyle(
          align: align,
          baseSizePt: baseFontSizePt * scale,
          bold: true,
        );
      case 'listItem':
        final rawIndent = block.attrs['indent'];
        final level =
            rawIndent is num ? rawIndent.toInt() : int.tryParse('$rawIndent') ?? 0;
        final kind = block.attrs['kind'];
        return _BlockStyle(
          align: align,
          baseSizePt: baseFontSizePt,
          indentTwips: _listIndentTwips * (1 + level),
          marker: kind == 'ordered' ? '$listOrdinal. ' : '• ',
        );
      case 'blockquote':
        return _BlockStyle(
          align: align,
          baseSizePt: baseFontSizePt,
          indentTwips: _ptToTwips(14),
        );
      case 'codeBlock':
        return _BlockStyle(
          align: align,
          baseSizePt: baseFontSizePt,
          family: 'Courier New',
        );
      default:
        return _BlockStyle(align: align, baseSizePt: baseFontSizePt);
    }
  }

  // -- Quebra de linha -------------------------------------------------------

  FontMetrics _metricsFor(String family) =>
      FontRegistry.instance.lookup(family) ?? FontRegistry.instance.lookup(null)!;

  double _measurePt(ResolvedRunStyle style, String text) {
    final face =
        fonts.faceFor(style.family, bold: style.bold, italic: style.italic);
    if (face != null) return face.measureWidthPt(text, style.sizePt);
    return _metricsFor(style.family).measureWidth(text, style.sizePt);
  }

  ({double ascent, double descent}) _verticalPt(ResolvedRunStyle style) {
    final face =
        fonts.faceFor(style.family, bold: style.bold, italic: style.italic);
    if (face != null) {
      return (
        ascent: face.ascentPt(style.sizePt),
        descent: face.descentPt(style.sizePt),
      );
    }
    final m = _metricsFor(style.family);
    return (ascent: m.ascentPx(style.sizePt), descent: m.descentPx(style.sizePt));
  }

  int _lineHeightTwips(String family, double sizePt) {
    final v = _verticalPt(ResolvedRunStyle(family: family, sizePt: sizePt));
    return _ptToTwips(v.ascent + v.descent);
  }

  ResolvedRunStyle _styleOfText(PMNode text, _BlockStyle blockStyle) {
    var family = blockStyle.family ?? baseFontFamily;
    var sizePt = blockStyle.baseSizePt;
    var bold = blockStyle.bold;
    var italic = false, underline = false, strike = false;
    var color = '#000000';
    String? link;
    for (final mark in text.marks) {
      switch (mark.type.name) {
        case 'bold':
          bold = true;
        case 'italic':
          italic = true;
        case 'underline':
          underline = true;
        case 'strike':
          strike = true;
        case 'font':
          family = '${mark.attrs['value']}';
        case 'size':
          sizePt = _parseSizePt('${mark.attrs['value']}') ?? sizePt;
        case 'color':
          color = '${mark.attrs['value']}';
        case 'link':
          link = '${mark.attrs['href']}';
      }
    }
    return ResolvedRunStyle(
      family: family,
      sizePt: sizePt,
      bold: bold,
      italic: italic,
      underline: underline,
      strike: strike,
      color: color,
      link: link,
    );
  }

  static double? _parseSizePt(String value) {
    final match = RegExp(r'^([\d.]+)(pt|px)?$').firstMatch(value.trim());
    if (match == null) return null;
    final number = double.tryParse(match.group(1)!);
    if (number == null) return null;
    return match.group(2) == 'px' ? number * 0.75 : number;
  }

  /// Quebra o conteúdo inline de [block] em linhas de até [widthTwips].
  List<LineBox> _breakLines(
    PMNode block,
    int widthTwips,
    _BlockStyle blockStyle,
    LayoutDiagnostics diagnostics,
  ) {
    // Tokens (palavra/espaço) com estilo, mantendo o offset de caractere.
    final tokens = <_Token>[];
    var charOffset = 0;
    block.content.forEach((child, offset, index) {
      if (child.isText) {
        final style = _styleOfText(child, blockStyle);
        final text = child.text!;
        final re = RegExp(r'(\s+)|([^\s]+)');
        for (final m in re.allMatches(text)) {
          final piece = m.group(0)!;
          tokens.add(_Token(
            text: piece,
            style: style,
            isSpace: m.group(1) != null,
            widthTwips: _ptToTwips(_measurePt(style, piece)),
            charStart: charOffset + m.start,
          ));
        }
        charOffset += text.length;
      } else {
        // Embed inline (imagem etc.): v1 reserva uma caixa quadrada da
        // altura da linha; a medição real entra com o suporte a imagem.
        diagnostics.warnings
            .add('embed inline ${child.type.name} medido como caixa padrão');
        final style = ResolvedRunStyle(
            family: baseFontFamily, sizePt: baseFontSizePt);
        tokens.add(_Token(
          text: '￼',
          style: style,
          isSpace: false,
          widthTwips: _ptToTwips(baseFontSizePt),
          charStart: charOffset,
        ));
        charOffset += 1;
      }
    });

    final lines = <LineBox>[];
    var current = <_Token>[];
    var currentWidth = 0;

    void flush() {
      if (current.isEmpty) return;
      // Segmentos: funde tokens adjacentes com o mesmo estilo.
      final segments = <LineSegment>[];
      for (final token in current) {
        if (segments.isNotEmpty &&
            identical(segments.last.style, token.style)) {
          segments[segments.length - 1] = LineSegment(
            text: segments.last.text + token.text,
            style: segments.last.style,
            widthTwips: segments.last.widthTwips + token.widthTwips,
          );
        } else {
          segments.add(LineSegment(
            text: token.text,
            style: token.style,
            widthTwips: token.widthTwips,
          ));
        }
      }
      var ascent = 0, height = 0;
      for (final segment in segments) {
        final v = _verticalPt(segment.style);
        final a = _ptToTwips(v.ascent);
        final h = a + _ptToTwips(v.descent);
        if (a > ascent) ascent = a;
        if (h > height) height = h;
      }
      if (height == 0) {
        height = _lineHeightTwips(baseFontFamily, blockStyle.baseSizePt);
        ascent = height;
      }
      lines.add(LineBox(
        segments: segments,
        widthTwips: currentWidth,
        ascentTwips: ascent,
        heightTwips: height,
        charStart: current.first.charStart,
        charEnd: current.last.charStart + current.last.text.length,
      ));
      current = [];
      currentWidth = 0;
    }

    for (final token in tokens) {
      if (token.isSpace) {
        if (current.isEmpty) continue; // colapsa espaço no início da linha
        current.add(token);
        currentWidth += token.widthTwips;
        continue;
      }
      if (currentWidth + token.widthTwips > widthTwips && current.isNotEmpty) {
        flush();
      }
      if (token.widthTwips > widthTwips && current.isEmpty) {
        // Palavra maior que a coluna: corte duro por caracteres.
        var rest = token;
        while (rest.widthTwips > widthTwips && rest.text.length > 1) {
          var cut = rest.text.length - 1;
          while (cut > 1 &&
              _ptToTwips(_measurePt(
                      rest.style, rest.text.substring(0, cut))) >
                  widthTwips) {
            cut--;
          }
          final head = rest.text.substring(0, cut);
          current.add(_Token(
            text: head,
            style: rest.style,
            isSpace: false,
            widthTwips: _ptToTwips(_measurePt(rest.style, head)),
            charStart: rest.charStart,
          ));
          currentWidth += current.last.widthTwips;
          flush();
          rest = _Token(
            text: rest.text.substring(cut),
            style: rest.style,
            isSpace: false,
            widthTwips:
                _ptToTwips(_measurePt(rest.style, rest.text.substring(cut))),
            charStart: rest.charStart + cut,
          );
        }
        current.add(rest);
        currentWidth += rest.widthTwips;
        continue;
      }
      current.add(token);
      currentWidth += token.widthTwips;
    }
    flush();
    return lines;
  }
}

extension _TableComposition on LayoutComposer {
  /// Larguras de coluna em twips: `colWidths` verbatim (px → twips ×15) ou
  /// larguras das células, com reescala para caber na área útil — a mesma
  /// cascata P12 do exportador linear.
  List<int> _tableColumnWidths(PMNode table) {
    final available = setup.contentWidthTwips;
    var widths = <int>[];
    final colWidths = table.attrs['colWidths'];
    if (colWidths is List && colWidths.isNotEmpty) {
      for (final col in colWidths) {
        final raw = col is Map ? col['width'] : null;
        final px = raw is num ? raw.toDouble() : double.tryParse('$raw') ?? 72;
        widths.add((px * 15).round()); // 1 px = 0,75 pt = 15 twips
      }
    } else {
      // Da primeira linha: célula sem colspan define a coluna.
      final firstRow =
          table.content.size > 0 ? table.content.child(0) : null;
      if (firstRow != null) {
        firstRow.content.forEach((cell, _, __) {
          final cellMap = cell.attrs['cell'];
          final raw = cellMap is Map ? cellMap['width'] : null;
          final px = raw is num
              ? raw.toDouble()
              : double.tryParse('$raw') ?? 72;
          widths.add((px * 15).round());
        });
      }
    }
    if (widths.isEmpty) return [available];
    final total = widths.fold<int>(0, (a, b) => a + b);
    if (total > available && total > 0) {
      widths = widths
          .map((w) => (w * available / total).round())
          .toList();
    }
    return widths;
  }

  List<TableRowBox> _composeTableRows(
      PMNode table, LayoutDiagnostics diagnostics) {
    final columnWidths = _tableColumnWidths(table);
    const cellPaddingTwips = 60; // 3 pt
    final rows = <TableRowBox>[];
    table.content.forEach((row, _, __) {
      final cells = <TableCellBox>[];
      var x = 0;
      var column = 0;
      var rowHeight = 0;
      row.content.forEach((cell, ___, ____) {
        final width = column < columnWidths.length
            ? columnWidths[column]
            : columnWidths.last;
        final innerWidth = width - 2 * cellPaddingTwips;
        final blocks = <BlockFragment>[];
        var y = cellPaddingTwips;
        cell.content.forEach((inner, _____, offset) {
          final style = _blockStyleOf(inner, 0);
          final lines =
              _breakLines(inner, innerWidth, style, diagnostics);
          var height = 0;
          for (final line in lines) {
            height += line.heightTwips;
          }
          if (lines.isEmpty) {
            height = _lineHeightTwips(baseFontFamily, baseFontSizePt);
          }
          blocks.add(BlockFragment(
            nodeId: officeNodeId(inner),
            docPos: 0,
            kind: inner.type.name,
            lines: lines,
            yTwips: y,
            heightTwips: height,
            align: style.align,
          ));
          y += height;
        });
        final contentHeight = y + cellPaddingTwips;
        if (contentHeight > rowHeight) rowHeight = contentHeight;
        cells.add(TableCellBox(
          xTwips: x,
          widthTwips: width,
          blocks: blocks,
          contentHeightTwips: contentHeight,
        ));
        x += width;
        column++;
      });
      rows.add(TableRowBox(heightTwips: rowHeight, cells: cells));
    });
    return rows;
  }
}

class _BlockStyle {
  const _BlockStyle({
    required this.align,
    required this.baseSizePt,
    this.bold = false,
    this.indentTwips = 0,
    this.marker,
    this.family,
  });

  final LayoutAlign align;
  final double baseSizePt;
  final bool bold;
  final int indentTwips;
  final String? marker;
  final String? family;
}

class _Token {
  const _Token({
    required this.text,
    required this.style,
    required this.isSpace,
    required this.widthTwips,
    required this.charStart,
  });

  final String text;
  final ResolvedRunStyle style;
  final bool isSpace;
  final int widthTwips;
  final int charStart;
}
