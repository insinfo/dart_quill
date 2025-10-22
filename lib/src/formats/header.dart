import '../blots/abstract/blot.dart';
import '../blots/block.dart';
import '../platform/dom.dart';
import '../platform/platform.dart';

class Header extends Block {
  Header(DomElement node) : super(node);

  static const String kBlotName = 'header';
  static const List<String> kTagNames = ['H1', 'H2', 'H3', 'H4', 'H5', 'H6'];
  static const int kScope = Scope.BLOCK_BLOT;

  static DomElement create(dynamic value) {
    final level = (value is int && value >= 1 && value <= 6) ? value : 1;
    return domBindings.adapter.document.createElement(kTagNames[level - 1]);
  }

  static int getLevel(DomElement node) {
    return kTagNames.indexOf(node.tagName.toUpperCase()) + 1;
  }

  @override
  String get blotName => kBlotName;

  @override
  int get scope => kScope;

  @override
  Map<String, dynamic> formats() => {kBlotName: getLevel(element)};

  @override
  Header clone() => Header(element.cloneNode(deep: true));
}
