// --- code_block.dart ---
import 'dart:core';
import '../block_listener.dart';
import '../lexer.dart';
import '../line.dart';

/// Code Block
class CodeBlock extends BlockListener {
  @override
  void process(Line line) {
    final heading = line.getAttribute('code-block');
    if (heading != null) {
      pick(line);
      line.setDone();
    }
  }

  @override
  void render(DeltaToHtmlConverter lexer) {
    wrapElement('<pre><code>{__buffer__}</code></pre>');
  }
}
