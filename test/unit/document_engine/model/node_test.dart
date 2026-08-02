import 'package:test/test.dart';
import 'package:dart_quill/src/document_engine/model/index.dart';
import 'package:dart_quill/src/document_engine/test_builder/index.dart';

void main() {
  final customSchema = Schema(SchemaSpec(
    nodes: {
      'doc': NodeSpec(content: 'paragraph+'),
      'paragraph': NodeSpec(content: '(text|contact)*'),
      'text': NodeSpec(), // Emulating custom debug string would require dart changes to PMNode, skip
      'contact': NodeSpec(
        inline: true,
        attrs: {'name': AttributeSpec(), 'email': AttributeSpec()},
        leafText: (PMNode node) => "${node.attrs['name']} <${node.attrs['email']}>"
      ),
      'hard_break': NodeSpec()
    }
  ));

  group('Node', () {
    group('toString', () {
      test('nests', () {
        expect(doc(ul(li(p("hey"), p()), li(p("foo")))).toString(),
            equals('doc(bullet_list(list_item(paragraph("hey"), paragraph), list_item(paragraph("foo"))))'));
      });

      test('shows inline children', () {
        expect(doc(p("foo", img({'src': ''}), br(), "bar")).toString(),
            equals('doc(paragraph("foo", image, hard_break, "bar"))'));
      });

      test('shows marks', () {
        expect(doc(p("foo", em("bar", strong("quux")), code("baz"))).toString(),
            equals('doc(paragraph("foo", em("bar"), em(strong("quux")), code("baz")))'));
      });
    });

    group('cut', () {
      void cut(PMNode docNode, PMNode cutNode) {
        int a = docNode.tag['a'] ?? 0;
        int b = docNode.tag['b'] ?? docNode.content.size;
        expect(docNode.cut(a, b).eq(cutNode), isTrue);
      }

      test('extracts a full block', () =>
          cut(doc(p("foo"), "<a>", p("bar"), "<b>", p("baz")),
              doc(p("bar"))));

      test('cuts text', () =>
          cut(doc(p("0"), p("foo<a>bar<b>baz"), p("2")),
              doc(p("bar"))));

      test('cuts deeply', () =>
          cut(doc(blockquote(ul(li(p("a"), p("b<a>c")), li(p("d")), "<b>", li(p("e"))), p("3"))),
              doc(blockquote(ul(li(p("c")), li(p("d")))))));

      test('works from the left', () {
        PMNode d = doc(blockquote(p("foo<b>bar")));
        cut(d, doc(blockquote(p("foo"))));
      });

      test('works to the right', () {
        PMNode d = doc(blockquote(p("foo<a>bar")));
        cut(d, doc(blockquote(p("bar"))));
      });

      test('preserves marks', () {
        PMNode d = doc(p("foo", em("ba<a>r", img({'src': ''}), strong("baz"), br()), "qu<b>ux", code("xyz")));
        cut(d, doc(p(em("r", img({'src': ''}), strong("baz"), br()), "qu")));
      });
    });

    group('between', () {
      void between(PMNode docNode, List<String> nodes) {
        int i = 0;
        int a = docNode.tag['a'] ?? 0;
        int b = docNode.tag['b'] ?? docNode.content.size;
        
        docNode.nodesBetween(a, b, (PMNode node, int pos, PMNode? parent, int index) {
          if (i == nodes.length) {
            fail("More nodes iterated than listed (\${node.type.name})");
          }
          String compare = node.isText ? node.text! : node.type.name;
          if (compare != nodes[i++]) {
            fail("Expected \${nodes[i - 1]}, got \$compare");
          }
          if (!node.isText && docNode.nodeAt(pos) != node) {
            fail("Pos \$pos does not point at node \$node \${docNode.nodeAt(pos)}");
          }
          return true; // continue
        });
      }

      test('iterates over text', () =>
          between(doc(p("foo<a>bar<b>baz")),
                  ["paragraph", "foobarbaz"]));

      test('descends multiple levels', () =>
          between(doc(blockquote(ul(li(p("f<a>oo")), p("b"), "<b>"), p("c"))),
                  ["blockquote", "bullet_list", "list_item", "paragraph", "foo", "paragraph", "b"]));

      test('iterates over inline nodes', () =>
          between(doc(p(em("x"), "f<a>oo", em("bar", img({'src': ''}), strong("baz"), br()), "quux", code("xy<b>z"))),
                  ["paragraph", "foo", "bar", "image", "baz", "hard_break", "quux", "xyz"]));
    });

    group('textBetween', () {
      test('works when passing a custom function as leafText', () {
        final d = doc(p("foo", img({'src': ''}), br()));
        expect(d.textBetween(0, d.content.size, blockSeparator: '', leafText: (node) {
          if (node.type.name == 'image') return '<image>';
          if (node.type.name == 'hard_break') return '<break>';
          return "";
        }), equals('foo<image><break>'));
      });

      test('works with leafText', () {
        final d = customSchema.nodes['doc']!.createChecked({}, [
          customSchema.nodes['paragraph']!.createChecked({}, [
            customSchema.text("Hello "),
            customSchema.nodes['contact']!.createChecked({'name': "Alice", 'email': "alice@example.com"})
          ])
        ]);
        expect(d.textBetween(0, d.content.size), equals('Hello Alice <alice@example.com>'));
      });

      test('should ignore leafText when passing a custom leafText', () {
        final d = customSchema.nodes['doc']!.createChecked({}, [
          customSchema.nodes['paragraph']!.createChecked({}, [
            customSchema.text("Hello "),
            customSchema.nodes['contact']!.createChecked({'name': "Alice", 'email': "alice@example.com"})
          ])
        ]);
        expect(d.textBetween(0, d.content.size, blockSeparator: '', leafText: (PMNode node) => '<anonymous>'), equals('Hello <anonymous>'));
      });

      test('adds block separator around empty paragraphs', () {
        expect(doc(p("one"), p(), p("two")).textBetween(0, 12, blockSeparator: "\n"), equals("one\n\ntwo"));
      });

      test('adds block separator around leaf nodes', () {
        expect(doc(p("one"), hr(), hr(), p("two")).textBetween(0, 12, blockSeparator: "\n", leafText: (n) => "---"), equals("one\n---\n---\ntwo"));
      });

      test('doesn\'t add block separator around non-rendered leaf nodes', () {
        expect(doc(p("one"), hr(), hr(), p("two")).textBetween(0, 12, blockSeparator: "\n"), equals("one\ntwo"));
      });
    });

    group('textContent', () {
      test('works on a whole doc', () {
        expect(doc(p("foo")).textContent, equals("foo"));
      });

      test('works on a text node', () {
        expect(schema.text("foo").textContent, equals("foo"));
      });

      test('works on a nested element', () {
        expect(doc(ul(li(p("hi")), li(p(em("a"), "b")))).textContent, equals("hiab"));
      });
    });
  });
}
