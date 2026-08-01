# Pendências antes do modo editor avançado

**Data da auditoria:** 2026-08-01
**Escopo:** os três recursos que precisam de paridade ANTES de qualquer trabalho
no modo Word paginado, porque um lançamento do SALI com este port depende deles:
paridade de PDF, colar do Word respeitando formatação e tabelas, e conversão
para HTML respeitando tabelas grandes e complexas.
**Método:** leitura dirigida do código deste repositório, do upstream vendorizado
em `referencias/` e do pipeline real do `new_sali`. Cada item tem evidência
arquivo:linha verificada na data acima.

Corpus de referência: `resources/PGCTIC1_-_ETP...` e `resources/PGCTIC1_-_TR...`
(DOCX + PDF gerado pelo Word), mais os 4 fixtures Delta reais em
`new_sali/core/test/assets` (12.507 ops).

---

## 1. Conversor HTML (`dart_quill_html.dart`)

**Fato central de proveniência:** `lib/src/converters/html/` é byte-idêntico ao
`nadar_delta_to_html` vendorizado no SALI (exceto imports/`css_util.dart`).
Todos os defeitos abaixo **existem hoje no SALI em produção** — corrigi-los aqui
já melhora o sistema atual.

### Críticos (corrompem a estrutura da tabela)

- **H1. Agrupamento de linhas quebra com ids `row-xxxx`.**
  `listener/table_better.dart:64-69` faz `int.tryParse(data-row) ?? 0`; tabelas
  criadas NO editor usam ids como `row-is10` → todas as células caem num único
  `<tr>`. Só funciona com deltas colados do Word (`data-row` numérico). No
  listener do table core (`listener/table.dart:50-64`) é pior: nenhum `<tr>` sai.
- **H2. Uma célula = só o bloco imediatamente anterior.**
  `table_better.dart:39-40` usa apenas `line.previous()`; célula com múltiplos
  blocos (header + parágrafo, lista) vira vários `<td>`; conteúdo com formato
  misto vaza para fora da tabela como `<p>`. `table-list`/`table-header`/
  `table-th-block` não têm listener algum.
- **H3. `colgroup`/larguras de coluna não são emitidos.**
  Ops `table-col` são descartados em silêncio; `table-temporary.col-widths`
  (injetado pelo SALI) não tem suporte em `lib/` inteiro; `table-layout: fixed`
  não é emitido (`sanitizeTableStyle` em `utils/css_util.dart:109-133` está sem
  chamador). Sem isso, larguras de tabelas grandes não reproduzem o editor.

### Importantes

- **H4. "HTML sem CSS" ainda vaza classes.** `class="ql-table-better ..."` copiado
  para `<table>` (`table_better.dart:124,151-152`), `img-responsive img-fluid`
  em imagem (`listener/image.dart:8-9`), `list-unstyled` em checklist
  (`listener/lists.dart:16`). Teste só proíbe `ql-editor`, não `class=`.
- **H5. Sem listener para `indent` de parágrafo, `direction`, `line-height`.**
- **H6. HTML→Delta achata célula para texto puro** (`from_html/parser/`
  `default_html_to_ops.dart:448-452`): links, cores, listas, negrito parcial
  dentro de célula se perdem; `<colgroup>` não vira `table-col`; `data-row`
  reindexado (round-trip instável); `rowspan` não desloca colunas.
- **H7. Escala:** `Lists.render`/`getFirstLine` têm padrões O(n²); único teste
  grande (2,1 MB) não mede tempo. Delta sem `\n` final derruba a conversão
  (`inline_listener.dart:25-27` lança).

### Ordem sugerida

1. H1 (comparação por string do `data-row`) + teste alimentado pelos 19 goldens;
2. H2 (agrupar por `cellId`/`table-cell-block`) + `table-list`/`table-header`;
3. H3 (`<colgroup>` + `col-widths` + `table-layout:fixed`);
4. H4/H5; 5. H6; 6. H7.

---

## 2. Colar do Word (clipboard)

