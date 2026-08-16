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
| Localizar/Substituir (Ctrl+F/Ctrl+H) | ✅ | `ui/find_replace.dart` (2026-08-09): painel no overlay, contador "N de M", Anterior/Próximo, opções de caixa e palavra inteira; Substituir Tudo em UMA transação. Sem realce visual das OUTRAS ocorrências (ver §2.8) |
| Marcas de formatação ¶ (mostrar/ocultar) | 🟡 | `ui/formatting_marks.dart` + CSS `.dq-office-marks` (2026-08-09): pilcrow e seta de tabulação por pseudo-elemento. Ponto médio no espaço NÃO é viável por CSS (ver §2.8) |
| Hyperlink (inserir/editar/abrir) | 🟡 | `ui/dialogs/link_dialog.dart` (2026-08-09): Ctrl+K insere/edita/remove a marca `link` com a aparência do estilo Hiperlink. Falta ABRIR o link (Ctrl+clique) |
| Verificação ortográfica | 🟡 | `OfficeWordEditorOptions.spellcheck` (2026-08-09) liga o corretor NATIVO na projeção (corpo, cabeçalho e caixa juntos). **Desligado por padrão** e a decisão é do hospedeiro: aceitar uma sugestão chega como `beforeinput/insertReplacementText`, que o WebKit entrega NÃO cancelável — e evento não cancelável é o browser escrevendo na projeção. Em Chromium/Gecko o caminho está fechado (`view/editor_view.dart` converte o evento em transação sobre o `getTargetRanges`), verificado em Chrome real (`test/browser/office_spellcheck_test.dart`). Corretor PRÓPRIO (dicionário, painel de revisão) continua fora |
| Fonte de ícones com cobertura para as fases seguintes | ✅ | 116 ícones (era 35) gerados de `resources/onlyoffice_ribbon_icons` por `tool/build_icon_font.dart` (2026-08-09): bordas, disposição de texto, cabeçalho/rodapé, colunas, hifenização, numeração de linhas, marca-d'água, alinhamento de tabela e busca |

### 1.2 Ribbon — estrutura e reatividade

| Funcionalidade | Status | Evidência |
|---|---|---|
| Abas Arquivo/Página Inicial/Inserir/Layout | ✅ | `ui/ribbon.dart:83-99` |
| Aba contextual de Tabela (aparece/some com a seleção) | ✅ | `ribbon.dart:155-167` |
| Duas abas contextuais de tabela ("Design da Tabela" + "Tabela Layout") | ✅ | `tabs/table_design_tab.dart` + `tabs/table_layout_tab.dart`, registradas em `ribbon.dart:tableTabKeys` (2026-08-09) |
| Aba contextual "Cabeçalho e Rodapé" | ✅ | `tabs/header_footer_tab.dart` (2026-08-09): aparece com a sessão do F6, com Ir para Cabeçalho/Rodapé, Primeira Página Diferente, Pares/Ímpares e Nº de Página |
| Aba contextual "Formato de Imagem"/"Formato da Forma" (imagem/caixa selecionada) | ✅ | `tabs/object_format_tab.dart` (2026-08-15): aparece e some com a seleção do objeto, o RÓTULO segue o tipo (como no Word), grupos Organizar (alinhar + disposição do texto + excluir) e Tamanho (altura/largura em cm com trava de proporção, pelo MESMO `setObjectSizeTwips` da alça). Correções/cor/efeitos/moldura de imagem ficam de fora com o motivo escrito no cabeçalho do arquivo — o `PageGraph` projeta a imagem só com `src`, largura e altura |
| Realce de estado: negrito/itálico/sub/sobre acesos conforme seleção | ✅ | `ribbon.dart:171-219` |
| Fonte e tamanho refletem a seleção | ✅ | `ribbon_actions.effectiveInlineValue` (2026-08-09): varre os runs, VAZIO em seleção mista, e resolve marca → estilo do DOCX → padrão do compositor |
| Galeria de estilos reflete o bloco corrente | ✅ | `OfficeStyleCatalog` + `home_tab.buildStyleGallery` (2026-08-09): cartões vêm do `styles.xml` do documento, ordenados por `uiPriority`, com preview da cascata resolvida e realce por `currentStyleId` (§2.8) |
| Combobox editável de fonte (27 faces, preview na própria fonte) e de tamanho (aceita 10,5 e vírgula decimal) | ✅ | `OfficeComboBox` em `ui/controller.dart` + `buildFontFamilyCombo`/`buildFontSizeCombo` (2026-08-09) |
| Line spacing, sombreamento, bordas de parágrafo no grupo Parágrafo | ✅ | `tabs/home_tab.dart` (2026-08-09): dropdown de entrelinha 1,0–3,0 + Adicionar/Remover Espaço Antes/Depois, paleta de sombreamento e menu de bordas. O compositor passou a DESENHAR sombreamento e bordas de bloco (`layout_composer._blockDecorationOf`, `BlockFragment.backgroundColor/borders`, `dom_renderer._blockDecoration`, `pdf_renderer._renderBlockDecoration`) — ver §2.11 |
| Dropdown de marcadores/numeração (galeria de bullets, multinível) | 🟡 | `tabs/home_tab.dart` (2026-08-09): botões DIVIDIDOS com galeria de 7 marcadores e 6 formatos numéricos (`style.lvlText`/`style.numFmt`, honrados em `layout_composer._listMarkerOf` e gravados por `docx_codec._numberingForList`). Vários níveis: esquemas de MARCADOR por nível funcionam; os numerados ("1.1.1") ficam desabilitados — o compositor tem UM `listOrdinal`, não um por nível |
| Botões Colar/Recortar/Copiar do sistema na ribbon | 🟡 | usam clipboard INTERNO (`ui/ribbon_actions.dart:166-195`); falta tentar Async Clipboard API com fallback |
| Pincel de formatação | 🟡 | só marcas de caractere, one-shot (`ribbon_actions.dart:199-224`); Word copia também formatação de parágrafo e duplo-clique trava o pincel |

### 1.3 Mini-UI contextual (quickbars) e menu de contexto

| Funcionalidade | Status | Evidência |
|---|---|---|
| Mini toolbar flutuante ao selecionar texto (fonte, tamanho, N/I/S, cor, realce, listas) | ✅ | `ui/quickbar.dart` (2026-08-09): nasce no mouseup/keyup que TERMINA a seleção, some ao digitar/colapsar, altura medida para não cobrir o texto |
| Mini toolbar de tabela (ao selecionar/clicar na âncora ⊞) | ✅ | `quickbar.showForTable` (2026-08-09) |
| Mini toolbar de imagem (alinhamento, excluir) | ✅ | `quickbar.showForObject`; em 2026-08-15 ela passou a abrir também para objeto DENTRO do cabeçalho e para a caixa flutuante (§2.14), e "Alinhar" da caixa deixou de lançar (B12) |
| Menu de botão direito (recortar/copiar/colar, marcas, recuo, itens de tabela) | ✅ | `ui/context_menu.dart` (2026-08-09): contextual, itens indisponíveis desabilitados; falta Fonte…/Parágrafo… (diálogos, F2 restante) |
| Popover "Opções de Layout" (ícone ao lado do objeto selecionado) | ✅ | `ui/layout_options.dart` + o ícone `dq-office-objanchor` da moldura; numa IMAGEM os modos flutuantes seguem desabilitados com o motivo, mas "Em linha com o texto" aparece MARCADO (2026-08-15) — é o modo vigente dela, e o Word o mostra assim |

### 1.4 Objetos: imagem e caixa de texto

