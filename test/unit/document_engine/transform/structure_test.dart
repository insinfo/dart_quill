import 'package:test/test.dart';
import 'package:dart_quill/src/document_engine/model/index.dart';
import 'package:dart_quill/src/document_engine/transform/index.dart';
import 'package:dart_quill/src/document_engine/test_builder/schema.dart' show testSchema;

final schema = Schema(SchemaSpec(
  nodes: {
    'doc': NodeSpec(content: "head? block* sect* closing?"),
    'para': NodeSpec(content: "text*", group: "block"),
    'head': NodeSpec(content: "text*", marks: ""),
    'figure': NodeSpec(content: "caption figureimage", group: "block"),
    'quote': NodeSpec(content: "block+", group: "block"),
    'figureimage': NodeSpec(),
    'caption': NodeSpec(content: "text*", marks: ""),
    'sect': NodeSpec(content: "head block* sect*"),
    'closing': NodeSpec(content: "text*"),
    'text': testSchema.spec.nodes['text']!,
    'fixed': NodeSpec(content: "head para closing", group: "block")
  },
  marks: {
    'em': MarkSpec()
  }
));

PMNode n(String name, [List<PMNode> content = const []]) {
  return schema.nodes[name]!.create(null, content);
}

PMNode t(String str, [bool em = false]) {
  return schema.text(str, em ? [schema.marks['em']!.create()] : null);
}

final testDoc = n("doc", [ // 0
  n("head", [t("Head")]), // 6
  n("para", [t("Intro")]), // 13
  n("sect", [ // 14
    n("head", [t("Section head")]), // 28
    n("sect", [ // 29
      n("head", [t("Subsection head")]), // 46
      n("para", [t("Subtext")]), // 55
      n("figure", [ // 56
        n("caption", [t("Figure caption")]), // 72
        n("figureimage") // 74
      ]),
      n("quote", [n("para", [t("!")])]) // 81
    ])
  ]),
  n("sect", [ // 82
    n("head", [t("S2")]), // 86
    n("para", [t("Yes")]) // 92
  ]),
  n("closing", [t("fin")]) // 97
]);

NodeRange? range(int pos, [int? end]) {
  return testDoc.resolve(pos).blockRange(end == null ? null : testDoc.resolve(end));
}

