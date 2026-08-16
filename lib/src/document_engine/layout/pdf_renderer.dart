/// PdfRenderer — desenha um [PageGraph] em PDF (Fase 5).
///
/// A regra da arquitetura: o PDF NUNCA sai do DOM. Editor e PDF consomem o
/// MESMO PageGraph — este renderizador não decide layout nenhum, só
/// transcreve páginas, fragments e line boxes já compostos. Reusa o writer
/// PDF existente do pacote (xref, Flate, standard-14/WinAnsi; as fontes
/// embutidas CID entram quando o TextShaper chegar).
library;

import 'dart:typed_data';

import '../../office/document/pdf/pdf_cid_font.dart';
import '../../office/document/pdf/pdf_content.dart';
import '../../office/document/pdf/pdf_image.dart';
import '../../office/document/pdf/pdf_writer.dart';
import 'fonts.dart';
import 'page_graph.dart';
import 'pdf_standard_widths.dart';

double _twipsToPt(int twips) => twips / 20.0;

/// XObjects belong to one [PdfWriter], so the cache deliberately lives for
/// exactly one render. Reusing a renderer for `render` and `renderAsync` must
/// never reuse object ids from the previous PDF.
class _PdfImageRegistry {
  _PdfImageRegistry(this.writer);

  final PdfWriter writer;
  final Map<String, _PdfImageResource?> _byDataUri = {};

  _PdfImageResource? resolve(String dataUri) {
    if (_byDataUri.containsKey(dataUri)) return _byDataUri[dataUri];

    final decoded = decodeDataUrlImage(dataUri);
    if (decoded == null) {
      _byDataUri[dataUri] = null;
      return null;
    }

    final objectId = writer.addImage(decoded);
    final resource = _PdfImageResource('Im$objectId', objectId);
    _byDataUri[dataUri] = resource;
    return resource;
  }
}

class _PdfImageResource {
  const _PdfImageResource(this.name, this.objectId);

  final String name;
  final int objectId;
}

/// A floating text box is a page-level overlay in the DOM (`z-index:1`).
/// Keep its already-resolved anchor geometry while normal content is painted,
/// then draw it in a final pass so an opaque letterhead image cannot erase it.
class _PdfFloatingTextBoxPaint {
  const _PdfFloatingTextBoxPaint({
    required this.segment,
    required this.lineOriginX,
    required this.lineAvailable,
    required this.lineTop,
  });

  final LineSegment segment;
  final double lineOriginX;
  final double lineAvailable;
  final double lineTop;
}

bool _shouldPaintPdfBackground(String? rawColor) {
  if (rawColor == null) return false;
  final color = rawColor.trim().toLowerCase();
  if (color.isEmpty ||
      color == 'auto' ||
      color == '#auto' ||
      color == 'none' ||
      color == 'transparent') {
    return false;
  }

  // CSS accepts alpha-bearing colors while PDF has no implicit alpha in the
  // current content builder. A fully transparent background must remain a
  // no-op, matching the DOM instead of becoming an opaque RGB rectangle.
  if (RegExp(r'^#[0-9a-f]{4}$').hasMatch(color) && color.substring(4) == '0') {
    return false;
  }
  if (RegExp(r'^#[0-9a-f]{8}$').hasMatch(color) && color.endsWith('00')) {
    return false;
  }
  final rgba =
      RegExp(r'^rgba\([^,]+,[^,]+,[^,]+,\s*([0-9.]+)\s*\)$').firstMatch(color);
  if (rgba != null && (double.tryParse(rgba.group(1)!) ?? 1) <= 0) {
    return false;
  }
  return true;
}

class PageGraphPdfRenderer {
  PageGraphPdfRenderer({this.title = 'Documento', LayoutFontSet? fonts})
      : fonts = fonts ?? LayoutFontSet(const []);

  final String title;

  /// As MESMAS faces passadas ao composer: aqui elas são embutidas como
  /// CID/Identity-H com subset das runas que o grafo realmente usa.
  final LayoutFontSet fonts;

  final Map<LayoutFontFace, EmbeddedCidFont> _embedded = {};

  (LayoutFontFace, EmbeddedCidFont)? _faceAndCidFor(ResolvedRunStyle style) {
    final face =
        fonts.faceFor(style.family, bold: style.bold, italic: style.italic);
    if (face == null) return null;
    final embedded = _embedded[face];
    return embedded == null ? null : (face, embedded);
  }

