import 'dart:collection';

import '../editor/dataset/enum/element.dart';
import '../editor/dataset/enum/list.dart';
import '../editor/dataset/enum/row.dart';
import '../editor/dataset/enum/table/table.dart';
import '../editor/dataset/enum/title.dart';
import '../editor/interface/element.dart';
import '../editor/interface/table/td.dart';

/// Conversor entre o modelo de elementos do editor e o formato Delta do
/// Quill (`{"ops": [{"insert": ..., "attributes": {...}}, ...]}`).
///
/// Cobertura:
/// - texto com formatação inline (bold, italic, underline, strike, color,
///   background, font, size, script sobrescrito/subscrito);
/// - títulos (`header` 1–6), alinhamento (`align`) e listas
///   (`list: bullet|ordered`) como atributos de linha;
/// - hyperlinks (`link`) e imagens (embed `{"image": ...}`);
/// - tabelas no formato do módulo `quill-table-better`: colunas como linhas
///   `table-col` e cada parágrafo de célula terminado por `\n` com os
///   atributos `table-cell-block` (cellId) e `table-cell`
///   (`data-row`/`colspan`/`rowspan`/`width`/`height`).
class QuillDeltaConverter {
  QuillDeltaConverter._();

  // -----------------------------------------------------------------------
  // Editor → Delta
  // -----------------------------------------------------------------------

