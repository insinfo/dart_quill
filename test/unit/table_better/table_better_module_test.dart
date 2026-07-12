import 'package:dart_quill/src/core/selection.dart';
import 'package:dart_quill/src/table_better/formats/table.dart';
import 'package:dart_quill/src/table_better/formats/header.dart';
import 'package:dart_quill/src/table_better/formats/list.dart';
import 'package:dart_quill/src/table_better/register.dart';
import 'package:dart_quill/src/table_better/table_better.dart';
import 'package:dart_quill/src/modules/toolbar.dart';
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

  TableBetter createModule({bool withToolbar = false}) {
    final modules = <String, dynamic>{
      if (withToolbar)
        'toolbar': ToolbarProps(
          container: ToolbarConfig(const [
            ['header', 'list']
          ]),
        ),
      'table-better': const <String, dynamic>{},
    };
    final quill = createTestQuill(
      modules: modules,
      theme: withToolbar ? 'snow' : null,
    );
    return quill.getModule('table-better') as TableBetter;
  }

  test('inserts one well-formed table and resolves its context', () {
    final module = createModule();
    module.quill.setSelection(const Range(0, 0));
    module.insertTable(2, 3);

    final tables = module.quill.scroll.descendants<TableContainer>().toList();
    expect(tables, hasLength(1));
    final rows = tables.single.tbody()!.children.whereType<TableRow>().toList();
    expect(rows, hasLength(2));
    expect(rows.every((row) => row.children.whereType<TableCell>().length == 3),
        isTrue);

    final firstBlock = tables.single.descendants<TableCellBlock>().first;
    final index = module.quill.scroll.offset(firstBlock);
    final context = module.getTable(Range(index, 0));
    expect(context.table, same(tables.single));
    expect(context.row, isNotNull);
    expect(context.cell, isNotNull);
  });

  test('prevents nested tables and deletes the active table', () {
    final module = createModule();
    module.quill.setSelection(const Range(0, 0));
    module.insertTable(2, 2);
    final table = module.quill.scroll.descendants<TableContainer>().single;
    final block = table.descendants<TableCellBlock>().first;
    final index = module.quill.scroll.offset(block);
    module.quill.setSelection(Range(index, 0));

    module.insertTable(3, 3);
    expect(module.quill.scroll.descendants<TableContainer>(), hasLength(1));
    module.deleteTable();
    expect(module.quill.scroll.descendants<TableContainer>(), isEmpty);
  });

  test('accepts language config maps like the TypeScript module', () {
    final options = TableBetterOptions.fromConfig({
      'language': {
        'name': 'custom',
        'content': {'copy': 'Copiar personalizado'}
      }
    });
    final language = options.language as dynamic;
    expect(language.name, 'custom');
    expect(language.content['copy'], 'Copiar personalizado');
  });

  test('registers the original table cell keyboard bindings', () {
    final module = createModule();
    final keyboard = module.quill.keyboard;
    for (final key in const ['ArrowUp', 'ArrowDown', 'Backspace', 'Delete']) {
      final bindings = keyboard.bindings[key] ?? const [];
      expect(
        bindings.any((binding) =>
            binding.format is List &&
                (binding.format as List).contains(TableCellBlock.kBlotName) ||
            binding.format is List &&
                (binding.format as List).contains(TableCell.kBlotName)),
        isTrue,
        reason: 'missing table-better binding for $key',
      );
    }
    expect(
      keyboard.bindings['Enter']!.any((binding) =>
          binding.format is List &&
          (binding.format as List).contains(TableHeader.kBlotName)),
      isTrue,
    );
    expect(
      keyboard.bindings['Enter']!.any((binding) =>
          binding.format is List &&
          (binding.format as List).contains(TableList.kBlotName)),
      isTrue,
    );
  });

  test('routes toolbar header format to all selected cells', () {
    final module = createModule(withToolbar: true);
    module.quill.setSelection(const Range(0, 0));
    module.insertTable(1, 2);
    final table = module.quill.scroll.descendants<TableContainer>().single;
    final selection = module.controllerFor(table).selection;
    selection.select(
      startRow: 0,
      startColumn: 0,
      endRow: 0,
      endColumn: 1,
    );

    final toolbar = module.quill.getModule('toolbar') as Toolbar;
    toolbar.handlers['header']!(2);
    final headers = table.descendants<TableHeader>().toList();
    expect(headers, hasLength(2));
    expect(
        headers.every((header) =>
            (header.formats()[TableHeader.kBlotName] as Map)['value'] == 2),
        isTrue);

    toolbar.handlers['list']!('bullet');
    final lists = table.descendants<TableList>().toList();
    expect(lists, hasLength(2), reason: table.element.innerHTML);
    expect(
        lists.every((list) => list.formats()[TableList.kBlotName] == 'bullet'),
        isTrue);
  });
}
