import 'dart:core';
import '../block_listener.dart';
import '../lexer.dart';
import '../line.dart';

/// Convert Blockquote Elements
class Blockquote extends BlockListener {
  @override
  void process(Line line) {
    if (line.getAttribute('blockquote') != null) {
      pick(line);
      line.setDone();
    }
  }

  @override
  void render(DeltaToHtmlConverter lexer) {
    wrapElement('<blockquote>{__buffer__}</blockquote>');
  }
}
