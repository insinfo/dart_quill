import 'package:dart_quill/src/core/emitter.dart';
import 'package:dart_quill/src/core/quill.dart';
import 'package:dart_quill/src/core/selection.dart';
import 'package:dart_quill/src/modules/toolbar.dart';
import 'package:dart_quill/src/platform/dom.dart';
import 'package:dart_quill/src/platform/platform.dart';
import 'package:dart_quill/src/themes/base.dart';
import 'package:dart_quill/src/themes/snow.dart';
import 'package:dart_quill/src/ui/tooltip.dart';
import 'package:test/test.dart';

import '../../support/quill_test_helpers.dart';
import '../../support/test_helpers.dart';

/// Adapter that lets a test dictate element rects (the fake DOM has no
/// layout) and records every `getBounds` request made by the editor.
class _LayoutAdapter implements DomAdapter {
  _LayoutAdapter(this.inner);

  final DomAdapter inner;
  final Map<DomElement, Map<String, dynamic>> rects = {};
  final List<List<int>> boundsCalls = [];

  void setRect(
    DomElement element, {
    required double left,
    required double top,
    required double right,
    required double bottom,
  }) {
    rects[element] = <String, dynamic>{
      'left': left,
      'top': top,
      'right': right,
      'bottom': bottom,
      'width': right - left,
      'height': bottom - top,
    };
  }

  @override
  Map<String, dynamic>? getElementBounds(DomElement element,
          {DomElement? relativeTo}) =>
      rects[element] ?? inner.getElementBounds(element, relativeTo: relativeTo);

  @override
  DomElement? getParentElement(DomElement element) =>
      inner.getParentElement(element);

  @override
  Map<String, double> getViewportBounds(DomDocument document) =>
      inner.getViewportBounds(document);

  @override
  Map<String, dynamic>? getBounds(DomElement root, int index, int length) {
    boundsCalls.add([index, length]);
    return inner.getBounds(root, index, length);
  }

  @override
  Map<String, dynamic>? getRangeBounds(
          DomNode startNode, int startOffset, DomNode endNode, int endOffset) =>
      inner.getRangeBounds(startNode, startOffset, endNode, endOffset);

  @override
  DomDocument get document => inner.document;

  @override
  DomMutationObserver createMutationObserver(
          void Function(List<DomMutationRecord>, DomMutationObserver) cb) =>
      inner.createMutationObserver(cb);

  @override
  DomSelectionRange? getSelectionRange(DomElement root) =>
      inner.getSelectionRange(root);

  @override
  DomNativeRange? getNativeSelectionRange() => inner.getNativeSelectionRange();

  @override
  void downloadBytes(String filename, String mimeType, List<int> bytes) =>
      inner.downloadBytes(filename, mimeType, bytes);

  @override
  DomNativeRange? caretRangeFromPoint(num x, num y) =>
      inner.caretRangeFromPoint(x, y);

  @override
  void setSelectionRange(DomElement root, int index, int length) =>
      inner.setSelectionRange(root, index, length);

  @override
  void setSelectionByNodes(
          DomNode startNode, int startOffset, DomNode endNode, int endOffset) =>
      inner.setSelectionByNodes(startNode, startOffset, endNode, endOffset);

  @override
  Future<String?> readFileAsDataUrl(dynamic file) =>
      inner.readFileAsDataUrl(file);

  @override
  void focus(DomElement element) => inner.focus(element);

  @override
  void blur(DomElement element) => inner.blur(element);

  @override
  String getComputedStyleProperty(DomElement element, String property) =>
      inner.getComputedStyleProperty(element, property);

  @override
  String? get userAgent => inner.userAgent;

  @override
  String? get platform => inner.platform;

  @override
  bool get supportsNativeSelection => inner.supportsNativeSelection;

  @override
  bool hasFocus(DomElement root) => inner.hasFocus(root);

  @override
  void clearNativeSelection() => inner.clearNativeSelection();
}

