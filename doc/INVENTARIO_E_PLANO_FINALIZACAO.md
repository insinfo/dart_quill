# Inventário de Paridade e Plano de Finalização do Port — Quill 2.0.3 + quill-table-better 1.2.3 → Dart

**Data:** 2026-07-28
**Método:** comparação arquivo-a-arquivo e método-a-método entre `referencias/quilljs/src`, `referencias/quill_table_better/1.2.3/src/src` (+ parchment em `referencias/quill_table_better/1.2.3/src/node_modules/parchment/src`) e `lib/`.
**Baseline de testes:** 309 unitários VM + 13 browser/Chrome + 3 E2E (Puppeteer) verdes; `dart analyze` limpo.
**Complementa:** `doc/PLANO_PORT_COMPLETO.md` (fases F0–F10; F0–F2 concluídas, F7/F8 núcleo entregue). Este documento substitui o detalhamento de lacunas daquele plano.

---

## 0. Sumário executivo

A cobertura em **nível de arquivo** é ~1:1 (todo arquivo TS tem contraparte Dart, exceto `ui/table-menus.ts` e `ui/toolbar-table.ts` do table-better). A lacuna real está **dentro** dos arquivos, em três camadas:

1. **Parchment (blots/abstract)** — o port reescreveu o parchment de forma simplificada. Faltam as primitivas `wrap/isolate/replaceWith/attach/detach/update`, a reconciliação DOM→modelo (`ParentBlot.update`, `TextBlot.update`, `ScrollBlot.update`), a convergência iterativa do `optimize`, `enforceAllowedChildren`/`requiredContainer` genéricos, `Cursor` funcional e `Embed` com guards. É a causa-raiz de dezenas de divergências à jusante.
2. **Core/Modules** — `Keyboard.DEFAULTS` está **vazio** (26 bindings default do Quill ausentes), `Selection` não tem camada nativa (focus/format/getBounds), `Editor` não tem `applyDelta`/`getHTML`/`getFormat`, `Quill.modify()` não existe (readOnly/SILENT quebrados), `Emitter.emit` trunca argumentos nulos, `Syntax` nunca aplica o realce, `Uploader` está inerte.
3. **table-better** — a camada de **modelo** está bem portada (13 blots, config, utils, matchers, bindings); a camada de **interação** (~2.400 linhas TS) não: `table-menus.ts` (1.059 l.) e `toolbar-table.ts` inexistem, `cell-selection`/`operate-line`/`properties-form` estão reduzidos a modelos lógicos sem DOM, e o seletor 10×10 atual insere a tabela do módulo **básico**, não a do table-better.

---

## 1. Inventário — Parchment / Blots (`lib/src/blots/`)

### 1.1 Gaps críticos (ordem de impacto)

| # | Gap | Local |
|---|---|---|
| B1 | `Scroll.update` não reconcilia mutações DOM→modelo: sem `super.update`, sem dispatch `blot.update(records)`, sem `ParentBlot.update`/`TextBlot.update`. Digitação nativa/IME/colagem não são absorvidas pelo modelo — só eventos são emitidos. | `scroll.dart:239-263` |
| B2 | `Scroll.optimize` sem o algoritmo de convergência do parchment (mutationsMap, `mark()`, pós-ordem dos marcados, drenagem de `takeRecords()` em laço, `MAX_OPTIMIZE_ITERATIONS=100`). Passada única sobre todos os filhos. | `scroll.dart:210-226`, `blot.dart:244-258` |
| B3 | `Cursor` é casca (62 vs 198 l.): sem `format()` real (ambos os ramos chamam no-op), `restore()`, `update()`, `optimize()`, `index()`, `position()`, ref à `Selection`. `selection.dart` nunca usa o Cursor → **formato pendente com cursor colapsado não funciona**. | `cursor.dart` |
| B4 | `Embed` inline sem guards (9 vs 94 l.): sem `contentNode`/`leftGuard`/`rightGuard` (﻿), `index()`, `restore()`, `update()`. Digitar adjacente a fórmula/imagem inline corrompe o DOM. | `embed.dart` |
| B5 | `Scroll.insertContents` inexistente (caminho canônico do `applyDelta`); `deltaToRenderBlocks`/`createBlock`/`insertInlineContents` existem **sem chamador**. | `scroll.dart:275,333,530` |
| B6 | `TextBlot.optimize` ausente: TextBlots adjacentes nunca fundem, vazios nunca são removidos → fragmentação progressiva do documento. | `text.dart` |
| B7 | `InlineBlot.format` faz addClass/removeClass cru; `formats()` devolve **todas as classes CSS** como formatos (formatos fantasma); `optimize` sem unwrap de span vazio nem merge genérico de irmãos (cada formato reimplementa: bold/italic/underline/link/syntax); `Inline.formatAt` sem `compare`+`isolate`+`wrap`. | `inline.dart:86-137` |
| B8 | `BlockEmbed` sem `attributes`/`delta()`/`format()`/`formatAt()` → align/indent em embeds de bloco não funcionam. | `block.dart:375-427` |
| B9 | `enforceAllowedChildren`/`requiredContainer`/`defaultChild` declarados mas nunca aplicados genericamente (só aproximação local no table_better). | vários |
| B10 | `ContainerBlot` vazio: sem `checkMerge()`/merge de irmãos no `optimize` — merges reimplementados localmente em `list.dart` e `table_better`. | `blot.dart:685-687` |
| B11 | Primitivas `wrap`/`isolate`/`replaceWith`/`attach`/`detach`/`update` ausentes na base; `Blot.formatAt` cai em no-op → leaf não-texto é não-formatável. | `blot.dart:132-207` |
| B12 | `Registry` sem `WeakMap<Node,Blot>`/`find` pela cadeia DOM (`ParentBlot.find` é varredura O(n) que não sobe pelo `parentNode`). | `blot.dart:623-651` |
| B13 | `ClassAttributor.keys` retorna `"ql-align-center"` (parchment: `"ql-align"`) → attributors de classe não são redescobertos de HTML carregado (align/indent/size/font somem). | `attributor.dart:142` |
| B14 | `Break.kScope = BLOCK_BLOT` (correto: INLINE_BLOT) — afeta `Scroll.insertBefore` e `bubbleFormats`. | `break.dart:10` |
| B15 | `descendant`/`_matches` usa `runtimeType ==` em vez de `is` → subclasses não casam com critério superclasse (Header vs Block). | `blot.dart:530-532` |
| B16 | `SCROLL_BLOT_MOUNT`/`UNMOUNT`/`EMBED_UPDATE` declarados e nunca emitidos (sem `emitMount`/`emitUnmount`/`emitEmbedUpdate`). | `emitter.dart:14-16` |
| B17 | `Scroll.remove()` lança (TS: no-op silencioso). | `scroll.dart:235-237` |
| B18 | `deleteAt`/`formatAt`/`insertAt` do Scroll não drenam `update()` antes (parchment scroll.ts:80-104). | `scroll.dart` |
| B19 | Dois `AttributorStore` incompatíveis (o real em `formats/abstract/attributor.dart` e um "naive" morto em `core/attributes/`); falta `move()`. | — |
| B20 | `Scroll.lines(index,length)` ignora o range dentro de containers → `formatLine` pode formatar linhas fora da seleção em listas/tabelas. | `scroll.dart:199-201` |

