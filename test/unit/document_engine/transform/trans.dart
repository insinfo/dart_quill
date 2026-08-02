import 'package:test/test.dart';
import 'package:dart_quill/src/document_engine/model/index.dart';
import 'package:dart_quill/src/document_engine/transform/index.dart';
import 'package:dart_quill/src/document_engine/test_builder/index.dart';

Transform invert(Transform transform) {
  Transform out = Transform(transform.doc);
  for (int i = transform.steps.length - 1; i >= 0; i--) {
    out.step(transform.steps[i].invert(transform.docs[i]));
  }
  return out;
}

void testMapping(Mapping mapping, int pos, int newPos) {
  int mapped = mapping.map(pos, 1);
  expect(mapped, equals(newPos));

  Mapping remap = Mapping(mapping.maps.map((m) => m.invert()).toList());
  for (int i = mapping.maps.length - 1, mapFrom = mapping.maps.length; i >= 0; i--) {
    remap.appendMap(mapping.maps[i], --mapFrom);
  }
  expect(remap.map(pos, 1), equals(pos));
}

void testStepJSON(Transform tr) {
  Transform newTR = Transform(tr.before);
  for (var step in tr.steps) {
    newTR.step(Step.fromJSON(tr.doc.type.schema, step.toJSON()));
  }
  expect(tr.doc.toJSON(), equals(newTR.doc.toJSON())); // Compare JSON representations for deep equality
}

void testTransform(Transform tr, PMNode expectNode) {
  expect(tr.doc.toJSON(), equals(expectNode.toJSON()));
  expect(tr.doc.eq(expectNode), isTrue);
  
  expect(invert(tr).doc.toJSON(), equals(tr.before.toJSON()));
  expect(invert(tr).doc.eq(tr.before), isTrue);

  testStepJSON(tr);

  for (String tag in expectNode.tag.keys) {
    if (tr.before.tag.containsKey(tag)) {
      testMapping(tr.mapping, tr.before.tag[tag]!, expectNode.tag[tag]!);
    }
  }
}
