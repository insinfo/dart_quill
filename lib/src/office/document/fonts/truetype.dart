/// Leitor de fontes TrueType/OpenType — só o que embutir uma fonte num PDF
/// exige.
///
/// Não é um motor tipográfico: não faz shaping, não lê `GPOS`/`GSUB`, não
/// renderiza contornos. Lê as tabelas necessárias para (a) medir texto,
/// (b) mapear caractere → glifo e (c) recortar um subconjunto de glifos para
/// embutir. Esse recorte é o que impede um despacho de duas páginas de pesar
/// megabytes por causa de quatro variantes da mesma família.
///
/// Referência de formato: a especificação OpenType. As implementações locais
/// (`itext`, `jsPDF`, `dart_graphics`) serviram de conferência de campos —
/// nenhuma linha veio delas, e nenhuma dependência entrou.
library;

import 'dart:typed_data';

/// Falha ao interpretar o arquivo de fonte.
class TrueTypeException implements Exception {
  TrueTypeException(this.message);

  final String message;

  @override
  String toString() => 'TrueTypeException: $message';
}

/// Caixa envolvente da fonte, em unidades de projeto (`unitsPerEm`).
class FontBoundingBox {
  const FontBoundingBox(this.xMin, this.yMin, this.xMax, this.yMax);

  final int xMin;
  final int yMin;
  final int xMax;
  final int yMax;

  @override
  String toString() => '[$xMin $yMin $xMax $yMax]';
}

/// O que a fonte declara sobre uso incorporado (`OS/2.fsType`).
///
/// O PDF não é obrigado a respeitar isto, mas gerar um documento que viola a
/// licença embutida da fonte é problema de quem gera — daí ficar exposto.
enum EmbeddingPermission {
  /// Instalável: sem restrição.
  installable,

  /// Pode ser embutida para visualização e impressão.
  printAndPreview,

  /// Pode ser embutida com permissão de edição.
  editable,

  /// A fonte proíbe embutir.
  restricted,
}

/// Uma fonte TrueType/OpenType já parseada.
class TrueTypeFont {
  TrueTypeFont._(this._bytes, this._tables);

  final Uint8List _bytes;
  final Map<String, _TableRecord> _tables;

  // Campos lidos uma vez na construção.
  late final int unitsPerEm = _head.unitsPerEm;
  late final int numGlyphs = _readUint16(_require('maxp').offset + 4);
  late final FontBoundingBox boundingBox = _head.bbox;
  late final int indexToLocFormat = _head.indexToLocFormat;
  late final int macStyle = _head.macStyle;

  late final _HheaTable _hhea = _parseHhea();
  int get ascender => _hhea.ascender;
  int get descender => _hhea.descender;
  int get lineGap => _hhea.lineGap;

  late final _Os2Table? _os2 = _parseOs2();

  /// Altura das maiúsculas, quando a fonte declara (`OS/2` v2+); senão
  /// estimada como 70% do em, que é a razão usual em fontes de texto.
  int get capHeight => _os2?.capHeight ?? (unitsPerEm * 0.7).round();

  /// Peso declarado (`OS/2.usWeightClass`): 400 normal, 700 negrito.
  int get weightClass => _os2?.weightClass ?? 400;

  /// Ângulo do itálico, em graus (negativo inclina para a direita).
  late final double italicAngle = _parseItalicAngle();

  late final bool isFixedPitch = _parseIsFixedPitch();

  bool get isBold => (macStyle & 0x0001) != 0 || weightClass >= 600;
  bool get isItalic => (macStyle & 0x0002) != 0 || italicAngle != 0;

  /// `true` quando a fonte é OpenType com contornos CFF (`CFF ` em vez de
  /// `glyf`). Este leitor **não** subdivide CFF: dá para embutir inteira, não
  /// recortada.
  bool get isCff => _tables.containsKey('CFF ') && !_tables.containsKey('glyf');

  late final EmbeddingPermission embeddingPermission =
      _parseEmbeddingPermission();

  /// Nome PostScript (`name` ID 6), usado no `/BaseFont` do PDF.
  late final String postScriptName = _readName(6) ?? 'Unknown';

  /// Nome da família (`name` ID 1).
  late final String familyName = _readName(1) ?? postScriptName;

  late final _CmapTable _cmap = _parseCmap();
  late final List<int> _advanceWidths = _parseHmtx();
  late final List<int> _locaOffsets = _parseLoca();