### 1.2 Divergências menores (blots)
`LeafBlot.split(0, force:true)` **duplica** o embed (TS nunca clona); `LeafBlot.index` ausente; `TextBlot.split` cria `DomText` novo (TS: `splitText`); `insertAt`/`deleteAt` do texto lançam `RangeError` (TS tolerante); `TextBlot.formatAt` reimplementação própria (`_isolate`/`_highestWrapTarget`/`_removeInlineFormat`); `escapeText` via `HtmlEscape` (mapa difere); `Block.formats()` só `attributes.values()` (sem `statics.formats`); `Block.insertAt` com ~45 l. de lógica extra; Registry sem `query(Scope)` (→ `scroll.create(Scope.INLINE)` impossível) e sem reuso de Node no `create` (ex.: `Header.create` ignora o `DomElement` recebido — quebra `Scroll.build` para HTML pré-existente); layout de `Scope` difere do parchment (`BLOCK & BLOT == 0` em Dart); `Attributor.canAdd` ignora whitelist na base; `AttributorStore.attribute` trata `''`/`0` como truthy (JS: falsy); `insertBefore` lança para ref inválido (TS tolera).

---

## 2. Inventário — Core + Modules (`lib/src/core/`, `lib/src/modules/`)

### 2.1 Gaps críticos

| # | Gap | Local |
|---|---|---|
| C1 | **`Keyboard.DEFAULTS` vazio — 26 bindings default ausentes**: bold/italic/underline (Ctrl+B/I/U), tab/indent/outdent, remove tab, list autofill, code exit, checklist/header/list/blockquote empty enter, embed left/right (±shift), table backspace/delete/enter/tab/up/down. Factories `makeFormatHandler`/`makeCodeBlockHandler`/`makeEmbedArrowHandler`/`makeTableArrowHandler`/`tableSide` são stubs. | `keyboard.dart:120,490-509` |
| C2 | `Selection` sem camada nativa (155 vs 486 l.): sem `getBounds`/`normalizeNative`/`normalizedToRange`/`rangeToNative`/`setNativeRange`/`update(source)`/CursorBlot/`handleComposition`/`handleDragging`; `focus()` no-op; `hasFocus()` = `_range != null`; **`format()` com contrato invertido** (só age com `length>0`; TS: só colapsado, via CursorBlot). | `selection.dart` |
| C3 | `Editor` sem `applyDelta` (newlines implícitas, `updateEmbedAt`, batch), sem update diff-based (characterData + `oldDelta.diff`), sem `getHTML`/`convertHTML`, `getFormat`/`combineFormats`, `removeFormat`, `isBlank`, `insertContents`, `getContents(i,l)`, `getText(i,l)`, normalização CRLF. | `editor.dart` |
| C4 | `Quill.modify()` ausente → readOnly não respeitado, TEXT_CHANGE emitido com SILENT, seleção ad-hoc. Faltam `enable/disable/blur/getLength/getLines/update/off/once/scrollSelectionIntoView/setText/getIndex`, `Quill.import/imports/DEFAULTS/expandConfig/overload`, `globalRegistry`, `ql-blank`+placeholder, conversão do innerHTML inicial, `history.clear()` no boot, instanciação do uploader. | `quill.dart` |
| C5 | `Emitter.emit` **trunca argumentos null** (arg intermediário nulo → handler chamado com menos args); bridge global DOM (`selectionchange/mousedown/mouseup/click` → `handleDOM`) ausente → `listenDOM` inerte. | `emitter.dart:66-84` |
| C6 | `Syntax` nunca aplica o realce (descarta o Delta do highlighter; falta `oldDelta.diff().reduce(formatAt)`); sem `initListener` (select de linguagem via attachUI); sem TokenAttributor. | `syntax.dart:252-260` |
| C7 | `Clipboard.matchAttributor` vazio (sem ATTRIBUTE/STYLE_ATTRIBUTORS; `options.attributors` default `[]`) → paste com `ql-align-*`/`ql-indent-*`/`ql-font-*`/`ql-size-*`/`dir` perde formatação; `matchBlot` hardcoded (IMG/vídeo/A/H1-6) vs genérico via `scroll.query`; `convert()` sem short-circuit de code-block; `matchCodeBlock` sem linguagem; `matchList` lê `data-list` (TS: `data-checked`). | `clipboard.dart` |
| C8 | Regex de Backspace/Delete sem âncora `^` (`RegExp(r'.?$')` casa sempre). | `keyboard.dart:137-147` |
| C9 | `SHORTKEY` fixo em `metaKey` → Ctrl+B/Z quebrados em Windows/Linux. | `keyboard.dart:19,446` |
| C10 | `Uploader` inerte: sem listener de `drop`, sem DEFAULTS.handler, não instanciado pelo Quill; integração no paste comentada. | `uploader.dart`, `clipboard.dart:205` |
| C11 | `UINode`: handler checa `ctx is! Map` mas Keyboard passa `Context` → binding nunca executa; correção do caret é no-op admitido. | `ui_node.dart:59,135` |
| C12 | `Toolbar`: guard de formato e ramo EmbedBlot (prompt p/ image/video/formula) comentados → botões embed inoperantes; select lido por atributo `selected`; `clean` não filtra `Scope.INLINE`; labels pt-BR hardcoded. | `toolbar.dart:132,179,606` |
| C13 | `instances` usa `Map` forte (TS: WeakMap) → vazamento de memória. | `instances.dart:4` |
| C14 | `Input._replaceText` age em range colapsado (risco de preventDefault indevido na digitação); sem `getTargetRanges()`. | `input.dart:100` |
| C15 | `scrollRectIntoView` sem walk de ancestrais/scroll-padding/visualViewport/smooth; nunca invocado. | `scroll_rect_into_view.dart` |
| C16 | `createRegistryWithFormats` sem o laço `requiredContainer` + detecção de ciclo. | `create_registry_with_formats.dart:27-36` |
| C17 | `deleteRange`/`handleBackspace`/`handleDelete` sem `AttributeMap.diff` (merge de formatos ao juntar linhas); `deleteRange` muta blots fora do pipeline (sem TEXT_CHANGE). | `keyboard.dart:454-488` |
| C18 | `Table` básico: `getTable`/`insertRow`/`insertColumn` privados, sem `register()` → bindings `table enter/tab` não integram. | `table.dart:586` |
| C19 | `TableEmbed` portado mas **nunca registrado**. | `initialization.dart` |
| C20 | `clipboard_temp.dart` morto (só `export`); remover. | — |

