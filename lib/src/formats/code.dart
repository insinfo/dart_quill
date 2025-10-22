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
  static final List<Type> allowedChildren = [CodeBlock];

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
    return children
        .map((child) => child.length() <= 1 ? '' : child.value())
        .join('\n')
        .substring(index, index + length);
  }

  String html(int index, int length) {
    return '<pre>\n${escapeText(code(index, length))}\n</pre>';
  }

  @override
  CodeBlockContainer clone() => CodeBlockContainer(element.cloneNode(deep: true));
}

class CodeBlock extends Block {
  CodeBlock(DomElement domNode) : super(domNode);

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
  CodeBlock clone() => CodeBlock(element.cloneNode(deep: true));

  @override
  Map<String, dynamic> formats() => {kBlotName: true};
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
  Map<String, dynamic> formats() => {kBlotName: true};

  @override
  Code clone() => Code(element.cloneNode(deep: true));
}
