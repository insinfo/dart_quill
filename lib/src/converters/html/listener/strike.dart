// --- strike.dart ---
import 'dart:core';
import '../inline_listener.dart';
import '../line.dart';

/// Process strike elements
class Strike extends InlineListener {
  @override
  void process(Line line) {
    if (line.getAttribute('strike') != null) {
      updateInput(line, '<del>${line.getInput()}</del>');
    }
  }
}
