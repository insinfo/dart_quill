@TestOn('vm')
library;

import 'dart:io';

import 'package:dart_quill/src/core/selection.dart';
import 'package:dart_quill/src/modules/toolbar.dart';
import 'package:dart_quill/src/platform/dom.dart';
import 'package:dart_quill/src/table_better/formats/table.dart';
import 'package:dart_quill/src/table_better/language/language.dart';
import 'package:dart_quill/src/table_better/register.dart';
import 'package:dart_quill/src/table_better/table_better.dart';
import 'package:dart_quill/src/table_better/ui/color_wheel.dart';
import 'package:dart_quill/src/table_better/ui/table_properties_form.dart';
import 'package:dart_quill/src/table_better/ui/toolbar_table.dart';
import 'package:test/test.dart';

import '../../support/fake_dom.dart';
import '../../support/quill_test_helpers.dart';
import '../../support/test_helpers.dart';

/// Guards `lib/assets/quill-table-better.css` against the UI it is supposed to
/// style.
///
/// The stylesheet is the upstream `quill-table-better.scss` compiled with sass;
/// none of its class names mean anything on their own. What matters is that the
/// classes this port actually writes to the DOM have a producer in the sheet —
/// the failure mode is an invisible one (a menu that renders unstyled), which no
/// behavioural test catches. So these tests build the real widgets against the
/// fake DOM, collect every class that ends up on an element, and check the sheet
/// mentions it.
void main() {
  late String stylesheet;
  late Set<String> styledClasses;

  setUpAll(() {
    ensureQuillTestInitialized();
    registerTableBetter(replaceClipboard: false);
    stylesheet = File('lib/assets/quill-table-better.css').readAsStringSync();
    styledClasses = _selectorClasses(stylesheet);
  });

  setUp(() {
    final body = testAdapter.document.body;
    while (body.firstChild != null) {
      body.firstChild!.remove();
    }
  });

  TableBetter createModule({
    bool toolbarTable = false,
    List<List<String>> toolbar = const [
      ['bold', 'table-better']
    ],
  }) {
    final quill = createTestQuill(
      theme: 'snow',
      modules: {
        'toolbar': ToolbarProps(container: ToolbarConfig(toolbar)),
        'table-better': <String, dynamic>{'toolbarTable': toolbarTable},
      },
    );
    return quill.getModule('table-better') as TableBetter;
  }

  ({TableBetter module, TableContainer table}) withTable() {
    final module = createModule();
    module.quill.setSelection(const Range(0, 0));
    module.insertTable(2, 2);
    final table = module.quill.scroll.descendants<TableContainer>().single;
    final block = table.descendants<TableCellBlock>().first;
    module.quill.setSelection(Range(module.quill.scroll.offset(block), 0));
    return (module: module, table: table);
  }

  /// Asserts that every class under [root] has at least one rule in the sheet.
  ///
  /// `ql-hidden`, `ql-picker` and friends belong to Quill's own stylesheet, so
  /// they are excluded rather than reported as gaps.
  void expectStyled(DomElement root, {required String what}) {
    final used = _classesInTree(root)
        .where((name) => !_ownedByQuillCore.contains(name))
        .where((name) => !_unstyledUpstream.contains(name))
        .where((name) => !name.startsWith('Iro'))
        .toList()
      ..sort();
    expect(used, isNotEmpty, reason: '$what produced no classes at all');
    final unstyled = used.where((name) => !styledClasses.contains(name));
    expect(
      unstyled,
      isEmpty,
      reason: '$what writes classes with no rule in '
          'lib/assets/quill-table-better.css',
    );
  }

  group('the stylesheet ships and is the compiled upstream sheet', () {
    test('the file assets.dart links to exists', () {
      final file = File('lib/assets/quill-table-better.css');
      expect(file.existsSync(), isTrue);
      expect(file.readAsStringSync().length, greaterThan(10000));
    });

    test('the check mark is self-contained, not a relative image', () {
      // Upstream inlines ../icon/check.png through url-loader; keeping the
      // data URI means dropping the single .css file into a page is enough.
      final urls = RegExp(r'url\(([^)]*)\)')
          .allMatches(stylesheet.replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), ''))
          .map((match) => match.group(1)!)
          .toList();
      expect(urls, isNotEmpty);
      for (final url in urls) {
        expect(url, startsWith('"data:'),
            reason: 'the sheet must not depend on a sibling asset');
      }
    });

    test('the keyframes the validation shake depends on are present', () {
      expect(stylesheet, contains('@keyframes ql-table-input-shake'));
    });
  });

  group('every class the UI writes has a rule', () {
    test('floating menus', () {
      final (:module, :table) = withTable();
      module.showTools();
      expectStyled(module.tableMenus.root, what: 'TableMenus');
    });

    test('menu dropdown lists, opened', () {
      final (:module, :table) = withTable();
      module.showTools();
      final menus = module.tableMenus;
      for (final dropdown in menus.root.querySelectorAll('[data-category]')) {
        dropdown.click();
      }
      expectStyled(menus.root, what: 'TableMenus with an open dropdown');
    });

    test('table properties form', () {
      final (:module, :table) = withTable();
      final form = _buildForm(type: 'table', table: table);
      expectStyled(form.form, what: 'the table properties form');
    });

    test('cell properties form', () {
      final (:module, :table) = withTable();
      final form = _buildForm(
        type: 'cell',
        table: table,
        cells: table.descendants<TableCell>().take(1).toList(),
      );
      expectStyled(form.form, what: 'the cell properties form');
    });

    test('the 10x10 toolbar grid', () {
      final select = TableSelect(document: testAdapter.document);
      expectStyled(select.root, what: 'TableSelect');
    });

    test('the resize overlay', () {
      final (:module, :table) = withTable();
      final cell = table.descendants<TableCell>().first.element;
      module.operateLine
          .handleMouseMove(FakeDomMouseEvent(type: 'mousemove', target: cell));
      expect(module.operateLine.line, isNotNull);
      expectStyled(module.operateLine.line!, what: 'the resize line');
      expectStyled(module.operateLine.dragBlock!, what: 'the corner block');
    });
  });

  group('classes applied to existing elements', () {
    test('cell selection marks cells with styled classes', () {
      final (:module, :table) = withTable();
      final cells = table.descendants<TableCell>().toList();
      final selection = module.controllerFor(table);

      selection.setSelected(cells.first.element, true);
      expect(_classesInTree(table.element), contains('ql-cell-focused'));

      // `setSelectedTds` clears first, so the two classes never coexist.
      selection.setSelectedTds(cells.map((cell) => cell.element).toList());
      expect(_classesInTree(table.element), contains('ql-cell-selected'));

      // Both draw through ::after, which needs the positioned parent rule.
      expect(stylesheet, contains('.ql-cell-focused {'));
      expect(stylesheet, contains('.ql-cell-selected {'));
      expect(stylesheet, contains('.ql-cell-focused::after'));
      expect(stylesheet, contains('.ql-cell-selected::after'));
    });

    test('the colour wheel needs no rules — it styles inline, as iro.js does',
        () {
      final wheel = ColorWheel(document: testAdapter.document);
      final layers = _descendantElements(wheel.root)
          .where((element) => element.classes.values.any((c) =>
              c.startsWith('IroWheel') || c.startsWith('IroHandle')))
          .toList();
      expect(layers, isNotEmpty);
      for (final layer in layers) {
        expect(layer.getAttribute('style'), isNotNull,
            reason: 'an Iro* layer without inline style would render blank, '
                'since the stylesheet has no rule for it');
      }
    });

    test('a disabled toolbar button uses the documented class', () {
      expect(styledClasses, contains('ql-table-button-disabled'));
      expect(styledClasses, contains('ql-table-disabled'));
    });

    test('the temporary blot is hidden by the sheet, not by inline style', () {
      final (:module, :table) = withTable();
      final temporary = table.element.querySelectorAll('.ql-table-temporary');
      expect(temporary, isNotEmpty);
      expect(styledClasses, contains('ql-table-temporary'));
    });
  });
}

