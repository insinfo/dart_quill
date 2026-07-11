// Bridge editor → DOCX (roteiro_editor_profissional, F3.3).
//
// Sincroniza o conteúdo atual do editor (IElement[]) de volta ao modelo
// WordprocessingML aberto, mantendo o passthrough D1: blocos cujo conteúdo
// não mudou desde a abertura re-usam o bloco original (XML byte a byte);
// blocos editados/novos são regenerados a partir dos elementos.

import 'dart:convert';

import '../ce_docx.dart';
import '../ce_opc.dart';

import '../editor/dataset/enum/element.dart';
import '../editor/dataset/enum/row.dart';
import '../editor/dataset/enum/title.dart';
import '../editor/interface/element.dart';
import '../editor/interface/table/td.dart';

const String _zwsp = '​';

class EditorToDocx {
  final DocxFile file;
  final List<String> notes = [];
  int _docPrId = 1000;

  EditorToDocx._(this.file);

  /// Aplica [current] (conteúdo atual do editor) ao modelo de [file].
  /// [original] é a lista convertida na abertura — referência de "intocado".
  /// Retorna notas de fidelidade.
  static List<String> apply(
      DocxFile file, List<IElement> current, List<IElement> original) {
    final sync = EditorToDocx._(file);
    sync._apply(current, original);
    return sync.notes;
  }

  void _apply(List<IElement> current, List<IElement> original) {
    final currentSpecs = _split(current);
    final originalSpecs = <int, _BlockSpec>{};
    for (final spec in _split(original)) {
      final stamp = spec.stamp;
      if (stamp != null) originalSpecs[stamp] = spec;
    }

    final body = file.document.body;
    final preservedIndices = <int>[
      for (var i = 0; i < body.length; i++)
        if (body[i] is WpPreservedBlock) i
    ];
    var preservedCursor = 0;

    final newBody = <WpBlock>[];
    for (final spec in currentSpecs) {
      final stamp = spec.stamp;
      // Reinsere blocos preservados (bookmarks etc.) que vinham antes
      // deste bloco no body original.
      if (stamp != null) {
        while (preservedCursor < preservedIndices.length &&
            preservedIndices[preservedCursor] < stamp) {
          newBody.add(body[preservedIndices[preservedCursor]]);
          preservedCursor++;
        }
      }

      final originalBlock =
          stamp != null && stamp < body.length ? body[stamp] : null;
      final originalSpec = stamp != null ? originalSpecs[stamp] : null;

      if (originalBlock != null &&
          originalSpec != null &&
          _specsEqual(spec, originalSpec)) {
        newBody.add(originalBlock); // passthrough D1
        continue;
      }

      // Primeiro parágrafo vazio do documento: não tem separador antes,
      // logo não tem stamp — casa por posição quando intocado.
      if (stamp == null &&
          spec.table == null &&
          _meaningful(spec.elements).isEmpty &&
          newBody.length < body.length) {
        final positional = body[newBody.length];
        if (positional is WpParagraph && positional.text.isEmpty) {
          newBody.add(positional);
          continue;
        }
      }

      if (spec.table != null) {
        newBody.add(_tableFromElement(
            spec.table!, originalBlock is WpTable ? originalBlock : null));
      } else {
        newBody.add(_paragraphFromElements(spec.elements,
            originalBlock is WpParagraph ? originalBlock.properties : null));
      }
    }
    while (preservedCursor < preservedIndices.length) {
      newBody.add(body[preservedIndices[preservedCursor]]);
      preservedCursor++;
    }

    body
      ..clear()
      ..addAll(newBody);
  }

  // ---------------------------------------------------------------------
  // Split: lista plana do editor → especificações de bloco
  // ---------------------------------------------------------------------

