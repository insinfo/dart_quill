/// Localizar e Substituir (Ctrl+F / Ctrl+H): a varredura do documento e o
/// painel que a conduz.
///
/// A parte difícil não é achar a substring — é dizer ONDE ela está. O índice
/// de um caractere dentro do texto NÃO é a posição do modelo: um átomo
/// (imagem, quebra, embed opaco) ocupa uma posição e não contribui com
/// nenhum caractere, e cada bloco custa mais duas posições (abertura e
/// fechamento). Somar comprimentos de string produz um deslocamento que
/// cresce a cada objeto do documento e faz a seleção cair longe da palavra
/// encontrada — sempre num documento real, nunca no de teste.
///
/// A solução aqui é achatar o documento UMA vez guardando, para cada
/// caractere, a posição do modelo que lhe corresponde ([_FlatText]). Todo nó
/// que não é texto entra no achatado como uma CERCA (NUL): ele ocupa o
/// seu lugar na fita, nunca casa com o que o usuário digitou e, de quebra,
/// impede que uma ocorrência atravesse a fronteira de um parágrafo, de uma
/// célula ou de uma imagem — exatamente o que o Word faz (a marca de
/// parágrafo e o objeto inline são `^p` e `^g`, e não caracteres comuns).
///
/// Substituir Tudo é UMA transação. N transações significam N passos de
/// undo para uma ação que o usuário percebeu como uma só, e o histórico
/// vira um inferno de Ctrl+Z. As faixas são aplicadas de trás para frente
/// justamente para que as posições ainda não tocadas continuem válidas.
library;

import '../../platform/dom.dart';
import '../model/index.dart';
import '../state/index.dart';
import 'controller.dart';
import 'overlay.dart';

/// Uma ocorrência: faixa `[from, to)` no espaço de posições do DOCUMENTO.
class OfficeSearchMatch {
  const OfficeSearchMatch(this.from, this.to);

  final int from;
  final int to;

  @override
  String toString() => 'OfficeSearchMatch($from..$to)';
}

/// As duas opções que o painel do Word oferece e que mudam o resultado.
class OfficeSearchOptions {
  const OfficeSearchOptions({this.matchCase = false, this.wholeWord = false});

  /// Falso por padrão, como no Word: quem procura "word" quer achar "Word".
  final bool matchCase;

  /// A ocorrência tem de estar cercada por não-letras dos dois lados.
  final bool wholeWord;
}

/// O caractere que representa, no achatado, tudo que não é texto.
///
/// NUL não sobrevive a nenhum caminho de entrada do editor (nem
/// digitação, nem colagem, nem DOCX), então nunca aparece numa busca legítima
/// — e é por isso que serve de cerca.
const String _fence = '\u0000';

/// Letra, dígito ou sublinhado — a definição de "palavra" para o modo
/// "palavra inteira". A classe Unicode é obrigatória: com `[A-Za-z0-9_]`,
/// "ação" seria três palavras e o modo mentiria em português.
final RegExp _wordChar = RegExp(r'[\p{L}\p{N}_]', unicode: true);

/// Todas as ocorrências de [query] em [doc], em ordem de documento.
List<OfficeSearchMatch> officeFindAll(
  PMNode doc,
  String query, {
  OfficeSearchOptions options = const OfficeSearchOptions(),
}) {
  if (query.isEmpty || query.contains(_fence)) return const [];
  final needle = options.matchCase ? query : _fold(query);
  final flat = _flatten(doc, matchCase: options.matchCase);
  final haystack = flat.chars;
  final matches = <OfficeSearchMatch>[];
  var cursor = haystack.indexOf(needle);
  while (cursor >= 0) {
    final end = cursor + needle.length;
    if (!options.wholeWord || _isWholeWord(haystack, cursor, end)) {
      matches.add(OfficeSearchMatch(
          flat.positions[cursor], flat.positions[end - 1] + 1));
      // Ocorrências não se sobrepõem (o Word também continua DEPOIS da que
      // acabou de achar): "aaa" tem uma ocorrência de "aa", não duas.
      cursor = haystack.indexOf(needle, end);
    } else {
      cursor = haystack.indexOf(needle, cursor + 1);
    }
  }
  return matches;
}

