# Inventário de terceiros (`THIRD_PARTY`)

Inventário de proveniência exigido pelo plano
([doc/PLANO_EDITOR_DOCX_PAGINADO_AVANCADO.md](doc/PLANO_EDITOR_DOCX_PAGINADO_AVANCADO.md),
§16). Cada componente portado está ligado ao upstream, à licença e ao lugar
onde vive neste repositório. O texto integral das licenças BSD-3-Clause e
MIT aplicáveis está em [LICENSE](LICENSE); o texto MIT do ProseMirror está
reproduzido ao fim deste arquivo.

## Ports incorporados (código de produção)

| Componente | Upstream | Versão de referência | Licença | Onde neste repositório |
|---|---|---|---|---|
| Quill | <https://github.com/slab/quill> | 2.0.3 | BSD-3-Clause | `lib/src/core/`, `lib/src/blots/`, `lib/src/formats/`, `lib/src/modules/`, `lib/src/delta/`, `lib/src/ui/`, temas e assets CSS derivados |
| quill-table-better | <https://github.com/attoae/quill-table-better> | 1.2.3 | MIT | `lib/src/table_better/`, `assets/quill-table-better.css` |
| ProseMirror (model) | <https://github.com/ProseMirror/prosemirror-model> | linha 1.x | MIT | `lib/src/document_engine/model/` |
| ProseMirror (transform) | <https://github.com/ProseMirror/prosemirror-transform> | linha 1.x | MIT | `lib/src/document_engine/transform/` |
| ProseMirror (state) | <https://github.com/ProseMirror/prosemirror-state> | linha 1.x | MIT | `lib/src/document_engine/state/` |
| ProseMirror (history) | <https://github.com/ProseMirror/prosemirror-history> | linha 1.x | MIT | `lib/src/document_engine/history/` |
| ProseMirror (commands) | <https://github.com/ProseMirror/prosemirror-commands> | linha 1.x | MIT | `lib/src/document_engine/commands/` |
| ProseMirror (test-builder / schema-list) | <https://github.com/ProseMirror/prosemirror-test-builder> | linha 1.x | MIT | `lib/src/document_engine/test_builder/`, `lib/src/document_engine/schema_list/` |

O port ProseMirror chegou a este repositório pela vendorização do port Dart
do projeto `docx_rendering` (mesmo autor), em 2026-08-02.

## Testes derivados de upstream

| Origem | Licença | Onde |
|---|---|---|
| Suítes do ProseMirror (model/transform/state/history/commands) | MIT | `test/unit/document_engine/` (casos portados junto com os módulos) |
| Goldens do Quill 2.0.3 e do quill-table-better 1.2.3 | BSD-3-Clause / MIT | `test/goldens/` |

## Implementação própria (sem upstream)

ZIP/deflate, XML, OPC, DOCX reader/writer, fontes TrueType (parser, subset,
GPOS), PDF writer, layout/paginação (`lib/src/document_engine/layout/`),
codecs Office (`lib/src/document_engine/office/`), a view/entrada
(`lib/src/document_engine/view/`) e o componente de UI
(`lib/src/document_engine/ui/`) foram escritos neste repositório. A camada
de extensões é INSPIRADA no conceito do Tiptap (MIT), sem código portado.

## Ativos gráficos incorporados

| Componente | Upstream | Licença | Onde neste repositório |
|---|---|---|---|
| Ícones de GUI do ONLYOFFICE (SVGs da ribbon) | <https://github.com/ONLYOFFICE/web-apps> (commit `1c8ca9987876bada73c0bde21367da09c0e1ed83`) | CC BY-SA 4.0 | fonte de ícones `lib/assets/fonts/dq-office-icons.*` e `lib/assets/office_word_icons.css`, gerados por `tool/build_icon_font.dart` |

Os **ícones** de interface do ONLYOFFICE são licenciados pela upstream sob
Creative Commons Attribution-ShareAlike 4.0 International (CC BY-SA 4.0) —
licença distinta da do código (AGPL-3.0), que segue NÃO incorporado (ver
abaixo). A fonte `dq-office-icons` é obra derivada desses SVGs e permanece
sob CC BY-SA 4.0, com atribuição no cabeçalho do CSS. O asset é opcional e
substituível: o componente só referencia classes `dq-icon-*`, e quem
preferir outra iconografia troca o stylesheet sem tocar no código.

## Fontes examinadas apenas em auditoria — nenhum CÓDIGO incorporado

Conforme o §16 do plano: ONLYOFFICE/EuroOffice DocumentServer (AGPL-3.0 —
código; apenas os ícones CC BY-SA 4.0 acima foram incorporados), iText
(AGPL-3.0/comercial), LibreOffice (licença mista), capturas do Word Online
(proprietário). Dessas fontes não há código, tradução de código ou bundle
neste repositório. PDFBox/FontBox, pdf.js e Apache POI (Apache-2.0) foram
autorizados como referência com atribuição, mas até esta data nenhum código
deles foi incorporado; se vier a ser, este inventário e o NOTICE devem ser
atualizados ANTES do merge.

## Dependências de runtime (pub.dev)

| Package | Licença | Papel |
|---|---|---|
| `web` | BSD-3-Clause | bindings tipados do browser (allowlist §11.5) |
| `html` | MIT-like (dart-lang) | parsing HTML5 (allowlist §11.5) |

---

## Texto da licença MIT — ProseMirror

Copyright (C) 2015-2017 by Marijn Haverbeke <marijnh@gmail.com> and others

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
