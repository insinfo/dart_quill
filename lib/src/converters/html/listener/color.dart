// --- color.dart ---
import '../inline_listener.dart';
import '../line.dart';

class Color extends InlineListener {
  bool ignore = false;

  @override
  void process(Line line) {
    final attr = line.getAttribute('color'); // pode ser String/bool/null
    if (attr is String && attr.isNotEmpty) {
      final safe = line.getLexer().escape(attr);
      updateInput(
        line,
        ignore
            ? line.getInput()
            : '<span style="color:$safe">${line.getInput()}</span>',
      );
    }
  }
}
