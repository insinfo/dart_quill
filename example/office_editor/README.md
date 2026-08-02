# Exemplo — editor Word (`OfficeWordEditor`)

A aplicação faz **uma chamada** e recebe a experiência completa — ribbon,
régua, páginas com cabeçalho/rodapé, barra de status e zoom. Todo o chrome
vem da biblioteca, escopado em `dq-office-*`; nada aqui toca o Quill
simples, e os dois podem coexistir na mesma página.

O visual são **assets do pacote** — dois `<link>` no `index.html`, ambos
substituíveis por tema/iconografia próprios (as classes `dq-icon-*` são o
contrato; a fonte de ícones deriva dos SVGs do ONLYOFFICE, CC BY-SA 4.0):

```html
<link rel="stylesheet"
      href="packages/dart_quill/assets/office_word_editor.css">
<link rel="stylesheet"
      href="packages/dart_quill/assets/office_word_icons.css">
```

```dart
OfficeWordEditor.mount(
  host: adapter.document.querySelector('#editor')!,
  adapter: adapter,
  document: doc,
  options: OfficeWordEditorOptions(
    mode: OfficeWordMode.word,
    headerText: 'PREFEITURA MUNICIPAL',
    footerText: 'Página {PAGE} de {NUMPAGES}',
  ),
);
```

## Rodar

```bash
cd example/office_editor
dart pub get
dart run build_runner serve web:8080
```

| URL | Modo |
|---|---|
| `http://localhost:8080` | Word completo: ribbon, régua, páginas, status, zoom |
| `http://localhost:8080?mode=flow` | edição contínua sem paginação visível |
| `http://localhost:8080?mode=view` | somente leitura |

## API

- `editor.exportPdf()` — o PDF da MESMA paginação da tela (o serviço também
  roda no backend, sem browser);
- `editor.setZoom(1.5)` — muda só a escala twips→px da projeção; grafo,
  posições e histórico de undo não mudam;
- `editor.view` — o laço de edição por baixo do chrome, para integrações.

O fluxo é coberto por testes em Chrome
(`test/browser/office_word_editor_test.dart`) e em VM
(`test/unit/document_engine/ui/word_editor_test.dart`).
