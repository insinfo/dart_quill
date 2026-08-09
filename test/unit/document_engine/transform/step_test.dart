import 'package:test/test.dart';
import 'package:dart_quill/src/document_engine/model/index.dart';
import 'package:dart_quill/src/document_engine/transform/index.dart';
import 'package:dart_quill/src/document_engine/test_builder/index.dart';
import 'package:dart_quill/src/document_engine/test_builder/schema.dart';

final testDoc = doc(p("foobar"));

Step mkStep(int from, int to, String? val) {
  if (val == "+em") {
    return AddMarkStep(from, to, testSchema.marks['em']!.create());
  } else if (val == "-em") {
    return RemoveMarkStep(from, to, testSchema.marks['em']!.create());
  } else {
    return ReplaceStep(
        from,
        to,
        val == null
            ? Slice.empty
            : Slice(Fragment.from(testSchema.text(val)), 0, 0));
  }
}

void main() {
  group('Step', () {
    group('merge', () {
      void Function() yes(
          int from1, int to1, String? val1, int from2, int to2, String? val2) {
        return () {
          Step step1 = mkStep(from1, to1, val1);
          Step step2 = mkStep(from2, to2, val2);
          Step? merged = step1.merge(step2);
          expect(merged, isNotNull);

          StepResult resultMerged = merged!.apply(testDoc);
          StepResult resultStep1 = step1.apply(testDoc);
          StepResult resultStep2 = step2.apply(resultStep1.doc!);

          expect(resultMerged.doc!.toJSON(), equals(resultStep2.doc!.toJSON()));
          expect(resultMerged.doc!.eq(resultStep2.doc!), isTrue);
        };
      }

      void Function() no(
          int from1, int to1, String? val1, int from2, int to2, String? val2) {
        return () {
          Step step1 = mkStep(from1, to1, val1);
          Step step2 = mkStep(from2, to2, val2);
          expect(step1.merge(step2), isNull);
        };
      }

      test('merges typing changes', yes(2, 2, "a", 3, 3, "b"));
      test('merges inverse typing', yes(2, 2, "a", 2, 2, "b"));
      test('doesn\'t merge separated typing', no(2, 2, "a", 4, 4, "b"));
      test(
          'doesn\'t merge inverted separated typing', no(3, 3, "a", 2, 2, "b"));
      test('merges adjacent backspaces', yes(3, 4, null, 2, 3, null));
      test('merges adjacent deletes', yes(2, 3, null, 2, 3, null));
      test('doesn\'t merge separate backspaces', no(1, 2, null, 2, 3, null));
      test('merges backspace and type', yes(2, 3, null, 2, 2, "x"));
      test('merges longer adjacent inserts', yes(2, 2, "quux", 6, 6, "baz"));
      test('merges inverted longer inserts', yes(2, 2, "quux", 2, 2, "baz"));
      test('merges longer deletes', yes(2, 5, null, 2, 4, null));
      test('merges inverted longer deletes', yes(4, 6, null, 2, 4, null));
      test('merges overwrites', yes(3, 4, "x", 4, 5, "y"));
      test('merges adding adjacent styles', yes(1, 2, "+em", 2, 4, "+em"));
      test('merges adding overlapping styles', yes(1, 3, "+em", 2, 4, "+em"));
      test('doesn\'t merge separate styles', no(1, 2, "+em", 3, 4, "+em"));
      test('merges removing adjacent styles', yes(1, 2, "-em", 2, 4, "-em"));
      test('merges removing overlapping styles', yes(1, 3, "-em", 2, 4, "-em"));
      test('doesn\'t merge removing separate styles',
          no(1, 2, "-em", 3, 4, "-em"));
    });
  });
}