| Funcionalidade | Status | Evidência |
|---|---|---|
| Renderização de imagem inline (tamanho em twips) | ✅ | `layout/dom_renderer.dart:541-551` |
| Renderização de imagem/objeto ancorado (flutuante) e textBox | ✅ | `dom_renderer.dart:472-486, 590-601` (contenteditable=false) |
| Clique seleciona o objeto (moldura de seleção) | ✅ | `ui/object_adorner.dart` (2026-08-09) |
| Âncoras de redimensionamento (8 handles) em imagem | ✅ | arrasto sem reprojetar, UMA transação no pointerup, Shift mantém proporção (2026-08-09); em 2026-08-15 passou a valer também para a imagem DENTRO do cabeçalho/rodapé (§2.14, B11) |
| Âncoras de redimensionamento em caixa de texto | ✅ | mesmo adorno (`officeResizableNodeTypes`); só começou a APARECER em 2026-08-15 — clicar na caixa não selecionava o nó (B13) |
| Arrastar para reposicionar objeto flutuante | ✅ (caixa de texto) | faixas de borda da moldura (`ui/object_adorner.dart`), UMA transação no `pointerup` somando `offsetX/offsetY`; imagem fica de fora porque a importação a achata em inline (`office/document/docx/reader.dart:641-643`) |
| Opções de disposição do texto (quadrado, próximo, através, sup./inf., atrás, na frente) | ✅ | popover `ui/layout_options.dart` + botão na quickbar de objeto; o compositor honra o modo em `layout/layout_composer.dart` (`_wrapModeOf`, `_WrapField.insetsFor`, `_topAndBottomBottomTwips`) e a exportação o reescreve em `office/docx_codec.dart` (`_textBoxRawXmlWithWrap`) |
| "Em linha com o texto" para caixa de texto | ❌ (item VISÍVEL e desabilitado, com o motivo) | a caixa é sempre flutuante no motor: o token dela tem largura zero (`layout_composer.dart`, ramo `textBox` de `_breakLines`) e o visual é `position:absolute` (`layout/dom_renderer.dart:_renderTextBox`) |
| Disposição do texto para IMAGEM | ❌ (itens VISÍVEIS e desabilitados) | `wp:anchor` de imagem é lido como inline (`office/document/docx/reader.dart:641-643`); não há `offsetX/offsetY/wrapMode` no nó `image` |
| Edição in-place da caixa de texto | ✅ | `ui/text_box_session.dart` (2026-08-09): duplo clique abre uma view sobre a caixa; o `w:txbxContent` é regerado na exportação quando a assinatura mudou (§2.10). Em 2026-08-15 a sessão ganhou a view DONA: a caixa do CABEÇALHO (o quadro "Continuação de Processo" do timbre) também abre, e a gravação volta para o documento da região (§2.14) |
| Inserir imagem (aba Inserir → arquivo) | ✅ | `ui/image_insert.dart` (2026-08-09): tamanho natural lido do cabeçalho, limitado à área útil |
| Inserir caixa de texto | ✅ | `ui/text_box_insert.dart` (2026-08-09): a caixa nasce SEM `word`, e é essa ausência que faz a exportação GERAR o `wps:wsp` + `w:txbxContent` (`office/text_box_drawing.dart`) em vez de carimbar um XML velho — round-trip provado e aberto no Word real (shape `msoTextBox`, `wrapNone`, `Saved=True`) |
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
| Alinhamento vertical/horizontal da célula, direção do texto, margens | 🟡 | vertical feito (`setCellVerticalAlign`, honrado em `layout_composer.dart:3578,3814-3818`); horizontal é alinhamento de parágrafo (já existe na Página Inicial); margens de célula feitas (2026-08-09) — `w:tcMar`/`w:tblCellMar` no diálogo Propriedades, honrados em `layout_composer.dart:3520-3532,3560,3584-3591`. **Direção do texto continua DESABILITADA** com o motivo escrito: `w:textDirection` não é lido em nenhum arquivo de `layout/` |
| Repetir linha de cabeçalho | ✅ | `table_ops.setTableHeaderRows` + botão "Repetir Linhas de Cabeçalho" na aba Tabela Layout (2026-08-09); compositor conta a corrida inicial em `layout_composer.dart:994-996` e repete em `:1029-1035`, renderer em `dom_renderer.dart:262-276`, exportação em `docx_codec.dart:3217`/`writer.dart:577` |
| Distribuir linhas/colunas, AutoAjuste, propriedades da tabela | ✅ | distribuir feito (2026-08-09); AutoAjuste com "à Janela" e "Largura Fixa" honráveis e "ao Conteúdo" DESABILITADO (o compositor nunca mede conteúdo para decidir a grade — `layout_composer.dart:3383-3416`); diálogo Propriedades da Tabela em 4 abas (`ui/dialogs/table_properties_dialog.dart`), só com campos que o compositor lê |
| Marcadores de coluna de tabela na régua | ✅ | `rulers.dart` (2026-08-09): um marcador por divisa quando o cursor está na tabela, posição vinda do `PageGraph` (`ui/table_geometry.dart`), arrasto com guia e UMA transação no `pointerup` por `table_ops.setTableColumnWidth` |

### 1.6 Cabeçalho e rodapé

| Funcionalidade | Status | Evidência |
|---|---|---|
| Renderização (inclusive variantes par/ímpar/primeira página) | ✅ | `dom_renderer.dart:164-205`; variantes em `word_editor.dart:129-131` |
| Campos PAGE/NUMPAGES resolvidos por página | ✅ | `layout/layout_composer.dart:399-401, 1886-1935` |
| Duplo clique entra no modo cabeçalho/rodapé | ✅ | `ui/header_footer.dart` + `word_editor.dart` (2026-08-09) |
| Linha tracejada + etiqueta "Cabeçalho"/"Rodapé" no modo de edição | ✅ | a etiqueta diz QUAL variante está aberta (primeira página / par). A ÁREA foi corrigida em 2026-08-15 (B14): ela vai da borda da folha até a linha divisória, como no Word — antes o tracejado cobria só a faixa composta e a tira do topo do papel ficava de fora |
| Corpo esmaecido durante a edição do cabeçalho | ✅ | tira o `contenteditable`, não só a opacidade — senão o caret voltaria ao texto pelo teclado |
| Aba contextual "Cabeçalho e Rodapé" | ✅ | `ui/tabs/header_footer_tab.dart` (2026-08-09) |
| Inserir nº de página / campo no cabeçalho | ✅ | `ribbon_actions.insertPageField` (2026-08-09): cria a sequência begin/instrução/separate/end com o `officeXml` do OOXML, então o compositor resolve 1, 2, 3 por página e o Word reconhece o campo |
| Edições no cabeçalho exportadas no DOCX | ✅ | `docx_codec._applyEditedRegions` (2026-08-09): reescreve só as variantes editadas preservando o invólucro `<w:hdr …>`; partes não tocadas seguem byte a byte |

### 1.7 Layout de página e seções

