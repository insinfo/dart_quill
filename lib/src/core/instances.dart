import '../platform/dom.dart';

/// The `WeakMap<Node, Quill>` of quill.ts, as an [Expando].
///
/// Keyed by [DomNode.identityKey], never by the wrapper: in a browser every
/// DOM access mints a new wrapper object, and an Expando is keyed by identity,
/// so `register(container)` followed by a lookup on the element returned by
/// `querySelectorAll('.ql-container')` found nothing at all. That is what
/// silently disabled the global DOM event bridge — `selectionchange` reached
/// the bridge, found no editor to route to, and a caret moved by the browser
/// never reached the model.
class QuillInstances {
  final Expando<Object> _instances = Expando<Object>('quillInstances');

  T? get<T>(DomNode? node) {
    if (node == null) {
      return null;
    }
    final value = _instances[node.identityKey];
    return value is T ? value : null;
  }

  void register<T>(DomNode node, T instance) {
    _instances[node.identityKey] = instance;
  }

  void unregister(DomNode node) {
    _instances[node.identityKey] = null;
  }
}

final quillInstances = QuillInstances();
