import 'package:dart_quill/src/blots/abstract/blot.dart';
import 'package:dart_quill/src/core/emitter.dart';
import 'package:dart_quill/src/core/quill.dart';
import 'package:dart_quill/src/core/theme.dart';
import 'package:dart_quill/src/delta/delta.dart';
import 'package:dart_quill/src/formats/bold.dart';
import 'package:dart_quill/src/modules/syntax.dart';
import 'package:test/test.dart';

import '../../support/quill_test_helpers.dart';
import '../../support/test_helpers.dart';

/// Port of `referencias/quilljs/test/unit/modules/syntax.spec.ts`.
const _highlightInterval = Duration(milliseconds: 10);

Delta _highlighter(String text, String language) {
  final result = Delta();
  final normalized =
      const {'javascript', 'ruby'}.contains(language) ? language : 'plain';
  final body = text.endsWith('\n') ? text.substring(0, text.length - 1) : text;
  for (final line in body.split('\n')) {
    var index = 0;
    final tokenPattern = normalized == 'javascript'
        ? RegExp(r'\bvar\b|\b\d+\b')
        : normalized == 'ruby'
            ? RegExp(r'\b\d+\b')
            : RegExp(r'(?!x)x');
    for (final match in tokenPattern.allMatches(line)) {
      if (match.start > index) {
        result.insert(line.substring(index, match.start));
      }
      final token = match.group(0)!;
      result.insert(token, {
        'code-token': RegExp(r'^\d+$').hasMatch(token) ? 'number' : 'keyword',
      });
      index = match.end;
    }
    if (index < line.length) result.insert(line.substring(index));
    result.insert('\n', {'code-block': normalized});
  }
  return result;
}

Quill _createQuill() => createEditorQuill(
      '<pre data-language="javascript">var test = 1;<br>'
      'var bugz = 0;<br></pre><p><br></p>',
      options: ThemeOptions(modules: {
        'syntax': SyntaxOptions(
          interval: _highlightInterval,
          languages: const [
            SyntaxLanguage(key: 'javascript', label: 'JavaScript'),
            SyntaxLanguage(key: 'ruby', label: 'Ruby'),
          ],
          highlighter: _highlighter,
        ),
      }),
    );

Future<void> _waitForHighlight(Quill quill) {
  // The upstream environment supplies this through MutationObserver. The VM
  // fake DOM has no observer, so inject the same platform event and let the
  // real Syntax timer/listener do the rest.
  quill.emitter.emit(EmitterEvents.SCROLL_OPTIMIZE, const [], const {});
  return Future<void>.delayed(
      _highlightInterval + const Duration(milliseconds: 5));
}

Delta _initialDelta() => Delta()
  ..insert('var test = 1;')
  ..insert('\n', {'code-block': 'javascript'})
  ..insert('var bugz = 0;')
  ..insert('\n', {'code-block': 'javascript'})
  ..insert('\n');

