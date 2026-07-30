import 'package:dart_quill/src/core/composition.dart';
import 'package:dart_quill/src/core/emitter.dart';
import 'package:test/test.dart';

import '../../support/fake_dom.dart';
import '../../support/quill_test_helpers.dart';

/// Port of `referencias/quilljs/test/unit/core/composition.spec.ts`.
void main() {
  setUpAll(ensureQuillTestInitialized);

  test('Composition triggers events on compositionstart', () {
    final quill = createTestQuill();
    final emitter = Emitter();
    Composition(quill.scroll, emitter);
    final calls = <(String, dynamic)>[];
    emitter.on(
        EmitterEvents.COMPOSITION_BEFORE_START,
        (dynamic event) =>
            calls.add((EmitterEvents.COMPOSITION_BEFORE_START, event)));
    emitter.on(EmitterEvents.COMPOSITION_START,
        (dynamic event) => calls.add((EmitterEvents.COMPOSITION_START, event)));

    final event = FakeDomEvent('compositionstart', quill.root);
    (quill.root as FakeDomElement).dispatchEvent('compositionstart', event);

    expect(calls, [
      (EmitterEvents.COMPOSITION_BEFORE_START, event),
      (EmitterEvents.COMPOSITION_START, event),
    ]);
  });
}
