/// Inserir → Símbolo: os caracteres que não estão no teclado.
///
/// A galeria é deliberadamente CURTA. O diálogo "Símbolo" do Word abre a
/// tabela Unicode inteira, e ninguém a percorre: o que se usa de verdade são
/// as duas dezenas de sinais desta lista — moeda, matemática, tipografia e a
/// pontuação que o teclado ABNT/US não tem. Uma tabela completa exigiria
/// escolher fonte, subconjunto e paginação para servir pior ao caso comum.
///
/// A inserção é `insertText`: o símbolo é TEXTO do documento, herda a
/// formatação do ponto onde entra e volta ao DOCX como qualquer outro
/// caractere. Nada aqui cria nó novo — um "espaço não separável" que virasse
/// átomo quebraria busca, contagem de palavras e quebra de linha.
library;

import '../../platform/dom.dart';
import 'controller.dart';

/// Um símbolo da galeria: o caractere e o nome que vai no `title`.
typedef OfficeSymbol = ({String char, String name});

/// Grupo de popup da galeria.
const String officeSymbolGroup = 'insert:symbol';

/// O que a galeria oferece, na ordem em que aparece.
const List<OfficeSymbol> officeSymbols = [
  (char: '€', name: 'Euro'),
  (char: '£', name: 'Libra'),
  (char: '¢', name: 'Centavo'),
  (char: '¥', name: 'Iene'),
  (char: '§', name: 'Parágrafo (seção)'),
  (char: '¶', name: 'Pilcrow'),
  (char: '©', name: 'Copyright'),
  (char: '®', name: 'Marca registrada'),
  (char: '™', name: 'Trademark'),
  (char: '°', name: 'Grau'),
  (char: 'µ', name: 'Micro'),
  (char: 'Ω', name: 'Ômega'),
  (char: 'α', name: 'Alfa'),
  (char: 'β', name: 'Beta'),
  (char: 'π', name: 'Pi'),
  (char: '±', name: 'Mais ou menos'),
  (char: '×', name: 'Multiplicação'),
  (char: '÷', name: 'Divisão'),
  (char: '≤', name: 'Menor ou igual'),
  (char: '≥', name: 'Maior ou igual'),
  (char: '≠', name: 'Diferente'),
  (char: '≈', name: 'Aproximadamente'),
  (char: '∞', name: 'Infinito'),
  (char: '√', name: 'Raiz quadrada'),
  (char: '¼', name: 'Um quarto'),
  (char: '½', name: 'Meio'),
  (char: '¾', name: 'Três quartos'),
  (char: '→', name: 'Seta à direita'),
  (char: '←', name: 'Seta à esquerda'),
  (char: '↑', name: 'Seta acima'),
  (char: '↓', name: 'Seta abaixo'),
  (char: '•', name: 'Marcador'),
  (char: '…', name: 'Reticências'),
  (char: '–', name: 'Traço (en dash)'),
  (char: '—', name: 'Travessão (em dash)'),
  (char: '“', name: 'Aspas duplas à esquerda'),
  (char: '”', name: 'Aspas duplas à direita'),
  (char: '‘', name: 'Aspa simples à esquerda'),
  (char: '’', name: 'Aspa simples à direita'),
  (char: '«', name: 'Aspas angulares à esquerda'),
  (char: '»', name: 'Aspas angulares à direita'),
  (char: '\u00a0', name: 'Espaço não separável'),
];

/// Insere [symbol] no cursor (substituindo a seleção, como qualquer tecla).
void officeInsertSymbol(OfficeWordController c, String symbol) {
  if (symbol.isEmpty) return;
  c.syncSelection();
  c.dispatch(c.activeView.state.tr..insertText(symbol));
}

/// A grade de símbolos, isolada da ribbon para o menu de contexto e os
/// testes a usarem sem montar uma aba.
DomElement buildSymbolGallery(
  OfficeWordController c,
  void Function(String symbol) onPick,
) {
  final kit = OfficeDomKit(c.adapter);
  final gallery = kit.el('div', 'dq-office-symbols');
  final label = kit.el('div', 'dq-office-symbols-label');
  label.appendText('Símbolo');
  gallery.append(label);

  final grid = kit.el('div', 'dq-office-symbols-grid');
  for (final symbol in officeSymbols) {
    final cell = kit.el('button', 'dq-office-symbol');
    cell.setAttribute('type', 'button');
    cell.setAttribute('title', symbol.name);
    cell.setAttribute('aria-label', symbol.name);
    cell.setAttribute('data-symbol', symbol.char);
    // O espaço não separável não se VÊ: a célula mostra o nome curto, senão
    // seria um botão em branco no meio da grade.
    cell.appendText(symbol.char == '\u00a0' ? '␣' : symbol.char);
    cell.addEventListener('mousedown', (event) => event.preventDefault());
    cell.addEventListener('click', (event) {
      event.preventDefault();
      onPick(symbol.char);
    });
    grid.append(cell);
  }
  gallery.append(grid);
  return gallery;
}

/// Abre a galeria ancorada em [anchor] e insere o que for escolhido.
void openSymbolGallery(OfficeWordController c, DomElement anchor) {
  if (c.overlay.closeGroup(officeSymbolGroup)) return;
  c.overlay.open(
    officeSymbolGroup,
    buildSymbolGallery(c, (symbol) {
      c.overlay.closeGroup(officeSymbolGroup);
      officeInsertSymbol(c, symbol);
    }),
    anchor: anchor,
  );
}
