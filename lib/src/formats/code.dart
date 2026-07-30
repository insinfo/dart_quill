import 'dart:convert';

import '../blots/abstract/blot.dart';
import '../blots/block.dart';
import '../blots/break.dart';
import '../blots/cursor.dart';
import '../blots/inline.dart';
import '../blots/text.dart';
import '../core/quill.dart';
import '../platform/dom.dart';
import '../platform/platform.dart';

String escapeText(String text) {
  return const HtmlEscape().convert(text);
}

class CodeBlockContainer extends ContainerBlot {
  CodeBlockContainer(DomElement domNode) : super(domNode);

  static const String kBlotName = 'code-block-container';
  static const String kClassName = 'ql-code-block-container';
  static const String kTagName = 'DIV';
  static const int kScope = Scope.BLOCK_BLOT;
  static CodeBlockContainer create([dynamic value]) {
    final node = domBindings.adapter.document.createElement(kTagName);
    // Parity parchment shadow.ts `create`: the base adds `this.className`
    // before the subclass touches the node. Skipping it produced a bare
    // `<div spellcheck="false">` — no `ql-code-block-container`, so the
    // stylesheet did not apply and re-loading the HTML no longer recognised
    // the block as code. Only the syntax variant (the default registry) was
    // adding it, which is why the goldens never caught this.
    node.classes.add(kClassName);
    node.setAttribute('spellcheck', 'false');
    return CodeBlockContainer(node);
  }

  @override
  String get blotName => kBlotName;

  @override
  int get scope => kScope;

  // Parity code.ts:48 — `CodeBlockContainer.allowedChildren = [CodeBlock]`.
  // Without it, a line whose code format was removed stayed INSIDE the
  // container: `<div class="ql-code-block-container"><h1>0123</h1></div>`.
  @override
  bool Function(Blot child)? get allowedChildren => (child) => child is CodeBlock;

  @override
  dynamic value() => children.map((child) => child.value()).toList();

  String code(int index, int length) {
    // Parity code.ts `code()` — the line's rendered text (`domNode.innerText`),
    // not `value()`, which for a Block is a list of child values. JS `.slice`
    // tolerates an end past the string; substring must be clamped to match.
    final joined = children
        .map((child) =>
            child.length() <= 1 ? '' : (child.domNode.textContent ?? ''))
        .join('\n');
    final start = index.clamp(0, joined.length);
    final end = (index + length).clamp(start, joined.length);
    return joined.substring(start, end);
  }

  @override
  String html([int index = 0, int length = 0]) {
    return '<pre>\n${escapeText(code(index, length))}\n</pre>';
  }

  @override
  CodeBlockContainer clone() =>
      CodeBlockContainer(element.cloneNode(deep: false));
}

class CodeBlock extends Block {
  CodeBlock(DomElement domNode) : super(domNode);

  /// Indentation unit used by Quill's code-block keyboard bindings.
  static const String TAB = '  ';

  static const String kBlotName = 'code-block';
  static const String kClassName = 'ql-code-block';
  static const String kTagName = 'DIV';
  static const int kScope = Scope.BLOCK_BLOT;
  static const Type requiredContainer = CodeBlockContainer;

  // Parity code.ts:50 — `CodeBlock.allowedChildren = [TextBlot, Break, Cursor]`
  // is what makes a line lose its inline formats when it becomes code.
  @override
  bool Function(Blot child)? get allowedChildren =>
      (child) => child is TextBlot || child is Break || child is Cursor;

  static void register() {
    Quill.register(CodeBlockContainer);
  }

  static CodeBlock create([dynamic value]) {
    final node = domBindings.adapter.document.createElement(kTagName);
    // See CodeBlockContainer.create — the className comes from the parchment
    // base `create`, and a code line without `ql-code-block` is invisible to
    // both the stylesheet and the next hydration.
    node.classes.add(kClassName);
    return CodeBlock(node);
  }

  @override
  String get blotName => kBlotName;

  @override
  int get scope => kScope;

  @override
  CodeBlock clone() => CodeBlock(element.cloneNode(deep: false));

  @override
  Map<String, dynamic> formats() => {...super.formats(), kBlotName: true};
}

class Code extends InlineBlot {
  Code(DomElement domNode) : super(domNode);

  static const String kBlotName = 'code';
  static const String kTagName = 'CODE';
  static const int kScope = Scope.INLINE_BLOT;

  static Code create([dynamic value]) {
    final node = domBindings.adapter.document.createElement(kTagName);
    return Code(node);
  }

  @override
  String get blotName => kBlotName;

  @override
  int get scope => kScope;

  @override
  Map<String, dynamic> formats() => {...super.formats(), kBlotName: true};

  @override
  Code clone() => Code(element.cloneNode(deep: false));
}
