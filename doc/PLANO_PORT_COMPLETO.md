# Plano Detalhado — Conclusão do Port Quill 2.0.3 + quill-table-better para Dart Puro

**Data:** 2026-07-11
**Objetivo:** Editor rich-text completo em Dart puro, dependendo **somente de `web: ^1.1.1`**, embarcável em qualquer app Dart Web (puro ou ngdart ^8.0.0-dev.4), capaz de **abrir DOCX**, **exportar DOCX** e **exportar PDF**, **exportar e importar delta**, **exportar e importar HTML**.

referencias https://github.com/quilljs/awesome-quill
tem que usar os icones do C:\MyDartProjects\dart_quill\lib\assets\icons\tabler de invetar outros icones malucos
ser compativel com C:\MyDartProjects\dart_quill\example\ngdart\web\assets\css\ltr\all.min.css para não ter conflitos
C:\MyDartProjects\dart_quill\referencias

---

## 1. Estado Atual (auditoria de 2026-07-11)

### 1.1 Núcleo Quill (lib/src) — paridade com quilljs 2.0.3

Fonte TS de referência: `C:\MyDartProjects\new_sali\frontend\web\assets\js\quill\2.0.3\src\packages\quill\src`
(também em `C:\MyDartProjects\dart_quill\referencias\quill\2.0.3\src`).

| Área | Estado | Lacunas |
|---|---|---|
| core/ (editor, emitter, quill, theme, composition…) | ~95% | `selection.dart` reduzido a modelo em memória; mapeamento índice→DOM reescrito em `quill.dart:_domPosition` de forma **não fiel** ao original (`selection.ts rangeToNative` + `LeafBlot.position`) |
| blots/ (parchment embutido em `blots/abstract/blot.dart`) | ~90% | **`LeafBlot.position(index, inclusive)` não existe**; caminhos `insertInto`/`insertAt` com `UnsupportedError` (blot.dart:243, 640) |
| blots/block.dart | ~80% | **`Block.format` retorna cedo para `Scope.BLOCK_ATTRIBUTE`** (block.dart:117-122) → align/list/indent/direction/header **não aplicam** |
| formats/ | ~95% | fórmulas (KaTeX) apenas stub; formatos de bloco inertes pela lacuna acima |
| modules/ | ~90% | `syntax` sem seletor de língua/highlight incremental; `keyboard.handleEnter` reescrito e **bugado** |
| themes/ + ui/ | ~85% | `icons.dart`, `color-picker.dart`, `icon-picker.dart` com placeholders; SVGs não migrados |
| assets | 0% | `.styl` não convertidos; `web/quill.snow.css` é cópia manual |
| platform/ | funcional | **usa `dart:html` (deprecated)** — precisa migrar para `package:web` + `dart:js_interop` |

### 1.2 Bug ativo do Enter (commit e1c24d1)

Sintoma: 1º Enter deixa cursor no início da linha; Enters seguintes "grudam" na 2ª linha.

Causas identificadas (nesta ordem de importância):

1. **`Quill._domPosition` (quill.dart:302-328)** substitui `Selection.rangeToNative` do TS mas ignora a semântica `inclusive`: o TS usa `inclusive=false` para o INÍCIO do range e `true` para o FIM (`selection.ts:341-356`). O Dart usa efetivamente `inclusive=true` para ambos e caminha `entries` de trás pra frente, resolvendo o índice pós-`\n` no **leaf final da linha anterior** em vez do leaf inicial da nova linha — exatamente o sintoma relatado.
2. **`LeafBlot.position` não foi portado** — o parchment original resolve linha vazia (`<br>`) retornando `(elementoPai, offsetDoFilho)`; o Dart retorna `(<br>, 0)`, que é não confiável para `setStart`.
3. **Aplicação dupla do caret**: `handleEnter` → `insertText` (que já faz `setSelection(index+1, USER)`) → `focus()` que **recalcula e reaplica** o caret via `_domPosition`. O TS usa `setSelection(index+1, SILENT)` + `focus()` sem recomputação.
4. Falta o clamp `min(scrollLength - 1, index)`.

