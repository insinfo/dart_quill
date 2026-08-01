# Plano alternativo A — tornar o `docx_rendering` o editor principal do SALI

**Status:** alternativa para spike e comparação de valor

**Data:** 2026-07-31

**Produto candidato:** `C:\MyDartProjects\docx_rendering`

**Aplicação-alvo:** `C:\MyDartProjects\new_sali`

**Decisão comparada:** [ADR_ESCOLHA_ENGINE_EDITOR_NEW_SALI.md](ADR_ESCOLHA_ENGINE_EDITOR_NEW_SALI.md)

**Plano concorrente:** [PLANO_ALTERNATIVO_CANVAS_EDITOR_PORT_SALI.md](PLANO_ALTERNATIVO_CANVAS_EDITOR_PORT_SALI.md)

## 0. Resposta direta

É tecnicamente viável transformar o `docx_rendering` no editor principal do
SALI e fazê-lo importar/exportar:

- Delta Quill 2.0.3;
- table-better conforme o comportamento realmente usado pelo SALI;
- `headerImage`;
- fontes, tamanhos e aliases SALI;
- page setup;
- larguras `table-temporary.col-widths`;
- HTML semântico;
- `OfficeDeltaSnapshot`;
- DOCX e PDF.

Esta alternativa entrega mais cedo uma experiência visual estilo Word porque o
projeto já possui:

- engine ProseMirror/Tiptap em Dart;
- superfície `contenteditable`;
- shell nos modos `compact`, `simple`, `word` e `viewer`;
- régua e tab stops;
- tabelas editáveis;
- TOC;
- paginação;
- importadores/exportadores DOCX/PDF.

O custo escondido é alto: o bridge Quill atual é insuficiente para os dados do
SALI e o writer DOCX ainda não preserva tudo. Escolher esta alternativa exige
transformar interoperabilidade e preservação em fundações do produto, e não em
conversores auxiliares.

O objetivo deste plano é permitir uma avaliação justa da hipótese:

> O valor de partir do engine `contenteditable`/Word mais maduro compensa o
> custo de reconstruir a compatibilidade Quill/table-better/SALI dentro do
> `docx_rendering`.

## 1. Resultado de produto pretendido

O `new_sali` passa a usar uma única fachada, implementada pelo
`docx_rendering`:

```text
new_sali
   |
   v
SaliDocumentEditorFacade
   |
   v
DocxRenderingSaliEditor
   |
   +-- simple mode ------ ProseMirror contenteditable + Quill projection
   +-- advanced/fast ---- ProseMirror contenteditable + paginação leve
   +-- advanced/fidelity ProseMirror contenteditable + layout fiel
   +-- viewer ----------- mesma árvore em leitura
```

O modo simples não é o `Scroll` do Quill. Ele é o mesmo engine ProseMirror com
UI e comandos limitados ao perfil Quill/SALI. Sua aceitação depende de provar
que os Deltas resultantes são semanticamente compatíveis com Quill 2.0.3 e com
os plugins usados em produção.

O editor deve permitir:

1. abrir despacho histórico Quill;
2. editar no modo simples;
3. alternar para avançado;
4. voltar ao simples enquanto só houver recursos representáveis;
5. promover para Office quando necessário;
6. importar DOCX;
7. salvar o documento avançado como JSON, sem binário DOCX autoritativo;
8. continuar materializando Delta Quill e HTML para os consumidores legados.

## 2. Restrições desta alternativa

- engine documental 100% frontend;
- Dart como linguagem de runtime;
- compilação JavaScript ou Wasm permitida;
- workers Dart permitidos;
- nenhuma API externa de conversão;
- nenhuma dependência de LibreOffice/DocumentServer em runtime;
- dependência direta de plataforma limitada a `web: ^1.1.1` e, se realmente
  necessária, `html: ^0.15.4`;
- sem package externo para Delta, ZIP, XML, DOCX ou PDF;
- `contenteditable` permanece a superfície principal;
- Deltas antigos não são migrados em massa;
- perda silenciosa é proibida;
- a coluna `delta` atual do SALI continua consumível pelo fluxo Quill/PDF
  existente durante o rollout;
- o editor avançado usa sidecar JSON Office enquanto existirem consumidores
  legados que assumem Quill.

Código de referência pode ser portado para dentro do repositório após auditoria
de licença e proveniência. Isso não cria dependência de runtime, mas cria
responsabilidade permanente de manutenção do fork.

## 3. Estado atual auditado

### 3.1 Ativos que entregam valor imediatamente

O `docx_rendering` possui:

- `lib/src/prosemirror/model`;
- `lib/src/prosemirror/state`;
- `lib/src/prosemirror/transform`;
- `lib/src/prosemirror/view`;
- `lib/src/prosemirror/history`;
- `lib/src/prosemirror/schema_list`;
- `lib/src/tiptap/core`;
- extensões de texto, listas, imagens, tabelas, TOC, paginação e history;
- `TiptapDocxEditorComponent`;
- `TiptapEditorShell`;
- `WordRulers`;
- `DocxImporter`;
- `DocxExporter`;
- exportação PDF vetorial/captura de layout;
- implementação própria de ZIP/XML/OPC;
- Delta próprio.

O componente já oferece mount/destroy sem dependência Angular e pode ser
hospedado por um wrapper AngularDart.

### 3.2 Lacunas Quill confirmadas

O conversor `lib/src/tiptap/converters/quill_delta.dart` atual:

- reconhece apenas `header`, `align` e listas básicas como atributos de linha;
- reconhece marcas inline comuns;
- entende somente `image` e `divider` como embeds;
- achata tabelas em texto ao voltar para Delta;
- achata listas aninhadas;
- não preserva `headerImage`;
- não preserva os atributos table-better;
- não preserva `table-temporary.col-widths`;
- não preserva atributos desconhecidos;
- não possui profile SALI;
- não produz relatório de perda.

Portanto, os testes atuais desse conversor validam somente o subset declarado.
Eles não são evidência de compatibilidade com os despachos reais.

### 3.3 Lacunas DOCX confirmadas

O importer já extrai bastante semântica e geometria, mas o pipeline atual não é
um round-trip lossless. O exporter:

- regenera um pacote reduzido;
- trata links parcialmente;
- não cobre todo `rowspan`/merge;
- não materializa todos os headers/footers importados;
- ignora recursos ainda não modelados;
- não mantém um catálogo completo de parts opacas;
- não possui patch writer ligado ao XML original.

Um editor que apenas “parece correto” após abrir não satisfaz o requisito de
reabrir/exportar sem perda.

### 3.4 Lacunas de view e paginação

O port ProseMirror view é funcional, mas a própria documentação registra
hardening ainda pendente em:

- `domchange`;
- MutationObserver localizado;
- seleção/IME em casos extremos;
- documentos longos;
- fragmentação de linhas/tabelas;
- convergência de paginação;
- virtualização real da árvore editável.

O projeto também possui mais de uma abordagem de paginação. Elas precisam ter
autoridade e responsabilidades explícitas.

## 4. Contrato SALI que deverá ser implementado

### 4.1 Shape externo

O codec público deve aceitar:

```json
{"ops": [{"insert": "Texto\n"}]}
```

Pode aceitar uma lista crua como entrada de compatibilidade, mas sempre emite o
envelope `{"ops":[...]}`.

Snapshot de documento é insert-only. `retain` e `delete` pertencem a change
Delta e não podem ser aceitos silenciosamente como conteúdo persistido.

### 4.2 Unidades de posição

Quill mede texto em unidades UTF-16 e embeds como comprimento 1.
ProseMirror possui tokens estruturais adicionais.

Criar:

```text
QuillPositionMap
  Quill UTF-16 index <-> ProseMirror position
```

O mapa precisa:

- atravessar newlines/blocos;
- atravessar embeds;
- representar linhas dentro de células;
- remapear seleção após transações;
- evitar posições entre high/low surrogate;
- ser reconstruído incrementalmente por range sujo.

Copiar diretamente índices Quill para posições ProseMirror é incorreto.

### 4.3 Atributos inline

Suportar no mínimo:

- `bold`;
- `italic`;
- `underline`;
- `strike`;
- `code`;
- `script`;
- `link`;
- `color`;
- `background`;
- `font`;
- `size`;
- `width`/`height` quando aplicáveis a embeds.

Fontes e tamanhos devem preservar o token original. O SALI usa tamanhos em
`pt`, inclusive a faixa de 8pt a 72pt. Converter para `px` e reemitir outro
token sem relatório quebra compatibilidade lexical e pode alterar layout.

### 4.4 Atributos de linha

Suportar no mínimo:

- `header`;
- `align`;
- `direction`;
- `indent`;
- `list`;
- `code-block`;
- atributos de página do SALI;
- atributos table-better;
- atributos desconhecidos preserváveis.

Os atributos `page-orientation` e `page-margin` ficam na primeira linha no
perfil SALI. Internamente eles podem alimentar metadata do documento, mas a
projeção Quill precisa restaurar a convenção.

### 4.5 Table-better

Implementar exatamente o dialeto observado:

- `table-col`;
- `table-cell-block`;
- `table-th-block`;
- `table-cell`;
- `table-th`;
- `table-temporary`;
- IDs de linha/célula;
- `data-row`;
- `width`;
- `height`;
- `rowspan`;
- `colspan`;
- `style`;
- conteúdo com múltiplos parágrafos/listas/títulos na célula;
- larguras SALI em `table-temporary.col-widths`.