### 2.2 Divergências menores (core/modules)
`isEnabled()` via atributo `disabled`; `getSemanticHTML` bespoke (~300 l., HTML divergente do upstream: checklist com `<input>`, indent inline); `getBounds` com lineHeight=20 hardcoded; History escuta eventos separados (TS: EDITOR_CHANGE único) e teclas `'Z'/'Y'` nunca casam (funciona pela duplicata do Keyboard); `record()` checa `ops.isEmpty` (TS: `length()==0`); `addBinding` sobrescreve campos com null (TS: spread preserva); `match` compara `keyCode.toString()`; Theme `init()` pula config null|false; `_applyStyle()` placeholder vazio; uploader filtra mimetype invertido; onPaste seleção via insertedLength (TS: `delta.length()-range.length`); normalize_external_html: paridade excelente (falta guard `documentElement` null).

---

## 3. Inventário — Formats / Themes / UI (`lib/src/formats/`, `themes/`, `ui/`)

### 3.1 Gaps críticos

| # | Gap | Local |
|---|---|---|
| F1 | `BubbleTooltip` nunca se posiciona (bloco do EDITOR_CHANGE comentado). | `bubble.dart:46-61` |
| F2 | `SnowTooltip.linkRange` sombreia `BaseTooltip.linkRange` → `save()` sempre vê null; editar link aplica no lugar errado. | `snow.dart:39` |
| F3 | `listen()` duplicado no Snow (construtor base + SnowTooltip) → listeners duplos. | `snow.dart:44` |
| F4 | (= C16) `createRegistryWithFormats` sem requiredContainer. | — |
| F5 | Namespaces `attributors/*` inexistentes; `Quill.register` indexa por `attrName` → `AlignClass`/`AlignStyle` não coexistem; 12 registros ausentes → `AlignStyle`, `DirectionAttribute/Style`, `BackgroundClass`, `ColorClass`, `FontStyleAttributor`, `SizeStyle` nunca registrados. | `quill.dart:118-125` |
| F6 | Checklist sem UI (`ListItem.attachUI` com toggle checked/unchecked não existe). | `list.dart` |
| F7 | Handlers de link por tema ausentes (mailto, preview, `range.length==0 → return`). | `toolbar.dart:422` |
| F8 | `fillSelect` das cores recebe `bool` como default (TS: `'#ffffff'`/`'#000000'`) → nenhum swatch `selected`. | `base.dart:441` |
| F9 | `Tooltip.position()` sem `getBoundingClientRect`/`ql-flip`. | `tooltip.dart:37-57` |
| F10 | `TableRow.checkMerge()/optimize()` ausentes no table core. | `formats/table.dart` |
| F11 | `Image.formats()` inclui `image: src` (polui o Delta). | `image.dart:82-85` |
| F12 | `Picker` não dispara `change` no `<select>` nativo. | `picker.dart:218` |

