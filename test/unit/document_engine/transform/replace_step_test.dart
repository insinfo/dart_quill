import 'package:test/test.dart';
import 'package:dart_quill/src/document_engine/model/index.dart';
import 'package:dart_quill/src/document_engine/transform/index.dart';
import 'package:dart_quill/src/document_engine/test_builder/index.dart';
import 'package:dart_quill/src/document_engine/test_builder/schema.dart';

void main() {
  group('ReplaceAroundStep.map', () {
    void testMap(PMNode docNode, void Function(Transform tr) change, void Function(Transform tr) otherChange, PMNode expected) {
      Transform trA = Transform(docNode);
      Transform trB = Transform(docNode);
      change(trA);
      otherChange(trB);
      
      Step? mappedStep = trA.steps[0].map(trB.mapping);
      expect(mappedStep, isNotNull);
      
      Transform resultTr = Transform(trB.doc).step(mappedStep!);
      expect(resultTr.doc.toJSON(), equals(expected.toJSON()));
      expect(resultTr.doc.eq(expected), isTrue);
    }

    test('doesn\'t break wrap steps on insertions', () {
      testMap(
        doc(p("a")),
        (tr) => tr.wrap(tr.doc.resolve(1).blockRange()!, [Wrapping(testSchema.nodes['blockquote']!)]),
        (tr) => tr.insert(0, p("b")),
        doc(p("b"), blockquote(p("a")))
      );
    });

    test('doesn\'t overwrite content inserted at start of unwrap step', () {
      testMap(
        doc(blockquote(p("a"))),
        (tr) => tr.lift(tr.doc.resolve(2).blockRange()!, 0),
        (tr) => tr.insert(2, testSchema.text("x")),
        doc(p("xa"))
      );
    });
  });
}
