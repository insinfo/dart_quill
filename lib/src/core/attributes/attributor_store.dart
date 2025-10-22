import '../../platform/dom.dart';

/// Naive attribute store that mirrors the behaviour used by block embeds.
class AttributorStore {
  final DomElement domNode;
  final Map<String, dynamic> _values = {};

  AttributorStore(this.domNode);

  Map<String, dynamic> values() => Map.unmodifiable(_values);

  void attribute(String name, dynamic value) {
    if (value == null || value == false) {
      _values.remove(name);
      domNode.removeAttribute(name);
      return;
    }
    _values[name] = value;
    domNode.setAttribute(name, value.toString());
  }
}
