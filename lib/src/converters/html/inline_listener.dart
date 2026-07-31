import 'dart:core';
import 'listener.dart';
import 'lexer.dart';
import 'line.dart';

/// Inline listener.
abstract class InlineListener extends Listener {
  @override
  int get type => Listener.TYPE_INLINE;

  /// A short hand method for handling inline elements.
  void updateInput(Line line, dynamic value) {
    line.setInput(value.toString());
    line.setDone();
    line.setAsInline();
    line.setAsEscaped();
    pick(line);
  }

  @override
  void render(DeltaToHtmlConverter lexer) {
    for (final pick in picks) {
      final next = pick.line.next((Line line) => !line.isInline());

      if (next == null) {
        throw Exception(
            'Unable to find a next element. Invalid DELTA on \'${pick.line.getInput()}\'. Maybe your delta code does not end with a newline?');
      }

      next.addPrepend(pick.line.getInput(), pick.line);
    }
  }
}
