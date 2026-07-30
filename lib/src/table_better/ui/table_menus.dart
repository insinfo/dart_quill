/// Port of `quill-table-better/src/ui/table-menus.ts` (v1.2.3) — the floating
/// menu bar shown above (or below) the table under the caret.
///
/// Faithful to the TS in DOM shape, class names, menu composition and the
/// positioning algorithm. The one systematic adaptation: wherever the TS
/// resolves the affected cells by comparing `getBoundingClientRect` edges
/// (`getSelectedTdsInfo`, `getCorrectTds`, `getColsOffset`, `getCellsOffset`,
/// `getRefInfo`), this port asks [CellSelection] — which keeps the same
/// information as an exact logical grid — so the menus work identically in a
/// browser and in a headless VM.
library;

import '../../core/emitter.dart';
import '../../core/quill.dart';
import '../../core/selection.dart';
import '../../dependencies/dart_quill_delta/dart_quill_delta.dart';
import '../../platform/dom.dart';
import '../assets/icons.dart';
import '../config/config.dart';
import '../formats/table.dart';
import '../language/language.dart';
import '../utils/utils.dart' as utils;
import 'cell_selection.dart';
import 'table_properties_form.dart';

/// One entry of a menu's dropdown list (TS `Children[key]`).
class TableMenuChild {
  const TableMenuChild({
    required this.name,
    required this.content,
    required this.handler,
    this.divider = false,
    this.createSwitch = false,
  });

  final String name;
  final String content;
  final void Function(TableMenus menus) handler;
  final bool divider;
  final bool createSwitch;
}

/// One top-level menu (TS `Menu` / `CustomMenu`).
class TableMenu {
  const TableMenu({
    required this.name,
    required this.content,
    required this.icon,
    required this.handler,
    this.children = const <TableMenuChild>[],
  });

  final String name;
  final String content;
  final String icon;
  final void Function(TableMenus menus, DomElement? list, DomElement tooltip)
      handler;
  final List<TableMenuChild> children;
}

/// TS `enum Alignment` — the style properties that encode a table's alignment.
class _Alignment {
  static const String left = 'margin-left';
  static const String right = 'margin-right';
}

/// TS `getMenusConfig(useLanguage, menus)`.
///
/// [menus] filters and orders the result exactly like upstream: a list of
/// names picks from DEFAULT + EXTRA; an empty/absent list yields DEFAULT.
List<TableMenu> getMenusConfig(Language language, [List<String>? menus]) {
  String t(String key) => language.useLanguage(key);

  void toggle(TableMenus m, DomElement? list, DomElement tooltip) =>
      m.toggleAttribute(list, tooltip);

  final defaults = <TableMenu>[
    TableMenu(
      name: 'column',
      content: t('col'),
      icon: tableBetterIcons['column']!,
      handler: toggle,
      children: [
        TableMenuChild(
          name: 'left',
          content: t('insColL'),
          handler: (m) => m.insertColumn(0),
        ),
        TableMenuChild(
          name: 'right',
          content: t('insColR'),
          handler: (m) => m.insertColumn(1),
        ),
        TableMenuChild(
          name: 'delete',
          content: t('delCol'),
          handler: (m) => m.deleteColumn(),
        ),
        TableMenuChild(
          name: 'select',
          content: t('selCol'),
          handler: (m) => m.selectColumn(),
        ),
      ],
    ),
    TableMenu(
      name: 'row',
      content: t('row'),
      icon: tableBetterIcons['row']!,
      handler: toggle,
      children: [
        TableMenuChild(
          name: 'header',
          content: t('headerRow'),
          divider: true,
          createSwitch: true,
          handler: (m) {
            m.toggleHeaderRow();
            m.toggleHeaderRowSwitch();
          },
        ),
        TableMenuChild(
          name: 'above',
          content: t('insRowAbv'),
          handler: (m) => m.insertRow(0),
        ),
        TableMenuChild(
          name: 'below',
          content: t('insRowBlw'),
          handler: (m) => m.insertRow(1),
        ),
        TableMenuChild(
          name: 'delete',
          content: t('delRow'),
          handler: (m) => m.deleteRow(),
        ),
        TableMenuChild(
          name: 'select',
          content: t('selRow'),
          handler: (m) => m.selectRow(),
        ),
      ],
    ),
    TableMenu(
      name: 'merge',
      content: t('mCells'),
      icon: tableBetterIcons['merge']!,
      handler: toggle,
      children: [
        TableMenuChild(
          name: 'merge',
          content: t('mCells'),
          handler: (m) {
            m.mergeCells();
            m.updateMenus();
          },
        ),
        TableMenuChild(
          name: 'split',
          content: t('sCell'),
          handler: (m) {
            m.splitCell();
            m.updateMenus();
          },
        ),
      ],
    ),
    TableMenu(
      name: 'table',
      content: t('tblProps'),
      icon: tableBetterIcons['table']!,
      handler: (m, list, tooltip) {
        m.toggleAttribute(list, tooltip);
        m.openTableProperties();
        m.hideMenus();
      },
    ),
    TableMenu(
      name: 'cell',
      content: t('cellProps'),
      icon: tableBetterIcons['cell']!,
      handler: (m, list, tooltip) {
        m.toggleAttribute(list, tooltip);
        m.openCellProperties();
        m.hideMenus();
      },
    ),
    TableMenu(
      name: 'wrap',
      content: t('insParaOTbl'),
      icon: tableBetterIcons['wrap']!,
      handler: toggle,
      children: [
        TableMenuChild(
          name: 'before',
          content: t('insB4'),
          handler: (m) => m.insertParagraph(-1),
        ),
        TableMenuChild(
          name: 'after',
          content: t('insAft'),
          handler: (m) => m.insertParagraph(1),
        ),
      ],
    ),
    TableMenu(
      name: 'delete',
      content: t('delTable'),
      icon: tableBetterIcons['delete']!,
      handler: (m, list, tooltip) => m.deleteTable(),
    ),
  ];
  final extra = <TableMenu>[
    TableMenu(
      name: 'copy',
      content: t('copyTable'),
      icon: tableBetterIcons['copy']!,
      handler: (m, list, tooltip) => m.copyTable(),
    ),
  ];

  if (menus == null || menus.isEmpty) return defaults;
  final all = <String, TableMenu>{
    for (final menu in [...defaults, ...extra]) menu.name: menu,
  };
  return [
    for (final name in menus)
      if (all.containsKey(name)) all[name]!,
  ];
}

