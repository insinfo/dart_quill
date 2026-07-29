/// Generates the embedded icon files from the `.svg` sources in `lib/assets/icons/`.
///
/// Counterpart of the Quill build step: upstream `icons.ts` declares
/// `import boldIcon from '../assets/icons/bold.svg'` and
/// `scripts/babel-svg-inline-import.cjs` replaces the import with the file's
/// contents. Nothing is pasted by hand there and nothing is here either — the
/// `.svg` files are the source of truth, and this script writes:
///
///   lib/assets/icons/svg_quill/*.svg        → lib/src/ui/icons.dart
///   lib/assets/icons/svg_table_better/*.svg → lib/src/table_better/assets/icons.dart
///
/// Run with:
///
///     dart run tool/gen_icons.dart
///
/// `test/unit/generated_icons_test.dart` re-runs the generation in memory and
/// fails if either file drifts from its sources.
library;

import 'dart:io';

import 'svg_inline.dart';

void main(List<String> args) {
  final check = args.contains('--check');
  var drifted = false;

  for (final entry in [generateQuillIcons(), generateTableBetterIcons()]) {
    final file = File(entry.path);
    final current = file.existsSync() ? file.readAsStringSync() : null;
    if (current == entry.contents) {
      stdout.writeln('unchanged  ${entry.path}  (${entry.count} icons)');
      continue;
    }
    if (check) {
      stderr.writeln('DRIFT      ${entry.path}');
      drifted = true;
      continue;
    }
    file.writeAsStringSync(entry.contents);
    stdout.writeln('written    ${entry.path}  (${entry.count} icons)');
  }

  if (drifted) {
    stderr.writeln('\nRun `dart run tool/gen_icons.dart` and commit the result.');
    exitCode = 1;
  }
}

/// One generated file.
class GeneratedFile {
  const GeneratedFile({
    required this.path,
    required this.contents,
    required this.count,
  });

  final String path;
  final String contents;
  final int count;
}

