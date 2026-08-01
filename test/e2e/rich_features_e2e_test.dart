@TestOn('vm')
@Timeout(Duration(minutes: 10))
library;

/// End-to-end coverage of the four features that only a real browser can
/// validate, driven by REAL user input:
///
/// * the placeholder (the demo must not render a stray one);
/// * the link tooltip, which has to land on the selected text — a
///   coordinate-system mistake in `getBounds()` puts it hundreds of pixels
///   away and nothing but layout can catch that;
/// * the Syntax module, which must colour code with the highlighter bundled in
///   the package (no highlight.js on the page);
/// * the Formula format, which must render math with the LaTeX renderer
///   bundled in the package (no KaTeX on the page).
import 'package:puppeteer/puppeteer.dart';
import 'package:test/test.dart';

import 'support/e2e_app.dart';

void main() {
  late E2eApp app;

  setUpAll(() async => app = await E2eApp.start());
  tearDownAll(() async => app.stop());

  group('placeholder', () {
    test('a blank editor renders no placeholder text', () async {
      await app.resetEditor();

      // `.ql-blank` is what the stylesheet keys the placeholder off of, so it
      // must be there — what must NOT be there is placeholder content.
      expect(
        await app.eval<bool>('() => document.querySelector(".ql-editor")'
            '.classList.contains("ql-blank")'),
        isTrue,
      );
      expect(
        await app.eval<String>('() => document.querySelector(".ql-editor")'
            '.getAttribute("data-placeholder") ?? ""'),
        isEmpty,
      );
      expect(
        await app.eval<String>('''() => {
          const el = document.querySelector(".ql-editor");
          const content = getComputedStyle(el, "::before").content;
          return content === "none" ? "" : content.replace(/^"|"\$/g, "");
        }'''),
        isEmpty,
        reason: 'the demo configures no placeholder, so nothing may be drawn',
      );
    });

    test('the placeholder option, when set, is what gets drawn', () async {
      await app.resetEditor();
      await app.eval<void>('''() => document.querySelector(".ql-editor")
          .setAttribute("data-placeholder", "Escreva algo épico...")''');

      expect(
        await app.eval<String>('''() => {
          const el = document.querySelector(".ql-editor");
          return getComputedStyle(el, "::before").content
              .replace(/^"|"\$/g, "");
        }'''),
        'Escreva algo épico...',
      );

      await app.eval<void>('''() => document.querySelector(".ql-editor")
          .removeAttribute("data-placeholder")''');
    });
  });

  group('link tooltip position', () {
    /// The viewport rect of the current selection, captured *before* the
    /// toolbar click: clicking moves focus to the tooltip input, and a
    /// collapsed native selection reports an empty rect.
    Future<Map<String, dynamic>> selectionRect() =>
        app.eval<Map<String, dynamic>>('''() => {
          const r = document.getSelection().getRangeAt(0).getBoundingClientRect();
          return {left: r.left, top: r.top, right: r.right, bottom: r.bottom,
                  width: r.width, height: r.height};
        }''');

    test('the tooltip opens on top of the selected text', () async {
      await app.resetEditor();
      await app.type('Quill site oficial');
      await app.selectAll();
      final selection = await selectionRect();
      await app.clickToolbarButton('link');
      await app.settle(120);

      final tooltip = await app.rectOf('.ql-tooltip');

      expect(
        await app.eval<bool>('() => document.querySelector(".ql-tooltip")'
            '.classList.contains("ql-editing")'),
        isTrue,
        reason: 'clicking the link button must open the tooltip editor',
      );

      final num tooltipTop = tooltip['top'] as num;
      final num selectionBottom = selection['bottom'] as num;
      expect(
        tooltipTop,
        inInclusiveRange(selectionBottom - 4, selectionBottom + 40),
        reason: 'the tooltip sits just below the selection, not elsewhere '
            'on the page (tooltip=$tooltip selection=$selection)',
      );

      // Centred on the selection, unless the tooltip is wider than the room
      // available — then it is clamped to the bounds container, so all that can
      // be required is a horizontal overlap with the selection.
      expect(
        (tooltip['left'] as num) <= (selection['right'] as num) &&
            (tooltip['right'] as num) >= (selection['left'] as num),
        isTrue,
        reason: 'the tooltip overlaps the selection horizontally '
            '(tooltip=$tooltip selection=$selection)',
      );

      await app.page.keyboard.press(Key.escape);
    });

    test('the tooltip follows the text down a long document', () async {
      await app.resetEditor();
      for (var i = 0; i < 12; i++) {
        await app.type('linha $i');
        await app.page.keyboard.press(Key.enter);
      }
      await app.type('alvo do link');
      await app.page.keyboard.down(Key.shift);
      for (var i = 0; i < 'alvo do link'.length; i++) {
        await app.page.keyboard.press(Key.arrowLeft);
      }
      await app.page.keyboard.up(Key.shift);
      final selection = await selectionRect();
      await app.clickToolbarButton('link');
      await app.settle(120);

      final tooltip = await app.rectOf('.ql-tooltip');
      final flipped = await app.eval<bool>(
          '() => document.querySelector(".ql-tooltip")'
          '.classList.contains("ql-flip")');

      // The tooltip either hangs below the selection or — when it would fall
      // out of the bounds container — flips above it. What must NOT happen is
      // a gap that grows with the distance from the top of the page: that is
      // the signature of a viewport-vs-container coordinate mix-up.
      final gap = flipped
          ? (selection['top'] as num) - (tooltip['bottom'] as num)
          : (tooltip['top'] as num) - (selection['bottom'] as num);
      expect(
        gap,
        inInclusiveRange(-4, 40),
        reason: 'flipped=$flipped tooltip=$tooltip selection=$selection',
      );

      await app.page.keyboard.press(Key.escape);
    });
  });

  group('no external dependencies', () {
    test('the page loads nothing from another host', () async {
      final external = await app.eval<List<dynamic>>('''() =>
          [...document.querySelectorAll('script[src], link[href]')]
              .map(el => el.src || el.href)
              .filter(url => !url.startsWith(location.origin))''');
      expect(external, isEmpty,
          reason: 'a formula or a code block must never need a CDN');
    });

    test('neither highlight.js nor KaTeX is on the page', () async {
      expect(await app.eval<bool>('() => typeof window.hljs !== "undefined"'),
          isFalse);
      expect(await app.eval<bool>('() => typeof window.katex !== "undefined"'),
          isFalse);
    });
  });

  group('syntax module (bundled highlighter)', () {
    test('a code block gets hljs tokens once a language is picked', () async {
      await app.resetEditor();
      await app.type('const answer = 42;');
      await app.clickToolbarButton('code-block');
      await app.settle(120);

      expect(
        await app.eval<int>('() => document.querySelectorAll('
            '".ql-editor .ql-code-block-container select").length'),
        1,
        reason: 'the module hangs a language <select> on every code block',
      );

      // A user picks the language from the block's own <select>.
      await app.page
          .select('.ql-editor .ql-code-block-container select', ['javascript']);
      await app.settle(400);

      final tokens = await app.eval<List<dynamic>>('''() =>
          [...document.querySelectorAll(".ql-editor .ql-token")]
              .map(el => el.className)''');
      expect(tokens, isNotEmpty,
          reason: 'highlight.js output must reach the document as ql-token '
              'spans');
      expect(
        tokens.join(' '),
        contains('hljs-'),
        reason: 'tokens carry highlight.js classes, exactly like upstream '
            '(got: $tokens)',
      );

      // Highlighting is presentation only: upstream keeps `code-token` out of
      // the document model, and so must this port — an application reading the
      // delta must not see colours in it.
      expect(await app.contents(), isNot(contains('code-token')));
      expect(
        await app.contents(),
        '[{"insert":"const answer = 42;"},'
            '{"insert":"\\n","attributes":{"code-block":"javascript"}}]',
      );
      // The bundled stylesheet must be what colours them — a 404 on
      // `assets/quill.syntax.css` would leave the tokens inheriting the
      // container's colour.
      expect(
        await app.eval<String>('''() => getComputedStyle(
            document.querySelector(".ql-editor .hljs-keyword")).color'''),
        'rgb(248, 48, 111)',
        reason: 'assets/quill.syntax.css must be served and applied',
      );

      // Scoped to the code line: `.ql-editor` also contains the language
      // <select> the module hangs on the block, whose options are text too.
      expect(
        await app.eval<String>('''() => document.querySelector(
            ".ql-editor .ql-code-block").textContent'''),
        'const answer = 42;',
        reason: 'the text itself is untouched',
      );
    });

    test('the language survives a reload of the highlight cycle', () async {
      // Typing more code inside the block keeps the language and re-highlights.
      await app.page.click('.ql-editor .ql-code-block');
      await app.page.keyboard.press(Key.end);
      await app.type('\nlet outro = "texto";');
      await app.settle(1400); // > the module's 1s debounce

      expect(
        await app.eval<int>('() => document.querySelectorAll('
            '".ql-editor .ql-token.hljs-string").length'),
        greaterThan(0),
        reason: 'the string literal must be tokenised after the debounce',
      );
    });

    test('leaving the code block strips the presentation tokens', () async {
      await app.resetEditor();
      await app.type('const x = 1;');
      await app.clickToolbarButton('code-block');
      await app.page
          .select('.ql-editor .ql-code-block-container select', ['javascript']);
      await app.settle(400);
      expect(
        await app.eval<int>(
            '() => document.querySelectorAll(".ql-editor .ql-token").length'),
        greaterThan(0),
        reason: 'precondition: the block is highlighted',
      );

      await app.clickToolbarButton('code-block'); // toggle off
      await app.settle(200);

      expect(
        await app.eval<int>(
            '() => document.querySelectorAll(".ql-editor .ql-token").length'),
        0,
        reason: 'the token spans must not survive into a plain paragraph',
      );
      expect(await app.contents(), isNot(contains('code-token')));
      expect(await app.editorText(), 'const x = 1;');
    });
  });

  group('formula format (bundled LaTeX renderer)', () {
    test('the toolbar inserts a formula rendered as MathML', () async {
      await app.resetEditor();
      await app.clickToolbarButton('formula');
      await app.settle(120);

      expect(
        await app.eval<String>('() => document.querySelector(".ql-tooltip")'
            '.getAttribute("data-mode")'),
        'formula',
      );

      await app.page.type('.ql-tooltip input[data-formula]', 'e=mc^2');
      await app.page.keyboard.press(Key.enter);
      await app.settle(200);

      expect(await app.contents(), contains('formula'),
          reason: 'the embed must reach the model');
      expect(
        await app.eval<int>('() => document.querySelectorAll('
            '".ql-editor .ql-formula math msup").length'),
        greaterThan(0),
        reason: 'the exponent must be rendered as MathML; raw LaTeX text '
            'means the renderer never ran',
      );
      // The browser has to lay the math out, not just hold the markup.
      final box = await app.rectOf('.ql-editor .ql-formula math');
      expect(box['width'] as num, greaterThan(0));
      expect(box['height'] as num, greaterThan(0));
      expect(
        await app.eval<String>('''() => document.querySelector(
            ".ql-editor .ql-formula").getAttribute("data-value")'''),
        'e=mc^2',
        reason: 'the source LaTeX is kept for round-tripping',
      );
    });

    test('a formula round-trips through the clipboard/HTML pipeline', () async {
      await app.resetEditor();
      await app.clickToolbarButton('formula');
      await app.settle(120);
      await app.page.type('.ql-tooltip input[data-formula]', r'\frac{a}{b}');
      await app.page.keyboard.press(Key.enter);
      await app.settle(200);

      // setContents with the same delta must rebuild rendered math, which is
      // what a load-from-database does.
      final contents = await app.contents();
      expect(contents, contains(r'\\frac{a}{b}'));

      await app.eval<void>('''() => {
        const delta = JSON.parse(window.e2eGetContents());
        window.e2eSetContents(JSON.stringify(delta));
      }''');
      await app.settle(200);

      expect(
        await app.eval<int>('() => document.querySelectorAll('
            '".ql-editor .ql-formula math mfrac").length'),
        greaterThan(0),
        reason: 'a formula loaded from a delta must render too',
      );
    });

    test('invalid LaTeX shows its source instead of breaking the editor',
        () async {
      await app.resetEditor();
      await app.clickToolbarButton('formula');
      await app.settle(120);
      await app.page.type('.ql-tooltip input[data-formula]', r'\naoexiste{x}');
      await app.page.keyboard.press(Key.enter);
      await app.settle(200);

      expect(
        await app.eval<String>('''() => document.querySelector(
            ".ql-editor .ql-formula")?.textContent ?? ""'''),
        contains(r'\naoexiste{x}'),
        reason: 'parity with KaTeX throwOnError:false — the source is shown',
      );
      // And the editor still works afterwards.
      await app.page.click('.ql-editor');
      await app.type(' depois');
      expect(await app.editorText(), contains('depois'));
    });
  });

  group('image selection', () {
    // 1x1 PNG transparente — pequeno o bastante para viver no teste e real o
    // bastante para o browser renderizar um <img> com caixa.
    const png = 'data:image/png;base64,'
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';

    Future<void> documentWithImage() async {
      await app.reload();
      await app.resetEditor();
      await app.setContents([
        {'insert': 'antes\n'},
        {
          'insert': {'image': png},
          'attributes': {'width': '120', 'height': '120'},
        },
        {'insert': '\n'},
      ]);
      await app.settle(200);
    }

    // Regressão: clicar na imagem só desenhava o overlay de redimensionamento;
    // a seleção do MODELO ficava onde estava, então Delete/Backspace não
    // tinham o que apagar e a imagem parecia selecionada mas não saía.
    test('clicking an image selects it in the model and Delete removes it',
        () async {
      await documentWithImage();
      expect(await app.contents(), contains('image'),
          reason: 'a imagem precisa estar no documento para o teste valer');

      await app.clickElement('.ql-editor img');
      await app.settle(200);

      expect(await app.eval<bool>('() => !!document.querySelector('
          '".ql-image-resize-overlay") && getComputedStyle('
          'document.querySelector(".ql-image-resize-overlay")).display '
          '!== "none"'),
          isTrue,
          reason: 'o overlay de redimensionamento aparece no clique');

      final selection = await app.selection();
      expect(selection.endsWith(':1'), isTrue,
          reason: 'a seleção precisa cobrir o embed (comprimento 1), '
              'não ser um caret — veio "$selection"');

      await app.page.keyboard.press(Key.delete);
      await app.settle(250);

      expect(await app.contents(), isNot(contains('image')),
          reason: 'Delete com a imagem selecionada precisa apagá-la');
      expect(await app.eval<int>(
          '() => document.querySelectorAll(".ql-editor img").length'), 0);
      expect(
          await app.eval<String>('() => { const o = document.querySelector('
              '".ql-image-resize-overlay"); return o ? '
              'getComputedStyle(o).display : "absent"; }'),
          anyOf('none', 'absent'),
          reason: 'o overlay não pode ficar pairando sobre uma imagem que '
              'já não existe');
    });
  });
}
