/// Kerning por GPOS (OpenType PairPos) — a etapa 1 do TextShaper.
///
/// Fontes modernas (Inter, Calibri, Arial atuais) NÃO têm a tabela `kern`
/// legada: o kerning de pares mora no GPOS, lookup type 2 (PairAdjustment),
/// nos formatos 1 (pares por glifo) e 2 (pares por classe). Este parser lê
/// exatamente esse subconjunto — o ajuste de `xAdvance` do primeiro glifo
/// do par, que é como o kerning latino é gravado na prática — e ignora o
/// resto do GPOS (marks, cursive, contextual: etapa 2).
///
/// Lookups tipo 9 (Extension) são resolvidos para o tipo real. A busca de
/// features aceita qualquer feature `kern` da fonte (sem filtrar por
/// script: para latino é o comportamento correto e simples).
library;

import 'dart:typed_data';

class GposKerning {
  GposKerning._(this._pairs, this._classKerning);

  /// Pares explícitos: chave `(left << 16) | right` → ajuste em unidades.
  final Map<int, int> _pairs;

  /// Subtables por classe, avaliadas em ordem.
  final List<_ClassKerning> _classKerning;

  static final GposKerning empty = GposKerning._(const {}, const []);

  bool get isEmpty => _pairs.isEmpty && _classKerning.isEmpty;

  /// Ajuste de avanço (unidades da fonte) para o par [left]→[right].
  int kerningFor(int left, int right) {
    final direct = _pairs[(left << 16) | right];
    if (direct != null) return direct;
    for (final table in _classKerning) {
      final value = table.kerningFor(left, right);
      if (value != null) return value;
    }
    return 0;
  }

  /// Faz o parse do GPOS em [data] (offset absoluto [gposOffset]).
  /// Qualquer estrutura fora do subconjunto suportado é ignorada em
  /// silêncio — kerning ausente nunca é erro, só medida sem ajuste.
  static GposKerning parse(ByteData data, int gposOffset) {
    try {
      return _parse(data, gposOffset);
    } catch (_) {
      return empty;
    }
  }

  static GposKerning _parse(ByteData data, int gpos) {
    final featureListOffset = gpos + data.getUint16(gpos + 6);
    final lookupListOffset = gpos + data.getUint16(gpos + 8);

    // Índices de lookup de TODAS as features `kern`.
    final lookupIndices = <int>{};
    final featureCount = data.getUint16(featureListOffset);
    for (var i = 0; i < featureCount; i++) {
      final recordOffset = featureListOffset + 2 + i * 6;
      final tag = String.fromCharCodes([
        data.getUint8(recordOffset),
        data.getUint8(recordOffset + 1),
        data.getUint8(recordOffset + 2),
        data.getUint8(recordOffset + 3),
      ]);
      if (tag != 'kern') continue;
      final featureOffset =
          featureListOffset + data.getUint16(recordOffset + 4);
      final lookupCount = data.getUint16(featureOffset + 2);
      for (var j = 0; j < lookupCount; j++) {
        lookupIndices.add(data.getUint16(featureOffset + 4 + j * 2));
      }
    }
    if (lookupIndices.isEmpty) return empty;

    final pairs = <int, int>{};
    final classTables = <_ClassKerning>[];

    final lookupCount = data.getUint16(lookupListOffset);
    for (final index in lookupIndices) {
      if (index >= lookupCount) continue;
      final lookupOffset =
          lookupListOffset + data.getUint16(lookupListOffset + 2 + index * 2);
      var lookupType = data.getUint16(lookupOffset);
      final subTableCount = data.getUint16(lookupOffset + 4);
      for (var s = 0; s < subTableCount; s++) {
        var subtable = lookupOffset + data.getUint16(lookupOffset + 6 + s * 2);
        var type = lookupType;
        if (type == 9) {
          // Extension: aponta para a subtable real com offset de 32 bits.
          type = data.getUint16(subtable + 2);
          subtable = subtable + data.getUint32(subtable + 4);
        }
        if (type != 2) continue; // só PairAdjustment
        _parsePairPos(data, subtable, pairs, classTables);
      }
    }
    return GposKerning._(pairs, classTables);
  }

  static void _parsePairPos(ByteData data, int subtable, Map<int, int> pairs,
      List<_ClassKerning> classTables) {
    final format = data.getUint16(subtable);
    final coverage =
        _Coverage.parse(data, subtable + data.getUint16(subtable + 2));
    final valueFormat1 = data.getUint16(subtable + 4);
    final valueFormat2 = data.getUint16(subtable + 6);
    // Só interessa o xAdvance do PRIMEIRO glifo (é onde o kerning mora).
    if (valueFormat1 & 0x0004 == 0) return;
    final size1 = _valueRecordSize(valueFormat1);
    final size2 = _valueRecordSize(valueFormat2);
    final xAdvanceOffset = _xAdvanceOffset(valueFormat1);

    if (format == 1) {
      final pairSetCount = data.getUint16(subtable + 8);
      for (var i = 0; i < pairSetCount; i++) {
        final first = coverage.glyphAt(i);
        if (first == null) continue;
        final pairSet = subtable + data.getUint16(subtable + 10 + i * 2);
        final pairCount = data.getUint16(pairSet);
        var cursor = pairSet + 2;
        for (var p = 0; p < pairCount; p++) {
          final second = data.getUint16(cursor);
          final xAdvance = data.getInt16(cursor + 2 + xAdvanceOffset);
          if (xAdvance != 0) {
            pairs[(first << 16) | second] = xAdvance;
          }
          cursor += 2 + size1 + size2;
        }
      }
    } else if (format == 2) {
      final classDef1 =
          _ClassDef.parse(data, subtable + data.getUint16(subtable + 8));
      final classDef2 =
          _ClassDef.parse(data, subtable + data.getUint16(subtable + 10));
      final class1Count = data.getUint16(subtable + 12);
      final class2Count = data.getUint16(subtable + 14);
      final values = Int16List(class1Count * class2Count);
      var cursor = subtable + 16;
      var any = false;
      for (var c1 = 0; c1 < class1Count; c1++) {
        for (var c2 = 0; c2 < class2Count; c2++) {
          final xAdvance = data.getInt16(cursor + xAdvanceOffset);
          values[c1 * class2Count + c2] = xAdvance;
          if (xAdvance != 0) any = true;
          cursor += size1 + size2;
        }
      }
      if (any) {
        classTables.add(_ClassKerning(
          coverage: coverage,
          classDef1: classDef1,
          classDef2: classDef2,
          class2Count: class2Count,
          values: values,
        ));
      }
    }
  }

