import 'package:test/test.dart';
import 'package:dart_quill/src/document_engine/model/index.dart';
import 'package:dart_quill/src/document_engine/test_builder/index.dart';

void main() {
  final testDoc = doc(p("ab"), blockquote(p(em("cd"), "ef")));
  final _doc = {'node': testDoc, 'start': 0, 'end': 12};
  final _p1 = {'node': testDoc.child(0), 'start': 1, 'end': 3};
  final _blk = {'node': testDoc.child(1), 'start': 5, 'end': 11};
  final _p2 = {
    'node': (_blk['node'] as PMNode).child(0),
    'start': 6,
    'end': 10
  };

  group('Node', () {
    group('resolve', () {
      test('should reflect the document structure', () {
        Map<int, List<dynamic>> expected = {
          0: [_doc, 0, null, _p1['node']],
          1: [_doc, _p1, 0, null, "ab"],
          2: [_doc, _p1, 1, "a", "b"],
          3: [_doc, _p1, 2, "ab", null],
          4: [_doc, 4, _p1['node'], _blk['node']],
          5: [_doc, _blk, 0, null, _p2['node']],
          6: [_doc, _blk, _p2, 0, null, "cd"],
          7: [_doc, _blk, _p2, 1, "c", "d"],
          8: [_doc, _blk, _p2, 2, "cd", "ef"],
          9: [_doc, _blk, _p2, 3, "e", "f"],
          10: [_doc, _blk, _p2, 4, "ef", null],
          11: [_doc, _blk, 6, _p2['node'], null],
          12: [_doc, 12, _blk['node'], null]
        };

        for (int pos = 0; pos <= testDoc.content.size; pos++) {
          ResolvedPos posRes = testDoc.resolve(pos);
          List<dynamic> exp = expected[pos]!;
          expect(posRes.depth, equals(exp.length - 4));
          for (int i = 0; i < exp.length - 3; i++) {
            PMNode expNode = exp[i] is Map ? exp[i]['node'] : exp[i];
            expect(posRes.node(i).eq(expNode), isTrue);
            int expStart = exp[i] is Map ? exp[i]['start'] : exp[i];
            expect(posRes.start(i), equals(expStart));
            int expEnd = exp[i] is Map ? exp[i]['end'] : exp[i];
            expect(posRes.end(i), equals(expEnd));
            if (i > 0) {
              expect(posRes.before(i), equals(expStart - 1));
              expect(posRes.after(i), equals(expEnd + 1));
            }
          }
          expect(posRes.parentOffset, equals(exp[exp.length - 3]));

          PMNode? before = posRes.nodeBefore;
          dynamic eBefore = exp[exp.length - 2];
          expect(eBefore is String ? before?.textContent : before,
              equals(eBefore));

          PMNode? after = posRes.nodeAfter;
          dynamic eAfter = exp[exp.length - 1];
          expect(eAfter is String ? after?.textContent : after, equals(eAfter));
        }
      });

      test('has a working posAtIndex method', () {
        PMNode d = doc(blockquote(
            p("one"), blockquote(p("two ", em("three")), p("four"))));
        ResolvedPos pThree = d.resolve(12); // Start of em("three")
        expect(pThree.posAtIndex(0), equals(8));
        expect(pThree.posAtIndex(1), equals(12));
        expect(pThree.posAtIndex(2), equals(17));
        expect(pThree.posAtIndex(0, 2), equals(7));
        expect(pThree.posAtIndex(1, 2), equals(18));
        expect(pThree.posAtIndex(2, 2), equals(24));
        expect(pThree.posAtIndex(0, 1), equals(1));
        expect(pThree.posAtIndex(1, 1), equals(6));
        expect(pThree.posAtIndex(2, 1), equals(25));
        expect(pThree.posAtIndex(0, 0), equals(0));
        expect(pThree.posAtIndex(1, 0), equals(26));
      });
    });
  });
}
