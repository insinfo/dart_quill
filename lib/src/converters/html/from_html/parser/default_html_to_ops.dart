// ignore_for_file: unnecessary_import

// ignore: unused_import
import 'dart:math';

import '../../../../delta/delta.dart';
import '../delta_from_html.dart';
import 'extensions/node_ext.dart';
import 'html_to_operation.dart';
import 'html_utils.dart';
import 'typedef/typedefs.dart';
import 'package:html/dom.dart' as dom;
import 'node_processor.dart';

/// Implementação padrão para converter HTML comum em operações Delta.
class DefaultHtmlToOperations extends HtmlOperations {
  final CSSVarible? onDetectLineheightCssVariable;

  DefaultHtmlToOperations(this.onDetectLineheightCssVariable);

  @override
  List<Operation> paragraphToOp(dom.Element element) {
    final Delta delta = Delta();
    final attributes = element.attributes;
    Map<String, dynamic> inlineAttributes = {};
    Map<String, dynamic> blockAttributes = {};

    // Parse style/align/dir
    if (attributes.containsKey('style') ||
        attributes.containsKey('align') ||
        attributes.containsKey('dir')) {
      final style = attributes['style'] ?? '';
      final alignAttr = attributes['align'] ?? '';
      final dirAttr = attributes['dir'] ?? '';

      final styleAttributes = parseStyleAttribute(
        element.localName!,
        style,
        onDetectLineheightCssVariable: onDetectLineheightCssVariable,
      );
      final alignAttributes = parseStyleAttribute(
        element.localName!,
        alignAttr,
        onDetectLineheightCssVariable: onDetectLineheightCssVariable,
      );
      final dirAttributes = parseStyleAttribute(
        element.localName!,
        dirAttr,
        onDetectLineheightCssVariable: onDetectLineheightCssVariable,
      );

      styleAttributes.addAll({...alignAttributes, ...dirAttributes});

      if (styleAttributes.containsKey('align') ||
          styleAttributes.containsKey('direction') ||
          styleAttributes.containsKey('indent')) {
        blockAttributes['align'] = styleAttributes['align'];
        blockAttributes['direction'] = styleAttributes['direction'];
        blockAttributes['indent'] = styleAttributes['indent'];
        styleAttributes.remove('align');
        styleAttributes.remove('direction');
        styleAttributes.remove('indent');
      }
      inlineAttributes.addAll(styleAttributes);
    }

    // Render do conteúdo inline
    final nodes = element.nodes;
    // <p><br></p> é UMA linha em branco: processar o <br> (que vira newline)
    // e ainda fechar o parágrafo com outro newline dobrava as linhas em
    // branco a cada ciclo export -> import (H6).
    final isBlankParagraph = nodes.isNotEmpty &&
        nodes.every((n) =>
            (n is dom.Element && n.isBreakLine) ||
            (n.nodeType == dom.Node.TEXT_NODE &&
                (n.text ?? '').trim().isEmpty));
    if (isBlankParagraph) {
      delta.insert('\n');
      return delta.toList();
    }
    for (final node in nodes) {
      processNode(
        node,
        inlineAttributes,
        delta,
        addSpanAttrs: true,
        customBlocks: customBlocks,
        onDetectLineheightCssVariable: onDetectLineheightCssVariable,
      );
    }

    // Checa se há conteúdo visível (texto não-vazio ou tags não-<br> com texto)
    bool hasVisible = nodes.any((n) =>
            n.nodeType == dom.Node.TEXT_NODE &&
            n.text?.trim().isNotEmpty == true) ||
        nodes.any((n) =>
            n.nodeType == dom.Node.ELEMENT_NODE &&
            !(n as dom.Element).isBreakLine &&
            (n.text.trim().isNotEmpty));

    // Se o parágrafo for "vazio", insira \n sem atributos de bloco
    if (!hasVisible) {
      delta.insert('\n');
    } else if (blockAttributes.isNotEmpty) {
      blockAttributes.removeWhere((k, v) => v == null);
      delta.insert('\n', blockAttributes);
    } else {
      delta.insert('\n');
    }

    return delta.toList();
  }

  @override
  List<Operation> spanToOp(dom.Element element) {
    final Delta delta = Delta();
    Map<String, dynamic> inlineAttributes = {};

    // style
    if (element.attributes.containsKey('style')) {
      final style = element.attributes['style'] ?? '';
      final styleAttributes = parseStyleAttribute(
        element.localName!,
        style,
        onDetectLineheightCssVariable: onDetectLineheightCssVariable,
      );
      // 'align' é atributo de bloco; não aplicar em inline
      styleAttributes.remove('align');
      inlineAttributes.addAll(styleAttributes);
    }

    for (final node in element.nodes) {
      processNode(
        node,
        inlineAttributes,
        delta,
        addSpanAttrs: false,
        customBlocks: customBlocks,
        onDetectLineheightCssVariable: onDetectLineheightCssVariable,
      );
    }

    return delta.toList();
  }

