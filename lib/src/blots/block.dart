import 'dart:html';
import 'dart:math' as math;
import 'package:quill_delta/quill_delta.dart';

import 'abstract/blot.dart';

// Placeholder classes for now, will be properly implemented later
class Break extends EmbedBlot {
  Break(HtmlElement domNode) : super(domNode);
  @override
  int length() => 0;
  @override
  dynamic value() => '';
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
  Blot clone() => Break(domNode.clone(true) as HtmlElement);
  @override
  void attach() {}
  @override
  void detach() {}
  @override
  void optimize([context]) {}
  @override
  void update([source]) {}
  @override
  List<dynamic> path(int index, [bool inclusive = false]) => [];
  @override
  int offset(Blot? root) => 0;
}

class Inline extends InlineBlot {
  Inline(HtmlElement domNode) : super(domNode);
  @override
  int length() => 0;
  @override
  dynamic value() => '';
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
  Blot clone() => Inline(domNode.clone(true) as HtmlElement);
  @override
  void attach() {}
  @override
  void detach() {}
  @override
  void optimize([context]) {}
  @override
  void update([source]) {}
  @override
  List<dynamic> path(int index, [bool inclusive = false]) => [];
  @override
  int offset(Blot? root) => 0;
}

class TextBlot extends LeafBlot {
  TextBlot(String text, HtmlElement domNode) : super(domNode);
  @override
  int length() => 0;
  @override
  dynamic value() => '';
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
  Blot clone() => TextBlot(text, domNode.clone(true) as HtmlElement);
  @override
  void attach() {}
  @override
  void detach() {}
  @override
  void optimize([context]) {}
  @override
  void update([source]) {}
  @override
  List<dynamic> path(int index, [bool inclusive = false]) => [];
  @override
  int offset(Blot? root) => 0;
}

const NEWLINE_LENGTH = 1;

Delta blockDelta(BlockBlot blot, [bool filter = true]) {
  // Implementação de descendents() é necessária em Parent
  return blot.descendants(LeafBlot)
      .fold(Delta(), (delta, leaf) {
        if (leaf.length() == 0) {
          return delta;
        }
        return delta.insert(leaf.value(), bubbleFormats(leaf, {}, filter));
      })
      .insert('\n', bubbleFormats(blot));
}

Map<String, dynamic> bubbleFormats(Blot? blot, [Map<String, dynamic> formats = const {}, bool filter = true]) {
  if (blot == null) return formats;
  
  var newFormats = Map<String, dynamic>.from(formats);
  
  // Assuming blot.formats is a method that returns a Map<String, dynamic>
  // and blot.statics is an object with a 'scope' property.
  // These need to be properly implemented in the abstract Blot classes.
  // For now, using dynamic access and checks.
  if (blot.formats is Function) {
    newFormats.addAll(blot.formats());
    if (filter) {
      newFormats.remove('code-token');
    }
  }

  // Placeholder for blot.parent.statics.blotName and blot.parent.statics.scope
  // These static properties need to be defined in the Blot hierarchy.
  // For now, using direct access which will require `statics` to be a Map or have these properties.
  if (blot.parent == null ||
      (blot.parent!.statics != null && blot.parent!.statics['blotName'] == 'scroll') ||
      (blot.parent!.statics != null && blot.parent!.statics['scope'] != blot.statics['scope'])) {
    return newFormats;
  }
  return bubbleFormats(blot.parent, newFormats, filter);
}

class Block extends BlockBlot {
  Map<String, dynamic> cache = {};
  late ScrollBlot scroll; // Assuming scroll is available

  Block(HtmlElement domNode) : super(domNode);

  Delta delta() {
    if (cache['delta'] == null) {
      cache['delta'] = blockDelta(this);
    }
    return cache['delta'] as Delta;
  }

  @override
  void deleteAt(int index, int length) {
    super.deleteAt(index, length);
    cache = {};
  }

