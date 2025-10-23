import 'dart:math' as math;

import '../platform/dom.dart';
import 'package:dart_quill/src/dependencies/dart_quill_delta/dart_quill_delta.dart';
import 'abstract/blot.dart';
import 'break.dart';
import 'inline.dart';
import 'text.dart';

const _newlineLength = 1;

Delta blockDelta(Block block, {bool filter = true}) {
  final delta = Delta();
  for (final leaf in block.descendants<LeafBlot>()) {
    if (leaf.length() == 0) {
      continue;
    }
    delta.insert(leaf.value(), bubbleFormats(leaf, filter: filter));
  }
  delta.insert('\n', bubbleFormats(block, filter: filter));
  return delta;
}

Map<String, dynamic> bubbleFormats(
  Blot? blot, {
  Map<String, dynamic>? initial,
  bool filter = true,
}) {
  if (blot == null) {
    return initial ?? <String, dynamic>{};
  }

  final formats = Map<String, dynamic>.from(initial ?? {});
  formats.addAll(blot.formats());
  if (filter) {
    formats.remove('code-token');
  }

  final parent = blot.parent;
  if (parent == null || parent is ScrollBlot || parent.scope != blot.scope) {
    return formats;
  }
  return bubbleFormats(parent, initial: formats, filter: filter);
}

class Block extends BlockBlot {
  Block(DomElement domNode) : super(domNode);

  static const String kBlotName = 'block';
  static const String tagName = 'P';
  static const int kScope = Scope.BLOCK_BLOT;
  static const List<Type> allowedChildren = [
    Break,
    InlineBlot,
    EmbedBlot,
    TextBlot,
  ];

  final Map<String, dynamic> _cache = <String, dynamic>{};

  @override
  String get blotName => Block.kBlotName;

  @override
  int get scope => Block.kScope;

  Delta delta() {
    if (!_cache.containsKey('delta')) {
      _cache['delta'] = blockDelta(this);
    }
    return _cache['delta'] as Delta;
  }

  @override
  Block clone() => Block(element.cloneNode(deep: false));

  @override
  void deleteAt(int index, int length) {
    super.deleteAt(index, length);
    _cache.clear();
  }

  @override
  void formatAt(int index, int length, String name, dynamic value) {
    if (length <= 0) return;
    final definition = scroll.query(name, Scope.BLOCK);
    if (definition != null) {
      if (index + length == this.length()) {
        format(name, value);
      }
    } else {
      final maxLength = math.max(0, this.length() - index - 1).toInt();
      final bounded = math.min(length, maxLength).toInt();
      super.formatAt(index, bounded, name, value);
    }
    _cache.clear();
  }

  @override
  void insertAt(int index, String value, [dynamic def]) {
    if (def != null) {
      super.insertAt(index, value, def);
      _cache.clear();
      return;
    }
    if (value.isEmpty) return;

    // Remove break if it's the only child - it will be replaced by text
    if (children.length == 1 && firstChild is Break) {
      firstChild?.remove();
    }

    final lines = value.split('\n');
    final text = lines.removeAt(0);
    if (text.isNotEmpty) {
      // If block is now empty (after removing break), create a text node directly
      if (children.isEmpty) {
        final textNode = TextBlot.create(text);
        appendChild(textNode);
      } else if (index < length() - 1 || lastChild == null) {
        final maxIndex = math.max(length() - 1, 0).toInt();
        final targetIndex = math.min(index, maxIndex).toInt();
        super.insertAt(targetIndex, text);
      } else {
        final tail = lastChild;
        tail?.insertAt(tail.length(), text);
      }
      _cache.clear();
    }

    var current = this as Blot;
    var cursor = index + text.length;
    for (final line in lines) {
      if (current is! Block) break;
      final nextBlock = current.split(cursor, force: true);
      if (nextBlock != null) {
        current = nextBlock;
        current.insertAt(0, line);
        cursor = line.length;
      }
    }
  }

  @override
  void insertBefore(Blot blot, Blot? ref) {
    final head = firstChild;
    super.insertBefore(blot, ref);
    if (head is Break && head.parent == this) {
      head.remove();
    }
    _cache.clear();
  }

  @override
  int length() {
    if (_cache.containsKey('length')) {
      return _cache['length'] as int;
    }
    final len = super.length() + _newlineLength;
    _cache['length'] = len;
    return len;
  }

  @override
  void moveChildren(ParentBlot target, Blot? ref) {
    super.moveChildren(target, ref);
    _cache.clear();
  }

  @override
  void optimize([
    List<DomMutationRecord>? mutations,
    Map<String, dynamic>? context,
  ]) {
    super.optimize(mutations, context);
    _cache.clear();

    // Ensure empty blocks have a break element
    if (children.isEmpty) {
      final br = createDefaultChild();
      if (br != null) {
        appendChild(br);
      }
    }
    // Remove trailing break if block has other content
    else if (children.length > 1) {
      final last = children.last;
      if (last is Break && children.length > 1) {
        // Don't remove the break, it's needed for newline
      }
    }
  }

  @override
  void removeChild(Blot child) {
    super.removeChild(child);
    _cache.clear();
  }

  @override
  Blot? split(int index, {bool force = false}) {
    if (force && (index == 0 || index >= length() - _newlineLength)) {
      final cloneBlock = clone();
      if (index == 0) {
        parent?.insertBefore(cloneBlock, this);
        _cache.clear();
        return this;
      }
      parent?.insertBefore(cloneBlock, next);
      _cache.clear();
      return cloneBlock;
    }
    final result = super.split(index, force: force);
    _cache.clear();
    return result;
  }

  @override
  Blot? createDefaultChild([dynamic value]) {
    return Break.create();
  }
}

class BlockEmbed extends EmbedBlot {
  BlockEmbed(DomElement domNode) : super(domNode);

  static const String kBlotName = 'blockEmbed';
  static const int kScope = Scope.BLOCK_BLOT;

  @override
  String get blotName => BlockEmbed.kBlotName;

  @override
  int get scope => BlockEmbed.kScope;

  @override
  BlockEmbed clone() =>
      BlockEmbed((domNode as DomElement).cloneNode(deep: true));

  @override
  dynamic value() => {};
}
