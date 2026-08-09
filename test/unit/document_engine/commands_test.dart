import 'package:test/test.dart';
import 'package:dart_quill/src/document_engine/state/index.dart';
import 'package:dart_quill/src/document_engine/commands/index.dart';
import 'package:dart_quill/src/document_engine/test_builder/index.dart';

void main() {
  group('Commands', () {
    test('splitBlock should split a paragraph', () {
      final docNode = doc(p("a<a>b"));
      final pos = docNode.tag['a']!;
      expect(pos, equals(2));

      // Create editor state
      var state = EditorState.create(EditorStateConfig(
        schema: schema,
        doc: docNode,
        selection: TextSelection.create(docNode, pos),
      ));

      // Run splitBlock
      bool dispatched = false;
      final success = splitBlock(state, (tr) {
        state = state.apply(tr);
        dispatched = true;
      });

      expect(success, isTrue);
      expect(dispatched, isTrue);

      // The expected document structure should have two paragraphs: p("a"), p("b")
      final expected = doc(p("a"), p("b"));
      expect(state.doc.eq(expected), isTrue);
    });

    test('toggleMark should add/remove bold mark', () {
      final docNode = doc(p("<a>hello<b>"));
      final from = docNode.tag['a']!;
      final to = docNode.tag['b']!;

      var state = EditorState.create(EditorStateConfig(
        schema: schema,
        doc: docNode,
        selection: TextSelection.create(docNode, from, to),
      ));

      final boldType = schema.marks['strong']!;

      // Add mark
      bool success = toggleMark(boldType)(state, (tr) {
        state = state.apply(tr);
      });

      expect(success, isTrue);
      expect(state.doc.eq(doc(p(strong("hello")))), isTrue);

      // Toggle off
      success = toggleMark(boldType)(state, (tr) {
        state = state.apply(tr);
      });

      expect(success, isTrue);
      expect(state.doc.eq(doc(p("hello"))), isTrue);
    });
  });
}
