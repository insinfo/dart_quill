/// Embute uma fonte TrueType no PDF como fonte CID (`Type0`/`Identity-H`).
///
/// É o que permite ao documento sair na fonte de verdade — Inter, Arial,
/// Calibri — em vez das 14 fontes padrão, e é o que faz um `ç`, um `ã` ou um
/// travessão sobreviverem: com `WinAnsiEncoding` tudo fora do cp1252 vira `?`.
///
/// Estrutura montada (PDF 32000-1 §9.7):
///
/// ```
/// /Type0            → a fonte que o content stream referencia
///   /Encoding /Identity-H   → o texto é uma sequência de CIDs de 2 bytes
///   /DescendantFonts [ /CIDFontType2 ]
///                           → /W com as larguras, /CIDToGIDMap /Identity
///     /FontDescriptor       → métricas e permissões
///       /FontFile2          → o subconjunto TrueType, comprimido
///   /ToUnicode              → CMap CID → Unicode
/// ```
///
/// O `/ToUnicode` não muda um pixel do desenho e é o que decide se copiar
/// texto do PDF assinado devolve as palavras ou lixo. Sem ele o documento é
/// visualmente perfeito e inútil para busca, leitor de tela e conferência.
library;

import 'dart:convert';
import 'dart:typed_data';

import '../fonts/truetype.dart';
import '../fonts/truetype_subset.dart';
import 'pdf_writer.dart';

/// Uma fonte pronta para ser usada no content stream.
class EmbeddedCidFont {
  const EmbeddedCidFont({
    required this.resourceName,
    required this.objectId,
    required this.font,
    required this.subset,
    required this.glyphOfRune,
  });

  /// Nome do recurso na página, ex.: `/TT1`.
  final String resourceName;

  /// Objeto do `/Type0`.
  final int objectId;

  /// A fonte de origem, para medir texto.
  final TrueTypeFont font;

  final TrueTypeSubset subset;

  /// Caractere → glifo, já filtrado pelo que a fonte cobre.
  final Map<int, int> glyphOfRune;

  /// Codifica [text] como a string hexadecimal de CIDs que o `Identity-H`
  /// espera.
  ///
  /// Um caractere sem glifo vira `.notdef` (0) — visível como caixa vazia,
  /// que é honesto: melhor do que sumir e melhor do que quebrar o desenho.
  String encodeText(String text) {
    final buffer = StringBuffer('<');
    for (final rune in text.runes) {
      final glyph = glyphOfRune[rune] ?? font.glyphIdFor(rune);
      buffer.write(glyph.toRadixString(16).padLeft(4, '0'));
    }
    buffer.write('>');
    return buffer.toString();
  }

  /// Largura de [text] em pontos, para [fontSize].
  double measure(String text, double fontSize) {
    var total = 0.0;
    for (final rune in text.runes) {
      total += font.advanceWidthOfChar(rune);
    }
    return total * fontSize / 1000;
  }
}

/// Embute [fontBytes] recortada para [usedRunes] e devolve a fonte utilizável.
///
/// [resourceName] tem de ser único na página (`/TT1`, `/TT2`, …).
EmbeddedCidFont embedCidFont(
  PdfWriter writer,
  Uint8List fontBytes, {
  required Iterable<int> usedRunes,
  required String resourceName,
}) {
  final font = TrueTypeFont.parse(fontBytes);
  return embedCidFontFromParsed(
    writer,
    font,
    usedRunes: usedRunes,
    resourceName: resourceName,
  );
}

