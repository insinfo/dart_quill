import '../blots/block.dart';
import '../blots/abstract/blot.dart';
import '../blots/break.dart';
import '../blots/scroll.dart';
import '../blots/text.dart';

import 'package:dart_quill/src/dependencies/dart_quill_delta/dart_quill_delta.dart';

class Editor {
  final Scroll scroll;
  Delta delta = Delta();

  Editor(this.scroll);

  /// Applies [delta] to the document (parity editor.ts:28-122).
  ///
  /// Kept as the single write path so `Quill.setContents`/`updateContents`
  /// behave like upstream. The name stays `update` for the existing call
  /// sites; [applyDelta] is the faithful implementation.
  void update(Delta delta, String source) {
    applyDelta(delta);
  }

  /// Parity `Editor.applyDelta` (editor.ts:28-122).
  ///
  /// Three things the previous bespoke loop did not do, each of which changed
  /// the resulting document:
  ///
  /// * **implicit newlines** — inserting text that does not end in `\n` at the
  ///   end of the document (or right before a block embed) makes the scroll
  ///   append one; inserting a block embed after non-newline content makes it
  ///   prepend one. Upstream records those in a companion delta and deletes
  ///   them afterwards, so the document matches the delta exactly;
  /// * **`splitOpLines`** — a multi-line insert is applied line by line, so
  ///   each line's attributes land on the right newline;
  /// * **retain of an object** — `{retain: {key: change}}` reaches
  ///   `Scroll.updateEmbedAt`, which is how embeds are updated in place.
  ///
  /// Attributes are diffed against what the document already has
  /// (`AttributeMap.diff`), instead of being applied blindly.
  Delta applyDelta(Delta delta) {
    scroll.update();
    var scrollLength = scroll.length();
    scroll.batchStart();

    final normalized = _normalizeDelta(delta);
    final deleteDelta = Delta();
    var index = 0;

    for (final op in _splitOpLines(normalized.operations)) {
      final length = _opLength(op);
      var attributes = Map<String, dynamic>.from(op.attributes ?? const {});
      var prependImplicitNewline = false;
      var appendImplicitNewline = false;

      if (op.isInsert) {
        deleteDelta.retain(length);
        final data = op.data;
        if (data is String) {
          appendImplicitNewline = !data.endsWith('\n') &&
              (scrollLength <= index || _blockEmbedAt(index) != null);
          scroll.insertAt(index, data);
          final entry = scroll.line(index);
          final line = entry.key;
          final offset = entry.value;
          var formats = <String, dynamic>{...bubbleFormats(line)};
          if (line is Block) {
            final leaf =
                line.descendant((blot) => blot is LeafBlot, offset).key;
            if (leaf != null) {
              formats = {...formats, ...bubbleFormats(leaf)};
            }
          }
          attributes = Delta.diffAttributes(formats, attributes) ?? {};
        } else if (data is Map && data.isNotEmpty) {
          final key = data.keys.first as String;
          final isInlineEmbed = scroll.query(key, Scope.INLINE) != null;
          if (isInlineEmbed) {
            if (scrollLength <= index || _blockEmbedAt(index) != null) {
              appendImplicitNewline = true;
            }
          } else if (index > 0) {
            final entry = scroll.descendant((b) => b is LeafBlot, index - 1);
            final leaf = entry.key;
            final leafOffset = entry.value;
            if (leaf is TextBlot) {
              final text = leaf.value() as String? ?? '';
              if (leafOffset >= text.length || text[leafOffset] != '\n') {
                prependImplicitNewline = true;
              }
            } else if (leaf is EmbedBlot && leaf.scope == Scope.INLINE_BLOT) {
              prependImplicitNewline = true;
            }
          }
          scroll.insertAt(index, key, data[key]);

          if (isInlineEmbed) {
            final leaf = scroll.descendant((b) => b is LeafBlot, index).key;
            if (leaf != null) {
              final formats = <String, dynamic>{...bubbleFormats(leaf)};
              attributes = Delta.diffAttributes(formats, attributes) ?? {};
            }
          }
        }
        scrollLength += length;
      } else {
        deleteDelta.push(op);
        // `{retain: {embedKey: change}}` updates an embed in place.
        if (op.isRetain && op.data is Map && (op.data as Map).isNotEmpty) {
          final change = op.data as Map;
          final key = change.keys.first as String;
          scroll.updateEmbedAt(index, key, change[key]);
        }
      }

      attributes.forEach((name, value) {
        scroll.formatAt(index, length, name, value);
      });

      final prepended = prependImplicitNewline ? 1 : 0;
      final appended = appendImplicitNewline ? 1 : 0;
      scrollLength += prepended + appended;
      deleteDelta.retain(prepended);
      deleteDelta.delete(appended);
      index += length + prepended + appended;
    }

    // Second pass: remove the newlines the scroll added implicitly.
    var deleteIndex = 0;
    for (final op in deleteDelta.operations) {
      if (op.isDelete) {
        scroll.deleteAt(deleteIndex, op.length ?? 0);
        continue;
      }
      deleteIndex += _opLength(op);
    }

    scroll.batchEnd();
    scroll.optimize([], {});
    _update();
    return normalized;
  }

