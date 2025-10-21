import 'dart:html';
import '../blots/abstract/blot.dart';

abstract class Attributor {
  final String attrName;
  final String keyName;
  final Map<String, dynamic> config;

  Attributor(this.attrName, this.keyName, this.config);

  bool canAdd(HtmlElement domNode, dynamic value) => true;
  dynamic value(HtmlElement domNode) => domNode.getAttribute(keyName);
  void add(HtmlElement domNode, dynamic value) => domNode.setAttribute(keyName, value.toString());
  void remove(HtmlElement domNode) => domNode.removeAttribute(keyName);

  static List<String> keys(HtmlElement domNode) => [];
}

abstract class ClassAttributor extends Attributor {
  ClassAttributor(String attrName, String keyName, Map<String, dynamic> config) : super(attrName, keyName, config);

  @override
  bool canAdd(HtmlElement domNode, dynamic value) {
    return config['whitelist'] == null || (config['whitelist'] as List).contains(value);
  }

  @override
  dynamic value(HtmlElement domNode) {
    final classes = domNode.classes.where((name) => name.startsWith('$keyName-'));
    if (classes.isNotEmpty) {
      return classes.first.substring(keyName.length + 1);
    }
    return null;
  }

  @override
  void add(HtmlElement domNode, dynamic value) {
    remove(domNode);
    domNode.classes.add('$keyName-$value');
  }

  @override
  void remove(HtmlElement domNode) {
    domNode.classes.removeWhere((name) => name.startsWith('$keyName-'));
  }

  static List<String> keys(HtmlElement domNode) => domNode.classes.toList();
}

abstract class StyleAttributor extends Attributor {
  StyleAttributor(String attrName, String keyName, Map<String, dynamic> config) : super(attrName, keyName, config);

  @override
  bool canAdd(HtmlElement domNode, dynamic value) {
    return config['whitelist'] == null || (config['whitelist'] as List).contains(value);
  }

  @override
  dynamic value(HtmlElement domNode) {
    return domNode.style.getPropertyValue(keyName);
  }

  @override
  void add(HtmlElement domNode, dynamic value) {
    domNode.style.setProperty(keyName, value.toString());
  }

  @override
  void remove(HtmlElement domNode) {
    domNode.style.removeProperty(keyName);
  }

  static List<String> keys(HtmlElement domNode) => domNode.style.getPropertyNames().toList();
}

class ColorAttributor extends StyleAttributor {
  ColorAttributor(String attrName, String keyName, Map<String, dynamic> config) : super(attrName, keyName, config);

  @override
  dynamic value(HtmlElement domNode) {
    var value = super.value(domNode) as String;
    if (!value.startsWith('rgb(')) return value;
    value = value.replaceAll(RegExp(r'^[^\d]+'), '').replaceAll(RegExp(r'[^\d]+$'), '');
    final hex = value
        .split(',')
        .map((component) => int.parse(component.trim()).toRadixString(16).padLeft(2, '0'))
        .join('');
    return '#$hex';
  }
}

  StyleAttributor(String attrName, String keyName, Map<String, dynamic> config) : super(attrName, keyName, config);

  @override
  bool canAdd(HtmlElement domNode, dynamic value) {
    return config['whitelist'] == null || (config['whitelist'] as List).contains(value);
  }

  @override
  dynamic value(HtmlElement domNode) {
    return domNode.style.getPropertyValue(keyName);
  }

  @override
  void add(HtmlElement domNode, dynamic value) {
    domNode.style.setProperty(keyName, value.toString());
  }

  @override
  void remove(HtmlElement domNode) {
    domNode.style.removeProperty(keyName);
  }

  static List<String> keys(HtmlElement domNode) => domNode.style.getPropertyNames().toList();
}
