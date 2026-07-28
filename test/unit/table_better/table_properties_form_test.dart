import 'package:dart_quill/src/core/selection.dart';
import 'package:dart_quill/src/platform/dom.dart';
import 'package:dart_quill/src/table_better/formats/table.dart';
import 'package:dart_quill/src/table_better/language/language.dart';
import 'package:dart_quill/src/table_better/register.dart';
import 'package:dart_quill/src/table_better/table_better.dart';
import 'package:dart_quill/src/table_better/ui/color_wheel.dart';
import 'package:dart_quill/src/table_better/ui/table_properties_form.dart';
import 'package:test/test.dart';

import '../../support/quill_test_helpers.dart';
import '../../support/test_helpers.dart';

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

  ({TableBetter module, TableContainer table}) withTable(
      {int rows = 2, int columns = 2}) {
    final quill = createTestQuill(
      modules: {'table-better': const <String, dynamic>{}},
    );
    final module = quill.getModule('table-better') as TableBetter;
    quill.setSelection(const Range(0, 0));
    module.insertTable(rows, columns);
    final table = quill.scroll.descendants<TableContainer>().single;
    final block = table.descendants<TableCellBlock>().first;
    quill.setSelection(Range(quill.scroll.offset(block), 0));
    return (module: module, table: table);
  }

  TablePropertiesForm buildForm({
    required String type,
    Map<String, String> attribute = const {},
    TableContainer? table,
    List<TableCell> cells = const [],
    void Function()? onClose,
  }) {
    final container = testAdapter.document.createElement('div');
    testAdapter.document.body.append(container);
    return TablePropertiesForm(
      type: type,
      attribute: attribute,
      host: TablePropertiesFormHost(
        container: container,
        language: Language('en_US'),
        table: table,
        selectedCells: cells,
        onClose: onClose ?? () {},
      ),
    );
  }

  group('structure', () {
    test('a table form carries the upstream skeleton', () {
      final form = buildForm(type: 'table');

      expect(form.form.classes.contains('ql-table-properties-form'), isTrue);
      expect(
          form.form.querySelectorAll('.properties-form-header'), hasLength(1));
      expect(form.form.querySelectorAll('.properties-form-row'), isNotEmpty);
      // One action row for the form, plus one inside each colour wheel palette.
      final actionRows =
          form.form.querySelectorAll('.properties-form-action-row');
      expect(actionRows, isNotEmpty);

      final buttons = actionRows.last.querySelectorAll('button');
      expect(buttons, hasLength(2));
      expect(buttons.first.getAttribute('label'), equals('save'));
      expect(buttons.last.getAttribute('label'), equals('cancel'));
      expect(form.saveButton, isNotNull);
    });

    test('colour fields get the palette of 15 swatches and a remove button',
        () {
      final form = buildForm(type: 'table');
      final colors = form.form.querySelectorAll('.ql-table-color-container');
      expect(colors, isNotEmpty);

      final list = colors.first.querySelectorAll('.color-list').first;
      expect(list.querySelectorAll('li'), hasLength(15));
      expect(list.querySelectorAll('li').first.getAttribute('data-color'),
          equals('#000000'));
      // Two icon rows: "remove colour" and the palette (wheel) toggle.
      expect(colors.first.querySelectorAll('.erase-container'), hasLength(2));
      // The picker starts closed.
      expect(
        colors.first
            .querySelectorAll('.color-picker-select')
            .first
            .classes
            .contains('ql-hidden'),
        isTrue,
      );
    });

    test('the border style dropdown lists every CSS style', () {
      final form = buildForm(type: 'table');
      final dropdowns =
          form.form.querySelectorAll('.ql-table-dropdown-properties');
      expect(dropdowns, isNotEmpty);
      final items = dropdowns.first
          .querySelectorAll('.ql-table-dropdown-list')
          .first
          .querySelectorAll('li')
          .map((li) => li.text)
          .toList();
      expect(items, contains('dashed'));
      expect(items, contains('none'));
      expect(items, contains('solid'));
    });

    test('a cell form offers the alignment check buttons', () {
      final form = buildForm(type: 'cell');
      final checks = form.form.querySelectorAll('.ql-table-check-container');
      expect(checks, isNotEmpty);
      expect(checks.first.querySelectorAll('span'), isNotEmpty);
    });

    test('the current alignment starts checked', () {
      final form = buildForm(type: 'cell', attribute: {'text-align': 'center'});
      final checks = form.form
          .querySelectorAll('.ql-table-check-container')
          .firstWhere((c) => c.getAttribute('data-property') == 'text-align');
      final checked = checks
          .querySelectorAll('span')
          .where((s) => s.classes.contains('ql-table-btns-checked'))
          .toList();
      expect(checked, hasLength(1));
      expect(checked.first.getAttribute('data-align'), equals('center'));
    });
  });

  group('validation', () {
    test('an invalid dimension marks the field and disables save', () {
      final form = buildForm(type: 'table');

      expect(form.setInputValue('width', 'not-a-size'), isTrue);
      expect(form.saveButton!.getAttribute('disabled'), equals('true'));
      expect(form.form.querySelectorAll('.label-field-view-error'), isNotEmpty);

      // A valid value clears the error and re-enables save.
      form.setInputValue('width', '250px');
      expect(form.saveButton!.hasAttribute('disabled'), isFalse);
      expect(form.form.querySelectorAll('.label-field-view-error'), isEmpty);
    });

    test('an invalid colour is reported instead of throwing', () {
      final form = buildForm(type: 'table');
      expect(
        () => form.setInputValue('background-color', 'nonsense'),
        returnsNormally,
      );
      expect(form.saveButton!.getAttribute('disabled'), equals('true'));
    });

    test('border: none greys out colour and width', () {
      final form =
          buildForm(type: 'table', attribute: {'border-style': 'solid'});
      form.toggleBorderDisabled('none');

      expect(form.attrs['border-color'], isEmpty);
      expect(form.attrs['border-width'], isEmpty);
      expect(form.borderForm[1].classes.contains('ql-table-disabled'), isTrue);
      expect(form.borderForm[2].classes.contains('ql-table-disabled'), isTrue);

      form.toggleBorderDisabled('solid');
      expect(form.borderForm[1].classes.contains('ql-table-disabled'), isFalse);
    });
  });

  group('getDiffProperties', () {
    test('only changed values survive, with dimension units added', () {
      final form = buildForm(
        type: 'table',
        attribute: {
          'width': '100px',
          'background-color': '#ffffff',
          // Without a border style the form starts by clearing border-color
          // and border-width (upstream `setBorderDisabled` does the same), so
          // give it one to isolate what the user changes.
          'border-style': 'solid',
          'border-color': '#000000',
          'border-width': '1px',
        },
      );

      expect(form.getDiffProperties(), isEmpty);

      form.setAttribute('width', '250');
      form.setAttribute('background-color', '#ffffff');
      final diff = form.getDiffProperties();
      expect(diff.keys, equals(['width']));
      expect(diff['width'], equals('250px'));
    });
  });

  group('save', () {
    test('table align becomes a margin declaration', () {
      final (module: _, :table) = withTable();
      final form = buildForm(
        type: 'table',
        attribute: {'align': 'left'},
        table: table,
      );

      form.setAttribute('align', 'center');
      form.saveAction();

      final target = table.temporary()?.element ?? table.element;
      expect(target.getAttribute('style'), contains('margin: 0 auto'));
    });

    test('right align writes margin-left auto', () {
      final (module: _, :table) = withTable();
      final form = buildForm(
        type: 'table',
        attribute: {'align': 'left'},
        table: table,
      );

      form.setAttribute('align', 'right');
      form.saveAction();

      final target = table.temporary()?.element ?? table.element;
      expect(target.getAttribute('style'), contains('margin-left: auto'));
    });

    test('cell styles land on every selected cell', () {
      final (module: _, :table) = withTable();
      final cells = table.descendants<TableCell>().take(2).toList();
      final form = buildForm(type: 'cell', cells: cells);

      form.setAttribute('background-color', '#ff0000');
      form.saveAction();

      for (final cell in cells) {
        expect(cell.element.getAttribute('style'),
            contains('background-color: #ff0000'));
      }
    });

    test('text-align propagates into the cell blocks, not the cell style', () {
      final (module: _, :table) = withTable();
      final cell = table.descendants<TableCell>().first;
      final form = buildForm(type: 'cell', cells: [cell]);

      form.setAttribute('text-align', 'center');
      form.saveAction();

      expect(cell.element.getAttribute('style') ?? '',
          isNot(contains('text-align')));
      expect(cell.children.first.formats()['align'], equals('center'));
    });

    test('save closes the form and hands control back', () {
      var closed = false;
      final form = buildForm(type: 'table', onClose: () => closed = true);
      final container = form.form.parentNode as DomElement;

      form.checkBtnsAction('save');

      expect(closed, isTrue);
      expect(container.querySelectorAll('.ql-table-properties-form'), isEmpty);
      expect(form.borderForm, isEmpty);
    });

    test('cancel closes without writing anything', () {
      final (module: _, :table) = withTable();
      final before = table.element.getAttribute('style');
      final form = buildForm(
        type: 'table',
        attribute: {'align': 'left'},
        table: table,
      );

      form.setAttribute('align', 'center');
      form.checkBtnsAction('cancel');

      expect(table.element.getAttribute('style'), equals(before));
    });
  });

  group('menus integration', () {
    test('the table menu opens a form and closing removes it', () {
      final (:module, table: _) = withTable();
      module.tableMenus.openTableProperties();

      expect(module.tableMenus.tablePropertiesForm, isNotNull);
      expect(
        module.quill.container.querySelectorAll('.ql-table-properties-form'),
        hasLength(1),
      );

      module.tableMenus.destroyTablePropertiesForm();
      expect(module.tableMenus.tablePropertiesForm, isNull);
      expect(
        module.quill.container.querySelectorAll('.ql-table-properties-form'),
        isEmpty,
      );
    });

    test('the cell menu opens with the selected cells attached', () {
      final (:module, :table) = withTable();
      final controller = module.controllerFor(table);
      controller.setSelectedTds(
        table.descendants<TableCell>().take(2).map((c) => c.element).toList(),
      );

      module.tableMenus.openCellProperties();
      final form = module.tableMenus.tablePropertiesForm;
      expect(form, isNotNull);
      expect(form!.host.selectedCells, hasLength(2));
      expect(form.type, equals('cell'));
    });
  });

  group('colour wheel', () {
    test('each colour field gets a wheel behind the palette button', () {
      final form = buildForm(
        type: 'table',
        attribute: {'background-color': '#ff0000'},
      );

      expect(form.colorWheels.containsKey('background-color'), isTrue);
      expect(form.colorWheels['background-color']!.color.hexString,
          equals('#ff0000'));

      final palettes = form.form.querySelectorAll('.color-picker-palette');
      expect(palettes, isNotEmpty);
      expect(palettes.first.classes.contains('ql-hidden'), isTrue);
      expect(form.form.querySelectorAll('.IroWheel'), isNotEmpty);
    });

    test('picking on the wheel and saving writes the colour to the field', () {
      final form = buildForm(
        type: 'table',
        attribute: {'background-color': '#ffffff'},
      );
      final wheel = form.colorWheels['background-color']!;

      wheel.color = const HsvColor(240, 100, 100);
      // Scope to this field: a table form has several colour containers.
      final field = form.form
          .querySelectorAll('.ql-table-color-container')
          .firstWhere(
              (c) => c.getAttribute('data-property') == 'background-color');
      // The palette's own action row commits it (label 'save').
      final palette = field.querySelectorAll('.color-picker-palette').first;
      final saveButton = palette
          .querySelectorAll('button')
          .firstWhere((b) => b.getAttribute('label') == 'save');
      saveButton.click();

      expect(form.attrs['background-color'], equals('#0000ff'));
      expect(form.getDiffProperties()['background-color'], equals('#0000ff'));
      expect(palette.classes.contains('ql-hidden'), isTrue);
    });
  });
}