/// TS `class TableMenus`.
class TableMenus {
  TableMenus({
    required this.quill,
    required this.language,
    required this.resolveSelection,
    required this.hideTools,
    this.menus,
    this.onOpenProperties,
  }) {
    _clickListener = handleClick;
    quill.root.addEventListener('click', _clickListener);
    root = createMenus();
  }

  final Quill quill;
  final Language language;

  /// Resolves the [CellSelection] of a table element — the module owns one
  /// controller per table, so the lookup stays there.
  final CellSelection? Function(DomElement table) resolveSelection;

  /// TS `this.tableBetter.hideTools()`.
  final void Function() hideTools;

  /// TS `options.menus` — names of the menus to show, in order.
  final List<String>? menus;

  /// Optional override for the properties form lifecycle; when absent the
  /// menus build a [TablePropertiesForm] themselves, as upstream does.
  final void Function(TableMenus menus, String type)? onOpenProperties;

  /// TS `this.tablePropertiesForm`.
  TablePropertiesForm? tablePropertiesForm;

  late final DomElement root;
  late final DomEventListener _clickListener;

  /// TS `this.table` — the `<table>` element the menus currently act on.
  DomElement? table;
  DomElement? prevList;
  DomElement? prevTooltip;
  DomElement? tableHeaderRow;
  bool scroll = false;

  final List<TableMenu> _config = <TableMenu>[];

  /// The [CellSelection] backing the current table, if any.
  CellSelection? get cellSelection {
    final element = table;
    return element == null ? null : resolveSelection(element);
  }

  TableContainer? get tableBlot => cellSelection?.table;

  DomDocument get _document => quill.root.ownerDocument;

  void destroy() {
    quill.root.removeEventListener('click', _clickListener);
    root.remove();
  }

  // --- construction -------------------------------------------------------

