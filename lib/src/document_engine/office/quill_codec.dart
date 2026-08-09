/// Codec Delta↔Office (Fase 3): o Delta fica NA FRONTEIRA.
///
/// `importQuillDelta` converte um documento Delta (Quill 2.0.3 +
/// table-better) na árvore Office; `exportQuillDelta` faz a volta. A
/// importação é uma função TOTAL: o que não tem mapeamento estruturado sai
/// pelas rotas de escape (`extra` nos blocos, marca `opaque` inline, nós
/// `opaque`/`opaqueInline` para embeds) — nada se perde, e cada uso das
/// rotas gera uma entrada no [OfficeCompatibilityReport]. O round-trip
/// import→export devolve um Delta semanticamente igual ao original
/// (normalizado pela fusão de ops adjacentes do próprio Delta).
library;

import '../model/index.dart';

/// Um achado da conversão (rota de escape usada, op não representável).
class OfficeCompatibilityIssue {
  OfficeCompatibilityIssue(this.code, this.detail);

  /// `unknown-line-attribute` | `unknown-inline-attribute` |
  /// `unknown-embed` | `non-insert-op`.
  final String code;
  final String detail;

  @override
  String toString() => '$code: $detail';
}

/// Relatório da importação.
class OfficeCompatibilityReport {
  final List<OfficeCompatibilityIssue> issues = [];

  /// Falso apenas quando algo foi DESCARTADO (op retain/delete num documento
  /// que deveria ser insert-only); rotas de escape preservam tudo.
  bool get isLossless => issues.every((issue) => issue.code != 'non-insert-op');

  void add(String code, String detail) =>
      issues.add(OfficeCompatibilityIssue(code, detail));
}

/// Resultado da importação: árvore + relatório.
class OfficeImportResult {
  OfficeImportResult(this.doc, this.report);

  final PMNode doc;
  final OfficeCompatibilityReport report;
}

// Atributos de linha com mapeamento estruturado.
const _lineKnown = {
  'header', 'list', 'blockquote', 'code-block', //
  'align', 'indent', 'direction',
};

// Dialeto de tabela do quill-table-better.
const _tableKeys = {
  'table-temporary', 'table-col', 'table-cell-block', 'table-cell', //
  'table-th-block', 'table-th', 'table', 'table-header', 'table-list',
  'table-list-container',
};

// Atributos inline com mapeamento estruturado.
const _inlineKnown = {
  'bold', 'italic', 'underline', 'strike', 'code', 'script', //
  'color', 'background', 'font', 'size', 'link',
};

// ---------------------------------------------------------------------------
// Importação
// ---------------------------------------------------------------------------

class _CellAcc {
  _CellAcc(this.cellId, this.cell, this.tag);

  final String cellId;
  final Map<String, dynamic> cell;
  final String tag;
  final List<PMNode> blocks = [];
}

class _RowAcc {
  _RowAcc(this.rowId);

  final String rowId;
  final List<_CellAcc> cells = [];
}

class _TableAcc {
  Map<String, dynamic>? anchor;
  final List<dynamic> colWidths = [];
  final List<_RowAcc> rows = [];

  bool get isEmpty => anchor == null && colWidths.isEmpty && rows.isEmpty;
}

