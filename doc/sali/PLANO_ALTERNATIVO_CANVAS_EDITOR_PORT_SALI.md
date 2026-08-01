# Plano alternativo B — tornar o `canvas-editor-port` o editor principal do SALI

**Status:** alternativa para spike e comparação de valor

**Data:** 2026-07-31

**Produto candidato:** `C:\MyDartProjects\canvas-editor-port`

**Aplicação-alvo:** `C:\MyDartProjects\new_sali`

**Decisão comparada:** [ADR_ESCOLHA_ENGINE_EDITOR_NEW_SALI.md](ADR_ESCOLHA_ENGINE_EDITOR_NEW_SALI.md)

**Plano concorrente:** [PLANO_ALTERNATIVO_DOCX_RENDERING_SALI.md](PLANO_ALTERNATIVO_DOCX_RENDERING_SALI.md)

## 0. Resposta direta

É tecnicamente possível expandir o `canvas-editor-port` para importar e
exportar:

- Delta Quill 2.0.3;
- table-better conforme usado pelo SALI;
- `headerImage`;
- fontes/tamanhos;
- page setup;
- `table-temporary.col-widths`;
- HTML semântico;
- OfficeDelta;
- DOCX/PDF.

Esta alternativa possui pontos fortes concretos:

- editor e viewer incorporáveis;
- aparência compacta/Word;
- paginação física já funcional;
- controle próprio de métricas e desenho;
- virtualização de backing stores;
- layout progressivo;
- reflow incremental;
- tabelas, régua, headers/footers e PDF;
- reader/writer DOCX com preservação parcial do pacote original;
- runtime atual somente com `web`.

O bloqueio mais importante também é concreto:

> O editor real não usa `contenteditable` como superfície. Ele desenha em
> canvas e captura texto/IME por uma `HTMLTextAreaElement` oculta.

Logo, esta alternativa somente pode vencer se ocorrer uma destas decisões:

1. o requisito de `contenteditable` for substituído por requisitos mensuráveis
   de IME, acessibilidade, clipboard e seleção; ou
2. um spike provar uma camada `contenteditable` sobre o canvas sem destruir
   desempenho, seleção e fidelidade.

Sem essa decisão, investir em compatibilidade Delta pode entregar valor como
viewer/renderer, mas não torna o canvas o editor principal solicitado.

Hipótese a avaliar:

> O controle de layout, a paginação e a performance do canvas compensam o custo
> de reconstruir compatibilidade Quill/SALI e de resolver a superfície de
> entrada/acessibilidade.

## 1. Resultado de produto pretendido

```text
new_sali
   |
   v
SaliDocumentEditorFacade
   |
   v
CanvasSaliEditor
   |
   +-- simple ---------- modelo Canvas + projeção Quill
   +-- advanced/fast --- fluxo contínuo/papel aproximado
   +-- advanced/fidelity páginas Canvas determinísticas
   +-- viewer ---------- páginas virtualizadas em leitura
```

O produto precisa:

1. abrir todo despacho Quill/SALI suportado;
2. editar e salvar Delta compatível;
3. preservar table-better sem achatar tabelas;
4. alternar simples/avançado sem promover enquanto o conteúdo for Quill;
5. importar DOCX e promover para OfficeDelta;
6. reabrir apenas pelo JSON armazenado;
7. exportar DOCX/PDF;
8. manter projeções Quill/HTML;
9. preservar o fluxo histórico de assinatura;
10. oferecer fallback para o Quill JS durante o rollout.

## 2. Restrições

- editor documental 100% frontend;
- runtime em Dart;
- JavaScript/Wasm gerados pelo compilador permitidos;
- workers Dart permitidos;
- nenhuma API/engine documental no backend;
- nenhuma dependência runtime de LibreOffice, DocumentServer ou package
  externo;
- somente `web: ^1.1.1` e, se indispensável, `html: ^0.15.4`;
- compatibilidade Quill 2.0.3/table-better/SALI medida pelo corpus;
- nenhum despacho histórico regravado ao abrir;
- perda silenciosa proibida;
- duas paginações sobre o mesmo estado;
- documento avançado persistido como JSON;
- PDF assinado ligado à revisão visualizada;
- licença/proveniência resolvida antes de distribuir.

## 3. Estado atual auditado

### 3.1 Ativos do produto

O `CanvasEditorWidget` já possui:

- `CanvasEditorWidgetMode.editor/viewer`;
- `CanvasEditorAppearance.compact/word`;
- mount/destroy;
- ribbon;
- toolbar compacta;
- toolbar flutuante;
- régua;
- painéis de sumário, busca e comentários;
- status de página/zoom;
- abertura/salvamento DOCX;
- Delta Quill;
- PDF vetorial e fallback raster.

O editor interno já possui:

- modelo `IElement`;
- command layer;
- histórico;
- layout incremental;
- índice de posições por página;
- reflow até convergência;
- canvas por página;
- dirty page queue;
- headers/footers default/first/even;
- tabelas;
- TOC;
- page number;
- imagens/floats;
- controles;
- clipboard e IME manuais.

### 3.2 Performance já demonstrada

No benchmark documentado com 122.603 elementos e 143 páginas:

