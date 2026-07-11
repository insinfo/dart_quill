/// Delta -> PDF exporter.
///
/// Bridges the dart_quill [Delta] model with the vendored pure-Dart PDF
/// stack (`dependencies/canvas_editor/document/pdf`) and the embedded font
/// metrics (`dependencies/canvas_editor/document/fonts`):
///
/// - [deltaToPdf]: [Delta] -> `QuillDeltaConverter.fromDelta` (element list)
///   -> paginated layout (this file) -> `PdfWriter` -> PDF bytes.
///
/// Layout capabilities:
/// - paragraphs with word wrapping driven by the embedded TTF metrics
///   (Arial / Times New Roman / Courier New) so line breaks match the
///   standard-14 fonts used in the output;
/// - alignment (left, center, right, justify with word-gap distribution);
/// - headers 1-6 (scaled font sizes, bold);
/// - inline formatting: bold, italic (standard-14 variants), underline,
///   strike, color, background highlight, sub/superscript;
/// - ordered and bullet lists with markers and hanging indent;
/// - hyperlinks (styled blue + underline, with clickable URI annotations);
/// - images from base64 data URIs (JPEG and non-interlaced PNG, including
///   alpha via SMask), scaled to fit the content box;
/// - tables as simple grids: column widths from the delta `table-col` ops,
///   cell background, borders and per-cell paragraph layout;
/// - automatic pagination by line metrics (a table row never splits).
///
/// Known limitations:
/// - text is emitted with WinAnsi (cp1252) encoding; codepoints outside it
///   are approximated or replaced by '?';
/// - bold width is estimated from the regular metrics (x1.05);
/// - table cells ignore `rowspan` (cells are laid out sequentially) and
///   nested tables inside cells are skipped;
/// - list indentation levels (`indent` attribute) are not represented by
///   the element converter and therefore render at a single level.
library;

import 'dart:typed_data';

import '../../dependencies/canvas_editor/document/fonts/font_metrics.dart'
    show FontMetrics;
import '../../dependencies/canvas_editor/document/fonts/font_registry.dart'
    show FontRegistry;
import '../../dependencies/canvas_editor/document/pdf/pdf_content.dart'
    show PdfContentBuilder, encodeWinAnsi, standardFontFor;
import '../../dependencies/canvas_editor/document/pdf/pdf_image.dart'
    show PdfImageData, decodeDataUrlImage;
import '../../dependencies/canvas_editor/document/pdf/pdf_writer.dart'
    show PdfWriter;
import '../../dependencies/canvas_editor/editor/dataset/enum/element.dart'
    show ElementType;
import '../../dependencies/canvas_editor/editor/dataset/enum/list.dart'
    show ListType;
import '../../dependencies/canvas_editor/editor/dataset/enum/row.dart'
    show RowFlex;
import '../../dependencies/canvas_editor/editor/dataset/enum/title.dart'
    show TitleLevel;
import '../../dependencies/canvas_editor/editor/interface/element.dart'
    show IColgroup, IElement;
import '../../dependencies/canvas_editor/editor/interface/table/td.dart'
    show ITd;
import '../../dependencies/canvas_editor/editor/interface/table/tr.dart'
    show ITr;
import '../../dependencies/canvas_editor/word/quill_delta.dart'
    show QuillDeltaConverter;
import '../../dependencies/dart_quill_delta/dart_quill_delta.dart' show Delta;

/// Conversion factor: CSS px (96 dpi) -> PDF points (72 dpi).
const double _pxToPt = 72 / 96;

/// A4 portrait width in points.
const double _a4WidthPt = 595.276;

/// A4 portrait height in points.
const double _a4HeightPt = 841.890;

/// 2 cm in points.
const double _twoCmPt = 56.693;

/// Options for [deltaToPdf].
///
/// All measurements are in PDF points (1 pt = 1/72 inch).
class PdfExportOptions {
  const PdfExportOptions({
    this.pageWidth = _a4WidthPt,
    this.pageHeight = _a4HeightPt,
    double margin = _twoCmPt,
    double? marginTop,
    double? marginBottom,
    double? marginLeft,
    double? marginRight,
    this.baseFontSize = 12,
    this.fontFamily = 'Arial',
    this.title = 'Documento',
  })  : marginTop = marginTop ?? margin,
        marginBottom = marginBottom ?? margin,
        marginLeft = marginLeft ?? margin,
        marginRight = marginRight ?? margin;

