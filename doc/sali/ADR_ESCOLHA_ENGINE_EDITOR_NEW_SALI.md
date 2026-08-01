# ADR — engine de edição profissional para o `new_sali`

**Status:** decisão técnica recomendada

**Data:** 2026-07-31

**Escopo:** `dart_quill`, `new_sali`, `docx_rendering` e `canvas-editor-port`

**Plano detalhado relacionado:** [PLANO_EDITOR_DOCX_PAGINADO_AVANCADO.md](../PLANO_EDITOR_DOCX_PAGINADO_AVANCADO.md)

## 1. Decisão

A opção mais viável é:

1. manter o **`dart_quill` como produto, API pública e autoridade do formato persistido**;
2. preservar o editor Quill atual como engine básico, sem paginação e sem regressões;
3. criar dentro do `dart_quill` um **engine avançado independente**, baseado no editor
   `contenteditable`/ProseMirror/Tiptap já portado para Dart no `docx_rendering`;
4. reutilizar o núcleo Office já existente em `dart_quill/lib/src/office` para
   OPC, ZIP, XML, DOCX, layout e PDF;
5. usar o `docx_rendering` como **fonte de componentes a portar**, não como nova
   dependência de runtime nem como segundo produto concorrente;
6. manter o `canvas-editor-port` como referência de layout, benchmark e possível
   renderer especializado futuro, mas não como engine principal;
7. criar um perfil de interoperabilidade específico do SALI para reproduzir o
   dialeto formado por Quill 2.0.3, table-better 1.2.3 e plugins próprios;
8. persistir documentos avançados em um `OfficeDeltaSnapshot` versionado, ainda
   no envelope JSON `{"ops":[...]}`, sem depender do binário DOCX para reabrir.

Portanto, a escolha é **expandir o `dart_quill`**, mas não tentar transformar a
árvore `Scroll` do Quill básico em um editor Word paginado. O modo avançado deve
ser outro engine, isolado atrás da mesma fachada de produto.

Esta é uma solução híbrida em termos de código-fonte, mas possui uma única
autoridade de produto:

```text
new_sali
   |
   v
SaliDocumentEditorFacade
   |
   +-- QuillBasicEngine ------------ Quill Delta 2.0.3
   |
   +-- OfficeContentEditableEngine - OfficeDeltaSnapshot
              |
              +-- componentes portados de docx_rendering
              +-- núcleo Office canônico de dart_quill
```

## 2. Resposta direta às três alternativas

Planos executáveis das alternativas não escolhidas:

- [PLANO_ALTERNATIVO_DOCX_RENDERING_SALI.md](PLANO_ALTERNATIVO_DOCX_RENDERING_SALI.md);
- [PLANO_ALTERNATIVO_CANVAS_EDITOR_PORT_SALI.md](PLANO_ALTERNATIVO_CANVAS_EDITOR_PORT_SALI.md).

| Alternativa | Veredito | Motivo principal |
|---|---|---|
| Expandir `dart_quill` | **Escolhida** | Já é o limite natural de compatibilidade Quill/table-better e já contém o núcleo Office que deve ser canônico |
| Tornar `docx_rendering` o produto principal | Não | É o melhor doador para `contenteditable` e recursos Word, mas seu conversor Delta atual perde o dialeto SALI e duplicaria ZIP/XML/DOCX/PDF |
| Tornar `canvas-editor-port` o produto principal | Não | Tem paginação promissora, porém usa canvas com textarea oculta, não `contenteditable`, e seu conversor Delta atual é muito lossy para o SALI |

O caminho escolhido não significa descartar os outros projetos:

- o `docx_rendering` reduz substancialmente o tempo para construir o modo
  profissional;
- o `canvas-editor-port` fornece ideias úteis de virtualização, backing stores,
  layout por página e benchmarks;
- ambos devem ser tratados como projetos doadores, com proveniência e licença
  auditadas antes da incorporação.

## 3. Restrições consideradas

A decisão considera como não negociáveis:

- execução do editor 100% no frontend;
- nenhuma API de conversão ou servidor de renderização de documentos;
- implementação de runtime em Dart;
- somente `web: ^1.1.1` e, quando realmente necessário, `html: ^0.15.4` como
  dependências diretas de plataforma;
- compilação Dart para JavaScript ou Wasm permitida;
- workers permitidos para tarefas pesadas;
- compatibilidade com JSON Delta do Quill 2.0.3;
- compatibilidade com os despachos antigos do SALI;
- modo Quill simples preservado;
- edição avançada baseada em `contenteditable`;
- dois níveis de paginação: rápido e de fidelidade;
- DOCX importado reabrível a partir do JSON armazenado, sem precisar guardar o
  `.docx` como fonte obrigatória;
- preservação de estilos, seções, margens, headers/footers, campos, tabelas,
  listas, imagens, numeração, tabulações e conteúdo OOXML ainda não editável;
- exportação DOCX sem destruir silenciosamente o que foi importado.

“Sem backend” é entendido como **sem engine documental no backend**. O editor,
o importador DOCX, o layout, a paginação e a geração de PDF continuam no
frontend. A integração com o fluxo de assinatura já existente no SALI é tratada
separadamente na seção 11.

## 4. Evidência encontrada no `new_sali`

### 4.1 O editor atual é um componente de aplicação, não apenas uma caixa de texto

O componente atual:

