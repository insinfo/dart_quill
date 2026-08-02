/// LayoutComposer — compõe o [PageGraph] a partir da árvore Office (Fase 5).
///
/// UM paginador, dois níveis de qualidade ([LayoutQuality]): `draft`
/// simplifica widow/orphan e tabelas; `fidelity` aplica as regras
/// completas. O documento, a seleção, os IDs e o snapshot NUNCA mudam com o
/// nível — só o refinamento do grafo.
///
/// Medição: [FontMetrics] embarcadas (as mesmas do exportador de PDF), a
/// autoridade de largura nas duas saídas — é o que garante que a linha do
/// editor e a do PDF quebram no mesmo lugar. O TextShaper (etapa 1:
/// latino/kerning/ligaturas) entra depois, atrás da mesma interface de
/// medição.
///
/// v1 cobre o perfil Quill: paragraph/heading/listItem/blockquote/codeBlock
/// com quebra por linha e fragmentação ENTRE páginas em granularidade de
/// LINHA (um parágrafo pode atravessar páginas — a limitação do exportador
/// Delta linear não existe aqui). Tabelas: granularidade de linha-de-tabela
/// no draft, com aviso; a fragmentação fina fica com o fidelity da Fase 6.
library;

import '../../office/document/fonts/font_metrics.dart';
import '../../office/document/fonts/font_registry.dart';
import '../model/index.dart';
import '../office/ids.dart';
import 'fonts.dart';
import 'page_graph.dart';

/// Converte pt→twips.
int _ptToTwips(double pt) => (pt * 20).round();

class LayoutComposer {
  LayoutComposer({
    this.setup = const PageSetupTwips(),
    this.quality = LayoutQuality.draft,
    this.baseFontFamily = 'Arial',
    this.baseFontSizePt = 12,
    LayoutFontSet? fonts,
    this.header,
    this.footer,
    this.sections = const [],
  }) : fonts = fonts ?? LayoutFontSet(const []);

  final PageSetupTwips setup;
  final LayoutQuality quality;
  final String baseFontFamily;
  final double baseFontSizePt;

  /// Faces embutidas: quando presentes, a medição usa a hmtx REAL da face —
  /// a mesma que o renderer embute — e as duas saídas quebram igual.
  final LayoutFontSet fonts;

  /// Geometrias por SEÇÃO, na ordem do documento.
  ///
  /// Vazio significa "uma seção só", que é `setup`. Com várias, um bloco
  /// que carrega `style.sectionBreak` ENCERRA a seção corrente: o OOXML
  /// coloca o `sectPr` no parágrafo que TERMINA a seção, não no que
  /// começa a seguinte — ler ao contrário aplicaria a geometria errada ao
  /// documento inteiro.
  ///
  /// Sem isto, um anexo em paisagem seria paginado em retrato na tela E no
  /// PDF, porque os dois consomem o mesmo grafo.
  final List<PageSetupTwips> sections;

  /// Regiões de cabeçalho/rodapé — árvores próprias, não parte do corpo.
  ///
  /// Elas repetem em todas as páginas, então NÃO entram no `positionMap`:
  /// uma posição do documento apontaria para N lugares, e o caret cairia
  /// num deles por sorteio.
  final PMNode? header;
  final PMNode? footer;

  /// Campos substituídos por página. `PAGE` é o número da página atual e
  /// `NUMPAGES` o total — os dois únicos que praticamente todo ofício usa.
  static final RegExp _pageField = RegExp(r'\{(PAGE|NUMPAGES)\}');

  /// Recuo por nível de lista, em twips (21,6 pt como o exportador linear).
  static const int _listIndentTwips = 432;

  PageGraph compose(PMNode doc) => _composeFrom(doc);