- primeiras quatro páginas + baseline: 1.639 ms;
- restante da paginação: +2.235 ms;
- digitação observada: 26,1 ms/tecla;
- handler aquecido: 6–15 ms/tecla;
- repaint comum: 1–6 ms;
- três canvases vivos para 143 páginas;
- 142 páginas reutilizadas em edição localizada.

Isso é uma base promissora. Ainda não prova:

- p95/p99 em browser/hardware de referência;
- table-better do SALI;
- screen reader;
- `contenteditable`;
- fidelidade Word completa;
- worker real.

### 3.3 O worker atual não é worker

`WorkerManager._runAsync` executa `Future(callback)`. O cálculo continua na main
thread.

O plano precisa introduzir worker de verdade via Web Worker compilado de Dart,
com fallback cooperativo.

### 3.4 Bridge Delta atual

`lib/src/word/quill_delta.dart` já cobre:

- texto/formatos comuns;
- headings;
- alinhamento;
- listas;
- imagem;
- parte do table-better;
- `table-col`;
- células e spans.

Mas o round-trip real do SALI ainda perde:

- `headerImage`;
- tamanho `pt` porque o parser privilegia `px`/número;
- indentação;
- page attrs;
- atributos desconhecidos;
- embeds desconhecidos;
- `table-temporary.col-widths`;
- parte dos estilos de tabela;
- geometria/headers/footers na volta para Delta;
- regiões fora de `main`.

Quando não há `table-col`, a largura pode cair no default 72, embora o SALI
grave larguras em `table-temporary`.

O modelo atual de célula não cobre integralmente padding por lado, largura/cor/
estilo de borda por lado, regra de altura e toda a CSS table-better. Não basta
melhorar o serializer: o modelo editável precisa ganhar `ICellStyle` tipado.

### 3.5 Sessão de origem

O widget mantém `_openedDocx`, `_openedConvertedMain` e
`_openedOriginalMain` para patch/preservação no save.

`loadQuillDelta` substitui o valor do editor, mas não demonstra limpar essa
origem DOCX. Sem correção, um Delta aberto depois de um DOCX pode ser salvo
contra o baseline anterior.

Toda entrada deve iniciar uma nova `DocumentSourceSession` atômica.

### 3.6 HTML, clipboard, PDF e eventos públicos

O pipeline atual ainda precisa de hardening:

- HTML de paste é anexado ao DOM para obter computed style e aceita elementos
  ricos; precisa ser sanitizado antes de qualquer montagem;
- o clipboard interno usa `localStorage` global; precisa de payload versionado,
  hash, `sessionId` e TTL;
- o PDF vetorial atual usa Standard-14/WinAnsi, portanto caracteres fora de
  cp1252 podem virar `?`;
- block/latex não possuem representação vetorial completa;
- imagens vetoriais aceitam um subset de data URLs;
- o `headerImage` SALI pode ser SVG/URL e precisa de resolução/rasterização
  controlada;
- fallback raster não pode ocorrer silenciosamente em documento jurídico;
- `CanvasEditorConfig` ainda não expõe um contrato público completo de
  `contentChanged`, `ready`, `dirty`, `focus`, `blur` e `touched`.

Esses itens entram no caminho crítico de integração, mesmo que a tela Word já
pareça funcional.

## 4. Gate arquitetural de entrada: textarea ou `contenteditable`

Este gate deve ocorrer antes de investir pesado no codec.

### 4.1 Caminho B1 — manter canvas + textarea

É o caminho coerente com a arquitetura atual:

- canvas continua visual;
- textarea oculta captura input/composition;
- cursor/seleção permanecem próprios;
- DOM semântico virtualizado auxilia acessibilidade;
- clipboard possui writer/reader próprios.

Vantagens:

- menor mudança;
- preserva performance;
- preserva layout determinístico;
- reaproveita history/eventos atuais.

Desvantagens:

- não atende literalmente ao requisito `contenteditable`;
- screen reader não recebe semântica rica automaticamente;
- seleção nativa do browser não representa o documento;
- IME/bidi/mobile exigem manutenção própria;
- plugins/ecossistema DOM não se aplicam.

Escolher B1 significa registrar formalmente que o requisito real é
“edição web acessível e compatível”, não “DOM contenteditable”.

### 4.2 Caminho B2 — overlay `contenteditable` ativo

Spike proposto:

```text
CanvasActiveBlockEditor
  active paragraph/cell -> HTMLElement contenteditable posicionado
  beforeinput/composition -> Canvas transactions
  DOM selection <-> DocumentPositionMap
  commit/reconcile -> repaint canvas
```

Durante a edição:

- o bloco/célula ativo ganha overlay DOM;
- os glyphs equivalentes no canvas ficam ocultos;
- CSS usa as mesmas métricas;
- input/composition ocorrem no `contenteditable`;
- cada mudança vira mutação tipada;
- blur/selection move desmonta ou reposiciona o overlay.

O spike precisa provar:

- seleção dentro do bloco;
- seleção atravessando blocos;
- seleção atravessando páginas;
- células/tabelas;
- formatação mista;
- IME;
- emoji/combining;
- bidi;
- paste/drop;
- undo/redo;
- zoom;
- scroll;
- screen reader;
- latência.

