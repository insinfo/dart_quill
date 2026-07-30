/// Undo/redo must restore the *selection* the change was made from, not just
/// the text — the behaviour `referencias/quilljs/test/e2e/history.spec.ts`
/// covers in its `selection` group.
///
/// Upstream keeps that state in `History.currentRange`, fed from a single
/// `EDITOR_CHANGE` listener (history.ts:38-56). Listening to SELECTION_CHANGE
/// and TEXT_CHANGE separately is not equivalent: `EDITOR_CHANGE` is emitted
/// for SILENT text changes too, and the order the two arrive in is what
/// decides whether the range recorded with a change is the one that produced
/// it.
library;

import 'package:dart_quill/src/core/emitter.dart';
import 'package:dart_quill/src/core/quill.dart';
import 'package:dart_quill/src/core/selection.dart';
import 'package:dart_quill/src/dependencies/dart_quill_delta/dart_quill_delta.dart';
import 'package:test/test.dart';

import '../../support/quill_test_helpers.dart';

void main() {
  late Quill quill;

  setUp(() {
    quill = createTestQuill(
      initialHtml: '<p>1234</p>',
      modules: {
        'history': {'delay': 0}
      },
    );
    quill.history.clear();
  });

  Map<String, int>? selection() {
    final range = quill.getSelection();
    return range == null ? null : {'index': range.index, 'length': range.length};
  }

  test('undo restores the range a user edit was made from', () {
    quill.setSelection(const Range(1, 2), source: EmitterSource.USER);
    quill.updateContents(
      Delta()
        ..retain(1)
        ..delete(2)
        ..insert('a'),
      source: EmitterSource.USER,
    );

    quill.history.undo();

    expect(quill.getText(), '1234\n');
    expect(selection(), {'index': 1, 'length': 2},
        reason: 'the selection that produced the change comes back with it');
  });

  test('redo restores the range the change left behind', () {
    quill.setSelection(const Range(1, 2), source: EmitterSource.USER);
    quill.updateContents(
      Delta()
        ..retain(1)
        ..delete(2),
      source: EmitterSource.USER,
    );
    quill.history.undo();
    quill.history.redo();

    expect(selection(), {'index': 1, 'length': 0});
  });

  test('a formatting change keeps the range on both sides', () {
    quill.setSelection(const Range(1, 2), source: EmitterSource.USER);
    quill.formatText(1, 2, 'bold', true, source: EmitterSource.USER);

    quill.history.undo();
    expect(selection(), {'index': 1, 'length': 2});
    quill.history.redo();
    expect(selection(), {'index': 1, 'length': 2});
  });

  test('a silent text change still shifts the recorded range', () {
    quill.setSelection(const Range(3, 0), source: EmitterSource.USER);
    // Parity history.ts:38-56 — EDITOR_CHANGE carries SILENT text changes, so
    // `currentRange` is transformed by them. Missing this makes every later
    // undo restore a range that is off by the silent edit's length.
    quill.updateContents(
      Delta()..insert('xx'),
      source: EmitterSource.SILENT,
    );
    quill.setSelection(const Range(5, 0), source: EmitterSource.SILENT);
    quill.insertText(5, 'a', source: EmitterSource.USER);

    quill.history.undo();
    expect(selection(), {'index': 5, 'length': 0});
  });

  test('an api change is transformed, not recorded, under userOnly', () {
    quill.history.options.userOnly = true;
    quill.setSelection(const Range(1, 2), source: EmitterSource.USER);
    quill.updateContents(
      Delta()
        ..retain(1)
        ..delete(2),
      source: EmitterSource.USER,
    );
    quill.updateContents(
      Delta()..insert('0'),
      source: EmitterSource.API,
    );

    quill.history.undo();
    expect(quill.getText(), '01234\n',
        reason: 'the api insert survives the undo of the user delete');
    expect(selection(), {'index': 2, 'length': 2},
        reason: 'the recorded range is shifted by the api change');
  });
}
