// font.dart (corrigido)
import '../inline_listener.dart';
import '../line.dart';

class Font extends InlineListener {
  bool ignore = false;

  @override
  void process(Line line) {
    final font = line.getAttribute('font');
    if (font is String && font.isNotEmpty) {
      updateInput(line, applyTemplate(font, line));
    }
  }

  String applyTemplate(String font, Line line) {
    if (ignore) return line.getInput();
    final safe = line.getLexer().escape(font);
    return '<span style="font-family: $safe;">${line.getInput()}</span>';
  }
}