Limitação honesta: um único overlay ativo não transforma o documento inteiro
em superfície `contenteditable`. Para seleção DOM nativa entre páginas seria
necessário montar múltiplos blocos DOM e reconciliar duas renderizações. Isso
se aproxima de escrever um segundo engine.

### 4.3 Caminho B3 — documento inteiro `contenteditable`

Renderizar uma árvore DOM editável completa por trás/sobre o canvas:

- duplica layout;
- cria duas autoridades visuais;
- enfraquece o principal benefício do canvas;
- exige reconciliar browser layout com métricas próprias;
- aproxima o projeto do `docx_rendering`.

B3 não é recomendado. Se for obrigatório, a alternativa canvas deve receber
veredito **no-go como produto principal** e permanecer renderer/viewer.

### 4.4 Critério do gate

| Resultado do spike | Decisão |
|---|---|
| B1 aceito pelo produto e a11y aprovado | Continuar canvas |
| B2 atende casos e SLOs | Continuar com overlay |
| Full contenteditable continua obrigatório | Não escolher canvas |
| A11y/IME falha sem correção clara | Não escolher canvas |

## 5. Contrato Quill/SALI

### 5.1 Codec público

Criar:

```text
QuillDeltaJsonCodec
QuillDocumentSnapshot
QuillChangeDelta
QuillCompatibilityReport
QuillSecurityLimits
SaliQuill203Profile
```

Entrada:

- envelope `{"ops":[...]}`;
- lista legada opcional;
- JSON validado antes de tocar o modelo.

Saída pública:

- sempre envelope;
- serialização canônica;
- atributos/payloads deep-copied;
- perda e sanitização classificadas.

### 5.2 Posições

O canvas usa índices do modelo e estruturas físicas de página. Quill usa UTF-16
e embed com comprimento 1.

Partes do canvas segmentam texto por graphemes/`Intl.Segmenter`. Esse índice é
correto para algumas operações visuais, mas não pode ser reutilizado como
índice Delta. Emoji, combining marks e pares surrogate precisam de mapeamento
explícito entre as duas unidades.

Criar:

```text
QuillDocumentIndex
  op/range Quill <-> ElementLocator <-> Position/page
```

Requisitos:

- índices UTF-16;
- newlines explícitos;
- linhas em células;
- headerImage/imagem como 1;
- stable IDs;
- seleção/bookmark;
- atualização incremental;
- nenhuma posição no meio de surrogate pair.

### 5.3 Metadata lossless

`IElement.extension` já é usado para metadata, mas `dynamic Map` espalhado não
é contrato suficiente.

Criar tipos:

```text
InteropMetadataStore
QuillRunMetadata
QuillLineMetadata
QuillEmbedMetadata
QuillTableMetadata
OfficeSourceAnchor
```

Cada `IElement`/bloco/tabela recebe ID estável. O store preserva:

- atributos conhecidos em representação original;
- atributos desconhecidos;
- op/embed original;
- ID de linha/célula;
- source range;
- política de edição/projeção;
- hash/revisão.

Metadata deve ser clonada, comparada e serializada de forma profunda. Não
guardar referências mutáveis ao JSON de entrada.

### 5.4 Atributos inline

Suportar:

- bold/italic/underline/strike;
- color/background;
- font;
- size `pt` e tokens originais;
- script;
- code;
- link;
- width/height de embeds;
- desconhecidos opacos.

O modelo pode usar px internamente, mas a metadata preserva unidade/token
original. Ao editar tamanho, o profile emite um valor SALI válido.

O modelo atual usa tamanho inteiro em pontos importantes do pipeline. Para
layout estável, introduzir `CssLength`/`double fontSizePx` sem remover
imediatamente o campo compatível: `10pt = 13,333...px` não pode ser truncado a
13px ao longo de centenas de linhas.

Métricas/fontes devem vir de assets locais e legalmente licenciados. Não usar
CDN. O layout aguarda `FontFace`/font load antes de congelar a paginação e
registra fallback no `CompatibilityReport`.

### 5.5 Atributos de linha

Suportar:

- header;
- align;
- direction;
- indent;
- list;
- code-block;
- page attrs;
- table-better;
- desconhecidos.

O modelo plano precisa de identidade explícita de parágrafo. Newline não pode
ser apenas texto sem metadata quando carrega atributos Quill.

### 5.6 Table-better

Refatorar o converter atual em:

```text
TableBetterDeltaDecoder
TableBetterModelBuilder
TableBetterDeltaEncoder
TableBetterIdAllocator
TableBetterCompatibilityAnalyzer
```

Cobertura:

- `table-col`;
- `table-cell-block`;
- `table-th-block`;
- `table-cell`;
- `table-th`;
- `table-temporary`;
- `data-row`;
- width/height;
- colspan/rowspan;
- styles/borders/background/padding;
- múltiplos parágrafos;
- lists/headings em célula;
- merge/split;
- resize;
- nested table quando presente;
- `col-widths`.

Regras:

- nunca default 72 se `col-widths` válido existir;
- introduzir `ICellStyle` com padding, border style/width/color por lado,
  background, vertical align, preferred width e regra de altura;