  /// TS `createList(children)`.
  DomElement? createList(List<TableMenuChild> children) {
    if (children.isEmpty) return null;
    final container = _document.createElement('ul');
    for (final child in children) {
      final list = _document.createElement('li');
      if (child.createSwitch) {
        list.classes.add('ql-table-header-row');
        createSwitch(list, child.content);
        tableHeaderRow = list;
      } else {
        list.text = child.content;
      }
      list.addEventListener('click', (_) => child.handler(this));
      container.append(list);
      if (child.divider) {
        final divider = _document.createElement('li');
        divider.classes.add('ql-table-divider');
        container.append(divider);
      }
    }
    container.classes.add('ql-table-dropdown-list');
    container.classes.add('ql-hidden');
    return container;
  }

  /// TS `createMenu(left, right, isDropDown, category)`.
  DomElement createMenu(
      String left, String right, bool isDropDown, String category) {
    final container = _document.createElement('div');
    final dropDown = _document.createElement('span');
    dropDown.innerHTML = isDropDown ? '$left$right' : left;
    container.classes.add('ql-table-dropdown');
    dropDown.classes.add('ql-table-tooltip-hover');
    container.setAttribute('data-category', category);
    container.append(dropDown);
    return container;
  }

  /// TS `createMenus()`.
  DomElement createMenus() {
    final container = _document.createElement('div');
    container.classes.add('ql-table-menus-container');
    container.classes.add('ql-hidden');
    _config
      ..clear()
      ..addAll(getMenusConfig(language, menus));
    for (final menu in _config) {
      final list = createList(menu.children);
      final tooltip = utils.createTooltip(menu.content);
      final element = createMenu(
        menu.icon,
        tableBetterIcons['down']!,
        menu.children.isNotEmpty,
        menu.name,
      );
      element.append(tooltip);
      if (list != null) element.append(list);
      container.append(element);
      element.addEventListener('click', (event) {
        // TS binds the handler with (list, tooltip) already applied.
        if (_isInsideHeaderRow(event.target)) return;
        menu.handler(this, list, tooltip);
      });
    }
    quill.container.append(container);
    return container;
  }

  /// TS `createSwitch(content)` — a title plus the aria-checked switch.
  void createSwitch(DomElement host, String content) {
    final title = _document.createElement('span');
    final switchContainer = _document.createElement('span');
    final switchInner = _document.createElement('span');
    title.text = content;
    switchContainer.classes.add('ql-table-switch');
    switchInner.classes.add('ql-table-switch-inner');
    switchInner.setAttribute('aria-checked', 'false');
    switchContainer.append(switchInner);
    host.append(title);
    host.append(switchContainer);
  }

  // --- visibility ---------------------------------------------------------

  /// TS `showMenus()`.
  void showMenus() => root.classes.remove('ql-hidden');

  /// TS `hideMenus()`.
  void hideMenus() => root.classes.add('ql-hidden');

  /// TS `disableMenu(category, disabled)`.
  void disableMenu(String category, [bool disabled = false]) {
    final menu = _menuElement(category);
    if (menu == null) return;
    if (disabled) {
      menu.classes.add('ql-table-disabled');
    } else {
      menu.classes.remove('ql-table-disabled');
    }
  }

  /// TS `toggleAttribute(list, tooltip, e)`.
  void toggleAttribute(DomElement? list, DomElement tooltip) {
    final previousList = prevList;
    if (previousList != null && previousList != list) {
      previousList.classes.add('ql-hidden');
      prevTooltip?.classes.remove('ql-table-tooltip-hidden');
    }
    if (list == null) return;
    list.classes.toggle('ql-hidden');
    tooltip.classes.toggle('ql-table-tooltip-hidden');
    prevList = list;
    prevTooltip = tooltip;
  }

  /// TS `updateScroll(scroll)`.
  void updateScroll(bool value) => scroll = value;

  /// TS `updateTable(table)`.
  void updateTable(DomElement? value) => table = value;

  /// TS `handleClick(e)`.
  void handleClick(DomEvent event) {
    if (!quill.isEnabled()) return;
    final target = _closestTable(event.target);
    prevList?.classes.add('ql-hidden');
    prevTooltip?.classes.remove('ql-table-tooltip-hidden');
    prevList = null;
    prevTooltip = null;
    final selection = target == null ? null : resolveSelection(target);
    if (target == null && (selection?.selectedTds.isEmpty ?? true)) {
      hideMenus();
      destroyTablePropertiesForm();
      return;
    }
    showMenus();
    updateMenus(target);
    if ((target != null && target != table) || scroll) {
      updateScroll(false);
    }
    table = target;
  }