| Funcionalidade | Status | Evidência |
|---|---|---|
| Orientação retrato/paisagem | ✅ | dropdown com ✓ na vigente (2026-08-09) |
| Tamanho do papel | 🟡 | dropdown com 8 papéis e as medidas em cm, preservando a orientação (2026-08-09); falta "Mais Tamanhos de Papel…" |
| Margens | 🟡 | dropdown com 4 predefinições do Word e as 4 medidas em cm, ✓ na vigente; `headerDistance`/`footerDistance` agora PRESERVADOS (2026-08-09). Falta "Margens Personalizadas…" |
| Múltiplas seções com geometrias diferentes (importadas) | ✅ | `word_editor.dart:126`, composer usa `sections` |
| Editar UMA seção (aba Layout por seção) | 🟡 | `word_editor.setPageSetup`/`pageSetup` (2026-08-09, B3): leitura e escrita seguem a seção do cursor, e "Quebras › Próxima Página" cria seção. Na EXPORTAÇÃO só a última seção chega ao arquivo — `_editedFile` aplica o override ao `sectPr` do corpo (§2, B3) |
| Colunas (1/2/3, esquerda, direita) | 🟡 | fluxo de jornal no compositor (2026-08-09): a coluna enche e o texto continua na seguinte, na MESMA página; `w:cols/@num` lido e gravado; 1/2/3 habilitados. "À Esquerda"/"À Direita" seguem desabilitadas — são colunas de larguras DIFERENTES, e a geometria só modela colunas iguais |
| Quebras: página/coluna/seção (próxima página, contínua, par, ímpar) | 🟡 | dropdown em `tabs/layout_tab.dart` (2026-08-09): Página, Coluna, Disposição do Texto e **Próxima Página** habilitadas e honradas (`layout_composer.dart:930, 1480, 2913`); Contínua sairia como quebra de página (o compositor sempre fecha a página na fronteira) e Par/Ímpar exigem página em branco de paridade — as três seguem desabilitadas com o motivo escrito |
| Números de linha | ❌ | — |
| Hifenização | ❌ | — |
| Recuar/Espaçamento (grupo Parágrafo da aba Layout: esquerda/direita/antes/depois com spinners) | ✅ | `tabs/layout_tab.dart` (2026-08-09): 4 spinners (cm nos recuos, pt no espaçamento) pelo MESMO `applyBlockStyle` da régua, com o valor do bloco refletido |
| Aba Design (marca-d'água, cor da página, bordas de página) | ✅ | `tabs/design_tab.dart` (2026-08-15): as três propriedades vivem na GEOMETRIA da seção (`PageSetupTwips.watermark/pageColor/pageBorders`) e são desenhadas pelos DOIS renderers — ligar a marca-d'água não repagina nem move uma vírgula, porque o compositor não as enxerga. `w:pgBorders` faz round-trip (§2.17). **Temas/formatação do documento continuam fora**: trocar tema é reescrever `theme1.xml` e recalcular a cascata inteira — motor, não chrome |

### 1.8 Réguas

| Funcionalidade | Status | Evidência |
|---|---|---|
| Régua H com ticks, números a partir da margem, área útil | ✅ | `ui/rulers.dart:35-93` |
| Marcadores de recuo arrastáveis (primeira linha, esquerdo, direito) | ✅ | `rulers.dart:95-158` |
| Régua vertical acompanhando a página da seleção | ✅ | `rulers.dart:182-233`, `word_editor.dart:689-705` |
| Arrastar MARGENS pela régua (fronteira cinza/branco) | ✅ | `rulers.dart` (2026-08-09): alça na fronteira, guia durante o gesto, UMA repaginação no pointerup |
| Tab stops: clicar na régua cria parada; seletor de tipo no canto (L girando) | ✅ | `rulers.dart` (2026-08-09): canto gira entre esquerda/centro/direita/decimal; grava `style['tabs']`, que o compositor JÁ honrava (`layout_composer.dart:2664-2745`) |
| Régua contextual de tabela (marcadores de borda de coluna) | ✅ | `rulers.dart` (2026-08-09): `.dq-office-colmark` por divisa, só com o cursor dentro da tabela; a posição é a PROJETADA (`table_geometry.officeTableColumnEdges`) e o commit é o mesmo `setTableColumnWidth` da alça sobre a tabela |
| Régua esmaecida/segmentada no modo cabeçalho/rodapé | ❌ | — |

### 1.9 Estilos (criação e gestão)

| Funcionalidade | Status | Evidência |
|---|---|---|
| Aplicar Normal/Título 1–3 | ✅ | `ribbon_actions.applyNamedStyle` (grava `styleId` no attr `word`) |
| Galeria dinâmica com os estilos DO DOCUMENTO (nome + preview real) | ✅ | `office/style_catalog.dart` + `tabs/home_tab.buildStyleGallery` (2026-08-09); cartões `w:qFormat` ordenados por `uiPriority`, preview com fonte/corpo/cor/negrito reais. Desde 2026-08-15 a galeria é uma JANELA com ▲ ▼ e "Mais" (B15) — antes ela era uma fileira solta e um DOCX com 30 estilos punha uma barra de rolagem horizontal atravessando a ribbon inteira |
| Criar estilo a partir da seleção (diálogo "Criar Novo Estilo…") | ✅ | `dialogs/style_dialog.openCreateStyleDialog` (2026-08-09) |
| Modificar estilo (diálogo com fonte/parágrafo/baseado em) | 🟡 | `dialogs/style_dialog.openModifyStyleDialog` (2026-08-09): família, corpo, negrito, alinhamento, recuos, espaçamento e entrelinha. Cor/itálico/sublinhado FICAM DE FORA — `LayoutComposer._BlockStyle` (4617-4671) não tem esses campos e `_styleOfText` (2539-2570) só os obtém de marcas de run |
| Menu de contexto do cartão (Atualizar para corresponder, Renomear, Remover) | ✅ | `tabs/home_tab._openStyleCardMenu` (2026-08-09), pelo `ui/menu.dart` |
| Exportar styles.xml alterado | ✅ | `OfficeStyleCatalog.patchStylesXml` + `docx_codec._applyStyleCatalog` (2026-08-09): patch TEXTUAL elemento a elemento; sem edição de estilo a parte sai byte a byte |

### 1.10 Aba Inserir (paridade Word)

| Funcionalidade | Status |
|---|---|
| Quebra de página | ✅ |
| Tabela (grid picker) | ✅ (10×8, hover) |
| Imagens (do arquivo) | ✅ |
| Formas / Ícones / SmartArt / Gráfico | ❌ (fora do escopo mínimo, exceto formas básicas) |
| Link (Ctrl+K) / Indicador / Referência cruzada | 🟡 (Link feito em 2026-08-09; indicador e referência cruzada não) |
| Comentário | ❌ |
| Cabeçalho / Rodapé / Número de Página (dropdowns) | ✅ (2026-08-09: Editar/Remover caem na MESMA sessão do duplo clique; Nº de Página usa `insertPageField` — nenhum motor novo) |
| Caixa de Texto / Partes Rápidas / WordArt / Letra Capitular | 🟡 (Caixa de Texto feita em 2026-08-09; as outras três não) |
| Equação / Símbolo | 🟡 (Símbolo feito em 2026-08-09: galeria de 42 sinais; Equação não) |
| Folha de Rosto / Página em Branco | 🟡 (2026-08-09: duas capas TIPOGRÁFICAS em `ui/cover_page.dart`, paginadas e exportadas com corpo/quebra reais. As galerias com faixas coloridas do Word dependem de forma decorativa que o compositor não desenha e ficam de fora — o menu diz isso) |

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
3. ~~**B3 — `setPageSetup` destrói seções importadas**~~ — **CORRIGIDO
   2026-08-09**: `pageSetup` passou a resolver a seção do CURSOR (antes
   devolvia `_setup`, que o compositor ignora quando há seções — a régua
   descrevia uma página que não estava na tela) e `setPageSetup` substitui só
   a entrada dessa seção. Limite explícito e testado: **o arquivo recebe só a
   última seção**, porque `_editedFile` aplica o override ao `sectPr` do
   corpo; editar uma seção intermediária muda a tela e não marca geometria
   suja — marcar gravaria a geometria dela por cima da última, corrupção
   silenciosa. Seções intermediárias na exportação continuam abertas.
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

11. ~~**B11 — objeto dentro do cabeçalho não tinha moldura nem alça**~~ —
    **CORRIGIDO 2026-08-15**: `OfficeObjectAdorner` olhava para
    `controller.view` (o CORPO). Com o modo cabeçalho/rodapé aberto, a
    seleção do brasão existe na view da REGIÃO, e o adorno perguntava a uma
    view onde nada estava selecionado — nenhuma alça era desenhada. Agora ele
    segue `activeView`, e `moveBy`/`resizeTo` montam a transação a partir da
    MESMA view em que a aplicam (antes liam o corpo e despachavam na região,
    que é a "mismatched transaction" que o estado recusa).
12. ~~**B12 — "Alinhar" da caixa de texto lançava**~~ — **CORRIGIDO
    2026-08-15**: `setObjectAlign` criava a `NodeSelection` a partir de
    `state.doc` DEPOIS do `setNodeMarkup`; a seleção tem de apontar para
    `tr.doc`. O erro morria dentro do handler do clique, então o botão
    simplesmente não fazia nada — na quickbar do objeto e no menu.
13. ~~**B13 — clicar numa caixa de texto flutuante não selecionava nada**~~ —
    **CORRIGIDO 2026-08-15**: o visual da caixa é filho do FRAGMENTO, não da
    linha, e `OfficeDomPositionMap.modelPositionAt` exige um ancestral
    `.dq-office-line` — devolvia null. Sem `NodeSelection` não há moldura,
    alça, ícone de Opções de Layout nem arrasto: a caixa era inerte. A view
    passou a ler a âncora `data-doc-pos` que o renderer já carimbava. No
    mesmo movimento, o renderer deixou de carimbar essa âncora na projeção
    REPETIDA de cabeçalho/rodapé (`docPos = -1` somado ao offset de caractere
    produzia uma posição positiva apontando para outro nó qualquer).
14. ~~**B14 — a área do cabeçalho não cobria o topo da página**~~ —
    **CORRIGIDO 2026-08-15**: o tracejado era desenhado sobre a FAIXA
    composta (a partir da distância do cabeçalho). No Word a área vai da
    borda da folha até a linha divisória, e a tira entre o topo do papel e o
    conteúdo faz parte dela. A moldura e a superfície editável passaram a ter
    geometrias separadas: a superfície continua onde o conteúdo é composto, a
    moldura cobre a área inteira (e o rodapé é o simétrico, da linha até a
    borda de baixo). A etiqueta foi para fora da linha, como no Word.
15. ~~**B15 — a galeria de estilos punha uma barra de rolagem horizontal na
    ribbon**~~ — **CORRIGIDO 2026-08-15**: os cartões eram despejados numa
    `dq-office-ribbon-row`, e um DOCX real traz dezenas de estilos `qFormat`
    (o ETP 20, o TR mais de 30). A faixa crescia sem limite e o
    `overflow-x:auto` do painel virava uma barra atravessando o editor. Agora
    a galeria é uma JANELA (trilha recortada + ▲ ▼ e "Mais", como no Word), o
    grupo Estilos é o elástico da faixa e a ribbon não rola mais na
    horizontal.
16. ~~**B16 — o fake DOM não propagava eventos**~~ — **CORRIGIDO
    2026-08-15**: `FakeDomElement.dispatchEvent` disparava só os listeners do
    próprio elemento. É a mesma família do B8: um teste que dispara no filho
    e passa, enquanto no browser real o evento não chega a ninguém, é pior
    que teste nenhum — e foi exatamente essa cegueira que deixou B11/B13
    passarem. Agora o fake sobe a árvore de elementos e honra
    `stopPropagation`. A subida para na raiz dos ELEMENTOS: quem escuta no
    `document` continua recebendo só o que é disparado nele.

17. ~~**B17 — todo run era desenhado no PDF com a largura errada**~~ —
    **CORRIGIDO 2026-08-15**, achado comparando o nosso PDF com o que o WORD
    exportou do mesmo DOCX (`tool/pdf_reference_diff.dart`). Sem faces
    embutidas o PDF desenha com as standard-14 (Helvetica/Times), enquanto o
    compositor mede com o `FontRegistry` — e as duas tabelas não coincidem: a
    Ecofont dos dois corpora resolve para Calibri/Carlito, ~7% mais estreita
    que a Helvetica. Cada run era desenhado mais largo que a caixa reservada
    e invadia o seguinte. No ETP o cabeçalho saía **"Processo nº44505/2025"**
    (sem o espaço) e o rodapé **"P á g i n a2 | 19"**. Pior no NEGRITO: o
    registro não tem variante de peso, então um run em negrito era medido com
    a largura do peso normal — a linha "…gestão pública **municipal**, no
    modelo…" saía com as duas partes sobrepostas. Agora
    `layout/pdf_standard_widths.dart` traz as larguras AFM oficiais das 14
    fontes-padrão (inclusive negrito e itálico) e o renderer absorve a
    diferença no espaçamento entre caracteres, de modo que o run desenhado
    termina exatamente onde a caixa do compositor termina. Medida contra a
    referência: o ETP saiu de **19 páginas divergentes de 19** para **1**, e
    essa uma difere só na escolha do ponto de hifenização dentro de uma
    célula.
18. ~~**B18 — comandos de TABELA quebravam no cabeçalho/rodapé**~~ —
    **CORRIGIDO 2026-08-15**: quickbar, menu de contexto, as duas abas
    contextuais, o diálogo de Propriedades e os adornos liam
    `controller.view.state` (o CORPO) e despachavam por `controller.dispatch`
    (a view ATIVA). Com o rodapé em edição — e o rodapé do TR de referência é
    uma tabela — inserir linha significava montar a transação a partir de um
    documento e aplicá-la em outro, que é a "mismatched transaction" que o
    estado recusa. As abas de tabela nem apareciam, porque a detecção também
    olhava o corpo. Pelo mesmo motivo, "Inserir → Imagens" com o cabeçalho
    aberto agora insere NO cabeçalho, como no Word. A régua ficou do outro
    lado da mesma linha: ela mede a PÁGINA, então passou a despachar
    explicitamente na view do corpo e esconde os marcadores de coluna
    enquanto uma região está aberta.

### 2.17 Aba Design: o chrome da FOLHA (2026-08-15)

Marca-d'água, cor da página e bordas de página. As três compartilham a
propriedade que decidiu onde elas moram: **não reflowam uma linha**. No Word,
pintar a folha, marcar "MINUTA" ou pôr uma moldura não muda onde o texto
quebra — então elas entram na `PageSetupTwips` da seção e são consumidas
DIRETO pelos dois renderers. O compositor nem as enxerga, e é isso que
garante que ligar a marca-d'água não repagine o documento.

**A marca-d'água não é conteúdo.** Ela não ocupa posição, não entra na
seleção, não é apagada por Ctrl+A e o caret não cai dentro dela — as camadas
são `contenteditable=false`, `pointer-events:none` e `data-model-length=0`.
Um editor que a inserisse como parágrafo faria o usuário apagá-la sem
entender o que apagou, e ela reapareceria em todas as páginas.

**Tela e PDF pela mesma fonte.** No PDF a rotação sai por MATRIZ DE TEXTO
(`Tm`), não por `q/cm/Q` em volta do bloco: o builder trabalha em
coordenadas de topo-esquerda e converte y ao escrever, então girar o sistema
inteiro inverteria também essa conversão e a marca sairia da página.
Verificado no corpus real (ETP com cor, moldura dupla e "MINUTA"): 19
páginas, folha cinza, moldura a 24 pt da borda e a marca atrás do texto.

**Round-trip.** `w:pgBorders` agora é LIDO (`WpSectionProperties.pageBorders`),
chega ao snapshot e volta ao editor: antes uma moldura importada sobrevivia
no XML preservado e mesmo assim sumia da tela — o documento parecia ter
perdido a borda, e o usuário a redesenharia por cima da que já existia. A
gravação segue a regra do `w:cols`: só quando MUDOU, senão o `sectPr` de
origem fica byte a byte (com a arte decorativa, o `w:shadow` e o
`offsetFrom="text"` que o editor não modela). A espessura é declarada em
OITAVOS DE PONTO — a unidade do arquivo —, porque 1 oitavo vale 2,5 twips e
uma escolha em twips que não seja múltiplo de 2,5 volta diferente do que
entrou (24 twips saíam como 25; o teste de ponto fixo pegou).

**Dívida honesta:** cor da página e marca-d'água ainda NÃO chegam ao `.docx`
— a primeira precisa de `w:background` + `w:displayBackgroundShape` no
`settings.xml`, e a segunda de um `v:shape` VML dentro do cabeçalho (e de
CRIAR a parte quando o documento não tem cabeçalho, que é criação de
estrutura, não edição). As duas sobrevivem no snapshot Office e no PDF, que
é o caminho do SALI; o item da aba diz isso.

**`copyWith` na geometria.** Os comandos de orientação/papel/colunas
copiavam a `PageSetupTwips` campo a campo, e toda propriedade NOVA nascia
sendo apagada por eles em silêncio — foi assim que a grade de texto do
documento se perdeu ao trocar o papel. Agora quem não fala de um campo o
preserva, e `pageSetupOf` delega a `_setupAt` pelo mesmo motivo: as duas
funções listavam o mapeamento em paralelo e uma propriedade nova era lida
por uma e ignorada pela outra.

### 2.16 Fontes de verdade: a API opcional (2026-08-15)

O motor já sabia usar uma face real (medir pela `hmtx`, embutir CID no PDF); o
que faltava era **como a face chega até ele**. `office/font_library.dart`
fecha isso sem amarrar a biblioteca a nenhum ambiente:

- **`OfficeFontLoader`** — a aplicação recebe um [OfficeFontRequest] (família,
  peso, estilo, os aliases metricamente compatíveis e o sufixo convencional de
  arquivo) e devolve bytes, ou `null` para "não tenho". O pacote não faz rede
  nem lê arquivos. `null` é MEMORIZADO: um loader de rede não é consultado
  duas vezes pela mesma face.
- **`OfficeFontLibrary`** — o acervo. Descobre o que o documento realmente usa
  (marcas de run, `attrs['style']` do bloco e o JSON das caixas de texto, onde
  mora o timbre), pede só essas combinações, e avisa uma vez quando o lote
  chega.
- **Registro na plataforma** — `DomFontFaceAdapter` (o mesmo padrão do
  download cooperativo, para não quebrar adaptador de terceiro). No browser a
  face entra pela CSS Font Loading API. Sem isso, fornecer uma fonte
  PIORARIA a tela: a medida passaria a ser da face nova e o desenho
  continuaria na antiga.
- **Uma recomposição** quando faces novas entram — a métrica do documento
  mudou, então ele repagina; caches de medição são invalidados junto.

`OfficeWordEditorOptions.fontLoader` liga tudo, e `openDocument` dispara a
busca em segundo plano (o documento aparece imediatamente com a métrica
compatível e repagina quando as faces chegam). Quem preferir abrir já com a
tipografia final chama `loadDocumentFonts()` e aguarda.

Verificação com o corpus real (`--fonts=C:/Windows/Fonts` na ferramenta de
comparação, que virou consumidora da API): o ETP embute 3 faces (Calibri,
Calibri-Bold, Arial), mantém 19 × 19 páginas e a mesma única divergência de
hifenização. `example/office_editor/web/fonts/README.md` documenta a
convenção de nomes e as fontes livres que valem a pena.

**Escopo deliberado:** o pacote continua NÃO distribuindo binários de fonte
(a política do `THIRD_PARTY.md`), e sem loader nada muda — métricas
compatíveis e standard-14, como antes.

### 2.15 Fidelidade do PDF contra o Word (2026-08-15)

`tool/pdf_reference_diff.dart` compara o PDF que o editor gera com o PDF que
o **Word** exportou do mesmo DOCX (`resources/*.pdf`). Não compara pixels —
fidelidade pixel a pixel não é meta — e sim as três coisas que um usuário
percebe na primeira olhada e que dá para afirmar automaticamente: contagem de
páginas, texto POR página e texto total. A extração usa `pdftotext`.

Estado atual:

| Corpus | Páginas (nosso × Word) | Páginas com texto divergente |
|---|---|---|
| ETP (19 páginas) | 19 × 19 | 1 — ponto de hifenização numa célula |
| TR (140 páginas) | 140 × 140 | poucas linhas de deriva acumulada |

O que continua divergindo, e por quê: **onde a linha quebra**. O Word tem a
fonte real do documento; nós temos a métrica compatível mais próxima e, sem
faces embutidas, o PDF desenha com uma standard-14. Uma diferença de 1% de
largura muda a última palavra de um parágrafo de página, e a hifenização
escolhe outro ponto ("on-premise" inteiro × "on-pre-/mise"). O que NÃO pode
divergir — e não diverge mais — é run invadindo run.

**Pendência conhecida:** o compositor mede negrito com métricas do peso
normal (`FontRegistry` não tem variante de peso). Hoje isso é compensado no
desenho do PDF, mas continua afetando a QUEBRA de linha de parágrafos com
muito negrito. Corrigir na origem é acrescentar tabelas de peso ao registro —
mudança de motor, com repaginação de todo o corpus para revalidar.

### 2.14 Objetos dentro da região (2026-08-15)

O timbre do documento real (brasão + quadro "Continuação de Processo" no
cabeçalho) juntava quatro defeitos, e todos tinham a mesma raiz: **o chrome
de objeto assumia que só existe uma view**.

- **O adorno** (moldura, alças, ícone de layout) lia a view do corpo.
- **A sessão da caixa** procurava o nó `textBox` no documento do corpo; para
  a caixa do cabeçalho ela não achava nada e desistia em silêncio. Agora a
  sessão guarda a view DONA (`ownerView`), resolvida pelo elemento clicado, e
  é para ela que o `_commit` volta — a gravação de uma caixa do cabeçalho
  entra no documento da região, que a sessão do F6 leva ao `header*.xml`.
- **Os eventos não chegavam.** Região e caixa são projetadas no OVERLAY, que
  é irmão do canvas: `dblclick`, `mouseup`, `keyup` e o `pointermove`/`up` do
  arrasto de alça viviam no canvas e nunca eram entregues. Passaram para o
  HOST, com dois filtros que substituem a garantia que o canvas dava de
  graça: as sessões só entram/saem a partir de uma projeção de documento (um
  duplo clique na ribbon não fecha mais nada) e a quickbar só nasce de um
  evento da área de edição.
- **Sair de uma caixa do cabeçalho destravava o corpo**, porque o `exit`
  chamava `setBodyEditingSuspended(false)` sem perguntar se a sessão da
  região ainda estava aberta.

O que continua fora, com motivo: a caixa flutuante ainda não pode ser
"em linha com o texto" (§2.11) e a imagem continua sem âncora flutuante no
modelo — o popover diz isso, agora com "Em linha com o texto" MARCADO, que é
o estado verdadeiro dela.

### 2.13 Colunas: fluxo de jornal (2026-08-09)

O que define colunas não é a largura das linhas — é o FLUXO. A coluna 1
enche até o rodapé e o texto continua no TOPO da coluna 2, na mesma página;
só quando a última enche é que a página fecha. Um layout que só estreitasse
as linhas e continuasse quebrando a página no fim da primeira coluna
pareceria certo numa captura de tela e estaria errado no segundo parágrafo.

A implementação é pequena porque reaproveita a máquina que já existia:
`closePage` passou a tentar `closeColumn` antes de emitir a página. O
fragmento carrega o `columnIndex` (não o x já calculado), e os dois
renderers resolvem o deslocamento pela MESMA `columnLeftTwips` que o
compositor usou — um x carimbado por fragmento divergiria do desenho no
primeiro caso de margem que eu esquecesse de propagar. `yTwips` continua
relativo ao topo do corpo, então dois fragmentos de colunas diferentes têm o
mesmo y: é o x que os põe lado a lado.

Duas coisas que essa mudança separou, e que antes eram legitimamente a mesma:

- **`force` em `closePage`.** "Acabou o espaço" (continua na coluna ao lado)
  deixou de ser "acabou a PÁGINA" (quebra manual, quebra de seção, flush
  final). Sem isso, um documento que termina antes de encher todas as
  colunas não emitia página nenhuma — foi o primeiro teste a pegar.
- **`w:br w:type="column"` vs `"page"`.** Num grafo monocoluna a próxima
  coluna livre ERA a da página seguinte, e por isso os dois puderam
  compartilhar um sinal por tanto tempo.

**`columnCount` é anulável de propósito.** null significa "não declarado",
e é isso que impede a exportação de achatar um `w:cols w:num="2"` importado
quando o chamador montou a geometria só para trocar margens — a mesma
corrupção silenciosa do B3, que dois testes de preservação de `sectPr`
pegaram na primeira tentativa. O arquivo só recebe `w:cols` quando a
contagem MUDOU; `w:equalWidth` e os `w:col` do produtor ficam onde estavam.

**Pendente:** colunas de larguras desiguais, linha separadora (`w:sep`) e
quebra de coluna balanceada no fim da seção.

### 2.11 Disposição do texto (wrap) no compositor e a UI que depende dela

O botão de disposição do texto não existia porque o compositor não sabia
desviar. Agora sabe, e é a exclusão de área — não o atributo — que os testes
cobram (`test/unit/document_engine/layout/text_wrap_test.dart`).

**Onde cada peça mora:**

- `layout/page_graph.dart`: `TextWrapMode` / `TextWrapSide` no
  `FloatingTextBoxLayout`, e `LineBox.wrapLeftInsetTwips` /
  `wrapRightInsetTwips` — o encurtamento é da LINHA, separado do recuo de
  parágrafo, porque muda a cada faixa vertical.
- `layout/layout_composer.dart`: `_WrapExclusion`/`_WrapField` (retângulos em
  coordenadas da caixa de conteúdo da página), `_wrapModeOf`,
  `_wrapExclusionsOf`, `_topAndBottomBottomTwips`. As exclusões vivem POR
  PÁGINA (`activeWrapExclusions`, zeradas em `closePage`), e `_breakLines`
  roda uma segunda passada quando o próprio bloco ancora um objeto com
  exclusão — é o laço âncora↔linha que o Word também itera.
- `layout/dom_renderer.dart` e `layout/pdf_renderer.dart`: somam o inset ao
  `left`/`right` da linha. O PDF consome o MESMO `PageGraph`, então a paridade
  sai de graça; o que precisou de cuidado foi manter a caixa flutuante
  posicionada pela largura do BLOCO, não pela largura já encurtada — senão a
  caixa se afastaria de si mesma a cada recomposição.
- `office/document/docx/reader.dart`: lê `wp:wrapSquare/Tight/Through/`
  `TopAndBottom/None` + `wp:anchor/@behindDoc` + `distL/T/R/B`.
- `office/docx_codec.dart`: `_textBoxRawXmlWithWrap` faz a cirurgia textual no
  XML preservado da caixa (mesma decisão do `_replaceTextBoxContent`), inclui
  o `wp:wrapPolygon` que `wrapTight/Through` exigem e mantém o `w10:wrap` do
  fallback VML coerente. Salvar sem trocar o modo não mexe num byte.
- `ui/layout_options.dart` + `ui/quickbar.dart` + `ui/object_adorner.dart`: o
  popover, o botão da quickbar de objeto e o ícone colado ao canto do objeto.

**Limites conhecidos (deliberados, não esquecidos):**

1. `bothSides` degrada para "maior lado": uma linha é UMA caixa no PageGraph,
   e não há como emitir a mesma linha dos dois lados do objeto.
2. `tight`/`through` usam a caixa delimitadora, não o `wp:wrapPolygon`. O erro
   é sempre para fora (o texto nunca invade o objeto).
3. Uma exclusão que cobre a largura inteira NÃO empurra a linha para baixo: o
   PageGraph desloca blocos, não linhas dentro de um bloco. A linha fica com
   `_minimumWrappedLineTwips` e o diagnóstico registra.
4. Um objeto só afeta a página em que sua âncora foi desenhada — que é a regra
   do Word — mas um parágrafo que ATRAVESSA a fronteira de página conserva as
   larguras da página em que começou.
5. "Em linha com o texto" e qualquer disposição de IMAGEM ficam desabilitadas
   com o motivo escrito no item (§1.4).

### 2.12 O grupo Parágrafo completo (2026-08-09)

**Entrelinha e espaçamento.** Dropdown com 1,0 / 1,15 / 1,5 / 2,0 / 2,5 / 3,0 e
os quatro comandos de Adicionar/Remover Espaço Antes/Depois (12 pt, como no
Word). O compositor já resolvia `lineTwips`/`lineRule`: lê em
`layout_composer.dart:2326-2331` (`_resolvedStyleOf`) e aplica em
`:2508-2537` (`_resolvedLineHeightTwips`, onde 240 = uma linha na regra
`auto`). A exportação grava em `docx_codec.dart:3106-3123` → `WpSpacing` →
`writer.dart:276-290` (`w:line`/`w:lineRule`). A escada de valores é **uma
só**, em `ribbon_actions.officeLineSpacingSteps`: o diálogo Parágrafo… deriva
os rótulos dela, senão o dropdown e o diálogo divergiriam.

**Sombreamento e bordas de parágrafo — o compositor passou a desenhar.** Antes
desta fase nada em `layout/` lia `w:shd`/`w:pBdr` de PARÁGRAFO (só de célula),
então a regra do plano deixava duas saídas: implementar o desenho ou
desabilitar o controle. Foi implementado, e é uma mudança pequena porque o
dado já existia ponta a ponta:

- `page_graph.dart` — `BlockFragment.backgroundColor` e `.borders`
  (`BlockBorders` é um `typedef` de `TableCellBorders`: são as mesmas quatro
  arestas resolvidas, e duplicar o tipo produziria duas funções de desenho
  para a mesma figura);
- `layout_composer._blockDecorationOf` — lê `attrs['word']['shading']` e
  `['borders']`, isto é, **o mesmo mapa que a exportação devolve para o
  OOXML**. Não há segundo dialeto de apresentação, e por isso um DOCX
  importado com borda direta já abre pintado;
- `dom_renderer._blockDecoration` e `pdf_renderer._renderBlockDecoration` —
  uma camada inerte (`data-model-length=0`, `contenteditable=false`) cobrindo
  só as LINHAS, não o `spaceBefore/After`, como o Word desenha. Num parágrafo
  partido entre páginas a aresta superior some nas fatias que continuam e a
  inferior nas que seguem: repetir as duas desenharia um traço no meio do
  parágrafo.

Duas decisões de contrato: quatro arestas `nil` (o que "Sem Borda" grava) são
tratadas como AUSÊNCIA de moldura, senão todo parágrafo já editado ganharia uma
caixa invisível; e a leitura é só de formatação DIRETA — o que vem da cascata
de estilos não está em `word`, e resolvê-la exigiria o catálogo dentro do
compositor.

**Ficou de fora, com motivo:** "Todas as Bordas", que no Word desenha também a
aresta `w:between` entre parágrafos vizinhos com a mesma moldura. Cada
parágrafo é uma caixa independente no `PageGraph`; o item fica visível e
desabilitado com essa frase.

**Galerias de lista.** Marcadores (7 caracteres) e numeração (1. / 1) / I. /
i. / A. / a)) em botões DIVIDIDOS — o corpo liga/desliga, a setinha abre a
galeria. O vocabulário gravado é o do OOXML (`style['numFmt']` e
`style['lvlText']`), lido em `layout_composer._listMarkerOf` e gravado por
`docx_codec._numberingForList`, que agora gera **uma definição por formato**
(a chave de cache era só "bullet"/"ordered", e a segunda escolha sobrescrevia
a primeira) e só reaproveita o `numId` importado quando ele já desenha o mesmo
rótulo.

