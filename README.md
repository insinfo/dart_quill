# dart_quill

Port em Dart puro do [Quill 2.0.3](https://quilljs.com) e do plugin
[quill-table-better 1.2.3](https://github.com/attoae/quill-table-better), para
aplicações web em Dart — com ou sem AngularDart.

Não é um *wrapper* sobre o Quill JavaScript: os blots, o parchment, o pipeline
de Delta, os módulos e os temas foram portados para Dart. A única dependência de
runtime é `web`.

> **Estado:** o port está em finalização. O núcleo (Delta, blots, teclado,
> clipboard, temas, tabelas) está funcional e coberto por testes; o
> acompanhamento detalhado de paridade contra o TypeScript está em
> [`doc/INVENTARIO_E_PLANO_FINALIZACAO.md`](doc/INVENTARIO_E_PLANO_FINALIZACAO.md).

---

## Índice

- [Instalação](#instalação)
- [Uso mínimo](#uso-mínimo)
- [Folhas de estilo](#folhas-de-estilo)
- [Ícones](#ícones)
- [Tabelas](#tabelas)
- [Realce de sintaxe](#realce-de-sintaxe)
- [DOCX](#docx)
- [Estendendo o editor](#estendendo-o-editor)
- [Desenvolvimento](#desenvolvimento)
- [Arquitetura](#arquitetura)
- [Licença](#licença)

---

## Instalação

```yaml
dependencies:
  dart_quill:
    path: ../dart_quill   # ou git:, enquanto não publicado
```

```bash
dart pub get
```

Requer SDK Dart `^3.6.0`.

---

## Uso mínimo

```dart
import 'package:web/web.dart' as web;
import 'package:dart_quill/dart_quill.dart';
import 'package:dart_quill/src/platform/html_dom.dart' show HtmlDomElement;

void main() {
  // Registra blots, formatos e módulos padrão. Chame uma vez, no boot.
  initializeQuill();

  // Carrega a folha do tema Snow (ver "Folhas de estilo" para a alternativa
  // de declarar o <link> no próprio HTML).
  QuillAssets.injectSnowTheme();

  // O editor fala com a abstração de DOM do pacote, não com package:web
  // diretamente; `HtmlDomElement` é a ponte.
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

  quill.setContents(Delta()..insert('Olá, mundo!\n'));
  print(quill.getContents().toJson());
}
```

### API principal

O contrato segue o do Quill; os mutadores devolvem o Delta aplicado.

```dart
quill.getText();                       // texto puro
quill.getContents();                   // Delta do documento
quill.setContents(Delta()..insert('texto\n'));
quill.updateContents(delta, source: EmitterSource.USER);

quill.insertText(0, 'texto', source: EmitterSource.API);
quill.deleteText(0, 5);
quill.formatText(0, 5, 'bold', true);
quill.formatLine(0, 1, 'header', 2);
quill.format('italic', true);
quill.removeFormat(0, 5);

quill.getSelection();                  // Range?
quill.setSelection(const Range(0, 5));
quill.getFormat(0, 5);                 // formatos ativos no intervalo

quill.enable();  quill.disable();      // somente leitura
quill.getSemanticHTML();

quill.on(EmitterEvents.TEXT_CHANGE, (delta, oldDelta, source) { /* … */ });
quill.on(EmitterEvents.SELECTION_CHANGE, (range, oldRange, source) { /* … */ });
```

---

## Folhas de estilo

**O CSS não é embutido no código Dart.** Ele vive em `lib/assets/*.css` como
arquivos, servidos em `packages/dart_quill/assets/…`. É o mesmo que o Quill faz
— o `quill.js` publicado não contém CSS, e o consumidor importa
`quill/dist/quill.snow.css` — e traz duas vantagens práticas:

- você edita o tema, sobrescreve regras ou troca por outra folha sem recompilar
  a biblioteca nem fazer fork;
- uma constante de CSS em Dart não é removida pelo *tree-shaking* do `dart2js`:
  ela entraria no JavaScript de toda aplicação, mesmo nas que trazem o próprio
  tema.

Declare os `<link>` no HTML:

```html
<link rel="stylesheet" href="packages/dart_quill/assets/quill.snow.css">
```

Ou deixe a biblioteca inseri-los:

```dart
QuillAssets.injectSnowTheme();          // <link> do tema Snow
QuillAssets.injectFileTheme();          // Snow + Tabler + camada Limitless
QuillAssets.injectStylesheet('meu-tema', 'assets/meu-quill.css');
```

Cada folha é inserida no máximo uma vez por documento (a chave é o `id`
passado).

### Integração com Limitless

Se a aplicação já carrega o `all.min.css` do Limitless, **não** carregue o
`quill.snow.css`: o Limitless já traz as regras do tema Quill. Use apenas o
Tabler e a camada de integração, nessa ordem:

```html
<link rel="stylesheet" href="assets/css/ltr/all.min.css">
<link rel="stylesheet" href="packages/dart_quill/assets/icons/tabler/tabler-icons.css">
<link rel="stylesheet" href="packages/dart_quill/assets/quill.limitless.css">
```

A camada `quill.limitless.css` precisa vir **depois** da folha global do
Limitless.

---

## Ícones

Dois conjuntos, mutuamente exclusivos por instância de editor:

```dart
ThemeOptions(
  theme: 'snow',
  iconTheme: QuillIconTheme.svg,     // padrão: os SVGs oficiais do Quill
);

ThemeOptions(
  theme: 'snow',
  iconTheme: QuillIconTheme.tabler,  // webfont Tabler (exige o CSS acima)
);
```

Nunca misture os dois modos no mesmo editor.

### Os SVGs são gerados, não colados

Os 72 SVGs oficiais ficam em `lib/assets/icons/svg_quill/` — essa é a fonte de
verdade, versionada e comparável com o upstream por um `diff` de diretórios. Os
literais Dart em `lib/src/ui/icons.dart` saem daí:

```bash
dart run tool/gen_icons.dart          # regrava os arquivos gerados
dart run tool/gen_icons.dart --check  # falha se estiverem defasados (CI)
```

É a contraparte do `scripts/babel-svg-inline-import.cjs` do Quill, que resolve
`import boldIcon from '../assets/icons/bold.svg'` em tempo de build. Ícone é
`innerHTML` de botão, não folha de estilo — por isso ele é embutido, e o CSS
não. Editar `icons.dart` à mão faz `test/unit/generated_icons_test.dart` falhar.

Para trocar um ícone: substitua o `.svg`, rode o gerador, rode os testes.

---

## Tabelas

Há dois módulos, e eles são independentes.

### `table` — o módulo básico do Quill

```dart
ThemeOptions(modules: {'table': true});

final table = quill.getModule('table') as Table;
table.insertTable(3, 3);
table.insertRow(1);         // 1 = abaixo, 0 = acima
table.insertColumn(1);
table.deleteTable();
```

### `table-better` — o plugin completo

Tabelas com colgroup, células mescladas, menus flutuantes, redimensionamento por
arrasto e formulário de propriedades.

```dart
import 'package:dart_quill/dart_quill.dart';
import 'package:dart_quill/dart_quill_table_better.dart';

initializeQuill();
registerTableBetter();                 // registra os 13 blots e o clipboard

final quill = Quill(
  host,                                // HtmlDomElement, como no exemplo acima
  options: ThemeOptions(
    theme: 'snow',
    modules: {
      'toolbar': ToolbarProps(
        container: ToolbarConfig(const [
          ['bold', 'table-better']
        ]),
      ),
      'table-better': {
        'language': 'pt_BR',           // 16 locales disponíveis
        'toolbarTable': true,          // botão com o seletor 10×10
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

O que está disponível: seleção de células por arrasto, menus flutuantes
(coluna/linha/mesclar/tabela/célula/quebra/excluir/copiar), conversão de linha
de cabeçalho, redimensionamento visual de colunas e linhas, formulário de
propriedades com paleta de 15 cores **e roda de cor**, recortar/copiar/colar por
grade, e os 16 idiomas do plugin.

---

## Realce de sintaxe

O upstream exige que a aplicação carregue o **highlight.js** de um CDN. Aqui o
realçador é parte do pacote (`lib/src/highlighter/`), escrito em
Dart, então basta ligar o módulo:

```dart
ThemeOptions(modules: {'syntax': true});
```

As 14 linguagens do seletor do Quill vêm prontas (plain, bash, cpp, cs, css,
diff, xml/html, java, javascript/ts, markdown, php, python, ruby, sql), e cada
bloco de código ganha um `<select>` de linguagem como nó de UI. Os nomes de
classe são os do highlight.js (`hljs-keyword`, `hljs-string`, …), então
qualquer tema hljs colore o resultado — as cores empacotadas estão em
`assets/quill.syntax.css`:

```html
<link rel="stylesheet" href="packages/dart_quill/assets/quill.syntax.css">
```

Para uma linguagem própria, sem tocar no pacote:

```dart
import 'package:dart_quill/src/highlighter/highlighter.dart';

registerLanguage(const Language(
  name: 'dart',
  root: Mode(keywords: {'keyword': ['final', 'var', 'class']}),
));
```

E as opções continuam aceitando um realçador da aplicação, que tem precedência
sobre o embutido:

```dart
ThemeOptions(modules: {
  'syntax': SyntaxOptions(
    interval: const Duration(milliseconds: 500),
    // Um highlighter que devolve Delta…
    highlighter: (text, language) => Delta()
      ..insert('final', {'code-token': 'keyword'})
      ..insert(' x = 1;')
      ..insert('\n', {'code-block': language}),
    // …ou um no contrato do highlight.js, devolvendo HTML com classes hljs-*:
    // htmlHighlighter: (text, language) => hljs.highlight(text, language),
  ),
});
```

Nota de paridade: `code-token` fica **fora** do Delta do documento — o
`bubbleFormats` o remove, exatamente como no upstream. O realce é apresentação.

---

## Fórmulas (LaTeX)

O upstream exige o **KaTeX** em `window`. Aqui o renderizador é parte do pacote
(`lib/src/math/`) e produz **MathML**, que o navegador desenha
nativamente — sem script, sem fonte para baixar e sem folha de estilo de
terceiros. O botão `formula` da toolbar funciona sem configuração:

```dart
final quill = Quill(container, options: ThemeOptions(
  theme: 'snow',
  modules: {'toolbar': {'container': [['formula', 'code-block']]}},
));
quill.insertEmbed(0, 'formula', r'x = \frac{-b \pm \sqrt{b^2-4ac}}{2a}');
```

Cobre o que aparece em texto real: frações, raízes, índices e expoentes,
`\left…\right`, somatórios e integrais com limites, gregas, acentos
(`\hat`, `\vec`, `\overline`), `\text`, fontes (`\mathbb`, `\mathbf`, …),
espaçamentos e ambientes (`pmatrix`, `bmatrix`, `cases`, `array`, `aligned`).

Como o renderizador é Dart puro, o mesmo MathML sai na VM — útil para exportar
ou testar:

```dart
import 'package:dart_quill/src/math/tex_math.dart';

texToMathML(r'e=mc^2');            // <math …><mi>e</mi>…</math>
isValidTex(r'\frac{1}');           // false
```

LaTeX inválido não derruba o editor: a fórmula mostra o próprio código-fonte em
vermelho, como o `throwOnError: false` do KaTeX.

---

## DOCX

Conversão em Dart puro (VM e web), sem dependências externas:

```dart
import 'dart:io';
import 'package:dart_quill/dart_quill_docx.dart';

final delta = docxToDelta(File('entrada.docx').readAsBytesSync());
File('saida.docx').writeAsBytesSync(deltaToDocx(delta));
```

---

## Estendendo o editor

O entrypoint público exporta o suficiente para criar formatos e módulos sem
tocar em `src/`:

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

Um módulo é uma classe registrada por nome e instanciada pelo tema:

```dart
class WordCount extends Module<Map<String, dynamic>> {
  WordCount(Quill quill, Map<String, dynamic> options) : super(quill, options) {
    quill.on(EmitterEvents.TEXT_CHANGE, (_, __, ___) {
      print(quill.getText().split(RegExp(r'\s+')).length);
    });
  }
}
```

Também estão expostos `Quill.registerPath`, `Quill.importDefinition` e
`Quill.registeredDefinitions`, a contraparte Dart do `Quill.import` do upstream
(`import` é palavra reservada em Dart).

---

## Desenvolvimento

```bash
dart pub get

dart analyze                          # deve ficar limpo
dart test test/unit                   # suíte VM (DOM falso)
dart test test/browser -p chrome      # suíte de navegador (layout real)
dart run tool/gen_icons.dart --check  # os arquivos gerados estão em dia?

webdev serve                          # exemplo em http://localhost:8080
webdev build
```

O exemplo AngularDart está em `example/ngdart/`.

### Testes

- `test/unit/` roda na VM contra um DOM falso — cobre modelo, Delta, blots,
  teclado, clipboard e toda a lógica de grade das tabelas.
- `test/browser/` roda em Chrome quando o comportamento depende de layout real
  (posicionamento de tooltip, *scroll into view*, medição de células).
- `test/e2e/` usa Puppeteer para os fluxos de ponta a ponta.

---

## Arquitetura

```
lib/
  dart_quill.dart               entrypoint principal
  dart_quill_table_better.dart  plugin de tabelas
  dart_quill_docx.dart          conversão DOCX
  assets/                       CSS, webfont e SVGs (arquivos)
    quill.snow.css
    quill.limitless.css
    icons/tabler/
    icons/svg_quill/            fonte dos ícones embutidos
    icons/svg_table_better/
  src/
    blots/                      parchment portado + blots do documento
    core/                       Quill, Editor, Selection, Emitter, Theme
    formats/                    negrito, cabeçalho, lista, link, …
    modules/                    toolbar, keyboard, clipboard, history, syntax, …
    themes/                     snow, bubble
    ui/                         picker, tooltip, ícones
    table_better/               port do plugin (blots, UI, i18n)
    converters/                 DOCX, PDF
    dependencies/               vendorizado: delta, zip, xml, fontes, …
    platform/                   abstração de DOM (package:web / stub / fake)
tool/
  gen_icons.dart                SVG → Dart
```

**Regra de assets:** CSS e fontes ficam em `lib/assets/` como arquivos; SVG de
ícone é embutido como constante Dart, porque vai para o `innerHTML` de um botão.
É a mesma divisão que o `webpack.common.cjs` do Quill faz, e está justificada em
`doc/INVENTARIO_E_PLANO_FINALIZACAO.md` §6.

**Camada de plataforma:** nada fora de `src/platform/` fala com o DOM
diretamente. É o que permite rodar quase toda a suíte na VM, contra um DOM
falso, e o que mantém o `dart:html` fora do projeto (só `package:web` +
`dart:js_interop`).

---

## Licença

Consulte `LICENSE`. O código portado preserva os avisos de copyright do Quill
(Slab, Jason Chen, salesforce.com) e do quill-table-better.
