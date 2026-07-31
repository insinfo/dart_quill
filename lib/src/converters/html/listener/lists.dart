// --- lists.dart ---
import '../block_listener.dart';
import '../lexer.dart';
import '../line.dart';
import '../models/pick.dart';

/// Converte elementos de lista (ul/ol) em bloco.
class Lists extends BlockListener {
  static const String ATTRIBUTE_LIST = 'list';
  static const String LIST_TYPE_BULLET = 'bullet';
  static const String LIST_TYPE_ORDERED = 'ordered';
  static const String LIST_TYPE_CHECKED = 'checked';
  static const String LIST_TYPE_UNCHECKED = 'unchecked';

  /// Classe aplicada em <ul> para checklists.
  String checkListClass = 'list-unstyled';

  @override
  void process(Line line) {
    final listType = line.getAttribute(ATTRIBUTE_LIST);
    if (listType != null) {
      pick(line, {'type': listType});
      line.setDone();
    }
  }

  @override
  void render(DeltaToHtmlConverter lexer) {
    bool isOpen = false;
    String? listTag;

    for (final pick in picks) {
      final first = getFirstLine(pick);
      bool isLast = false;

      // (1) Re-inicializa por pick
      bool isEmpty = first.isEmpty(); // (2) usa conteúdo, não atributo

      // Concatena o conteúdo do grupo (first .. pick.line)
      final buffer = StringBuffer();
      if (!isEmpty) {
        Line? current = first;
        while (current != null) {
          buffer.write(current.getInput());
          current.setDone();
          if (current.index == pick.line.index) break;
          current = current.next();
        }
      }

      // Verifica se há quebra entre este item e o próximo item de lista
      bool hasNextInside = false;
      pick.line.whileNext((Line line) {
        if (line.getAttribute(ATTRIBUTE_LIST) != null) {
          return false; // para quando achar o próximo item da lista
        }
        if (line.hasEndNewline() ||
            line.hasNewline() ||
            (line.isJsonInsert() && !line.isInline())) {
          hasNextInside = true;
        }
        return true;
      });

      if (hasNextInside) {
        isLast = true;
      }

      final output = StringBuffer();

      // Troca de tipo de lista (fecha a anterior)
      final thisTag = _getListAttribute(pick);
      if (isOpen && listTag != null && listTag != thisTag) {
        output.write('</$listTag>\n');
        isOpen = false;
      }

      final pickType = _getPickType(pick);
      final isCheck =
          [LIST_TYPE_CHECKED, LIST_TYPE_UNCHECKED].contains(pickType);

      // Abre a lista se ainda não estiver aberta
      if (!isOpen) {
        output.write('<$thisTag');
        if (isCheck) {
          output.write(' class="$checkListClass"');
        }
        output.write('>\n');
        isOpen = true;
      }

      // Indentação do próximo item
      int nextIndent = 0;
      pick.line.whileNext((Line line) {
        final indent = line.getAttribute('indent', 0);
        if (line.getAttribute(ATTRIBUTE_LIST) != null) {
          nextIndent = indent;
          return false;
        }
        return true;
      });

      final currentIndent = pick.line.getAttribute('indent', 0);

      if (isEmpty) {
        output.write('<li></li>');
      } else {
        output.write('<li>');

        if (isCheck) {
          output.write('<input type="checkbox" disabled');
          if (pickType == LIST_TYPE_CHECKED) {
            output.write(' checked');
          }
          output.write('><label>${buffer.toString()}</label>');
        } else {
          output.write(buffer.toString());
        }

        if (nextIndent > currentIndent) {
          // abre lista aninhada
          output.write('<$thisTag>\n');
        } else if (nextIndent < currentIndent) {
          // fecha níveis (igual ao PHP)
          output.write('</li></$thisTag></li>\n');
          final closeGap = currentIndent - nextIndent;
          if (closeGap > 1) {
            output.write('</$thisTag></li>\n');
          }
        } else {
          output.write('</li>\n');
        }
      }

      // Fecha a lista se for o último deste grupo/tipo
      if (isLast || pick.isLast) {
        output.write('</$thisTag>\n');
        isOpen = false;
      }

      listTag = thisTag;
      pick.line.output = output.toString();
      pick.line.setDone();
    }
  }

  /// Retorna a tag de lista para o tipo.
  String _getListAttribute(Pick pick) {
    final type = _getPickType(pick);
    if (type == LIST_TYPE_ORDERED) return 'ol';
    if ([LIST_TYPE_BULLET, LIST_TYPE_CHECKED, LIST_TYPE_UNCHECKED]
        .contains(type)) {
      return 'ul';
    }
    throw Exception(
      'The provided list type "$type" is not a known list type (ordered or bullet).',
    );
  }

  /// Obtém o tipo de lista a partir das opções do pick.
  String _getPickType(Pick pick) {
    final optionValueType = pick.optionValue('type');
    return (optionValueType is Map)
        ? optionValueType['type']
        : optionValueType.toString();
  }
}
