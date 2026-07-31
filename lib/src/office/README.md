# `lib/src/office` — a máquina de documentos

Camada de **formatos de documento** do `dart_quill`, em Dart puro, sem
dependência externa. Não é o editor: é o que está por baixo dos conversores.

| Diretório | O que é |
|---|---|
| `document/docx/` | leitura e escrita de WordprocessingML (`.docx`): reader, writer, styles, numbering, units, validator |
| `document/opc/` | Open Packaging Conventions — o container que embala um `.docx` (content types, relationships) |
| `document/xml/` | parser/serializador XML usado pelos dois acima |
| `document/zip/` | ZIP + codecs Deflate/Inflate próprios (é o que comprime o `.docx` e os streams `/FlateDecode` do PDF) |
| `document/pdf/` | escritor de PDF: objetos indiretos, xref, content streams, imagens JPEG/PNG com SMask |
| `document/fonts/` | métricas das 14 fontes padrão do PDF, para medir texto e quebrar linha |
| `editor/` | o modelo de elementos (`IElement` e enums) que serve de meio-termo entre Delta e os formatos |
| `word/` | as pontes `Delta ⇄ IElement ⇄ docx` |

## Quem usa

- `lib/src/converters/docx/docx_codec.dart` → `docxToDelta` / `deltaToDocx`
  (export público em `package:dart_quill/dart_quill_docx.dart`)
- `lib/src/converters/pdf/pdf_exporter.dart` → `deltaToPdf`
  (export público em `package:dart_quill/dart_quill_pdf.dart`)

## Procedência

O modelo de elementos (`editor/`) e a base do stack OOXML vieram de um port do
projeto **canvas-editor**, adaptados aqui: os tipos foram ajustados ao Delta
deste pacote, o escritor de PDF e as métricas de fonte foram acrescentados, e o
código morto que veio junto foi removido.

Ficava em `lib/src/dependencies/canvas_editor/` — um nome que dizia "código de
fora, não mexa". Não é mais verdade: é parte do produto, é onde o suporte a
DOCX e PDF de fato mora, e é aqui que o trabalho de fontes embutidas (P1 do
`doc/PLANO_PORT_CONVERSORES_HTML_PDF.md`) vai acontecer.