  /// Page width in points (default: A4).
  final double pageWidth;

  /// Page height in points (default: A4).
  final double pageHeight;

  /// Page margins in points (default: 2 cm each).
  final double marginTop;
  final double marginBottom;
  final double marginLeft;
  final double marginRight;

  /// Font size, in points, of plain body text (headers scale from it).
  final double baseFontSize;

  /// Default font family for text without an explicit `font` attribute.
  /// Mapped to a metrically close PDF standard-14 font (Arial -> Helvetica,
  /// Times New Roman -> Times, Courier New -> Courier).
  final String fontFamily;

  /// Document title written to the PDF `/Info` dictionary.
  final String title;
}

/// Converts a Quill [Delta] into the bytes of a paginated PDF document.
///
/// Produces PDF 1.4 with vector (selectable, searchable) text using the
/// standard-14 fonts. See the library documentation for the supported
/// content and known limitations.
Uint8List deltaToPdf(
  Delta delta, {
  PdfExportOptions options = const PdfExportOptions(),
}) {
  final List<IElement> elements = QuillDeltaConverter.fromDelta(
      <String, dynamic>{'ops': delta.toJson()});
  return _PdfLayoutEngine(options).render(elements);
}

// ---------------------------------------------------------------------------
// Internal layout model.
// ---------------------------------------------------------------------------

/// Paragraph alignment (subset of Quill `align`).
enum _Align { left, center, right, justify }

/// A styled inline run: either a piece of text or an image.
class _Run {
  _Run({
    this.text = '',
    this.image,
    required this.family,
    required this.size,
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.strike = false,
    this.color = '#000000',
    this.highlight,
    this.link,
    this.baselineShift = 0,
  });

  final String text;
  final _ImageRef? image;
  final String family;
  final double size;
  final bool bold;
  final bool italic;
  final bool underline;
  final bool strike;
  final String color;
  final String? highlight;
  final String? link;

  /// Vertical baseline shift in points (positive raises the text).
  final double baselineShift;
}

/// A decoded image registered as a PDF XObject.
class _ImageRef {
  _ImageRef({
    required this.objectId,
    required this.name,
    required this.widthPt,
    required this.heightPt,
  });

  final int objectId;
  final String name;
  double widthPt;
  double heightPt;
}

/// A measured token of a line: a word, a whitespace stretch or an image.
class _Seg {
  _Seg({
    required this.run,
    required this.text,
    required this.width,
    this.isSpace = false,
  });

  final _Run run;
  final String text;
  final double width;
  final bool isSpace;
}

/// A laid-out line: segments plus vertical metrics.
class _Line {
  _Line({
    required this.segs,
    required this.width,
    required this.ascent,
    required this.height,
  });

  final List<_Seg> segs;

  /// Width excluding trailing whitespace (used for alignment).
  final double width;
  final double ascent;
  final double height;
}

/// A block-level unit: a paragraph or a table.
abstract class _Block {}

class _ParagraphBlock extends _Block {
  _ParagraphBlock({
    required this.runs,
    this.align = _Align.left,
    this.headerLevel,
    this.marker,
    this.indent = 0,
    this.spacingBefore = 0,
    this.spacingAfter = 0,
  });

  final List<_Run> runs;
  final _Align align;
  final int? headerLevel;

  /// List marker text ("1. " / bullet), drawn left of the first line.
  final String? marker;

  /// Left indent, in points, applied to every line of the paragraph.
  final double indent;
  final double spacingBefore;
  final double spacingAfter;
}

class _TableBlock extends _Block {
  _TableBlock(this.element);

  final IElement element;
}

/// Per-page accumulation: content stream builder, image resources and link
/// annotations.
class _PageSink {
  _PageSink(this.builder);

  final PdfContentBuilder builder;
  final Map<String, int> xObjects = <String, int>{};
  final List<int> annotationIds = <int>[];
}

// ---------------------------------------------------------------------------
// Layout engine.
// ---------------------------------------------------------------------------

class _PdfLayoutEngine {
  _PdfLayoutEngine(this.options);

  final PdfExportOptions options;
  final PdfWriter _writer = PdfWriter();
  final Map<String, _ImageRef?> _imageCache = <String, _ImageRef?>{};

