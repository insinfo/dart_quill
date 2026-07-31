import '../block_listener.dart';
import '../lexer.dart';
import '../line.dart';

class Table extends BlockListener {
  @override
  void process(Line line) {
    final rowAttr = line.getAttribute('table');
    if (rowAttr != null) {
      // conteúdo da célula está na linha anterior
      final prev = line.previous();
      final text = prev?.getInput() ?? '';

      pick(line, {
        'row': rowAttr, // pode vir int ou string
        'text': text, // HTML-safe (já escapado via getInput)
        'align': line.getAttribute('align'), // opcional
      });

      // evita sair duas vezes
      prev?.setAsInline();
      prev?.setDone();
      line.setDone();
    }
  }

  @override
  void render(DeltaToHtmlConverter lexer) {
    if (picks.isEmpty) return;

    final buf = StringBuffer();
    bool tableOpen = false;
    int? currentRow;

    void openTable() {
      buf.write('<table style="border-collapse:collapse;width:100%;">\n');
      tableOpen = true;
    }

    void closeTable() {
      if (tableOpen) {
        buf.write('</table>\n');
        tableOpen = false;
      }
    }

    for (var i = 0; i < picks.length; i++) {
      final p = picks[i];

      final rowVal = p.optionValue('row');
      final row = rowVal is int ? rowVal : int.tryParse(rowVal.toString());
      final text = (p.optionValue('text') ?? '').toString();
      final align = p.optionValue('align');
      final tdStyle = (align is String && align.isNotEmpty)
          ? ' style="text-align:$align;border:1px solid #000;padding:6px;"'
          : ' style="border:1px solid #000;padding:6px;"';

      if (!tableOpen) openTable();

      if (currentRow != row) {
        if (currentRow != null) buf.write('</tr>\n');
        buf.write('<tr>');
        currentRow = row;
      }

      buf.write('<td$tdStyle>$text</td>');
      p.line.setDone();

      // fecha a <tr> quando mudar de linha ou for o último pick
      final isLast = i == picks.length - 1;
      int? nextRow;
      if (!isLast) {
        final nr = picks[i + 1].optionValue('row');
        nextRow = nr is int ? nr : int.tryParse(nr.toString());
      }
      if (isLast || nextRow != currentRow) {
        buf.write('</tr>\n');
      }
    }

    closeTable();

    // escreve a tabela em um único lugar (no último pick)
    final last = picks.last;
    last.line.output = buf.toString();
  }
}
