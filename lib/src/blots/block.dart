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
  void format(String name, dynamic value) {
    final definition = scroll.query(name, Scope.BLOCK);
    if (definition != null) {
      final currentFormats = formats();
      final currentValue = currentFormats[name];

      if ((value == null || value == false)) {
        if (blotName == Block.kBlotName) {
          return;
        }
        final replacement = scroll.create(Block.kBlotName) as Block;
        _replaceWithBlock(replacement);
        _cache.clear();
        return;
      }

      if (definition.blotName == blotName && currentValue == value) {
        return;
      }

      final replacement = scroll.create(name, value) as Block;
      _replaceWithBlock(replacement);
      _cache.clear();
      return;
    }

    final attribute = scroll.query(name, Scope.BLOCK_ATTRIBUTE);
    if (attribute != null) {
      // Block attributes (e.g., align, list) not yet supported in this port.
      // Placeholder to avoid silently failing future implementations.
      return;
    }

    super.format(name, value);
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
      final definition = scroll.query(value, Scope.ANY);
      if (definition != null) {
        if (definition.scope == Scope.BLOCK_BLOT) {
          final parentBlot = parent;
          if (parentBlot is ParentBlot) {
            final blockLength = length();
            final clampedIndex = math.max(0, math.min(index, blockLength));
            final isAfterBlock = index >= blockLength;
            final isLineEnd = !isAfterBlock &&
                clampedIndex >= math.max(0, blockLength - _newlineLength);
            final isStart = clampedIndex <= 0;

            Blot? ref;
            if (!isStart && !isAfterBlock && !isLineEnd) {
              ref = split(clampedIndex, force: true);
            } else if (isLineEnd) {
              ref = split(clampedIndex, force: true);
            } else if (isAfterBlock) {
              ref = next;
            } else {
              ref = this;
            }

            final embed = scroll.create(value, def);
            parentBlot.insertBefore(embed, ref);
            _cache.clear();
            return;
          }
        }

        if (definition.scope == Scope.INLINE_BLOT) {
          if (children.length == 1 && firstChild is Break) {
            final embed = scroll.create(value, def);
            insertBefore(embed, firstChild);
            _cache.clear();
            return;
          }
        }
      }

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
      if (last is Break) {
        last.remove();
      }
    }

    // Remove unmanaged DOM nodes (e.g., stray <br> appended directly)
    final managedNodes = children.map((child) => child.domNode).toSet();
    for (final node in List<DomNode>.from(element.childNodes)) {
      if (!managedNodes.contains(node) &&
          node is DomElement &&
          node.tagName.toUpperCase() == Break.tagName) {
        node.remove();
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

  void _replaceWithBlock(Block replacement) {
    final parentBlot = parent;
    if (parentBlot == null) {
      return;
    }

    parentBlot.insertBefore(replacement, next);
    moveChildren(replacement, null);

    if (replacement.children.isEmpty) {
      final defaultChild = replacement.createDefaultChild();
      if (defaultChild != null) {
        replacement.appendChild(defaultChild);
      }
    }

    remove();
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

  @override
  void insertAt(int index, String value, [dynamic def]) {
    if (def != null) {
      final parentBlot = parent;
      if (parentBlot is! ParentBlot) {
        return;
      }
      final embed = scroll.create(value, def);
      final ref = index <= 0 ? this : next;
      parentBlot.insertBefore(embed, ref);
      return;
    }

    final parentBlot = parent;
    if (parentBlot is! ParentBlot) {
      return;
    }

    final lines = value.split('\n');
    final text = lines.isNotEmpty ? lines.removeLast() : '';
    final ref = split(index);

    for (final line in lines) {
      final block = scroll.create(Block.kBlotName) as Block;
      block.insertAt(0, line);
      parentBlot.insertBefore(block, ref);
    }

    if (text.isNotEmpty) {
      final textBlot = scroll.create(TextBlot.kBlotName, text);
      parentBlot.insertBefore(textBlot, ref);
    }
  }
}
