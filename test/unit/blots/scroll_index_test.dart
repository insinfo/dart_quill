import 'package:dart_quill/src/platform/dom.dart';
import 'package:test/test.dart';

import '../../support/test_helpers.dart';

void main() {
  setUpAll(() {
    initializeFakeDom();
  });

  setUp(() {
    final body = testAdapter.document.body;
    while (body.firstChild != null) {
      body.firstChild!.remove();
    }
  });

  group('Scroll.indexFromDomNode', () {
    test('returns null for nodes outside the scroll', () {
      final scroll = createScroll('<p>Test</p>');
      final orphan = testAdapter.document.createElement('div');

      expect(scroll.indexFromDomNode(orphan, 0), isNull);
    });

    test('maps text node offsets', () {
      final scroll = createScroll('<p>Alpha</p>');
      final root = scroll.domNode as DomElement;
      final paragraph = root.childNodes.firstWhere((node) => node is DomElement)
          as DomElement;
      final textNode =
          paragraph.childNodes.firstWhere((node) => node is DomText) as DomText;

      expect(scroll.indexFromDomNode(textNode, 0), 0);
      expect(scroll.indexFromDomNode(textNode, 2), 2);
      expect(scroll.indexFromDomNode(textNode, 99), 5);
    });

    test('maps element child offsets to cumulative lengths', () {
      final scroll = createScroll('<p>ABC</p>');
      final root = scroll.domNode as DomElement;
      final paragraph = root.childNodes.firstWhere((node) => node is DomElement)
          as DomElement;

      expect(scroll.indexFromDomNode(paragraph, 0), 0);
      expect(scroll.indexFromDomNode(paragraph, 1), 3);
      expect(scroll.indexFromDomNode(paragraph, 99), 3);
    });

    test('respects preceding content when computing offsets', () {
      final scroll = createScroll('<p>One</p><p>Two</p>');
      final root = scroll.domNode as DomElement;
      final paragraphs = root.childNodes.whereType<DomElement>().toList();
      final secondParagraph = paragraphs[1];
      final secondText = secondParagraph.childNodes
          .firstWhere((node) => node is DomText) as DomText;

      expect(scroll.indexFromDomNode(secondText, 0), 4);
      expect(scroll.indexFromDomNode(secondText, 2), 6);
    });
  });
}
