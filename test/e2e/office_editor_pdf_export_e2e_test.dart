@TestOn('vm')
@Timeout(Duration(minutes: 30))
library;

/// Focused real-browser proof for Arquivo -> Exportar PDF.
///
/// The full DOCX workflow also exercises this path. This smaller test exists
/// so PDF pagination and responsiveness can be measured for both corpus files
/// without repeating the trusted editing and two-save audit.
import 'dart:io';
import 'dart:typed_data';

import 'package:test/test.dart';

import '../support/pdf_reader.dart';
import 'support/office_e2e_app.dart';

void main() {
  late OfficeE2eApp app;

  // Por PREFIXO (ver officeCorpusFile): caminho literal com acento não
  // resolve no checkout do Linux da CI.
  final documents = [
    (name: 'etp', path: officeEtpCorpus().path, pages: 19),
    (name: 'tr', path: officeTrCorpus().path, pages: 140),
  ];

  setUpAll(() async => app = await OfficeE2eApp.start());
  tearDownAll(() async => app.stop());

  for (final document in documents) {
    test('${document.name.toUpperCase()}: botão Exportar PDF', () async {
      final source = File(document.path);
      if (skipWithoutCorpus(source, 'corpus ${document.name}')) return;
      await app.reload();
      final issueStart = app.issueCount;
      final imported = await app.importDocx(
        source,
        artifactName: '${document.name}-final-pdf-focused',
        timeout: const Duration(minutes: 5),
        captureScreenshots: false,
      );
      final exported = await app.exportPdf(
        artifactName: '${document.name}-final',
      );
      final searchableText = PdfReader(
        Uint8List.fromList(exported.file.readAsBytesSync()),
      ).extractText();

      final sourceFilename = source.path.replaceAll('\\', '/').split('/').last;
      final sourceStem = sourceFilename.substring(
        0,
        sourceFilename.toLowerCase().lastIndexOf('.docx'),
      );
      final fatalIssues = app
          .issuesSince(issueStart)
          .where((issue) => issue['severity'] == 'error')
          .toList();

      expect(imported.metrics['totalPages'], document.pages);
      expect(exported.pageCount, document.pages,
          reason: 'the PDF must reuse the exact browser page graph');
      expect(exported.browserFilename, '$sourceStem.pdf');
      expect(exported.mimeType, 'application/pdf');
      expect(exported.byteLength, greaterThan(1000));
      expect(exported.file.existsSync(), isTrue);
      expect(exported.file.lengthSync(), exported.byteLength);
      expect(exported.performance['maxFrameGapMs'] as num, lessThan(500));
      expect(exported.performance['maxLongTaskMs'] as num, lessThan(500));
      expect(exported.performance['phaseTimings'], isA<Map>());
      expect(searchableText, contains('Continuação de Processo'));
      expect(searchableText, contains('44505/2025'));
      if (document.name == 'etp') {
        expect(searchableText, contains('Responsáveis'));
      } else {
        expect(searchableText, contains('ANEXO III'));
        for (var item = 1; item <= 17; item++) {
          expect(searchableText, contains('$item. '),
              reason: 'the real TR PDF lost marker-only row $item on page 53');
        }
      }
      expect(fatalIssues, isEmpty,
          reason: 'browser console/page/network errors: $fatalIssues');
    });
  }
}