  static Map<String, dynamic> toDelta(List<IElement> main) {
    final List<Map<String, dynamic>> ops = <Map<String, dynamic>>[];
    int tableIndex = 0;

    void insertText(String text, Map<String, dynamic> attributes) {
      if (text.isEmpty) return;
      ops.add(<String, dynamic>{
        'insert': text,
        if (attributes.isNotEmpty)
          'attributes': Map<String, dynamic>.from(attributes),
      });
    }

    void insertNewline(Map<String, dynamic> lineAttributes) {
      ops.add(<String, dynamic>{
        'insert': '\n',
        if (lineAttributes.isNotEmpty)
          'attributes': Map<String, dynamic>.from(lineAttributes),
      });
    }

    void walk(List<IElement> elements, Map<String, dynamic> inherited) {
      for (final IElement element in elements) {
        switch (element.type) {
          case ElementType.title:
            final Map<String, dynamic> titleInherited = <String, dynamic>{
              ...inherited,
              if (element.level != null)
                'header': _titleLevelToHeader(element.level!),
            };
            walk(element.valueList ?? const <IElement>[], titleInherited);
            if (ops.isEmpty || ops.last['insert'] != '\n') {
              insertNewline(_lineAttributes(element, titleInherited));
            }
            continue;
          case ElementType.list:
            final Map<String, dynamic> listInherited = <String, dynamic>{
              ...inherited,
              'list':
                  element.listType == ListType.ordered ? 'ordered' : 'bullet',
            };
            walk(element.valueList ?? const <IElement>[], listInherited);
            if (ops.isEmpty || ops.last['insert'] != '\n') {
              insertNewline(_lineAttributes(element, listInherited));
            }
            continue;
          case ElementType.hyperlink:
            final Map<String, dynamic> linked = <String, dynamic>{
              ...inherited,
              if (element.url != null) 'link': element.url,
            };
            walk(element.valueList ?? const <IElement>[], linked);
            continue;
          case ElementType.image:
            ops.add(<String, dynamic>{
              'insert': <String, dynamic>{'image': element.value},
              'attributes': <String, dynamic>{
                if (element.width != null) 'width': element.width,
                if (element.height != null) 'height': element.height,
              },
            });
            continue;
          case ElementType.table:
            // Formato quill-table-better: colunas (`table-col`) seguidas dos
            // parágrafos de cada célula, cujo '\n' terminador carrega
            // `table-cell-block` (cellId) + `table-cell` (props do TD).
            // Uma tabela começa em uma nova linha. Sem este terminador, o
            // primeiro `table-col` consumiria o texto aberto imediatamente
            // anterior durante a importação do Delta.
            if (ops.isNotEmpty) {
              final Object? previousInsert = ops.last['insert'];
              if (previousInsert is! String || !previousInsert.endsWith('\n')) {
                insertNewline(const <String, dynamic>{});
              }
            }
            tableIndex++;
            final List<ITr> trList = element.trList ?? const <ITr>[];
            final int columnCount = element.colgroup?.length ??
                trList.fold<int>(0, (int max, ITr tr) {
                  int cols = 0;
                  for (final ITd td in tr.tdList) {
                    cols += td.colspan;
                  }
                  return cols > max ? cols : max;
                });
            for (int c = 0; c < columnCount; c++) {
              final double width =
                  element.colgroup != null && c < element.colgroup!.length
                      ? element.colgroup![c].width
                      : 72;
              insertNewline(<String, dynamic>{
                'table-col': <String, dynamic>{'width': '${width.round()}'},
              });
            }
            for (int r = 0; r < trList.length; r++) {
              final ITr tr = trList[r];
              final String rowId = 'row-t$tableIndex-r${r + 1}';
              for (int c = 0; c < tr.tdList.length; c++) {
                final ITd td = tr.tdList[c];
                final String cellId = 'cell-t$tableIndex-r${r + 1}-c${c + 1}';
                final bool isHeaderCell = td.extension is Map &&
                    (td.extension as Map)['quillTableHeader'] == true;
                final Map<String, dynamic> cellAttributes = <String, dynamic>{
                  'data-row': rowId,
                  if (td.colspan > 1) 'colspan': '${td.colspan}',
                  if (td.rowspan > 1) 'rowspan': '${td.rowspan}',
                  if (td.width != null) 'width': '${td.width!.round()}',
                  'height': '${tr.height.round()}',
                  if (td.backgroundColor != null)
                    'style': 'background-color: ${td.backgroundColor}',
                };
                final Map<String, dynamic> cellInherited = <String, dynamic>{
                  isHeaderCell ? 'table-th-block' : 'table-cell-block': cellId,
                  isHeaderCell ? 'table-th' : 'table-cell': cellAttributes,
                };
                final int opsBefore = ops.length;
                walk(td.value, cellInherited);
                // Garante o terminador da célula quando o conteúdo não
                // terminou em '\n' (célula vazia ou parágrafo aberto).
                final bool terminated = ops.length > opsBefore &&
                    ops.last['insert'] == '\n' &&
                    ops.last['attributes'] is Map &&
                    _cellIdOf((ops.last['attributes'] as Map)
                            .cast<String, dynamic>()) ==
                        cellId;
                if (!terminated) {
                  insertNewline(cellInherited);
                }
              }
            }
            continue;
          case ElementType.separator:
          case ElementType.pageBreak:
            insertNewline(const <String, dynamic>{});
            continue;
          default:
            break;
        }

        final Map<String, dynamic> charAttributes =
            _charAttributes(element, inherited);
        final Map<String, dynamic> lineAttributes =
            _lineAttributes(element, inherited);
        final String value = element.value;
        int start = 0;
        for (int i = 0; i < value.length; i++) {
          if (value[i] == '\n') {
            insertText(value.substring(start, i), charAttributes);
            insertNewline(lineAttributes);
            start = i + 1;
          }
        }
        insertText(value.substring(start), charAttributes);
      }
    }

    walk(main, const <String, dynamic>{});
    // Todo Delta do Quill termina em '\n'.
    final Map<String, dynamic>? last = ops.isEmpty ? null : ops.last;
    final Object? lastInsert = last?['insert'];
    if (lastInsert is! String || !lastInsert.endsWith('\n')) {
      ops.add(<String, dynamic>{'insert': '\n'});
    }
    return <String, dynamic>{'ops': ops};
  }

