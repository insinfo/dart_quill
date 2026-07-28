@TestOn('browser')
library tooltip_position_test;

import 'package:dart_quill/src/core/initialization.dart';
import 'package:dart_quill/src/core/quill.dart';
import 'package:dart_quill/src/platform/html_dom.dart';
import 'package:dart_quill/src/ui/dom_interop.dart';
import 'package:dart_quill/src/ui/tooltip.dart';
import 'package:test/test.dart';
import 'package:web/web.dart' as web;

const double _containerWidth = 200;
const double _containerHeight = 100;
const double _tooltipWidth = 120;
const double _tooltipHeight = 40;

class _Fixture {
  _Fixture(this.wrapper, this.quill, this.tooltip);

  final web.HTMLElement wrapper;
  final Quill quill;
  final Tooltip tooltip;

  web.HTMLElement get root =>
      (tooltip.root as HtmlDomElement).node as web.HTMLElement;

  /// Root position relative to the bounds container, as laid out.
  double get left =>
      root.getBoundingClientRect().left - wrapper.getBoundingClientRect().left;

  double get top =>
      root.getBoundingClientRect().top - wrapper.getBoundingClientRect().top;
}

_Fixture _createFixture() {
  final wrapper = web.document.createElement('div') as web.HTMLElement;
  wrapper.style.cssText = 'position:relative;width:${_containerWidth}px;'
      'height:${_containerHeight}px;margin:0;padding:0;';
  final host = web.document.createElement('div') as web.HTMLElement;
  wrapper.appendChild(host);
  web.document.body!.appendChild(wrapper);
  addTearDown(() => wrapper.remove());

  final quill = Quill(HtmlDomElement(host));
  final tooltip = Tooltip(quill, HtmlDomElement(wrapper));
  final root = (tooltip.root as HtmlDomElement).node as web.HTMLElement;
  root.style.cssText = 'position:absolute;box-sizing:border-box;'
      'width:${_tooltipWidth}px;height:${_tooltipHeight}px;';
  return _Fixture(wrapper, quill, tooltip);
}

Map<String, dynamic> _reference({
  required double left,
  required double top,
  required double bottom,
  double width = 40,
}) =>
    <String, dynamic>{
      'left': left,
      'top': top,
      'right': left + width,
      'bottom': bottom,
      'width': width,
      'height': bottom - top,
    };

void main() {
  setUpAll(initializeQuill);

  group('computed overflow', () {
    test('reports the computed (not inline) overflow-y', () {
      final style = web.document.createElement('style') as web.HTMLStyleElement;
      style.textContent = '.ql-test-scroller { overflow-y: auto; }';
      web.document.head!.appendChild(style);
      addTearDown(() => style.remove());

      final scroller = web.document.createElement('div') as web.HTMLElement;
      scroller.className = 'ql-test-scroller';
      final plain = web.document.createElement('div') as web.HTMLElement;
      web.document.body!.appendChild(scroller);
      web.document.body!.appendChild(plain);
      addTearDown(() => scroller.remove());
      addTearDown(() => plain.remove());

      expect(computedOverflowY(HtmlDomElement(scroller)), 'auto');
      expect(isScrollable(HtmlDomElement(scroller)), isTrue);
      expect(computedOverflowY(HtmlDomElement(plain)), 'visible');
      expect(isScrollable(HtmlDomElement(plain)), isFalse);
    });
  });

  group('Tooltip.position with real layout', () {
    test('centers on the reference and does not flip when it fits', () {
      final fixture = _createFixture();
      final shift = fixture.tooltip.position(
        _reference(left: 60, top: 0, bottom: 20),
      );

      expect(shift, 0);
      // left = 60 + 40 / 2 - 120 / 2 = 20
      expect(fixture.left, closeTo(20, 0.5));
      expect(fixture.top, closeTo(20, 0.5));
      expect(fixture.root.classList.contains('ql-flip'), isFalse);
    });

    test('shifts back inside when overflowing the right edge', () {
      final fixture = _createFixture();
      final shift = fixture.tooltip.position(
        _reference(left: 150, top: 0, bottom: 20),
      );

      // left would be 110, so the 120px wide tooltip ends at 230 > 200.
      expect(shift, closeTo(-30, 0.5));
      expect(fixture.left, closeTo(80, 0.5));
      expect(fixture.root.classList.contains('ql-flip'), isFalse);
    });

    test('shifts back inside when overflowing the left edge', () {
      final fixture = _createFixture();
      final shift = fixture.tooltip.position(
        _reference(left: 0, top: 0, bottom: 20),
      );

      // left would be -40.
      expect(shift, closeTo(40, 0.5));
      expect(fixture.left, closeTo(0, 0.5));
    });

    test('flips above the reference when overflowing the bottom edge', () {
      final fixture = _createFixture();
      fixture.tooltip.position(_reference(left: 60, top: 60, bottom: 80));

      // top would be 80, so the 40px tall tooltip ends at 120 > 100.
      // verticalShift = (80 - 60) + 40 = 60 => 80 - 60 = 20
      expect(fixture.top, closeTo(20, 0.5));
      expect(fixture.root.classList.contains('ql-flip'), isTrue);
    });

    test('clears ql-flip once the tooltip fits again', () {
      final fixture = _createFixture();
      fixture.tooltip.position(_reference(left: 60, top: 60, bottom: 80));
      expect(fixture.root.classList.contains('ql-flip'), isTrue);

      fixture.tooltip.position(_reference(left: 60, top: 0, bottom: 20));
      expect(fixture.root.classList.contains('ql-flip'), isFalse);
    });
  });
}