**Lista de vários níveis, honestamente parcial.** As duas chaves aceitam uma
LISTA — um valor por nível —, o compositor indexa por `attrs['indent']` e a
exportação gera um `w:abstractNum` `hybridMultilevel` com um `w:lvl` por
nível, agora carregando também o `w:ilvl` do parágrafo (sem ele a lista saía
achatada no nível zero). Com isso "Aumentar/Diminuir Nível da Lista" troca o
marcador sozinho, sem a ação reescrever o parágrafo. Os esquemas NUMERADOS
("1.1.1", "I. A. 1.") ficam visíveis e desabilitados: o compositor mantém UM
`listOrdinal` para o documento inteiro (`layout_composer.dart:821,1179`, e ele
ainda viaja em `PageSignature.carryListOrdinal` e `PageGraphResume`), então o
primeiro subitem sairia "1.2" em vez de "1.1". Trocar o contador por um vetor
por nível toca assinatura de página e resume da paginação progressiva — é uma
mudança do MOTOR, não da ribbon.

### 2.9 F10 parcial em 2026-08-09 (Localizar/Substituir, Link, Símbolo, ¶)

Entregues: `ui/find_replace.dart`, `ui/dialogs/link_dialog.dart`,
`ui/symbol_picker.dart`, `ui/formatting_marks.dart`, com Ctrl+F/Ctrl+H/Ctrl+K
registrados em `ui/word_editor.dart` (ao lado do Ctrl+S, porque abrir painel
e diálogo é chrome, não transação sobre o `EditorState`).

