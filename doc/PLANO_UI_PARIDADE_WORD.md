# Plano — paridade de UI do editor Word (chrome, contextual e objetos)

**Data da auditoria:** 2026-08-09
**Escopo auditado:** `lib/src/document_engine/ui/` (ribbon, abas, réguas, status
bar), `lib/src/document_engine/view/` (laço de edição, clipboard, reconciler),
`lib/src/document_engine/layout/` (composer, renderer DOM, page graph),
`lib/src/document_engine/office/schema.dart`.
**Referências de comportamento:**
- ONLYOFFICE/EuroOffice: `D:\EuroOfficeNative\DocumentServer\sdkjs\word\`
  (motor) e `D:\EuroOfficeNative\DocumentServer\web-apps\apps\documenteditor\main\app\`
  (UI: `view/`, `controller/` — ribbon, quickbars, diálogos);
- LibreOffice Writer: `D:\libreoffice\core-master\sw\source\uibase\`
  (`docvw/` = área do documento e header/footer separators, `ribbar/`,
  `frmdlg/` = diálogos de frame/imagem, `chrdlg/`, `fldui/`, `table/`);
- Word real via COM: `C:\MyDartProjects\access_to_dart` (FFI/COM) para abrir
  o Word, gerar DOCX de referência e tirar screenshots comparativos.

Este plano complementa `PLANO_EDITOR_DOCX_PAGINADO_AVANCADO.md` (motor) — aqui
o assunto é o **chrome e a interação**: mini-UIs contextuais, ribbon reativa,
âncoras/handles de objetos, header/footer editável, diálogos e réguas.

---

## 1. Estado atual — o que existe, o que é parcial, o que falta

Legenda: ✅ implementado · 🟡 parcial · ❌ ausente · 🐞 com bug conhecido.

### 1.1 Superfície de edição (base)

| Funcionalidade | Status | Evidência |
|---|---|---|
| Digitação via `beforeinput` roteada pelo modelo | ✅ | `view/editor_view.dart:625` |
| IME/composição com reconciliação | ✅ | `editor_view.dart:536-565` |
| Undo/redo (Ctrl+Z/Y) | ✅ | `view/extension.dart:193-214` |
| Copiar/recortar/colar sistema (HTML+texto) | ✅ | `editor_view.dart:567-623` |
| Colar do Word preservando estrutura rica (tabela/lista/imagem) | 🟡 | `view/clipboard.dart` — parse de HTML básico; sem caminho de imagem/estilos Word |
| Tab entre células de tabela | ✅ | `editor_view.dart:947-982` |
| Seleção nativa sincronizada com o modelo | ✅ | `editor_view.dart:223-232` |
| Seleção de NÓ (clicar numa imagem/caixa seleciona o objeto) | ✅ | `NodeSelection` já existia no motor; o clique e o teclado de objeto entraram em `view/editor_view.dart` (2026-08-09) |
| Ctrl+S salva DOCX | ✅ | `ui/word_editor.dart:603-614` |
| Virtualização de páginas + página fixada pela seleção | ✅ | `editor_view.dart:374-392` |
| Zoom com slider −/+ e percentual (50–200%) | ✅ | `ui/status_bar.dart` — feito em 2026-08-09; falta Ctrl+scroll |
| Status bar clara e baixa (estilo Word, não azul) | ✅ | CSS `.dq-office-statusbar` — feito em 2026-08-09 |
| Contagem de palavras na status bar | ✅ | `status_bar.dart` — cacheada por identidade do doc (2026-08-09) |
| Spinner/overlay de loading ao abrir e salvar | ✅ | `runBusy` no controller + `.dq-office-busy` (2026-08-09) |
| Paginação progressiva estilo Word (primeiras páginas já, resto em background, contagem cresce) | ✅ | `compose(maxPages:)` + `composeContinue` + `OfficeProgressivePagination` (2026-08-09); ver §2.1 para limites |
| Localizar/Substituir (Ctrl+F/Ctrl+H) | ❌ | nenhuma ocorrência em `ui/` |
| Marcas de formatação ¶ (mostrar/ocultar) | ❌ | — |
| Hyperlink (inserir/editar/abrir) | 🟡 | marca `link` existe no schema (`office/schema.dart:224`), zero UI |
| Verificação ortográfica | ❌ | `spellcheck` nem é setado na projeção |
| Fonte de ícones com cobertura para as fases seguintes | ✅ | 116 ícones (era 35) gerados de `resources/onlyoffice_ribbon_icons` por `tool/build_icon_font.dart` (2026-08-09): bordas, disposição de texto, cabeçalho/rodapé, colunas, hifenização, numeração de linhas, marca-d'água, alinhamento de tabela e busca |

### 1.2 Ribbon — estrutura e reatividade

| Funcionalidade | Status | Evidência |
|---|---|---|
| Abas Arquivo/Página Inicial/Inserir/Layout | ✅ | `ui/ribbon.dart:83-99` |
| Aba contextual de Tabela (aparece/some com a seleção) | ✅ | `ribbon.dart:155-167` |
| Duas abas contextuais de tabela ("Design da Tabela" + "Tabela Layout") | ✅ | `tabs/table_design_tab.dart` + `tabs/table_layout_tab.dart`, registradas em `ribbon.dart:tableTabKeys` (2026-08-09) |
| Aba contextual "Cabeçalho e Rodapé" | ❌ | — |
| Aba contextual "Forma de Formato" (imagem/caixa selecionada) | ❌ | — |
| Realce de estado: negrito/itálico/sub/sobre acesos conforme seleção | ✅ | `ribbon.dart:171-219` |
| Fonte e tamanho refletem a seleção | ✅ | `ribbon_actions.effectiveInlineValue` (2026-08-09): varre os runs, VAZIO em seleção mista, e resolve marca → estilo do DOCX → padrão do compositor |
| Galeria de estilos reflete o bloco corrente | 🟡 | `ribbon.dart:221-235` — só Normal/Título 1–3 fixos; não mostra os estilos DO DOCUMENTO (ex.: "Nível 01", "Nível 1-Se…" do ETP) |
| Combobox editável de fonte (27 faces, preview na própria fonte) e de tamanho (aceita 10,5 e vírgula decimal) | ✅ | `OfficeComboBox` em `ui/controller.dart` + `buildFontFamilyCombo`/`buildFontSizeCombo` (2026-08-09) |
| Line spacing, sombreamento, bordas de parágrafo no grupo Parágrafo | ❌ | `tabs/home_tab.dart:158-181` só tem listas/recuo/alinhamento |
| Dropdown de marcadores/numeração (galeria de bullets, multinível) | ❌ | botões liga/desliga apenas (a infraestrutura de menu já existe: `ui/menu.dart`) |
| Botões Colar/Recortar/Copiar do sistema na ribbon | 🟡 | usam clipboard INTERNO (`ui/ribbon_actions.dart:166-195`); falta tentar Async Clipboard API com fallback |
| Pincel de formatação | 🟡 | só marcas de caractere, one-shot (`ribbon_actions.dart:199-224`); Word copia também formatação de parágrafo e duplo-clique trava o pincel |

### 1.3 Mini-UI contextual (quickbars) e menu de contexto

| Funcionalidade | Status | Evidência |
|---|---|---|
| Mini toolbar flutuante ao selecionar texto (fonte, tamanho, N/I/S, cor, realce, listas) | ✅ | `ui/quickbar.dart` (2026-08-09): nasce no mouseup/keyup que TERMINA a seleção, some ao digitar/colapsar, altura medida para não cobrir o texto |
| Mini toolbar de tabela (ao selecionar/clicar na âncora ⊞) | ✅ | `quickbar.showForTable` (2026-08-09) |
| Mini toolbar de imagem (alinhamento, excluir) | 🟡 | `quickbar.showForObject` (2026-08-09); disposição do texto espera wrap no compositor |
| Menu de botão direito (recortar/copiar/colar, marcas, recuo, itens de tabela) | ✅ | `ui/context_menu.dart` (2026-08-09): contextual, itens indisponíveis desabilitados; falta Fonte…/Parágrafo… (diálogos, F2 restante) |
| Popover "Opções de Layout" (ícone ao lado do objeto selecionado) | ❌ | — |

### 1.4 Objetos: imagem e caixa de texto

| Funcionalidade | Status | Evidência |
|---|---|---|
| Renderização de imagem inline (tamanho em twips) | ✅ | `layout/dom_renderer.dart:541-551` |
| Renderização de imagem/objeto ancorado (flutuante) e textBox | ✅ | `dom_renderer.dart:472-486, 590-601` (contenteditable=false) |
| Clique seleciona o objeto (moldura de seleção) | ✅ | `ui/object_adorner.dart` (2026-08-09) |
| Âncoras de redimensionamento (8 handles) em imagem | ✅ | arrasto sem reprojetar, UMA transação no pointerup, Shift mantém proporção (2026-08-09) |
| Âncoras de redimensionamento em caixa de texto | ✅ | mesmo adorno (`officeResizableNodeTypes`) — a edição in-place fica para F9 |
| Arrastar para reposicionar objeto flutuante; ícone de âncora ⚓ | ❌ | schema já guarda `offsetX/offsetY/positionHAlign` (`office/schema.dart:156-178`) |
| Opções de disposição do texto (inline, quadrado, atrás, na frente…) | ❌ | o compositor só honra `wrapTopAndBottom`; a UI espera o wrap real (senão o botão não mudaria nada) |
| Edição in-place da caixa de texto | ❌ | `textBox` é atom com `contenteditable=false`; conteúdo em `textBoxDoc` |
| Inserir imagem (aba Inserir → arquivo) | ✅ | `ui/image_insert.dart` (2026-08-09): tamanho natural lido do cabeçalho, limitado à área útil |
| Inserir caixa de texto | ❌ | — |
| Girar objeto (handle de rotação) | ❌ | — |

### 1.5 Tabelas

| Funcionalidade | Status | Evidência |
|---|---|---|
| Inserir/excluir linha e coluna, excluir tabela | ✅ | `ui/table_ops.dart` + `tabs/table_tab.dart` |
| Grid picker de inserção (hover N×M, 10×8 como no Word) | ✅ | `tabs/insert_tab.dart` `buildTableGridPicker` (2026-08-09) |
| Âncora ⊞ (seleciona a tabela) | ✅ | `ui/table_adorner.dart` (2026-08-09); o handle ◱ de redimensionar a tabela inteira fica para F5 |
| Seleção de célula/linha/coluna/tabela (arrastar entre células) | ✅ | `CellSelection` + `ui/table_map.dart` (2026-08-09); a seleção CRUA entre células continua bloqueada na view, que é o que protege a grade |
| Redimensionar coluna arrastando a borda | ✅ | guia tracejada, transação no pointerup, grava em `colWidths` E no `width` das células (2026-08-09); altura de LINHA pendente |
| Mesclar/dividir células | 🟡 | mesclar concatena o conteúdo e soma os spans; dividir só na horizontal (2026-08-09) |
| Galeria de estilos de tabela na ribbon (Design da Tabela) | ❌ | o compositor NÃO resolve `w:tblStyle` (nenhuma ocorrência em `layout/`); a galeria gravaria um atributo ignorado — depende de F8 |
| Bordas/sombreamento de célula | ✅ | `table_ops.setCellBorders/setCellShading` + aba Design (2026-08-09); honrados em `layout_composer.dart:3582,3846-3871` e `3577,4300-4306` |
| Alinhamento vertical/horizontal da célula, direção do texto, margens | 🟡 | vertical feito (`setCellVerticalAlign`, honrado em `layout_composer.dart:3578,3814-3818`); horizontal é alinhamento de parágrafo (já existe na Página Inicial); direção do texto e margens de célula continuam sem UI |
| Repetir linha de cabeçalho | 🟡 | renderer já REPETE header importado (`dom_renderer.dart:259-269`); sem UI para ligar/desligar |
| Distribuir linhas/colunas, AutoAjuste, propriedades da tabela | 🟡 | distribuir linhas e colunas feito (2026-08-09); AutoAjuste e o diálogo de propriedades continuam ausentes |
| Marcadores de coluna de tabela na régua | ❌ | `rulers.dart` não conhece tabela |

### 1.6 Cabeçalho e rodapé

| Funcionalidade | Status | Evidência |
|---|---|---|
| Renderização (inclusive variantes par/ímpar/primeira página) | ✅ | `dom_renderer.dart:164-205`; variantes em `word_editor.dart:129-131` |
| Campos PAGE/NUMPAGES resolvidos por página | ✅ | `layout/layout_composer.dart:399-401, 1886-1935` |
| Duplo clique entra no modo cabeçalho/rodapé | ❌ | região é `contenteditable=false` (`dom_renderer.dart:197`) |
| Linha tracejada + etiqueta "Cabeçalho"/"Rodapé" no modo de edição | ❌ | — |
| Corpo esmaecido durante a edição do cabeçalho | ❌ | — |
| Aba contextual "Cabeçalho e Rodapé" (ir para rodapé, primeira pág. diferente, par/ímpar, distâncias, fechar) | ❌ | flags já existem no modelo (`_titlePage`, `_evenAndOddHeaders`) |
| Inserir nº de página / campo no cabeçalho | ❌ | — |
| Edições no cabeçalho exportadas no DOCX | ❌ | headers/footers hoje são somente-leitura na sessão |

### 1.7 Layout de página e seções

| Funcionalidade | Status | Evidência |
|---|---|---|
| Orientação retrato/paisagem | ✅ | dropdown com ✓ na vigente (2026-08-09) |
| Tamanho do papel | 🟡 | dropdown com 8 papéis e as medidas em cm, preservando a orientação (2026-08-09); falta "Mais Tamanhos de Papel…" |
| Margens | 🟡 | dropdown com 4 predefinições do Word e as 4 medidas em cm, ✓ na vigente; `headerDistance`/`footerDistance` agora PRESERVADOS (2026-08-09). Falta "Margens Personalizadas…"; `setPageSetup` ainda apaga as seções importadas (B3) |
| Múltiplas seções com geometrias diferentes (importadas) | ✅ | `word_editor.dart:126`, composer usa `sections` |
| Editar UMA seção (aba Layout por seção) | ❌ | qualquer mudança vira documento inteiro |
| Colunas (1/2/3, esquerda, direita) | ❌ | dropdown existe em `tabs/layout_tab.dart`, todos os itens DESABILITADOS: nenhuma leitura de `w:cols` em `layout/`, e o compositor documenta o fluxo monocoluna (`layout_composer.dart:2914-2916`) |
| Quebras: página/coluna/seção (próxima página, contínua, par, ímpar) | 🟡 | dropdown em `tabs/layout_tab.dart` (2026-08-09): Página, Coluna e Disposição do Texto habilitadas e honradas (`layout_composer.dart:930, 2913, 2917`); as quatro de SEÇÃO ficam desabilitadas até B3 |
| Números de linha | ❌ | — |
| Hifenização | ❌ | — |
| Recuar/Espaçamento (grupo Parágrafo da aba Layout: esquerda/direita/antes/depois com spinners) | ✅ | `tabs/layout_tab.dart` (2026-08-09): 4 spinners (cm nos recuos, pt no espaçamento) pelo MESMO `applyBlockStyle` da régua, com o valor do bloco refletido |
| Aba Design (temas, formatação do documento, marca-d'água, cor/bordas de página) | ❌ | — |

### 1.8 Réguas

| Funcionalidade | Status | Evidência |
|---|---|---|
| Régua H com ticks, números a partir da margem, área útil | ✅ | `ui/rulers.dart:35-93` |
| Marcadores de recuo arrastáveis (primeira linha, esquerdo, direito) | ✅ | `rulers.dart:95-158` |
| Régua vertical acompanhando a página da seleção | ✅ | `rulers.dart:182-233`, `word_editor.dart:689-705` |
| Arrastar MARGENS pela régua (fronteira cinza/branco) | ✅ | `rulers.dart` (2026-08-09): alça na fronteira, guia durante o gesto, UMA repaginação no pointerup |
| Tab stops: clicar na régua cria parada; seletor de tipo no canto (L girando) | ✅ | `rulers.dart` (2026-08-09): canto gira entre esquerda/centro/direita/decimal; grava `style['tabs']`, que o compositor JÁ honrava (`layout_composer.dart:2664-2745`) |
| Régua contextual de tabela (marcadores de borda de coluna) | ❌ | — |
| Régua esmaecida/segmentada no modo cabeçalho/rodapé | ❌ | — |

### 1.9 Estilos (criação e gestão)

| Funcionalidade | Status | Evidência |
|---|---|---|
| Aplicar Normal/Título 1–3 | ✅ | `ribbon_actions.dart:263-286` (grava `styleId` no attr `word`) |
| Galeria dinâmica com os estilos DO DOCUMENTO (nome + preview real) | ❌ | cartões fixos (`tabs/home_tab.dart:183-191`); estilos importados do DOCX não aparecem |
| Criar estilo a partir da seleção (diálogo "Criar Novo Estilo…") | ❌ | — |
| Modificar estilo (diálogo com fonte/parágrafo/baseado em) | ❌ | — |
| Menu de contexto do cartão (Atualizar para corresponder, Renomear, Remover) | ❌ | — |
| Exportar styles.xml alterado | 🟡 | partes originais preservadas byte a byte; não há caminho para GRAVAR estilo novo/alterado |

### 1.10 Aba Inserir (paridade Word)

| Funcionalidade | Status |
|---|---|
| Quebra de página | ✅ |
| Tabela (grid picker) | ✅ (10×8, hover) |
| Imagens (do arquivo) | ✅ |
| Formas / Ícones / SmartArt / Gráfico | ❌ (fora do escopo mínimo, exceto formas básicas) |
| Link (Ctrl+K) / Indicador / Referência cruzada | ❌ |
| Comentário | ❌ |
| Cabeçalho / Rodapé / Número de Página (dropdowns) | ❌ |
| Caixa de Texto / Partes Rápidas / WordArt / Letra Capitular | ❌ (mínimo: Caixa de Texto) |
| Equação / Símbolo | ❌ (mínimo: Símbolo) |
| Folha de Rosto / Página em Branco | 🟡 (Página em Branco feita; Folha de Rosto não) |

---

## 2. Bugs conhecidos (corrigir independentemente das fases)

1. ~~**B1 — valor de fonte/tamanho em seleção mista**~~ — **CORRIGIDO
   2026-08-09**: `ribbon_actions.effectiveInlineValue` percorre os runs da
   seleção e devolve null (controle VAZIO) quando eles divergem, como no
   Word. A mesma função serve ribbon e quickbar.
2. ~~**B2 — fallback "Arial/12" fixo**~~ — **CORRIGIDO 2026-08-09**: a
   cadeia é marca → `attrs['style']` resolvido do DOCX → padrão do
   compositor (`LayoutComposer.defaultBaseFontFamily/SizePt`, agora
   constantes públicas para layout e chrome não divergirem). Um parágrafo
   sem formatação direta mostra a fonte com que o texto foi DESENHADO, não
   um palpite.
3. **B3 — `setPageSetup` destrói seções importadas.** `word_editor.dart`
   zera `_sections`. Com a aba Layout por seção (F7) isso passa a editar só a
   seção da seleção. **Ainda aberto.**
4. ~~**B4 — cartões de estilo com `_slug` frágil**~~ — **CORRIGIDO
   2026-08-09**: `styleSlug` translitera acentos, colapsa o resto em hífens
   e cai num hash estável quando não sobra nada usável.
5. ~~**B5 — status bar conta "blocos"**~~ — **CORRIGIDO 2026-08-09**: agora
   mostra contagem de palavras, cacheada por identidade do documento.
6. ~~**B6 — botões da ribbon roubam a seleção**~~ — **CORRIGIDO 2026-08-09**:
   `OfficeDomKit.button` cancela o `mousedown`, e todo popup do overlay faz o
   mesmo no próprio contêiner. Verificado em Chrome real
   (`office_editor_contextual_ui_e2e_test.dart`): a seleção sobrevive ao
   clique no N da quickbar.
8. ~~**B8 — listeners de teclado no DOCUMENTO nunca recebiam
   `DomKeyboardEvent`**~~ — **CORRIGIDO 2026-08-09**, achado pelo e2e:
   `HtmlDomDocument.addEventListener` embrulhava todo evento como
   `DomMouseEvent` ou `DomEvent`, então qualquer código com
   `event is DomKeyboardEvent` (Esc que fecha popup, atalhos globais)
   desistia em silêncio no browser — e passava nos testes de VM, onde o fake
   DOM entrega o evento tipado. Agora o mapeamento por tipo é o MESMO dos
   elementos.
7. ~~**B7 — corpo invadia o rodapé ao abrir o TR** (rodapé mais alto que a
   margem + hints `lastRenderedPageBreak` medidos com as métricas do Word)~~
   — **CORRIGIDO 2026-08-09** em `layout_composer.dart`: o inset do rodapé é
   um limite FÍSICO em todos os caminhos, e na primeira quebra forçada pela
   capacidade os hints são descartados dali em diante (senão cada marker
   seguinte fecharia uma página-lasca). TR: 140 páginas, zero overlap;
   ETP: 19 páginas preservadas. Teste: `docx_codec_test.dart`
   "TR mantém 140 páginas…".

9. ~~**B9 — `MouseEvent.clientX/Y` explodia com coordenada fracionária**~~
   — **CORRIGIDO 2026-08-09**, achado pelo e2e do F3: `package:web` declara
   `clientX/clientY` como `int`, mas o browser devolve DOUBLE em
   `PointerEvent`, com zoom ≠ 100% e em telas de device pixel ratio
   fracionário. O getter tipado lançava TypeError no dart2js e derrubava o
   handler inteiro — o sintoma é "arrastar não faz nada", só em algumas
   máquinas, e o fake DOM nunca o reproduz. `HtmlDomMouseEvent` agora lê a
   propriedade crua e converte para double. Afetava TODO arrasto: alças de
   objeto, marcadores de recuo da régua e a âncora da quickbar.
10. ~~**B10 — `mount` sem `schema:` criava outra instância de Schema**~~ —
    **CORRIGIDO 2026-08-09**, também achado pelo e2e: `officeQuillSchema()`
    constrói um Schema NOVO a cada chamada, e o content matching compara
    tipos por IDENTIDADE. Um consumidor que montasse o editor sem passar o
    mesmo schema do documento tinha toda inserção posterior descartada em
    silêncio (transação sem passos). Agora `mount` usa o schema DO
    DOCUMENTO por padrão e rejeita explicitamente um `schema:` incompatível.
    O próprio `example/office_editor` tinha esse defeito.

### 2.5 F5 concluída em 2026-08-09 (sem a galeria de estilos)

**Duas abas contextuais**, como no Word: `tabs/table_design_tab.dart`
(aparência) e `tabs/table_layout_tab.dart` (estrutura). Elas nascem e somem
juntas — o contexto é o mesmo — e `ribbon.dart` passou a tratar uma LISTA de
abas contextuais (`OfficeRibbon.tableTabKeys`) em vez da chave única `table`.

**A regra que decidiu o escopo:** nenhum controle grava atributo que o
compositor ignora. Cada botão exposto foi conferido em `layout_composer.dart`:
bordas de célula (`word.borders`, linha 3582 e 3846-3871), sombreamento
(`cell.background`/`word.shading.fill`, 3577 e 4300-4306), alinhamento
vertical (`cell.verticalAlign`/`word.vAlign`, 3578-3581 e 3814-3818), largura
de coluna (`colWidths`, 3638) e altura de linha (`word.heightTwips` +
`heightRule`, 3547-3548 e 3762-3773). Os cinco também sobrevivem à
exportação: `docx_codec` reconstrói `w:tcBorders`, `w:shd`, `w:vAlign`,
`w:tblGrid` e `w:trHeight` a partir desses mesmos mapas.

**Ficou de fora, com motivo:** a galeria de estilos de tabela. Ela aplicaria
`w:tblStyle`, e não existe UMA linha no `layout/` que leia esse atributo — a
cascata de estilo de tabela (tabela → bandas → cabeçalho → célula) não está
implementada. Um cartão de galeria mudaria o modelo e a tela continuaria
idêntica, que é exatamente o botão-que-não-faz-nada que este plano proíbe.
Fica para F8, junto do `OfficeStyleCatalog`.

**Duas decisões de contrato que valem registro:**
- "Sem bordas" grava `val: nil` EXPLÍCITO em vez de omitir a chave. Omitir
  significa "não opinei" e deixa a célula herdar `tblBorders`; só o `nil`
  apaga a aresta. O compositor distingue os dois casos por `containsKey`.
- "Distribuir linhas" recebe a altura de FORA (`data-height-twips` das linhas
  projetadas). A altura real de uma linha sem `w:trHeight` só existe depois de
  composta; calculá-la dentro de uma operação de modelo significaria compor o
  documento ali dentro. E a regra gravada é `atLeast`, nunca `exact`: `exact`
  cortaria em silêncio o conteúdo que não coubesse.

**Pendente desta fase:** galeria de estilos (F8); AutoAjuste e diálogo de
Propriedades da Tabela; direção do texto e margens de célula (o compositor lê
`word.margins`, mas o controle é um diálogo, não um botão); repetir linha de
cabeçalho (o renderer já repete, falta ligar `word.tblHeader` pela UI); e o
realce de estado dos botões novos — a ribbon só reflete marcas e estilo de
bloco, então o alinhamento vertical corrente ainda não acende o botão.

### 2.6 F7 (réguas + quebras) concluída em 2026-08-09

**Réguas.** As fronteiras cinza/branco viraram alças de MARGEM; o canto "L"
gira entre esquerda/centro/direita/decimal e é o tipo armado para a próxima
parada; clicar na banda cria uma parada de tabulação, arrastar move, soltar
fora remove. Todos os três arrastos seguem a regra do repositório: durante o
gesto só a guia se move, e a transação/repaginação sai uma vez no
`pointerup`.

A pergunta aberta do plano ("o modelo já tem `tabs` no estilo de
parágrafo?") tem resposta: **sim**. O compositor já lia `style['tabs']` e
resolvia esquerda/centro/direita/decimal, com `leader` e `clear`
(`layout_composer.dart:2354`, `:2664-2745`) — a régua só precisava escrever
ali, sem tocar no motor.

**Quebras e Colunas.** Dropdown de Quebras com Página, Coluna e Disposição
do Texto habilitadas e honradas. As quatro de SEÇÃO e todas as opções de
Colunas ficam VISÍVEIS e DESABILITADAS, com o motivo na descrição do item —
desabilitar diz a verdade; habilitar seria um botão que não muda nada.

**Bug latente corrigido:** os listeners de ponteiro da régua viviam só no
`_canvas`, mas a faixa da régua é IRMÃ dele — um gesto curto contido na
régua nunca gerava `pointermove` no canvas. Isso já afetava o arrasto dos
marcadores de recuo.

### 2.5b Correção de fidelidade herdada do F4

`setTableColumnWidth` e `distributeTableColumns` gravavam a largura em
`cell.width` e em `colWidths`, mas NÃO em `word.width` (o `w:tcW`). Numa
tabela importada o `tcW` antigo sobrevive no XML e o Word costuma
preferi-lo à grade nova: a coluna redimensionada voltava ao tamanho velho
ao abrir no Word. As duas funções agora escrevem nos três lugares.

### 2.4 F4 concluída em 2026-08-09

**Mapa de grade** (`ui/table_map.dart`). A árvore guarda linhas com as
células que existem; a grade VISUAL é outra coisa, porque `colspan` ocupa
colunas vizinhas e `rowspan`/`vMerge` ocupam linhas abaixo. Sem essa
tradução não é possível responder "quais são as células da coluna 3" — a
pergunta que seleção retangular, redimensionamento e mesclagem fazem o tempo
todo. As duas formas de continuação vertical viram a mesma coisa aqui: o
DOCX materializa `vMerge=continue` e o Quill omite o slot coberto.

**CellSelection** (`state/selection.dart`). Uma faixa POR CÉLULA, não um
`from..to` cru — que arrastaria junto as células intermediárias das outras
colunas. Nunca é considerada vazia: células em branco selecionadas continuam
sendo o destinatário de "excluir linha", "mesclar", "sombrear".

**Operações** (`ui/table_ops.dart`): selecionar retângulo/linha/coluna/tabela;
mesclar CONCATENANDO o conteúdo (perder texto em silêncio é o pior resultado
possível dessa operação); dividir; e gravar largura de coluna nos DOIS
lugares que precisam concordar — `colWidths` da tabela (`w:tblGrid`) e o
`width` de cada célula. Escrever só um faz o Word e a projeção discordarem.

**Adornos** (`ui/table_adorner.dart`): realce da seleção, âncora ⊞ que
seleciona a tabela, e redimensionamento de coluna com guia tracejada — a
transação sai UMA vez no `pointerup`, como no resize de objeto. Arrastar de
uma célula para outra vira seleção retangular; arrastar DENTRO de uma célula
continua sendo seleção de texto.

**Quickbar de tabela**: inserir/excluir linha e coluna, mesclar e dividir,
reusando as mesmas funções da aba contextual.

**Pendente de F4:** marcadores de coluna na régua e altura de linha por
arrasto; a divisão só é horizontal (a vertical exige rearranjar a grade
inteira). Estilos de tabela e as duas abas contextuais são F5.

### 2.3 F3 concluída em 2026-08-09

**Seleção de objeto.** `NodeSelection` já existia no motor
(`state/selection.dart`) — o que faltava era a view. Clicar numa imagem ou
caixa de texto seleciona o NÓ (`view/editor_view.dart`, handler de
`pointerdown` que resolve o elemento pelo mapa de posições), e o teclado
passa a agir sobre o objeto: Delete/Backspace apagam, setas e Esc escapam
para o texto vizinho.

**Moldura e alças.** `ui/object_adorner.dart` desenha no overlay a moldura e
as 8 alças do Word. Durante o arrasto **a projeção não é reconstruída** —
só o adorno se move, e a transação sai UMA vez no `pointerup` (mesma regra
da composição IME). Shift nas alças de canto mantém a proporção; alças de
aresta mudam uma dimensão só. A geometria vem do DOM projetado, não de um
cálculo paralelo em twips.

**Inserir → Imagens.** `ui/image_insert.dart` lê as dimensões do CABEÇALHO
do arquivo (PNG/JPEG/GIF/BMP/WebP, sem decodificar pixels), converte a
96 dpi e limita à área útil preservando a proporção — como o Word, e não um
tamanho arbitrário que o usuário teria de corrigir sempre.

**Barra do objeto.** Com um objeto selecionado aparece a barra DELE
(alinhamento + excluir), não a de texto. Alinhar uma caixa de texto grava
`positionHAlign`; uma imagem em linha alinha o parágrafo que a contém — os
dois comportamentos do Word.

**Verificação em Chrome real**
(`test/e2e/office_editor_object_selection_e2e_test.dart`): a moldura cobre a
imagem (±2 px), as 8 alças existem, arrastar a alça sudeste 48 px leva a
projeção de 96 → 144 px, e o DOCX exportado carrega o novo tamanho.

**Fora do escopo, com motivo:** "disposição do texto"
(quadrado/tight/atrás/na frente) NÃO foi implementada. O compositor só
honra `wrapTopAndBottom` hoje; um controle que grava um atributo que o
layout ignora seria um botão que não muda nada. Entra quando o compositor
ganhar wrap de verdade — anotado como pendência de F9/F10.

### 2.2 F0–F2 concluídas em 2026-08-09

**F0 — correções e controles.** B1, B2, B4 e B6 corrigidos (§2). Combobox
editável de fonte (27 faces, cada item na própria fonte) e de tamanho
(aceita 10,5 e vírgula decimal, arredonda para meio ponto como o OOXML).
Grid picker de tabela 10×8 com rótulo "N × M Tabela".

**F1 — overlay e popups unificados.** `ui/overlay.dart`: uma camada por
editor (`pointer-events:none`, popups com `auto`), grupos que se excluem,
UMA regra de fechamento (clique fora, Esc, scroll do canvas) e três
posicionamentos (`below`, `aboveCentered`, `atPoint`, `abovePoint` — este
mede o popup depois de anexá-lo). As paletas de cor migraram para lá.
`ui/menu.dart` descreve menu como DADOS (`OfficeMenuEntry`: rótulo,
descrição, detalhe, ✓, habilitado) e serve tanto os dropdowns da ribbon
quanto o menu de contexto. Aba Layout reescrita com os dropdowns do Word
(Margens/Orientação/Tamanho, item vigente marcado) e o grupo
Recuar/Espaçamento.

**F2 — mini-UI contextual.** `ui/quickbar.dart` e `ui/context_menu.dart`,
ambos reusando `ribbon_actions.dart` e o registro de estado da ribbon
(`OfficeRibbon.contextFor()`) — nenhuma formatação tem duas implementações.

**Verificação em Chrome real** (`test/e2e/office_editor_contextual_ui_e2e_test.dart`),
que achou dois defeitos invisíveis para o fake DOM:
- a quickbar cobria o texto (altura estimada) → `abovePoint` mede o popup;
- **B8**: `HtmlDomDocument.addEventListener` nunca entregava
  `DomKeyboardEvent`, então Esc não fechava popup nenhum no browser.

Pendências conhecidas destas fases: diálogos Fonte…/Parágrafo… (o menu de
contexto já tem o lugar deles), Colar via Async Clipboard API, e dropdowns
de marcadores/numeração e quebras — a infraestrutura (`ui/menu.dart`) já
está pronta para os três.

### 2.1 Implementados em 2026-08-09 (fora das fases)

- **Overlay de loading** — `OfficeWordController.runBusy(label, action)`;
  usado por Abrir DOCX, Salvar DOCX e Exportar PDF. Contador para chamadas
  aninhadas; atributo `data-dq-office-busy` no host para testes/integrações.
- **Status bar estilo Word** — clara (`#f3f2f1`), baixa, "Página X de Y",
  contagem de palavras e slider de zoom −/+ com percentual. O slider aplica
  o zoom no `change` (soltar), não a cada pixel — remontar 140 páginas por
  pixel de arrasto travaria o arrasto.
