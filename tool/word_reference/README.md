# Harness de referência: o Word como oráculo

Dirige o Microsoft Word por COM para **produzir os documentos de referência**
do editor Office. É ferramenta de desenvolvimento, Windows-only, e **não faz
parte do pacote publicado**.

## Por que ele existe

Nenhuma descrição do comportamento do Word é tão confiável quanto o próprio
Word. Um `w:pgBorders` que eu escrevo à mão é o que eu *acho* que ele grava;
o que interessa é o que ele grava de verdade — os filhos que completa
sozinho, a ordem dos elementos e os padrões que assume. A diferença é testar
contra a especificação × testar contra o produto.

Cada execução produz um par:

- **`.docx`** → fixture de importação (`test/unit/document_engine/office/word_reference_fixtures_test.dart`);
- **`.pdf` exportado pelo Word** → gabarito de paginação para
  `tool/pdf_reference_diff.dart`.

## Por que é um pacote separado

O `dart_quill` limita as dependências de produção a `web` e `html`. Este
harness precisa de `win32` e `ffi`, e um contribuidor que rode
`dart pub get` na raiz não deve baixar FFI de Windows para trabalhar no
editor. Como pacote próprio, as dependências ficam contidas e o analisador da
raiz não as enxerga.

## Uso

```bash
cd tool/word_reference
dart pub get

# todas as fixtures (resources/word_reference/)
dart run bin/generate_fixtures.dart

# só uma
dart run bin/generate_fixtures.dart page_borders

# a captura de tela de um DOCX aberto no Word (doc/referencias-ui/)
dart run bin/capture_screenshot.dart ../../resources/word_reference/page_borders.docx
```

## O que o `com.dart` oferece

| API | Para quê |
|---|---|
| `initializeComApartment`, `createDispatcher` | abrir o Word por `IDispatch` |
| `setProperty`, `invokeMethod`, `getDispatchProperty`… | dirigir o MODELO (documentos, seções, formas) |
| `snapshotProcessIdsByExecutable`, `terminateProcessById` | saber quais `WINWORD.EXE` são NOSSOS |
| `findWindowOfProcess` | achar a janela desta sessão (por processo, não por título) |
| `focusWindow` | foco de verdade, via `AttachThreadInput` |
| `whileFocused` | guarda: só entrega entrada com a janela alvo em primeiro plano |
| `sendKey`, `sendText`, `KeyModifiers` | teclado (`KEYEVENTF_UNICODE`, layout-independente) |
| `moveMouse`, `clickMouse`, `dragMouse`, `scrollMouse` | mouse, com passos intermediários no arrasto |
| `windowBounds`, `captureWindowToBmp`, `captureScreenToBmp` | captura de janela e print screen |

### Sobre a entrada sintética (teclado e mouse)

`SendInput` entrega o evento a **quem tiver o foco no instante da chamada**,
não à janela que o script tinha em mente. Por isso todo lote passa por
`whileFocused`, que confere e aborta em vez de digitar no programa errado.

`bin/ui_probe.dart` responde "este ambiente permite?" antes de alguém
escrever um roteiro de UI: ele clica, digita e **confirma pelo MODELO** (lê
`Content.Text` por COM) que o texto chegou ao documento. Numa sessão em que
outro programa segura o foco — automação, RDP, área de trabalho em uso — o
teclado não chega ao Word e a sonda sai com código 70. É uma limitação do
ambiente, não do harness: rode com a área de trabalho livre.

### Sobre a captura de tela

Ela é **best-effort e exige a área de trabalho livre**. O Windows não deixa
um processo em segundo plano trazer outra janela para a frente, e
`PrintWindow` devolve preto para janelas que a composição nunca desenhou.
Nesse caso o script **falha em voz alta** em vez de gravar alguma coisa: o
"fallback" óbvio — copiar o retângulo da tela nas coordenadas da janela —
grava o que estiver por cima, isto é, a janela de quem está usando a máquina.
A primeira versão fez exatamente isso, e a imagem foi descartada.

O oráculo automatizável é o **PDF** que `generate_fixtures.dart` exporta; a
captura serve só para olhar o chrome do Word (onde ele põe um controle).

Requisitos: Windows com Microsoft Word instalado e registrado em COM
(`HKCR\Word.Application`).

## Segurança de processo

`WordSession.run` fotografa os PIDs de `WINWORD.EXE` **antes** de criar a
instância e só encerra à força o que nasceu depois. Quem roda este harness
quase sempre tem o Word aberto com o próprio documento; um kill cego mataria
essa sessão e o trabalho não salvo junto.

## As fixtures

| Nome | O que isola |
|---|---|
| `page_borders` | `w:pgBorders` real (dupla, 2,25 pt, vermelha) |
| `watermark` | a marca-d'água do Word (WordArt no cabeçalho) |
| `sections_landscape` | duas seções, retrato + paisagem com margens próprias |
| `tab_stops` | paradas esquerda/centro/direita/decimal, com líder |
| `multilevel_numbering` | numeração 1. / 1.1 / 1.1.1 da galeria do Word |
| `header_first_even` | `titlePg` + `evenAndOddHeaders` + as três variantes |
| `columns_two` | `w:cols` com linha separadora |
| `line_numbers` | `w:lnNumType` de 5 em 5 |

As três últimas linhas da tabela do teste cobrem lacunas DECLARADAS
(numeração de linha, marca-d'água importada, rótulo multinível): elas travam
o que o editor **não** faz, para que a perda continue sendo preservação e
nunca vire perda silenciosa.

## O que ele já achou

- **borda `double` saía como linha única no PDF.** O DOM desenhava duas
  (CSS `border-style:double`) e o PDF uma só; a mesma moldura ficava
  diferente nas duas saídas. Corrigido em `pdf_renderer._strokeBorder`.
- **a marca-d'água de um DOCX importado não é desenhada.** A forma sobrevive
  no cabeçalho preservado (o teste prova), mas o editor ainda não a lê.

## Proveniência

`lib/com.dart` veio de `C:/MyDartProjects/access_to_dart`
(`tools/_com_automation.dart`, mesmo mantenedor), com autorização explícita.