O ponto que exigiu desenho: **índice de texto ≠ posição do modelo**. A
varredura achata o documento uma vez guardando `posição[i]` para cada
caractere e escrevendo uma CERCA (NUL) em todo nó que não é texto —
isso resolve de uma vez a posição depois de uma imagem (átomo ocupa posição
e não tem texto), impede ocorrência atravessando parágrafo/célula/objeto e
mantém o casamento entre runs de formatação diferente.

Pendências honestas desta fatia:

1. **Sem realce das demais ocorrências.** Só a ocorrência corrente é
   SELECIONADA. Pintar as outras exige decorações na projeção (o renderer
   desenha a partir do `PageGraph`, não há camada de decoração inline) ou
   marcas temporárias no documento — e marca temporária suja undo e DOCX.
   Depende de uma camada de decoração no `PageGraphDomRenderer`.
2. **Ponto médio no espaço (·) não sai por CSS.** Não existe seletor de
   CARACTERE; revelar espaço a espaço exigiria o renderer emitir um elemento
   por espaço, e `layout/dom_position_map.dart:199` soma o comprimento
   lógico dos filhos — a fragmentação mudaria a projeção que o mapa de
   posições e o reconciliador leem. ¶ e a seta de tabulação saem por
   `::after`/`::before` (pseudo-elemento não está no DOM, não tem
   `textContent`, não desloca nada) e estão entregues.
