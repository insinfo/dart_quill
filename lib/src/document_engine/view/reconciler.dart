/// Reconciliação DOM→modelo — a rede de segurança que a composição IME
/// transforma em caminho principal.
///
/// Em todo o resto do editor o DOM é projeção e nada é lido de volta dele.
/// A composição é a exceção INEVITÁVEL: `beforeinput` durante composição não
/// é cancelável de forma confiável, e o browser precisa da sua própria
/// sequência de nós para desenhar o texto provisório (o sublinhado do
/// candidato, a janela do IME). Cancelar ali quebraria CJK, acentos mortos e
/// a autocorreção do mobile.
///
/// Então a política é: durante a composição o browser escreve na projeção e
/// nós NÃO reprojetamos (reprojetar destrói o estado do IME no meio da
/// palavra); quando a composição termina, lemos o bloco afetado e
/// reconstruímos a diferença como uma transação normal. O modelo volta a
/// ser a fonte de verdade, e o histórico vê UMA edição, não uma por tecla.
///
/// O diff é por bloco e por prefixo/sufixo comum: barato, e o resultado é a
/// menor faixa que realmente mudou. Ele respeita pares substitutos (emoji
/// não é cortado ao meio) — a armadilha que já mordeu o diff do Quill.
library;

import '../../platform/dom.dart';
import '../model/index.dart';
import '../state/index.dart';
import '../layout/dom_renderer.dart';

/// A diferença encontrada num bloco, em posições do MODELO.
class OfficeTextDiff {
  const OfficeTextDiff({
    required this.from,
    required this.to,
    required this.text,
  });

  /// Início da faixa substituída (posição do modelo).
  final int from;

  /// Fim da faixa substituída.
  final int to;

  /// O que passa a ocupar a faixa.
  final String text;

  bool get isEmpty => from == to && text.isEmpty;
}

class OfficeDomReconciler {
  const OfficeDomReconciler();

  /// Lê o bloco que contém [node] e devolve a transação que põe o modelo de
  /// acordo com o que o browser escreveu.
  ///
  /// [host] delimita a projeção DESTE editor. A checagem não é zelo: a
  /// seleção nativa é global e pode estar obsoleta ou pertencer a outro
  /// editor da mesma página — sem ela, uma composição num editor
  /// reescreveria o documento do outro, porque `data-doc-pos` faz sentido
  /// em qualquer projeção.
  ///
  /// Devolve null quando não há nada a fazer — nó fora do host, nenhum
  /// bloco identificável, ou o texto já bate. Não gerar transação é
  /// importante: uma transação vazia sujaria o histórico e forçaria uma
  /// recomposição inútil.
  Transaction? reconcile({
    required DomElement host,
    required DomNode node,
    required EditorState state,
  }) {
    if (!_contains(host, node)) return null;
    final block = _blockOf(node);
    if (block == null || !_contains(host, block)) return null;
    final docPos = int.tryParse(block.getAttribute('data-doc-pos') ?? '');
    if (docPos == null || docPos < 1) return null;

    // Um mesmo parágrafo pode ter vários fragmentos DOM, inclusive em
    // páginas diferentes. O IME escreve dentro de UMA linha projetada; usar
    // textContent do bloco e compará-lo com o parágrafo PM inteiro apagaria
    // tudo que ficou nas páginas anteriores/seguintes.
    final line = _lineOf(node, block);
    if (line == null) return null;
    final charStart = int.tryParse(line.getAttribute('data-char-start') ?? '');
    final charEnd = int.tryParse(line.getAttribute('data-char-end') ?? '');
    if (charStart == null ||
        charEnd == null ||
        charStart < 0 ||
        charEnd < charStart) {
      return null;
    }

    final domText = textOfProjectedLine(line);
    final modelText = _modelTextAt(
      state.doc,
      docPos,
      charStart: charStart,
      charEnd: charEnd,
    );
    if (modelText == null || domText == modelText) return null;

    final rangeStart = docPos + charStart;
    final diff = diffText(modelText, domText, rangeStart);
    if (diff.isEmpty) return null;
    final localFrom = diff.from - rangeStart;
    final localTo = diff.to - rangeStart;
    if (localFrom < 0 || localTo < localFrom || localTo > modelText.length) {
      return null;
    }
    // Atoms inline não editáveis são sentinelas de alinhamento, não texto
    // que o IME possa materializar ou apagar. Se o diff os tocar, a opção
    // segura é reprojetar o modelo canônico.
    if (diff.text.contains(_modelAtom) ||
        modelText.substring(localFrom, localTo).contains(_modelAtom)) {
      return null;
    }
    return state.tr..insertText(diff.text, diff.from, diff.to);
  }

  /// O texto do bloco COMO O DOCUMENTO o vê.
  ///
  /// Marcadores de lista ficam de fora: são projeção do layout, e incluí-los
  /// faria o diff "descobrir" um texto que o documento nunca teve.
  String textOfBlock(DomElement block) {
    final buffer = StringBuffer();
    for (final line in _linesIn(block)) {
      _collectModelText(line, buffer);
    }
    return buffer.toString();
  }