  static int _valueRecordSize(int valueFormat) {
    var bits = valueFormat & 0xFF;
    var count = 0;
    while (bits != 0) {
      count += bits & 1;
      bits >>= 1;
    }
    return count * 2;
  }

  /// Posição do xAdvance dentro do ValueRecord: soma dos campos anteriores
  /// (xPlacement 0x1, yPlacement 0x2) presentes.
  static int _xAdvanceOffset(int valueFormat) {
    var offset = 0;
    if (valueFormat & 0x0001 != 0) offset += 2;
    if (valueFormat & 0x0002 != 0) offset += 2;
    return offset;
  }
}

class _ClassKerning {
  _ClassKerning({
    required this.coverage,
    required this.classDef1,
    required this.classDef2,
    required this.class2Count,
    required this.values,
  });

  final _Coverage coverage;
  final _ClassDef classDef1;
  final _ClassDef classDef2;
  final int class2Count;
  final Int16List values;

  int? kerningFor(int left, int right) {
    if (!coverage.contains(left)) return null;
    final c1 = classDef1.classOf(left);
    final c2 = classDef2.classOf(right);
    final index = c1 * class2Count + c2;
    if (index < 0 || index >= values.length) return null;
    final value = values[index];
    return value == 0 ? null : value;
  }
}

class _Coverage {
  _Coverage._(this._glyphs, this._ranges);

  final List<int>? _glyphs; // formato 1
  final List<(int start, int end, int startIndex)>? _ranges; // formato 2

  static _Coverage parse(ByteData data, int offset) {
    final format = data.getUint16(offset);
    if (format == 1) {
      final count = data.getUint16(offset + 2);
      final glyphs = List<int>.generate(
          count, (i) => data.getUint16(offset + 4 + i * 2));
      return _Coverage._(glyphs, null);
    }
    final count = data.getUint16(offset + 2);
    final ranges = <(int, int, int)>[];
    for (var i = 0; i < count; i++) {
      final base = offset + 4 + i * 6;
      ranges.add((
        data.getUint16(base),
        data.getUint16(base + 2),
        data.getUint16(base + 4),
      ));
    }
    return _Coverage._(null, ranges);
  }

  bool contains(int glyph) => indexOfGlyph(glyph) != null;

  int? indexOfGlyph(int glyph) {
    final glyphs = _glyphs;
    if (glyphs != null) {
      final index = glyphs.indexOf(glyph);
      return index == -1 ? null : index;
    }
    for (final (start, end, startIndex) in _ranges!) {
      if (glyph >= start && glyph <= end) {
        return startIndex + (glyph - start);
      }
    }
    return null;
  }

  /// Glifo cujo coverage index é [index] (para PairPos formato 1).
  int? glyphAt(int index) {
    final glyphs = _glyphs;
    if (glyphs != null) {
      return index < glyphs.length ? glyphs[index] : null;
    }
    for (final (start, end, startIndex) in _ranges!) {
      final size = end - start + 1;
      if (index >= startIndex && index < startIndex + size) {
        return start + (index - startIndex);
      }
    }
    return null;
  }
}

class _ClassDef {
  _ClassDef._(this._startGlyph, this._classes, this._ranges);

  final int _startGlyph; // formato 1
  final List<int>? _classes;
  final List<(int start, int end, int classValue)>? _ranges; // formato 2

  static _ClassDef parse(ByteData data, int offset) {
    final format = data.getUint16(offset);
    if (format == 1) {
      final startGlyph = data.getUint16(offset + 2);
      final count = data.getUint16(offset + 4);
      final classes = List<int>.generate(
          count, (i) => data.getUint16(offset + 6 + i * 2));
      return _ClassDef._(startGlyph, classes, null);
    }
    final count = data.getUint16(offset + 2);
    final ranges = <(int, int, int)>[];
    for (var i = 0; i < count; i++) {
      final base = offset + 4 + i * 6;
      ranges.add((
        data.getUint16(base),
        data.getUint16(base + 2),
        data.getUint16(base + 4),
      ));
    }
    return _ClassDef._(0, null, ranges);
  }

  int classOf(int glyph) {
    final classes = _classes;
    if (classes != null) {
      final index = glyph - _startGlyph;
      return index >= 0 && index < classes.length ? classes[index] : 0;
    }
    for (final (start, end, classValue) in _ranges!) {
      if (glyph >= start && glyph <= end) return classValue;
    }
    return 0;
  }
}