3. **Ctrl+clique não ABRE o hiperlink.** O renderer projeta `data-link`
   (`layout/dom_renderer.dart:583`), mas nada escuta o clique; falta decidir
   a política de navegação (mesma aba/nova aba) com a aplicação hospedeira.
4. **Localizar/Substituir e ¶ estão na aba Inserir**, não na Página Inicial
   (grupos Edição/Parágrafo, como no Word): `tabs/home_tab.dart` estava sob
   edição concorrente. São funções livres — mudar de aba é mover a linha que
   as monta.

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

### 2.10 F9 parcial em 2026-08-09 (edição in-place da caixa de texto)

Duplo clique na caixa entra, duplo clique fora sai — outra
`OfficeEditorView` sobre outra raiz no overlay, a mesma estrutura do F6 pela
mesma razão do §6.

Duas peças que a caixa exigiu e o cabeçalho não:

- o visual flutuante é filho do FRAGMENTO, não da linha, então não herdava
  offset de caractere nenhum. `FloatingTextBoxLayout.charStartInBlock` +
  `data-doc-pos` no elemento resolvem qual caixa o duplo clique abriu;
- a gravação é UMA transação ao sair, não por tecla: `textBoxDoc` vive
  DENTRO do documento do corpo, e gravar por tecla repaginaria o documento
  inteiro a cada caractere. O preço é a sessão ser um único passo de undo.

