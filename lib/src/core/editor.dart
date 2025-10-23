import '../blots/scroll.dart';

import 'package:dart_quill/src/dependencies/dart_quill_delta/dart_quill_delta.dart';

class Editor {
  final Scroll scroll;
  Delta delta = Delta();

  Editor(this.scroll);

  void update(Delta delta, String source) {
    var index = 0;
    delta.operations.forEach((op) {
      if (op.isInsert) {
        if (op.data is String) {
          scroll.insertAt(index, op.data as String);
          index += (op.data as String).length;
        } else if (op.data is Map) {
          final embed = op.data as Map;
          embed.forEach((key, value) {
            scroll.insertAt(index, key, value);
            index++;
          });
        }
      } else if (op.isDelete) {
        scroll.deleteAt(index, op.length!);
      } else if (op.isRetain) {
        if (op.attributes != null) {
          op.attributes!.forEach((name, value) {
            scroll.formatAt(index, op.length!, name, value);
          });
        }
        index += op.length!;
      }
    });
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
    var tempDelta = Delta();
    scroll.children.forEach((child) {
      final childDelta = _buildDelta(child);
      tempDelta = tempDelta.concat(childDelta);
    });
    delta = tempDelta;
  }

  Delta getContents() {
    return delta;
  }

  Delta _buildDelta(dynamic blot) {
    if (blot is String) {
      return Delta()..insert(blot);
    }
    final formats = blot.formats();
    if (formats.isEmpty) {
      return Delta()..insert(blot.value());
    }
    return Delta()..insert(blot.value(), formats);
  }
}
