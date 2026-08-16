/// Réguas horizontal e vertical do editor Word.
///
/// Comportamento de referência (shell do docx_rendering / DocumentServer):
/// banda com a área útil branca sobre trilho cinza, tick de 0,25 cm, tick
/// médio de 0,5 cm, número por centímetro CONTADO A PARTIR DA MARGEM, caixa
/// de canto (seletor de tabulação) e marcadores de recuo ARRASTÁVEIS —
/// primeira linha no topo, recuo esquerdo embaixo, recuo direito na margem
/// direita.
///
/// A horizontal ocupa uma faixa própria imediatamente abaixo da ribbon. A
/// vertical fica no limite esquerdo do viewport do documento e é movida
/// para a página que contém a seleção — há uma única régua vertical ativa,
/// como no Word.
///
/// Três interações vivem aqui, e as três seguem a MESMA regra de arrasto do
/// resto do chrome (`object_adorner.dart`, `table_adorner.dart`): enquanto o
/// ponteiro se move só o ADORNO muda; a transação/repaginação sai UMA vez,
/// no `pointerup`. Repaginar a cada pixel de arrasto remontaria o DOM
/// debaixo do ponteiro e travaria o gesto num documento de 140 páginas.
///
/// 1. **Recuos** (primeira linha, esquerdo, direito) → `applyBlockStyle`.
/// 2. **Margens** — a fronteira entre o trilho cinza e a área branca é alça.
///    Arrastar grava `marginLeft`/`marginRight` via `setMarginsTwips`, que é
///    o mesmo caminho do menu Margens da aba Layout.
/// 3. **Paradas de tabulação** — o canto deixa de ser um "L" decorativo e
///    passa a girar entre esquerda/centro/direita/decimal; clicar na banda
///    cria a parada, arrastar move, arrastar para FORA da faixa remove. As
///    paradas vão em `attrs['style']['tabs']`, que é exatamente o formato
///    que o compositor lê (`LayoutComposer._nextTabStop`) — nenhuma delas é
///    um atributo decorativo.
/// 4. **Divisas de coluna de tabela** — com o cursor dentro de uma tabela, a
///    régua ganha um marcador por borda de coluna, como no Word. A posição
///    vem da PROJEÇÃO (`table_geometry.dart`), não dos atributos crus, e o
///    arrasto termina na MESMA `table_ops.setTableColumnWidth` que a alça
///    sobre a tabela usa — o mesmo gesto por dois caminhos não pode gravar
///    de dois jeitos.
library;

import '../../platform/dom.dart';
import 'controller.dart';
import 'ribbon_actions.dart' as actions;
import 'table_geometry.dart';
import 'table_map.dart';
import 'table_ops.dart' as table_ops;

const int _quarterCmTwips = 142; // 0,25 cm

/// Largura útil mínima que qualquer arrasto de margem/recuo preserva.
const int _minContentTwips = 567; // 1 cm

/// Deslocamento vertical (px) a partir do qual soltar o ponteiro REMOVE a
/// parada de tabulação, como no Word: arrastá-la para fora da régua a apaga.
const int _tabDropOutPx = 18;

/// Largura mínima de coluna (0,5 cm), a mesma da alça sobre a tabela: uma
/// coluna de 0 twips some da tela e não há como pegá-la de volta com o
/// ponteiro.
const int _minColumnTwips = 283;

/// Os tipos de parada que o COMPOSITOR honra, na ordem em que o canto gira.
///
/// `bar` e os pseudo-tipos "recuo de primeira linha"/"recuo pendente" do
/// Word ficam de fora de propósito: `_nextTabStop` não os conhece, e um
/// tipo que o layout ignorasse transformaria o seletor num controle que não
/// muda nada.
const List<({String val, String glyph, String title})> officeTabStopKinds = [
  (val: 'left', glyph: '└', title: 'Tabulação à esquerda'),
  (val: 'center', glyph: '┴', title: 'Tabulação centralizada'),
  (val: 'right', glyph: '┘', title: 'Tabulação à direita'),
  (val: 'decimal', glyph: '┴.', title: 'Tabulação decimal'),
];

class OfficeHorizontalRuler {
  OfficeHorizontalRuler(this.controller)
      : _kit = OfficeDomKit(controller.adapter);

  final OfficeWordController controller;
  final OfficeDomKit _kit;