/// Reads every `.svg` of [directory], sorted, as `{fileNameWithoutExtension:
/// inlinedSource}`.
Map<String, String> readSvgs(String directory) {
  final dir = Directory(directory);
  if (!dir.existsSync()) {
    throw StateError('Missing SVG source directory: $directory');
  }
  final files = dir
      .listSync()
      .whereType<File>()
      .where((file) => file.path.endsWith('.svg'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  return {
    for (final file in files)
      file.uri.pathSegments.last.replaceAll('.svg', ''):
          inlineSvg(file.readAsStringSync()),
  };
}

// --- lib/src/ui/icons.dart -------------------------------------------------

/// Format name → icon file, mirroring the default export of upstream
/// `src/ui/icons.ts`.
///
/// A value is either a file name or a `{formatValue: fileName}` map, exactly
/// like the nested objects upstream uses for align/direction/header/…
const Map<String, Object> _quillIconMap = {
  'align': {
    '': 'align-left',
    'center': 'align-center',
    'right': 'align-right',
    'justify': 'align-justify',
  },
  'background': 'background',
  'blockquote': 'blockquote',
  'bold': 'bold',
  'clean': 'clean',
  'code': 'code',
  'code-block': 'code',
  'color': 'color',
  'direction': {
    '': 'direction-ltr',
    'rtl': 'direction-rtl',
  },
  'formula': 'formula',
  'header': {
    '1': 'header',
    '2': 'header-2',
    '3': 'header-3',
    '4': 'header-4',
    '5': 'header-5',
    '6': 'header-6',
  },
  'italic': 'italic',
  'image': 'image',
  'indent': {
    '+1': 'indent',
    '-1': 'outdent',
  },
  'link': 'link',
  'list': {
    'bullet': 'list-bullet',
    'check': 'list-check',
    'ordered': 'list-ordered',
  },
  'script': {
    'sub': 'subscript',
    'super': 'superscript',
  },
  'strike': 'strike',
  'table': 'table',
  'underline': 'underline',
  'video': 'video',
};

/// Toolbar formats this port adds on top of upstream's map, for the basic
/// `table` module's buttons. Upstream has no equivalent, but the official SVG
/// set does ship the artwork — these used to be placeholders reusing the plain
/// table and clean icons.
const Map<String, String> _quillExtraIconMap = {
  'table-row-above': 'table-insert-rows',
  'table-row-below': 'table-insert-rows',
  'table-column-left': 'table-insert-columns',
  'table-column-right': 'table-insert-columns',
  'table-delete-row': 'table-delete-rows',
  'table-delete-column': 'table-delete-columns',
  'table-delete': 'table-delete-cells',
  'table-merge': 'table-merge-cells',
  'table-split': 'table-unmerge-cells',
};

GeneratedFile generateQuillIcons() {
  const source = 'lib/assets/icons/svg_quill';
  final svgs = readSvgs(source);

  // Only the files the map actually references become constants, so the
  // unused two thirds of the official set do not enter the JS bundle.
  final used = <String>{};
  void collect(Object? value) {
    if (value is String) {
      used.add(value);
    } else if (value is Map) {
      for (final child in value.values) {
        collect(child);
      }
    }
  }

  _quillIconMap.values.forEach(collect);
  _quillExtraIconMap.values.forEach(collect);

  final missing = used.where((name) => !svgs.containsKey(name)).toList()..sort();
  if (missing.isNotEmpty) {
    throw StateError('Missing SVGs in $source: ${missing.join(', ')}');
  }

  final buffer = StringBuffer()
    ..write(generatedHeader)
    ..writeln()
    ..writeln('library;')
    ..writeln();

  for (final name in used.toList()..sort()) {
    buffer
      ..writeln('const String _${camelCase(name)}Icon =')
      ..writeln('    ${dartRawString(svgs[name]!)};')
      ..writeln();
  }

  buffer
    ..writeln('/// Icon registry, keyed by format name'
        ' (`Quill.import(\'ui/icons\')` upstream).')
    ..writeln('///')
    ..writeln('/// Mutable on purpose: modules register their own icons at'
        ' runtime — the')
    ..writeln('/// table-better toolbar button does'
        " `icons['table-better'] = tableIcon`")
    ..writeln('/// (toolbar-table.ts:8-10).')
    ..writeln('final Map<String, dynamic> icons ='
        ' Map<String, dynamic>.from(defaultIcons);')
    ..writeln()
    ..writeln('/// The built-in set, before any module adds to it.')
    ..writeln('const Map<String, dynamic> defaultIcons = {');

  void writeEntry(String key, Object value, String indent) {
    if (value is String) {
      buffer.writeln("$indent'$key': _${camelCase(value)}Icon,");
      return;
    }
    buffer.writeln("$indent'$key': {");
    (value as Map).forEach((childKey, childValue) {
      writeEntry('$childKey', childValue as Object, '$indent  ');
    });
    buffer.writeln('$indent},');
  }

  _quillIconMap.forEach((key, value) => writeEntry(key, value, '  '));
  buffer.writeln('  // Buttons of the basic `table` module (not in upstream).');
  _quillExtraIconMap.forEach((key, value) => writeEntry(key, value, '  '));
  buffer.writeln('};');

  return GeneratedFile(
    path: 'lib/src/ui/icons.dart',
    contents: buffer.toString(),
    count: used.length,
  );
}

// --- lib/src/table_better/assets/icons.dart --------------------------------

GeneratedFile generateTableBetterIcons() {
  const source = 'lib/assets/icons/svg_table_better';
  final svgs = readSvgs(source);

  final buffer = StringBuffer()
    ..write(generatedHeader)
    ..writeln()
    ..writeln('/// SVG assets of `quill-table-better`'
        ' (`src/assets/icon/*.svg`), inlined so')
    ..writeln('/// the package keeps its single runtime dependency.')
    ..writeln('library;')
    ..writeln();

  for (final name in svgs.keys) {
    buffer
      ..writeln('const String _${camelCase(name)}Icon =')
      ..writeln('    ${dartRawString(svgs[name]!)};')
      ..writeln();
  }

  buffer
    ..writeln('/// Icon name (matching the upstream file name) to inline SVG'
        ' markup.')
    ..writeln('const Map<String, String> tableBetterIcons = <String, String>{');
  for (final name in svgs.keys) {
    buffer.writeln("  '$name': _${camelCase(name)}Icon,");
  }
  buffer.writeln('};');

  return GeneratedFile(
    path: 'lib/src/table_better/assets/icons.dart',
    contents: buffer.toString(),
    count: svgs.length,
  );
}