O algoritmo deve:

1. reconhecer a sequência flat de ops;
2. preservar o mapa bruto de `table-temporary`;
3. validar IDs, ordem e spans;
4. agrupar células por `data-row`;
5. reunir linhas sucessivas com o mesmo cell ID como parágrafos da célula;
6. construir `table`/`tableRow`/`tableCell` ProseMirror;
7. manter metadata Quill estável;
8. permitir comandos de merge/split/resize;
9. serializar novamente no formato table-better;
10. preservar IDs quando a estrutura não mudou;
11. gerar novos IDs deterministicamente somente para nós novos;
12. emitir `CompatibilityReport` para tabela inválida/ambígua.

Precedência de largura:

1. `table-temporary.col-widths`;
2. `table-col`;
3. `width`/`style` das células;
4. grid inferido;
5. fallback somente com diagnóstico.

Não é aceitável exportar o texto das células fora da tabela.

### 4.6 Plugins SALI

Implementar:

- node `saliHeaderImage` para `{insert:{headerImage:...}}`;
- comportamento de delete decidido por contrato, não por comentário do plugin;
- profile de fontes/aliases;
- profile de tamanhos;
- page setup com defaults A4/retrato/2cm;
- citações internas preservadas como links;
- equivalentes Dart dos matchers de paste Word;
- geração de HTML semântico compatível com o viewer.

O normalizador `sali_word_paste.js` é um pipeline de clipboard HTML, não um
importador DOCX. Ele deve virar regras testáveis sobre DOM/HTML sanitizado.

Na projeção Quill, page setup default pode ser omitido conforme o comportamento
legado. Page setup não default volta na primeira newline segura. Margens Office
diferentes por lado, se não couberem no atributo SALI, tornam a projeção
parcial e aparecem no relatório; não devem ser arredondadas silenciosamente.

### 4.7 Extensões desconhecidas

Para impedir perda silenciosa, adicionar ao schema:

```text
quillPassthroughMark  -> mapa de atributos inline não reconhecidos
quillLineMetadata     -> mapa de atributos do newline
quillOpaqueInline     -> embed inline desconhecido
quillOpaqueBlock      -> embed de bloco desconhecido
quillTableMetadata    -> IDs e payload original table-better
```

Regras:

- payload sempre JSON puro e deep-copied;
- desconhecido preservado não é automaticamente renderizável;
- o editor básico não altera opaco fora do range editado;
- sanitizer pode colocar payload inseguro em quarentena;
- cada normalização aparece no relatório;
- nenhuma extensão é registrada globalmente por efeito colateral.

## 5. Arquitetura proposta dentro do `docx_rendering`

### 5.1 Novos módulos

```text
lib/src/sali/
  editor/
    sali_document_editor.dart
    sali_editor_session.dart
    sali_editor_mode.dart
    sali_editor_facade.dart
    sali_lifecycle.dart
  quill/
    quill_delta_json_codec.dart
    quill_document_snapshot.dart
    quill_change_delta.dart
    quill_position_map.dart
    quill_capability_profile.dart
    quill_compatibility_report.dart
    quill_canonicalizer.dart
    quill_security_limits.dart
    sali_quill_203_profile.dart
    table_better_codec.dart
    table_better_ids.dart
    table_better_metadata.dart
    sali_header_image_codec.dart
    sali_page_setup_codec.dart
    sali_paste_normalizer.dart
    sali_semantic_html.dart
  office/
    office_delta_codec.dart
    office_delta_manifest.dart
    office_promotion.dart
    office_projection.dart
    office_source_map.dart
    opaque_part_catalog.dart
  worker/
    worker_protocol.dart
    worker_client.dart
    worker_entrypoint.dart
```

Os nomes são propostos; o importante é impedir que toda a compatibilidade seja
novamente acumulada no único arquivo `quill_delta.dart`.

### 5.2 Refatorações do schema Tiptap

Alterar/adicionar:

- `lib/src/tiptap/extensions/block_style.dart`;
- `lib/src/tiptap/extensions/table.dart`;
- `lib/src/tiptap/extensions/table_resizing.dart`;
- `lib/src/tiptap/extensions/image.dart`;
- nova extensão `sali_header_image.dart`;
- novas extensões passthrough;
- metadata de documento/seção;
- IDs estáveis em blocos, tabelas, linhas e células.

Cada propriedade precisa declarar:

- representação Quill;
- representação Office;
- DOM de edição;
- DOM semântico;
- DOCX import/export;
- comportamento de history;
- comportamento de projeção/downgrade.

