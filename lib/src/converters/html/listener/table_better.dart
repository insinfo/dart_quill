// listener/table_better.dart
import 'dart:core';
import '../block_listener.dart';
import '../lexer.dart';
import '../line.dart';
import '../models/pick.dart';
// ignore: unused_import
import '../utils/css_util.dart';

/// Suporte ao plugin quill-table-better.
///
/// Atributos reconhecidos (as formas vêm dos goldens gravados contra o plugin
/// real — `test/goldens/quill_table_better_1.2.3.json`):
/// - `table-temporary`: âncora/metadados da tabela (class, border, style,
///   e opcionalmente `col-widths`, a lista de larguras medidas que o SALI
///   injeta ao salvar);
/// - `table-col`: uma coluna do `<colgroup>` (`{width}`), uma linha por coluna;
/// - `table-cell`: metadados da célula (data-row, width, colspan, rowspan...);
/// - `table-cell-block`: id do bloco de parágrafo da célula (o `cellId`);
/// - `table-header` (`{cellId, value}`): título h1-h6 dentro da célula;
/// - `table-list` + `table-list-container` (`{cellId, ...}`): item de lista
///   dentro da célula.
///
/// Uma célula pode ter VÁRIOS blocos (parágrafos, título, itens de lista):
/// todos os blocos consecutivos com o mesmo `cellId` entram no MESMO `<td>`.
/// O id de linha (`data-row`) é uma string opaca — `row-xxxx` no editor,
/// `"1"`/`"2"` em conteúdo colado — e nunca deve ser convertido para número.
class TableBetter extends BlockListener {
  static const String _kTmp = 'table-temporary';
  static const String _kCol = 'table-col';
  static const String _kCell = 'table-cell';
  static const String _kCellBlock = 'table-cell-block';
  static const String _kHeader = 'table-header';
  static const String _kList = 'table-list';
  static const String _kListContainer = 'table-list-container';

  @override
  void process(Line line) {
    // âncora/início de uma tabela (aparece uma vez antes das colunas/células).
    final tblMeta = line.getAttribute(_kTmp);
    if (tblMeta != null) {
      pick(line, {
        'kind': 'table-start',
        'table': tblMeta, // Map com border, cellspacing, style, data-class...
      });
      line.setDone();
      return;
    }

    // uma coluna do colgroup
    final colMeta = line.getAttribute(_kCol);
    if (colMeta != null) {
      pick(line, {
        'kind': 'col',
        'width': (colMeta is Map) ? colMeta['width'] : null,
      });
      line.setDone();
      return;
    }

    // um BLOCO dentro de uma célula (parágrafo, título ou item de lista)
    final cellMeta = line.getAttribute(_kCell);
    if (cellMeta == null) return;

    final headerMeta = line.getAttribute(_kHeader);
    final listType = line.getAttribute(_kList);
    final listContainer = line.getAttribute(_kListContainer);

    // O cellId agrupa blocos consecutivos no mesmo <td>. Cada tipo de bloco o
    // carrega em um lugar diferente; sem nenhum, cada linha vira uma célula.
    String? cellId = line.getAttribute(_kCellBlock)?.toString();
    if (cellId == null && headerMeta is Map) {
      cellId = headerMeta['cellId']?.toString();
    }
    if (cellId == null && listContainer is Map) {
      cellId = listContainer['cellId']?.toString();
    }
    cellId ??= 'line-${line.getIndex()}';

    dynamic metaVal(String key) {
      final own = (cellMeta is Map) ? cellMeta[key] : null;
      if (own != null) return own;
      return (listContainer is Map) ? listContainer[key] : null;
    }

    // Marca as linhas de conteúdo desta linha lógica como done para o Text
    // não as renderizar fora da tabela. O texto em si é coletado no render
    // (depois dos listeners inline), então aqui só sinalizamos.
    var cur = line.previous();
    while (cur != null &&
        !cur.hasEndNewline() &&
        !cur.hasNewline() &&
        !(cur.isJsonInsert() && !cur.isInline())) {
      cur.setDone();
      cur = cur.previous();
    }

    var blockKind = 'p';
    var headerLevel = 0;
    if (headerMeta is Map) {
      blockKind = 'header';
      headerLevel = int.tryParse('${headerMeta['value']}') ?? 2;
    } else if (listType != null) {
      blockKind = 'list';
    }

    pick(line, {
      'kind': 'cell-block',
      'row': _readRow(cellMeta),
      'cellId': cellId,
      'block': blockKind,
      'headerLevel': headerLevel,
      'listType': listType?.toString(),
      'width': metaVal('width'),
      'rowspan': metaVal('rowspan'),
      'colspan': metaVal('colspan'),
      'style': metaVal('style'),
      'class': (cellMeta is Map)
          ? (cellMeta['class'] ?? cellMeta['data-class'])
          : null,
      // alinhamento pode estar no op do texto ou no op da célula.
      'align': line.getAttribute('align') ??
          line.previous()?.getAttribute('align'),
    });
    line.setDone();
  }

