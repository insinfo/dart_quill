import 'dart:js_interop';

import 'package:web/web.dart' as web;

import '../platform/dom.dart';
import '../platform/html_dom.dart';

web.Element? _native(DomElement element) {
  if (element is! HtmlDomElement) return null;
  final node = element.node;
  if (!node.isA<web.Element>()) return null;
  return node as web.Element;
}

/// Computed `overflow-y` of [element] (`getComputedStyle(el).overflowY`).
///
/// Returns `null` when the element is not backed by a real DOM node.
String? computedOverflowY(DomElement element) {
  final native = _native(element);
  if (native == null) return null;
  try {
    return web.window.getComputedStyle(native).overflowY;
  } catch (_) {
    return null;
  }
}

/// Dispatches a bubbling event named [type] on [element].
///
/// Returns `false` when the element is not backed by a real DOM node.
bool dispatchDomEvent(DomElement element, String type) {
  final native = _native(element);
  if (native == null) return false;
  native.dispatchEvent(web.Event(type, web.EventInit(bubbles: true)));
  return true;
}