  @override
  void formatAt(int index, int length, String name, dynamic value) {
    if (length <= 0) return;
    // Assuming scroll.query is implemented and returns a Blot type
    if (scroll.query(name, Scope.BLOCK) != null) {
      if (index + length == this.length()) {
        this.format(name, value);
      }
    } else {
      super.formatAt(
        index,
        math.min(length, this.length() - index - 1),
        name,
        value,
      );
    }
    this.cache = {};
  }

  @override
  void insertAt(int index, String value, [dynamic def]) {
    if (def != null) {
      super.insertAt(index, value, def);
      this.cache = {};
      return;
    }
    if (value.isEmpty) return;
    final lines = value.split('\n');
    final text = lines.removeAt(0);
    if (text.isNotEmpty) {
      if (index < this.length() - 1 || children.isEmpty) {
        super.insertAt(math.min(index, this.length() - 1), text);
      } else {
        children.last.insertAt(children.last.length(), text);
      }
      this.cache = {};
    }

    Blot block = this;
    lines.fold<int>(index + text.length, (lineIndex, line) {
      // Assuming split returns a Blot
      block = block.split(lineIndex, true)!;
      block.insertAt(0, line);
      return line.length;
    });
  }

  @override
  void insertBefore(Blot blot, Blot? ref) {
    final head = children.isNotEmpty ? children.first : null;
    super.insertBefore(blot, ref);
    if (head is Break) {
      head.remove();
    }
    this.cache = {};
  }

  @override
  int length() {
    if (cache['length'] == null) {
      cache['length'] = super.length() + NEWLINE_LENGTH;
    }
    return cache['length'] as int;
  }
  
  @override
  void moveChildren(Parent target, Blot? ref) {
    super.moveChildren(target, ref);
    this.cache = {};
  }

  @override
  void optimize([dynamic context]) {
    super.optimize(context);
    this.cache = {};
  }

  @override
  List<dynamic> path(int index, [bool inclusive = false]) {
    return super.path(index, true);
  }

  @override
  void removeChild(Blot child) {
    super.removeChild(child);
    this.cache = {};
  }

  @override
  Blot? split(int index, [bool force = false]) {
    if (force && (index == 0 || index >= this.length() - NEWLINE_LENGTH)) {
      final clone = this.clone();
      if (index == 0) {
        parent!.insertBefore(clone, this);
        return this;
      }
      parent!.insertBefore(clone, next);
      return clone;
    }
    final nextBlot = super.split(index, force);
    this.cache = {};
    return nextBlot;
  }
  
  static String blotName = 'block';
  static String tagName = 'P';
  static Type defaultChild = Break;
  static List<Type> allowedChildren = [Break, Inline, EmbedBlot, TextBlot];
}

class BlockEmbed extends EmbedBlot {
  late AttributorStore attributes;
  late HtmlElement domNode;
  late ScrollBlot scroll; // Assuming scroll is available

  BlockEmbed(HtmlElement domNode) : super(domNode);

  @override
  void attach() {
    super.attach();
    this.attributes = AttributorStore(this.domNode);
  }

  @override
  Delta delta() {
    return Delta()..insert(this.value(), {
      ...this.formats(),
      ...this.attributes.values(),
    });
  }

  @override
  void format(String name, dynamic value) {
    final attribute = scroll.query(name, Scope.BLOCK_ATTRIBUTE);
    if (attribute != null) {
      this.attributes.attribute(attribute, value);
    }
  }

  @override
  void formatAt(int index, int length, String name, dynamic value) {
    this.format(name, value);
  }

  @override
  void insertAt(int index, String value, [dynamic def]) {
    if (def != null) {
      super.insertAt(index, value, def);
      return;
    }
    final lines = value.split('\n');
    final text = lines.removeLast();
    final blocks = lines.map((line) {
      final block = scroll.create(Block.blotName);
      block.insertAt(0, line);
      return block;
    }).toList();
    final ref = split(index);
    blocks.forEach((block) {
      parent!.insertBefore(block, ref);
    });
    if (text.isNotEmpty) {
      parent!.insertBefore(scroll.create('text', text), ref);
    }
  }
  
  static const String scope = Scope.BLOCK_BLOT;
}