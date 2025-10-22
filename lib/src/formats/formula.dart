import 'dart:js' as js;

import '../blots/abstract/blot.dart';
import '../blots/embed.dart';
import '../platform/dom.dart';
import '../platform/platform.dart';

class Formula extends Embed {
  Formula(DomElement node) : super(node);

  static const String kBlotName = 'formula';
  static const String kClassName = 'ql-formula';
  static const String kTagName = 'SPAN';
  static const int kScope = Scope.INLINE_BLOT;

  static DomElement create(String value) {
    // Verificar se KaTeX está disponível
    if (!js.context.hasProperty('katex')) {
      throw Exception('Formula module requires KaTeX.');
    }
    
    final node = domBindings.adapter.document.createElement(kTagName);
    node.classes.add(kClassName);
    
    // Renderizar fórmula usando KaTeX
    js.context['katex'].callMethod('render', [
      value,
      node,
      js.JsObject.jsify({
        'throwOnError': false,
        'errorColor': '#f00',
      })
    ]);
    node.setAttribute('data-value', value);
    
    return node;
  }

  static String? getValue(DomElement node) {
    return node.getAttribute('data-value');
  }

  String html() {
    final formula = getValue(element);
    return '<span>\$\$${formula ?? ''}\$\$</span>';
  }

  @override
  String get blotName => kBlotName;

  @override
  int get scope => kScope;

  @override
  Formula clone() => Formula(element.cloneNode(deep: true));

  @override
  void optimize([
    List<DomMutationRecord>? mutations,
    Map<String, dynamic>? context,
  ]) {}

  @override
  Map<String, dynamic> formats() => {kBlotName: getValue(element)};

  @override
  dynamic value() => getValue(element);
}
