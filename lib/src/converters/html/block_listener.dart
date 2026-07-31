// --- block_listener.dart ---
import 'dart:core';
import 'listener.dart';

import 'line.dart';
import 'models/pick.dart';

/// Block Listener
abstract class BlockListener extends Listener {
  @override
  int get type => Listener.TYPE_BLOCK;

  /// Generate a rendered output from the current picks with a custom Wrapper Template.
  void wrapElement(String wrapper,
      {List<String> simpleOptions = const [],
      Map<String, Function> callbackOptions = const {}}) {
    final search = <String>['{__buffer__}'];
    final options = <String>[...simpleOptions, ...callbackOptions.keys];
    for (final key in options) {
      search.add('{$key}');
    }

    for (final pick in picks) {
      final first = getFirstLine(pick);
      final buffer = StringBuffer();
      Line? current = first;

      while (current != null) {
        buffer.write(current.getInput());
        current.setDone();
        if (current.index == pick.line.index ||
            first.index == pick.line.index) {
          break;
        }
        current = current.next();
      }

      final replace = <String>[buffer.toString()];
      for (final key in options) {
        final content = pick.optionValue(key);
        if (callbackOptions.containsKey(key)) {
          replace.add(callbackOptions[key]!(content, pick, key).toString());
        } else {
          replace.add(content.toString());
        }
      }

      String output = wrapper;
      for (int i = 0; i < search.length; i++) {
        output = output.replaceAll(search[i], replace[i]);
      }

      pick.line.output = '$output\n';
      pick.line.setDone();
    }
  }

  /// Returns the first Line from a Pick.
  Line getFirstLine(Pick pick) {
    var first = pick.line;
    var current = pick.line.previous();

    while (current != null) {
      if (current == pick.line) {
        current = current.previous();
        continue;
      }
      if ((current.hasEndNewline() ||
          current.hasNewline() ||
          (current.isJsonInsert() && !current.isInline()))) {
        break;
      }

      first = current;
      current = current.previous();
    }
    return first;
  }
}
