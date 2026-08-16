# Fontes do exemplo (opcional)

O editor funciona **sem nenhum arquivo aqui**: quando não encontra a face, ele
mede pela métrica compatível mais próxima e o PDF sai com as fontes-padrão do
formato (Helvetica/Times/Courier). É o comportamento histórico, e continua
correto.

Colocar fontes aqui muda uma coisa importante: **as três pontas passam a usar
a mesma face**. O compositor mede pela `hmtx` real, a projeção desenha com a
mesma fonte (registrada no browser por `@font-face`) e o PDF a embute como
CID/Identity-H com subset. A linha quebra no mesmo lugar na tela, no PDF e no
que o Word mostraria.

## Como nomear

O loader do exemplo (`_fetchFont` em `../main.dart`) procura, nesta ordem:

```
fonts/<Família>-Regular.ttf      fonts/<Família>-Bold.ttf
fonts/<Família>-Italic.ttf       fonts/<Família>-BoldItalic.ttf
fonts/<Família>.ttf              (só a regular, sem sufixo)
```

Ele tenta primeiro a família que o documento pede e depois os **aliases
metricamente compatíveis** que o editor conhece. Na prática: um `Carlito` aqui
atende um documento que pede `Ecofont_Spranq_eco_Sans` ou `Calibri` — que é
exatamente a substituição que o Word faz.

## Fontes livres que valem a pena

| Arquivo | Substitui | Licença |
|---|---|---|
| `Carlito-Regular.ttf`, `-Bold`, `-Italic`, `-BoldItalic` | Calibri (métricas idênticas) | SIL OFL 1.1 |
| `LiberationSans-*.ttf` | Arial / Helvetica | SIL OFL 1.1 |
| `LiberationSerif-*.ttf` | Times New Roman | SIL OFL 1.1 |
| `Inter-Regular.ttf` | uso geral | SIL OFL 1.1 |

Os binários **não são distribuídos pelo pacote** (é a mesma política do
`THIRD_PARTY.md`): baixe do projeto de origem e copie para cá.

## Na sua aplicação

Nada obriga a usar `fetch` nem esta convenção de nomes. `fontLoader` recebe a
face pedida e devolve bytes — de um asset bundle, de IndexedDB, de um CDN, de
um pacote Dart de fontes. Devolver `null` significa "não tenho".