### 1.3 Testes

- `dart test`: **108 passando / 38 falhando** (após correção de compilação de 2026-07-11 — quiver removido, diff_match_patch vendorizado).
- Falhas concentradas em: `block_test`, `block_embed_test`, `inline_test`, `scroll_index_test`, `bold_test` (optimize), `history_test`, `table_test`. Sintoma típico: `<p><br></p>` **extra** ao inserir newlines → off-by-one em `Block/Scroll.insertAt` — mesma família de causa do bug do Enter (camada blot, não DOM).
- Sem testes para `core/selection`, `core/editor`, maioria de `formats/*`; sem e2e/fuzz.

### 1.4 Dependências

- `pubspec.yaml`: apenas `web: ^1.1.1` (runtime). `quiver` **removido** (Object.hash), `diff_match_patch` **vendorizado** em `lib/src/dependencies/diff_match_patch/` (cópia pura-Dart de new_sali/core).
- Ainda importados mas não declarados (resolvem via transitividade de dev_deps): `package:collection` (9 arquivos — DeepCollectionEquality) → **vendorizar helpers de igualdade** (item F0.2).
- `lib/src/app/*.dart` (componentes Angular) importam `ngdart` não declarado → mover para `example/ngdart/` (item F0.3).

---

## 2. Recursos Disponíveis para DOCX/PDF (auditados)

| Recurso | O que é | Pureza | Papel no plano |
|---|---|---|---|
| **`C:\MyDartProjects\canvas-editor-port`** (`canvas_text_editor` v2) | Editor DOCX canvas; exporta `ce_docx` (DocxReader/DocxWriter/DocxValidator/FormatResolver), `ce_pdf` (PdfWriter + RasterPdfEncoder), `ce_opc`, `ce_zip` (deflate/inflate/crc32 próprios), `ce_xml`, `ce_fonts` (parser TTF + métricas), e **conversores `word/docx_to_element.dart`, `element_to_docx.dart`, `quill_delta.dart`** (DOCX↔modelo↔Delta, com passthrough byte-a-byte de blocos não editados) | **Dart puro, única dep `web: ^1.1.1`** | **Backbone de DOCX import/export e PDF export** |
| **`C:\MyDartProjects\docx_rendering`** | Port Dart do docx-preview (docxjs): OPC completo, parser (estilos, numeração, tabelas, VML, notas), renderer DOCX→HTML/DOM, paginação | Dart puro + `web ^1.1.1` | Visualização de alta fidelidade e **caminho alternativo de import** (DOCX→HTML→Delta) |
| **`C:\MyDartProjects\xlsx_editor`** | Editor XLSX; mesma pilha zip/xml pura | `web ^1.1.1` | Referência da pilha OPC (já duplicada nos dois acima) |
| `new_sali/core/lib/dependencies/delta_from_html` | HTML→Delta | dep `package:html` | Import via HTML (colar Word, caminho docx_rendering) |
| `new_sali/core/lib/dependencies/delta_html` | Delta→HTML | **Dart puro (zero deps)** | Export HTML / preview / base para export DOCX |
| `new_sali/core/lib/dependencies/quill_to_pdf` + `delta_to_pdf` | Delta→PDF sobre `pdf_plus` | dep `pdf_plus` (muitas deps transitivas) | **Referência de layout**; não usar como dep (viola regra "só web") |
| `new_sali/core/lib/dependencies/highlight` | Syntax highlight puro | Dart puro | Vendorizar para o módulo `syntax` |
| `referencias/quill_custom_plugins` | `sali_word_paste.js` (normalizador Word 434 l.), `sali_fonts.js`, `sali_page_setup.js`, `pmro_sali_header.js` | JS | Portar como módulos opcionais |
| `D:\EuroOfficeNative\DocumentServer` | OnlyOffice (C++/JS): X2tConverter, HtmlFile2, sdkjs/word | C++/JS | **Somente referência** de semântica de conversão DOCX↔HTML |

