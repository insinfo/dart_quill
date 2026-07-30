import '../../platform/dom.dart';

// Scope bit constants duplicated from blots/abstract/blot.dart to avoid a
// layering cycle (Registry imports this file).
const int _kScopeInline = 0x0002;
const int _kScopeBlock = 0x0004;
const int _kScopeAttribute = 0x0100;

abstract class Attributor {
  final String attrName;
  final String keyName;
  final Map<String, dynamic> config;

  Attributor(this.attrName, this.keyName, this.config);

  /// Mirrors parchment's Attributor scope resolution: the level bits from the
  /// config combined with the ATTRIBUTE type bit.
  int get scope {
    final configScope = config['scope'];
    if (configScope is int) {
      return (configScope & (_kScopeInline | _kScopeBlock)) | _kScopeAttribute;
    }
    return _kScopeAttribute;
  }

  /// Parity attributor.ts:40-49 — whitelist check with quote stripping for
  /// string values (e.g. font-family: "Arial" matches whitelist 'Arial').
  bool canAdd(DomElement domNode, dynamic value) {
    final whitelist = config['whitelist'];
    if (whitelist is! List) return true;
    if (value is String) {
      return whitelist.contains(value.replaceAll(RegExp('["\']'), ''));
    }
    return whitelist.contains(value);
  }

  dynamic value(DomElement domNode) => domNode.getAttribute(keyName);
  bool add(DomElement domNode, dynamic value) {
    if (!canAdd(domNode, value)) return false;
    domNode.setAttribute(keyName, value.toString());
    return true;
  }

  void remove(DomElement domNode) => domNode.removeAttribute(keyName);

  static List<String> keys(DomElement domNode) => domNode.attributeNames;
}

/// Per-element store of applied attributors, mirroring parchment's
/// `AttributorStore`. Built lazily because Dart blots only gain access to the
/// registry once attached to a scroll.
class AttributorStore {
  AttributorStore(this.domNode);

  final DomElement domNode;
  final Map<String, Attributor> _attributes = {};
  bool _built = false;

  void attribute(Attributor attribute, dynamic value) {
    if (value != null && value != false) {
      if (attribute.add(domNode, value)) {
        if (attribute.value(domNode) != null) {
          _attributes[attribute.attrName] = attribute;
        } else {
          _attributes.remove(attribute.attrName);
        }
      }
    } else {
      attribute.remove(domNode);
      _attributes.remove(attribute.attrName);
    }
  }

  /// Rebuilds the store from the element's attributes/classes/styles,
  /// resolving each key through [queryAttributor]
  /// (name → Attributor at ATTRIBUTE scope).
  void build(Attributor? Function(String name) queryAttributor) {
    _attributes.clear();
    _built = true;
    final names = <String>[
      ...Attributor.keys(domNode),
      ...ClassAttributor.keys(domNode),
      ...StyleAttributor.keys(domNode),
    ];
    for (final name in names) {
      final attr = queryAttributor(name);
      if (attr != null) {
        _attributes[attr.attrName] = attr;
      }
    }
  }

  void ensureBuilt(Attributor? Function(String name) queryAttributor) {
    if (!_built) {
      build(queryAttributor);
    }
  }

  void copy(void Function(String name, dynamic value) format) {
    for (final entry in _attributes.entries) {
      format(entry.key, entry.value.value(domNode));
    }
  }

  /// Parity parchment `AttributorStore.move(target)`: transfer every
  /// attributor to a replacement/wrapper and clear it from this element.
  void move(void Function(String name, dynamic value) format) {
    copy(format);
    for (final attribute in _attributes.values) {
      attribute.remove(domNode);
    }
    _attributes.clear();
  }

  Map<String, dynamic> values() {
    final result = <String, dynamic>{};
    _attributes.forEach((name, attribute) {
      final value = attribute.value(domNode);
      if (value != null) {
        result[name] = value;
      }
    });
    return result;
  }
}

abstract class ClassAttributor extends Attributor {
  ClassAttributor(String attrName, String keyName, Map<String, dynamic> config)
      : super(attrName, keyName, config);

  @override
  dynamic value(DomElement domNode) {
    final classes =
        domNode.classes.values.where((name) => name.startsWith('$keyName-'));
    if (classes.isNotEmpty) {
      return classes.first.substring(keyName.length + 1);
    }
    return null;
  }

  @override
  bool add(DomElement domNode, dynamic value) {
    if (!canAdd(domNode, value)) return false;
    remove(domNode);
    domNode.classes.add('$keyName-$value');
    return true;
  }

  @override
  void remove(DomElement domNode) {
    final toRemove = domNode.classes.values
        .where((name) => name.startsWith('$keyName-'))
        .toList();
    for (final cls in toRemove) {
      domNode.classes.remove(cls);
    }
    // Parity class.ts:31-33 — drop the attribute entirely when empty.
    if (domNode.classes.values.isEmpty) {
      domNode.removeAttribute('class');
    }
  }

  /// Parity class.ts:11-15 — each class name is reduced to its attributor
  /// keyName by dropping the trailing value segment
  /// ("ql-align-center" → "ql-align"), so AttributorStore.build can
  /// rediscover class attributors from pre-existing HTML.
  static List<String> keys(DomElement domNode) {
    return (domNode.getAttribute('class') ?? '')
        .split(RegExp(r'\s+'))
        .where((name) => name.isNotEmpty)
        .map((name) {
      final parts = name.split('-');
      return parts.sublist(0, parts.length - 1).join('-');
    }).toList();
  }
}

abstract class StyleAttributor extends Attributor {
  StyleAttributor(String attrName, String keyName, Map<String, dynamic> config)
      : super(attrName, keyName, config);

  @override
  dynamic value(DomElement domNode) {
    final styles = _parseInlineStyles(domNode);
    return styles[keyName];
  }

  @override
  bool add(DomElement domNode, dynamic value) {
    if (!canAdd(domNode, value)) return false;
    final styles = _parseInlineStyles(domNode);
    styles[keyName] = value.toString();
    _writeInlineStyles(domNode, styles);
    return true;
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
    // Parchment writes through the CSSOM (`node.style[prop] = value`,
    // style.ts:8-11), and the browser re-serializes the attribute as cssText:
    // hex colors become `rgb(r, g, b)` and every declaration is terminated
    // with `;`. This port writes the attribute directly, so it reproduces
    // that serialization here — the semantic HTML goldens recorded from real
    // Chrome depend on it, and it keeps both platforms byte-identical.
    final buffer = StringBuffer();
    styles.forEach((key, value) {
      if (buffer.isNotEmpty) buffer.write(' ');
      buffer.write('$key: ${_normalizeCssValue(value)};');
    });
    domNode.setAttribute('style', buffer.toString());
  }

  static String _normalizeCssValue(String value) {
    return value.replaceAllMapped(
      RegExp(r'#([0-9a-fA-F]{6}|[0-9a-fA-F]{3})\b'),
      (match) {
        var hex = match[1]!;
        if (hex.length == 3) {
          hex = hex.split('').map((c) => '$c$c').join();
        }
        final r = int.parse(hex.substring(0, 2), radix: 16);
        final g = int.parse(hex.substring(2, 4), radix: 16);
        final b = int.parse(hex.substring(4, 6), radix: 16);
        return 'rgb($r, $g, $b)';
      },
    );
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
    final numeric = raw.replaceAll(RegExp(r'[^\d,]'), '');
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