- inicializa Quill 2.0.3 e table-better 1.2.3;
- é um `ControlValueAccessor` AngularDart;
- usa `String` do `ControlValueAccessor` como HTML, não como Delta;
- emite HTML semântico em `onChange` somente para mudanças com source `user`;
- carrega e salva o envelope `{"ops":[...]}`;
- enriquece o Delta antes de salvar;
- mantém HTML semântico derivado;
- gera preview/PDF;
- oferece comandos consumidos diretamente pelas páginas do sistema.

O contrato externo observado inclui:

- `addText`;
- `clearAllText`;
- `insertHeaderImage`;
- `getValidSemanticHTML`;
- `getDeltaJson`;
- `hasMeaningfulContent`;
- `insertInternalCitation`;
- `reset`;
- `loadDeltaJson`;
- `gerarPreviewDocumentoFinalizadoBytes`.

A migração deve começar por uma fachada que preserve esse contrato. As páginas
do SALI não devem conhecer `Quill`, ProseMirror, árvore Office ou implementação
de paginação.

O componente não possui `@Input`; a integração efetiva usa o selector
`quill-text-editor`, outputs e chamadas imperativas. `writeValue(String)`
interpreta o valor como HTML. A página ainda consulta `textEditor.quill` para
saber se o editor está pronto. O adaptador pode emular isso transitoriamente,
mas o contrato novo deve expor `isReady`.

Há dívidas de lifecycle/form a corrigir com teste de compatibilidade:

- `onDisabledChanged` é no-op;
- o callback guardado por `registerOnTouched` aparentemente não é chamado;
- o teardown atual fecha streams, mas não demonstra destruição completa do
  editor/observers.

### 4.2 O “Delta SALI” é maior que o Delta padrão do Quill

O SALI carrega scripts globais para:

- Quill 2.0.3;
- table-better 1.2.3;
- `headerImage`;
- aliases e whitelist de fontes;
- configuração de página;
- normalização especial de conteúdo colado do Word.

Além disso, o componente injeta no salvamento:

- atributos de página;
- larguras medidas de tabela em `table-temporary.col-widths`;
- dados necessários ao cabeçalho customizado.

O diretório table-better está rotulado como 1.2.3, enquanto o
`package.json` do source vendorizado declara 1.2.4 e Quill `^2.0.1`. O contrato
deve ser congelado por corpus/goldens do comportamento realmente carregado,
não somente pelo nome do diretório.

O perfil observado inclui ainda:

- `table-cell-block`, `table-th-block`, `table-cell`, `table-th`,
  `table-temporary` e `table-col`;
- objetos de célula com `data-row`, `width`, `rowspan`, `colspan` e `style`;
- tamanhos style de `8pt` a `72pt`;
- fontes `inter`, `arial` e `calibri`, além de aliases locais;
- `page-orientation` e `page-margin` na primeira linha;
- links usados também por citações internas.

Assim, “compatível com Quill 2.0.3” possui dois níveis:

1. compatibilidade com o Delta público padrão do Quill 2.0.3;
2. compatibilidade com o **perfil SALI**, que inclui extensões próprias e
   table-better 1.2.3.

O segundo nível é o gate real para substituir o editor em produção.

### 4.3 O corpus atual confirma que tabela é requisito central

Os quatro fixtures JSON encontrados em `new_sali/core/test/assets` somam
12.507 ops. Os atributos mais frequentes incluem:

| Atributo | Ocorrências |
|---|---:|
| `table-cell` | 5.521 |
| `table-cell-block` | 5.521 |
| `align` | 5.299 |
| `color` | 3.810 |
| `size` | 3.461 |
| `font` | 3.459 |
| `background` | 1.749 |
| `bold` | 714 |
| `list` | 441 |
| `indent` | 441 |
| `table-temporary` | 25 |

Também aparecem embeds `headerImage` e `image`.

Isso elimina qualquer estratégia que “achate” tabelas em parágrafos ou que
ignore `table-temporary`: ela reprovaria justamente no conteúdo mais abundante
do corpus.

### 4.4 Delta e HTML possuem papéis diferentes

O modelo de despacho e as páginas atuais guardam:

- `delta`: fonte estruturada usada para reabrir o editor e gerar documento;
- `descricao`: HTML semântico derivado, útil para exibição, pesquisa e
  compatibilidade de telas.

Também existem despachos históricos com `delta == null`, cuja autoridade
remanescente é HTML. Eles precisam de uma política explícita de visualização e
não devem ser “convertidos” automaticamente para um Delta inventado.

O novo modo deve manter esse princípio:

- o JSON Delta/snapshot é a fonte autoritativa;
- o HTML é uma projeção;
- PDF e DOCX são materializações;
- nenhuma edição deve ser reconstruída a partir do HTML se o snapshot existir.

### 4.5 O Delta participa do fluxo jurídico de PDF e assinatura

O backend atual decodifica `delta`, espera um mapa com `ops`, sanitiza o
conteúdo e gera o PDF usado para hash e assinatura.

Isso impede trocar silenciosamente um Delta Quill por ops Office e esperar que
o fluxo atual continue funcionando. Um `office-manifest` não pode ser enviado
ao conversor Quill existente como se fosse conteúdo visual.

Esse ponto é um gate de produto, não apenas um detalhe do componente editor.

O sanitizer atual remove, entre outros, `color`, `background` e os atributos de
página antes do renderer, depois de extrair o page setup necessário. Portanto,
o PDF jurídico atual já não é uma reprodução visual completa de todo Delta
editável. O novo fluxo deve declarar se pretende manter essa política histórica
ou assinar a materialização Office fiel.

Há ainda dois gaps de contrato que precisam de golden:

