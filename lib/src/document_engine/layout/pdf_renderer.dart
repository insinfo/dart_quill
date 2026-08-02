/// PdfRenderer — desenha um [PageGraph] em PDF (Fase 5).
///
/// A regra da arquitetura: o PDF NUNCA sai do DOM. Editor e PDF consomem o
/// MESMO PageGraph — este renderizador não decide layout nenhum, só
/// transcreve páginas, fragments e line boxes já compostos. Reusa o writer
/// PDF existente do pacote (xref, Flate, standard-14/WinAnsi; as fontes
/// embutidas CID entram quando o TextShaper chegar).
library;

import 'dart:typed_data';

import '../../office/document/pdf/pdf_content.dart';
import '../../office/document/pdf/pdf_writer.dart';
import 'page_graph.dart';

double _twipsToPt(int twips) => twips / 20.0;

class PageGraphPdfRenderer {
  PageGraphPdfRenderer({this.title = 'Documento'});

  final String title;

  Uint8List render(PageGraph graph) {
    final writer = PdfWriter();

    for (final page in graph.pages) {
      final setup = page.setup;
      final pageHeightPt = _twipsToPt(setup.heightTwips);
      final builder = PdfContentBuilder(pageHeightPt: pageHeightPt, k: 1);
      final contentX = _twipsToPt(setup.marginLeftTwips);
      final contentTop = _twipsToPt(setup.marginTopTwips);
      final contentWidth = _twipsToPt(setup.contentWidthTwips);

      for (final fragment in page.fragments) {
        var y = contentTop + _twipsToPt(fragment.yTwips);
        final left = contentX + _twipsToPt(fragment.indentTwips);
        final available = contentWidth - _twipsToPt(fragment.indentTwips);

        var firstLine = true;
        for (final line in fragment.lines) {
          final baseline = y + _twipsToPt(line.ascentTwips);
          var x = left;
          final lineWidth = _twipsToPt(line.widthTwips);
          if (fragment.align == LayoutAlign.center) {
            x += (available - lineWidth) / 2;
          } else if (fragment.align == LayoutAlign.right) {
            x += available - lineWidth;
          }

          if (firstLine && fragment.marker != null) {
            final style = line.segments.isNotEmpty
                ? line.segments.first.style
                : const ResolvedRunStyle(family: 'Arial', sizePt: 12);
            final font = standardFontFor(
                family: style.family, bold: style.bold, italic: style.italic);
            builder.text(
              fontResource: writer.fontResourceName(font),
              sizePx: style.sizePt,
              winAnsiText: encodeWinAnsi(fragment.marker!),
              x: left - style.sizePt * 1.4,
              baselineY: baseline,
              color: style.color,
            );
          }

          for (final segment in line.segments) {
            final style = segment.style;
            if (segment.text.trim().isNotEmpty || segment.text.isNotEmpty) {
              final font = standardFontFor(
                  family: style.family,
                  bold: style.bold,
                  italic: style.italic);
              builder.text(
                fontResource: writer.fontResourceName(font),
                sizePx: style.sizePt,
                winAnsiText: encodeWinAnsi(segment.text),
                x: x,
                baselineY: baseline,
                color: style.color,
              );
              if (style.underline) {
                builder.strokeLine(
                  x,
                  baseline + style.sizePt * 0.11,
                  x + _twipsToPt(segment.widthTwips),
                  baseline + style.sizePt * 0.11,
                  color: style.color,
                  widthPx: style.sizePt * 0.055,
                );
              }
              if (style.strike) {
                builder.strokeLine(
                  x,
                  baseline - style.sizePt * 0.27,
                  x + _twipsToPt(segment.widthTwips),
                  baseline - style.sizePt * 0.27,
                  color: style.color,
                  widthPx: style.sizePt * 0.055,
                );
              }
            }
            x += _twipsToPt(segment.widthTwips);
          }
          y += _twipsToPt(line.heightTwips);
          firstLine = false;
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
}
