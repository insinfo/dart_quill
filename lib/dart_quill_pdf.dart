/// PDF export for dart_quill.
///
/// Pure-Dart (VM and web) conversion from a Quill [Delta] document to the
/// bytes of a paginated PDF, with **no external dependency**: the PDF writer,
/// the content-stream builder, the image encoder and the standard-14 font
/// metrics are all part of this package.
///
/// ```dart
/// import 'dart:io';
/// import 'package:dart_quill/dart_quill_pdf.dart';
///
/// final bytes = deltaToPdf(delta, options: const PdfExportOptions(
///   title: 'Despacho',
///   margin: 56.7, // 2 cm
/// ));
/// File('despacho.pdf').writeAsBytesSync(bytes);
/// ```
///
/// ## Fonts
///
/// The package ships **font metrics**, never font files: text is laid out and
/// written with the 14 standard PDF fonts, which every reader has. Embedding a
/// real TrueType face (so the document renders in Inter, Arial or Calibri, and
/// so characters outside cp1252 survive) is the job of the loading API — the
/// `.ttf` bytes always come from the application, on the backend as much as on
/// the frontend. See `doc/PLANO_PORT_CONVERSORES_HTML_PDF.md` (P1).
library dart_quill_pdf;

export 'src/converters/pdf/pdf_exporter.dart'
    show
        deltaToPdf,
        deltaToPdfWithReport,
        PdfExportOptions,
        PdfExportResult,
        PdfFontFace;
export 'src/converters/pdf/pdf_page_setup.dart'
    show
        InvalidPdfOperation,
        PdfPageSetup,
        PdfSanitizePolicy,
        pageSetupOptions,
        parsePageMarginCm,
        readPdfPageSetup,
        sanitizeOpsForPdf;