**Decisão de arquitetura DOCX/PDF:** usar a pilha do `canvas-editor-port` (ce_zip/ce_xml/ce_opc/ce_fonts/ce_pdf/ce_docx + ponte Delta) vendorizada em `lib/src/dependencies/`, pois é a única que satisfaz "somente `web: ^1.1.1`" e já tem conversores Delta prontos. `docx_rendering` entra como segundo caminho de import (fidelidade visual) se necessário.

---

## 3. Arquitetura Alvo

```
dart_quill/
  lib/
    dart_quill.dart              # API pública (Quill, Delta, Range, registro de formatos/módulos)
    dart_quill_table_better.dart # módulo opcional de tabelas avançadas
    dart_quill_docx.dart         # import/export DOCX
    dart_quill_pdf.dart          # export PDF
    src/
      platform/                  # ÚNICA fronteira com o navegador → package:web + js_interop
      blots/  core/  formats/  modules/  themes/  ui/
      table_better/              # port do quill-table-better 1.2.3
        formats/  modules/  ui/  language/  utils/  config/
      converters/
        docx_import/             # DOCX → Delta
        docx_export/             # Delta → DOCX
        pdf_export/              # Delta → PDF
        html/                    # Delta ↔ HTML (vendor delta_html / delta_from_html adaptado)
      dependencies/              # tudo vendorizado, zero deps externas
        dart_quill_delta/  quill_delta_easy_parser/  diff_match_patch/
        collection_utils/        # substitui package:collection (equality/hash)
        ce_zip/ ce_xml/ ce_opc/ ce_fonts/ ce_pdf/ ce_docx/   # do canvas-editor-port
        highlight/               # syntax
      assets/
        css.dart                 # quill.snow.css, quill.bubble.css, table-better.css como const String
        icons.dart               # SVGs como const String
  example/
    plain/                       # dart web puro (atual web/)
    ngdart/                      # componente Angular (atual lib/src/app)
  test/  (unit + integração dart test -p chrome)
```

Regras:
- **Nenhum `dart:html`** — só `package:web`/`dart:js_interop`, e apenas dentro de `src/platform/` e dos renderers.
- **Nenhuma dependência runtime além de `web`** — tudo vendorizado em `src/dependencies/`.
- CSS/SVG embutidos como strings Dart com injeção opcional (`QuillAssets.injectSnowTheme()`), para o consumidor não precisar de arquivos estáticos.

---

## 4. Fases de Implementação

### F0 — Saneamento da base (pré-requisito, ~1 dia)
- [x] F0.1 Remover `quiver` (→ `Object.hash*`) e vendorizar `diff_match_patch`. *(feito em 2026-07-11)*
- [ ] F0.2 Vendorizar utilidades de `package:collection` usadas (DeepCollectionEquality etc.) em `src/dependencies/collection_utils/` e trocar os 9 imports.
- [x] F0.3 `lib/src/app/*` (Angular) movido para `example/ngdart/` e excluído da análise. *(feito em 2026-07-11; `web/`→`example/plain/` ainda pendente)*
- [x] F0.4 `dart analyze` limpo. *(feito em 2026-07-11)*