- **Paginação progressiva** (`OfficeProgressivePagination`):
  `compose(maxPages:)` para na primeira fronteira LIMPA (página nova
  nascendo com bloco fresco — o mesmo contrato de `startsFreshBlock` do
  reuso incremental) e devolve `PageGraph.resume`; `composeContinue` retoma.
  A view projeta a primeira fatia imediatamente e completa o resto no event
  loop; a status bar e o atributo `data-dq-office-pagination`
  (`partial`/`complete`) acompanham. TR: primeira fatia (12 páginas) em
  ~6 ms VM vs ~100-150 ms do compose único; grafo final IDÊNTICO (140
  páginas, positionMap igual).
  Limites documentados:
  - **default OFF** (`progressivePagination: null`) — os testes e2e amostram
    `totalPages` logo após abrir; ligar por padrão exige e2e aguardar
    `data-dq-office-pagination === 'complete'`. O exemplo `office_editor`
    liga.
  - fatias param em fronteira de bloco: a tabela de 1.367 linhas do TR
    (88 páginas) é UMA fatia — o corte intra-bloco fica para depois;
  - editar durante a paginação cancela as fatias e compõe o documento
    inteiro de uma vez (reuso incremental contra grafo parcial convergiria
    sem a cauda);
  - a seção ativa agora é recuperada ao retomar do meio do documento
    (`sectionIndex` derivado dos `_endsSection` anteriores) — corrige também
    um bug latente do resume incremental com múltiplas seções.

