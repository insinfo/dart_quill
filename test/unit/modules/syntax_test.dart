import 'package:dart_quill/src/delta/delta.dart';
import 'package:dart_quill/src/modules/syntax.dart';
import 'package:test/test.dart';

import '../../support/quill_test_helpers.dart';

void main() {
  group('Syntax module', () {
    test('registers module and preserves code-block language', () {
      final quill = createTestQuill(modules: {'syntax': true});

      quill.setContents(
        Delta()
          ..insert('var test = 1;')
          ..insert('\n', {'code-block': 'javascript'}),
      );

      expect(
        quill.getContents().toJson(),
        equals(
          (Delta()
                ..insert('var test = 1;')
                ..insert('\n', {'code-block': 'javascript'}))
              .toJson(),
        ),
      );
      expect(quill.getModule('syntax'), isA<Syntax>());
      expect(quill.getSemanticHTML(), contains('data-language="javascript"'));
    });

    test('normalizes unknown languages to plain when highlighting', () {
      final quill = createTestQuill(
        modules: {
          'syntax': SyntaxOptions(
            languages: const [SyntaxLanguage(key: 'plain', label: 'Plain')],
          ),
        },
      );
      final syntax = quill.getModule('syntax') as Syntax;

      final delta = syntax.highlightBlot('const value = 1;\n', 'invalid');

      expect(
        delta.toJson(),
        equals(
          (Delta()
                ..insert('const value = 1;')
                ..insert('\n', {'code-block': 'plain'}))
              .toJson(),
        ),
      );
    });

    test('uses custom highlighter for configured languages', () {
      final quill = createTestQuill(
        modules: {
          'syntax': SyntaxOptions(
            languages: const [
              SyntaxLanguage(key: 'plain', label: 'Plain'),
              SyntaxLanguage(key: 'dart', label: 'Dart'),
            ],
            highlighter: (text, language) {
              return Delta()
                ..insert('final', {'code-token': 'keyword'})
                ..insert(' value')
                ..insert('\n', {'code-block': language});
            },
          ),
        },
      );
      final syntax = quill.getModule('syntax') as Syntax;

      final delta = syntax.highlightBlot('final value\n', 'dart');

      expect(
        delta.toJson(),
        equals(
          (Delta()
                ..insert('final', {'code-token': 'keyword'})
                ..insert(' value')
                ..insert('\n', {'code-block': 'dart'}))
              .toJson(),
        ),
      );
    });

    test('applies the highlighter output to the document (G5.4)', () {
      final quill = createTestQuill(
        modules: {
          'syntax': SyntaxOptions(
            languages: const [
              SyntaxLanguage(key: 'plain', label: 'Plain'),
              SyntaxLanguage(key: 'dart', label: 'Dart'),
            ],
            highlighter: (text, language) {
              // Marks every leading `final ` as a keyword token.
              final delta = Delta();
              for (final line
                  in text.substring(0, text.length - 1).split('\n')) {
                if (line.startsWith('final ')) {
                  delta.insert('final', {'code-token': 'keyword'});
                  delta.insert(line.substring(5));
                } else if (line.isNotEmpty) {
                  delta.insert(line);
                }
                delta.insert('\n', {'code-block': language});
              }
              return delta;
            },
          ),
        },
      );
      final syntax = quill.getModule('syntax') as Syntax;

      quill.setContents(
        Delta()
          ..insert('final value = 1;')
          ..insert('\n', {'code-block': 'dart'}),
      );
      syntax.highlight(null, true);

      // The token blots are materialised in the tree...
      final tokens = quill.scroll.descendants<CodeToken>().toList();
      expect(tokens, hasLength(1));
      expect(tokens.single.formats(), equals({'code-token': 'keyword'}));
      expect(tokens.single.value(), equals(['final']));
      expect(quill.root.innerHTML, contains('hljs-keyword'));

      // ...but stay out of the document Delta, which `bubbleFormats` filters
      // (block.ts:44-46) because highlighting is presentation-only.
      expect(
        quill.getContents().toJson(),
        equals(
          (Delta()
                ..insert('final value = 1;')
                ..insert('\n', {'code-block': 'dart'}))
              .toJson(),
        ),
      );
    });

    test('re-highlighting is idempotent and drops stale tokens', () {
      var keyword = 'final';
      final quill = createTestQuill(
        modules: {
          'syntax': SyntaxOptions(
            languages: const [
              SyntaxLanguage(key: 'plain', label: 'Plain'),
              SyntaxLanguage(key: 'dart', label: 'Dart'),
            ],
            highlighter: (text, language) {
              final delta = Delta();
              final body = text.substring(0, text.length - 1);
              if (body.startsWith(keyword)) {
                delta.insert(keyword, {'code-token': 'keyword'});
                delta.insert(body.substring(keyword.length));
              } else if (body.isNotEmpty) {
                delta.insert(body);
              }
              return delta..insert('\n', {'code-block': language});
            },
          ),
        },
      );
      final syntax = quill.getModule('syntax') as Syntax;

      quill.setContents(
        Delta()
          ..insert('final value = 1;')
          ..insert('\n', {'code-block': 'dart'}),
      );
      syntax.highlight(null, true);
      syntax.highlight(null, true);
      expect(quill.scroll.descendants<CodeToken>().toList(), hasLength(1));

      // A highlighter that no longer marks the word must unwrap the token.
      keyword = 'const';
      syntax.highlight(null, true);
      expect(quill.scroll.descendants<CodeToken>().toList(), isEmpty);
      expect(quill.getText(), equals('final value = 1;\n'));
    });

    test('code blocks without data-language report plain (upstream parity)',
        () {
      final quill = createTestQuill(modules: {'syntax': true});

      quill.setContents(
        Delta()
          ..insert('noop();')
          ..insert('\n', {'code-block': true}),
      );

      expect(
        quill.getContents().toJson(),
        equals(
          (Delta()
                ..insert('noop();')
                ..insert('\n', {'code-block': 'plain'}))
              .toJson(),
        ),
      );
    });

    test('mounting a code block attaches a language select', () {
      final quill = createTestQuill(modules: {'syntax': true});

      quill.setContents(
        Delta()
          ..insert('noop();')
          ..insert('\n', {'code-block': 'javascript'}),
      );

      final container =
          quill.scroll.descendants<SyntaxCodeBlockContainer>().first;
      final ui = container.uiNode;
      expect(ui, isNotNull);
      expect(ui!.tagName, equalsIgnoringCase('select'));
      expect(ui.querySelectorAll('option').length,
          equals(Syntax.defaultLanguages.length));
      expect(readSelectValue(ui), equals('javascript'));
    });
  });
}
