/// Port of the colour wheel `quill-table-better` gets from `@jaames/iro`
/// (`iro.js` v5 — `src/Wheel.tsx` plus the geometry of `@irojs/iro-core`).
///
/// Only the Wheel layout is ported, which is the single layout the plugin
/// configures (`layout: [{ component: iro.ui.Wheel }]`). The hue is the angle
/// around the centre and the saturation the distance from it; value stays at
/// 100 because the plugin never shows a value slider.
///
/// The DOM is the upstream one — `.IroWheel` with the hue, saturation, border
/// and handle layers — so the existing stylesheet applies unchanged.
library;

import 'dart:math' as math;

import '../../platform/dom.dart';
import '../utils/utils.dart' as utils;

/// iro.js `HUE_GRADIENT_CLOCKWISE`.
const String kHueGradientClockwise =
    'conic-gradient(red, yellow, lime, aqua, blue, magenta, red)';

/// iro.js `HUE_GRADIENT_ANTICLOCKWISE`.
const String kHueGradientAnticlockwise =
    'conic-gradient(red, magenta, blue, aqua, lime, yellow, red)';

const double _tau = math.pi * 2;

double _mod(double a, double n) => (a % n + n) % n;

double _dist(double x, double y) => math.sqrt(x * x + y * y);

/// An HSV colour, as iro.js models it (h 0-360, s and v 0-100).
class HsvColor {
  const HsvColor(this.h, this.s, this.v);

  final double h;
  final double s;
  final double v;

  HsvColor copyWith({double? h, double? s, double? v}) =>
      HsvColor(h ?? this.h, s ?? this.s, v ?? this.v);

  /// iro.js `IroColor.hsvToRgb`.
  (int r, int g, int b) toRgb() {
    final hue = h / 60;
    final sat = s / 100;
    final val = v / 100;
    final i = hue.floor();
    final f = hue - i;
    final p = val * (1 - sat);
    final q = val * (1 - f * sat);
    final t = val * (1 - (1 - f) * sat);
    final index = i % 6;
    final r = [val, q, p, p, t, val][index];
    final g = [t, val, val, q, p, p][index];
    final b = [p, p, t, val, val, q][index];
    return (
      (r * 255).round().clamp(0, 255),
      (g * 255).round().clamp(0, 255),
      (b * 255).round().clamp(0, 255),
    );
  }

  /// iro.js `IroColor.rgbToHsv`.
  static HsvColor fromRgb(int red, int green, int blue) {
    final r = red / 255;
    final g = green / 255;
    final b = blue / 255;
    final max = math.max(r, math.max(g, b));
    final min = math.min(r, math.min(g, b));
    final delta = max - min;
    var hue = 0.0;
    if (delta != 0) {
      if (max == r) {
        hue = (g - b) / delta % 6;
      } else if (max == g) {
        hue = (b - r) / delta + 2;
      } else {
        hue = (r - g) / delta + 4;
      }
    }
    return HsvColor(
      _mod(hue * 60, 360),
      max == 0 ? 0 : (delta / max) * 100,
      max * 100,
    );
  }

  /// Parses `#rgb`, `#rrggbb` or `rgb(r, g, b)`.
  static HsvColor? parse(String value) {
    final input = value.trim();
    if (input.isEmpty) return null;
    if (input.startsWith('#')) {
      var hex = input.substring(1);
      if (hex.length == 3) {
        hex = hex.split('').map((c) => '$c$c').join();
      }
      if (hex.length != 6) return null;
      final parsed = int.tryParse(hex, radix: 16);
      if (parsed == null) return null;
      return fromRgb(
          (parsed >> 16) & 0xff, (parsed >> 8) & 0xff, parsed & 0xff);
    }
    final match = RegExp(r'rgba?\(\s*(\d+)\D+(\d+)\D+(\d+)').firstMatch(input);
    if (match == null) return null;
    return fromRgb(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
    );
  }

  /// iro.js `color.hexString`.
  String get hexString {
    final (r, g, b) = toRgb();
    String pad(int value) => value.toRadixString(16).padLeft(2, '0');
    return '#${pad(r)}${pad(g)}${pad(b)}';
  }

  /// iro.js `color.hslString`, used to fill the handle.
  String get hslString {
    final (r, g, b) = toRgb();
    return 'rgb($r, $g, $b)';
  }
}

/// The colour wheel widget (iro.js `IroWheel`).
class ColorWheel {
  ColorWheel({
    required DomDocument document,
    this.width = 110,
    this.padding = 6,
    this.handleRadius = 8,
    this.borderWidth = 0,
    this.wheelAngle = 0,
    this.wheelDirection = 'anticlockwise',
    HsvColor? color,
    this.onChange,
  })  : _document = document,
        _color = color ?? const HsvColor(0, 0, 100) {
    root = _build();
    _render();
  }

  final DomDocument _document;

  /// iro.js props.
  final double width;
  final double padding;
  final double handleRadius;
  final double borderWidth;
  final double wheelAngle;
  final String wheelDirection;

  /// Fired on every colour change, like iro.js `color:change`.
  final void Function(HsvColor color)? onChange;

  late final DomElement root;
  late final DomElement _handle;

  HsvColor _color;

  HsvColor get color => _color;