  static Map<String, dynamic> _charAttributes(
      IElement element, Map<String, dynamic> inherited) {
    return <String, dynamic>{
      if (inherited.containsKey('link')) 'link': inherited['link'],
      if (element.bold == true) 'bold': true,
      if (element.italic == true) 'italic': true,
      if (element.underline == true) 'underline': true,
      if (element.strikeout == true) 'strike': true,
      if (element.color != null) 'color': element.color,
      if (element.highlight != null) 'background': element.highlight,
      if (element.font != null) 'font': element.font,
      if (element.size != null) 'size': '${element.size}px',
      if (element.type == ElementType.superscript) 'script': 'super',
      if (element.type == ElementType.subscript) 'script': 'sub',
    };
  }

  static Map<String, dynamic> _lineAttributes(
      IElement element, Map<String, dynamic> inherited) {
    final Object? cellId =
        inherited['table-cell-block'] ?? inherited['table-th-block'];
    final bool isTableLine = cellId != null;
    return <String, dynamic>{
      if (inherited.containsKey('header') && !isTableLine)
        'header': inherited['header'],
      if (inherited.containsKey('list') && !isTableLine)
        'list': inherited['list'],
      if (inherited.containsKey('header') && isTableLine)
        'table-header': <String, dynamic>{
          'cellId': cellId,
          'value': inherited['header'],
        }
      else if (inherited.containsKey('list') && isTableLine)
        'table-list': <String, dynamic>{
          'cellId': cellId,
          'value': inherited['list'],
        }
      else if (inherited.containsKey('table-cell-block'))
        'table-cell-block': inherited['table-cell-block'],
      if (inherited.containsKey('table-th-block') &&
          !inherited.containsKey('header') &&
          !inherited.containsKey('list'))
        'table-th-block': inherited['table-th-block'],
      if (inherited.containsKey('table-cell'))
        'table-cell': inherited['table-cell'],
      if (inherited.containsKey('table-th')) 'table-th': inherited['table-th'],
      if (element.rowFlex == RowFlex.center) 'align': 'center',
      if (element.rowFlex == RowFlex.right) 'align': 'right',
      if (element.rowFlex == RowFlex.alignment ||
          element.rowFlex == RowFlex.justify)
        'align': 'justify',
    };
  }

  static int _titleLevelToHeader(TitleLevel level) {
    switch (level) {
      case TitleLevel.first:
        return 1;
      case TitleLevel.second:
        return 2;
      case TitleLevel.third:
        return 3;
      case TitleLevel.fourth:
        return 4;
      case TitleLevel.fifth:
        return 5;
      case TitleLevel.sixth:
        return 6;
    }
  }

  // -----------------------------------------------------------------------
  // Delta → Editor
  // -----------------------------------------------------------------------

