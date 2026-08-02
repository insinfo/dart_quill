/// Numeração multinível do Word — o rótulo que o documento NÃO carrega.
///
/// Num DOCX, "1.1 Objeto" não tem o "1.1" no texto: o Word o calcula a
/// partir de `numbering.xml` e da posição do parágrafo na sequência. Sem
/// resolver isso, todo documento administrativo importado perde a numeração
/// das seções — e o PDF assinado sai sem ela.
///
/// O que este arquivo faz é rodar o contador: para cada parágrafo numerado,
/// qual é o rótulo naquele ponto do documento. O resultado vira o `marker`
/// do bloco — projeção do layout, nunca texto do documento. Isso importa:
/// se o rótulo virasse texto, editar o parágrafo o corromperia, e salvar
/// gravaria o número literal por cima da numeração automática.
library;

import '../../office/document/docx/model.dart';
import '../../office/document/docx/numbering.dart';

/// Contador de numeração, no estado em que ele está ao percorrer o corpo.
///
/// É stateful de propósito: numeração do Word é sequencial e depende de
/// tudo que veio antes. Um parágrafo isolado não tem rótulo definido.
class OfficeNumberingCounter {
  OfficeNumberingCounter(this.numbering);

  final WpNumbering numbering;

  /// Contadores por (numId, ilvl).
  final Map<int, Map<int, int>> _counters = {};

  /// O rótulo deste parágrafo, ou null quando ele não é numerado.
  ///
  /// Avança o contador — chamar duas vezes para o mesmo parágrafo conta
  /// duas vezes, porque o método É o avanço da sequência.
  String? labelFor(WpParagraph paragraph) {
    final numPr = paragraph.properties?.numPr;
    final numId = numPr?.numId;
    // `numId = 0` é a forma OOXML de REMOVER a numeração herdada do estilo,
    // não de usar a numeração zero.
    if (numId == null || numId == 0) return null;

    final level = _levelOf(numId, numPr!.ilvl);
    if (level == null) return null;

    final counters = _counters.putIfAbsent(numId, () => {});
    counters[numPr.ilvl] = (counters[numPr.ilvl] ?? level.start - 1) + 1;

    // Níveis MAIS PROFUNDOS reiniciam quando um superior avança. É o que
    // faz "1.1, 1.2, 2.1" em vez de "1.1, 1.2, 2.3".
    counters.removeWhere((ilvl, _) => ilvl > numPr.ilvl);

    return _format(numId, numPr.ilvl, level, counters);
  }

  /// O nível efetivo: override do `w:num` ganha do `w:abstractNum`.
  WpNumberingLevel? _levelOf(int numId, int ilvl) {
    final num = numbering.nums[numId];
    if (num == null) return null;
    final override = num.overrides[ilvl];
    if (override != null) return override;
    return numbering.abstractNums[num.abstractNumId]?.levels[ilvl];
  }

  /// Aplica o `lvlText` (`"%1.%2."`), substituindo cada `%n` pelo contador
  /// do nível n-1 no formato daquele nível.
  String _format(
    int numId,
    int ilvl,
    WpNumberingLevel level,
    Map<int, int> counters,
  ) {
    // Bullet não tem contador: o próprio lvlText é o caractere.
    if (level.numFmt == 'bullet') {
      return level.lvlText.isEmpty ? '• ' : '${level.lvlText} ';
    }
    if (level.numFmt == 'none') return '';

    final label = level.lvlText.replaceAllMapped(RegExp(r'%(\d)'), (match) {
      final target = int.parse(match.group(1)!) - 1;
      final value = counters[target] ??
          (_levelOf(numId, target)?.start ?? 1);
      final format = target == ilvl
          ? level.numFmt
          : (_levelOf(numId, target)?.numFmt ?? 'decimal');
      return formatNumber(value, format);
    });
    return label.isEmpty ? '' : '$label ';
  }

  /// Um contador no formato do Word.
  ///
  /// Formatos desconhecidos caem em decimal em vez de sumir: um rótulo
  /// errado é visível e corrigível; um rótulo ausente parece conteúdo que
  /// nunca existiu.
  static String formatNumber(int value, String format) => switch (format) {
        'decimal' => '$value',
        'decimalZero' => value < 10 ? '0$value' : '$value',
        'lowerLetter' => _letters(value).toLowerCase(),
        'upperLetter' => _letters(value),
        'lowerRoman' => _roman(value).toLowerCase(),
        'upperRoman' => _roman(value),
        _ => '$value',
      };

  /// a, b, … z, aa, ab — o esquema do Word repete a letra em vez de usar
  /// base 26 posicional.
  static String _letters(int value) {
    if (value <= 0) return '';
    final index = (value - 1) % 26;
    final repeat = ((value - 1) ~/ 26) + 1;
    return String.fromCharCode(65 + index) * repeat;
  }

  static const _romanValues = [
    (1000, 'M'), (900, 'CM'), (500, 'D'), (400, 'CD'),
    (100, 'C'), (90, 'XC'), (50, 'L'), (40, 'XL'),
    (10, 'X'), (9, 'IX'), (5, 'V'), (4, 'IV'), (1, 'I'),
  ];

  static String _roman(int value) {
    if (value <= 0 || value > 3999) return '$value';
    final buffer = StringBuffer();
    var rest = value;
    for (final (amount, symbol) in _romanValues) {
      while (rest >= amount) {
        buffer.write(symbol);
        rest -= amount;
      }
    }
    return buffer.toString();
  }
}