- manter raw CSS/table metadata enquanto a célula estiver intocada;
- preservar IDs em no-op;
- regenerar somente estrutura alterada;
- derivar `col-widths` de `IColgroup`, nunca de uma `<table>` DOM inexistente;
- representar headers de tabela;
- mapear styles completos;
- bloquear tabela inconsistente;
- comparar com goldens do JavaScript real.

### 5.7 `headerImage`

Adicionar papel semântico ao modelo:

```text
ElementType.saliHeaderImage
SaliHeaderImageMetadata
```

ou um tipo de embed extensível equivalente.

O node:

- comprimento Quill 1;
- preserva source;
- não se confunde com imagem comum;
- possui política explícita de remoção;
- aparece no HTML/Delta;
- pode virar header Office quando promovido apenas por comando explícito.

### 5.8 Page setup

Ao importar:

- ler `page-orientation`/`page-margin` da primeira linha;
- aplicar defaults A4/retrato/2cm quando ausentes;
- configurar page width/height/margins do editor;
- manter metadata Quill.

Ao exportar:

- gravar atributos na convenção SALI;
- atualizar somente quando page setup mudou;
- não derivar valores de arredondamentos cumulativos do canvas.

### 5.9 Paste Word

O handler de paste precisa aceitar:

- `text/html`;
- `text/plain`;
- imagens quando permitido.

Pipeline:

1. limites e sanitizer;
2. detectar HTML Word;
3. normalizar listas/marcadores;
4. mapear bold/classes;
5. preservar parágrafos vazios/espaçamento conforme contrato SALI;
6. converter tabela HTML;
7. gerar mutação tipada;
8. emitir Delta/HTML canônico;
9. registrar itens removidos.

Portar comportamento, não executar o JavaScript SALI como dependência.

## 6. Arquitetura proposta no `canvas-editor-port`

### 6.1 Novos módulos

```text
lib/src/sali/
  editor/
    sali_canvas_editor.dart
    sali_editor_facade.dart
    sali_editor_mode.dart
    document_source_session.dart
    document_export_bundle.dart
    document_authority.dart
  quill/
    quill_delta_json_codec.dart
    quill_document_snapshot.dart
    quill_attribute_pool.dart
    quill_document_index.dart
    quill_compatibility_report.dart
    quill_security_limits.dart
    sali_quill_203_profile.dart
    quill_to_elements.dart
    elements_to_quill.dart
    table_better_codec.dart
    sali_header_image_codec.dart
    sali_page_setup_codec.dart
    sali_paste_normalizer.dart
    sali_semantic_html.dart
  interop/
    interop_metadata_store.dart
    interop_transaction_hook.dart
    opaque_embed.dart
  office/
    office_delta_codec.dart
    office_source_map.dart
    office_projection.dart
    office_promotion.dart
  input/
    canvas_contenteditable_bridge.dart
    semantic_accessibility_mirror.dart
  worker/
    worker_protocol.dart
    worker_client.dart
    worker_entrypoint.dart
```

### 6.2 Refatorar `QuillDeltaConverter`

Manter temporariamente:

```dart
QuillDeltaConverter.toDelta(...)
QuillDeltaConverter.fromDelta(...)
```

como facade deprecated.

O novo pipeline separa:

- parsing/validation;
- flat Delta tokenization;
- construção do modelo;
- metadata;
- serialização;
- análise de compatibilidade.

### 6.3 `DocumentSourceSession`

Toda abertura chama:

```text
beginFromQuill(...)
beginFromOfficeDelta(...)
beginFromDocx(...)
beginEmpty(...)
```

A troca:

- cancela layout/worker anterior;
- limpa `_openedDocx` e referências incompatíveis;
- revoga URLs/assets;
- substitui authority/baseline;
- reinicia history;
- carrega o novo modelo;
- publica readiness somente após transação atômica.

Isso corrige a ambiguidade atual entre `loadQuillDelta` e o baseline DOCX.

### 6.4 Estado canônico

```text
CanvasDocumentSession
  authority
  IEditorData
  InteropMetadataStore
  QuillDocumentIndex
  OfficeSourceMap?
  openedPackageBaseline?
  dirtyRegions
  semanticRevision
  CompatibilityReport
```

Autoridade:

| Entrada/estado | Autoridade |
|---|---|
| HTML-only legado | HTML em leitura até conversão explícita |
| Quill não promovido | Quill snapshot |
| DOCX | OfficeDelta |
| Quill com feature Office | OfficeDelta |

O modelo `IElement` é a projeção editável, mas metadata/baseline fazem parte da
mesma sessão e do mesmo checkpoint.

### 6.5 Mutação/histórico

Cada mutação precisa informar:

- locator/range;
- elementos removidos/inseridos;
- metadata afetada;
- região dirty;
- source anchors;
- mudança de autoridade/capability.

Não é suficiente editar `IElement` e tentar reconstruir metadata no save.

## 7. Modos

### 7.1 `simple`

- aparência compacta;
- comandos limitados ao perfil SALI;
- Delta continua canônico;
- sem régua/paginação pesada;
- projeção visual pode ser contínua;
- Office-only bloqueado.

### 7.2 `wordFast`

- aparência Word;
- páginas/flutuadores aproximados;
- layout progressivo;
- quebra não precisa coincidir com Word;
- usa mesmo estado;
- promoção apenas ao usar feature Office.

