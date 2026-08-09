import 'package:test/test.dart';
import 'package:dart_quill/src/document_engine/transform/index.dart';

void testMapping(Mapping mapping, List<List<dynamic>> cases) {
  Mapping inverted = mapping.invert();
  for (int i = 0; i < cases.length; i++) {
    int from = cases[i][0];
    int to = cases[i][1];
    int bias = cases[i].length > 2 ? cases[i][2] : 1;
    bool lossy = cases[i].length > 3 ? cases[i][3] : false;

    expect(mapping.map(from, bias), equals(to));
    if (!lossy) expect(inverted.map(to, bias), equals(from));
  }
}

void testDel(Mapping mapping, int pos, int side, String flags) {
  MapResult r = mapping.mapResult(pos, side);
  String found = "";
  if (r.deleted) found += "d";
  if (r.deletedBefore) found += "b";
  if (r.deletedAfter) found += "a";
  if (r.deletedAcross) found += "x";
  expect(found, equals(flags));
}

Mapping mk(List<dynamic> args) {
  Mapping mapping = Mapping();
  for (var arg in args) {
    if (arg is List) {
      mapping.appendMap(StepMap(arg.cast<int>()));
    } else if (arg is Map) {
      arg.forEach((from, to) {
        mapping.setMirror(from as int, to as int);
      });
    }
  }
  return mapping;
}

void main() {
  group('Mapping', () {
    test('can map through a single insertion', () {
      testMapping(
          mk([
            [2, 0, 4]
          ]),
          [
            [0, 0],
            [2, 6],
            [2, 2, -1],
            [3, 7]
          ]);
    });

    test('can map through a single deletion', () {
      testMapping(
          mk([
            [2, 4, 0]
          ]),
          [
            [0, 0],
            [2, 2, -1],
            [3, 2, 1, true],
            [6, 2, 1],
            [6, 2, -1, true],
            [7, 3]
          ]);
    });

    test('can map through a single replace', () {
      testMapping(
          mk([
            [2, 4, 4]
          ]),
          [
            [0, 0],
            [2, 2, 1],
            [4, 6, 1, true],
            [4, 2, -1, true],
            [6, 6, -1],
            [8, 8]
          ]);
    });

    test('can map through a mirrorred delete-insert', () {
      testMapping(
          mk([
            [2, 4, 0],
            [2, 0, 4],
            {0: 1}
          ]),
          [
            [0, 0],
            [2, 2],
            [4, 4],
            [6, 6],
            [7, 7]
          ]);
    });

    test('cap map through a mirrorred insert-delete', () {
      testMapping(
          mk([
            [2, 0, 4],
            [2, 4, 0],
            {0: 1}
          ]),
          [
            [0, 0],
            [2, 2],
            [3, 3]
          ]);
    });

    test('can map through an delete-insert with an insert in between', () {
      testMapping(
          mk([
            [2, 4, 0],
            [1, 0, 1],
            [3, 0, 4],
            {0: 2}
          ]),
          [
            [0, 0],
            [1, 2],
            [4, 5],
            [6, 7],
            [7, 8]
          ]);
    });

    test('assigns the correct deleted flags when deletions happen before', () {
      testDel(
          mk([
            [0, 2, 0]
          ]),
          2,
          -1,
          "db");
      testDel(
          mk([
            [0, 2, 0]
          ]),
          2,
          1,
          "b");
      testDel(
          mk([
            [0, 2, 2]
          ]),
          2,
          -1,
          "db");
      testDel(
          mk([
            [0, 1, 0],
            [0, 1, 0]
          ]),
          2,
          -1,
          "db");
      testDel(
          mk([
            [0, 1, 0]
          ]),
          2,
          -1,
          "");
    });

    test('assigns the correct deleted flags when deletions happen after', () {
      testDel(
          mk([
            [2, 2, 0]
          ]),
          2,
          -1,
          "a");
      testDel(
          mk([
            [2, 2, 0]
          ]),
          2,
          1,
          "da");
      testDel(
          mk([
            [2, 2, 2]
          ]),
          2,
          1,
          "da");
      testDel(
          mk([
            [2, 1, 0],
            [2, 1, 0]
          ]),
          2,
          1,
          "da");
      testDel(
          mk([
            [3, 2, 0]
          ]),
          2,
          -1,
          "");
    });

    test('assigns the correct deleted flags when deletions happen across', () {
      testDel(
          mk([
            [0, 4, 0]
          ]),
          2,
          -1,
          "dbax");
      testDel(
          mk([
            [0, 4, 0]
          ]),
          2,
          1,
          "dbax");
      testDel(
          mk([
            [0, 4, 0]
          ]),
          2,
          1,
          "dbax");
      testDel(
          mk([
            [0, 1, 0],
            [4, 1, 0],
            [0, 3, 0]
          ]),
          2,
          1,
          "dbax");
    });

    test('assigns the correct deleted flags when deletions happen around', () {
      testDel(
          mk([
            [4, 1, 0],
            [0, 1, 0]
          ]),
          2,
          -1,
          "");
      testDel(
          mk([
            [2, 1, 0],
            [0, 2, 0]
          ]),
          2,
          -1,
          "dba");
      testDel(
          mk([
            [2, 1, 0],
            [0, 1, 0]
          ]),
          2,
          -1,
          "a");
      testDel(
          mk([
            [3, 1, 0],
            [0, 2, 0]
          ]),
          2,
          -1,
          "db");
    });
  });
}
