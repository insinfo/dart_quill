/// Port of `referencias/quilljs/test/unit/formats/color.spec.ts` (Quill 2.0.3).
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
      registry: registryWithFormats(['formats/color', 'formats/bold']));

  group('Color', () {
    test('add', () {
      final editor = Editor(scroll('<p>0123</p>'));
      editor.formatText(1, 2, 'color', 'red');

      expect(
        editor.getContents().toJson(),
        (Delta()
              ..insert('0')
              ..insert('12', {'color': 'red'})
              ..insert('3\n'))
            .toJson(),
      );
      expectHTML(
          editor.scroll.element, '<p>0<span style="color: red;">12</span>3</p>');
    });

    test('remove', () {
      final editor =
          Editor(scroll('<p>0<strong style="color: red;">12</strong>3</p>'));
      editor.formatText(1, 2, 'color', false);

      expect(
        editor.getContents().toJson(),
        (Delta()
              ..insert('0')
              ..insert('12', {'bold': true})
              ..insert('3\n'))
            .toJson(),
      );
      expectHTML(editor.scroll.element, '<p>0<strong>12</strong>3</p>');
    });

    test('remove unwrap', () {
      final editor =
          Editor(scroll('<p>0<span style="color: red;">12</span>3</p>'));
      editor.formatText(1, 2, 'color', false);

      expect(editor.getContents().toJson(),
          (Delta()..insert('0123\n')).toJson());
      expectHTML(editor.scroll.element, '<p>0123</p>');
    });

    test('invalid scope', () {
      final editor = Editor(scroll('<p>0123</p>'));
      editor.formatText(4, 1, 'color', 'red');

      expect(editor.getContents().toJson(),
          (Delta()..insert('0123\n')).toJson(),
          reason: 'color is inline: formatting the newline does nothing');
      expectHTML(editor.scroll.element, '<p>0123</p>');
    });
  });
}
