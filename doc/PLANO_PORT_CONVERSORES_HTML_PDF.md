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
| Escritor de PDF (objetos, xref, streams) | `…/canvas_editor/document/pdf/pdf_writer.dart` | 259 |
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

Também não vêm: `highlight` (14.609 l. — temos o `dart_highlight` do G13.7),
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
package:dart_quill/dart_quill_html.dart     # Delta ⇄ HTML  → sem deps
package:dart_quill/dart_quill_pdf.dart      # Delta → PDF   → sem deps
```

**Zero dependências novas no `pubspec.yaml`.** O critério de aceite do inventário
("única dependência runtime: `web`") continua valendo **para a biblioteca
inteira**, não só para o editor.

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
- [ ] **PX.3 `dart_quill_delta` → `lib/src/delta/`.** É *o modelo do editor*, com **67 consumidores** — o oposto de uma dependência externa. Mudança mecânica (um `sed` nos imports), mas grande; fazer isolada, com a suíte verde antes e depois.
- [ ] **PX.4 `diff_match_patch` → `lib/src/delta/diff/`.** Consumidor único: `Delta.diff`. Fica junto de quem o usa.
- [ ] **PX.5 `canvas_editor` (70 arq., 19.151 l.) — o caso legítimo, mas mal endereçado.** É port de um projeto de terceiros, então `dependencies/` faz sentido; o problema é que **metade dele não é editor**: `document/{docx,opc,xml,zip}` é a máquina do DOCX e `document/{pdf,fonts}` é a do PDF — as duas coisas que este plano promove a produto. Proposta: mover `document/pdf` + `document/fonts` para **`lib/src/converters/pdf/backend/`** (junto do `pdf_exporter.dart`, que já é o consumidor) e manter o resto sob `dependencies/canvas_editor` com um `README.md` dizendo de onde veio e o que foi adaptado. Fazer **depois** do P1, para não mover o chão embaixo do trabalho de fontes.
- [ ] **PX.6 Guarda contra reincidência:** `tool/find_unreachable.dart` (o analisador usado aqui) vira ferramenta versionada, com `--check` para o CI reprovar código morto novo. Ele precisa entender `part` e `import ... if (...)` antes de virar guarda — os dois falsos positivos acima.
- **Aceite:** suíte verde a cada passo; `lib/src/dependencies/` contendo **só** o que veio mesmo de fora, cada um com um README de procedência.

### P1 — Fontes TrueType embutidas (3–5 dias) — **o item crítico**
É o que separa o exportador atual do PDF do SALI. Sem isso, `Inter`/`Arial`/
`Calibri` não existem no PDF e qualquer caractere fora do cp1252 vira `?`.
- [ ] P1.1 **Parser TTF/OTF mínimo**: tabelas `head`, `hhea`, `hmtx`, `maxp`, `cmap` (formatos 4 e 12), `loca`, `glyf`, `name`, `post`, `OS/2`. Só leitura, só o que o embedding exige. Referência de formato: `dart_graphics/lib/src/typography/openfont/`, `jsPDF/lib/src/libs/ttffont.dart` e `itext/lib/src/io/font/` — **como referência, sem copiar dependência**.
- [ ] P1.2 **Subsetting**: manter só os glifos usados pelo documento, remapeando `loca`/`glyf` e recalculando `hmtx`. É o que impede o PDF de um despacho de 2 páginas pesar 2 MB por causa de quatro variantes da Inter.
- [ ] P1.3 **Embedding CID**: `/Type0` + `/Identity-H`, `CIDFontType2`, `/FontFile2` (subset comprimido em Flate — o codec zlib **já existe** em `canvas_editor/document/zip/codecs/zlib/`), `/W` a partir do `hmtx` e **`/ToUnicode`**, sem o qual copiar texto do PDF assinado devolve lixo.
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

### P4 — Delta ⇄ HTML (1–2 dias)
- [ ] P4.1 Copiar `nadar_delta_to_html/` para `lib/src/converters/html/`, reescrevendo imports para o Delta daqui (**compatível**: o nosso `Delta` é superconjunto do de lá — mesma base, só o hash difere: `quiver.hash2` × `Object.hash`).
- [ ] P4.2 Substituir `utils/css_util.dart` por um parser de declarações próprio (107 l. → ~40), eliminando o `csslib`.
- [ ] P4.3 Revisar os 22 listeners contra o que **este** editor produz: `data-list` no `<li>` (G10.10), `data-language` no code-block, e o `table_better.dart` que já existe lá.
- [ ] P4.4 API: `String deltaToHtml(Delta, {HtmlConvertOptions})`, com o wrapper `<div style="font-size:12pt…">` que hoje o frontend concatena à mão como opção.
- [ ] P4.5 Trazer `delta_from_html` (HTML→Delta, 16 arq.) para fechar o par — o frontend já o usa. *Ele depende do package `html`, hoje só em `dev_dependencies`: ou vira dependência normal (viola a regra) ou é reescrito sobre o `DomParser` da abstração de plataforma, que o clipboard já usa. **Recomendo o segundo.***
- **Aceite:** round-trip `delta → html → delta` estável nos fixtures; golden de HTML por formato.

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

## 7. Decisões que preciso de você

1. **Fontes**: confirmo que os `.ttf` **não** entram na lib (o consumidor passa os bytes)? Embutir a Inter resolveria o "funciona out-of-the-box" ao custo de ~300 KB por variante dentro do pacote.
2. **Perfil SALI** (sanitizer, page-setup, whitelist de fontes): entra como perfil opcional aqui — recomendado, some do `new_sali` — ou fica lá?
3. **`delta_from_html`** (P4.5): incluo, reescrevendo sobre o `DomParser` da abstração para não adicionar o package `html` como dependência?
4. **Ordem**: começo pelo P0 (expor + testar o que já existe) ou você prefere P4 (HTML) primeiro, que é mais barato e já substitui o `getValidSemanticHTML` do frontend?