/// Substitui TODAS as ocorrências numa transação só. Devolve quantas foram.
///
/// De trás para frente porque cada substituição desloca o que vem depois
/// dela; as faixas anteriores, que ainda não foram tocadas, continuam com as
/// posições que a varredura mediu.
int officeReplaceAll(
  OfficeWordController c,
  String query,
  String replacement, {
  OfficeSearchOptions options = const OfficeSearchOptions(),
}) {
  final view = c.activeView;
  final state = view.state;
  final matches = officeFindAll(state.doc, query, options: options);
  if (matches.isEmpty) return 0;
  final tr = state.tr;
  // Sem isto, marcas ARMADAS (o negrito ligado antes de digitar) vazariam
  // para cada texto substituído. O que vale é a formatação de onde o texto
  // estava, e é o que `insertText` usa quando não há storedMarks.
  tr.setStoredMarks(null);
  for (final match in matches.reversed) {
    tr.insertText(replacement, match.from, match.to);
  }
  c.dispatch(tr);
  return matches.length;
}

/// Substitui UMA faixa (a ocorrência corrente do painel).
void officeReplaceRange(
  OfficeWordController c,
  OfficeSearchMatch match,
  String replacement,
) {
  final state = c.activeView.state;
  if (match.from < 0 || match.to > state.doc.content.size) return;
  final tr = state.tr;
  tr.setStoredMarks(null);
  tr.insertText(replacement, match.from, match.to);
  c.dispatch(tr);
}

/// Seleciona a ocorrência e leva o usuário até ela.
///
/// A seleção é a navegação: o `dispatch` FIXA a página na janela
/// virtualizada (`editor_view._computeWindow`) e escreve a seleção nativa
/// depois de projetar, então a página é montada mesmo estando a 200 folhas
/// do viewport. Só a rolagem não é consequência automática disso — daí o
/// [OfficeWordController.revealSelection].
void officeSelectMatch(OfficeWordController c, OfficeSearchMatch match) {
  final view = c.activeView;
  final state = view.state;
  final size = state.doc.content.size;
  if (match.from < 0 || match.to > size) return;
  c.dispatch(state.tr
    ..setSelection(TextSelection.create(state.doc, match.from, match.to)));
  c.revealSelection();
}

// -- achatado ----------------------------------------------------------------

class _FlatText {
  const _FlatText(this.chars, this.positions);

  /// Um caractere por posição varrida (texto ou cerca).
  final String chars;

  /// `positions[i]` é a posição de MODELO do caractere `chars[i]`.
  final List<int> positions;
}

_FlatText _flatten(PMNode doc, {required bool matchCase}) {
  final chars = StringBuffer();
  final positions = <int>[];
  doc.nodesBetween(0, doc.content.size, (node, pos, parent, index) {
    if (node.isText) {
      final text = node.text!;
      // Caracteres CONSECUTIVOS de um nó de texto ocupam posições
      // consecutivas — é o que torna `positions[i] = pos + i` exato, e o que
      // permite uma ocorrência atravessar dois runs vizinhos (metade em
      // negrito) sem nenhum cuidado extra.
      for (var i = 0; i < text.length; i++) {
        chars.write(matchCase ? text[i] : _fold(text[i]));
        positions.add(pos + i);
      }
      return false;
    }
    chars.write(_fence);
    positions.add(pos);
    return true;
  });
  return _FlatText(chars.toString(), positions);
}

/// Caixa baixa CARACTERE A CARACTERE, e só quando o resultado continua com um
/// caractere.
///
/// A dobra tem de preservar o comprimento: se um caractere virasse dois, todo
/// o mapa `índice → posição` depois dele sairia do lugar, e a seleção cairia
/// no meio da palavra seguinte.
String _fold(String value) {
  final buffer = StringBuffer();
  for (var i = 0; i < value.length; i++) {
    final char = value[i];
    final lower = char.toLowerCase();
    buffer.write(lower.length == 1 ? lower : char);
  }
  return buffer.toString();
}