### 5.3 Refatoração do bridge Delta

Dividir `QuillDeltaConverter` em:

```text
QuillDeltaDecoder
QuillTreeBuilder
QuillDeltaEncoder
QuillPositionMap
QuillInteropProfile
CompatibilityAnalyzer
```

O converter atual pode permanecer como facade deprecated durante a migração.

Evitar importar `dart_quill` como dependência de runtime. Para paridade:

- usar os goldens gerados pela implementação real Quill 2.0.3;
- portar somente algoritmos necessários, com licença/proveniência;
- manter testes diferenciais contra o JavaScript vendorizado;
- documentar divergências intencionais.

Essa escolha aumenta manutenção duplicada e deve entrar no scorecard.

### 5.4 Estado e autoridade

Em memória:

```text
SaliEditorSession
  sourceKind
  authority
  EditorState/PMNode
  ResourceStore
  OoxmlPreservationStore
  QuillSourceMap
  OfficeSourceMap?
  visibleQuillProjection
  CompatibilityReport
  dirtyRanges
  semanticRevision
```

Autoridades possíveis:

| Estado | Autoridade |
|---|---|
| Despacho Quill não promovido | Quill document snapshot |
| Delta aberto no avançado sem feature Office | Quill snapshot + árvore derivada |
| DOCX importado | OfficeDeltaSnapshot |
| Documento promovido | OfficeDeltaSnapshot |

A árvore ProseMirror é o estado editável em memória, mas isso não autoriza
descartar metadata que ela não representa. Source maps e payloads opacos fazem
parte da sessão transacional.

Assets, parts OOXML, o Delta original e blobs grandes não devem ser colocados
em `doc.attrs`. Eles ficam em stores revisionados da sessão; caso contrário,
cada transação/copied node carregaria payload documental desnecessário. O
snapshot persistido materializa árvore e stores de forma atômica.

### 5.5 Histórico

Toda mudança entra em uma transação:

- texto;
- formatação;
- tabela;
- régua/tabulação;
- page setup;
- header/footer;
- estilos;
- TOC/fields;
- alteração de asset.

O histórico deve guardar inversão/mapping sem clonar o documento completo por
tecla. O checkpoint de persistência reconcilia árvore, metadata e projeções
atomicamente.

## 6. Modos de edição

### 6.1 `simple`

- mesma view `contenteditable`;
- toolbar compacta;
- somente comandos representáveis pelo perfil SALI;
- documento continua Quill enquanto possível;
- nodes Office não representáveis ficam read-only ou escondidos por projeção;
- export Delta deve ser lossless.

### 6.2 `wordFast`

- UI completa;
- paginação por floats/spacers/decorations;
- overscan;
- layout DOM medido incrementalmente;
- pode promover ao usar recurso Office;
- paridade de quebra com Word não é promessa.

### 6.3 `wordFidelity`

- mesmo snapshot e mesma árvore;
- layout por seção/página;
- regras de keep/widow/orphan;
- tabelas atravessando página;
- headers/footers;
- footnotes;
- fields;
- estabilização de TOC/page numbers;
- fonte/métricas controladas;
- comparação com Word/PDF de referência.

### 6.4 `viewer`

- sem comandos mutáveis;
- virtualização agressiva;
- pode renderizar Quill, OfficeDelta ou DOCX;
- HTML semântico e preview não se tornam fonte de verdade.

Trocar `simple`/`wordFast`/`wordFidelity` não cria documento novo. Somente o uso
de feature não representável promove a autoridade.

## 7. Dois paginadores sem duas semânticas

### 7.1 Autoridade comum

Os paginadores recebem:

```text
DocumentRevision + resolved styles + page geometry + dirty range
```

e devolvem:

```text
LayoutSnapshot + PositionMap + diagnostics
```

Eles não alteram o `PMNode` para “consertar” quebras visuais.

### 7.2 Paginador rápido

Evoluir `lib/src/tiptap/extensions/pagination.dart`:

- separar medição, decisão e aplicação DOM;
- agendar slices cooperativos;
- invalidar por bloco;
- propagar somente até convergir;
- manter páginas da seleção pinadas;
- virtualizar páginas fora do viewport;
- impedir loops de page count/floats;
- registrar diagnóstico por revisão.

### 7.3 Paginador de fidelidade

Não usar apenas `getBoundingClientRect` como engine.

Criar uma camada de layout puro que:

- resolva styles/numbering;
- meça runs;
- componha linhas;
- quebre parágrafos;
- fragmente tabelas;
- posicione floats;
- componha páginas e regiões;
- estabilize fields/TOC.

O DOM `contenteditable` materializa o resultado. A main thread continua
responsável por seleção e eventos; cálculo puro pode ir para worker.

