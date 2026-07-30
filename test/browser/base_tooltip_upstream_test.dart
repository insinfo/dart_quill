@TestOn('browser')
library base_tooltip_upstream_test;

/// Browser port of
/// `referencias/quilljs/test/unit/theme/base/tooltip.spec.ts`.
import 'package:dart_quill/src/core/initialization.dart';
import 'package:dart_quill/src/core/quill.dart';
import 'package:dart_quill/src/platform/html_dom.dart';
import 'package:dart_quill/src/themes/base.dart';
import 'package:test/test.dart';
import 'package:web/web.dart' as web;

({web.HTMLElement container, BaseTooltip tooltip}) _setup() {
  final container = web.document.createElement('div') as web.HTMLElement;
  web.document.body!.appendChild(container);
  addTearDown(() => container.remove());
  final quill = Quill(HtmlDomElement(container));
  final tooltip = BaseTooltip(quill, '<input type="text">');
  return (container: container, tooltip: tooltip);
}

void _insertVideo(BaseTooltip tooltip, String url) {
  tooltip.textbox!.value = url;
  tooltip.root.setAttribute('data-mode', 'video');
  tooltip.save();
}

void main() {
  setUpAll(initializeQuill);

  group('BaseTooltip.save', () {
    for (final testCase in <(String, String, String)>[
      (
        'converts youtube video url to embedded',
        'http://youtube.com/watch?v=QHH3iSeDBLo',
        'http://www.youtube.com/embed/QHH3iSeDBLo',
      ),
      (
        'converts www.youtube video url to embedded',
        'http://www.youtube.com/watch?v=QHH3iSeDBLo',
        'http://www.youtube.com/embed/QHH3iSeDBLo',
      ),
      (
        'converts m.youtube video url to embedded',
        'http://m.youtube.com/watch?v=QHH3iSeDBLo',
        'http://www.youtube.com/embed/QHH3iSeDBLo',
      ),
      (
        'preserves youtube video url protocol',
        'https://m.youtube.com/watch?v=QHH3iSeDBLo',
        'https://www.youtube.com/embed/QHH3iSeDBLo',
      ),
      (
        'uses https as default youtube video url protocol',
        'youtube.com/watch?v=QHH3iSeDBLo',
        'https://www.youtube.com/embed/QHH3iSeDBLo',
      ),
      (
        'converts vimeo video url to embedded',
        'http://vimeo.com/47762693',
        'http://player.vimeo.com/video/47762693/',
      ),
      (
        'converts www.vimeo video url to embedded',
        'http://www.vimeo.com/47762693',
        'http://player.vimeo.com/video/47762693/',
      ),
      (
        'preserves vimeo video url protocol',
        'https://www.vimeo.com/47762693',
        'https://player.vimeo.com/video/47762693/',
      ),
      (
        'uses https as default vimeo video url protocol',
        'vimeo.com/47762693',
        'https://player.vimeo.com/video/47762693/',
      ),
    ]) {
      test(testCase.$1, () {
        final fixture = _setup();
        _insertVideo(fixture.tooltip, testCase.$2);
        final video = fixture.container.querySelector('.ql-video');
        expect(video, isNotNull);
        expect(video!.getAttribute('src'), contains(testCase.$3));
      });
    }
  });
}