### 7.3 `wordFidelity`

- páginas físicas;
- regras Word por seção;
- headers/footers;
- tabela entre páginas;
- fields/TOC;
- floats;
- métricas de fonte determinísticas;
- layout até convergência.

### 7.4 `viewer`

- canvas é particularmente adequado;
- somente páginas viewport ± overscan mantêm backing store;
- sem caret/input;
- pode oferecer miniaturas e PDF;
- HTML/Delta continuam derivados.

## 8. Dois paginadores

### 8.1 Paginador leve

Criar modo contínuo com “papel” aproximado:

- linhas/layout contínuo;
- marcadores visuais de página;
- headers/footers somente como decoração opcional;
- sem exigir fragmentação exata;
- menor trabalho por edição;
- útil para despachos Quill comuns.

Pode reaproveitar:

- o `PageMode.continuity` já exposto pelo widget;
- layout incremental;
- `LayoutScheduler`;
- `PageRowIndex`;
- dirty ranges;
- posição por página lógica.

### 8.2 Paginador de fidelidade

Evoluir o paginador atual:

- usar `PageMode.paging`/print layout como base do perfil;
- fragmentos de tabela como estado derivado;
- reflow regional após mudança anterior à tabela;
- row/header repetition;
- keep lines/keep next;
- widow/orphan;
- section breaks;
- first/even headers;
- footnotes;
- floats/wrap;
- page fields;
- TOC estabilizado;
- métricas de fontes.

### 8.3 Contrato comum

```text
DocumentRevision + resolved style + geometry + dirty region
   -> LayoutSnapshot
```

Trocar paginador:

- não muda o snapshot;
- não cria entrada de history;
- não altera Delta;
- não altera source anchors;
- preserva seleção lógica.

## 9. Worker real

Tarefas candidatas:

- inflate/deflate;
- XML tokenization;
- package index;
- style/numbering resolution;
- Quill token/index;
- layout puro de ranges;
- paginação não visual;
- OfficeDelta;
- DOCX;
- PDF.

Não enviar ao worker:

- canvas context;
- nodes DOM;
- selection DOM;
- eventos.

Protocolo:

- `requestId`;
- `documentRevision`;
- `sourceHash`;
- cancelamento;
- transferables;
- resposta determinística;
- descarte de resposta obsoleta;
- fallback em slices ≤ orçamento.

Wasm só é selecionado após benchmark mostrar vantagem sobre JavaScript.

## 10. HTML semântico

O canvas não possui DOM semântico naturalmente equivalente ao conteúdo
desenhado.

Criar `SaliSemanticHtmlWriter` sobre o modelo lógico:

- parágrafos/headings;
- listas/indent;
- links/citações;
- spans de estilo;
- imagens/headerImage;
- table/thead/tbody/tr/td;
- rowspan/colspan;
- atributos permitidos;
- sanitizer;
- HTML determinístico.

O writer não deve ler pixels/canvas para reconstruir conteúdo.

Para acessibilidade, um `SemanticAccessibilityMirror` pode materializar somente
o viewport e contexto da seleção. Ele não vira a fonte de verdade.

## 11. DOCX e OfficeDelta

### 11.1 Aproveitar a preservação existente

O projeto já:

- mantém o `DocxFile` aberto;
- guarda referência convertida/original;
- reutiliza blocos intocados;
- preserva blocos/parts desconhecidos;
- aplica patch em conteúdo alterado;
- reancora após save;
- possui sync localizado de text box em header.

Isso é mais próximo de um writer preservador que regenerar o pacote inteiro.

### 11.2 Lacunas

- baseline existe apenas em memória;
- source stamps precisam ser formalizados;
- múltiplas seções/regiões precisam entrar no snapshot;
- patch de text box atual possui limitações;
- metadata dinâmica precisa de schema;
- parts/relationships/assets precisam de catálogo integral;
- diferença entre conteúdo semântico e opaco precisa ser explícita;
- save após trocar a origem precisa ser seguro.

### 11.3 OfficeDelta

Adicionar:

```json
{
  "ops": [
    {
      "insert": {
        "office-manifest": {
          "format": "sali-canvas-office-delta",
          "snapshotVersion": 0
        }
      }
    }
  ]
}
```

Persistir:

- body/header/footer/regions;
- `IElement` semântico em forma estável;
- styles;
- numbering;
- sections;
- page geometry;
- table metadata;
- assets;
- OPC parts;
- source anchors/stamps;
- baseline/patches;
- conteúdo opaco.

O JSON precisa ser independente de identidade de objetos Dart.

### 11.4 Writer

Ao exportar DOCX:

1. reconstruir package baseline do snapshot;
2. aplicar patches das regiões dirty;
3. preservar parts opacas;
4. atualizar rels/content types;
5. validar package;
6. serializar deterministicamente;
7. emitir relatório.

### 11.5 Persistência SALI

| Campo | Conteúdo |
|---|---|
| `delta` | projeção Quill 2.0.3 válida |
| `descricao` | HTML semântico |
| `office_delta_json` | OfficeDelta canônico |
| `document_kind` | HTML-only, Quill ou Office |

Ops Office não entram inicialmente na coluna `delta` usada pelo renderer
jurídico atual.