/// Importa `ops` (lista de mapas `{"insert": ...}`) para a árvore Office.
OfficeImportResult importQuillDelta(List<dynamic> ops, Schema schema) {
  final report = OfficeCompatibilityReport();
  final blocks = <PMNode>[];
  var inline = <PMNode>[];
  _TableAcc? table;
  // Um embed de BLOCO (headerImage/opaque) ocupa a linha inteira: o newline
  // que vem logo depois é o TERMINADOR dele, não um parágrafo vazio.
  var pendingEmbedTerminator = false;

  void flushTable() {
    final acc = table;
    table = null;
    if (acc == null || acc.rows.isEmpty) return;
    final rows = acc.rows
        .map((row) => schema.node(
            'tableRow',
            {'rowId': row.rowId},
            Fragment.from(row.cells
                .map((cell) => schema.node(
                    'tableCell',
                    {
                      'cellId': cell.cellId,
                      'cell': cell.cell,
                      'tag': cell.tag,
                    },
                    Fragment.from(cell.blocks)))
                .toList())))
        .toList();
    blocks.add(schema.node(
        'table',
        {
          'anchor': acc.anchor,
          'colWidths': acc.colWidths.isEmpty ? null : acc.colWidths,
        },
        Fragment.from(rows)));
  }

  List<Mark> marksOf(Map<String, dynamic> attrs) {
    final marks = <Mark>[];
    final opaque = <String, dynamic>{};
    // Ordem fixa (a do schema) para a igualdade de marks ser determinística.
    for (final name in _inlineKnown) {
      final value = attrs[name];
      if (value == null || value == false) continue;
      switch (name) {
        case 'script':
          marks.add(schema.marks['script']!.create({'value': value}));
        case 'color':
        case 'background':
        case 'font':
        case 'size':
          marks.add(schema.marks[name]!.create({'value': value}));
        case 'link':
          marks.add(schema.marks['link']!.create({'href': value}));
        default:
          marks.add(schema.marks[name]!.create());
      }
    }
    attrs.forEach((name, value) {
      if (_inlineKnown.contains(name) ||
          _lineKnown.contains(name) ||
          _tableKeys.contains(name)) {
        return;
      }
      opaque[name] = value;
    });
    if (opaque.isNotEmpty) {
      marks.add(schema.marks['opaqueAttrs']!.create({'attrs': opaque}));
      report.add('unknown-inline-attribute', opaque.keys.join(','));
    }
    return marks;
  }

  /// Fecha a linha corrente com os atributos do '\n'.
  void closeLine(Map<String, dynamic> attrs) {
    if (pendingEmbedTerminator) {
      pendingEmbedTerminator = false;
      if (inline.isEmpty && attrs.isEmpty) return; // terminador do embed
    }
    final content = Fragment.from(inline);
    inline = [];

    // Linha de dialeto de tabela?
    final cellBlockId = attrs['table-cell-block'] ?? attrs['table-th-block'];
    final isTemporary = attrs['table-temporary'] is Map;
    final isCol = attrs['table-col'] is Map;
    if (isTemporary || isCol || cellBlockId != null) {
      table ??= _TableAcc();
      if (isTemporary) {
        // Âncora abre tabela NOVA: fecha a anterior se tinha linhas.
        if (table!.rows.isNotEmpty) {
          flushTable();
          table = _TableAcc();
        }
        table!.anchor =
            (attrs['table-temporary'] as Map).cast<String, dynamic>();
        return;
      }
      if (isCol) {
        table!.colWidths.add(attrs['table-col']);
        return;
      }
      final isTh =
          attrs.containsKey('table-th-block') || attrs.containsKey('table-th');
      final cellMap = ((attrs['table-cell'] ?? attrs['table-th']) as Map?)
              ?.cast<String, dynamic>() ??
          const <String, dynamic>{};
      final rowId = '${cellMap['data-row'] ?? cellBlockId}';
      // Parágrafo interno da célula: align + o que sobrar em extra.
      final innerExtra = <String, dynamic>{};
      attrs.forEach((name, value) {
        if (_tableKeys.contains(name) || name == 'align') return;
        innerExtra[name] = value;
      });
      final innerParagraph = schema.node(
          'paragraph',
          {
            'align': attrs['align'],
            'extra': innerExtra.isEmpty ? null : innerExtra,
          },
          content);
      var row = table!.rows.isNotEmpty ? table!.rows.last : null;
      if (row == null || row.rowId != rowId) {
        row = _RowAcc(rowId);
        table!.rows.add(row);
      }
      var cell = row.cells.isNotEmpty ? row.cells.last : null;
      if (cell == null || cell.cellId != '$cellBlockId') {
        cell = _CellAcc('$cellBlockId', cellMap, isTh ? 'th' : 'td');
        row.cells.add(cell);
      }
      cell.blocks.add(innerParagraph);
      return;
    }

    flushTable();

    // O que sobrar dos atributos, fora os estruturados, vai para extra.
    final extra = <String, dynamic>{};
    attrs.forEach((name, value) {
      if (_lineKnown.contains(name)) return;
      extra[name] = value;
      report.add('unknown-line-attribute', name);
    });
    final extraOrNull = extra.isEmpty ? null : extra;

    final header = attrs['header'];
    final list = attrs['list'];
    if (header is int) {
      blocks.add(schema.node(
          'heading',
          {
            'level': header,
            'align': attrs['align'],
            'extra': extraOrNull,
          },
          content));
    } else if (list is String) {
      blocks.add(schema.node(
          'listItem',
          {
            'kind': list,
            'indent': attrs['indent'],
            'align': attrs['align'],
            'extra': extraOrNull,
          },
          content));
    } else if (attrs['blockquote'] == true) {
      blocks.add(schema.node('blockquote', {'extra': extraOrNull}, content));
    } else if (attrs.containsKey('code-block')) {
      final language = attrs['code-block'];
      blocks.add(schema.node(
          'codeBlock',
          {
            'language': language is String ? language : null,
            'extra': extraOrNull,
          },
          content));
    } else {
      blocks.add(schema.node(
          'paragraph',
          {
            'align': attrs['align'],
            'indent': attrs['indent'],
            'direction': attrs['direction'],
            'extra': extraOrNull,
          },
          content));
    }
  }

  for (final dynamic rawOp in ops) {
    if (rawOp is! Map) continue;
    final dynamic insert = rawOp['insert'];
    final attrs =
        ((rawOp['attributes'] as Map?) ?? const {}).cast<String, dynamic>();
    if (insert == null) {
      report.add('non-insert-op', '$rawOp');
      continue;
    }

    if (insert is Map) {
      final entry = insert.entries.first;
      // Atributos do op de embed além dos estruturados: verbatim em extra
      // (o corpus real tem imagem com color/height/width juntos).
      Map<String, dynamic>? extraOf(Set<String> structured) {
        final extra = <String, dynamic>{};
        attrs.forEach((name, value) {
          if (!structured.contains(name)) extra[name] = value;
        });
        return extra.isEmpty ? null : extra;
      }

      switch (entry.key) {
        case 'image':
          inline.add(schema.node('image', {
            'src': '${entry.value}',
            'width': attrs['width'],
            'height': attrs['height'],
            'extra': extraOf(const {'width', 'height'}),
          }));
        case 'video':
          inline.add(schema.node('video', {
            'src': '${entry.value}',
            'extra': extraOf(const {}),
          }));
        case 'formula':
          inline.add(schema.node('formula', {
            'value': '${entry.value}',
            'extra': extraOf(const {}),
          }));
        case 'headerImage':
          // Bloco atômico: fecha a linha corrente se tinha conteúdo.
          if (inline.isNotEmpty) closeLine(const {});
          flushTable();
          blocks.add(schema.node('headerImage', {'src': '${entry.value}'}));
          pendingEmbedTerminator = true;
        default:
          report.add('unknown-embed', '${entry.key}');
          inline.add(schema.node('opaqueInline', {
            'insert': Map<String, dynamic>.from(insert),
          }));
      }
      continue;
    }

    final text = '$insert';
    final marks = marksOf(attrs);
    var start = 0;
    while (true) {
      final newline = text.indexOf('\n', start);
      if (newline == -1) {
        if (start < text.length) {
          inline.add(schema.text(text.substring(start), marks));
        }
        break;
      }
      if (newline > start) {
        inline.add(schema.text(text.substring(start, newline), marks));
      }
      closeLine(attrs);
      start = newline + 1;
    }
  }

  // Conteúdo inline sem terminador (Delta malformado): fecha como parágrafo.
  if (inline.isNotEmpty) closeLine(const {});
  flushTable();
  if (blocks.isEmpty) {
    blocks.add(schema.node('paragraph', null, Fragment.empty));
  }
  return OfficeImportResult(
      schema.node('doc', null, Fragment.from(blocks)), report);
}

