import '../platform/dom.dart';
import '../platform/platform.dart';
import 'abstract/blot.dart';

class Cursor extends EmbedBlot {
  Cursor(DomElement domNode)
      : _textNode = domBindings.adapter.document.createTextNode(_kContents),
        super(domNode) {
    element.classes.add(kClassName);
    element.append(_textNode);
  }

  static const String kBlotName = 'cursor';
  static const String kTagName = 'SPAN';
  static const String kClassName = 'ql-cursor';
  static const String _kContents = '\uFEFF';
  static const int kScope = Scope.INLINE_BLOT;

  final DomText _textNode;
  int _savedLength = 0;

  static Cursor create([dynamic value]) {
    final node = domBindings.adapter.document.createElement(kTagName);
    return Cursor(node);
  }

  @override
  String get blotName => kBlotName;

  @override
  int get scope => kScope;

  @override
  int length() => _savedLength;

  @override
  Cursor clone() {
    final cloneElement = element.cloneNode(deep: true);
    return Cursor(cloneElement);
  }

  @override
  dynamic value() => '';

  @override
  void format(String name, dynamic value) {
    if (_savedLength != 0) {
      super.format(name, value);
      return;
    }
    super.format(name, value);
  }

  void resetContents() {
    _savedLength = 0;
    _textNode.data = _kContents;
  }

  void saveLength(int length) {
    _savedLength = length;
  }
}