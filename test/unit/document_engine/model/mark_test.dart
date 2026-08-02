import 'package:test/test.dart';
import 'package:dart_quill/src/document_engine/model/index.dart';
import 'package:dart_quill/src/document_engine/test_builder/index.dart';
import 'package:dart_quill/src/document_engine/test_builder/schema.dart';

void main() {
  final em_ = testSchema.marks['em']!.create();
  final strong = testSchema.marks['strong']!.create();
  Mark link(String href, [String? title]) => testSchema.marks['link']!.create({'href': href, 'title': title});
  final code = testSchema.marks['code']!.create();

  final customSchema = Schema(SchemaSpec(
    nodes: {
      'doc': NodeSpec(content: 'paragraph+'),
      'paragraph': NodeSpec(content: 'text*'),
      'text': NodeSpec()
    },
    marks: {
      'remark': MarkSpec(attrs: {'id': AttributeSpec()}, excludes: "", inclusive: false),
      'user': MarkSpec(attrs: {'id': AttributeSpec()}, excludes: "_"),
      'strong': MarkSpec(excludes: "em-group"),
      'em': MarkSpec(group: "em-group")
    }
  ));
  final custom = customSchema.marks;
  
  final remark1 = custom['remark']!.create({'id': 1});
  final remark2 = custom['remark']!.create({'id': 2});
  final user1 = custom['user']!.create({'id': 1});
  final user2 = custom['user']!.create({'id': 2});
  final customEm = custom['em']!.create();
  final customStrong = custom['strong']!.create();

  group('Mark', () {
    group('sameSet', () {
      test('returns true for two empty sets', () => expect(Mark.sameSet([], []), isTrue));

      test('returns true for simple identical sets', () =>
         expect(Mark.sameSet([em_, strong], [em_, strong]), isTrue));

      test('returns false for different sets', () =>
         expect(Mark.sameSet([em_, strong], [em_, code]), isFalse));

      test('returns false when set size differs', () =>
         expect(Mark.sameSet([em_, strong], [em_, strong, code]), isFalse));

      test('recognizes identical links in set', () =>
         expect(Mark.sameSet([link("http://foo"), code], [link("http://foo"), code]), isTrue));

      test('recognizes different links in set', () =>
         expect(Mark.sameSet([link("http://foo"), code], [link("http://bar"), code]), isFalse));
    });

    group('eq', () {
      test('considers identical links to be the same', () =>
         expect(link("http://foo").eq(link("http://foo")), isTrue));

      test('considers different links to differ', () =>
         expect(link("http://foo").eq(link("http://bar")), isFalse));

      test('considers links with different titles to differ', () =>
         expect(link("http://foo", "A").eq(link("http://foo", "B")), isFalse));
    });

    group('addToSet', () {
      test('can add to the empty set', () =>
         expect(Mark.sameSet(em_.addToSet([]), [em_]), isTrue));

      test('is a no-op when the added thing is in set', () =>
         expect(Mark.sameSet(em_.addToSet([em_]), [em_]), isTrue));

      test('adds marks with lower rank before others', () =>
         expect(Mark.sameSet(em_.addToSet([strong]), [em_, strong]), isTrue));

      test('adds marks with higher rank after others', () =>
         expect(Mark.sameSet(strong.addToSet([em_]), [em_, strong]), isTrue));

      test('replaces different marks with new attributes', () =>
         expect(Mark.sameSet(link("http://bar").addToSet([link("http://foo"), em_]),
             [link("http://bar"), em_]), isTrue));

      test('does nothing when adding an existing link', () =>
         expect(Mark.sameSet(link("http://foo").addToSet([em_, link("http://foo")]),
             [em_, link("http://foo")]), isTrue));

      test('puts code marks at the end', () =>
         expect(Mark.sameSet(code.addToSet([em_, strong, link("http://foo")]),
             [em_, strong, link("http://foo"), code]), isTrue));

      test('puts marks with middle rank in the middle', () =>
         expect(Mark.sameSet(strong.addToSet([em_, code]), [em_, strong, code]), isTrue));

      test('allows nonexclusive instances of marks with the same type', () =>
         expect(Mark.sameSet(remark2.addToSet([remark1]), [remark1, remark2]), isTrue));

      test('doesn\'t duplicate identical instances of nonexclusive marks', () =>
         expect(Mark.sameSet(remark1.addToSet([remark1]), [remark1]), isTrue));

      test('clears all others when adding a globally-excluding mark', () =>
         expect(Mark.sameSet(user1.addToSet([remark1, customEm]), [user1]), isTrue));

      test('does not allow adding another mark to a globally-excluding mark', () =>
         expect(Mark.sameSet(customEm.addToSet([user1]), [user1]), isTrue));

      test('does overwrite a globally-excluding mark when adding another instance', () =>
         expect(Mark.sameSet(user2.addToSet([user1]), [user2]), isTrue));

      test('doesn\'t add anything when another mark excludes the added mark', () =>
         expect(Mark.sameSet(customEm.addToSet([remark1, customStrong]), [remark1, customStrong]), isTrue));

      test('remove excluded marks when adding a mark', () =>
         expect(Mark.sameSet(customStrong.addToSet([remark1, customEm]), [remark1, customStrong]), isTrue));
    });

    group('removeFromSet', () {
      test('is a no-op for the empty set', () =>
         expect(Mark.sameSet(em_.removeFromSet([]), []), isTrue));

      test('can remove the last mark from a set', () =>
         expect(Mark.sameSet(em_.removeFromSet([em_]), []), isTrue));

      test('is a no-op when the mark isn\'t in the set', () =>
         expect(Mark.sameSet(strong.removeFromSet([em_]), [em_]), isTrue));

      test('can remove a mark with attributes', () =>
         expect(Mark.sameSet(link("http://foo").removeFromSet([link("http://foo")]), []), isTrue));

      test('doesn\'t remove a mark when its attrs differ', () =>
         expect(Mark.sameSet(link("http://foo", "title").removeFromSet([link("http://foo")]),
                             [link("http://foo")]), isTrue));
    });

    group('ResolvedPos.marks', () {
      void isAt(PMNode docNode, Mark mark, bool result) {
        expect(mark.isInSet(docNode.resolve(docNode.tag['a']!).marks()), equals(result));
      }

      test('recognizes a mark exists inside marked text', () =>
         isAt(doc(p(em("fo<a>o"))), em_, true));

      test('recognizes a mark doesn\'t exist in non-marked text', () =>
         isAt(doc(p(em("fo<a>o"))), strong, false));

      test('considers a mark active after the mark', () =>
         isAt(doc(p(em("hi"), "<a> there")), em_, true));

      test('considers a mark inactive before the mark', () =>
         isAt(doc(p("one <a>", em("two"))), em_, false));

      test('considers a mark active at the start of the textblock', () =>
         isAt(doc(p(em("<a>one"))), em_, true));

      test('notices that attributes differ', () =>
         isAt(doc(p(a({'href': 'foo'}, "li<a>nk"))), link("http://baz"), false));

      final customDoc = customSchema.node("doc", null, [
        customSchema.node("paragraph", null, [ // pos 1
          customSchema.text("one", [remark1, customStrong]), customSchema.text("two")
        ]),
        customSchema.node("paragraph", null, [ // pos 9
          customSchema.text("one"), customSchema.text("two", [remark1]), customSchema.text("three", [remark1])
        ]), // pos 22
        customSchema.node("paragraph", null, [
          customSchema.text("one", [remark2]), customSchema.text("two", [remark1])
        ])
      ]);

      test('omits non-inclusive marks at end of mark', () =>
         expect(Mark.sameSet(customDoc.resolve(4).marks(), [customStrong]), isTrue));

      test('includes non-inclusive marks inside a text node', () =>
         expect(Mark.sameSet(customDoc.resolve(3).marks(), [remark1, customStrong]), isTrue));

      test('omits non-inclusive marks at the end of a line', () =>
         expect(Mark.sameSet(customDoc.resolve(20).marks(), []), isTrue));

      test('includes non-inclusive marks between two marked nodes', () =>
         expect(Mark.sameSet(customDoc.resolve(15).marks(), [remark1]), isTrue));

      test('excludes non-inclusive marks at a point where mark attrs change', () =>
         expect(Mark.sameSet(customDoc.resolve(25).marks(), []), isTrue));
    });
  });
}