  void _embedFonts(PdfWriter writer, PageGraph graph) {
    _embedded.clear();
    if (fonts.isEmpty) return;
    // Runas usadas POR FACE (o subset é por fonte embutida).
    final runesByFace = <LayoutFontFace, Set<int>>{};
    void collect(BlockFragment fragment) {
      ResolvedRunStyle? inferredMarkerStyle;
      for (final line in fragment.lines) {
        for (final segment in line.segments) {
          final textBox = segment.textBox;
          if (textBox != null && textBox.contentBlocks.isNotEmpty) {
            textBox.contentBlocks.forEach(collect);
            continue;
          }
          if (segment.hardBreak ||
              segment.isTab ||
              segment.isOpaqueInline ||
              segment.imageSrc != null) {
            continue;
          }
          final style = segment.style;
          inferredMarkerStyle ??= style;
          final face = fonts.faceFor(style.family,
              bold: style.bold, italic: style.italic);
          if (face == null) continue;
          runesByFace.putIfAbsent(face, () => <int>{})
            ..addAll(segment.text.runes)
            ..addAll((segment.textBox?.text ?? '').runes);
        }
      }
      final marker = fragment.marker;
      if (marker != null) {
        final style = fragment.markerStyle ??
            inferredMarkerStyle ??
            const ResolvedRunStyle(family: 'Arial', sizePt: 12);
        final face =
            fonts.faceFor(style.family, bold: style.bold, italic: style.italic);
        if (face != null) {
          runesByFace.putIfAbsent(face, () => <int>{})..addAll(marker.runes);
        }
      }
    }

    for (final page in graph.pages) {
      // As regiões contam para o subset: uma fonte usada só no timbre
      // precisa estar embutida, senão o cabeçalho sai em branco.
      page.header.forEach(collect);
      page.footer.forEach(collect);
      for (final fragment in page.fragments) {
        switch (fragment) {
          case BlockFragment():
            collect(fragment);
          case TableFragment():
            for (final row in fragment.rows) {
              for (final cell in row.cells) {
                if (cell.isMergeContinuation) continue;
                cell.blocks.forEach(collect);
              }
            }
        }
      }
    }

    var index = 1;
    runesByFace.forEach((face, runes) {
      final embedded = embedCidFont(
        writer,
        face.bytes,
        usedRunes: runes..addAll(' 0123456789.•'.runes),
        resourceName: 'TT$index',
      );
      writer.registerFontResource(embedded.resourceName, embedded.objectId);
      _embedded[face] = embedded;
      index++;
    });
  }

  Uint8List render(PageGraph graph) {
    final writer = PdfWriter();
    final images = _PdfImageRegistry(writer);
    _embedFonts(writer, graph);

    for (final page in graph.pages) {
      _addPage(writer, images, page);
    }

    return writer.build(title: title, producer: 'dart_quill office');
  }