Depois que todos os consumidores reconhecerem versão/tipo, pode-se avaliar um
envelope combinado com `ops` Quill e metadata `sali` top-level. O oracle deve
provar que leitores toleram campos extras. Isso não elimina a regra: o Quill
antigo descartará a metadata ao resalvar, logo documento promovido não pode
voltar a ele como writer.

## 12. Facade AngularDart

Preservar:

- selector `quill-text-editor`;
- `ControlValueAccessor<String>` com HTML;
- `onChange`;
- `previewRequested`;
- `addText`;
- `clearAllText`;
- `insertHeaderImage`;
- `insertInternalCitation`;
- `loadDeltaJson`;
- `getDeltaJson`;
- `getValidSemanticHTML`;
- `hasMeaningfulContent`;
- `gerarPreviewDocumentoFinalizadoBytes`;
- `reset`;
- teardown.

Adicionar:

- `isReady`;
- `loadOfficeDeltaJson`;
- `exportOfficeDeltaJson`;
- `exportBundle`;
- `switchMode`;
- `getCompatibilityReport`;
- `checkpoint`.

`DocumentExportBundle` congela, na mesma revisão:

```text
revision
deltaJson
semanticHtml
officeDeltaJson?
compatibilityReport
pdfInputHash
```

O SALI atualmente obtém HTML e Delta por chamadas separadas. O novo save deve
usar um único bundle para impedir que uma mudança ocorrida entre as chamadas
grave projeções de revisões diferentes.

Feature flags independentes:

```text
editor.engine = quill_js | canvas
editor.input = textarea | contenteditable_overlay
editor.pagination = none | light | fidelity
editor.office_import
editor.office_save
editor.client_pdf_signing
```

## 13. PDF e assinatura

### Quill

Manter o renderer/assinatura atuais durante o rollout.

### Office

O canvas possui PDF vetorial e fallback raster. Para assinatura fiel:

```text
OfficeDelta revision
 -> layout completo
 -> PDF vetorial
 -> verificação de páginas/fontes
 -> bytes congelados
 -> hash/assinatura
```

Perfis explícitos:

- `visualExact`: páginas rasterizadas, aparência preservada, texto não
  selecionável;
- `searchable`: fontes incorporadas/subset, ToUnicode, links, realces, imagens
  e texto pesquisável.

Antes do cutover, o perfil vetorial precisa incorporar fontes/Unicode, resolver
assets URL/blob/data e rasterizar SVG com APIs nativas quando necessário. Todo
item omitido vira erro/warning no `PdfExportReport`.

Não usar fallback raster silenciosamente para documento jurídico; fallback deve
ser erro explícito ou política aprovada.

Sem mudança no handoff existente, somente a projeção Quill pode ser assinada,
não o layout Office visualizado.

## 14. Fases e entregas de valor

### B0 — gate de input/acessibilidade

- decidir B1/B2/B3;
- protótipo com texto, tabela, seleção entre páginas e IME;
- screen reader;
- medir latência/memória;
- registrar decisão de produto.

**Valor:** elimina cedo o maior risco.

**No-go:** full contenteditable obrigatório ou a11y/IME sem solução.

### B1 — corpus e kernel Delta

- licença/proveniência;
- corpus SALI;
- codec envelope;
- validation/report;
- canonicalização;
- UTF-16;
- metadata typed;
- `DocumentSourceSession`.

**Valor:** decoder/validator seguro e origem sem mistura.

**Go/no-go:** round-trip do subset simples contra Quill real.

### B2 — Quill padrão

- formatos inline/bloco;
- imagens/links;
- listas/indent;
- page attrs;
- unknown passthrough;
- HTML semântico.

**Valor:** viewer/editor de Deltas simples.

**Go/no-go:** igualdade semântica e seleção estável.

### B3 — table-better e SALI

- decoder/encoder de tabela;
- spans/IDs/styles;
- `col-widths`;
- `headerImage`;
- fonts/sizes;
- paste;
- citações.

**Valor:** candidato a substituir Quill JS.

**Go/no-go:** todo corpus SALI sem perda silenciosa.

### B4 — facade e shadow mode

- wrapper Angular;
- Quill JS continua writer;
- Delta/HTML/PDF comparados;
- telemetria;
- teardown;
- fallback/kill switch.

**Valor:** validação em fluxo real.

**Go/no-go:** divergências conhecidas e reversíveis.

### B5 — writer básico e paginação leve

- liberar para novos rascunhos;
- modo compact/simple;
- paginação leve;
- autosave;
- assinatura Quill inalterada.

**Valor:** substituição progressiva e desempenho.

**Go/no-go:** SLOs e fluxo SALI aprovados.

### B6 — OfficeDelta e reabertura JSON

- snapshot;
- baseline/package catalog;
- source anchors;
- assets;
- sidecar;
- promoção/projeções.

**Valor:** persistência avançada sem DOCX binário.

**Go/no-go:** snapshot determinístico e autocontido.

### B7 — DOCX/Word fidelity

- patch writer completo;
- seções;
- headers/footers;
- TOC/fields;
- tabelas entre páginas;
- floats;
- estilos/templates;
- fidelity layout.

**Valor:** editor profissional.