  List<_BlockSpec> _split(List<IElement> elements) {
    final specs = <_BlockSpec>[];
    var currentElements = <IElement>[];
    var emittedSinceSeparator = false;
    var sawSeparator = false;

    // O separador '\n' que abre o bloco i carrega o stamp wp:i — é a única
    // fonte de identidade para parágrafos VAZIOS (que não têm elementos).
    int? previousSeparatorStamp;

    void flushParagraph() {
      specs.add(_BlockSpec.paragraph(currentElements,
          fallbackStamp: previousSeparatorStamp));
      currentElements = [];
      emittedSinceSeparator = true;
    }

    for (final element in _expandNewlines(elements)) {
      final isSeparator = element.type == null &&
          element.value == '\n' &&
          !_hasFlag(element, 'wpBr');
      if (isSeparator) {
        if (currentElements.isNotEmpty) {
          flushParagraph();
        } else if (!emittedSinceSeparator) {
          specs.add(_BlockSpec.paragraph(const [],
              fallbackStamp: previousSeparatorStamp));
        }
        emittedSinceSeparator = false;
        sawSeparator = true;
        previousSeparatorStamp = _stampOf(element);
        continue;
      }
      if (element.type == ElementType.table) {
        if (currentElements.isNotEmpty) flushParagraph();
        specs.add(_BlockSpec.table(element));
        emittedSinceSeparator = true;
        continue;
      }
      if (element.type == ElementType.list) {
        if (currentElements.isNotEmpty) flushParagraph();
        notes.add('lista criada no editor exportada como parágrafos');
        var item = <IElement>[];
        for (final child in element.valueList ?? const <IElement>[]) {
          if (child.type == null && child.value == '\n') {
            specs.add(_BlockSpec.paragraph(item));
            item = [];
          } else {
            item.add(child);
          }
        }
        specs.add(_BlockSpec.paragraph(item));
        emittedSinceSeparator = true;
        continue;
      }
      currentElements.add(element);
    }
    if (currentElements.isNotEmpty) {
      flushParagraph();
    } else if (sawSeparator && !emittedSinceSeparator) {
      specs.add(_BlockSpec.paragraph(const [],
          fallbackStamp: previousSeparatorStamp));
    }
    return specs;
  }

  /// O zip do editor pode fundir '\n' dentro de values multi-caractere
  /// (ZERO→'\n', Enter digitado). Expande esses values em elementos
  /// separados para o split enxergar os separadores de bloco.
  static List<IElement> _expandNewlines(List<IElement> elements) {
    List<IElement>? expanded;
    for (var i = 0; i < elements.length; i++) {
      final element = elements[i];
      final isPlainText =
          element.type == null || element.type == ElementType.text;
      if (!isPlainText ||
          _hasFlag(element, 'wpBr') ||
          element.value == '\n' ||
          !element.value.contains('\n')) {
        expanded?.add(element);
        continue;
      }
      expanded ??= [...elements.sublist(0, i)];
      final parts = element.value.split('\n');
      for (var p = 0; p < parts.length; p++) {
        if (p > 0) {
          expanded.add(IElement(value: '\n')..externalId = element.externalId);
        }
        if (parts[p].isNotEmpty) {
          expanded.add(_cloneWithValue(element, parts[p]));
        }
      }
    }
    return expanded ?? elements;
  }

  static IElement _cloneWithValue(IElement source, String value) => IElement(
        value: value,
        type: source.type,
        font: source.font,
        size: source.size,
        bold: source.bold,
        italic: source.italic,
        underline: source.underline,
        strikeout: source.strikeout,
        color: source.color,
        highlight: source.highlight,
        rowFlex: source.rowFlex,
        rowMargin: source.rowMargin,
        externalId: source.externalId,
        extension: source.extension,
      );

  // ---------------------------------------------------------------------
  // Comparação intocado vs. editado
  // ---------------------------------------------------------------------

  bool _specsEqual(_BlockSpec a, _BlockSpec b) {
    if ((a.table == null) != (b.table == null)) return false;
    if (a.table != null) return _sameTable(a.table!, b.table!);
    final left = _meaningful(a.elements);
    final right = _meaningful(b.elements);
    if (left.length != right.length) return false;
    for (var i = 0; i < left.length; i++) {
      if (!_sameElement(left[i], right[i])) return false;
    }
    return true;
  }

