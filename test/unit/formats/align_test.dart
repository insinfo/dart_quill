/// Port of `referencias/quilljs/test/unit/formats/align.spec.ts` (Quill 2.0.3).
///
/// Case for case, with the upstream expectations verbatim.
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
      createScroll(html, registry: registryWithFormats(['formats/align']));

  group('Align', () {
    test('add', () {
      final editor = Editor(scroll('<p>0123</p>'));
      editor.formatText(4, 1, 'align', 'center');

      expect(
        editor.getContents().toJson(),
        (Delta()
              ..insert('0123')
              ..insert('\n', {'align': 'center'}))
            .toJson(),
      );
      expectHTML(editor.scroll.element, '<p class="ql-align-center">0123</p>');
    });

    test('remove', () {
      final editor = Editor(scroll('<p class="ql-align-center">0123</p>'));
      editor.formatText(4, 1, 'align', false);

      expect(editor.getContents().toJson(),
          (Delta()..insert('0123\n')).toJson());
      expectHTML(editor.scroll.element, '<p>0123</p>');
    });

    test('whitelist', () {
      final editor = Editor(scroll('<p class="ql-align-center">0123</p>'));
      editor.formatText(4, 1, 'align', 'middle');

      expect(
        editor.getContents().toJson(),
        (Delta()
              ..insert('0123')
              ..insert('\n', {'align': 'center'}))
            .toJson(),
        reason: 'a value outside the whitelist must be ignored',
      );
      expectHTML(editor.scroll.element, '<p class="ql-align-center">0123</p>');
    });

    test('invalid scope', () {
      final editor = Editor(scroll('<p>0123</p>'));
      editor.formatText(1, 2, 'align', 'center');

      expect(editor.getContents().toJson(),
          (Delta()..insert('0123\n')).toJson(),
          reason: 'align is a block format: an inline range does nothing');
      expectHTML(editor.scroll.element, '<p>0123</p>');
    });
  });
}
