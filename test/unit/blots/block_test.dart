import 'package:dart_quill/src/blots/block.dart';
import 'package:dart_quill/src/platform/dom.dart';
import 'package:dart_quill/src/platform/platform.dart';
import 'package:test/test.dart';

class TestBlock extends Block {
  TestBlock(DomElement domNode) : super(domNode);
  
  @override
  int length() => domNode.textContent?.length ?? 0;
  
  @override
  void optimize([List<DomMutationRecord>? mutations, Map<String, dynamic>? context]) {}

  @override
  void insertAt(int index, String value, [dynamic def]) {
    // Cast to DomElement to access text property
    if (domNode is DomElement) {
      final element = domNode as DomElement;
      final current = element.text ?? '';
      final safeIndex = index.clamp(0, current.length);
      element.text = current.replaceRange(safeIndex, safeIndex, value);
    }
  }

  @override
  String value() => domNode.textContent ?? '';
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