/// Igual a [embedCidFont], reaproveitando uma fonte já parseada.
EmbeddedCidFont embedCidFontFromParsed(
  PdfWriter writer,
  TrueTypeFont font, {
  required Iterable<int> usedRunes,
  required String resourceName,
}) {
  if (font.embeddingPermission == EmbeddingPermission.restricted) {
    throw TrueTypeException(
        'a fonte "${font.postScriptName}" declara em OS/2.fsType que não pode '
        'ser embutida');
  }

  final glyphOfRune = <int, int>{};
  for (final rune in usedRunes) {
    final glyph = font.glyphIdFor(rune);
    if (glyph != 0) glyphOfRune[rune] = glyph;
  }

  final subset = subsetTrueType(font, glyphOfRune.values);
  final baseName = '${_subsetTag(subset.glyphIds)}+${_sanitizeName(font.postScriptName)}';
  final scale = 1000 / font.unitsPerEm;
  int scaled(num value) => (value * scale).round();

  // O programa da fonte. /Length1 é o tamanho descomprimido, que alguns
  // leitores exigem para TrueType.
  final fontFileId = writer.addStream(
    subset.bytes,
    extraEntries: '/Length1 ${subset.bytes.length}',
  );

  final descriptorId = writer.addDict(
    '<< /Type /FontDescriptor '
    '/FontName /$baseName '
    '/Flags ${_flags(font)} '
    '/FontBBox [${scaled(font.boundingBox.xMin)} ${scaled(font.boundingBox.yMin)} '
    '${scaled(font.boundingBox.xMax)} ${scaled(font.boundingBox.yMax)}] '
    '/ItalicAngle ${_number(font.italicAngle)} '
    '/Ascent ${scaled(font.ascender)} '
    '/Descent ${scaled(font.descender)} '
    '/CapHeight ${scaled(font.capHeight)} '
    '/StemV ${_stemV(font)} '
    '/FontFile2 $fontFileId 0 R >>',
  );

  final descendantId = writer.addDict(
    '<< /Type /Font /Subtype /CIDFontType2 '
    '/BaseFont /$baseName '
    '/CIDSystemInfo << /Registry (Adobe) /Ordering (Identity) /Supplement 0 >> '
    '/FontDescriptor $descriptorId 0 R '
    '/DW 1000 '
    '/W ${_widthsArray(font, subset.glyphIds, scale)} '
    // Identity: o CID É o glifo. É o que dispensa um CIDToGIDMap e o que o
    // subsetter garante ao preservar os identificadores.
    '/CIDToGIDMap /Identity >>',
  );

  final toUnicodeId = writer.addStream(
    latin1.encode(_toUnicodeCMap(glyphOfRune)),
  );

  final fontId = writer.addDict(
    '<< /Type /Font /Subtype /Type0 '
    '/BaseFont /$baseName '
    '/Encoding /Identity-H '
    '/DescendantFonts [$descendantId 0 R] '
    '/ToUnicode $toUnicodeId 0 R >>',
  );

  writer.registerFontResource(resourceName, fontId);

  return EmbeddedCidFont(
    resourceName: resourceName,
    objectId: fontId,
    font: font,
    subset: subset,
    glyphOfRune: glyphOfRune,
  );
}

/// `/W` no formato `[ cid [w1 w2 …] … ]`, agrupando glifos consecutivos.
///
/// Só os glifos do subconjunto entram: `/DW 1000` cobre o resto.
String _widthsArray(TrueTypeFont font, Set<int> glyphIds, double scale) {
  final sorted = glyphIds.toList()..sort();
  final buffer = StringBuffer('[');
  var index = 0;
  while (index < sorted.length) {
    final start = sorted[index];
    final widths = <int>[];
    var gid = start;
    while (index < sorted.length && sorted[index] == gid) {
      widths.add((font.advanceWidthOf(gid) * scale).round());
      index++;
      gid++;
    }
    buffer.write('$start [${widths.join(' ')}]');
    if (index < sorted.length) buffer.write(' ');
  }
  buffer.write(']');
  return buffer.toString();
}