  static List<IElement> _meaningful(List<IElement> elements) => [
        for (final element in elements)
          if (!(element.type == null &&
              element.value.replaceAll(_zwsp, '').isEmpty &&
              element.value.isNotEmpty))
            element
      ];

  bool _sameElement(IElement a, IElement b) {
    if (a.type != b.type ||
        _clean(a.value) != _clean(b.value) ||
        a.font != b.font ||
        a.size != b.size ||
        (a.bold ?? false) != (b.bold ?? false) ||
        (a.italic ?? false) != (b.italic ?? false) ||
        (a.underline ?? false) != (b.underline ?? false) ||
        (a.strikeout ?? false) != (b.strikeout ?? false) ||
        a.color != b.color ||
        a.highlight != b.highlight ||
        a.rowFlex != b.rowFlex ||
        a.level != b.level ||
        a.url != b.url) {
      return false;
    }
    final aChildren = a.valueList ?? const <IElement>[];
    final bChildren = b.valueList ?? const <IElement>[];
    if (aChildren.length != bChildren.length) return false;
    for (var i = 0; i < aChildren.length; i++) {
      if (!_sameElement(aChildren[i], bChildren[i])) return false;
    }
    return true;
  }

  bool _sameTable(IElement a, IElement b) {
    final aTr = a.trList ?? const [];
    final bTr = b.trList ?? const [];
    if (aTr.length != bTr.length) return false;
    for (var r = 0; r < aTr.length; r++) {
      if (aTr[r].tdList.length != bTr[r].tdList.length) return false;
      for (var c = 0; c < aTr[r].tdList.length; c++) {
        final aTd = aTr[r].tdList[c];
        final bTd = bTr[r].tdList[c];
        if (aTd.colspan != bTd.colspan ||
            aTd.rowspan != bTd.rowspan ||
            aTd.backgroundColor != bTd.backgroundColor) {
          return false;
        }
        final aValue = _meaningful(aTd.value);
        final bValue = _meaningful(bTd.value);
        if (aValue.length != bValue.length) return false;
        for (var i = 0; i < aValue.length; i++) {
          if (!_sameElement(aValue[i], bValue[i])) return false;
        }
      }
    }
    return true;
  }

  static String _clean(String value) => value.replaceAll(_zwsp, '');

  static bool _hasFlag(IElement element, String flag) {
    final extension = element.extension;
    return extension is Map && extension[flag] == true;
  }

  static int? _stampOf(IElement element) {
    final id = element.externalId;
    if (id == null || !id.startsWith('wp:')) return null;
    return int.tryParse(id.substring(3));
  }

  // ---------------------------------------------------------------------
  // Regeneração de parágrafo
  // ---------------------------------------------------------------------

