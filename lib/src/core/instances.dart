import '../platform/dom.dart';

class QuillInstances {
  final Map<DomNode, dynamic> _instances = <DomNode, dynamic>{};

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
    _instances.remove(node);
  }

  Iterable<T> values<T>() sync* {
    for (final value in _instances.values) {
      if (value is T) {
        yield value;
      }
    }
  }
}

final quillInstances = QuillInstances();