  /// Parity `Op.length(op)`.
  int _opLength(Operation op) {
    if (op.isDelete || op.isRetain) return op.length ?? 0;
    final data = op.data;
    return data is String ? data.length : 1;
  }

  /// Parity `splitOpLines(ops)` (editor.ts:465-480) — a text insert becomes one
  /// op per line, with an explicit `\n` op carrying the line's attributes.
  List<Operation> _splitOpLines(List<Operation> ops) {
    final split = <Operation>[];
    for (final op in ops) {
      final data = op.data;
      if (op.isInsert && data is String) {
        final lines = data.split('\n');
        for (var i = 0; i < lines.length; i++) {
          if (i > 0) split.add(Operation.insert('\n', op.attributes));
          if (lines[i].isNotEmpty) {
            split.add(Operation.insert(lines[i], op.attributes));
          }
        }
      } else {
        split.add(op);
      }
    }
    return split;
  }

  /// The block embed covering [index], if any (TS
  /// `this.scroll.descendant(BlockEmbed, index)[0]`).
  Blot? _blockEmbedAt(int index) =>
      scroll.descendant((blot) => blot is BlockEmbed, index).key;

  void deleteText(int index, int length) {
    scroll.deleteAt(index, length);
    _update();
  }

  /// Mirrors editor.ts `formatLine`: applies [formats] directly to every
  /// line in the range and returns the equivalent change delta.
  Delta formatLine(int index, int length, Map<String, dynamic> formats) {
    formats.forEach((name, value) {
      final lineLength = length > 1 ? length : 1;
      for (final line in scroll.lines(index, lineLength)) {
        line.format(name, value);
      }
    });
    scroll.optimize([], {});
    _update();
    final change = Delta()..retain(index);
    if (length > 0) {
      change.retain(length, Map<String, dynamic>.from(formats));
    }
    return change;
  }

  Delta formatText(int index, int length, String name, dynamic value) {
    scroll.formatAt(index, length, name, value);
    _update();
    return Delta()
      ..retain(index)
      ..retain(length, {name: value});
  }

  Delta insertEmbed(int index, String type, dynamic data) {
    scroll.insertAt(index, type, data);
    _update();
    return Delta()
      ..retain(index)
      ..insert({type: data});
  }

  /// Parity editor.ts `insertContents`: inserts a full delta (multiline,
  /// embeds, block formats) at [index] through the canonical
  /// [Scroll.insertContents] path and returns the change delta.
  Delta insertContents(int index, Delta contents) {
    final normalized = _normalizeDelta(contents);
    scroll.insertContents(index, normalized);
    _update();
    return (Delta()..retain(index)).concat(normalized);
  }

  /// Parity editor.ts `normalizeDelta` — CRLF→LF on every string insert.
  Delta _normalizeDelta(Delta delta) {
    final normalized = Delta();
    for (final op in delta.operations) {
      final data = op.data;
      if (op.isInsert && data is String) {
        normalized.insert(data.replaceAll('\r\n', '\n').replaceAll('\r', '\n'),
            op.attributes);
      } else {
        normalized.operations.add(op);
      }
    }
    return normalized;
  }

  Delta insertText(int index, String text, [Map<String, dynamic>? formats]) {
    scroll.insertAt(index, text);
    if (formats != null) {
      formats.forEach((name, value) {
        scroll.formatAt(index, text.length, name, value);
      });
    }
    _update();
    return Delta()
      ..retain(index)
      ..insert(text, formats);
  }