  static List<IElement> fromDelta(Map<String, dynamic> delta) {
    final List<IElement> main = <IElement>[];
    // Segmentos da linha corrente, aguardando o '\n' que define os atributos
    // de linha (modelo do Quill: line attributes ficam no terminador).
    final List<IElement> line = <IElement>[];
    bool isFirstLine = true;

    void flushLine(Map<String, dynamic> lineAttributes) {
      final Object? header = lineAttributes['header'];
      final Object? list = lineAttributes['list'];
      final RowFlex? rowFlex = _alignToRowFlex(lineAttributes['align']);
      if (rowFlex != null) {
        for (final IElement element in line) {
          element.rowFlex = rowFlex;
        }
      }
      final String separator = isFirstLine ? '' : '\n';
      isFirstLine = false;

      if (header is int && line.isNotEmpty) {
        if (separator.isNotEmpty) {
          main.add(IElement(value: separator, rowFlex: rowFlex));
        }
        main.add(IElement(
          value: '',
          type: ElementType.title,
          level: _headerToTitleLevel(header),
          rowFlex: rowFlex,
          valueList: List<IElement>.from(line),
        ));
      } else if (list is String && line.isNotEmpty) {
        if (separator.isNotEmpty) {
          main.add(IElement(value: separator, rowFlex: rowFlex));
        }
        main.add(IElement(
          value: '',
          type: ElementType.list,
          listType: list == 'ordered' ? ListType.ordered : ListType.unordered,
          rowFlex: rowFlex,
          valueList: List<IElement>.from(line),
        ));
      } else {
        if (line.isEmpty) {
          if (separator.isNotEmpty) {
            main.add(IElement(value: separator, rowFlex: rowFlex));
          }
        } else {
          line.first.value = '$separator${line.first.value}';
          main.addAll(line);
        }
      }
      line.clear();
    }

    final _TableAccumulator table = _TableAccumulator();

    void flushTable() {
      if (table.isEmpty) return;
      if (!isFirstLine) {
        main.add(IElement(value: '\n'));
      }
      isFirstLine = false;
      main.add(table.build());
      table.reset();
    }

    /// Fecha a linha corrente: linhas de tabela (quill-table-better) são
    /// acumuladas no [_TableAccumulator]; as demais viram parágrafos.
    void endLine(Map<String, dynamic> lineAttributes) {
      final Object? tableCol = lineAttributes['table-col'];
      if (tableCol is Map) {
        table.addColumn(_toDouble(tableCol['width']));
        line.clear();
        return;
      }
      final String? cellId = _cellIdOf(lineAttributes);
      if (cellId != null) {
        final Map<String, dynamic> cellAttributes = <String, dynamic>{
          if (lineAttributes['table-cell'] is Map)
            ...(lineAttributes['table-cell'] as Map).cast<String, dynamic>()
          else if (lineAttributes['table-th'] is Map)
            ...(lineAttributes['table-th'] as Map).cast<String, dynamic>(),
        };
        List<IElement> cellLine = List<IElement>.from(line);
        final Object? tableHeader = lineAttributes['table-header'];
        final Object? tableList = lineAttributes['table-list'];
        if (tableHeader is Map && cellLine.isNotEmpty) {
          cellLine = <IElement>[
            IElement(
              value: '',
              type: ElementType.title,
              level: _headerToTitleLevel(
                  (_parseInt(tableHeader['value']) ?? 1).clamp(1, 6)),
              valueList: cellLine,
            ),
          ];
        } else if (tableList is Map && cellLine.isNotEmpty) {
          final String value = '${tableList['value']}';
          cellLine = <IElement>[
            IElement(
              value: '',
              type: ElementType.list,
              listType:
                  value == 'ordered' ? ListType.ordered : ListType.unordered,
              valueList: cellLine,
            ),
          ];
        }
        table.addLine(
          cellId,
          cellAttributes,
          cellLine,
          isHeaderCell: lineAttributes['table-th'] is Map ||
              lineAttributes.containsKey('table-th-block'),
        );
        line.clear();
        return;
      }
      flushTable();
      flushLine(lineAttributes);
    }

    final Object? rawOps = delta['ops'];
    if (rawOps is! List) return main;
    for (final Object? rawOp in rawOps) {
      if (rawOp is! Map) continue;
      final Object? insert = rawOp['insert'];
      final Map<String, dynamic> attributes = <String, dynamic>{
        if (rawOp['attributes'] is Map)
          ...(rawOp['attributes'] as Map).cast<String, dynamic>(),
      };

      if (insert is Map) {
        final Object? image = insert['image'];
        if (image is String) {
          line.add(IElement(
            value: image,
            type: ElementType.image,
            width: _toDouble(attributes['width']),
            height: _toDouble(attributes['height']),
          ));
        }
        continue;
      }
      if (insert is! String) continue;

      int start = 0;
      for (int i = 0; i < insert.length; i++) {
        if (insert[i] == '\n') {
          final String text = insert.substring(start, i);
          if (text.isNotEmpty) {
            line.add(_textElement(text, attributes));
          }
          endLine(attributes);
          start = i + 1;
        }
      }
      final String tail = insert.substring(start);
      if (tail.isNotEmpty) {
        line.add(_textElement(tail, attributes));
      }
    }
    if (line.isNotEmpty) {
      endLine(const <String, dynamic>{});
    }
    flushTable();
    if (main.isEmpty) {
      main.add(IElement(value: ''));
    }
    return main;
  }

