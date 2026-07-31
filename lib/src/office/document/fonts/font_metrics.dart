import 'dart:typed_data';

/// Métricas de uma fonte TrueType/OpenType suficientes para o LAYOUT
/// determinístico do editor (D4/F4.10): largura de avanço por codepoint e
/// métricas verticais de linha. NÃO carrega contornos de glifo (o canvas
/// continua rasterizando com a fonte do browser); só substitui `measureText`
/// e a altura de linha para que o layout seja idêntico ao Word e independente
/// das fontes que o navegador tenha instaladas.
class FontMetrics {
  FontMetrics({
    required this.unitsPerEm,
    required this.ascent,
    required this.descent,
    required this.lineGap,
    required this.advanceWidths,
    required this.defaultAdvance,
  });

  /// Grade de coordenadas da fonte (tipicamente 2048 em TTF, 1000 em CFF).
  final int unitsPerEm;

  /// Ascendente/descendente/entrelinha em unidades da fonte. `ascent` e
  /// `lineGap` positivos; `descent` armazenado como magnitude positiva.
  final int ascent;
  final int descent;
  final int lineGap;

  /// codepoint → largura de avanço (unidades da fonte).
  final Map<int, int> advanceWidths;

  /// Avanço para codepoints ausentes (largura do glifo .notdef / espaço).
  final int defaultAdvance;

  /// Largura de [text] em px na altura [sizePx] (soma dos avanços × escala).
  double measureWidth(String text, double sizePx) {
    final double scale = sizePx / unitsPerEm;
    int units = 0;
    for (final int cp in text.runes) {
      units += advanceWidths[cp] ?? defaultAdvance;
    }
    return units * scale;
  }

  /// Altura da linha "single" (ascent+descent+lineGap) em múltiplo de em.
  double get singleLineEm => (ascent + descent + lineGap) / unitsPerEm;

  double ascentPx(double sizePx) => ascent * sizePx / unitsPerEm;
  double descentPx(double sizePx) => descent * sizePx / unitsPerEm;
  double lineGapPx(double sizePx) => lineGap * sizePx / unitsPerEm;

  /// Constrói métricas a partir de dados já extraídos (usado pelo arquivo
  /// gerado com as fontes embarcadas). [packedAdvances] é uma lista plana
  /// `[cp0, w0, cp1, w1, ...]` para um literal Dart compacto.
  factory FontMetrics.fromPacked({
    required int unitsPerEm,
    required int ascent,
    required int descent,
    required int lineGap,
    required int defaultAdvance,
    required List<int> packedAdvances,
  }) {
    final Map<int, int> widths = <int, int>{};
    for (int i = 0; i + 1 < packedAdvances.length; i += 2) {
      widths[packedAdvances[i]] = packedAdvances[i + 1];
    }
    return FontMetrics(
      unitsPerEm: unitsPerEm,
      ascent: ascent,
      descent: descent,
      lineGap: lineGap,
      advanceWidths: widths,
      defaultAdvance: defaultAdvance,
    );
  }
}

/// Erro de parsing de fonte (arquivo truncado, tabela ausente, formato de
/// cmap não suportado).
class FontParseException implements Exception {
  FontParseException(this.message);
  final String message;
  @override
  String toString() => 'FontParseException: $message';
}

