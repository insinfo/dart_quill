import 'dart:math' as math;

import 'package:dart_quill/src/table_better/ui/color_wheel.dart';
import 'package:test/test.dart';

import '../../support/test_helpers.dart';

void main() {
  setUpAll(initializeFakeDom);

  ColorWheel build({HsvColor? color, double width = 110}) => ColorWheel(
        document: testAdapter.document,
        width: width,
        color: color,
      );

  group('HsvColor conversions', () {
    test('hsv → rgb matches the iro.js reference values', () {
      expect(const HsvColor(0, 100, 100).toRgb(), equals((255, 0, 0)));
      expect(const HsvColor(120, 100, 100).toRgb(), equals((0, 255, 0)));
      expect(const HsvColor(240, 100, 100).toRgb(), equals((0, 0, 255)));
      expect(const HsvColor(0, 0, 100).toRgb(), equals((255, 255, 255)));
      expect(const HsvColor(0, 0, 0).toRgb(), equals((0, 0, 0)));
    });

    test('rgb → hsv is the inverse', () {
      final red = HsvColor.fromRgb(255, 0, 0);
      expect(red.h, closeTo(0, 0.001));
      expect(red.s, closeTo(100, 0.001));
      expect(red.v, closeTo(100, 0.001));

      final teal = HsvColor.fromRgb(0, 128, 128);
      expect(teal.h, closeTo(180, 0.5));
      expect(teal.s, closeTo(100, 0.5));
    });

    test('hexString round-trips', () {
      for (final hex in ['#ff0000', '#00ff00', '#0000ff', '#4d99e6']) {
        expect(HsvColor.parse(hex)!.hexString, equals(hex));
      }
    });

    test('parse accepts short hex and rgb()', () {
      expect(HsvColor.parse('#f00')!.hexString, equals('#ff0000'));
      expect(HsvColor.parse('rgb(0, 0, 255)')!.hexString, equals('#0000ff'));
      expect(HsvColor.parse('rgba(255, 165, 0, 0.5)')!.hexString,
          equals('#ffa500'));
      expect(HsvColor.parse('nonsense'), isNull);
      expect(HsvColor.parse(''), isNull);
    });
  });

  group('geometry', () {
    test('dimensions and handle range follow the iro.js formulas', () {
      final wheel = build(width: 110);
      final size = wheel.dimensions;
      expect(size.width, equals(110));
      expect(size.cx, equals(55));
      expect(size.cy, equals(55));
      // width/2 - padding - handleRadius - borderWidth
      expect(wheel.handleRange, equals(55 - 6 - 8 - 0));
    });

    test('a fully saturated colour sits on the handle range', () {
      final wheel = build(color: const HsvColor(0, 100, 100));
      final position = wheel.handlePosition();
      final distance = math
          .sqrt(math.pow(position.x - 55, 2) + math.pow(position.y - 55, 2));
      expect(distance, closeTo(wheel.handleRange, 0.001));
    });

    test('a desaturated colour sits at the centre', () {
      final wheel = build(color: const HsvColor(200, 0, 100));
      final position = wheel.handlePosition();
      expect(position.x, closeTo(55, 0.001));
      expect(position.y, closeTo(55, 0.001));
    });

    test('handlePosition and valueFromInput are inverses', () {
      for (final hsv in const [
        HsvColor(0, 100, 100),
        HsvColor(90, 50, 100),
        HsvColor(210, 75, 100),
        HsvColor(330, 20, 100),
      ]) {
        final wheel = build(color: hsv);
        final position = wheel.handlePosition();
        final back = wheel.valueFromInput(position.x, position.y);
        expect(back.h, closeTo(hsv.h, 1));
        expect(back.s, closeTo(hsv.s, 1));
      }
    });

    test('input outside the circle is rejected on start', () {
      final wheel = build();
      expect(wheel.isInsideWheel(55, 55), isTrue);
      expect(wheel.isInsideWheel(0, 0), isFalse);
      expect(wheel.handleInput(0, 0, isStart: true), isFalse);
      expect(wheel.handleInput(0, 0), isTrue,
          reason: 'a drag already in progress is not re-tested');
    });

    test('saturation is clamped to the handle range', () {
      final wheel = build();
      // Far to the right, well beyond the wheel: saturation saturates at 100.
      wheel.handleInput(1000, 55);
      expect(wheel.color.s, equals(100));
    });
  });

  group('widget', () {
    test('builds the iro.js layer stack', () {
      final wheel = build();
      expect(wheel.root.classes.contains('IroWheel'), isTrue);
      expect(wheel.root.querySelectorAll('.IroWheelHue'), hasLength(1));
      expect(wheel.root.querySelectorAll('.IroWheelSaturation'), hasLength(1));
      expect(wheel.root.querySelectorAll('.IroWheelBorder'), hasLength(1));
      expect(wheel.root.querySelectorAll('.IroHandle'), hasLength(1));
      expect(
        wheel.root.querySelectorAll('.IroWheelHue').first.getAttribute('style'),
        contains('conic-gradient'),
      );
    });

    test('changing the colour moves the handle and fires onChange', () {
      HsvColor? seen;
      final wheel = ColorWheel(
        document: testAdapter.document,
        color: const HsvColor(0, 0, 100),
        onChange: (color) => seen = color,
      );
      final handle = wheel.root.querySelectorAll('.IroHandle').first;
      final before = handle.getAttribute('style');

      wheel.color = const HsvColor(120, 100, 100);

      expect(seen?.hexString, equals('#00ff00'));
      expect(handle.getAttribute('style'), isNot(equals(before)));
      expect(handle.getAttribute('style'), contains('rgb(0, 255, 0)'));
    });

    test('setHexString accepts a valid colour and rejects junk', () {
      final wheel = build();
      expect(wheel.setHexString('#0000ff'), isTrue);
      expect(wheel.color.hexString, equals('#0000ff'));
      expect(wheel.setHexString('not-a-colour'), isFalse);
      expect(wheel.color.hexString, equals('#0000ff'));
    });
  });
}
