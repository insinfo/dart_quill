// --- underline.dart ---
import 'dart:core';
import '../inline_listener.dart';
import '../line.dart';

/// Process underline elements
class Underline extends InlineListener {
  @override
  void process(Line line) {
    if (line.getAttribute('underline') != null) {
      updateInput(line, '<u>${line.getInput()}</u>');
    }
  }
}
