/// Conversões de unidades OOXML → unidades do editor (px @96dpi)
/// (roteiro_editor_profissional, F2.2: 1 twip = 1/15 px).
class Units {
  Units._();

  /// Twips (1/20 pt) → px @96dpi. 11906 twips = 793,7 px (A4).
  static double twipToPx(num twips) => twips / 15.0;

  /// Half-points (w:sz) → px. 24 half-points = 12pt = 16 px.
  static double halfPointToPx(num halfPoints) => halfPoints * 2.0 / 3.0;

  /// Pontos → px.
  static double pointToPx(num points) => points * 4.0 / 3.0;

  /// Oitavos de ponto (w:sz de bordas) → px.
  static double eighthPointToPx(num eighths) => eighths / 6.0;

  /// EMU (drawings) → px. 914400 EMU = 1 in = 96 px.
  static double emuToPx(num emu) => emu / 9525.0;
}