  /// Recompõe REUSANDO o prefixo de páginas que a edição não pode ter
  /// afetado.
  ///
  /// O ponto da Fase 7: digitar na página 180 de 200 não pode custar as 200.
  /// Uma página só é ponto de retomada se COMEÇAR um bloco fresco — uma
  /// página que continua um parágrafo não sabe quantas linhas dele já foram
  /// consumidas, e recompor a partir dela duplicaria conteúdo.
  ///
  /// [changedFromDocPos] é a MENOR posição tocada pela transação. Tudo antes
  /// dela é idêntico no documento novo e no antigo, inclusive as posições —
  /// é o que torna o reuso do prefixo seguro sem remapear nada.
  PageGraph composeIncremental(
    PMNode doc, {
    required PageGraph previous,
    required int changedFromDocPos,
  }) {
    var resumeAt = 0;
    for (var p = 1; p < previous.pages.length; p++) {
      if (!previous.pages[p].signature.startsFreshBlock) continue;
      if (previous.pages[p - 1].signature.lastDocPos >= changedFromDocPos) {
        break;
      }
      resumeAt = p;
    }
    if (resumeAt == 0) {
      // Nenhum prefixo reusável — é o caso da edição na PRIMEIRA página.
      // Ainda assim passamos o grafo anterior: é justamente aqui que a
      // convergência de sufixo vale, porque é ela (e não o prefixo) que
      // impede recompor as 200 páginas por causa da primeira linha.
      return _composeFrom(doc, convergeAgainst: previous);
    }

    final signature = previous.pages[resumeAt].signature;
    return _composeFrom(
      doc,
      reusedPages: previous.pages.sublist(0, resumeAt),
      reusedEntries: previous.positionMap.entries
          .where((entry) => entry.pageIndex < resumeAt)
          .toList(),
      startBlockIndex: signature.firstBlockIndex,
      startOffset: signature.firstBlockOffset,
      startListOrdinal: signature.carryListOrdinal,
      convergeAgainst: previous,
      convergeFromPage: resumeAt,
    );
  }

