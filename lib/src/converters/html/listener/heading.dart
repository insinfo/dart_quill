// --- heading.dart ---
import 'dart:core';
import '../block_listener.dart';
import '../lexer.dart';
import '../line.dart';

/// Convert header into heading elements.
class Heading extends BlockListener {
  /// Supported header levels.
  List<int> levels = [1, 2, 3, 4, 5, 6];

  @override
  void process(Line line) {
    final heading = line.getAttribute('header');
    if (heading != null) {
      pick(line, {'heading': heading});
      line.setDone();
    }
  }

  @override
  void render(DeltaToHtmlConverter lexer) {
    for (final pick in picks) {
      final headingValue = pick.optionValue('heading');
      if (headingValue is! int || !levels.contains(headingValue)) {
        // prevent html injection in case the attribute is user input
        throw Exception(
            'An unknown heading level "$headingValue" has been detected.');
      }
    }

    wrapElement('<h{heading}>{__buffer__}</h{heading}>',
        simpleOptions: ['heading']);
  }
}