  /// Interpreta [bytes] como uma fonte.
  ///
  /// Aceita `.ttf` (`0x00010000`), `.otf` (`OTTO`) e a variante `true` dos
  /// Macs. Um `.ttc` (coleção) é recusado explicitamente em vez de produzir
  /// lixo silencioso.
  factory TrueTypeFont.parse(Uint8List bytes) {
    if (bytes.length < 12) {
      throw TrueTypeException('arquivo curto demais (${bytes.length} bytes)');
    }
    final data = ByteData.sublistView(bytes);
    final tag = data.getUint32(0);
    if (tag == 0x74746366) {
      throw TrueTypeException(
          'coleção TrueType (.ttc) não suportada: extraia a fonte desejada');
    }
    if (tag != 0x00010000 && tag != 0x4F54544F && tag != 0x74727565) {
      throw TrueTypeException(
          'assinatura desconhecida: 0x${tag.toRadixString(16)}');
    }

    final numTables = data.getUint16(4);
    final tables = <String, _TableRecord>{};
    for (var i = 0; i < numTables; i++) {
      final record = 12 + i * 16;
      if (record + 16 > bytes.length) {
        throw TrueTypeException('diretório de tabelas truncado');
      }
      final name = String.fromCharCodes(bytes, record, record + 4);
      final offset = data.getUint32(record + 8);
      final length = data.getUint32(record + 12);
      if (offset > bytes.length) {
        throw TrueTypeException('tabela $name aponta para fora do arquivo');
      }
      tables[name] = _TableRecord(offset, length);
    }
    return TrueTypeFont._(bytes, tables);
  }

  /// Os bytes originais, para quem precisa embutir a fonte inteira.
  Uint8List get bytes => _bytes;

  /// Tabelas presentes, para diagnóstico.
  Iterable<String> get tableNames => _tables.keys;

  bool hasTable(String name) => _tables.containsKey(name);

  /// Conteúdo bruto de uma tabela, ou null se ausente.
  Uint8List? tableData(String name) {
    final record = _tables[name];
    if (record == null) return null;
    final end = (record.offset + record.length).clamp(0, _bytes.length);
    return Uint8List.sublistView(_bytes, record.offset, end);
  }

  /// Glifo que desenha [charCode]; `0` (`.notdef`) quando a fonte não o tem.
  int glyphIdFor(int charCode) => _cmap.lookup(charCode);

  /// Avanço horizontal de [glyphId], em unidades de projeto.
  ///
  /// A `hmtx` guarda menos entradas que glifos quando a cauda é monoespaçada:
  /// os glifos além de `numberOfHMetrics` repetem a última largura. Ignorar
  /// isso é o erro clássico que faz o texto medir errado no fim do alfabeto.
  int advanceWidthOf(int glyphId) {
    if (_advanceWidths.isEmpty) return 0;
    if (glyphId < 0 || glyphId >= numGlyphs) return _advanceWidths.first;
    return glyphId < _advanceWidths.length
        ? _advanceWidths[glyphId]
        : _advanceWidths.last;
  }

  /// Avanço de [charCode] em milésimos de em — a unidade do PDF.
  int advanceWidthOfChar(int charCode) =>
      (advanceWidthOf(glyphIdFor(charCode)) * 1000 / unitsPerEm).round();

  /// Deslocamento lateral esquerdo de [glyphId], em unidades de projeto.
  ///
  /// A `hmtx` guarda `numberOfHMetrics` pares (avanço, lsb) e, depois deles,
  /// **só lsb** para os glifos restantes. Ler isso errado desloca o desenho
  /// dos últimos glifos dentro da própria caixa.
  int leftSideBearingOf(int glyphId) {
    final hmtx = _tables['hmtx'];
    if (hmtx == null || glyphId < 0 || glyphId >= numGlyphs) return 0;
    final count = _hhea.numberOfHMetrics;
    final at = glyphId < count
        ? hmtx.offset + glyphId * 4 + 2
        : hmtx.offset + count * 4 + (glyphId - count) * 2;
    if (at + 2 > _bytes.length) return 0;
    return _readInt16(at);
  }

  /// Bytes do contorno de [glyphId] na tabela `glyf`.
  ///
  /// Vazio para um glifo sem contorno (o espaço, por exemplo) — o que é
  /// legítimo e diferente de "glifo inexistente".
  Uint8List glyphData(int glyphId) {
    if (isCff) {
      throw TrueTypeException(
          'fonte com contornos CFF: `glyf` não existe nesta fonte');
    }
    if (glyphId < 0 || glyphId + 1 >= _locaOffsets.length) {
      return Uint8List(0);
    }
    final glyf = _require('glyf');
    final start = glyf.offset + _locaOffsets[glyphId];
    final end = glyf.offset + _locaOffsets[glyphId + 1];
    if (end <= start || end > _bytes.length) return Uint8List(0);
    return Uint8List.sublistView(_bytes, start, end);
  }