  /// Variante cooperativa para a UI do navegador.
  ///
  /// A versão síncrona continua sendo a API de backend e produz os mesmos
  /// bytes. No browser, porém, um DOCX de 140 páginas não pode ocupar o
  /// isolate principal até o último stream ser comprimido. O writer é
  /// incremental, então cedemos a fila de eventos entre pequenos grupos de
  /// páginas sem recompor layout nem alterar o PDF.
  Future<Uint8List> renderAsync(
    PageGraph graph, {
    Map<String, int>? timings,
    Duration workBudget = const Duration(milliseconds: 8),
  }) async {
    final totalWatch = Stopwatch()..start();
    final writer = PdfWriter();
    final images = _PdfImageRegistry(writer);
    final embedWatch = Stopwatch()..start();
    _embedFonts(writer, graph);
    embedWatch.stop();

    final pageWatch = Stopwatch()..start();
    final sliceWatch = Stopwatch()..start();
    var maxPageUs = 0;
    var pageWorkUs = 0;
    var maxWorkSliceUs = 0;
    var cooperativeYields = 0;
    for (var index = 0; index < graph.pages.length; index++) {
      final onePage = Stopwatch()..start();
      _addPage(writer, images, graph.pages[index]);
      onePage.stop();
      pageWorkUs += onePage.elapsedMicroseconds;
      if (onePage.elapsedMicroseconds > maxPageUs) {
        maxPageUs = onePage.elapsedMicroseconds;
      }
      final shouldYield =
          index + 1 < graph.pages.length && sliceWatch.elapsed >= workBudget;
      if (shouldYield) {
        if (sliceWatch.elapsedMicroseconds > maxWorkSliceUs) {
          maxWorkSliceUs = sliceWatch.elapsedMicroseconds;
        }
        cooperativeYields++;
        await Future<void>.delayed(Duration.zero);
        sliceWatch
          ..reset()
          ..start();
      }
    }
    if (sliceWatch.elapsedMicroseconds > maxWorkSliceUs) {
      maxWorkSliceUs = sliceWatch.elapsedMicroseconds;
    }
    pageWatch.stop();

    final buildWatch = Stopwatch()..start();
    final bytes = writer.build(title: title, producer: 'dart_quill office');
    buildWatch.stop();
    totalWatch.stop();
    timings?.addAll({
      'totalUs': totalWatch.elapsedMicroseconds,
      'embedFontsUs': embedWatch.elapsedMicroseconds,
      'pageRenderUs': pageWatch.elapsedMicroseconds,
      'pageWorkUs': pageWorkUs,
      'writerBuildUs': buildWatch.elapsedMicroseconds,
      'cooperativeYields': cooperativeYields,
      'maxPageUs': maxPageUs,
      'maxWorkSliceUs': maxWorkSliceUs,
    });
    return bytes;
  }

  void _addPage(PdfWriter writer, _PdfImageRegistry images, PageLayout page) {
    final setup = page.setup;
    final pageHeightPt = _twipsToPt(setup.heightTwips);
    final builder = PdfContentBuilder(pageHeightPt: pageHeightPt, k: 1);
    final xObjects = <String, int>{};
    final floatingTextBoxes = <_PdfFloatingTextBoxPaint>[];
    final contentX = _twipsToPt(setup.marginLeftTwips);
    final contentTop = _twipsToPt(setup.marginTopTwips);
    final contentWidth = _twipsToPt(setup.contentWidthTwips);

    // Cabeçalho e rodapé são medidos a partir da BORDA da página, como no
    // Word — não a partir da margem do corpo. Eles entram primeiro no
    // content stream: uma imagem opaca que invade a margem não apaga texto
    // do corpo, que é pintado em seguida.
    final regionHeight =
        page.footer.fold<int>(0, (sum, fragment) => sum + fragment.heightTwips);
    for (final (fragments, top) in [
      (page.header, _twipsToPt(setup.headerDistanceTwips)),
      (
        page.footer,
        _twipsToPt(setup.heightTwips - setup.footerDistanceTwips - regionHeight)
      ),
    ]) {
      for (final fragment in fragments) {
        _renderBlock(
          writer,
          builder,
          fragment,
          x: contentX + _twipsToPt(fragment.indentTwips),
          top: top + _twipsToPt(fragment.yTwips),
          available: contentWidth - _twipsToPt(fragment.indentTwips),
          withMarker: false,
          images: images,
          xObjects: xObjects,
          floatingTextBoxes: floatingTextBoxes,
        );
      }
    }

    for (final fragment in page.fragments) {
      // Mesma resolução de coluna do DOM, pela mesma geometria da seção — é
      // o que garante que a exportação em PDF saia igual à tela num
      // documento de duas colunas.
      final columnX =
          _twipsToPt(page.setup.columnLeftTwips(fragment.columnIndex));
      final columnWidth = _twipsToPt(page.setup.columnWidthTwips);
      switch (fragment) {
        case BlockFragment():
          _renderBlock(
            writer,
            builder,
            fragment,
            x: contentX + columnX + _twipsToPt(fragment.indentTwips),
            top: contentTop + _twipsToPt(fragment.yTwips),
            available: columnWidth - _twipsToPt(fragment.indentTwips),
            withMarker: true,
            images: images,
            xObjects: xObjects,
            floatingTextBoxes: floatingTextBoxes,
          );
        case TableFragment():
          _renderTable(
              writer, images, xObjects, floatingTextBoxes, builder, fragment,
              contentX: contentX + columnX,
              top: contentTop + _twipsToPt(fragment.yTwips));
      }
    }

    // Match the DOM's positioned `z-index:1`: text boxes are overlays, not
    // ordinary inline paint. This is intentionally after header/footer,
    // images, tables and body text for the whole page.
    for (final paint in floatingTextBoxes) {
      _renderTextBox(
        writer,
        builder,
        paint.segment,
        lineOriginX: paint.lineOriginX,
        lineAvailable: paint.lineAvailable,
        lineTop: paint.lineTop,
        images: images,
        xObjects: xObjects,
      );
    }

    writer.addPage(
      widthPt: _twipsToPt(setup.widthTwips),
      heightPt: pageHeightPt,
      content: builder.build(),
      xObjects: xObjects,
    );
  }

