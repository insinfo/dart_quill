import 'package:dart_quill/src/core/selection.dart';
import 'package:dart_quill/src/modules/toolbar.dart';
import 'package:dart_quill/src/platform/dom.dart';
import 'package:dart_quill/src/table_better/formats/table.dart';
import 'package:dart_quill/src/table_better/register.dart';
import 'package:dart_quill/src/table_better/table_better.dart';
import 'package:test/test.dart';

import '../../support/fake_dom.dart';
import '../../support/quill_test_helpers.dart';
import '../../support/test_helpers.dart';

/// Two tables in one document.
///
/// Upstream keeps a single `CellSelection` for the whole editor, so "only one
/// selection is live" holds by construction. This port keys the logical grid by
/// table — one [CellSelectionController] each — which bought headless testing
/// but lost that invariant. These are the two things that broke before
/// `clearOtherSelections` restored it:
///
/// * both tables could carry `ql-cell-selected` at the same time;
/// * the toolbar disable state is editor-wide, yet each controller computed it
///   from its own selection, so the last one to run won.
void main() {
  setUpAll(() {
    ensureQuillTestInitialized();
    registerTableBetter(replaceClipboard: false);
  });

  setUp(() {
    final body = testAdapter.document.body;
    while (body.firstChild != null) {
      body.firstChild!.remove();
    }
  });

  ({TableBetter module, List<TableContainer> tables}) withTwoTables() {
    final quill = createTestQuill(
      theme: 'snow',
      modules: {
        'toolbar': ToolbarProps(
          container: ToolbarConfig(const [
            ['bold', 'blockquote', 'link']
          ]),
        ),
        'table-better': const <String, dynamic>{},
      },
    );
    final module = quill.getModule('table-better') as TableBetter;
    quill.setSelection(const Range(0, 0));
    module.insertTable(2, 2);
    quill.setSelection(Range(quill.getLength() - 1, 0));
    module.insertTable(2, 2);
    final tables = quill.scroll.descendants<TableContainer>().toList();
    expect(tables, hasLength(2));
    return (module: module, tables: tables);
  }

  List<DomElement> cellsOf(TableContainer table) =>
      table.descendants<TableCell>().map((cell) => cell.element).toList();

  DomElement button(TableBetter module, String className) {
    final toolbar = module.quill.getModule('toolbar');
    final container = (toolbar as dynamic).container as DomElement;
    return container
        .querySelectorAll('button')
        .firstWhere((element) => element.classes.contains(className));
  }

  bool isSelected(DomElement td) =>
      td.classes.contains('ql-cell-selected') ||
      td.classes.contains('ql-cell-focused');

  test('selecting in one table drops the selection of the other', () {
    final (:module, :tables) = withTwoTables();
    final first = cellsOf(tables[0]);
    final second = cellsOf(tables[1]);

    module.controllerFor(tables[0]).setSelectedTds(first);
    expect(first.where(isSelected), hasLength(4));

    module.controllerFor(tables[1]).handleMousedown(
        FakeDomMouseEvent(type: 'mousedown', target: second.first));

    expect(first.where(isSelected), isEmpty,
        reason: 'two tables must never look selected at once');
    expect(second.where(isSelected), hasLength(1));
  });

  test('a drag in the second table clears the first', () {
    final (:module, :tables) = withTwoTables();
    module.controllerFor(tables[0]).setSelectedTds(cellsOf(tables[0]));

    final controller = module.controllerFor(tables[1]);
    final cells = tables[1].descendants<TableCell>().toList();
    controller.selectRange(cells.first, cells.last);

    expect(cellsOf(tables[0]).where(isSelected), isEmpty);
    expect(controller.selectedTds, hasLength(4));
  });

  test('there is one controller for the editor, not one per table', () {
    final (:module, :tables) = withTwoTables();
    expect(
      identical(module.controllerFor(tables[0]), module.controllerFor(tables[1])),
      isTrue,
      reason: 'upstream has a single CellSelection; so must this port, or the '
          'editor-wide toolbar state ends up with two owners',
    );
    expect(identical(module.controllerFor(tables[0]), module.cellSelection),
        isTrue);
  });

  test('the editor-wide toolbar state follows the visible selection', () {
    final (:module, :tables) = withTwoTables();
    final link = button(module, 'ql-link');
    final quote = button(module, 'ql-blockquote');

    // A multi-cell selection greys out `link` (single white list) as well as
    // the formats outside the white list.
    final controller = module.controllerFor(tables[0]);
    controller.setSelectedTds(cellsOf(tables[0]));
    controller.setDisabled(true);
    expect(quote.classes.contains('ql-table-button-disabled'), isTrue);
    expect(link.classes.contains('ql-table-button-disabled'), isTrue);

    // Moving to the other table drops the selection, so `link` — which only
    // applies to a single cell — comes back.
    module.controllerFor(tables[1]).setSelected(cellsOf(tables[1]).first);

    expect(cellsOf(tables[0]).where(isSelected), isEmpty);
    expect(link.classes.contains('ql-table-button-disabled'), isFalse);
    expect(quote.classes.contains('ql-table-button-disabled'), isTrue,
        reason: 'a cell is still selected, just in the other table');
  });

  test('hideTools still clears every table', () {
    final (:module, :tables) = withTwoTables();
    module.controllerFor(tables[0]).setSelectedTds(cellsOf(tables[0]));

    module.hideTools();

    for (final table in tables) {
      expect(cellsOf(table).where(isSelected), isEmpty);
    }
  });
}
