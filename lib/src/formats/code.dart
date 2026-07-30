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
    node.setAttribute('spellcheck', 'false');
    return CodeBlockContainer(node);
  }

  @override
  String get blotName => kBlotName;

  @override
  int get scope => kScope;

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
  static final List<Type> allowedChildren = [TextBlot, Break, Cursor];

  static void register() {
    Quill.register(CodeBlockContainer);
  }

  static CodeBlock create([dynamic value]) {
    final node = domBindings.adapter.document.createElement(kTagName);
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