  static String _readRow(dynamic meta) {
    // o plugin costuma enviar 'data-row', mas aceitamos 'row' por segurança.
    // O id é uma STRING opaca; converter para int fazia todo id não numérico
    // virar 0 e a tabela inteira colapsar em um único <tr>.
    final raw = (meta is Map) ? (meta['data-row'] ?? meta['row']) : meta;
    return raw?.toString() ?? '';
  }

  /// Coleta o HTML inline de uma linha lógica: as linhas não-inline carregam
  /// o próprio input mais os prepends que os listeners inline (bold, italic,
  /// color...) depositaram nelas — exatamente o contrato que o Text usa.
  String _collectText(Pick p) {
    final first = getFirstLine(p);
    final sb = StringBuffer();
    Line? cur = first;
    while (cur != null) {
      if (!cur.isInline()) {
        sb.write(cur.renderPrepend());
        sb.write(cur.getInput());
      }
      if (cur.index == p.line.index) break;
      cur = cur.next();
    }
    return sb.toString();
  }

  @override
  void render(DeltaToHtmlConverter lexer) {
    if (picks.isEmpty) return;

    StringBuffer? buf;
    Pick? attachPick; // pick onde o HTML final da tabela será escrito
    Map _tableMeta = const {};
    bool tagWritten = false;
    final pendingCols = <String>[];
    String? currentRow;
    String? currentCell;
    bool rowOpen = false;
    bool tbodyOpen = false;
    bool cellOpen = false;
    Map? cellAttrs; // atributos do <td> aberto (do primeiro bloco da célula)
    final cellBlocks = <Map<String, dynamic>>[];

    String formatColWidth(dynamic raw) {
      final s = raw?.toString().trim() ?? '';
      if (s.isEmpty) return '';
      return double.tryParse(s) != null ? '${s}px' : s;
    }

    /// Extrai o valor numérico de uma string de width (ex: "1379.39px" -> 1379.39)
    double? parseWidthValue(String? widthString) {
      if (widthString == null || widthString.trim().isEmpty) return null;
      final numericPart =
          widthString.replaceAll(RegExp(r'[a-zA-Z%]+'), '').trim();
      return double.tryParse(numericPart);
    }

    // Escreve a tag <table ...> (e o <colgroup>) na primeira necessidade —
    // adiada porque as colunas só são conhecidas depois da âncora.
    void _ensureTableTag() {
      if (tagWritten || buf == null) return;
      tagWritten = true;

      final tableMeta = _tableMeta;
      final tblClass = _withoutEditorClasses(
          _escape(tableMeta['data-class'] ?? tableMeta['class']));
      final border = _escape(tableMeta['border']);
      final cellspacing = _escape(tableMeta['cellspacing']);
      var rawStyle = _escape(tableMeta['style']);

      rawStyle = rawStyle?.trim() ?? '';
      final mapStyle = parseInlineStyleToMap(rawStyle);
      if (mapStyle.containsKey('width')) {
        final widthValue = parseWidthValue(mapStyle['width']);
        // Se o width for maior que 600px, troca por 100% (responsividade)
        if (widthValue != null && widthValue > 600) {
          mapStyle.remove('width');
          mapStyle['width'] = '100%';
        }
      }
      if (mapStyle.containsKey('margin-left')) {
        mapStyle.remove('margin-left');
      }
      // Com larguras de coluna explícitas, o browser só as respeita com
      // table-layout fixo (mesma regra do editor: .ql-editor table).
      if (pendingCols.isNotEmpty) {
        mapStyle['table-layout'] = 'fixed';
      }

      final sanitized = styleMapToString(mapStyle);
      final styleEscaped = _escape(sanitized);

      final classAttr =
          (tblClass?.isNotEmpty == true) ? ' class="$tblClass"' : '';
      final borderAttr = (border?.isNotEmpty == true) ? ' border="$border"' : '';
      final cellspAttr =
          (cellspacing?.isNotEmpty == true) ? ' cellspacing="$cellspacing"' : '';

      final styleMerged = styleMapToString(parseInlineStyleToMap(
          'border-collapse: collapse; ${styleEscaped ?? ''}'));
      buf!.write('<table$classAttr$borderAttr$cellspAttr'
          ' style="$styleMerged">\n');

      if (pendingCols.isNotEmpty) {
        buf!.write('<colgroup>');
        for (final w in pendingCols) {
          buf!.write(w.isEmpty
              ? '<col>'
              : '<col style="width:${_escape(w)};">');
        }
        buf!.write('</colgroup>\n');
      }
    }

    // Fecha o <td> aberto, materializando os blocos acumulados.
    void _flushCell() {
      if (!cellOpen || buf == null) return;
      final attrs = cellAttrs ?? const {};

      final width = _escape(attrs['width']);
      final colspan = _escape(attrs['colspan']);
      final rowspan = _escape(attrs['rowspan']);
      final cls = _withoutEditorClasses(_escape(attrs['class']));
      final style = _escape(attrs['style']);

      // Uma célula com um único parágrafo mantém o texto direto no <td> (o
      // formato histórico deste conversor); com múltiplos blocos cada um vira
      // <p>/<hN>/<ul>/<ol> dentro do mesmo <td>.
      final single = cellBlocks.length == 1 && cellBlocks[0]['block'] == 'p';
      String inner;
      String tdAlignCss = '';
      if (single) {
        inner = cellBlocks[0]['text'] as String;
        final align = _escape(cellBlocks[0]['align']);
        if (align?.isNotEmpty == true) tdAlignCss = 'text-align:$align;';
      } else {
        final sb = StringBuffer();
        String? listOpen; // 'bullet' | 'ordered'
        void closeList() {
          if (listOpen != null) {
            sb.write(listOpen == 'ordered' ? '</ol>' : '</ul>');
            listOpen = null;
          }
        }

        for (final b in cellBlocks) {
          final align = _escape(b['align']);
          final alignAttr = (align?.isNotEmpty == true)
              ? ' style="text-align:$align;"'
              : '';
          switch (b['block']) {
            case 'list':
              final t = b['listType'] == 'ordered' ? 'ordered' : 'bullet';
              if (listOpen != t) {
                closeList();
                sb.write(t == 'ordered' ? '<ol>' : '<ul>');
                listOpen = t;
              }
              sb.write('<li$alignAttr>${b['text']}</li>');
              break;
            case 'header':
              closeList();
              var level = b['headerLevel'] as int;
              if (level < 1 || level > 6) level = 2;
              sb.write('<h$level$alignAttr>${b['text']}</h$level>');
              break;
            default:
              closeList();
              sb.write('<p$alignAttr>${b['text']}</p>');
          }
        }
        closeList();
        inner = sb.toString();
      }

      // sempre aplicamos borda simples e padding; mesclamos com style do
      // plugin POR MAPA: concatenar acumulava declarações duplicadas a cada
      // ciclo export -> import -> export (H6).
      const baseTd = 'border:1px solid #000;padding:6px;';
      final styleAttr =
          ' style="${styleMapToString(parseInlineStyleToMap('$baseTd$tdAlignCss${style ?? ''}'))}"';

      final widthAttr = (width?.isNotEmpty == true) ? ' width="$width"' : '';
      final colAttr = (colspan?.isNotEmpty == true) ? ' colspan="$colspan"' : '';
      final rowAttr = (rowspan?.isNotEmpty == true) ? ' rowspan="$rowspan"' : '';
      final classAttr = (cls?.isNotEmpty == true) ? ' class="$cls"' : '';
      // O id opaco da célula também viaja (H6): é o que o staticFormats do
      // plugin lê num paste e o que o importador de HTML devolve intacto.
      final cellIdAttr = (currentCell?.isNotEmpty == true)
          ? ' data-cell="${_escape(currentCell!)}"'
          : '';

      buf!.write('<td$widthAttr$colAttr$rowAttr$classAttr$cellIdAttr$styleAttr>'
          '$inner</td>');
      cellBlocks.clear();
      cellAttrs = null;
      cellOpen = false;
      currentCell = null;
    }

    void _closeRow() {
      _flushCell();
      if (rowOpen) {
        buf!.write('</tr>\n');
        rowOpen = false;
      }
    }

    void _closeTable() {
      if (buf != null) {
        _ensureTableTag();
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
      _tableMeta = const {};
      tagWritten = false;
      pendingCols.clear();
      currentRow = null;
      currentCell = null;
      rowOpen = false;
      tbodyOpen = false;
      cellOpen = false;
      cellAttrs = null;
      cellBlocks.clear();
    }

    void _openTable(Map tableMeta, Pick startPick) {
      buf = StringBuffer();
      attachPick = startPick;
      _tableMeta = tableMeta;
      tagWritten = false;
      pendingCols.clear();
      // Larguras medidas que o SALI injeta na âncora ao salvar; usadas como
      // colgroup quando o delta não traz ops table-col explícitos.
      final measured = tableMeta['col-widths'];
      if (measured is List) {
        for (final w in measured) {
          pendingCols.add(formatColWidth(w));
        }
      }
      tbodyOpen = false;
      rowOpen = false;
      currentRow = null;
      currentCell = null;
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
      } else if (kind == 'col') {
        if (buf == null) _openTable(const {}, p);
        // ops table-col têm precedência sobre col-widths medidos
        if (!tagWritten) {
          if (p == picks.firstWhere((x) => x.optionValue('kind') == 'col',
              orElse: () => p)) {
            // primeira coluna explícita: descarta os widths herdados da âncora
          }
        }
        pendingCols.add(formatColWidth(p.optionValue('width')));
        p.line.setDone();
      } else if (kind == 'cell-block') {
        if (buf == null) {
          // fallback: células sem 'table-start' abrem uma tabela padrão
          _openTable(const {}, p);
        }
        _ensureTableTag();
        if (!tbodyOpen) {
          buf!.write('<tbody>\n');
          tbodyOpen = true;
        }

        final row = (p.optionValue('row') as String?) ?? '';
        final cellId = (p.optionValue('cellId') as String?) ?? '';

        if (!rowOpen || currentRow != row) {
          _closeRow();
          // O id opaco da linha viaja no HTML (H6): reimportar o próprio
          // export devolve o mesmo data-row em vez de reindexar de 1.
          final rowAttr = row.isNotEmpty ? ' data-row="${_escape(row)}"' : '';
          buf!.write('<tr$rowAttr>');
          rowOpen = true;
          currentRow = row;
        }
        if (!cellOpen || currentCell != cellId) {
          _flushCell();
          cellOpen = true;
          currentCell = cellId;
          cellAttrs = {
            'width': p.optionValue('width'),
            'rowspan': p.optionValue('rowspan'),
            'colspan': p.optionValue('colspan'),
            'style': p.optionValue('style'),
            'class': p.optionValue('class'),
          };
        }

        cellBlocks.add({
          'block': p.optionValue('block') ?? 'p',
          'headerLevel': p.optionValue('headerLevel') ?? 0,
          'listType': p.optionValue('listType'),
          'align': p.optionValue('align'),
          'text': _collectText(p),
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
    return s
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

}

/// Remove os tokens de classe do editor e do Word (H4): `ql-*` só faz
/// sentido dentro do Quill e `Mso*` só dentro do Word — num HTML sem CSS os
/// dois são ruído que ainda por cima denuncia a origem.
String? _withoutEditorClasses(String? classAttr) {
  if (classAttr == null || classAttr.isEmpty) return classAttr;
  final kept = classAttr
      .split(RegExp(r'\s+'))
      .where((token) =>
          token.isNotEmpty &&
          !token.startsWith('ql-') &&
          !token.startsWith('Mso'))
      .join(' ');
  return kept;
}
