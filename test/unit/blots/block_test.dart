import 'package:dart_quill/src/blots/block.dart';
import 'package:dart_quill/src/platform/dom.dart';
import 'package:dart_quill/src/platform/platform.dart';
import 'package:test/test.dart';

class TestBlock extends Block {
  TestBlock(DomElement domNode) : super(domNode);
  @override
  int length() => domNode.text?.length ?? 0;
  @override
  void optimize([List<DomMutationRecord>? mutations, Map<String, dynamic>? context]) {}

  @override
  void insertAt(int index, String value, [dynamic def]) {
    final current = domNode.text ?? '';
    final safeIndex = index.clamp(0, current.length);
    domNode.text = current.replaceRange(safeIndex, safeIndex, value);
  }

  @override
  String value() => domNode.text ?? '';
}

void main() {
  group('Block', () {
    test('childless', () {
      final domNode = domBindings.adapter.document.createElement('div');
      final block = TestBlock(domNode);
      block.optimize();
      expect(block.length(), equals(0));
    });

    test('insert into empty', () {
      final domNode = domBindings.adapter.document.createElement('div');
      final block = TestBlock(domNode);
      block.insertAt(0, 'Test');
      expect(block.length(), greaterThan(0));
    });

    // Adicione mais testes conforme a tradução dos métodos
  });
}
