import 'package:dart_quill/src/core/emitter.dart';
import 'package:dart_quill/src/dependencies/dart_quill_delta/dart_quill_delta.dart';

import '../platform/dom.dart';
import '../platform/platform.dart';
import 'abstract/blot.dart';
import 'block.dart';
import 'break.dart';
import 'text.dart';

bool isLine(Blot blot) => blot is Block || blot is BlockEmbed;

abstract class UpdatableEmbed {
  void updateContent(dynamic change);
}

bool isUpdatable(Blot blot) => blot is UpdatableEmbed;

class Scroll extends ScrollBlot {
  Scroll(
    Registry registry,
    DomElement domNode, {
    required this.emitter,
  })  : _batch = null,
        super(registry, domNode) {
    element.classes.add(className);
    observer = domBindings.adapter.createMutationObserver(_handleMutations);
    observer?.observe(domNode,
        subtree: true, childList: true, characterData: true);
    build();
    optimize([], {});
    enable();
    element.addEventListener('dragstart', handleDragStart);
  }

  static const String kBlotName = 'scroll';
  static const String className = 'ql-editor';
  static const String tagName = 'DIV';
  static const int kScope = Scope.BLOCK_BLOT;

  final Emitter emitter;
  List<DomMutationRecord>? _batch;

  @override
  String get blotName => kBlotName;

  @override
  int get scope => kScope;

  @override
  Scroll clone() => throw UnsupportedError('Scroll cannot be cloned');

  void batchStart() {
    _batch ??= <DomMutationRecord>[];
  }

  void batchEnd() {
    final pending = _batch;
    if (pending == null) return;
    _batch = null;
    if (pending.isNotEmpty) {
      update(pending);
    }
  }

  void enable([bool enabled = true]) {
    element.setAttribute('contenteditable', enabled ? 'true' : 'false');
  }

  @override
  void deleteAt(int index, int length) {
    final firstEntry = line(index);
    final lastEntry = line(index + length);
    Blot? first = firstEntry.key;
    var offset = firstEntry.value;
    final last = lastEntry.key;

    if ((offset <= 0) && index > 0) {
      final previousEntry = line(index - 1);
      if (previousEntry.key != null) {
        first = previousEntry.key;
        offset = previousEntry.value + 1;
      }
    }

    super.deleteAt(index, length);

    if (first != null && last != null && first != last && offset > 0) {
      if (last is ParentBlot &&
          last.children.length == 1 &&
          last.children.first is Break) {
        last.remove();
        optimize([], {});
        return;
      }

      if (first is BlockEmbed || last is BlockEmbed) {
        optimize([], {});
        return;
      }

      Blot? ref;
      if (last is ParentBlot) {
        if (last.children.isNotEmpty && last.children.first is Break) {
          ref = null;
        } else if (last.children.isNotEmpty) {
          ref = last.children.first;
        }
      }

      if (first is ParentBlot && last is ParentBlot) {
        first.moveChildren(last, ref);
        first.remove();
      }
    }

    optimize([], {});
  }

  @override
  void formatAt(int index, int length, String name, dynamic value) {
    super.formatAt(index, length, name, value);
    optimize([], {});
  }

  @override
  void insertAt(int index, String value, [dynamic def]) {
    if (index >= length()) {
      if (def != null) {
        final definition = query(value, Scope.ANY);
        if (definition != null && definition.scope == Scope.BLOCK_BLOT) {
          final embed = create(value, def);
          insertBefore(embed, null);
          optimize([], {});
          return;
        }
      }

      final block = _appendBlock();
      final insertionIndex = block.length() - 1;
      if (def == null && value.endsWith('\n')) {
        block.insertAt(insertionIndex, value.substring(0, value.length - 1));
      } else {
        block.insertAt(insertionIndex, value, def);
      }
    } else {
      super.insertAt(index, value, def);
    }
    optimize([], {});
  }

