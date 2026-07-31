import 'dart:core';
import '../inline_listener.dart';
import '../line.dart';

/// Convert Bold attributes into tags.
class Bold extends InlineListener {
  @override
  void process(Line line) {
    if (line.getAttribute('bold') != null) {
      updateInput(line, '<strong>${line.getInput()}</strong>');
    }
  }
}
