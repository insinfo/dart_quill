import 'package:dart_quill/src/platform/dom.dart';
import 'package:test/test.dart';

import '../../support/quill_test_helpers.dart';
import '../../support/test_helpers.dart';

/// Port of `referencias/quilljs/test/unit/formats/bold.spec.ts`.
void main() {
  setUpAll(ensureQuillTestInitialized);

  setUp(() {
    final body = testAdapter.document.body;
    while (body.firstChild != null) {
      body.firstChild!.remove();
    }
  });

  group('Bold', () {
    test('optimize and merge', () {
      final scroll = createScrollWithFormats(
        '<p><strong>a</strong>b<strong>c</strong></p>',
        ['formats/bold'],
      );

      // The `<b>` a browser (or a paste) can drop in the middle: it must be
      // normalized to `<strong>` and then merged with both neighbours.
      final paragraph = scroll.element.firstChild as DomElement;
      final bold = testAdapter.document.createElement('b');
      bold.append(paragraph.childNodes[1]);
      paragraph.insertBefore(bold, paragraph.lastChild);

      scroll.update();

      expect(scroll.element, EqualHTML('<p><strong>abc</strong></p>'));
    });
  });
}
