@TestOn('browser')
library document_listeners_test;

import 'package:dart_quill/src/platform/dom.dart';
import 'package:dart_quill/src/platform/html_dom.dart';
import 'package:test/test.dart';
import 'package:web/web.dart' as web;

/// `element.ownerDocument` mints a NEW adapter wrapper on every call, so the
/// document-level listener registry cannot live on the wrapper instance —
/// otherwise `removeEventListener` silently misses and the native listener
/// stays attached forever.
///
/// That leak is what made the table resize replay itself on every later
/// click: each drag armed a `mousemove`/`mouseup` pair on the document and
/// never released it.
void main() {
  test('a listener added through one ownerDocument wrapper is removable '
      'through another', () {
    final host = web.document.createElement('div');
    web.document.body!.appendChild(host);
    addTearDown(() => host.remove());
    final element = HtmlDomElement(host);

    final addDoc = element.ownerDocument;
    final removeDoc = element.ownerDocument;
    expect(identical(addDoc, removeDoc), isFalse,
        reason: 'the premise: ownerDocument returns a fresh wrapper');
    expect(addDoc, equals(removeDoc),
        reason: 'wrappers of the same document compare equal');

    var calls = 0;
    void listener(DomEvent event) => calls++;

    addDoc.addEventListener('mouseup', listener);
    web.document.dispatchEvent(web.Event('mouseup'));
    expect(calls, 1);

    removeDoc.removeEventListener('mouseup', listener);
    web.document.dispatchEvent(web.Event('mouseup'));
    expect(calls, 1,
        reason: 'the listener must be gone after removal through a '
            'different wrapper of the same document');
  });

  test('adding the same listener twice registers it once', () {
    final element = HtmlDomElement(web.document.body!);
    var calls = 0;
    void listener(DomEvent event) => calls++;

    element.ownerDocument.addEventListener('mousedown', listener);
    element.ownerDocument.addEventListener('mousedown', listener);
    addTearDown(
        () => element.ownerDocument.removeEventListener('mousedown', listener));

    web.document.dispatchEvent(web.Event('mousedown'));
    expect(calls, 1,
        reason: 'DOM semantics: re-adding the same listener is a no-op, and '
            'a second native registration could never be removed');
  });
}