O pipeline core e o table-better clipboard estão portados e testados
(`lib/src/modules/clipboard.dart`, `lib/src/table_better/utils/`
`clipboard_matchers.dart` — colspan/rowspan/colgroup/th funcionam). Os gaps:

### Críticos

- **W1. `font-size` em pt é descartado** — whitelist `['10px','18px','32px']`
  (`lib/src/formats/size.dart:18-22`); todo tamanho do Word (`11.0pt`) morre.
- **W2. `font-family` é descartada** — whitelist `['serif','monospace']`
  (`lib/src/formats/font.dart:5-8`); Calibri/Arial/Times morrem.
- **W3. Numeração literal perdida + tipo de lista frágil.** Os marcadores
  `mso-list:Ignore` são removidos (`normalize_external_html/normalizers/`
  `ms_word.dart:81-83`) e o Quill renumera de 1; bullet×ordered depende de um
  regex de `@list` que, falhando, cai em `ordered`.
- **W4. Gate estreito de detecção.** `ms_word.dart:138` exige `xmlns:w`; HTML de
  Word vindo de Outlook Web/variantes (`class="Mso..."`, `mso-list` sem o
  namespace) não é normalizado de forma nenhuma.
- **W5. Paridade upstream faltando:** o ramo `text-indent > 0 → '\t'` de
  `clipboard.ts:603-607` não foi portado para `matchStyles`
  (`clipboard.dart:920-966`).

### Importantes

- **W6. CSS de `<style>` (negrito/margens por classe `p.X{...}`) é ignorado**
  (`['style', matchIgnore]`, `clipboard.dart:101`).
- **W7. Espaçamento entre parágrafos** (`margin-bottom` ≥ 4pt → parágrafo em
  branco) — correção que o SALI faz em `sali_word_paste.js` e o port não tem.
- **W8. Tabela aninhada é descartada INTEIRA** (`table_better/modules/`
  `clipboard.dart:43-45` devolve `Delta()` — paridade com o plugin, mas perda
  real; achatar seria melhor).
- **W9. Sem try/catch nos normalizadores** (`normalize_external_html/index.dart`)
  — uma exceção quebra o paste inteiro.
- **W10. Zero fixtures de HTML real do Word nos testes.**

O `sali_word_paste.js` (434 linhas) codifica as correções W3/W4/W6/W7 em
produção; a porta genérica delas (como opções de `ClipboardOptions` /
normalizador estendido) é o caminho — rodando ANTES de `normalizeMsWord`, como
o patch faz hoje.

### Ordem sugerida

1. Fixtures reais + testes (destrava o resto); 2. W5 + W9 (baratos);
3. W3/W4 como normalizador estendido genérico; 4. W6/W7 (parser mínimo do
`<style>`); 5. W1/W2 via attributors configuráveis por instância (sem quebrar o
default de paridade); 6. W8/tabelas aninhadas e imagens `file:///`.

---

## 3. PDF (`dart_quill_pdf.dart`)

**Achado central:** fonte CID (`office/document/pdf/pdf_cid_font.dart`),
subsetting TrueType e renderizador SVG estão prontos e testados (17+25+15+30
casos), mas **nenhum está ligado ao exportador** — `pdf_exporter.dart:728-737`
segue em standard-14 + WinAnsi (fora do cp1252 → `?`), e não há emissão de
string hex `<...> Tj` no `pdf_content.dart` para o CID ser utilizável.

### Bloqueadores (perda silenciosa ou política do SALI)

- **P1. Fontes embutidas não ligadas** (acima) — o documento assinado não sai em
  Inter; travessão/aspas curvas viram `?`.
- **P2. `headerImage` descartado sem aviso** (`office/word/quill_delta.dart:404-415`
  só reconhece `insert['image']`) — o brasão some do despacho.
- **P3. SVG não ligado** — mesmo com P2, o `.svg` do cabeçalho não desenha.
- **P4. Imagem por URL não resolve** (`pdf_image.dart:34-39` só aceita
  `data:base64`) — o Delta do SALI guarda URLs; falta o equivalente ao
  `onDetectImageUrl` (decisão de API: callback async → muda a assinatura de
  `deltaToPdf`; decidir cedo).