Exportação: o writer carimbava o `rawXml` importado, então a edição não
chegava ao arquivo. `_textBoxRawXml` compara a assinatura atual com
`textBoxSourceSignature` e, só quando diferem, regenera o miolo de TODAS as
ocorrências de `w:txbxContent` (o Word escreve a caixa duas vezes dentro de
`mc:AlternateContent`; atualizar uma só faria o texto mudar conforme o
leitor). O resto do XML da forma segue carimbado.

**Inserir caixa nova — concluído em 2026-08-09.** `ui/text_box_insert.dart`
cria o nó e ABRE a sessão (o cursor do Word nasce dentro da caixa);
`office/text_box_drawing.dart` gera o `mc:AlternateContent` na exportação.
Três decisões que valem registrar:

- a caixa nova nasce **sem `word`**, e é essa ausência que roteia a
  exportação para o gerador. Nascer com um XML pronto faria a primeira alça
  arrastada gravar uma largura no modelo e outra no arquivo, porque o
  `wp:extent` carimbado não acompanha o resize;
- é `mc:AlternateContent`, não `w:drawing` puro: o nosso próprio leitor só
  reconhece caixa dentro dele (`docx/reader._parseTextBox`), e um `w:drawing`
  solto voltaria como IMAGEM;
- os namespaces (`mc`, `wp`, `a`, `wps`, `v`, `o`) são declarados NO elemento
  gerado, porque o `w:document` de um documento novo declara só `w` e `r`
  (`docx/reader.createEmpty`) — prefixo não declarado é o diálogo de reparo.

Verificado contra o Word real (COM, §5): `caixa_nova.docx` e o corpus com uma
caixa inserida abrem com `Document.Saved == True` (sem reparo), a forma é
`msoTextBox` (type 17) com o texto certo e `WrapFormat.Type == wdWrapNone`.

**Pendente do F9:** as opções de disposição do texto, que dependem do
compositor honrar wrap além de `wrapTopAndBottom`; e o redimensionamento de
uma caixa IMPORTADA, que continua sem chegar ao arquivo — `_textBoxRawXml`
(`office/docx_codec.dart`) regenera só o `w:txbxContent`, então o `wp:extent`
carimbado mantém o tamanho de origem.

### 2.8 F8 (estilos dinâmicos) concluída em 2026-08-09

**`OfficeStyleCatalog`** (`office/style_catalog.dart`) resolve a cascata do
Word por ESTILO (docDefaults → cadeia `basedOn` da raiz para a folha) e
devolve um mapa cujas chaves são LITERALMENTE as de `attrs['style']`. Foi a
decisão que evitou uma segunda linguagem de apresentação: aplicar um estilo
é escrever esse mapa no bloco, e o compositor já sabe lê-lo.

O catálogo viaja em `OfficeDocxImport.styleCatalog`, não no snapshot: a UI
importa com `includePackageResources: false`, então o `styles.xml` não
sobrevive ao envelope, e reabrir o pacote só para listar a galeria custaria
outro unzip do documento. `OfficeStyleCatalog.fromSnapshot` existe para o
envelope persistido, que tem as partes opacas.

**A galeria** é o recorte que o Word faz: estilos de PARÁGRAFO com
`w:qFormat`, ordenados por `uiPriority`, com o `w:default` pregado em
primeiro (ele quase sempre tira o `qFormat` do `w:latentStyles`, que não
parseamos, e uma galeria sem "Normal" não teria caminho de volta ao corpo do
texto). Sem catálogo, os quatro cartões fixos continuam de pé.

**Três decisões de contrato:**