**Go/no-go:** capability matrix e goldens visuais.

### B8 — worker, PDF jurídico e rollout

- worker real;
- PDF congelado;
- handoff assinatura;
- browsers;
- a11y/IME;
- segurança/fuzz;
- rollout geral.

**Valor:** fluxo Office de produção.

**Go/no-go:** auditoria, SLOs e rollback.

## 15. Scorecard de valor

| Dimensão | Métrica |
|---|---|
| Quill | percentual do corpus sem perdas |
| table-better | goldens e comandos aprovados |
| Input | B1/B2, IME, mobile, clipboard |
| Acessibilidade | screen reader/teclado/semântica |
| Performance | abertura, tecla, scroll, memória |
| Paginação | fast e fidelity no mesmo snapshot |
| DOCX | semântica + parts opacas |
| HTML | equivalência semântica SALI |
| PDF | vetor/fonte/página ligado à revisão |
| Manutenção | complexidade de modelo + metadata |
| Segurança | validator/sanitizer/fuzz |
| Migração | facade/fallback/rollback |

Hipótese:

- tende a pontuar alto em layout controlado, viewer, memória visual e PDF;
- pode pontuar alto em DOCX porque já possui patch/passthrough;
- começa baixo em Quill/SALI;
- começa criticamente baixo em `contenteditable`/a11y;
- o maior valor diferencial aparece apenas se B0 e B3 forem aprovados.

## 16. Testes obrigatórios

### 16.1 Delta/SALI

- 12.507 ops dos fixtures atuais;
- fixture ~2,18 MB/11.709 ops;
- produção anonimizada;
- canonicalização;
- UTF-16;
- fonts/sizes pt;
- indent/list;
- `headerImage`;
- page attrs;
- table-better completo;
- `col-widths`;
- attrs/embeds desconhecidos;
- no-op;
- edição localizada;
- básico/avançado;
- save após trocar DOCX → Delta.

### 16.2 Input

- textarea e/ou overlay;
- beforeinput;
- composition;
- dead keys;
- emoji/combining;
- bidi/RTL;
- seleção intra/interbloco;
- seleção entre páginas;
- tabela;
- clipboard/drop;
- mobile;
- undo/redo;
- zoom/scroll;
- screen reader.

### 16.3 DOCX

```text
DOCX -> OfficeDelta -> DOCX
DOCX -> OfficeDelta -> reabrir JSON -> DOCX
OfficeDelta -> Canvas -> OfficeDelta
QuillDelta -> Canvas -> QuillDelta
QuillDelta + Office feature -> OfficeDelta + Quill projection
```

Asserções:

- package/rels/content types;
- XML opaco;
- styles/numbering/settings;
- seções;
- header/footer variants;
- text boxes;
- tabelas;
- assets;
- fields;
- source stamps;
- relatório.

### 16.4 Segurança

- ZIP/XML bombs;
- external relationships;
- data URI;
- imagem enorme;
- HTML/CSS;
- URL;
- JSON profundo;
- metadata corrompida;
- IDs duplicados;
- source anchors inválidos;
- macros/OLE nunca executados.

## 17. SLOs provisórios comuns

| Métrica | `fast` | `fidelity` |
|---|---:|---:|
| primeira página DOCX editável | ≤ 2 s | ≤ 3 s |
| snapshot, primeira página | ≤ 1 s | ≤ 1,5 s |
| layout completo background | ≤ 4 s | ≤ 10 s |
| tecla p95 | ≤ 16 ms | ≤ 16 ms |
| tecla p99 | < 50 ms | < 50 ms |
| slice main thread | ≤ 8 ms | ≤ 8 ms |
| scroll estabilizado | ≥ 55 fps | ≥ 55 fps |
| canvases vivos | viewport ± overscan | viewport ± overscan |
| perda silenciosa | zero | zero |

O baseline atual de 26,1 ms/tecla observado pelo Puppeteer é promissor, mas não
cumpre automaticamente p95 ≤16 ms. Medir handler, browser e despacho
separadamente no mesmo harness das outras alternativas.

## 18. Riscos e mitigação

| Risco | Impacto | Mitigação/gate |
|---|---|---|
| Não é `contenteditable` | Bloqueador | B0 antes de todo investimento pesado |
| Screen reader sem árvore semântica | Crítico | mirror + testes; no-go se falhar |
| Bridge perde dados SALI | Crítico | B1–B3 e corpus |
| Modelo plano perde newline metadata | Crítico | IDs + typed metadata |
| `col-widths` ignorado | Crítico | decoder table-better exato |
| Baseline DOCX vaza entre loads | Crítico | `DocumentSourceSession` |
| Metadata vira segunda autoridade | Alto | checkpoint transacional/hashes |
| Worker continua fake | Alto | worker real + SLO |
| Tabela fragmentada força full layout | Alto | reflow regional |
| HTML semântico diverge | Alto | writer lógico/goldens |
| PDF raster usado sem aviso | Alto | política jurídica explícita |
| Assets Office inflam JSON | Alto | limites/compressão/benchmark |
| Licença/proveniência | Bloqueador | B0/B1 |

## 19. Primeiros PRs

