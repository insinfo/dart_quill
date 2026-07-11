@TestOn('browser')
library enter_key_test;

import 'package:web/web.dart' as web;

import 'package:dart_quill/src/blots/block.dart';
import 'package:dart_quill/src/core/initialization.dart';
import 'package:dart_quill/src/core/quill.dart';
import 'package:dart_quill/src/core/selection.dart';
import 'package:dart_quill/src/modules/keyboard.dart';
import 'package:dart_quill/src/platform/dom.dart';
import 'package:dart_quill/src/platform/html_dom.dart';
import 'package:test/test.dart';

class _FakeDomEvent implements DomEvent {
  bool _prevented = false;

  @override
  bool get defaultPrevented => _prevented;

  @override
  void preventDefault() => _prevented = true;

  @override
  void stopPropagation() {}

  @override
  dynamic get rawEvent => null;

  @override
  DomNode? get target => null;
}

Quill _createQuill() {
  final host = web.document.createElement('div');
  web.document.body!.appendChild(host);
  return Quill(HtmlDomElement(host));
}

Context _contextFor(Quill quill, Range range) {
  final lineEntry = quill.getLine(range.index);
  final line = lineEntry.key as Block;
  return Context(
    collapsed: range.length == 0,
    empty: range.length == 0 && line.length() <= 1,
    format: quill.getFormat(range.index, range.length),
    line: line,
    offset: lineEntry.value,
    prefix: '',
    suffix: '',
    event: _FakeDomEvent(),
  );
}

void _pressEnter(Quill quill, Range range) {
  quill.setSelection(range, source: 'user');
  quill.keyboard.handleEnter(range, _contextFor(quill, range));
}

web.Element _rawRoot(Quill quill) =>
    (quill.root as HtmlDomElement).node as web.Element;

List<web.Element> _paragraphsOf(web.Element root) {
  final nodes = root.querySelectorAll('p');
  return [for (var i = 0; i < nodes.length; i++) nodes.item(i)! as web.Element];
}

void main() {
  setUpAll(initializeQuill);

  test('Enter at end of line creates new line and moves caret to it', () {
    final quill = _createQuill();
    quill.insertText(0, 'Hello');
    _pressEnter(quill, const Range(5, 0));

    final root = _rawRoot(quill);
    final paragraphs = _paragraphsOf(root);
    expect(paragraphs.length, equals(2));
    expect(paragraphs[0].textContent, equals('Hello'));

    final range = quill.selection.getRange();
    expect(range, isNotNull);
    expect(range!.index, equals(6));
    expect(range.length, equals(0));

    final native = web.window.getSelection();
    expect(native, isNotNull);
    var node = native!.anchorNode;
    var inSecond = false;
    while (node != null) {
      if (node == paragraphs[1]) {
        inSecond = true;
        break;
      }
      node = node.parentNode;
    }
    expect(inSecond, isTrue,
        reason: 'caret should be inside the second paragraph, '
            'anchor=${native.anchorNode} offset=${native.anchorOffset}');

    final syncedRange = quill.getSelection();
    expect(syncedRange?.index, equals(6),
        reason: 'the implicit newline between paragraphs must count toward '
            'the document index');

    quill.insertText(syncedRange!.index, 'World', source: 'user');
    expect(quill.getText(), equals('Hello\nWorld\n'));
    expect(paragraphs[0].textContent, equals('Hello'));
    expect(paragraphs[1].textContent, equals('World'));
  });

  test('Successive Enters keep advancing lines', () {
    final quill = _createQuill();
    quill.insertText(0, 'abc');
    for (var i = 0; i < 3; i++) {
      final index = 3 + i;
      _pressEnter(quill, Range(index, 0));
      final range = quill.selection.getRange();
      expect(range!.index, equals(index + 1),
          reason: 'after Enter #${i + 1} caret should be at ${index + 1}');
    }
    final paragraphs = _paragraphsOf(_rawRoot(quill));
    expect(paragraphs.length, equals(4));
  });

  test('Enter in middle splits line and caret lands at split start', () {
    final quill = _createQuill();
    quill.insertText(0, 'HelloWorld');
    _pressEnter(quill, const Range(5, 0));
    expect(quill.getText(), equals('Hello\nWorld\n'));
    expect(quill.selection.getRange()!.index, equals(6));

    final paragraphs = _paragraphsOf(_rawRoot(quill));
    expect(paragraphs.length, equals(2));
    expect(paragraphs[0].textContent, equals('Hello'));
    expect(paragraphs[1].textContent, equals('World'));
  });
}