  @override
  void insertBefore(Blot blot, Blot? ref) {
    if (blot.scope == Scope.INLINE_BLOT) {
      final wrapper = _createBlock();
      wrapper.insertBefore(
          blot, wrapper.lastChild); // place before trailing break
      super.insertBefore(wrapper, ref);
    } else {
      super.insertBefore(blot, ref);
    }
  }

  bool isEnabled() => element.getAttribute('contenteditable') == 'true';

  MapEntry<LeafBlot?, int> leaf(int index) {
    final segments = path(index, inclusive: false);
    if (segments.isEmpty) {
      return const MapEntry<LeafBlot?, int>(null, -1);
    }
    final entry = segments.last;
    final blot = entry.key;
    final offset = entry.value;
    return blot is LeafBlot ? MapEntry(blot, offset) : const MapEntry(null, -1);
  }

  MapEntry<Blot?, int> line(int index) {
    if (length() == 0) {
      return const MapEntry(null, -1);
    }
    final adjusted = index >= length() ? length() - 1 : index;
    return descendant(isLine, adjusted);
  }

  List<Blot> lines([int index = 0, int length = 0x7fffffff]) {
    final result = <Blot>[];
    var offset = 0;
    var remaining = length;
    for (final child in children) {
      final childLength = child.length();
      final end = offset + childLength;
      if (end <= index) {
        offset = end;
        continue;
      }
      if (isLine(child)) {
        result.add(child);
      } else if (child is ContainerBlot) {
        result.addAll(child.descendants<Blot>(predicate: isLine));
      }
      remaining -= childLength;
      if (remaining <= 0) {
        break;
      }
      offset = end;
    }
    return result;
  }

  @override
  void optimize([
    List<DomMutationRecord>? mutations,
    Map<String, dynamic>? context,
  ]) {
    if (_batch != null) return;
    super.optimize(mutations, context);
    if (children.isEmpty) {
      final block = _createBlock();
      appendChild(block);
    }
    final records = mutations ?? const <DomMutationRecord>[];
    final scope = context ?? <String, dynamic>{};
    if (records.isNotEmpty) {
      emitter.emit(EmitterEvents.SCROLL_OPTIMIZE, records, scope);
    }
  }

  @override
  List<MapEntry<Blot, int>> path(int index, {bool inclusive = false}) {
    final entries = super.path(index, inclusive: inclusive);
    return entries.length <= 1 ? entries : entries.sublist(1);
  }

  @override
  void remove() {
    throw UnsupportedError('Scroll cannot be removed');
  }

  @override
  void update([
    List<DomMutationRecord>? mutations,
    Map<String, dynamic>? context,
  ]) {
    if (_batch != null) {
      if (mutations != null) {
        _batch!.addAll(mutations);
      }
      return;
    }
    final records =
        mutations ?? observer?.takeRecords() ?? const <DomMutationRecord>[];
    final filtered = records.where((record) {
      final blot = find(record.target, bubble: true).key;
      return blot != null && !isUpdatable(blot);
    }).toList();
    if (filtered.isEmpty) {
      optimize([], context ?? {});
      return;
    }
    final source = context != null ? context['source'] : EmitterSource.USER;
    emitter.emit(EmitterEvents.SCROLL_BEFORE_UPDATE, source, filtered);
    emitter.emit(EmitterEvents.SCROLL_UPDATE, source, filtered);
  }

  void updateEmbedAt(int index, String key, dynamic change) {
    final result = descendant((blot) => blot is BlockEmbed, index);
    final blot = result.key;
    if (blot != null && blot.blotName == key && isUpdatable(blot)) {
      (blot as UpdatableEmbed).updateContent(change);
    }
  }

  void handleDragStart(DomEvent event) => event.preventDefault();