### 3.2 Divergências menores (formats/themes/ui)
`Italic.optimize` divergente (unwrap+insertBefore **sem mover filhos** — provável perda de conteúdo ao normalizar `<i>`→`<em>`); `Strike` sem optimize (não normaliza `<strike>`→`<s>`); `CodeBlock.TAB` ausente; duas `ColorAttributor` divergentes; `FontStyle` não registrado; `Formula.html()` com `$$`; `Link.sanitize` não resolve URL relativa; modelo de dados de `list` divergente do upstream (tipo no container + tag OL/UL vs `data-list` no `<li>`); `Blockquote` **não registrado** em `initialization.dart`; `dart_quill.dart` não exporta formats/ui/themes-base/keyboard/clipboard/history/input (consumidor não estende); stubs mortos `color-picker.dart`/`icon-picker.dart`; `merge()` duplicada; TOOLBAR_CONFIG do Snow com grupo extra de tabela; picker usa `mousedown` (TS: click) e refatorou hooks (API incompatível para extensão); `icons.dart` com paridade completa de chaves, mas ícones de tabela extras são placeholders.

---

## 4. Inventário — table-better (`lib/src/table_better/`)

### 4.1 Gaps críticos

| # | Gap | Local |
|---|---|---|
| T1 | **`ui/table-menus.ts` (1.059 l.) não existe**: sem barra de menus flutuante (column/row/merge/table/cell/wrap/delete/copy + 15 sub-itens), posicionamento, tooltips, switch Header row, `disableMenu`/`updateMenus`/`updateScroll`, ciclo de vida do properties-form. A lógica de merge/split/header-row/copy foi portada em `cell_selection.dart` (sem UI). `TableContainer.insertColumn/insertRow/deleteColumn/deleteRow` existem e **ninguém os chama**. | ausente |
| T2 | **`ui/toolbar-table.ts` não existe**: `_TableGridPicker` atual chama o módulo `table` **básico** → o seletor 10×10 insere a tabela errada (sem temporary/colgroup/data-row). Sem blot `ToolbarTable` (`formats/table-better`), sem botão `ql-table-better`. Handlers `table-row-above` etc. também apontam para o módulo básico. | `modules/toolbar.dart:493` |
| T3 | `cell-selection.ts`: ~85% ausente (drag-select, setas, triplo-clique, copy/cut/paste nativos por grade, Ctrl+Backspace, WHITE_LIST/disable de botões, `updateSelected`, `exitTableFocus`…). Controller atual: só click/shift-click. | `ui/cell_selection*.dart` |
| T4 | `operate-line.ts` (463→104 l.): sem overlay/drag/hit-test; API por índice com clamps inventados; escreve `data-height`/`data-width` (atributos inventados; TS: `height`/`width` nas td + largura no temporary). | `ui/operate_line.dart` |
| T5 | `table-properties-form.ts` (791→226 l.): sem color picker/palette (15 cores), check-btns de alinhamento, dropdown border-style, validação inline (Dart **lança** FormatException), `getDiffProperties`, `saveTableAction` (align→margin), `saveCellAction` (percent/propagação text-align), posicionamento; labels **hardcoded pt-BR** ignorando `Language`; `getProperties()` do config **não é consumido**. | `ui/*properties_form.dart` |
| T6 | `modules/toolbar.ts` (`TableToolbar extends Toolbar`) não portado: sem `attach` bifurcado, `setTableFormat` (isReplace), handlers DEFAULTS header/list tri-estado/table-better; `register.dart` não substitui `modules/toolbar`. O `TableToolbarRouter` atual é reimplementação parcial. | `modules/toolbar.dart` |
| T7 | `utils.elementRectResolver` **lança UnimplementedError** → `TableContainer.deleteRow/insertColumn/_setColumnCells` explodem em runtime sem DOM com layout. | `utils/utils.dart:39-50` |
| T8 | Módulo `Table` (table_better.dart) incompleto: sem `handleKeyup/handleMousedown/handleMouseMove/handleScroll/showTools/updateMenus/registerToolbarTable/clearHistorySelected`; `hideTools` parcial; `insertTable` não chama `showTools`. | `table_better.dart` |
| T9 | Options sem `menus`/`toolbarButtons`/`toolbarTable`. | `table_better.dart:28` |
| T10 | 14 idiomas ausentes (há só en_US/pt_BR; faltam zh_CN, fr_FR, pl_PL, de_DE, ru_RU, tr_TR, pt_PT, ja_JP, cs_CZ, da_DK, nb_NO, it_IT, sv_SE, zh_TW). | `language/` |

### 4.2 Bugs pontuais (corrigíveis de imediato)
- Bindings `table-list`: leem `data-cell` do `<li>` (que nunca é definido) em vez do `ListContainer` → geram `cellId` novo e quebram o agrupamento da célula.
- `table-cell-block backspace`: só aceita `prev is TableCellBlock` (TS: também ListContainer/TableHeader).
- `table-header enter`: retain usa chave `table-header` (TS: `header`); falta `scrollSelectionIntoView`.
- `TableCellBlock.format`: ramos header/list caem no `super.format` (TODO desatualizado — os formats já existem).
- `formats/header.dart`/`list.dart`: sem `getCellFormats`/`isReplace`/ramos cruzados header↔list↔cell.
- `modules/clipboard.dart`: precedência invertida em `getTableDelta`; `onPaste` com seleção divergente.
- `utils.getAlign`/`getCellChildBlot` só consideram `TableCellBlock` (TS: +TableList/TableHeader) → `cellId` de fallback errado em merge/split.
- `getCorrectContainerWidth` sem padding; `getElementStyle` sem computed style.
- Assets: 22 SVGs + `quill-table-better.scss` não portados (nenhuma classe CSS da UI tem produtor).

---

## 5. Plano de finalização (fases G0–G9)

