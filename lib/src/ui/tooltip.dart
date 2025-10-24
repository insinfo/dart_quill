import '../core/quill.dart';
import '../platform/dom.dart';

class Tooltip {
  Tooltip(this.quill, [DomElement? boundsContainer, String? template])
      : boundsContainer = boundsContainer ?? quill.root.ownerDocument.body,
        root = quill.addContainer('ql-tooltip') {
    if (template != null && template.isNotEmpty) {
      root.innerHTML = template;
    }
    hide();
    _installScrollHandler();
  }

  final Quill quill;
  final DomElement boundsContainer;
  final DomElement root;

  DomEventListener? _scrollListener;

  String get template => '';

  void _installScrollHandler() {
    final style = root.style as dynamic;
    style.marginTop = '${-quill.root.scrollTop}px';
    _scrollListener = (event) {
      final style = root.style as dynamic;
      style.marginTop = '${-quill.root.scrollTop}px';
    };
    quill.root.addEventListener('scroll', _scrollListener!);
  }

  void hide() {
    root.classes.add('ql-hidden');
  }

  double position(Map<String, dynamic> reference) {
    final style = root.style as dynamic;
    final double refLeft = _extract(reference['left']);
    final double refBottom = _extract(reference['bottom']);
    final double refWidth = _extract(reference['width']);

    final double rootWidth = root.offsetWidth.toDouble();
    final double containerWidth = boundsContainer.offsetWidth.toDouble();

    final double centeredLeft = refLeft + (refWidth / 2) - (rootWidth / 2);
    final double maxLeft = (containerWidth - rootWidth).clamp(0, double.infinity);
    final double clampedLeft = centeredLeft.clamp(0, maxLeft);

    final double top = refBottom + quill.root.scrollTop;

    style.left = '${clampedLeft}px';
    style.top = '${top}px';
    root.classes.remove('ql-flip');

    return clampedLeft - centeredLeft;
  }

  void show() {
    root.classes.remove('ql-hidden');
    root.classes.remove('ql-editing');
  }

  double _extract(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return 0;
  }
}
