import 'package:dart_quill/src/blots/abstract/blot.dart';
import 'package:dart_quill/src/formats/image.dart';
import 'package:dart_quill/src/formats/video.dart';
import 'package:test/test.dart';

import '../../support/fake_dom.dart';
import '../../support/test_helpers.dart';

RegistryEntry videoEntry() {
  return RegistryEntry(
    blotName: Video.kBlotName,
    scope: Scope.BLOCK_BLOT,
    create: ([value]) {
      if (value is FakeDomElement) {
        return Video(value);
      }
      final url = value is String ? value : '#';
      return Video.create(url);
    },
    tagNames: [Video.kTagName],
    classNames: [Video.kClassName],
  );
}

RegistryEntry imageEntry() {
  return RegistryEntry(
    blotName: Image.kBlotName,
    scope: Image.kScope,
    create: ([value]) {
      if (value is FakeDomElement) {
        return Image(value);
      }
      final src = value is String ? value : '';
      return Image(Image.create(src));
    },
    tagNames: [Image.kTagName],
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

  final formats = [videoEntry(), imageEntry()];

  group('Block Embed', () {
    test('insert', () {
      final scroll = createScroll('<p>0123</p>', registry: createRegistry(formats));
      scroll.insertAt(2, 'video', '#');
      expectHTML(
        scroll.domNode as FakeDomElement,
        '<p>01</p><iframe src="#" class="ql-video" frameborder="0" allowfullscreen="true"></iframe><p>23</p>',
      );
    });

    test('split newline', () {
      final scroll = createScroll('<p>0123</p>', registry: createRegistry(formats));
      scroll.insertAt(4, 'video', '#');
      expectHTML(
        scroll.domNode as FakeDomElement,
        '<p>0123</p><iframe src="#" class="ql-video" frameborder="0" allowfullscreen="true"></iframe><p><br></p>',
      );
    });

    test('insert end of document', () {
      final scroll = createScroll('<p>0123</p>', registry: createRegistry(formats));
      scroll.insertAt(5, 'video', '#');
      expectHTML(
        scroll.domNode as FakeDomElement,
        '<p>0123</p><iframe src="#" class="ql-video" frameborder="0" allowfullscreen="true"></iframe>',
      );
    });

    test('insert text before', () {
      final scroll = createScroll(
        '<iframe src="#" class="ql-video" frameborder="0" allowfullscreen="true"></iframe>',
        registry: createRegistry(formats),
      );
      scroll.insertAt(0, 'Test');
      expectHTML(
        scroll.domNode as FakeDomElement,
        '<p>Test</p><iframe src="#" class="ql-video" frameborder="0" allowfullscreen="true"></iframe>',
      );
    });

    test('insert text after', () {
      final scroll = createScroll(
        '<iframe src="#" class="ql-video" frameborder="0" allowfullscreen="true"></iframe>',
        registry: createRegistry(formats),
      );
      scroll.insertAt(1, 'Test');
      expectHTML(
        scroll.domNode as FakeDomElement,
        '<iframe src="#" class="ql-video" frameborder="0" allowfullscreen="true"></iframe><p>Test</p>',
      );
    });

    test('insert inline embed before', () {
      final scroll = createScroll(
        '<iframe src="#" class="ql-video" frameborder="0" allowfullscreen="true"></iframe>',
        registry: createRegistry(formats),
      );
      scroll.insertAt(0, 'image', '/assets/favicon.png');
      expectHTML(
        scroll.domNode as FakeDomElement,
        '<p><img src="/assets/favicon.png"></p><iframe src="#" class="ql-video" frameborder="0" allowfullscreen="true"></iframe>',
      );
    });

    test('insert inline embed after', () {
      final scroll = createScroll(
        '<iframe src="#" class="ql-video" frameborder="0" allowfullscreen="true"></iframe>',
        registry: createRegistry(formats),
      );
      scroll.insertAt(1, 'image', '/assets/favicon.png');
      expectHTML(
        scroll.domNode as FakeDomElement,
        '<iframe src="#" class="ql-video" frameborder="0" allowfullscreen="true"></iframe><p><img src="/assets/favicon.png"></p>',
      );
    });

    test('insert block embed before', () {
      final scroll = createScroll(
        '<iframe src="#" class="ql-video" frameborder="0" allowfullscreen="true"></iframe>',
        registry: createRegistry(formats),
      );
      scroll.insertAt(0, 'video', '#1');
      expectHTML(
        scroll.domNode as FakeDomElement,
        '<iframe src="#1" class="ql-video" frameborder="0" allowfullscreen="true"></iframe><iframe src="#" class="ql-video" frameborder="0" allowfullscreen="true"></iframe>',
      );
    });

    test('insert block embed after', () {
      final scroll = createScroll(
        '<iframe src="#" class="ql-video" frameborder="0" allowfullscreen="true"></iframe>',
        registry: createRegistry(formats),
      );
      scroll.insertAt(1, 'video', '#1');
      expectHTML(
        scroll.domNode as FakeDomElement,
        '<iframe src="#" class="ql-video" frameborder="0" allowfullscreen="true"></iframe><iframe src="#1" class="ql-video" frameborder="0" allowfullscreen="true"></iframe>',
      );
    });

    test('insert newline before', () {
      final scroll = createScroll(
        '<iframe src="#" class="ql-video" frameborder="0" allowfullscreen="true"></iframe>',
        registry: createRegistry(formats),
      );
      scroll.insertAt(0, '\n');
      scroll.optimize();
      expectHTML(
        scroll.domNode as FakeDomElement,
        '<p><br></p><iframe src="#" class="ql-video" frameborder="0" allowfullscreen="true"></iframe>',
      );
    });

    test('insert multiple newlines before', () {
      final scroll = createScroll(
        '<iframe src="#" class="ql-video" frameborder="0" allowfullscreen="true"></iframe>',
        registry: createRegistry(formats),
      );
      scroll.insertAt(0, '\n\n\n');
      scroll.optimize();
      expectHTML(
        scroll.domNode as FakeDomElement,
        '<p><br></p><p><br></p><p><br></p><iframe src="#" class="ql-video" frameborder="0" allowfullscreen="true"></iframe>',
      );
    });

    test('insert newline after', () {
      final scroll = createScroll(
        '<iframe src="#" class="ql-video" frameborder="0" allowfullscreen="true"></iframe>',
        registry: createRegistry(formats),
      );
      scroll.insertAt(1, '\n');
      scroll.optimize();
      expectHTML(
        scroll.domNode as FakeDomElement,
        '<iframe src="#" class="ql-video" frameborder="0" allowfullscreen="true"></iframe><p><br></p>',
      );
    });

    test('delete preceding newline', () {
      final scroll = createScroll(
        '<p>0123</p><iframe src="#" class="ql-video" frameborder="0" allowfullscreen="true"></iframe>',
        registry: createRegistry(formats),
      );
      scroll.deleteAt(4, 1);
      expectHTML(
        scroll.domNode as FakeDomElement,
        '<p>0123</p><iframe src="#" class="ql-video" frameborder="0" allowfullscreen="true"></iframe>',
      );
    });
  });
}
