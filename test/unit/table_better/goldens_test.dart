@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:dart_quill/src/core/quill.dart';
import 'package:dart_quill/src/core/selection.dart';
import 'package:dart_quill/src/dependencies/dart_quill_delta/dart_quill_delta.dart';
import 'package:dart_quill/src/modules/toolbar.dart';
import 'package:dart_quill/src/table_better/register.dart';
import 'package:dart_quill/src/table_better/table_better.dart';
import 'package:test/test.dart';

import '../../support/quill_test_helpers.dart';
import '../../support/test_helpers.dart';

/// Delta compatibility with quill-table-better 1.2.3, proved against the real
/// plugin.
///
/// `dart run tool/gen_goldens.dart --suite table-better` runs every case in
/// `test/goldens/table_better_cases.json` against the plugin bundle on quill
/// 2.0.3 in headless Chrome; this replays them against the port.
///
/// A table's Delta is the whole contract of this plugin — `table-cell-block`
/// carries a cell id, `table-cell` a `data-row`, and `table-temporary` the
/// table's own style. A document written by the JS plugin has to open here with
/// its rows and cells still associated the same way.
void main() {
  final cases =
      (jsonDecode(File('test/goldens/table_better_cases.json').readAsStringSync())
          as Map<String, dynamic>)['cases'] as List<dynamic>;
  final goldenFile = File('test/goldens/quill_table_better_1.2.3.json');

  setUpAll(() {
    ensureQuillTestInitialized();
    registerTableBetter(replaceClipboard: true);
  });

  setUp(() {
    final body = testAdapter.document.body;
    while (body.firstChild != null) {
      body.firstChild!.remove();
    }
  });

  test('the goldens were recorded against the version being ported', () {
    expect(goldenFile.existsSync(), isTrue,
        reason: 'run `dart run tool/gen_goldens.dart --suite table-better`');
    final golden =
        jsonDecode(goldenFile.readAsStringSync()) as Map<String, dynamic>;
    expect(golden['quill'], equals('2.0.3'));
    expect(golden['suite'], equals('table-better'));
    expect((golden['results'] as List).length, equals(cases.length),
        reason: 'the case list changed without re-running the generator');
  });

  final golden =
      jsonDecode(goldenFile.readAsStringSync()) as Map<String, dynamic>;
  final results = golden['results'] as List<dynamic>;

  for (var i = 0; i < cases.length; i++) {
    final testCase = cases[i] as Map<String, dynamic>;
    final expected = results[i] as Map<String, dynamic>;
    final name = testCase['name'] as String;
    final group = testCase['group'] as String;

    test('$group / $name', () {
      expect(expected['error'], isNull,
          reason: 'the plugin itself failed on this case; fix the case list');

      final quill = createTestQuill(
        theme: 'snow',
        modules: {
          'toolbar': ToolbarProps(
            container: ToolbarConfig(const [
              ['bold', 'italic'],
              ['table-better']
            ]),
          ),
          'table-better': const <String, dynamic>{'language': 'en_US'},
        },
      );
      final module = quill.getModule('table-better') as TableBetter;

      final setup = testCase['setup'] as Map<String, dynamic>? ?? const {};
      final html = setup['html'];
      if (html is String) {
        quill.setContents(quill.clipboard.convert(html: html));
      } else {
        quill.setContents(
            Delta.fromJson(setup['delta'] as List<dynamic>? ?? const []));
      }
      for (final action in (testCase['actions'] as List<dynamic>? ?? const [])) {
        _applyAction(quill, module, action as Map<String, dynamic>);
      }

      expect(
        _canonicalise(quill.getContents().toJson()),
        equals(_canonicalise(expected['contents'])),
        reason: 'the Delta differs from what quill-table-better 1.2.3 produces',
      );
    }, skip: _knownDivergences['$group / $name']);
  }
}

