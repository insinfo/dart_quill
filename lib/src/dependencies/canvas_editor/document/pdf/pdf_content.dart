import 'pdf_writer.dart' show pdfFormatNumber, escapePdfString;

/// Builder de content stream PDF que recebe coordenadas do canvas do editor
/// (px CSS, origem no topo-esquerdo, já multiplicadas pelo zoom) e converte
/// para o espaço PDF (pt, origem embaixo-esquerda) com o fator [k].
///
/// Mantém estado de fonte/cor para evitar operadores redundantes; o texto sai
/// como `Tj` com WinAnsiEncoding — selecionável e pesquisável no viewer.
class PdfContentBuilder {
  PdfContentBuilder({required this.pageHeightPt, required this.k});

  /// Altura da página em pontos (para inverter o eixo Y).
  final double pageHeightPt;

  /// Fator px-do-canvas → pt (tipicamente `0.75 / zoom`).
  final double k;

  final StringBuffer _ops = StringBuffer();

  String? _fillColor;
  String? _strokeColor;
  double? _lineWidth;
  bool _dashed = false;

  double _x(double x) => x * k;
  double _y(double y) => pageHeightPt - y * k;
  String _n(double v) => pdfFormatNumber(v);

  void _setFill(String cssColor) {
    final String rgb = _cssColorToPdf(cssColor);
    if (_fillColor != rgb) {
      _fillColor = rgb;
      _ops.writeln('$rgb rg');
    }
  }

  void _setStroke(String cssColor) {
    final String rgb = _cssColorToPdf(cssColor);
    if (_strokeColor != rgb) {
      _strokeColor = rgb;
      _ops.writeln('$rgb RG');
    }
  }

  void _setLineWidth(double widthPx) {
    final double pt = widthPx * k;
    if (_lineWidth != pt) {
      _lineWidth = pt;
      _ops.writeln('${_n(pt)} w');
    }
  }

  void _setDash(List<double>? dashPx) {
    final bool wantDash = dashPx != null && dashPx.isNotEmpty;
    if (wantDash) {
      final String pattern =
          dashPx.map((double d) => _n(d * k)).join(' ');
      _ops.writeln('[$pattern] 0 d');
      _dashed = true;
    } else if (_dashed) {
      _ops.writeln('[] 0 d');
      _dashed = false;
    }
  }

  /// Texto na baseline ([x],[baselineY]) em px do canvas. [fontResource] é o
  /// nome do recurso (`/F1`), [sizePx] o tamanho em px sem zoom já aplicado ao
  /// k... isto é: o tamanho em px do canvas (com zoom), convertido aqui.
  void text({
    required String fontResource,
    required double sizePx,
    required String winAnsiText,
    required double x,
    required double baselineY,
    String color = '#000000',
  }) {
    if (winAnsiText.isEmpty) return;
    _setFill(color);
    _ops
      ..writeln('BT')
      ..writeln('$fontResource ${_n(sizePx * k)} Tf')
      ..writeln('${_n(_x(x))} ${_n(_y(baselineY))} Td')
      ..writeln('(${escapePdfString(winAnsiText)}) Tj')
      ..writeln('ET');
  }

  /// Retângulo preenchido; coordenadas/tamanho em px do canvas.
  void fillRect(double x, double y, double w, double h, String cssColor) {
    if (w <= 0 || h <= 0) return;
    _setFill(cssColor);
    _ops.writeln(
        '${_n(_x(x))} ${_n(_y(y + h))} ${_n(w * k)} ${_n(h * k)} re f');
  }

  /// Linha entre dois pontos em px do canvas.
  void strokeLine(
    double x1,
    double y1,
    double x2,
    double y2, {
    String color = '#000000',
    double widthPx = 1,
    List<double>? dashPx,
  }) {
    _setStroke(color);
    _setLineWidth(widthPx);
    _setDash(dashPx);
    _ops
      ..writeln('${_n(_x(x1))} ${_n(_y(y1))} m')
      ..writeln('${_n(_x(x2))} ${_n(_y(y2))} l S');
  }

  /// Contorno de retângulo em px do canvas.
  void strokeRect(
    double x,
    double y,
    double w,
    double h, {
    String color = '#000000',
    double widthPx = 1,
    List<double>? dashPx,
  }) {
    _setStroke(color);
    _setLineWidth(widthPx);
    _setDash(dashPx);
    _ops.writeln(
        '${_n(_x(x))} ${_n(_y(y + h))} ${_n(w * k)} ${_n(h * k)} re S');
  }

  /// Posiciona um XObject de imagem ([resourceName], ex.: `Im1`) no retângulo
  /// dado em px do canvas.
  void drawImage(
      String resourceName, double x, double y, double w, double h) {
    if (w <= 0 || h <= 0) return;
    _ops
      ..writeln('q')
      ..writeln('${_n(w * k)} 0 0 ${_n(h * k)} '
          '${_n(_x(x))} ${_n(_y(y + h))} cm')
      ..writeln('/$resourceName Do')
      ..writeln('Q');
  }

  /// Estado gráfico manual (para rotação de marca d'água etc.).
  void rawOp(String op) => _ops.writeln(op);

  /// Define cor de preenchimento para operadores emitidos via [rawOp].
  void setFillColor(String cssColor) => _setFill(cssColor);

  /// Define cor e espessura de traço para operadores emitidos via [rawOp].
  void setStrokeStyle(String cssColor, double widthPx) {
    _setStroke(cssColor);
    _setLineWidth(widthPx);
    _setDash(null);
  }

  /// Invalida o cache de estado (após `Q` restaurar o estado gráfico).
  void invalidateGraphicsState() {
    _fillColor = null;
    _strokeColor = null;
    _lineWidth = null;
    _dashed = false;
  }

