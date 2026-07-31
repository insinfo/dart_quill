// --- link.dart ---
import 'dart:core';
import '../inline_listener.dart';
import '../line.dart';

/// Convert links into a inline elements.
class Link extends InlineListener {
  String wrapperOpen = '<a href="{link}" target="_blank">';
  String wrapperMiddle = '{text}';
  String wrapperClose = '</a>';

  @override
  void process(Line line) {
    final link = line.getAttribute('link');
    if (link != null) {
      var wrapper = StringBuffer();
      final Map<String, String> replacements = {};

      final previousLineHasSimilarLink =
          line.previous()?.getAttribute('link') == link;
      if (previousLineHasSimilarLink == false) {
        wrapper.write(wrapperOpen);
        replacements['{link}'] = line.getLexer().escape(link.toString());
      }

      wrapper.write(wrapperMiddle);
      replacements['{text}'] = line.getInput();

      final nextLineHasSimilarLink = line.next()?.getAttribute('link') == link;
      if (nextLineHasSimilarLink == false) {
        wrapper.write(wrapperClose);
      }

      String output = wrapper.toString();
      replacements.forEach((key, value) {
        output = output.replaceAll(key, value);
      });

      updateInput(line, output);
    }
  }
}
