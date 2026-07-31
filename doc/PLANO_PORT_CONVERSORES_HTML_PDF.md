# Plano: conversores Delta→HTML e Delta→PDF em `dart_quill`, sem dependências

**Data:** 2026-07-30
**Objetivo:** `dart_quill` passa a ser editor **e** conversor (HTML e PDF), com
exports separados, para que o `new_sali` remova o Quill TypeScript e os
conversores do próprio código e dependa só desta biblioteca.
**Restrição do projeto:** **nada de `pdf_plus`** — nem qualquer outra dependência
runtime além de `web`. O `pdf_plus` é uma biblioteca inchada para o que este
conversor precisa; o que faltar é implementado aqui, enxuto, usando as
referências locais (`C:\MyDartProjects\{itext,jsPDF,pdfbox_dart,dart_graphics}`)
só como **referência de formato**, não como dependência.
**Método:** leitura arquivo a arquivo de `new_sali/core` (conversores e call
sites em `backend/lib`/`frontend/lib`) e do que já existe em `dart_quill`.

---

## 1. O achado que muda tudo: metade do trabalho já está feita aqui

`dart_quill` **já tem um conversor Delta→PDF em Dart puro**, herdado do port do
canvas_editor — ele apenas **não está exportado nem coberto por testes**:

| Peça | Arquivo | Linhas |
|---|---|---:|
| Exportador Delta→PDF | `lib/src/converters/pdf/pdf_exporter.dart` | 1.073 |
| Escritor de PDF (objetos, xref, streams) | `…/office/document/pdf/pdf_writer.dart` | 259 |
| Content stream (operadores, WinAnsi) | `…/document/pdf/pdf_content.dart` | 304 |
| Imagens (JPEG/PNG + SMask) | `…/document/pdf/pdf_image.dart` | 286 |
| Rasterizador auxiliar | `…/document/pdf/raster_pdf_encoder.dart` | 147 |
| Métricas de fonte + tabelas | `…/document/fonts/*.dart` | 3.673 |
| **Total já existente** | | **5.742** |

O que ele já entrega (declarado no cabeçalho do arquivo e conferido no código):
parágrafos com quebra de linha por métrica real, alinhamento incluindo
justificado, headers 1–6, negrito/itálico/sublinhado/tachado/cor/realce/sub e
sobrescrito, listas ordenadas e com marcador, **hiperlinks com anotação
clicável**, imagens de data URI (JPEG e PNG não-entrelaçado, com alpha via
SMask), tabelas com largura de coluna vinda dos ops `table-col`, e paginação
automática que não quebra uma linha de tabela ao meio.

**Limitações declaradas** (é aqui que está o trabalho real):

1. texto sai em **WinAnsi (cp1252)** — sem fonte embutida; fora do cp1252 vira `?`;
2. largura do negrito é **estimada** (×1,05 sobre a métrica regular);
3. tabela ignora `rowspan` e tabela aninhada;
4. níveis de `indent` de lista não são representados.

## 2. O que o SALI exige além disso

Do `new_sali/core/lib/src/services/pdf` (634 l., 9 arquivos) e do
`backend/.../despacho_pdf_service.dart:48`, o PDF assinado precisa de:

- **fontes reais embutidas**: Inter (base/bold/italic/boldItalic) como padrão e
  Arial/Calibri **sob demanda** — é política de documento, escrita em
  `sali_pdf_font_families.dart`, e é incompatível com a limitação (1) acima;
- **configuração de página vinda do próprio Delta**: `page-orientation` e
  `page-margin` (faixa válida 0,5–5 cm), com fallback A4 retrato/2 cm para
  deltas antigos;
- **sanitização** dos ops antes de renderizar: descartar `script`, `color`,
  `background` e os `page-*`, e normalizar `font-family` contra a whitelist
  `{inter, arial, calibri}` com aliases (`arimo`→`arial`, `helvetica`→`arial`);
- **dois layouts**: `signedDocument` (margem 2 cm) e `editorExport` (1 cm);
- **tabelas do table-better** com `rowspan`/`colspan` e larguras medidas — o
  editor grava isso no Delta e o PDF assinado tem de bater com a tela.

## 3. O que NÃO vamos portar do new_sali

O `quill_to_pdf` (5.446 l.) existe para falar com o `pdf_plus`: é um tradutor
Delta→*widgets* (`pw.Widget`, `pw.RichText`, `pw.SpanningTable`… **68 APIs
distintas**). Portá-lo obrigaria a reimplementar um motor de layout tipo Flutter
inteiro — constraints, `MultiPage`, `LayoutBuilder`, `FittedBox`, `SvgImage` —
para depois desenhar o mesmo que o nosso exportador já desenha direto no content
stream. **É exatamente o inchaço que a restrição do projeto rejeita.**

