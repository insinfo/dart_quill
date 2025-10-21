import '../blots/block.dart';
import '../blots/inline.dart';
import '../blots/text.dart';
import '../blots/break.dart';
import '../blots/cursor.dart';
import '../blots/container.dart';
import 'dart:html';

// Placeholder for Quill
class Quill {
  static void register(dynamic blot, [bool overwrite = false]) {}
}

class CodeBlockContainer extends Container {
  CodeBlockContainer(HtmlElement domNode) : super(domNode);

  static HtmlElement create(String value) {
    final domNode = HtmlElement.div();
    domNode.setAttribute('spellcheck', 'false');
    return domNode;
  }

  String code(int index, int length) {
    // Placeholder for children.map and domNode.innerText
    return children
        .map((child) => child.length() <= 1 ? '' : (child.domNode as HtmlElement).innerText)
        .join('\n')
        .substring(index, index + length);
  }

  String html(int index, int length) {
    // Placeholder for escapeText
    return '<pre>\n${escapeText(code(index, length))}\n</pre>';
  }

  static const String blotName = 'code-block-container';
  static const String className = 'ql-code-block-container';
  static const String tagName = 'DIV';
  static List<Type> allowedChildren = [CodeBlock]; // Placeholder for CodeBlock

  @override
  Blot clone() => CodeBlockContainer(domNode.clone(true) as HtmlElement);
}

class CodeBlock extends Block {
  CodeBlock(HtmlElement domNode) : super(domNode);

  static const String TAB = '  ';

  static void register() {
    Quill.register(CodeBlockContainer);
  }

  static const String blotName = 'code-block';
  static const String className = 'ql-code-block';
  static const String tagName = 'DIV';
  static Type requiredContainer = CodeBlockContainer;
  static List<Type> allowedChildren = [TextBlot, Break, Cursor];

  @override
  Blot clone() => CodeBlock(domNode.clone(true) as HtmlElement);
}

class Code extends Inline {
  Code(HtmlElement domNode) : super(domNode);

  static const String blotName = 'code';
  static const String tagName = 'CODE';

  @override
  Blot clone() => Code(domNode.clone(true) as HtmlElement);
}
