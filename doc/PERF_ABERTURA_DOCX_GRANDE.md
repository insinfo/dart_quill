# Abrir um DOCX de 140 páginas: onde está o travamento

**Data:** 2026-08-01
**Arquivo de teste:** `PGCTIC1_-_TR_-_...docx` — 465 KB, 140 páginas,
10.968 ops, 22 tabelas, 3.650 células.
**Bancada:** `tool/perf/` (`dart run tool/perf/run_bench.dart`), Chrome via
Puppeteer, mesma máquina e mesmo arquivo em todos os cenários.

## Resumo

O travamento **não** é falta de paralelismo. É um algoritmo **quadrático** na
hidratação de tabelas. Nem Worker nem WebAssembly resolvem o problema, porque
99,9% do tempo está na metade que constrói o DOM — e nem Worker nem WASM têm
DOM.

## O experimento

| Cenário | parse | materialização | total | UI |
|---|---:|---:|---:|---|
| 1. main thread: `parse + setContents` (atual) | 392 ms | **376.252 ms** | 377 s | **congelada** (0 frames) |
| 2. main thread: `parse + Delta→HTML + innerHTML` | ~400 ms | falha aos 108 s | 108 s | congelada |
| 3. worker → Delta, main faz `setContents` | 502 ms (worker) | **631.812 ms** | 632 s | **viva** (maior travada 20 ms) |
| 4. worker → HTML, main faz `innerHTML` | 586 + 240 ms (worker) | falha aos 85 s | 85 s | viva (31 ms) |
| 5. WebAssembly (WasmGC): só o parse | **563 ms** | — | 572 ms | — |

Startup do módulo WASM: 88 ms.

### O que cada linha ensina

1. **O parse é irrelevante.** 392 ms de 377 s — 0,1% do tempo. Otimizar,
   paralelizar ou compilar o parse para WASM mexe em um décimo de por cento.
2. **WebAssembly é mais LENTO que JavaScript aqui** (563 ms contra 392 ms,
   +44%). Não é anomalia: o dart2js é maduro e este código é manipulação de
   strings, mapas e objetos — exatamente onde o WasmGC ainda paga interop e
   conversão de String. WASM ganha em aritmética densa sobre buffers, que não
   é o caso de descompactar ZIP e caminhar XML.
3. **O Worker resolve o CONGELAMENTO, não o tempo.** No cenário 3 a página
   continuou respondendo (34 frames, maior intervalo 20 ms) porque o parse saiu
   da main thread — mas a materialização continuou lá, e o total ficou em 10
   minutos. Trocar "congela 6 minutos" por "responde durante 10 minutos" não é
   uma solução.
4. **O caminho via HTML falha antes de terminar:** `Maximum optimize iterations
   exceeded`. Montar o HTML em Dart puro (inclusive num worker, com
   `package:html`) e deixar o parser nativo do navegador construir o DOM é uma
   ideia boa — o parser nativo é C++ e faz isso em milissegundos —, mas hoje o
   `Scroll.build()` sobre uma árvore com 22 tabelas não converge no limite de
   100 iterações do optimize. É um bug do port, não do conceito.

## A causa real

Medida isolada, hidratando conteúdo sintético (`tool/perf` e o teste de
escala):

| Conteúdo | Custo |
|---|---|
| 4.000 parágrafos simples | 88 ms — **linear** (13→22 µs por parágrafo) |
| 50 células de tabela | 98 ms |
| 100 células | 96 ms |
| 200 células | 297 ms |
| 400 células | 1.115 ms |
| 800 células | 4.472 ms |

O custo **por célula** dobra a cada duplicação do número de células
(964 → 1.490 → 2.790 → 5.591 µs): o total é **O(n²)**. Extrapolando para as
3.650 células do TR: ~90-140 s, que é exatamente o medido.

Texto puro escala perfeitamente. O problema é específico de tabela.

Duas observações que estreitam a busca:

