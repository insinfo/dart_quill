import 'package:dart_quill/src/blots/abstract/blot.dart';
import 'package:dart_quill/src/formats/bold.dart';
import 'package:dart_quill/src/platform/dom.dart';
import 'package:test/test.dart';

import '../../support/quill_test_helpers.dart';
import '../../support/test_helpers.dart';

void main() {
  group('Bold format', () {
    test('optimize merges adjacent bold segments', () {
      ensureQuillTestInitialized();

      final boldEntry = RegistryEntry(
        blotName: Bold.kBlotName,
        scope: Bold.kScope,
        tagNames: Bold.kTagNames,
        create: Bold.create,
      );

      final registry = createRegistry([boldEntry]);
      final container = testAdapter.document.createElement('div');
      testAdapter.document.body.append(container);
      addTearDown(container.remove);

      final scroll = createScroll(
        '<p><strong>a</strong>b<strong>c</strong></p>',
        registry: registry,
        container: container,
      );

      final paragraph = container.childNodes.first as DomElement;
      final middleNode = paragraph.childNodes[1];

      final boldWrapper = testAdapter.document.createElement('b');
      boldWrapper.append(middleNode);
      paragraph.insertBefore(boldWrapper, paragraph.lastChild);

      scroll.update();

      expectHTML(container, '<p><strong>abc</strong></p>');
    });
  });
}
