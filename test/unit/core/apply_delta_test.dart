import 'package:dart_quill/src/delta/delta.dart';
import 'package:test/test.dart';

import '../../support/quill_test_helpers.dart';

/// `Editor.applyDelta` (editor.ts:28-122) replaced a bespoke loop that walked
/// the ops applying each blindly. These cover what the bespoke version could
/// not do.
void main() {
  group('splitOpLines', () {
    test('a multi-line insert puts each line format on its own newline', () {
      final quill = createTestQuill();
      quill.setContents(Delta()
        ..insert('one\ntwo\nthree')
        ..insert('\n', {'header': 2}));

      // Only the last line is a header; the first two are plain.
      expect(quill.getFormat(0)['header'], isNull);
      expect(quill.getFormat(4)['header'], isNull);
      expect(quill.getFormat(8)['header'], equals(2));
    });

    test('a multi-line insert with a block format formats every line', () {
      final quill = createTestQuill();
      quill.setContents(Delta()..insert('a\nb\nc\n', {'header': 1}));

      expect(quill.getFormat(0)['header'], equals(1));
      expect(quill.getFormat(2)['header'], equals(1));
      expect(quill.getFormat(4)['header'], equals(1));
    });
  });

  group('attribute diffing', () {
    test('an attribute the document already has is not re-applied', () {
      final quill = createTestQuill();
      quill.setContents(Delta()..insert('bold', {'bold': true}));

      final change = quill.updateContents(Delta()
        ..retain(4)
        ..insert('more', {'bold': true}));

      expect(change, isNotNull);
      expect(quill.getFormat(0, 8)['bold'], isTrue);
    });

    test('inserting plain text next to formatted text clears the format', () {
      final quill = createTestQuill();
      quill.setContents(Delta()
        ..insert('bold', {'bold': true})
        ..insert('\n'));

      quill.updateContents(Delta()
        ..retain(4)
        ..insert('plain'));

      expect(quill.getFormat(0, 4)['bold'], isTrue);
      expect(quill.getFormat(4, 5)['bold'], isNull);
    });
  });

  group('the resulting document matches the delta', () {
    test('inserting text without a trailing newline at the end', () {
      final quill = createTestQuill();
      quill.setContents(Delta()..insert('a\n'));

      quill.updateContents(Delta()
        ..retain(2)
        ..insert('b'));

      // The implicit newline the scroll adds is removed again, so the text is
      // exactly what the delta described.
      expect(quill.getText(), equals('a\nb\n'));
    });

    test('setContents round-trips a multi-line document', () {
      final quill = createTestQuill();
      final source = Delta()
        ..insert('title')
        ..insert('\n', {'header': 1})
        ..insert('body text')
        ..insert('\n')
        ..insert('item')
        ..insert('\n', {'list': 'bullet'});

      quill.setContents(source);

      expect(quill.getContents().toJson(), equals(source.toJson()));
    });

    test('an inline format survives a round trip', () {
      final quill = createTestQuill();
      final source = Delta()
        ..insert('plain ')
        ..insert('bold', {'bold': true})
        ..insert(' and ')
        ..insert('italic', {'italic': true})
        ..insert('\n');

      quill.setContents(source);

      expect(quill.getContents().toJson(), equals(source.toJson()));
    });
  });

  group('removeFormat', () {
    test('clears a block format (the list survives no more)', () {
      final quill = createTestQuill();
      quill.setContents(Delta()
        ..insert('item')
        ..insert('\n', {'list': 'bullet'}));

      quill.removeFormat(0, 4);

      expect(
        quill.getContents().toJson(),
        equals((Delta()..insert('item\n')).toJson()),
      );
    });

    test('clears inline formats too', () {
      final quill = createTestQuill();
      quill.setContents(Delta()
        ..insert('bold', {'bold': true})
        ..insert('\n'));

      quill.removeFormat(0, 4);

      expect(quill.getFormat(0, 4)['bold'], isNull);
      expect(quill.getText(), equals('bold\n'));
    });

    test('leaves the rest of the line alone', () {
      final quill = createTestQuill();
      quill.setContents(Delta()
        ..insert('keep', {'bold': true})
        ..insert('drop', {'italic': true})
        ..insert('\n'));

      quill.removeFormat(4, 4);

      expect(quill.getFormat(0, 4)['bold'], isTrue,
          reason: 'the prefix keeps its format');
      expect(quill.getFormat(4, 4)['italic'], isNull);
    });
  });
}
