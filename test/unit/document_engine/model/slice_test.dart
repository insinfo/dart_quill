import 'package:test/test.dart';
import 'package:dart_quill/src/document_engine/model/index.dart';
import 'package:dart_quill/src/document_engine/test_builder/index.dart';

void main() {
  group('Node', () {
    group('slice', () {
      void t(PMNode docNode, PMNode expectNode, int openStart, int openEnd) {
        int a = docNode.tag['a'] ?? 0;
        int b = docNode.tag['b'] ?? docNode.content.size;

        Slice slice = docNode.slice(a, b);
        if (!slice.content.eq(expectNode.content) ||
            slice.openStart != openStart ||
            slice.openEnd != openEnd) {
          print('ACTUAL slice toJSON: \${slice.content.toJSON()}');
          print('EXPECTED slice toJSON: \${expectNode.content.toJSON()}');

          void traceEq(Fragment f1, Fragment f2, String path) {
            if (f1.content.length != f2.content.length)
              print(path +
                  ' length diff ' +
                  f1.content.length.toString() +
                  ' != ' +
                  f2.content.length.toString());
            for (int i = 0; i < f1.content.length; i++) {
              if (i >= f2.content.length) break;
              PMNode n1 = f1.content[i];
              PMNode n2 = f2.content[i];
              if (n1.type != n2.type)
                print(path +
                    '[' +
                    i.toString() +
                    '] type diff ' +
                    n1.type.name +
                    ' != ' +
                    n2.type.name);
              if (!n1.sameMarkup(n2))
                print(path + '[' + i.toString() + '] sameMarkup failed');
              if (n1 is TextNode && n2 is TextNode && n1.text != n2.text)
                print(path +
                    '[' +
                    i.toString() +
                    '] text diff ' +
                    n1.text +
                    ' != ' +
                    n2.text);
              traceEq(n1.content, n2.content, path + '[' + i.toString() + ']');
            }
          }

          traceEq(slice.content, expectNode.content, "root");
        }
        expect(slice.content.eq(expectNode.content), isTrue);
        expect(slice.openStart, equals(openStart));
        expect(slice.openEnd, equals(openEnd));
      }

      test('can cut half a paragraph',
          () => t(doc(p("hello<b> world")), doc(p("hello")), 0, 1));

      test('can cut to the end of a pragraph',
          () => t(doc(p("hello<b>")), doc(p("hello")), 0, 1));

      test('leaves off extra content',
          () => t(doc(p("hello<b> world"), p("rest")), doc(p("hello")), 0, 1));

      test(
          'preserves styles',
          () => t(doc(p("hello ", em("WOR<b>LD"))), doc(p("hello ", em("WOR"))),
              0, 1));

      test('can cut multiple blocks',
          () => t(doc(p("a"), p("b<b>")), doc(p("a"), p("b")), 0, 1));

      test('can cut to a top-level position',
          () => t(doc(p("a"), "<b>", p("b")), doc(p("a")), 0, 0));

      test(
          'can cut to a deep position',
          () => t(doc(blockquote(ul(li(p("a")), li(p("b<b>"))))),
              doc(blockquote(ul(li(p("a")), li(p("b"))))), 0, 4));

      test('can cut everything after a position',
          () => t(doc(p("hello<a> world")), doc(p(" world")), 1, 0));

      test('can cut from the start of a textblock',
          () => t(doc(p("<a>hello")), doc(p("hello")), 1, 0));

      test('leaves off extra content before',
          () => t(doc(p("foo"), p("bar<a>baz")), doc(p("baz")), 1, 0));

      test(
          'preserves styles after cut',
          () => t(
              doc(p("a sentence with an ",
                  em("emphasized ", a({'href': 'foo'}, "li<a>nk")), " in it")),
              doc(p(em(a({'href': 'foo'}, "nk")), " in it")),
              1,
              0));

      test(
          'preserves styles started after cut',
          () => t(
              doc(p("a ", em("sentence"), " wi<a>th ", em("text"), " in it")),
              doc(p("th ", em("text"), " in it")),
              1,
              0));

      test('can cut from a top-level position',
          () => t(doc(p("a"), "<a>", p("b")), doc(p("b")), 0, 0));

      test(
          'can cut from a deep position',
          () => t(doc(blockquote(ul(li(p("a")), li(p("<a>b"))))),
              doc(blockquote(ul(li(p("b"))))), 4, 0));

      test('can cut part of a text node',
          () => t(doc(p("hell<a>o wo<b>rld")), p("o wo"), 0, 0));

      test('can cut across paragraphs',
          () => t(doc(p("on<a>e"), p("t<b>wo")), doc(p("e"), p("t")), 1, 1));

      test(
          'can cut part of marked text',
          () => t(doc(p("here's noth<a>ing and ", em("here's e<b>m"))),
              p("ing and ", em("here's e")), 0, 0));

      test(
          'can cut across different depths',
          () => t(
              doc(ul(li(p("hello")), li(p("wo<a>rld")), li(p("x"))),
                  p(em("bo<b>o"))),
              doc(ul(li(p("rld")), li(p("x"))), p(em("bo"))),
              3,
              1));

      test(
          'can cut between deeply nested nodes',
          () => t(
              doc(blockquote(p("foo<a>bar"),
                  ul(li(p("a")), li(p("b"), "<b>", p("c"))), p("d"))),
              blockquote(p("bar"), ul(li(p("a")), li(p("b")))),
              1,
              2));

      test('can include parents', () {
        PMNode d = doc(blockquote(p("fo<a>o"), p("bar<b>")));
        Slice slice = d.slice(d.tag['a']!, d.tag['b']!, true);
        expect(slice.toString(),
            equals('<blockquote(paragraph("o"), paragraph("bar"))>(2,2)'));
      });
    });
  });
}