Princípios: (a) manter a suíte verde a cada lote; (b) portar fiel ao TS em vez de reinventar; (c) fundações primeiro (parchment → core → UI), pois os gaps de cima dependem delas; (d) tudo testável em VM com fake DOM quando possível, browser/E2E para interação.

### G0 — Quick wins de correção (1-2 dias) — EXECUTADO em 2026-07-27
Bugs pontuais de alto impacto e baixo risco, sem mudança arquitetural:
- [x] G0.1 `Break.kScope` → INLINE_BLOT (B14). *Nota: `_matches` com `is` (B15) não é tradutível para Dart com `Type` em runtime; todos os call-sites internos já usam predicates — reclassificado como restrição documentada.*
- [x] G0.2 `ClassAttributor.keys` estilo parchment (B13); `Attributor.canAdd` base com whitelist + strip de aspas; `ClassAttributor.remove` limpa o atributo `class` vazio.
- [x] G0.3 Keyboard: SHORTKEY por plataforma via userAgent (C9); âncora `^` nas regex de Backspace/Delete (C8); undo/redo movido para o History com teclas corretas 'z'/'Z'+shift/'y'-Win (paridade history.ts:27).
- [x] G0.4 `Emitter.emit`/`once` com sentinela `_absent` (não trunca null) e dispatch tolerante a aridade (C5, parte 1).
- [x] G0.5 `Image.formats()` sem `image` (F11); `Blockquote` registrado; `TableEmbed` disponível como módulo opt-in (paridade upstream); `clipboard_temp.dart` removido (C20).
- [x] G0.6 Snow: `linkRange` sem shadow (F2); `listen()` único (F3); `fillSelect` defaults '#ffffff'/'#000000' (F8).
- [x] G0.7 `createRegistryWithFormats` com laço requiredContainer (novo campo `RegistryEntry.requiredContainerBlotName`, cadeias list/code-block/table preenchidas) + guard de ciclo + suporte a attributors (C16/F4).
- [x] G0.8 table-better: `cellId` dos bindings de lista lido do `TableListContainer`; backspace aceita prev ∈ {TableCellBlock, TableListContainer, TableHeader}; `getAlign`/`getCellChildBlot` consideram TableList/TableListContainer/TableHeader. *Chave do enter (`table-header: null`) mantida: o `TableHeader.format` Dart trata esse ramo com o mesmo efeito do TS (`header: null` → replaceWith cell-block).*
- [x] G0.9 `Scroll.remove()` no-op (B17); `Italic`/`Strike` com optimize fiel ao Bold (normalização de tag movendo filhos + merge de irmãos) e `format(name,false)→unwrap`.

### G1 — Parchment fiel (1-2 semanas) — pré-requisito de tudo — EM ANDAMENTO (2026-07-27)
- [x] G1.1 Primitivas base: `wrap`/`wrapWith`, `isolate`, `replaceWith`/`replaceWithBlot` (ParentBlot move filhos), `splitAfter` genérico, `shadowFormatAt` com fallback (Scope.BLOT → wrap; ATTRIBUTE → parent same-scope) como default de `Blot.formatAt`; `EmbedBlot.format/formatAt` fiéis a embed.ts (leaf não-texto agora é formatável/embrulhável). *`attach`/`detach` ficam para G1.5 (dependem do pipeline de update).* (B11)
- [x] G1.2 `TextBlot.optimize` (remove vazio + merge com next TextBlot). *`update` de characterData fica para G1.5.* (B6)
- [x] G1.3 `InlineBlot` fiel: `attributes` (AttributorStore) movido para a base; `format` com ramos unwrap/attributor/replaceWith (inline.ts:62-85); `formats()` = attributes.values() — **sem formatos fantasma de classes CSS**; `optimize` com unwrap de `Inline` vazio + merge de irmãos com formats iguais (inline.ts:113-128). (B7)
- [x] G1.4 `ContainerBlot.checkMerge` (blotName+tagName) + optimize genérico (remoção de vazio + merge de irmão, container.ts:39-45) com opt-out `managesOwnContainerOptimize` para o table_better (que converge sozinho em passada única); `TableRow` core ganhou `checkMerge` por data-row (table.ts:66-77). *O split de linha (table.ts:79-97) fica junto do G1.10 — conflita com a normalização do módulo sem o applyDelta fiel. `enforceAllowedChildren`/`requiredContainer` genérico continuam pendentes (B9).* (B10, F10 parcial)
- [x] G1.5 (núcleo) Reconciliação DOM→modelo: `Blot.applyMutations` (base), `ParentBlot.applyMutations`/`syncChildrenFromDom` (resync de filhos por childList reusando blots + hidratando novos via `Scroll.hydrateDomNode`), `Cursor`/`Embed` roteando characterData para `restore()`, invalidação do cache do Block afetado; `Scroll.update` agrupa mutações por blot (children-first) e despacha; `Scroll.optimize` convergente drenando `observer.takeRecords()` com `MAX_OPTIMIZE_ITERATIONS=100`. *`attach`/`detach` formais e o mark-based partial optimize do parchment ficam como refinamento.* (B1, B2)
- [x] G1.6 (parte) `Registry.queryScope` (query(Scope)→block/inline) + **reuso de Node no `create`**: todos os closures de registro adotam o `DomElement` recebido (Scroll.build agora preserva H1-H6, href de link, atributos) — regressão coberta por `test/unit/core/hydration_node_reuse_test.dart`. *Expando find pela cadeia DOM continua pendente (B12).* 
- [x] G1.7 `Cursor` funcional: `format()` real (sobe ao bloco + formatAt com savedLength — formato pendente), `restore()` (texto digitado no guard vira TextBlot adjacente, com correção do push-down do browser), `update()` por characterData, `optimize()` anti-`<a>` (Safari), `index`/`position`/`remove`. *Integração com a Selection nativa fica no G2.2 (hook `isComposing` já exposto).* (B3)
- [x] G1.8 `Embed` inline com guards ﻿: contentNode contenteditable=false, leftGuard/rightGuard, `restore()`/`index()`/`update()`, `EmbedContextRange`. (B4)
- [x] G1.9 `BlockEmbed` com `attributes` (AttributorStore de BLOCK_ATTRIBUTE), `delta()`, `format()`/`formatAt()` fiéis; `Editor._buildDelta` mescla `attributeValues()` na linha do embed (align/indent em vídeo funcionam). (B8)
- [x] G1.10 (núcleo) `Scroll.insertContents` fiel (scroll.ts:139-210, usando deltaToRenderBlocks/createBlock/insertInlineContents que estavam órfãos) + `Editor.insertContents(index, delta)` com normalização CRLF; `Scroll.lines` respeitando range dentro de containers (B20); testes novos em `test/unit/core/insert_contents_test.dart`. *Restam: trocar o Editor.update bespoke pelo applyDelta fiel, drenagem de update nas APIs (B18), emitMount/emitUnmount (B16), split de TableRow por data-row.*
- Testes: portar cenários de `parchment` upstream + suíte atual verde.