void main() {
  setUpAll(ensureQuillTestInitialized);

  setUp(() {
    final body = testAdapter.document.body;
    while (body.firstChild != null) {
      body.firstChild!.remove();
    }
  });

  group('Syntax', () {
    group('highlighting', () {
      test('initialize', () {
        final quill = _createQuill();
        expect(
          quill.root,
          EqualHTML('''
            <div class="ql-code-block-container" spellcheck="false">
              <div class="ql-code-block" data-language="javascript">var test = 1;</div>
              <div class="ql-code-block" data-language="javascript">var bugz = 0;</div>
            </div>
            <p><br></p>
          '''),
        );
        expectDelta(quill.getContents(), _initialDelta());
      });

      test('adds token', () async {
        final quill = _createQuill();
        await _waitForHighlight(quill);
        expect(
          quill.root,
          EqualHTML('''
            <div class="ql-code-block-container" spellcheck="false">
              <div class="ql-code-block" data-language="javascript">
                <span class="ql-token hljs-keyword">var</span> test = <span class="ql-token hljs-number">1</span>;
              </div>
              <div class="ql-code-block" data-language="javascript">
                <span class="ql-token hljs-keyword">var</span> bugz = <span class="ql-token hljs-number">0</span>;
              </div>
            </div><p><br></p>
          '''),
        );
        expectDelta(quill.getContents(), _initialDelta());
      });

      test('tokens do not escape', () async {
        final quill = _createQuill();
        quill.deleteText(22, 6);
        await _waitForHighlight(quill);
        expect(
          quill.root,
          EqualHTML('''
            <div class="ql-code-block-container" spellcheck="false">
              <div class="ql-code-block" data-language="javascript">
                <span class="ql-token hljs-keyword">var</span> test = <span class="ql-token hljs-number">1</span>;
              </div>
            </div>
            <p>var bugz</p>
          '''),
        );
        expectDelta(
          quill.getContents(),
          Delta()
            ..insert('var test = 1;')
            ..insert('\n', {'code-block': 'javascript'})
            ..insert('var bugz\n'),
        );
      });

      test('change language', () async {
        final quill = _createQuill();
        quill.formatLine(0, 20, 'code-block', 'ruby');
        await _waitForHighlight(quill);
        expect(
          quill.root,
          EqualHTML('''
            <div class="ql-code-block-container" spellcheck="false">
              <div class="ql-code-block" data-language="ruby">var test = <span class="ql-token hljs-number">1</span>;</div>
              <div class="ql-code-block" data-language="ruby">var bugz = <span class="ql-token hljs-number">0</span>;</div>
            </div><p><br></p>
          '''),
        );
        expectDelta(
          quill.getContents(),
          Delta()
            ..insert('var test = 1;')
            ..insert('\n', {'code-block': 'ruby'})
            ..insert('var bugz = 0;')
            ..insert('\n', {'code-block': 'ruby'})
            ..insert('\n'),
        );
      });

      test('invalid language', () async {
        final quill = _createQuill();
        quill.formatLine(0, 20, 'code-block', 'invalid');
        await _waitForHighlight(quill);
        expect(
          quill.root,
          EqualHTML('''
            <div class="ql-code-block-container" spellcheck="false">
              <div class="ql-code-block" data-language="plain">var test = 1;</div>
              <div class="ql-code-block" data-language="plain">var bugz = 0;</div>
            </div><p><br></p>
          '''),
        );
        expectDelta(
          quill.getContents(),
          Delta()
            ..insert('var test = 1;')
            ..insert('\n', {'code-block': 'plain'})
            ..insert('var bugz = 0;')
            ..insert('\n', {'code-block': 'plain'})
            ..insert('\n'),
        );
      });

      test('unformat first line', () async {
        final quill = _createQuill();
        quill.formatLine(0, 1, 'code-block', false);
        await _waitForHighlight(quill);
        expect(
          quill.root,
          EqualHTML('''
            <p>var test = 1;</p>
            <div class="ql-code-block-container" spellcheck="false">
              <div class="ql-code-block" data-language="javascript">
                <span class="ql-token hljs-keyword">var</span> bugz = <span class="ql-token hljs-number">0</span>;
              </div>
            </div><p><br></p>
          '''),
        );
        expectDelta(
          quill.getContents(),
          Delta()
            ..insert('var test = 1;\nvar bugz = 0;')
            ..insert('\n', {'code-block': 'javascript'})
            ..insert('\n'),
        );
      });

      test('split container', () async {
        final quill = _createQuill();
        quill.updateContents(Delta()
          ..retain(14)
          ..insert('\n'));
        await _waitForHighlight(quill);
        expect(
          quill.root,
          EqualHTML('''
            <div class="ql-code-block-container" spellcheck="false">
              <div class="ql-code-block" data-language="javascript">
                <span class="ql-token hljs-keyword">var</span> test = <span class="ql-token hljs-number">1</span>;
              </div>
            </div>
            <p><br></p>
            <div class="ql-code-block-container" spellcheck="false">
              <div class="ql-code-block" data-language="javascript">
                <span class="ql-token hljs-keyword">var</span> bugz = <span class="ql-token hljs-number">0</span>;
              </div>
            </div><p><br></p>
          '''),
        );
        expectDelta(
          quill.getContents(),
          Delta()
            ..insert('var test = 1;')
            ..insert('\n', {'code-block': 'javascript'})
            ..insert('\nvar bugz = 0;')
            ..insert('\n', {'code-block': 'javascript'})
            ..insert('\n'),
        );
      });

      test('merge containers', () async {
        final quill = _createQuill();
        quill.updateContents(Delta()
          ..retain(14)
          ..insert('\n'));
        await _waitForHighlight(quill);
        quill.deleteText(14, 1);
        await _waitForHighlight(quill);
        expect(quill.root.querySelectorAll('.ql-code-block-container'),
            hasLength(1));
        expectDelta(quill.getContents(), _initialDelta());
      });

      group('allowedChildren', () {
        bool allowBold(Blot child) => child is Bold;

        setUp(() => SyntaxCodeBlock.extraAllowedChildren.add(allowBold));
        tearDown(() => SyntaxCodeBlock.extraAllowedChildren.remove(allowBold));

        test('modification', () async {
          final quill = _createQuill();
          quill.formatText(2, 3, 'bold', true);
          await _waitForHighlight(quill);
          expect(
            quill.root,
            EqualHTML('''
              <div class="ql-code-block-container" spellcheck="false">
                <div class="ql-code-block" data-language="javascript">
                  <span class="ql-token hljs-keyword">va</span>
                  <strong><span class="ql-token hljs-keyword">r</span> t</strong>est = <span class="ql-token hljs-number">1</span>;
                </div>
                <div class="ql-code-block" data-language="javascript">
                  <span class="ql-token hljs-keyword">var</span> bugz = <span class="ql-token hljs-number">0</span>;
                </div>
              </div><p><br></p>
            '''),
          );
          expectDelta(
            quill.getContents(),
            Delta()
              ..insert('va')
              ..insert('r t', {'bold': true})
              ..insert('est = 1;')
              ..insert('\n', {'code-block': 'javascript'})
              ..insert('var bugz = 0;')
              ..insert('\n', {'code-block': 'javascript'})
              ..insert('\n'),
          );
        });

        test('removal', () async {
          final quill = _createQuill();
          quill.formatText(2, 3, 'bold', true);
          await _waitForHighlight(quill);
          quill.formatLine(0, 15, 'code-block', false);
          expect(
            quill.root,
            EqualHTML(
                '<p>va<strong>r t</strong>est = 1;</p><p>var bugz = 0;</p><p><br></p>'),
          );
          expectDelta(
            quill.getContents(),
            Delta()
              ..insert('va')
              ..insert('r t', {'bold': true})
              ..insert('est = 1;\nvar bugz = 0;\n\n'),
          );
        });

        test('addition', () async {
          final quill = _createQuill();
          quill.setText('var test = 1;\n');
          quill.formatText(2, 3, 'bold', true);
          quill.formatLine(0, 1, 'code-block', 'javascript');
          await _waitForHighlight(quill);
          expect(
            quill.root,
            EqualHTML('''
              <div class="ql-code-block-container" spellcheck="false">
                <div class="ql-code-block" data-language="javascript">
                  <span class="ql-token hljs-keyword">va</span>
                  <strong><span class="ql-token hljs-keyword">r</span> t</strong>est = <span class="ql-token hljs-number">1</span>;
                </div>
              </div>
            '''),
          );
          expectDelta(
            quill.getContents(),
            Delta()
              ..insert('va')
              ..insert('r t', {'bold': true})
              ..insert('est = 1;')
              ..insert('\n', {'code-block': 'javascript'}),
          );
        });
      });
    });

    group('html', () {
      test('code language', () {
        final quill = _createQuill();
        expect(quill.getSemanticHTML(), contains('data-language="javascript"'));
      });
    });
  });
}