  @override
  List<Operation> linkToOp(dom.Element element) {
    final Delta delta = Delta();
    Map<String, dynamic> attributes = {};

    if (element.attributes.containsKey('href')) {
      attributes['link'] = element.attributes['href'];
    }

    for (final node in element.nodes) {
      processNode(
        node,
        attributes,
        delta,
        onDetectLineheightCssVariable: onDetectLineheightCssVariable,
      );
    }
    return delta.toList();
  }

  @override
  List<Operation> headerToOp(dom.Element element) {
    final Delta delta = Delta();
    Map<String, dynamic> inlineAttributes = {};
    Map<String, dynamic> blockAttributes = {};

    if (element.attributes.containsKey('style') ||
        element.attributes.containsKey('align') ||
        element.attributes.containsKey('dir')) {
      final style = element.getSafeAttribute('style');
      final alignAttr = element.getSafeAttribute('align');
      final dirAttr = element.getSafeAttribute('dir');

      final styleAttributes = parseStyleAttribute(
        element.localName!,
        style,
        onDetectLineheightCssVariable: onDetectLineheightCssVariable,
      );
      final alignAttributes = parseStyleAttribute(
        element.localName!,
        alignAttr,
        onDetectLineheightCssVariable: onDetectLineheightCssVariable,
      );
      final dirAttributes = parseStyleAttribute(
        element.localName!,
        dirAttr,
        onDetectLineheightCssVariable: onDetectLineheightCssVariable,
      );

      styleAttributes.addAll({...alignAttributes, ...dirAttributes});

      if (styleAttributes.containsKey('align') ||
          styleAttributes.containsKey('direction') ||
          styleAttributes.containsKey('indent')) {
        blockAttributes['align'] = styleAttributes['align'];
        blockAttributes['direction'] = styleAttributes['direction'];
        blockAttributes['indent'] = styleAttributes['indent'];
        styleAttributes.remove('align');
        styleAttributes.remove('direction');
        styleAttributes.remove('indent');
      }
      inlineAttributes.addAll(styleAttributes);
    }

    final headerLevel = element.localName ?? 'h1';
    blockAttributes['header'] = int.parse(headerLevel.substring(1));

    for (final node in element.nodes) {
      processNode(
        node,
        inlineAttributes,
        delta,
        addSpanAttrs: true,
        removeTheseAttributesFromSpan: ['size'],
        onDetectLineheightCssVariable: onDetectLineheightCssVariable,
      );
    }

    if (blockAttributes.isNotEmpty) {
      blockAttributes.removeWhere((k, v) => v == null);
      delta.insert('\n', blockAttributes);
    }
    return delta.toList();
  }

  @override
  List<Operation> divToOp(dom.Element element) {
    final Delta delta = Delta();
    Map<String, dynamic> inlineAttributes = {};

    if (element.attributes.containsKey('style')) {
      final style = element.attributes['style'] ?? '';
      final styleAttributes = parseStyleAttribute(
        element.localName!,
        style,
        onDetectLineheightCssVariable: onDetectLineheightCssVariable,
      );
      inlineAttributes.addAll(styleAttributes..remove('align'));
    }

    for (final node in element.nodes) {
      if (node.nodeType == dom.Node.TEXT_NODE) {
        delta.insert(node.text);
      } else if (node.nodeType == dom.Node.ELEMENT_NODE) {
        final ops = resolveCurrentElement(node as dom.Element);
        for (final op in ops) {
          delta.insert(op.data, op.attributes);
        }
        if (node.isParagraph) {
          delta.insert('\n');
        }
      }
    }
    return delta.toList();
  }