  PageGraph _composeFrom(
    PMNode doc, {
    List<PageLayout> reusedPages = const [],
    List<PositionMapEntry> reusedEntries = const [],
    int startBlockIndex = 0,
    int startOffset = 0,
    int startListOrdinal = 0,
    PageGraph? convergeAgainst,
    int convergeFromPage = 0,
  }) {
    final diagnostics = LayoutDiagnostics();
    final pages = <PageLayout>[...reusedPages];
    final mapEntries = <PositionMapEntry>[...reusedEntries];

    var currentFragments = <PageFragment>[];
    var cursorTwips = 0;
    var sectionIndex = 0;
    var activeSetup = sections.isEmpty ? setup : sections.first;
    var capacity = activeSetup.contentHeightTwips;

    // Estado de ENTRADA da página aberta (o que a assinatura registra).
    var pageStartBlockIndex = startBlockIndex;
    var pageStartOffset = startOffset;
    var pageStartListOrdinal = startListOrdinal;

    void closePage() {
      final first = currentFragments.isEmpty ? null : currentFragments.first;
      pages.add(PageLayout(
        index: pages.length,
        setup: activeSetup,
        fragments: currentFragments,
        signature: PageSignature(
          firstBlockIndex: pageStartBlockIndex,
          firstBlockOffset: pageStartOffset,
          carryListOrdinal: pageStartListOrdinal,
          startsFreshBlock: first == null || !_continuesFrom(first),
          lastDocPos: _lastDocPosOf(currentFragments),
        ),
      ));
      currentFragments = [];
      cursorTwips = 0;
    }

    // Convergência de SUFIXO: quando a composição nova reencontra o estado
    // de entrada de uma página antiga, tudo dali para frente é o mesmo
    // conteúdo — só as posições mudaram, pelo tamanho do que a edição
    // acrescentou ou removeu ANTES. Sem isto, editar a primeira linha de um
    // documento de 200 páginas recomporia as 200.
    final blockIndexDelta =
        convergeAgainst == null ? 0 : doc.childCount - convergeAgainst.blockCount;
    final docPosDelta =
        convergeAgainst == null ? 0 : doc.content.size - convergeAgainst.docSize;
    var converged = false;

    /// Existe página antiga com este mesmo estado de entrada?
    int? _oldPageMatching(int blockIndex, int blockOffset, int ordinal) {
      final old = convergeAgainst;
      if (old == null) return null;
      for (var m = convergeFromPage; m < old.pages.length; m++) {
        final sig = old.pages[m].signature;
        if (!sig.startsFreshBlock) continue;
        if (sig.firstBlockIndex + blockIndexDelta != blockIndex) continue;
        if (sig.firstBlockOffset + docPosDelta != blockOffset) continue;
        if (sig.carryListOrdinal != ordinal) continue;
        return m;
      }
      return null;
    }

    var listOrdinal = startListOrdinal;

    // O estado de entrada de uma página só é conhecido quando o PRIMEIRO
    // fragmento dela entra: uma página nova nasce no MEIO de um bloco
    // (quando `closePage` dispara na quebra de linha), então capturar no
    // topo da iteração registraria o bloco da página anterior.
    void beginPage(int index, int blockOffset, int ordinalBefore) {
      if (currentFragments.isNotEmpty) return;
      pageStartBlockIndex = index;
      pageStartOffset = blockOffset;
      pageStartListOrdinal = ordinalBefore;
    }

    /// Tenta convergir numa FRONTEIRA de página, com o próximo bloco a
    /// entrar sendo [blockIndex]. Só vale com a página vazia: com
    /// fragmentos pendentes, a página em construção não é comparável.
    bool tryConverge(int blockIndex, int blockOffset, int ordinal) {
      if (currentFragments.isNotEmpty) return false;
      final match = _oldPageMatching(blockIndex, blockOffset, ordinal);
      if (match == null) return false;
      final old = convergeAgainst!;
      final pageDelta = pages.length - match;
      for (var m = match; m < old.pages.length; m++) {
        pages.add(old.pages[m].shifted(
          newIndex: pages.length,
          docPosDelta: docPosDelta,
          blockIndexDelta: blockIndexDelta,
        ));
      }
      for (final entry in old.positionMap.entries) {
        if (entry.pageIndex < match) continue;
        mapEntries.add(
            entry.shifted(docPosDelta: docPosDelta, pageDelta: pageDelta));
      }
      converged = true;
      return true;
    }

    var offset = startOffset;
    for (var index = startBlockIndex; index < doc.childCount; index++) {
      if (index > startBlockIndex && tryConverge(index, offset, listOrdinal)) {
        break;
      }
      final block = doc.child(index);
      final blockOffset = offset;
      // ANTES da atualização de numeração: retomar neste bloco tem de
      // reproduzir o mesmo incremento, não contá-lo duas vezes.
      final ordinalBefore = listOrdinal;
      final docPos = offset + 1;
      offset += block.nodeSize;
      final kind = block.type.name;

      if (kind == 'table') {
        listOrdinal = 0;
        final rows = _composeTableRows(block, diagnostics);
        var i = 0;
        var firstOfTable = true;
        while (i < rows.length) {
          final remaining = capacity - cursorTwips;
          var take = 0;
          var height = 0;
          while (i + take < rows.length &&
              height + rows[i + take].heightTwips <= remaining) {
            height += rows[i + take].heightTwips;
            take++;
          }
          if (take == 0) {
            if (cursorTwips == 0) {
              // Linha de tabela maior que a página: entra com corte estável.
              take = 1;
              height = rows[i].heightTwips;
              diagnostics.warnings
                  .add('linha de tabela mais alta que a página');
            } else {
              closePage();
              if (i == 0 && tryConverge(index, blockOffset, ordinalBefore)) {
                break;
              }
              continue;
            }
          }
          final slice = rows.sublist(i, i + take);
          beginPage(index, blockOffset, ordinalBefore);
          currentFragments.add(TableFragment(
            nodeId: officeNodeId(block),
            docPos: docPos,
            rows: slice,
            yTwips: cursorTwips,
            heightTwips: height,
            continuesFromPreviousPage: !firstOfTable,
            continuesOnNextPage: i + take < rows.length,
          ));
          mapEntries.add(PositionMapEntry(
            docPosStart: docPos,
            docPosEnd: docPos + block.nodeSize - 2,
            pageIndex: pages.length,
          ));
          cursorTwips += height;
          firstOfTable = false;
          i += take;
        }
        if (converged) break;
        continue;
      }

      // Estado da numeração de lista ordenada.
      if (kind == 'listItem' && block.attrs['kind'] == 'ordered') {
        listOrdinal++;
      } else if (kind != 'listItem') {
        listOrdinal = 0;
      }

      final blockStyle = _blockStyleOf(block, listOrdinal);
      final lines = _breakLines(
        block,
        activeSetup.contentWidthTwips - blockStyle.indentTwips,
        blockStyle,
        diagnostics,
      );

      var firstLineOfBlock = true;
      var i = 0;
      while (i < lines.length) {
        final remaining = capacity - cursorTwips;
        // Quantas linhas cabem nesta página.
        var take = 0;
        var height = 0;
        while (i + take < lines.length &&
            height + lines[i + take].heightTwips <= remaining) {
          height += lines[i + take].heightTwips;
          take++;
        }
        if (take == 0) {
          if (cursorTwips == 0) {
            // Linha maior que a página inteira: entra mesmo assim (corte
            // estável, nunca loop) e o aviso registra a perda visual.
            take = 1;
            height = lines[i].heightTwips;
            diagnostics.warnings
                .add('linha mais alta que a página no nó ${block.type.name}');
          } else {
            closePage();
            // A fronteira de página nasce AQUI quando o bloco inteiro não
            // cabe no que sobrou: é o ponto em que a página nova começa
            // num bloco fresco, e portanto o ponto de convergência.
            if (i == 0 && tryConverge(index, blockOffset, ordinalBefore)) {
              break;
            }
            continue;
          }
        }
        final slice = lines.sublist(i, i + take);
        beginPage(index, blockOffset, ordinalBefore);
        currentFragments.add(BlockFragment(
          nodeId: officeNodeId(block),
          docPos: docPos,
          kind: kind,
          lines: slice,
          yTwips: cursorTwips,
          heightTwips: height,
          indentTwips: blockStyle.indentTwips,
          align: blockStyle.align,
          marker: firstLineOfBlock ? blockStyle.marker : null,
          continuesFromPreviousPage: !firstLineOfBlock,
          continuesOnNextPage: i + take < lines.length,
        ));
        mapEntries.add(PositionMapEntry(
          docPosStart: docPos + slice.first.charStart,
          docPosEnd: docPos + slice.last.charEnd,
          pageIndex: pages.length,
        ));
        cursorTwips += height;
        firstLineOfBlock = false;
        i += take;
      }
      if (converged) break;
      // A quebra de seção é processada DEPOIS do bloco: o `sectPr` descreve
      // a seção que termina NELE, então ele ainda pertence à geometria
      // antiga.
      if (_endsSection(block) && sectionIndex + 1 < sections.length) {
        if (currentFragments.isNotEmpty) closePage();
        sectionIndex++;
        activeSetup = sections[sectionIndex];
        capacity = activeSetup.contentHeightTwips;
      }
      if (lines.isEmpty) {
        // Bloco vazio: uma linha em branco na altura da fonte base.
        final blank = _lineHeightTwips(baseFontFamily, baseFontSizePt);
        if (cursorTwips + blank > capacity && currentFragments.isNotEmpty) {
          closePage();
        }
        beginPage(index, blockOffset, ordinalBefore);
        currentFragments.add(BlockFragment(
          nodeId: officeNodeId(block),
          docPos: docPos,
          kind: kind,
          lines: const [],
          yTwips: cursorTwips,
          heightTwips: blank,
          align: blockStyle.align,
        ));
        mapEntries.add(PositionMapEntry(
          docPosStart: docPos,
          docPosEnd: docPos + block.nodeSize - 2,
          pageIndex: pages.length,
        ));
        cursorTwips += blank;
      }
    }

    if (!converged &&
        (currentFragments.isNotEmpty || pages.length == reusedPages.length)) {
      closePage();
    }

    return PageGraph(
      pages: _withHeadersAndFooters(pages, diagnostics),
      positionMap: PositionMap(mapEntries),
      diagnostics: diagnostics,
      quality: quality,
      docSize: doc.content.size,
      blockCount: doc.childCount,
    );
  }

