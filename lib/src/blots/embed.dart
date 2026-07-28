import '../platform/dom.dart';
import '../platform/platform.dart';
import 'abstract/blot.dart';
import 'text.dart';

const String kGuardText = '﻿';

/// Native-selection context produced by [Embed.restore] (embed.ts:7-12).
class EmbedContextRange {
  const EmbedContextRange({
    required this.startNode,
    required this.startOffset,
    this.endNode,
    this.endOffset,
  });

  final DomNode startNode;
  final int startOffset;
  final DomNode? endNode;
  final int? endOffset;
}

/// Base class for inline embeds — port of quilljs blots/embed.ts.
///
/// The embed's own children move into a non-editable `contentNode` span,
/// framed by two zero-width no-break space text nodes (guards). Text the
/// browser types into a guard is pulled out into an adjacent TextBlot by
/// [restore], keeping the model consistent.
abstract class Embed extends EmbedBlot {
  Embed(DomElement domNode) : super(domNode) {
    final document = domBindings.adapter.document;
    contentNode = document.createElement('span');
    contentNode.setAttribute('contenteditable', 'false');
    for (final child in List<DomNode>.from(domNode.childNodes)) {
      contentNode.append(child);
    }
    leftGuard = document.createTextNode(kGuardText);
    rightGuard = document.createTextNode(kGuardText);
    domNode.append(leftGuard);
    domNode.append(contentNode);
    domNode.append(rightGuard);
  }

  late final DomElement contentNode;
  late final DomText leftGuard;
  late final DomText rightGuard;

  /// Parity embed.ts:33-37.
  @override
  int index(DomNode node, int offset) {
    if (identical(node, leftGuard)) return 0;
    if (identical(node, rightGuard)) return 1;
    return offset > 0 ? 1 : 0;
  }

  /// Parity embed.ts:39-77 — text typed into a guard becomes a TextBlot next
  /// to the embed; returns where the caret should be restored.
  EmbedContextRange? restore(DomText node) {
    EmbedContextRange? range;
    final text = node.data.split(kGuardText).join('');
    final document = domBindings.adapter.document;
    if (identical(node, leftGuard)) {
      final previous = prev;
      if (previous is TextBlot) {
        final prevLength = previous.length();
        previous.insertAt(prevLength, text);
        range = EmbedContextRange(
          startNode: previous.domNode,
          startOffset: prevLength + text.length,
        );
      } else {
        final textNode = document.createTextNode(text);
        parent?.insertBefore(TextBlot(textNode), this);
        range = EmbedContextRange(
          startNode: textNode,
          startOffset: text.length,
        );
      }
    } else if (identical(node, rightGuard)) {
      final following = next;
      if (following is TextBlot) {
        following.insertAt(0, text);
        range = EmbedContextRange(
          startNode: following.domNode,
          startOffset: text.length,
        );
      } else {
        final textNode = document.createTextNode(text);
        parent?.insertBefore(TextBlot(textNode), next);
        range = EmbedContextRange(
          startNode: textNode,
          startOffset: text.length,
        );
      }
    }
    node.data = kGuardText;
    return range;
  }

  @override
  void applyMutations(
    List<DomMutationRecord> mutations,
    Map<String, dynamic> context,
  ) =>
      update(mutations, context);

  /// Parity embed.ts:79-90 — invoked by the scroll update pipeline when a
  /// characterData mutation hits one of the guards.
  void update(List<DomMutationRecord> mutations, Map<String, dynamic> context) {
    for (final mutation in mutations) {
      if (mutation.type == 'characterData' &&
          (identical(mutation.target, leftGuard) ||
              identical(mutation.target, rightGuard))) {
        final range = restore(mutation.target as DomText);
        if (range != null) {
          context['range'] = range;
        }
      }
    }
  }
}