  @override
  List<Operation> listToOp(dom.Element element, [int indentLevel = 0]) {
    final Delta delta = Delta();
    final tagName = element.localName ?? 'ul';
    final Map<String, dynamic> blockAttrs = {};
    final List<dom.Element> items =
        element.children.where((c) => c.localName == 'li').toList();

    if (tagName == 'ul') {
      blockAttrs['list'] = 'bullet';
    } else if (tagName == 'ol') {
      blockAttrs['list'] = 'ordered';
    }

    final checkbox = element.querySelector('input[type="checkbox"]');
    if (checkbox != null) {
      blockAttrs['list'] =
          checkbox.attributes.containsKey('checked') ? 'checked' : 'unchecked';
    }

    for (final item in items) {
      int effectiveIndent = indentLevel;
      bool insertedBlockBreak = false;

      if (checkbox == null) {
        final dataChecked = item.getSafeAttribute('data-checked');
        final attr = parseStyleAttribute(
          element.localName!,
          dataChecked,
          onDetectLineheightCssVariable: onDetectLineheightCssVariable,
        );
        if (attr.containsKey('list')) {
          blockAttrs['list'] = attr['list'];
        }
      }

      if (indentLevel > 5) indentLevel = 5;
      if (indentLevel > 0) blockAttrs['indent'] = indentLevel;

      for (final node in item.nodes) {
        if (node.nodeType == dom.Node.TEXT_NODE) {
          delta.insert(node.text);
        } else if (node.nodeType == dom.Node.ELEMENT_NODE) {
          final el = node as dom.Element;
          // lista aninhada
          if (el.isList) {
            effectiveIndent++;
            delta.insert('\n', blockAttrs);
            insertedBlockBreak = true;
          }
          final ops = resolveCurrentElement(el, effectiveIndent);
          for (final op in ops) {
            delta.insert(op.data, op.attributes);
          }
        }
      }

      if (!insertedBlockBreak) delta.insert('\n', blockAttrs);
    }

    return delta.toList();
  }

  @override
  List<Operation> imgToOp(dom.Element element) {
    final src = element.getSafeAttribute('src');
    final styles = element.getSafeAttribute('style');
    final align = element.getSafeAttribute('align');

    final attributes = parseImageStyleAttribute(styles, align);
    if (src.isNotEmpty) {
      return [
        Operation.insert(
          {'image': src},
          styles.isEmpty
              ? null
              : {
                  'style': attributes.entries
                      .map((e) => '${e.key}:${e.value}')
                      .join(';'),
                },
        ),
      ];
    }
    return [];
  }

  @override
  List<Operation> videoToOp(dom.Element element) {
    final src = element.attributes['src'];
    final sourceSrc = element.nodes
        .where((n) => n.nodeType == dom.Node.ELEMENT_NODE)
        .firstOrNull
        ?.attributes['src'];

    final link = (src != null && src.isNotEmpty)
        ? src
        : (sourceSrc != null && sourceSrc.isNotEmpty ? sourceSrc : null);

    if (link != null) {
      return [
        Operation.insert({'video': link})
      ];
    }
    return [];
  }

  @override
  List<Operation> blockquoteToOp(dom.Element element) {
    final Delta delta = Delta();
    for (final node in element.nodes) {
      processNode(
        node,
        const {},
        delta,
        onDetectLineheightCssVariable: onDetectLineheightCssVariable,
      );
    }
    delta.insert('\n', {'blockquote': true});
    return delta.toList();
  }

  @override
  List<Operation> codeblockToOp(dom.Element element) {
    final Delta delta = Delta();
    for (final node in element.nodes) {
      processNode(
        node,
        const {},
        delta,
        onDetectLineheightCssVariable: onDetectLineheightCssVariable,
      );
    }
    delta.insert('\n', {'code-block': true});
    return delta.toList();
  }

  @override
  List<Operation> brToOp(dom.Element element) => [Operation.insert('\n')];

  // ---------------------------------------------------------------------------
  //  TABELA (compatível com o seu export "TableBetter")
  // ---------------------------------------------------------------------------

