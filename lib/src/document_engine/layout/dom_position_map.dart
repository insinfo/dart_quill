/// Mapeamento posição-do-modelo ↔ posição-no-DOM (Fase 2).
///
/// É o passo 1 da ordem que o plano fixa (§7.9): posição robusta ANTES de
/// seleção, IME e virtualização. Sem isto, cada uma dessas camadas inventa
/// seu próprio jeito de perguntar "onde eu estou" e os bugs viram
/// irreproduzíveis.
///
/// O mapa não guarda estado: ele LÊ as âncoras que o [PageGraphDomRenderer]
/// escreve na projeção (`data-doc-pos`, `data-char-start/end`) e as combina
/// com o texto dos runs. Consequência importante: uma reprojeção não
/// invalida nada — o mapa continua correto porque a verdade está no DOM
/// projetado, e a verdade DO DOCUMENTO continua sendo a árvore.
///
/// Convenção de posição: a mesma do [PageGraph] — `docPos` do fragment é o
/// início do CONTEÚDO do bloco (posição PM), e a posição de um caractere é
/// `docPos + offsetNoBloco`.
library;

import '../../platform/dom.dart';
import 'dom_renderer.dart';

/// Uma posição no DOM projetado: nó de texto e offset dentro dele.
class DomTextPosition {
  const DomTextPosition(this.node, this.offset);

  final DomNode node;
  final int offset;

  @override
  String toString() => 'DomTextPosition($offset in ${node.nodeName})';
}

/// Lê e escreve posições sobre a projeção de um [PageGraph].
class OfficeDomPositionMap {
  const OfficeDomPositionMap();

  static const String _pageClass = '$officeCssPrefix-page';
  static const String _blockClass = '$officeCssPrefix-block';
  static const String _lineClass = '$officeCssPrefix-line';
  static const String _markerClass = '$officeCssPrefix-marker';

  // -- DOM → modelo ---------------------------------------------------------

  /// Posição do modelo para um ponto do DOM, ou null quando o ponto não
  /// pertence à projeção (chrome da página, placeholder, marcador de lista).
  int? modelPositionAt(DomNode node, int offset) {
    final line = _ancestorWithClass(node, _lineClass);
    if (line == null) return null;
    final block = _ancestorWithClass(line, _blockClass);
    if (block == null) return null;
    final docPos = int.tryParse(block.getAttribute('data-doc-pos') ?? '');
    final charStart = int.tryParse(line.getAttribute('data-char-start') ?? '');
    // Cabeçalhos/rodapés repetidos usam docPos negativo porque não pertencem
    // ao espaço de posições do corpo. Nunca transforme essa projeção inerte
    // em seleção/caret editável.
    if (docPos == null || docPos < 0 || charStart == null) return null;

    // Offset dentro da LINHA: soma o comprimento LÓGICO dos runs anteriores.
    // Atoms como imagem/<br>/opaque não têm textContent, mas ocupam uma
    // posição no modelo e declaram isso em data-model-length.
    var withinLine = 0;
    for (final run in line.childNodes) {
      if (run is DomElement && run.classes.contains(_markerClass)) continue;
      if (_contains(run, node)) {
        withinLine += _modelOffsetWithin(run, node, offset);
        return docPos + charStart + withinLine;
      }
      withinLine += _modelLength(run);
    }
    // O ponto é a própria linha (offset entre filhos): conta os N primeiros.
    var index = 0;
    withinLine = 0;
    for (final run in line.childNodes) {
      if (index >= offset) break;
      if (!(run is DomElement && run.classes.contains(_markerClass))) {
        withinLine += _modelLength(run);
      }
      index++;
    }
    return docPos + charStart + withinLine;
  }

  /// Índice da página que contém [node], ou null fora da projeção.
  int? pageIndexOf(DomNode node) {
    final page = _ancestorWithClass(node, _pageClass);
    if (page == null) return null;
    return int.tryParse(page.getAttribute('data-page') ?? '');
  }

  /// Id estável do nó do documento que contém [node] (a chave do cache
  /// tipográfico e da invalidação incremental), ou null.
  String? nodeIdOf(DomNode node) =>
      _ancestorWithClass(node, _blockClass)?.getAttribute('data-node-id');

  // -- modelo → DOM ---------------------------------------------------------