  DomElement? _center;
  DomElement? _content;
  DomElement? _tabLayer;
  DomElement? _tableLayer;
  DomElement? _corner;
  DomElement? _guide;

  DomElement? _first;
  DomElement? _left;
  DomElement? _right;
  DomElement? _marginLeft;
  DomElement? _marginRight;

  /// Tipo de parada armado no canto. Sobrevive à reconstrução da régua
  /// (zoom/geometria refazem o DOM, não o estado do seletor).
  int _tabKindIndex = 0;

  /// Drag de marcador de recuo em curso: tipo, X inicial e valor inicial.
  ({String kind, num startX, int startTwips})? _drag;

  /// Drag de MARGEM em curso. `startTwips` é a margem do lado arrastado.
  ({bool left, num startX, int startTwips})? _marginDrag;

  /// Drag de PARADA em curso. `index` é a posição na lista completa de
  /// `style['tabs']` (inclusive as entradas `clear`, que não têm marcador
  /// mas continuam contando).
  ({int index, num startX, num startY, int startTwips})? _tabDrag;

  /// Arrasto de DIVISA DE COLUNA em curso. `startWidthTwips` é a largura da
  /// coluna à esquerda da divisa — é ela que o gesto redimensiona.
  ({
    int tablePos,
    int columnIndex,
    num startX,
    int startWidthTwips,
    int startEdgeTwips,
  })? _columnDrag;

  String get activeTabStopKind => officeTabStopKinds[_tabKindIndex].val;

  DomElement build() {
    double px(int twips) => twips * controller.pxPerTwip;
    final setup = controller.pageSetup;

    final track = _kit.el('div', 'dq-office-ruler');
    final center = _kit.el('div', 'dq-office-ruler-center');
    center.setAttribute('style', 'width:${px(setup.widthTwips)}px;');
    _center = center;

    track.append(_buildCorner());

    final band = _kit.el('div', 'dq-office-ruler-band');
    final content = _kit.el('div', 'dq-office-ruler-content');
    content.setAttribute(
        'style',
        'left:${px(setup.marginLeftTwips)}px;'
            'width:${px(setup.contentWidthTwips)}px;');
    _content = content;
    band.append(content);
    // Clicar na banda cria a parada do tipo armado no canto. O listener fica
    // na BANDA (e não no centro) porque ticks e números são irmãos dela: com
    // `pointer-events:none` no CSS deles, qualquer ponto da faixa cinza ou
    // branca chega aqui, e os marcadores (z-index maior) continuam captando
    // o próprio arrasto.
    band.addEventListener('pointerdown', _handleBandPointerDown);
    center.append(band);

    final totalQuarters = setup.widthTwips ~/ _quarterCmTwips;
    for (var q = 1; q < totalQuarters; q++) {
      final twips = q * _quarterCmTwips;
      final sinceMargin = twips - setup.marginLeftTwips;
      if (q % 4 == 0) {
        final cm = sinceMargin ~/ (_quarterCmTwips * 4);
        final insideContent = sinceMargin > 0 &&
            twips < setup.widthTwips - setup.marginRightTwips &&
            cm >= 1;
        if (insideContent) {
          final number = _kit.el('span', 'dq-office-ruler-number');
          number.setAttribute('style', 'left:${px(twips)}px;');
          number.appendText('$cm');
          center.append(number);
          continue;
        }
      }
      final tick = _kit.el(
          'span',
          q.isEven
              ? 'dq-office-ruler-tick dq-office-ruler-tick-half'
              : 'dq-office-ruler-tick');
      tick.setAttribute('style', 'left:${px(twips)}px;');
      center.append(tick);
    }

    _marginLeft = _marginHandle(left: true);
    _marginRight = _marginHandle(left: false);
    center.append(_marginLeft!);
    center.append(_marginRight!);

    // As paradas ficam numa camada própria porque são reconstruídas a cada
    // mudança de seleção — sem ela, cada refresh teria de varrer os filhos
    // do centro procurando o que apagar.
    _tabLayer = _kit.el('div', 'dq-office-ruler-tabs');
    center.append(_tabLayer!);

    // As divisas de coluna também são reconstruídas a cada mudança de
    // seleção (elas só existem enquanto o cursor está numa tabela) e pela
    // mesma razão ganham camada própria.
    _tableLayer = _kit.el('div', 'dq-office-ruler-tabs dq-office-ruler-cols');
    center.append(_tableLayer!);

    _guide = _kit.el('span', 'dq-office-ruler-guide');
    _guide!.setAttribute('style', 'display:none;');
    center.append(_guide!);

    _first =
        _marker('dq-office-indent-first', 'Recuo da primeira linha', 'first');
    _left = _marker('dq-office-indent-left', 'Recuo à esquerda', 'left');
    _right = _marker('dq-office-indent-right', 'Recuo à direita', 'right');
    center.append(_first!);
    center.append(_left!);
    center.append(_right!);

    track.append(center);
    positionMarkers();
    return track;
  }

