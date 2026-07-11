import 'package:dart_quill/src/core/selection.dart';
import 'package:dart_quill/src/dependencies/dart_quill_delta/dart_quill_delta.dart';
import 'package:test/test.dart';

import '../../support/fake_dom.dart';
import '../../support/quill_test_helpers.dart';

void main() {
  setUpAll(ensureQuillTestInitialized);

  group('Block attributors', () {
    test('align via formatLine adds ql-align class', () {
      final quill = createTestQuill(initialHtml: '<p>Hello</p>');
      quill.formatLine(0, 1, 'align', 'center');
      final block = (quill.root as FakeDomElement).querySelectorAll('p').first;
      expect(block.classes.contains('ql-align-center'), isTrue);
      expect(quill.getFormat(0)['align'], equals('center'));
    });

    test('align lands on newline in delta and clears', () {
      final quill = createTestQuill(initialHtml: '<p>Hello</p>');
      quill.formatLine(0, 1, 'align', 'right');
      final ops = quill.getContents().toJson();
      expect(
        ops,
        equals([
          {'insert': 'Hello'},
          {
            'insert': '\n',
            'attributes': {'align': 'right'}
          },
        ]),
      );

      quill.formatLine(0, 1, 'align', null);
      final block = (quill.root as FakeDomElement).querySelectorAll('p').first;
      expect(block.classes.contains('ql-align-right'), isFalse);
      expect(quill.getFormat(0).containsKey('align'), isFalse);
    });

    test('indent +1/-1 adjusts ql-indent class', () {
      final quill = createTestQuill(initialHtml: '<p>item</p>');
      quill.formatLine(0, 1, 'indent', '+1');
      var block = (quill.root as FakeDomElement).querySelectorAll('p').first;
      expect(block.classes.contains('ql-indent-1'), isTrue);

      quill.formatLine(0, 1, 'indent', '+1');
      block = (quill.root as FakeDomElement).querySelectorAll('p').first;
      expect(block.classes.contains('ql-indent-2'), isTrue);
      expect(quill.getFormat(0)['indent'], equals(2));

      quill.formatLine(0, 1, 'indent', '-1');
      block = (quill.root as FakeDomElement).querySelectorAll('p').first;
      expect(block.classes.contains('ql-indent-1'), isTrue);
    });

    test('direction rtl applies and reads back', () {
      final quill = createTestQuill(initialHtml: '<p>abc</p>');
      quill.formatLine(0, 1, 'direction', 'rtl');
      final block = (quill.root as FakeDomElement).querySelectorAll('p').first;
      expect(block.classes.contains('ql-direction-rtl'), isTrue);
      expect(quill.getFormat(0)['direction'], equals('rtl'));
    });

    test('align survives header toggle (attribute copy on replace)', () {
      final quill = createTestQuill(initialHtml: '<p>Title</p>');
      quill.formatLine(0, 1, 'align', 'center');
      quill.formatLine(0, 1, 'header', 1);
      final h1 = (quill.root as FakeDomElement).querySelectorAll('h1');
      expect(h1.length, equals(1));
      expect(h1.first.classes.contains('ql-align-center'), isTrue);
      final formats = quill.getFormat(0);
      expect(formats['header'], equals(1));
      expect(formats['align'], equals('center'));
    });

    test('formatLine list ordered wraps into <ol><li>', () {
      final quill = createTestQuill(initialHtml: '<p>item</p>');
      quill.formatLine(0, 1, 'list', 'ordered');
      final root = quill.root as FakeDomElement;
      final ol = root.querySelectorAll('ol');
      expect(ol.length, equals(1),
          reason: 'list item must be wrapped in an attached <ol>');
      final li = root.querySelectorAll('li');
      expect(li.length, equals(1));
      expect(quill.getFormat(0)['list'], equals('ordered'));
    });

    test('formatLine list bullet wraps into <ul><li>', () {
      final quill = createTestQuill(initialHtml: '<p>item</p>');
      quill.formatLine(0, 1, 'list', 'bullet');
      final root = quill.root as FakeDomElement;
      expect(root.querySelectorAll('ul').length, equals(1));
      expect(quill.getFormat(0)['list'], equals('bullet'));
    });

    test('enter keeps line format on new line via keyboard delta', () {
      final quill = createTestQuill(initialHtml: '<p>Hi</p>');
      quill.formatLine(0, 1, 'align', 'center');
      // Simulate what handleEnter builds: retain + insert('\n', lineFormats).
      quill.updateContents(
        Delta()
          ..retain(2)
          ..insert('\n', {'align': 'center'}),
        source: 'user',
      );
      quill.setSelection(const Range(3, 0));
      final blocks = (quill.root as FakeDomElement).querySelectorAll('p');
      expect(blocks.length, equals(2));
      expect(blocks[1].classes.contains('ql-align-center'), isTrue);
    });
  });
}