  /// Extrai o cellId de uma linha de tabela do quill-table-better. Blocos de
  /// célula podem ser `table-cell-block`/`table-th-block` (valor = cellId)
  /// ou `table-header`/`table-list` (valor = `{cellId, value}`).
  static String? _cellIdOf(Map<String, dynamic> attributes) {
    final Object? block =
        attributes['table-cell-block'] ?? attributes['table-th-block'];
    if (block is String && block.isNotEmpty) return block;
    if (block is Map) return block['cellId'] as String?;
    final Object? wrapped =
        attributes['table-header'] ?? attributes['table-list'];
    if (wrapped is Map) return wrapped['cellId'] as String?;
    // Célula sem bloco identificado, mas com props de TD: usa o data-row
    // como agrupador de fallback.
    final Object? cell = attributes['table-cell'] ?? attributes['table-th'];
    if (cell is Map) {
      final Object? dataRow = cell['data-row'];
      if (dataRow is String) return 'cell-$dataRow';
    }
    return null;
  }

  static IElement _textElement(String text, Map<String, dynamic> attributes) {
    final Object? link = attributes['link'];
    final Object? script = attributes['script'];
    final IElement element = IElement(
      value: text,
      bold: attributes['bold'] == true ? true : null,
      italic: attributes['italic'] == true ? true : null,
      underline: attributes['underline'] == true ? true : null,
      strikeout: attributes['strike'] == true ? true : null,
      color: attributes['color'] as String?,
      highlight: attributes['background'] as String?,
      font: attributes['font'] as String?,
      size: _parseSize(attributes['size']),
      type: script == 'super'
          ? ElementType.superscript
          : script == 'sub'
              ? ElementType.subscript
              : null,
    );
    if (link is String && link.isNotEmpty) {
      return IElement(
        value: '',
        type: ElementType.hyperlink,
        url: link,
        valueList: <IElement>[element],
      );
    }
    return element;
  }

  static RowFlex? _alignToRowFlex(Object? align) {
    switch (align) {
      case 'center':
        return RowFlex.center;
      case 'right':
        return RowFlex.right;
      case 'justify':
        return RowFlex.alignment;
      default:
        return null;
    }
  }

  static TitleLevel _headerToTitleLevel(int header) {
    switch (header) {
      case 1:
        return TitleLevel.first;
      case 2:
        return TitleLevel.second;
      case 3:
        return TitleLevel.third;
      case 4:
        return TitleLevel.fourth;
      case 5:
        return TitleLevel.fifth;
      default:
        return TitleLevel.sixth;
    }
  }

  static int? _parseSize(Object? size) {
    if (size is num) return size.round();
    if (size is String) {
      final String cleaned =
          size.endsWith('px') ? size.substring(0, size.length - 2) : size;
      return int.tryParse(cleaned);
    }
    return null;
  }

  static double? _toDouble(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) {
      final String cleaned =
          value.endsWith('px') ? value.substring(0, value.length - 2) : value;
      return double.tryParse(cleaned);
    }
    return null;
  }

  static int? _parseInt(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse('$value');
  }
}

/// Reconstrói um elemento de tabela do editor a partir das linhas de célula
/// do quill-table-better (`table-col` + `table-cell-block`/`table-cell`).
class _TableAccumulator {
  final List<double?> _columnWidths = <double?>[];

  /// Linhas na ordem de chegada (`data-row` → células); células na ordem de
  /// chegada (`cellId` → parágrafos acumulados).
  final LinkedHashMap<String, _RowAccumulator> _rows =
      LinkedHashMap<String, _RowAccumulator>();

  bool get isEmpty => _columnWidths.isEmpty && _rows.isEmpty;