---

## 3. Arquitetura das peças novas

Princípios (mantidos deste repositório):
- **Nenhum controle tem caminho próprio para mudar o documento** — tudo vira
  transação via `OfficeWordController` (`ui/controller.dart`).
- **A UI reflete o modelo, nunca o contrário** (`ribbon.dart:169`).
- Sem `package:web` direto no chrome: tudo pela abstração `platform/dom.dart`
  (testável em VM com fake DOM).

### 3.1 Camada de overlay (pré-requisito de quase tudo)

Um `OfficeOverlayLayer` por canvas (`ui/overlay.dart`), irmão de
`.dq-office-pages`, `position:absolute`, coordenadas na MESMA projeção
twips→px do renderer. Sobre ele vivem: moldura + handles de objeto, âncoras de
tabela, linha tracejada de header/footer, popups (quickbars, paletas, menus,
dropdowns) e guias de arrasto. Popups compartilham um `OfficePopupHost` com
regra única de fechamento (clique fora, Esc, scroll) — a paleta de cores de
`home_tab.dart:214-245` migra para ele.

### 3.2 `NodeSelection` no motor de estado

`state/selection.dart` ganha `NodeSelection` (ProseMirror-like): clique em
`image`/`textBox`/`opaque` seleciona o nó; Delete apaga; setas escapam.
`dom_position_map` já mapeia atoms (`data-model-length`), falta o tipo de
seleção e o desenho da moldura pelo overlay. **Sem isso não existem handles.**

