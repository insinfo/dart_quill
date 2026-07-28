import 'package:dart_quill/src/blots/scroll.dart';
import 'package:dart_quill/src/core/emitter.dart';
import 'package:dart_quill/src/formats/header.dart';
import 'package:dart_quill/src/formats/link.dart';
import 'package:test/test.dart';

import '../../support/fake_dom.dart';
import '../../support/quill_test_helpers.dart';
import '../../support/test_helpers.dart';

/// Regression tests for registry node reuse during hydration (G1.6):
/// Scroll.build passes the pre-existing DOM node to create(), and the
/// produced blot must adopt it instead of minting a fresh element (an H3
/// used to hydrate as H1 and links lost their href).
void main() {
  setUpAll(ensureQuillTestInitialized);

  Scroll hydrate(String html) {
    final quill = createTestQuill();
    final registry = quill.scroll.registry;
    final root = testAdapter.document.createElement('div');
    (root as FakeDomElement).innerHTML = normalizeHTML(html);
    return Scroll(registry, root, emitter: Emitter());
  }

  test('header keeps its level when hydrated from existing DOM', () {
    final scroll = hydrate('<h3>title</h3>');
    final header = scroll.descendants<Header>().single;
    expect(header.element.tagName, 'H3');
    expect(header.formats()[Header.kBlotName], 3);
  });

  test('link keeps its href when hydrated from existing DOM', () {
    final scroll = hydrate('<p><a href="https://quilljs.com">q</a></p>');
    final link = scroll.descendants<Link>().single;
    expect(link.element.getAttribute('href'), 'https://quilljs.com');
  });
}