Do lado do PDF, o `new_sali` entra como **especificação e banco de testes**, não
como código: os 7 testes e os fixtures de delta real (`Férias`, `TR de sistema`,
`tabela com colunas iguais`) migram e passam a ser o contrato do nosso
exportador.

Também não vêm: `highlight` (14.609 l. — temos o realçador de `lib/src/highlighter/`),
`numerus` (numeração romana: ~40 linhas próprias), `quill_delta_easy_parser`
(o nosso exportador já tem o seu parser), `delta_html` e `delta_to_pdf` (mortos,
zero call sites).

Do lado do HTML, aí sim o port é direto: `nadar_delta_to_html` (31 arq., 1.899
l.) é string-in/string-out, e a única dependência externa (`csslib`) está
confinada em `utils/css_util.dart` (107 l.).

## 4. Desenho alvo

```
package:dart_quill/dart_quill.dart          # editor        → só `web`
package:dart_quill/dart_quill_docx.dart     # DOCX ⇄ Delta  → já existe
package:dart_quill/dart_quill_html.dart     # Delta ⇄ HTML  → `html`
package:dart_quill/dart_quill_pdf.dart      # Delta → PDF   → sem deps
```

**Dependências: `web` e `html`.** O critério de aceite do inventário
("única dependência runtime: `web`") passa a admitir **uma** exceção, decidida
em 2026-07-30: o package `html`, usado só pelo import de HTML externo.

**Fontes são da aplicação — decidido em 2026-07-30.** A biblioteca embute o
*código* que lê e embute um TTF, **nunca os arquivos `.ttf`**. O que é permitido
em Dart são **arquivos de métricas das fontes padrão do PDF** — que já existem
(`document/fonts/metrics_data.dart`, 3.282 l.) e seguem sendo o fallback sem
assets. Para fontes reais, a biblioteca expõe **só as APIs de carregamento**,
servindo backend e frontend com a mesma interface: o consumidor entrega os
bytes (`PdfFontSource.fromBytes`) ou um resolvedor
(`Future<Uint8List?> Function(String)`), e o SALI continua dono da
Inter/Arial/Calibri e dos caminhos onde elas moram.

---

## 5. Fases

### P0 — Expor e travar o que já existe — ✅ **CONCLUÍDO (2026-07-30)**
- [x] P0.1 `lib/dart_quill_pdf.dart` exporta `deltaToPdf` e `PdfExportOptions`. Antes disso o exportador era **código morto para quem consome o pacote**.
- [x] P0.2 `test/support/pdf_reader.dart` — leitor mínimo de PDF só para teste (header, trailer `/Root`, `/Count` da árvore de páginas, tabela xref, `/MediaBox`, streams FlateDecode e extração de texto com `Tj`/octais em cp1252). *Achado: o `zlibEncode` do `PdfWriter` envolve o deflate cru com header zlib (RFC 1950), enquanto o `Inflate` embutido consome deflate cru — o leitor precisa descascar os 2 bytes de header e o Adler-32.*
- [x] P0.3 Os 4 fixtures de delta real do SALI copiados para `test/assets/delta/` (conferidos por md5: são quatro documentos distintos, não cópias) e renderizados: `documento`, `férias`, `tabela com colunas iguais`, `termo de referência` (2,1 MB).
- [x] P0.4 **16 casos** em `test/unit/converters/pdf_export_test.dart`: estrutura (xref apontando para objetos reais, `%%EOF`, `/Root`), tamanho de página e margens, título no `/Info`, paginação, anotação de link clicável, texto pesquisável, e **determinismo** (o mesmo Delta produz os mesmos bytes — é o que permite o backend hashear o PDF em SHA-256 e provar depois que o assinado é o que foi gerado).
- [x] P0.5 A limitação do cp1252 está **fixada como teste**, não como comentário: `preço` passa, `日本` não. No dia em que o P1 entregar as fontes embutidas, esse teste falha e é reescrito — em vez de continuar passando silenciosamente.
- **Resultado:** 972 VM verdes, `dart analyze` limpo, `pubspec.yaml` **inalterado** (zero dependências).

### PX — Faxina e integração de `lib/src/dependencies/` (2–3 dias) — parcialmente feito
O diretório `dependencies/` diz "código de fora, tratado como caixa-preta". Boa
parte dele **não é mais isso**: há código escrito do zero aqui e há código morto.
Enquanto ficar sob esse nome, ninguém o refatora, ninguém o testa direito, e o
`dart2js` carrega o que não deveria existir.