### 7.4 Virtualização e `contenteditable`

Virtualizar sem quebrar seleção exige:

- manter página ativa e páginas da seleção montadas;
- spacers com altura determinística;
- bookmarks de seleção antes de desmontar;
- remapeamento por IDs/positions;
- DOMObserver ignorando mutações do paginador;
- fallback para montar a página destino antes de mover caret;
- testes IME/clipboard/drag/drop.

## 8. DOCX e `OfficeDeltaSnapshot`

### 8.1 O importer deve preservar, não somente interpretar

Adicionar:

```text
DocxPackageBaseline
OpcPartCatalog
RelationshipIndex
DocxSourceMap
OpaqueXmlFragment
DocxImportReport
```

Cada part recebe política:

| Política | Tratamento |
|---|---|
| semântica | regenerada deterministicamente |
| baseline + patch | XML original com patches localizados |
| opaca | bytes preservados |

### 8.2 O writer deve ser patch-based

Manter dois caminhos explícitos:

1. documento criado no editor: gerador DOCX completo;
2. documento importado: package original + patches localizados.

No segundo caminho:

1. identificar nodes/ranges alterados;
2. atualizar XML ligado pelo source map;
3. preservar siblings desconhecidos;
4. atualizar relationships/content types;
5. materializar styles/numbering/settings alterados;
6. copiar parts opacas;
7. validar referências e package;
8. produzir relatório.

O ZIP próprio já permite preservar entries não alteradas; isso deve virar
garantia testada do exportador, não apenas propriedade incidental do archive.

### 8.3 Snapshot persistido

O formato continua:

```json
{
  "ops": [
    {
      "insert": {
        "office-manifest": {
          "format": "sali-office-delta",
          "snapshotVersion": 0
        }
      }
    }
  ]
}
```

O snapshot inclui:

- texto/regiões;
- estilos;
- numbering;
- seções;
- headers/footers;
- fields;
- tabelas;
- assets;
- parts opacas;
- source anchors;
- baseline/patches.

Ops de storage Office nunca são enviados ao converter Quill como conteúdo
editável.

### 8.4 Persistência no `new_sali`

Durante o rollout:

| Campo | Conteúdo |
|---|---|
| `delta` | projeção Quill 2.0.3 válida |
| `descricao` | HTML semântico |
| `office_delta_json` | snapshot Office canônico |
| `document_kind` | `html`, `quill203` ou `office` |

Esse sidecar é JSON, não o binário `.docx`.

## 9. Integração AngularDart

Não montar diretamente o componente de demonstração, que hoje fixa shell,
extensões e ações privadas. Extrair primeiro:

```text
lib/src/tiptap/application/
  document_editor_controller.dart
  document_editor_options.dart
  document_editor_events.dart
  document_editor_facade.dart
```

O `TiptapDocxEditorComponent` passa a consumir esse controller e continua útil
como demo. O wrapper SALI consome o mesmo controller com outro shell.

Criar no `new_sali` um wrapper que preserve inicialmente:

- selector `quill-text-editor`;
- `ControlValueAccessor<String>` cujo valor é HTML;
- output `onChange` com HTML;
- output `previewRequested`;
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
- `destroy`.

Adicionar `isReady` e remover gradualmente a dependência da página em
`textEditor.quill`.

O wrapper:

- monta o `DocumentEditorController` em um host controlado;
- reutiliza somente componentes de shell adequados ao modo;
- escolhe profile/mode por feature flags;
- liga update ao HTML somente nos mesmos momentos esperados;
- faz autosave/checkpoint;
- impede save durante promoção incompleta;
- desmonta observers, workers e blob URLs.

## 10. PDF e assinatura

### 10.1 Quill legado

Continuar:

```text
delta Quill -> renderer atual -> PDF/hash/assinatura
```

### 10.2 Office

Para fidelidade visual:

```text
OfficeDelta -> layout docx_rendering frontend -> PDF bytes
            -> congelamento -> hash/assinatura
```

O backend não renderiza DOCX. Ele apenas recebe/valida os bytes finais e realiza
persistência/hash/assinatura.

Se não houver alteração possível nesse handoff, o documento Office será
assinado pela projeção Quill e não pela paginação Word. Isso deve ser uma
limitação explícita do produto.

## 11. Workers

Criar protocolo versionado com mensagens JSON/transferables:

```text
parseDocx
inflatePart
resolveStyles
buildQuillIndex
layoutDirtyRegion
serializeOfficeDelta
writeDocx
buildPdf
```

Regras:

- payload não contém objetos DOM;
- revisão/hash acompanha request/response;
- resposta obsoleta é descartada;
- cancelamento cooperativo;
- limites de memória;
- transferência de `Uint8List` quando possível;
- fallback main-thread em slices;
- JavaScript e Wasm devem produzir resultado determinístico.

