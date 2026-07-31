// --- italic.dart ---
import 'dart:core';
import '../inline_listener.dart';
import '../line.dart';

/// Convert Italic Inline elements.
class Italic extends InlineListener {
  @override
  void process(Line line) {
    if (line.getAttribute('italic') != null) {
      updateInput(line, '<em>${line.getInput()}</em>');
    }
  }
}
