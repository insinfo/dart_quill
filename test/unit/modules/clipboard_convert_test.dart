import 'package:dart_quill/src/dependencies/dart_quill_delta/dart_quill_delta.dart';
import 'package:dart_quill/src/formats/abstract/attributor.dart';
import 'package:dart_quill/src/formats/color.dart';
import 'package:dart_quill/src/formats/direction.dart';
import 'package:dart_quill/src/modules/clipboard.dart';
import 'package:dart_quill/src/platform/dom.dart';
import 'package:test/test.dart';

import '../../support/quill_test_helpers.dart';
import '../../support/test_helpers.dart';

void main() {
  setUpAll(() {
    ensureQuillTestInitialized();
  });

  setUp(() {
    final body = testAdapter.document.body;
    while (body.firstChild != null) {
      body.firstChild!.remove();
    }
  });

  group('Clipboard.convert', () {
    Clipboard _clipboard({List<Attributor> attributors = const []}) {
      final options =
          attributors.isEmpty ? null : ClipboardOptions(attributors: attributors);
      final quill = createTestQuill(clipboardOptions: options);
      return quill.clipboard;
    }

    test('text with adjacent spaces', () {
      final delta = _clipboard().convert(text: 'simple  text');
      expectDelta(delta, Delta()..insert('simple  text'));
    });

    test('text with newlines', () {
      final delta = _clipboard().convert(text: 'simple\ntext');
      expectDelta(delta, Delta()..insert('simple\ntext'));
    });

    test('only text in html', () {
      final delta = _clipboard().convert(html: 'simple plain text');
      expectDelta(delta, Delta()..insert('simple plain text'));
    });

    test('whitespace', () {
      const html =
          '<div> 0 </div><div> <div> 1 2 <span> 3 </span> 4 </div> </div>'
          '<div><span>5 </span><span>6 </span><span> 7</span><span> 8</span></div>';
      final delta = _clipboard().convert(html: html);
      expectDelta(delta, Delta()..insert('0\n1 2  3  4\n5 6  7 8'));
    });

    test('multiple whitespaces', () {

      final delta = _clipboard().convert(html: '<div>1   2    3</div>');
      expectDelta(delta, Delta()..insert('1 2 3'));
    });

    test('inline whitespace', () {
      final delta = _clipboard().convert(html: '<p>0 <strong>1</strong> 2</p>');
      expectDelta(
        delta,
        Delta()
          ..insert('0 ')
          ..insert('1', {'bold': true})
          ..insert(' 2'),

      );
    });

    test('intentional whitespace', () {
      final delta = _clipboard()
          .convert(html: '<span>0&nbsp;<strong>1</strong>&nbsp;2</span>');
      expectDelta(
        delta,
        Delta()
          ..insert('0 ')
          ..insert('1', {'bold': true})
          ..insert(' 2'),
      );
    });

    test('consecutive intentional whitespace', () {

      final delta = _clipboard()
          .convert(html: '<strong>&nbsp;&nbsp;1&nbsp;&nbsp;</strong>');
      expectDelta(
        delta,
        Delta()..insert('  1  ', {'bold': true}),
      );
    });

    test('intentional whitespace at line start/end', () {
      expectDelta(

        _clipboard().convert(html: '<p>0 &nbsp;</p><p>&nbsp; 2</p>'),
        Delta()
          ..insert('0  \n')
          ..insert('  2'),
      );
      expectDelta(
        _clipboard().convert(html: '<p>0&nbsp; </p><p> &nbsp;2</p>'),
        Delta()
          ..insert('0 \n')
          ..insert(' 2'),
      );

    });

    test('newlines between inline elements', () {
      final delta =
          _clipboard().convert(html: '<span>foo</span>\n<span>bar</span>');
      expectDelta(delta, Delta()..insert('foo bar'));
    });

    test('multiple newlines between inline elements', () {
      final delta = _clipboard()
          .convert(html: '<span>foo</span>\n\n\n\n<span>bar</span>');

      expectDelta(delta, Delta()..insert('foo bar'));
    });

    test('newlines between block elements', () {
      final delta = _clipboard().convert(html: '<p>foo</p>\n<p>bar</p>');
      expectDelta(delta, Delta()..insert('foo\nbar'));
    });

    test('multiple newlines between block elements', () {
      final delta = _clipboard().convert(html: '<p>foo</p>\n\n\n\n<p>bar</p>');
      expectDelta(delta, Delta()..insert('foo\nbar'));
    });

    test('space between empty paragraphs', () {

      final delta = _clipboard().convert(html: '<p></p> <p></p>');
      expectDelta(delta, Delta()..insert('\n'));
    });

    test('newline between empty paragraphs', () {

      final delta = _clipboard().convert(html: '<p></p>\n<p></p>');
      expectDelta(delta, Delta()..insert('\n'));
    });

    test('break', () {
      const html =

          '<div>0<br>1</div><div>2<br></div><div>3</div><div><br>4</div><div><br></div><div>5</div>';
      final delta = _clipboard().convert(html: html);
      expectDelta(delta, Delta()..insert('0\n1\n2\n3\n\n4\n\n5'));
    });

    test('empty block', () {
      final delta =
          _clipboard().convert(html: '<h1>Test</h1><h2></h2><p>Body</p>');
      expectDelta(
        delta,
        Delta()
          ..insert('Test\n', {'header': 1})
          ..insert('\n', {'header': 2})
          ..insert('Body'),
      );
    });

    test('mixed inline and block', () {
      final delta = _clipboard().convert(html: '<div>One<div>Two</div></div>');
      expectDelta(delta, Delta()..insert('One\nTwo'));
    });


    test('alias', () {
      final delta = _clipboard().convert(html: '<b>Bold</b><i>Italic</i>');
      expectDelta(
        delta,
        Delta()
          ..insert('Bold', {'bold': true})
          ..insert('Italic', {'italic': true}),
      );
    });


    test('nested list', () {
      final delta = _clipboard().convert(
        html: '<ol><li>One</li><li class="ql-indent-1">Alpha</li></ol>',

      );
      expectDelta(
        delta,
        Delta()
          ..insert('One\n', {'list': 'ordered'})
          ..insert('Alpha\n', {'list': 'ordered', 'indent': 1}),
      );
    });

    test('html nested list', () {
      final delta = _clipboard().convert(
        html:
            '<ol><li>One<ol><li>Alpha</li><li>Beta<ol><li>I</li></ol></li></ol></li></ol>',
      );
      expectDelta(
        delta,
        Delta()
          ..insert('One\n', {'list': 'ordered'})
          ..insert('Alpha\n', {'list': 'ordered', 'indent': 1})
          ..insert('Beta\n', {'list': 'ordered', 'indent': 1})
          ..insert('I\n', {'list': 'ordered', 'indent': 2}),
      );
    });

    test('html nested bullet', () {
      final delta = _clipboard().convert(
        html:
            '<ul><li>One<ul><li>Alpha</li><li>Beta<ul><li>I</li></ul></li></ul></li></ul>',
      );
      expectDelta(
        delta,
        Delta()
          ..insert('One\n', {'list': 'bullet'})
          ..insert('Alpha\n', {'list': 'bullet', 'indent': 1})
          ..insert('Beta\n', {'list': 'bullet', 'indent': 1})
          ..insert('I\n', {'list': 'bullet', 'indent': 2}),
      );
    });

    test('html nested checklist', () {
      final delta = _clipboard().convert(
        html:
            '<ul><li data-list="checked">One<ul><li data-list="checked">Alpha</li><li data-list="checked">Beta<ul><li data-list="checked">I</li></ul></li></ul></li></ul>',
      );
      expectDelta(
        delta,
        Delta()
          ..insert('One\n', {'list': 'checked'})
          ..insert('Alpha\n', {'list': 'checked', 'indent': 1})
          ..insert('Beta\n', {'list': 'checked', 'indent': 1})
          ..insert('I\n', {'list': 'checked', 'indent': 2}),
      );
    });

    test('html partial list', () {
      final delta = _clipboard().convert(
        html:
            '<ol><li><ol><li><ol><li>iiii</li></ol></li><li>bbbb</li></ol></li><li>2222</li></ol>',
      );
      expectDelta(
        delta,
        Delta()
          ..insert('iiii\n', {'list': 'ordered', 'indent': 2})
          ..insert('bbbb\n', {'list': 'ordered', 'indent': 1})
          ..insert('2222\n', {'list': 'ordered'}),
      );
    });

    test('html table', () {
      const html =
          '<table>'
          '<thead><tr><td>A1</td><td>A2</td><td>A3</td></tr></thead>'
          '<tbody><tr><td>B1</td><td></td><td>B3</td></tr></tbody>'
          '</table>';
      final delta = _clipboard().convert(html: html);
      expectDelta(
        delta,
        Delta()
          ..insert('A1\nA2\nA3\n', {'table': 1})
          ..insert('B1\n\nB3\n', {'table': 2}),
      );
    });

    test('embeds', () {
      final delta = _clipboard().convert(
        html:
            '<div>01<img src="/assets/favicon.png" height="200" width="300">34</div>',
      );
      final expected = Delta()
        ..insert('01')
        ..insert(
          {'image': '/assets/favicon.png'},
          {'height': '200', 'width': '300'},
        )
        ..insert('34');
      expectDelta(delta, expected);
    });

    test('block embed', () {
      final delta = _clipboard().convert(
        html: '<p>01</p><iframe src="#"></iframe><p>34</p>',
      );
      expectDelta(
        delta,
        Delta()
          ..insert('01\n')
          ..insert({'video': '#'})
          ..insert('34'),
      );
    });

    test('block embeds within blocks', () {
      final delta = _clipboard().convert(
        html: '<h1>01<iframe src="#"></iframe>34</h1><p>67</p>',
      );
      expectDelta(
        delta,
        Delta()
          ..insert('01\n', {'header': 1})
          ..insert({'video': '#'}, {'header': 1})
          ..insert('34\n', {'header': 1})
          ..insert('67'),
      );
    });

    test('wrapped block embed', () {
      final delta = _clipboard().convert(
        html:
            '<h1>01<a href="/"><iframe src="#"></iframe></a>34</h1><p>67</p>',
      );
      expectDelta(
        delta,
        Delta()
          ..insert('01\n', {'header': 1})
          ..insert({'video': '#'}, {'link': '/', 'header': 1})
          ..insert('34\n', {'header': 1})
          ..insert('67'),
      );
    });

    test('wrapped block embed with siblings', () {
      final delta = _clipboard().convert(
        html:
            '<h1>01<a href="/">a<iframe src="#"></iframe>b</a>34</h1><p>67</p>',
      );
      expectDelta(
        delta,
        Delta()
          ..insert('01', {'header': 1})
          ..insert('a\n', {'link': '/', 'header': 1})
          ..insert({'video': '#'}, {'link': '/', 'header': 1})
          ..insert('b', {'link': '/', 'header': 1})
          ..insert('34\n', {'header': 1})
          ..insert('67'),
      );
    });

    test('attributor and style match', () {
      const html = '<p style="direction:rtl;">Test</p>';
      final attributors = [
        DirectionStyle.instance,
        DirectionClass.instance,
        DirectionAttribute.instance,
      ];
      for (final attributor in attributors) {
        final delta = _clipboard(attributors: [attributor]).convert(html: html);
        expectDelta(delta, Delta()..insert('Test\n', {'direction': 'rtl'}));
      }

      expectDelta(_clipboard().convert(html: html), Delta()..insert('Test'));
    });

    test('nested styles', () {
      const html =
          '<span style="color: red;"><span style="color: blue;">Test</span></span>';
      final attributors = [ColorStyle.instance, ColorClass.instance];
      for (final attributor in attributors) {
        final delta = _clipboard(attributors: [attributor]).convert(html: html);
        expectDelta(delta, Delta()..insert('Test', {'color': 'blue'}));
      }

      expectDelta(_clipboard().convert(html: html), Delta()..insert('Test'));
    });

    test('custom matcher', () {
      final clipboard = _clipboard();
      clipboard.addMatcher(DomNode.TEXT_NODE, (node, delta, scroll) {
        final text = node.textContent ?? '';
        final regex = RegExp(r'https?:\/\/[^\s]+');
        var index = 0;
        final composer = Delta();
        for (final match in regex.allMatches(text)) {
          final retainBefore = match.start - index;
          if (retainBefore > 0) {
            composer.retain(retainBefore);
          }
          index = match.end;
          final matched = match.group(0)!;
          composer.retain(matched.length, {'link': matched});
        }
        return delta.compose(composer);
      });
      final delta = clipboard.convert(
        html: 'http://github.com https://quilljs.com',
      );
      final expected = Delta()
        ..insert('http://github.com', {'link': 'http://github.com'})
        ..insert(' ')
        ..insert('https://quilljs.com', {'link': 'https://quilljs.com'});
      expectDelta(delta, expected);
    });

    test('does not execute javascript', () {
      var wasCalled = false;
      const html =
          "<img src='/assets/favicon.png' onload='wasCalled = true;'/>";
      _clipboard().convert(html: html);
      expect(wasCalled, isFalse);
    });

    test('xss', () {
      final delta = _clipboard().convert(html: '<script>alert(2);</script>');
      expectDelta(delta, Delta()..insert(''));
    });

    test('Google Docs', () {
      const html =
          "<meta charset='utf-8'><meta charset=\"utf-8\"><b style=\"font-weight:normal;\" id=\"docs-internal-guid-6f072e08-7fff-e641-0fbc-7fe2846294a4\"><p dir=\"ltr\" style=\"line-height:1.38;margin-top:0pt;margin-bottom:0pt;\"><span style=\"font-size:11pt;font-family:Arial,sans-serif;color:#000000;background-color:transparent;font-weight:400;font-style:normal;font-variant:normal;text-decoration:none;vertical-align:baseline;white-space:pre;white-space:pre-wrap;\">text</span></p><br /><ol style=\"margin-top:0;margin-bottom:0;padding-inline-start:48px;\"><li dir=\"ltr\" style=\"list-style-type:decimal;font-size:11pt;font-family:Arial,sans-serif;color:#000000;background-color:transparent;font-weight:400;font-style:normal;font-variant:normal;text-decoration:none;vertical-align:baseline;white-space:pre;\" aria-level=\"1\"><p dir=\"ltr\" style=\"line-height:1.38;margin-top:0pt;margin-bottom:0pt;\" role=\"presentation\"><span style=\"font-size:11pt;font-family:Arial,sans-serif;color:#000000;background-color:transparent;font-weight:400;font-style:normal;font-variant:normal;text-decoration:none;vertical-align:baseline;white-space:pre;white-space:pre-wrap;\">i1</span></p></li><li dir=\"ltr\" style=\"list-style-type:decimal;font-size:11pt;font-family:Arial,sans-serif;color:#000000;background-color:transparent;font-weight:400;font-style:normal;font-variant:normal;text-decoration:none;vertical-align:baseline;white-space:pre;\" aria-level=\"1\"><p dir=\"ltr\" style=\"line-height:1.38;margin-top:0pt;margin-bottom:0pt;\" role=\"presentation\"><span style=\"font-size:11pt;font-family:Arial,sans-serif;color:#000000;background-color:transparent;font-weight:400;font-style:normal;font-variant:normal;text-decoration:none;vertical-align:baseline;white-space:pre;white-space:pre-wrap;\">i2</span></p></li><ol style=\"margin-top:0;margin-bottom:0;padding-inline-start:48px;\"><li dir=\"ltr\" style=\"list-style-type:lower-alpha;font-size:11pt;font-family:Arial,sans-serif;color:#000000;background-color:transparent;font-weight:400;font-style:normal;font-variant:normal;text-decoration:none;vertical-align:baseline;white-space:pre;\" aria-level=\"2\"><p dir=\"ltr\" style=\"line-height:1.38;margin-top:0pt;margin-bottom:0pt;\" role=\"presentation\"><span style=\"font-size:11pt;font-family:Arial,sans-serif;color:#000000;background-color:transparent;font-weight:400;font-style:normal;font-variant:normal;text-decoration:none;vertical-align:baseline;white-space:pre;white-space:pre-wrap;\">i3</span></p></li></ol></ol><p dir=\"ltr\" style=\"line-height:1.38;margin-top:0pt;margin-bottom:0pt;\"><span style=\"font-size:11pt;font-family:Arial,sans-serif;color:#000000;background-color:transparent;font-weight:700;font-style:normal;font-variant:normal;text-decoration:none;vertical-align:baseline;white-space:pre;white-space:pre-wrap;\">text</span></p></b><br class=\"Apple-interchange-newline\">";
      final delta = _clipboard().convert(html: html);
      expectDelta(
        delta,
        Delta()
          ..insert('text\n')
          ..insert('i1\ni2\n', {'list': 'ordered'})
          ..insert('i3\n', {'list': 'ordered', 'indent': 1})
          ..insert('text', {'bold': true})
          ..insert('\n'),
      );
    });

    test('pre', () {
      const html = '<pre> 01 \n 23 </pre>';
      final clipboard = _clipboard();
      expectDelta(
        clipboard.convert(html: html, formats: {'code-block': true}),
        Delta()..insert(' 01 \n 23 ', {'code-block': true}),
      );
      expectDelta(
        clipboard.convert(html: html),
        Delta()..insert(' 01 \n 23 '),
      );
    });

    test('pre with newline node', () {
      const html = '<pre><span> 01 </span>\n<span> 23 </span></pre>';
      final delta =
          _clipboard().convert(html: html, formats: {'code-block': true});
      expectDelta(delta, Delta()..insert(' 01 \n 23 ', {'code-block': true}));
    });

    test('ignore empty elements except paragraphs', () {
      final delta = _clipboard()
          .convert(html: '<div>hello<div></div>my<p></p>world</div>');
      expectDelta(delta, Delta()..insert('hello\nmy\n\nworld'));
    });
  });
}
