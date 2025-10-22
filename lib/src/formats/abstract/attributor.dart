import '../../platform/dom.dart';

abstract class Attributor {
  final String attrName;
  final String keyName;
  final Map<String, dynamic> config;

  Attributor(this.attrName, this.keyName, this.config);

  bool canAdd(DomElement domNode, dynamic value) => true;
  dynamic value(DomElement domNode) => domNode.getAttribute(keyName);
  void add(DomElement domNode, dynamic value) => domNode.setAttribute(keyName, value.toString());
  void remove(DomElement domNode) => domNode.removeAttribute(keyName);

  static List<String> keys(DomElement domNode) => [];
}

abstract class ClassAttributor extends Attributor {
  ClassAttributor(String attrName, String keyName, Map<String, dynamic> config) : super(attrName, keyName, config);

  @override
  bool canAdd(DomElement domNode, dynamic value) {
    return config['whitelist'] == null || (config['whitelist'] as List).contains(value);
  }

  @override
  dynamic value(DomElement domNode) {
    final classes = domNode.classes.values.where((name) => name.startsWith('$keyName-'));
    if (classes.isNotEmpty) {
      return classes.first.substring(keyName.length + 1);
    }
    return null;
  }

  @override
  void add(DomElement domNode, dynamic value) {
    remove(domNode);
    domNode.classes.add('$keyName-$value');
  }

  @override
  void remove(DomElement domNode) {
    final toRemove = domNode.classes.values
        .where((name) => name.startsWith('$keyName-'))
        .toList();
    for (final cls in toRemove) {
      domNode.classes.remove(cls);
    }
  }

  static List<String> keys(DomElement domNode) => domNode.classes.values.toList();
}

abstract class StyleAttributor extends Attributor {
  StyleAttributor(String attrName, String keyName, Map<String, dynamic> config) : super(attrName, keyName, config);

  @override
  bool canAdd(DomElement domNode, dynamic value) {
    return config['whitelist'] == null || (config['whitelist'] as List).contains(value);
  }

  @override
  dynamic value(DomElement domNode) {
    final styles = _parseInlineStyles(domNode);
    return styles[keyName];
  }

  @override
  void add(DomElement domNode, dynamic value) {
    final styles = _parseInlineStyles(domNode);
    styles[keyName] = value.toString();
    _writeInlineStyles(domNode, styles);
  }

  @override
  void remove(DomElement domNode) {
    final styles = _parseInlineStyles(domNode);
    styles.remove(keyName);
    _writeInlineStyles(domNode, styles);
  }

  static List<String> keys(DomElement domNode) {
    // getPropertyNames is not a standard method, so we'll have to do a workaround
    final style = domNode.getAttribute('style') ?? '';
    return style
        .split(';')
        .map((part) => part.split(':').first.trim())
        .where((key) => key.isNotEmpty)
        .toList();
  }

  Map<String, String> _parseInlineStyles(DomElement domNode) {
    final style = domNode.getAttribute('style');
    if (style == null || style.trim().isEmpty) return {};
    final entries = <String, String>{};
    for (final declaration in style.split(';')) {
      final parts = declaration.split(':');
      if (parts.length != 2) continue;
      final key = parts[0].trim();
      final value = parts[1].trim();
      if (key.isNotEmpty) {
        entries[key] = value;
      }
    }
    return entries;
  }

  void _writeInlineStyles(DomElement domNode, Map<String, String> styles) {
    if (styles.isEmpty) {
      domNode.removeAttribute('style');
      return;
    }
    final buffer = StringBuffer();
    styles.forEach((key, value) {
      if (buffer.isNotEmpty) buffer.write('; ');
      buffer.write('$key: $value');
    });
    domNode.setAttribute('style', buffer.toString());
  }
}

/// Specialized style attributor for color handling.
abstract class ColorAttributor extends StyleAttributor {
  ColorAttributor(String attrName, String keyName, Map<String, dynamic> config)
      : super(attrName, keyName, config);

  @override
  dynamic value(DomElement domNode) {
    final raw = super.value(domNode) as String?;
    if (raw == null || !raw.startsWith('rgb(')) return raw;

    // Convert rgb(r, g, b) to hex #rrggbb
    final numeric = raw
        .replaceAll(RegExp(r'[^\d,]'), '');
    final components = numeric.split(',');
    if (components.length != 3) return raw;

    try {
      final hex = components.map((component) {
        final value = int.parse(component.trim());
        return value.toRadixString(16).padLeft(2, '0');
      }).join('');
      return '#$hex';
    } catch (e) {
      return raw;
    }
  }
}
