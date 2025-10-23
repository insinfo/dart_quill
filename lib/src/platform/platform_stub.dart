import 'dom.dart';

/// Stub adapter for non-web platforms (VM, etc)
/// This will throw an error if used, as it's meant to be replaced
/// by tests with a fake implementation
class _StubDomAdapter implements DomAdapter {
  @override
  DomDocument get document => throw UnsupportedError(
    'DOM operations are not supported on this platform. '
    'Use a FakeDomAdapter in tests or run on web platform.'
  );

  @override
  DomMutationObserver createMutationObserver(
    void Function(List<DomMutationRecord> records, DomMutationObserver observer) callback,
  ) {
    throw UnsupportedError('DOM operations are not supported on this platform.');
  }
}

/// Creates the platform-specific DOM adapter
/// On VM/IO platforms, returns a stub that throws errors
DomAdapter createPlatformAdapter() => _StubDomAdapter();
