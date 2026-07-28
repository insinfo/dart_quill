@TestOn('browser')
library scroll_selection_into_view_test;

import 'package:dart_quill/src/core/initialization.dart';
import 'package:dart_quill/src/core/quill.dart';
import 'package:dart_quill/src/core/selection.dart';
import 'package:dart_quill/src/dependencies/dart_quill_delta/dart_quill_delta.dart';
import 'package:dart_quill/src/platform/html_dom.dart';
import 'package:test/test.dart';
import 'package:web/web.dart' as web;

void main() {
  setUpAll(initializeQuill);

  test('scrolls a distant selected line into the real browser viewport', () {
    final host = web.document.createElement('div') as web.HTMLElement;
    web.document.body!.appendChild(host);
    addTearDown(() => host.remove());

    final quill = Quill(HtmlDomElement(host));
    final root = (quill.root as HtmlDomElement).node as web.HTMLElement;
    root.style.cssText = 'display:block;height:100px;width:300px;overflow:auto;'
        'line-height:20px;padding:0;margin:0;';
    final text = List.generate(100, (index) => 'line ${index + 1}').join('\n');
    quill.setContents(Delta()..insert('$text\n'));
    final index = text.indexOf('line 80');

    quill.setSelection(const Range(0, 0), source: 'silent');
    root.scrollTop = 0;
    quill.setSelection(Range(index, 4), source: 'user');

    final rootRect = root.getBoundingClientRect();
    final selectionBounds = quill.getBounds(index, 4)!;
    final details =
        'scrollTop=${root.scrollTop}, root=${rootRect.top}..${rootRect.bottom}, '
        'selection=${selectionBounds['top']}..${selectionBounds['bottom']}';
    expect(root.scrollTop, greaterThan(0));
    expect(selectionBounds['top'], greaterThanOrEqualTo(rootRect.top - 1),
        reason: details);
    expect(selectionBounds['bottom'], lessThanOrEqualTo(rootRect.bottom + 1),
        reason: details);
  });
}