**Levantamento (medido com um analisador de alcançabilidade a partir dos quatro
entrypoints):** 226 arquivos em `lib/`, **196 alcançáveis, 30 não**.

- [x] **PX.1 Código morto removido (2026-07-30): 2.099 linhas.**
  - `dependencies/quill_delta_easy_parser/` (17 arq., 1.918 l.) — importado **só por si mesmo**; nada no pacote o alcança.
  - `core/attributes/attributor_store.dart` (21 l.) — o "AttributorStore ingênuo" que o inventário já registrava como morto no **B19**; o real é o de `formats/abstract/attributor.dart`.
  - `canvas_editor/ce_fonts.dart` e `ce_pdf.dart` (barris que ninguém importa) e `document/pdf/raster_pdf_encoder.dart` (147 l.), alcançável só pelo barril morto.
  - *Falsos positivos confirmados e **preservados**: `platform_stub.dart` e `dom_interop_stub.dart` (só chegam por `import ... if (dart.library.js)`, que o analisador não segue) e `diff_match_patch/src/diff/*.dart` (são `part` de `src/diff.dart`). Apagar qualquer um deles quebraria o pacote.*
- [x] **PX.2 O que foi escrito aqui saiu de `dependencies/` (2026-07-30).** Chamar de dependência código nascido neste repositório é enganoso:
  - `dependencies/dart_highlight/` → **`lib/src/highlighter/`** (barril `highlighter.dart`)
  - `dependencies/dart_math/` → **`lib/src/math/`** (barril `tex_math.dart`)
  - Testes acompanharam (`test/unit/highlighter/`, `test/unit/math/`) e o README foi atualizado.
- [x] **PX.3 `dart_quill_delta` → `lib/src/delta/` (2026-07-30).** É *o modelo do editor*, com **66 consumidores** — o oposto de uma dependência externa. O barril virou `delta/delta.dart`.
- [x] **PX.4 `diff_match_patch` → `lib/src/delta/diff_match_patch/` (2026-07-30).** Consumidor único: `Delta.diff`. Agora mora junto de quem o usa; o nome fica, porque é o nome do algoritmo e é o que preserva a procedência.
- [x] **PX.5 `canvas_editor` → `lib/src/office/` (2026-07-30).** O nome dizia "editor de canvas", que é de onde o código veio, não o que ele faz aqui: OOXML (`document/{docx,opc,xml,zip}`), escritor de PDF (`document/pdf`), métricas de fonte (`document/fonts`), o modelo de elementos (`editor/`) e as pontes Delta⇄docx (`word/`). Movido inteiro, preservando a estrutura interna — os imports relativos internos continuaram válidos e só os 5 consumidores externos mudaram. Ganhou **`lib/src/office/README.md`** com a procedência (port do canvas-editor, o que foi adaptado) e o mapa dos diretórios.
- [x] **PX.5b `lib/src/dependencies/` deixou de existir (2026-07-30).**
- [ ] **PX.6 Guarda contra reincidência:** `tool/find_unreachable.dart` (o analisador usado aqui) vira ferramenta versionada, com `--check` para o CI reprovar código morto novo. Ele precisa entender `part` e `import ... if (...)` antes de virar guarda — os dois falsos positivos acima.
- **Aceite:** suíte verde a cada passo; `lib/src/dependencies/` contendo **só** o que veio mesmo de fora, cada um com um README de procedência.

### P1 — Fontes TrueType embutidas (3–5 dias) — **o item crítico**
É o que separa o exportador atual do PDF do SALI. Sem isso, `Inter`/`Arial`/
`Calibri` não existem no PDF e qualquer caractere fora do cp1252 vira `?`.
- [ ] P1.1 **Parser TTF/OTF mínimo**: tabelas `head`, `hhea`, `hmtx`, `maxp`, `cmap` (formatos 4 e 12), `loca`, `glyf`, `name`, `post`, `OS/2`. Só leitura, só o que o embedding exige. Referência de formato: `dart_graphics/lib/src/typography/openfont/`, `jsPDF/lib/src/libs/ttffont.dart` e `itext/lib/src/io/font/` — **como referência, sem copiar dependência**.
- [ ] P1.2 **Subsetting**: manter só os glifos usados pelo documento, remapeando `loca`/`glyf` e recalculando `hmtx`. É o que impede o PDF de um despacho de 2 páginas pesar 2 MB por causa de quatro variantes da Inter.
- [ ] P1.3 **Embedding CID**: `/Type0` + `/Identity-H`, `CIDFontType2`, `/FontFile2` (subset comprimido em Flate — o codec zlib **já existe** em `office/document/zip/codecs/zlib/`), `/W` a partir do `hmtx` e **`/ToUnicode`**, sem o qual copiar texto do PDF assinado devolve lixo.
- [ ] P1.4 Trocar a medição: `FontMetrics` passa a ler `hmtx` da fonte embutida, eliminando a estimativa ×1,05 do negrito (limitação 2).
- [ ] P1.5 API: `PdfFontSource.fromBytes(Uint8List, family: 'inter', weight/style)`, um `PdfFontRegistry` que resolve família→fonte e cai nas standard-14 quando não há bytes.
- **Aceite:** PDF com Inter embutida abre no Acrobat/Chrome/Word; texto copiado volta correto (inclusive `ç`, `ã`, `—`); um teste mede o tamanho do arquivo para provar que o subset funcionou.

