import 'package:test/test.dart';

import 'package:dart_quill/src/modules/normalize_external_html/normalizers/ms_word.dart';
import 'package:dart_quill/src/platform/dom.dart';

import '../../../../support/fake_dom.dart';

void main() {
  group('NormalizeExternalHTML – Microsoft Word', () {
    test('converts mso list paragraphs into semantic lists', () {
      const html = '''
      <html xmlns:w="urn:schemas-microsoft-com:office:word">
        <style>
          @list l0:level3 { mso-level-number-format:bullet; }
          @list l2:level1 { mso-level-number-format:alpha; }
        </style>
        <body>
          <p style="mso-list: l0 level1 lfo1"><span style="mso-list: Ignore;">1. </span>item 1</p>
          <p style="mso-list: l0 level3 lfo1">item 2</p>
          <p style="mso-list: l1 level4 lfo1">item 3 in another list</p>
          <p>Plain paragraph</p>
          <p style="mso-list: l2 level1 lfo1">the last item</p>
        </body>
      </html>
      ''';

      final doc = FakeDomDocument.fromHtml(html);
      normalizeMsWord(doc);

      final children = doc.body.childNodes.whereType<DomElement>().toList();
      expect(children.length, 4);

      final firstList = children[0];
      expect(firstList.tagName, 'UL');
      final firstItems = firstList.childNodes.whereType<DomElement>().toList();
      expect(firstItems.length, 2);
      expect(firstItems[0].tagName, 'LI');
      expect(firstItems[0].getAttribute('data-list'), 'ordered');
      expect(firstItems[0].text?.trim(), 'item 1');
      expect(firstItems[1].getAttribute('data-list'), 'bullet');
      expect(firstItems[1].getAttribute('class'), 'ql-indent-2');
      expect(firstItems[1].text?.trim(), 'item 2');

      final secondList = children[1];
      expect(secondList.tagName, 'UL');
      final secondItems = secondList.childNodes.whereType<DomElement>().toList();
      expect(secondItems.length, 1);
      expect(secondItems[0].getAttribute('class'), 'ql-indent-3');
      expect(secondItems[0].getAttribute('data-list'), 'ordered');
      expect(secondItems[0].text?.trim(), 'item 3 in another list');

      final paragraph = children[2];
      expect(paragraph.tagName, 'P');
      expect(paragraph.text?.trim(), 'Plain paragraph');

      final thirdList = children[3];
      expect(thirdList.tagName, 'UL');
      final thirdItems = thirdList.childNodes.whereType<DomElement>().toList();
      expect(thirdItems.length, 1);
      expect(thirdItems[0].getAttribute('data-list'), 'ordered');
      expect(thirdItems[0].text?.trim(), 'the last item');
    });
  });
}