### 3.3 Quickbars (mini-UI contextual)

`ui/quickbar/` com um host comum e três conteúdos:
- **texto** — após `mouseup`/fim de arrasto com seleção não vazia (e não em
  objeto): fonte, tamanho, N/I/S, realce, cor, marcadores, numeração, Estilos,
  (futuro) Novo Comentário. Aparece acima do início da seleção, some ao digitar
  ou clicar fora (comportamento do Word; referência ONLYOFFICE:
  `web-apps/.../view/DocumentHolder.js`, LibreOffice: `sw/source/uibase/docvw`).
- **tabela** — quando a seleção está numa tabela e o usuário clica na âncora ⊞
  ou seleciona células: fonte/tamanho + Inserir/Excluir + bordas + Novo
  Comentário (screenshot de referência do usuário).
- **objeto** — imagem/caixa selecionada: alinhamento, disposição do texto,
  girar, "Ver mais…" (abre diálogo).

Todos reutilizam as MESMAS ações de `ribbon_actions.dart` — zero duplicação.

### 3.4 Menu de contexto (botão direito)

`ui/context_menu.dart`: handler de `contextmenu` no canvas com
`preventDefault`. Itens por contexto (texto, tabela, objeto, header/footer):
Recortar/Copiar/Colar (Async Clipboard API com fallback interno), Fonte…,
Parágrafo…, Link…, itens de tabela, Opções de Layout do objeto. Estrutura
declarativa (`List<MenuEntry>`), renderizada pelo `OfficePopupHost`.

