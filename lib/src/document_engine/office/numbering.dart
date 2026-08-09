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

  /// Contadores por grupo de sequência → (ilvl → valor corrente).
  ///
  /// Em geral cada `numId` é uma lista independente. O Word, porém, cria
  /// uma nova instância com `startOverride` para reiniciar um nível dentro
  /// da sequência anterior do mesmo `abstractNum`. Nessa situação as duas
  /// instâncias precisam compartilhar o estado dos níveis superiores.
  final Map<int, Map<int, int>> _counters = {};

  /// Grupo canônico usado por cada `numId`.
  final Map<int, int> _counterGroupByNumId = {};

  /// Último grupo observado para cada definição abstrata.
  final Map<int, int> _lastGroupByAbstractNumId = {};

  /// Um `startOverride` força o valor na primeira ocorrência daquele nível.
  final Set<(int, int)> _activatedOverrideLevels = {};

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

    final num = numbering.nums[numId];
    if (num == null) return null;

    final ilvl = numPr!.ilvl;
    final level = numbering.levelOf(numId, ilvl);
    if (level == null) return null;

    var counterGroup = _counterGroupByNumId.putIfAbsent(numId, () => numId);
    final explicitStart = num.startOverrides[ilvl];
    final firstUseOfOverride =
        explicitStart != null && _activatedOverrideLevels.add((numId, ilvl));

    // Word represents an in-sequence restart as a fresh w:num carrying a
    // startOverride. Reuse the preceding sequence of the same abstractNum so
    // `%1` keeps (for example) 8 while `%2` restarts at 1. Ordinary w:num
    // instances without an explicit restart remain independent.
    if (firstUseOfOverride) {
      final previousGroup = _lastGroupByAbstractNumId[num.abstractNumId];
      if (previousGroup != null) {
        counterGroup = previousGroup;
        _counterGroupByNumId[numId] = previousGroup;
      }
    }

    final counters = _counters.putIfAbsent(counterGroup, () => {});
    if (firstUseOfOverride) {
      counters[ilvl] = explicitStart;
    } else {
      counters[ilvl] = (counters[ilvl] ?? level.start - 1) + 1;
    }

    // Níveis mais profundos obedecem w:lvlRestart. Ausente significa o
    // comportamento padrão do Word (nível imediatamente anterior ou algum
    // nível ainda mais alto); zero significa nunca reiniciar.
    counters.removeWhere(
      (deeperIlvl, _) =>
          deeperIlvl > ilvl && _restartsAfter(numId, deeperIlvl, ilvl),
    );

    _lastGroupByAbstractNumId[num.abstractNumId] = counterGroup;

    return _format(numId, ilvl, level, counters);
  }

  bool _restartsAfter(int numId, int deeperIlvl, int advancedIlvl) {
    final restart = numbering.levelOf(numId, deeperIlvl)?.restart;
    if (restart == 0) return false;
    final triggerIlvl = restart == null ? deeperIlvl - 1 : restart - 1;
    return advancedIlvl <= triggerIlvl;
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
      return '${_unicodeBullet(level.lvlText)} ';
    }
    if (level.numFmt == 'none') return '';

    final label = level.lvlText.replaceAllMapped(RegExp(r'%(\d)'), (match) {
      final target = int.parse(match.group(1)!) - 1;
      final value =
          counters[target] ?? (numbering.levelOf(numId, target)?.start ?? 1);
      final format = target == ilvl
          ? level.numFmt
          : (numbering.levelOf(numId, target)?.numFmt ?? 'decimal');
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

  /// Word stores many list bullets in the Symbol/Wingdings private-use
  /// range. Rendering those code points with the paragraph font produces a
  /// tofu square in browsers, so project their semantic Unicode equivalent.
  static String _unicodeBullet(String value) {
    if (value.isEmpty) return '•';
    return switch (value.codeUnitAt(0)) {
      0xF0B7 || 0x00B7 => '•',
      0xF0A7 || 0x00A7 => '■',
      0xF06F || 0x006F => '○',
      0xF0FC => '✓',
      0xF0D8 => '➢',
      _ => value,
    };
  }

  /// a, b, … z, aa, ab — o esquema do Word repete a letra em vez de usar
  /// base 26 posicional.
  static String _letters(int value) {
    if (value <= 0) return '';
    final index = (value - 1) % 26;
    final repeat = ((value - 1) ~/ 26) + 1;
    return String.fromCharCode(65 + index) * repeat;
  }

  static const _romanValues = [
    (1000, 'M'),
    (900, 'CM'),
    (500, 'D'),
    (400, 'CD'),
    (100, 'C'),
    (90, 'XC'),
    (50, 'L'),
    (40, 'XL'),
    (10, 'X'),
    (9, 'IX'),
    (5, 'V'),
    (4, 'IV'),
    (1, 'I'),
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