  /// Converte <table> → Delta compatível com o plugin (table-temporary + table-cell)
  @override
  List<Operation> tableToOp(dom.Element table, [bool _ = false]) {
    final ops = <Operation>[];

    void addInsert(String text, [Map<String, dynamic>? attrs]) {
      if (attrs != null && attrs.isNotEmpty) {
        ops.add(Operation.insert(text, attrs));
      } else {
        ops.add(Operation.insert(text));
      }
    }

    // ---------- 1) Op-âncora "table-temporary" ----------
    final styleAttr = (table.getAttribute('style') ?? '').trim();

    String css(String prop, String fallback) {
      final m = RegExp('$prop\\s*:\\s*([^;]+)', caseSensitive: false)
          .firstMatch(styleAttr);
      return (m != null ? m.group(1)!.trim() : fallback);
    }

    final anchor = <String, dynamic>{
      'border': (table.getAttribute('border') ?? '0').toString(),
      'cellspacing': (table.getAttribute('cellspacing') ?? '0').toString(),
      'style': 'margin-left: ${css('margin-left', '1cm')}; '
          'border-collapse: collapse; '
          'width: ${css('width', '100%')};',
      'data-class': table.classes.join(' ').trim(),
    };

    addInsert('\n', {'table-temporary': anchor});

    String onlyNumber(String v) => v.replaceAll(RegExp(r'[^0-9.]'), '');

    // ---------- 2) <colgroup> vira table-col (H6) ----------
    // Sem isto as larguras de coluna do HTML exportado não voltavam ao
    // editor nem ao PDF — só a largura por célula sobrevivia.
    for (final col in table.querySelectorAll('colgroup col')) {
      final rawWidth = (col.attributes['width'] ?? '').trim().isNotEmpty
          ? col.attributes['width']!.trim()
          : (RegExp(r'width\s*:\s*([^;]+)', caseSensitive: false)
                  .firstMatch(col.attributes['style'] ?? '')
                  ?.group(1) ??
              '');
      final width = onlyNumber(rawWidth);
      if (width.isNotEmpty) {
        addInsert('\n', {
          'table-col': {'width': width}
        });
      }
    }

    // ---------- 3) Células ----------
    final scope = table.querySelector('tbody') ?? table;
    final rows = scope.querySelectorAll('tr');

    // Ocupação de colunas por rowspan (H6): uma célula mesclada ocupa a
    // MESMA coluna nas linhas seguintes; sem a grade o índice de bloco das
    // células dessas linhas escorregava para a esquerda.
    final occupied = <int>[];

    for (var r = 0; r < rows.length; r++) {
      final row = rows[r];

      // Round-trip estável (H6): o id de linha é uma string opaca; quando o
      // HTML traz o original (`data-row`), ele volta intacto em vez de ser
      // reindexado — reimportar o próprio export não muda o Delta.
      final rowId = (row.attributes['data-row'] ?? '').trim().isNotEmpty
          ? row.attributes['data-row']!.trim()
          : (r + 1).toString();

      // mantém ordem real th/td
      final cells = <dom.Element>[
        for (final c in row.children)
          if (c.localName == 'th' || c.localName == 'td') c
      ];

      var column = 0; // índice de coluna real, contando ocupação de rowspan

      for (final cell in cells) {
        while (column < occupied.length && occupied[column] > 0) {
          column++;
        }
        final cellStyle = (cell.getAttribute('style') ?? '').trim();

        final rowspan = (cell.getAttribute('rowspan') ?? '').trim();
        final colspan = (cell.getAttribute('colspan') ?? '').trim();
        final colSpanN = int.tryParse(colspan.isEmpty ? '1' : colspan) ?? 1;
        final rowSpanN = int.tryParse(rowspan.isEmpty ? '1' : rowspan) ?? 1;

        // align
        var align = 'center';
        final am = RegExp(r'text-align\s*:\s*(left|right|center|justify)',
                caseSensitive: false)
            .firstMatch(cellStyle);
        if (am != null) align = am.group(1)!.toLowerCase();

        // width (sempre STRING no delta alvo)
        String width = '';
        final wAttr = cell.getAttribute('width');
        if (wAttr != null && wAttr.trim().isNotEmpty) {
          width = onlyNumber(wAttr);
        } else {
          final wm = RegExp(r'width\s*:\s*([^;]+)', caseSensitive: false)
              .firstMatch(cellStyle);
          if (wm != null) width = onlyNumber(wm.group(1)!);
        }

        final tableCell = <String, String>{
          'data-row': rowId,
          'width': width,
          'style': cellStyle,
        };
        if (rowspan.isNotEmpty) tableCell['rowspan'] = rowspan;
        if (colspan.isNotEmpty) tableCell['colspan'] = colspan;

        // Id de célula: o original quando o HTML o traz (`data-cell`),
        // senão o índice de coluna real (1-based).
        final cellId = (cell.attributes['data-cell'] ?? '').trim().isNotEmpty
            ? cell.attributes['data-cell']!.trim()
            : (column + 1).toString();
        final cellLineAttrs = <String, dynamic>{
          'table-cell-block': cellId,
          'table-cell': tableCell,
          'align': align,
        };

        // Conteúdo RICO da célula (H6): antes era `cell.text` com um bold
        // único para a célula toda — links, cores, itálico parcial e
        // múltiplos parágrafos se perdiam. Cada bloco interno vira uma
        // linha da MESMA célula (mesmo table-cell-block), o dialeto do
        // editor para célula multi-bloco.
        final cellDelta = Delta();
        void processCellNode(dom.Node node) {
          if (node is dom.Element &&
              const ['p', 'div', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'li']
                  .contains(node.localName)) {
            for (final child in node.nodes) {
              processNode(child, const {}, cellDelta,
                  addSpanAttrs: true,
                  onDetectLineheightCssVariable:
                      onDetectLineheightCssVariable);
            }
            cellDelta.insert('\n');
            return;
          }
          processNode(node, const {}, cellDelta,
              addSpanAttrs: true,
              onDetectLineheightCssVariable: onDetectLineheightCssVariable);
        }

        for (final node in cell.nodes) {
          processCellNode(node);
        }

        var wroteLine = false;
        for (final op in cellDelta.toList()) {
          final data = op.data;
          if (data is! String) {
            ops.add(op);
            continue;
          }
          var rest = data;
          while (rest.contains('\n')) {
            final index = rest.indexOf('\n');
            final before = rest.substring(0, index);
            if (before.trim().isNotEmpty) {
              addInsert(before, op.attributes);
            }
            addInsert('\n', cellLineAttrs);
            wroteLine = true;
            rest = rest.substring(index + 1);
          }
          if (rest.trim().isNotEmpty) {
            addInsert(rest, op.attributes);
            wroteLine = false;
          }
        }
        // Fecha a última linha da célula (ou uma célula vazia).
        final lastOp = ops.isEmpty ? null : ops.last;
        final closed = wroteLine &&
            lastOp != null &&
            lastOp.data == '\n' &&
            lastOp.attributes?['table-cell-block'] == cellId;
        if (!closed) {
          addInsert('\n', cellLineAttrs);
        }

        // marca a ocupação desta célula na grade
        while (occupied.length < column + colSpanN) {
          occupied.add(0);
        }
        if (rowSpanN > 1) {
          for (var c = column; c < column + colSpanN; c++) {
            occupied[c] = rowSpanN;
          }
        }
        column += colSpanN;
      }

      for (var c = 0; c < occupied.length; c++) {
        if (occupied[c] > 0) occupied[c]--;
      }
    }

    return ops;
  }

