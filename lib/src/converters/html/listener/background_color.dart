// background_color.dart (corrigido)
import '../inline_listener.dart';
import '../line.dart';

/// Converte atributo 'background' em <span style="background-color:...">
class BackgroundColor extends InlineListener {
  bool ignore = false;

  @override
  void process(Line line) {
    final attr = line.getAttribute('background');
    if (attr is String && attr.isNotEmpty) {
      final safe = line.getLexer().escape(attr);
      updateInput(
        line,
        ignore
            ? line.getInput()
            : '<span style="background-color:$safe">${line.getInput()}</span>',
      );
    }
  }
}