### G2 — Core fiel (1 semana) — EM ANDAMENTO (2026-07-27)
- [x] G2.1 **`Quill.modify()` fiel** (quill.ts:881-917): guard de readOnly (`!isEnabled() && source==USER && !allowReadOnlyEdits` → Delta vazio), captura do oldDelta, shift+reaplicação silenciosa da seleção, e emissão condicional — **TEXT_CHANGE suprimido em SILENT** (antes era sempre emitido) e nada emitido quando o change é vazio. Todos os mutadores (`insertText`/`deleteText`/`formatText`/`formatLine`/`insertEmbed`/`updateContents`) passaram a delegar a ele e agora **retornam o Delta** como no TS. Novas APIs: `enable`/`disable`/`editReadOnly`/`allowReadOnlyEdits`, `blur`, `getLength`, `getLines`, `update(source)`, `off`, `once`; `isEnabled()` agora reflete `contenteditable` (scroll.isEnabled) e o construtor habilita o scroll. `DomAdapter.blur` adicionado (html/stub/fake). Testes: `test/unit/core/modify_test.dart`. (C4)
- [~] G2.2 `Selection`: **`format()` com o contrato correto** — com seleção colapsada agora estaciona um `Cursor` no caret e o formata (formato pendente), em vez de não fazer nada; com range aplica direto. Em 2026-07-28 foram portados `normalizeNative` e `normalizedToRange`, usados pelo `Input` para converter `StaticRange` do navegador em `Range` do Quill. *Pendente: `rangeToNative`/`setNativeRange`/`update(source)` e integração completa do Cursor com a seleção nativa.* (C2 parcial)
- [x] G2.3 `Editor`: `getFormat` (delegando ao `Scroll.getFormat`, que já implementa combineFormats fiel), `removeFormat` fiel (diff contra texto puro + sufixo da linha), `isBlank`, `getContentsRange(i,l)`, `getText(i,l)`, `insertContents` + normalização CRLF (C3). *Pendente: `getHTML`/`convertHTML` baseado em blots (hoje `deltaToSemanticHTML` bespoke).*
  - ⚠️ **Achado bloqueante para G1.10:** `Quill.removeFormat` NÃO pôde ser trocado para o `Editor.removeFormat` fiel — o diff produz um `retain {list: null}` que o `Editor.update` bespoke não aplica (o clean deixa a lista intacta). Isso é evidência concreta de que **o `applyDelta` fiel é pré-requisito** de vários itens de paridade; a versão bespoke de `Quill.removeFormat` foi mantida com a nota no código.
- [x] G2.4 **Emitter global e instâncias fracas** (2026-07-28): bridge instalado uma vez por `DomDocument` para `selectionchange`/`mousedown`/`mouseup`/`click`, roteando somente aos `.ql-container` anexados e respeitando o alvo de cada `listenDOM`; `QuillInstances` usa `Expando<Object>` em vez de `Map<DomNode, dynamic>`, eliminando a retenção forte e a enumeração de editores. Fake DOM ganhou selector `.class` no documento para testar o mesmo caminho do browser. Testes: `emitter_test.dart` (bridge, detach e isolamento entre editores) + `instances_test.dart`. (C5 parte 2, C13)
- [ ] G2.5 `scrollRectIntoView` fiel + `Quill.scrollSelectionIntoView` (C15).

### G3 — Keyboard completo — CONCLUÍDO (2026-07-27)
- [x] G3.1 As 5 factories reais (`makeFormatHandler`, `makeCodeBlockHandler`, `makeEmbedArrowHandler`, `makeTableArrowHandler`, `tableSide`), portadas de keyboard.ts:639-784/817-831. Handlers default usam `DefaultBindingHandler(Keyboard, Range, Context)` como substituto do `this` do TS; `_invokeHandler` reconhece a aridade e mantém compatibilidade com `(range, context)`/`(range)`.
- [x] G3.2 **Os 26 bindings default** registrados (C1), com `{...DEFAULTS.bindings, ...options.bindings}` (usuário sobrescreve por nome; `null`/`false` desabilita). `addBinding` com semântica de spread real + `context` como função ou BindingObject. Correções colaterais necessárias: **`Keyboard.match` era infiel** (modificador ausente era tratado como "tanto faz", então Tab capturava Shift+Tab) — agora ausente = "não pode estar pressionado", só `null` é opcional; `normalize` clona o binding (senão os objetos estáticos de DEFAULTS eram mutados e vazavam entre instâncias); `listen()` extraiu `handleKeydown(DomEvent)` público para permitir teste em VM.
- [x] G3.3 `handleBackspace`/`handleDelete`/`deleteRange` com `Delta.diffAttributes` no pipeline de delta (C17) — nada mais muta blots direto, tudo emite TEXT_CHANGE.
- [ ] G3.4 `Table` básico: `getTable`/`insertRow`/`insertColumn` públicos + `register()` (C18). *O binding `table enter` foi implementado derivando table/row/cell de `context.line`, então funciona sem essa API.*
- Testes: `test/unit/modules/keyboard_bindings_test.dart` (23 casos: defaults por tecla + contagem, Ctrl/Cmd+B, Tab/Shift+Tab, autofill, empty enter, code exit, merge de formatos no backspace, semântica do addBinding).
- TODOs deixados: `CodeBlock.TAB` (G5.2), `quill.scrollSelectionIntoView` (G2.5), `Quill.update` no makeCodeBlockHandler (G2.1 — expresso como delta, mesmo efeito).