### F1 — Fidelidade do núcleo: Enter + 38 testes (crítico) ✅ CONCLUÍDO 2026-07-11
- [x] F1.1 `LeafBlot.position(index, inclusive)` + `TextBlot.position` portados do parchment.
- [x] F1.2 `_domPosition` reescrito fiel a `rangeToNative` (inclusive start=false/end=true, clamp `scrollLength-1`, via `scroll.leaf` + `position`); `Block.path` com `inclusive:true` (block.ts:102); condição inclusive de `ParentBlot.path` alinhada ao `LinkedList.find` do parchment.
- [x] F1.3 `handleEnter` paritário: delta único + `setSelection(index+1, SILENT)` + `focus()`; deslocamento de seleção estilo `modify()`/`shiftRange` (`shiftRangeByDelta`/`shiftRangeByLength` em selection.dart) aplicado em insertText/deleteText/insertEmbed/updateContents/formatText.
- [x] F1.4 Causa raiz dos testes: hidratação dupla do DOM inicial — `Scroll.build()` adicionado ao construtor (paridade com `ParentBlot.build` do parchment); `setContents` agora remove a linha final extra (paridade quill.ts).
- [x] F1.5 Atributos de bloco habilitados: `AttributorStore` portado (store.ts), `Registry.registerAttributor`/`queryAttributor` (lookup por attrName E keyName), `Block.format/formats/formatAt/_replaceWithBlock` com attributors; align/indent/direction/color/background/font/size registrados por padrão; `Quill.formatLine` + `Editor.formatLine` fiéis; `Scroll.getFormat` fiel a `Editor.getFormat` (combineFormats + `descendantsAt`).
- [x] F1.6 Suíte: 152 testes VM verdes (inclui novos `block_attributors_test.dart`); 3 testes browser de Enter em Chrome (`test/browser/enter_key_test.dart`) verdes.
- [ ] F1.7 Teste manual no navegador com o demo (`dart run build_runner serve`) — pendente de sessão interativa.
- [x] F1.8 Formatação multilinha/toolbar corrigida (2026-07-11): `Quill.format` distingue blots e attributors de bloco; seleção salva sobrevive ao clique; align/list cobrem todas as linhas; `removeFormat` remove formatos inline e de bloco; limpeza de listas gera parágrafos válidos. Regressões cobertas na suíte.

### F2 — Migração `dart:html` → `package:web` ✅ CONCLUÍDO 2026-07-11
- [x] F2.1 `platform/html_dom.dart` reescrito com `package:web` 1.1.1 + `dart:js_interop`. Sem mudanças nas interfaces de `dom.dart`. Adições internas: `HtmlRawEventProxy`/`HtmlRawEventTargetProxy` (acesso dinâmico a rawEvent), `HtmlDomCssStyle` (wrapper de CSSStyleDeclaration), `_HtmlDomDatasetMap` (mapa vivo sobre data-*), sanitizador de HTML próprio (substitui NodeValidator do dart:html).
- [x] F2.2 `web/main.dart` migrado (comentário Angular preservado); demo ganhou botões Abrir/Exportar DOCX.
- [x] F2.3 Suíte VM + browser verdes pós-migração; smoke test em Chrome com toolbar/ícones/pickers OK.

### F3 — Assets e UI (~2 dias)
- [ ] F3.1 Converter `assets/*.styl` do Quill (snow, bubble, core) para CSS definitivo; embutir em `src/assets/css.dart`; manter arquivos `.css` gerados em `example/` p/ referência.
- [ ] F3.2 Migrar todos os SVGs de `quilljs/src/assets/icons` para `src/assets/icons.dart`; completar `ui/icons.dart`, `color-picker`, `icon-picker` (remover placeholders).
- [ ] F3.3 API `QuillAssets.inject()` (cria `<style>` via platform layer).

### F4 — Syntax completo (~1-2 dias, opcional/paralelizável)
- [ ] F4.1 Vendorizar `highlight` (de new_sali/core/dependencies) em `src/dependencies/highlight/`.
- [ ] F4.2 Completar `modules/syntax.dart`: seletor de linguagem (picker), re-highlight incremental com tokens aplicados no DOM, paridade com `syntax.spec.ts`.

### F5 — Port quill-table-better 1.2.3 (~2-3 semanas, maior bloco)
Fonte: `referencias/quill_table_better/1.2.3/src/src` (~6.436 linhas TS em 15 arquivos).
Ordem de port (dependências primeiro):

**Estado em 2026-07-11:** o módulo básico `modules/table.dart` está funcional e habilitado por padrão. A toolbar Snow e os demos usam um único botão com dropdown em grade 10×10, realce progressivo e rótulo linhas×colunas, portado de `ui/toolbar-table.ts`. Ao entrar numa célula surge uma mini-toolbar contextual com inserir linha acima/abaixo, inserir coluna à esquerda/direita e excluir linha/coluna/tabela, usando títulos e ícones Tabler locais. Do table-better já existem formatos estruturais, config, utils, idiomas en_US/pt_BR e 38 testes. Seleção multicélula, merge/split, propriedades e redimensionamento visual ainda não estão concluídos.

