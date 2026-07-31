/// Desenha um SVG dentro de um PDF, como operadores de caminho.
///
/// **Escopo deliberado.** Não é um renderizador de SVG genérico: cobre o que
/// os brasões e cabeçalhos de documento usam — caminhos, cores sólidas,
/// `fill-rule`, grupos, `viewBox` e gradiente linear. Tudo que ficar fora é
/// **registrado em [SvgRenderResult.warnings]**, nunca descartado em silêncio:
/// um cabeçalho que some sem aviso é o defeito que ninguém percebe até o
/// documento estar assinado.
///
/// O que não é suportado hoje, e é reportado: `transform`, `clipPath`,
/// `stroke`, `<image>`, filtros, gradiente radial e `<text>` (este último
/// depende das fontes embutidas — P1/P7.3 do plano).
library;

import 'dart:math' as math;

import '../../xml/dom.dart';
import 'svg_path.dart';

/// Um SVG interpretado, pronto para ser desenhado.
class SvgPicture {
  const SvgPicture({
    required this.width,
    required this.height,
    required this.viewBox,
    required this.shapes,
    required this.warnings,
  });

  /// Dimensões declaradas no elemento raiz, em unidades de usuário.
  final double width;
  final double height;

  /// `[minX, minY, width, height]` — o sistema de coordenadas do desenho.
  final List<double> viewBox;

  final List<SvgShape> shapes;

  /// O que o arquivo pede e este renderizador não faz.
  final List<String> warnings;

  double get aspectRatio =>
      viewBox[3] == 0 ? 1 : viewBox[2] / viewBox[3];
}

/// Uma figura pronta para virar operadores de PDF.
class SvgShape {
  const SvgShape({
    required this.segments,
    required this.fill,
    required this.evenOdd,
    required this.opacity,
  });

  final List<SvgPathSegment> segments;

  /// Cor de preenchimento `#rrggbb`, ou null para não preencher.
  final String? fill;

  /// `fill-rule: evenodd` (o PDF chama de `f*`).
  final bool evenOdd;

  final double opacity;
}

/// Resultado de desenhar: os operadores e o que não coube.
class SvgRenderResult {
  const SvgRenderResult(this.operators, this.warnings);

  final String operators;
  final List<String> warnings;
}

/// Interpreta [source].
///
/// Lança [FormatException] só quando o arquivo não é um SVG; um SVG válido com
/// recursos não suportados devolve o que dá para desenhar mais os avisos.
SvgPicture parseSvg(String source) {
  final document = XmlDocument.parse(source);
  final root = document.rootElement;
  if (root.localName != 'svg') {
    throw FormatException('elemento raiz não é <svg>: <${root.localName}>');
  }

  final warnings = <String>[];
  final gradients = _collectGradients(root);

  final viewBox = _parseViewBox(root.getAttribute('viewBox'));
  final width = _parseLength(root.getAttribute('width')) ?? viewBox?[2] ?? 0;
  final height = _parseLength(root.getAttribute('height')) ?? viewBox?[3] ?? 0;

  final shapes = <SvgShape>[];
  _walk(root, const _SvgStyle(), shapes, warnings, gradients);

  return SvgPicture(
    width: width,
    height: height,
    viewBox: viewBox ?? <double>[0, 0, width, height],
    shapes: shapes,
    warnings: warnings,
  );
}

/// Emite os operadores que desenham [picture] no retângulo dado, em pontos.
///
/// [y] é a coordenada **do topo** do retângulo no espaço do PDF (origem no
/// canto inferior esquerdo), que é como o resto deste exportador raciocina.
SvgRenderResult renderSvgToPdfOperators(
  SvgPicture picture, {
  required double x,
  required double y,
  required double width,
  required double height,
}) {
  final buffer = StringBuffer();
  final box = picture.viewBox;
  final boxWidth = box[2] == 0 ? 1.0 : box[2];
  final boxHeight = box[3] == 0 ? 1.0 : box[3];

  // Preserva a proporção e centraliza — o equivalente ao
  // `preserveAspectRatio="xMidYMid meet"`, que é o padrão do SVG.
  final scale = math.min(width / boxWidth, height / boxHeight);
  final drawnWidth = boxWidth * scale;
  final drawnHeight = boxHeight * scale;
  final offsetX = x + (width - drawnWidth) / 2;
  final offsetY = y - (height - drawnHeight) / 2;

  buffer.writeln('q');
  // O eixo Y do SVG cresce para baixo e o do PDF para cima: a matriz inverte
  // a escala vertical e ancora no topo do retângulo.
  buffer.writeln('${_n(scale)} 0 0 ${_n(-scale)} '
      '${_n(offsetX - box[0] * scale)} ${_n(offsetY + box[1] * scale)} cm');

  String? currentFill;
  for (final shape in picture.shapes) {
    final fill = shape.fill;
    if (fill == null || shape.segments.isEmpty) continue;
    if (fill != currentFill) {
      final rgb = _hexToRgb(fill);
      buffer.writeln('${_n(rgb[0])} ${_n(rgb[1])} ${_n(rgb[2])} rg');
      currentFill = fill;
    }
    _writePath(buffer, shape.segments);
    buffer.writeln(shape.evenOdd ? 'f*' : 'f');
  }
  buffer.writeln('Q');

  return SvgRenderResult(buffer.toString(), picture.warnings);
}

