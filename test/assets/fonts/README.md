# Fontes de teste

`Inter-Regular.ttf` — **Inter**, de Rasmus Andersson, sob
[SIL Open Font License 1.1](https://openfontlicense.org), que permite
redistribuição.

Está aqui, e **não** em `lib/`, por decisão de projeto: a biblioteca nunca
embute arquivos de fonte — expõe as APIs para a aplicação carregar os seus
(ver `doc/PLANO_PORT_CONVERSORES_HTML_PDF.md`, §4).

É a fonte que o PDF assinado do SALI precisa embutir, então o parser e o
subsetting são testados contra o alvo real, não contra um exemplo sintético.