- **Aplicar/modificar um estilo REESCREVE as marcas dos runs.** A importação
  achata a cascata em marcas (`docx_codec._marksOf`), e no compositor a marca
  ganha do bloco (`layout_composer._styleOfText:2539-2570`). Sem tocar nelas,
  mudar a fonte de um estilo não mudaria uma letra de um DOCX importado. A
  reescrita só atinge o run cujo valor AINDA É o do estilo antigo — é o único
  sinal disponível para separar "veio do estilo" de "o usuário pôs à mão", e a
  mesma regra vale chave a chave em `attrs['style']`.
- **Exportar é patch TEXTUAL do `styles.xml`.** Reserializar a parte a partir
  do nosso modelo perderia `w:latentStyles`, `w:semiHidden`, `w:next`, rsids e
  os estilos que nem representamos — 78 KB de conteúdo alheio num DOCX real.
  O patch troca só os elementos governados dentro do `<w:style>` tocado, e
  nunca APAGA um filho que não geramos. Sem edição de estilo a parte sai byte
  a byte.
- **"Remover da Galeria" tira o `w:qFormat`, não o estilo.** Apagar a
  definição invalidaria todo `w:pStyle` que ainda aponta para ela.

**O que NÃO entrou, e por quê:** cor da fonte, itálico e sublinhado no
diálogo. `LayoutComposer._BlockStyle` (`layout_composer.dart:4617-4671`) não
tem esses três campos — o compositor só os obtém de marcas de run. Um
controle de "cor do estilo" gravaria uma definição que a tela ignoraria em
todo parágrafo novo, que é o botão-que-não-faz-nada que este plano proíbe.
Falta também a re-resolução de cabeçalhos/rodapés (raízes próprias, sem
caminho de transação por região) e a galeria de estilos de TABELA, que
continua dependendo do compositor resolver `w:tblStyle`.

### 2.7 F6 (cabeçalho/rodapé) concluída em 2026-08-09

Duplo clique na região entra no modo, duplo clique no corpo sai. A
restrição do §6 foi respeitada: **não há um segundo laço de edição**.
`OfficeEditorView` já era parametrizada por raiz, estado, compositor e
renderer — a sessão monta outra instância com a raiz no OVERLAY (fora de
`.dq-office-pages`, o que impede os dois laços de receberem o mesmo evento
por bubbling) e um compositor da geometria da região.

Duas decisões de custo, ambas documentadas no código:
- cada tecla troca só o MODELO da região e marca sujo; a repaginação sai
  uma vez, ao fechar. Recompor a cada caractere travaria a digitação num
  DOCX de 140 páginas. O preço: com o modo aberto, as outras páginas ainda
  mostram o cabeçalho antigo;
- suspender a edição do corpo TIRA o `contenteditable`, não só a opacidade.

`OfficeWordController` ganhou `activeView`, e as ações de formatação
passaram a lê-la: com o modo aberto, negrito, undo e a quickbar agem na
REGIÃO. Régua e barra de status continuam descrevendo o corpo, que é o que
elas medem.

**Concluído depois, no mesmo dia:**
- **exportação DOCX das edições** — `_applyEditedRegions` reescreve
  `word/header*.xml`/`footer*.xml` das variantes editadas preservando o
  invólucro `<w:hdr …>` original (regenerar os namespaces faria o Word
  rejeitar o documento inteiro), sem tocar nas partes não editadas e
  ignorando variantes que o pacote não tem — criar parte + relacionamento +
  referência no `sectPr` é criação de estrutura, não edição;
- **botão "Nº de Página"** — `insertPageField` cria a sequência
  begin/instrução/separate/end com o `officeXml` literal do OOXML, então o
  compositor resolve 1, 2, 3 por página e o Word reconhece o campo no
  arquivo. Um "1" digitado diria 1 em todas as páginas; é essa a diferença
  que os testes protegem.

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

### F3 — NodeSelection + imagem — **CONCLUÍDA 2026-08-09** (disposição do texto entregue com o wrap do compositor; ver §2.11)
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

### F6 — Cabeçalho/rodapé editável — **CONCLUÍDA 2026-08-09** (campo PAGE e exportação DOCX pendentes)
- §3.6 completo: duplo clique, tracejado + etiqueta, corpo esmaecido, aba
  contextual, variantes (primeira/par/ímpar), campo PAGE, exportação.
- **Critério:** editar "Folha:" no cabeçalho do ETP, salvar, reabrir no Word
  com a edição em TODAS as páginas; réguas refletem a área do cabeçalho.

### F7 — Layout completo + seções — **PARCIAL 2026-08-09** (réguas, quebras e geometria por seção feitas; colunas dependem de layout multicoluna no compositor, e a exportação de seções intermediárias segue aberta)
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

### F8 — Estilos dinâmicos e gestão — **CONCLUÍDA 2026-08-09** (ver §2.8; cor/itálico/sublinhado do estilo pendentes de `_BlockStyle`)
- `OfficeStyleCatalog` (§3.7); galeria dinâmica com estilos do documento;
  menu de contexto do cartão (Atualizar para Corresponder à Seleção,
  Modificar…, Renomear, Remover da Galeria); diálogo Criar Estilo; exportação
  de styles.xml alterado.
- **Critério:** abrir o ETP → galeria mostra "Nível 01, Nível 1-Se…";
  modificar um estilo muda todos os parágrafos que o usam; DOCX exportado
  reflete no Word.

### F9 — Caixa de texto completa — **PARCIAL 2026-08-09** (edição in-place, exportação, disposição do texto e arrasto feitos; inserir caixa nova segue pendente — ver §2.10 e §2.11)
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

Colunas fechadas — o último bloqueio estrutural saiu. 2417 testes passando, CI verde nos três jobs.

Como ficou
O que define colunas não é a largura das linhas, é o fluxo: a coluna 1 enche até o rodapé e o texto continua no topo da coluna 2, na mesma página. A implementação acabou pequena porque reaproveita a máquina existente — closePage passou a tentar closeColumn antes de emitir a página. O fragmento carrega o columnIndex, não o x já calculado, e os dois renderers resolvem o deslocamento pela mesma geometria que o compositor usou.

Duas coisas que os testes pegaram, e que valem mais que a feature
O flush final parou de emitir página. Assim que closePage passou a avançar de coluna, um documento que termina antes de encher todas as colunas não produzia página nenhuma. Isso obrigou a separar "acabou o espaço" (continua ao lado) de "acabou a página" (quebra manual, quebra de seção, flush final) — uma distinção que num grafo monocoluna simplesmente não existia. Pelo mesmo motivo, w:br type="column" e type="page" deixaram de poder compartilhar um sinal.

Eu ia achatar o w:cols de quem nunca pediu. Minha primeira versão gravava sempre a contagem do editor, e dois testes de preservação de sectPr mostraram o resultado: um documento com w:num="2" importado saía com w:num="1" porque o chamador montou a geometria só para trocar margens. É exatamente a corrupção silenciosa que recusei no B3. A causa era de modelagem — columnCount = 1 não distinguia "uma coluna" de "não declarado". Agora é anulável, e o arquivo só recebe w:cols quando a contagem mudou; w:equalWidth e os w:col do produtor ficam onde estavam.

De brinde, _copySetup descartava a grade de texto do documento: trocar o tamanho do papel mudava a métrica de linha do arquivo inteiro sem ninguém pedir.

Desabilitado, com o motivo
"À Esquerda" e "À Direita" são as colunas de larguras diferentes do Word. A geometria só modela colunas iguais, então habilitá-las produziria duas colunas iguais com o nome errado. Ficam visíveis e desligadas, com isso escrito na descrição.

Ainda em aberto no tema: linha separadora (w:sep) e balanceamento de colunas no fim da seção.

Sobra agora, do que era estrutural, só w:tblStyle (galeria de Design da Tabela) e os campos de cor/itálico/sublinhado em _BlockStyle. O resto da lista é UI sobre motor que já existe.