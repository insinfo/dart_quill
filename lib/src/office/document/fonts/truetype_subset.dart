/// Recorta uma fonte TrueType para os glifos que o documento realmente usa.
///
/// Sem isto, embutir quatro variantes da Inter num despacho de duas páginas
/// custa cerca de 1,6 MB de fonte para desenhar algumas centenas de
/// caracteres. Com o recorte, o custo é proporcional ao que o documento tem.
///
/// **Os identificadores de glifo são preservados**, e a fonte resultante
/// declara `numGlyphs = maiorGlifoMantido + 1`. Isso permite usar
/// `Identity-H`/`Identity-V` no PDF, onde CID = GID, sem precisar de um
/// `CIDToGIDMap` — e é barato para texto latino, cujos glifos ficam no começo
/// da fonte. A alternativa (renumerar os glifos) encolheria a `loca` mais um
/// pouco ao custo de um mapa extra no PDF e de uma classe inteira de erros de
/// correspondência.
library;

import 'dart:typed_data';

import 'truetype.dart';

/// Resultado de um recorte.
class TrueTypeSubset {
  const TrueTypeSubset({
    required this.bytes,
    required this.glyphIds,
    required this.numGlyphs,
    required this.originalSize,
  });

  /// A fonte recortada, pronta para ir num `/FontFile2`.
  final Uint8List bytes;

  /// Glifos mantidos, já incluindo `.notdef` e os componentes.
  final Set<int> glyphIds;

  /// `numGlyphs` declarado pela fonte recortada (maior glifo mantido + 1).
  final int numGlyphs;

  /// Tamanho da fonte original, para medir o ganho.
  final int originalSize;

  int get size => bytes.length;

  /// Fração do tamanho original, entre 0 e 1.
  double get ratio => originalSize == 0 ? 1 : size / originalSize;
}

/// Recorta [font] mantendo [glyphIds] (mais `.notdef` e os componentes).
///
/// Lança [TrueTypeException] para uma fonte com contornos CFF: recortar CFF é
/// outro formato inteiro, e entregar bytes truncados seria pior que recusar.
TrueTypeSubset subsetTrueType(TrueTypeFont font, Iterable<int> glyphIds) {
  if (font.isCff) {
    throw TrueTypeException(
        'fonte com contornos CFF não pode ser recortada por este subsetter; '
        'embuta a fonte inteira');
  }

  final keep = font.expandWithComponents(<int>{0, ...glyphIds})
    ..removeWhere((id) => id < 0 || id >= font.numGlyphs);
  keep.add(0); // `.notdef` sempre, mesmo que o filtro acima o tenha tirado.

  final maxGid = keep.reduce((a, b) => a > b ? a : b);
  final numGlyphs = maxGid + 1;

  final glyf = _buildGlyf(font, keep, numGlyphs);
  final tables = <String, Uint8List>{
    'head': _buildHead(font),
    'hhea': _buildHhea(font, numGlyphs),
    'maxp': _buildMaxp(font, numGlyphs),
    'hmtx': _buildHmtx(font, numGlyphs),
    'loca': glyf.loca,
    'glyf': glyf.data,
  };

  // Tabelas de hinting: copiadas como estão. Sem elas a fonte ainda desenha,
  // mas perde o ajuste fino em tamanhos pequenos.
  for (final name in const ['cvt ', 'fpgm', 'prep']) {
    final data = font.tableData(name);
    if (data != null && data.isNotEmpty) tables[name] = data;
  }

  return TrueTypeSubset(
    bytes: _assemble(tables),
    glyphIds: keep,
    numGlyphs: numGlyphs,
    originalSize: font.bytes.length,
  );
}

/// Conveniência: recorta pelos **caracteres** usados.
TrueTypeSubset subsetTrueTypeForText(TrueTypeFont font, Iterable<int> runes) {
  final glyphs = <int>{};
  for (final rune in runes) {
    final glyph = font.glyphIdFor(rune);
    if (glyph != 0) glyphs.add(glyph);
  }
  return subsetTrueType(font, glyphs);
}

// ---------------------------------------------------------------------------
// Construção das tabelas
// ---------------------------------------------------------------------------

class _Glyf {
  const _Glyf(this.data, this.loca);
  final Uint8List data;
  final Uint8List loca;
}

/// Monta `glyf` com os glifos mantidos e a `loca` correspondente.
///
/// Um glifo descartado vira uma entrada de comprimento zero — que é como o
/// formato representa "sem contorno", o mesmo que o espaço usa. A `loca` sai
/// sempre no formato longo (32 bits): o formato curto guarda o deslocamento
/// dividido por dois e só serve enquanto a tabela cabe em 128 KB, e ganhar
/// alguns bytes não paga o risco de estourar isso silenciosamente.
_Glyf _buildGlyf(TrueTypeFont font, Set<int> keep, int numGlyphs) {
  final glyphBytes = BytesBuilder(copy: false);
  final offsets = Uint32List(numGlyphs + 1);
  var offset = 0;

  for (var gid = 0; gid < numGlyphs; gid++) {
    offsets[gid] = offset;
    if (!keep.contains(gid)) continue;
    final data = font.glyphData(gid);
    if (data.isEmpty) continue;
    glyphBytes.add(data);
    offset += data.length;
    // Cada glifo começa em fronteira de 4 bytes; alguns rasterizadores
    // assumem isso ao ler words da tabela.
    final padding = (4 - (offset % 4)) % 4;
    if (padding > 0) {
      glyphBytes.add(Uint8List(padding));
      offset += padding;
    }
  }
  offsets[numGlyphs] = offset;

  final loca = ByteData(4 * (numGlyphs + 1));
  for (var i = 0; i <= numGlyphs; i++) {
    loca.setUint32(i * 4, offsets[i]);
  }
  return _Glyf(glyphBytes.takeBytes(), loca.buffer.asUint8List());
}

