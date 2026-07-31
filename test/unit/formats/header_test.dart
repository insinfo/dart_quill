/// Port of `referencias/quilljs/test/unit/formats/header.spec.ts` (Quill 2.0.3).
import 'package:dart_quill/src/blots/scroll.dart';
import 'package:dart_quill/src/core/editor.dart';
import 'package:dart_quill/src/delta/delta.dart';
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

  Scroll scroll(String html) => createScroll(html,
      registry: registryWithFormats(['formats/header', 'formats/italic']));

  group('Header', () {
    test('add', () {
      final editor = Editor(scroll('<p><em>0123</em></p>'));
      editor.formatText(4, 1, 'header', 1);

      expect(
        editor.getContents().toJson(),
        (Delta()
              ..insert('0123', {'italic': true})
              ..insert('\n', {'header': 1}))
            .toJson(),
      );
      expectHTML(editor.scroll.element, '<h1><em>0123</em></h1>');
    });

    test('remove', () {
      final editor = Editor(scroll('<h1><em>0123</em></h1>'));
      editor.formatText(4, 1, 'header', false);

      expect(
        editor.getContents().toJson(),
        (Delta()
              ..insert('0123', {'italic': true})
              ..insert('\n'))
            .toJson(),
      );
      expectHTML(editor.scroll.element, '<p><em>0123</em></p>');
    });

    test('change', () {
      final editor = Editor(scroll('<h1><em>0123</em></h1>'));
      editor.formatText(4, 1, 'header', 2);

      expect(
        editor.getContents().toJson(),
        (Delta()
              ..insert('0123', {'italic': true})
              ..insert('\n', {'header': 2}))
            .toJson(),
      );
      expectHTML(editor.scroll.element, '<h2><em>0123</em></h2>');
    });
  });
}
