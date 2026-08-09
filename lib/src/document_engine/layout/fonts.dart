/// Fontes embutidas no layout (Fase 5 — CID no PageGraph).
///
/// A REGRA da arquitetura: uma única autoridade de medição. Quando a
/// aplicação fornece faces TrueType/OpenType, o COMPOSER mede com a `hmtx`
/// real da face (via [TrueTypeFont]) e o RENDERER embute a mesma face como
/// CID/Identity-H com subsetting — a linha quebra no mesmo lugar nas duas
/// saídas e acentos/travessões saem perfeitos (nada de `?` do WinAnsi).
/// Sem faces, o par cai no padrão standard-14 + FontMetrics embarcadas.
library;

import 'dart:typed_data';

import '../../office/document/fonts/font_registry.dart';
import '../../office/document/fonts/truetype.dart';

/// Codificador de texto→hex CID (o `encodeText` da fonte embutida).
typedef EmbeddedCidFontEncoder = String Function(String text);

/// Um pedaço do array TJ: a string hex e o ajuste (milésimos de em) que a
/// SEGUE — 0 quando não há kerning depois.
class ShapedPiece {
  const ShapedPiece(this.hex, this.adjustThousandths);

  final String hex;
  final int adjustThousandths;
}

/// Uma face fornecida pela aplicação (o pacote não faz rede nem carrega
/// arquivos: os bytes chegam de fora, como no exportador linear).
class LayoutFontFace {
  LayoutFontFace(
    this.family,
    this.bytes, {
    this.bold = false,
    this.italic = false,
  });

  final String family;
  final Uint8List bytes;
  final bool bold;
  final bool italic;

  /// Parse preguiçoso e único — o composer mede muitas vezes.
  late final TrueTypeFont font = TrueTypeFont.parse(bytes);

  double measureWidthPt(String text, double sizePt) {
    var total = 0.0;
    int? previous;
    for (final rune in text.runes) {
      total += font.advanceWidthOfChar(rune);
      if (previous != null) {
        total += font.kerningBetweenChars(previous, rune);
      }
      previous = rune;
    }
    return total * sizePt / 1000;
  }

  /// Shaping para o PDF: corre o texto acumulando runs e emitindo o ajuste
  /// de kerning ENTRE eles — vira o array TJ (`[<hex> adj <hex>] TJ`).
  /// O ajuste TJ é em milésimos de em e POSITIVO move para a ESQUERDA,
  /// então o valor emitido é `-kern`.
  List<ShapedPiece> shapeForTJ(String text, EmbeddedCidFontEncoder encode) {
    final pieces = <ShapedPiece>[];
    final runes = text.runes.toList();
    final buffer = StringBuffer();
    for (var i = 0; i < runes.length; i++) {
      buffer.write(String.fromCharCode(runes[i]));
      final next = i + 1 < runes.length ? runes[i + 1] : null;
      final kern = next == null ? 0 : font.kerningBetweenChars(runes[i], next);
      if (kern != 0) {
        pieces.add(ShapedPiece(encode(buffer.toString()), -kern));
        buffer.clear();
      }
    }
    if (buffer.isNotEmpty) {
      pieces.add(ShapedPiece(encode(buffer.toString()), 0));
    }
    return pieces;
  }

  double ascentPt(double sizePt) => font.ascender * sizePt / font.unitsPerEm;

  double descentPt(double sizePt) => -font.descender * sizePt / font.unitsPerEm;

  double lineGapPt(double sizePt) => font.lineGap * sizePt / font.unitsPerEm;
}

/// Resolve a face para (família, bold, itálico) — a mesma política do
/// exportador linear: casamento exato, senão a regular da família (o PDF
/// sintetiza menos que o browser, então a regular é o fallback honesto).
class LayoutFontSet {
  const LayoutFontSet(this.faces);

  final List<LayoutFontFace> faces;

  bool get isEmpty => faces.isEmpty;

  LayoutFontFace? faceFor(String family,
      {bool bold = false, bool italic = false}) {
    final candidates = <String>[
      family,
      ...FontRegistry.instance.fallbackFamilyStack(family),
    ];
    final visited = <String>{};
    for (final candidate in candidates) {
      final key = candidate.trim().toLowerCase();
      if (!visited.add(key)) continue;
      final face = _faceForExactFamily(key, bold: bold, italic: italic);
      if (face != null) return face;
    }
    return null;
  }

  /// Exact-family lookup kept separate so an OOXML alias is tried only after
  /// every requested weight/style fallback for the original family.
  LayoutFontFace? _faceForExactFamily(String key,
      {required bool bold, required bool italic}) {
    LayoutFontFace? regular;
    for (final face in faces) {
      if (face.family.trim().toLowerCase() != key) continue;
      if (face.bold == bold && face.italic == italic) return face;
      if (!face.bold && !face.italic) regular = face;
    }
    return regular;
  }
}