bool _isWholeWord(String haystack, int start, int end) {
  if (start > 0 && _wordChar.hasMatch(haystack[start - 1])) return false;
  if (end < haystack.length && _wordChar.hasMatch(haystack[end])) return false;
  return true;
}

// -- painel ------------------------------------------------------------------

/// Grupo de popup do painel: abrir Substituir com Localizar aberto troca o
/// painel em vez de empilhar dois.
const String officeFindGroup = 'find';

final Expando<OfficeFindReplacePanel> _panelOf = Expando('officeFindPanel');

/// O painel DO editor. É um por editor porque o estado da busca (consulta,
/// opções, ocorrência corrente) vive nele: o atalho Ctrl+F e o botão da
/// ribbon têm de encontrar a mesma caixa, com o mesmo texto dentro.
OfficeFindReplacePanel officeFindPanel(OfficeWordController c) =>
    _panelOf[c] ??= OfficeFindReplacePanel(c);

/// O painel Localizar/Substituir do editor.
///
/// Ele é o DONO da ocorrência corrente — não a seleção do documento. A
/// diferença aparece no momento em que o usuário está digitando no campo de
/// busca: o foco está no painel, e reler a seleção nativa devolveria o caret
/// do `<input>`, não a palavra realçada. Guardar o índice também é o que faz
/// "Substituir" agir na ocorrência que o contador anuncia.
class OfficeFindReplacePanel {
  OfficeFindReplacePanel(this.controller)
      : _kit = OfficeDomKit(controller.adapter);

  final OfficeWordController controller;
  final OfficeDomKit _kit;

  OfficePopupHandle? _handle;

  /// O corpo do painel, construído UMA vez e reaproveitado a cada abertura.
  ///
  /// Reusar o mesmo DOM é o que preserva a consulta, o substituto e as duas
  /// opções quando algo fecha o painel por fora (trocar de aba na ribbon
  /// chama `overlay.closeAll`). Reconstruir apagaria o que o usuário digitou.
  DomElement? _content;
  DomElement? _query;
  DomElement? _replacement;
  DomElement? _counter;
  DomElement? _matchCase;
  DomElement? _wholeWord;
  DomElement? _replaceRow;

  List<OfficeSearchMatch> _matches = const [];
  int _current = -1;
  bool _withReplace = false;

  bool get isOpen => _handle?.isOpen ?? false;

  /// Ocorrências da busca corrente (os testes conferem posições por aqui).
  List<OfficeSearchMatch> get matches => List.unmodifiable(_matches);

  /// Índice da ocorrência realçada, ou −1.
  int get currentIndex => _current;

  /// Abre (ou revela) o painel. [withReplace] mostra a linha de substituição
  /// — é a única diferença entre Ctrl+F e Ctrl+H no Word.
  void open({bool withReplace = false}) {
    // O texto selecionado alimenta a busca, como no Word: quem selecionou a
    // palavra e apertou Ctrl+F já disse o que procura. Uma seleção de VÁRIAS
    // linhas não é consulta de busca — nesse caso o campo fica como estava.
    controller.syncSelection();
    final selection = controller.activeView.state.selection;
    final selected = selection.empty
        ? ''
        : controller.activeView.state.doc
            .textBetween(selection.from, selection.to);
    final seed = selected.contains('\n') ? '' : selected;

    final content = _content ??= _build();
    if (seed.isNotEmpty) _query?.value = seed;
    if (!isOpen) {
      _handle = controller.overlay.open(
        officeFindGroup,
        content,
        // O painel NÃO é ancorado num controle: ele é uma faixa fixa no alto
        // do editor, como o painel de navegação do Word, e o CSS a posiciona.
        placement: OfficePopupPlacement.atPoint,
        x: 0,
        y: 0,
        // O host inteiro conta como âncora: clicar no documento para
        // reposicionar o caret NÃO pode fechar o painel — é justamente o gesto
        // de quem vai substituir a ocorrência seguinte à mão.
        anchor: controller.hostElement,
        extraClass: 'dq-office-find-popup',
        // Navegar entre ocorrências ROLA o documento; sem isto o painel
        // fecharia no efeito do próprio comando.
        persistent: true,
      );
    }
    _setReplaceVisible(withReplace);
    _refresh(select: seed.isNotEmpty);
    _focusQuery();
  }