  /// TS `updateMenus(table)` — the positioning pass.
  ///
  /// TS defers to `requestAnimationFrame`; this runs synchronously so headless
  /// callers observe the result immediately (a browser frame boundary would
  /// only matter for layout thrashing).
  void updateMenus([DomElement? target]) {
    final element = target ?? table;
    if (element == null) return;
    root.classes.remove('ql-table-triangle-none');
    final bounds = getCorrectBounds(element);
    final tableBounds = bounds[0];
    final containerBounds = bounds[1];
    final rootBounds = utils.getCorrectBounds(root, quill.container);
    final height = rootBounds.height;
    final width = rootBounds.width;
    var correctTop = tableBounds.top - height - 10;
    var correctLeft =
        ((tableBounds.left + tableBounds.right - width) / 2).floorToDouble();
    if (correctTop > 0) {
      root.classes.add('ql-table-triangle-up');
      root.classes.remove('ql-table-triangle-down');
    } else {
      correctTop = tableBounds.bottom > containerBounds.height
          ? containerBounds.height + 10
          : tableBounds.bottom + 10;
      root.classes.add('ql-table-triangle-down');
      root.classes.remove('ql-table-triangle-up');
    }
    if (correctLeft < containerBounds.left) {
      correctLeft = 0;
      root.classes.add('ql-table-triangle-none');
    } else if (correctLeft + width > containerBounds.right) {
      correctLeft = containerBounds.right - width;
      root.classes.add('ql-table-triangle-none');
    }
    utils.setElementProperty(root, {
      'left': '${utils.formatNum(correctLeft)}px',
      'top': '${utils.formatNum(correctTop)}px',
    });
  }

  /// TS `getCorrectBounds(table)` — `[tableBounds, containerBounds]`, with a
  /// table wider than the container clamped to the container's width.
  List<utils.CorrectBound> getCorrectBounds(DomElement target) {
    final bounds = utils.getCorrectBounds(quill.container);
    final tableBounds = utils.getCorrectBounds(target, quill.container);
    if (tableBounds.width >= bounds.width) {
      return [
        utils.CorrectBound(
          left: 0,
          right: bounds.width,
          top: tableBounds.top,
          bottom: tableBounds.bottom,
          width: tableBounds.width,
          height: tableBounds.height,
        ),
        bounds,
      ];
    }
    return [tableBounds, bounds];
  }

  // --- actions ------------------------------------------------------------

  /// TS `insertColumn(td, offset)`.
  void insertColumn(int offset) {
    final selection = cellSelection;
    final blot = tableBlot;
    if (selection == null || blot == null) return;
    final range = selection.range;
    if (range == null) return;
    final bounds =
        table == null ? null : utils.getCorrectBounds(table!, quill.container);
    final reference = offset > 0
        ? _cellAt(selection, range.startRow, range.endColumn)
        : _cellAt(selection, range.startRow, range.startColumn);
    if (reference == null) return;
    final referenceBounds =
        utils.getCorrectBounds(reference.element, quill.container);
    final isLast = reference.next == null;
    final position = offset > 0 ? referenceBounds.right : referenceBounds.left;
    blot.insertColumn(position, isLast, referenceBounds.width, offset);
    if (bounds != null) {
      utils.updateTableWidth(blot, bounds, cellDefaultWidth.toDouble());
    }
    quill.scrollSelectionIntoView();
    updateMenus();
  }

  /// TS `insertRow(td, offset)`.
  void insertRow(int offset) {
    final selection = cellSelection;
    final blot = tableBlot;
    if (selection == null || blot == null) return;
    final range = selection.range;
    if (range == null) return;
    final reference = offset > 0
        ? _cellAt(selection, range.endRow, range.startColumn)
        : _cellAt(selection, range.startRow, range.startColumn);
    if (reference == null) return;
    final index = reference.rowOffset();
    final isTh = reference.blotName == TableTh.kBlotName;
    if (offset > 0) {
      final rowspan =
          int.tryParse(reference.element.getAttribute('rowspan') ?? '') ?? 1;
      blot.insertRow(index + offset + rowspan - 1, offset, isTh);
    } else {
      blot.insertRow(index + offset, offset, isTh);
    }
    quill.scrollSelectionIntoView();
    updateMenus();
  }

