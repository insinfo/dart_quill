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
    bool rowOpen = false;
    // O id da linha é uma STRING opaca ("row-xxxx" no editor, "1"/"2" em
    // conteúdo colado). Convertê-lo para int fazia ids não numéricos virarem
    // null e nenhum <tr> era emitido.
    String? currentRow;

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

      final row = p.optionValue('row')?.toString() ?? '';
      final text = (p.optionValue('text') ?? '').toString();
      final align = p.optionValue('align');
      final tdStyle = (align is String && align.isNotEmpty)
          ? ' style="text-align:$align;border:1px solid #000;padding:6px;"'
          : ' style="border:1px solid #000;padding:6px;"';

      if (!tableOpen) openTable();

      if (!rowOpen) {
        buf.write('<tr>');
        rowOpen = true;
        currentRow = row;
      } else if (currentRow != row) {
        buf.write('</tr>\n<tr>');
        currentRow = row;
      }

      buf.write('<td$tdStyle>$text</td>');
      p.line.setDone();
    }

    if (rowOpen) buf.write('</tr>\n');
    closeTable();

    // escreve a tabela em um único lugar (no último pick)
    final last = picks.last;
    last.line.output = buf.toString();
  }
}