  void close() {
    controller.overlay.closeGroup(officeFindGroup);
    _handle = null;
    _matches = const [];
    _current = -1;
  }

  /// Vai para a ocorrência seguinte (ou anterior), circulando — o Word volta
  /// ao começo em vez de parar no fim do documento.
  void step({required bool forward}) {
    _recompute();
    if (_matches.isEmpty) {
      _updateCounter();
      return;
    }
    _current = _current < 0
        ? (forward ? 0 : _matches.length - 1)
        : (_current + (forward ? 1 : -1)) % _matches.length;
    if (_current < 0) _current += _matches.length;
    _updateCounter();
    officeSelectMatch(controller, _matches[_current]);
  }

  /// Substitui a ocorrência corrente e segue para a próxima.
  void replaceCurrent() {
    _recompute();
    if (_matches.isEmpty) return;
    if (_current < 0) {
      step(forward: true);
      return;
    }
    final target = _matches[_current];
    final replacement = _replacement?.value ?? '';
    officeReplaceRange(controller, target, replacement);
    // O documento mudou: a lista inteira precisa ser refeita, e a ocorrência
    // corrente passa a ser a que ocupa o mesmo índice (a próxima do texto).
    _recompute();
    if (_matches.isEmpty) {
      _current = -1;
      _updateCounter();
      return;
    }
    if (_current >= _matches.length) _current = 0;
    _updateCounter();
    officeSelectMatch(controller, _matches[_current]);
  }

  /// Substitui tudo. UMA transação: um Ctrl+Z devolve o documento inteiro.
  int replaceAll() {
    final query = _query?.value ?? '';
    final count = officeReplaceAll(
      controller,
      query,
      _replacement?.value ?? '',
      options: _options,
    );
    _current = -1;
    _recompute();
    _updateCounter(replaced: count);
    return count;
  }

  OfficeSearchOptions get _options => OfficeSearchOptions(
        matchCase: _matchCase?.value == 'true',
        wholeWord: _wholeWord?.value == 'true',
      );

  // -- montagem -------------------------------------------------------------

  DomElement _build() {
    final panel = _kit.el('div', 'dq-office-find');

    final findRow = _kit.el('div', 'dq-office-find-row');
    final query = _textField('find', 'Localizar', '');
    _query = query;
    query.addEventListener('input', (_) => _refresh(select: true));
    query.addEventListener('keydown', (event) {
      if (event is! DomKeyboardEvent) return;
      if (event.key == 'Enter') {
        event.preventDefault();
        step(forward: !event.shiftKey);
      } else if (event.key == 'Escape') {
        event.preventDefault();
        close();
      }
    });
    findRow.append(query);

    final counter = _kit.el('span', 'dq-office-find-count');
    _counter = counter;
    findRow.append(counter);
    findRow.append(_kit.button(
        '‹', 'Anterior (Shift+Enter)', () => step(forward: false),
        extraClass: 'dq-office-find-step'));
    findRow.append(_kit.button(
        '›', 'Próximo (Enter)', () => step(forward: true),
        extraClass: 'dq-office-find-step'));
    findRow.append(
        _kit.button('✕', 'Fechar', close, extraClass: 'dq-office-find-close'));
    panel.append(findRow);

    final replaceRow = _kit.el('div', 'dq-office-find-row');
    _replaceRow = replaceRow;
    final replacement = _textField('replace', 'Substituir por', '');
    _replacement = replacement;
    replacement.addEventListener('keydown', (event) {
      if (event is! DomKeyboardEvent) return;
      if (event.key == 'Enter') {
        event.preventDefault();
        replaceCurrent();
      } else if (event.key == 'Escape') {
        event.preventDefault();
        close();
      }
    });
    replaceRow.append(replacement);
    replaceRow.append(_kit.button(
        'Substituir', 'Substituir a ocorrência atual', replaceCurrent,
        extraClass: 'dq-office-find-action'));
    replaceRow.append(_kit.button('Substituir Tudo',
        'Substituir todas as ocorrências (um só desfazer)', replaceAll,
        extraClass: 'dq-office-find-action'));
    panel.append(replaceRow);

    final optionsRow = _kit.el('div', 'dq-office-find-row');
    _matchCase = _checkField('matchCase', 'Diferenciar maiúsculas', optionsRow);
    _wholeWord = _checkField('wholeWord', 'Palavra inteira', optionsRow);
    panel.append(optionsRow);
    return panel;
  }

