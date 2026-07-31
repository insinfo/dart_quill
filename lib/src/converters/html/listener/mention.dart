// --- mention.dart ---
import 'dart:core';
import '../inline_listener.dart';
import '../line.dart';

/// Mention Quill Plugin Listener.
class Mention extends InlineListener {
  @override
  void process(Line line) {
    final mention = line.insertJsonKey('mention');

    if (mention != null && mention is Map) {
      updateInput(line, line.getLexer().escape(mention['value'].toString()));
    }
  }
}