  /// Texto lógico de uma linha: somente caracteres que têm posição no PM.
  /// Hífens discricionários e caixas flutuantes são projeções visuais;
  /// atoms reais usam uma sentinela de um code unit para preservar offsets.
  String textOfProjectedLine(DomElement line) {
    final buffer = StringBuffer();
    _collectModelText(line, buffer);
    return buffer.toString();
  }

  static const String _modelAtom = '\u{fffc}';

  void _collectModelText(DomNode node, StringBuffer buffer) {
    if (node is DomText) {
      buffer.write(node.data);
      return;
    }
    if (node is DomElement) {
      final declaredLength =
          int.tryParse(node.getAttribute('data-model-length') ?? '');
      if (declaredLength == 0 ||
          node.classes.contains('$officeCssPrefix-marker') ||
          node.classes.contains('$officeCssPrefix-discretionary-hyphen') ||
          node.classes.contains('$officeCssPrefix-text-box')) {
        return;
      }
      if (node.getAttribute('contenteditable') == 'false') {
        if (declaredLength != null && declaredLength > 0) {
          for (var i = 0; i < declaredLength; i++) {
            buffer.write(_modelAtom);
          }
        }
        return;
      }
      if (declaredLength != null &&
          declaredLength > 0 &&
          node.firstChild == null) {
        for (var i = 0; i < declaredLength; i++) {
          buffer.write(_modelAtom);
        }
        return;
      }
    }
    var child = node.firstChild;
    while (child != null) {
      _collectModelText(child, buffer);
      child = child.nextSibling;
    }
  }

  /// [ancestor] contém [node]? Compara por IGUALDADE de nó, nunca por
  /// identidade: o adaptador web cunha um wrapper novo a cada acesso, então
  /// `identical` passa no fake DOM e falha em Chrome.
  static bool _contains(DomNode ancestor, DomNode node) {
    DomNode? current = node;
    while (current != null) {
      if (current == ancestor) return true;
      current = current.parentNode;
    }
    return false;
  }

  /// Sobe até o elemento de bloco da projeção.
  DomElement? _blockOf(DomNode node) {
    DomNode? current = node;
    while (current != null) {
      if (current is DomElement &&
          current.classes.contains('$officeCssPrefix-block')) {
        return current;
      }
      current = current.parentNode;
    }
    return null;
  }

  DomElement? _lineOf(DomNode node, DomElement block) {
    DomNode? current = node;
    while (current != null) {
      if (current is DomElement &&
          current.classes.contains('$officeCssPrefix-line')) {
        return current;
      }
      if (current == block) return null;
      current = current.parentNode;
    }
    return null;
  }

  Iterable<DomElement> _linesIn(DomNode root) sync* {
    for (final child in root.childNodes) {
      if (child is! DomElement) continue;
      if (child.classes.contains('$officeCssPrefix-line')) {
        yield child;
      } else {
        yield* _linesIn(child);
      }
    }
  }

  /// O texto lógico da faixa projetada do textblock que começa em [docPos].
  String? _modelTextAt(
    PMNode doc,
    int docPos, {
    required int charStart,
    required int charEnd,
  }) {
    if (docPos < 1 || docPos > doc.content.size) return null;
    final resolved = doc.resolve(docPos);
    final block = resolved.parent;
    if (!block.isTextblock) return null;
    if (charEnd > block.content.size) return null;
    return block.textBetween(
      charStart,
      charEnd,
      leafText: (_) => _modelAtom,
    );
  }

  /// Prefixo/sufixo comum, em posições do modelo.
  ///
  /// Trabalha em unidades de código UTF-16 (é o que o DOM e o modelo usam),
  /// mas nunca corta um par substituto: um emoji editado ao lado viraria
  /// meio caractere inválido, e o bug só aparece no conteúdo do usuário.
  OfficeTextDiff diffText(String before, String after, int docPos) {
    var start = 0;
    final maxStart =
        before.length < after.length ? before.length : after.length;
    while (start < maxStart &&
        before.codeUnitAt(start) == after.codeUnitAt(start)) {
      start++;
    }
    if (_splitsSurrogate(before, start) || _splitsSurrogate(after, start)) {
      start--;
    }

    var endBefore = before.length;
    var endAfter = after.length;
    while (endBefore > start &&
        endAfter > start &&
        before.codeUnitAt(endBefore - 1) == after.codeUnitAt(endAfter - 1)) {
      endBefore--;
      endAfter--;
    }
    if (_splitsSurrogate(before, endBefore) ||
        _splitsSurrogate(after, endAfter)) {
      endBefore++;
      endAfter++;
    }

    return OfficeTextDiff(
      from: docPos + start,
      to: docPos + endBefore,
      text: after.substring(start, endAfter),
    );
  }

  /// True se [index] cai NO MEIO de um par substituto.
  static bool _splitsSurrogate(String text, int index) {
    if (index <= 0 || index >= text.length) return false;
    final previous = text.codeUnitAt(index - 1);
    final current = text.codeUnitAt(index);
    return previous >= 0xD800 &&
        previous <= 0xDBFF &&
        current >= 0xDC00 &&
        current <= 0xDFFF;
  }
}
