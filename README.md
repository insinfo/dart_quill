# dart_quill

A pure-Dart port of [Quill 2.0.3](https://quilljs.com) and the
[quill-table-better 1.2.3](https://github.com/attoae/quill-table-better) plugin,
for Dart web applications — with or without AngularDart.

This is not a wrapper around the JavaScript Quill: the blots, parchment, the
Delta pipeline, the modules and the themes were ported to Dart. The only
runtime dependency is `web`.

> **Status:** the port is in its final stretch. The core (Delta, blots,
> keyboard, clipboard, themes, tables) is functional and covered by tests;
> detailed parity tracking against the TypeScript source lives in
> [`doc/INVENTARIO_E_PLANO_FINALIZACAO.md`](doc/INVENTARIO_E_PLANO_FINALIZACAO.md).

---

## Table of contents

- [Installation](#installation)
- [Minimal usage](#minimal-usage)
- [Stylesheets](#stylesheets)
- [Icons](#icons)
- [Tables](#tables)
- [Syntax highlighting](#syntax-highlighting)
- [Formulas (LaTeX)](#formulas-latex)
- [DOCX](#docx)
- [Extending the editor](#extending-the-editor)
- [Development](#development)
- [Architecture](#architecture)
- [License](#license)

---

## Installation

```yaml
dependencies:
  dart_quill:
    path: ../dart_quill   # or git:, while not yet published
```

```bash
dart pub get
```

Requires Dart SDK `^3.6.0`.

---

## Minimal usage

```dart
import 'package:web/web.dart' as web;
import 'package:dart_quill/dart_quill.dart';
import 'package:dart_quill/src/platform/html_dom.dart' show HtmlDomElement;

void main() {
  // Registers the default blots, formats and modules. Call once, at boot.
  initializeQuill();

  // Loads the Snow theme stylesheet (see "Stylesheets" for the alternative
  // of declaring the <link> in the HTML itself).
  QuillAssets.injectSnowTheme();

  // The editor talks to the package's DOM abstraction, not to package:web
  // directly; `HtmlDomElement` is the bridge.
  final host = HtmlDomElement(web.document.querySelector('#editor')!);

  final quill = Quill(
    host,
    options: ThemeOptions(
      theme: 'snow',
      modules: {
        'toolbar': ToolbarProps(
          container: ToolbarConfig(const [
            ['bold', 'italic', 'underline'],
            [
              {'header': [1, 2, false]}
            ],
            [
              {'list': 'ordered'},
              {'list': 'bullet'}
            ],
            ['link', 'image'],
            ['clean'],
          ]),
        ),
      },
    ),
  );

  quill.setContents(Delta()..insert('Hello, world!\n'));
  print(quill.getContents().toJson());
}
```

### Main API

The contract follows Quill's; mutators return the applied Delta.

```dart
quill.getText();                       // plain text
quill.getContents();                   // document Delta
quill.setContents(Delta()..insert('text\n'));
quill.updateContents(delta, source: EmitterSource.USER);

quill.insertText(0, 'text', source: EmitterSource.API);
quill.deleteText(0, 5);
quill.formatText(0, 5, 'bold', true);
quill.formatLine(0, 1, 'header', 2);
quill.format('italic', true);
quill.removeFormat(0, 5);

quill.getSelection();                  // Range?
quill.setSelection(const Range(0, 5));
quill.getFormat(0, 5);                 // active formats in the range

quill.enable();  quill.disable();      // read-only
quill.getSemanticHTML();

quill.on(EmitterEvents.TEXT_CHANGE, (delta, oldDelta, source) { /* … */ });
quill.on(EmitterEvents.SELECTION_CHANGE, (range, oldRange, source) { /* … */ });
```

---

## Stylesheets

**The CSS is not embedded in Dart code.** It lives in `lib/assets/*.css` as
files, served from `packages/dart_quill/assets/…`. This is the same thing Quill
does — the published `quill.js` contains no CSS, and the consumer imports
`quill/dist/quill.snow.css` — and it brings two practical advantages:

- you can edit the theme, override rules or swap in another stylesheet without
  recompiling the library or forking it;
- a CSS constant in Dart is not removed by `dart2js` tree-shaking: it would end
  up in the JavaScript of every application, even those shipping their own
  theme.

Declare the `<link>` tags in the HTML:

```html
<link rel="stylesheet" href="packages/dart_quill/assets/quill.snow.css">
```

Or let the library insert them:

```dart
QuillAssets.injectSnowTheme();          // Snow theme <link>
QuillAssets.injectFileTheme();          // Snow + Tabler + Limitless layer
QuillAssets.injectStylesheet('my-theme', 'assets/my-quill.css');
```

Each stylesheet is inserted at most once per document (the key is the `id`
passed in).

### Limitless integration

If the application already loads Limitless's `all.min.css`, do **not** load
`quill.snow.css`: Limitless already ships the Quill theme rules. Use only the
Tabler font and the integration layer, in this order:

```html
<link rel="stylesheet" href="assets/css/ltr/all.min.css">
<link rel="stylesheet" href="packages/dart_quill/assets/icons/tabler/tabler-icons.css">
<link rel="stylesheet" href="packages/dart_quill/assets/quill.limitless.css">
```

The `quill.limitless.css` layer must come **after** the global Limitless
stylesheet.

---

## Icons

Two sets, mutually exclusive per editor instance:

```dart
ThemeOptions(
  theme: 'snow',
  iconTheme: QuillIconTheme.svg,     // default: Quill's official SVGs
);

ThemeOptions(
  theme: 'snow',
  iconTheme: QuillIconTheme.tabler,  // Tabler webfont (requires the CSS above)
);
```

Never mix the two modes in the same editor.

### The SVGs are generated, not pasted

The 72 official SVGs live in `lib/assets/icons/svg_quill/` — that is the source
of truth, versioned and comparable against upstream with a directory `diff`.
The Dart literals in `lib/src/ui/icons.dart` are produced from it:

```bash
dart run tool/gen_icons.dart          # rewrites the generated files
dart run tool/gen_icons.dart --check  # fails when they are stale (CI)
```

It is the counterpart of Quill's `scripts/babel-svg-inline-import.cjs`, which
resolves `import boldIcon from '../assets/icons/bold.svg'` at build time. An
icon is a button's `innerHTML`, not a stylesheet — that is why it is embedded
and the CSS is not. Editing `icons.dart` by hand makes
`test/unit/generated_icons_test.dart` fail.

To replace an icon: swap the `.svg`, run the generator, run the tests.

---

## Tables

There are two modules, and they are independent.

### `table` — Quill's basic module

```dart
ThemeOptions(modules: {'table': true});

final table = quill.getModule('table') as Table;
table.insertTable(3, 3);
table.insertRow(1);         // 1 = below, 0 = above
table.insertColumn(1);
table.deleteTable();
```

### `table-better` — the full plugin

Tables with colgroup, merged cells, floating menus, drag resizing and a
properties form.

```dart
import 'package:dart_quill/dart_quill.dart';
import 'package:dart_quill/dart_quill_table_better.dart';

initializeQuill();
registerTableBetter();                 // registers the 13 blots and the clipboard

final quill = Quill(
  host,                                // HtmlDomElement, as in the example above
  options: ThemeOptions(
    theme: 'snow',
    modules: {
      'toolbar': ToolbarProps(
        container: ToolbarConfig(const [
          ['bold', 'table-better']
        ]),
      ),
      'table-better': {
        'language': 'en_US',           // 16 locales available
        'toolbarTable': true,          // button with the 10×10 grid picker
        'menus': ['column', 'row', 'merge', 'table', 'cell', 'delete'],
        'toolbarButtons': {
          'whiteList': ['bold', 'italic', 'link'],
          'singleWhiteList': ['link'],
        },
      },
    },
  ),
);

final tables = quill.getModule('table-better') as TableBetter;
tables.insertTable(3, 3);
```

What is available: cell selection by dragging, floating menus
(column/row/merge/table/cell/wrap/delete/copy), header-row conversion, visual
resizing of columns and rows, a properties form with a 15-color palette **and a
color wheel**, grid-based cut/copy/paste, and the plugin's 16 languages.

---

## Syntax highlighting

Upstream requires the application to load **highlight.js** from a CDN. Here the
highlighter is part of the package (`lib/src/highlighter/`), written in Dart,
so just enable the module:

```dart
ThemeOptions(modules: {'syntax': true});
```

The 14 languages of Quill's picker come ready (plain, bash, cpp, cs, css, diff,
xml/html, java, javascript/ts, markdown, php, python, ruby, sql), and each code
block gets a language `<select>` as a UI node. The class names are
highlight.js's (`hljs-keyword`, `hljs-string`, …), so any hljs theme colors the
output — the bundled colors are in `assets/quill.syntax.css`:

```html
<link rel="stylesheet" href="packages/dart_quill/assets/quill.syntax.css">
```

For your own language, without touching the package:

```dart
import 'package:dart_quill/src/highlighter/highlighter.dart';

registerLanguage(const Language(
  name: 'dart',
  root: Mode(keywords: {'keyword': ['final', 'var', 'class']}),
));
```

And the options still accept an application-provided highlighter, which takes
precedence over the built-in one:

```dart
ThemeOptions(modules: {
  'syntax': SyntaxOptions(
    interval: const Duration(milliseconds: 500),
    // A highlighter returning a Delta…
    highlighter: (text, language) => Delta()
      ..insert('final', {'code-token': 'keyword'})
      ..insert(' x = 1;')
      ..insert('\n', {'code-block': language}),
    // …or one following the highlight.js contract, returning HTML with hljs-* classes:
    // htmlHighlighter: (text, language) => hljs.highlight(text, language),
  ),
});
```

Parity note: `code-token` stays **out** of the document Delta —
`bubbleFormats` strips it, exactly as upstream does. Highlighting is
presentation.

---

## Formulas (LaTeX)

Upstream requires **KaTeX** on `window`. Here the renderer is part of the
package (`lib/src/math/`) and produces **MathML**, which the browser draws
natively — no script, no font download and no third-party stylesheet. The
toolbar's `formula` button works with no configuration:

```dart
final quill = Quill(container, options: ThemeOptions(
  theme: 'snow',
  modules: {'toolbar': {'container': [['formula', 'code-block']]}},
));
quill.insertEmbed(0, 'formula', r'x = \frac{-b \pm \sqrt{b^2-4ac}}{2a}');
```

It covers what shows up in real text: fractions, roots, subscripts and
superscripts, `\left…\right`, sums and integrals with limits, Greek letters,
accents (`\hat`, `\vec`, `\overline`), `\text`, fonts (`\mathbb`, `\mathbf`,
…), spacing and environments (`pmatrix`, `bmatrix`, `cases`, `array`,
`aligned`).

Since the renderer is pure Dart, the same MathML comes out on the VM — useful
for exporting or testing:

```dart
import 'package:dart_quill/src/math/tex_math.dart';

texToMathML(r'e=mc^2');            // <math …><mi>e</mi>…</math>
isValidTex(r'\frac{1}');           // false
```

Invalid LaTeX does not crash the editor: the formula shows its own source in
red, like KaTeX's `throwOnError: false`.

---

## DOCX

Pure-Dart conversion (VM and web), no external dependencies:

```dart
import 'dart:io';
import 'package:dart_quill/dart_quill_docx.dart';

final delta = docxToDelta(File('input.docx').readAsBytesSync());
File('output.docx').writeAsBytesSync(deltaToDocx(delta));
```

---

## Extending the editor

The public entrypoint exports enough to create formats and modules without
touching `src/`:

```dart
import 'package:dart_quill/dart_quill.dart';

class Highlight extends InlineBlot {
  Highlight(DomElement node) : super(node);

  static const String kBlotName = 'highlight';
  static const String kTagName = 'MARK';

  static Highlight create([dynamic value]) => Highlight(
        value is DomElement
            ? value
            : domBindings.adapter.document.createElement(kTagName),
      );

  @override
  String get blotName => kBlotName;
  @override
  int get scope => Scope.INLINE_BLOT;
  @override
  Highlight clone() => Highlight(element.cloneNode(deep: false));
}

Quill.register(
  RegistryEntry(
    blotName: Highlight.kBlotName,
    scope: Scope.INLINE_BLOT,
    tagNames: const [Highlight.kTagName],
    create: Highlight.create,
  ),
  true,
);
```

A module is a class registered by name and instantiated by the theme:

```dart
class WordCount extends Module<Map<String, dynamic>> {
  WordCount(Quill quill, Map<String, dynamic> options) : super(quill, options) {
    quill.on(EmitterEvents.TEXT_CHANGE, (_, __, ___) {
      print(quill.getText().split(RegExp(r'\s+')).length);
    });
  }
}
```

Also exposed are `Quill.registerPath`, `Quill.importDefinition` and
`Quill.registeredDefinitions`, the Dart counterpart of upstream's
`Quill.import` (`import` is a reserved word in Dart).

---

## Development

```bash
dart pub get

dart analyze                          # must stay clean
dart test test/unit                   # VM suite (fake DOM)
dart test test/browser -p chrome      # browser suite (real layout)
dart run tool/gen_icons.dart --check  # are the generated files up to date?

webdev serve                          # example at http://localhost:8080
webdev build
```

The AngularDart example is in `example/ngdart/`.

### Tests

- `test/unit/` runs on the VM against a fake DOM — covers the model, Delta,
  blots, keyboard, clipboard and all the table grid logic.
- `test/browser/` runs in Chrome when the behavior depends on real layout
  (tooltip positioning, scroll into view, cell measurement).
- `test/e2e/` uses Puppeteer for the end-to-end flows.

---

## Architecture

```
lib/
  dart_quill.dart               main entrypoint
  dart_quill_table_better.dart  tables plugin
  dart_quill_docx.dart          DOCX conversion
  assets/                       CSS, webfont and SVGs (files)
    quill.snow.css
    quill.limitless.css
    icons/tabler/
    icons/svg_quill/            source of the embedded icons
    icons/svg_table_better/
  src/
    blots/                      ported parchment + document blots
    core/                       Quill, Editor, Selection, Emitter, Theme
    formats/                    bold, header, list, link, …
    modules/                    toolbar, keyboard, clipboard, history, syntax, …
    themes/                     snow, bubble
    ui/                         picker, tooltip, icons
    table_better/               plugin port (blots, UI, i18n)
    converters/                 DOCX, PDF
    dependencies/               vendored: delta, zip, xml, fonts, …
    platform/                   DOM abstraction (package:web / stub / fake)
tool/
  gen_icons.dart                SVG → Dart
```

**Assets rule:** CSS and fonts live in `lib/assets/` as files; icon SVGs are
embedded as Dart constants, because they go into a button's `innerHTML`. It is
the same split Quill's `webpack.common.cjs` makes, justified in
`doc/INVENTARIO_E_PLANO_FINALIZACAO.md` §6.

**Platform layer:** nothing outside `src/platform/` talks to the DOM directly.
That is what allows almost the entire suite to run on the VM against a fake
DOM, and what keeps `dart:html` out of the project (only `package:web` +
`dart:js_interop`).

---

## License

See `LICENSE`. The ported code preserves the copyright notices of Quill (Slab,
Jason Chen, salesforce.com) and quill-table-better.
