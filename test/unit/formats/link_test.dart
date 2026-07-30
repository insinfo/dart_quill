/// Port of `referencias/quilljs/test/unit/formats/link.spec.ts` (Quill 2.0.3).
import 'package:dart_quill/src/blots/scroll.dart';
import 'package:dart_quill/src/core/editor.dart';
import 'package:dart_quill/src/dependencies/dart_quill_delta/dart_quill_delta.dart';
import 'package:dart_quill/src/formats/link.dart';
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
      registry: registryWithFormats(['formats/link', 'formats/size']));

  group('Link', () {
    test('add', () {
      final editor = Editor(scroll('<p>0123</p>'));
      editor.formatText(1, 2, 'link', 'https://quilljs.com');

      expect(
        editor.getContents().toJson(),
        (Delta()
              ..insert('0')
              ..insert('12', {'link': 'https://quilljs.com'})
              ..insert('3\n'))
            .toJson(),
      );
      expectHTML(
        editor.scroll.element,
        '<p>0<a href="https://quilljs.com" rel="noopener noreferrer" '
            'target="_blank">12</a>3</p>',
      );
    });

    test('add invalid', () {
      final editor = Editor(scroll('<p>0123</p>'));
      editor.formatText(1, 2, 'link', 'javascript:alert(0);');

      expect(
        editor.getContents().toJson(),
        (Delta()
              ..insert('0')
              ..insert('12', {'link': Link.kSanitizedUrl})
              ..insert('3\n'))
            .toJson(),
      );
    });

    test('add non-whitelisted protocol', () {
      final editor = Editor(scroll('<p>0123</p>'));
      editor.formatText(1, 2, 'link', 'gopher://quilljs.com');

      expect(
        editor.getContents().toJson(),
        (Delta()
              ..insert('0')
              ..insert('12', {'link': Link.kSanitizedUrl})
              ..insert('3\n'))
            .toJson(),
      );
      expectHTML(
        editor.scroll.element,
        '<p>0<a href="about:blank" rel="noopener noreferrer" '
            'target="_blank">12</a>3</p>',
      );
    });

    test('change', () {
      final editor = Editor(scroll(
          '<p>0<a href="https://github.com" target="_blank" '
          'rel="noopener noreferrer">12</a>3</p>'));
      editor.formatText(1, 2, 'link', 'https://quilljs.com');

      expect(
        editor.getContents().toJson(),
        (Delta()
              ..insert('0')
              ..insert('12', {'link': 'https://quilljs.com'})
              ..insert('3\n'))
            .toJson(),
      );
      expectHTML(
        editor.scroll.element,
        '<p>0<a href="https://quilljs.com" rel="noopener noreferrer" '
            'target="_blank">12</a>3</p>',
      );
    });

    test('remove', () {
      final editor = Editor(scroll(
          '<p>0<a class="ql-size-large" href="https://quilljs.com" '
          'rel="noopener noreferrer" target="_blank">12</a>3</p>'));
      editor.formatText(1, 2, 'link', false);

      expect(
        editor.getContents().toJson(),
        (Delta()
              ..insert('0')
              ..insert('12', {'size': 'large'})
              ..insert('3\n'))
            .toJson(),
      );
      expectHTML(editor.scroll.element,
          '<p>0<span class="ql-size-large">12</span>3</p>');
    });
  });
}