### 3.5 Diálogos

`ui/dialogs/` com um `OfficeDialog` modal base (também no overlay):
- **Fonte…** (efeitos, maiúsculas, espaçamento de caracteres);
- **Parágrafo…** (recuos, espaçamento antes/depois, entrelinha, quebras);
- **Criar/Modificar Estilo** (nome, baseado em, próximo parágrafo, formatação);
- **Propriedades da Tabela**; **Mais Tamanhos de Papel…/Margens
  Personalizadas…**; **Inserir Link**; **Símbolo**.

### 3.6 Modo de edição de cabeçalho/rodapé

Duplo clique na região → `OfficeHeaderFooterSession`:
1. o corpo vira `contenteditable=false` e ganha classe de esmaecimento; a
   região da página ATIVA vira editável com um `OfficeEditorView` secundário
   montado sobre o doc do header (mesma classe, composer de região);
2. linha tracejada + etiqueta ("Cabeçalho -Seção 1-") desenhadas pelo overlay
   (referência: `sw/source/uibase/docvw/HeaderFooterWin.cxx`);
3. aba contextual "Cabeçalho e Rodapé" com: Ir para Rodapé/Cabeçalho,
   Primeira Página Diferente, Pares/Ímpares Diferentes, distâncias (spinners),
   Nº de Página (insere campo `PAGE`), Fechar;