  WpParagraph _paragraphFromElements(
      List<IElement> elements, WpParagraphProperties? base) {
    TitleLevel? headingLevel;
    final flattened = <IElement>[];
    void flatten(IElement element) {
      headingLevel ??= element.level;
      if (element.type == ElementType.title) {
        for (final child in element.valueList ?? const <IElement>[]) {
          flatten(child);
        }
        return;
      }
      flattened.add(element);
    }

    for (final element in elements) {
      flatten(element);
    }

    final inlines = <WpInline>[];
    final pendingRun = <WpRunContent>[];
    WpRunProperties? pendingProps;

    void flushRun() {
      if (pendingRun.isEmpty) return;
      inlines
          .add(WpRun(properties: pendingProps, content: List.of(pendingRun)));
      pendingRun.clear();
      pendingProps = null;
    }

    void addContent(WpRunProperties? props, WpRunContent content) {
      if (pendingRun.isNotEmpty && !_samePropsKey(pendingProps, props)) {
        flushRun();
      }
      pendingProps = props ?? pendingProps;
      pendingRun.add(content);
    }

    for (final element in flattened) {
      if (_hasFlag(element, 'wpMarker')) continue; // numeração vem do numPr
      if (_hasFlag(element, 'wpBr')) {
        // Quebra(s) de linha w:br — value contém apenas '\n's.
        for (var i = 0; i < element.value.length; i++) {
          if (element.value.codeUnitAt(i) == 0x0a) {
            addContent(null, WpBreak());
          }
        }
        continue;
      }
      switch (element.type) {
        case null || ElementType.superscript || ElementType.subscript:
          final text = _clean(element.value);
          if (text.isEmpty) break;
          addContent(_runPropsFrom(element), WpText(text));
        case ElementType.tab:
          addContent(null, WpTabChar());
        case ElementType.pageBreak:
          addContent(null, WpBreak('page'));
        case ElementType.image:
          final drawing = _drawingFor(element);
          if (drawing != null) addContent(null, drawing);
        case ElementType.hyperlink:
          flushRun();
          inlines.add(_hyperlinkFrom(element));
        case ElementType.separator:
          notes.add('separador exportado como parágrafo vazio');
        case _:
          final text = _clean(element.value);
          if (text.isNotEmpty) {
            addContent(_runPropsFrom(element), WpText(text));
          }
          notes.add('elemento ${element.type} exportado como texto');
      }
    }
    flushRun();

    final rowFlex = flattened.isEmpty ? null : flattened.first.rowFlex;
    final jc = switch (rowFlex) {
      RowFlex.center => 'center',
      RowFlex.right => 'right',
      RowFlex.alignment => 'both',
      RowFlex.justify => 'distribute',
      _ => base?.styleId != null ? 'left' : null,
    };
    final int? outlineLevel = headingLevel == null
        ? null
        : <TitleLevel, int>{
            TitleLevel.first: 0,
            TitleLevel.second: 1,
            TitleLevel.third: 2,
            TitleLevel.fourth: 3,
            TitleLevel.fifth: 4,
            TitleLevel.sixth: 5,
          }[headingLevel];
    final String? headingStyleId =
        headingLevel == null ? null : _resolveHeadingStyleId(outlineLevel!);
    final IElement? paragraphAnchor =
        flattened.isEmpty ? null : flattened.first;
    final String? lineRule = paragraphAnchor?.lineSpacingRule;
    final double? lineValue = paragraphAnchor?.lineSpacingValue;
    final double? beforePx = paragraphAnchor?.paraSpacingBefore;
    final double? afterPx = paragraphAnchor?.paraSpacingAfter;
    final double? indentLeftPx = paragraphAnchor?.paraIndentLeft;
    final double? firstLinePx = paragraphAnchor?.paraIndentFirstLine;
    final WpSpacing? spacing =
        lineRule == null && beforePx == null && afterPx == null
            ? base?.spacing
            : WpSpacing(
                beforeTwips: beforePx == null
                    ? base?.spacing?.beforeTwips
                    : (beforePx * 15).round(),
                afterTwips: afterPx == null
                    ? base?.spacing?.afterTwips
                    : (afterPx * 15).round(),
                line: lineRule == null || lineValue == null
                    ? base?.spacing?.line
                    : lineRule == 'auto'
                        ? (lineValue * 240).round()
                        : (lineValue * 15).round(),
                lineRule: lineRule ?? base?.spacing?.lineRule,
              );
    final WpIndent? indent = indentLeftPx == null && firstLinePx == null
        ? base?.indent
        : WpIndent(
            leftTwips: indentLeftPx == null
                ? base?.indent?.leftTwips
                : (indentLeftPx * 15).round(),
            rightTwips: base?.indent?.rightTwips,
            firstLineTwips: firstLinePx != null && firstLinePx >= 0
                ? (firstLinePx * 15).round()
                : null,
            hangingTwips: firstLinePx != null && firstLinePx < 0
                ? (-firstLinePx * 15).round()
                : null,
          );

    return WpParagraph(
      properties: base == null &&
              jc == null &&
              headingLevel == null &&
              spacing == null &&
              indent == null
          ? null
          : WpParagraphProperties(
              styleId: headingStyleId ?? base?.styleId,
              numPr: base?.numPr,
              jc: jc ?? base?.jc,
              spacing: spacing,
              indent: indent,
              tabs: base?.tabs,
              shading: base?.shading,
              borders: base?.borders,
              keepNext: headingLevel != null ? true : base?.keepNext,
              keepLines: headingLevel != null ? true : base?.keepLines,
              pageBreakBefore: base?.pageBreakBefore,
              widowControl: base?.widowControl,
              contextualSpacing: base?.contextualSpacing,
              outlineLvl: outlineLevel ?? base?.outlineLvl,
              markRunProperties: base?.markRunProperties,
            ),
      inlines: inlines,
    );
  }

