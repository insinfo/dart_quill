// --- script.dart ---
import 'dart:core';
import '../inline_listener.dart';
import '../line.dart';

/// Renders script attribute which will generate sup/sub tags.
class Script extends InlineListener {
  List<String> scriptTags = ['super', 'sub'];

  @override
  void process(Line line) {
    final script = line.getAttribute('script');
    if (script != null) {
      updateInput(line, applyTemplate(script.toString(), line));
    }
  }

  /// Wrap in sup/sub tag.
  String applyTemplate(String script, Line line) {
    if (!scriptTags.contains(script)) {
      throw Exception('An unknown script tag "$script" has been detected.');
    }

    String tag = (script == 'super') ? 'sup' : script;
    return '<$tag>${line.getInput()}</$tag>';
  }
}
