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

import '../../office/document/fonts/truetype.dart';

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
    for (final rune in text.runes) {
      total += font.advanceWidthOfChar(rune);
    }
    return total * sizePt / 1000;
  }

  double ascentPt(double sizePt) =>
      font.ascender * sizePt / font.unitsPerEm;

  double descentPt(double sizePt) =>
      -font.descender * sizePt / font.unitsPerEm;
}

/// Resolve a face para (família, bold, itálico) — a mesma política do
/// exportador linear: casamento exato, senão a regular da família (o PDF
/// sintetiza menos que o browser, então a regular é o fallback honesto).
class LayoutFontSet {
  LayoutFontSet(this.faces);

  final List<LayoutFontFace> faces;

  bool get isEmpty => faces.isEmpty;

  LayoutFontFace? faceFor(String family, {bool bold = false, bool italic = false}) {
    final key = family.trim().toLowerCase();
    LayoutFontFace? regular;
    for (final face in faces) {
      if (face.family.trim().toLowerCase() != key) continue;
      if (face.bold == bold && face.italic == italic) return face;
      if (!face.bold && !face.italic) regular = face;
    }
    return regular;
  }
}
