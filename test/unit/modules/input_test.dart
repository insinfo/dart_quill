import 'package:dart_quill/src/core/selection.dart';
import 'package:dart_quill/src/delta/delta.dart';
import 'package:dart_quill/src/platform/dom.dart';
import 'package:test/test.dart';

import '../../support/fake_dom.dart';
import '../../support/quill_test_helpers.dart';

void main() {
  group('Input beforeinput', () {
    test('ignores a collapsed target range', () {
      final quill = createTestQuill();
      quill.setContents(Delta()..insert('hello\n'));
      quill.setSelection(const Range(0, 5));
      final textNode = quill.scroll.leaf(0).key!.domNode;
      final event = FakeDomInputEvent(
        type: 'beforeinput',
        inputType: 'insertText',
        data: 'X',
        targetRanges: [
          DomNativeRange(
            startContainer: textNode,
            startOffset: 2,
            endContainer: textNode,
            endOffset: 2,
          ),
        ],
      );

      (quill.root as FakeDomElement).dispatchEvent('beforeinput', event);

      expect(event.defaultPrevented, isFalse);
      expect(quill.getText(), 'hello\n');
    });

    test('replaces the native target range, not the logical selection', () {
      final quill = createTestQuill();
      quill.setContents(Delta()..insert('hello\n'));
      quill.setSelection(const Range(0, 1));
      final textNode = quill.scroll.leaf(0).key!.domNode;
      final event = FakeDomInputEvent(
        type: 'beforeinput',
        inputType: 'insertReplacementText',
        data: 'i',
        targetRanges: [
          DomNativeRange(
            startContainer: textNode,
            startOffset: 1,
            endContainer: textNode,
            endOffset: 4,
          ),
        ],
      );

      (quill.root as FakeDomElement).dispatchEvent('beforeinput', event);

      expect(event.defaultPrevented, isTrue);
      expect(quill.getText(), 'hio\n');
      expect(quill.getSelection()?.index, 2);
      expect(quill.getSelection()?.length, 0);
    });

    test('inherits formats and reads replacement text from data transfer', () {
      final quill = createTestQuill();
      quill.setContents(
        Delta()
          ..insert('bold', {'bold': true})
          ..insert('\n'),
      );
      final textNode = quill.scroll.leaf(0).key!.domNode;
      final transfer = FakeDomDataTransfer({'text/plain': 'new'});
      final event = FakeDomInputEvent(
        type: 'beforeinput',
        inputType: 'insertReplacementText',
        dataTransfer: transfer,
        targetRanges: [
          DomNativeRange(
            startContainer: textNode,
            startOffset: 0,
            endContainer: textNode,
            endOffset: 4,
          ),
        ],
      );

      (quill.root as FakeDomElement).dispatchEvent('beforeinput', event);

      expect(event.defaultPrevented, isTrue);
      expect(
        quill.getContents().toJson(),
        (Delta()
              ..insert('new', {'bold': true})
              ..insert('\n'))
            .toJson(),
      );
    });

    test('empty plain-text replacement deletes the native target range', () {
      final quill = createTestQuill();
      quill.setContents(Delta()..insert('hello\n'));
      final textNode = quill.scroll.leaf(0).key!.domNode;
      final event = FakeDomInputEvent(
        type: 'beforeinput',
        inputType: 'insertReplacementText',
        dataTransfer: FakeDomDataTransfer({'text/plain': ''}),
        targetRanges: [
          DomNativeRange(
            startContainer: textNode,
            startOffset: 1,
            endContainer: textNode,
            endOffset: 4,
          ),
        ],
      );

      (quill.root as FakeDomElement).dispatchEvent('beforeinput', event);

      expect(event.defaultPrevented, isTrue);
      expect(quill.getText(), 'ho\n');
    });

    test('ignores target ranges outside the editor', () {
      final quill = createTestQuill();
      quill.setContents(Delta()..insert('hello\n'));
      final outside = quill.root.ownerDocument.createTextNode('outside');
      final event = FakeDomInputEvent(
        type: 'beforeinput',
        inputType: 'insertText',
        data: 'X',
        targetRanges: [
          DomNativeRange(
            startContainer: outside,
            startOffset: 0,
            endContainer: outside,
            endOffset: 3,
          ),
        ],
      );

      (quill.root as FakeDomElement).dispatchEvent('beforeinput', event);

      expect(event.defaultPrevented, isFalse);
      expect(quill.getText(), 'hello\n');
    });
  });
}
