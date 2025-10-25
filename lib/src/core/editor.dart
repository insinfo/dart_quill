import '../blots/block.dart';
import '../blots/abstract/blot.dart';
import '../blots/scroll.dart';

import 'package:dart_quill/src/dependencies/dart_quill_delta/dart_quill_delta.dart';

class Editor {
  final Scroll scroll;
  Delta delta = Delta();

  Editor(this.scroll);

  void update(Delta delta, String source) {
    var index = 0;

    for (final op in delta.operations) {
      if (op.isInsert) {
        if (op.data is String) {
          final text = op.data as String;
          scroll.insertAt(index, text);
          final length = text.length;
          final formats = _collectFormatsAt(index);
          final diff = _diffFormats(formats, op.attributes);
          diff.forEach((name, value) {
            scroll.formatAt(index, length, name, value);
          });
          index += length;
        } else if (op.data is Map) {
          final embed = op.data as Map;
          embed.forEach((key, value) {
            scroll.insertAt(index, key, value);
            final formats = _collectFormatsAt(index);
            final diff = _diffFormats(formats, op.attributes);
            diff.forEach((name, attrValue) {
              scroll.formatAt(index, 1, name, attrValue);
            });
            index += 1;
          });
        }
      } else if (op.isRetain) {
        final length = op.length ?? 0;
        if (op.attributes != null && op.attributes!.isNotEmpty) {
          op.attributes!.forEach((name, value) {
            scroll.formatAt(index, length, name, value);
          });
        }
        index += length;
      } else if (op.isDelete) {
        var remaining = op.length ?? 0;
        while (remaining > 0) {
          final before = scroll.length();
          scroll.deleteAt(index, remaining);
          final removed = before - scroll.length();
          if (removed <= 0) {
            break;
          }
          remaining -= removed;
        }
      }
    }

    _update();
  }

  void deleteText(int index, int length) {
    scroll.deleteAt(index, length);
    _update();
  }

  void formatLine(int index, int length, String name, dynamic value) {
    scroll.formatAt(index, length, name, value);
    _update();
  }

  Delta formatText(int index, int length, String name, dynamic value) {
    scroll.formatAt(index, length, name, value);
    _update();
    return Delta()..retain(index)..retain(length, {name: value});
  }

  Delta insertEmbed(int index, String type, dynamic data) {
    scroll.insertAt(index, type, data);
    _update();
    return Delta()..retain(index)..insert({type: data});
  }

  Delta insertText(int index, String text, [Map<String, dynamic>? formats]) {
    scroll.insertAt(index, text);
    if (formats != null) {
      formats.forEach((name, value) {
        scroll.formatAt(index, text.length, name, value);
      });
    }
    _update();
    return Delta()..retain(index)..insert(text, formats);
  }

  void _update() {
    // Build new delta from current document state
    final childrenList = <Blot>[];
    for (final child in scroll.children) {
      childrenList.add(child);
    }

    var tempDelta = Delta();
    for (var i = 0; i < childrenList.length; i++) {
      final child = childrenList[i];
      final isLast = i == childrenList.length - 1;
      final shouldSkipSentinel = isLast && tempDelta.isNotEmpty &&
          child is Block && _isTrivialSentinelBlock(child);
      if (shouldSkipSentinel) {
        continue;
      }

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

  Delta _buildDelta(Blot blot) {
    if (blot is Block) {
      return blot.delta();
    }

    if (blot is BlockEmbed) {
      final attributes = bubbleFormats(blot, filter: true);
      final value = {blot.blotName: blot.value()};
      return Delta()
        ..insert(value, attributes.isEmpty ? null : attributes)
        ..insert('\n', attributes.isEmpty ? null : attributes);
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

  bool _isTrivialSentinelBlock(Block block) {
    final blockDelta = block.delta();
    if (blockDelta.operations.length != 1) {
      return false;
    }
    final op = blockDelta.operations.first;
    if (!op.isInsert) {
      return false;
    }
    final data = op.data;
    if (data is! String) {
      return false;
    }
    if (data != '\n') {
      return false;
    }
    final attrs = op.attributes;
    return attrs == null || attrs.isEmpty;
  }

  Map<String, dynamic> _collectFormatsAt(int index) {
    final formats = <String, dynamic>{};
    final lineEntry = scroll.line(index);
    final line = lineEntry.key;
    final offset = lineEntry.value;

    if (line != null) {
      formats.addAll(bubbleFormats(line, filter: true));
      if (line is ParentBlot) {
        final leafResult = line.descendant((blot) => blot is LeafBlot, offset);
        final leaf = leafResult.key;
        if (leaf != null) {
          formats.addAll(bubbleFormats(leaf, filter: true));
        }
      }
    }

    return formats;
  }

  Map<String, dynamic> _diffFormats(
      Map<String, dynamic> current, Map<String, dynamic>? desired) {
    final target = desired == null
        ? const <String, dynamic>{}
        : Map<String, dynamic>.from(desired);
    final diff = <String, dynamic>{};
    final keys = {...current.keys, ...target.keys};

    for (final key in keys) {
      final currentValue = current[key];
      final hasTarget = target.containsKey(key);
      final targetValue = hasTarget ? target[key] : null;

      if (!hasTarget || targetValue == null || targetValue == false) {
        if (current.containsKey(key) && currentValue != null) {
          diff[key] = null;
        }
        continue;
      }

      if (currentValue != targetValue) {
        diff[key] = targetValue;
      }
    }
    return diff;
  }
}