Com a implementação atual, `DOMParser`, `contenteditable`, seleção, IME,
MutationObserver e medição final do browser permanecem na main thread.
Parsers/layouts puros podem migrar ao worker somente depois de remover sua
dependência de DOM.

## 12. Fases e entregas de valor

Não atribuir calendário antes dos spikes. Cada fase termina com decisão
go/no-go e uma entrega demonstrável.

### A0 — proveniência, corpus e contratos

- auditoria de licença;
- congelar Quill 2.0.3 e o table-better realmente carregado;
- importar os quatro fixtures atuais;
- adicionar corpus anonimizado de produção;
- congelar HTML, Delta e PDF atuais;
- inventariar DOCX e parts;
- ratificar SLOs.

**Valor entregue:** baseline confiável.

**Go/no-go:** nenhuma incorporação sem licença; corpus reproduzível.

### A1 — kernel Delta seguro

- envelope/lista;
- document/change Delta;
- validação estrutural;
- deep copy/freeze;
- canonicalização;
- UTF-16;
- embeds mapa;
- retain de embed quando aplicável;
- limites de segurança;
- `CompatibilityReport`.

**Valor entregue:** codec utilizável sem montar editor.

**Go/no-go:** diferencial contra Quill 2.0.3 sem perdas não declaradas.

### A2 — subset Quill padrão

- texto;
- marks;
- headers;
- align;
- indent/list;
- links/images;
- seleção/mapping;
- HTML semântico.

**Valor entregue:** viewer/editor simples para documentos sem tabela.

**Go/no-go:** Quill → ProseMirror → Quill equivalente no corpus subset.

### A3 — table-better e perfil SALI

- codec table-better;
- IDs/spans/larguras;
- `table-temporary.col-widths`;
- `headerImage`;
- page setup;
- fontes/tamanhos;
- paste;
- citações;
- desconhecidos opacos.

**Valor entregue:** candidato real a substituir o Quill JS.

**Go/no-go:** 100% do corpus SALI abre/salva sem perda silenciosa; goldens
table-better passam.

### A4 — facade Angular e shadow mode

- wrapper com API atual;
- feature flags;
- writer JS permanece canônico;
- candidato produz Delta/HTML/PDF em paralelo;
- telemetria local de divergência/performance;
- teardown e editores simultâneos.

**Valor entregue:** evidência em fluxos reais sem risco de gravação.

**Go/no-go:** divergências classificadas e fallback funcional.

### A5 — writer básico e paginação rápida

- liberar writer para novos rascunhos;
- alternância `simple`/`wordFast`;
- autosave;
- rollback por registro/usuário;
- virtualização inicial.

**Valor entregue:** substituição progressiva do Quill JS e experiência paginada.

**Go/no-go:** fluxo de despacho e assinatura Quill inalterados.

### A6 — OfficeDelta e DOCX preservável

- snapshot versionado;
- baseline/source map;
- patch writer;
- parts opacas;
- import/reopen/export;
- projeções Quill/HTML.

**Valor entregue:** edição DOCX com persistência JSON.

**Go/no-go:** round-trip sem perda no capability matrix; reabertura sem DOCX.

### A7 — recursos Word

- estilos/templates;
- régua completa;
- tab stops;
- seções;
- headers/footers;
- campos/page numbers;
- TOC;
- tabelas entre páginas;
- drawings/floats;
- paginação fidelity.

**Valor entregue:** editor profissional.

**Go/no-go:** goldens semânticos/visuais por feature.

### A8 — PDF Office, performance e rollout geral

- PDF fiel congelado;
- handoff de assinatura;
- workers;
- Wasm quando medido melhor;
- hardening browser/IME/a11y;
- remoção eventual do Quill JS.

**Valor entregue:** fluxo Office completo em produção.

**Go/no-go:** SLOs, auditoria e rollback atendidos.

## 13. Scorecard de valor desta alternativa

Avaliar após cada marco, usando evidência:

| Dimensão | Métrica |
|---|---|
| Compatibilidade | percentual do corpus sem perdas críticas |
| Tabela | goldens table-better e operações reais aprovadas |
| Migração | páginas SALI funcionando sem alteração ou via facade |
| Valor imediato | Quill JS substituível antes do DOCX completo |
| Word UX | recursos profissionais utilizáveis |
| DOCX | features lossless + parts opacas preservadas |
| Desempenho | SLOs de abertura, tecla, scroll e layout |
| Acessibilidade | IME, teclado, screen reader e clipboard |
| Manutenção | linhas/módulos duplicados de Delta/ZIP/XML/PDF |
| Segurança | validação, limites, sanitizer e fuzz |
| Assinatura | revisão visual ligada aos bytes/hash |
| Reversibilidade | fallback sem regravar fonte original |

