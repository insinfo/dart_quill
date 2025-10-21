import 'dart:html';
import 'abstract/blot.dart';

const GUARD_TEXT = '\uFEFF';

class EmbedContextRange {
  Node startNode;
  int startOffset;
  Node? endNode;
  int? endOffset;

  EmbedContextRange({
    required this.startNode,
    required this.startOffset,
    this.endNode,
    this.endOffset,
  });
}

class Embed extends EmbedBlot {
  late HtmlSpanElement contentNode;
  late Text leftGuard;
  late Text rightGuard;
  late ScrollBlot scroll; // Assuming scroll is available

  Embed(ScrollBlot scroll, Node node) : super(node as HtmlElement) {
    this.scroll = scroll;
    contentNode = HtmlSpanElement();
    contentNode.setAttribute('contenteditable', 'false');
    node.childNodes.forEach((childNode) {
      contentNode.append(childNode);
    });
    leftGuard = Text(GUARD_TEXT);
    rightGuard = Text(GUARD_TEXT);
    domNode.append(leftGuard);
    domNode.append(contentNode);
    domNode.append(rightGuard);
  }

  @override
  int index(Node node, int offset) {
    if (node == leftGuard) return 0;
    if (node == rightGuard) return 1;
    return super.index(node, offset);
  }

  EmbedContextRange? restore(Text node) {
    EmbedContextRange? range;
    Text textNode;
    final text = node.data!.split(GUARD_TEXT).join('');
    if (node == leftGuard) {
      // Placeholder for prev being TextBlot
      if (prev is TextBlot) {
        final prevTextBlot = prev as TextBlot;
        final prevLength = prevTextBlot.length();
        prevTextBlot.insertAt(prevLength, text);
        range = EmbedContextRange(
          startNode: prevTextBlot.domNode,
          startOffset: prevLength + text.length,
        );
      } else {
        textNode = Text(text);
        parent!.insertBefore(scroll.create(textNode), this);
        range = EmbedContextRange(
          startNode: textNode,
          startOffset: text.length,
        );
      }
    } else if (node == rightGuard) {
      // Placeholder for next being TextBlot
      if (next is TextBlot) {
        final nextTextBlot = next as TextBlot;
        nextTextBlot.insertAt(0, text);
        range = EmbedContextRange(
          startNode: nextTextBlot.domNode,
          startOffset: text.length,
        );
      } else {
        textNode = Text(text);
        parent!.insertBefore(scroll.create(textNode), next);
        range = EmbedContextRange(
          startNode: textNode,
          startOffset: text.length,
        );
      }
    }
    node.data = GUARD_TEXT;
    return range;
  }

  @override
  void update(List<MutationRecord> mutations, Map<String, dynamic> context) {
    mutations.forEach((mutation) {
      if (
        mutation.type == 'characterData' &&
        (mutation.target == leftGuard || mutation.target == rightGuard)
      ) {
        final range = restore(mutation.target as Text);
        if (range != null) context['range'] = range;
      }
    });
  }

  @override
  Blot clone() => Embed(scroll, domNode.clone(true) as HtmlElement);

  @override
  void attach() {}

  @override
  void detach() {}

  @override
  Map<String, dynamic> formats() => {};

  @override
  void format(String name, value) {}

  @override
  void formatAt(int index, int length, String name, value) {}

  @override
  void insertAt(int index, String value, [def]) {}

  @override
  void deleteAt(int index, int length) {}

  @override
  dynamic value() => null;

  @override
  void optimize([context]) {}

  @override
  List<dynamic> path(int index, [bool inclusive = false]) => [];

  @override
  int offset(Blot? root) => 0;
}
