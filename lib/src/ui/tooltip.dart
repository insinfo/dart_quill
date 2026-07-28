import '../core/quill.dart';
import '../platform/dom.dart';
import '../platform/platform.dart';
import 'dom_interop.dart';

/// Parity `tooltip.ts:4-7` — `overflowY !== 'visible' && overflowY !== 'clip'`.
///
/// The platform DOM abstraction has no computed-style API, so the value is
/// resolved through [tooltipOverflowYResolver]. When it cannot be resolved
/// (VM / fake DOM) the element is assumed scrollable: installing the scroll
/// listener on a non-scrolling element is a no-op (its `scrollTop` stays 0),
/// whereas skipping it on a scrolling editor would leave the tooltip
/// detached from the text while the user scrolls.
bool isScrollable(DomElement element) {
  final overflowY = tooltipOverflowYResolver(element);
  if (overflowY == null || overflowY.isEmpty) return true;
  return overflowY != 'visible' && overflowY != 'clip';
}

/// Resolves the computed `overflow-y` of an element; pluggable so tests (and
/// alternative platform adapters) can provide layout information.
String? Function(DomElement element) tooltipOverflowYResolver =
    computedOverflowY;

class Tooltip {
  Tooltip(this.quill, [DomElement? boundsContainer, String? template])
      : boundsContainer = boundsContainer ?? quill.root.ownerDocument.body,
        root = quill.addContainer('ql-tooltip') {
    if (template != null && template.isNotEmpty) {
      root.innerHTML = template;
    }
    if (isScrollable(quill.root)) {
      _scrollListener = (event) {
        final style = root.style as dynamic;
        style?.marginTop = '${-1 * quill.root.scrollTop}px';
      };
      quill.root.addEventListener('scroll', _scrollListener!);
    }
    hide();
  }

  final Quill quill;
  final DomElement boundsContainer;
  final DomElement root;

  DomEventListener? _scrollListener;

  void hide() {
    root.classes.add('ql-hidden');
  }

  /// Parity `tooltip.ts:32-58`. Returns the horizontal shift applied to keep
  /// the tooltip inside [boundsContainer] (0 when it already fits).
  double position(Map<String, dynamic> reference) {
    final style = root.style as dynamic;
    final double refLeft = _extract(reference['left']);
    final double refTop = _extract(reference['top']);
    final double refBottom = _extract(reference['bottom']);
    final double refWidth = _extract(reference['width']);

    final double left =
        refLeft + refWidth / 2 - root.offsetWidth.toDouble() / 2;
    // root.scrollTop should be 0 if scrollContainer !== root
    final double top = refBottom + quill.root.scrollTop;
    style?.left = '${left}px';
    style?.top = '${top}px';
    root.classes.remove('ql-flip');

    final containerBounds =
        domBindings.adapter.getElementBounds(boundsContainer);
    final rootBounds = domBindings.adapter.getElementBounds(root);
    if (containerBounds == null || rootBounds == null) {
      // No layout information on this adapter: leave the centered position.
      return 0;
    }

    final double containerLeft = _extract(containerBounds['left']);
    final double containerRight = _extract(containerBounds['right']);
    final double containerBottom = _extract(containerBounds['bottom']);
    final double rootLeft = _extract(rootBounds['left']);
    final double rootRight = _extract(rootBounds['right']);
    final double rootTop = _extract(rootBounds['top']);
    final double rootBottom = _extract(rootBounds['bottom']);

    double shift = 0;
    if (rootRight > containerRight) {
      shift = containerRight - rootRight;
      style?.left = '${left + shift}px';
    }
    if (rootLeft < containerLeft) {
      shift = containerLeft - rootLeft;
      style?.left = '${left + shift}px';
    }
    if (rootBottom > containerBottom) {
      final double height = rootBottom - rootTop;
      final double verticalShift = refBottom - refTop + height;
      style?.top = '${top - verticalShift}px';
      root.classes.add('ql-flip');
    }
    return shift;
  }

  void show() {
    root.classes.remove('ql-editing');
    root.classes.remove('ql-hidden');
  }

  double _extract(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return 0;
  }
}