  void _renderTable(
    PdfWriter writer,
    _PdfImageRegistry images,
    Map<String, int> xObjects,
    List<_PdfFloatingTextBoxPaint> floatingTextBoxes,
    PdfContentBuilder builder,
    TableFragment fragment, {
    required double contentX,
    required double top,
  }) {
    var y = top;
    for (final row in fragment.rows) {
      final rowHeight = _twipsToPt(row.heightTwips);
      for (final cell in row.cells) {
        if (cell.isMergeContinuation) continue;
        final x = contentX + _twipsToPt(cell.xTwips);
        final width = _twipsToPt(cell.widthTwips);
        final height = _twipsToPt(cell.heightTwips);
        if (_shouldPaintPdfBackground(cell.backgroundColor)) {
          builder.fillRect(x, y, width, height, cell.backgroundColor!);
        }
        _renderCellBorders(builder, cell.borders, x, y, width, height);
        for (final block in cell.blocks) {
          _renderBlock(
            writer,
            builder,
            block,
            x: x + _twipsToPt(block.indentTwips),
            top: y + _twipsToPt(block.yTwips + cell.contentOffsetTwips),
            available: width - _twipsToPt(block.indentTwips),
            withMarker: true,
            images: images,
            xObjects: xObjects,
            floatingTextBoxes: floatingTextBoxes,
          );
        }
      }
      y += rowHeight;
    }
  }

  /// Sombreamento e bordas do PARÁGRAFO, na mesma geometria do DOM.
  ///
  /// A caixa cobre só as LINHAS ([top] já vem depois do `spaceBefore`), e as
  /// arestas horizontais somem nas fatias interiores de um parágrafo partido
  /// entre páginas — é a mesma regra do `_blockDecoration` do renderer DOM,
  /// porque o PDF é projeção do MESMO grafo, não uma segunda composição.
  void _renderBlockDecoration(
    PdfContentBuilder builder,
    BlockFragment fragment, {
    required double x,
    required double top,
    required double available,
  }) {
    final borders = fragment.borders;
    final background = fragment.backgroundColor;
    if (background == null && borders == null) return;
    final heightTwips = fragment.heightTwips -
        fragment.spaceBeforeTwips -
        fragment.spaceAfterTwips;
    if (heightTwips <= 0) return;
    final height = _twipsToPt(heightTwips);
    final width = available - _twipsToPt(fragment.rightIndentTwips);
    if (width <= 0) return;

    if (_shouldPaintPdfBackground(background)) {
      builder.fillRect(x, top, width, height, background!);
    }
    if (borders == null) return;
    if (!fragment.continuesFromPreviousPage) {
      _strokeBorder(builder, borders.top, x, top, x + width, top);
    }
    if (!fragment.continuesOnNextPage) {
      _strokeBorder(
          builder, borders.bottom, x, top + height, x + width, top + height);
    }
    _strokeBorder(builder, borders.left, x, top, x, top + height);
    _strokeBorder(
        builder, borders.right, x + width, top, x + width, top + height);
  }

  void _renderCellBorders(PdfContentBuilder builder, TableCellBorders borders,
      double x, double y, double width, double height) {
    final sides = [borders.top, borders.right, borders.bottom, borders.left];
    final first = sides.first;
    if (first != null && sides.every((border) => _sameBorder(border, first))) {
      if (first.isVisible) {
        builder.strokeRect(x, y, width, height,
            color: first.color,
            widthPx: _twipsToPt(first.widthTwips),
            dashPx: _borderDash(first));
      }
      return;
    }
    _strokeBorder(builder, borders.top, x, y, x + width, y);
    _strokeBorder(builder, borders.right, x + width, y, x + width, y + height);
    _strokeBorder(
        builder, borders.bottom, x, y + height, x + width, y + height);
    _strokeBorder(builder, borders.left, x, y, x, y + height);
  }

