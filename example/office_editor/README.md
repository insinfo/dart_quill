# Exemplo — modo avançado (editor paginado)

Demonstra o engine Office do `dart_quill`: árvore tipada, layout paginado
próprio, projeção em `contenteditable` e PDF gerado do MESMO `PageGraph` que
o editor mostra.

```bash
cd example/office_editor
dart pub get
dart run build_runner serve web:8080
```

Abra <http://localhost:8080>.

## O que dá para ver funcionando

| Recurso | Onde aparece |
|---|---|
| Edição sobre layout paginado | digitar, apagar, Enter — o texto reflui e a paginação acompanha |
| Atalhos e histórico | Ctrl+B/I/U, Ctrl+Z, Ctrl+Shift+Z |
| Clipboard preservador | copiar dentro do editor e colar mantém marcas e bordas do recorte |
| IME | composição (acentos, CJK) reconciliada no fim, como UMA edição no histórico |
| Virtualização | gere 200 páginas e observe o número de páginas montadas no DOM |
| Layout incremental | o tempo de recomposição por tecla aparece no rodapé |
| PDF | o botão gera o PDF da MESMA paginação mostrada na tela |
| Import de Delta | cola um `{"ops":[...]}` do Quill e ele abre no modo avançado |

## O que este exemplo NÃO demonstra

Import/export de `.docx` roda igual aqui, mas depende de um arquivo local;
o round-trip preservador é coberto pelos testes sobre o corpus real, em
`test/unit/document_engine/office/docx_codec_test.dart`.

A fidelidade tipográfica é a do shaper latino (etapa 1): ótima para
documento administrativo em português, não equivalente universal ao Word.
