@TestOn('vm')
@Timeout(Duration(minutes: 10))
library;

import 'package:test/test.dart';

import 'support/office_e2e_app.dart';

void main() {
  late OfficeE2eApp app;

  setUpAll(() async => app = await OfficeE2eApp.start());
  tearDownAll(() async => app.stop());

  test('download hand-off produces real DOCX and PDF Blobs', () async {
    final docx = await app.exportDocx(artifactName: 'download-smoke-docx');
    expect(docx.readAsBytesSync().take(4), [0x50, 0x4b, 0x03, 0x04]);
    final pdf = await app.exportPdf(artifactName: 'download-smoke-pdf');
    expect(pdf.pageCount, greaterThan(0));
    expect(pdf.mimeType, 'application/pdf');
  });
}