void _writePath(StringBuffer buffer, List<SvgPathSegment> segments) {
  for (final segment in segments) {
    switch (segment) {
      case SvgMoveTo(:final x, :final y):
        buffer.writeln('${_n(x)} ${_n(y)} m');
      case SvgLineTo(:final x, :final y):
        buffer.writeln('${_n(x)} ${_n(y)} l');
      case SvgCubicTo(
          :final x1,
          :final y1,
          :final x2,
          :final y2,
          :final x,
          :final y
        ):
        buffer.writeln('${_n(x1)} ${_n(y1)} ${_n(x2)} ${_n(y2)} '
            '${_n(x)} ${_n(y)} c');
      case SvgClosePath():
        buffer.writeln('h');
    }
  }
}

// ---------------------------------------------------------------------------
// Travessia
// ---------------------------------------------------------------------------

/// Atributos herdados de `<g>` para os filhos.
class _SvgStyle {
  const _SvgStyle({
    this.fill = '#000000',
    this.evenOdd = false,
    this.opacity = 1,
  });

  final String? fill;
  final bool evenOdd;
  final double opacity;

  _SvgStyle inherit(XmlElement element, Map<String, String> gradients,
      List<String> warnings) {
    var nextFill = fill;
    final rawFill = element.getAttribute('fill') ?? _styleValue(element, 'fill');
    if (rawFill != null) {
      nextFill = _resolveFill(rawFill, gradients, warnings);
    }

    var nextEvenOdd = evenOdd;
    final rule = element.getAttribute('fill-rule') ??
        _styleValue(element, 'fill-rule');
    if (rule != null) nextEvenOdd = rule.trim() == 'evenodd';

    var nextOpacity = opacity;
    final rawOpacity = element.getAttribute('opacity') ??
        element.getAttribute('fill-opacity');
    if (rawOpacity != null) {
      nextOpacity = opacity * (double.tryParse(rawOpacity.trim()) ?? 1);
    }

    return _SvgStyle(
      fill: nextFill,
      evenOdd: nextEvenOdd,
      opacity: nextOpacity,
    );
  }
}

void _walk(
  XmlElement element,
  _SvgStyle inherited,
  List<SvgShape> shapes,
  List<String> warnings,
  Map<String, String> gradients,
) {
  for (final child in element.childElements) {
    final name = child.localName;

    if (child.getAttribute('transform') != null) {
      _warnOnce(warnings,
          '`transform` não é aplicado (elemento <$name>); o desenho pode sair '
          'fora de posição');
    }

    switch (name) {
      case 'g':
        _walk(child, inherited.inherit(child, gradients, warnings), shapes,
            warnings, gradients);
        break;

      case 'path':
        final style = inherited.inherit(child, gradients, warnings);
        final d = child.getAttribute('d');
        if (d == null || d.trim().isEmpty) break;
        shapes.add(SvgShape(
          segments: parseSvgPath(d),
          fill: style.fill,
          evenOdd: style.evenOdd,
          opacity: style.opacity,
        ));
        break;

      case 'rect':
        final style = inherited.inherit(child, gradients, warnings);
        final rx = _parseLength(child.getAttribute('x')) ?? 0;
        final ry = _parseLength(child.getAttribute('y')) ?? 0;
        final rw = _parseLength(child.getAttribute('width')) ?? 0;
        final rh = _parseLength(child.getAttribute('height')) ?? 0;
        if (rw <= 0 || rh <= 0) break;
        shapes.add(SvgShape(
          segments: <SvgPathSegment>[
            SvgMoveTo(rx, ry),
            SvgLineTo(rx + rw, ry),
            SvgLineTo(rx + rw, ry + rh),
            SvgLineTo(rx, ry + rh),
            const SvgClosePath(),
          ],
          fill: style.fill,
          evenOdd: style.evenOdd,
          opacity: style.opacity,
        ));
        break;

      case 'polygon':
      case 'polyline':
        final style = inherited.inherit(child, gradients, warnings);
        final points = _parsePoints(child.getAttribute('points'));
        if (points.length < 2) break;
        final segments = <SvgPathSegment>[
          SvgMoveTo(points.first.$1, points.first.$2),
          for (final point in points.skip(1)) SvgLineTo(point.$1, point.$2),
          if (name == 'polygon') const SvgClosePath(),
        ];
        shapes.add(SvgShape(
          segments: segments,
          fill: style.fill,
          evenOdd: style.evenOdd,
          opacity: style.opacity,
        ));
        break;

      case 'defs':
      case 'metadata':
      case 'title':
      case 'desc':
      case 'linearGradient':
      case 'radialGradient':
        break; // já coletados ou irrelevantes para o desenho

      case 'text':
        _warnOnce(warnings,
            '<text> ainda não é desenhado: depende da fonte embutida '
            '(P1/P7.3 do plano)');
        break;

      case 'image':
      case 'use':
      case 'clipPath':
      case 'mask':
      case 'filter':
        _warnOnce(warnings, '<$name> não é suportado');
        break;

      case 'circle':
      case 'ellipse':
      case 'line':
        _warnOnce(warnings, '<$name> ainda não é desenhado');
        break;

      default:
        _warnOnce(warnings, '<$name> desconhecido, ignorado');
    }
  }
}