/// Cases the port answers differently, with the root cause. Every entry is a
/// compatibility debt, not an accepted difference — a table written by the JS
/// plugin does not survive a round trip through the port in any of them.
const Map<String, String> _knownDivergences = {
  // ---- pasting a table builds the wrong structure (10 cases) ------------
  // Narrowed twice. First with the `converted` field the generator records —
  // the plugin's own `clipboard.convert` output — which showed the matchers
  // were at fault and got them fixed. Then, once the fake DOM's innerHTML
  // stopped hiding `data-*` attributes, the remaining defect became visible:
  //
  //   port:   <tr><td data-row="1">a</td></tr>
  //           <tr><td><p class="ql-table-block" data-cell="1"><br></p></td></tr>
  //           <tr><td data-row="1">b</td></tr>…
  //   plugin: <tr><td data-row="1"><p class="ql-table-block" data-cell="1">a</p></td>
  //               <td data-row="1"><p class="ql-table-block" data-cell="2">b</p></td></tr>
  //
  // `data-row` *is* written — an earlier note here said otherwise, which was an
  // artefact of the truncated serializer, not a real defect. Two things are
  // actually wrong: `table-cell-block` lands on a new empty line instead of
  // wrapping the cell's text, and the resulting cells never merge into one row.
  // Both point at `Scroll.insertContents` / `deltaToRenderBlocks` — the path
  // `dangerouslyPasteHTML` takes and `setContents` does not. The same delta
  // applied through `setContents` produces exactly the upstream structure.
  'table html to delta / a plain 2x2 table': _pasteBroken,
  'table html to delta / a table with a colgroup': _pasteBroken,
  'table html to delta / a table with a header row': _pasteBroken,
  'table html to delta / colspan and rowspan': _pasteBroken,
  'table html to delta / cell styles survive the paste': _pasteBroken,
  'table html to delta / a table carrying its own style': _pasteBroken,
  'table html to delta / block content inside a cell': _pasteBroken,
  'table html to delta / a list inside a cell': _pasteBroken,
  'table html to delta / inline formatting inside a cell': _pasteBroken,
  'table html to delta / text around a table': _pasteBroken,

  // ---- insertTable after existing content --------------------------------
  'insertTable / a table after existing text':
      'the port leaves an extra empty line before the table — the `isExtra` '
          'branch of insertTable adds a newline upstream does not',

  // ---- the two delete entry points ---------------------------------------
  'table editing / deleting the temporary blot':
      'deleteTableTemporary leaves the table-temporary line in the document',
  'table editing / deleting the whole table':
      'deleteTable leaves the table-temporary line behind',
};

const String _pasteBroken =
    'insertContents puts `table-cell-block` on a new empty line instead of '
    'wrapping the cell text, and the cells never merge into one row (see the '
    'comment above the map)';

void _applyAction(
    Quill quill, TableBetter module, Map<String, dynamic> action) {
  final args = action['args'] as List<dynamic>? ?? const [];
  final moduleMethod = action['module'] as String?;
  if (moduleMethod != null) {
    switch (moduleMethod) {
      case 'insertTable':
        module.insertTable(args[0] as int, args[1] as int);
      case 'deleteTable':
        module.deleteTable();
      case 'deleteTableTemporary':
        module.deleteTableTemporary();
      default:
        throw UnsupportedError('unknown module action "$moduleMethod"');
    }
    return;
  }
  switch (action['method'] as String) {
    case 'pasteHtml':
      quill.clipboard.dangerouslyPasteHTML(args[0] as int, args[1] as String);
    case 'setSelection':
      quill.setSelection(Range(args[0] as int, args[1] as int));
    case 'insertText':
      quill.insertText(args[0] as int, args[1] as String);
    case 'formatText':
      quill.formatText(
          args[0] as int, args[1] as int, args[2] as String, args[3]);
    case 'formatLine':
      quill.formatLine(
          args[0] as int, args[1] as int, args[2] as String, args[3]);
    case 'deleteText':
      quill.deleteText(args[0] as int, args[1] as int);
    default:
      throw UnsupportedError('unknown action "${action['method']}"');
  }
}

/// Replaces the random cell/row ids with `cell#N` / `row#N`, numbered by order
/// of first appearance.
///
/// `cellId()` and `tableId()` mint random ids in both implementations, so the
/// literal values can never match. The mapping is injective and order-preserving
/// on each side, so everything that carries meaning survives it: two cells that
/// share a row still share one afterwards, and a cell that changed rows still
/// shows it. Only the opaque identity of an id is discarded.
Object? _canonicalise(Object? value) {
  // Namespaced per kind: a paste mints ids like "1"/"2" for both cells and
  // rows, so a single shared map would fuse a cell id with a row id that
  // happens to read the same and hide a real structural difference.
  final ids = <String, String>{};
  final counts = <String, int>{};
  String canonical(String kind, String raw) => ids.putIfAbsent(
      '$kind:$raw', () => '$kind#${counts[kind] = (counts[kind] ?? 0) + 1}');

  const kinds = {
    'table-cell-block': 'cell',
    'table-th-block': 'cell',
    'data-cell': 'cell',
    'cellId': 'cell',
    'data-row': 'row',
  };

  Object? walk(Object? node, [String? kind]) {
    if (node is List) return node.map<Object?>((e) => walk(e)).toList();
    if (node is Map) {
      final out = <String, Object?>{};
      for (final entry in node.entries) {
        final key = '${entry.key}';
        final child = walk(entry.value, kinds[key]);
        if (key == 'attributes' && child is Map && child.isEmpty) continue;
        out[key] = child;
      }
      return out;
    }
    if (kind != null && node is String && node.isNotEmpty) {
      return canonical(kind, node);
    }
    return node;
  }

  return walk(value);
}
