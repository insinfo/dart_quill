# Roteiro de Tradução – QuillJS (TypeScript) → Dart

## Visão Geral

Portamos o QuillJS para Dart visando paridade funcional com a base TypeScript, preservando compatibilidade web e abrindo espaço para outros adaptadores via camada `Dom*`. O código-fonte de referência encontra-se em `quilljs/src`, enquanto a implementação Dart reside em `lib/src`.

---

## Status Atual

| Área | Situação | Observações |
| --- | --- | --- |
| Plataforma (DOM) | ✅ Completa | Abstração `Dom*` cobre eventos, seleção, DataTransfer e parser; fake DOM atualizado para testes. |
| Blots / Formats | ✅ Completa | Todos os blots e formatos principais portados e integrados com Parchment. |
| Core | ✅ Completa | `logger`, `instances`, `composition`, utilitários e bootstrap integrados em `core/`. |
| Módulos | ⚠️ Parcial | Clipboard, History, Input, Keyboard, NormalizeExternalHTML, Toolbar e Uploader prontos; módulos de tabela, syntax e UI Node ainda faltam. |
| Temas & UI | ⚠️ Parcial | Themes Snow/Bubble e componentes de picker básicos portados; assets e UI de tabela pendentes. |
| Assets (CSS/SVG) | ❌ Pendente | `.styl`, SVGs e templates HTML ainda não migrados nem empacotados para Dart. |
| Testes | ❌ Pendente | Apenas testes de blots em Dart; suíte JS (unit/fuzz/e2e) ainda não portada. |

`dart analyze` está limpo; precisamos ampliar cobertura de testes para garantir regressão mínima.

---

## Análise de Paridade (quilljs/src × lib/src)

### Já Portado
- `core/`: composition, editor, emitter, instances, logger, selection, theme e utilitários.
- `modules/`: clipboard (com normalizeExternalHTML), history, input, keyboard, toolbar, uploader.
- `blots/` e `formats/`: equivalentes às versões TypeScript.
- `themes/`: base, bubble e snow.
- `ui/`: picker, icon picker, tooltip e ícones iniciais.

### Ainda Necessário
- `modules/table.ts`, `tableEmbed.ts`, `uiNode.ts`, `syntax.ts` e helpers vinculados.
- Componentes de UI relacionados a tabela e popovers (ver `quilljs/src/ui` para wrappers adicionais).
- Processamento completo de assets (`src/assets` → CSS/SVG utilizáveis em Dart).
- Ferramentas auxiliares do build (`scripts/`, tarefas webpack/babel) não necessárias em Dart, mas referências podem guiar assets.

---

## Backlog de Implementação

1. **Módulos Restantes**
   - Portar `table`, `tableEmbed` e `uiNode` respeitando integração com `formats/table.dart`.
   - Implementar `syntax` (prover dependência opcional ou stub disciplinado).

2. **Interface & Assets**
   - Converter `.styl` para CSS/SCSS utilizável no build Web.
   - Migrar SVGs do toolbar, ícones e sprites.
   - Revisar `ui/` para cobrir componentes faltantes (menus contextuais, tabelas).

3. **Integração & Refino**
   - Revisar `module initialization` para incluir novos módulos.
   - Garantir compatibilidade com APIs externas (ex: `Quill.import`, `register`).

4. **Testes**
   - Portar unit tests priorizando módulos recém-portados (Clipboard/NormalizeExternalHTML, Input, Keyboard).
   - Recriar helpers (`__helpers__`), fixtures e mocks em `test/support`.
   - Definir abordagem para fuzz e e2e (possível substituição por testes de integração Dart/Web).

---

## Próximos Passos (Imediatos)

1. Portar bateria inicial de testes unitários: iniciar por NormalizeExternalHTML (Google Docs / MS Word) usando `FakeDomDocument.fromHtml`.
2. Estender helpers de teste para cobrir módulos (clipboard, keyboard, history).
3. Mapear estrutura de testes JS (`quilljs/test`) e estabelecer plano incremental de migração.
4. Planejar port do módulo de tabelas após validação dos testes de clipboard.
5. Investigar estratégia de conversão de assets (`styles/*.styl`, `ui/icons`) para pipeline Dart.

---

## Histórico Resumido
- Camada DOM evoluída com suporte a `beforeinput`, DataTransfer e normalização de HTML externo.
- Portados utilitários de core (logger, composition, instances) e integrados ao `Quill` Dart.
- Clipboard agora aplica `normalizeExternalHTML` com normalizadores Google Docs e MS Word.
- Fake DOM aprimorado com `documentElement`, seleção por atributo e parser auxiliar, viabilizando novos testes.

---

## Métricas & Qualidade
- `dart analyze` ✅
- Testes automatizados atuais: somente `test/unit/blots/*`; necessidade de ampliar cobertura para módulos e core.
- Atualizar este roteiro a cada entrega significativa (novo módulo, suíte de testes, assets convertidos).

---

## Pendências Globais
- ☑️ Normalização de HTML externa
- 🔲 Módulo de tabelas (table, tableEmbed, uiNode)
- 🔲 Syntax highlighting opcional
- 🔲 Assets (CSS/SVG) e integração visual
- 🔲 Portabilidade da suíte de testes (unit, fuzz, e2e)
- 🔲 Documentação de API paritária