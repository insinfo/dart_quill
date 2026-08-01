// listener/table_better.dart
import 'dart:core';
import '../block_listener.dart';
import '../lexer.dart';
import '../line.dart';
import '../models/pick.dart';
// ignore: unused_import
import '../utils/css_util.dart';

/// Suporte ao plugin quill-table-better.
/// Ele entende os atributos gerados pelo plugin:
/// - `table-temporary`: metadados da tabela (class, border, cellspacing, style...)
/// - `table-cell`: metadados da célula (data-row, width, colspan, rowspan, style...)
/// - `table-cell-block`: índice interno do bloco da célula (não é obrigatório para a renderização)
/// O conteúdo visível da célula está no **delta imediatamente anterior** à linha que carrega
/// `table-cell`, portanto capturamos o texto do `previous()` e marcamos ambos como `done`.
class TableBetter extends BlockListener {
  static const String _kTmp = 'table-temporary';
  static const String _kCell = 'table-cell';
  static const String _kCellBlock = 'table-cell-block';

  @override
  void process(Line line) {
    // âncora/início de uma tabela (aparece uma vez antes da primeira célula).
    final tblMeta = line.getAttribute(_kTmp);
    if (tblMeta != null) {
      pick(line, {
        'kind': 'table-start',
        'table': tblMeta, // Map com border, cellspacing, style, data-class...
      });
      line.setDone();
      return;
    }

    // marcação de célula do plugin
    final cellMeta = line.getAttribute(_kCell);
    if (cellMeta != null) {
      // o texto da célula está no delta imediatamente anterior
      final prev = line.previous();
      final cellText = prev?.getInput() ?? '';

      pick(line, {
        'kind': 'cell',
        'text': cellText,
        'row': _readRow(cellMeta),
        'width': cellMeta['width'],
        'rowspan': cellMeta['rowspan'],
        'colspan': cellMeta['colspan'],
        'style': cellMeta['style'],
        'class': cellMeta['class'] ?? cellMeta['data-class'],
        // alinhamento pode estar no op do texto (prev) ou no op da célula;
        // o do texto prevalece (pois já envolve <strong>, <em> etc).
        'align': prev?.getAttribute('align') ?? line.getAttribute('align'),
        'block': line.getAttribute(_kCellBlock),
      });

      // Evita o texto “vazar” para fora da tabela.
      prev?.setAsInline();
      prev?.setDone();
      line.setDone();
    }
  }

  static String _readRow(dynamic meta) {
    // o plugin costuma enviar 'data-row', mas aceitamos 'row' por segurança.
    // O id é uma STRING opaca: tabelas criadas no editor usam ids como
    // "row-is10" (tableId()), e só deltas colados de HTML/Word trazem "1","2".
    // Converter para int fazia todo id não numérico virar 0 e a tabela
    // inteira colapsar em um único <tr>.
    final raw = (meta is Map) ? (meta['data-row'] ?? meta['row']) : meta;
    return raw?.toString() ?? '';
  }

