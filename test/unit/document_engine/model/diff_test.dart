import 'package:test/test.dart';
import 'package:dart_quill/src/document_engine/model/index.dart';
import 'package:dart_quill/src/document_engine/test_builder/index.dart';

void main() {
  group('Fragment', () {
    group('findDiffStart', () {
      void start(PMNode a, PMNode b) {
        expect(a.content.findDiffStart(b.content), equals(a.tag['a']));
      }

      test(
          'returns null for identical nodes',
          () => start(doc(p("a", em("b")), p("hello"), blockquote(h1("bye"))),
              doc(p("a", em("b")), p("hello"), blockquote(h1("bye")))));

      test(
          'notices when one node is longer',
          () => start(
              doc(p("a", em("b")), p("hello"), blockquote(h1("bye")), "<a>"),
              doc(p("a", em("b")), p("hello"), blockquote(h1("bye")),
                  p("oops"))));

      test(
          'notices when one node is shorter',
          () => start(
              doc(p("a", em("b")), p("hello"), blockquote(h1("bye")), "<a>",
                  p("oops")),
              doc(p("a", em("b")), p("hello"), blockquote(h1("bye")))));

      test('notices differing marks',
          () => start(doc(p("a<a>", em("b"))), doc(p("a", strong("b")))));

      test('stops at longer text',
          () => start(doc(p("foo<a>bar", em("b"))), doc(p("foo", em("b")))));

      test('stops at a different character',
          () => start(doc(p("foo<a>bar")), doc(p("foocar"))));

      test('stops at a different node type',
          () => start(doc(p("a"), "<a>", p("b")), doc(p("a"), h1("b"))));

      test('works when the difference is at the start',
          () => start(doc("<a>", p("b")), doc(h1("b"))));

      test('notices a different attribute',
          () => start(doc(p("a"), "<a>", h1("foo")), doc(p("a"), h2("foo"))));

      test('doesn\'t start in the middle of a surrogate pair', () {
        start(doc(p("<a>𝛿")), doc(p("𝛾")));
      });
    });

    group('findDiffEnd', () {
      void end(PMNode a, PMNode b) {
        final found = a.content.findDiffEnd(b.content);
        expect(found?.a, equals(a.tag['a']));
      }

      test(
          'returns null when there is no difference',
          () => end(doc(p("a", em("b")), p("hello"), blockquote(h1("bye"))),
              doc(p("a", em("b")), p("hello"), blockquote(h1("bye")))));

      test(
          'notices when the second doc is longer',
          () => end(
              doc("<a>", p("a", em("b")), p("hello"), blockquote(h1("bye"))),
              doc(p("oops"), p("a", em("b")), p("hello"),
                  blockquote(h1("bye")))));

      test(
          'notices when the second doc is shorter',
          () => end(
              doc(p("oops"), "<a>", p("a", em("b")), p("hello"),
                  blockquote(h1("bye"))),
              doc(p("a", em("b")), p("hello"), blockquote(h1("bye")))));

      test(
          'notices different styles',
          () =>
              end(doc(p("a", em("b"), "<a>c")), doc(p("a", strong("b"), "c"))));

      test('spots longer text',
          () => end(doc(p("bar<a>foo", em("b"))), doc(p("foo", em("b")))));

      test('spots different text',
          () => end(doc(p("foob<a>ar")), doc(p("foocar"))));

      test('notices different nodes',
          () => end(doc(p("a"), "<a>", p("b")), doc(h1("a"), p("b"))));

      test('notices a difference at the end',
          () => end(doc(p("b"), "<a>"), doc(h1("b"))));

      test('handles a similar start',
          () => end(doc("<a>", p("hello")), doc(p("hey"), p("hello"))));

      test('doesn\'t end in the middle of a surrogate pair', () {
        end(doc(p("𝋾<a>")), doc(p("𝛾")));
      });
    });
  });
}