  /// Glifos referenciados por [glyphId] quando ele é composto (um `é` é a
  /// composição de `e` e do acento).
  ///
  /// Um subconjunto que esqueça os componentes gera glifos vazios no PDF —
  /// o texto aparece com buracos exatamente nos caracteres acentuados, que é
  /// o pior lugar possível para um documento em português.
  Set<int> componentGlyphsOf(int glyphId) {
    final data = glyphData(glyphId);
    if (data.length < 10) return const <int>{};
    final view = ByteData.sublistView(data);
    final numberOfContours = view.getInt16(0);
    if (numberOfContours >= 0) return const <int>{}; // glifo simples

    final components = <int>{};
    var offset = 10;
    while (offset + 4 <= data.length) {
      final flags = view.getUint16(offset);
      final index = view.getUint16(offset + 2);
      components.add(index);
      offset += 4;

      // ARG_1_AND_2_ARE_WORDS
      offset += (flags & 0x0001) != 0 ? 4 : 2;
      if ((flags & 0x0008) != 0) {
        offset += 2; // WE_HAVE_A_SCALE
      } else if ((flags & 0x0040) != 0) {
        offset += 4; // X_AND_Y_SCALE
      } else if ((flags & 0x0080) != 0) {
        offset += 8; // TWO_BY_TWO
      }
      if ((flags & 0x0020) == 0) break; // MORE_COMPONENTS
    }
    return components;
  }

  /// Fecho de [glyphIds] com todos os componentes, recursivamente.
  ///
  /// É o conjunto que o subsetting precisa manter.
  Set<int> expandWithComponents(Iterable<int> glyphIds) {
    final result = <int>{};
    final pending = <int>[...glyphIds];
    while (pending.isNotEmpty) {
      final id = pending.removeLast();
      if (!result.add(id)) continue;
      if (isCff) continue;
      pending.addAll(componentGlyphsOf(id));
    }
    return result;
  }

  /// Deslocamentos da `loca`, com `numGlyphs + 1` entradas.
  List<int> get glyphOffsets => List.unmodifiable(_locaOffsets);

  // ---------------------------------------------------------------------
  // Parsing das tabelas
  // ---------------------------------------------------------------------

  _TableRecord _require(String name) {
    final record = _tables[name];
    if (record == null) {
      throw TrueTypeException('tabela obrigatória ausente: $name');
    }
    return record;
  }

  int _readUint16(int offset) => ByteData.sublistView(_bytes).getUint16(offset);
  int _readInt16(int offset) => ByteData.sublistView(_bytes).getInt16(offset);
  int _readUint32(int offset) => ByteData.sublistView(_bytes).getUint32(offset);

  late final _HeadTable _head = _parseHead();

  _HeadTable _parseHead() {
    final head = _require('head');
    return _HeadTable(
      unitsPerEm: _readUint16(head.offset + 18),
      macStyle: _readUint16(head.offset + 44),
      indexToLocFormat: _readInt16(head.offset + 50),
      bbox: FontBoundingBox(
        _readInt16(head.offset + 36),
        _readInt16(head.offset + 38),
        _readInt16(head.offset + 40),
        _readInt16(head.offset + 42),
      ),
    );
  }

  _HheaTable _parseHhea() {
    final hhea = _require('hhea');
    return _HheaTable(
      ascender: _readInt16(hhea.offset + 4),
      descender: _readInt16(hhea.offset + 6),
      lineGap: _readInt16(hhea.offset + 8),
      numberOfHMetrics: _readUint16(hhea.offset + 34),
    );
  }

  _Os2Table? _parseOs2() {
    final os2 = _tables['OS/2'];
    if (os2 == null || os2.length < 10) return null;
    final version = _readUint16(os2.offset);
    return _Os2Table(
      weightClass: _readUint16(os2.offset + 4),
      fsType: _readUint16(os2.offset + 8),
      // sCapHeight só existe da versão 2 em diante (offset 88).
      capHeight:
          version >= 2 && os2.length >= 90 ? _readInt16(os2.offset + 88) : null,
    );
  }

  double _parseItalicAngle() {
    final post = _tables['post'];
    if (post == null || post.length < 12) return 0;
    // Fixed 16.16 com sinal.
    final raw = ByteData.sublistView(_bytes).getInt32(post.offset + 4);
    return raw / 65536.0;
  }