  late _PageSink _sink;
  late double _cursorY;
  bool _pageHasContent = false;

  double get _contentX => options.marginLeft;
  double get _contentTop => options.marginTop;
  double get _contentWidth =>
      options.pageWidth - options.marginLeft - options.marginRight;
  double get _contentBottom => options.pageHeight - options.marginBottom;

  Uint8List render(List<IElement> elements) {
    _sink = _newSink();
    _cursorY = _contentTop;
    for (final _Block block in _buildBlocks(elements)) {
      if (block is _ParagraphBlock) {
        _renderParagraph(block);
      } else if (block is _TableBlock) {
        _renderTable(block.element);
      }
    }
    _flushPage();
    return _writer.build(title: options.title, producer: 'dart_quill');
  }

  _PageSink _newSink() => _PageSink(
      PdfContentBuilder(pageHeightPt: options.pageHeight, k: 1));

  void _flushPage() {
    _writer.addPage(
      widthPt: options.pageWidth,
      heightPt: options.pageHeight,
      content: _sink.builder.build(),
      xObjects: _sink.xObjects,
      annotationIds: _sink.annotationIds,
    );
  }

  void _newPage() {
    _flushPage();
    _sink = _newSink();
    _cursorY = _contentTop;
    _pageHasContent = false;
  }

  /// Starts a new page when [height] does not fit below the cursor (unless
  /// the cursor is already at the top of an empty page).
  void _ensureSpace(double height) {
    if (_cursorY + height > _contentBottom && _pageHasContent) {
      _newPage();
    }
  }

  // -- Element list -> blocks ----------------------------------------------

  /// Converts the element list produced by `QuillDeltaConverter.fromDelta`
  /// (separator-before line model: `'\n'` values separate lines) into
  /// block-level paragraphs and tables.
  List<_Block> _buildBlocks(List<IElement> elements) {
    final List<_Block> blocks = <_Block>[];
    final List<_Run> current = <_Run>[];
    RowFlex? currentFlex;
    // The separator following a self-terminating block (title/list/table)
    // only closes that block's line; it must not create an empty paragraph.
    bool skipNextNewline = false;
    int listOrdinal = 0;

    void emitParagraph() {
      blocks.add(_ParagraphBlock(
        runs: List<_Run>.from(current),
        align: _alignOf(currentFlex),
      ));
      current.clear();
      currentFlex = null;
      listOrdinal = 0;
    }

    void flushIfNotEmpty() {
      if (current.isNotEmpty) emitParagraph();
    }

    for (final IElement element in elements) {
      switch (element.type) {
        case ElementType.title:
          flushIfNotEmpty();
          final int level = _headerLevel(element.level);
          final double size = options.baseFontSize * _headerScale(level);
          blocks.add(_ParagraphBlock(
            runs: _collectInline(element.valueList ?? const <IElement>[],
                defaultSize: size, defaultBold: true),
            align: _alignOf(element.rowFlex),
            headerLevel: level,
            spacingBefore: size * 0.6,
            spacingAfter: size * 0.3,
          ));
          skipNextNewline = true;
          listOrdinal = 0;
          continue;
        case ElementType.list:
          flushIfNotEmpty();
          final bool ordered = element.listType == ListType.ordered;
          listOrdinal = ordered ? listOrdinal + 1 : 0;
          blocks.add(_ParagraphBlock(
            runs: _collectInline(element.valueList ?? const <IElement>[],
                defaultSize: options.baseFontSize),
            align: _alignOf(element.rowFlex),
            marker: ordered ? '$listOrdinal. ' : '• ',
            indent: 21.6,
          ));
          skipNextNewline = true;
          continue;
        case ElementType.table:
          flushIfNotEmpty();
          blocks.add(_TableBlock(element));
          skipNextNewline = true;
          listOrdinal = 0;
          continue;
        case ElementType.image:
          final _ImageRef? image = _imageFor(element);
          if (image != null) {
            current.add(_Run(
              image: image,
              family: options.fontFamily,
              size: options.baseFontSize,
            ));
            currentFlex ??= element.rowFlex;
            skipNextNewline = false;
          }
          continue;
        case ElementType.hyperlink:
          current.addAll(_collectInline(
            element.valueList ?? const <IElement>[],
            defaultSize: options.baseFontSize,
            link: element.url,
          ));
          currentFlex ??= element.rowFlex;
          skipNextNewline = false;
          continue;
        default:
          break;
      }

      // Plain text (including sub/superscript), possibly with '\n'
      // separators between lines.
      final String value = element.value;
      int start = 0;
      for (int i = 0; i < value.length; i++) {
        if (value[i] != '\n') continue;
        final String piece = value.substring(start, i);
        if (piece.isNotEmpty) {
          current.add(_textRun(element, piece, options.baseFontSize));
          currentFlex ??= element.rowFlex;
          skipNextNewline = false;
        }
        if (current.isEmpty && skipNextNewline) {
          skipNextNewline = false;
        } else {
          emitParagraph();
        }
        start = i + 1;
      }
      final String tail = value.substring(start);
      if (tail.isNotEmpty) {
        current.add(_textRun(element, tail, options.baseFontSize));
        currentFlex ??= element.rowFlex;
        skipNextNewline = false;
      }
    }
    flushIfNotEmpty();
    return blocks;
  }