  /// Compõe cabeçalho e rodapé de cada página.
  ///
  /// Quando a região NÃO tem campo de página, ela é composta UMA vez e a
  /// mesma lista é reusada em todas as páginas — é conteúdo idêntico, e
  /// recompor 200 vezes seria desperdício puro. Com campo, o texto muda por
  /// página e a composição precisa acontecer por página; regiões de
  /// cabeçalho são pequenas, então o custo é aceitável e a alternativa
  /// (medir com o placeholder e desenhar outro texto) desalinharia.
  List<PageLayout> _withHeadersAndFooters(
      List<PageLayout> pages, LayoutDiagnostics diagnostics) {
    if (header == null && footer == null) return pages;
    if (pages.isEmpty) return pages;

    final total = pages.length;
    final headerHasField = _hasPageField(header);
    final footerHasField = _hasPageField(footer);

    final sharedHeader = headerHasField
        ? null
        : _composeRegion(header, diagnostics, 0, total);
    final sharedFooter = footerHasField
        ? null
        : _composeRegion(footer, diagnostics, 0, total);

    return [
      for (final page in pages)
        PageLayout(
          index: page.index,
          setup: page.setup,
          fragments: page.fragments,
          signature: page.signature,
          header: sharedHeader ??
              _composeRegion(header, diagnostics, page.index, total),
          footer: sharedFooter ??
              _composeRegion(footer, diagnostics, page.index, total),
        )
    ];
  }

  static bool _hasPageField(PMNode? region) {
    if (region == null) return false;
    return _pageField.hasMatch(region.textBetween(0, region.content.size));
  }

