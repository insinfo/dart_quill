// --- text.dart ---
import 'dart:core';
import '../block_listener.dart';
import '../lexer.dart';
import '../line.dart';
import '../listener.dart';

/// Convert all the not done elements into paragraphs.
class Text extends BlockListener {
  static const String CLOSEP = '</p>\n';
  static const String OPENP = '<p>';
  static const String LINEBREAK = '<br>';

  @override
  int get priority => Listener.PRIORITY_GARBAGE_COLLECTOR;

  @override
  void process(Line line) {
    if (!line.isDone()) {
      pick(line);
    }
  }

  @override
  void render(DeltaToHtmlConverter lexer) {
    bool isOpen = false;
    for (final pick in picks) {
      if (!pick.line.isDone() &&
          !pick.line.hasAttributes() &&
          !pick.line.isInline()) {
        pick.line.setDone();

        final next = pick.line.next();
        final prev = pick.line.previous();

        final output = <String>[];

        if (!isOpen) {
          isOpen = _output(output, OPENP, true);
        }

        output.add(pick.line.isEmpty()
            ? LINEBREAK
            : pick.line.renderPrepend() + pick.line.getInput());

        if (isOpen && (next != null && !next.isInline())) {
          isOpen = _output(output, CLOSEP, false);
        } else if (isOpen && next == null) {
          isOpen = _output(output, CLOSEP, false);
        } else if (isOpen &&
            (prev != null && prev.isInline()) &&
            pick.line.hasEndNewline()) {
          isOpen = _output(output, CLOSEP, false);
        } else if (pick.line.isEmpty() && next != null && !next.isDone()) {
          isOpen = _output(output, CLOSEP + OPENP, true);
        } else if (isOpen && pick.line.hasEndNewline()) {
          isOpen = _output(output, CLOSEP, false);
        }

        if (next != null &&
            next.isInline() &&
            !isOpen &&
            !pick.line.hasEndNewline()) {
          isOpen = _output(output, OPENP, true);
        }

        pick.line.output = output.join("");
      }
    }
  }

  /// Helper method simplify output writer.
  bool _output(List<String> output, String tag, bool openState) {
    output.add(tag);
    return openState;
  }
}