  /// Collects the inline children of a title/list/hyperlink block as runs.
  List<_Run> _collectInline(
    List<IElement> children, {
    required double defaultSize,
    bool defaultBold = false,
    String? link,
  }) {
    final List<_Run> runs = <_Run>[];
    for (final IElement child in children) {
      if (child.type == ElementType.hyperlink) {
        runs.addAll(_collectInline(child.valueList ?? const <IElement>[],
            defaultSize: defaultSize,
            defaultBold: defaultBold,
            link: child.url));
        continue;
      }
      if (child.type == ElementType.image) {
        final _ImageRef? image = _imageFor(child);
        if (image != null) {
          runs.add(_Run(
              image: image, family: options.fontFamily, size: defaultSize));
        }
        continue;
      }
      // Line separators inside a block become plain spaces.
      final String text = child.value.replaceAll('\n', ' ');
      if (text.isEmpty) continue;
      runs.add(_textRun(child, text, defaultSize,
          defaultBold: defaultBold, link: link));
    }
    return runs;
  }

  _Run _textRun(
    IElement element,
    String text,
    double defaultSize, {
    bool defaultBold = false,
    String? link,
  }) {
    double size =
        element.size != null ? element.size! * _pxToPt : defaultSize;
    double baselineShift = 0;
    if (element.type == ElementType.superscript) {
      baselineShift = size * 0.33;
      size *= 0.65;
    } else if (element.type == ElementType.subscript) {
      baselineShift = -size * 0.15;
      size *= 0.65;
    }
    final bool linked = link != null && link.isNotEmpty;
    return _Run(
      text: text,
      family: element.font ?? options.fontFamily,
      size: size,
      bold: element.bold ?? defaultBold,
      italic: element.italic ?? false,
      underline: (element.underline ?? false) || linked,
      strike: element.strikeout ?? false,
      color: element.color ?? (linked ? '#0563C1' : '#000000'),
      highlight: element.highlight,
      link: linked ? link : null,
      baselineShift: baselineShift,
    );
  }

  // -- Measurement ----------------------------------------------------------

  /// Maps a CSS family to the embedded metrics family that matches the
  /// standard-14 font chosen by `standardFontFor`, guaranteeing that the
  /// measured widths agree with the font used in the output.
  FontMetrics _metricsFor(String? family) {
    final String f = (family ?? '').toLowerCase();
    final String key;
    if (f.contains('courier') || f.contains('mono') || f.contains('consolas')) {
      key = 'courier new';
    } else if (f.contains('times') ||
        f.contains('georgia') ||
        f.contains('garamond') ||
        f.contains('cambria') ||
        f.contains('book') ||
        (f.contains('serif') && !f.contains('sans'))) {
      key = 'times new roman';
    } else {
      key = 'arial';
    }
    return FontRegistry.instance.lookup(key) ??
        FontRegistry.instance.lookup(null)!;
  }

  double _measure(_Run run, String text) {
    final double width = _metricsFor(run.family).measureWidth(text, run.size);
    // The embedded metrics are for the regular weight; bold glyphs of the
    // standard-14 families are slightly wider.
    return run.bold ? width * 1.05 : width;
  }

  double _lineHeightOf(_Run run) {
    if (run.image != null) return run.image!.heightPt + 2;
    final FontMetrics m = _metricsFor(run.family);
    final double h = run.size * m.singleLineEm;
    return h < run.size * 1.15 ? run.size * 1.15 : h;
  }

