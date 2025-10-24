import '../../platform/dom.dart';

class Rect {
  const Rect({
    required this.top,
    required this.right,
    required this.bottom,
    required this.left,
  });

  final double top;
  final double right;
  final double bottom;
  final double left;

  double get height => bottom - top;
  double get width => right - left;
}

class ScrollRectIntoViewOptions {
  const ScrollRectIntoViewOptions({this.smooth = false});

  final bool smooth;
}

void scrollRectIntoView(
  DomElement root,
  Rect target,
  [ScrollRectIntoViewOptions options = const ScrollRectIntoViewOptions()]
) {
  final currentTop = root.scrollTop;
  final currentBottom = currentTop + root.clientHeight;

  var deltaY = 0;
  if (target.top < currentTop) {
    deltaY = target.top.floor() - currentTop;
  } else if (target.bottom > currentBottom) {
    deltaY = target.bottom.ceil() - currentBottom;
  }

  if (deltaY != 0) {
    root.scrollTop = currentTop + deltaY;
  }

  final currentLeft = root.scrollLeft;
  final currentRight = currentLeft + root.clientWidth;

  var deltaX = 0;
  if (target.left < currentLeft) {
    deltaX = target.left.floor() - currentLeft;
  } else if (target.right > currentRight) {
    deltaX = target.right.ceil() - currentRight;
  }

  if (deltaX != 0) {
    root.scrollLeft = currentLeft + deltaX;
  }

  if (options.smooth && (deltaX != 0 || deltaY != 0)) {
    // Smooth scrolling is not currently implemented in the platform abstraction.
    // The values above provide an immediate jump which matches the default behaviour.
  }
}