  // -- canto: o seletor de tipo de tabulação ---------------------------------

  DomElement _buildCorner() {
    final corner = _kit.el('div', 'dq-office-ruler-corner');
    corner.setAttribute('role', 'button');
    // B6: nenhum controle do chrome tira o foco (e a seleção visível) do
    // documento — girar o seletor não pode apagar a seleção que vai receber
    // a parada.
    corner.addEventListener('mousedown', (event) => event.preventDefault());
    corner.addEventListener('click', (event) {
      event.preventDefault();
      _tabKindIndex = (_tabKindIndex + 1) % officeTabStopKinds.length;
      _paintCorner();
    });
    _corner = corner;
    _paintCorner();
    return corner;
  }

  void _paintCorner() {
    final corner = _corner;
    if (corner == null) return;
    final kind = officeTabStopKinds[_tabKindIndex];
    _kit.setText(corner, kind.glyph);
    corner.setAttribute('title', kind.title);
    corner.setAttribute('aria-label', kind.title);
    corner.setAttribute('data-tab-kind', kind.val);
  }

  // -- marcadores de recuo ---------------------------------------------------

  DomElement _marker(String cssClass, String title, String kind) {
    final marker = _kit.el('span', 'dq-office-indent $cssClass');
    marker.setAttribute('title', title);
    marker.addEventListener('pointerdown', (event) {
      if (event is! DomMouseEvent) return;
      event.preventDefault();
      controller.syncSelection();
      final style = controller.currentBlockStyle();
      _drag = (
        kind: kind,
        startX: event.clientX,
        startTwips: _styleInt(style, _keyOf(kind)),
      );
    });
    return marker;
  }

  static String _keyOf(String kind) => switch (kind) {
        'first' => 'firstLineIndentTwips',
        'right' => 'rightIndentTwips',
        _ => 'indentTwips',
      };

  static int _styleInt(Map? style, String key) =>
      style?[key] is num ? (style![key] as num).toInt() : 0;

  // -- alças de margem -------------------------------------------------------

  /// A fronteira cinza/branco vira alça, como no Word. Ela não pertence ao
  /// parágrafo: mexe na SEÇÃO (hoje, no documento inteiro), então o commit
  /// vai por `setMarginsTwips` e não por `applyBlockStyle`.
  DomElement _marginHandle({required bool left}) {
    final handle = _kit.el(
        'span',
        'dq-office-margin '
            '${left ? 'dq-office-margin-left' : 'dq-office-margin-right'}');
    final title = left ? 'Margem esquerda' : 'Margem direita';
    handle.setAttribute('title', title);
    handle.setAttribute('aria-label', title);
    handle.addEventListener('pointerdown', (event) {
      if (event is! DomMouseEvent) return;
      event.preventDefault();
      final setup = controller.pageSetup;
      _marginDrag = (
        left: left,
        startX: event.clientX,
        startTwips: left ? setup.marginLeftTwips : setup.marginRightTwips,
      );
    });
    return handle;
  }

  /// O valor da margem arrastada, com o limite do Word: as duas margens
  /// somadas nunca engolem a área útil.
  int _marginValue(({bool left, num startX, int startTwips}) drag, num x) {
    final delta = ((x - drag.startX) / controller.pxPerTwip).round();
    final setup = controller.pageSetup;
    final other = drag.left ? setup.marginRightTwips : setup.marginLeftTwips;
    final limit = setup.widthTwips - other - _minContentTwips;
    final value = drag.startTwips + (drag.left ? delta : -delta);
    return value.clamp(0, limit < 0 ? 0 : limit);
  }

