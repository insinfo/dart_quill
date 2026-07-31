@TestOn('browser')
library selection_native_test;

/// The native selection layer (selection.ts) against a REAL browser
/// selection: this is the code that made a toolbar click lose the user's
/// selection, and none of it can be exercised with the fake DOM, which has
/// no `document.getSelection()`.
import 'package:dart_quill/src/core/initialization.dart';
import 'package:dart_quill/src/core/quill.dart';
import 'package:dart_quill/src/core/selection.dart';
import 'package:dart_quill/src/delta/delta.dart';
import 'package:dart_quill/src/platform/html_dom.dart';
import 'package:test/test.dart';
import 'package:web/web.dart' as web;

Quill _createQuill() {
  final host = web.document.createElement('div') as web.HTMLElement;
  web.document.body!.appendChild(host);
  addTearDown(() => host.remove());
  return Quill(HtmlDomElement(host));
}

/// The text the browser reports as selected. `Selection.toString()` is a JS
/// method, so it has to be read through the range's contents from Dart.
String _nativeSelectionText() {
  final selection = web.window.getSelection();
  if (selection == null || selection.rangeCount == 0) return '';
  return selection.getRangeAt(0).cloneContents().textContent ?? '';
}

void main() {
  setUpAll(initializeQuill);

  group('range round-trip', () {
    test('a range set through the API becomes the browser selection', () {
      final quill = _createQuill();
      quill.setContents(Delta()..insert('selecione isto\n'));

      quill.setSelection(const Range(0, 9), source: 'user');

      expect(_nativeSelectionText(), 'selecione',
          reason: 'setSelection must reach document.getSelection()');
      final read = quill.getSelection();
      expect(read?.index, 0);
      expect(read?.length, 9);
    });

    test('a collapsed caret round-trips through the native selection', () {
      final quill = _createQuill();
      quill.setContents(Delta()..insert('abcdef\n'));

      quill.setSelection(const Range(3, 0), source: 'user');

      expect(_nativeSelectionText(), isEmpty);
      final read = quill.getSelection();
      expect(read?.index, 3);
      expect(read?.length, 0);
    });

    test('the caret never sits past the final newline', () {
      final quill = _createQuill();
      quill.setContents(Delta()..insert('abc\n'));

      // Upstream `rangeToNative` clamps to `scroll.length() - 1`, and the
      // clamped value is what ends up stored.
      quill.setSelection(const Range(99, 0), source: 'user');

      expect(quill.getSelection()?.index, quill.getLength() - 1);
    });
  });

  group('focus and savedRange', () {
    test('focus() restores the last range, which is what keeps a toolbar '
        'click from dropping the selection', () {
      final quill = _createQuill();
      quill.setContents(Delta()..insert('preserve isto\n'));
      quill.setSelection(const Range(0, 8), source: 'user');
      expect(quill.selection.savedRange?.length, 8);

      // Focus somewhere else, as clicking a toolbar button does.
      final outside = web.document.createElement('input') as web.HTMLElement;
      web.document.body!.appendChild(outside);
      addTearDown(() => outside.remove());
      outside.focus();
      expect(quill.hasFocus(), isFalse);

      quill.focus();

      expect(quill.hasFocus(), isTrue);
      expect(_nativeSelectionText(), 'preserve',
          reason: 'the saved range must come back with the focus');
      expect(quill.getSelection()?.length, 8);
    });

    test('formatting after a refocus applies to the restored range', () {
      final quill = _createQuill();
      quill.setContents(Delta()..insert('negrito aqui\n'));
      quill.setSelection(const Range(0, 7), source: 'user');

      final outside = web.document.createElement('input') as web.HTMLElement;
      web.document.body!.appendChild(outside);
      addTearDown(() => outside.remove());
      outside.focus();

      quill.focus();
      final range = quill.getSelection()!;
      quill.formatText(range.index, range.length, 'bold', true, source: 'user');

      expect(quill.getContents().toJson().first['attributes']?['bold'], isTrue);
      final root = (quill.root as HtmlDomElement).node as web.Element;
      expect(root.querySelector('strong'), isNotNull);
    });
  });

  group('pending format at a collapsed caret', () {
    test('typing into the parked cursor produces formatted text, with no '
        'zero-width guard left behind', () {
      final quill = _createQuill();
      quill.setContents(Delta()..insert('ab\n'));
      quill.setSelection(const Range(2, 0), source: 'user');

      quill.format('bold', true, source: 'user');

      final root = (quill.root as HtmlDomElement).node as web.Element;
      final cursor = root.querySelector('.ql-cursor');
      expect(cursor, isNotNull,
          reason: 'a collapsed format parks a cursor blot');

      // What the browser does when the user types with the caret parked in
      // the cursor: it appends to the guard text node and leaves the caret
      // after the typed character.
      final guard = cursor!.firstChild as web.Text;
      guard.data = '${guard.data}c';
      final native = web.document.createRange()
        ..setStart(guard, guard.data.length)
        ..setEnd(guard, guard.data.length);
      web.window.getSelection()
        ?..removeAllRanges()
        ..addRange(native);
      quill.update();

      expect(quill.getText(), 'abc\n');
      expect(quill.getText().contains('﻿'), isFalse,
          reason: 'the FEFF guard must never leak into the document');
      final ops = quill.getContents().toJson();
      expect(
          ops.any((op) =>
              op['insert'] == 'c' && op['attributes']?['bold'] == true),
          isTrue,
          reason: 'the typed character carries the pending format: $ops');
    });
  });

  group('bounds', () {
    test('a selected range reports a box inside the editor', () {
      final quill = _createQuill();
      quill.setContents(Delta()..insert('medindo isto\n'));

      final bounds = quill.getBounds(0, 7);
      expect(bounds, isNotNull);
      expect(bounds!['width'], greaterThan(0));
      expect(bounds['height'], greaterThan(0));
    });

    test('a collapsed caret reports a zero-width box', () {
      final quill = _createQuill();
      quill.setContents(Delta()..insert('medindo\n'));

      final bounds = quill.getBounds(3, 0);
      expect(bounds, isNotNull);
      expect(bounds!['width'], 0);
      expect(bounds['height'], greaterThan(0));
    });
  });
}