4. ao fechar (ou duplo clique no corpo): o doc editado substitui
   `_header`/`_footer`/variante correspondente, recompõe e marca dirty —
   `docx_codec.exportEdited*` passa a receber headers editados.

### 3.7 Estilos dinâmicos

O snapshot já carrega styles.xml. Criar `OfficeStyleCatalog` (nome, id,
herança, propriedades resolvidas) exposto no controller:
- galeria da ribbon construída do catálogo (preview com fonte/cor reais,
  ordem `uiPriority`, `qFormat`);
- aplicar estilo = `styleId` no attr `word` (caminho atual) + attrs visuais
  resolvidos para o layout;
- criar/modificar estilo altera o catálogo e entra na exportação (patch de
  `styles.xml` na gravação — novo nó `w:style` serializado; partes intactas
  continuam byte a byte).

### 3.8 Tabela interativa

- `CellSelection` (retângulo de células) no motor de seleção; pintura via
  overlay; copiar/recortar/limpar agem no retângulo;
- âncora ⊞ e handle ◱ desenhados pelo overlay quando o mouse paira sobre a
  tabela (posição vem do `PageGraph`);
- resize de coluna: hit-test na borda ±3px → guia vertical → transação em
  `colWidths`/`cell.width`; linha idem (`row height`);