  // -- paradas de tabulação --------------------------------------------------

  /// As paradas do parágrafo corrente, normalizadas e ORDENADAS.
  ///
  /// As entradas `clear` (o "apagar a parada herdada do estilo" do OOXML)
  /// são preservadas: `_nextTabStop` as usa para pular posições da malha
  /// padrão, então descartá-las mudaria o layout de documentos importados.
  List<Map<String, dynamic>> currentTabStops() {
    final raw = controller.currentBlockStyle()?['tabs'];
    if (raw is! List) return const [];
    final stops = <Map<String, dynamic>>[
      for (final entry in raw)
        if (entry is Map && entry['posTwips'] is num)
          {
            'val': '${entry['val'] ?? 'left'}',
            'posTwips': (entry['posTwips'] as num).toInt(),
            if (entry['leader'] != null) 'leader': '${entry['leader']}',
          },
    ];
    stops
        .sort((a, b) => (a['posTwips'] as int).compareTo(b['posTwips'] as int));
    return stops;
  }

  void _commitTabStops(List<Map<String, dynamic>> stops) {
    stops
        .sort((a, b) => (a['posTwips'] as int).compareTo(b['posTwips'] as int));
    controller.applyBlockStyle({'tabs': stops});
  }

  /// clientX → twips CONTADOS A PARTIR DA MARGEM ESQUERDA, que é a unidade
  /// de `w:tab/@pos` e a que `_nextTabStop` compara.
  int _tabPositionAt(num clientX) {
    final center = _center;
    if (center == null) return 0;
    final bounds = controller.adapter.getElementBounds(center);
    final originPx = bounds == null ? 0.0 : (bounds['left'] as num).toDouble();
    final fromPageLeft = (clientX - originPx) / controller.pxPerTwip;
    return fromPageLeft.round() - controller.pageSetup.marginLeftTwips;
  }

  /// Encaixa na malha visível (0,25 cm) e mantém a parada dentro da área
  /// útil: uma parada fora dela nunca seria alcançada por um TAB.
  int _snapTabPosition(int twips) {
    final snapped = (twips / _quarterCmTwips).round() * _quarterCmTwips;
    return snapped.clamp(
        _quarterCmTwips, controller.pageSetup.contentWidthTwips);
  }

  void _handleBandPointerDown(DomEvent event) {
    if (event is! DomMouseEvent) return;
    event.preventDefault();
    controller.syncSelection();
    if (!controller.viewReady) return;
    final position = _snapTabPosition(_tabPositionAt(event.clientX));
    final stops = List<Map<String, dynamic>>.from(currentTabStops());
    // Clicar em cima de uma parada existente a redefine para o tipo armado,
    // em vez de empilhar duas paradas no mesmo ponto.
    final existing = stops.indexWhere((stop) => stop['posTwips'] == position);
    if (existing >= 0) {
      stops[existing] = {...stops[existing], 'val': activeTabStopKind};
    } else {
      stops.add({'val': activeTabStopKind, 'posTwips': position});
    }
    _commitTabStops(stops);
  }

  void _renderTabStops({({int index, int twips})? override}) {
    final layer = _tabLayer;
    if (layer == null) return;
    _kit.clear(layer);
    if (!controller.viewReady) return;
    double px(int twips) => twips * controller.pxPerTwip;
    final marginLeft = controller.pageSetup.marginLeftTwips;
    final stops = currentTabStops();
    for (var i = 0; i < stops.length; i++) {
      final stop = stops[i];
      final val = '${stop['val']}'.toLowerCase();
      if (val == 'clear') continue;
      final kind = officeTabStopKinds.firstWhere((k) => k.val == val,
          orElse: () => officeTabStopKinds.first);
      final position = override != null && override.index == i
          ? override.twips
          : stop['posTwips'] as int;
      final marker = _kit.el('span', 'dq-office-tabstop');
      marker.setAttribute('style', 'left:${px(marginLeft + position)}px;');
      marker.setAttribute('title', kind.title);
      marker.setAttribute('data-tab-kind', kind.val);
      marker.setAttribute('data-tab-pos', '$position');
      marker.appendText(kind.glyph);
      marker.addEventListener('pointerdown', (event) {
        if (event is! DomMouseEvent) return;
        event.preventDefault();
        controller.syncSelection();
        _tabDrag = (
          index: i,
          startX: event.clientX,
          startY: event.clientY,
          startTwips: stop['posTwips'] as int,
        );
      });
      layer.append(marker);
    }
  }

