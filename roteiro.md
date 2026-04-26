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
| Módulos | ⚠️ Parcial | Clipboard, History, Input, Keyboard, NormalizeExternalHTML, Toolbar, Uploader, tabelas, `uiNode` e `syntax` (inicial) prontos; refinamentos de `syntax` (UI de seletor, highlight incremental) ainda pendentes. |
| Temas & UI | ⚠️ Parcial | Themes Snow/Bubble e componentes de picker básicos portados; assets e UI de tabela pendentes. |
| Assets (CSS/SVG) | ❌ Pendente | `.styl`, SVGs e templates HTML ainda não migrados nem empacotados para Dart. |
| Testes | ⚠️ Parcial | Cobertura unitária Dart já inclui blots, formatos, core e módulos principais; fuzz/e2e e parte da suíte JS ainda pendentes. |

`dart analyze` está limpo; precisamos ampliar cobertura de testes para garantir regressão mínima.

---

## Análise de Paridade (quilljs/src × lib/src)

### Já Portado
- `core/`: composition, editor, emitter, instances, logger, selection, theme e utilitários.
- `modules/`: clipboard (com normalizeExternalHTML), history, input, keyboard, toolbar, uploader, table, tableEmbed, syntax inicial e **uiNode**.
- `blots/` e `formats/`: equivalentes às versões TypeScript.
- `themes/`: base, bubble e snow.
- `ui/`: picker, icon picker, tooltip e ícones iniciais.

### Ainda Necessário
- Refinamentos finais de `syntax.ts` (UI de seletor de linguagem, integração completa com engine de highlight e atualização incremental de tokens).
- Componentes de UI relacionados a tabela e popovers (ver `quilljs/src/ui` para wrappers adicionais).
- Processamento completo de assets (`src/assets` → CSS/SVG utilizáveis em Dart).
- Ferramentas auxiliares do build (`scripts/`, tarefas webpack/babel) não necessárias em Dart, mas referências podem guiar assets.

---

## Backlog de Implementação

1. **Módulos Restantes**
   - Completar `syntax`: seletor de linguagem, aplicação incremental de tokens no DOM e adaptação de uma biblioteca de highlight opcional.
   - `uiNode` ✅ portado.

2. **Interface & Assets**
   - Converter `.styl` para CSS/SCSS utilizável no build Web.
   - Migrar SVGs do toolbar, ícones e sprites.
   - Revisar `ui/` para cobrir componentes faltantes (menus contextuais, tabelas).

3. **Integração & Refino**
   - Revisar `module initialization` para incluir novos módulos.
   - Garantir compatibilidade com APIs externas (ex: `Quill.import`, `register`).

4. **Testes**
   - Portar unit tests restantes priorizando `syntax`, `uiNode` e lacunas de Clipboard/Keyboard/History.
   - Recriar helpers (`__helpers__`), fixtures e mocks em `test/support`.
   - Definir abordagem para fuzz e e2e (possível substituição por testes de integração Dart/Web).

---

## Próximos Passos (Imediatos)

1. Completar o port de `syntax` aplicando tokens no DOM e cobrindo cenários equivalentes a `quilljs/test/unit/modules/syntax.spec.ts`.
2. Mapear lacunas restantes da suíte JS (`quilljs/test`) e estabelecer plano incremental de fuzz/e2e em Dart/Web.
3. Investigar estratégia de conversão de assets (`styles/*.styl`, `ui/icons`) para pipeline Dart.
4. Revisar APIs públicas (`Quill.import`, `register`, módulos opcionais) contra a superfície QuillJS.

---

## Histórico Resumido
- Camada DOM evoluída com suporte a `beforeinput`, DataTransfer e normalização de HTML externo.
- Portados utilitários de core (logger, composition, instances) e integrados ao `Quill` Dart.
- Clipboard agora aplica `normalizeExternalHTML` com normalizadores Google Docs e MS Word.
- Fake DOM aprimorado com `documentElement`, seleção por atributo e parser auxiliar, viabilizando novos testes.
- Tabelas (`table`, `tableEmbed`), `syntax` e `uiNode` já foram portados com testes Dart focados.

---

## Métricas & Qualidade
- `dart analyze` ✅
- Testes automatizados atuais: 158 passando; blots, formatos, core e módulos principais incluindo `uiNode`; pendem fuzz/e2e e paridade completa de `syntax`.
- Atualizar este roteiro a cada entrega significativa (novo módulo, suíte de testes, assets convertidos).

---

## Pendências Globais
- ☑️ Normalização de HTML externa
- ☑️ Módulo de tabelas (table, tableEmbed)
- ☑️ UI Node (`uiNode`)
- 🔲 Syntax highlighting opcional completo
- 🔲 Assets (CSS/SVG) e integração visual
- 🔲 Portabilidade da suíte de testes (unit, fuzz, e2e)
- 🔲 Documentação de API paritária