- [ ] F5.1 `utils/index.ts` (447 l.) + `config/index.ts` (437 l.) → `table_better/utils/`, `table_better/config/`.
- [ ] F5.2 `formats/table.ts` (902 l.) → 12 blots: TableCellBlock/TableThBlock/TableCell/TableTh/TableRow/TableThRow/TableBody/TableThead/TableCol/TableColgroup/TableTemporary/TableContainer (+ `cellId`/`tableId`). Atenção: `TableTemporary` roundtrip de atributos da `<table>` via `optimize()`.
- [ ] F5.3 `formats/header.ts` (78 l.) e `formats/list.ts` (159 l.) → header/list dentro de célula.
- [ ] F5.4 `quill-table-better.ts` (446 l.) → módulo `TableBetter` (registro, keyboard bindings `makeTableArrowHandler`/`makeCellBlockHandler`/etc., insertTable/deleteTable/getTable, listenDeleteTable).
- [ ] F5.5 `utils/clipboard-matchers.ts` (110 l.) + `modules/clipboard.ts` (61 l.) → matchers `td,th`/`tr`/`col`/`table` e `TableClipboard.getTableDelta`.
- [ ] F5.6 `ui/cell-selection.ts` (811 l.) → seleção multi-célula, copy/cut/paste de células, navegação por setas, WHITE_LIST. Incluir patch SALI (null-guard em `onCapturePaste`).
- [ ] F5.7 `ui/operate-line.ts` (463 l.) → redimensionamento de colunas/linhas/tabela. Incluir patch SALI (`quill.update(USER)` no mouseup).
- [ ] F5.8 `ui/table-menus.ts` (1059 l.) → **parcial:** mini-toolbar contextual entregue para inserir/apagar linha/coluna/tabela; ainda faltam merge/split, header row, copiar tabela e menus de propriedades completos.
- [ ] F5.9 `ui/table-properties-form.ts` (791 l.) → diálogo de propriedades. **Substituir `@jaames/iro`** por color-picker próprio simples (paleta 15 cores + input hex + roda opcional canvas) — sem dep JS.
- [ ] F5.10 `ui/toolbar-table.ts` (133 l.) + `modules/toolbar.ts` (283 l.) → **grid 10×10 e dropdown entregues**; ainda falta roteamento de formatos para seleção multicélula, dependente de F5.6.
- [ ] F5.11 `language/` → i18n com pt_BR/en_US primeiro (16 locales no total, ~60 chaves).
- [ ] F5.12 CSS (847 l.) + 21 SVGs → `src/assets/` (strings Dart).
- [ ] F5.13 Testes: port dos cenários da suíte JS do plugin + testes de Delta roundtrip de tabela.

**Testes portados/adicionados em 2026-07-11:** a árvore `referencias/quilljs/test` foi incluída como fonte normativa para testes core/unit/e2e (table, toolbar, clipboard, history e fuzz). O repositório do table-better não distribui testes equivalentes junto de `src`; foram criados testes unitários Dart e E2E Puppeteer para o seletor 10×10, inserção dimensional, toolbar contextual, ícones Tabler e isolamento contra CSS Limitless. O E2E gera o bundle com Webdev e o serve em porta efêmera com Shelf. Estado verificado: 203 testes unitários + 2 E2E passando.

