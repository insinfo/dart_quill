import 'package:dart_quill/src/core/emitter.dart';
import 'package:dart_quill/src/core/selection.dart';
import 'package:dart_quill/src/delta/delta.dart';
import 'package:test/test.dart';

import '../../support/quill_test_helpers.dart';
import '../../support/test_helpers.dart';

/// G2.1 — `Quill.modify` (quill.ts:881-917): readOnly guard, SILENT
/// suppression and the no-change guard.
void main() {
  setUpAll(ensureQuillTestInitialized);

  setUp(() {
    final body = testAdapter.document.body;
    while (body.firstChild != null) {
      body.firstChild!.remove();
    }
  });

  test('editor is enabled by default and disable() flips it', () {
    final quill = createTestQuill();
    expect(quill.isEnabled(), isTrue);
    quill.disable();
    expect(quill.isEnabled(), isFalse);
    quill.enable();
    expect(quill.isEnabled(), isTrue);
  });

  test('USER edits are rejected while disabled', () {
    final quill = createTestQuill();
    quill.setSelection(const Range(0, 0));
    quill.disable();
    final change = quill.insertText(0, 'nope', source: EmitterSource.USER);
    expect(change.operations, isEmpty);
    expect(quill.getText(), isNot(contains('nope')));
  });

  test('API edits still apply while disabled', () {
    final quill = createTestQuill();
    quill.setSelection(const Range(0, 0));
    quill.disable();
    quill.insertText(0, 'api', source: EmitterSource.API);
    expect(quill.getText(), startsWith('api'));
  });

  test('editReadOnly lets a USER edit through', () {
    final quill = createTestQuill();
    quill.setSelection(const Range(0, 0));
    quill.disable();
    quill.editReadOnly(
        () => quill.insertText(0, 'forced', source: EmitterSource.USER));
    expect(quill.getText(), startsWith('forced'));
  });

  test('SILENT suppresses TEXT_CHANGE but still emits EDITOR_CHANGE', () {
    final quill = createTestQuill();
    quill.setSelection(const Range(0, 0));
    var textChanges = 0;
    var editorChanges = 0;
    quill.on(EmitterEvents.TEXT_CHANGE, (_, __, ___) => textChanges++);
    // EDITOR_CHANGE also fires for selection changes (faithful to the TS
    // emitter), so only count the text-change flavor here.
    quill.on(EmitterEvents.EDITOR_CHANGE, (name, _, __, ___) {
      if (name == EmitterEvents.TEXT_CHANGE) editorChanges++;
    });

    quill.insertText(0, 'silent', source: EmitterSource.SILENT);
    expect(textChanges, 0);
    expect(editorChanges, 1);

    quill.insertText(0, 'loud', source: EmitterSource.USER);
    expect(textChanges, 1);
    expect(editorChanges, 2);
  });

  test('a no-op change emits nothing', () {
    final quill = createTestQuill();
    quill.setSelection(const Range(0, 0));
    var events = 0;
    quill.on(EmitterEvents.EDITOR_CHANGE, (_, __, ___, ____) => events++);
    quill.updateContents(Delta(), source: EmitterSource.USER);
    expect(events, 0);
  });

  test('mutations return the change delta', () {
    final quill = createTestQuill();
    quill.setSelection(const Range(0, 0));
    final change = quill.insertText(0, 'hi', source: EmitterSource.API);
    expect(change.operations, isNotEmpty);
  });
}