Hipótese de valor:

- tende a pontuar alto cedo em UX Word/contenteditable;
- tende a pontuar baixo no início em compatibilidade SALI;
- tem risco médio/alto de duplicação de infraestrutura;
- pode entregar paginação leve antes da preservação DOCX completa;
- só substitui o Quill JS depois de A3/A4, não depois da aparência visual.

## 14. Testes obrigatórios

### 14.1 Quill/SALI

- fixtures atuais: 12.507 ops;
- fixture grande: aproximadamente 2,18 MB/11.709 ops;
- Deltas anonimizados de produção;
- envelope/lista;
- newline/canonicalização;
- Unicode/emoji/combining;
- atributos inline/bloco;
- desconhecidos;
- `headerImage`;
- page setup;
- fonts 8pt–72pt;
- links/citações;
- table-better com merge/split/resize;
- `col-widths`;
- paste Word;
- no-op e edição localizada;
- básico ↔ avançado.

### 14.2 DOCX/Office

```text
DOCX -> OfficeDelta -> OfficeDelta
DOCX -> OfficeDelta -> DOCX
OfficeDelta -> editor -> OfficeDelta
OfficeDelta -> DOCX -> OfficeDelta
QuillDelta -> simple -> QuillDelta
QuillDelta -> wordFast -> QuillDelta
QuillDelta + feature Office -> OfficeDelta
```

Asserções:

- parts/relationships/content types;
- assets;
- styles/numbering/settings;
- seções;
- headers/footers;
- fields;
- tabelas/spans;
- opacos;
- hashes/revisões;
- relatório de perda.

### 14.3 View

- `beforeinput`;
- composition/IME;
- dead keys;
- teclado;
- seleção para frente/trás;
- seleção entre páginas/tabelas;
- clipboard/drop;
- undo/redo;
- múltiplos editores;
- mount/destroy repetido;
- Chrome/Edge/Firefox;
- screen reader.

### 14.4 Segurança

- ZIP bomb;
- XML profundo;
- entidades externas;
- relationships externas;
- data URI grande;
- imagem com dimensões abusivas;
- CSS/HTML malicioso;
- URL proibida;
- JSON profundo;
- IDs duplicados/cíclicos;
- parts/rels ausentes;
- macros/OLE não executados.

## 15. SLOs provisórios comuns

Ratificar no mesmo hardware/browser usado para comparar as alternativas.

| Métrica | `fast` | `fidelity` |
|---|---:|---:|
| primeira página DOCX editável | ≤ 2 s | ≤ 3 s |
| snapshot, primeira página | ≤ 1 s | ≤ 1,5 s |
| layout completo em background | ≤ 4 s | ≤ 10 s |
| tecla p95 | ≤ 16 ms | ≤ 16 ms |
| tecla p99 | < 50 ms | < 50 ms |
| slice na main thread | ≤ 8 ms | ≤ 8 ms |
| scroll estabilizado | ≥ 55 fps | ≥ 55 fps |
| páginas montadas | viewport ±3 | viewport ±3 |
| perda silenciosa | zero | zero |

Não alterar metas removendo fixtures difíceis. Registrar memória, long tasks,
nós DOM, páginas recalculadas, bytes e custo de worker.

## 16. Riscos e mitigação

| Risco | Impacto | Mitigação/gate |
|---|---|---|
| Converter atual achata tabelas | Crítico | A3 bloqueia rollout até goldens reais |
| Posições PM ≠ Quill | Crítico | `QuillPositionMap` e fuzz de transações |
| Metadata desconhecida desaparece | Crítico | nodes/marks passthrough + report |
| Writer DOCX regenerativo perde parts | Crítico | baseline/source map/patch writer |
| Duas paginações divergem | Alto | input/output comum e autoridade declarada |
| DOM longo degrada | Alto | incremental + virtualização/páginas pinadas |
| View/IME ainda incompleto | Alto | corpus de browser antes do writer |
| Delta próprio duplica manutenção | Alto | goldens diferenciais/proveniência |
| PDF atual do SALI difere visualmente | Alto | política de assinatura explícita |
| Snapshot/assets cresce demais | Alto | limites, compressão e benchmark |
| Shell visual mascara falha semântica | Alto | gates de dados antes de UX |
| Licença/origem indefinida | Bloqueador | A0 antes de copiar/publicar |

## 17. Primeiros PRs

