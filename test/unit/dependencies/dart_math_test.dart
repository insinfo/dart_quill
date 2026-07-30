/// Tests for the bundled LaTeX renderer.
///
/// Two properties matter above all: valid TeX must produce well-formed MathML
/// (a malformed tree renders as nothing at all in a browser), and *invalid*
/// TeX must never throw — a typo in a formula cannot be allowed to break the
/// editor, which is why upstream passes `throwOnError: false` to KaTeX.
library;

import 'package:dart_quill/src/dependencies/dart_math/dart_math.dart';
import 'package:test/test.dart';

void main() {
  /// Fails when tags are not balanced, which is the practical definition of
  /// "the browser will render this".
  void expectWellFormed(String mathml) {
    final tags = RegExp(r'<(/?)([a-zA-Z]+)([^>]*?)(/?)>');
    final stack = <String>[];
    for (final match in tags.allMatches(mathml)) {
      final closing = match.group(1) == '/';
      final name = match.group(2)!;
      final selfClosing = match.group(4) == '/';
      if (selfClosing) continue;
      if (closing) {
        expect(stack, isNotEmpty, reason: 'stray </$name> in $mathml');
        expect(stack.removeLast(), name, reason: 'mismatched tag in $mathml');
      } else {
        stack.add(name);
      }
    }
    expect(stack, isEmpty, reason: 'unclosed ${stack.join(', ')} in $mathml');
  }

  String render(String tex) {
    final mathml = texToMathML(tex);
    expectWellFormed(mathml);
    return mathml;
  }

  group('structure', () {
    test('wraps the body in an inline math element', () {
      final mathml = render('x');
      expect(mathml, startsWith('<math xmlns="http://www.w3.org/1998/Math/MathML" '
          'display="inline">'));
      expect(mathml, endsWith('</math>'));
      expect(mathml, contains('<mi>x</mi>'));
    });

    test('display mode is requested explicitly', () {
      expect(texToMathML('x', displayMode: true), contains('display="block"'));
    });

    test('identifiers, numbers and operators use the right elements', () {
      final mathml = render('2x + 1 = y');
      expect(mathml, contains('<mn>2</mn>'));
      expect(mathml, contains('<mi>x</mi>'));
      expect(mathml, contains('<mo>+</mo>'));
      expect(mathml, contains('<mo>=</mo>'));
    });

    test('decimals stay one number', () {
      expect(render('3.14'), contains('<mn>3.14</mn>'));
    });

    test('a minus sign becomes the real minus character', () {
      expect(render('a - b'), contains('<mo>−</mo>'));
    });
  });

  group('the formulas from Quill\'s own demo', () {
    test(r'e=mc^2', () {
      final mathml = render('e=mc^2');
      expect(mathml, contains('<msup><mi>c</mi><mn>2</mn></msup>'));
    });

    test(r'x^2 + (y - x^3)^2 = 1', () {
      final mathml = render(r'x^2 + (y - x^3)^2 = 1');
      expect(mathml, contains('<msup>'));
      expect(mathml, contains('<mo stretchy="false">(</mo>'));
    });

    test(r'x^2 + (y - \sqrt[3]{x^2})^2 = 1', () {
      final mathml = render(r'x^2 + (y - \sqrt[3]{x^2})^2 = 1');
      expect(mathml, contains('<mroot>'));
      expect(mathml, contains('<mn>3</mn>'));
    });
  });

  group('constructions', () {
    test('fractions', () {
      expect(render(r'\frac{a}{b}'),
          contains('<mfrac><mrow><mi>a</mi></mrow><mrow><mi>b</mi></mrow></mfrac>'));
      expect(render(r'\dfrac{1}{2}'), contains('<mfrac>'));
    });

    test('legacy \\over splits the group', () {
      final mathml = render(r'{a + 1 \over b}');
      expect(mathml, contains('<mfrac>'));
      expect(mathml, contains('<mi>a</mi>'));
      expect(mathml, contains('<mi>b</mi>'));
    });

    test('square and n-th roots', () {
      expect(render(r'\sqrt{2}'), contains('<msqrt><mn>2</mn></msqrt>'));
      expect(render(r'\sqrt[n]{x}'), contains('<mroot>'));
    });

    test('binomials render as a line-less fraction in parentheses', () {
      final mathml = render(r'\binom{n}{k}');
      expect(mathml, contains('linethickness="0"'));
      expect(mathml, contains('<mo fence="true" stretchy="false">(</mo>'));
    });

    test('sub and superscripts, together and apart', () {
      expect(render('a_i'), contains('<msub>'));
      expect(render('a^i'), contains('<msup>'));
      expect(render('a_i^2'), contains('<msubsup><mi>a</mi><mi>i</mi><mn>2</mn>'
          '</msubsup>'));
    });

    test('primes become superscript marks', () {
      expect(render("f'"), contains('′'));
      expect(render("f''"), contains('′′'));
    });

    test('big operators take limits above and below', () {
      final mathml = render(r'\sum_{i=1}^{n} i');
      expect(mathml, contains('<munderover>'));
      expect(mathml, contains('∑'));
    });

    test('integrals keep their limits beside the sign', () {
      final mathml = render(r'\int_0^1 x dx');
      expect(mathml, contains('<msubsup>'));
      expect(mathml, contains('∫'));
    });

    test(r'\left…\right fences stretch', () {
      final mathml = render(r'\left( \frac{a}{b} \right)');
      expect(mathml, contains('<mo fence="true" stretchy="true">(</mo>'));
      expect(mathml, contains('<mo fence="true" stretchy="true">)</mo>'));
    });

    test(r'\left. renders no delimiter', () {
      final mathml = render(r'\left. \frac{a}{b} \right|');
      expect(mathml, isNot(contains('>.</mo>')));
      expect(mathml, contains('>|</mo>'));
    });

    test('greek letters are identifiers', () {
      expect(render(r'\alpha + \Omega'), contains('<mi>α</mi>'));
      expect(render(r'\alpha + \Omega'), contains('<mi>Ω</mi>'));
    });

    test('function names are upright', () {
      expect(render(r'\sin x'), contains('<mi mathvariant="normal">sin</mi>'));
    });

    test('lim takes limits below', () {
      expect(render(r'\lim_{x \to 0} f(x)'), contains('<munder>'));
    });

    test('text keeps its spaces', () {
      final mathml = render(r'\text{a b}');
      // A plain space would be collapsed away by MathML layout.
      expect(mathml, contains('<mtext>a b</mtext>'));
    });

    test('font switches map to mathvariant', () {
      expect(render(r'\mathbb{R}'), contains('mathvariant="double-struck"'));
      expect(render(r'\mathbf{v}'), contains('mathvariant="bold"'));
    });

    test('accents sit over their argument', () {
      expect(render(r'\hat{x}'), contains('<mover accent="true">'));
      expect(render(r'\vec{v}'), contains('→'));
      expect(render(r'\underline{x}'), contains('<munder accentunder="true">'));
    });

    test('spacing commands become mspace', () {
      expect(render(r'a \, b'), contains('<mspace width="0.167em"/>'));
      expect(render(r'a \quad b'), contains('<mspace width="1em"/>'));
    });

    test(r'\not strikes the relation through', () {
      expect(render(r'a \not= b'), contains('̸'));
    });

    test('matrices become tables inside fences', () {
      final mathml = render(r'\begin{pmatrix} a & b \\ c & d \end{pmatrix}');
      expect(mathml, contains('<mtable'));
      expect(mathml, contains('<mtr><mtd><mi>a</mi></mtd><mtd><mi>b</mi></mtd>'
          '</mtr>'));
      expect(mathml, contains('<mo fence="true" stretchy="true">(</mo>'));
    });

    test('a trailing row separator adds no empty row', () {
      final mathml = render(r'\begin{matrix} a \\ b \\ \end{matrix}');
      expect(RegExp('<mtr>').allMatches(mathml).length, 2);
    });

    test('cases uses a brace and left alignment', () {
      final mathml = render(r'\begin{cases} 1 & x > 0 \\ 0 & x \le 0 \end{cases}');
      expect(mathml, contains('columnalign="left"'));
      expect(mathml, contains('>{</mo>'));
    });

    test('array honours its column spec', () {
      final mathml = render(r'\begin{array}{lr} a & b \end{array}');
      expect(mathml, contains('columnalign="left right"'));
    });

    test('nested environments parse', () {
      final mathml = render(
          r'\begin{pmatrix} \begin{matrix} a \end{matrix} & b \end{pmatrix}');
      expect(RegExp('<mtable').allMatches(mathml).length, 2);
    });

    test('escaped specials are literal', () {
      expect(render(r'50\%'), contains('<mo stretchy="false">%</mo>'));
      expect(render(r'\{x\}'), contains('>{</mo>'));
    });

    test('markup characters in the source are escaped', () {
      final mathml = render('a < b');
      expect(mathml, contains('&lt;'));
      expect(mathml, isNot(contains('<mo><</mo>')));
    });
  });

  group('error handling', () {
    test('an unknown command shows the source in the error colour', () {
      final mathml = texToMathML(r'\naoexiste{x}');
      expect(mathml, contains('ql-formula-error'));
      expect(mathml, contains('#f00'));
      expect(mathml, contains(r'\naoexiste{x}'));
      expect(mathml, isNot(contains('<math')));
    });

    test('the error colour is configurable', () {
      expect(texToMathML(r'\bad', errorColor: '#00f'), contains('#00f'));
    });

    test('unbalanced input never throws', () {
      for (final broken in [
        r'\frac{a',
        r'\left( a',
        '}',
        r'\begin{pmatrix} a',
        r'\sqrt',
        'a^^b',
        r'\begin{naoexiste} a \end{naoexiste}',
        r'\begin{matrix} a \end{pmatrix}',
        '\\',
      ]) {
        expect(() => texToMathML(broken), returnsNormally,
            reason: 'must degrade, not throw: $broken');
        expect(texToMathML(broken), contains('ql-formula-error'),
            reason: 'must be reported as an error: $broken');
      }
    });

    test('the source is HTML-escaped in the error markup', () {
      final mathml = texToMathML(r'\bad <script>');
      expect(mathml, contains('&lt;script&gt;'));
      expect(mathml, isNot(contains('<script>')));
    });

    test('an empty formula is valid and renders nothing', () {
      expect(render(''), '<math xmlns="http://www.w3.org/1998/Math/MathML" '
          'display="inline"></math>');
    });

    test('isValidTex separates good from bad', () {
      expect(isValidTex(r'\frac{1}{2}'), isTrue);
      expect(isValidTex(r'\frac{1}'), isFalse);
    });
  });

  group('well-formedness sweep', () {
    const formulas = [
      r'e=mc^2',
      r'\sum_{n=1}^{\infty} \frac{1}{n^2} = \frac{\pi^2}{6}',
      r'\int_{-\infty}^{\infty} e^{-x^2} dx = \sqrt{\pi}',
      r'\left[ \frac{\partial f}{\partial x} \right]_{x=0}',
      r'f(x) = \begin{cases} x^2 & x \ge 0 \\ -x & x < 0 \end{cases}',
      r'\mathbf{A} = \begin{bmatrix} 1 & 0 \\ 0 & 1 \end{bmatrix}',
      r'\lim_{h \to 0} \frac{f(x+h) - f(x)}{h}',
      r'\vec{F} = m \vec{a}',
      r'\alpha^2 + \beta^2 \le \gamma^2',
      r'x = \frac{-b \pm \sqrt{b^2 - 4ac}}{2a}',
      r'\text{Área} = \pi r^2',
      r'A \cup B \subseteq C \cap D',
      r'\overline{z_1 z_2} = \overline{z_1} \cdot \overline{z_2}',
      r'\binom{n}{k} = \frac{n!}{k!(n-k)!}',
      r'\begin{aligned} a &= b \\ c &= d \end{aligned}',
      r'\hat{y} = \beta_0 + \beta_1 x_1',
      r'P(A \mid B) = \frac{P(B \mid A) P(A)}{P(B)}',
      r'\nabla \times \vec{B} = \mu_0 \vec{J}',
      r'\sqrt[3]{\frac{a}{b}}',
      r'\left\{ x \in \mathbb{R} : x > 0 \right\}',
    ];

    for (final formula in formulas) {
      test('renders $formula', () {
        final mathml = render(formula);
        expect(mathml, contains('<math'),
            reason: 'must parse, not fall back: $formula');
        expect(mathml, isNot(contains('ql-formula-error')));
      });
    }
  });
}
