import 'package:dart_quill/src/blots/abstract/blot.dart';
import 'package:dart_quill/src/modules/ui_node.dart';
import 'package:test/test.dart';

import '../../support/quill_test_helpers.dart';

void main() {
  group('UINode module', () {
    test('registers and is retrievable as UINode instance', () {
      final quill = createTestQuill(modules: {'uiNode': true});
      expect(quill.getModule('uiNode'), isA<UINode>());
    });

    test('ParentBlot.uiNode is null by default', () {
      // Any ParentBlot subclass (Block) should start with uiNode == null
      // before a UI element is explicitly assigned.
      final quill = createTestQuill();
      final scroll = quill.scroll;
      // The scroll blot itself is a ParentBlot — uiNode defaults to null.
      expect(scroll.uiNode, isNull);
    });

    test('TTL constant is 100 ms', () {
      expect(kUiNodeSelectionChangeTtl, equals(100));
    });
  });
}
