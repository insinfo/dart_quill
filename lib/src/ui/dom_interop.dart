/// Small escape hatch for the two browser APIs the UI layer needs but the
/// platform DOM abstraction (`lib/src/platform/dom.dart`) does not expose:
/// `getComputedStyle` and `dispatchEvent`.
///
/// Mirrors the conditional-import strategy used by `platform/platform.dart`:
/// the web implementation talks to `package:web`, the stub is a no-op used on
/// the VM (and by the fake-DOM unit tests), where both APIs are unavailable.
export 'dom_interop_web.dart' if (dart.library.io) 'dom_interop_stub.dart';
