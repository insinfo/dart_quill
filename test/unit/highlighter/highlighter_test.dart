/// Tests for the bundled syntax highlighter.
///
/// The contract that matters is the one Quill's Syntax module consumes: token
/// classes named like highlight.js' (`keyword`, `string`, `comment`, …) and,
/// above all, tokens whose concatenated text is *exactly* the input — a
/// highlighter that loses or duplicates a character would corrupt the
/// document it is only supposed to colour.
library;

import 'package:dart_quill/src/highlighter/highlighter.dart';
import 'package:test/test.dart';

void main() {
  /// The scope covering [needle], or null when it is not highlighted.
  String? scopeOf(List<HighlightToken> tokens, String needle) {
    for (final token in tokens) {
      if (token.text.contains(needle)) return token.scope;
    }
    return null;
  }

  void expectLossless(String code, String language) {
    final tokens = highlight(code, language);
    expect(tokens.map((t) => t.text).join(), code,
        reason: 'highlighting must never alter the text ($language)');
  }

  group('losslessness', () {
    const samples = {
      'javascript': '''
const quill = new Quill('#editor', {
  modules: { toolbar: '#toolbar' }, // inline comment
  theme: 'snow',
});
/* block
   comment */
class Editor extends Base { }
''',
      'python': '''
@decorator
def soma(a, b=2):
    """doc
    string"""
    return a + b  # comentário
''',
      'sql': "SELECT id, name FROM users WHERE name LIKE 'O''Brien' -- nota\n",
      'xml': '<div class="a" id=\'b\'><!-- c --><br/>&amp;</div>\n',
      'css': '.a > #b:hover { color: #fff; width: calc(10px + 2em) !important; }\n',
      'bash': 'for f in *.dart; do\n  echo "\$f ok" # nota\ndone\n',
      'diff': '--- a/x\n+++ b/x\n@@ -1,2 +1,2 @@\n-old\n+new\n',
      'markdown': '# Título\n\n**forte** e *ênfase* e `código`\n\n- item\n',
      'ruby': "class Foo\n  def bar\n    puts \"olá #{name}\"\n  end\nend\n",
      'php': '<?php\nclass A { public \$x = 1; } // fim\n?>\n',
      'java': 'public class A implements B {\n  int x = 0x1F; // nota\n}\n',
      'cpp': '#include <vector>\nnamespace n { int x = 42; /* c */ }\n',
      'cs': 'namespace N { public class A { string s = @"raw"; } }\n',
      'plain': 'nada para realçar\n',
    };

    samples.forEach((language, code) {
      test('$language keeps the text intact', () => expectLossless(code, language));
    });

    test('an unknown language degrades to plain text', () {
      final tokens = highlight('qualquer coisa', 'klingon');
      expect(tokens, [const HighlightToken('qualquer coisa')]);
    });

    test('empty input yields no tokens', () {
      expect(highlight('', 'javascript'), isEmpty);
    });

    test('an unterminated string cannot swallow the document', () {
      final tokens = highlight("const a = 'aberta\nconst b = 2;\n", 'javascript');
      expect(tokens.map((t) => t.text).join(), "const a = 'aberta\nconst b = 2;\n");
      expect(
        tokens.where((t) => t.scope == 'keyword' && t.text == 'const').length,
        2,
        reason: 'the newline is illegal inside the string, so it closes there '
            'and the next line is highlighted normally',
      );
    });
  });

  group('javascript', () {
    final tokens = highlight(
      "const answer = 42; // resposta\nlet s = 'texto';\n",
      'javascript',
    );

    test('keywords are tokenised', () => expect(scopeOf(tokens, 'const'), 'keyword'));
    test('numbers are tokenised', () => expect(scopeOf(tokens, '42'), 'number'));
    test('strings are tokenised', () => expect(scopeOf(tokens, 'texto'), 'string'));
    test('comments are tokenised',
        () => expect(scopeOf(tokens, 'resposta'), 'comment'));
    test('literals are tokenised', () {
      expect(scopeOf(highlight('let a = true;', 'javascript'), 'true'), 'literal');
    });
    test('built-ins are tokenised', () {
      expect(scopeOf(highlight('console.log(1)', 'javascript'), 'console'),
          'built_in');
    });
    test('a function name becomes a title', () {
      final result = highlight('function somar(a, b) { return a + b; }', 'javascript');
      expect(scopeOf(result, 'somar'), 'title');
      expect(scopeOf(result, 'function'), 'keyword');
    });
    test('a class name becomes a title and extends stays a keyword', () {
      final result = highlight('class Editor extends Base {}', 'javascript');
      expect(scopeOf(result, 'Editor'), 'title');
      expect(scopeOf(result, 'extends'), 'keyword');
    });
    test('template literals highlight their substitutions', () {
      final result = highlight(r'const s = `a ${x + 1} b`;', 'javascript');
      expect(scopeOf(result, 'a '), 'string');
      expect(scopeOf(result, r'${'), 'subst');
    });
    test('an escaped quote does not close the string', () {
      final result = highlight(r"const s = 'a\'b'; const n = 1;", 'javascript');
      expect(scopeOf(result, r"a\'b"), 'string');
      expect(
        result.where((t) => t.scope == 'keyword' && t.text == 'const').length,
        2,
        reason: 'the string closes at its own quote, so the code after it is '
            'still highlighted',
      );
    });
  });

  group('other grammars', () {
    test('python def gets a title and builtins are marked', () {
      final result = highlight('def somar(a):\n    return len(a)\n', 'python');
      expect(scopeOf(result, 'somar'), 'title');
      expect(scopeOf(result, 'len'), 'built_in');
    });

    test('python triple-quoted strings span lines', () {
      final result = highlight('x = """a\nb"""\n', 'python');
      expect(scopeOf(result, 'a\nb'), 'string');
    });

    test('sql is case-insensitive', () {
      expect(scopeOf(highlight('select 1 from t', 'sql'), 'select'), 'keyword');
      expect(scopeOf(highlight('SELECT 1 FROM t', 'sql'), 'SELECT'), 'keyword');
    });

    test("sql '' inside a literal does not close it", () {
      final result = highlight("SELECT 'O''Brien' AS n", 'sql');
      expect(scopeOf(result, "O''Brien"), 'string');
      expect(scopeOf(result, 'AS'), 'keyword');
    });

    test('xml tags, attributes and values', () {
      final result = highlight('<a href="x">t</a>', 'xml');
      expect(scopeOf(result, '<a'), 'tag');
      expect(scopeOf(result, 'href'), 'attr');
      expect(scopeOf(result, '"x"'), 'string');
      expect(scopeOf(result, 't'), isNull, reason: 'text content is not a token');
    });

    test('css attributes and values', () {
      final result = highlight('.a { color: red; width: 10px; }', 'css');
      expect(scopeOf(result, '.a'), 'selector-class');
      expect(scopeOf(result, 'color'), 'attribute');
      expect(scopeOf(result, '10px'), 'number');
    });

    test('diff marks additions, deletions and hunks', () {
      final result = highlight('@@ -1 +1 @@\n-a\n+b\n', 'diff');
      expect(scopeOf(result, '-a'), 'deletion');
      expect(scopeOf(result, '+b'), 'addition');
      expect(scopeOf(result, '@@ -1 +1 @@'), 'meta');
    });

    test('markdown headings, code and emphasis', () {
      final result = highlight('# T\n\n**f** `c`\n', 'markdown');
      expect(scopeOf(result, '# T'), 'section');
      expect(scopeOf(result, '**f**'), 'strong');
      expect(scopeOf(result, '`c`'), 'code');
    });

    test('bash marks variables inside double quotes', () {
      final result = highlight('echo "ok \$HOME"\n', 'bash');
      expect(scopeOf(result, r'$HOME'), 'variable');
      expect(scopeOf(result, 'echo'), 'built_in');
    });

    test('php variables and meta tags', () {
      final result = highlight('<?php \$x = 1; ?>', 'php');
      expect(scopeOf(result, '<?php'), 'meta');
      expect(scopeOf(result, r'$x'), 'variable');
    });

    test('ruby symbols, ivars and interpolation', () {
      final result = highlight('def f\n  puts "#{@a} :b"\nend\n', 'ruby');
      expect(scopeOf(result, '@a'), isNot('string'));
      expect(scopeOf(result, 'puts'), 'built_in');
    });

    test('java annotations and types', () {
      final result = highlight('@Override\npublic int x = 1;\n', 'java');
      expect(scopeOf(result, '@Override'), 'meta');
      expect(scopeOf(result, 'int'), 'type');
    });

    test('cpp preprocessor lines are meta', () {
      final result = highlight('#include <vector>\nint x = 1;\n', 'cpp');
      expect(scopeOf(result, '#include'), 'meta');
      expect(scopeOf(result, 'int'), 'type');
    });

    test('c# verbatim strings span lines', () {
      final result = highlight('var s = @"a\nb";\n', 'cs');
      expect(scopeOf(result, 'a\nb'), 'string');
    });
  });

  group('html output', () {
    test('produces hljs class names and escapes the text', () {
      final html = highlightToHtml('const a = "<b>";', 'javascript');
      expect(html, contains('<span class="hljs-keyword">const</span>'));
      expect(html, contains('&lt;b&gt;'));
      expect(html, isNot(contains('<b>')));
    });
  });

  group('registry', () {
    test('every language Quill offers in its picker has a grammar', () {
      for (final key in const [
        'plain', 'bash', 'cpp', 'cs', 'css', 'diff', 'xml', 'java',
        'javascript', 'markdown', 'php', 'python', 'ruby', 'sql',
      ]) {
        expect(supportsLanguage(key), isTrue, reason: 'missing grammar: $key');
      }
    });

    test('aliases resolve to their language', () {
      expect(scopeOf(highlight('const a = 1;', 'js'), 'const'), 'keyword');
      expect(scopeOf(highlight('<a>x</a>', 'html'), '<a'), 'tag');
    });

    test('an application can register its own grammar', () {
      registerLanguage(const Language(
        name: 'toy',
        root: Mode(keywords: {'keyword': ['ping']}),
      ));
      expect(scopeOf(highlight('ping pong', 'toy'), 'ping'), 'keyword');
    });
  });
}