  double _ascentOf(_Run run) {
    if (run.image != null) return run.image!.heightPt;
    return _metricsFor(run.family).ascentPx(run.size) + run.baselineShift;
  }

  double get _emptyLineHeight {
    final FontMetrics m = _metricsFor(options.fontFamily);
    final double h = options.baseFontSize * m.singleLineEm;
    return h < options.baseFontSize * 1.15 ? options.baseFontSize * 1.15 : h;
  }

  // -- Line breaking ---------------------------------------------------------

  static final RegExp _tokenPattern = RegExp(r'\s+|[^\s]+');

  List<_Line> _breakLines(List<_Run> runs, double maxWidth) {
    final double width = maxWidth < 1 ? 1 : maxWidth;
    final List<_Seg> tokens = <_Seg>[];
    for (final _Run run in runs) {
      if (run.image != null) {
        final _ImageRef image = run.image!;
        if (image.widthPt > width) {
          // Scale down to the available width, preserving aspect ratio.
          final double factor = width / image.widthPt;
          image.widthPt *= factor;
          image.heightPt *= factor;
        }
        tokens.add(_Seg(run: run, text: '', width: image.widthPt));
        continue;
      }
      for (final Match match in _tokenPattern.allMatches(run.text)) {
        final String token = match.group(0)!;
        final bool isSpace = token.trim().isEmpty;
        tokens.add(_Seg(
          run: run,
          text: token,
          width: _measure(run, token),
          isSpace: isSpace,
        ));
      }
    }

    final List<_Line> lines = <_Line>[];
    List<_Seg> current = <_Seg>[];
    double currentWidth = 0;
    bool wrapped = false;

    void flushLine() {
      // Alignment width ignores trailing whitespace.
      double w = currentWidth;
      for (int i = current.length - 1; i >= 0 && current[i].isSpace; i--) {
        w -= current[i].width;
      }
      double ascent = 0;
      double height = 0;
      for (final _Seg seg in current) {
        final double a = _ascentOf(seg.run);
        final double h = _lineHeightOf(seg.run);
        if (a > ascent) ascent = a;
        if (h > height) height = h;
      }
      if (current.isEmpty || height == 0) {
        height = _emptyLineHeight;
        ascent = _metricsFor(options.fontFamily)
            .ascentPx(options.baseFontSize);
      }
      lines.add(_Line(
          segs: current, width: w < 0 ? 0 : w, ascent: ascent, height: height));
      current = <_Seg>[];
      currentWidth = 0;
      wrapped = true;
    }

    for (final _Seg token in tokens) {
      if (token.isSpace) {
        if (current.isEmpty && wrapped) continue; // collapse at wrap point
        current.add(token);
        currentWidth += token.width;
        continue;
      }
      if (currentWidth + token.width > width && current.isNotEmpty) {
        flushLine();
      }
      if (token.width > width && current.isEmpty) {
        // Hard-break an over-long word (or image wider than the column —
        // images were already capped above, so this is text only).
        _Seg remaining = token;
        while (remaining.width > width && remaining.text.length > 1) {
          int cut = remaining.text.length - 1;
          while (cut > 1 &&
              _measure(remaining.run, remaining.text.substring(0, cut)) >
                  width) {
            cut--;
          }
          final String head = remaining.text.substring(0, cut);
          current.add(_Seg(
              run: remaining.run,
              text: head,
              width: _measure(remaining.run, head)));
          currentWidth += current.last.width;
          flushLine();
          final String rest = remaining.text.substring(cut);
          remaining = _Seg(
              run: remaining.run,
              text: rest,
              width: _measure(remaining.run, rest));
        }
        current.add(remaining);
        currentWidth += remaining.width;
        continue;
      }
      current.add(token);
      currentWidth += token.width;
    }
    if (current.isNotEmpty) flushLine();
    return lines;
  }

  // -- Drawing ---------------------------------------------------------------