  bool get isEmpty => _ops.isEmpty;

  List<int> build() => _ops.toString().codeUnits;
}

/// Converte cor CSS (`#rgb`, `#rrggbb`, `rgb()/rgba()`, nomes comuns) para o
/// triplo `r g b` PDF em 0..1.
String _cssColorToPdf(String css) {
  final String value = css.trim().toLowerCase();
  int r = 0, g = 0, b = 0;
  if (value.startsWith('#')) {
    final String hex = value.substring(1);
    if (hex.length == 3) {
      r = int.parse(hex[0] * 2, radix: 16);
      g = int.parse(hex[1] * 2, radix: 16);
      b = int.parse(hex[2] * 2, radix: 16);
    } else if (hex.length >= 6) {
      r = int.parse(hex.substring(0, 2), radix: 16);
      g = int.parse(hex.substring(2, 4), radix: 16);
      b = int.parse(hex.substring(4, 6), radix: 16);
    }
  } else if (value.startsWith('rgb')) {
    final List<String> parts = value
        .substring(value.indexOf('(') + 1, value.contains(')')
            ? value.indexOf(')')
            : value.length)
        .split(',');
    if (parts.length >= 3) {
      r = double.tryParse(parts[0].trim())?.round() ?? 0;
      g = double.tryParse(parts[1].trim())?.round() ?? 0;
      b = double.tryParse(parts[2].trim())?.round() ?? 0;
    }
  } else {
    const Map<String, List<int>> named = <String, List<int>>{
      'black': <int>[0, 0, 0],
      'white': <int>[255, 255, 255],
      'red': <int>[255, 0, 0],
      'green': <int>[0, 128, 0],
      'blue': <int>[0, 0, 255],
      'yellow': <int>[255, 255, 0],
      'gray': <int>[128, 128, 128],
      'grey': <int>[128, 128, 128],
    };
    final List<int>? rgb = named[value];
    if (rgb != null) {
      r = rgb[0];
      g = rgb[1];
      b = rgb[2];
    }
  }
  String c(int v) => pdfFormatNumber(v / 255);
  return '${c(r)} ${c(g)} ${c(b)}';
}

// ── Fontes standard-14 e WinAnsi ────────────────────────────────────────

/// Resolve a família CSS usada pelo editor para uma fonte standard-14
/// metricamente próxima (Arial→Helvetica, Times New Roman→Times etc.).
String standardFontFor({String? family, bool bold = false, bool italic = false}) {
  final String f = (family ?? '').toLowerCase();
  final bool isMono = f.contains('courier') || f.contains('mono') ||
      f.contains('consolas');
  final bool isSerif = !isMono &&
      (f.contains('times') ||
          f.contains('georgia') ||
          f.contains('garamond') ||
          f.contains('cambria') ||
          f.contains('book') ||
          (f.contains('serif') && !f.contains('sans')));
  if (isMono) {
    if (bold && italic) return 'Courier-BoldOblique';
    if (bold) return 'Courier-Bold';
    if (italic) return 'Courier-Oblique';
    return 'Courier';
  }
  if (isSerif) {
    if (bold && italic) return 'Times-BoldItalic';
    if (bold) return 'Times-Bold';
    if (italic) return 'Times-Italic';
    return 'Times-Roman';
  }
  if (bold && italic) return 'Helvetica-BoldOblique';
  if (bold) return 'Helvetica-Bold';
  if (italic) return 'Helvetica-Oblique';
  return 'Helvetica';
}

const Map<int, int> _winAnsiSpecials = <int, int>{
  0x20ac: 0x80, 0x201a: 0x82, 0x0192: 0x83, 0x201e: 0x84, 0x2026: 0x85,
  0x2020: 0x86, 0x2021: 0x87, 0x02c6: 0x88, 0x2030: 0x89, 0x0160: 0x8a,
  0x2039: 0x8b, 0x0152: 0x8c, 0x017d: 0x8e, 0x2018: 0x91, 0x2019: 0x92,
  0x201c: 0x93, 0x201d: 0x94, 0x2022: 0x95, 0x2013: 0x96, 0x2014: 0x97,
  0x02dc: 0x98, 0x2122: 0x99, 0x0161: 0x9a, 0x203a: 0x9b, 0x0153: 0x9c,
  0x017e: 0x9e, 0x0178: 0x9f,
};

/// Codifica [text] em WinAnsi (cp1252). Codepoints sem mapeamento viram
/// aproximações ASCII ou são omitidos (nunca lançam).
String encodeWinAnsi(String text) {
  final StringBuffer out = StringBuffer();
  for (final int cp in text.runes) {
    if (cp == 0x200b || cp == 0xfeff || cp == 0x0) continue; // zero-width
    if (cp >= 0x20 && cp <= 0x7e) {
      out.writeCharCode(cp);
    } else if (cp >= 0xa0 && cp <= 0xff) {
      out.writeCharCode(cp);
    } else if (_winAnsiSpecials.containsKey(cp)) {
      out.writeCharCode(_winAnsiSpecials[cp]!);
    } else if (cp == 0x2028 || cp == 0x2029 || cp == 0x0a || cp == 0x0d) {
      // quebras não têm glifo
    } else if (cp == 0x00a0 || cp == 0x2007 || cp == 0x202f) {
      out.writeCharCode(0x20);
    } else if (cp == 0x2212) {
      out.writeCharCode(0x2d); // sinal de menos
    } else if (cp == 0x2713 || cp == 0x2714) {
      out.writeCharCode(0x76); // ✓ → v (aproximação)
    } else {
      out.writeCharCode(0x3f); // '?'
    }
  }
  return out.toString();
}
