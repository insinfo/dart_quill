 # Roteiro de Tradução: QuillJS (TypeScript) → Dart

## 📋 Objetivo do Projeto

# Roteiro de Tradução: QuillJS (TypeScript) → Dart

## Objetivo

Portar o editor QuillJS de TypeScript para Dart com uma camada de abstração de plataforma. O código deve rodar em projetos Dart web/AngularDart e manter compatibilidade futura com outras plataformas por meio de adaptadores.

- Fonte original: `quilljs/src`
- Implementação Dart: `lib/src`
- Dependências Delta: `lib/src/dependencies`

---

## Estado Atual

| Área | Status | Observações |
|------|--------|-------------|
| **Plataforma (DOM)** | ✅ Concluído | Abstrações `Dom*` implementadas e utilizadas pelo restante do código. |
| **Blots (Parchment)** | ✅ Concluído | Árvores de documento e registry funcionam. |
| **Formats** | ✅ Concluído | Formatos básicos e embeds convertidos. |
| **Core** | ✅ Concluído (parcial) | Editor, Quill, Emitter, Selection portados; faltam utilitários (`core.ts`, `composition.ts`, `instances.ts`, `logger.ts`). |
| **Modules** | ⚠️ Parcial | Clipboard, History, Keyboard, Toolbar, Uploader presentes. Ainda faltam Input, Syntax, Table, TableEmbed, UiNode e NormalizeExternalHTML. |
| **Themes & UI** | ⚠️ Parcial | Temas Snow/Bubble e componentes base portados, mas sem assets (CSS/SVG) completos e sem suporte de tabela. |
| **Assets** | ❌ Pendente | Arquivos `.styl` e ícones SVG ainda não convertidos para uso no build Dart. |
| **Tests** | ❌ Pendente | Apenas dois testes Dart (`block` e `block_embed`). Toda a suíte JS (unit, fuzz, e2e) falta ser portada. |

`dart analyze` e `webdev build` passam com o conjunto atual, mas o editor não possui paridade de recursos com QuillJS.

---

## Lacunas Identificadas

### Núcleo (core)
- `core.ts`, `quill.ts` (entry points de registro e bootstrap).
- `core/composition.ts` (suporte a IME/composição de texto).
- `core/instances.ts` (rastreamento de múltiplos editores).
- `core/logger.ts` (sistema de logging configurável).
- `core/utils/createRegistryWithFormats.ts`.
- `core/utils/scrollRectIntoView.ts`.
- `types.d.ts` (contratos de tipos expostos).

### Módulos
- `modules/input.ts` (eventos de entrada/focus/blurring).
- `modules/syntax.ts` (realce opcional, dependência do toolbar).
- `modules/table.ts`, `modules/tableEmbed.ts`, `modules/uiNode.ts` (infra de tabelas e UI de contexto).
- `modules/normalizeExternalHTML` (pipeline de limpeza para clipboard, incluindo `googleDocs.ts` e `msWord.ts`).

### UI e Assets
- Estilos `.styl` das themes (`core`, `snow`, `bubble`, toolbars).
- Conjunto completo de ícones SVG utilizados pelo toolbar.
- Arquivos auxiliares das themes (tooltips, toolbar templates).

### Testes
- Suíte unitária (blots, core, formats, modules, UI).
- Suíte fuzz (`test/fuzz`).
- Suíte e2e (Playwright).
- Helpers e fixtures de teste (`__helpers__`, `fixtures`, `pageobjects`).

---

## Plano de Portabilidade

1. **Fundação de Core Utilitários**
   - Portar `core/logger.ts` → novo `lib/src/core/logger.dart`.
   - Portar `core/instances.ts` → gerenciamento estático em Dart.
   - Implementar `core/composition.ts` (eventos de composição IME).
   - Converter `core/utils/createRegistryWithFormats.ts` e `scrollRectIntoView.ts`.
   - Adaptar `lib/dart_quill.dart` para expor API semelhante a `quilljs/src/quill.ts`.

2. **Módulos Faltantes**
   - `modules/input.dart`: gerenciamento de eventos DOM e sincronização de seleção.
   - `modules/normalize_external_html/`: normalizadores específicos (Google Docs, MS Word).
   - `modules/table.dart`, `modules/table_embed.dart`, `modules/ui_node.dart`.
   - `modules/syntax.dart`: manter opcional, mas fornecer stub funcional.

3. **Suporte a Tabelas e UI Avançada**
   - Integrar módulo de tabela com formatos já existentes (`formats/table.dart`).
   - Implementar componentes UI complementares (menus contextuais, pickers de tabela).

4. **Assets**
   - Converter `.styl` para `.css` ou `.scss` utilizáveis em AngularDart/Web.
   - Copiar SVGs para diretório web e expor via `ui/icons.dart`.

5. **Testes**
   - Reproduzir helpers de teste (`__helpers__`, fixtures) em `test/support`.
   - Portar specs unitárias gradualmente, começando por core/blots/formats.
   - Planejar estratégia para fuzz/e2e (traduzir ou substituir por cobertura semelhante).

6. **Documentação e Exemplos**
   - Atualizar README com status.
   - Criar exemplos AngularDart exibindo features portadas.

---

## Próximos Passos Imediatos

1. Criar utilitários de core ausentes (`logger`, `instances`).
2. Registrar novos utilitários em `lib/dart_quill.dart` e ajustar bootstrap do editor.
3. Implementar `modules/input.dart` para capturar eventos de teclado/mouse/focus.
4. Trazer pipeline `normalizeExternalHTML` para garantir paridade do Clipboard.
5. Preparar estrutura de testes unitários (helpers + primeira bateria de specs portadas).

Cada entrega deve incluir atualização deste roteiro e execução de `dart analyze`, `dart test` (quando aplicável) e `webdev build` para garantir integridade contínua.

---

## Histórico Resumido

- Portadas as camadas principais: plataforma, blots, formats, core básico, módulos essenciais, temas base.
- Corrigido `Clipboard` para usar abstrações e `Delta` corretamente (build atual passa).
- AngularDart host funcional (`web/` + `lib/src/app`).
- Identificadas lacunas de paridade com QuillJS; próximas etapas priorizam utilidades de core e módulos restantes.