  String _resolveHeadingStyleId(int outlineLevel) {
    final int number = outlineLevel + 1;
    final RegExp namePattern = RegExp(
      '^(heading|title|título|titulo)\\s*$number\$',
      caseSensitive: false,
    );
    final List<WpStyle> paragraphStyles = file.styles.byId.values
        .where((WpStyle style) => style.type == 'paragraph')
        .toList(growable: false);
    for (final WpStyle style in paragraphStyles) {
      if (namePattern.hasMatch(style.name?.trim() ?? '')) return style.id;
    }
    for (final WpStyle style in paragraphStyles) {
      int? effectiveOutline;
      for (final WpStyle chained in file.styles.chainOf(style.id)) {
        effectiveOutline =
            chained.paragraphProperties?.outlineLvl ?? effectiveOutline;
      }
      if (effectiveOutline == outlineLevel) return style.id;
    }
    return 'Heading$number';
  }

  WpRunProperties _runPropsFrom(IElement element) => WpRunProperties(
        fontAscii: element.font,
        fontHAnsi: element.font,
        bold: element.bold == true,
        italic: element.italic == true,
        strike: element.strikeout == true,
        sizeHalfPoints:
            element.size == null ? null : (element.size! * 3 / 2).round(),
        color: element.color?.replaceFirst('#', ''),
        highlight: null,
        shading: element.highlight != null
            ? WpShading(fill: element.highlight!.replaceFirst('#', ''))
            : null,
        underline: element.underline == true ? 'single' : null,
        vertAlign: switch (element.type) {
          ElementType.superscript => 'superscript',
          ElementType.subscript => 'subscript',
          _ => null,
        },
      );

  static bool _samePropsKey(WpRunProperties? a, WpRunProperties? b) {
    if (a == null || b == null) return a == b;
    return a.fontAscii == b.fontAscii &&
        a.bold == b.bold &&
        a.italic == b.italic &&
        a.strike == b.strike &&
        a.sizeHalfPoints == b.sizeHalfPoints &&
        a.color == b.color &&
        a.underline == b.underline &&
        a.vertAlign == b.vertAlign &&
        a.shading?.fill == b.shading?.fill;
  }

  WpHyperlink _hyperlinkFrom(IElement element) {
    final runs = <WpRun>[];
    for (final child in element.valueList ?? const <IElement>[]) {
      final text = _clean(child.value);
      if (text.isEmpty) continue;
      runs.add(WpRun(
        properties: _runPropsFrom(child),
        content: [WpText(text)],
      ));
    }
    final url = element.url ?? '';
    if (url.startsWith('#')) {
      return WpHyperlink(anchor: url.substring(1), runs: runs);
    }
    return WpHyperlink(relId: _relIdForUrl(url), runs: runs);
  }

  String _relIdForUrl(String url) {
    final rels = file.package.relationshipsFor(file.mainPartName);
    for (final rel in rels.items) {
      if (rel.isExternal && rel.target == url) return rel.id;
    }
    final id = rels.nextId();
    rels.add(Relationship(
        id: id, type: RelType.hyperlink, target: url, isExternal: true));
    file.package.setRelationshipsFor(file.mainPartName, rels);
    return id;
  }