  @override
  void render(DeltaToHtmlConverter lexer) {
    if (picks.isEmpty) return;

    // agrupamos por tabelas: cada ocorrência de 'table-start' inicia um novo buffer
    StringBuffer? buf;
    Pick? attachPick; // pick onde o HTML final da tabela será escrito
    String? currentRow;
    bool rowOpen = false;
    bool tbodyOpen = false;

    void _closeRow() {
      if (rowOpen == true) {
        buf!.write('</tr>\n');
        rowOpen = false;
      }
    }

    void _closeTable() {
      if (buf != null) {
        _closeRow();
        if (tbodyOpen) {
          buf!.write('</tbody>\n');
          tbodyOpen = false;
        }
        buf!.write('</table>\n');
      }
    }

    void _flushAndAttach() {
      if (attachPick != null && buf != null) {
        attachPick!.line.output = buf!.toString();
        attachPick!.line.setDone();
      }
      buf = null;
      attachPick = null;
      currentRow = null;
      rowOpen = false;
      tbodyOpen = false;
    }

    /// Extrai o valor numérico de uma string de width (ex: "1379.39px" -> 1379.39)
    /// Retorna null se o valor for nulo, vazio ou inválido.
    double? parseWidthValue(String? widthString) {
      if (widthString == null || widthString.trim().isEmpty) return null;
      // Remove unidades (px, pt, em, etc) e tenta converter para double
      final numericPart =
          widthString.replaceAll(RegExp(r'[a-zA-Z%]+'), '').trim();
      return double.tryParse(numericPart);
    }

    // abre a <table> respeitando os metadados do plugin
    void _openTable(Map tableMeta, Pick startPick) {
      final tblClass = _escape(tableMeta['data-class'] ?? tableMeta['class']);
      final border = _escape(tableMeta['border']);
      final cellspacing = _escape(tableMeta['cellspacing']);
      var rawStyle = _escape(tableMeta['style']);

      rawStyle = rawStyle?.trim() ?? '';
      final mapStyle = parseInlineStyleToMap(rawStyle);
      if (mapStyle.containsKey('width')) {
        final widthString = mapStyle['width'];
        final widthValue = parseWidthValue(widthString);
        // Se o width for maior que 600px, remove o atributo
        if (widthValue != null && widthValue > 600) {
          mapStyle.remove('width');
          // Adiciona width para responsividade
          mapStyle['width'] = '100%';
        }
      }

      if (mapStyle.containsKey('margin-left')) {
        mapStyle.remove('margin-left');
      }

      final sanitized = styleMapToString(mapStyle);

      // Agora sim faça o escape para HTML
      final styleEscaped = _escape(sanitized);

      final classAttr =
          (tblClass?.isNotEmpty == true) ? ' class="$tblClass"' : '';
      final borderAttr =
          (border?.isNotEmpty == true) ? ' border="$border"' : '';
      final cellspAttr = (cellspacing?.isNotEmpty == true)
          ? ' cellspacing="$cellspacing"'
          : '';

      // sempre forçamos border-collapse para ficar igual ao editor, preservando style vindo do plugin
      final styleMerged =
          _mergeStyles('border-collapse: collapse;', styleEscaped ?? '');
      final styleAttr = ' style="$styleMerged"';

      buf = StringBuffer()
        ..write('<table$classAttr$borderAttr$cellspAttr$styleAttr>\n');
      attachPick = startPick;
      tbodyOpen = false;
      rowOpen = false;
      currentRow = null;
    }

    // cria <td ...>
    void _writeCell(Map opts) {
      if (buf == null) return;

      if (!tbodyOpen) {
        buf!.write('<tbody>\n');
        tbodyOpen = true;
      }

      // troca de linha? (comparação por STRING do id — nova linha quando o
      // valor muda; o primeiro <tr> abre porque rowOpen começa falso)
      final row = (opts['row'] as String?) ?? '';
      if (!rowOpen || currentRow != row) {
        _closeRow();
        buf!.write('<tr>');
        rowOpen = true;
        currentRow = row;
      }

      final width = _escape(opts['width']);
      final colspan = _escape(opts['colspan']);
      final rowspan = _escape(opts['rowspan']);
      final cls = _escape(opts['class']);
      final align = _escape(opts['align']);
      final style = _escape(opts['style']);

      // sempre aplicamos borda simples e padding; mesclamos com style vindo do plugin
      final baseTd = 'border:1px solid #000;padding:6px;';
      final merged = _mergeStyles(baseTd, style ?? '');
      final alignCss = (align?.isNotEmpty == true) ? 'text-align:$align;' : '';
      final styleAttr = ' style="$alignCss$merged"';

      final widthAttr = (width?.isNotEmpty == true) ? ' width="$width"' : '';
      final colAttr =
          (colspan?.isNotEmpty == true) ? ' colspan="$colspan"' : '';
      final rowAttr =
          (rowspan?.isNotEmpty == true) ? ' rowspan="$rowspan"' : '';
      final classAttr = (cls?.isNotEmpty == true) ? ' class="$cls"' : '';

      final text =
          (opts['text'] ?? '').toString(); // já vem com <strong>, <em> etc.
      buf!.write(
          '<td$widthAttr$colAttr$rowAttr$classAttr$styleAttr>$text</td>');
    }

    for (final p in picks) {
      final kind = p.optionValue('kind');
      if (kind == 'table-start') {
        // se já havia uma tabela em andamento, finaliza e anexa
        if (buf != null) {
          _closeTable();
          _flushAndAttach();
        }
        final meta = p.optionValue('table') as Map? ?? const {};
        _openTable(meta, p);
        p.line.setDone(); // a âncora em si não deve gerar saída bruta
      } else if (kind == 'cell') {
        if (buf == null) {
          // fallback: se por algum motivo as células vierem sem 'table-start'
          // abrimos uma tabela padrão
          _openTable(const {}, p);
        }
        _writeCell({
          'row': p.optionValue('row') ?? '',
          'width': p.optionValue('width'),
          'rowspan': p.optionValue('rowspan'),
          'colspan': p.optionValue('colspan'),
          'style': p.optionValue('style'),
          'class': p.optionValue('class'),
          'align': p.optionValue('align'),
          'text': p.optionValue('text') ?? '',
        });
        p.line.setDone();
      }
    }

    // fecha e anexa a última tabela
    if (buf != null) {
      _closeTable();
      _flushAndAttach();
    }
  }

  // ---------- helpers ----------

  static String? _escape(dynamic v) {
    if (v == null) return null;
    final s = v.toString();
    if (s.isEmpty) return null;
    // usa o escapador simples do Lexer para segurança; fallback local se necessário
    // (em listeners não temos acesso direto ao lexer aqui, então
    //  mantemos apenas o replace básico).
    return s
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  static String _mergeStyles(String a, String b) {
    if (b.trim().isEmpty) return a;
    if (a.trim().isEmpty) return b;
    // evita duplicar ; se já tiver ponto-e-vírgula de fechamento.
    final left = a.trim().endsWith(';') ? a.trim() : '${a.trim()};';
    return '$left ${b.trim()}';
  }
}