  /// TS `deleteColumn(isKeyboard)`.
  void deleteColumn([bool isKeyboard = false]) {
    final selection = cellSelection;
    final blot = tableBlot;
    if (selection == null || blot == null) return;
    final range = selection.range;
    if (range == null) return;
    final target = table;
    final bounds =
        target == null ? null : utils.getCorrectBounds(target, quill.container);

    // TS partitions the geometrically selected cells into fully covered ones
    // (`selTds`, removed) and partially covered ones (`changeTds`, whose
    // colspan shrinks). The logical grid gives the same partition exactly.
    final delTds = <DomElement>[];
    final changeTds = <MapEntry<DomElement, int>>[];
    for (final entry in _grid(selection)) {
      final colStart = entry.column;
      final colEnd = entry.column + entry.colspan - 1;
      if (colStart >= range.startColumn && colEnd <= range.endColumn) {
        delTds.add(entry.cell.element);
      } else {
        final overlap =
            _overlap(colStart, colEnd, range.startColumn, range.endColumn);
        if (overlap > 0) {
          changeTds.add(MapEntry(entry.cell.element, -overlap));
        }
      }
    }
    if (delTds.isEmpty && changeTds.isEmpty) return;
    if (isKeyboard && delTds.length != selection.selectedTds.length) return;

    final cols = <DomElement>[];
    final colgroup = blot.colgroup();
    if (colgroup != null) {
      var index = 0;
      for (final col in colgroup.children) {
        if (col is TableCol &&
            index >= range.startColumn &&
            index <= range.endColumn) {
          cols.add(col.element);
        }
        index += 1;
      }
    }

    if (!selection.updateSelected('column')) hideTools();
    blot.deleteColumn(changeTds, delTds, deleteTable, cols);
    if (target != null && bounds != null) {
      utils.updateTableWidth(
        blot,
        bounds,
        -(range.endColumn - range.startColumn + 1) *
            cellDefaultWidth.toDouble(),
      );
    }
    updateMenus();
  }

  /// TS `deleteRow(isKeyboard)`.
  void deleteRow([bool isKeyboard = false]) {
    final selection = cellSelection;
    final blot = tableBlot;
    if (selection == null || blot == null) return;
    if (selection.selectedTds.isEmpty) return;
    final rows = getCorrectRows();
    if (rows.isEmpty) return;
    if (isKeyboard) {
      final sum =
          rows.fold<int>(0, (total, row) => total + row.children.length);
      if (sum != selection.selectedTds.length) return;
    }
    if (!selection.updateSelected('row')) hideTools();
    blot.deleteRow(rows, deleteTable);
    updateMenus();
  }

  /// TS `deleteTable()` (table-menus.ts:485-492).
  void deleteTable() {
    final blot = tableBlot;
    if (blot == null) return;
    final offset = quill.scroll.offset(blot);
    blot.remove();
    hideTools();
    hideMenus();
    // The blot was removed outside the delta pipeline, so the cached
    // document delta must be reconciled — `scroll.optimize` alone left
    // `getContents()` still reporting the deleted table (the module's own
    // `deleteTable` twin already did this; this one did not).
    quill.update(EmitterSource.USER);
    final length = quill.scroll.length();
    quill.setSelection(
      Range((offset - 1).clamp(0, length).toInt(), 0),
      source: EmitterSource.USER,
    );
    table = null;
  }

  /// TS `insertParagraph(offset)`.
  void insertParagraph(int offset) {
    final blot = tableBlot;
    if (blot == null) return;
    final index = quill.scroll.offset(blot);
    final length = offset > 0 ? blot.length() : 0;
    final delta = Delta()
      ..retain(index + length)
      ..insert('\n');
    quill.updateContents(delta, source: EmitterSource.USER);
    quill.setSelection(
      Range(index + length, 0),
      source: EmitterSource.SILENT,
    );
    hideTools();
    hideMenus();
    quill.scrollSelectionIntoView();
  }

  /// TS `mergeCells()` — the grid arithmetic lives in [CellSelection].
  void mergeCells() {
    cellSelection?.mergeCells();
    quill.scrollSelectionIntoView();
  }

  /// TS `splitCell()`.
  void splitCell() {
    cellSelection?.splitCells();
    quill.scrollSelectionIntoView();
  }

  /// TS `selectColumn()`.
  void selectColumn() {
    cellSelection?.selectColumn();
    updateMenus();
  }

  /// TS `selectRow()`.
  void selectRow() {
    cellSelection?.selectRow();
    updateMenus();
  }

