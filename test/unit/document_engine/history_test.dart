import 'package:test/test.dart';
import 'package:dart_quill/src/document_engine/state/index.dart';
import 'package:dart_quill/src/document_engine/history/history.dart';
import 'package:dart_quill/src/document_engine/test_builder/index.dart';

void main() {
  group('History', () {
    test('undo and redo basic typing', () {
      final docNode = doc(p("<a>"));
      final pos = docNode.tag['a']!;

      var state = EditorState.create(EditorStateConfig(
        schema: schema,
        doc: docNode,
        selection: TextSelection.create(docNode, pos),
        plugins: [history()],
      ));

      // 1. Type "x"
      var tr = state.tr;
      tr.insertText("x", pos);
      state = state.apply(tr);
      expect(state.doc.eq(doc(p("x"))), isTrue);
      expect(undoDepth(state), equals(1));

      // 2. Undo
      bool success = undo(state, (undoTr) {
        state = state.apply(undoTr);
      });
      expect(success, isTrue);
      expect(state.doc.eq(doc(p())), isTrue);
      expect(undoDepth(state), equals(0));
      expect(redoDepth(state), equals(1));

      // 3. Redo
      success = redo(state, (redoTr) {
        state = state.apply(redoTr);
      });
      expect(success, isTrue);
      expect(state.doc.eq(doc(p("x"))), isTrue);
      expect(undoDepth(state), equals(1));
      expect(redoDepth(state), equals(0));
    });
  });
}
