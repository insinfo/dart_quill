import '../platform/dom.dart';

/// Base class for UI pickers
abstract class Picker {
  final DomElement container;
  
  Picker(this.container);
  
  void close() {
    container.classes.remove('ql-expanded');
  }
  
  void update() {
    // Override in subclasses
  }
}

/// Color picker implementation
class ColorPicker extends Picker {
  ColorPicker(DomElement container, String? icon) : super(container);
}

/// Icon picker implementation
class IconPicker extends Picker {
  IconPicker(DomElement container, Map<String, String> icons) : super(container);
}