- o export manual usa ops crus, enquanto o salvamento real usa ops
  enriquecidos;
- o loader do frontend e a persistência do backend não possuem validação
  estrutural rigorosa, embora o serviço de assinatura seja mais restritivo.

### 4.6 Viewer, templates e segurança também entram no rollout

O viewer comum renderiza `descricao` como HTML, e despachos assinados são
abertos pelo PDF congelado. Por isso `descricao` não pode desaparecer na
primeira migração.

Os templates de despacho atuais guardam texto puro e são inseridos sem
formatação. Templates profissionais com estilos, campos, tabelas e cabeçalhos
precisarão de payload estruturado/versionado; reutilizar a coluna de texto
eliminaria justamente os recursos novos.

O viewer atual usa uma política HTML permissiva. A troca de editor é uma boa
fronteira para introduzir:

- sanitizer explícito e testado;
- política de links/citações internas;
- limites de data URI e assets;
- CSP compatível;
- separação entre HTML de exibição e payload Office opaco.

## 5. Avaliação do `dart_quill`

### 5.1 Pontos favoráveis

O `dart_quill` já possui:

- o editor básico que deverá substituir o Quill TypeScript;
- núcleo Delta em Dart;
- port de table-better;
- goldens gerados contra Quill 2.0.3 e table-better 1.2.3;
- módulos Office para ZIP, XML, OPC, Word, layout e PDF;
- conversores e testes que podem ser endurecidos sem duplicar infraestrutura;
- uma divisão de bibliotecas que permite isolar APIs básica, table-better e
  Office.

Nos testes table-better já existentes, 19 casos golden são comparados com a
implementação real Quill 2.0.3/table-better 1.2.3, sem divergências conhecidas
registradas nesse conjunto.

### 5.2 Lacunas que impedem um “drop-in” imediato

O `dart_quill` ainda não deve substituir o editor do SALI antes de corrigir:

- `Delta.fromJson` aceita a lista de ops, mas não diretamente o envelope
  `{"ops":[...]}`;
- atributos desconhecidos podem desaparecer silenciosamente ao montar o DOM;
- embeds desconhecidos podem falhar ou ser perdidos;
- `retain` com payload de atualização de embed do Quill 2 não completa o
  round-trip JSON;
- `getContents()` expõe estado mutável;
- registries globais dificultam perfis isolados;
- fonte e tamanho possuem whitelists menores que as usadas pelo SALI;
- `headerImage` e atributos de página não fazem parte do perfil básico atual;
- `table-temporary.col-widths` precisa de suporte explícito;
- existem divergências localizadas em fórmula, imagem sanitizada, custom embeds
  com payload mapa e diff de pares surrogate;
- o codec DOCX público simplificado é deliberadamente lossy.

Essas lacunas não invalidam a escolha. Elas definem a primeira fase obrigatória:
compatibilidade SALI antes do editor Word.

### 5.3 Papel correto do núcleo Office existente

`dart_quill/lib/src/office` já contém infraestrutura que também aparece nos
outros candidatos. Ela deve ser a implementação canônica para:

- ZIP/deflate;
- XML e namespaces;
- OPC e relationships;
- importação/exportação DOCX;
- modelo de estilos e numbering;
- layout/paginação;
- PDF;
- bridge Quill/table-better.

Não se deve portar para o `dart_quill` uma segunda cópia dessas camadas apenas
porque elas existem no `docx_rendering`.

## 6. Avaliação do `docx_rendering`

### 6.1 Por que ele é o melhor doador do engine avançado

O projeto já possui em Dart:

- modelo, state, transform e view no estilo ProseMirror;
- editor/extensões no estilo Tiptap;
- edição baseada em `contenteditable`;
- seleção e transações estruturais;
- tabelas editáveis e comandos;
- régua, tab stops e controles de página;
- TOC;
- regiões de página;
- paginação;
- exemplo AngularDart com versões de SDK e `web` próximas às do `new_sali`.

Isso o torna o caminho mais curto para um modo profissional baseado em
`contenteditable`.

### 6.2 Por que ele não deve se tornar a autoridade do produto

O conversor Quill atual do projeto:

- trata tabelas como conteúdo sem representação Quill adequada;
- achata a tabela ao exportar;
- reconhece apenas um conjunto pequeno de embeds;
- não implementa table-better;
- não preserva `headerImage`;
- não preserva todo o perfil de página do SALI;
- não representa o dialeto real dos despachos.

O exportador DOCX ainda possui limitações em:

- links;
- `rowspan`;
- imagens remotas;
- headers/footers;
- partes e objetos OOXML ainda não suportados semanticamente.

Além disso, torná-lo o produto principal manteria dois núcleos concorrentes para
Delta, ZIP, XML, DOCX, PDF e paginação. O custo de reconciliar as duas
autoridades seria maior que portar somente o engine editável necessário.

### 6.3 Política de migração de código

Portar seletivamente:

- model/state/transform;
- view `contenteditable`;
- mapeamento de posições;
- history/commands;
- tabelas e resize;
- ruler/tab stops;
- extensões de TOC e page regions;
- shell e integração AngularDart úteis.

Não portar cegamente:

- outro Delta;
- outro ZIP/XML/OPC;
- outro codec DOCX;
- outro PDF;
- bridges Quill lossy;
- código duplicado de layout sem uma decisão explícita de autoridade.

## 7. Avaliação do `canvas-editor-port`

### 7.1 Pontos favoráveis

O projeto possui:

