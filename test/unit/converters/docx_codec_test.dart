import 'dart:typed_data';

import 'package:dart_quill/dart_quill_docx.dart';
import 'package:dart_quill/src/dependencies/dart_quill_delta/dart_quill_delta.dart';
import 'package:test/test.dart';

/// Concatenates every string insert of [delta] into the document plain text.
String _plainText(Delta delta) {
  final buffer = StringBuffer();
  for (final op in delta.toList()) {
    final data = op.data;
    if (data is String) buffer.write(data);
  }
  return buffer.toString();
}

/// Returns the attributes of the first insert op whose data contains [text].
Map<String, dynamic>? _attributesOfTextContaining(Delta delta, String text) {
  for (final op in delta.toList()) {
    final data = op.data;
    if (data is String && data.contains(text)) return op.attributes;
  }
  return null;
}

/// Returns the attributes of the newline op that terminates the line
/// containing [text] (i.e. the first `\n` insert at or after that op).
Map<String, dynamic>? _lineAttributesOf(Delta delta, String text) {
  final ops = delta.toList();
  var found = false;
  for (final op in ops) {
    final data = op.data;
    if (data is! String) continue;
    if (!found && data.contains(text)) found = true;
    if (found && data.contains('\n')) return op.attributes;
  }
  return null;
}

Delta _buildSampleDelta() {
  return Delta()
    ..insert('Plain paragraph text')
    ..insert('\n')
    ..insert('bold run', {'bold': true})
    ..insert(' and ')
    ..insert('italic run', {'italic': true})
    ..insert('\n')
    ..insert('Document Header')
    ..insert('\n', {'header': 1})
    ..insert('First item')
    ..insert('\n', {'list': 'ordered'})
    ..insert('Second item')
    ..insert('\n', {'list': 'ordered'})
    ..insert('Centered paragraph')
    ..insert('\n', {'align': 'center'});
}

void main() {
  group('docx codec', () {
    test('deltaToDocx produces a ZIP (PK) package', () {
      final Uint8List bytes = deltaToDocx(_buildSampleDelta());
      expect(bytes.length, greaterThan(4));
      expect(bytes[0], 0x50, reason: 'first byte should be P');
      expect(bytes[1], 0x4B, reason: 'second byte should be K');
    });

    test('docxToDelta reads back a generated document (non-empty text)', () {
      final bytes = deltaToDocx(_buildSampleDelta());
      final delta = docxToDelta(bytes);
      expect(delta.isNotEmpty, isTrue);
      expect(_plainText(delta).trim(), isNotEmpty);
    });

    test('round-trip preserves text content and order', () {
      final bytes = deltaToDocx(_buildSampleDelta());
      final delta = docxToDelta(bytes);
      final text = _plainText(delta);

      // List items come back with their materialized markers ("1. ", "2. ")
      // because the DOCX pipeline stores numbering as literal text.
      const fragments = [
        'Plain paragraph text',
        'bold run',
        ' and ',
        'italic run',
        'Document Header',
        '1. First item',
        '2. Second item',
        'Centered paragraph',
      ];
      var cursor = 0;
      for (final fragment in fragments) {
        final index = text.indexOf(fragment, cursor);
        expect(index, greaterThanOrEqualTo(0),
            reason: 'expected "$fragment" after position $cursor in "$text"');
        cursor = index + fragment.length;
      }
    });

    test('round-trip preserves inline formatting (bold/italic)', () {
      final delta = docxToDelta(deltaToDocx(_buildSampleDelta()));

      final bold = _attributesOfTextContaining(delta, 'bold run');
      expect(bold, isNotNull);
      expect(bold!['bold'], isTrue);

      final italic = _attributesOfTextContaining(delta, 'italic run');
      expect(italic, isNotNull);
      expect(italic!['italic'], isTrue);

      final plain = _attributesOfTextContaining(delta, ' and ');
      expect(plain?['bold'], isNot(isTrue));
      expect(plain?['italic'], isNot(isTrue));
    });

    test('round-trip preserves line formats (header/align) on their lines',
        () {
      final delta = docxToDelta(deltaToDocx(_buildSampleDelta()));

      final headerLine = _lineAttributesOf(delta, 'Document Header');
      expect(headerLine, isNotNull);
      expect(headerLine!['header'], 1,
          reason: 'header 1 line attribute should survive');

      final centeredLine = _lineAttributesOf(delta, 'Centered paragraph');
      expect(centeredLine, isNotNull);
      expect(centeredLine!['align'], 'center',
          reason: 'center alignment should survive on the centered line');

      // Lines that were not aligned must not gain alignment.
      expect(_lineAttributesOf(delta, 'Plain paragraph text')?['align'],
          isNull);
      expect(_lineAttributesOf(delta, '2. Second item')?['align'], isNull);
    });

    test('round-trip keeps ordered list numbering as visible markers', () {
      // Known pipeline limitation: the Quill `list` attribute does not
      // survive DOCX (numbering is materialized as literal marker text).
      final delta = docxToDelta(deltaToDocx(_buildSampleDelta()));
      final text = _plainText(delta);
      expect(text, contains('1. First item'));
      expect(text, contains('2. Second item'));
    });

    test('second round-trip is stable', () {
      final once = docxToDelta(deltaToDocx(_buildSampleDelta()));
      final twice = docxToDelta(deltaToDocx(once));
      expect(twice.toJson(), equals(once.toJson()));
    });
  });
}
