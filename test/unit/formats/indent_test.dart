/// Port of `referencias/quilljs/test/unit/formats/indent.spec.ts` (Quill 2.0.3).
///
/// The list blots come from the base registry, as they do upstream.
import 'package:dart_quill/src/blots/scroll.dart';
import 'package:dart_quill/src/core/editor.dart';
import 'package:dart_quill/src/dependencies/dart_quill_delta/dart_quill_delta.dart';
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
      createScroll(html, registry: registryWithFormats(['formats/indent']));

  group('Indent', () {
    test('+1', () {
      final editor =
          Editor(scroll('<ol><li data-list="bullet">0123</li></ol>'));
      editor.formatText(4, 1, 'indent', '+1');

      expect(
        editor.getContents().toJson(),
        (Delta()
              ..insert('0123')
              ..insert('\n', {'list': 'bullet', 'indent': 1}))
            .toJson(),
      );
      expectHTML(editor.scroll.element,
          '<ol><li class="ql-indent-1" data-list="bullet">0123</li></ol>');
    });

    test('-1', () {
      final editor = Editor(scroll(
          '<ol><li data-list="bullet" class="ql-indent-1">0123</li></ol>'));
      editor.formatText(4, 1, 'indent', '-1');

      expect(
        editor.getContents().toJson(),
        (Delta()
              ..insert('0123')
              ..insert('\n', {'list': 'bullet'}))
            .toJson(),
      );
      expectHTML(
          editor.scroll.element, '<ol><li data-list="bullet">0123</li></ol>');
    });

    test('1', () {
      final editor = Editor(scroll('<p>abc</p>'));
      editor.formatText(3, 1, 'indent', 1);

      expect(
        editor.getContents().toJson(),
        (Delta()
              ..insert('abc')
              ..insert('\n', {'indent': 1}))
            .toJson(),
      );
      expectHTML(editor.scroll.element, '<p class="ql-indent-1">abc</p>');
    });
  });
}
