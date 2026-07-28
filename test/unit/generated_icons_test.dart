@TestOn('vm')
library;

import 'dart:io';

import 'package:test/test.dart';

import '../../tool/gen_icons.dart';
import '../../tool/svg_inline.dart';

/// Guards the generated icon files against drift.
///
/// The `.svg` files under `lib/assets/icons/` are the source of truth; the
/// Dart literals are produced by `tool/gen_icons.dart`. These tests re-run the
/// generation in memory and compare against what is on disk, so editing an
/// `icons.dart` by hand — or changing an SVG without re-running the generator —
/// fails here instead of silently diverging from upstream.
void main() {
  group('inlineSvg', () {
    test('collapses the whitespace between tags, as html-loader does', () {
      const source = '''
<svg viewbox="0 0 18 18">
  <line class="ql-stroke" x1="3" x2="15"></line>
</svg>
''';
      expect(
        inlineSvg(source),
        equals('<svg viewbox="0 0 18 18">'
            '<line class="ql-stroke" x1="3" x2="15"></line>'
            '</svg>'),
      );
    });

    test('drops the XML prolog and DOCTYPE, illegal in an HTML fragment', () {
      const source = '<?xml version="1.0" standalone="no"?>'
          '<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "x.dtd">'
          '<svg><path d="M0,0"/></svg>';
      expect(inlineSvg(source), equals('<svg><path d="M0,0"/></svg>'));
    });

    test('preserves text content and attribute values', () {
      const source = '<svg>\n  <text>0 x 0</text>\n</svg>';
      expect(inlineSvg(source), equals('<svg><text>0 x 0</text></svg>'));
    });

    test('camelCase matches the constant naming', () {
      expect(camelCase('align-left'), equals('alignLeft'));
      expect(camelCase('table-insert-rows'), equals('tableInsertRows'));
      expect(camelCase('bold'), equals('bold'));
    });
  });

  group('generated files are up to date', () {
    for (final generated in [generateQuillIcons(), generateTableBetterIcons()]) {
      test(generated.path, () {
        final file = File(generated.path);
        expect(file.existsSync(), isTrue,
            reason: '${generated.path} is missing — run '
                '`dart run tool/gen_icons.dart`');
        expect(
          file.readAsStringSync(),
          equals(generated.contents),
          reason: '${generated.path} drifted from the SVGs in '
              'lib/assets/icons/. Run `dart run tool/gen_icons.dart` and '
              'commit the result.',
        );
      });
    }
  });

  group('sources', () {
    test('the official Quill icon set is complete', () {
      final svgs = readSvgs('lib/assets/icons/svg_quill');
      expect(svgs.length, equals(72));
      // Spot-check that they are the upstream files, not a subset.
      for (final name in const ['bold', 'header-6', 'table-merge-cells']) {
        expect(svgs.containsKey(name), isTrue, reason: 'missing $name.svg');
      }
    });

    test('every embedded icon is byte-identical to its SVG source', () {
      final svgs = readSvgs('lib/assets/icons/svg_quill');
      final generated = File('lib/src/ui/icons.dart').readAsStringSync();
      for (final entry in svgs.entries) {
        if (!generated.contains('_${camelCase(entry.key)}Icon')) continue;
        expect(generated, contains(entry.value),
            reason: '${entry.key}.svg is not embedded verbatim');
      }
    });

    test('the table-better set matches the plugin assets', () {
      final ours = readSvgs('lib/assets/icons/svg_table_better');
      final upstream = readSvgs(
          'referencias/quill_table_better/1.2.3/src/src/assets/icon');
      expect(ours.keys.toSet(), equals(upstream.keys.toSet()));
      for (final key in ours.keys) {
        expect(ours[key], equals(upstream[key]),
            reason: '$key.svg differs from the plugin source');
      }
    });
  });

  group('icon map', () {
    test('the table buttons use real artwork, not placeholders', () {
      final generated = File('lib/src/ui/icons.dart').readAsStringSync();
      // These used to reuse the plain table / clean icons.
      expect(generated, contains("'table-row-above': _tableInsertRowsIcon"));
      expect(generated, contains("'table-delete-row': _tableDeleteRowsIcon"));
      expect(
          generated, contains("'table-delete-column': _tableDeleteColumnsIcon"));
    });

    test('every upstream format key is present', () {
      final generated = File('lib/src/ui/icons.dart').readAsStringSync();
      for (final key in const [
        'align',
        'background',
        'blockquote',
        'bold',
        'clean',
        'code',
        'code-block',
        'color',
        'direction',
        'formula',
        'header',
        'italic',
        'image',
        'indent',
        'link',
        'list',
        'script',
        'strike',
        'table',
        'underline',
        'video',
      ]) {
        expect(generated, contains("'$key':"), reason: 'missing key $key');
      }
    });
  });
}