/// Extrai [FontMetrics] de um TTF/OTF/TTC em memória. Suporta apenas o que o
/// layout precisa: `head`, `hhea`, `hmtx`, `maxp`, `cmap` (formato 4, Unicode
/// BMP) e, quando presente, `OS/2`. Em coleções (`ttcf`) usa a primeira fonte.
///
/// [codepointRange] limita os codepoints extraídos para o mapa de avanços
/// (padrão: Latin básico + suplementar + extensões A/B, cobrindo pt-BR).
/// [extraCodepoints] adiciona símbolos/pontuação fora desse intervalo.
FontMetrics parseTtfMetrics(
  Uint8List bytes, {
  int codepointMin = 0x20,
  int codepointMax = 0x24F,
  Iterable<int> extraCodepoints = const <int>[],
}) {
  final _Reader r = _Reader(bytes);
  int sfntOffset = 0;
  final int magic = r.u32(0);
  if (magic == 0x74746366) {
    // 'ttcf' — coleção; primeira fonte em offsetTable[0] (após 12 bytes).
    sfntOffset = r.u32(12);
  }

  final int numTables = r.u16(sfntOffset + 4);
  final Map<String, int> tableOffsets = <String, int>{};
  final Map<String, int> tableLengths = <String, int>{};
  int p = sfntOffset + 12;
  for (int i = 0; i < numTables; i++) {
    final String tag = String.fromCharCodes(bytes, p, p + 4);
    tableOffsets[tag] = r.u32(p + 8);
    tableLengths[tag] = r.u32(p + 12);
    p += 16;
  }

  int need(String tag) {
    final int? off = tableOffsets[tag];
    if (off == null) {
      throw FontParseException('tabela ausente: $tag');
    }
    return off;
  }

  // head: unitsPerEm.
  final int head = need('head');
  final int unitsPerEm = r.u16(head + 18);

  // hhea: ascender/descender/lineGap e numberOfHMetrics.
  final int hhea = need('hhea');
  int ascent = r.i16(hhea + 4);
  int descent = -r.i16(hhea + 6); // hhea.descender é negativo → magnitude.
  int lineGap = r.i16(hhea + 8);
  final int numberOfHMetrics = r.u16(hhea + 34);

  // OS/2 (se presente): quando fsSelection bit 7 (USE_TYPO_METRICS) estiver
  // ligado, o Word usa as métricas tipográficas para a altura de linha.
  final int? os2 = tableOffsets['OS/2'];
  if (os2 != null && tableLengths['OS/2']! >= 78) {
    final int fsSelection = r.u16(os2 + 62);
    final bool useTypo = (fsSelection & 0x80) != 0;
    if (useTypo) {
      ascent = r.i16(os2 + 68); // sTypoAscender
      descent = -r.i16(os2 + 70); // sTypoDescender
      lineGap = r.i16(os2 + 72); // sTypoLineGap
    }
  }

  // hmtx: avanço por glifo (glifos além de numberOfHMetrics reusam o último).
  final int hmtx = need('hmtx');
  int advanceOfGlyph(int glyphId) {
    final int idx = glyphId < numberOfHMetrics ? glyphId : numberOfHMetrics - 1;
    return r.u16(hmtx + idx * 4);
  }

  // cmap: escolhe uma subtabela Unicode BMP (platform 3/1 ou 0/*).
  final int cmap = need('cmap');
  final int numSub = r.u16(cmap + 2);
  int? best;
  for (int i = 0; i < numSub; i++) {
    final int rec = cmap + 4 + i * 8;
    final int platform = r.u16(rec);
    final int encoding = r.u16(rec + 2);
    final int off = r.u32(rec + 4);
    final bool unicodeBmp =
        (platform == 3 && (encoding == 1 || encoding == 0)) ||
            (platform == 0 && encoding <= 4);
    if (unicodeBmp) {
      best = cmap + off;
      if (platform == 3 && encoding == 1) break; // preferido
    }
  }
  if (best == null) {
    throw FontParseException('sem subtabela cmap Unicode BMP');
  }
  final _CmapFormat4 cm = _CmapFormat4.parse(r, best);

  // Monta codepoint → avanço no intervalo pedido + extras.
  final Set<int> codepoints = <int>{
    for (int cp = codepointMin; cp <= codepointMax; cp++) cp,
    ...extraCodepoints,
  };
  final Map<int, int> advances = <int, int>{};
  for (final int cp in codepoints) {
    final int gid = cm.glyphOf(cp);
    if (gid == 0) continue; // sem glifo — usa defaultAdvance no lookup
    advances[cp] = advanceOfGlyph(gid);
  }
  final int defaultAdvance = advanceOfGlyph(0);

  return FontMetrics(
    unitsPerEm: unitsPerEm,
    ascent: ascent,
    descent: descent,
    lineGap: lineGap,
    advanceWidths: advances,
    defaultAdvance: defaultAdvance,
  );
}

/// Leitor big-endian sobre os bytes da fonte.
class _Reader {
  _Reader(this.b);
  final Uint8List b;

  int u16(int o) => (b[o] << 8) | b[o + 1];
  int i16(int o) {
    final int v = u16(o);
    return v >= 0x8000 ? v - 0x10000 : v;
  }

  int u32(int o) =>
      (b[o] << 24) | (b[o + 1] << 16) | (b[o + 2] << 8) | b[o + 3];
}

/// Subtabela cmap formato 4 (segment mapping to delta values), o formato
/// padrão para o BMP em fontes Windows.
class _CmapFormat4 {
  _CmapFormat4({
    required this.segCount,
    required this.endCodes,
    required this.startCodes,
    required this.idDeltas,
    required this.idRangeOffsets,
    required this.idRangeOffsetPos,
    required this.reader,
  });

  final int segCount;
  final List<int> endCodes;
  final List<int> startCodes;
  final List<int> idDeltas;
  final List<int> idRangeOffsets;
  final int
      idRangeOffsetPos; // offset absoluto do início do array idRangeOffset
  final _Reader reader;

  static _CmapFormat4 parse(_Reader r, int off) {
    final int format = r.u16(off);
    if (format != 4) {
      throw FontParseException('cmap formato $format não suportado (só 4)');
    }
    final int segX2 = r.u16(off + 6);
    final int segCount = segX2 ~/ 2;
    final int endBase = off + 14;
    final int startBase = endBase + segX2 + 2; // +2 reservedPad
    final int deltaBase = startBase + segX2;
    final int rangeBase = deltaBase + segX2;
    final List<int> endCodes = <int>[];
    final List<int> startCodes = <int>[];
    final List<int> idDeltas = <int>[];
    final List<int> idRangeOffsets = <int>[];
    for (int i = 0; i < segCount; i++) {
      endCodes.add(r.u16(endBase + i * 2));
      startCodes.add(r.u16(startBase + i * 2));
      idDeltas.add(r.u16(deltaBase + i * 2));
      idRangeOffsets.add(r.u16(rangeBase + i * 2));
    }
    return _CmapFormat4(
      segCount: segCount,
      endCodes: endCodes,
      startCodes: startCodes,
      idDeltas: idDeltas,
      idRangeOffsets: idRangeOffsets,
      idRangeOffsetPos: rangeBase,
      reader: r,
    );
  }

  int glyphOf(int cp) {
    for (int i = 0; i < segCount; i++) {
      if (cp > endCodes[i]) continue;
      if (cp < startCodes[i]) return 0;
      final int rangeOffset = idRangeOffsets[i];
      if (rangeOffset == 0) {
        return (cp + idDeltas[i]) & 0xFFFF;
      }
      // glyphIndexArray[idRangeOffset/2 + (cp - startCode) - (segCount - i)]
      final int glyphIndexAddr =
          idRangeOffsetPos + i * 2 + rangeOffset + (cp - startCodes[i]) * 2;
      final int gid = reader.u16(glyphIndexAddr);
      if (gid == 0) return 0;
      return (gid + idDeltas[i]) & 0xFFFF;
    }
    return 0;
  }
}