- visual de documento paginado;
- editor/viewer;
- layout por página;
- backing stores de canvas;
- virtualização e agendamento progressivo;
- núcleo Dart próprio para DOCX/PDF;
- benchmark interno relevante para documentos grandes.

É uma boa fonte para estudar:

- invalidação por página;
- raster cache;
- virtualização;
- renderização progressiva;
- métricas de latência.

### 7.2 Bloqueio arquitetural

O editor real usa:

- canvas para renderização;
- `HTMLTextAreaElement` invisível para entrada;
- composição IME e cursor implementados manualmente.

Ele não usa `contenteditable` como superfície principal. O pouco
`contenteditable` encontrado é auxiliar.

Se `contenteditable` é obrigatório, escolher o canvas como base significaria
reescrever justamente o núcleo de entrada, seleção, IME, acessibilidade e DOM.

### 7.3 Bloqueio de compatibilidade

O bridge Delta atual perde:

- `headerImage`;
- tamanhos em `pt`;
- indentação;
- `table-temporary`;
- larguras reais de coluna;
- estilos avançados de tabela;
- atributos e embeds desconhecidos;
- headers, footers e geometria de página na volta para Delta.

Logo, ele não é uma rota mais curta para os dados existentes do SALI.

### 7.4 Papel futuro possível

Após o modelo Office e os codecs serem canônicos no `dart_quill`, o canvas pode
ser experimentado atrás de uma interface de renderer para:

- preview read-only;
- miniaturas;
- documentos extremos;
- comparação visual;
- modo de fidelidade especializado.

Isso não faz parte do caminho crítico inicial.

## 8. Matriz comparativa

Legenda: **alta**, **média**, **baixa** representam aderência atual, antes do
trabalho proposto.

| Critério | `dart_quill` | `docx_rendering` | `canvas-editor-port` |
|---|---:|---:|---:|
| Quill 2.0.3 básico | **Alta** | Média/baixa | Baixa |
| table-better 1.2.3 | **Alta** | Baixa | Baixa |
| Dialeto SALI atual | Média | Baixa | Baixa |
| `contenteditable` estrutural | Média, via port planejado | **Alta** | **Não atende** |
| Recursos Word já prototipados | Média | **Alta** | Média/alta |
| Núcleo Office canônico desejado | **Alta** | Médio, mas duplicado | Médio, mas duplicado |
| Risco de migração dos despachos | **Menor** | Alto | Alto |
| Risco de duplicação futura | **Menor** | Alto como produto | Alto como produto |
| Adequação como produto principal | **Escolhido** | Doador | Referência/opcional |

Estimativa relativa de engenharia, sujeita a spikes e gates:

- `dart_quill` + port seletivo: baseline `1,0x`;
- `docx_rendering` como produto e reconstrução da compatibilidade SALI:
  aproximadamente `1,3x–1,6x`;
- `canvas-editor-port` como produto, reconstruindo compatibilidade e trocando o
  núcleo de entrada por `contenteditable`: aproximadamente `1,5x–2,0x`.

Esses fatores são estimativas de planejamento, não medições de calendário.

## 9. Contrato de compatibilidade entre os modos

### 9.1 Um Delta customizado é possível, mas não é automaticamente Quill

Sim, ops e atributos customizados podem representar recursos DOCX, assim como
table-better representa tabelas. Porém:

- o JSON continua válido;
- o codec Office consegue preservá-lo;
- o Quill 2.0.3 comum não conhece esses ops;
- montar ops Office em `Quill.setContents()` pode descartá-los, deformá-los ou
  lançar erro.

Por isso há dois dialetos no mesmo envelope externo:

```text
QuillDocumentDelta   = Delta visível e editável pelo Quill
OfficeDeltaSnapshot  = snapshot avançado, versionado e autocontido
```

O primeiro op `office-manifest` distingue o snapshot avançado internamente e
elimina a necessidade de guardar o DOCX binário. Isso não torna seguro colocá-lo
na coluna `delta` legada do SALI; nela há consumidores que pressupõem Quill.

### 9.2 Matriz de abertura e alternância

| Documento persistido | Básico editável | Avançado editável | Quill JS 2.0.3 |
|---|---:|---:|---:|
| Delta Quill padrão suportado | Sim | Sim | Sim |
| Delta com perfil SALI suportado | Sim | Sim | Sim, com plugins SALI |
| Delta com extensão desconhecida preservável | Só após relatório lossless | Sim/condicional | Condicional |
| `OfficeDeltaSnapshot` | Não diretamente | Sim | Não |

Regras:

1. Delta Quill suportado entra no avançado sem promoção automática.
2. Enquanto o usuário usar apenas recursos representáveis no Quill, pode
   alternar básico → avançado → básico sem perda semântica.
3. O primeiro recurso exclusivamente Office promove atomicamente o documento
   para `OfficeDeltaSnapshot`.
4. Depois da promoção, o básico pode mostrar uma projeção read-only ou uma
   cópia explicitamente degradada; não pode virar a fonte autoritativa.
5. Demotion editável só é permitido quando um relatório comprovar que a
   conversão é lossless.
6. Ops de storage Office nunca são enviados para `Quill.setContents()`.

### 9.3 Compatibilidade não significa igualdade byte a byte

O contrato correto para Delta Quill é equivalência após canonicalizações
declaradas, incluindo:

- união de ops adjacentes;
- remoção de mapas de atributos vazios;
- normalização de newline;
- newline estrutural final;
- normalizações lexicais previstas pelo Quill.

Qualquer atributo, embed ou payload suportado deve continuar profundamente
equivalente. Perda silenciosa é falha.