### P2 — Paridade de documento com o SALI (2–3 dias)
- [ ] P2.1 Page setup a partir do Delta: `page-orientation`/`page-margin`, faixa 0,5–5 cm, fallback A4/2 cm — literal ao `sali_quill_pdf_defaults.dart`.
- [ ] P2.2 Os dois layouts (`signedDocument` 2 cm, `editorExport` 1 cm).
- [ ] P2.3 Sanitização dos ops + normalização de `font-family` com os aliases.
- [ ] P2.4 Empacotar como **perfil opcional** (`SaliPdfProfile`), fora do caminho padrão: o `new_sali` apaga o código dele sem que a biblioteca fique com regra de negócio no caminho principal.
- **Aceite:** `sali_page_setup_pdf_test.dart` e `sali_pdf_font_families_test.dart` portados e verdes.

### P3 — Tabelas fiéis ao table-better (2–3 dias)
- [ ] P3.1 `rowspan`/`colspan` (limitação 3) — o modelo já está no Delta que **este** editor grava.
- [ ] P3.2 Larguras: `colgroup`/`table-col` e as medidas que o editor grava no Delta, para o PDF bater com a tela.
- [ ] P3.3 Bordas, alinhamento vertical e fundo por célula; tabela aninhada ao menos não pode sumir silenciosamente.
- [ ] P3.4 Níveis de `indent` em listas (limitação 4).
- **Aceite:** `quill_table_better_pdf_test.dart` e `table_aware_delta_parser_test.dart` portados; o fixture "colunas iguais menores que a largura da página" renderiza com as larguras certas.

### P4 — Delta ⇄ HTML — ✅ **CONCLUÍDO (2026-07-31)**
- [x] P4.1 `nadar_delta_to_html/` (31 arq., 1.899 l.) copiado para `lib/src/converters/html/`, com os imports apontando para o Delta daqui. **Nenhuma mudança de lógica foi necessária** — o achado do §2.1 se confirmou na prática: o `Delta` deste pacote é superconjunto do de lá.
- [x] P4.2 `utils/css_util.dart` reescrito **sem `csslib`**: um parser de declarações que respeita parênteses (`rgb(1, 2, 3)`, `url(a;b)`) e aspas. O original embrulhava o estilo num seletor falso (`.x { … }`), parseava uma folha inteira e caminhava a AST com dois níveis de `try`/`catch` para lidar com mudanças de API.
- [x] P4.3 `lib/dart_quill_html.dart` exporta `deltaToHtml(Delta)`, `opsToHtml(List)` — para o Delta que chega do banco, sem construir um objeto só para converter — e `HtmlConvertOptions` (escape e o wrapper `<div style="…">` que o frontend do SALI concatenava à mão, agora com a constante `saliDocumentStyle`).
- [x] P4.4 **30 casos** (`html_export_test.dart` 19, `css_util_test.dart` 11): formatos inline e de bloco, escape de `<script>`, wrapper, os 4 documentos reais do SALI (com asserção de que uma amostra do texto sobrevive — sem isso um conversor que devolvesse `<p></p>` passaria), tabela virando `<table>` e determinismo.
- **Dois defeitos reais encontrados, ambos silenciosos:**
  1. `stripWidthQuick` usava a flag inline `(?i)`, que **Dart não aceita**: qualquer chamada lançava `FormatException`. O comentário "use apenas como último recurso" é provavelmente a razão de nunca ter estourado em produção.
  2. Depois de corrigida a flag, `\bwidth` **não** protegia o `max-width` — o hífen já é fronteira de palavra, então `\b` casa entre `max-` e `width`. A regex passou a ancorar em início-de-string ou `;`. Levar o `max-width` junto tiraria justamente o que segura a tabela dentro da página impressa.