  // ---------------------------------------------------------------------
  // Imagens
  // ---------------------------------------------------------------------

  WpDrawing? _drawingFor(IElement element) {
    final extension = element.extension;
    if (extension is Map && extension['wpDrawing'] is String) {
      return WpDrawing(
          isInline: true, rawXml: extension['wpDrawing'] as String);
    }
    return _embedNewImage(element);
  }

  WpDrawing? _embedNewImage(IElement element) {
    final match = RegExp(r'^data:(image/[a-z+]+);base64,(.+)$', dotAll: true)
        .firstMatch(element.value);
    if (match == null) {
      notes.add('imagem sem data URL válida ignorada no save');
      return null;
    }
    final contentType = match.group(1)!;
    final bytes = base64Decode(match.group(2)!);
    final extensionName = switch (contentType) {
      'image/png' => 'png',
      'image/jpeg' => 'jpeg',
      'image/gif' => 'gif',
      _ => 'png',
    };

    // Content type default para a extensão (regenera [Content_Types].xml
    // apenas se necessário).
    if (file.package.contentTypes.defaults[extensionName] == null) {
      file.package.contentTypes.setDefault(extensionName, contentType);
      file.package.setPartString(
          '[Content_Types].xml', file.package.contentTypes.toXmlString());
    }

    var index = 1;
    while (file.package.hasPart('word/media/image900$index.$extensionName')) {
      index++;
    }
    final partName = 'word/media/image900$index.$extensionName';
    file.package.setPart(partName, bytes);

    final rels = file.package.relationshipsFor(file.mainPartName);
    final relId = rels.nextId();
    rels.add(Relationship(
        id: relId,
        type: RelType.image,
        target: 'media/image900$index.$extensionName'));
    file.package.setRelationshipsFor(file.mainPartName, rels);

    final cx = ((element.width ?? 100) * 9525).round();
    final cy = ((element.height ?? 100) * 9525).round();
    final id = _docPrId++;
    final xml = '<w:drawing>'
        '<wp:inline distT="0" distB="0" distL="0" distR="0">'
        '<wp:extent cx="$cx" cy="$cy"/>'
        '<wp:docPr id="$id" name="Imagem $id"/>'
        '<a:graphic xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main">'
        '<a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/picture">'
        '<pic:pic xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture">'
        '<pic:nvPicPr><pic:cNvPr id="$id" name="Imagem $id"/><pic:cNvPicPr/></pic:nvPicPr>'
        '<pic:blipFill><a:blip r:embed="$relId"/>'
        '<a:stretch><a:fillRect/></a:stretch></pic:blipFill>'
        '<pic:spPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="$cx" cy="$cy"/></a:xfrm>'
        '<a:prstGeom prst="rect"><a:avLst/></a:prstGeom></pic:spPr>'
        '</pic:pic></a:graphicData></a:graphic></wp:inline></w:drawing>';
    notes.add('imagem nova embutida como $partName');
    return WpDrawing(isInline: true, rawXml: xml, embedRelId: relId);
  }

  // ---------------------------------------------------------------------
  // Regeneração de tabela
  // ---------------------------------------------------------------------