  /// TS `copyTable()` — the async ClipboardItem write belongs to the caller;
  /// this returns the payload and moves the selection past the table.
  CellSelectionClipboardData? copyTable() {
    final selection = cellSelection;
    final blot = tableBlot;
    if (selection == null || blot == null) return null;
    final data = selection.copyTableData();
    final index = quill.scroll.offset(blot);
    quill.setSelection(
      Range(index + blot.length(), 0),
      source: EmitterSource.SILENT,
    );
    hideTools();
    hideMenus();
    quill.scrollSelectionIntoView();
    return data;
  }

  /// TS `toggleHeaderRow()`.
  void toggleHeaderRow() {
    final selection = cellSelection;
    if (selection == null) return;
    final (:hasTd, :hasTh) = selection.hasTdTh();
    if (!hasTd && hasTh) {
      selection.convertToRow();
    } else {
      selection.convertToHeaderRow();
    }
  }

  /// TS `toggleHeaderRowSwitch(value)`.
  void toggleHeaderRowSwitch([String? value]) {
    final headerRow = tableHeaderRow;
    if (headerRow == null) return;
    final inners = headerRow.querySelectorAll('.ql-table-switch-inner');
    if (inners.isEmpty) return;
    final switchInner = inners.first;
    var next = value;
    if (next == null) {
      final checked = switchInner.getAttribute('aria-checked');
      next = checked == 'false' ? 'true' : 'false';
    }
    switchInner.setAttribute('aria-checked', next);
  }

  /// TS `getCorrectRows()` — rows covered by the selection, rowspan included.
  List<TableRow> getCorrectRows() {
    final selection = cellSelection;
    final range = selection?.range;
    if (selection == null || range == null) return const [];
    final rows = <TableRow>[];
    final all = selection.table.descendants<TableRow>().toList();
    for (var index = range.startRow; index <= range.endRow; index++) {
      if (index >= 0 && index < all.length) rows.add(all[index]);
    }
    return rows;
  }

  /// TS `getTableAlignment(table)`.
  String getTableAlignment(DomElement target) {
    final align = target.getAttribute('align');
    if (align != null && align.isNotEmpty) return align;
    final style = utils
        .getElementStyle(target, const [_Alignment.left, _Alignment.right]);
    if (style[_Alignment.left] == 'auto') {
      return style[_Alignment.right] == 'auto' ? 'center' : 'right';
    }
    return 'left';
  }

  /// TS `getSelectedTdAttrs(td)`.
  Map<String, String> getSelectedTdAttrs(TableCell cell) {
    final attrs = utils.getElementStyle(cell.element, cellProperties);
    final align = utils.getAlign(cell);
    if (align.isNotEmpty) {
      return {...attrs, 'text-align': align};
    }
    return attrs;
  }

  /// TS `getSelectedTdsAttrs(selectedTds)` — properties that differ across the
  /// selection fall back to their default value.
  Map<String, String> getSelectedTdsAttrs(List<TableCell> cells) {
    if (cells.isEmpty) return const {};
    final attribute = Map<String, String>.from(getSelectedTdAttrs(cells.first));
    final differing = <String>{};
    for (final cell in cells.skip(1)) {
      final attrs = getSelectedTdAttrs(cell);
      for (final key in attribute.keys) {
        if (differing.contains(key)) continue;
        if (attrs[key] != attribute[key]) differing.add(key);
      }
    }
    for (final key in differing) {
      attribute[key] = cellDefaultValues[key] ?? '';
    }
    return attribute;
  }

  /// Attribute map the `table` properties menu opens with (TS inlines this in
  /// the menu handler).
  Map<String, String> tablePropertiesAttributes() {
    final target = table;
    if (target == null) return const {};
    return {
      ...utils.getElementStyle(target, tableProperties),
      'align': getTableAlignment(target),
    };
  }

  /// Attribute map the `cell` properties menu opens with.
  Map<String, String> cellPropertiesAttributes() {
    final cells = cellSelection?.selectedCells ?? const <TableCell>[];
    if (cells.isEmpty) return const {};
    return cells.length > 1
        ? getSelectedTdsAttrs(cells)
        : getSelectedTdAttrs(cells.first);
  }