  /// Uma região empilhada a partir do topo do seu box, com os campos de
  /// página já resolvidos para ESTA página.
  List<BlockFragment> _composeRegion(
    PMNode? region,
    LayoutDiagnostics diagnostics,
    int pageIndex,
    int totalPages,
  ) {
    if (region == null) return const [];
    final resolved = _resolveFields(region, pageIndex + 1, totalPages);
    final fragments = <BlockFragment>[];
    var y = 0;
    for (var i = 0; i < resolved.childCount; i++) {
      final block = resolved.child(i);
      final style = _blockStyleOf(block, 0);
      final lines = _breakLines(block, setup.contentWidthTwips - style.indentTwips,
          style, diagnostics);
      final height = lines.fold<int>(0, (sum, line) => sum + line.heightTwips);
      fragments.add(BlockFragment(
        nodeId: officeNodeId(block),
        // Fora do espaço de posições do corpo: -1 declara que este fragmento
        // não corresponde a nenhuma posição do documento.
        docPos: -1,
        kind: block.type.name,
        lines: lines,
        yTwips: y,
        heightTwips: height,
        indentTwips: style.indentTwips,
        align: style.align,
      ));
      y += height;
    }
    return fragments;
  }

  /// Substitui `{PAGE}`/`{NUMPAGES}` pelos valores desta página.
  PMNode _resolveFields(PMNode region, int pageNumber, int totalPages) {
    if (!_hasPageField(region)) return region;
    String replace(String text) => text.replaceAllMapped(
        _pageField,
        (match) =>
            match.group(1) == 'PAGE' ? '$pageNumber' : '$totalPages');

    PMNode mapNode(PMNode node) {
      if (node.isText) {
        return node.type.schema.text(replace(node.text ?? ''), node.marks);
      }
      final children = <PMNode>[
        for (var i = 0; i < node.childCount; i++) mapNode(node.child(i))
      ];
      return node.copy(Fragment.from(children));
    }

    return mapNode(region);
  }

  /// O bloco encerra uma seção?
  ///
  /// A marca vem da importação (`style.sectionBreak`), que a lê do
  /// `w:pPr/w:sectPr` — o lugar onde o OOXML registra a quebra.
  static bool _endsSection(PMNode block) {
    final style = block.attrs['style'];
    return style is Map && style['sectionBreak'] == true;
  }

  static bool _continuesFrom(PageFragment fragment) => switch (fragment) {
        BlockFragment(:final continuesFromPreviousPage) =>
          continuesFromPreviousPage,
        TableFragment(:final continuesFromPreviousPage) =>
          continuesFromPreviousPage,
      };

  static int _lastDocPosOf(List<PageFragment> fragments) {
    var last = 0;
    for (final fragment in fragments) {
      final end = switch (fragment) {
        BlockFragment(:final docPos, :final lines) => lines.isEmpty
            ? docPos
            : docPos + lines.last.charEnd,
        TableFragment(:final docPos) => docPos,
      };
      if (end > last) last = end;
    }
    return last;
  }

  // -- Estilo de bloco -------------------------------------------------------

  _BlockStyle _blockStyleOf(PMNode block, int listOrdinal) {
    final resolved = _resolvedStyleOf(block, listOrdinal);
    if (resolved != null) return resolved;
    return _heuristicStyleOf(block, listOrdinal);
  }

  /// A apresentação que veio RESOLVIDA da importação (`attrs['style']`).
  ///
  /// Quando existe, ela manda: é a cascata real do documento
  /// (docDefaults → basedOn → estilo → formatação direta), não um palpite.
  /// A heurística por nível de heading continua como fallback para
  /// documentos que nunca passaram por um importador — Delta do Quill, por
  /// exemplo, onde `header: 1` é tudo que se sabe.
  _BlockStyle? _resolvedStyleOf(PMNode block, int listOrdinal) {
    final raw = block.attrs['style'];
    if (raw is! Map) return null;
    final sizePt = raw['sizePt'];
    if (sizePt is! num || sizePt <= 0) return null;

    final heuristic = _heuristicStyleOf(block, listOrdinal);
    return _BlockStyle(
      align: switch (raw['align'] ?? block.attrs['align']) {
        'center' => LayoutAlign.center,
        'right' => LayoutAlign.right,
        'justify' => LayoutAlign.justify,
        'left' => LayoutAlign.left,
        _ => heuristic.align,
      },
      baseSizePt: sizePt.toDouble(),
      bold: raw['bold'] is bool ? raw['bold'] as bool : heuristic.bold,
      indentTwips: raw['indentTwips'] is num
          ? (raw['indentTwips'] as num).toInt()
          : heuristic.indentTwips,
      // O rótulo de numeração resolvido do `numbering.xml` ganha do
      // marcador heurístico: ele é o que o Word desenharia.
      marker: raw['marker'] is String ? raw['marker'] as String : heuristic.marker,
      family: raw['family'] is String ? raw['family'] as String : heuristic.family,
    );
  }

