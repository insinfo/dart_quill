import 'dart:html';
import 'abstract/blot.dart';

// Placeholder for Selection class
class Selection {
  bool composing = false;
  dynamic getNativeRange() => null;
  void setNativeRange(Node? startNode, int? startOffset, [Node? endNode, int? endOffset, bool force = false]) {}
}

class Cursor extends EmbedBlot {
  static const String blotName = 'cursor';
  static const String className = 'ql-cursor';
  static const String tagName = 'span';
  static const String CONTENTS = '\uFEFF'; // Zero width no break space

  static dynamic value_() {
    return null;
  }

  late Selection selection;
  late Text textNode;
  int savedLength = 0;
  late ScrollBlot scroll; // Assuming scroll is available

  Cursor(ScrollBlot scroll, HtmlElement domNode, this.selection) : super(domNode) {
    this.scroll = scroll;
    this.textNode = Text(Cursor.CONTENTS);
    this.domNode.append(this.textNode);
  }

  @override
  void detach() {
    if (parent != null) parent!.removeChild(this);
  }

  @override
  void format(String name, dynamic value) {
    if (savedLength != 0) {
      super.format(name, value);
      return;
    }
    
    dynamic target = this;
    int index = 0;
    // Placeholder for statics.scope and Scope.BLOCK_BLOT
    while (target != null && target.statics['scope'] != Scope.BLOCK_BLOT) {
      index += target.offset(target.parent);
      target = target.parent;
    }
    if (target != null) {
      savedLength = Cursor.CONTENTS.length;
      target.optimize();
      target.formatAt(index, Cursor.CONTENTS.length, name, value);
      savedLength = 0;
    }
  }

  int index(Node node, int offset) {
    if (node == textNode) return 0;
    return super.index(node, offset);
  }

  @override
  int length() {
    return savedLength;
  }

  List<dynamic> position() {
    return [textNode, textNode.data!.length];
  }

  @override
  void remove() {
    super.remove();
    parent = null; // Setting parent to null as in JS
  }
  
  Map<String, dynamic>? restore() {
    if (selection.composing || parent == null) return null;
    final range = selection.getNativeRange();

    while (domNode.lastChild != null && domNode.lastChild != textNode) {
      domNode.parentNode!.insertBefore(domNode.lastChild!, domNode);
    }

    // Placeholder for prev and next being TextBlot
    final prevTextBlot = prev is TextBlot ? prev as TextBlot : null;
    final prevTextLength = prevTextBlot?.length() ?? 0;
    final nextTextBlot = next is TextBlot ? next as TextBlot : null;
    final nextText = nextTextBlot?.text ?? '';
    
    final newText = textNode.data!.split(Cursor.CONTENTS).join('');
    textNode.data = Cursor.CONTENTS;

    Blot? mergedTextBlot;
    if (prevTextBlot != null) {
      mergedTextBlot = prevTextBlot;
      if (newText.isNotEmpty || nextTextBlot != null) {
        prevTextBlot.insertAt(prevTextBlot.length(), newText + nextText);
        if (nextTextBlot != null) {
          nextTextBlot.remove();
        }
      }
    } else if (nextTextBlot != null) {
      mergedTextBlot = nextTextBlot;
      nextTextBlot.insertAt(0, newText);
    } else {
      final newTextNode = Text(newText);
      mergedTextBlot = scroll.create(newTextNode);
      parent!.insertBefore(mergedTextBlot, this);
    }

    remove();

    if (range != null) {
      int? remapOffset(Node node, int offset) {
        // Placeholder for domNode access on TextBlot
        if (prevTextBlot != null && node == prevTextBlot.domNode) {
          return offset;
        }
        if (node == textNode) {
          return prevTextLength + offset - 1;
        }
        if (nextTextBlot != null && node == nextTextBlot.domNode) {
          return prevTextLength + newText.length + offset;
        }
        return null;
      }

      final start = remapOffset(range['start']['node'], range['start']['offset']);
      final end = remapOffset(range['end']['node'], range['end']['offset']);

      if (start != null && end != null) {
        return {
          'startNode': mergedTextBlot!.domNode,
          'startOffset': start,
          'endNode': mergedTextBlot.domNode,
          'endOffset': end,
        };
      }
    }
    return null;
  }


  void update(List<MutationRecord> mutations, Map<String, dynamic> context) {
    if (mutations.any((mutation) =>
        mutation.type == 'characterData' && mutation.target == textNode)) {
      final range = restore();
      if (range != null) context['range'] = range;
    }
  }

  @override
  void optimize([dynamic context]) {
    super.optimize(context);

    var currentParent = parent;
    while (currentParent != null) {
      if (currentParent.domNode.tagName == 'A') {
        savedLength = Cursor.CONTENTS.length;
        // Placeholder for isolate and unwrap
        // currentParent.isolate(offset(currentParent), length()).unwrap();
        savedLength = 0;
        break;
      }
      currentParent = currentParent.parent;
    }
  }
  
  @override
  String value() {
    return '';
  }

  @override
  Blot clone() => Cursor(scroll, domNode.clone(true) as HtmlElement, selection);

  @override
  void attach() {}

  @override
  void update([source]) {}

  @override
  List<dynamic> path(int index, [bool inclusive = false]) => [];

  @override
  int offset(Blot? root) => 0;
}
