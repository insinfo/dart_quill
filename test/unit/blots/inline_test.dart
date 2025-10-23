import 'package:dart_quill/src/blots/abstract/blot.dart';
import 'package:dart_quill/src/formats/bold.dart';
import 'package:dart_quill/src/formats/italic.dart';
import 'package:test/test.dart';

import '../../support/fake_dom.dart';
import '../../support/test_helpers.dart';

RegistryEntry boldEntry() {
  return RegistryEntry(
    blotName: Bold.kBlotName,
    scope: Bold.kScope,
    create: ([value]) {
      if (value is FakeDomElement) {
        return Bold(value);
      }
      return Bold.create();
    },
    tagNames: Bold.kTagNames,
  );
}

RegistryEntry italicEntry() {
  return RegistryEntry(
    blotName: Italic.kBlotName,
    scope: Italic.kScope,
    create: ([value]) {
      if (value is FakeDomElement) {
        return Italic(value);
      }
      return Italic.create();
    },
    tagNames: Italic.kTagNames,
  );
}

void main() {
  setUpAll(initializeFakeDom);

  setUp(() {
    final body = testAdapter.document.body;
    while (body.firstChild != null) {
      body.firstChild!.remove();
    }
  });

  final formats = [boldEntry(), italicEntry()];

  group('Inline', () {
    test('format order', () {
      final scroll = createScroll(
        '<p>Hello World!</p>',
        registry: createRegistry(formats),
      );
      scroll.formatAt(0, 1, 'bold', true);
      scroll.formatAt(0, 1, 'italic', true);
      scroll.formatAt(2, 1, 'italic', true);
      scroll.formatAt(2, 1, 'bold', true);
      expectHTML(
        scroll.domNode as FakeDomElement,
        '<p><strong><em>H</em></strong>e<strong><em>l</em></strong>lo World!</p>',
      );
    });

    test('reorder', () {
      final scroll = createScroll(
        '<p>0<strong>12</strong>3</p>',
        registry: createRegistry(formats),
      );
      final root = scroll.domNode as FakeDomElement;
      final block = scroll.children.first as ParentBlot;
      final italic = scroll.create('italic') as ParentBlot;
      final existing = List<Blot>.from(block.children);
      for (final child in existing) {
        italic.appendChild(child);
      }
      block.appendChild(italic);
      expectHTML(root, '<p><em>0<strong>12</strong>3</em></p>');
      scroll.optimize();
      expectHTML(
        root,
        '<p><em>0</em><strong><em>12</em></strong><em>3</em></p>',
      );
    });
  });
}
