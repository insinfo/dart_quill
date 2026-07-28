import 'package:dart_quill/src/core/quill.dart';
import 'package:dart_quill/src/core/selection.dart';
import 'package:dart_quill/src/dependencies/dart_quill_delta/dart_quill_delta.dart';
import 'package:test/test.dart';

import '../../support/quill_test_helpers.dart';
import '../../support/test_helpers.dart';

/// G1.10 — Scroll.insertContents / Editor.insertContents (scroll.ts:139-210).
void main() {
  setUpAll(ensureQuillTestInitialized);

  setUp(() {
    final body = testAdapter.document.body;
    while (body.firstChild != null) {
      body.firstChild!.remove();
    }
  });

  Quill setup() {
    final quill = createTestQuill();
    quill.setSelection(const Range(0, 0));
    return quill;
  }

  test('inserts multiline text splitting into blocks', () {
    final quill = setup();
    quill.editor.insertContents(
      0,
      Delta()
        ..insert('abc\ndef\nghi'),
    );
    final text = quill.getText();
    expect(text, startsWith('abc\ndef\nghi'));
  });

  test('applies block attributes to the inserted lines', () {
    final quill = setup();
    quill.editor.insertContents(
      0,
      Delta()
        ..insert('title')
        ..insert('\n', {'header': 2})
        ..insert('body'),
    );
    final contents = quill.getContents();
    final headerOp = contents.operations
        .firstWhere((op) => op.attributes?.containsKey('header') ?? false);
    expect(headerOp.attributes!['header'], 2);
    expect(quill.getText(), startsWith('title\nbody'));
  });

  test('applies inline attributes through the diff path', () {
    final quill = setup();
    quill.editor.insertContents(
      0,
      Delta()..insert('bold', {'bold': true}),
    );
    final contents = quill.getContents();
    final boldOp = contents.operations
        .firstWhere((op) => op.attributes?.containsKey('bold') ?? false);
    expect(boldOp.data, 'bold');
    expect(boldOp.attributes!['bold'], true);
  });

  test('inserts into the middle of an existing line', () {
    final quill = setup();
    quill.insertText(0, 'helloworld');
    quill.editor.insertContents(5, Delta()..insert('X\nY'));
    expect(quill.getText(), startsWith('helloX\nYworld'));
  });
}