  int _tabDragValue(
          ({int index, num startX, num startY, int startTwips}) drag, num x) =>
      _snapTabPosition(
          drag.startTwips + ((x - drag.startX) / controller.pxPerTwip).round());

  // -- divisas de coluna de tabela -------------------------------------------

  /// Redesenha os marcadores de coluna da tabela da seleção.
  ///
  /// Fora de tabela a camada fica VAZIA: um marcador que não corresponde a
  /// nenhuma divisa visível seria pior que marcador nenhum. As posições vêm
  /// do `PageGraph` (a grade que o compositor resolveu), então o marcador
  /// cai exatamente sobre a linha desenhada na página.
  void _renderTableColumns({({int index, int twips})? override}) {
    final layer = _tableLayer;
    if (layer == null) return;
    _kit.clear(layer);
    if (!controller.viewReady) return;
    // A régua mede a PÁGINA, e a página é o corpo. Com o cabeçalho ou uma
    // caixa de texto abertos, o cursor não está no corpo: os marcadores
    // descreveriam a última tabela em que o cursor esteve, e arrastá-los
    // editaria um documento que não é o que está sendo digitado.
    if (controller.headerFooter.isActive || controller.textBoxSession.isActive) {
      return;
    }
    final state = controller.view.state;
    final map = OfficeTableMap.at(state.doc, state.selection.from);
    if (map == null || map.columns == 0) return;
    final edges = officeTableColumnEdges(
        controller.view.pageGraph, map.tablePos,
        columns: map.columns);
    if (edges.isEmpty) return;

    final marginLeft = controller.pageSetup.marginLeftTwips;
    for (var i = 0; i < edges.length; i++) {
      final edge =
          override != null && override.index == i ? override.twips : edges[i];
      final marker = _kit.el('span', 'dq-office-colmark');
      marker.setAttribute(
          'style', 'left:${(marginLeft + edge) * controller.pxPerTwip}px;');
      marker.setAttribute('title', 'Mover a divisa da coluna ${i + 1}');
      marker.setAttribute('data-column', '$i');
      marker.setAttribute('data-edge-twips', '$edge');
      final startWidth = i == 0 ? edges[0] : edges[i] - edges[i - 1];
      marker.addEventListener('pointerdown', (event) {
        if (event is! DomMouseEvent) return;
        event.preventDefault();
        _columnDrag = (
          tablePos: map.tablePos,
          columnIndex: i,
          startX: event.clientX,
          startWidthTwips: startWidth,
          startEdgeTwips: edges[i],
        );
      });
      layer.append(marker);
    }
  }

  /// A largura da coluna arrastada, com o mesmo piso da alça sobre a tabela.
  int _columnDragWidth(
    ({
      int tablePos,
      int columnIndex,
      num startX,
      int startWidthTwips,
      int startEdgeTwips,
    }) drag,
    num x,
  ) {
    final delta = ((x - drag.startX) / controller.pxPerTwip).round();
    final width = drag.startWidthTwips + delta;
    return width < _minColumnTwips ? _minColumnTwips : width;
  }

  // -- laço de ponteiro ------------------------------------------------------

  /// Chamado pelo orquestrador nos pointermove/pointerup do canvas E da
  /// faixa da régua — o arrasto começa na régua, que é irmã do canvas, e sem
  /// os dois registros um gesto inteiramente contido na faixa não veria
  /// nenhum `pointermove`.
  void handlePointerMove(DomEvent event) {
    if (event is! DomMouseEvent) return;
    final columnDrag = _columnDrag;
    if (columnDrag != null) {
      event.preventDefault();
      final width = _columnDragWidth(columnDrag, event.clientX);
      final edge =
          columnDrag.startEdgeTwips - columnDrag.startWidthTwips + width;
      _renderTableColumns(
          override: (index: columnDrag.columnIndex, twips: edge));
      _previewGuide(controller.pageSetup.marginLeftTwips + edge);
      return;
    }
    final marginDrag = _marginDrag;
    if (marginDrag != null) {
      event.preventDefault();
      _previewMargin(marginDrag, _marginValue(marginDrag, event.clientX));
      return;
    }
    final tabDrag = _tabDrag;
    if (tabDrag != null) {
      event.preventDefault();
      _renderTabStops(override: (
        index: tabDrag.index,
        twips: _tabDragValue(tabDrag, event.clientX)
      ));
      return;
    }
    final drag = _drag;
    if (drag == null) return;
    event.preventDefault();
    positionMarkers(
        override: (kind: drag.kind, twips: _dragValue(drag, event.clientX)));
  }