  DomElement _textField(String key, String placeholder, String value) {
    final input = _kit.el('input', 'dq-office-find-input');
    input.setAttribute('type', 'text');
    input.setAttribute('placeholder', placeholder);
    input.setAttribute('aria-label', placeholder);
    input.setAttribute('data-field', key);
    input.value = value;
    _keepFocusable(input);
    return input;
  }

  DomElement _checkField(String key, String label, DomElement row) {
    final wrap = _kit.el('label', 'dq-office-find-check');
    final input = _kit.el('input', 'dq-office-find-checkbox');
    input.setAttribute('type', 'checkbox');
    input.setAttribute('data-field', key);
    // O estado mora no `value` (como nos diálogos): um caminho só de leitura
    // para todos os campos, sem um ramo por tipo de controle.
    input.value = 'false';
    input.addEventListener('change', (_) {
      input.value = input.value == 'true' ? 'false' : 'true';
      _refresh(select: true);
    });
    _keepFocusable(input);
    wrap.append(input);
    final caption = _kit.el('span', 'dq-office-find-check-label');
    caption.appendText(label);
    wrap.append(caption);
    row.append(wrap);
    return input;
  }

  /// O overlay cancela o `mousedown` do popup inteiro para nenhum controle
  /// roubar o caret do documento. Num CAMPO isso é o contrário do que se
  /// quer: sem foco não há digitação. Parar a propagação no próprio campo
  /// deixa o `preventDefault` do popup fora do caminho sem afrouxar a regra
  /// para os botões, que continuam preservando a seleção.
  void _keepFocusable(DomElement input) {
    for (final type in const ['pointerdown', 'mousedown']) {
      input.addEventListener(type, (event) => event.stopPropagation());
    }
  }

  void _setReplaceVisible(bool visible) {
    _withReplace = visible;
    final row = _replaceRow;
    if (row == null) return;
    if (visible) {
      row.classes.remove('dq-office-find-row-hidden');
    } else {
      row.classes.add('dq-office-find-row-hidden');
    }
  }

  bool get isReplaceVisible => _withReplace;

  void _focusQuery() {
    final query = _query;
    if (query == null) return;
    controller.adapter.focus(query);
    query.select();
  }

  void _recompute() {
    _matches = officeFindAll(
      controller.activeView.state.doc,
      _query?.value ?? '',
      options: _options,
    );
  }

  /// Recalcula e, com [select], já realça a PRIMEIRA ocorrência a partir do
  /// caret — digitar na caixa de busca navega, como no Word.
  void _refresh({bool select = false}) {
    _recompute();
    if (_matches.isEmpty) {
      _current = -1;
      _updateCounter();
      return;
    }
    if (!select) {
      _updateCounter();
      return;
    }
    final from = controller.activeView.state.selection.from;
    var index = _matches.indexWhere((match) => match.from >= from);
    if (index < 0) index = 0;
    _current = index;
    _updateCounter();
    officeSelectMatch(controller, _matches[index]);
  }

  void _updateCounter({int? replaced}) {
    final counter = _counter;
    if (counter == null) return;
    if (replaced != null) {
      _kit.setText(counter,
          replaced == 0 ? 'Nenhuma substituição' : '$replaced substituídas');
      return;
    }
    if ((_query?.value ?? '').isEmpty) {
      _kit.setText(counter, '');
      return;
    }
    if (_matches.isEmpty) {
      _kit.setText(counter, 'Nenhum resultado');
      return;
    }
    final position = _current < 0 ? 1 : _current + 1;
    _kit.setText(counter, '$position de ${_matches.length}');
  }
}