- [x] **P4.5 HTML → Delta (2026-07-31).** `delta_from_html` (16 arq., 2.162 l.) em `lib/src/converters/html/from_html/`, exportado como `htmlToDelta(String)` mais `HtmlToDelta`/`HtmlOperations`/`CustomHtmlPart` para quem precisa customizar. É o caminho que roda **sem DOM e sem editor** — o que o backend precisa para importar documento de fora, e o que o distingue do `Clipboard.convert`, que trabalha sobre o DOM vivo do navegador.
- [x] **P4.6 `html: ^0.15.4` entrou no `pubspec.yaml`** (decisão 3), saindo de `dev_dependencies`, com o motivo escrito ao lado da linha. Verificado que o build web do demo continua compilando: quem não importa `dart_quill_html.dart` não paga por ele.
- [x] **P4.7 Round-trip provado (18 casos em `html_import_test.dart`).** É o teste que dá valor ao par: cada formato tem de sobreviver à ida **e à volta**. Um conversor pode gerar HTML bonito e mesmo assim perder o formato ao reimportar — e é assim que um documento se degrada, uma conversão de cada vez. Cobertos: negrito, itálico, link com query string, cabeçalho, lista, acentuação/travessão, e o caso que mais assusta — texto com `<` e `&` **não** pode voltar escapado duas vezes.
- **Aceite:** 1.026 VM + 96 Chrome verdes; round-trip estável nos formatos cobertos.

### P5 — Fechar a malha DOCX ⇄ HTML/PDF (1–2 dias)
- [ ] P5.1 Teste de cadeia sobre um `.docx` real: `docx → Delta → HTML` e `docx → Delta → PDF`.
- [ ] P5.2 Registrar por escrito o que o import de DOCX traz e os exports ignoram (imagens flutuantes, numeração real, page setup) — parte já está no G8 do inventário.

### P6 — Migração do new_sali (fora deste repositório)
- [ ] P6.1 `new_sali/core` depende de `dart_quill` e apaga `dependencies/{nadar_delta_to_html,quill_to_pdf,delta_from_html,highlight,numerus,quill_delta_easy_parser,delta_html,delta_to_pdf,dart_quill_delta}` — **~28 mil linhas a menos** — e o `pdf_plus` sai do `pubspec.yaml`.
- [ ] P6.2 `core/src/services/pdf/*` encolhe para o que é do SALI: caminhos dos assets e escolha do perfil.
- [ ] P6.3 Só depois, e como passo independente, o Quill TypeScript do frontend sai.

---

## 6. Onde está o risco, com honestidade

**O item caro é o P1, e ele não tem atalho.** Parser TTF + subsetting + CID/
ToUnicode é a parte que qualquer biblioteca de PDF esconde; escrever enxuto é
viável (as referências locais mostram o formato), mas é o que domina a
estimativa. Se o SALI aceitasse as 14 fontes padrão, P1 sairia inteiro — mas aí
o PDF assinado não sai em Inter, e **isso é política de documento do SALI**, não
detalhe estético. Portanto: P1 fica.

**O que reduz risco de verdade:** P0 primeiro. Expor e testar o exportador que
já existe dá, em um dia, um Delta→PDF funcionando de ponta a ponta com fixtures
reais — e transforma cada item seguinte em melhoria mensurável em cima de algo
verde, em vez de aposta.

**Estimativa:** P0 1d · P1 3–5d · P2 2–3d · P3 2–3d · P4 1–2d · P5 1–2d →
**10–16 dias** de trabalho focado, fora o P6.

## 7. Decisões — respondidas

1. **Fontes (2026-07-30):** os `.ttf` **não** entram na lib. Permitido em Dart: arquivos de **métricas** das fontes padrão do PDF. Para fontes reais, só as APIs de carregamento, servindo backend e frontend com a mesma interface.
2. **Perfil SALI (2026-07-30):** **entra aqui** e **some do `new_sali`** — sanitizer, page-setup e whitelist de fontes viram um perfil opcional desta biblioteca (P2.4).
3. **`delta_from_html` (2026-07-30):** incluído, e o package **`html` é a única dependência autorizada** a entrar no `pubspec.yaml` além de `web`. O parser de HTML externo (colagem, importação) não vale reescrever do zero — é área de segurança e de casos de borda, onde uma implementação caseira erra mais do que economiza.
4. **Ordem:** P0 ✅ → PX ✅ → **P4 (HTML)** → P1 (fontes) → P2 → P3 → P5.