  bool _parseIsFixedPitch() {
    final post = _tables['post'];
    if (post == null || post.length < 16) return false;
    return _readUint32(post.offset + 12) != 0;
  }

  EmbeddingPermission _parseEmbeddingPermission() {
    final fsType = _os2?.fsType;
    if (fsType == null) return EmbeddingPermission.installable;
    // Bit 1 (0x0002) = restricted; os bits são mutuamente exclusivos na
    // prática, mas a especificação manda checar o restrito primeiro.
    if ((fsType & 0x0002) != 0) return EmbeddingPermission.restricted;
    if ((fsType & 0x0008) != 0) return EmbeddingPermission.editable;
    if ((fsType & 0x0004) != 0) return EmbeddingPermission.printAndPreview;
    return EmbeddingPermission.installable;
  }

  List<int> _parseHmtx() {
    final hmtx = _tables['hmtx'];
    if (hmtx == null) return const <int>[];
    final count = _hhea.numberOfHMetrics;
    final widths = <int>[];
    for (var i = 0; i < count; i++) {
      final at = hmtx.offset + i * 4;
      if (at + 2 > _bytes.length) break;
      widths.add(_readUint16(at));
    }
    return widths;
  }

  List<int> _parseLoca() {
    final loca = _tables['loca'];
    if (loca == null) return const <int>[];
    final long = indexToLocFormat != 0;
    final count = numGlyphs + 1;
    final offsets = <int>[];
    for (var i = 0; i < count; i++) {
      final at = loca.offset + (long ? i * 4 : i * 2);
      if (long) {
        if (at + 4 > _bytes.length) break;
        offsets.add(_readUint32(at));
      } else {
        if (at + 2 > _bytes.length) break;
        // O formato curto guarda o deslocamento dividido por dois.
        offsets.add(_readUint16(at) * 2);
      }
    }
    return offsets;
  }

  String? _readName(int nameId) {
    final name = _tables['name'];
    if (name == null || name.length < 6) return null;
    final count = _readUint16(name.offset + 2);
    final stringOffset = _readUint16(name.offset + 4);

    String? fallback;
    for (var i = 0; i < count; i++) {
      final record = name.offset + 6 + i * 12;
      if (record + 12 > _bytes.length) break;
      if (_readUint16(record + 6) != nameId) continue;

      final platformId = _readUint16(record);
      final length = _readUint16(record + 8);
      final offset = _readUint16(record + 10);
      final start = name.offset + stringOffset + offset;
      if (start + length > _bytes.length) continue;
      final raw = Uint8List.sublistView(_bytes, start, start + length);

      // Plataforma 3 (Windows) e 0 (Unicode) usam UTF-16BE; a 1 (Mac) usa
      // um encoding de byte único que, para nomes latinos, coincide com
      // ASCII.
      final decoded = platformId == 1
          ? String.fromCharCodes(raw)
          : _decodeUtf16Be(raw);
      if (platformId == 3) return decoded; // preferido
      fallback ??= decoded;
    }
    return fallback;
  }

  static String _decodeUtf16Be(Uint8List raw) {
    final units = <int>[];
    for (var i = 0; i + 1 < raw.length; i += 2) {
      units.add((raw[i] << 8) | raw[i + 1]);
    }
    return String.fromCharCodes(units);
  }

  _CmapTable _parseCmap() {
    final cmap = _tables['cmap'];
    if (cmap == null) return _CmapTable.empty();
    final numSubtables = _readUint16(cmap.offset + 2);

    // Preferência: (3,10) UCS-4 → (3,1) BMP → (0,x) Unicode → qualquer.
    int? best;
    var bestScore = -1;
    for (var i = 0; i < numSubtables; i++) {
      final record = cmap.offset + 4 + i * 8;
      if (record + 8 > _bytes.length) break;
      final platformId = _readUint16(record);
      final encodingId = _readUint16(record + 2);
      final offset = _readUint32(record + 4);

      var score = 0;
      if (platformId == 3 && encodingId == 10) {
        score = 4;
      } else if (platformId == 3 && encodingId == 1) {
        score = 3;
      } else if (platformId == 0) {
        score = 2;
      } else {
        score = 1;
      }
      if (score > bestScore) {
        bestScore = score;
        best = cmap.offset + offset;
      }
    }
    if (best == null || best + 2 > _bytes.length) return _CmapTable.empty();

    final format = _readUint16(best);
    switch (format) {
      case 4:
        return _parseCmapFormat4(best);
      case 12:
        return _parseCmapFormat12(best);
      case 6:
        return _parseCmapFormat6(best);
      case 0:
        return _parseCmapFormat0(best);
      default:
        return _CmapTable.empty();
    }
  }