/// CMap que devolve o texto a quem copia, busca ou lê o PDF em voz alta.
String _toUnicodeCMap(Map<int, int> glyphOfRune) {
  // Um glifo pode servir a mais de um caractere; o primeiro ganha, que é o
  // comportamento usual e não tem resposta melhor.
  final byGlyph = <int, int>{};
  for (final entry in glyphOfRune.entries) {
    byGlyph.putIfAbsent(entry.value, () => entry.key);
  }
  final entries = byGlyph.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));

  final buffer = StringBuffer()
    ..writeln('/CIDInit /ProcSet findresource begin')
    ..writeln('12 dict begin')
    ..writeln('begincmap')
    ..writeln('/CIDSystemInfo << /Registry (Adobe) /Ordering (UCS) '
        '/Supplement 0 >> def')
    ..writeln('/CMapName /Adobe-Identity-UCS def')
    ..writeln('/CMapType 2 def')
    ..writeln('1 begincodespacerange')
    ..writeln('<0000> <FFFF>')
    ..writeln('endcodespacerange');

  // O formato limita cada bloco a 100 entradas.
  for (var start = 0; start < entries.length; start += 100) {
    final chunk = entries.skip(start).take(100).toList();
    buffer.writeln('${chunk.length} beginbfchar');
    for (final entry in chunk) {
      buffer.writeln('<${entry.key.toRadixString(16).padLeft(4, '0')}> '
          '<${_utf16BeHex(entry.value)}>');
    }
    buffer.writeln('endbfchar');
  }

  buffer
    ..writeln('endcmap')
    ..writeln('CMapName currentdict /CMap defineresource pop')
    ..writeln('end')
    ..writeln('end');
  return buffer.toString();
}

/// Um ponto de código como UTF-16BE em hexadecimal — com par substituto
/// quando estiver fora do BMP, que é o que a CMap exige.
String _utf16BeHex(int rune) {
  if (rune <= 0xFFFF) return rune.toRadixString(16).padLeft(4, '0');
  final value = rune - 0x10000;
  final high = 0xD800 + (value >> 10);
  final low = 0xDC00 + (value & 0x3FF);
  return '${high.toRadixString(16).padLeft(4, '0')}'
      '${low.toRadixString(16).padLeft(4, '0')}';
}

/// Prefixo de 6 letras maiúsculas que marca a fonte como subconjunto.
///
/// **Derivado do conjunto de glifos**, não aleatório: o mesmo documento tem de
/// gerar os mesmos bytes, ou o hash SHA-256 do PDF assinado muda a cada
/// execução.
String _subsetTag(Set<int> glyphIds) {
  var hash = 0x811C9DC5; // FNV-1a de 32 bits
  for (final id in glyphIds.toList()..sort()) {
    hash ^= id & 0xFF;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
    hash ^= (id >> 8) & 0xFF;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  final buffer = StringBuffer();
  for (var i = 0; i < 6; i++) {
    buffer.writeCharCode(0x41 + (hash % 26));
    hash ~/= 26;
  }
  return buffer.toString();
}

/// `/Flags` do descritor (PDF 32000-1, tabela 123).
int _flags(TrueTypeFont font) {
  var flags = 0;
  if (font.isFixedPitch) flags |= 1 << 0; // FixedPitch
  flags |= 1 << 2; // Symbolic: o Identity-H não usa encoding padrão
  if (font.isItalic) flags |= 1 << 6; // Italic
  if (font.weightClass >= 600) flags |= 1 << 18; // ForceBold
  return flags;
}

/// Espessura vertical do traço. Não há campo para isso na fonte; a
/// aproximação a partir do peso é a prática comum, e o valor só afeta a
/// substituição quando a fonte **não** está embutida — que não é o caso aqui.
int _stemV(TrueTypeFont font) =>
    (50 + (font.weightClass * font.weightClass) / 10000).round();

/// Nomes do PDF não aceitam espaço nem delimitador.
String _sanitizeName(String name) {
  final cleaned = name.replaceAll(RegExp(r'[\s()<>\[\]{}/%#]'), '');
  return cleaned.isEmpty ? 'Embedded' : cleaned;
}

String _number(double value) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value.toStringAsFixed(2);
}
