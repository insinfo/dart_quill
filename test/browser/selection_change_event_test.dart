@TestOn('browser')
library selection_change_event_test;

/// A caret moved by the *browser* — arrow keys, a click, an IME, or anything
/// that writes `document.getSelection()` — must reach the model on its own.
///
/// Upstream wires that in selection.ts:64-68: a `selectionchange` listener on
/// the document schedules `update(USER)`, which is what emits SELECTION_CHANGE.
/// Nothing else does it: `Quill.getSelection()` happens to call `update()`, so
/// a test that reads the selection first *creates* the state it then asserts,
/// and the gap stays invisible. History is the module that pays for it — it
/// records the range each change was made from, and with no SELECTION_CHANGE
/// that range is null, so undo restores the caret to the wrong place.
import 'dart:async';

import 'package:dart_quill/src/core/emitter.dart';
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

/// Moves the browser caret without going through any Quill API.
void _setNativeCaret(Quill quill, int offset) {
  final root = (quill.root as HtmlDomElement).node as web.Element;
  final textNode = root.firstChild!.firstChild!;
  final range = web.document.createRange()
    ..setStart(textNode, offset)
    ..setEnd(textNode, offset);
  final selection = web.window.getSelection()!;
  selection.removeAllRanges();
  selection.addRange(range);
}

/// The listener is scheduled on a 1ms timer, like upstream's `setTimeout`.
Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 60));

void main() {
  setUpAll(initializeQuill);

  test('a browser-moved caret emits SELECTION_CHANGE without being asked',
      () async {
    final quill = _createQuill();
    quill.setContents(Delta()..insert('1234\n'));
    quill.focus();

    Range? seen;
    var calls = 0;
    quill.on(EmitterEvents.SELECTION_CHANGE,
        (dynamic range, dynamic old, dynamic source) {
      if (range is Range) {
        seen = range;
        calls++;
      }
    });

    _setNativeCaret(quill, 2);
    await _settle();

    expect(calls, greaterThan(0),
        reason: 'selectionchange must schedule Selection.update');
    expect(seen?.index, 2);
    expect(seen?.length, 0);
  });

  test('EDITOR_CHANGE carries the same event, which is what History reads',
      () async {
    final quill = _createQuill();
    quill.setContents(Delta()..insert('1234\n'));
    quill.focus();

    final types = <String>[];
    quill.on(EmitterEvents.EDITOR_CHANGE,
        (dynamic type, [dynamic a, dynamic b, dynamic c]) {
      if (type == EmitterEvents.SELECTION_CHANGE && a is Range) {
        types.add('${a.index}:${a.length}/$c');
      }
    });

    _setNativeCaret(quill, 3);
    await _settle();

    expect(types, contains('3:0/user'),
        reason: 'the source must be USER, or History ignores it');
  });

  test('History records the range a browser-placed caret produced', () async {
    final quill = _createQuill();
    quill.setContents(Delta()..insert('1234\n'));
    quill.focus();
    quill.history.clear();

    _setNativeCaret(quill, 2);
    await _settle();

    // An edit made from that caret, then undone, must put the caret back.
    quill.insertText(2, 'a', source: EmitterSource.USER);
    quill.history.undo();

    final range = quill.getSelection();
    expect(range?.index, 2,
        reason: 'undo restores the range the change was made from');
  });
}
