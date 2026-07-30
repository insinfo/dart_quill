import 'dart:math';

import 'package:dart_quill/src/dependencies/dart_quill_delta/dart_quill_delta.dart';
import 'package:dart_quill/src/modules/table_embed.dart';
import 'package:test/test.dart';

import '../support/quill_test_helpers.dart';

class _TableEmbedFuzzer {
  _TableEmbedFuzzer(this.seed) : random = Random(seed);

  final int seed;
  final Random random;

  int randomInt(int max) => max <= 0 ? 0 : random.nextInt(max);

  T choose<T>(List<T> choices) => choices[randomInt(choices.length)];

  String randomId() {
    const characters = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(
      8,
      (_) => characters[randomInt(characters.length)],
    ).join();
  }

  Map<String, dynamic> attachAttributes(Map<String, dynamic> object) {
    if (choose([true, false])) {
      final count = choose([1, 4, 8]);
      const names = ['align', 'background', 'color', 'font'];
      const values = ['center', 'red', 'left', 'uppercase'];
      final attributes = <String, dynamic>{};
      for (var i = 0; i < count; i += 1) {
        attributes[choose(names)] = choose(values);
      }
      object['attributes'] = attributes;
    }
    return object;
  }

  List<Map<String, dynamic>> randomCellContent() {
    final delta = Delta();
    for (var i = 0; i < choose([1, 2, 3]); i += 1) {
      final text = List.generate(
        randomInt(10) + 1,
        (_) => choose(['a', 'b', 'c', 'c', 'e', 'f', 'g']),
      ).join();
      delta.push(Operation.fromJson(attachAttributes({'insert': text})));
    }
    return delta.toJson();
  }

  List<Map<String, dynamic>> randomRowColumnInsert(int count) => List.generate(
        count,
        (_) => attachAttributes({
          'insert': {'id': randomId()},
        }),
      );

  Delta randomBase() {
    final rowCount = choose([0, 1, 2, 3]);
    final columnCount = choose([0, 1, 2]);
    final cellCount = choose([0, 1, 2, 3, 4, 5]);
    final table = <String, dynamic>{};
    if (rowCount > 0) table['rows'] = randomRowColumnInsert(rowCount);
    if (columnCount > 0) {
      table['columns'] = randomRowColumnInsert(columnCount);
    }
    if (cellCount > 0) {
      final cells = <String, dynamic>{};
      for (var i = 0; i < cellCount; i += 1) {
        final identity =
            '${randomInt(rowCount) + 1}:${randomInt(columnCount) + 1}';
        final cell = attachAttributes(<String, dynamic>{});
        if (choose([true, false])) cell['content'] = randomCellContent();
        if (cell.isNotEmpty) cells[identity] = cell;
      }
      if (cells.isNotEmpty) table['cells'] = cells;
    }
    return Delta()
      ..insert({
        'table-embed': table,
      });
  }

  Delta randomChange(Delta base) {
    final table = <String, dynamic>{};
    final baseData = (base.operations.first.data! as Map)['table-embed'] as Map;
    final dimensions = {
      'rows': Delta.fromJson((baseData['rows'] as List?) ?? const []).length,
      'columns':
          Delta.fromJson((baseData['columns'] as List?) ?? const []).length,
    };

    for (final field in ['rows', 'columns']) {
      final baseLength = dimensions[field]!;
      final delta = Delta();
      switch (choose(['insert', 'delete', 'retain'])) {
        case 'insert':
          delta.retain(randomInt(baseLength + 1));
          delta.push(
            Operation.fromJson(
              attachAttributes({
                'insert': {'id': randomId()},
              }),
            ),
          );
        case 'delete':
          if (baseLength >= 1) {
            delta.retain(randomInt(baseLength));
            delta.delete(1);
          }
        case 'retain':
          if (baseLength >= 1) {
            delta.retain(randomInt(baseLength));
            delta.push(
              Operation.fromJson(attachAttributes({'retain': 1})),
            );
          }
      }
      if (delta.isNotEmpty) table[field] = delta.toJson();
    }

    for (var i = 0; i < choose([0, 1, 2, 3]); i += 1) {
      final identity = '${randomInt(dimensions['rows']!) + 1}:'
          '${randomInt(dimensions['columns']!) + 1}';
      // This assignment is intentionally identical to the upstream spec:
      // every generated update replaces the previous `cells` map.
      table['cells'] = {
        identity: attachAttributes({
          'content': randomCellContent(),
        }),
      };
    }

    return Delta()
      ..retain(1, {
        'table-embed': table,
      });
  }
}

void main() {
  setUpAll(() {
    TableEmbed.register();
  });

  tearDownAll(() {
    TableEmbed.unregister();
  });

  group('tableEmbed', () {
    test('delta', () {
      const seed = 0x7ab1e;
      final fuzzer = _TableEmbedFuzzer(seed);
      for (var i = 0; i < 20; i += 1) {
        for (var j = 0; j < 1000; j += 1) {
          printOnFailure('fuzz seed=$seed outer=$i inner=$j');
          final base = fuzzer.randomBase();
          final change = fuzzer.randomChange(base);
          expectDelta(
            base.compose(change).compose(change.invert(base)),
            base,
          );

          final anotherChange = fuzzer.randomChange(base);
          expectDelta(
            change.compose(change.transform(anotherChange, true)),
            anotherChange.compose(anotherChange.transform(change, false)),
          );
        }
      }
    });
  });
}
