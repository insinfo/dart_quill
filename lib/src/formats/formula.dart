import '../blots/abstract/blot.dart';
import '../blots/embed.dart';
import '../platform/dom.dart';
import '../platform/platform.dart';
import 'formula_renderer.dart';

class Formula extends Embed {
  Formula(DomElement node) : super(node);

  static const String kBlotName = 'formula';
  static const String kClassName = 'ql-formula';
  static const String kTagName = 'SPAN';
  static const int kScope = Scope.INLINE_BLOT;

  static DomElement create(String value) {
    final node = domBindings.adapter.document.createElement(kTagName);
    node.classes.add(kClassName);
    renderFormula(value, node);
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
