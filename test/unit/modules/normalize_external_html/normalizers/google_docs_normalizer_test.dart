import 'package:test/test.dart';

import 'package:dart_quill/src/modules/normalize_external_html/normalizers/google_docs.dart';
import 'package:dart_quill/src/platform/dom.dart';

import '../../../../support/fake_dom.dart';

void main() {
  group('NormalizeExternalHTML – Google Docs', () {
    test('removes normal-weight <b> wrappers', () {
      const html = '''
      <b
        style="font-weight: normal;"
        id="docs-internal-guid-9f51ddb9-7fff-7da1-2cd6-e966f9297902"
      >
        <span>Item 1</span><b>Item 2</b>
      </b>
      <b style="font-weight: bold;">Item 3</b>
      ''';

      final doc = FakeDomDocument.fromHtml(html);
      normalizeGoogleDocs(doc);

      final elementChildren = doc.body.childNodes
          .whereType<DomElement>()
          .toList(growable: false);

      expect(elementChildren.length, 3);
      expect(elementChildren[0].tagName, 'SPAN');
      expect(elementChildren[0].text?.trim(), 'Item 1');

      expect(elementChildren[1].tagName, 'B');
      expect(elementChildren[1].text?.trim(), 'Item 2');
      expect(elementChildren[1].getAttribute('style'), isNull);

      expect(elementChildren[2].tagName, 'B');
      expect(elementChildren[2].text?.trim(), 'Item 3');
      expect(
        elementChildren[2].getAttribute('style'),
        equals('font-weight: bold;'),
      );
    });
  });
}