_LayoutAdapter _installLayoutAdapter() {
  ensureQuillTestInitialized();
  final previous = domBindings.adapter;
  final adapter = _LayoutAdapter(previous);
  domBindings.adapter = adapter;
  addTearDown(() => domBindings.adapter = previous);
  return adapter;
}

void main() {
  group('isScrollable', () {
    final defaultResolver = tooltipOverflowYResolver;

    tearDown(() {
      tooltipOverflowYResolver = defaultResolver;
    });

    test('visible and clip are not scrollable', () {
      final element = testAdapter.document.createElement('div');
      tooltipOverflowYResolver = (_) => 'visible';
      expect(isScrollable(element), isFalse);
      tooltipOverflowYResolver = (_) => 'clip';
      expect(isScrollable(element), isFalse);
    });

    test('auto/scroll/hidden are scrollable', () {
      final element = testAdapter.document.createElement('div');
      for (final value in ['auto', 'scroll', 'hidden']) {
        tooltipOverflowYResolver = (_) => value;
        expect(isScrollable(element), isTrue, reason: value);
      }
    });

    test('unknown overflow falls back to scrollable', () {
      final element = testAdapter.document.createElement('div');
      tooltipOverflowYResolver = (_) => null;
      expect(isScrollable(element), isTrue);
    });
  });

  group('Tooltip.position', () {
    late Quill quill;
    late _LayoutAdapter adapter;

    setUp(() {
      adapter = _installLayoutAdapter();
      quill = createTestQuill(initialHtml: '<p>0123</p>');
    });

    Tooltip createTooltip() => Tooltip(quill, quill.container);

    test('no shift and no flip when the tooltip fits', () {
      final tooltip = createTooltip();
      adapter.setRect(tooltip.boundsContainer,
          left: 0, top: 0, right: 500, bottom: 500);
      adapter.setRect(tooltip.root, left: 40, top: 20, right: 140, bottom: 60);

      final shift = tooltip.position(
        {
          'left': 40.0,
          'top': 0.0,
          'right': 140.0,
          'bottom': 20.0,
          'width': 100.0
        },
      );

      expect(shift, 0);
      expect(tooltip.root.classes.contains('ql-flip'), isFalse);
    });

    test('shifts left when overflowing the container right edge', () {
      final tooltip = createTooltip();
      adapter.setRect(tooltip.boundsContainer,
          left: 0, top: 0, right: 200, bottom: 500);
      adapter.setRect(tooltip.root, left: 150, top: 20, right: 250, bottom: 60);

      final shift = tooltip.position(
        {
          'left': 150.0,
          'top': 0.0,
          'right': 250.0,
          'bottom': 20.0,
          'width': 100.0
        },
      );

      // containerBounds.right - rootBounds.right
      expect(shift, -50);
      expect(tooltip.root.classes.contains('ql-flip'), isFalse);
    });

    test('shifts right when overflowing the container left edge', () {
      final tooltip = createTooltip();
      adapter.setRect(tooltip.boundsContainer,
          left: 100, top: 0, right: 600, bottom: 500);
      adapter.setRect(tooltip.root, left: 60, top: 20, right: 160, bottom: 60);

      final shift = tooltip.position(
        {
          'left': 60.0,
          'top': 0.0,
          'right': 160.0,
          'bottom': 20.0,
          'width': 100.0
        },
      );

      expect(shift, 40);
    });

    test('adds ql-flip when overflowing the container bottom edge', () {
      final tooltip = createTooltip();
      adapter.setRect(tooltip.boundsContainer,
          left: 0, top: 0, right: 500, bottom: 100);
      adapter.setRect(tooltip.root, left: 40, top: 80, right: 140, bottom: 120);

      tooltip.position(
        {
          'left': 40.0,
          'top': 60.0,
          'right': 140.0,
          'bottom': 80.0,
          'width': 100.0
        },
      );

      expect(tooltip.root.classes.contains('ql-flip'), isTrue);
    });

    test('removes a stale ql-flip when the tooltip fits again', () {
      final tooltip = createTooltip();
      adapter.setRect(tooltip.boundsContainer,
          left: 0, top: 0, right: 500, bottom: 500);
      adapter.setRect(tooltip.root, left: 40, top: 20, right: 140, bottom: 60);
      tooltip.root.classes.add('ql-flip');

      tooltip.position(
        {
          'left': 40.0,
          'top': 0.0,
          'right': 140.0,
          'bottom': 20.0,
          'width': 100.0
        },
      );

      expect(tooltip.root.classes.contains('ql-flip'), isFalse);
    });
  });

  group('BubbleTooltip', () {
    test('positions against the last line of a multi-line selection', () {
      final adapter = _installLayoutAdapter();
      final quill = createTestQuill(
        initialHtml: '<p>0123</p><p>5678</p>',
        theme: 'bubble',
      );

      adapter.boundsCalls.clear();
      quill.setSelection(Range(0, 9), source: EmitterSource.USER);

      expect(adapter.boundsCalls, isNotEmpty);
      // Parity bubble.ts:48-58: the last line starts at index 5 and the
      // selection covers its 4 characters (the trailing newline is excluded).
      expect(adapter.boundsCalls, contains(equals([5, 4])));
      // scrollSelectionIntoView uses Selection's native viewport bounds
      // directly (quill.ts:696), not Quill.getBounds' platform fallback.
      expect(adapter.boundsCalls.last, [5, 4]);
    });

    test('positions against the selection itself on a single line', () {
      final adapter = _installLayoutAdapter();
      final quill = createTestQuill(
        initialHtml: '<p>0123</p><p>5678</p>',
        theme: 'bubble',
      );

      adapter.boundsCalls.clear();
      quill.setSelection(Range(1, 2), source: EmitterSource.USER);

      expect(adapter.boundsCalls.last, [1, 2]);
    });
  });

  group('theme link handlers', () {
    test('snowLinkPreview prefixes mailto: only for e-mail text', () {
      expect(snowLinkPreview('a@b.com'), 'mailto:a@b.com');
      expect(snowLinkPreview('mailto:a@b.com'), 'mailto:a@b.com');
      expect(snowLinkPreview('quilljs'), 'quilljs');
      expect(snowLinkPreview('https://quilljs.com'), 'https://quilljs.com');
      expect(snowLinkPreview('a@b.com c@d.com'), 'a@b.com c@d.com');
    });

    test('snow opens the tooltip editor for a non-empty selection', () {
      _installLayoutAdapter();
      final quill = createTestQuill(
        initialHtml: '<p>quilljs</p>',
        theme: 'snow',
        modules: {
          'toolbar': [
            ['link']
          ],
        },
      );
      final toolbar = quill.theme.modules['toolbar'] as Toolbar;
      final tooltip = (quill.theme as BaseTheme).tooltip as BaseTooltip;

      quill.setSelection(Range(0, 7), source: EmitterSource.USER);
      toolbar.handlers['link']!(true);

      expect(tooltip.root.classes.contains('ql-editing'), isTrue);
    });

    test('snow ignores a collapsed selection', () {
      _installLayoutAdapter();
      final quill = createTestQuill(
        initialHtml: '<p>quilljs</p>',
        theme: 'snow',
        modules: {
          'toolbar': [
            ['link']
          ],
        },
      );
      final toolbar = quill.theme.modules['toolbar'] as Toolbar;
      final tooltip = (quill.theme as BaseTheme).tooltip as BaseTooltip;

      quill.setSelection(Range(2, 0), source: EmitterSource.USER);
      toolbar.handlers['link']!(true);

      expect(tooltip.root.classes.contains('ql-editing'), isFalse);
    });

    test('bubble opens the tooltip editor without a preview', () {
      _installLayoutAdapter();
      final quill = createTestQuill(
        initialHtml: '<p>quilljs</p>',
        theme: 'bubble',
      );
      final toolbar = quill.theme.modules['toolbar'] as Toolbar;
      final tooltip = (quill.theme as BaseTheme).tooltip as BaseTooltip;

      quill.setSelection(Range(0, 7), source: EmitterSource.USER);
      toolbar.handlers['link']!(true);

      expect(tooltip.root.classes.contains('ql-editing'), isTrue);
    });
  });
}