### F5A — Manipulação de imagens estilo Word (pendente, ~1-2 semanas)
- [x] F5A.1 Base de atributos Delta/DOM entregue (2026-07-11): largura, altura, `data-image-wrap`, tipo de âncora e campos X/Y reconhecidos pelo blot. Modos avançados `square`, `tight`, `behind` e `in-front` ainda pendentes.
- [x] F5A.2 Primeira versão de `ImageResize` entregue: overlay, oito alças, tamanho mínimo, proporção preservada nos cantos e controles inline/esquerda/centro/direita. Controles usam exclusivamente o webfont Tabler vendorizado em `lib/assets/icons/tabler`. Teclado e limites avançados ainda pendentes.
- [ ] F5A.3 Implementar arraste/ancoragem e reposicionamento responsivo sem gravar coordenadas transitórias do viewport no Delta.
- [ ] F5A.4 Integrar undo/redo e clipboard; a toolbar flutuante e títulos/ARIA básicos foram entregues, mas context menu e operação completa por teclado seguem pendentes.
- [ ] F5A.5 Mapear imagens inline/flutuantes para DrawingML no DOCX e para o layout do PDF; hoje o import DOCX reduz imagem flutuante a inline.
- [ ] F5A.6 Testes browser de resize/drag e roundtrip Delta↔DOCX. Há 3 testes VM do módulo; validação visual manual foi realizada no demo Angular, mas a suíte Chrome automatizada ficou sem resposta nesta sessão.

### F6 — Plugins SALI opcionais (~2-3 dias)
- [ ] F6.1 `sali_word_paste.js` (434 l.) → normalizador extra em `modules/normalize_external_html/normalizers/ms_word_sali.dart` (listas numeradas, bullets, bold por classe).
- [ ] F6.2 `sali_fonts.js` → attributor de fonte com whitelist (inter/arial/calibri).
- [ ] F6.3 `sali_page_setup.js` → attributors `page-orientation`/`page-margin` (alimentam export PDF/DOCX).
- [ ] F6.4 `pmro_sali_header.js` → `HeaderImageBlot` (BlockEmbed não editável).

### F7 — Import DOCX (~1-2 semanas) — núcleo entregue em 2026-07-11
- [x] F7.1 Vendorizado (61 arquivos) em `src/dependencies/canvas_editor/`: document/{zip,xml,opc,docx}, editor/{dataset,interface} (fechamento transitivo), word/ (docx_to_element, element_to_docx, quill_delta). Zero deps pub novas.
- [x] F7.2 `converters/docx/docx_codec.dart`: `docxToDelta(Uint8List)` com normalização separador→terminador de linha (roundtrip idempotente). Limitações atuais: numeração DOCX vira texto literal no import; alinhamento do 1º parágrafo não recuperado.
- [x] F7.3 API pública em `lib/dart_quill_docx.dart`; demo `web/main.dart` com botão "Abrir DOCX" (input file + FileReader).
- [ ] F7.4 Caminho alternativo via `docx_rendering` → HTML → Delta (avaliar fidelidade com documentos reais).
- [ ] F7.5 Testes com fixtures .docx reais (Word, LibreOffice, Google Docs) + suporte real a `w:numPr`→list.

### F8 — Export DOCX — núcleo entregue em 2026-07-11
- [x] F8.1/F8.2 `deltaToDocx(Delta)` via QuillDeltaConverter.fromDelta + EditorToDocx/DocxWriter; botão "Exportar DOCX" no demo (Blob + anchor). 7 testes de roundtrip passando.
- [ ] F8.3 Listas como numeração WordprocessingML real (hoje: marcadores literais); page setup; validação no Word/LibreOffice reais.

### F8 — Export DOCX (~1 semana)
- [ ] F8.1 Adaptar `element_to_docx.dart`/`DocxWriter` → `converters/docx_export/delta_to_docx.dart`: Delta → docx (estilos, numbering.xml para listas, tabelas com tblGrid/gridSpan/vMerge, imagens, page setup do F6.3).
- [ ] F8.2 API: `quill.exportDocx() → Uint8List` + download helper (`Blob` + anchor na platform layer).
- [ ] F8.3 Roundtrip test: import→export→import preserva Delta (nos formatos suportados).

