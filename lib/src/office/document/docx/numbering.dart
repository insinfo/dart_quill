import '../../ce_xml.dart';

import 'model.dart';

/// Um nível (`<w:lvl>`) de numeração.
class WpNumberingLevel {
  final int ilvl;
  final int start;
  final String numFmt; // decimal | lowerLetter | lowerRoman | bullet | ...
  final String lvlText; // ex.: "%1.%2." ou "" (bullet char)
  final String? lvlJc;
  final WpIndent? indent;
  final WpRunProperties? runProperties;

  /// Reinicia quando um nível superior incrementa (default OOXML: sim).
  final int? restart;

  const WpNumberingLevel({
    required this.ilvl,
    this.start = 1,
    this.numFmt = 'decimal',
    this.lvlText = '',
    this.lvlJc,
    this.indent,
    this.runProperties,
    this.restart,
  });

  static WpNumberingLevel fromXml(XmlElement el) {
    return WpNumberingLevel(
      ilvl: int.tryParse(el.getAttribute('w:ilvl') ?? '') ?? 0,
      start:
          int.tryParse(el.firstChild('w:start')?.getAttribute('w:val') ?? '') ??
              1,
      numFmt: el.firstChild('w:numFmt')?.getAttribute('w:val') ?? 'decimal',
      lvlText: el.firstChild('w:lvlText')?.getAttribute('w:val') ?? '',
      lvlJc: el.firstChild('w:lvlJc')?.getAttribute('w:val'),
      indent: WpIndent.fromXml(el.firstChild('w:pPr')?.firstChild('w:ind')),
      runProperties: WpRunProperties.fromXml(el.firstChild('w:rPr')),
      restart: int.tryParse(
          el.firstChild('w:lvlRestart')?.getAttribute('w:val') ?? ''),
    );
  }
}

class WpAbstractNum {
  final int id;
  final String? multiLevelType;
  final Map<int, WpNumberingLevel> levels;

  const WpAbstractNum(
      {required this.id, this.multiLevelType, required this.levels});
}

class WpNum {
  final int numId;
  final int abstractNumId;
  final Map<int, WpNumberingLevel> overrides;

  const WpNum(
      {required this.numId,
      required this.abstractNumId,
      this.overrides = const {}});
}

/// Catálogo de numeração (`numbering.xml`): abstractNum + num
/// (roteiro_editor_profissional, D2/F2.1).
class WpNumbering {
  final Map<int, WpAbstractNum> abstractNums;
  final Map<int, WpNum> nums;

  WpNumbering({Map<int, WpAbstractNum>? abstractNums, Map<int, WpNum>? nums})
      : abstractNums = abstractNums ?? {},
        nums = nums ?? {};

  static WpNumbering parse(String xml) {
    final root = XmlDocument.parse(xml).rootElement;
    final abstractNums = <int, WpAbstractNum>{};
    for (final el in root.childrenNamed('w:abstractNum')) {
      final id = int.tryParse(el.getAttribute('w:abstractNumId') ?? '');
      if (id == null) continue;
      final levels = <int, WpNumberingLevel>{};
      for (final lvlEl in el.childrenNamed('w:lvl')) {
        final level = WpNumberingLevel.fromXml(lvlEl);
        levels[level.ilvl] = level;
      }
      abstractNums[id] = WpAbstractNum(
        id: id,
        multiLevelType:
            el.firstChild('w:multiLevelType')?.getAttribute('w:val'),
        levels: levels,
      );
    }

    final nums = <int, WpNum>{};
    for (final el in root.childrenNamed('w:num')) {
      final numId = int.tryParse(el.getAttribute('w:numId') ?? '');
      final abstractNumId = int.tryParse(
          el.firstChild('w:abstractNumId')?.getAttribute('w:val') ?? '');
      if (numId == null || abstractNumId == null) continue;
      final overrides = <int, WpNumberingLevel>{};
      for (final overrideEl in el.childrenNamed('w:lvlOverride')) {
        final lvlEl = overrideEl.firstChild('w:lvl');
        if (lvlEl != null) {
          final level = WpNumberingLevel.fromXml(lvlEl);
          overrides[level.ilvl] = level;
        }
      }
      nums[numId] = WpNum(
          numId: numId, abstractNumId: abstractNumId, overrides: overrides);
    }

    return WpNumbering(abstractNums: abstractNums, nums: nums);
  }

