import 'dart:js' as js;

import '../platform/dom.dart';

void renderFormula(String value, DomElement node) {
  if (!js.context.hasProperty('katex')) {
    node.text = value;
    return;
  }

  js.context['katex'].callMethod('render', [
    value,
    (node as dynamic).node,
    js.JsObject.jsify({
      'throwOnError': false,
      'errorColor': '#f00',
    })
  ]);
}
