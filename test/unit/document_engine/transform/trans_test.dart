import 'package:test/test.dart';
import 'package:dart_quill/src/document_engine/model/index.dart';
import 'package:dart_quill/src/document_engine/transform/index.dart';
import 'package:dart_quill/src/document_engine/test_builder/index.dart';
import 'package:dart_quill/src/document_engine/test_builder/schema.dart';
import 'trans.dart'; // From the trans.ts port

int getTag(PMNode node, String tagKey) {
  return node.tag[tagKey] ?? (throw Exception("Missing tag \$tagKey on \$node"));
}

int? tagOpt(PMNode node, String tagKey) {
  return node.tag[tagKey];
}

void main() {
  registerReplaceSteps();
  registerMarkSteps();
  registerAttrSteps();

  group('Transform', () {
    group('addMark', () {
      void add(PMNode docNode, Mark mark, PMNode expectNode) {
        testTransform(Transform(docNode).addMark(getTag(docNode, "a"), getTag(docNode, "b"), mark), expectNode);
      }

      test('should add a mark', () =>
         add(doc(p("hello <a>there<b>!")),
             testSchema.marks['strong']!.create(),
             doc(p("hello ", strong("there"), "!"))));

      test('should only add a mark once', () =>
         add(doc(p("hello ", strong("<a>there"), "!<b>")),
             testSchema.marks['strong']!.create(),
             doc(p("hello ", strong("there!")))));

      test('should join overlapping marks', () =>
         add(doc(p("one <a>two ", em("three<b> four"))),
             testSchema.marks['strong']!.create(),
             doc(p("one ", strong("two ", em("three")), em(" four")))));

      test('should overwrite marks with different attributes', () =>
         add(doc(p("this is a ", a({"href": "bar"}, "<a>link<b>"))),
             testSchema.marks['link']!.create({'href': "bar"}),
             doc(p("this is a ", a({'href': "bar"}, "link")))));

      test('can add a mark in a nested node', () =>
         add(doc(p("before"), blockquote(p("the variable is called <a>i<b>")), p("after")),
             testSchema.marks['code']!.create(),
             doc(p("before"), blockquote(p("the variable is called ", code("i"))), p("after"))));

      test('can add a mark across blocks', () =>
         add(doc(p("hi <a>this"), blockquote(p("is")), p("a docu<b>ment"), p("!")),
             testSchema.marks['em']!.create(),
             doc(p("hi ", em("this")), blockquote(p(em("is"))), p(em("a docu"), "ment"), p("!"))));
    });

    group('removeMark', () {
      void rem(PMNode docNode, Mark? mark, PMNode expectNode) {
        testTransform(Transform(docNode).removeMark(getTag(docNode, "a"), getTag(docNode, "b"), mark), expectNode);
      }

      test('can cut a gap', () =>
         rem(doc(p(em("hello <a>world<b>!"))),
             testSchema.marks['em']!.create(),
             doc(p(em("hello "), "world", em("!")))));

      test('doesn\'t do anything when there\'s no mark', () =>
         rem(doc(p(em("hello"), " <a>world<b>!")),
             testSchema.marks['em']!.create(),
             doc(p(em("hello"), " <a>world<b>!"))));

      test('can remove marks from nested nodes', () =>
         rem(doc(p(em("one ", strong("<a>two<b>"), " three"))),
             testSchema.marks['strong']!.create(),
             doc(p(em("one two three")))));

      test('can remove a link', () =>
         rem(doc(p("<a>hello ", a({"href": "foo"}, "link<b>"))),
             testSchema.marks['link']!.create({'href': "foo"}),
             doc(p("hello link"))));

      test('doesn\'t remove a non-matching link', () =>
         rem(doc(p("<a>hello ", a({"href": "bar"}, "link<b>"))),
             testSchema.marks['link']!.create({'href': "foo"}),
             doc(p("hello ", a({"href": "bar"}, "link")))));

      test('can remove across blocks', () =>
         rem(doc(blockquote(p(em("much <a>em")), p(em("here too"))), p("between", em("...")), p(em("end<b>"))),
             testSchema.marks['em']!.create(),
             doc(blockquote(p(em("much "), "em"), p("here too")), p("between..."), p("end"))));

      test('can remove everything', () =>
         rem(doc(p("<a>hello, ", em("this is ", strong("much"), " ", a({"href": "bar"}, "markup<b>")))),
             null,
             doc(p("<a>hello, this is much markup"))));
    });

    group('insert', () {
      void ins(PMNode docNode, dynamic nodes, PMNode expectNode) {
        testTransform(Transform(docNode).insert(getTag(docNode, "a"), nodes), expectNode);
      }

      test('can insert a break', () =>
         ins(doc(p("hello<a>there")),
             testSchema.nodes['hard_break']!.create(),
             doc(p("hello", br(), "<a>there"))));

      test('can insert an empty paragraph at the top', () =>
         ins(doc(p("one"), "<a>", p("two<2>")),
             testSchema.nodes['paragraph']!.create(),
             doc(p("one"), p(), "<a>", p("two<2>"))));

      test('can insert two block nodes', () =>
         ins(doc(p("one"), "<a>", p("two<2>")),
             [testSchema.nodes['paragraph']!.create(null, [testSchema.text("hi")]),
              testSchema.nodes['horizontal_rule']!.create()],
             doc(p("one"), p("hi"), hr(), "<a>", p("two<2>"))));

      test('can insert at the end of a blockquote', () =>
         ins(doc(blockquote(p("he<before>y"), "<a>"), p("after<after>")),
             testSchema.nodes['paragraph']!.create(),
             doc(blockquote(p("he<before>y"), p()), p("after<after>"))));

      test('can insert at the start of a blockquote', () =>
         ins(doc(blockquote("<a>", p("he<1>y")), p("after<2>")),
             testSchema.nodes['paragraph']!.create(),
             doc(blockquote(p(), "<a>", p("he<1>y")), p("after<2>"))));
    });

    group('delete', () {
      void del(PMNode docNode, PMNode expectNode) {
        testTransform(Transform(docNode).delete(getTag(docNode, "a"), getTag(docNode, "b")), expectNode);
      }

      test('can delete a word', () =>
         del(doc(p("<1>one"), "<a>", p("tw<2>o"), "<b>", p("<3>three")),
             doc(p("<1>one"), "<a><2>", p("<3>three"))));

      test('preserves content constraints', () =>
         del(doc(blockquote("<a>", p("hi"), "<b>"), p("x")),
             doc(blockquote(p()), p("x"))));

      test('preserves positions after the range', () =>
         del(doc(blockquote(p("a"), "<a>", p("b"), "<b>"), p("c<1>")),
             doc(blockquote(p("a")), p("c<1>"))));

      test('doesn\'t join incompatible nodes', () {
         del(doc(pre("fo<a>o"), p("b<b>ar", img({"src": "foo"}))),
             doc(pre("fo"), p("ar", img({"src": "foo"}))));
      });
    });

    group('join', () {
      void join(PMNode docNode, PMNode expectNode) {
        testTransform(Transform(docNode).join(getTag(docNode, "a")), expectNode);
      }

      test('can join blocks', () =>
         join(doc(blockquote(p("<before>a")), "<a>", blockquote(p("b")), p("after<after>")),
              doc(blockquote(p("<before>a"), "<a>", p("b")), p("after<after>"))));

      test('can join compatible blocks', () =>
         join(doc(h1("foo"), "<a>", p("bar")),
              doc(h1("foobar"))));

      test('can join nested blocks', () =>
         join(doc(blockquote(blockquote(p("a"), p("b<before>")), "<a>", blockquote(p("c"), p("d<after>")))),
              doc(blockquote(blockquote(p("a"), p("b<before>"), "<a>", p("c"), p("d<after>"))))));

      test('can join lists', () =>
         join(doc(ol(li(p("one")), li(p("two"))), "<a>", ol(li(p("three")))),
              doc(ol(li(p("one")), li(p("two")), "<a>", li(p("three"))))));
    });

    group('split', () {
      void split(PMNode docNode, dynamic expectNode, [int depth = 1, List<Wrapping?>? typesAfter]) {
        if (expectNode == "fail") {
          expect(() => Transform(docNode).split(getTag(docNode, "a"), depth, typesAfter), throwsA(isA<TransformError>()));
        } else {
          testTransform(Transform(docNode).split(getTag(docNode, "a"), depth, typesAfter), expectNode as PMNode);
        }
      }

      test('can split a textblock', () =>
         split(doc(p("foo<a>bar")),
               doc(p("foo"), p("<a>bar"))));

      test('correctly maps positions', () =>
         split(doc(p("<1>a"), p("<2>foo<a>bar<3>"), p("<4>b")),
               doc(p("<1>a"), p("<2>foo"), p("<a>bar<3>"), p("<4>b"))));

      test('can split two deep', () =>
         split(doc(blockquote(blockquote(p("foo<a>bar"))), p("after<1>")),
               doc(blockquote(blockquote(p("foo")), blockquote(p("<a>bar"))), p("after<1>")),
               2));

      test('can split three deep', () =>
         split(doc(blockquote(blockquote(p("foo<a>bar"))), p("after<1>")),
               doc(blockquote(blockquote(p("foo"))), blockquote(blockquote(p("<a>bar"))), p("after<1>")),
               3));

      test('can split at end', () =>
         split(doc(blockquote(p("hi<a>"))),
               doc(blockquote(p("hi"), p("<a>")))));

      test('can split at start', () =>
         split(doc(blockquote(p("<a>hi"))),
               doc(blockquote(p(), p("<a>hi")))));

      test('can split inside a list item', () =>
         split(doc(ol(li(p("one<1>")), li(p("two<a>three")), li(p("four<2>")))),
               doc(ol(li(p("one<1>")), li(p("two"), p("<a>three")), li(p("four<2>"))))));

      test('can split a list item', () =>
         split(doc(ol(li(p("one<1>")), li(p("two<a>three")), li(p("four<2>")))),
               doc(ol(li(p("one<1>")), li(p("two")), li(p("<a>three")), li(p("four<2>")))),
               2));

      test('respects the type param', () =>
         split(doc(h1("hell<a>o!")),
               doc(h1("hell"), p("<a>o!")),
               1, [Wrapping(testSchema.nodes['paragraph']!)]));

      test('preserves content constraints before', () =>
         split(doc(blockquote("<a>", p("x"))), "fail"));

      test('preserves content constraints after', () =>
         split(doc(blockquote(p("x"), "<a>")), "fail"));
    });

    group('lift', () {
      void lift(PMNode docNode, PMNode expectNode) {
        NodeRange? range = docNode.resolve(getTag(docNode, "a")).blockRange(docNode.resolve(tagOpt(docNode, "b") ?? getTag(docNode, "a")));
        testTransform(Transform(docNode).lift(range!, liftTarget(range)!), expectNode);
      }

      test('can lift a block out of the middle of its parent', () =>
         lift(doc(blockquote(p("<before>one"), p("<a>two"), p("<after>three"))),
              doc(blockquote(p("<before>one")), p("<a>two"), blockquote(p("<after>three")))));

      test('can lift a block from the start of its parent', () =>
         lift(doc(blockquote(p("<a>two"), p("<after>three"))),
              doc(p("<a>two"), blockquote(p("<after>three")))));

      test('can lift a block from the end of its parent', () =>
         lift(doc(blockquote(p("<before>one"), p("<a>two"))),
              doc(blockquote(p("<before>one")), p("<a>two"))));

      test('can lift a single child', () =>
         lift(doc(blockquote(p("<a>t<in>wo"))),
              doc(p("<a>t<in>wo"))));

      test('can lift multiple blocks', () =>
         lift(doc(blockquote(blockquote(p("on<a>e"), p("tw<b>o")), p("three"))),
              doc(blockquote(p("on<a>e"), p("tw<b>o"), p("three")))));

      test('finds a valid range from a lopsided selection', () =>
         lift(doc(p("start"), blockquote(blockquote(p("a"), p("<a>b")), p("<b>c"))),
              doc(p("start"), blockquote(p("a"), p("<a>b")), p("<b>c"))));

      test('can lift from a nested node', () =>
         lift(doc(blockquote(blockquote(p("<1>one"), p("<a>two"), p("<3>three"), p("<b>four"), p("<5>five")))),
              doc(blockquote(blockquote(p("<1>one")), p("<a>two"), p("<3>three"), p("<b>four"), blockquote(p("<5>five"))))));

      test('can lift from a list', () =>
         lift(doc(ul(li(p("one")), li(p("two<a>")), li(p("three")))),
              doc(ul(li(p("one"))), p("two<a>"), ul(li(p("three"))))));

      test('can lift from the end of a list', () =>
         lift(doc(ul(li(p("a")), li(p("b<a>")), "<1>")),
              doc(ul(li(p("a"))), p("b<a>"), "<1>")));
    });

    group('wrap', () {
      void wrap(PMNode docNode, PMNode expectNode, String type, [Map<String, dynamic>? attrs]) {
        NodeRange? range = docNode.resolve(getTag(docNode, "a")).blockRange(docNode.resolve(tagOpt(docNode, "b") ?? getTag(docNode, "a")));
        testTransform(Transform(docNode).wrap(range!, findWrapping(range, testSchema.nodes[type]!, attrs)!), expectNode);
      }

      test('can wrap in a blockquote', () =>
         wrap(doc(p("one"), p("<a>two"), p("three")),
              doc(p("one"), blockquote(p("<a>two")), p("three")),
              "blockquote"));

      test('can wrap two blocks', () =>
         wrap(doc(p("one<1>"), p("<a>two"), p("<b>three"), p("four<4>")),
              doc(p("one<1>"), blockquote(p("<a>two"), p("three")), p("four<4>")),
              "blockquote"));

      test('can wrap in a list', () =>
         wrap(doc(p("<a>one"), p("<b>two")),
              doc(ul(li(p("<a>one"), p("<b>two")))),
              "bullet_list"));
    });

    group('setBlockType', () {
      void set(PMNode docNode, PMNode expectNode, String type, [Map<String, dynamic>? attrs]) {
        testTransform(Transform(docNode).setBlockType(getTag(docNode, "a"), tagOpt(docNode, "b") ?? getTag(docNode, "a"), testSchema.nodes[type], attrs), expectNode);
      }

      test('can change a single textblock', () =>
         set(doc(p("am<a> i")), doc(h2("am i")), "heading", {"level": 2}));

      test('can change multiple blocks', () =>
         set(doc(h1("<a>hello"), p("there"), p("<b>!"), p("x")),
             doc(pre("hello"), pre("there"), pre("!"), p("x")),
             "code_block"));

      test('can change a wrapped block', () =>
         set(doc(blockquote(p("<a>hi"))), doc(blockquote(h1("hi"))), "heading", {"level": 1}));

      test('clears markup when necessary', () =>
         set(doc(p("<a>v", em("ery"), " ", strong("well"))),
             doc(pre("very well")),
             "code_block"));
    });

    group('setNodeMarkup', () {
      void set(PMNode docNode, PMNode expectNode, String? type, [Map<String, dynamic>? attrs]) {
        testTransform(Transform(docNode).setNodeMarkup(getTag(docNode, "a"), type != null ? testSchema.nodes[type] : null, attrs), expectNode);
      }

      test('can change the markup of a paragraph', () =>
         set(doc("<a>", p("foo")), doc(h1("foo")), "heading", {"level": 1}));

      test('can change the markup of an inline node', () =>
         set(doc(p("foo<a>", img({"src": "foo.png"}), "bar")), doc(p("foo", img({"alt": "x", "src": "foo.png"}), "bar")), null, {"alt": "x", "src": "foo.png"}));
    });

    group('setNodeAttribute', () {
      void set(PMNode docNode, String attr, dynamic value, PMNode expectNode) {
        testTransform(Transform(docNode).setNodeAttribute(getTag(docNode, "a"), attr, value), expectNode);
      }

      test('sets an attribute', () =>
        set(doc("<a>", h1("a")), "level", 2, doc("<a>", h2("a"))));
    });
  });
}