  _BlockStyle _heuristicStyleOf(PMNode block, int listOrdinal) {
    final align = switch (block.attrs['align']) {
      'center' => LayoutAlign.center,
      'right' => LayoutAlign.right,
      'justify' => LayoutAlign.justify,
      _ => LayoutAlign.left,
    };
    switch (block.type.name) {
      case 'heading':
        final level = (block.attrs['level'] as num?)?.toInt() ?? 1;
        final scale = switch (level) {
          1 => 2.0,
          2 => 1.5,
          3 => 1.17,
          4 => 1.0,
          5 => 0.83,
          _ => 0.67,
        };
        return _BlockStyle(
          align: align,
          baseSizePt: baseFontSizePt * scale,
          bold: true,
        );
      case 'listItem':
        final rawIndent = block.attrs['indent'];
        final level =
            rawIndent is num ? rawIndent.toInt() : int.tryParse('$rawIndent') ?? 0;
        final kind = block.attrs['kind'];
        return _BlockStyle(
          align: align,
          baseSizePt: baseFontSizePt,
          indentTwips: _listIndentTwips * (1 + level),
          marker: kind == 'ordered' ? '$listOrdinal. ' : '• ',
        );
      case 'blockquote':
        return _BlockStyle(
          align: align,
          baseSizePt: baseFontSizePt,
          indentTwips: _ptToTwips(14),
        );
      case 'codeBlock':
        return _BlockStyle(
          align: align,
          baseSizePt: baseFontSizePt,
          family: 'Courier New',
        );
      default:
        return _BlockStyle(align: align, baseSizePt: baseFontSizePt);
    }
  }

  // -- Quebra de linha -------------------------------------------------------

  FontMetrics _metricsFor(String family) =>
      FontRegistry.instance.lookup(family) ?? FontRegistry.instance.lookup(null)!;

  /// Cache tipográfico: a MESMA palavra, no mesmo estilo, é medida uma vez.
  ///
  /// Medir domina a composição (uma medida por palavra por tentativa de
  /// quebra) e o texto de um documento repete muito — artigos, preposições,
  /// e as palavras que sobrevivem a uma edição. A chave inclui todo o
  /// estilo que afeta o avanço; a face entra por família/peso/itálico, que
  /// é como `faceFor` resolve.
  final Map<String, double> _measureCache = {};

  /// Quantas medições distintas o cache guarda. Diagnóstico — é o que
  /// permite testar o cache sem cronômetro (comparar tempo de parede num
  /// teste é instável e pisca na CI).
  int get measurementCacheSize => _measureCache.length;

  double _measurePt(ResolvedRunStyle style, String text) {
    final key = '${style.family} ${style.sizePt} '
        '${style.bold ? 1 : 0}${style.italic ? 1 : 0} $text';
    final cached = _measureCache[key];
    if (cached != null) return cached;
    final face =
        fonts.faceFor(style.family, bold: style.bold, italic: style.italic);
    final width = face != null
        ? face.measureWidthPt(text, style.sizePt)
        : _metricsFor(style.family).measureWidth(text, style.sizePt);
    _measureCache[key] = width;
    return width;
  }

  ({double ascent, double descent}) _verticalPt(ResolvedRunStyle style) {
    final face =
        fonts.faceFor(style.family, bold: style.bold, italic: style.italic);
    if (face != null) {
      return (
        ascent: face.ascentPt(style.sizePt),
        descent: face.descentPt(style.sizePt),
      );
    }
    final m = _metricsFor(style.family);
    return (ascent: m.ascentPx(style.sizePt), descent: m.descentPx(style.sizePt));
  }

  int _lineHeightTwips(String family, double sizePt) {
    final v = _verticalPt(ResolvedRunStyle(family: family, sizePt: sizePt));
    return _ptToTwips(v.ascent + v.descent);
  }

  ResolvedRunStyle _styleOfText(PMNode text, _BlockStyle blockStyle) {
    var family = blockStyle.family ?? baseFontFamily;
    var sizePt = blockStyle.baseSizePt;
    var bold = blockStyle.bold;
    var italic = false, underline = false, strike = false;
    var color = '#000000';
    String? link;
    for (final mark in text.marks) {
      switch (mark.type.name) {
        case 'bold':
          bold = true;
        case 'italic':
          italic = true;
        case 'underline':
          underline = true;
        case 'strike':
          strike = true;
        case 'font':
          family = '${mark.attrs['value']}';
        case 'size':
          sizePt = _parseSizePt('${mark.attrs['value']}') ?? sizePt;
        case 'color':
          color = '${mark.attrs['value']}';
        case 'link':
          link = '${mark.attrs['href']}';
      }
    }
    return ResolvedRunStyle(
      family: family,
      sizePt: sizePt,
      bold: bold,
      italic: italic,
      underline: underline,
      strike: strike,
      color: color,
      link: link,
    );
  }