- mesclar/dividir: transações sobre `colspan`/`vMerge` (o renderer e a
  navegação já entendem `vMerge: continue`);
- aba "Design da Tabela": galeria de estilos de tabela (catálogo do
  styles.xml + os embutidos do Word), opções de estilo (linha de cabeçalho,
  listradas…), sombreamento, bordas;
- aba "Tabela Layout" (renomear a atual): células (mesclar/dividir), tamanho
  (altura/largura + distribuir), alinhamento na célula, dados.

---

## 4. Fases de implementação

Cada fase termina com testes (`dart test -j 1`, somente os testes do escopo
tocado) e uma verificação visual com o exemplo `example/office_editor` contra
o Word real (harness COM abaixo). Ordem escolhida por dependência técnica:
overlay/NodeSelection destravam tudo que envolve objeto.

### F0 — Correções imediatas (sem arquitetura nova) — **CONCLUÍDA 2026-08-09**
- B1, B2, B4, B5, B6 da seção 2.
- Combobox de fonte com lista completa (fonts do documento + padrão Word) e
  tamanho digitável.
- Grid picker de tabela (hover N×M) no Inserir.
- **Critério:** ribbon espelha fielmente fonte/tamanho/estilo da seleção,
  inclusive mista (vazio) e efetiva (via estilo).

### F1 — Overlay + popups unificados — **CONCLUÍDA 2026-08-09** (dropdowns de marcadores/quebras ficam para quando existirem as ações)
- `OfficeOverlayLayer` + `OfficePopupHost`; migrar paletas de cor.
- Dropdowns da ribbon estilo Word (painel com itens grandes + descrição):
  Margens, Orientação, Tamanho, Colunas (UI; aplicação de colunas fica em F7),
  Quebras, Marcadores/Numeração.
- **Critério:** um único mecanismo de popup; Esc/clique-fora fecham; nenhum
  popup rouba a seleção.

### F2 — Quickbar de texto + menu de contexto — **CONCLUÍDA 2026-08-09** (diálogos Fonte…/Parágrafo… pendentes)
- Quickbar de seleção de texto (§3.3) e `contextmenu` (§3.4) com Colar via
  Async Clipboard API (fallback: instrução Ctrl+V, como Word Online).
- Diálogos Fonte… e Parágrafo… (§3.5) acessíveis pelo menu.
- **Critério:** selecionar palavra → mini toolbar como no screenshot; botão
  direito → menu do editor (não o do browser).

### F3 — NodeSelection + imagem — **CONCLUÍDA 2026-08-09** (disposição do texto pendente: precisa de wrap no compositor)
- `NodeSelection` no estado; clique seleciona imagem; moldura + 8 handles;
  resize por arrasto (Shift mantém proporção) → transação em width/height;
  Delete remove; arrastar reposiciona (inline: drop no caret; flutuante:
  offset).
