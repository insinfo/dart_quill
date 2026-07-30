import '../blots/abstract/blot.dart';
import '../blots/inline.dart';
import '../platform/dom.dart';
import '../platform/platform.dart';

class Italic extends InlineBlot {
  Italic(DomElement domNode) : super(domNode);

  static const String kBlotName = 'italic';
  static const List<String> kTagNames = ['EM', 'I'];
  static const int kScope = Scope.INLINE_BLOT;

  static Italic create([dynamic value]) {
    final node = domBindings.adapter.document.createElement(kTagNames.first);
    return Italic(node);
  }

  @override
  String get blotName => kBlotName;

  @override
  int get scope => kScope;

  @override
  Map<String, dynamic> formats() => {...super.formats(), kBlotName: true};

  @override
  void optimize([
    List<DomMutationRecord>? mutations,
    Map<String, dynamic>? context,
  ]) {
    // Parity italic.ts: `Italic extends Bold`, so this is Bold's optimize —
    // normalize `<i>` to `<em>`, nothing else. See the note in bold.dart on
    // why the sibling merge does NOT belong here.
    super.optimize(mutations, context);
    if (element.tagName != kTagNames.first) {
      replaceWith(kBlotName);
    }
  }

  @override
  void format(String name, dynamic value) {
    if (name == kBlotName && value == false) {
      unwrap();
      return;
    }
    super.format(name, value);
  }

  @override
  Italic clone() => Italic(element.cloneNode(deep: false));
}
