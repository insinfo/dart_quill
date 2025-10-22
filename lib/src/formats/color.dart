import '../blots/abstract/blot.dart';
import '../platform/dom.dart';
import 'abstract/attributor.dart';

final Map<String, dynamic> colorConfig = {
  'scope': Scope.INLINE,
};

class ColorAttributor extends StyleAttributor {
  ColorAttributor(String name, String styleName, Map<String, dynamic> options) 
      : super(name, styleName, options);

  @override
  String? value(DomElement domNode) {
    final raw = super.value(domNode) as String?;
    if (raw == null || !raw.startsWith('rgb(')) return raw;

    final numeric = raw
        .replaceFirst(RegExp(r'^[^\d]+'), '')
        .replaceFirst(RegExp(r'[^\d]+$'), '');

    final components = numeric.split(',');
    final hex = components.map((component) {
      final hexValue = int.parse(component.trim()).toRadixString(16).padLeft(2, '0');
      return hexValue;
    }).join('');

    return '#$hex';
  }
}

class ColorClass extends ClassAttributor {
  static final ColorClass instance = ColorClass._();
  
  ColorClass._() : super('color', 'ql-color', colorConfig);
}

class ColorStyle extends ColorAttributor {
  static final ColorStyle instance = ColorStyle._();
  
  ColorStyle._() : super('color', 'color', colorConfig);
}
