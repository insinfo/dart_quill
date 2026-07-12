import 'package:dart_quill/src/core/selection.dart';
import 'package:dart_quill/src/table_better/formats/table.dart';
import 'package:dart_quill/src/table_better/register.dart';
import 'package:dart_quill/src/table_better/table_better.dart';
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

  TableBetter createModule() {
    final quill = createTestQuill(modules: {
      'table-better': const <String, dynamic>{},
    });
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
  });
}