  void _strokeBorder(PdfContentBuilder builder, TableBorder? border, double x1,
      double y1, double x2, double y2) {
    if (border == null || !border.isVisible) return;
    builder.strokeLine(x1, y1, x2, y2,
        color: border.color,
        widthPx: _twipsToPt(border.widthTwips),
        dashPx: _borderDash(border));
  }

  List<double>? _borderDash(TableBorder border) => switch (border.style) {
        'dotted' => [1, 2],
        'dashed' => [4, 2],
        _ => null,
      };

  bool _sameBorder(TableBorder? a, TableBorder b) =>
      a != null &&
      a.style == b.style &&
      a.widthTwips == b.widthTwips &&
      a.color == b.color;

  void _renderBlock(
    PdfWriter writer,
    PdfContentBuilder builder,
    BlockFragment fragment, {
    required double x,
    required double top,
    required double available,
    required bool withMarker,
    required _PdfImageRegistry images,
    required Map<String, int> xObjects,
    required List<_PdfFloatingTextBoxPaint> floatingTextBoxes,
  }) {
    var y = top + _twipsToPt(fragment.spaceBeforeTwips);
    _renderBlockDecoration(builder, fragment,
        x: x, top: y, available: available);
    if (withMarker && fragment.marker != null && fragment.lines.isEmpty) {
      final style = _markerStyle(fragment, null);
      final lineHeightTwips = fragment.heightTwips -
          fragment.spaceBeforeTwips -
          fragment.spaceAfterTwips;
      _renderMarker(
        writer,
        builder,
        fragment,
        style,
        x: x,
        baseline: y + _emptyMarkerBaselineOffset(style, lineHeightTwips),
      );
    }
    var firstLine = true;
    for (final line in fragment.lines) {
      final baseline = y + _twipsToPt(line.ascentTwips);
      // O recuo de primeira linha desloca o X; o recuo direito encolhe a
      // caixa em que center/right se apoiam — igual ao DOM.
      var cursorX = x + _twipsToPt(line.indentTwips);
      final lineOriginX = cursorX;
      final blockAvailable = available -
          _twipsToPt(line.indentTwips) -
          _twipsToPt(fragment.rightIndentTwips);
      // A exclusão do objeto flutuante encolhe a caixa em que o TEXTO se
      // apoia, mas não a do próprio objeto — senão a caixa se afastaria de
      // si mesma a cada recomposição.
      cursorX += _twipsToPt(line.wrapLeftInsetTwips);
      final lineAvailable = blockAvailable -
          _twipsToPt(line.wrapLeftInsetTwips) -
          _twipsToPt(line.wrapRightInsetTwips);
      final lineWidth = _twipsToPt(line.widthTwips);
      if (fragment.align == LayoutAlign.center) {
        cursorX += (lineAvailable - lineWidth) / 2;
      } else if (fragment.align == LayoutAlign.right) {
        cursorX += lineAvailable - lineWidth;
      }

      if (withMarker && firstLine && fragment.marker != null) {
        _renderMarker(
          writer,
          builder,
          fragment,
          _markerStyle(fragment, line),
          x: x,
          baseline: baseline,
        );
      }

      for (final segment in line.segments) {
        if (segment.hardBreak || segment.isOpaqueInline) continue;
        final style = segment.style;
        if (segment.textBox != null) {
          floatingTextBoxes.add(_PdfFloatingTextBoxPaint(
            segment: segment,
            lineOriginX: lineOriginX,
            lineAvailable: blockAvailable,
            lineTop: y,
          ));
          continue;
        }
        if (segment.isTab) {
          _renderTabLeader(builder, segment, cursorX, baseline);
          cursorX += _twipsToPt(segment.widthTwips);
          continue;
        }
        final imageSrc = segment.imageSrc;
        if (imageSrc != null) {
          final width = _twipsToPt(segment.widthTwips);
          final height =
              _twipsToPt(segment.imageHeightTwips ?? segment.widthTwips);
          final image = images.resolve(imageSrc);
          if (image != null && width > 0 && height > 0) {
            xObjects[image.name] = image.objectId;
            // O DOM projeta o mesmo segmento como `vertical-align:middle`.
            // A caixa da LineBox já inclui a altura da imagem, enquanto o
            // ascent continua sendo tipográfico; ancorar em baseline-height
            // faria imagens altas invadirem o parágrafo anterior. Centralizar
            // dentro da linha preserva a posição vertical decidida no grafo.
            final imageTop = y + (_twipsToPt(line.heightTwips) - height) / 2;
            builder.drawImage(
              image.name,
              cursorX,
              imageTop,
              width,
              height,
            );
          }
          // O U+FFFC em `text` existe apenas para offsets estáveis no modelo.
          // A caixa continua avançando mesmo se a data URI for inválida, mas
          // o caractere substituto jamais é enviado à fonte/PDF.
          cursorX += width;
          continue;
        }
        if (segment.text.isNotEmpty) {
          final adjustedWidth = _twipsToPt(segment.widthTwips) +
              _ordinarySpaceCount(segment.text) * line.wordSpacingTwips / 20.0;
          _drawRunText(writer, builder, segment.text, style,
              x: cursorX,
              baseline: baseline,
              wordSpacingTwips: line.wordSpacingTwips,
              // A caixa que o COMPOSITOR reservou para este run. Sem ela o
              // desenho com a standard-14 pode ser mais largo que a caixa e
              // invadir o run seguinte — ver `_drawRunText`.
              targetWidthPt: adjustedWidth);
          if (style.underline) {
            builder.strokeLine(
              cursorX,
              baseline + style.sizePt * 0.11,
              cursorX + adjustedWidth,
              baseline + style.sizePt * 0.11,
              color: style.color,
              widthPx: style.sizePt * 0.055,
            );
          }
          if (style.strike) {
            builder.strokeLine(
              cursorX,
              baseline - style.sizePt * 0.27,
              cursorX + adjustedWidth,
              baseline - style.sizePt * 0.27,
              color: style.color,
              widthPx: style.sizePt * 0.055,
            );
          }
          cursorX += adjustedWidth;
          continue;
        }
        cursorX += _twipsToPt(segment.widthTwips);
      }
      y += _twipsToPt(line.heightTwips);
      firstLine = false;
    }
  }