**⚠️ Dois bugs de core encontrados pelo trabalho de G3 (ainda abertos, candidatos a G1.10):**
1. **`Scroll.deleteAt` apaga demais em blocos vazios**: em `'code\n\n\n\n'`, `updateContents(retain(6)+delete(1))` produz `'code\n'` — três newlines somem. Reproduz também com parágrafos simples. Afeta backspace/delete em linhas vazias.
2. **`Quill.deleteText` não apaga através de fronteira de bloco**: `Editor.deleteText` chama `Scroll.deleteAt` uma única vez (só `Editor.update` tem o laço `while (remaining > 0)`), então `deleteText(3, 5)` sobre `'Title\nbody\n'` remove só 3 caracteres **e ainda emite um delta que não corresponde ao documento**.

### G4 — Clipboard/Uploader/Input/UINode (3-5 dias) — CONCLUÍDO (2026-07-28)
- [x] G4.1 ATTRIBUTE/STYLE_ATTRIBUTORS + `matchAttributor` real; `matchBlot` genérico via registry; short-circuit code-block; `matchCodeBlock` com linguagem; `matchList` via `data-checked` (C7). Testes: `clipboard_attributors_test.dart` + expectativas de conversão atualizadas para o registry padrão.
- [x] G4.2 Uploader: listener de drop + `DEFAULTS.handler`, filtro de mimetype correto, uma única operação Delta para múltiplos arquivos e integração no paste (C10). *Pendente de plataforma: obter o índice pelo ponto do drop (`caretRangeFromPoint`) e expor `dataTransfer` em eventos de drop genéricos.*
- [x] G4.3 **Input fiel ao `beforeinput`**: `DomInputEvent.getTargetRanges()`/`DomNativeRange`, rejeição de range colapsado, normalização DOM→Quill e substituição do range nativo (não da seleção lógica desatualizada), incluindo texto vindo de `dataTransfer` e replacement vazio. **UINode funcional**: handler recebe `Context`, direção via computed style, escuta one-shot de `document.selectionchange` com TTL e move o range nativo para depois de `.ql-ui`. `ParentBlot.attachUI` foi portado; hidratação/reconciliação ignoram o nó UI de comprimento zero (evita transformá-lo em Cursor e vazar FEFF); checklist checked/unchecked agora alterna por mouse/touch. Testes: 5 novos de Input + 2 de UINode/checklist, além da regressão table-better existente. (C14, C11, F6 parcial)
- [x] G4.4 **Registros não-colidentes e API pública**: os 13 caminhos upstream `attributors/attribute|class|style/*` são registrados pelo caminho exato e coexistem mesmo compartilhando `attrName`; os aliases `formats/*` continuam instalando somente o default correto no registry do editor. `Quill.registerPath`, `importDefinition` e `registeredDefinitions` fornecem a contraparte Dart da registry de imports. `dart_quill.dart` agora exporta blots/registry, attributors e formatos, módulos principais, BaseTheme, pickers/tooltip/ícones e tipos DOM necessários para extensões; os exemplos Angular escondem o módulo `Input` para não colidir com `@Input`. Testes: `public_api_test.dart` (namespaces, aliases e smoke da superfície pública). (F5)

### G5 — Formats/Themes/UI (3-5 dias) — G5.1/G5.3 CONCLUÍDOS (2026-07-27)
- [x] G5.1 **BubbleTooltip posicionado** (F1) — o corpo comentado foi portado de bubble.ts:42-59 incluindo o caso multi-linha; **`Tooltip.position` com rects reais e `ql-flip`** (F9) + `isScrollable` guardando o listener de scroll; **handlers de link por tema** (F7) — snow ignora seleção colapsada e prefixa `mailto:`, bubble abre sem preview, handler do usuário vence (`BaseTheme.overridesHandler`); o Ctrl+K do snow delega ao handler. Novo helper `ui/dom_interop{,_stub,_web}.dart` para computed overflow / dispatch de evento (a camada de plataforma não expõe `getComputedStyle`). Testes: `test/unit/themes/tooltip_position_test.dart` (14) + `test/browser/tooltip_position_test.dart` (6).
- [x] G5.3 `Picker.selectItem` público e despachando `change` no `<select>` nativo (F12); stubs mortos `color-picker.dart`/`icon-picker.dart`, `merge()` duplicada, getter `template` e `BubbleTheme.defaults()` removidos.
- [~] G5.2 Checklist com `attachUI` e toggle checked/unchecked concluído em G4.3 (F6); `TableRow.checkMerge` já entregue em G1.4; `FontStyle`/`SizeStyle` e todas as demais variantes de attributor registrados por namespace em G4.4. Pendentes: `CodeBlock.TAB`; refinamento de `TableRow.optimize`; unificar `ColorAttributor`; `Link.sanitize` fiel; alinhar integralmente o modelo de `list` ao upstream (avaliar impacto no Delta).
- [ ] G5.4 Syntax: aplicar realce via diff (C6) + initListener com select de linguagem; vendorizar highlight (F4 do plano antigo).