  void _drawLineAt(
    _PageSink sink,
    _Line line,
    double x,
    double top,
    double width,
    _Align align,
    bool isLastLine,
  ) {
    double startX = x;
    double extraPerSpace = 0;
    if (align == _Align.center) {
      startX += (width - line.width) / 2;
    } else if (align == _Align.right) {
      startX += width - line.width;
    } else if (align == _Align.justify && !isLastLine) {
      int spaces = 0;
      double trailing = 0;
      for (int i = line.segs.length - 1; i >= 0 && line.segs[i].isSpace; i--) {
        trailing++;
      }
      for (int i = 0; i < line.segs.length - trailing; i++) {
        if (line.segs[i].isSpace) spaces++;
      }
      if (spaces > 0 && line.width < width) {
        extraPerSpace = (width - line.width) / spaces;
      }
    }
    final double baseline = top + line.ascent;

    // Pass 1: highlight rectangles (must sit behind the glyphs).
    double cx = startX;
    for (final _Seg seg in line.segs) {
      final _Run run = seg.run;
      if (run.image == null && run.highlight != null && seg.text.isNotEmpty) {
        final FontMetrics m = _metricsFor(run.family);
        final double asc = m.ascentPx(run.size);
        final double desc = m.descentPx(run.size);
        sink.builder.fillRect(
            cx, baseline - asc, seg.width, asc + desc, run.highlight!);
      }
      cx += seg.width + (seg.isSpace ? extraPerSpace : 0);
    }

    // Pass 2: text, images, decorations and link annotations.
    cx = startX;
    for (final _Seg seg in line.segs) {
      final _Run run = seg.run;
      if (run.image != null) {
        final _ImageRef image = run.image!;
        sink.xObjects[image.name] = image.objectId;
        sink.builder.drawImage(image.name, cx, baseline - image.heightPt,
            image.widthPt, image.heightPt);
        cx += seg.width + (seg.isSpace ? extraPerSpace : 0);
        continue;
      }
      final double segBaseline = baseline - run.baselineShift;
      if (seg.text.isNotEmpty) {
        final String baseFont = standardFontFor(
            family: run.family, bold: run.bold, italic: run.italic);
        sink.builder.text(
          fontResource: _writer.fontResourceName(baseFont),
          sizePx: run.size,
          winAnsiText: encodeWinAnsi(seg.text),
          x: cx,
          baselineY: segBaseline,
          color: run.color,
        );
      }
      if (run.underline && !seg.isSpace && seg.text.isNotEmpty) {
        sink.builder.strokeLine(cx, segBaseline + run.size * 0.11,
            cx + seg.width, segBaseline + run.size * 0.11,
            color: run.color, widthPx: run.size * 0.055);
      }
      if (run.strike && !seg.isSpace && seg.text.isNotEmpty) {
        sink.builder.strokeLine(cx, segBaseline - run.size * 0.27,
            cx + seg.width, segBaseline - run.size * 0.27,
            color: run.color, widthPx: run.size * 0.055);
      }
      if (run.link != null && !seg.isSpace && seg.text.isNotEmpty) {
        final FontMetrics m = _metricsFor(run.family);
        final double topY = segBaseline - m.ascentPx(run.size);
        final double bottomY = segBaseline + m.descentPx(run.size);
        sink.annotationIds.add(_writer.addLinkAnnotation(<double>[
          cx,
          options.pageHeight - bottomY,
          cx + seg.width,
          options.pageHeight - topY,
        ], run.link!));
      }
      cx += seg.width + (seg.isSpace ? extraPerSpace : 0);
    }
  }

  void _renderParagraph(_ParagraphBlock paragraph) {
    final double available = _contentWidth - paragraph.indent;
    final List<_Line> lines = _breakLines(paragraph.runs, available);
    if (lines.isEmpty) {
      // Deliberate blank line.
      final double height = _emptyLineHeight;
      _ensureSpace(height);
      _cursorY += height;
      _pageHasContent = true;
      return;
    }
    if (paragraph.spacingBefore > 0 && _pageHasContent) {
      _cursorY += paragraph.spacingBefore;
    }
    for (int i = 0; i < lines.length; i++) {
      final _Line line = lines[i];
      _ensureSpace(line.height);
      if (i == 0 && paragraph.marker != null) {
        final _Run markerRun = paragraph.runs.isNotEmpty
            ? paragraph.runs.first
            : _Run(family: options.fontFamily, size: options.baseFontSize);
        final _Run marker = _Run(
          text: paragraph.marker!,
          family: markerRun.family,
          size: markerRun.size,
          color: markerRun.color,
        );
        final double markerWidth = _measure(marker, marker.text);
        _drawLineAt(
          _sink,
          _Line(
            segs: <_Seg>[
              _Seg(run: marker, text: marker.text, width: markerWidth)
            ],
            width: markerWidth,
            ascent: line.ascent,
            height: line.height,
          ),
          _contentX + paragraph.indent - markerWidth - 4,
          _cursorY,
          markerWidth,
          _Align.left,
          true,
        );
      }
      _drawLineAt(_sink, line, _contentX + paragraph.indent, _cursorY,
          available, paragraph.align, i == lines.length - 1);
      _cursorY += line.height;
      _pageHasContent = true;
    }
    if (paragraph.spacingAfter > 0) {
      _cursorY += paragraph.spacingAfter;
    }
  }