  List<Map<String, dynamic>> deltaToRenderBlocks(Delta delta) {
    final renderBlocks = <Map<String, dynamic>>[];
    var current = Delta();
    for (final op in delta.operations) {
      final insert = op.data;
      if (insert == null) continue;
      if (insert is String) {
        final parts = insert.split('\n');
        for (var i = 0; i < parts.length - 1; i++) {
          final text = parts[i];
          if (text.isNotEmpty) {
            current.insert(text, op.attributes);
          }
          renderBlocks.add({
            'type': 'block',
            'delta': current,
            'attributes': op.attributes ?? <String, dynamic>{},
          });
          current = Delta();
        }
        final remainder = parts.last;
        if (remainder.isNotEmpty) {
          current.insert(remainder, op.attributes);
        }
      } else if (insert is Map) {
        final key = insert.keys.first;
        if (key == null) continue;
        final value = insert[key];
        if (query(key, Scope.INLINE) != null) {
          current.push(op);
        } else {
          if (current.isNotEmpty) {
            renderBlocks.add({
              'type': 'block',
              'delta': current,
              'attributes': <String, dynamic>{},
            });
            current = Delta();
          }
          renderBlocks.add({
            'type': 'blockEmbed',
            'key': key,
            'value': value,
            'attributes': op.attributes ?? <String, dynamic>{},
          });
        }
      }
    }
    if (current.isNotEmpty) {
      renderBlocks.add({
        'type': 'block',
        'delta': current,
        'attributes': <String, dynamic>{},
      });
    }
    return renderBlocks;
  }

  ParentBlot createBlock(Map<String, dynamic> attributes, [Blot? refBlot]) {
    String? blockName;
    final formats = <String, dynamic>{};
    attributes.forEach((name, value) {
      if (query(name, Scope.BLOCK_BLOT) != null) {
        blockName = name;
      } else {
        formats[name] = value;
      }
    });

    final block = create(blockName ?? Block.kBlotName);
    insertBefore(block, refBlot);
    final blockLength = block.length();
    formats.forEach((name, value) {
      block.formatAt(0, blockLength, name, value);
    });
    return block as ParentBlot;
  }

  /// Builds the blot tree from pre-existing DOM children of the scroll root.
  /// Mirrors parchment's `ParentBlot.build()` performed at construction time.
  void build() {
    for (final node in List<DomNode>.from(element.childNodes)) {
      final blot = _blotFromDomNode(node);
      if (blot != null) {
        insertBefore(blot, null);
      }
    }
  }

  Blot? _blotFromDomNode(DomNode node) {
    if (node is DomText) {
      final trimmed = node.data.trim();
      if (trimmed.isEmpty && node.data.isNotEmpty) {
        // Whitespace between blocks; drop it to avoid phantom text blots.
        node.remove();
        return null;
      }
      return TextBlot(node);
    }

    if (node is DomElement) {
      final entry = registry.queryByTagName(node.tagName, scope: Scope.ANY) ??
          registry.queryByClassName(node.className ?? '', scope: Scope.ANY);
      final blotName = entry?.blotName ?? Block.kBlotName;
      final blot = create(blotName, node);
      if (blot is ParentBlot) {
        for (final child in List<DomNode>.from(node.childNodes)) {
          final childBlot = _blotFromDomNode(child);
          if (childBlot != null) {
            blot.insertBefore(childBlot, null);
          }
        }
      }
      return blot;
    }

    return null;
  }

  Block _appendBlock() {
    final block = _createBlock();
    appendChild(block);
    return block;
  }

  Block _createBlock() {
    final node = domBindings.adapter.document.createElement(Block.tagName);
    final block = Block(node);
    block.appendChild(Break.create());
    return block;
  }

  void _handleMutations(
    List<DomMutationRecord> records,
    DomMutationObserver observer,
  ) {
    final pending = _batch;
    if (pending != null) {
      pending.addAll(records);
    } else {
      update(records);
    }
  }

  String? findBlotName(DomNode node) {
    // Find the blot name for a given DOM node
    final blot = find(node, bubble: false).key;
    return blot?.blotName;
  }