  static double? _parseSizePt(String value) {
    final match = RegExp(r'^([\d.]+)(pt|px)?$').firstMatch(value.trim());
    if (match == null) return null;
    final number = double.tryParse(match.group(1)!);
    if (number == null) return null;
    return match.group(2) == 'px' ? number * 0.75 : number;
  }

  /// Quebra o conteúdo inline de [block] em linhas de até [widthTwips].
  List<LineBox> _breakLines(
    PMNode block,
    int widthTwips,
    _BlockStyle blockStyle,
    LayoutDiagnostics diagnostics,
  ) {
    // Tokens (palavra/espaço) com estilo, mantendo o offset de caractere.
    final tokens = <_Token>[];
    var charOffset = 0;
    block.content.forEach((child, offset, index) {
      if (child.isText) {
        final style = _styleOfText(child, blockStyle);
        final text = child.text!;
        final re = RegExp(r'(\s+)|([^\s]+)');
        for (final m in re.allMatches(text)) {
          final piece = m.group(0)!;
          tokens.add(_Token(
            text: piece,
            style: style,
            isSpace: m.group(1) != null,
            widthTwips: _ptToTwips(_measurePt(style, piece)),
            charStart: charOffset + m.start,
          ));
        }
        charOffset += text.length;
      } else {
        // Embed inline (imagem etc.): v1 reserva uma caixa quadrada da
        // altura da linha; a medição real entra com o suporte a imagem.
        diagnostics.warnings
            .add('embed inline ${child.type.name} medido como caixa padrão');
        final style = ResolvedRunStyle(
            family: baseFontFamily, sizePt: baseFontSizePt);
        tokens.add(_Token(
          text: '￼',
          style: style,
          isSpace: false,
          widthTwips: _ptToTwips(baseFontSizePt),
          charStart: charOffset,
        ));
        charOffset += 1;
      }
    });

    final lines = <LineBox>[];
    var current = <_Token>[];
    var currentWidth = 0;

    void flush() {
      if (current.isEmpty) return;
      // Segmentos: funde tokens adjacentes com o mesmo estilo.
      final segments = <LineSegment>[];
      for (final token in current) {
        if (segments.isNotEmpty &&
            identical(segments.last.style, token.style)) {
          segments[segments.length - 1] = LineSegment(
            text: segments.last.text + token.text,
            style: segments.last.style,
            widthTwips: segments.last.widthTwips + token.widthTwips,
          );
        } else {
          segments.add(LineSegment(
            text: token.text,
            style: token.style,
            widthTwips: token.widthTwips,
          ));
        }
      }
      var ascent = 0, height = 0;
      for (final segment in segments) {
        final v = _verticalPt(segment.style);
        final a = _ptToTwips(v.ascent);
        final h = a + _ptToTwips(v.descent);
        if (a > ascent) ascent = a;
        if (h > height) height = h;
      }
      if (height == 0) {
        height = _lineHeightTwips(baseFontFamily, blockStyle.baseSizePt);
        ascent = height;
      }
      lines.add(LineBox(
        segments: segments,
        widthTwips: currentWidth,
        ascentTwips: ascent,
        heightTwips: height,
        charStart: current.first.charStart,
        charEnd: current.last.charStart + current.last.text.length,
      ));
      current = [];
      currentWidth = 0;
    }

    for (final token in tokens) {
      if (token.isSpace) {
        if (current.isEmpty) continue; // colapsa espaço no início da linha
        current.add(token);
        currentWidth += token.widthTwips;
        continue;
      }
      if (currentWidth + token.widthTwips > widthTwips && current.isNotEmpty) {
        flush();
      }
      if (token.widthTwips > widthTwips && current.isEmpty) {
        // Palavra maior que a coluna: corte duro por caracteres.
        var rest = token;
        while (rest.widthTwips > widthTwips && rest.text.length > 1) {
          var cut = rest.text.length - 1;
          while (cut > 1 &&
              _ptToTwips(_measurePt(
                      rest.style, rest.text.substring(0, cut))) >
                  widthTwips) {
            cut--;
          }
          final head = rest.text.substring(0, cut);
          current.add(_Token(
            text: head,
            style: rest.style,
            isSpace: false,
            widthTwips: _ptToTwips(_measurePt(rest.style, head)),
            charStart: rest.charStart,
          ));
          currentWidth += current.last.widthTwips;
          flush();
          rest = _Token(
            text: rest.text.substring(cut),
            style: rest.style,
            isSpace: false,
            widthTwips:
                _ptToTwips(_measurePt(rest.style, rest.text.substring(cut))),
            charStart: rest.charStart + cut,
          );
        }
        current.add(rest);
        currentWidth += rest.widthTwips;
        continue;
      }
      current.add(token);
      currentWidth += token.widthTwips;
    }
    flush();
    return lines;
  }
}