  void handlePointerUp(DomEvent event) {
    if (event is! DomMouseEvent) return;

    final columnDrag = _columnDrag;
    if (columnDrag != null) {
      // Zerar o arrasto ANTES de aplicar, como no gesto de margem: a
      // transação repagina e reconstrói a régua inteira.
      _columnDrag = null;
      _hideGuide();
      final state = controller.view.state;
      table_ops.setTableColumnWidth(
        state,
        // A view do CORPO, que é de quem este estado veio. `controller.dispatch`
        // segue a view ATIVA, e as duas divergem com o cabeçalho aberto — a
        // transação seria aplicada num documento que não é o dela.
        controller.view.dispatch,
        tablePos: columnDrag.tablePos,
        columnIndex: columnDrag.columnIndex,
        widthTwips: _columnDragWidth(columnDrag, event.clientX),
        projectedWidths: officeTableColumnWidths(
          controller.view.pageGraph,
          columnDrag.tablePos,
          columns: OfficeTableMap.of(state.doc, columnDrag.tablePos).columns,
        ),
      );
      return;
    }

    final marginDrag = _marginDrag;
    if (marginDrag != null) {
      // Zerar o arrasto ANTES de aplicar: `setMarginsTwips` repagina e
      // reconstrói a régua inteira, e o handler não pode voltar a mexer em
      // elementos que já saíram do documento.
      _marginDrag = null;
      _hideGuide();
      final value = _marginValue(marginDrag, event.clientX);
      final setup = controller.pageSetup;
      actions.setMarginsTwips(
        controller,
        top: setup.marginTopTwips,
        bottom: setup.marginBottomTwips,
        left: marginDrag.left ? value : setup.marginLeftTwips,
        right: marginDrag.left ? setup.marginRightTwips : value,
      );
      return;
    }

    final tabDrag = _tabDrag;
    if (tabDrag != null) {
      _tabDrag = null;
      final stops = List<Map<String, dynamic>>.from(currentTabStops());
      if (tabDrag.index >= stops.length) return;
      // Arrastar para fora da faixa REMOVE, como no Word — é o único gesto
      // de exclusão que existe sem um diálogo "Tabulações…".
      if ((event.clientY - tabDrag.startY).abs() > _tabDropOutPx) {
        stops.removeAt(tabDrag.index);
      } else {
        stops[tabDrag.index] = {
          ...stops[tabDrag.index],
          'posTwips': _tabDragValue(tabDrag, event.clientX),
        };
      }
      _commitTabStops(stops);
      return;
    }

    final drag = _drag;
    if (drag == null) return;
    _drag = null;
    controller
        .applyBlockStyle({_keyOf(drag.kind): _dragValue(drag, event.clientX)});
  }

  /// O valor em twips durante/apos o arrasto, com os limites do Word: nada
  /// sai da área útil e recuo esquerdo + primeira linha nunca fica negativo
  /// em relação à margem.
  int _dragValue(({String kind, num startX, int startTwips}) drag, num x) {
    final deltaTwips = ((x - drag.startX) / controller.pxPerTwip).round() *
        (drag.kind == 'right' ? -1 : 1);
    var value = drag.startTwips + deltaTwips;
    final style = controller.currentBlockStyle();
    final content = controller.pageSetup.contentWidthTwips;
    switch (drag.kind) {
      case 'left':
        final first = _styleInt(style, 'firstLineIndentTwips');
        value = value.clamp(first < 0 ? -first : 0, content - _minContentTwips);
      case 'first':
        final left = _styleInt(style, 'indentTwips');
        value = value.clamp(-left, content - left - _minContentTwips);
      default: // right
        value = value.clamp(0, content - _minContentTwips);
    }
    return value;
  }

  // -- posicionamento --------------------------------------------------------