- o número de passadas do `optimize` é **constante** (5) para qualquer tamanho
  de tabela — o quadrático está DENTRO de uma passada, não na convergência;
- `insertContents` já usa `batchStart/batchEnd`, então não é optimize por linha.

O suspeito é a fusão de irmãos por absorção repetida (`checkMerge` + `merge` +
`moveChildren`): cada célula nasce embrulhada na sua própria `TableRow`, e
fundir N linhas uma a uma copia a lista acumulada a cada passo — o padrão
clássico O(n²).

## Primeiro ponto quadrático localizado e corrigido

`_enforceRequiredContainerUnchecked` (`table_better/formats/table.dart`): ao
juntar uma célula à linha anterior, ele reotimizava o **irmão inteiro** —
uma subárvore que cresce a cada célula adicionada. Passou a reotimizar apenas
o blot que acabou de se mover; a fusão que o irmão precisava continua
acontecendo na convergência do optimize do pai, que roda até o estado parar
de mudar.

| Células (tabela sintética) | antes | depois |
|---:|---:|---:|
| 100 | 189 ms | 154 ms |
| 200 | 422 ms | 174 ms |
| 400 | 1.794 ms | **571 ms** |

A curva melhorou 3x, mas **ainda é superlinear** e o TR real continua em
~154 s: há pelo menos mais um ponto quadrático no caminho das tabelas reais
(que têm mescla, cabeçalho e vários blocos por célula, ao contrário da
sintética). A instrumentação usada para achar este está descrita abaixo e é
o caminho para achar o próximo.

### Como a instrumentação achou

Contadores temporários em `insertBefore`, `removeChild`, `checkMerge`,
`moveChildren`, `length()` e `enforceAllowedChildren`, medidos com o número de
células dobrando:

| Operação | 100 células | 200 | 400 | comportamento |
|---|---:|---:|---:|---|
| insertBefore | 1.219 | 2.399 | 4.759 | linear |
| removeChild | 883 | 1.743 | 3.463 | linear |
| moveChildren | 284 | 564 | 1.124 | linear |
| length() | 1.668 | 3.248 | 6.408 | linear |
| **enforceAllowedChildren** | 38.151 | 144.171 | **560.211** | **quadrático** |
| Scroll.optimize (chamadas) | 15 | 15 | 15 | constante |

O `enforce` vinha todo de `ParentBlot.optimize` (24k → 93k → 362k), e o
`Scroll.optimize` sendo constante provou que a explosão estava DENTRO de uma
passada — não na convergência.

## Recomendação

1. **Corrigir o quadrático** na hidratação de tabelas. É a única mudança que
   transforma 10 minutos em segundos. Com custo linear, as 3.650 células do TR
   custariam ~1-2 s e nenhuma das arquiteturas abaixo seria necessária.
2. **Depois disso**, se ainda houver 1-2 s de trabalho, um Worker para o parse
   é barato e mantém a UI responsiva — mas é otimização de acabamento, não
   solução.
3. **WebAssembly não se justifica** para este trabalho: mede-se mais lento que
   o JS compilado, custa 88 ms de startup e um segundo artefato de build.
4. **O caminho `innerHTML` + parser nativo** continua promissor (o navegador
   monta DOM muito mais rápido que qualquer laço nosso) e combina bem com um
   worker que devolve HTML pronto — mas depende de o `Scroll.build()` convergir
   sobre documentos com muitas tabelas.

## Como reproduzir

```bash
dart compile js -O2 -o tool/perf/bench_main.dart.js tool/perf/bench_main.dart
dart compile js -O2 -o tool/perf/worker_parse.js  tool/perf/worker_parse.dart
dart compile wasm -O2 -o tool/perf/bench_parse.wasm tool/perf/bench_parse.dart
dart run tool/perf/run_bench.dart          # SKIP_SLOW=1 pula o cenário de 6 min
```

O `tr.docx` da bancada não é versionado (vem de `resources/`, que está no
`.gitignore`); copie o arquivo para `tool/perf/tr.docx` antes de rodar.