void main() {
  group('canSplit', () {
    void Function() yes(int pos, [int depth = 1, String? after]) {
      return () => expect(canSplit(testDoc, pos, depth, after == null ? null : [Wrapping(schema.nodes[after]!)]), isTrue);
    }

    void Function() no(int pos, [int depth = 1, String? after]) {
      return () => expect(canSplit(testDoc, pos, depth, after == null ? null : [Wrapping(schema.nodes[after]!)]), isFalse);
    }

    test('can\'t at start', no(0));
    test('can\'t in head', no(3));
    test('can by making head a para', yes(3, 1, "para"));
    test('can\'t on top level', no(6));
    test('can in regular para', yes(8));
    test('can\'t at start of section', no(14));
    test('can\'t in section head', no(17));
    test('can if also splitting the section', yes(17, 2));
    test('can if making the remaining head a para', yes(18, 1, "para"));
    test('can\'t after the section head', no(46));
    test('can in the first section para', yes(48));
    test('can\'t in the figure caption', no(60));
    test('can\'t if it also splits the figure', no(62, 2));
    test('can\'t after the figure caption', no(72));
    test('can in the first para in a quote', yes(76));
    test('can if it also splits the quote', yes(77, 2));
    test('can\'t at the end of the document', no(97));

    test('doesn\'t return true when the split-off content doesn\'t fit in the given node type', () {
      final s = Schema(SchemaSpec(
        nodes: Map.from(schema.spec.nodes)
          ..addAll({
            'heading': NodeSpec(content: "text*"),
            'title': NodeSpec(content: "text*"),
            'chapter': NodeSpec(content: "title scene+"),
            'scene': NodeSpec(content: "para+"),
          })
          ..update('doc', (val) => NodeSpec(content: "chapter+")),
        marks: schema.spec.marks
      ));
      expect(canSplit(s.node("doc", null, [s.node("chapter", null, [
        s.node("title", null, [s.text("title")]),
        s.node("scene", null, [s.node("para", null, [s.text("scene")])])
      ])]), 4, 1, [Wrapping(s.nodes['scene']!)]), isFalse);
    });
  });

  group('liftTarget', () {
    void Function() yes(int pos) {
      return () {
        final r = range(pos);
        expect(r, isNotNull);
        expect(liftTarget(r!), isNotNull);
      };
    }
    
    void Function() no(int pos) {
      return () {
        final r = range(pos);
        expect(r == null || liftTarget(r) == null, isTrue);
      };
    }

    test('can\'t at the start of the doc', no(0));
    test('can\'t in the heading', no(3));
    test('can\'t in a subsection para', no(52));
    test('can\'t in a figure caption', no(70));
    test('can from a quote', yes(76));
    test('can\'t in a section head', no(86));

    test('notices unliftable content after or before', () {
      final s = Schema(SchemaSpec(
        nodes: {
          'doc': NodeSpec(content: "section+"),
          'section': NodeSpec(content: "heading? p+"),
          'heading': NodeSpec(content: "p+"),
          'p': NodeSpec(content: "text*"),
          'text': NodeSpec(inline: true),
        }
      ));
      final pNode = s.node("p", null, [s.text("A")]);
      final d = s.node("doc", null, [s.node("section", null, [s.node("heading", null, [pNode, pNode, pNode]), pNode])]);
      final range1 = d.resolve(3).blockRange();
      expect(range1 == null || liftTarget(range1) == null, isTrue);
      
      final range2 = d.resolve(6).blockRange();
      expect(range2 == null || liftTarget(range2) == null, isTrue);
      
      final range3 = d.resolve(3).blockRange(d.resolve(6));
      expect(range3 == null || liftTarget(range3) == null, isTrue);
      
      final range4 = d.resolve(9).blockRange();
      expect(range4 != null ? liftTarget(range4) : null, equals(1));
    });
  });

  group('findWrapping', () {
    void Function() yes(int pos, int end, String type) {
      return () {
        final r = range(pos, end);
        expect(r, isNotNull);
        expect(findWrapping(r!, schema.nodes[type]!), isNotNull);
      };
    }

    void Function() no(int pos, int end, String type) {
      return () {
        final r = range(pos, end);
        expect(r == null || findWrapping(r, schema.nodes[type]!) == null, isTrue);
      };
    }

    test('can wrap the whole doc in a section', yes(0, 92, "sect"));
    test('can\'t wrap a head before a para in a section', no(4, 4, "sect"));
    test('can wrap a top paragraph in a quote', yes(8, 8, "quote"));
    test('can\'t wrap a section head in a quote', no(18, 18, "quote"));
    test('can wrap a figure in a quote', yes(55, 74, "quote"));
    test('can\'t wrap a head in a figure', no(90, 90, "figure"));
  });

  group('Transform', () {
    group('replace', () {
      void Function() repl(PMNode docNode, int from, int to, PMNode? content, int openStart, int openEnd, PMNode result) {
        return () {
          final slice = content != null ? Slice(content.content, openStart, openEnd) : Slice.empty;
          final tr = Transform(docNode).replace(from, to, slice);
          expect(tr.doc.toJSON(), equals(result.toJSON()));
          expect(tr.doc.eq(result), isTrue);
        };
      }

      test('automatically adds a heading to a section',
         repl(n("doc", [n("sect", [n("head", [t("foo")]), n("para", [t("bar")])])]),
              6, 6, n("doc", [n("sect"), n("sect")]), 1, 1,
              n("doc", [n("sect", [n("head", [t("foo")])]), n("sect", [n("head"), n("para", [t("bar")])])])));

      test('suppresses impossible inputs',
         repl(n("doc", [n("para", [t("a")]), n("para", [t("b")])]),
              3, 3, n("doc", [n("closing", [t(".")])]), 0, 0,
              n("doc", [n("para", [t("a")]), n("para", [t("b")])])));

      test('adds necessary nodes to the left',
         repl(n("doc", [n("sect", [n("head", [t("foo")]), n("para", [t("bar")])])]),
              1, 3, n("doc", [n("sect"), n("sect", [n("head", [t("hi")])])]), 1, 2,
              n("doc", [n("sect", [n("head")]), n("sect", [n("head", [t("hioo")]), n("para", [t("bar")])])])));

      test('adds a caption to a figure',
         repl(n("doc"),
              0, 0, n("doc", [n("figure", [n("figureimage")])]), 1, 0,
              n("doc", [n("figure", [n("caption"), n("figureimage")])])));

      test('adds an image to a figure',
         repl(n("doc"),
              0, 0, n("doc", [n("figure", [n("caption")])]), 0, 1,
              n("doc", [n("figure", [n("caption"), n("figureimage")])])));

      test('can join figures',
         repl(n("doc", [n("figure", [n("caption"), n("figureimage")]), n("figure", [n("caption"), n("figureimage")])]),
              3, 8, null, 0, 0,
              n("doc", [n("figure", [n("caption"), n("figureimage")])])));

      test('adds necessary nodes to a parent node',
         repl(n("doc", [n("sect", [n("head"), n("figure", [n("caption"), n("figureimage")])])]),
              7, 9, n("doc", [n("para", [t("hi")])]), 0, 0,
              n("doc", [n("sect", [n("head"), n("figure", [n("caption"), n("figureimage")]), n("para", [t("hi")])])])));
    });
  });
}