1. Harness do corpus SALI e comparador canônico.
2. `QuillDeltaJsonCodec` + validation/report.
3. `QuillPositionMap` com UTF-16.
4. Refatorar converter em decoder/builder/encoder.
5. Suportar todo subset Quill padrão.
6. Adicionar metadata passthrough.
7. Implementar table-better decoder/encoder.
8. Implementar `SaliQuill203Profile`.
9. Adicionar `headerImage`, page setup e fonts/sizes.
10. Goldens de HTML/paste.
11. Facade Angular em shadow mode.
12. Paginação rápida incremental/virtualizada.
13. Manifest/codec do OfficeDelta.
14. Baseline/source map/patch writer DOCX.
15. Projeções e promoção atômica.

Cada PR deve ser pequeno o suficiente para provar uma propriedade. Não juntar
table-better, DOCX e UI em uma única entrega.

## 18. Condições para escolher esta alternativa

Escolher `docx_rendering` como produto principal se os spikes demonstrarem:

1. compatibilidade SALI/table-better atingível sem deformar o schema;
2. alternância simples/avançado preservando Delta;
3. view `contenteditable` estável em documentos grandes;
4. paginação rápida agregando valor antes do layout fiel;
5. writer patch-based preservando DOCX;
6. custo de manter Delta/Office duplicado aceitável;
7. integração Angular mais curta que portar o engine ao `dart_quill`.

Interromper ou rebaixar esta alternativa a doadora se:

- A3 não atingir o corpus sem perdas;
- a metadata passthrough contaminar todas as transações;
- a view não atingir IME/performance;
- a preservação DOCX exigir substituir a maior parte da pilha;
- a duplicação com `dart_quill` produzir duas autoridades inconciliáveis.

## 19. Conclusão da alternativa

O `docx_rendering` é o candidato com maior valor visual imediato e melhor
aderência ao requisito `contenteditable`. O investimento inicial deve ser
direcionado à compatibilidade Quill/SALI, não a novos botões Word.

Se A1–A4 forem aprovadas, esta alternativa pode substituir o Quill JavaScript
antes de concluir a fidelidade DOCX. Se falharem, o projeto ainda permanece um
doador valioso de engine avançado, e o trabalho de corpus/goldens continua útil
para a alternativa `dart_quill`.

## 20. Evidências locais principais

### `docx_rendering`

- `pubspec.yaml`: runtime atual somente com `web`;
- `lib/src/prosemirror/view/index.dart:90-113`: view `contenteditable`;
- `lib/src/prosemirror/view/domobserver.dart:33-68`: MutationObserver;
- `lib/src/tiptap/ui/docx_editor_component.dart:21-65`: componente montável;
- `docx_editor_component.dart:69-128`: extensões atuais;
- `docx_editor_component.dart:1532-1610`: import/export Delta/DOCX;
- `lib/src/tiptap/ui/editor_shell.dart:6-34`: modos públicos;
- `lib/src/tiptap/converters/quill_delta.dart:1-21`: cobertura/perdas
  declaradas;
- `quill_delta.dart:270-318`: tabela achatada;
- `quill_delta.dart:465-517`: attrs/embeds reconhecidos;
- `lib/src/quill_delta/delta.dart:326-345`: JSON interno;
- `lib/src/tiptap/converters/docx_import.dart:22-112`: importer e metadata de
  documento;
- `docx_import.dart:859-953`: tabelas;
- `lib/src/tiptap/converters/docx_export.dart:29-76`: exporter atual;
- `lib/src/docx_rendering/zip/zip_archive.dart:18-25,253-269`: preservação de
  entries não alteradas;
- `lib/src/tiptap/extensions/block_style.dart:7-127`: propriedades DOCX;
- `lib/src/tiptap/extensions/pagination.dart`: paginação DOM atual;
- `lib/src/tiptap/ui/word_rulers.dart`: régua/tab stops;
- `doc/plano_editor_completo.md:60-143`: lacunas de view, performance e
  conversores;
- `doc/RELATORIO_INVESTIGACAO_E_MELHORIAS.md:197-225`: estado/gaps.
- `example2/pubspec.yaml:5-12`: SDK/ngdart/web compatíveis com o frontend SALI.

### `new_sali`

- `frontend/lib/src/shared/components/quill/quill_text_editor.dart:44-60`:
  contrato Angular;
- `quill_text_editor.dart:228-317`: enrichment table/page;
- `quill_text_editor.dart:353-425`: table-better/fonts/sizes;
- `quill_text_editor.dart:834-854`: HTML/Delta salvos;
- `quill_text_editor.dart:1088-1150`: load/forms/lifecycle;
- `backend/lib/src/modules/assinatura/services/despacho_pdf_service.dart:24-94`:
  PDF/hash atual;
- `core/lib/src/services/pdf/quill_pdf_sanitizer.dart:12-90`: sanitizer atual.
