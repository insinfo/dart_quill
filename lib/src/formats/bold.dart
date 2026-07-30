import '../blots/abstract/blot.dart';
import '../blots/inline.dart';
import '../platform/dom.dart';
import '../platform/platform.dart';

class Bold extends InlineBlot {
  Bold(DomElement domNode) : super(domNode);

  static const String kBlotName = 'bold';
  static const int kScope = Scope.INLINE_BLOT;
  static const List<String> kTagNames = ['STRONG', 'B'];

  static Bold create([dynamic value]) {
    if (value is DomElement) {
      return Bold(value);
    }
    final node = domBindings.adapter.document.createElement(kTagNames.first);
    return Bold(node);
  }

  @override
  String get blotName => kBlotName;

  @override
  int get scope => kScope;

  // Parity parchment `FormatBlot.formats()` (inline.ts:87-94): the attributor
  // store comes FIRST, then this blot's own format. Reporting only
  // `{bold: true}` hid every attributor living on the same element, with two
  // consequences: `bubbleFormats` dropped it from the delta, and `optimize`
  // considered two wrappers that differ only by an attributor identical — so
  // it merged them and DELETED the attribute. Two runs of text differing only
  // in `size`/`color` collapsed into one.
  @override
  Map<String, dynamic> formats() => {...super.formats(), kBlotName: true};

  @override
  void optimize([
    List<DomMutationRecord>? mutations,
    Map<String, dynamic>? context,
  ]) {
    // Parity bold.ts:15-20 — the ONLY thing this blot's optimize does is
    // normalize `<b>` to `<strong>`.
    //
    // It used to also merge with the previous/next sibling of the same type,
    // ignoring their formats. Merging belongs to `InlineBlot.optimize`, which
    // compares `formats()` first; merging blindly here DELETED the attributor
    // that made the two wrappers different (`<em class="ql-size-huge">` next
    // to a plain `<em>` lost the size).
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
  // Parity parchment shadow.ts:72-75 — `clone()` is ALWAYS shallow
  // (`cloneNode(false)`). A deep clone makes every `split`/`isolate` of this
  // wrapper duplicate its whole subtree into the new half: splitting
  // `<strong>0123</strong>` at 2 left `<strong>01</strong>` plus a tail
  // `<strong>012323</strong>`. The model kept reading the blots, so the delta
  // stayed correct and only the DOM was corrupted — invisible to any
  // delta-only assertion, fatal in the browser once the observer hydrates the
  // stray nodes back into the document.
  Bold clone() => Bold(element.cloneNode(deep: false));
}
