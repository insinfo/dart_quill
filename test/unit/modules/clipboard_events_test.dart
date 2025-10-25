import 'package:dart_quill/src/core/quill.dart';
import 'package:dart_quill/src/core/selection.dart';
import 'package:dart_quill/src/dependencies/dart_quill_delta/dart_quill_delta.dart';
import 'package:test/test.dart';

import '../../support/fake_dom.dart';
import '../../support/quill_test_helpers.dart';
import '../../support/test_helpers.dart';

void main() {
  setUpAll(() {
    ensureQuillTestInitialized();
  });

  setUp(() {
    final body = testAdapter.document.body;
    while (body.firstChild != null) {
      body.firstChild!.remove();
    }
  });

  group('Clipboard events', () {
    Quill createFixture() {
      final quill = createTestQuill(
        initialHtml: '<h1>0123</h1><p>5<em>67</em>8</p>',
      );
      quill.setSelection(const Range(2, 5));
      return quill;
    }

    test('pastes html data', () {
      final quill = createFixture();
      final clipboardData = FakeDomDataTransfer({
        'text/html': '<strong>|</strong>',
      });
      final event = FakeDomClipboardEvent(
        type: 'paste',
        clipboardData: clipboardData,
      );

      quill.clipboard.onCapturePaste(event);

      expectHTML(
        quill.root,
        '<p>01<strong>|</strong><em>7</em>8</p>',
      );
      final selection = quill.getSelection();
      expect(selection?.index, 3);
      expect(selection?.length, 0);
    });

    test('pastes with "paste and match style"', () {
      final quill = createFixture();
      quill.setContents(
        Delta()
          ..insert('abc', {'bold': true})
          ..insert('\n'),
      );
      quill.setSelection(const Range(3, 0));
      final clipboardData = FakeDomDataTransfer({'text/plain': 'def'});
      final event =
          FakeDomClipboardEvent(type: 'paste', clipboardData: clipboardData);

      quill.clipboard.onCapturePaste(event);

      // DEBUG

      expect(
        quill.getContents().toJson(),
        equals([
          {
            'insert': 'abcdef',
            'attributes': {'bold': true},
          },
          {'insert': '\n'},
        ]),
      );
    });

    test('pastes links from iOS share sheets', () {
      final quill = createFixture();
      quill.setContents(Delta()..insert('\n'));
      quill.setSelection(const Range(0, 0));

      final firstPaste = FakeDomClipboardEvent(
        type: 'paste',
        clipboardData: FakeDomDataTransfer({
          'text/uri-list': 'https://example.com',
        }),
      );
      quill.clipboard.onCapturePaste(firstPaste);
      expect(
        quill.getContents().toJson(),
        equals([
          {'insert': 'https://example.com\n'},
        ]),
      );

      quill.setContents(Delta()..insert('\n'));
      quill.setSelection(const Range(0, 0));
      final secondPaste = FakeDomClipboardEvent(
        type: 'paste',
        clipboardData: FakeDomDataTransfer({
          'text/uri-list':
              'https://example.com\r\n# Comment\r\nhttps://example.com/a',
        }),
      );
      quill.clipboard.onCapturePaste(secondPaste);
      expect(
        quill.getContents().toJson(),
        equals([
          {'insert': 'https://example.com\nhttps://example.com/a\n'},
        ]),
      );
    });

    test('pastes html data if present with file', () {
      final quill = createFixture();
      final clipboardData = FakeDomDataTransfer(
        {'text/html': '<strong>|</strong>'},
        [FakeDomFile(name: 'file')],
      );
      final event =
          FakeDomClipboardEvent(type: 'paste', clipboardData: clipboardData);

      quill.clipboard.onCapturePaste(event);

      expectHTML(
        quill.root,
        '<p>01<strong>|</strong><em>7</em>8</p>',
      );
    });

    test('cut keeps formats of first line', () {
      final quill = createFixture();
      final event = FakeDomClipboardEvent(type: 'cut');

      quill.clipboard.onCaptureCopy(event, true);

      expectHTML(quill.root, '<h1>01<em>7</em>8</h1>');
      final selection = quill.getSelection();
      expect(selection?.index, 2);
      expect(selection?.length, 0);

      final clipboardData = event.clipboardData as FakeDomDataTransfer;
      expect(clipboardData.data['text/plain'], '23\n56');
      expect(
        clipboardData.data['text/html'],
        '<h1>23</h1><p>5<em>6</em></p>',
      );
    });
  });

  group('Clipboard.dangerouslyPasteHTML', () {
    test('dangerouslyPasteHTML(html)', () {
      final quillInstance = createTestQuill();
      quillInstance.clipboard.dangerouslyPasteHTML('<i>ab</i><b>cd</b>');
      expectHTML(quillInstance.root, '<p><em>ab</em><strong>cd</strong></p>');
    });

    test('dangerouslyPasteHTML(index, html)', () {
      final quillInstance =
          createTestQuill(initialHtml: '<h1>0123</h1><p>5<em>67</em>8</p>');
      quillInstance.clipboard.dangerouslyPasteHTML(2, '<b>ab</b>');
      expectHTML(
        quillInstance.root,
        '<h1>01<strong>ab</strong>23</h1><p>5<em>67</em>8</p>',
      );
    });
  });
}
