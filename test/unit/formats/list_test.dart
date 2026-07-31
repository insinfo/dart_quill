import 'package:dart_quill/src/core/editor.dart';
import 'package:dart_quill/src/delta/delta.dart';
import 'package:test/test.dart';

import '../../support/quill_test_helpers.dart';
import '../../support/test_helpers.dart';

/// Port of `referencias/quilljs/test/unit/formats/list.spec.ts`.
///
/// The list model was rewritten in G10.10 to the upstream shape (container is
/// always `<ol>`; the whole format lives in each `<li data-list>`), so this is
/// the spec that proves it.

const String _video =
    'https://www.youtube.com/embed/QHH3iSeDBLo?showinfo=0';

Editor _createEditor(String html) => Editor(createScrollWithFormats(html, [
      'formats/list',
      'formats/indent',
      'attributors/class/align',
      'formats/video',
    ]));

void main() {
  setUpAll(ensureQuillTestInitialized);

  setUp(() {
    final body = testAdapter.document.body;
    while (body.firstChild != null) {
      body.firstChild!.remove();
    }
  });

  group('List', () {
    test('add', () {
      final editor = _createEditor('''
        <p>0123</p>
        <p>5678</p>
        <p>0123</p>''');
      editor.formatText(9, 1, 'list', 'ordered');
      expectDelta(
        editor.getDelta(),
        Delta()
          ..insert('0123\n5678')
          ..insert('\n', {'list': 'ordered'})
          ..insert('0123\n'),
      );
      expect(
        editor.scroll.element,
        EqualHTML('''
          <p>0123</p>
          <ol>
            <li data-list="ordered">5678</li>
          </ol>
          <p>0123</p>
        '''),
      );
    });

    test('checklist', () {
      final editor = _createEditor('''
        <p>0123</p>
        <p>5678</p>
        <p>0123</p>
      ''');
      editor.scroll.element.classes.add('ql-editor');
      editor.formatText(4, 1, 'list', 'checked');
      editor.formatText(9, 1, 'list', 'unchecked');
      expectDelta(
        editor.getDelta(),
        Delta()
          ..insert('0123')
          ..insert('\n', {'list': 'checked'})
          ..insert('5678')
          ..insert('\n', {'list': 'unchecked'})
          ..insert('0123\n'),
      );
      expect(
        editor.scroll.element,
        EqualHTML('''
          <ol>
            <li data-list="checked">0123</li>
            <li data-list="unchecked">5678</li>
          </ol>
          <p>0123</p>
        '''),
      );
    });

    test('remove', () {
      final editor = _createEditor('''
        <p>0123</p>
        <ol><li data-list="ordered">5678</li></ol>
        <p>0123</p>
      ''');
      editor.formatText(9, 1, 'list', null);
      expectDelta(editor.getDelta(), Delta()..insert('0123\n5678\n0123\n'));
      expect(
        editor.scroll.element,
        EqualHTML('''
          <p>0123</p>
          <p>5678</p>
          <p>0123</p>
        '''),
      );
    });

    test('replace', () {
      final editor = _createEditor('''
        <p>0123</p>
        <ol><li data-list="ordered">5678</li></ol>
        <p>0123</p>
      ''');
      editor.formatText(9, 1, 'list', 'bullet');
      expectDelta(
        editor.getDelta(),
        Delta()
          ..insert('0123\n5678')
          ..insert('\n', {'list': 'bullet'})
          ..insert('0123\n'),
      );
      expect(
        editor.scroll.element,
        EqualHTML('''
          <p>0123</p>
          <ol>
            <li data-list="bullet">5678</li>
          </ol>
          <p>0123</p>
        '''),
      );
    });

    test('replace checklist with bullet', () {
      final editor = _createEditor('''
        <ol>
          <li data-list="checked">0123</li>
        </ol>
      ''');
      editor.formatText(4, 1, 'list', 'bullet');
      expectDelta(
        editor.getDelta(),
        Delta()
          ..insert('0123')
          ..insert('\n', {'list': 'bullet'}),
      );
      expect(
        editor.scroll.element,
        EqualHTML('''
          <ol>
            <li data-list="bullet">0123</li>
          </ol>
        '''),
      );
    });

    test('replace with attributes', () {
      final editor = _createEditor(
        '<ol><li data-list="ordered" class="ql-align-center">0123</li></ol>',
      );
      editor.formatText(4, 1, 'list', 'bullet');
      expectDelta(
        editor.getDelta(),
        Delta()
          ..insert('0123')
          ..insert('\n', {'align': 'center', 'list': 'bullet'}),
      );
      expect(
        editor.scroll.element,
        EqualHTML('''
          <ol>
            <li class="ql-align-center" data-list="bullet">0123</li>
          </ol>
        '''),
      );
    });

    test('format merge', () {
      final editor = _createEditor('''
        <ol><li data-list="ordered">0123</li></ol>
        <p>5678</p>
        <ol><li data-list="ordered">0123</li></ol>
      ''');
      editor.formatText(9, 1, 'list', 'ordered');
      expectDelta(
        editor.getDelta(),
        Delta()
          ..insert('0123')
          ..insert('\n', {'list': 'ordered'})
          ..insert('5678')
          ..insert('\n', {'list': 'ordered'})
          ..insert('0123')
          ..insert('\n', {'list': 'ordered'}),
      );
      expect(
        editor.scroll.element,
        EqualHTML('''
          <ol>
            <li data-list="ordered">0123</li>
            <li data-list="ordered">5678</li>
            <li data-list="ordered">0123</li>
          </ol>
        '''),
      );
    });

    test('delete merge', () {
      final editor = _createEditor('''
        <ol><li data-list="ordered">0123</li></ol>
        <p>5678</p>
        <ol><li data-list="ordered">0123</li></ol>''');
      editor.deleteText(5, 5);
      expectDelta(
        editor.getDelta(),
        Delta()
          ..insert('0123')
          ..insert('\n', {'list': 'ordered'})
          ..insert('0123')
          ..insert('\n', {'list': 'ordered'}),
      );
      expect(
        editor.scroll.element,
        EqualHTML('''
          <ol>
            <li data-list="ordered">0123</li>
            <li data-list="ordered">0123</li>
          </ol>
        '''),
      );
    });

    test('merge checklist', () {
      final editor = _createEditor('''
        <ol><li data-list="checked">0123</li></ol>
        <p>5678</p>
        <ol><li data-list="checked">0123</li></ol>
      ''');
      editor.formatText(9, 1, 'list', 'checked');
      expectDelta(
        editor.getDelta(),
        Delta()
          ..insert('0123')
          ..insert('\n', {'list': 'checked'})
          ..insert('5678')
          ..insert('\n', {'list': 'checked'})
          ..insert('0123')
          ..insert('\n', {'list': 'checked'}),
      );
      expect(
        editor.scroll.element,
        EqualHTML('''
          <ol>
            <li data-list="checked">0123</li>
            <li data-list="checked">5678</li>
            <li data-list="checked">0123</li>
          </ol>
        '''),
      );
    });

    test('empty line interop', () {
      final editor =
          _createEditor('<ol><li data-list="ordered"><br></li></ol>');
      editor.insertText(0, 'Test');
      expect(
        editor.scroll.element,
        EqualHTML('''
          <ol>
            <li data-list="ordered">Test</li>
          </ol>
        '''),
      );
      editor.deleteText(0, 4);
      expect(
        editor.scroll.element,
        EqualHTML('''
          <ol>
            <li data-list="ordered"><br /></li>
          </ol>
        '''),
      );
    });

    test('delete multiple items', () {
      final editor = _createEditor('''
        <ol>
          <li data-list="ordered">0123</li>
          <li data-list="ordered">5678</li>
          <li data-list="ordered">0123</li>
        </ol>''');
      editor.deleteText(2, 5);
      expect(
        editor.scroll.element,
        EqualHTML('''
          <ol>
            <li data-list="ordered">0178</li>
            <li data-list="ordered">0123</li>
          </ol>
        '''),
      );
    });

    test('delete across last item', () {
      final editor = _createEditor('''
        <ol><li data-list="ordered">0123</li></ol>
        <p>5678</p>''');
      editor.deleteText(2, 5);
      expect(editor.scroll.element, EqualHTML('<p>0178</p>'));
    });

    test('delete partial', () {
      final editor = _createEditor(
          '<p>0123</p><ol><li data-list="ordered">5678</li></ol>');
      editor.deleteText(2, 5);
      expect(
        editor.scroll.element,
        EqualHTML('''
          <ol>
            <li data-list="ordered">0178</li>
          </ol>
        '''),
      );
    });

    test('nested list replacement', () {
      final editor = _createEditor('''
        <ol>
          <li data-list="bullet">One</li>
          <li class="ql-indent-1" data-list="bullet">Alpha</li>
          <li data-list="bullet">Two</li>
        </ol>
      ''');
      editor.formatLine(1, 10, {'list': 'bullet'});
      expect(
        editor.scroll.element,
        EqualHTML('''
          <ol>
            <li data-list="bullet">One</li>
            <li class="ql-indent-1" data-list="bullet">Alpha</li>
            <li data-list="bullet">Two</li>
          </ol>
        '''),
      );
    });

    test('copy atttributes', () {
      final editor = _createEditor('<p class="ql-align-center">Test</p>');
      editor.formatLine(4, 1, {'list': 'bullet'});
      expect(
        editor.scroll.element,
        EqualHTML('''
          <ol>
            <li class="ql-align-center" data-list="bullet">Test</li>
          </ol>
        '''),
      );
    });

    test('insert block embed', () {
      final editor =
          _createEditor('<ol><li data-list="ordered">Test</li></ol>');
      editor.insertEmbed(2, 'video', _video);
      expect(
        editor.scroll.element,
        EqualHTML('''
          <ol>
            <li data-list="ordered">Te</li>
          </ol>
          <iframe allowfullscreen="true" class="ql-video" frameborder="0"
              src="$_video"></iframe>
          <ol>
            <li data-list="ordered">st</li>
          </ol>
        '''),
      );
    });

    test('insert block embed at beginning', () {
      final editor =
          _createEditor('<ol><li data-list="ordered">Test</li></ol>');
      editor.insertEmbed(0, 'video', _video);
      expect(
        editor.scroll.element,
        EqualHTML('''
          <iframe allowfullscreen="true" class="ql-video" frameborder="0"
              src="$_video"></iframe>
          <ol>
            <li data-list="ordered">Test</li>
          </ol>
        '''),
      );
    });

    test('insert block embed at end', () {
      final editor =
          _createEditor('<ol><li data-list="ordered">Test</li></ol>');
      editor.insertEmbed(4, 'video', _video);
      expect(
        editor.scroll.element,
        EqualHTML('''
          <ol>
            <li data-list="ordered">Test</li>
          </ol>
          <iframe allowfullscreen="true" class="ql-video" frameborder="0"
              src="$_video"></iframe>
          <ol>
            <li data-list="ordered"><br /></li>
          </ol>
        '''),
      );
    });
  });
}