  // -- Tables ----------------------------------------------------------------

  static const double _cellPadding = 4;

  void _renderTable(IElement table) {
    final List<ITr> rows = table.trList ?? const <ITr>[];
    if (rows.isEmpty) return;
    final List<double> columnWidths = _columnWidths(table);
    if (columnWidths.isEmpty) return;

    for (final ITr tr in rows) {
      // Measure the row: lay out each cell's blocks at its column width.
      final List<List<_Block>> cellBlocks = <List<_Block>>[];
      final List<double> cellWidths = <double>[];
      final List<double> cellX = <double>[];
      double x = _contentX;
      int column = 0;
      double rowHeight = tr.height * _pxToPt;
      if (rowHeight < 16) rowHeight = 16;
      for (final ITd td in tr.tdList) {
        double width = 0;
        for (int span = 0; span < td.colspan; span++) {
          if (column < columnWidths.length) {
            width += columnWidths[column];
            column++;
          }
        }
        if (width <= 0) width = 36;
        final List<_Block> blocks = _buildBlocks(td.value);
        final double contentHeight =
            _measureBlocks(blocks, width - 2 * _cellPadding);
        final double cellHeight = contentHeight + 2 * _cellPadding;
        if (cellHeight > rowHeight) rowHeight = cellHeight;
        cellBlocks.add(blocks);
        cellWidths.add(width);
        cellX.add(x);
        x += width;
      }

      _ensureSpace(rowHeight);
      final double rowTop = _cursorY;
      for (int i = 0; i < tr.tdList.length; i++) {
        final ITd td = tr.tdList[i];
        if (td.backgroundColor != null) {
          _sink.builder.fillRect(
              cellX[i], rowTop, cellWidths[i], rowHeight, td.backgroundColor!);
        }
        _sink.builder.strokeRect(cellX[i], rowTop, cellWidths[i], rowHeight,
            color: table.borderColor ?? '#000000',
            widthPx: table.borderWidth ?? 0.75);
        _drawBlocksAt(_sink, cellBlocks[i], cellX[i] + _cellPadding,
            rowTop + _cellPadding, cellWidths[i] - 2 * _cellPadding);
      }
      _cursorY = rowTop + rowHeight;
      _pageHasContent = true;
    }
  }

  /// Column widths in points, scaled down proportionally when the table is
  /// wider than the content box.
  List<double> _columnWidths(IElement table) {
    final List<IColgroup> colgroup = table.colgroup ?? const <IColgroup>[];
    List<double> widths =
        colgroup.map((IColgroup col) => col.width * _pxToPt).toList();
    if (widths.isEmpty) {
      int columns = 0;
      for (final ITr tr in table.trList ?? const <ITr>[]) {
        int cols = 0;
        for (final ITd td in tr.tdList) {
          cols += td.colspan;
        }
        if (cols > columns) columns = cols;
      }
      if (columns == 0) return const <double>[];
      widths = List<double>.filled(columns, _contentWidth / columns);
    }
    final double total = widths.fold(0, (double sum, double w) => sum + w);
    if (total > _contentWidth && total > 0) {
      final double factor = _contentWidth / total;
      widths = widths.map((double w) => w * factor).toList();
    }
    return widths;
  }

  /// Total height of [blocks] laid out at [width] (no pagination).
  double _measureBlocks(List<_Block> blocks, double width) {
    double height = 0;
    for (final _Block block in blocks) {
      if (block is! _ParagraphBlock) continue; // nested tables are skipped
      final List<_Line> lines =
          _breakLines(block.runs, width - block.indent);
      if (lines.isEmpty) {
        height += _emptyLineHeight;
        continue;
      }
      height += block.spacingBefore + block.spacingAfter;
      for (final _Line line in lines) {
        height += line.height;
      }
    }
    return height;
  }