  /// TS: the `table` menu handler builds the form with the table's attributes.
  void openTableProperties() {
    if (onOpenProperties != null) {
      onOpenProperties!(this, 'table');
      return;
    }
    _openProperties('table', tablePropertiesAttributes());
  }

  /// TS: the `cell` menu handler builds the form with the cells' attributes.
  void openCellProperties() {
    if (onOpenProperties != null) {
      onOpenProperties!(this, 'cell');
      return;
    }
    _openProperties('cell', cellPropertiesAttributes());
  }

  void _openProperties(String type, Map<String, String> attribute) {
    destroyTablePropertiesForm();
    final target = table;
    if (target == null) return;
    final bounds = getCorrectBounds(target);
    tablePropertiesForm = TablePropertiesForm(
      type: type,
      attribute: attribute,
      host: TablePropertiesFormHost(
        container: quill.container,
        language: language,
        table: tableBlot,
        selectedCells: cellSelection?.selectedCells ?? const [],
        containerBounds: bounds[1],
        targetBounds: bounds[0],
        onClose: () {
          tablePropertiesForm = null;
          showMenus();
          updateMenus();
        },
        // The save writes styles onto the table/temporary element directly
        // (upstream relies on the MutationObserver from there); this port
        // asks for the reconcile, so the temporary's attributes reach the
        // `<table>` and `getContents()` reports the new styling.
        onSaved: () => quill.update(EmitterSource.USER),
      ),
    )..updatePropertiesForm();
  }

  /// TS `destroyTablePropertiesForm()`.
  void destroyTablePropertiesForm() {
    if (onOpenProperties != null) {
      onOpenProperties!(this, 'close');
      return;
    }
    tablePropertiesForm?.removePropertiesForm();
    tablePropertiesForm = null;
  }

  // --- helpers ------------------------------------------------------------

  /// Attribute selectors are not universally available across the DOM
  /// adapters, so the category lookup walks the built menus instead.
  DomElement? _menuElement(String category) {
    for (final element in root.querySelectorAll('[data-category]')) {
      if (element.getAttribute('data-category') == category) return element;
    }
    return null;
  }

  bool _isInsideHeaderRow(DomNode? target) {
    DomNode? node = target;
    while (node != null) {
      if (node is DomElement && node.classes.contains('ql-table-header-row')) {
        return true;
      }
      node = node.parentNode;
    }
    return false;
  }

  DomElement? _closestTable(DomNode? target) {
    DomNode? node = target;
    while (node != null) {
      if (node is DomElement && node.tagName.toUpperCase() == 'TABLE') {
        return node;
      }
      if (node == quill.root) return null;
      node = node.parentNode;
    }
    return null;
  }

  TableCell? _cellAt(CellSelection selection, int row, int column) {
    for (final entry in _grid(selection)) {
      if (entry.row <= row &&
          row < entry.row + entry.rowspan &&
          entry.column <= column &&
          column < entry.column + entry.colspan) {
        return entry.cell;
      }
    }
    return null;
  }

  int _overlap(int aStart, int aEnd, int bStart, int bEnd) {
    final start = aStart > bStart ? aStart : bStart;
    final end = aEnd < bEnd ? aEnd : bEnd;
    return end < start ? 0 : end - start + 1;
  }

  List<_GridEntry> _grid(CellSelection selection) {
    final entries = <_GridEntry>[];
    final occupied = <int, int>{};
    final rows = selection.table.descendants<TableRow>().toList();
    for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) {
      var column = 0;
      for (final child in rows[rowIndex].children) {
        if (child is! TableCell) continue;
        while ((occupied[column] ?? -1) >= rowIndex) {
          column++;
        }
        final rowspan = _span(child, 'rowspan');
        final colspan = _span(child, 'colspan');
        entries.add(_GridEntry(child, rowIndex, column, rowspan, colspan));
        for (var offset = 0; offset < colspan; offset++) {
          if (rowspan > 1) occupied[column + offset] = rowIndex + rowspan - 1;
        }
        column += colspan;
      }
    }
    return entries;
  }

  int _span(TableCell cell, String name) {
    final value = int.tryParse(cell.element.getAttribute(name) ?? '') ?? 1;
    return value < 1 ? 1 : value;
  }
}

class _GridEntry {
  const _GridEntry(
      this.cell, this.row, this.column, this.rowspan, this.colspan);

  final TableCell cell;
  final int row;
  final int column;
  final int rowspan;
  final int colspan;
}