  /// Mirrors `Editor.getFormat` in editor.ts: for a cursor the path at
  /// [index] supplies both line and leaf; for a range, formats common to all
  /// lines and leaves in the range are combined.
  Map<String, dynamic> getFormat(int index, [int length = 0]) {
    var lineBlots = <Blot>[];
    var leafBlots = <LeafBlot>[];
    if (length == 0) {
      for (final entry in path(index, inclusive: false)) {
        final blot = entry.key;
        if (blot is Block) {
          lineBlots.add(blot);
        } else if (blot is LeafBlot) {
          leafBlots.add(blot);
        }
      }
    } else {
      lineBlots = lines(index, length);
      leafBlots = descendantsAt<LeafBlot>(index, length);
    }

    Map<String, dynamic> mergeAll(List<Blot> blots) {
      if (blots.isEmpty) return <String, dynamic>{};
      var formats = bubbleFormats(blots.first);
      for (var i = 1; i < blots.length && formats.isNotEmpty; i++) {
        formats = _combineFormats(bubbleFormats(blots[i]), formats);
      }
      return formats;
    }

    return {...mergeAll(lineBlots), ...mergeAll(List<Blot>.from(leafBlots))};
  }

  /// Mirrors `combineFormats` in editor.ts: keeps only formats present in
  /// both maps; differing values accumulate into a list.
  Map<String, dynamic> _combineFormats(
      Map<String, dynamic> formats, Map<String, dynamic> combined) {
    final merged = <String, dynamic>{};
    combined.forEach((name, combinedValue) {
      final value = formats[name];
      if (value == null) return;
      if (combinedValue == value) {
        merged[name] = combinedValue;
      } else if (combinedValue is List) {
        if (!combinedValue.contains(value)) {
          merged[name] = [...combinedValue, value];
        } else {
          merged[name] = combinedValue;
        }
      } else {
        merged[name] = [combinedValue, value];
      }
    });
    return merged;
  }

  int? indexFromDomNode(DomNode? node, int nativeOffset) {
    if (node == null) {
      return null;
    }
    final result = find(node, bubble: true);
    final blot = result.key;
    if (blot == null) {
      return null;
    }

    var base = this.offset(blot);

    if (blot is LeafBlot) {
      final clamped = _clampOffset(nativeOffset, blot.length());
      return base + clamped;
    }

    if (node is DomElement) {
      final children = node.childNodes;
      final limit = _clampOffset(nativeOffset, children.length);
      for (var i = 0; i < limit; i++) {
        final child = children[i];
        base += _lengthOfDomNode(child);
      }
      return base;
    }

    return base;
  }

  int _lengthOfDomNode(DomNode node) {
    final result = find(node, bubble: true);
    final blot = result.key;
    if (blot == null) {
      return 0;
    }
    return blot.length();
  }

  int _clampOffset(int value, int max) {
    if (value <= 0) {
      return 0;
    }
    if (value >= max) {
      return max;
    }
    return value;
  }
}

void insertInlineContents(
  ParentBlot parent,
  int index,
  Delta inlineContents,
) {
  for (final op in inlineContents.operations) {
    final opLength = op.length;
    var attributes = op.attributes ?? <String, dynamic>{};
    final data = op.data;
    if (data is String) {
      parent.insertAt(index, data);
      final leafResult = parent.descendant((blot) => blot is LeafBlot, index);
      final leaf = leafResult.key;
      final formats = bubbleFormats(leaf);
      attributes =
          Delta.diffAttributes(formats, attributes) ?? <String, dynamic>{};
    } else if (data is Map) {
      final key = data.keys.first;
      if (key == null) continue;
      parent.insertAt(index, key, data[key]);
      final scroll = parent.scroll;
      final isInlineEmbed = scroll.query(key, Scope.INLINE) != null;
      if (isInlineEmbed) {
        final leafResult = parent.descendant((blot) => blot is LeafBlot, index);
        final leaf = leafResult.key;
        final formats = bubbleFormats(leaf);
        attributes =
            Delta.diffAttributes(formats, attributes) ?? <String, dynamic>{};
      }
    }

    if (opLength != null) {
      attributes.forEach((name, value) {
        parent.formatAt(index, opLength, name, value);
      });
      index += opLength;
    }
  }
}
