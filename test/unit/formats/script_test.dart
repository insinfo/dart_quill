/// Port of `referencias/quilljs/test/unit/formats/script.spec.ts` (Quill 2.0.3).
import 'package:dart_quill/src/blots/scroll.dart';
import 'package:dart_quill/src/core/editor.dart';
import 'package:test/test.dart';

import '../../support/quill_test_helpers.dart';
import '../../support/test_helpers.dart';

void main() {
  setUpAll(ensureQuillTestInitialized);

  setUp(() {
    final body = testAdapter.document.body;
    while (body.firstChild != null) {
      body.firstChild!.remove();
    }
  });

  Scroll scroll(String html) =>
      createScroll(html, registry: registryWithFormats(['formats/script']));

  group('Script', () {
    test('add', () {
      final editor =
          Editor(scroll('<p>a<sup>2</sup> + b2 = c<sup>2</sup></p>'));
      editor.formatText(6, 1, 'script', 'super');

      expectHTML(editor.scroll.element,
          '<p>a<sup>2</sup> + b<sup>2</sup> = c<sup>2</sup></p>');
    });

    test('remove', () {
      final editor = Editor(scroll('<p>a<sup>2</sup> + b<sup>2</sup></p>'));
      editor.formatText(1, 1, 'script', false);

      expectHTML(editor.scroll.element, '<p>a2 + b<sup>2</sup></p>');
    });

    test('replace', () {
      final editor = Editor(scroll('<p>a<sup>2</sup> + b<sup>2</sup></p>'));
      editor.formatText(1, 1, 'script', 'sub');

      expectHTML(editor.scroll.element, '<p>a<sub>2</sub> + b<sup>2</sup></p>');
    });
  });
}
