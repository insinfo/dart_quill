@TestOn('vm')
library;

import 'dart:convert';

import 'package:dart_quill/src/office/document/pdf/pdf_writer.dart';
import 'package:test/test.dart';

void main() {
  group('standard font resources', () {
    test('preserve registration order and cache the assigned resource name',
        () {
      final writer = PdfWriter();

      expect(writer.fontResourceName('Helvetica'), '/F1');
      expect(writer.fontResourceName('Helvetica'), '/F1');

      // A direct fontId call has always occupied the next resource slot, even
      // when its resource name is requested only later.
      writer.fontId('Times-Roman');
      expect(writer.fontResourceName('Courier'), '/F3');
      expect(writer.fontResourceName('Times-Roman'), '/F2');
      expect(writer.fontResourceName('Courier'), '/F3');
    });

    test('page resources keep the exact names and object associations', () {
      final writer = PdfWriter();
      final helvetica = writer.fontId('Helvetica');
      final times = writer.fontId('Times-Roman');
      final courier = writer.fontId('Courier');

      writer.addPage(
        widthPt: 595,
        heightPt: 842,
        content: ascii.encode(
          'BT /F1 12 Tf (A) Tj /F2 12 Tf (B) Tj /F3 12 Tf (C) Tj ET',
        ),
      );

      final raw = latin1.decode(writer.build());
      expect(
        raw,
        contains('/Font << /F1 $helvetica 0 R /F2 $times 0 R '
            '/F3 $courier 0 R >>'),
      );
      expect(writer.fontResourceName('Helvetica'), '/F1');
      expect(writer.fontResourceName('Times-Roman'), '/F2');
      expect(writer.fontResourceName('Courier'), '/F3');
    });
  });
}