void _warnOnce(List<String> warnings, String message) {
  if (!warnings.contains(message)) warnings.add(message);
}

// ---------------------------------------------------------------------------
// Cores, gradientes e medidas
// ---------------------------------------------------------------------------

/// Cor média de cada gradiente, por id.
///
/// Um gradiente vira **uma cor sólida**: a média das paradas, ponderada pelos
/// intervalos entre elas. Pintar de chapado é visivelmente diferente do
/// degradê, e por isso vai um aviso junto — mas é muito melhor que a
/// alternativa de não pintar nada, que apagaria a peça do brasão.
Map<String, String> _collectGradients(XmlElement root) {
  final result = <String, String>{};
  for (final gradient in root.descendantsNamed('linearGradient')) {
    final id = gradient.getAttribute('id');
    if (id == null) continue;
    final color = _averageStopColor(gradient);
    if (color != null) result[id] = color;
  }
  for (final gradient in root.descendantsNamed('radialGradient')) {
    final id = gradient.getAttribute('id');
    if (id == null) continue;
    final color = _averageStopColor(gradient);
    if (color != null) result[id] = color;
  }
  return result;
}

String? _averageStopColor(XmlElement gradient) {
  final stops = gradient.childrenNamed('stop').toList();
  if (stops.isEmpty) return null;

  var r = 0.0;
  var g = 0.0;
  var b = 0.0;
  var totalWeight = 0.0;
  for (var i = 0; i < stops.length; i++) {
    final color = _namedOrHexColor(stops[i].getAttribute('stop-color') ??
            _styleValue(stops[i], 'stop-color') ??
            '#000000') ??
        '#000000';
    final rgb = _hexToRgb(color);
    // Peso pela largura da faixa que a parada domina.
    final offset = double.tryParse(
            (stops[i].getAttribute('offset') ?? '0').replaceAll('%', '')) ??
        0;
    final next = i + 1 < stops.length
        ? (double.tryParse((stops[i + 1].getAttribute('offset') ?? '1')
                .replaceAll('%', '')) ??
            1)
        : 1.0;
    final weight = math.max(next - offset, 0.0001);
    r += rgb[0] * weight;
    g += rgb[1] * weight;
    b += rgb[2] * weight;
    totalWeight += weight;
  }
  if (totalWeight == 0) return null;
  int channel(double value) =>
      ((value / totalWeight) * 255).round().clamp(0, 255);
  return '#${channel(r).toRadixString(16).padLeft(2, '0')}'
      '${channel(g).toRadixString(16).padLeft(2, '0')}'
      '${channel(b).toRadixString(16).padLeft(2, '0')}';
}

String? _resolveFill(
    String raw, Map<String, String> gradients, List<String> warnings) {
  final value = raw.trim();
  if (value.isEmpty || value == 'none' || value == 'transparent') return null;

  if (value.startsWith('url(')) {
    final id = value
        .substring(4, value.length - (value.endsWith(')') ? 1 : 0))
        .replaceAll('#', '')
        .replaceAll('"', '')
        .replaceAll("'", '')
        .trim();
    final color = gradients[id];
    if (color != null) {
      _warnOnce(warnings,
          'gradiente "$id" foi aproximado por uma cor sólida (a média das '
          'paradas)');
      return color;
    }
    _warnOnce(warnings, 'referência de preenchimento não resolvida: $value');
    return null;
  }
  return _namedOrHexColor(value);
}