  ResolvedRunStyle _markerStyle(BlockFragment fragment, LineBox? line) =>
      fragment.markerStyle ??
      (line != null && line.segments.isNotEmpty
          ? line.segments.first.style
          : const ResolvedRunStyle(family: 'Arial', sizePt: 12));

  void _renderMarker(
    PdfWriter writer,
    PdfContentBuilder builder,
    BlockFragment fragment,
    ResolvedRunStyle style, {
    required double x,
    required double baseline,
  }) {
    final marker = fragment.marker;
    if (marker == null || marker.isEmpty) return;
    // [x] already includes indentTwips. markerPositionTwips, however, is
    // relative to the available box (the page body or the table cell), so
    // remove the text indent before applying the marker position.
    final markerX =
        x + _twipsToPt(fragment.markerPositionTwips - fragment.indentTwips);
    _drawRunText(
      writer,
      builder,
      marker,
      style,
      x: markerX,
      baseline: baseline,
    );
  }

  double _emptyMarkerBaselineOffset(
      ResolvedRunStyle style, int lineHeightTwips) {
    var lineHeight = _twipsToPt(lineHeightTwips);
    if (lineHeight <= 0) lineHeight = style.sizePt;
    final face =
        fonts.faceFor(style.family, bold: style.bold, italic: style.italic);
    final ascent = face?.ascentPt(style.sizePt) ?? style.sizePt * 0.8;
    final descent = face?.descentPt(style.sizePt) ?? style.sizePt * 0.2;
    final lineGap = face?.lineGapPt(style.sizePt) ?? 0;
    final naturalHeight = ascent + descent + lineGap;
    final centered = ascent + lineGap / 2 + (lineHeight - naturalHeight) / 2;
    return centered.clamp(0, lineHeight).toDouble();
  }

