/// `BlockBlot.format` (parchment block.ts:49-63).
///
/// The branch that matters is the falsy one: a falsy value reverts the line to
/// a plain block ONLY when the format named is the blot's own. Applying a
/// falsy value for a *different* block format has to be a no-op — and getting
/// that wrong is silent data loss, because the line keeps rendering, just
/// stripped of the format it actually had.
///
/// Found by `test/fuzz/editor_test.dart` (seed 55934): the change
/// `{list: 'checked', blockquote: null}` on a list line produced a bare
/// paragraph instead of a checked list item.
library;

import 'package:dart_quill/src/core/emitter.dart';
import 'package:dart_quill/src/core/quill.dart';
import 'package:dart_quill/src/dependencies/dart_quill_delta/dart_quill_delta.dart';
import 'package:test/test.dart';

import '../../support/quill_test_helpers.dart';

void main() {
  setUpAll(ensureQuillTestInitialized);

  Quill quill(Delta contents) {
    final editor = createTestQuill();
    editor.setContents(contents);
    return editor;
  }

  test('a falsy value for another block format leaves the line alone', () {
    final editor = quill(Delta()
      ..insert('\n', {'list': 'ordered'}));

    editor.formatLine(0, 1, 'blockquote', null, source: EmitterSource.API);

    expect(editor.getContents().toJson(), [
      {
        'insert': '\n',
        'attributes': {'list': 'ordered'}
      }
    ]);
  });

  test('the two together apply as one change, like upstream', () {
    final editor = quill(Delta()..insert('\n', {'list': 'ordered'}));

    // The exact change the fuzzer produced.
    final change = editor.updateContents(
      Delta()
        ..retain(1, {'list': 'checked', 'blockquote': null}),
      source: EmitterSource.API,
    );

    expect(editor.getContents().toJson(), [
      {
        'insert': '\n',
        'attributes': {'list': 'checked'}
      }
    ]);
    expect(change.toJson(), [
      {
        'retain': 1,
        'attributes': {'list': 'checked', 'blockquote': null}
      }
    ], reason: 'the emitted change must describe exactly what was asked');
  });

  test('a falsy value for the line own format reverts it to a paragraph', () {
    final editor = quill(Delta()..insert('\n', {'blockquote': true}));

    editor.formatLine(0, 1, 'blockquote', false, source: EmitterSource.API);

    expect(editor.getContents().toJson(), [
      {'insert': '\n'}
    ]);
  });

  test('a header cleared by list:null keeps its header', () {
    final editor = quill(Delta()
      ..insert('t')
      ..insert('\n', {'header': 2}));

    editor.formatLine(0, 2, 'list', null, source: EmitterSource.API);

    expect(editor.getContents().toJson(), [
      {'insert': 't'},
      {
        'insert': '\n',
        'attributes': {'header': 2}
      }
    ]);
  });

  test('a block attributor set to null is still removed', () {
    final editor = quill(Delta()
      ..insert('t')
      ..insert('\n', {'align': 'center', 'blockquote': true}));

    editor.formatLine(0, 2, 'align', null, source: EmitterSource.API);

    expect(editor.getContents().toJson(), [
      {'insert': 't'},
      {
        'insert': '\n',
        'attributes': {'blockquote': true}
      }
    ], reason: 'attributors keep the falsy-means-remove behaviour');
  });
}