  _CmapTable _parseCmapFormat0(int at) {
    final map = <int, int>{};
    for (var code = 0; code < 256; code++) {
      final index = at + 6 + code;
      if (index >= _bytes.length) break;
      final glyph = _bytes[index];
      if (glyph != 0) map[code] = glyph;
    }
    return _CmapTable(map);
  }

  _CmapTable _parseCmapFormat4(int at) {
    final segCountX2 = _readUint16(at + 6);
    final segCount = segCountX2 ~/ 2;
    final endCodes = at + 14;
    final startCodes = endCodes + segCountX2 + 2; // +2 do reservedPad
    final idDeltas = startCodes + segCountX2;
    final idRangeOffsets = idDeltas + segCountX2;

    final map = <int, int>{};
    for (var segment = 0; segment < segCount; segment++) {
      final end = _readUint16(endCodes + segment * 2);
      final start = _readUint16(startCodes + segment * 2);
      if (start > end) continue;
      final delta = _readInt16(idDeltas + segment * 2);
      final rangeOffsetAt = idRangeOffsets + segment * 2;
      final rangeOffset = _readUint16(rangeOffsetAt);

      for (var code = start; code <= end && code != 0xFFFF; code++) {
        int glyph;
        if (rangeOffset == 0) {
          glyph = (code + delta) & 0xFFFF;
        } else {
          // O idRangeOffset é um deslocamento em bytes a partir da PRÓPRIA
          // posição dele — a indireção mais fácil de errar do formato.
          final glyphAt = rangeOffsetAt + rangeOffset + (code - start) * 2;
          if (glyphAt + 2 > _bytes.length) continue;
          glyph = _readUint16(glyphAt);
          if (glyph != 0) glyph = (glyph + delta) & 0xFFFF;
        }
        if (glyph != 0) map[code] = glyph;
      }
    }
    return _CmapTable(map);
  }

  _CmapTable _parseCmapFormat6(int at) {
    final first = _readUint16(at + 6);
    final count = _readUint16(at + 8);
    final map = <int, int>{};
    for (var i = 0; i < count; i++) {
      final glyphAt = at + 10 + i * 2;
      if (glyphAt + 2 > _bytes.length) break;
      final glyph = _readUint16(glyphAt);
      if (glyph != 0) map[first + i] = glyph;
    }
    return _CmapTable(map);
  }

  _CmapTable _parseCmapFormat12(int at) {
    final numGroups = _readUint32(at + 12);
    final map = <int, int>{};
    for (var group = 0; group < numGroups; group++) {
      final record = at + 16 + group * 12;
      if (record + 12 > _bytes.length) break;
      final startChar = _readUint32(record);
      final endChar = _readUint32(record + 4);
      final startGlyph = _readUint32(record + 8);
      // Um grupo pode cobrir milhares de pontos; materializar tudo custaria
      // memória à toa, então grupos enormes ficam em faixas.
      if (endChar - startChar > 0xFFFF) continue;
      for (var code = startChar; code <= endChar; code++) {
        map[code] = startGlyph + (code - startChar);
      }
    }
    return _CmapTable(map);
  }
}

class _TableRecord {
  const _TableRecord(this.offset, this.length);
  final int offset;
  final int length;
}

class _HeadTable {
  const _HeadTable({
    required this.unitsPerEm,
    required this.macStyle,
    required this.indexToLocFormat,
    required this.bbox,
  });
  final int unitsPerEm;
  final int macStyle;
  final int indexToLocFormat;
  final FontBoundingBox bbox;
}

class _HheaTable {
  const _HheaTable({
    required this.ascender,
    required this.descender,
    required this.lineGap,
    required this.numberOfHMetrics,
  });
  final int ascender;
  final int descender;
  final int lineGap;
  final int numberOfHMetrics;
}

class _Os2Table {
  const _Os2Table({
    required this.weightClass,
    required this.fsType,
    required this.capHeight,
  });
  final int weightClass;
  final int fsType;
  final int? capHeight;
}

class _CmapTable {
  _CmapTable(this._map);
  _CmapTable.empty() : _map = const <int, int>{};

  final Map<int, int> _map;

  int lookup(int charCode) => _map[charCode] ?? 0;

  int get length => _map.length;
}