### G6 — table-better UI completa (2-3 semanas, maior bloco)
Ordem interna (dependências primeiro):
- [x] G6.1 `elementRectResolver` real via `domBindings.adapter.getElementBounds` (getBoundingClientRect no browser; fake DOM fornece bounds sintéticos nos testes VM) (T7). *Feito em 2026-07-27.*
- [x] G6.3-parcial: o seletor 10×10 (`_TableGridPicker`) agora roteia para `TableBetter.insertTable` quando o módulo `table-better` está ativo, com fallback ao módulo básico (T2, parte crítica). *Feito em 2026-07-27; resta o blot `ToolbarTable`/botão `ql-table-better` dedicado e o click-outside.*
- [ ] G6.2 `ui/table-menus.dart`: port fiel de `table-menus.ts` — menus dropdown, tooltips, switch header-row, posicionamento, `updateMenus`, `getSelectedTdsInfo`/`getCorrectTds`, wrappers deleteRow/deleteColumn(isKeyboard), `copyTable`, `getTableAlignment` — chamando os métodos já existentes de `TableContainer` e `CellSelection` (T1).
- [ ] G6.3 `ui/toolbar_table.dart`: `TableSelect` + blot `ToolbarTable` + botão `ql-table-better` roteado para `TableBetter.insertTable`; migrar/aposentar o `_TableGridPicker` do módulo básico (T2).
- [ ] G6.4 `cell-selection` completa: drag, setas, triplo-clique, copy/cut/paste por grade, Ctrl+Backspace, WHITE_LIST/disable, `ql-cell-focused` (T3).
- [ ] G6.5 `operate-line` com overlay/drag/hit-test e persistência fiel (height/width nas td, largura no temporary) (T4).
- [ ] G6.6 `table-properties-form` fiel: palette 15 cores + hex, check-btns, dropdown border-style, validação inline, saveTable/saveCellAction, posicionamento; consumir `getProperties()` + `Language` (T5).
- [ ] G6.7 `TableToolbar` (module) com `setTableFormat`/isReplace + DEFAULTS handlers; registrar em `register.dart` (T6).
- [ ] G6.8 Módulo `Table` completo (handleKeyup/Mousedown/MouseMove/Scroll, showTools, options menus/toolbarButtons/toolbarTable) (T8, T9).
- [ ] G6.9 Ramos cruzados header↔list↔cell em `TableCellBlock.format`/`header.dart`/`list.dart` (+`setCellRowspan`); fixes de clipboard do módulo (§4.2).
- [ ] G6.10 CSS `quill-table-better.scss` → Dart const + 22 SVGs (ou mapa Tabler equivalente já adotado). ~~14 idiomas restantes~~ **✓ Idiomas completos (2026-07-27): os 16 locales do TS portados e registrados em `language/language.dart` (60 chaves cada, verificadas por diff).** (T10)
- Testes: cenários E2E Puppeteer para menus/resize/properties; unit para toda a lógica de grade.

### G7 — Assets e API pública (2-3 dias)
- [ ] G7.1 `.styl` do Quill → CSS definitivo embutido (core/snow/bubble); `QuillAssets.inject()` (F3 do plano antigo).
- [ ] G7.2 Ícones SVG oficiais completos (72) como alternativa ao tema Tabler.
- [~] G7.3 Superfície pública: exports de extensão e `Quill.import`-like entregues em G4.4 (`importDefinition`, pois `import` é palavra reservada em Dart); pendem revisão final de compatibilidade e dartdoc.

### G8 — DOCX/PDF restantes (1-2 semanas)
- [ ] G8.1 Import: `w:numPr`→list real; alinhamento do 1º parágrafo; fixtures Word/LibreOffice/Google (F7.4/F7.5 do plano antigo).
- [ ] G8.2 Export DOCX: numeração WordprocessingML real; page setup; tabelas table-better com tblGrid/gridSpan/vMerge; validação no Word (F8.3).
- [ ] G8.3 Export PDF (F9 do plano antigo, inteiro).
- [ ] G8.4 Imagens flutuantes → DrawingML (F5A.5).

### G9 — QA final e empacotamento (3-5 dias)
- F10 do plano antigo: exemplos plain/ngdart, suíte 100% VM+chrome, smoke e2e completo (digitar, formatar, tabela completa, abrir/exportar DOCX, exportar PDF), README/docs.

### Estimativa total
G0: 1-2 dias · G1: 1-2 sem · G2: 1 sem · G3: 3-5 d · G4: 3-5 d · G5: 3-5 d · G6: 2-3 sem · G7: 2-3 d · G8: 1-2 sem · G9: 3-5 d → **~8-10 semanas** de trabalho focado.

### Critérios de aceite (inalterados do plano F, reforçados)
- `dart analyze` limpo; suíte 100% verde (VM + chrome + E2E).
- Única dependência runtime: `web: ^1.1.1`.
- Paridade comportamental com Quill 2.0.3: 26 bindings, paste com attributors, formato pendente no cursor, embeds com guards, checklist clicável, syntax com realce aplicado.
- table-better completo: menus flutuantes, seleção por arrasto, resize visual, propriedades com paleta, seletor 10×10 inserindo tabela table-better, 16 idiomas.
- DOCX abre/exporta fiel; PDF visualmente equivalente.
