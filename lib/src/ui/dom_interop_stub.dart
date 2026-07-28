import '../platform/dom.dart';

/// Computed `overflow-y` of [element].
///
/// Returns `null` when the platform adapter has no computed-style API (VM /
/// fake DOM); callers must treat `null` as "unknown", not as a value.
String? computedOverflowY(DomElement element) => null;

/// Dispatches a bubbling event named [type] on [element].
///
/// Returns `false` when the platform adapter cannot dispatch events, so the
/// caller can fall back to invoking its own listeners directly.
bool dispatchDomEvent(DomElement element, String type) => false;