## 10. Arquitetura alvo no `dart_quill`

### 10.1 Bibliotecas públicas

Manter os entrypoints já existentes:

```text
dart_quill.dart
dart_quill_table_better.dart
dart_quill_docx.dart
dart_quill_html.dart
dart_quill_pdf.dart
```

Adicionar, quando estabilizado:

```text
dart_quill_office.dart
```

Responsabilidades:

| Biblioteca | Responsabilidade |
|---|---|
| `dart_quill.dart` | Delta/Quill básico e API compatível |
| `dart_quill_table_better.dart` | perfil table-better e comandos de tabela Quill |
| `dart_quill_docx.dart` | codec DOCX público simplificado existente |
| `dart_quill_html.dart` | conversão Delta ↔ HTML semântico |
| `dart_quill_pdf.dart` | geração de PDF a partir de Delta |
| `dart_quill_office.dart` | sessão avançada, DOCX preservador, OfficeDelta e paginação |

O modo básico não importa a biblioteca Office. Isso protege tamanho, startup,
registries e comportamento legado.

### 10.2 Perfil SALI por instância

Criar um `SaliQuill203Profile`, inicialmente no adaptador da aplicação e depois
generalizável, com:

- formatos padrão Quill 2.0.3;
- formatos table-better 1.2.3;
- `headerImage`;
- fontes Inter, Arial, Calibri e aliases atuais;
- tamanhos aceitos pelo SALI;
- atributos de página;
- `table-temporary.col-widths`;
- política de links e imagens;
- normalização de paste Word;
- geração de HTML semântico;
- limites de segurança.

O registry precisa ser por instância. Abrir um editor avançado não pode
contaminar outro editor básico na mesma página.

### 10.3 Fachada do `new_sali`

Criar uma fachada sem expor o engine:

```dart
abstract interface class SaliDocumentEditorFacade {
  Future<void> loadDeltaJson(String json);
  String getDeltaJson();
  String getValidSemanticHTML();
  bool hasMeaningfulContent({bool ignoreHeaderImage = true});
  Future<void> addText(String text);
  Future<void> clearAllText();
  Future<void> insertHeaderImage(String source);
  Future<void> insertInternalCitation(Object citation);
  Future<List<int>> gerarPreviewDocumentoFinalizadoBytes();
  Future<void> reset();
  Future<ModeSwitchResult> switchMode(EditorMode mode);
  Future<void> dispose();
}
```

O contrato final deve preservar os nomes necessários ao rollout ou oferecer um
adaptador de compatibilidade para que as páginas sejam migradas gradualmente.

Também precisa substituir checagens como `editor.quill != null` por
`editor.isReady`, pois o modo avançado não terá uma instância Quill.

Durante a primeira fase, o facade Angular deve preservar:

- selector `quill-text-editor`;
- `ControlValueAccessor<String>` com HTML;
- output `onChange` com HTML semântico;
- output `previewRequested`;
- nomes dos métodos imperativos usados pelas páginas.

Uma API nova e mais consistente pode existir por baixo, mas a quebra do contrato
Angular não deve ser misturada com a troca de engine.

### 10.4 Sessão avançada

A sessão avançada mantém:

- snapshot imutável;
- árvore editável;
- transações e histórico;
- índice de estilos/numbering;
- source map OOXML;
- cache de layout;
- mapa de seleção em offsets UTF-16;
- projeção Delta Quill visível;
- relatório de compatibilidade;
- baseline e patches das parts OPC.

Texto, régua, estilo, tabela, header/footer e campos entram no mesmo histórico
transacional. Edições em overlays que só são salvas no `blur` não são
suficientes.

### 10.5 Paginação

Os dois modos usam o mesmo modelo:

- **rápido:** fluxo contínuo com páginas/flutuadores aproximados, overscan,
  medição limitada e repaginação local;
- **fidelidade:** layout determinístico por seção/página, regras de quebra,
  headers/footers, fields, tabelas, footnotes e estabilização de páginas.

A troca de paginador não converte nem reinterpreta o documento.

Tarefas pesadas podem executar em worker compilado para JavaScript ou Wasm:

- inflate/deflate;
- parsing XML;
- construção de índices;
- style resolution;
- medição/layout puro;
- serialização DOCX;
- geração de PDF.

DOM, seleção e `contenteditable` permanecem na main thread. Deve existir fallback
funcional para execução sem worker.

## 11. Integração com PDF e assinatura do SALI

### 11.1 Documentos Quill antigos e básicos

Manter o caminho atual inalterado:

```text
Delta Quill -> sanitização existente -> PDF existente -> hash/assinatura
```

Isso evita reprocessar ou migrar em massa despachos históricos.

### 11.2 Documentos Office

Para preservar a paginação realmente vista pelo usuário:

```text
OfficeDeltaSnapshot
   -> layout/PDF Dart no frontend
   -> bytes finais
   -> armazenamento/hash/assinatura pelo fluxo existente
```

O backend não interpreta DOCX, não pagina e não executa um engine documental.
Ele recebe os bytes finais, valida limites/tipo e executa sua responsabilidade
jurídica de persistência, hash e assinatura.

Isso pode exigir uma pequena rota/alteração no backend atual, mas não cria uma
dependência de renderização no backend.

Se “sem backend” também significar **zero alteração no fluxo de assinatura
existente**, então o modo Office não pode assinar com fidelidade total. Nesse
cenário, somente documentos projetáveis sem perda para o Delta Quill atual
podem entrar no fluxo; os demais devem permanecer em rascunho avançado ou usar
uma exportação explícita degradada.

