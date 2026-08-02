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
import '../../office/document/pdf/pdf_writer.dart';
import 'fonts.dart';
import 'page_graph.dart';

double _twipsToPt(int twips) => twips / 20.0;

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
      for (final line in fragment.lines) {
        for (final segment in line.segments) {
          final style = segment.style;
          final face = fonts.faceFor(style.family,
              bold: style.bold, italic: style.italic);
          if (face == null) continue;
          runesByFace.putIfAbsent(face, () => <int>{})
            ..addAll(segment.text.runes)
            ..addAll((fragment.marker ?? '').runes);
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
      writer.registerFontResource(
          embedded.resourceName, embedded.objectId);
      _embedded[face] = embedded;
      index++;
    });
  }

  Uint8List render(PageGraph graph) {
    final writer = PdfWriter();
    _embedFonts(writer, graph);

    for (final page in graph.pages) {
      final setup = page.setup;
      final pageHeightPt = _twipsToPt(setup.heightTwips);
      final builder = PdfContentBuilder(pageHeightPt: pageHeightPt, k: 1);
      final contentX = _twipsToPt(setup.marginLeftTwips);
      final contentTop = _twipsToPt(setup.marginTopTwips);
      final contentWidth = _twipsToPt(setup.contentWidthTwips);

      for (final fragment in page.fragments) {
        switch (fragment) {
          case BlockFragment():
            _renderBlock(
              writer,
              builder,
              fragment,
              x: contentX + _twipsToPt(fragment.indentTwips),
              top: contentTop + _twipsToPt(fragment.yTwips),
              available: contentWidth - _twipsToPt(fragment.indentTwips),
              withMarker: true,
            );
          case TableFragment():
            _renderTable(writer, builder, fragment,
                contentX: contentX,
                top: contentTop + _twipsToPt(fragment.yTwips));
        }
      }

      // Cabeçalho e rodapé são medidos a partir da BORDA da página, como no
      // Word — não a partir da margem do corpo.
      final regionHeight = page.footer
          .fold<int>(0, (sum, fragment) => sum + fragment.heightTwips);
      for (final (fragments, top) in [
        (page.header, _twipsToPt(setup.headerDistanceTwips)),
        (
          page.footer,
          _twipsToPt(setup.heightTwips -
              setup.footerDistanceTwips -
              regionHeight)
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
          );
        }
      }

      writer.addPage(
        widthPt: _twipsToPt(setup.widthTwips),
        heightPt: pageHeightPt,
        content: builder.build(),
      );
    }

    return writer.build(title: title, producer: 'dart_quill office');
  }

  void _renderTable(
    PdfWriter writer,
    PdfContentBuilder builder,
    TableFragment fragment, {
    required double contentX,
    required double top,
  }) {
    var y = top;
    for (final row in fragment.rows) {
      final rowHeight = _twipsToPt(row.heightTwips);
      for (final cell in row.cells) {
        final x = contentX + _twipsToPt(cell.xTwips);
        final width = _twipsToPt(cell.widthTwips);
        builder.strokeRect(x, y, width, rowHeight,
            color: '#000000', widthPx: 0.75);
        for (final block in cell.blocks) {
          _renderBlock(
            writer,
            builder,
            block,
            x: x + _twipsToPt(block.indentTwips) + 3,
            top: y + _twipsToPt(block.yTwips) + 3,
            available: width - _twipsToPt(block.indentTwips) - 6,
            withMarker: false,
          );
        }
      }
      y += rowHeight;
    }
  }

  void _renderBlock(
    PdfWriter writer,
    PdfContentBuilder builder,
    BlockFragment fragment, {
    required double x,
    required double top,
    required double available,
    required bool withMarker,
  }) {
    var y = top;
    var firstLine = true;
    for (final line in fragment.lines) {
      final baseline = y + _twipsToPt(line.ascentTwips);
      var cursorX = x;
      final lineWidth = _twipsToPt(line.widthTwips);
      if (fragment.align == LayoutAlign.center) {
        cursorX += (available - lineWidth) / 2;
      } else if (fragment.align == LayoutAlign.right) {
        cursorX += available - lineWidth;
      }

      if (withMarker && firstLine && fragment.marker != null) {
        final style = line.segments.isNotEmpty
            ? line.segments.first.style
            : const ResolvedRunStyle(family: 'Arial', sizePt: 12);
        final pair = _faceAndCidFor(style);
        if (pair != null) {
          final (face, cid) = pair;
          builder.textCidTJ(
            fontResource: cid.resourceName,
            sizePx: style.sizePt,
            pieces: [
              for (final piece
                  in face.shapeForTJ(fragment.marker!, cid.encodeText))
                (piece.hex, piece.adjustThousandths)
            ],
            x: x - style.sizePt * 1.4,
            baselineY: baseline,
            color: style.color,
          );
        } else {
          final font = standardFontFor(
              family: style.family, bold: style.bold, italic: style.italic);
          builder.text(
            fontResource: writer.fontResourceName(font),
            sizePx: style.sizePt,
            winAnsiText: encodeWinAnsi(fragment.marker!),
            x: x - style.sizePt * 1.4,
            baselineY: baseline,
            color: style.color,
          );
        }
      }

      for (final segment in line.segments) {
        final style = segment.style;
        if (segment.text.isNotEmpty) {
          final pair = _faceAndCidFor(style);
          if (pair != null) {
            final (face, cid) = pair;
            builder.textCidTJ(
              fontResource: cid.resourceName,
              sizePx: style.sizePt,
              pieces: [
                for (final piece
                    in face.shapeForTJ(segment.text, cid.encodeText))
                  (piece.hex, piece.adjustThousandths)
              ],
              x: cursorX,
              baselineY: baseline,
              color: style.color,
            );
          } else {
            final font = standardFontFor(
                family: style.family, bold: style.bold, italic: style.italic);
            builder.text(
              fontResource: writer.fontResourceName(font),
              sizePx: style.sizePt,
              winAnsiText: encodeWinAnsi(segment.text),
              x: cursorX,
              baselineY: baseline,
              color: style.color,
            );
          }
          if (style.underline) {
            builder.strokeLine(
              cursorX,
              baseline + style.sizePt * 0.11,
              cursorX + _twipsToPt(segment.widthTwips),
              baseline + style.sizePt * 0.11,
              color: style.color,
              widthPx: style.sizePt * 0.055,
            );
          }
          if (style.strike) {
            builder.strokeLine(
              cursorX,
              baseline - style.sizePt * 0.27,
              cursorX + _twipsToPt(segment.widthTwips),
              baseline - style.sizePt * 0.27,
              color: style.color,
              widthPx: style.sizePt * 0.055,
            );
          }
        }
        cursorX += _twipsToPt(segment.widthTwips);
      }
      y += _twipsToPt(line.heightTwips);
      firstLine = false;
    }
  }
}
