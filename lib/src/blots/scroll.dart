import 'dart:math' as math;

import 'package:dart_quill/src/core/emitter.dart';
import 'package:dart_quill/src/delta/delta.dart';

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
    // Parchment's OBSERVER_CONFIG also carries `attributes: true`; see G12 in
    // doc/INVENTARIO_E_PLANO_FINALIZACAO.md.
    //
    // Measured again 2026-07-30, after the faithful `Editor.update` (G13.6)
    // and the SCROLL_UPDATE listener (G13.8): the document no longer
    // collapses, but the *selection source* flips. An attribute record on the
    // root (`ql-blank` toggling is one) makes selection.ts' `triggeredByTyping`
    // true, so the scroll-driven `update(SILENT)` wins the race against the
    // `selectionchange`-driven `update(USER)` — the second finds the range
    // unchanged and emits nothing. SELECTION_CHANGE then arrives as `silent`,
    // History ignores it, and undo restores the wrong caret.
    //
    // Left off until the characterData/attribute branch of `Editor.update`
    // (the one that reads MutationRecords) is ported and the pipeline can tell
    // an attribute write apart from typing. Direct attribute writes keep
    // asking for `quill.update()` explicitly meanwhile — the checklist toggle
    // is the one place upstream relies on this and the port cannot yet.
    observer?.observe(
      domNode,
      subtree: true,
      childList: true,
      characterData: true,
      characterDataOldValue: true,
    );
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

  /// Parity scroll.ts:79-96.
  ///
  /// The line the deletion starts in absorbs the remainder of the line it ends
  /// in, and then disappears. Two invented branches used to live here — one
  /// re-resolved `first`/`offset` from `line(index - 1)` when the offset was 0,
  /// and one removed `last` outright when it held a lone Break. Together they
  /// swallowed whole lines: deleting one newline in `'code\n\n\n\n'` left
  /// `'code\n'`, and `deleteText` could not cross a block boundary at all.
  @override
  void deleteAt(int index, int length) {
    final first = line(index).key;
    final offset = line(index).value;
    final last = line(index + length).key;

    _scrollDeleteAt(index, length);

    if (last != null && first != null && first != last && offset > 0) {
      if (first is BlockEmbed || last is BlockEmbed) {
        optimize([], {});
        return;
      }
      if (first is ParentBlot && last is ParentBlot) {
        final head = last.children.isEmpty ? null : last.children.first;
        final ref = head is Break ? null : head;
        first.moveChildren(last, ref);
        first.remove();
      }
    }

    optimize([], {});
  }

  /// Parity parchment `ScrollBlot.deleteAt` (scroll.ts:80-89), the level the
  /// Quill `Scroll.deleteAt` above delegates to.
  ///
  /// Two things the generic `ParentBlot.deleteAt` cannot do: drain pending
  /// mutations first, and handle "delete everything" by removing the children
  /// — the generic path would call `remove()` on the scroll itself, which is a
  /// deliberate no-op, so `setContents` would silently keep the old document.
  void _scrollDeleteAt(int index, int length) {
    update();
    if (index == 0 && length == this.length()) {
      for (final child in List<Blot>.from(children)) {
        child.remove();
      }
      return;
    }
    super.deleteAt(index, length);
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

  /// Parity scroll.ts:222-227 — only the index that lands exactly ON the end
  /// of the document falls back to the previous one; anything past it has no
  /// line at all.
  ///
  /// The port used to CLAMP every out-of-range index to the last line, so
  /// `removeFormat(0, tooLong)` computed a suffix from a line that does not
  /// intersect the range and appended a spurious empty paragraph.
  MapEntry<Blot?, int> line(int index) {
    if (index == length()) {
      return line(index - 1);
    }
    return descendant(isLine, index);
  }

  List<Blot> lines([int index = 0, int length = 0x7fffffff]) {
    // Parity scroll.ts:234-257 — recurse into containers respecting the
    // range (the previous version returned ALL of a container's lines even
    // when the range covered only part of it, so formatLine could format
    // lines outside the selection inside lists/tables).
    List<Blot> getLines(ParentBlot blot, int blotIndex, int blotLength) {
      final result = <Blot>[];
      var lengthLeft = blotLength;
      var offset = 0;
      for (final child in blot.children) {
        final childLength = child.length();
        final end = offset + childLength;
        if (end > blotIndex && offset < blotIndex + blotLength) {
          final childIndex = math.max(0, blotIndex - offset);
          final visited = (math.min(end, blotIndex + blotLength) -
                  math.max(offset, blotIndex))
              .toInt();
          if (isLine(child)) {
            result.add(child);
          } else if (child is ContainerBlot) {
            result.addAll(getLines(child, childIndex, lengthLeft));
          }
          lengthLeft -= visited;
        }
        offset = end;
        if (offset >= blotIndex + blotLength) {
          break;
        }
      }
      return result;
    }

    return getLines(this, index, length);
  }

  static const int _kMaxOptimizeIterations = 100;

  @override
  void optimize([
    List<DomMutationRecord>? mutations,
    Map<String, dynamic>? context,
  ]) {
    if (_batch != null) return;
    final scope = context ?? <String, dynamic>{};
    final records =
        List<DomMutationRecord>.from(mutations ?? const <DomMutationRecord>[]);

    // Parity parchment scroll.ts:106-181 — converge: each optimize pass may
    // mutate the DOM (merges, unwraps, requiredContainer wrapping); drain
    // the observer and re-run until quiescent, with a hard iteration cap.
    var remaining = _kMaxOptimizeIterations;
    while (true) {
      final versionBefore = treeVersion;
      super.optimize(mutations, scope);
      if (children.isEmpty) {
        final block = _createBlock();
        appendChild(block);
      }
      final produced = observer?.takeRecords() ?? const <DomMutationRecord>[];
      records.addAll(produced);
      // Off-browser there is no observer to drain, so the structural changes a
      // pass makes (requiredContainer wrapping, sibling merges) are detected
      // through the tree version instead.
      if (produced.isEmpty && treeVersion == versionBefore) break;
      remaining -= 1;
      if (remaining <= 0) {
        throw StateError('[Parchment] Maximum optimize iterations exceeded');
      }
    }

    if (records.isNotEmpty) {
      emitter.emit(EmitterEvents.SCROLL_OPTIMIZE, records, scope);
    }
  }

  /// Parity scroll.ts:67-69 — blots signal their own mount so modules
  /// (Syntax's language `<select>`) can attach UI to them.
  void emitMount(Blot blot) {
    emitter.emit(EmitterEvents.SCROLL_BLOT_MOUNT, blot);
  }

  /// Parity scroll.ts:71-73.
  void emitUnmount(Blot blot) {
    emitter.emit(EmitterEvents.SCROLL_BLOT_UNMOUNT, blot);
  }

  /// Parity scroll.ts:75-77.
  void emitEmbedUpdate(Blot blot, dynamic change) {
    emitter.emit(EmitterEvents.SCROLL_EMBED_UPDATE, blot, change);
  }

  @override
  List<MapEntry<Blot, int>> path(int index, {bool inclusive = false}) {
    final entries = super.path(index, inclusive: inclusive);
    return entries.length <= 1 ? entries : entries.sublist(1);
  }

  @override
  void remove() {
    // Parity with scroll.ts:276-278 — the root is never removed; ignore
    // silently so optimize passes that try to drop it keep running.
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
    final ctx = context ?? <String, dynamic>{};
    emitter.emit(EmitterEvents.SCROLL_BEFORE_UPDATE, source, filtered);

    // Parity parchment scroll.ts:183-213 — group mutations by owning blot
    // and let each blot reconcile itself (children before parents so a
    // parent's childList resync sees settled subtrees).
    final mutationsMap = <Blot, List<DomMutationRecord>>{};
    for (final record in filtered) {
      final blot = find(record.target, bubble: true).key;
      if (blot == null) continue;
      // Edição NATIVA (digitação) muda o texto sem passar pelos setters do
      // modelo: o record é o único aviso, então a invalidação do cache de
      // comprimento acontece aqui.
      final owner = blot is ParentBlot ? blot : blot.parent;
      owner?.invalidateLengthCache();
      mutationsMap.putIfAbsent(blot, () => []).add(record);
    }
    final targets = mutationsMap.keys.toList()
      ..sort((a, b) => b.depth.compareTo(a.depth));
    for (final blot in targets) {
      if (!identical(blot, this) && blot.parent == null) continue;
      blot.applyMutations(mutationsMap[blot]!, ctx);
      _invalidateEnclosingBlockCache(blot);
    }

    emitter.emit(EmitterEvents.SCROLL_UPDATE, source, filtered);
    optimize(filtered, ctx);
  }

  void _invalidateEnclosingBlockCache(Blot blot) {
    Blot? current = blot;
    while (current != null) {
      if (current is Block) {
        current.invalidateCache();
        return;
      }
      current = current.parent;
    }
  }

  /// Public hydration entry used by ParentBlot.syncChildrenFromDom.
  @override
  Blot? hydrateDomNode(DomNode node) => _blotFromDomNode(node);

  void updateEmbedAt(int index, String key, dynamic change) {
    final result = descendant((blot) => blot is BlockEmbed, index);
    final blot = result.key;
    if (blot != null && blot.blotName == key && isUpdatable(blot)) {
      (blot as UpdatableEmbed).updateContent(change);
    }
  }

  void handleDragStart(DomEvent event) => event.preventDefault();

  /// Parity scroll.ts:139-210 — the canonical delta→blots insertion path.
  void insertContents(int index, Delta delta) {
    final dbgTot = Stopwatch()..start();
    final renderBlocks =
        deltaToRenderBlocks(delta.concat(Delta()..insert('\n')));
    final dbgRender = dbgTot.elapsedMilliseconds;
    if (renderBlocks.isEmpty) return;
    final last = renderBlocks.removeLast();

    batchStart();

    var insertIndex = index;
    if (renderBlocks.isNotEmpty) {
      final first = renderBlocks.removeAt(0);
      final isBlock = first['type'] == 'block';
      final firstDelta = isBlock
          ? first['delta'] as Delta
          : (Delta()..insert({first['key'] as String: first['value']}));
      final firstLength = _characterLength(firstDelta);
      final hasBlockEmbedAt =
          descendant((blot) => blot is BlockEmbed, insertIndex).key != null;
      final shouldInsertNewlineChar = isBlock &&
          (firstLength == 0 || (!hasBlockEmbedAt && insertIndex < length()));
      insertInlineContents(this, insertIndex, firstDelta);
      final newlineCharLength = isBlock ? 1 : 0;
      final lineEndIndex = insertIndex + firstLength + newlineCharLength;
      if (shouldInsertNewlineChar) {
        insertAt(lineEndIndex - 1, '\n');
      }

      final lineEntry = line(insertIndex);
      final formats = bubbleFormats(lineEntry.key);
      final attributes = Delta.diffAttributes(
              formats, first['attributes'] as Map<String, dynamic>) ??
          <String, dynamic>{};
      attributes.forEach((name, value) {
        formatAt(lineEndIndex - 1, 1, name, value);
      });

      insertIndex = lineEndIndex;
    }

    var refEntry = _childAtIndex(insertIndex);
    var refBlot = refEntry.key;
    var refBlotOffset = refEntry.value;
    if (renderBlocks.isNotEmpty) {
      if (refBlot != null) {
        refBlot = refBlot.split(refBlotOffset);
        refBlotOffset = 0;
      }

      for (final renderBlock in renderBlocks) {
        if (renderBlock['type'] == 'block') {
          createBlock(
              Map<String, dynamic>.from(renderBlock['attributes'] as Map),
              refBlot,
              renderBlock['delta'] as Delta);
        } else {
          final blockEmbed =
              create(renderBlock['key'] as String, renderBlock['value']);
          insertBefore(blockEmbed, refBlot);
          (renderBlock['attributes'] as Map).forEach((name, value) {
            blockEmbed.format('$name', value);
          });
        }
      }
    }

    if (last['type'] == 'block') {
      final lastDelta = last['delta'] as Delta;
      if (lastDelta.isNotEmpty) {
        final offset =
            refBlot != null ? this.offset(refBlot) + refBlotOffset : length();
        insertInlineContents(this, offset, lastDelta);
      }
    }

    batchEnd();
    optimize([], {});
  }

  /// Direct child containing [index] (LinkedList.find equivalent); null when
  /// the index is at or past the end.
  MapEntry<Blot?, int> _childAtIndex(int index) {
    var offset = 0;
    for (final child in children) {
      final childLength = child.length();
      if (index < offset + childLength) {
        return MapEntry(child, index - offset);
      }
      offset += childLength;
    }
    return const MapEntry(null, 0);
  }

  static int _characterLength(Delta delta) =>
      delta.operations.fold<int>(0, (total, op) => total + (op.length ?? 0));

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

  /// [contents] é o conteúdo inline da linha. O upstream o insere DEPOIS de
  /// aplicar os formatos restantes (scroll.ts:392-400), o que funciona para um
  /// Block — vazio, ele já tem comprimento 1 (o newline). Um blot de bloco que
  /// é CONTAINER (a `table-cell` do table-better) tem comprimento 0 enquanto
  /// vazio, então `formatAt(0, 0, ...)` é no-op e o formato se perde: era
  /// assim que o cellId do Delta sumia e uma célula com dois parágrafos virava
  /// duas colunas. Nesse caso o conteúdo entra primeiro, e os formatos caem
  /// sobre o bloco filho que ele criou.
  ParentBlot createBlock(Map<String, dynamic> attributes,
      [Blot? refBlot, Delta? contents]) {
    String? blockName;
    final formats = <String, dynamic>{};
    // Uma linha pode nomear VÁRIOS blots de bloco. A regra é semântica, não
    // posicional, porque a ordem das chaves varia entre produtores (o
    // clipboard emite `{table, table-cell, table-cell-block}`; um Delta
    // gravado emite `{table-cell-block, table-cell}`) e não pode mudar o
    // resultado:
    //
    // * a linha NASCE como o último blot de bloco SIMPLES (o cellBlock, um
    //   header...) — nunca como um container: um container vazio tem
    //   comprimento 0, o `formatAt` seguinte não pega em nada e o id da
    //   célula se perdia (o merge compara cellIds: célula com dois parágrafos
    //   virava duas colunas);
    // * chaves de CONTAINER (a `table-cell`) são rebaixadas a formato e
    //   aplicadas depois do conteúdo — é o caminho de `format('table-cell')`
    //   do plugin, que embrulha a linha na cadeia row/cell preservando o
    //   data-row;
    // * as demais chaves de bloco simples preteridas são DESCARTADAS, como no
    //   upstream (`{list, header}` fica só com um). Isso inclui o eco
    //   `table: 1` que o matcher core de `<tr>` adiciona por cima dos
    //   formatos do table-better: rebaixá-lo criava a estrutura de tabela
    //   CORE dentro da do plugin, e as duas se desfaziam mutuamente até o
    //   optimize estourar o limite de iterações.
    final blockKeys = <String>[];
    attributes.forEach((name, value) {
      if (query(name, Scope.BLOCK_BLOT) != null) {
        blockKeys.add(name);
      } else {
        formats[name] = value;
      }
    });
    if (blockKeys.length == 1) {
      blockName = blockKeys.single;
    } else if (blockKeys.length > 1) {
      final containerByKey = <String, bool>{
        for (final key in blockKeys)
          key: create(key, attributes[key]) is ContainerBlot,
      };
      blockName = blockKeys.lastWhere(
        (key) => !containerByKey[key]!,
        orElse: () => blockKeys.last,
      );
      for (final key in blockKeys) {
        if (key == blockName) continue;
        if (containerByKey[key]!) {
          formats[key] = attributes[key];
        }
      }
    }

    // Parity scroll.ts:120-124 — the block blot is created WITH its value
    // (`create('list', 'bullet')`). Creating it bare produced an `<li>` with
    // no `data-list`, so a line whose attributes named a block format lost
    // that format entirely: `insertContents` and `applyDelta` disagreed on
    // the very same delta.
    final block = create(
      blockName ?? Block.kBlotName,
      blockName != null ? attributes[blockName] : null,
    );
    insertBefore(block, refBlot);
    final parent = block as ParentBlot;
    var pending = contents;
    if (pending != null && parent.length() == 0) {
      insertInlineContents(parent, 0, pending);
      pending = null;
    }
    final blockLength = parent.length();
    formats.forEach((name, value) {
      parent.formatAt(0, blockLength, name, value);
    });
    if (pending != null) {
      insertInlineContents(parent, 0, pending);
    }
    return parent;
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
      // Class beats tag (parchment query(node) checks classes first), and the
      // tag falls back to registration order — see Registry.scanByTagName.
      final entry =
          registry.queryByClassName(node.className ?? '', scope: Scope.ANY) ??
              registry.scanByTagName(node.tagName, scope: Scope.ANY);
      final blotName = entry?.blotName ?? Block.kBlotName;
      final blot = create(blotName, node);
      if (blot is ParentBlot) {
        for (final child in List<DomNode>.from(node.childNodes)) {
          // `attachUI()` may prepend a zero-length marker while the parent
          // blot is being constructed. It is deliberately not part of the
          // blot tree.
          if (child == blot.uiNode) continue;
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