1. Decision record B1/B2 para input.
2. Spike contenteditable/a11y isolado.
3. Corpus/goldens Quill/SALI.
4. `DocumentSourceSession` e correção de troca de origem.
5. `QuillDeltaJsonCodec`/validator/report.
6. `InteropMetadataStore` e stable IDs.
7. Separar converter em decoder/encoder/index.
8. Completar Quill padrão.
9. Completar table-better e `col-widths`.
10. Adicionar `headerImage`, page attrs, fonts/sizes.
11. HTML semântico e paste.
12. Facade Angular/shadow mode.
13. Paginação leve.
14. OfficeDelta e serialização do baseline.
15. Worker real.
16. DOCX patch/source map completo.

## 20. Condições para escolher esta alternativa

Escolher o canvas como produto principal somente se:

1. B0 produzir decisão aceitável de input/acessibilidade;
2. o corpus SALI fizer round-trip sem perda;
3. table-better editar e serializar com paridade;
4. metadata não virar uma segunda árvore impossível de manter;
5. a vantagem de layout/performance permanecer após o profile SALI;
6. OfficeDelta conseguir persistir baseline/source map;
7. o PDF vetorial representar o layout visualizado;
8. a integração Angular for reversível.

Rebaixar para viewer/renderer se:

- `contenteditable` integral continuar obrigatório;
- screen reader/IME não atingir os gates;
- B3 exigir reescrever todo o modelo;
- overlay DOM destruir a vantagem de canvas;
- a projeção Delta permanecer lossy.

Mesmo nesse resultado, o trabalho pode entregar valor como:

- visualizador rápido;
- preview paginado;
- miniaturas;
- renderer PDF;
- benchmark de layout;
- engine fidelity opcional atrás de outra fachada.

## 21. Conclusão da alternativa

O `canvas-editor-port` tem o melhor ponto de partida para controlar pixels,
memória de páginas e PDF, além de um pipeline DOCX preservador promissor.

Seu valor como editor principal depende primeiro do gate de input. Não faz
sentido investir meses em compatibilidade table-better e descobrir no final que
o produto exige uma superfície `contenteditable` integral.

Se B0 e B3 passarem, a alternativa pode competir de forma séria. Se B0 falhar,
o uso de maior valor é renderer/viewer de fidelidade, e não substituto do
editor Quill.

## 22. Evidências locais principais

### `canvas-editor-port`

- `pubspec.yaml`: runtime atual somente com `web`;
- `lib/src/components/canvas_editor/canvas_editor_widget.dart:27-86`: modos,
  aparência e facade;
- `canvas_editor_widget.dart:127-130`: baseline DOCX em memória;
- `canvas_editor_widget.dart:520-575`: aplicação de DOCX/regiões;
- `canvas_editor_widget.dart:624-655`: patch/preservação no save;
- `canvas_editor_widget.dart:774-782`: Delta atual;
- `canvas_editor_widget.dart:895-910`: destroy;
- `lib/src/editor/core/cursor/cursor_agent.dart:6-45`: textarea de entrada;
- `lib/src/editor/core/cursor/cursor.dart:52-135`: foco/cursor;
- `lib/src/editor/core/event/handlers/composition.dart:10-52`: IME;
- `lib/src/editor/utils/index.dart:175-218`: segmentação por grapheme;
- `lib/src/editor/utils/clipboard.dart:34-151`: payload interno/localStorage e
  HTML de clipboard;
- `lib/src/editor/utils/element.dart:2639-3074`: import HTML/computed style;
- `lib/src/editor/core/rendering/page_canvas_manager.dart:5-215`:
  backing-store/virtualização;
- `lib/src/editor/core/layout/page_row_index.dart:17-179`: paginação
  incremental/convergência;
- `lib/src/editor/core/worker/worker_manager.dart:19-33`: async ainda na main;
- `lib/src/word/quill_delta.dart:1-23`: cobertura declarada;
- `quill_delta.dart:272-415`: import Delta/tabela;
- `quill_delta.dart:465-532`: attrs/tamanho;
- `quill_delta.dart:588-676`: largura/style de tabela;
- `lib/src/editor/interface/table/td.dart:6-35`: propriedades de célula atuais;
- `lib/src/word/docx_to_element.dart:163-227`: regiões/geometria;
- `lib/src/word/element_to_docx.dart:1-90`: patch/passthrough;
- `doc/plano_otimizacao_performance.md:171-311`: refatoração e benchmarks;
- `doc/plano_expansao_word_gdocs.md:78-316`: gaps Word.
- `lib/src/editor/core/draw/pdf/vector_pdf_exporter.dart:30-37,159-198`:
  limitações vetoriais/fontes;
- `lib/src/document/pdf/pdf_content.dart:260-282`: fallback WinAnsi;
- `example2/lib/app_component.dart:45-71,150-153`: integração Angular e
  destroy.

### `new_sali`

- `frontend/lib/src/shared/components/quill/quill_text_editor.dart:44-60`:
  contrato Angular;
- `quill_text_editor.dart:228-317`: table/page enrichment;
- `quill_text_editor.dart:353-425`: table-better/fonts/sizes;
- `quill_text_editor.dart:834-854`: HTML/Delta;
- `backend/lib/src/modules/assinatura/services/despacho_pdf_service.dart:24-94`:
  PDF/hash atual.
