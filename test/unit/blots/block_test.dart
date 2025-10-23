import 'package:dart_quill/src/blots/abstract/blot.dart';
import 'package:dart_quill/src/formats/header.dart';
import 'package:dart_quill/src/formats/bold.dart';
import 'package:test/test.dart';
import '../../support/test_helpers.dart';
import '../../support/fake_dom.dart';

// Helper to create registry entries for format blots
RegistryEntry headerEntry() {
  return RegistryEntry(
    blotName: Header.kBlotName,
    scope: Header.kScope,
    create: ([value]) {
      if (value is FakeDomElement) {
        return Header(value);
      }
      final element = Header.create(value);
      return Header(element);
    },
    tagNames: Header.kTagNames,
  );
}

RegistryEntry boldEntry() {
  return RegistryEntry(
    blotName: Bold.kBlotName,
    scope: Bold.kScope,
    create: ([value]) {
      final element = value is FakeDomElement
          ? value
          : testAdapter.document.createElement(Bold.kTagNames.first);
      return Bold(element);
    },
    tagNames: Bold.kTagNames,
  );
}

void main() {
  // Initialize FakeDom before running tests
  setUpAll(() {
    initializeFakeDom();
  });

  // Clean up between tests
  setUp(() {
    // Clear the body of the test adapter's document
    final body = testAdapter.document.body;
    while (body.firstChild != null) {
      body.firstChild!.remove();
    }
  });

  final formats = [headerEntry(), boldEntry()];

  group('Block', () {
    test('childless', () {
      final scroll = createScroll('', registry: createRegistry(formats));
      final block = scroll.create('block');
      block.optimize();
      expectHTML(block.domNode as FakeDomElement, '<br>');
    });

    test('insert into empty', () {
      final scroll = createScroll('', registry: createRegistry(formats));
      final block = scroll.create('block');
      block.insertAt(0, 'Test');
      expectHTML(block.domNode as FakeDomElement, 'Test');
    });

    test('insert newlines', () {
      final scroll =
          createScroll('<p><br></p>', registry: createRegistry(formats));
      scroll.insertAt(0, '\n\n\n');
      expectHTML(
        scroll.domNode as FakeDomElement,
        '<p><br></p><p><br></p><p><br></p><p><br></p>',
      );
    });

    test('insert multiline', () {
      final scroll = createScroll('<p>Hello World!</p>',
          registry: createRegistry(formats));
      scroll.insertAt(6, 'pardon\nthis\n\ninterruption\n');
      expectHTML(
        scroll.domNode as FakeDomElement,
        '<p>Hello pardon</p>'
        '<p>this</p>'
        '<p><br></p>'
        '<p>interruption</p>'
        '<p>World!</p>',
      );
    });

    test('insert into formatted', () {
      final scroll =
          createScroll('<h1>Welcome</h1>', registry: createRegistry(formats));
      scroll.insertAt(3, 'l\n');

      final firstChild = scroll.domNode.firstChild;
      expect(firstChild, isNotNull);
      if (firstChild is FakeDomElement) {
        expectHTML(firstChild, '<h1>Well</h1>', includeOuterTag: true);
      }

      final secondChild = scroll.domNode.childNodes.length > 1
          ? scroll.domNode.childNodes[1]
          : null;
      expect(secondChild, isNotNull);
      if (secondChild is FakeDomElement) {
        expectHTML(secondChild, '<h1>come</h1>', includeOuterTag: true);
      }
    });

    test('delete line contents', () {
      final scroll = createScroll('<p>Hello</p><p>World!</p>',
          registry: createRegistry(formats));
      scroll.deleteAt(0, 5);
      expectHTML(
        scroll.domNode as FakeDomElement,
        '<p><br></p><p>World!</p>',
      );
    });

    test('join lines', () {
      final scroll = createScroll('<h1>Hello</h1><h2>World!</h2>',
          registry: createRegistry(formats));
      scroll.deleteAt(5, 1);
      expectHTML(scroll.domNode as FakeDomElement, '<h2>HelloWorld!</h2>');
    });

    test('join line with empty', () {
      final scroll = createScroll(
          '<p>Hello<strong>World</strong></p><p><br></p>',
          registry: createRegistry(formats));
      scroll.deleteAt(10, 1);
      expectHTML(
        scroll.domNode as FakeDomElement,
        '<p>Hello<strong>World</strong></p>',
      );
    });

    test('join empty lines', () {
      final scroll = createScroll('<h1><br></h1><p><br></p>',
          registry: createRegistry(formats));
      scroll.deleteAt(1, 1);
      expectHTML(scroll.domNode as FakeDomElement, '<h1><br></h1>');
    });

    test('format empty', () {
      final scroll =
          createScroll('<p><br></p>', registry: createRegistry(formats));
      scroll.formatAt(0, 1, 'header', 1);
      expectHTML(scroll.domNode as FakeDomElement, '<h1><br></h1>');
    });

    test('format newline', () {
      final scroll =
          createScroll('<h1>Hello</h1>', registry: createRegistry(formats));
      scroll.formatAt(5, 1, 'header', 2);
      expectHTML(scroll.domNode as FakeDomElement, '<h2>Hello</h2>');
    });

    test('remove unnecessary break', () {
      final scroll =
          createScroll('<p>Test</p>', registry: createRegistry(formats));

      // Add an extra <br> element
      final children = scroll.children;
      if (children.isNotEmpty) {
        final head = children.first;
        if (head.domNode is FakeDomElement) {
          final element = head.domNode as FakeDomElement;
          final br = FakeDomDocument().createElement('br');
          element.append(br);
        }
      }

      scroll.update();
      expectHTML(scroll.domNode as FakeDomElement, '<p>Test</p>');
    });
  });
}
