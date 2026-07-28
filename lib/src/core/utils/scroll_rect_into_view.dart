import '../../platform/dom.dart';
import '../../platform/platform.dart';

class Rect {
  const Rect({
    required this.top,
    required this.right,
    required this.bottom,
    required this.left,
  });

  factory Rect.fromMap(Map<String, dynamic> value) => Rect(
        top: (value['top'] as num).toDouble(),
        right: (value['right'] as num).toDouble(),
        bottom: (value['bottom'] as num).toDouble(),
        left: (value['left'] as num).toDouble(),
      );

  final double top;
  final double right;
  final double bottom;
  final double left;

  double get height => bottom - top;
  double get width => right - left;

  Rect translate(double x, double y) => Rect(
        top: top + y,
        right: right + x,
        bottom: bottom + y,
        left: left + x,
      );
}

class ScrollRectIntoViewOptions {
  const ScrollRectIntoViewOptions({this.smooth = false});

  final bool smooth;
}

class _ScrollOffsetRecord {
  const _ScrollOffsetRecord(this.element, this.left, this.top);

  final DomElement element;
  final double left;
  final double top;
}

double _paddingValueToDouble(String value) {
  final match = RegExp(r'^[-+]?\d+(?:\.\d+)?').firstMatch(value.trim());
  return match == null ? 0 : double.tryParse(match.group(0)!) ?? 0;
}

// CSSOM View's "nearest" scrolling distance.
double _getScrollDistance(
  double targetStart,
  double targetEnd,
  double scrollStart,
  double scrollEnd,
  double scrollPaddingStart,
  double scrollPaddingEnd,
) {
  if (targetStart < scrollStart && targetEnd > scrollEnd) return 0;
  if (targetStart < scrollStart) {
    return -(scrollStart - targetStart + scrollPaddingStart);
  }
  if (targetEnd > scrollEnd) {
    return targetEnd - targetStart > scrollEnd - scrollStart
        ? targetStart + scrollPaddingStart - scrollStart
        : targetEnd - scrollEnd + scrollPaddingEnd;
  }
  return 0;
}

Rect? _getElementRect(DomElement element) {
  final bounds = domBindings.adapter.getElementBounds(element);
  if (bounds == null) return null;
  final rawWidth = (bounds['width'] as num?)?.toDouble() ??
      ((bounds['right'] as num).toDouble() -
          (bounds['left'] as num).toDouble());
  final rawHeight = (bounds['height'] as num?)?.toDouble() ??
      ((bounds['bottom'] as num).toDouble() -
          (bounds['top'] as num).toDouble());
  final ratioX =
      element.offsetWidth == 0 ? 0.0 : rawWidth.abs() / element.offsetWidth;
  final ratioY =
      element.offsetHeight == 0 ? 0.0 : rawHeight.abs() / element.offsetHeight;
  final scaleX = ratioX == 0 ? 1.0 : ratioX;
  final scaleY = ratioY == 0 ? 1.0 : ratioY;
  final left = (bounds['left'] as num).toDouble();
  final top = (bounds['top'] as num).toDouble();
  return Rect(
    top: top,
    right: left + element.clientWidth * scaleX,
    bottom: top + element.clientHeight * scaleY,
    left: left,
  );
}

/// Scroll [targetRect] into the nearest visible position through every
/// scrollable ancestor of [root], following Quill's CSSOM-view algorithm.
void scrollRectIntoView(
  DomElement root,
  Rect targetRect, [
  ScrollRectIntoViewOptions options = const ScrollRectIntoViewOptions(),
]) {
  final document = root.ownerDocument;
  var rect = targetRect;
  final records = <_ScrollOffsetRecord>[];

  DomElement? current = root;
  while (current != null) {
    final isDocumentBody = current == document.body;
    final viewport = domBindings.adapter.getViewportBounds(document);
    final bounding = isDocumentBody
        ? Rect(
            top: 0,
            right: viewport['width']!,
            bottom: viewport['height']!,
            left: 0,
          )
        : _getElementRect(current);
    if (bounding == null) break;

    String style(String property) =>
        domBindings.adapter.getComputedStyleProperty(current!, property);
    final distanceX = _getScrollDistance(
      rect.left,
      rect.right,
      bounding.left,
      bounding.right,
      _paddingValueToDouble(style('scroll-padding-left')),
      _paddingValueToDouble(style('scroll-padding-right')),
    );
    final distanceY = _getScrollDistance(
      rect.top,
      rect.bottom,
      bounding.top,
      bounding.bottom,
      _paddingValueToDouble(style('scroll-padding-top')),
      _paddingValueToDouble(style('scroll-padding-bottom')),
    );

    if (distanceX != 0 || distanceY != 0) {
      final previousLeft = current.scrollLeft;
      final previousTop = current.scrollTop;
      current.scrollBy(distanceX, distanceY);
      records.add(_ScrollOffsetRecord(current, distanceX, distanceY));

      if (!isDocumentBody) {
        final scrolledLeft = current.scrollLeft - previousLeft;
        final scrolledTop = current.scrollTop - previousTop;
        rect = rect.translate(
          -scrolledLeft.toDouble(),
          -scrolledTop.toDouble(),
        );
      }
    }

    final fixed = style('position') == 'fixed';
    current = isDocumentBody || fixed
        ? null
        : domBindings.adapter.getParentElement(current);
  }

  if (options.smooth) {
    for (final record in records) {
      record.element.scrollBy(-record.left, -record.top);
      record.element.scrollBy(record.left, record.top, smooth: true);
    }
  }
}