  set color(HsvColor value) {
    _color = value;
    _render();
    onChange?.call(_color);
  }

  /// Convenience setter matching `colorPicker.color.hexString = ...`.
  bool setHexString(String value) {
    final parsed = HsvColor.parse(value);
    if (parsed == null) return false;
    color = parsed;
    return true;
  }

  /// iro.js `getWheelDimensions`.
  ({double width, double radius, double cx, double cy}) get dimensions {
    final r = width / 2;
    return (width: width, radius: r - borderWidth, cx: r, cy: r);
  }

  /// iro.js `getHandleRange`.
  double get handleRange => width / 2 - padding - handleRadius - borderWidth;

  /// iro.js `translateWheelAngle(props, angle, invert)`.
  double translateWheelAngle(double angle, {bool invert = false}) {
    if (invert && wheelDirection == 'clockwise') {
      return _mod(wheelAngle + angle, 360);
    }
    if (wheelDirection == 'clockwise') {
      return _mod(360 - wheelAngle + angle, 360);
    }
    if (invert && wheelDirection == 'anticlockwise') {
      return _mod(wheelAngle + 180 - angle, 360);
    }
    return _mod(wheelAngle - angle, 360);
  }

  /// iro.js `getWheelHandlePosition(props, color)`.
  ({double x, double y}) handlePosition([HsvColor? target]) {
    final hsv = target ?? _color;
    final size = dimensions;
    final angle =
        (180 + translateWheelAngle(hsv.h, invert: true)) * (_tau / 360);
    final distance = hsv.s / 100 * handleRange;
    final direction = wheelDirection == 'clockwise' ? -1 : 1;
    return (
      x: size.cx + distance * math.cos(angle) * direction,
      y: size.cy + distance * math.sin(angle) * direction,
    );
  }

  /// iro.js `getWheelValueFromInput(props, x, y)` — the pointer position, in
  /// wheel-local coordinates, becomes hue and saturation.
  HsvColor valueFromInput(double x, double y) {
    final size = dimensions;
    final dx = size.cx - x;
    final dy = size.cy - y;
    final hue = translateWheelAngle(math.atan2(-dy, -dx) * (360 / _tau));
    final distance = math.min(_dist(dx, dy), handleRange);
    return _color.copyWith(
      h: hue.roundToDouble(),
      s: (100 / handleRange * distance).roundToDouble(),
    );
  }

  /// iro.js `isInputInsideWheel(props, x, y)`.
  bool isInsideWheel(double x, double y) {
    final size = dimensions;
    return _dist(size.cx - x, size.cy - y) < width / 2;
  }

  /// Applies a pointer position, ignoring clicks outside the circle exactly as
  /// the upstream `IroInputType.Start` branch does.
  bool handleInput(double x, double y, {bool isStart = false}) {
    if (isStart && !isInsideWheel(x, y)) return false;
    color = valueFromInput(x, y);
    return true;
  }

  DomElement _build() {
    final container = _document.createElement('div');
    container.classes.add('IroWheel');
    utils.setElementProperty(container, {
      'width': '${utils.formatNum(width)}px',
      'height': '${utils.formatNum(width)}px',
      'position': 'relative',
    });

    DomElement layer(String className, Map<String, String> style) {
      final element = _document.createElement('div');
      element.classes.add(className);
      utils.setElementProperty(element, {
        'position': 'absolute',
        'top': '0',
        'left': '0',
        'width': '100%',
        'height': '100%',
        'border-radius': '50%',
        'box-sizing': 'border-box',
        ...style,
      });
      container.append(element);
      return element;
    }

    layer('IroWheelHue', {
      'transform': 'rotateZ(${utils.formatNum(wheelAngle + 90)}deg)',
      'background': wheelDirection == 'clockwise'
          ? kHueGradientClockwise
          : kHueGradientAnticlockwise,
    });
    layer('IroWheelSaturation', {
      'background': 'radial-gradient(circle closest-side, #fff, transparent)',
    });
    layer('IroWheelBorder', {});

    _handle = _document.createElement('div');
    _handle.classes.add('IroHandle');
    _handle.classes.add('IroHandle--isActive');
    container.append(_handle);

    container.addEventListener('mousedown', (event) {
      if (event is! DomMouseEvent) return;
      final local = _toLocal(event);
      if (handleInput(local.x, local.y, isStart: true)) event.preventDefault();
    });
    return container;
  }

  ({double x, double y}) _toLocal(DomMouseEvent event) {
    final bounds = utils.getCorrectBounds(root);
    return (
      x: event.clientX.toDouble() - bounds.left,
      y: event.clientY.toDouble() - bounds.top,
    );
  }

  void _render() {
    final position = handlePosition();
    final diameter = handleRadius * 2;
    utils.setElementProperty(_handle, {
      'position': 'absolute',
      'width': '${utils.formatNum(diameter)}px',
      'height': '${utils.formatNum(diameter)}px',
      'border-radius': '50%',
      'box-sizing': 'border-box',
      'border': '2px solid #fff',
      'box-shadow': '0 0 3px rgba(0,0,0,.3)',
      'left': '${utils.formatNum(position.x - handleRadius)}px',
      'top': '${utils.formatNum(position.y - handleRadius)}px',
      'background-color': _color.hslString,
    });
  }
}