  /// Posiciona os marcadores conforme o parágrafo corrente (ou o valor de
  /// um arrasto em curso, para feedback imediato).
  void positionMarkers({({String kind, int twips})? override}) {
    positionMargins();
    if (_left == null || !controller.viewReady) return;
    double px(int twips) => twips * controller.pxPerTwip;
    final setup = controller.pageSetup;
    final style = controller.currentBlockStyle();
    int value(String kind) => override != null && override.kind == kind
        ? override.twips
        : _styleInt(style, _keyOf(kind));

    final left = value('left');
    final first = value('first');
    final right = value('right');
    _left!.setAttribute('style', 'left:${px(setup.marginLeftTwips + left)}px;');
    _first!.setAttribute(
        'style', 'left:${px(setup.marginLeftTwips + left + first)}px;');
    _right!.setAttribute('style',
        'left:${px(setup.widthTwips - setup.marginRightTwips - right)}px;');
    _renderTabStops();
    _renderTableColumns();
  }

  /// As alças de margem NÃO dependem da view: elas refletem a geometria, que
  /// já existe quando a régua é construída (antes do primeiro `mountView`).
  void positionMargins({int? leftOverride, int? rightOverride}) {
    double px(int twips) => twips * controller.pxPerTwip;
    final setup = controller.pageSetup;
    final left = leftOverride ?? setup.marginLeftTwips;
    final right = rightOverride ?? setup.marginRightTwips;
    _marginLeft?.setAttribute('style', 'left:${px(left)}px;');
    _marginRight?.setAttribute(
        'style', 'left:${px(setup.widthTwips - right)}px;');
    _content?.setAttribute(
        'style',
        'left:${px(left)}px;'
            'width:${px(setup.widthTwips - left - right)}px;');
  }

  /// Feedback do arrasto de margem: a área branca e a guia tracejada se
  /// movem, o documento NÃO. A repaginação é uma só, no pointerup.
  void _previewMargin(
      ({bool left, num startX, int startTwips}) drag, int value) {
    positionMargins(
      leftOverride: drag.left ? value : null,
      rightOverride: drag.left ? null : value,
    );
    final setup = controller.pageSetup;
    _previewGuide(drag.left ? value : setup.widthTwips - value);
  }

  /// A guia tracejada em [twips] contados da borda esquerda do papel.
  void _previewGuide(int twips) =>
      _guide?.setAttribute('style', 'left:${twips * controller.pxPerTwip}px;');

  void _hideGuide() => _guide?.setAttribute('style', 'display:none;');
}

class OfficeVerticalRuler {
  OfficeVerticalRuler(this.controller)
      : _kit = OfficeDomKit(controller.adapter);

  final OfficeWordController controller;
  final OfficeDomKit _kit;

  DomElement build() {
    double px(int twips) => twips * controller.pxPerTwip;
    final setup = controller.pageSetup;

    final ruler = _kit.el('div', 'dq-office-vruler');
    final track = _kit.el('div', 'dq-office-vruler-track');
    track.setAttribute('style', 'height:${px(setup.heightTwips)}px;');

    final content = _kit.el('div', 'dq-office-vruler-content');
    content.setAttribute(
        'style',
        'top:${px(setup.marginTopTwips)}px;'
            'height:${px(setup.contentHeightTwips)}px;');
    track.append(content);

    final totalQuarters = setup.heightTwips ~/ _quarterCmTwips;
    for (var q = 1; q < totalQuarters; q++) {
      final twips = q * _quarterCmTwips;
      final sinceMargin = twips - setup.marginTopTwips;
      if (q % 4 == 0) {
        final cm = sinceMargin ~/ (_quarterCmTwips * 4);
        final insideContent = sinceMargin > 0 &&
            twips < setup.heightTwips - setup.marginBottomTwips &&
            cm >= 1;
        if (insideContent) {
          final number = _kit.el('span', 'dq-office-vruler-number');
          number.setAttribute('style', 'top:${px(twips)}px;');
          number.appendText('$cm');
          track.append(number);
          continue;
        }
      }
      final tick = _kit.el(
          'span',
          q.isEven
              ? 'dq-office-vruler-tick dq-office-vruler-tick-half'
              : 'dq-office-vruler-tick');
      tick.setAttribute('style', 'top:${px(twips)}px;');
      track.append(tick);
    }

    ruler.append(track);
    return ruler;
  }
}