  WpTable _tableFromElement(IElement element, WpTable? base) {
    final colgroup = element.colgroup ?? const <IColgroup>[];
    final grid = base != null && base.gridColumnsTwips.length == colgroup.length
        ? base.gridColumnsTwips
        : [for (final col in colgroup) (col.width * 15).round()];

    final rows = <WpTableRow>[];
    // vMerge: células com rowspan > 1 exigem células de continuação nas
    // linhas seguintes (removidas na conversão de abertura).
    final pending = <int, _PendingMerge>{};
    for (final tr in element.trList ?? const <ITr>[]) {
      final cells = <WpTableCell>[];
      var col = 0;
      var tdIndex = 0;
      while (true) {
        final merge = pending[col];
        if (merge != null) {
          cells.add(WpTableCell(
            properties: WpTableCellProperties(
              width: _cellWidth(grid, col, merge.span),
              gridSpan: merge.span > 1 ? merge.span : null,
              vMerge: 'continue',
            ),
            blocks: [WpParagraph(inlines: const [])],
          ));
          merge.remaining--;
          if (merge.remaining == 0) pending.remove(col);
          col += merge.span;
          continue;
        }
        if (tdIndex >= (tr.tdList.length)) break;
        final td = tr.tdList[tdIndex++];
        final span = td.colspan;
        cells.add(WpTableCell(
          properties: WpTableCellProperties(
            width: _cellWidth(grid, col, span),
            gridSpan: span > 1 ? span : null,
            vMerge: td.rowspan > 1 ? 'restart' : null,
            shading: td.backgroundColor != null
                ? WpShading(
                    val: 'clear',
                    color: 'auto',
                    fill: td.backgroundColor!.replaceFirst('#', ''))
                : null,
            vAlign: switch (td.verticalAlign?.value) {
              'middle' => 'center',
              'bottom' => 'bottom',
              _ => null,
            },
          ),
          blocks: _cellBlocks(td),
        ));
        if (td.rowspan > 1) {
          pending[col] = _PendingMerge(td.rowspan - 1, span);
        }
        col += span;
      }
      rows.add(WpTableRow(
        properties: tr.pagingRepeat == true
            ? const WpTableRowProperties(tblHeader: true)
            : null,
        cells: cells,
      ));
    }

    return WpTable(
      properties: base?.properties ??
          const WpTableProperties(
            width: WpTableWidth(value: 5000, type: 'pct'),
            borders: WpBorders(
              top: WpBorder(val: 'single', sizeEighths: 4, color: '000000'),
              left: WpBorder(val: 'single', sizeEighths: 4, color: '000000'),
              bottom: WpBorder(val: 'single', sizeEighths: 4, color: '000000'),
              right: WpBorder(val: 'single', sizeEighths: 4, color: '000000'),
              insideH: WpBorder(val: 'single', sizeEighths: 4, color: '000000'),
              insideV: WpBorder(val: 'single', sizeEighths: 4, color: '000000'),
            ),
          ),
      gridColumnsTwips: grid,
      rows: rows,
    );
  }

  static WpTableWidth _cellWidth(List<int> grid, int col, int span) {
    var width = 0;
    for (var i = col; i < col + span && i < grid.length; i++) {
      width += grid[i];
    }
    return WpTableWidth(value: width, type: 'dxa');
  }

  List<WpBlock> _cellBlocks(ITd td) {
    final blocks = <WpBlock>[];
    var current = <IElement>[];
    void flush() {
      blocks.add(_paragraphFromElements(current, null));
      current = [];
    }

    for (final element in td.value) {
      if (element.type == null &&
          element.value == '\n' &&
          !_hasFlag(element, 'wpBr')) {
        flush();
        continue;
      }
      if (element.type == ElementType.table) {
        notes.add('tabela aninhada não exportada (achatada na abertura)');
        continue;
      }
      current.add(element);
    }
    flush();
    return blocks;
  }
}

class _PendingMerge {
  int remaining;
  final int span;
  _PendingMerge(this.remaining, this.span);
}

class _BlockSpec {
  final List<IElement> elements;
  final IElement? table;

  /// Stamp do separador que abriu o bloco (identidade de parágrafo vazio).
  final int? fallbackStamp;

  _BlockSpec.paragraph(this.elements, {this.fallbackStamp}) : table = null;

  _BlockSpec.table(IElement this.table)
      : elements = const [],
        fallbackStamp = null;

  /// Índice do bloco original (stamp `wp:<i>`), quando consistente.
  int? get stamp {
    int? result;
    final candidates = table != null ? [table!] : elements;
    for (final element in candidates) {
      final stamp = EditorToDocx._stampOf(element);
      if (stamp == null) continue;
      if (result == null) {
        result = stamp;
      } else if (result != stamp) {
        return null; // parágrafos mesclados: regenerar
      }
    }
    return result ?? fallbackStamp;
  }
}