// ---------------------------------------------------------------------------
// Exportação
// ---------------------------------------------------------------------------

/// Exporta a árvore Office de volta para ops Delta (insert-only).
List<Map<String, dynamic>> exportQuillDelta(PMNode doc) {
  final ops = <Map<String, dynamic>>[];

  void push(dynamic insert, [Map<String, dynamic>? attrs]) {
    final op = <String, dynamic>{'insert': insert};
    if (attrs != null && attrs.isNotEmpty) op['attributes'] = attrs;
    // Fusão com o anterior quando texto+texto com os mesmos atributos — a
    // normalização que o Delta faria, para o round-trip comparar igual.
    if (ops.isNotEmpty && insert is String) {
      final last = ops.last;
      if (last['insert'] is String &&
          _sameAttrs(last['attributes'], op['attributes'])) {
        last['insert'] = '${last['insert']}$insert';
        return;
      }
    }
    ops.add(op);
  }

  Map<String, dynamic> markAttrs(List<Mark> marks) {
    final attrs = <String, dynamic>{};
    for (final mark in marks) {
      switch (mark.type.name) {
        case 'script':
        case 'color':
        case 'background':
        case 'font':
        case 'size':
          attrs[mark.type.name] = mark.attrs['value'];
        case 'link':
          attrs['link'] = mark.attrs['href'];
        case 'opaqueAttrs':
          attrs.addAll((mark.attrs['attrs'] as Map).cast<String, dynamic>());
        default:
          attrs[mark.type.name] = true;
      }
    }
    return attrs;
  }

  void emitInline(PMNode block) {
    block.content.forEach((child, offset, index) {
      if (child.isText) {
        push(child.text!, markAttrs(child.marks));
        return;
      }
      Map<String, dynamic> withExtra(Map<String, dynamic> attrs) {
        final extra = child.attrs['extra'];
        if (extra is Map) attrs.addAll(extra.cast<String, dynamic>());
        return attrs;
      }

      switch (child.type.name) {
        case 'image':
          push(
              {'image': child.attrs['src']},
              withExtra({
                if (child.attrs['width'] != null) 'width': child.attrs['width'],
                if (child.attrs['height'] != null)
                  'height': child.attrs['height'],
              }));
        case 'video':
          push({'video': child.attrs['src']}, withExtra({}));
        case 'formula':
          push({'formula': child.attrs['value']}, withExtra({}));
        case 'opaqueInline':
          push(Map<String, dynamic>.from(child.attrs['insert'] as Map));
      }
    });
  }

  Map<String, dynamic> lineAttrs(PMNode block) {
    final attrs = <String, dynamic>{};
    switch (block.type.name) {
      case 'heading':
        attrs['header'] = block.attrs['level'];
        if (block.attrs['align'] != null) {
          attrs['align'] = block.attrs['align'];
        }
      case 'listItem':
        attrs['list'] = block.attrs['kind'];
        if (block.attrs['indent'] != null) {
          attrs['indent'] = block.attrs['indent'];
        }
        if (block.attrs['align'] != null) {
          attrs['align'] = block.attrs['align'];
        }
      case 'blockquote':
        attrs['blockquote'] = true;
      case 'codeBlock':
        attrs['code-block'] = block.attrs['language'] ?? true;
      default:
        for (final name in const ['align', 'indent', 'direction']) {
          if (block.attrs[name] != null) attrs[name] = block.attrs[name];
        }
    }
    final extra = block.attrs['extra'];
    if (extra is Map) attrs.addAll(extra.cast<String, dynamic>());
    return attrs;
  }

  void emitBlock(PMNode block) {
    switch (block.type.name) {
      case 'headerImage':
        push({'headerImage': block.attrs['src']});
        push('\n');
      case 'opaque':
        push(Map<String, dynamic>.from(block.attrs['insert'] as Map));
        push('\n');
      case 'table':
        final anchor = block.attrs['anchor'];
        if (anchor is Map) {
          push('\n', {'table-temporary': anchor});
        }
        final colWidths = block.attrs['colWidths'];
        if (colWidths is List) {
          for (final col in colWidths) {
            push('\n', {'table-col': col});
          }
        }
        block.content.forEach((row, _, __) {
          row.content.forEach((cell, ___, ____) {
            final isTh = cell.attrs['tag'] == 'th';
            cell.content.forEach((inner, _____, ______) {
              emitInline(inner);
              final attrs = <String, dynamic>{
                isTh ? 'table-th-block' : 'table-cell-block':
                    cell.attrs['cellId'],
                if (cell.attrs['cell'] != null)
                  isTh ? 'table-th' : 'table-cell': cell.attrs['cell'],
                if (inner.attrs['align'] != null) 'align': inner.attrs['align'],
              };
              final extra = inner.attrs['extra'];
              if (extra is Map) attrs.addAll(extra.cast<String, dynamic>());
              push('\n', attrs);
            });
          });
        });
      default:
        emitInline(block);
        push('\n', lineAttrs(block));
    }
  }

  doc.content.forEach((block, _, __) => emitBlock(block));
  return ops;
}

bool _sameAttrs(dynamic a, dynamic b) {
  if (a == null && b == null) return true;
  if (a is! Map || b is! Map) return false;
  if (a.length != b.length) return false;
  for (final key in a.keys) {
    final va = a[key];
    final vb = b[key];
    if (va is Map || vb is Map || va is List || vb is List) {
      if ('$va' != '$vb') return false;
    } else if (va != vb) {
      return false;
    }
  }
  return true;
}