/// Classes the upstream `.scss` leaves unstyled too — excluded on parity
/// grounds, not because the sheet is incomplete:
///
/// * `icon` comes inside the `<svg>` assets themselves (an iconfont export);
/// * `ql-table-dropdown-icon` (table-properties-form.ts:275),
///   `ql-table-block` (formats/table.ts:28) and `ql-table-header`
///   (formats/header.ts:12) are written by the TS and matched by no rule.
///
/// Grep the plugin's `src/` before adding to this list; a genuinely missing
/// rule belongs in the stylesheet instead.
const Set<String> _unstyledUpstream = {
  'icon',
  'ql-table-dropdown-icon',
  'ql-table-block',
  'ql-table-header',
};

/// Classes owned by `quill.snow.css`, not by the table-better sheet.
const Set<String> _ownedByQuillCore = {
  'ql-hidden',
  'ql-picker',
  'ql-picker-label',
  'ql-picker-options',
  'ql-picker-item',
  'ql-formats',
  'ql-active',
  'ql-stroke',
  'ql-fill',
  'ql-editor',
  'ql-container',
  'ql-toolbar',
};

/// Every class named anywhere in a selector of [css].
Set<String> _selectorClasses(String css) {
  final withoutComments = css.replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '');
  final withoutBodies =
      withoutComments.replaceAll(RegExp(r'\{[^{}]*\}'), '{}');
  return RegExp(r'\.(-?[_a-zA-Z][-\w]*)')
      .allMatches(withoutBodies)
      .map((match) => match.group(1)!)
      .toSet();
}

/// Every class on [root] and its descendant elements.
Set<String> _classesInTree(DomElement root) =>
    _descendantElements(root).expand((e) => e.classes.values).toSet();

/// [root] plus every descendant element, in document order.
List<DomElement> _descendantElements(DomElement root) {
  final found = <DomElement>[];
  void visit(DomNode node) {
    if (node is! DomElement) return;
    found.add(node);
    for (final child in node.childNodes) {
      visit(child);
    }
  }

  visit(root);
  return found;
}

TablePropertiesForm _buildForm({
  required String type,
  TableContainer? table,
  List<TableCell> cells = const [],
}) {
  final container = testAdapter.document.createElement('div');
  testAdapter.document.body.append(container);
  return TablePropertiesForm(
    type: type,
    attribute: const {},
    host: TablePropertiesFormHost(
      container: container,
      language: Language('en_US'),
      table: table,
      selectedCells: cells,
      onClose: () {},
    ),
  );
}