  /// Draws [blocks] inside a fixed box (table cell) without pagination.
  void _drawBlocksAt(
    _PageSink sink,
    List<_Block> blocks,
    double x,
    double top,
    double width,
  ) {
    double y = top;
    for (final _Block block in blocks) {
      if (block is! _ParagraphBlock) continue;
      final double available = width - block.indent;
      final List<_Line> lines = _breakLines(block.runs, available);
      if (lines.isEmpty) {
        y += _emptyLineHeight;
        continue;
      }
      y += block.spacingBefore;
      for (int i = 0; i < lines.length; i++) {
        final _Line line = lines[i];
        if (i == 0 && block.marker != null) {
          final _Run base = block.runs.isNotEmpty
              ? block.runs.first
              : _Run(family: options.fontFamily, size: options.baseFontSize);
          final _Run marker = _Run(
              text: block.marker!,
              family: base.family,
              size: base.size,
              color: base.color);
          final double markerWidth = _measure(marker, marker.text);
          _drawLineAt(
            sink,
            _Line(
              segs: <_Seg>[
                _Seg(run: marker, text: marker.text, width: markerWidth)
              ],
              width: markerWidth,
              ascent: line.ascent,
              height: line.height,
            ),
            x + block.indent - markerWidth - 4,
            y,
            markerWidth,
            _Align.left,
            true,
          );
        }
        _drawLineAt(sink, line, x + block.indent, y, available, block.align,
            i == lines.length - 1);
        y += line.height;
      }
      y += block.spacingAfter;
    }
  }

  // -- Images ----------------------------------------------------------------

  /// Decodes and registers the image of an image element; results (including
  /// failures) are cached by data URL so repeated images share one XObject.
  _ImageRef? _imageFor(IElement element) {
    final String source = element.value;
    _ImageRef? ref;
    if (_imageCache.containsKey(source)) {
      ref = _imageCache[source];
    } else {
      final PdfImageData? decoded = decodeDataUrlImage(source);
      if (decoded == null) {
        _imageCache[source] = null;
        return null;
      }
      final int id = _writer.addImage(decoded);
      ref = _ImageRef(
        objectId: id,
        name: 'Im$id',
        widthPt: decoded.width * _pxToPt,
        heightPt: decoded.height * _pxToPt,
      );
      _imageCache[source] = ref;
    }
    if (ref == null) return null;
    // Per-use sizing: honor the delta width/height attributes and cap to the
    // content box. A fresh instance is returned because `_breakLines` may
    // rescale it to the column width.
    double width = (element.width ?? ref.widthPt / _pxToPt) * _pxToPt;
    double height = (element.height ?? ref.heightPt / _pxToPt) * _pxToPt;
    if (width <= 0 || height <= 0) {
      width = ref.widthPt;
      height = ref.heightPt;
    }
    final double maxWidth = _contentWidth;
    final double maxHeight = _contentBottom - _contentTop - _emptyLineHeight;
    double factor = 1;
    if (width > maxWidth) factor = maxWidth / width;
    if (height * factor > maxHeight) factor = maxHeight / height;
    return _ImageRef(
      objectId: ref.objectId,
      name: ref.name,
      widthPt: width * factor,
      heightPt: height * factor,
    );
  }

  // -- Helpers ---------------------------------------------------------------

  static _Align _alignOf(RowFlex? flex) {
    switch (flex) {
      case RowFlex.center:
        return _Align.center;
      case RowFlex.right:
        return _Align.right;
      case RowFlex.alignment:
      case RowFlex.justify:
        return _Align.justify;
      default:
        return _Align.left;
    }
  }

  static int _headerLevel(TitleLevel? level) {
    switch (level) {
      case TitleLevel.first:
        return 1;
      case TitleLevel.second:
        return 2;
      case TitleLevel.third:
        return 3;
      case TitleLevel.fourth:
        return 4;
      case TitleLevel.fifth:
        return 5;
      case TitleLevel.sixth:
      default:
        return 6;
    }
  }

  static double _headerScale(int level) {
    switch (level) {
      case 1:
        return 2.0;
      case 2:
        return 1.5;
      case 3:
        return 1.17;
      case 4:
        return 1.0;
      case 5:
        return 0.83;
      default:
        return 0.67;
    }
  }
}