Uint8List _buildHead(TrueTypeFont font) {
  final head = Uint8List.fromList(font.tableData('head')!);
  final view = ByteData.sublistView(head);
  // O checkSumAdjustment é recalculado sobre o arquivo inteiro no fim.
  view.setUint32(8, 0);
  // indexToLocFormat = 1 (loca longa), coerente com _buildGlyf.
  if (head.length >= 52) view.setInt16(50, 1);
  return head;
}

Uint8List _buildHhea(TrueTypeFont font, int numGlyphs) {
  final hhea = Uint8List.fromList(font.tableData('hhea')!);
  if (hhea.length >= 36) {
    ByteData.sublistView(hhea).setUint16(34, numGlyphs);
  }
  return hhea;
}

Uint8List _buildMaxp(TrueTypeFont font, int numGlyphs) {
  final maxp = Uint8List.fromList(font.tableData('maxp')!);
  if (maxp.length >= 6) {
    ByteData.sublistView(maxp).setUint16(4, numGlyphs);
  }
  return maxp;
}

/// `hmtx` com um par (avanço, lsb) por glifo.
///
/// Emitir métricas completas em vez de comprimir a cauda custa 4 bytes por
/// glifo e elimina a assimetria que mais dá errado ao ler `hmtx`.
Uint8List _buildHmtx(TrueTypeFont font, int numGlyphs) {
  final hmtx = ByteData(numGlyphs * 4);
  for (var gid = 0; gid < numGlyphs; gid++) {
    hmtx.setUint16(gid * 4, font.advanceWidthOf(gid).clamp(0, 0xFFFF));
    hmtx.setInt16(gid * 4 + 2, font.leftSideBearingOf(gid).clamp(-32768, 32767));
  }
  return hmtx.buffer.asUint8List();
}

// ---------------------------------------------------------------------------
// Montagem do arquivo
// ---------------------------------------------------------------------------

/// Escreve o sfnt: cabeçalho, diretório ordenado por tag e as tabelas.
Uint8List _assemble(Map<String, Uint8List> tables) {
  final names = tables.keys.toList()..sort();
  final numTables = names.length;

  // searchRange e afins descrevem uma busca binária no diretório. Nenhum
  // leitor moderno depende deles, mas validadores reclamam quando erram.
  var entrySelector = 0;
  while ((1 << (entrySelector + 1)) <= numTables) {
    entrySelector++;
  }
  final searchRange = (1 << entrySelector) * 16;
  final rangeShift = numTables * 16 - searchRange;

  final headerSize = 12 + numTables * 16;
  var offset = headerSize;
  final offsets = <String, int>{};
  final lengths = <String, int>{};
  for (final name in names) {
    offsets[name] = offset;
    lengths[name] = tables[name]!.length;
    offset += _align4(tables[name]!.length);
  }

  final output = Uint8List(offset);
  final view = ByteData.sublistView(output);
  view.setUint32(0, 0x00010000); // sfnt version: TrueType com contornos glyf
  view.setUint16(4, numTables);
  view.setUint16(6, searchRange);
  view.setUint16(8, entrySelector);
  view.setUint16(10, rangeShift);

  var record = 12;
  for (final name in names) {
    final data = tables[name]!;
    output.setRange(offsets[name]!, offsets[name]! + data.length, data);

    output.setRange(record, record + 4, name.codeUnits);
    view.setUint32(record + 4, _checksum(output, offsets[name]!, data.length));
    view.setUint32(record + 8, offsets[name]!);
    view.setUint32(record + 12, lengths[name]!);
    record += 16;
  }

  // checkSumAdjustment: 0xB1B0AFBA menos a soma do arquivo inteiro, com o
  // campo zerado. É a assinatura que valida a fonte como um todo.
  final headOffset = offsets['head'];
  if (headOffset != null) {
    final total = _checksum(output, 0, output.length);
    view.setUint32(headOffset + 8, (0xB1B0AFBA - total) & 0xFFFFFFFF);
  }
  return output;
}

int _align4(int value) => (value + 3) & ~3;

/// Soma de 32 bits big-endian sobre [length] bytes a partir de [start],
/// tratando o resto como zeros (é o que a especificação manda).
int _checksum(Uint8List data, int start, int length) {
  var sum = 0;
  final end = start + _align4(length);
  for (var i = start; i < end; i += 4) {
    var word = 0;
    for (var b = 0; b < 4; b++) {
      final index = i + b;
      word = (word << 8) | (index < data.length && index < start + length
          ? data[index]
          : 0);
    }
    sum = (sum + word) & 0xFFFFFFFF;
  }
  return sum;
}