  // ---------------------------------------------------------------------------
  //  RESOLVER principal (com tratamento especial para tabela)
  // ---------------------------------------------------------------------------

  @override
  List<Operation> resolveCurrentElement(
    dom.Element element, [
    int indentLevel = 0,
    bool transformTableAsEmbed = false,
  ]) {
    List<Operation> ops = [];
    if (element.localName == null) {
      return ops..add(Operation.insert(element.text));
    }

    // Tabela: deixe para tableToOp
    if (element.localName == 'table') return tableToOp(element);
    if (['tbody', 'thead', 'tfoot', 'tr', 'td', 'th']
        .contains(element.localName)) {
      return ops; // ignora: já processado por tableToOp
    }

    // Inlines
    if (isInline(element.localName!)) {
      final Delta delta = Delta();
      final Map<String, dynamic> attributes = {};
      if (element.isStrong) attributes['bold'] = true;
      if (element.isItalic) attributes['italic'] = true;
      if (element.isUnderline) attributes['underline'] = true;
      if (element.isStrike) attributes['strike'] = true;
      if (element.isSubscript) attributes['script'] = 'sub';
      if (element.isSuperscript) attributes['script'] = 'super';
      if (element.attributes.containsKey('style')) {
        final styleAttributes = parseStyleAttribute(
          element.localName!,
          element.attributes['style']!,
          onDetectLineheightCssVariable: onDetectLineheightCssVariable,
        )..removeWhere(
            (k, v) => k == 'align' || k == 'direction' || k == 'indent');
        attributes.addAll(styleAttributes);
      }
      for (final node in element.nodes) {
        processNode(
          node,
          attributes,
          delta,
          customBlocks: customBlocks,
          onDetectLineheightCssVariable: onDetectLineheightCssVariable,
        );
      }
      ops.addAll(delta.toList());
    }

    // Blocos (não-tabela)
    if (element.isBreakLine) ops.addAll(brToOp(element));
    if (element.isParagraph) ops.addAll(paragraphToOp(element));
    if (element.isHeader) ops.addAll(headerToOp(element));
    if (element.isList) ops.addAll(listToOp(element, indentLevel));
    if (element.isSpan) ops.addAll(spanToOp(element));
    if (element.isLink) ops.addAll(linkToOp(element));
    if (element.isImg) ops.addAll(imgToOp(element));
    if (element.isVideo) ops.addAll(videoToOp(element));
    if (element.isBlockquote) ops.addAll(blockquoteToOp(element));
    if (element.isCodeBlock) ops.addAll(codeblockToOp(element));
    if (element.isDivBlock) ops.addAll(divToOp(element));

    return ops;
  }
}