- **P5. `rowspan` ignorado em tabela** (`pdf_exporter.dart:829-874`) — o SALI já
  suporta hoje (`quill_table_better_builder.dart:255-289` é a especificação).
- **P6. Page setup ausente** — sem `page-orientation`/`page-margin` (faixa
  0,5–5 cm) nem os dois layouts do SALI (assinado 2 cm / editor 1 cm);
  espelhar `sali_quill_pdf_defaults.dart:48-109`.
- **P7. Sanitizer/perfil assinado ausente** — o SALI REMOVE `color`,
  `background`, `script` e filtra `font` por whitelist com aliases
  (`quill_pdf_sanitizer.dart:12-50`) antes do PDF jurídico; portar como perfil
  opcional (não no caminho default da lib).

### Importantes

- **P8.** `indent` de lista colapsado num nível só; **P9.** largura de negrito
  estimada ×1,05 (some com P1); **P10.** sem code-block/blockquote/checklist;
  **P11.** sem `line-height`; **P12.** cascata de larguras de tabela incompleta
  (falta reescala pela âncora `table-temporary` — tabela colada do Word
  estoura); **P13.** tabela aninhada pulada em silêncio; **P14.** linha maior
  que a página transborda; **P15.** heurística de justificado do SALI (≤48
  chars → left) não replicada; **P16.** `deltaToPdf` não devolve `warnings` —
  toda perda é invisível.

### Cobertura

- **P17.** Zero testes de tabela no PDF; **P18.** zero de imagem fim-a-fim;
  **P19.** os 4 deltas reais só assertam "abre"; **P20.** corpus
  `resources/*.docx+pdf` não ligado a nenhum teste de comparação.

### Ordem sugerida

1. P16+P2+P4+P3 (parar de perder conteúdo em silêncio; fixa a API);
2. P1+P9 (fontes; o teste cp1252 existente foi desenhado para falhar aqui);
3. P6+P7 (perfil SALI); 4. P5+P12+P13+P17 (tabelas + a suíte que não existe);
5. P8/P10/P11/P15; 6. P19/P20 (corpus ETP/TR como regressão).

**Risco de rollout:** `despacho_pdf_service.dart:58-60` hasheia o PDF
(SHA-256). Migrar o SALI do `pdf_plus` para este exportador muda o hash de
documentos REGERADOS; despachos já assinados não são afetados (PDF congelado),
mas a política para regeração precisa ser explícita antes do P6 do plano de
conversores.

---

## Estado (2026-08-01)

| Frente | Estado |
|---|---|
| H1 — `<tr>` por id de linha string | **corrigido** |
| H2 — célula multi-bloco num único `<td>` (`<p>`/`<hN>`/`<ul>`/`<ol>`), `table-header` e `table-list` renderizados, inline completo | **corrigido** |
| H3 — `<colgroup>` a partir de `table-col` e de `table-temporary.col-widths`, com `table-layout: fixed` | **corrigido** |
| H4–H7, W1–W10, P1–P20 | pendentes |

Testes que travam o corrigido: `test/unit/converters/html_table_rows_test.dart`
e `test/unit/converters/html_table_cells_test.dart` (este alimentado pelos
deltas reais dos goldens do plugin).

Fora desta lista, corrigidos na mesma passagem por serem bugs de produto
reportados no exemplo ngdart (ambos com E2E que reproduz a condição):

- `insertColumn` misturava bounds de viewport com bounds relativos ao
  container — "inserir coluna à esquerda" não fazia nada quando o editor não
  estava em x≈0;
- o dropdown de estilo de borda não fechava ao escolher um valor (guard de
  `<li>` que o upstream não tem);
- tabela sem bordas visíveis sob o Limitless (regras de tabela ausentes) e
  mini-UI do table-better visível sem tabela (especificidade de `.ql-hidden`).

Atualizar esta tabela a cada item fechado.
