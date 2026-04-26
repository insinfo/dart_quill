import 'package:dart_quill/src/dependencies/dart_quill_delta/dart_quill_delta.dart';
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
  });
}