Essa limitação deve ser decidida como política de produto antes do rollout.

## 12. Persistência

### 12.1 Sem migração destrutiva

Não converter todos os registros antigos.

Ao ler:

1. consultar `document_kind` e a existência do sidecar Office;
2. se houver sidecar, validar seu `office-manifest` e torná-lo canônico;
3. na ausência dele, tratar `delta` como Quill/SALI;
4. se `delta == null`, preservar o registro como HTML-only;
5. canonicalizar somente em memória;
6. não regravar um documento apenas porque foi aberto;
7. promover somente ao usar recurso Office ou ao importar DOCX.

### 12.2 Banco atual

Em uma aplicação nova, o envelope com `office-manifest` poderia ocupar uma
coluna textual genérica. **No `new_sali` atual isso não é seguro**, porque
consumidores existentes tratam `sw_despacho.delta` como Quill e o enviam ao
renderer jurídico.

O rollout recomendado é:

| Campo | Autoridade/papel |
|---|---|
| `delta` | Sempre uma projeção `QuillDelta203` válida `{"ops":[...]}` |
| `descricao` | Projeção HTML semântica para telas/pesquisa/legado |
| `office_delta_json` | `OfficeDeltaSnapshot` canônico quando o documento for promovido |
| `document_kind`/`format_version` | Discriminador e roteamento explícitos |

O nome final pode ser coluna ou tabela associada. O requisito importante é não
colocar ops Office desconhecidos na coluna que ainda é interpretada por
consumidores Quill.

Isso continua cumprindo a exigência de salvar o documento importado como
JSON/Delta, e não como binário DOCX. O sidecar é o próprio
`OfficeDeltaSnapshot`, com `office-manifest` interno versionado.

Regras de autoridade:

1. em um registro não promovido, `delta` é canônico;
2. ao usar a primeira feature exclusiva ou importar DOCX,
   `office_delta_json` passa a ser canônico;
3. depois da promoção, `delta` e `descricao` são projeções materializadas;
4. toda gravação Office atualiza snapshot e projeções atomicamente;
5. se uma projeção Quill não puder representar algo, isso aparece no
   `CompatibilityReport`; nunca se descarta o snapshot;
6. o modo básico só edita o subset sincronizável ou abre a projeção em leitura.

Após todos os consumidores reconhecerem `document_kind`, uma consolidação
futura pode ser avaliada. Ela não pertence ao primeiro rollout.

### 12.3 DOCX sem binário autoritativo

O `OfficeDeltaSnapshot` deve carregar:

- manifesto e versões;
- regiões editáveis;
- texto e propriedades semânticas;
- estilos e numbering;
- seções;
- tabelas;
- assets em base64;
- catálogo OPC;
- parts XML/binárias desconhecidas;
- anchors/source maps;
- baseline e patches necessários ao exportador.

Assim o banco guarda JSON autocontido. O custo é um payload geralmente maior
que o ZIP DOCX original por causa do base64 e dos metadados. Compressão Dart
antes do base64 e deduplicação por hash devem ser avaliadas.

Esse custo precisa de benchmark real: já existe fixture Delta do SALI com cerca
de 2,18 MB e 11.709 ops. Limites de API, banco, memória, autosave e assinatura
devem ser medidos antes de permitir assets Office inline sem orçamento.

## 13. Roadmap recomendado

### Fase 0 — congelar contratos e proveniência

- inventariar licença e origem dos quatro repositórios;
- formar corpus anonimizado com fixtures e exemplos reais;
- registrar versões exatas Quill/table-better/plugins SALI;
- congelar saídas de Delta, HTML semântico e PDF do editor atual;
- definir limites de tamanho, segurança e performance.

**Gate:** nenhuma incorporação de código sem proveniência; corpus reproduzível.

### Fase 1 — tornar `dart_quill` um substituto básico seguro

- codec público para envelope `{"ops":[...]}`;
- preflight/relatório de compatibilidade;
- snapshots profundos imutáveis;
- registries/perfis por instância;
- `SaliQuill203Profile`;
- `headerImage`;
- fontes e tamanhos SALI;
- atributos de página;
- `table-temporary.col-widths`;
- correções Delta/embeds/Unicode identificadas;
- paridade de paste, HTML e lifecycle;
- fachada AngularDart inicial.

**Gate:** todos os documentos do corpus abrem, editam e salvam sem perda
semântica ou perda silenciosa.

### Fase 2 — shell avançado dentro do `dart_quill`

- portar model/state/transform/view necessários do `docx_rendering`;
- seleção, IME, clipboard e history;
- editor `contenteditable` virtualizável;
- API de sessão e lifecycle;
- mapeamento UTF-16 entre Delta e árvore.

**Gate:** Delta Quill padrão alterna básico ↔ avançado ↔ básico sem promoção e
sem perda.

### Fase 3 — OfficeDelta e DOCX

- implementar `OfficeDeltaCodec`;
- tornar `dart_quill/lib/src/office` a autoridade OPC/DOCX;
- preservar parts e fragments opacos;
- source map e patch writer;
- importação DOCX → snapshot;
- snapshot → DOCX;
- reabertura somente pelo snapshot JSON;
- fuzzing ZIP/XML/OPC e limites de segurança.

**Gate:** `DOCX A -> snapshot -> DOCX B` conserva semântica e conteúdo opaco
declarado; `snapshot -> reabrir -> snapshot` é determinístico.

