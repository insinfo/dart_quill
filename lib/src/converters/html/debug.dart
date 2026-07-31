// --- debug.dart ---
import 'dart:convert';
import 'lexer.dart';
import 'line.dart';

/// Debug Object.
class Debug {
  final DeltaToHtmlConverter lexer;
  final HtmlEscape _htmlEscape = const HtmlEscape();

  Debug(this.lexer);

  List<Line> _getNotDoneLines() {
    return lexer.getLines().where((line) => !line.isDone()).toList();
  }

  List<Line> _getNotPickedLines() {
    return lexer
        .getLines()
        .where((line) => !line.isPicked() && !line.isDone())
        .toList();
  }

  /// return a string with debug informations.
  String getHtml() {
    final d = StringBuffer();
    d.writeln("<p><b>NOT PICKED LINES</b></p>");
    d.writeln(_getLinesTable(_getNotPickedLines()));
    d.writeln("<p><b>NOT DONE LINES</b></p>");
    d.writeln(_getLinesTable(_getNotDoneLines()));
    d.writeln("<p><b>LINE BY LINE</b></p>");
    d.writeln(_getLinesTable(lexer.getLines()));
    return d.toString().replaceAll('\n', '<br>');
  }

  /// Get an array with alles lines rendered a string
  String _getLinesTable(List<Line> lines) {
    final rows = lines.map((line) {
      return <String>[
        line.index.toString(),
        line.getInput(),
        _htmlEscape.convert(line.output),
        _htmlEscape.convert(line.renderPrepend()),
        line.getDebugInfo().join(", "),
        // CORREÇÃO AQUI: usar a API pública de Line
        line.getAttributes().toString(),
        line.isInline().toString(),
        _lineStatus(line),
        line.hasEndNewline().toString(),
        line.hasNewline().toString(),
        line.isEmpty().toString(),
      ];
    }).toList();

    return _renderTable(rows, const <String>[
      'ID',
      'input',
      'output',
      'prepend',
      'debug',
      'attributes',
      'is inline',
      'status',
      'has end newline',
      'has new line',
      'is empty',
    ]);
  }

  /// Get the status waterfall of a given line
  String _lineStatus(Line line) {
    if (line.isDone()) {
      return 'Picked => Done';
    } else if (line.isPicked()) {
      return 'Picked';
    }
    return '';
  }

  /// Render the given table line by line
  String _renderTable(List<List<String>> rows, List<String> head) {
    final buffer = StringBuffer(
      '<table class="table table-bordered table-striped table-hover table-sm small" border="1" width="100%" cellpadding="3" cellspacing="0">',
    );

    if (head.isNotEmpty) {
      buffer.write('<thead><tr>');
      for (final col in head) {
        buffer.write('<td><b>$col</b></td>');
      }
      buffer.write('</tr></thead>');
    }

    for (final cols in rows) {
      buffer.write(
        '<tr onclick="this.style.backgroundColor=(this.style.backgroundColor==\'red\')?(\'transparent\'):(\'red\');">',
      );
      for (final col in cols) {
        buffer.write('<td>$col</td>');
      }
      buffer.write('</tr>');
    }

    buffer.write('</table>');
    return buffer.toString();
  }
}