  /// Resolve o nível efetivo de (numId, ilvl), aplicando overrides do num.
  WpNumberingLevel? levelOf(int numId, int ilvl) {
    final num = nums[numId];
    if (num == null) return null;
    final override = num.overrides[ilvl];
    if (override != null) return override;
    return abstractNums[num.abstractNumId]?.levels[ilvl];
  }
}

/// Formata um valor de contador segundo o `numFmt` OOXML.
String formatNumber(int value, String numFmt) {
  switch (numFmt) {
    case 'decimal':
      return '$value';
    case 'decimalZero':
      return value < 10 ? '0$value' : '$value';
    case 'lowerLetter':
      return _letter(value).toLowerCase();
    case 'upperLetter':
      return _letter(value).toUpperCase();
    case 'lowerRoman':
      return _roman(value).toLowerCase();
    case 'upperRoman':
      return _roman(value);
    case 'bullet':
      return '';
    case 'none':
      return '';
    default:
      return '$value';
  }
}

String _letter(int value) {
  // 1→A, 26→Z, 27→AA...
  var v = value;
  final buffer = StringBuffer();
  while (v > 0) {
    v--;
    buffer.write(String.fromCharCode(0x41 + (v % 26)));
    v ~/= 26;
  }
  return buffer.toString().split('').reversed.join();
}

String _roman(int value) {
  const pairs = [
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
  var v = value;
  final buffer = StringBuffer();
  for (final (n, s) in pairs) {
    while (v >= n) {
      buffer.write(s);
      v -= n;
    }
  }
  return buffer.toString();
}

/// Contadores de numeração multinível: gera o texto do marcador
/// (`lvlText` `%1.%2.` etc.) parágrafo a parágrafo, na ordem do documento.
class NumberingCounters {
  final WpNumbering numbering;

  /// contadores por numId → (ilvl → valor corrente).
  final Map<int, Map<int, int>> _counters = {};

  NumberingCounters(this.numbering);

  /// Avança o contador de (numId, ilvl) e retorna o marcador formatado
  /// (ex.: "3.2.1.") ou `null` se o num não existe.
  String? next(int numId, int ilvl) {
    final level = numbering.levelOf(numId, ilvl);
    if (level == null) return null;

    final counters = _counters.putIfAbsent(numId, () => {});
    counters[ilvl] = (counters[ilvl] ?? _startOf(numId, ilvl) - 1) + 1;
    // Reinicia níveis mais profundos.
    counters.removeWhere((lvl, _) => lvl > ilvl);

    if (level.numFmt == 'bullet') {
      return _bulletChar(level.lvlText);
    }

    var text = level.lvlText;
    for (var i = 1; i <= 9; i++) {
      if (!text.contains('%$i')) continue;
      final lvlIndex = i - 1;
      final value = counters[lvlIndex] ?? _startOf(numId, lvlIndex);
      counters[lvlIndex] = value;
      final fmt = numbering.levelOf(numId, lvlIndex)?.numFmt ?? 'decimal';
      text = text.replaceAll('%$i', formatNumber(value, fmt));
    }
    return text;
  }

  int _startOf(int numId, int ilvl) =>
      numbering.levelOf(numId, ilvl)?.start ?? 1;

  /// Bullets de Symbol/Wingdings → fallback Unicode (roteiro F4.2).
  static String _bulletChar(String lvlText) {
    if (lvlText.isEmpty) return '•';
    final code = lvlText.codeUnitAt(0);
    return switch (code) {
      0xF0B7 || 0xB7 => '•', // Symbol bullet
      0xF0A7 || 0xA7 => '■', // Wingdings square
      0xF06F || 0x6F => '○', // Courier o
      0xF0FC => '✓',
      0xF0D8 => '➢',
      _ => lvlText,
    };
  }
}