  /// Ponto do DOM para a posição [modelPosition], procurando dentro de
  /// [root] (o host da projeção). Null quando a posição não está numa
  /// página MONTADA — o chamador monta a janela e tenta de novo, que é
  /// exatamente o contrato da virtualização.
  DomTextPosition? domPositionFor(DomElement root, int modelPosition) {
    for (final line in _linesIn(root)) {
      final block = _ancestorWithClass(line, _blockClass);
      if (block == null) continue;
      final docPos = int.tryParse(block.getAttribute('data-doc-pos') ?? '');
      final charStart =
          int.tryParse(line.getAttribute('data-char-start') ?? '');
      final charEnd = int.tryParse(line.getAttribute('data-char-end') ?? '');
      if (docPos == null ||
          docPos < 0 ||
          charStart == null ||
          charEnd == null) {
        continue;
      }

      final start = docPos + charStart;
      final end = docPos + charEnd;
      // Fronteira: a posição do FIM de uma linha e a do INÍCIO da próxima
      // coincidem; a primeira linha que a contém vence (afinidade à
      // esquerda, como o caret do browser).
      if (modelPosition < start || modelPosition > end) continue;

      var remaining = modelPosition - start;
      var childIndex = 0;
      for (final run in line.childNodes) {
        if (run is DomElement && run.classes.contains(_markerClass)) {
          childIndex++;
          continue;
        }
        final modelLength = _modelLength(run);
        if (remaining <= modelLength) {
          final textNode = _firstTextNode(run);
          // A tab has one real text character and keeps the familiar text
          // caret. A zero-text atom needs a boundary in its parent: DOM
          // nodes such as IMG/BR cannot host a Range offset themselves.
          if (textNode != null) {
            final textLength = (textNode.textContent ?? '').length;
            return DomTextPosition(textNode, remaining.clamp(0, textLength));
          }
          return DomTextPosition(
              line, remaining <= 0 ? childIndex : childIndex + 1);
        }
        remaining -= modelLength;
        childIndex++;
      }
      // Linha vazia: o ponto é a própria linha.
      return DomTextPosition(line, 0);
    }
    return null;
  }

  /// Índice da página onde [modelPosition] está projetado, ou null quando
  /// nenhuma página montada a contém.
  int? pageIndexFor(DomElement root, int modelPosition) {
    final position = domPositionFor(root, modelPosition);
    if (position == null) return null;
    return pageIndexOf(position.node);
  }

  // -- travessia ------------------------------------------------------------

  Iterable<DomElement> _linesIn(DomElement root) sync* {
    for (final child in root.childNodes) {
      if (child is! DomElement) continue;
      if (child.classes.contains(_lineClass)) {
        yield child;
      } else {
        yield* _linesIn(child);
      }
    }
  }

  DomElement? _ancestorWithClass(DomNode node, String className) {
    DomNode? current = node;
    while (current != null) {
      if (current is DomElement && current.classes.contains(className)) {
        return current;
      }
      current = current.parentNode;
    }
    return null;
  }

  /// `contains` por igualdade de nó — NUNCA por identidade de wrapper: o
  /// adaptador do browser cunha um wrapper novo a cada acesso, então
  /// `identical` passa no fake DOM e falha em Chrome.
  bool _contains(DomNode ancestor, DomNode node) {
    DomNode? current = node;
    while (current != null) {
      if (current == ancestor) return true;
      current = current.parentNode;
    }
    return false;
  }

  /// Logical length of a projected node. Plain runs use their text; atoms
  /// explicitly override it because an empty IMG/BR/span still has PM size
  /// one (and a floating text box's visible label is not document text).
  int _modelLength(DomNode node) {
    if (node is DomElement) {
      final declared =
          int.tryParse(node.getAttribute('data-model-length') ?? '');
      if (declared != null && declared >= 0) return declared;
    }
    return (node.textContent ?? '').length;
  }

  int _modelOffsetWithin(DomNode container, DomNode target, int offset) {
    if (container == target) {
      final length = _modelLength(container);
      return offset.clamp(0, length);
    }
    final declaredLength = container is DomElement
        ? int.tryParse(container.getAttribute('data-model-length') ?? '')
        : null;
    int withinDeclaredLength(int value) =>
        declaredLength != null && declaredLength >= 0
            ? value.clamp(0, declaredLength)
            : value;
    var total = 0;
    for (final child in container.childNodes) {
      if (child == target) return withinDeclaredLength(total + offset);
      if (_contains(child, target)) {
        return withinDeclaredLength(
            total + _modelOffsetWithin(child, target, offset));
      }
      total += _modelLength(child);
    }
    return withinDeclaredLength(total);
  }

  DomNode? _firstTextNode(DomNode node) {
    if (node is DomText) return node;
    for (final child in node.childNodes) {
      final found = _firstTextNode(child);
      if (found != null) return found;
    }
    return null;
  }
}