  void addColumn(double? width) {
    _columnWidths.add(width);
  }

  void addLine(String cellId, Map<String, dynamic> cellAttributes,
      List<IElement> lineElements,
      {bool isHeaderCell = false}) {
    final String rowKey = cellAttributes['data-row'] as String? ?? cellId;
    final _RowAccumulator row = _rows.putIfAbsent(rowKey, _RowAccumulator.new);
    final double? height = _parsePx(cellAttributes['height']);
    if (height != null) {
      row.height = height;
    }
    final _CellAccumulator cell =
        row.cells.putIfAbsent(cellId, _CellAccumulator.new);
    cell
      ..colspan = _parseInt(cellAttributes['colspan']) ?? cell.colspan
      ..rowspan = _parseInt(cellAttributes['rowspan']) ?? cell.rowspan
      ..width = _parsePx(cellAttributes['width']) ?? cell.width
      ..backgroundColor =
          _backgroundColor(cellAttributes['style']) ?? cell.backgroundColor
      ..isHeaderCell = isHeaderCell || cell.isHeaderCell
      ..paragraphs.add(lineElements);
  }

  IElement build() {
    const double defaultColumnWidth = 72;
    int columnCount = _columnWidths.length;
    if (columnCount == 0) {
      for (final _RowAccumulator row in _rows.values) {
        int cols = 0;
        for (final _CellAccumulator cell in row.cells.values) {
          cols += cell.colspan;
        }
        if (cols > columnCount) columnCount = cols;
      }
    }
    final List<IColgroup> colgroup = <IColgroup>[
      for (int c = 0; c < columnCount; c++)
        IColgroup(
          width: c < _columnWidths.length
              ? _columnWidths[c] ?? defaultColumnWidth
              : defaultColumnWidth,
        ),
    ];

    final List<ITr> trList = <ITr>[];
    for (final _RowAccumulator row in _rows.values) {
      final List<ITd> tdList = <ITd>[];
      for (final _CellAccumulator cell in row.cells.values) {
        final List<IElement> value = <IElement>[];
        for (final List<IElement> paragraph in cell.paragraphs) {
          if (value.isNotEmpty) {
            value.add(IElement(value: '\n'));
          }
          value.addAll(paragraph);
        }
        if (value.isEmpty) {
          value.add(IElement(value: ''));
        }
        tdList.add(ITd(
          colspan: cell.colspan,
          rowspan: cell.rowspan,
          width: cell.width,
          backgroundColor: cell.backgroundColor,
          extension: cell.isHeaderCell
              ? <String, dynamic>{'quillTableHeader': true}
              : null,
          value: value,
        ));
      }
      trList.add(ITr(
        height: row.height ?? 42,
        minHeight: 16,
        tdList: tdList,
      ));
    }

    return IElement(
      type: ElementType.table,
      value: '',
      colgroup: colgroup,
      trList: trList,
      borderType: TableBorder.all,
    );
  }

  void reset() {
    _columnWidths.clear();
    _rows.clear();
  }

  static int? _parseInt(Object? value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double? _parsePx(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) {
      final String cleaned =
          value.endsWith('px') ? value.substring(0, value.length - 2) : value;
      return double.tryParse(cleaned);
    }
    return null;
  }

  static String? _backgroundColor(Object? style) {
    if (style is! String) return null;
    final Match? match =
        RegExp(r'background-color\s*:\s*([^;]+)', caseSensitive: false)
            .firstMatch(style);
    return match?.group(1)?.trim();
  }
}

class _RowAccumulator {
  double? height;
  final LinkedHashMap<String, _CellAccumulator> cells =
      LinkedHashMap<String, _CellAccumulator>();
}

class _CellAccumulator {
  int colspan = 1;
  int rowspan = 1;
  double? width;
  String? backgroundColor;
  bool isHeaderCell = false;
  final List<List<IElement>> paragraphs = <List<IElement>>[];
}
