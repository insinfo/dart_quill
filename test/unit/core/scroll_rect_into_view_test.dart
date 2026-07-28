import 'package:dart_quill/src/core/utils/scroll_rect_into_view.dart';
import 'package:test/test.dart';

import '../../support/fake_dom.dart';
import '../../support/quill_test_helpers.dart';
import '../../support/test_helpers.dart';

void main() {
  setUpAll(initializeFakeDom);

  FakeDomElement nestedRoot({double parentHeight = 50}) {
    final document = testAdapter.document;
    final parent = document.createElement('div') as FakeDomElement
      ..setAttribute('height', '$parentHeight');
    final root = document.createElement('div') as FakeDomElement
      ..setAttribute('height', '100');
    document.body.append(parent);
    parent.append(root);
    addTearDown(parent.remove);
    return root;
  }

  test('scrolls the nearest overflowing ancestor and adjusts the target', () {
    final root = nestedRoot();
    final parent = root.parentNode! as FakeDomElement;

    scrollRectIntoView(
      root,
      const Rect(top: 80, right: 10, bottom: 90, left: 0),
    );

    expect(root.scrollTop, 0);
    expect(parent.scrollTop, 40);
  });

  test('honours scroll padding', () {
    final root = nestedRoot(parentHeight: 100);
    root.style.setProperty('scroll-padding-bottom', '10px');

    scrollRectIntoView(
      root,
      const Rect(top: 70, right: 10, bottom: 105, left: 0),
    );

    expect(root.scrollTop, 15);
  });

  test('does not move when the target spans both viewport edges', () {
    final root = nestedRoot(parentHeight: 100);

    scrollRectIntoView(
      root,
      const Rect(top: -10, right: 10, bottom: 110, left: 0),
    );

    expect(root.scrollTop, 0);
  });

  test('smooth mode replays the measured movement as smooth', () {
    final root = nestedRoot(parentHeight: 100);

    scrollRectIntoView(
      root,
      const Rect(top: 90, right: 10, bottom: 110, left: 0),
      const ScrollRectIntoViewOptions(smooth: true),
    );

    expect(root.scrollTop, 10);
    expect(root.scrollCalls, hasLength(3));
    expect(root.scrollCalls.last.smooth, isTrue);
  });

  test('a fixed root stops traversal before its ancestors', () {
    final root = nestedRoot(parentHeight: 50);
    final parent = root.parentNode! as FakeDomElement;
    root.style.setProperty('position', 'fixed');

    scrollRectIntoView(
      root,
      const Rect(top: 80, right: 10, bottom: 110, left: 0),
    );

    expect(root.scrollTop, 10);
    expect(parent.scrollTop, 0);
  });

  test('Quill exposes direct rectangle scrolling', () {
    final quill = createTestQuill();

    quill.scrollRectIntoView(
      const Rect(top: 100, right: 10, bottom: 110, left: 0),
    );

    expect(quill.root.scrollTop, 30);
  });
}