- Popover "Opções de Layout" (inline/quadrado/atrás/na frente/mover com
  texto) gravando no attr `anchor`/`extra`; ícone de âncora ⚓ para objetos
  flutuantes.
- Inserir → Imagens (pickFile → asset por hash no snapshot → nó `image`).
- **Critério:** abrir o ETP de referência, clicar no brasão do cabeçalho não
  (ainda) — no corpo: selecionar, redimensionar, desfazer; exportar DOCX e
  abrir no Word com o novo tamanho.

### F4 — Tabela interativa (seleção, âncoras, resize, quickbar) — **CONCLUÍDA 2026-08-09** (régua de tabela e altura de linha pendentes)
- `CellSelection`, âncora ⊞ (mover/selecionar tabela) e handle ◱;
- resize de colunas/linhas com guia; marcadores de coluna na régua H;
- quickbar de tabela; menu de contexto de tabela;
- mesclar/dividir células.
- **Critério:** tabela de severidade do ETP: selecionar coluna, redimensionar,
  mesclar duas células, desfazer tudo, exportar e conferir no Word.

### F5 — Ribbon de tabela em duas abas + estilos de tabela — **CONCLUÍDA 2026-08-09 exceto a galeria de estilos** (ver §2.5)
- "Design da Tabela" (sombreamento e bordas) e "Tabela Layout" (selecionar,
  linhas/colunas, mesclar/dividir, distribuir, alinhamento vertical).
- A GALERIA de estilos de tabela não entrou: o compositor não resolve
  `w:tblStyle`, então ela seria um controle sem efeito na tela. Entra com o
  catálogo de estilos de F8.
- **Critério revisto:** aplicar bordas/sombreamento numa tabela → a projeção
  muda e o DOCX exportado abre no Word com `w:tcBorders`/`w:shd`.

### F6 — Cabeçalho/rodapé editável
- §3.6 completo: duplo clique, tracejado + etiqueta, corpo esmaecido, aba
  contextual, variantes (primeira/par/ímpar), campo PAGE, exportação.
- **Critério:** editar "Folha:" no cabeçalho do ETP, salvar, reabrir no Word
  com a edição em TODAS as páginas; réguas refletem a área do cabeçalho.

### F7 — Layout completo + seções — **PARCIAL 2026-08-09** (réguas e quebras feitas; seções/colunas dependem de B3 e de colunas no compositor)
- Aba Layout com os dropdowns reais (F1) aplicando POR SEÇÃO (fix B3);
  Margens Personalizadas…/Mais Tamanhos…; quebras de seção (próxima página,
  contínua, par, ímpar) e de coluna; colunas 1/2/3/esq/dir; números de linha;
  hifenização (automática = CSS `hyphens` na projeção + `w:autoHyphenation`
  na exportação); grupo Recuar/Espaçamento com spinners.
- Réguas: arrastar margens; tab stops com seletor no canto e paradas
  clicáveis/arrastáveis (modelo já tem `tabs` no estilo de parágrafo? — se
  não, adicionar `tabStops` ao attr `style` + composer).
- **Critério:** documento com 2 seções (retrato+paisagem) criado no editor
  abre idêntico no Word.

### F8 — Estilos dinâmicos e gestão
- `OfficeStyleCatalog` (§3.7); galeria dinâmica com estilos do documento;
  menu de contexto do cartão (Atualizar para Corresponder à Seleção,
  Modificar…, Renomear, Remover da Galeria); diálogo Criar Estilo; exportação
  de styles.xml alterado.
- **Critério:** abrir o ETP → galeria mostra "Nível 01, Nível 1-Se…";
  modificar um estilo muda todos os parágrafos que o usam; DOCX exportado
  reflete no Word.

### F9 — Caixa de texto completa
- Inserir → Caixa de Texto; `NodeSelection` + handles (F3 reusa);
  edição in-place (view secundária sobre `textBoxDoc`, mesma técnica do
  header F6); opções de alinhamento/disposição; bordas/preenchimento.
- **Critério:** o quadro "Continuação de Processo" do ETP é clicável,
  editável in-place e reposicionável; exportação preserva o `w:txbxContent`.

### F10 — Inserir/Design/qualidade de vida
- Inserir: Link (Ctrl+K + diálogo), Símbolo, Número de Página, Cabeçalho/
  Rodapé (atalho para F6), Folha de Rosto, Página em Branco.
- Localizar/Substituir (Ctrl+F/H) com realce via overlay.
- Contagem de palavras; zoom com slider + Ctrl+scroll; mostrar/ocultar ¶;
  `spellcheck=true` opcional na projeção.
- Aba Design mínima: marca-d'água, cor da página, bordas da página.
- **Critério:** checklist da seção 1 sem ❌ nas linhas marcadas como mínimas.

---

## 5. Harness de referência com o Word real (COM)

Usar `C:\MyDartProjects\access_to_dart` (FFI/COM) para automatizar o Word do
Windows como ORÁCULO:
- `tool/word_reference/` (novo): scripts Dart que abrem um DOCX no Word,
  ajustam zoom/página e capturam screenshot (via COM `Window.Activate` +
  captura Win32), e geram DOCXs mínimos de referência (tabela com estilo X,
  seção paisagem, tab stops…);
- os DOCX gerados entram em `resources/` como fixtures de import/export;
- os screenshots ficam em `doc/referencias-ui/` para comparação visual manual
  (não são teste automatizado — fidelidade pixel a pixel não é meta, cf.
  "Limite honesto" do plano do motor).

## 6. Riscos e limites

- **Async Clipboard API** exige permissão/gesto do usuário; os botões da
  ribbon mantêm fallback interno com tooltip explicando Ctrl+V (igual Word
  Online).
- **Resize/arrasto e IME**: durante drag de handle a projeção não pode ser
  reconstruída (mesma regra da composição IME) — aplicar transação só no
  pointerup, com feedback via overlay.
- **Estilos de tabela embutidos do Word**: a galeria padrão do Word vem de
  `wordDocument` defaults; embutir um subconjunto (Grade, Lista Clara etc.)
  serializado como `w:style w:type="table"` na exportação.
- **Header/footer com view secundária** duplica o laço de edição; manter UMA
  classe (`OfficeEditorView`) parametrizada por raiz é obrigatório para não
  bifurcar correções.
- Cada fase deve rodar **somente os testes do escopo afetado** localmente
  (`dart test -j 1 test/<área>`); a suíte completa fica para a CI.