### F9 — Export PDF (~1 semana)
- [ ] F9.1 Vendorizar `ce_pdf` + `ce_fonts` (PdfWriter, métricas TTF, fontes core embutidas).
- [ ] F9.2 `converters/pdf_export/delta_to_pdf.dart`: layout de linhas (quebra por métrica de fonte), headers, listas, tabelas (larguras do colgroup), imagens, cores, alinhamento, margens/orientação do page setup. Usar `quill_to_pdf` (new_sali) **como referência de layout**, não como dependência.
- [ ] F9.3 API: `quill.exportPdf() → Uint8List` + download helper.
- [ ] F9.4 Validar visualmente contra o export atual do SALI (delta_to_pdf/pdf_plus).

### F10 — Empacotamento, exemplos e QA final (~3-5 dias)
- [ ] F10.1 API pública: `dart_quill.dart` exportando Quill/Delta/Range/registry; `Quill.register`/`Quill.import` paritários; docs dartdoc.
- [ ] F10.2 `example/plain/` (dart web puro) e `example/ngdart/` (componente `<quill-editor>` com @Input/@Output) compilando com ngdart 8.0.0-dev.4.
- [ ] F10.3 Suíte completa verde em VM (fake DOM) e `-p chrome`; smoke e2e manual: digitar, formatar, tabela completa, abrir .docx, exportar .docx/.pdf.
- [ ] F10.4 Atualizar roteiro.md/README; publicar CSS/exemplos.

---

## 5. Ordem de Execução e Estimativa

| Fase | Duração estimada | Dependências |
|---|---|---|
| F0 saneamento | 1 dia | — |
| F1 núcleo/Enter | 3-5 dias | F0 |
| F2 package:web | 2-3 dias | F1 (para não migrar código quebrado) |
| F3 assets | 2 dias | F2 |
| F4 syntax | 1-2 dias | F1 (paralelo a F3) |
| F5 table-better | 2-3 semanas | F1-F3 |
| F6 plugins SALI | 2-3 dias | F1 (paralelo a F5) |
| F7 import DOCX | 1-2 semanas | F5 (tabelas) |
| F8 export DOCX | 1 semana | F7 |
| F9 export PDF | 1 semana | F7 (modelo comum) |
| F10 empacotamento | 3-5 dias | tudo |
| **Total** | **~8-11 semanas** de trabalho focado | |

## 6. Riscos e Mitigações

1. **Divergência do parchment embutido** — o port não separa parchment; qualquer correção deve comparar com `parchment` upstream (github quilljs/parchment v3), não só com `quill/src`. Mitigação: F1 porta `LeafBlot.position`/`insertInto` direto do parchment.
2. **`document.execCommand`/beforeinput cross-browser** — testar Chrome/Firefox; a camada Input já trata `beforeinput`.
3. **Fidelidade DOCX** — Word real usa recursos além do modelo Delta (seções, campos, notas). Estratégia: mapear o que o Delta representa; preservar o resto via passthrough do ce_docx quando em modo "editar documento existente"; documentar limitações.
4. **Fontes no PDF** — métricas TTF necessárias para quebra de linha correta; `ce_fonts` já parseia TTF; embutir Inter/Arial-metric-compatible ou carregar fontes do app.
5. **Tamanho do bundle** — CSS/SVG/fontes embutidos aumentam o JS; usar `const String` (tree-shakeable por import separado: `dart_quill_pdf.dart` só puxa ce_pdf se importado).
6. **ngdart dev** — manter Angular só em `example/` evita acoplar a lib a uma versão dev.

## 7. Critérios de Aceite

- `dart analyze` limpo; `dart test` 100% verde (VM e chrome).
- pubspec com **única** dependência runtime `web: ^1.1.1`.
- Demo plain-Dart: digitação estável (Enter/backspace/undo), toolbar completa com ícones, listas/align/indent funcionando, tabela better completa (inserir, merge, resize, propriedades, copy/paste).
- Abrir .docx gerado pelo Word com texto, formatação, listas, tabela e imagem → conteúdo fiel no editor.
- Exportar .docx que abre no Word/LibreOffice sem reparo.
- Exportar .pdf visualmente equivalente ao documento.
- Exemplo ngdart compilando e funcional.