/// `#rgb`, `#rrggbb`, `rgb(r, g, b)` e as cores nomeadas que aparecem em
/// arquivo de editor gráfico.
String? _namedOrHexColor(String raw) {
  final value = raw.trim().toLowerCase();
  if (value.startsWith('#')) {
    final hex = value.substring(1);
    if (hex.length == 3) {
      return '#${hex[0]}${hex[0]}${hex[1]}${hex[1]}${hex[2]}${hex[2]}';
    }
    if (hex.length >= 6) return '#${hex.substring(0, 6)}';
    return null;
  }
  if (value.startsWith('rgb(')) {
    final parts = value
        .substring(4, value.length - (value.endsWith(')') ? 1 : 0))
        .split(',')
        .map((part) => int.tryParse(part.trim()) ?? 0)
        .toList();
    if (parts.length < 3) return null;
    return '#${parts.take(3).map((c) => c.clamp(0, 255).toRadixString(16).padLeft(2, '0')).join()}';
  }
  return _namedColors[value];
}

const Map<String, String> _namedColors = <String, String>{
  'black': '#000000',
  'white': '#ffffff',
  'red': '#ff0000',
  'green': '#008000',
  'blue': '#0000ff',
  'yellow': '#ffff00',
  'gray': '#808080',
  'grey': '#808080',
  'silver': '#c0c0c0',
  'maroon': '#800000',
  'olive': '#808000',
  'lime': '#00ff00',
  'aqua': '#00ffff',
  'cyan': '#00ffff',
  'teal': '#008080',
  'navy': '#000080',
  'fuchsia': '#ff00ff',
  'magenta': '#ff00ff',
  'purple': '#800080',
  'orange': '#ffa500',
  'gold': '#ffd700',
  'none': '',
};

List<double> _hexToRgb(String hex) {
  final value = hex.startsWith('#') ? hex.substring(1) : hex;
  if (value.length < 6) return <double>[0, 0, 0];
  return <double>[
    int.parse(value.substring(0, 2), radix: 16) / 255,
    int.parse(value.substring(2, 4), radix: 16) / 255,
    int.parse(value.substring(4, 6), radix: 16) / 255,
  ];
}

String? _styleValue(XmlElement element, String property) {
  final style = element.getAttribute('style');
  if (style == null) return null;
  for (final declaration in style.split(';')) {
    final colon = declaration.indexOf(':');
    if (colon <= 0) continue;
    if (declaration.substring(0, colon).trim().toLowerCase() == property) {
      return declaration.substring(colon + 1).trim();
    }
  }
  return null;
}

List<double>? _parseViewBox(String? raw) {
  if (raw == null) return null;
  final parts = raw
      .trim()
      .split(RegExp(r'[\s,]+'))
      .map(double.tryParse)
      .whereType<double>()
      .toList();
  return parts.length == 4 ? parts : null;
}

/// Aceita as unidades absolutas do SVG e devolve unidades de usuário.
double? _parseLength(String? raw) {
  if (raw == null) return null;
  final value = raw.trim().toLowerCase();
  final match = RegExp(r'^([-+]?[\d.]+)\s*([a-z%]*)$').firstMatch(value);
  if (match == null) return null;
  final number = double.tryParse(match.group(1)!);
  if (number == null) return null;
  switch (match.group(2)) {
    case '':
    case 'px':
      return number;
    case 'pt':
      return number * 96 / 72;
    case 'mm':
      return number * 96 / 25.4;
    case 'cm':
      return number * 96 / 2.54;
    case 'in':
      return number * 96;
    default:
      return number; // inclusive `%`, que sem contexto não dá para resolver
  }
}

List<(double, double)> _parsePoints(String? raw) {
  if (raw == null) return const [];
  final numbers = raw
      .trim()
      .split(RegExp(r'[\s,]+'))
      .map(double.tryParse)
      .whereType<double>()
      .toList();
  final points = <(double, double)>[];
  for (var i = 0; i + 1 < numbers.length; i += 2) {
    points.add((numbers[i], numbers[i + 1]));
  }
  return points;
}

/// Números no content stream: sem notação científica, que o PDF não aceita.
String _n(double value) {
  if (value.isNaN || value.isInfinite) return '0';
  final rounded = (value * 1000).round() / 1000;
  if (rounded == rounded.roundToDouble()) return rounded.toInt().toString();
  return rounded.toString();
}