### Fase 4 — recursos profissionais

- estilos e templates;
- títulos customizados;
- régua, margens e tab stops;
- tabelas com resize, merge/split e repetição de header;
- seções, headers e footers;
- fields e numeração de página;
- TOC automático;
- imagens e drawings;
- dois paginadores;
- preview e PDF.

**Gate:** cada recurso possui round-trip DOCX, persistência OfficeDelta,
undo/redo e testes de paginação.

### Fase 5 — integração progressiva no `new_sali`

1. disponibilizar o `dart_quill` inicialmente como viewer/shadow, mantendo o
   Quill JS como writer;
2. comparar em shadow mode Delta/HTML/PDF e operações table-better;
3. liberar o writer Dart básico para novos rascunhos, com fallback para JS;
4. liberar paginação leve sobre o mesmo QuillDelta, sem promoção;
5. liberar modo avançado/sidecar somente para novos documentos e usuários
   internos;
6. liberar importação DOCX;
7. integrar PDF Office congelado ao fluxo de assinatura;
8. remover scripts Quill globais somente após paridade comprovada.

Flags independentes:

```text
editor.engine = quill_js | dart_quill
editor.pagination = none | light | fidelity
editor.office_import = true | false
editor.office_save = true | false
editor.client_pdf_signing = true | false
```

As flags devem aceitar segmentação por ambiente, usuário ou setor e possuir
kill switch. Engine, paginação e assinatura não devem ser uma única flag.

**Gate:** rollback por registro e por usuário sem regravar o dado original.

### Fase 6 — desempenho e hardening

- worker real;
- layout incremental;
- virtualização de DOM/páginas;
- cache por revisão e dirty range;
- benchmarks longos;
- Chrome/Edge/Firefox;
- IME, composição, RTL, screen reader e teclado;
- testes de memória e teardown repetido.

**Gate:** metas quantitativas do plano técnico detalhado atingidas no hardware
de referência.

## 14. Gates de compatibilidade obrigatórios

### Gate A — Quill 2.0.3

- aceitar envelope e lista legada;
- emitir envelope padrão;
- preservar offsets UTF-16;
- document Delta separado de change Delta;
- reproduzir canonicalização upstream declarada;
- nenhum desconhecido descartado sem diagnóstico.

### Gate B — SALI

- corpus atual com 12.507 ops;
- corpus anonimizado de produção;
- `headerImage`;
- fontes/tamanhos;
- page setup;
- table-better;
- `table-temporary.col-widths`;
- paste Word;
- HTML semântico;
- PDF atual.

### Gate C — alternância

- básico → avançado → básico;
- seleção mapeada;
- undo/redo com fronteira explícita;
- ausência de promoção quando só há recursos Quill;
- bloqueio seguro após recurso Office;
- nenhuma montagem de storage ops no Quill.

### Gate D — DOCX

- importação e reabertura a partir do JSON;
- exportação determinística;
- preservação de partes desconhecidas;
- assets autocontidos;
- estilos, numbering e seções;
- tabela e headers/footers;
- comparação semântica e visual.

### Gate E — assinatura

- bytes visualizados iguais aos enviados para assinatura;
- hash reproduzível;
- vínculo entre revisão do snapshot e PDF;
- bloqueio de edição concorrente durante finalização;
- trilha de auditoria;
- fallback Quill histórico inalterado.

## 15. Primeiros PRs recomendados

1. Adicionar `QuillDeltaJsonCodec`, `CompatibilityReport` e limites de entrada.
2. Corrigir deep snapshot, embed retain, embeds mapa, fórmula e diff surrogate.
3. Introduzir registry/perfil por instância.
4. Criar fixtures/goldens do perfil SALI, sem alterar o `new_sali`.
5. Implementar `SaliQuill203Profile`.
6. Criar uma fachada experimental no `new_sali` atrás de feature flag.
7. Mover/portar o núcleo mínimo de model/state/transform do
   `docx_rendering`.
8. Portar a view `contenteditable` e provar alternância com Delta simples.
9. Implementar o `OfficeDeltaCodec` e a promoção atômica.
10. Conectar o importer/exporter DOCX canônico.

O editor avançado não deve começar por toolbar, régua ou aparência. Primeiro
precisa provar contratos de dados, seleção, history e round-trip.

## 16. O que não fazer

- não paginar a árvore `Scroll` do Quill básico;
- não misturar formatos Office no registry básico global;
- não enviar `OfficeDeltaSnapshot` para `Quill.setContents()`;
- não achatar tabelas para interoperar;
- não usar HTML como fonte de verdade;
- não regravar todos os despachos antigos;
- não escolher canvas se `contenteditable` continuar obrigatório;
- não manter dois codecs autoritativos de DOCX;
- não portar dependências duplicadas do `docx_rendering`;
- não chamar `Future(callback)` de worker;
- não prometer “100% igual ao Word” sem corpus, tolerância e limites formais;
- não liberar assinatura Office antes de vincular snapshot, PDF e hash.

## 17. Critério final de sucesso

A migração será considerada bem-sucedida quando:

1. os despachos Quill 2.0.3 antigos continuarem editáveis e assináveis;
2. o modo básico puder substituir o JavaScript sem divergência relevante;
3. um Delta comum puder alternar entre básico e avançado sem perda;
4. um DOCX puder ser importado, salvo somente como JSON, reaberto e exportado;
5. recursos Office não forem silenciosamente destruídos pelo modo básico;
6. o usuário puder escolher paginação rápida ou de fidelidade sem converter o
   documento;
