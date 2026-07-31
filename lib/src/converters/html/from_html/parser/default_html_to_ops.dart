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

    // ---------- 2) Células ----------
    final scope = table.querySelector('tbody') ?? table;
    final rows = scope.querySelectorAll('tr');

    String onlyNumber(String v) => v.replaceAll(RegExp(r'[^0-9.]'), '');

    for (var r = 0; r < rows.length; r++) {
      final row = rows[r];

      // mantém ordem real th/td
      final cells = <dom.Element>[
        for (final c in row.children)
          if (c.localName == 'th' || c.localName == 'td') c
      ];

      var block = 1; // table-cell-block inicia em 1 por linha

      for (final cell in cells) {
        final cellStyle = (cell.getAttribute('style') ?? '').trim();

        // texto da célula (bold se tiver <strong>/<b>)
        final rawText = cell.text;
        final text = rawText.trim();
        if (text.isNotEmpty) {
          final hasBold = cell.querySelector('strong,b') != null;
          addInsert(text, hasBold ? {'bold': true} : null);
        }

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

        final rowspan = (cell.getAttribute('rowspan') ?? '').trim();
        final colspan = (cell.getAttribute('colspan') ?? '').trim();

        final tableCell = <String, String>{
          'data-row': (r + 1).toString(),
          'width': width,
          'style': cellStyle,
        };
        if (rowspan.isNotEmpty) tableCell['rowspan'] = rowspan;
        if (colspan.isNotEmpty) tableCell['colspan'] = colspan;

        // fecha a célula com '\n' + atributos da linha/célula
        addInsert('\n', {
          'table-cell-block': block.toString(), // STRING, igual ao seu delta
          'table-cell': tableCell, // todos valores como STRING
          'align': align,
        });

        // avança block respeitando colspan
        final span = int.tryParse(colspan.isEmpty ? '1' : colspan) ?? 1;
        block += span;
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
