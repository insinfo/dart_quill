import 'package:dart_quill/src/dependencies/dart_quill_delta/dart_quill_delta.dart';
import 'package:dart_quill/src/formats/list.dart';
import 'package:dart_quill/src/modules/ui_node.dart';
import 'package:dart_quill/src/platform/dom.dart';
import 'package:test/test.dart';

import '../../support/fake_dom.dart';
import '../../support/quill_test_helpers.dart';
import '../../support/test_helpers.dart';

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

    test('moves a native caret from before the UI node to after it', () {
      final quill = createTestQuill(modules: {'uiNode': true});
      quill.setContents(
        Delta()
          ..insert('item')
          ..insert('\n', {'list': 'bullet'}),
      );
      final listElement = quill.root.querySelectorAll('li').first;
      final line = quill.scroll.find(listElement, bubble: true).key as ListItem;
      expect(line.uiNode, isNotNull);
      testAdapter.nativeSelectionRange = DomNativeRange(
        startContainer: line.element,
        startOffset: 0,
        endContainer: line.element,
        endOffset: 0,
      );

      (quill.root as FakeDomElement).dispatchEvent(
        'keydown',
        FakeDomKeyboardEvent(type: 'keydown', key: 'ArrowRight'),
      );
      (testAdapter.document).dispatchEvent(
        'selectionchange',
        FakeDomEvent('selectionchange'),
      );

      final corrected = testAdapter.nativeSelectionRange!;
      expect(corrected.startContainer, same(line.element));
      expect(corrected.startOffset, 1);
      expect(corrected.endOffset, 1);
    });

    test('checklist UI toggles checked state and prevents native selection',
        () {
      final quill = createTestQuill();
      quill.setContents(
        Delta()
          ..insert('task')
          ..insert('\n', {'list': 'unchecked'}),
      );
      final listElement = quill.root.querySelectorAll('li').first;
      final line = quill.scroll.find(listElement, bubble: true).key as ListItem;
      final event = FakeDomEvent('mousedown');

      (line.uiNode! as FakeDomElement).dispatchEvent('mousedown', event);

      expect(event.defaultPrevented, isTrue);
      expect(line.element.dataset['list'], 'checked');
    });
  });
}