  /// Parity `Editor.getDelta` (editor.ts:162-166) — the document delta is the
  /// concatenation of every line's delta, nothing else.
  ///
  /// The port used to skip the last block when it was an empty paragraph, on
  /// the theory that it was a rendering sentinel. It is not: a document ending
  /// in an empty line *has* an empty last line, and upstream reports it.
  /// Dropping it made `setContents` lossy — `a\n\n\n` came back as `a\n\n` — and
  /// masked the stray paragraph the block-embed path leaves behind.
  void _update() {
    var tempDelta = Delta();
    for (final child in scroll.children) {
      final childDelta = _buildDelta(child);
      if (childDelta.isNotEmpty) {
        tempDelta = tempDelta.concat(childDelta);
      }
    }
    if (tempDelta.isEmpty) {
      tempDelta.insert('\n');
    }
    delta = tempDelta;
  }

  Delta getContents() {
    return delta;
  }

  /// Parity editor.ts `update(null, mutations)` — recompute the document delta
  /// straight from the blot tree and return the change against the previous
  /// snapshot.
  ///
  /// Needed whenever the tree is mutated outside the delta pipeline (native
  /// typing absorbed by `Scroll.update`, the Syntax module's `formatAt` pass);
  /// without it `getContents()` keeps serving a stale snapshot.
  Delta syncFromDocument() {
    final oldDelta = delta;
    _update();
    return oldDelta.diff(delta);
  }

  /// Parity editor.ts:158-160.
  Delta getContentsRange(int index, int length) =>
      delta.slice(index, index + length);

  /// Parity editor.ts:211-216.
  String getText(int index, int length) {
    final buffer = StringBuffer();
    for (final op in getContentsRange(index, length).operations) {
      final data = op.data;
      if (op.isInsert && data is String) {
        buffer.write(data);
      }
    }
    return buffer.toString();
  }

  /// Parity editor.ts:168-196 — line formats combined with leaf formats;
  /// values that differ across the range accumulate into a list.
  Map<String, dynamic> getFormat(int index, [int length = 0]) =>
      scroll.getFormat(index, length);

  /// Parity editor.ts:245-253.
  bool isBlank() {
    if (scroll.children.isEmpty) return true;
    if (scroll.children.length > 1) return false;
    final blot = scroll.children.first;
    if (blot is! Block) return false;
    if (blot.children.length > 1) return false;
    return blot.children.isNotEmpty && blot.children.first is Break;
  }

  /// Parity editor.ts:255-271 — diff the range against its plain text (plus
  /// the untouched suffix of the closing line) and apply the difference, so
  /// both inline and block formats are dropped in one delta.
  Delta removeFormat(int index, int length) {
    final text = getText(index, length);
    final lineEntry = scroll.line(index + length);
    final line = lineEntry.key;
    final offset = lineEntry.value;
    var suffixLength = 0;
    var suffix = Delta();
    if (line is Block) {
      suffixLength = line.length() - offset;
      suffix = line
          .delta()
          .slice(offset, offset + suffixLength - 1)
          .concat(Delta()..insert('\n'));
    }
    final contents = getContentsRange(index, length + suffixLength);
    // `Delta()..insert(text)..concat(suffix)` would discard the concat: a
    // cascade returns the receiver, not the new Delta. The suffix never made
    // it into the diff, so the diff deleted the line's newline instead of
    // clearing its formats, and block formats survived the clean.
    final plain = Delta()..insert(text);
    final diff = contents.diff(plain.concat(suffix));
    final change = (Delta()..retain(index)).concat(diff);
    applyDelta(change);
    return change;
  }

  Delta _buildDelta(Blot blot) {
    if (blot is Block) {
      return blot.delta();
    }

    if (blot is BlockEmbed) {
      // Block attributors (align/indent on a full-line embed) live in the
      // embed's AttributorStore (block.ts:140-145), not in formats().
      final attributes = {
        ...bubbleFormats(blot, filter: true),
        ...blot.attributeValues(),
      };
      final value = {blot.blotName: blot.value()};
      // Parity `BlockEmbed.delta()` (block.ts:26-31): the embed *is* the line —
      // one op, length 1, no newline of its own. Emitting a trailing `\n` here
      // made the delta two units long for a one-unit blot, so every index after
      // a block embed was off by one, and the document reported a paragraph
      // that does not exist.
      return Delta()..insert(value, attributes.isEmpty ? null : attributes);
    }

    if (blot is ParentBlot) {
      var delta = Delta();
      for (final child in blot.children) {
        delta = delta.concat(_buildDelta(child));
      }
      return delta;
    }

    if (blot is LeafBlot) {
      final attributes = bubbleFormats(blot, filter: true);
      final value = blot.value();
      return Delta()..insert(value, attributes.isEmpty ? null : attributes);
    }

    return Delta();
  }

}