7. o PDF assinado corresponder à revisão visualizada;
8. todo o runtime documental continuar frontend-only e Dart;
9. o `new_sali` depender de uma fachada estável, e não dos detalhes do engine.

## 18. Conclusão

O investimento com melhor relação entre risco, reaproveitamento e manutenção é
**transformar o `dart_quill` na plataforma única de edição do SALI**.

O modo básico continua sendo Quill. O modo profissional é um novo engine
`contenteditable`, portado seletivamente do `docx_rendering`, apoiado pelo núcleo
Office canônico que já existe no `dart_quill`. O `canvas-editor-port` permanece
como referência e opção experimental de renderização, não como fundação do
editor.

Antes de qualquer trabalho visual avançado, o projeto deve concluir a paridade
do perfil SALI e congelar o fluxo jurídico de Delta/HTML/PDF/assinatura. Essa é
a fronteira que torna possível evoluir para DOCX e Word sem quebrar os
despachos existentes.

## 19. Evidências locais principais

### `new_sali`

- `frontend/lib/src/shared/components/quill/quill_text_editor.dart:44-60`:
  componente Angular e `ControlValueAccessor<String>`;
- `quill_text_editor.dart:228-317`: medição de colunas, `col-widths` e page
  setup;
- `quill_text_editor.dart:353-425`: registro table-better e whitelists;
- `quill_text_editor.dart:618`: citações internas;
- `quill_text_editor.dart:679-717`: preview final;
- `quill_text_editor.dart:834-854`: HTML semântico e JSON Delta persistido;
- `quill_text_editor.dart:1046-1055`: export manual sem o mesmo enrichment;
- `quill_text_editor.dart:1088-1121`: carga do Delta;
- `quill_text_editor.dart:1123-1150`: contrato de forms/lifecycle;
- `frontend/lib/src/modules/protocolo/pages/editar_despacho/editar_despacho_page.dart:480-488`:
  carga e vazamento de readiness por `.quill`;
- `editar_despacho_page.dart:980-1004`: dual-write HTML + Delta;
- `core/lib/src/models/despacho.dart:100-129,231-249`: modelo e serialização;
- `backend/scripts/ci/schema_sali.sql:4053-4069`: colunas atuais;
- `backend/lib/src/modules/assinatura/services/despacho_pdf_service.dart:24-94`:
  contrato Delta, PDF, hash e congelamento;
- `core/lib/src/services/pdf/sali_quill_pdf_defaults.dart:21-87,111-156`:
  page setup, sanitizer e conversão;
- `core/lib/src/services/pdf/quill_pdf_sanitizer.dart:12-90`: formatos
  removidos/permitidos;
- `frontend/web/assets/js/quill_custom_plugins/pmro_sali_header.js:10-39`:
  `headerImage`;
- `frontend/web/assets/js/quill_custom_plugins/sali_page_setup.js:1-56`:
  atributos de página;
- `frontend/web/assets/js/quill_custom_plugins/sali_fonts.js:26-62`:
  fontes e aliases;
- `frontend/web/assets/js/quill_custom_plugins/sali_word_paste.js:379-433`:
  patch do clipboard.

### `dart_quill`

- `lib/src/office/README.md:3-33`: escopo e origem do núcleo Office;
- `lib/src/converters/docx/docx_codec.dart:16-25`: perdas declaradas do codec
  DOCX público simplificado;
- `lib/src/office/word/quill_delta.dart:14-23,394-415,465-492`: bridge atual e
  limites de embeds/atributos;
- `lib/src/formats/font.dart`: whitelist básica atual;
- `lib/src/formats/size.dart`: whitelist básica atual;
- `lib/src/table_better/formats/table.dart:30-36`: atributos table-better
  reconhecidos;
- `test/unit/table_better/goldens_test.dart:18-28,47-55,98-108`: goldens contra
  Quill 2.0.3/table-better;
- `test/unit/table_better/delta_apply_test.dart:8-10,70-81`: hidratação e
  round-trip da tabela;
- `lib/src/delta/core/delta.dart:327-340`: shape JSON interno;
- `lib/src/core/editor.dart:265-316`: normalização e snapshot atual;
- `lib/src/blots/abstract/blot.dart:168-275`: desconhecidos e registry.

### `docx_rendering`

- `lib/src/tiptap/converters/quill_delta.dart:20-21,309-318,508-517`:
  achatamento de tabela e embeds reconhecidos;
- `lib/src/tiptap/converters/docx_export.dart:15-17`: limitações declaradas;
- `doc/plano_editor_completo.md:64-76`: hardening pendente da view;
- `doc/plano_editor_completo.md:98-143`: paginação, DOCX e Delta;
- `doc/RELATORIO_INVESTIGACAO_E_MELHORIAS.md:207-225`: engines e perdas
  conhecidas.

### `canvas-editor-port`

- `lib/src/editor/core/rendering/page_canvas_manager.dart:5-30`: canvas por
  página;
- `lib/src/editor/core/cursor/cursor_agent.dart:6-45`: agente de entrada;
- `lib/src/editor/core/cursor/cursor.dart:52-83,122-135,209-240`: textarea
  oculta/cursor;
- `lib/src/editor/core/event/handlers/composition.dart:10-52`: IME manual;
- `lib/src/editor/core/worker/worker_manager.dart:19-33`: agendamento que ainda não é
  worker real;
- `lib/src/word/quill_delta.dart:404-414,465-492,525-532,588-607,671-676`:
  perdas de embeds, atributos, tamanhos e tabelas.