extension _TableComposition on LayoutComposer {
  /// Larguras de coluna em twips: `colWidths` verbatim (px → twips ×15) ou
  /// larguras das células, com reescala para caber na área útil — a mesma
  /// cascata P12 do exportador linear.
  List<int> _tableColumnWidths(PMNode table) {
    final available = setup.contentWidthTwips;
    var widths = <int>[];
    final colWidths = table.attrs['colWidths'];
    if (colWidths is List && colWidths.isNotEmpty) {
      for (final col in colWidths) {
        final raw = col is Map ? col['width'] : null;
        final px = raw is num ? raw.toDouble() : double.tryParse('$raw') ?? 72;
        widths.add((px * 15).round()); // 1 px = 0,75 pt = 15 twips
      }
    } else {
      // Da primeira linha: célula sem colspan define a coluna.
      final firstRow =
          table.content.size > 0 ? table.content.child(0) : null;
      if (firstRow != null) {
        firstRow.content.forEach((cell, _, __) {
          final cellMap = cell.attrs['cell'];
          final raw = cellMap is Map ? cellMap['width'] : null;
          final px = raw is num
              ? raw.toDouble()
              : double.tryParse('$raw') ?? 72;
          widths.add((px * 15).round());
        });
      }
    }
    if (widths.isEmpty) return [available];
    final total = widths.fold<int>(0, (a, b) => a + b);
    if (total > available && total > 0) {
      widths = widths
          .map((w) => (w * available / total).round())
          .toList();
    }
    return widths;
  }

  List<TableRowBox> _composeTableRows(
      PMNode table, LayoutDiagnostics diagnostics) {
    final columnWidths = _tableColumnWidths(table);
    const cellPaddingTwips = 60; // 3 pt
    final rows = <TableRowBox>[];
    table.content.forEach((row, _, __) {
      final cells = <TableCellBox>[];
      var x = 0;
      var column = 0;
      var rowHeight = 0;
      row.content.forEach((cell, ___, ____) {
        final width = column < columnWidths.length
            ? columnWidths[column]
            : columnWidths.last;
        final innerWidth = width - 2 * cellPaddingTwips;
        final blocks = <BlockFragment>[];
        var y = cellPaddingTwips;
        cell.content.forEach((inner, _____, offset) {
          final style = _blockStyleOf(inner, 0);
          final lines =
              _breakLines(inner, innerWidth, style, diagnostics);
          var height = 0;
          for (final line in lines) {
            height += line.heightTwips;
          }
          if (lines.isEmpty) {
            height = _lineHeightTwips(baseFontFamily, baseFontSizePt);
          }
          blocks.add(BlockFragment(
            nodeId: officeNodeId(inner),
            docPos: 0,
            kind: inner.type.name,
            lines: lines,
            yTwips: y,
            heightTwips: height,
            align: style.align,
          ));
          y += height;
        });
        final contentHeight = y + cellPaddingTwips;
        if (contentHeight > rowHeight) rowHeight = contentHeight;
        cells.add(TableCellBox(
          xTwips: x,
          widthTwips: width,
          blocks: blocks,
          contentHeightTwips: contentHeight,
        ));
        x += width;
        column++;
      });
      rows.add(TableRowBox(heightTwips: rowHeight, cells: cells));
    });
    return rows;
  }
}

class _BlockStyle {
  const _BlockStyle({
    required this.align,
    required this.baseSizePt,
    this.bold = false,
    this.indentTwips = 0,
    this.marker,
    this.family,
  });

  final LayoutAlign align;
  final double baseSizePt;
  final bool bold;
  final int indentTwips;
  final String? marker;
  final String? family;
}

class _Token {
  const _Token({
    required this.text,
    required this.style,
    required this.isSpace,
    required this.widthTwips,
    required this.charStart,
  });

  final String text;
  final ResolvedRunStyle style;
  final bool isSpace;
  final int widthTwips;
  final int charStart;
}
