import '../blots/abstract/blot.dart';
import '../blots/inline.dart';
import '../platform/dom.dart';
import '../platform/platform.dart';

class Strike extends InlineBlot {
  Strike(DomElement domNode) : super(domNode);

  static const String kBlotName = 'strike';
  static const List<String> kTagNames = ['S', 'STRIKE'];
  static const int kScope = Scope.INLINE_BLOT;

  static Strike create([dynamic value]) {
    final node = domBindings.adapter.document.createElement(kTagNames.first);
    return Strike(node);
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
    // Parity strike.ts: `Strike extends Bold` — normalize `<strike>` to `<s>`
    // and nothing more. See the note in bold.dart on the sibling merge.
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
  Strike clone() => Strike(element.cloneNode(deep: false));
}
