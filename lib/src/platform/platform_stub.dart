import 'dom.dart';

/// Stub adapter for non-web platforms (VM, etc)
/// This will throw an error if used, as it's meant to be replaced
/// by tests with a fake implementation
class _StubDomAdapter implements DomAdapter {
  @override
  DomDocument get document => throw UnsupportedError(
      'DOM operations are not supported on this platform. '
      'Use a FakeDomAdapter in tests or run on web platform.');

  @override
  DomMutationObserver createMutationObserver(
    void Function(List<DomMutationRecord> records, DomMutationObserver observer)
        callback,
  ) {
    throw UnsupportedError(
        'DOM operations are not supported on this platform.');
  }

  @override
  void focus(DomElement element) {
    throw UnsupportedError(
        'DOM operations are not supported on this platform.');
  }

  @override
  void blur(DomElement element) {
    throw UnsupportedError(
        'DOM operations are not supported on this platform.');
  }

  @override
  DomSelectionRange? getSelectionRange(DomElement root) => null;

  @override
  DomNativeRange? getNativeSelectionRange() => null;

  @override
  DomNativeRange? caretRangeFromPoint(num x, num y) => null;

  @override
  void downloadBytes(String filename, String mimeType, List<int> bytes) {}

  @override
  void setSelectionRange(DomElement root, int index, int length) {}

  @override
  void setSelectionByNodes(
      DomNode startNode, int startOffset, DomNode endNode, int endOffset) {}

  @override
  Map<String, dynamic>? getBounds(DomElement root, int index, int length) =>
      null;

  @override
  Map<String, dynamic>? getRangeBounds(
          DomNode startNode, int startOffset, DomNode endNode, int endOffset) =>
      null;

  @override
  Map<String, dynamic>? getElementBounds(DomElement element,
          {DomElement? relativeTo}) =>
      null;

  @override
  DomElement? getParentElement(DomElement element) =>
      element.parentNode is DomElement
          ? element.parentNode as DomElement
          : null;

  @override
  Map<String, double> getViewportBounds(DomDocument document) => {
        'width': document.documentElement.clientWidth.toDouble(),
        'height': document.documentElement.clientHeight.toDouble(),
      };

  @override
  String getComputedStyleProperty(DomElement element, String property) => '';

  @override
  Future<String?> readFileAsDataUrl(dynamic file) async => null;

  @override
  String? get userAgent => null;

  @override
  String? get platform => null;

  @override
  bool get supportsNativeSelection => false;

  @override
  bool hasFocus(DomElement root) => false;

  @override
  void clearNativeSelection() {}
}

/// Creates the platform-specific DOM adapter
/// On VM/IO platforms, returns a stub that throws errors
DomAdapter createPlatformAdapter() => _StubDomAdapter();
