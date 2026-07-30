@TestOn('browser')
library clipboard_convert_test;

/// HTML→Delta conversion through the browser's own `DOMParser`.
///
/// The VM suite parses pasted HTML with `package:html`; the browser uses the
/// native parser, which normalizes markup differently (implied `<tbody>`,
/// attribute casing, whitespace). These tests pin the conversion — and the
/// Word/Google-Docs normalizers — on the parser real users paste through.
import 'package:dart_quill/src/core/initialization.dart';
import 'package:dart_quill/src/core/quill.dart';
import 'package:dart_quill/src/dependencies/dart_quill_delta/dart_quill_delta.dart';
import 'package:dart_quill/src/platform/html_dom.dart';
import 'package:test/test.dart';
import 'package:web/web.dart' as web;

Quill _createQuill() {
  final host = web.document.createElement('div') as web.HTMLElement;
  web.document.body!.appendChild(host);
  addTearDown(() => host.remove());
  return Quill(HtmlDomElement(host));
}

List<Map<String, dynamic>> _ops(Delta delta) =>
    delta.toJson().cast<Map<String, dynamic>>();

void main() {
  setUpAll(initializeQuill);

  group('inline formats', () {
    test('bold, italic and links survive the conversion', () {
      final quill = _createQuill();
      final delta = quill.clipboard.convert(
          html: '<p><strong>forte</strong> e <em>italico</em> e '
              '<a href="https://quilljs.com">link</a></p>');

      final ops = _ops(delta);
      expect(ops.first['insert'], 'forte');
      expect(ops.first['attributes']?['bold'], isTrue);
      expect(
          ops.any((op) =>
              op['insert'] == 'italico' && op['attributes']?['italic'] == true),
          isTrue,
          reason: '$ops');
      expect(
          ops.any((op) =>
              op['insert'] == 'link' &&
              op['attributes']?['link'] == 'https://quilljs.com'),
          isTrue,
          reason: '$ops');
    });

    test('inline styles become attributes through the style attributors', () {
      final quill = _createQuill();
      final delta = quill.clipboard.convert(
          html: '<p><span style="color: rgb(230, 0, 0);">vermelho</span></p>');

      final ops = _ops(delta);
      expect(ops.first['insert'], 'vermelho');
      expect(ops.first['attributes']?['color'], isNotNull,
          reason: 'the colour must survive a paste: $ops');
    });
  });

  group('block formats', () {
    test('headers and lists keep their line attributes', () {
      final quill = _createQuill();
      final delta = quill.clipboard.convert(
          html: '<h1>Titulo</h1><ul><li>um</li><li>dois</li></ul>');

      // `applyFormat` stamps the format onto every op of the sub-delta and
      // equal neighbours merge, so the list arrives as one op carrying the
      // attribute — `applyDelta` moves it onto each newline when applied.
      final ops = _ops(delta);
      expect(
          ops.any((op) =>
              op['attributes']?['header'] == 1 &&
              '${op['insert']}'.contains('Titulo')),
          isTrue,
          reason: '$ops');
      expect(
          ops.any((op) =>
              op['attributes']?['list'] == 'bullet' &&
              '${op['insert']}'.contains('um') &&
              '${op['insert']}'.contains('dois')),
          isTrue,
          reason: '$ops');
    });

    test('a pasted list becomes real list items in the document', () {
      final quill = _createQuill();
      quill.clipboard.dangerouslyPasteHTML('<ul><li>um</li><li>dois</li></ul>');

      final root = (quill.root as HtmlDomElement).node as web.Element;
      final items = root.querySelectorAll('li');
      expect(items.length, 2, reason: '${root.innerHTML}');
      expect((items.item(0)! as web.Element).getAttribute('data-list'),
          'bullet');
      expect(quill.getText(), 'um\ndois\n');
    });

    test('a table keeps its cells and its table attribute', () {
      final quill = _createQuill();
      // The browser inserts the implied <tbody> the VM parser also adds.
      final delta = quill.clipboard.convert(
          html: '<table><tr><td>a1</td><td>a2</td></tr></table>');

      final ops = _ops(delta);
      final text = ops.map((op) => op['insert']).whereType<String>().join();
      expect(text, contains('a1'));
      expect(text, contains('a2'));
      expect(ops.any((op) => op['attributes']?['table'] != null), isTrue,
          reason: 'the cells must carry the table format: $ops');
    });
  });

  group('external sources', () {
    test('a Google Docs wrapper does not bold the whole paste', () {
      final quill = _createQuill();
      // Google Docs wraps copied content in <b style="font-weight:normal">.
      final delta = quill.clipboard.convert(
          html: '<b style="font-weight:normal" id="docs-internal-guid-x">'
              '<span>texto normal</span></b>');

      final ops = _ops(delta);
      expect(ops.first['insert'], 'texto normal');
      expect(ops.first['attributes']?['bold'], isNull,
          reason: 'the wrapper is presentational, not a format: $ops');
    });

    test('Word list paragraphs are not turned into stray characters', () {
      final quill = _createQuill();
      // The Word namespace is what arms the normalizer, upstream included
      // (msWord.ts:90-97) — without it Word markup is left alone.
      const html = '<html xmlns:w="urn:schemas-microsoft-com:office:word">'
          '<body><p class="MsoListParagraphCxSpFirst" '
          'style="mso-list:l0 level1 lfo1">'
          '<span style="mso-list:Ignore">1.</span>item</p></body></html>';

      // What the normalizer is given, straight from the browser's parser.
      final parsed = quill.root.ownerDocument.parser
          .parseFromString(html, 'text/html');
      expect(parsed.querySelectorAll('[style*=mso-list]').length, 2,
          reason: 'both the paragraph and the ignored marker must be found '
              'by the selector the normalizer uses');

      final delta = quill.clipboard.convert(html: html);
      final ops = _ops(delta);
      final text = ops.map((op) => op['insert']).whereType<String>().join();
      expect(text, contains('item'));
      expect(text, isNot(contains('1.')),
          reason: 'the mso-list bullet marker must be dropped: $ops');
      expect(ops.any((op) => op['attributes']?['list'] != null), isTrue,
          reason: 'a Word list paragraph becomes a real list item: $ops');
    });
  });

  group('pasting into the document', () {
    test('dangerouslyPasteHTML replaces the document with the parsed content',
        () {
      final quill = _createQuill();
      quill.clipboard.dangerouslyPasteHTML('<p>um</p><p><em>dois</em></p>');

      expect(quill.getText(), 'um\ndois\n');
      final root = (quill.root as HtmlDomElement).node as web.Element;
      expect(root.querySelector('em'), isNotNull);
    });
  });
}