  /// Desenha um run na posição que o grafo decidiu.
  ///
  /// [targetWidthPt] é a largura que o COMPOSITOR reservou para o run. Ela
  /// importa porque as duas pontas podem usar fontes diferentes: o compositor
  /// mede com a face resolvida pelo `FontRegistry` (a Ecofont dos dois
  /// corpora PGCTIC resolve para Calibri/Carlito), enquanto o PDF sem faces
  /// embutidas desenha com a standard-14 (Helvetica), que é ~7% mais larga.
  /// Cada run era então desenhado mais largo que a caixa reservada e invadia
  /// o seguinte: no ETP o cabeçalho saía "Processo nº44505/2025" (sem o
  /// espaço) e o rodapé "P á g i n a2 | 19", porque o espaço final de um run
  /// era engolido pelo run seguinte. A diferença é absorvida no espaçamento
  /// entre caracteres (`Tc`), que é onde ela desaparece visualmente — as
  /// quebras de linha continuam sendo as que o compositor decidiu, e o texto
  /// passa a terminar exatamente na margem.
  ///
  /// Com face EMBUTIDA (CID) não há correção nenhuma a fazer: quem desenha é
  /// a mesma face que mediu.
  void _drawRunText(
    PdfWriter writer,
    PdfContentBuilder builder,
    String text,
    ResolvedRunStyle style, {
    required double x,
    required double baseline,
    double wordSpacingTwips = 0,
    double? targetWidthPt,
  }) {
    if (text.isEmpty) return;
    final pair = _faceAndCidFor(style);
    if (pair != null) {
      final (face, cid) = pair;
      builder.textCidTJ(
        fontResource: cid.resourceName,
        sizePx: style.sizePt,
        pieces: style.letterSpacingTwips == 0 && wordSpacingTwips == 0
            ? [
                for (final piece in face.shapeForTJ(text, cid.encodeText))
                  (piece.hex, piece.adjustThousandths)
              ]
            : _shapeCidWithSpacing(
                face,
                cid,
                text,
                style,
                wordSpacingTwips,
              ),
        x: x,
        baselineY: baseline,
        color: style.color,
      );
    } else {
      final font = standardFontFor(
          family: style.family, bold: style.bold, italic: style.italic);
      builder.text(
        fontResource: writer.fontResourceName(font),
        sizePx: style.sizePt,
        winAnsiText: encodeWinAnsi(text),
        x: x,
        baselineY: baseline,
        color: style.color,
        characterSpacingPx: _twipsToPt(style.letterSpacingTwips) +
            _standardFontFitPt(
                text, style, font, wordSpacingTwips, targetWidthPt),
        wordSpacingPx: wordSpacingTwips / 20.0,
      );
    }
  }

  double _standardFontFitPt(
    String text,
    ResolvedRunStyle style,
    String pdfFont,
    double wordSpacingTwips,
    double? targetWidthPt,
  ) =>
      officeStandard14FitPerCharPt(
        text: text,
        pdfFont: pdfFont,
        sizePt: style.sizePt,
        letterSpacingPt: _twipsToPt(style.letterSpacingTwips),
        wordSpacingPt: wordSpacingTwips / 20.0,
        targetWidthPt: targetWidthPt,
      );

  List<(String hex, int adjust)> _shapeCidWithSpacing(
    LayoutFontFace face,
    EmbeddedCidFont cid,
    String text,
    ResolvedRunStyle style,
    double wordSpacingTwips,
  ) {
    final pieces = <(String hex, int adjust)>[];
    final runes = text.runes.toList(growable: false);
    final buffer = StringBuffer();
    for (var i = 0; i < runes.length; i++) {
      final rune = runes[i];
      buffer.writeCharCode(rune);
      final next = i + 1 < runes.length ? runes[i + 1] : null;
      final kerning =
          next == null ? 0 : face.font.kerningBetweenChars(rune, next);
      final spacingTwips =
          style.letterSpacingTwips + (rune == 0x20 ? wordSpacingTwips : 0);
      final spacingThousandths = style.sizePt == 0
          ? 0
          : (spacingTwips / 20 / style.sizePt * 1000).round();
      // TJ positivo move o próximo glifo para a esquerda; portanto tanto o
      // kerning da face quanto espaçamento positivo entram com sinal oposto.
      final adjust = -kerning - spacingThousandths;
      if (adjust != 0) {
        pieces.add((cid.encodeText(buffer.toString()), adjust));
        buffer.clear();
      }
    }
    if (buffer.isNotEmpty) {
      pieces.add((cid.encodeText(buffer.toString()), 0));
    }
    return pieces;
  }

