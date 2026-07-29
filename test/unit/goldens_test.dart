@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:dart_quill/src/core/quill.dart';
import 'package:dart_quill/src/dependencies/dart_quill_delta/dart_quill_delta.dart';
import 'package:test/test.dart';

import '../support/quill_test_helpers.dart';

/// Delta compatibility with the real Quill, proved rather than argued.
///
/// `tool/gen_goldens.dart` runs every case in `test/goldens/cases.json` against
/// quill 2.0.3 in a headless Chrome and records the resulting Delta. This test
/// replays the same cases against the port and diffs op by op. A document
/// written by upstream Quill must load here unchanged, and a document written
/// here must mean the same thing there — anything else is a compatibility bug,
/// no matter how reasonable the port's own behaviour looks in isolation.
///
/// A failure is never fixed by editing the golden. Either the port is wrong, or
/// the divergence is deliberate and belongs in [_knownDivergences] with a
/// reason and a plan item.
void main() {
  final cases = (jsonDecode(File('test/goldens/cases.json').readAsStringSync())
      as Map<String, dynamic>)['cases'] as List<dynamic>;
  final goldenFile = File('test/goldens/quill_2.0.3.json');

  setUpAll(ensureQuillTestInitialized);

  test('the goldens were recorded against the version being ported', () {
    expect(goldenFile.existsSync(), isTrue,
        reason: 'run `dart run tool/gen_goldens.dart`');
    final golden =
        jsonDecode(goldenFile.readAsStringSync()) as Map<String, dynamic>;
    expect(golden['quill'], equals('2.0.3'));
    expect((golden['results'] as List).length, equals(cases.length),
        reason: 'cases.json changed without re-running the generator');
  });

  final golden =
      jsonDecode(goldenFile.readAsStringSync()) as Map<String, dynamic>;
  final results = golden['results'] as List<dynamic>;

  for (var i = 0; i < cases.length; i++) {
    final testCase = cases[i] as Map<String, dynamic>;
    final expected = results[i] as Map<String, dynamic>;
    final name = testCase['name'] as String;
    final group = testCase['group'] as String;
    final divergence = _knownDivergences['$group / $name'];

    test('$group / $name', () {
      expect(expected['error'], isNull,
          reason: 'upstream itself failed on this case; fix cases.json');
      expect(expected['name'], equals(name),
          reason: 'cases.json and the golden are out of sync');

      final quill = createTestQuill();
      _applySetup(quill, testCase['setup'] as Map<String, dynamic>? ?? const {});
      for (final action in (testCase['actions'] as List<dynamic>? ?? const [])) {
        _applyAction(quill, action as Map<String, dynamic>);
      }

      expect(
        _normalise(quill.getContents().toJson()),
        equals(_normalise(expected['contents'])),
        reason: 'the Delta differs from what quill 2.0.3 produces',
      );
      expect(quill.getText(), equals(expected['text']));
    }, skip: divergence);
  }
}

/// Cases the port knowingly answers differently, each with the root cause found
/// by running it. Empty is the goal; every entry is a compatibility debt, and
/// the ones below are grouped by the three defects behind them.
///
/// These are not "acceptable differences". A document written by upstream Quill
/// and loaded here — or the reverse — loses information in every one of them.
const Map<String, String> _knownDivergences = {
  // ---- empty-block normalisation around the end of the document ----------
  // The port drops one trailing empty line where upstream keeps it, and adds a
  // paragraph around a block embed where upstream has none. Same underlying
  // question: how the scroll represents the last block. Fix in Editor/Scroll
  // normalisation, then delete these four entries.
  'setContents normalisation / trailing newlines are kept except the last':
      'the port renders `a\\n\\n\\n` as two lines, upstream as three — a '
          'trailing empty paragraph is dropped',
  'setContents normalisation / block embed at the end without a preceding newline':
      'the port appends an empty paragraph after a trailing block embed',
  'setContents normalisation / block embed at the start':
      'the port prepends an empty paragraph before a leading block embed',
  'setContents normalisation / block embed with an attribute':
      'same leading-paragraph defect, with the embed attribute along for the '
          'ride',
  'editing / insertEmbed of a block embed':
      'same trailing-paragraph defect, reached through insertEmbed',

  // ---- code-block carries a language upstream, a boolean here ------------
  // quill.js registers modules/syntax, whose SyntaxCodeBlock.formats() reads
  // `data-language` defaulting to "plain"; the port only installs that when the
  // syntax module is switched on, so its default code-block reports `true`.
  // Every code block written by a standard Quill loses its language here.
  'block formats / blockquote and code block':
      'code-block is `true` here, `"plain"` upstream — the language is lost',
  'html to delta / preformatted block':
      'same: <pre> converts to code-block `true` instead of `"plain"`',

  // ---- list model (tracked as G5.2) --------------------------------------
  'block formats / checked and unchecked list items':
      'checked/unchecked collapse to `ordered`: the port keeps the list type on '
          'the container + OL/UL tag instead of `data-list` on the <li> (G5.2)',
};

void _applySetup(Quill quill, Map<String, dynamic> setup) {
  final html = setup['html'];
  if (html is String) {
    quill.setContents(quill.clipboard.convert(html: html));
    return;
  }
  quill.setContents(_delta(setup['delta'] as List<dynamic>? ?? const []));
}

void _applyAction(Quill quill, Map<String, dynamic> action) {
  final method = action['method'] as String;
  final args = action['args'] as List<dynamic>? ?? const [];
  switch (method) {
    case 'insertText':
      quill.insertText(
        args[0] as int,
        args[1] as String,
        formats: args.length > 2
            ? Map<String, dynamic>.from(args[2] as Map)
            : null,
      );
    case 'deleteText':
      quill.deleteText(args[0] as int, args[1] as int);
    case 'formatText':
      quill.formatText(
          args[0] as int, args[1] as int, args[2] as String, args[3]);
    case 'formatLine':
      quill.formatLine(
          args[0] as int, args[1] as int, args[2] as String, args[3]);
    case 'removeFormat':
      quill.removeFormat(args[0] as int, args[1] as int);
    case 'insertEmbed':
      quill.insertEmbed(args[0] as int, args[1] as String, args[2]);
    case 'updateContents':
      quill.updateContents(_delta(args[0] as List<dynamic>));
    default:
      throw UnsupportedError('unknown action "$method" — teach _applyAction');
  }
}

Delta _delta(List<dynamic> ops) => Delta.fromJson(ops);

/// Drops the differences that are encoding, not meaning.
///
/// `quill-delta` omits an empty `attributes` map; the Dart port may carry one.
/// Nothing else is smoothed over — in particular attribute *values* are
/// compared as recorded, so `1` and `"1"` are a failure, not a nuance.
Object? _normalise(Object? value) {
  if (value is List) return value.map(_normalise).toList();
  if (value is Map) {
    final out = <String, Object?>{};
    for (final entry in value.entries) {
      final key = '${entry.key}';
      final normalised = _normalise(entry.value);
      if (key == 'attributes' && normalised is Map && normalised.isEmpty) {
        continue;
      }
      out[key] = normalised;
    }
    return out;
  }
  return value;
}
