import '../platform/dom.dart';

class QuillInstances {
  final Expando<Object> _instances = Expando<Object>('quillInstances');

  T? get<T>(DomNode? node) {
    if (node == null) {
      return null;
    }
    final value = _instances[node];
    return value is T ? value : null;
  }

  void register<T>(DomNode node, T instance) {
    _instances[node] = instance;
  }

  void unregister(DomNode node) {
    _instances[node] = null;
  }
}

final quillInstances = QuillInstances();
