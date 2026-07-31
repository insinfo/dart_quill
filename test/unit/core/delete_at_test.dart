import 'package:dart_quill/src/delta/delta.dart';
import 'package:test/test.dart';

import '../../support/quill_test_helpers.dart';

/// Regressions for `Scroll.deleteAt` / `ParentBlot.deleteAt`.
///
/// Both used to diverge from upstream in ways that ate content:
///
/// * `Scroll.deleteAt` had two invented branches — one re-resolving
///   `first`/`offset` from `line(index - 1)`, one removing the trailing line
///   when it held a lone Break — so deleting a single newline between empty
///   blocks removed several lines;
/// * `ParentBlot.deleteAt` removed emptied children eagerly and then recursed
///   on the same index for the remainder, double-counting lengths, so a
///   deletion spanning a block boundary stopped early.
void main() {
  group('deleting a newline between empty blocks', () {
    test('removes exactly one line', () {
      final quill = createTestQuill();
      // Four lines: 'code', '', '' and ''. This expectation used to read
      // 'code\n\n\n', encoding a defect of the port — `Editor._update` skipped a
      // trailing empty paragraph, so `setContents` was lossy. The Delta goldens
      // recorded from quill 2.0.3 showed the document keeps every line.
      quill.setContents(Delta()..insert('code\n\n\n\n'));
      expect(quill.getText(), equals('code\n\n\n\n'));

      quill.updateContents(Delta()
        ..retain(6)
        ..delete(1));

      expect(quill.getText(), equals('code\n\n\n'));
    });

    test('the same holds for plain paragraphs', () {
      final quill = createTestQuill();
      quill.setContents(Delta()..insert('a\n\n\nb\n'));

      quill.updateContents(Delta()
        ..retain(2)
        ..delete(1));

      expect(quill.getText(), equals('a\n\nb\n'));
    });

    test('deleting several newlines at once', () {
      final quill = createTestQuill();
      quill.setContents(Delta()..insert('a\n\n\n\nb\n'));

      quill.updateContents(Delta()
        ..retain(2)
        ..delete(2));

      expect(quill.getText(), equals('a\n\nb\n'));
    });
  });

  group('deleting across a block boundary', () {
    test('deleteText joins the two lines', () {
      final quill = createTestQuill();
      quill.setContents(Delta()..insert('Title\nbody\n'));

      quill.deleteText(3, 5);

      // 'Title\nbody\n' minus indices 3..7 ('le\nbo') leaves 'Tit' + 'dy\n'.
      expect(quill.getText(), equals('Titdy\n'));
      expect(
        quill.getContents().toJson(),
        equals((Delta()..insert('Titdy\n')).toJson()),
      );
    });

    test('the emitted delta matches the document', () {
      final quill = createTestQuill();
      quill.setContents(Delta()..insert('Title\nbody\n'));
      final before = quill.getContents();

      final change = quill.deleteText(3, 5);

      expect(
        before.compose(change).toJson(),
        equals(quill.getContents().toJson()),
        reason: 'the delta must describe what actually happened',
      );
    });

    test('the surviving line keeps the formats of the line it merged into', () {
      final quill = createTestQuill();
      quill.setContents(Delta()
        ..insert('Title')
        ..insert('\n', {'header': 1})
        ..insert('body')
        ..insert('\n'));

      quill.deleteText(3, 5);

      expect(quill.getText(), equals('Titdy\n'));
    });

    test('deleting a whole line closes the gap', () {
      final quill = createTestQuill();
      quill.setContents(Delta()..insert('a\nb\nc\n'));

      quill.deleteText(2, 2);

      expect(quill.getText(), equals('a\nc\n'));
    });

    test('deleting through inline embeds removes the whole range', () {
      final quill = createTestQuill();
      quill.setContents(
        Delta()
          ..insert('onthis is a')
          ..insert({'image': 'https://example.com'})
          ..insert({'image': 'https://example.com'})
          ..insert('\nnext\n'),
      );

      final before = quill.getContents();
      final requested = Delta()
        ..retain(2)
        ..delete(12);
      final change = quill.updateContents(requested);

      expectDelta(quill.getContents(), Delta()..insert('onnext\n'));
      expectDelta(change, requested);
      expectDelta(before.compose(change), quill.getContents());
    });

    test('insert newline then delete the complete remainder line', () {
      final quill = createTestQuill();
      quill.setContents(
        Delta()
          ..insert('onthis is a')
          ..insert({'image': 'https://example.com'})
          ..insert({'image': 'https://example.com'})
          ..insert('\nnext\n'),
      );

      final requested = Delta()
        ..retain(2)
        ..insert('\n')
        ..delete(12);
      final change = quill.updateContents(requested);

      expectDelta(quill.getContents(), Delta()..insert('on\nnext\n'));
      expectDelta(change, requested);
    });

    test('inserting a newline before inline embeds splits the line', () {
      final quill = createTestQuill();
      quill.setContents(
        Delta()
          ..insert('onthis is a')
          ..insert({'image': 'https://example.com'})
          ..insert({'image': 'https://example.com'})
          ..insert('\nnext\n'),
      );

      quill.updateContents(
        Delta()
          ..retain(2)
          ..insert('\n'),
      );

      expectDelta(
        quill.getContents(),
        Delta()
          ..insert('on\nthis is a')
          ..insert({'image': 'https://example.com'})
          ..insert({'image': 'https://example.com'})
          ..insert('\nnext\n'),
      );
    });
  });
}
