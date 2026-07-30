import 'package:dart_quill/src/blots/cursor.dart';
import 'package:dart_quill/src/core/selection.dart';
import 'package:dart_quill/src/dependencies/dart_quill_delta/dart_quill_delta.dart';
import 'package:test/test.dart';

import '../../support/fake_dom.dart';
import '../../support/quill_test_helpers.dart';
import '../../support/test_helpers.dart';

/// Port of `referencias/quilljs/test/unit/blots/scroll.spec.ts`.
///
/// The upstream `user change` case (a native DOM edit reaching the model
/// through the MutationObserver) has no VM counterpart — the fake DOM has no
/// observer — and lives in `test/browser/model_reconcile_test.dart`, against
/// a real one.
void main() {
  setUpAll(ensureQuillTestInitialized);

  setUp(() {
    final body = testAdapter.document.body;
    while (body.firstChild != null) {
      body.firstChild!.remove();
    }
  });

  group('Scroll', () {
    test('initialize empty document', () {
      final scroll = createScrollWithFormats('', const []);
      expect(scroll.element, EqualHTML('<p><br></p>'));
    });

    // Upstream's `api change` (an API edit emitting SCROLL_OPTIMIZE) belongs
    // to the browser suite: the event carries the MutationRecords of the edit
    // and only fires when there are any (`scroll.ts` emits under
    // `mutations.length > 0`). Off-browser there is no observer to produce
    // them, so asserting it here would be asserting the fake DOM, not Quill.
    // It lives in `test/browser/model_reconcile_test.dart`.

    test('prevent dragstart', () {
      final scroll = createScrollWithFormats('<p>Hello World!</p>', const []);
      final dragstart = FakeDomEvent('dragstart');
      (scroll.element as FakeDomElement).dispatchEvent('dragstart', dragstart);
      expect(dragstart.defaultPrevented, isTrue);
    });

    group('leaf()', () {
      test('text', () {
        final scroll = createScrollWithFormats('<p>Tests</p>', const []);
        final entry = scroll.leaf(2);
        expect(entry.key?.value(), 'Tests');
        expect(entry.value, 2);
      });

      test('precise', () {
        final scroll = createScrollWithFormats(
          '<p><u>0</u><s>1</s><u>2</u><s>3</s><u>4</u></p>',
          ['formats/underline', 'formats/strike'],
        );
        final entry = scroll.leaf(3);
        expect(entry.key?.value(), '2');
        expect(entry.value, 1);
      });

      test('newline', () {
        final scroll =
            createScrollWithFormats('<p>0123</p><p>5678</p>', const []);
        final entry = scroll.leaf(4);
        expect(entry.key?.value(), '0123');
        expect(entry.value, 4);
      });

      test('cursor', () {
        final scroll = createScrollWithFormats(
          '<p><u>0</u>1<u>2</u></p>',
          ['formats/underline', 'formats/strike'],
        );
        final selection = Selection(scroll, scroll.emitter);
        selection.setRange(const Range(2));
        selection.format('strike', true);
        final entry = scroll.leaf(2);
        expect(entry.key, isA<Cursor>());
        expect(entry.value, 0);
      });

      test('beyond document', () {
        final scroll = createScrollWithFormats('<p>Test</p>', const []);
        final entry = scroll.leaf(10);
        expect(entry.key, isNull);
        expect(entry.value, -1);
      });
    });

    group('insertContents()', () {
      test('does not mutate the input', () {
        final scroll = createScrollWithFormats('<p>Test</p>', const []);
        final delta = Delta()..insert('\n');
        final clonedOps = delta.toJson();
        scroll.insertContents(0, delta);
        expect(delta.toJson(), clonedOps);
      });
    });
  });
}
