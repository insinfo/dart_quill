import 'package:dart_quill/src/modules/image_resize.dart';
import 'package:dart_quill/src/platform/dom.dart';
import 'package:test/test.dart';

import '../../support/quill_test_helpers.dart';

dynamic _imageFixture() {
  final quill = createTestQuill(initialHtml: '<p><br></p>');
  quill.insertEmbed(0, 'image', 'https://example.com/a.png');
  return quill;
}

void main() {
  setUpAll(ensureQuillTestInitialized);

  group('ImageResize', () {
    test('selects an image and exposes eight resize handles', () {
      final quill = _imageFixture();
      final module = quill.getModule('imageResize') as ImageResize;
      final images = quill.root.querySelectorAll('img');
      expect(images, isNotEmpty, reason: quill.root.innerHTML);
      final image = images.first;

      module.select(image);

      expect(module.selectedImage, same(image));
      final handles = quill.container
          .querySelectorAll('span')
          .where((DomElement element) =>
              element.classes.contains('ql-image-resize-handle'))
          .toList();
      expect(handles, hasLength(8));
    });

    test('persists dimensions and paragraph anchor on the image embed', () {
      final quill = _imageFixture();
      final module = quill.getModule('imageResize') as ImageResize;
      final images = quill.root.querySelectorAll('img');
      expect(images, isNotEmpty, reason: quill.root.innerHTML);
      final image = images.first;
      module.select(image);

      module.resizeTo(320, 180);
      module.applyWrap(ImageWrap.right);

      expect(image.getAttribute('width'), '320');
      expect(image.getAttribute('height'), '180');
      expect(image.getAttribute('data-image-wrap'), 'right');
      expect(image.getAttribute('data-anchor'), 'paragraph');
    });

    test('enforces the configured minimum size', () {
      final quill = createTestQuill(initialHtml: '<p><br></p>', modules: {
        'imageResize': const ImageResizeOptions(minimumSize: 40),
      });
      quill.insertEmbed(0, 'image', 'https://example.com/a.png');
      final module = quill.getModule('imageResize') as ImageResize;
      final images = quill.root.querySelectorAll('img');
      expect(images, isNotEmpty, reason: quill.root.innerHTML);
      final image = images.first;
      module.select(image);

      module.resizeTo(1, 2);

      expect(image.getAttribute('width'), '40');
      expect(image.getAttribute('height'), '40');
    });
  });
}