  int _ordinarySpaceCount(String text) {
    var count = 0;
    for (final rune in text.runes) {
      if (rune == 0x20) count++;
    }
    return count;
  }

  void _renderTabLeader(PdfContentBuilder builder, LineSegment segment,
      double x, double baseline) {
    final leader = segment.tabLeader?.toLowerCase();
    if (leader == null || leader == 'none') return;
    final width = _twipsToPt(segment.widthTwips);
    if (width <= 0) return;
    final dash = switch (leader) {
      'dot' || 'middledot' => <double>[1, 2],
      'hyphen' => <double>[4, 2],
      _ => null,
    };
    builder.strokeLine(
      x,
      baseline + 1.5,
      x + width,
      baseline + 1.5,
      color: segment.style.color,
      widthPx: 0.6,
      dashPx: dash,
    );
  }

  void _renderTextBox(
    PdfWriter writer,
    PdfContentBuilder builder,
    LineSegment segment, {
    required double lineOriginX,
    required double lineAvailable,
    required double lineTop,
    required _PdfImageRegistry images,
    required Map<String, int> xObjects,
  }) {
    final box = segment.textBox!;
    final width = _twipsToPt(box.widthTwips > 0 ? box.widthTwips : 1);
    final height = _twipsToPt(box.heightTwips > 0 ? box.heightTwips : 1);
    final offsetX = _twipsToPt(box.offsetXTwips);
    final left = switch (box.positionHAlign?.toLowerCase()) {
      'center' => lineOriginX + (lineAvailable - width) / 2 + offsetX,
      'right' => lineOriginX + lineAvailable - width + offsetX,
      _ => lineOriginX + offsetX,
    };
    final top = lineTop + _twipsToPt(box.offsetYTwips);
    if (_shouldPaintPdfBackground(box.backgroundColor)) {
      builder.fillRect(left, top, width, height, box.backgroundColor!);
    }
    if (box.borderWidthTwips > 0) {
      builder.strokeRect(left, top, width, height,
          color: box.borderColor, widthPx: _twipsToPt(box.borderWidthTwips));
    }
    if (box.contentBlocks.isNotEmpty) {
      final innerWidthTwips =
          box.widthTwips - box.insetLeftTwips - box.insetRightTwips;
      final innerHeightTwips =
          box.heightTwips - box.insetTopTwips - box.insetBottomTwips;
      if (innerWidthTwips <= 0 || innerHeightTwips <= 0) return;

      final innerLeft = left + _twipsToPt(box.insetLeftTwips);
      final innerTop = top + _twipsToPt(box.insetTopTwips);
      final nestedTextBoxes = <_PdfFloatingTextBoxPaint>[];
      for (final block in box.contentBlocks) {
        // The DOM clips the projected subtree to the DrawingML body box.
        // Whole blocks starting outside that box must likewise stay hidden.
        if (block.yTwips >= innerHeightTwips) break;
        final availableTwips = innerWidthTwips - block.indentTwips;
        if (availableTwips <= 0) continue;
        _renderBlock(
          writer,
          builder,
          block,
          x: innerLeft + _twipsToPt(block.indentTwips),
          top: innerTop + _twipsToPt(block.yTwips),
          available: _twipsToPt(availableTwips),
          withMarker: true,
          images: images,
          xObjects: xObjects,
          floatingTextBoxes: nestedTextBoxes,
        );
      }
      for (final paint in nestedTextBoxes) {
        _renderTextBox(
          writer,
          builder,
          paint.segment,
          lineOriginX: paint.lineOriginX,
          lineAvailable: paint.lineAvailable,
          lineTop: paint.lineTop,
          images: images,
          xObjects: xObjects,
        );
      }
      return;
    }

    // Compatibilidade com PageGraphs/snapshots anteriores à projeção rica.
    var baseline = top + segment.style.sizePt + 2;
    for (final line in box.text.split('\n')) {
      if (baseline > top + height) break;
      _drawRunText(writer, builder, line, segment.style,
          x: left + 2, baseline: baseline);
      baseline += segment.style.sizePt * 1.15;
    }
  }
}
