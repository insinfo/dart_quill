/// Parser do atributo `d` de um `<path>` SVG.
///
/// Produz os segmentos já em coordenadas **absolutas**, com arcos e curvas
/// quadráticas convertidos para cúbicas — que é a única curva que o PDF
/// desenha (`c`). Assim o renderizador só precisa saber emitir `m`, `l`, `c`
/// e `h`.
///
/// A gramática do `d` é mais folgada do que parece: vírgulas e espaços são
/// intercambiáveis, o sinal serve de separador (`10-5` são dois números),
/// `.5.5` são dois números, e um comando repetido pode omitir a letra
/// (`L 1 2 3 4` são dois segmentos). Cada uma dessas licenças aparece em
/// arquivo exportado de editor gráfico.
library;

import 'dart:math' as math;

/// Um segmento de caminho, sempre em coordenadas absolutas.
sealed class SvgPathSegment {
  const SvgPathSegment();
}

class SvgMoveTo extends SvgPathSegment {
  const SvgMoveTo(this.x, this.y);
  final double x;
  final double y;
}

class SvgLineTo extends SvgPathSegment {
  const SvgLineTo(this.x, this.y);
  final double x;
  final double y;
}

/// Curva cúbica de Bézier — a única forma de curva que o PDF conhece.
class SvgCubicTo extends SvgPathSegment {
  const SvgCubicTo(this.x1, this.y1, this.x2, this.y2, this.x, this.y);
  final double x1;
  final double y1;
  final double x2;
  final double y2;
  final double x;
  final double y;
}

class SvgClosePath extends SvgPathSegment {
  const SvgClosePath();
}

/// Interpreta [d] e devolve os segmentos absolutos.
///
/// Entrada inválida não lança: o que já foi entendido é devolvido. Um `d`
/// truncado no meio deve desenhar o que dá, não apagar o desenho inteiro.
List<SvgPathSegment> parseSvgPath(String d) {
  final tokens = _SvgPathTokenizer(d);
  final segments = <SvgPathSegment>[];

  var currentX = 0.0;
  var currentY = 0.0;
  var startX = 0.0;
  var startY = 0.0;
  // Último ponto de controle, para os comandos "suaves" (S/T).
  var lastCubicControlX = 0.0;
  var lastCubicControlY = 0.0;
  var lastQuadControlX = 0.0;
  var lastQuadControlY = 0.0;
  var lastCommand = '';

  String? command;
  while (true) {
    final next = tokens.peekCommand();
    if (next != null) {
      command = tokens.readCommand();
    } else if (command == null) {
      break;
    } else if (!tokens.hasNumber) {
      break;
    } else {
      // Comando repetido sem a letra. Depois de um `M`, os pares seguintes
      // são `L` (e `m` → `l`), que é a regra mais esquecida da gramática.
      if (command == 'M') command = 'L';
      if (command == 'm') command = 'l';
    }

    final current = command;
    final relative = current == current.toLowerCase();
    final upper = current.toUpperCase();

    double dx(double v) => relative ? currentX + v : v;
    double dy(double v) => relative ? currentY + v : v;

    switch (upper) {
      case 'M':
        final x = dx(tokens.readNumber());
        final y = dy(tokens.readNumber());
        segments.add(SvgMoveTo(x, y));
        currentX = startX = x;
        currentY = startY = y;
        break;

      case 'L':
        final x = dx(tokens.readNumber());
        final y = dy(tokens.readNumber());
        segments.add(SvgLineTo(x, y));
        currentX = x;
        currentY = y;
        break;

      case 'H':
        final x = dx(tokens.readNumber());
        segments.add(SvgLineTo(x, currentY));
        currentX = x;
        break;

      case 'V':
        final y = dy(tokens.readNumber());
        segments.add(SvgLineTo(currentX, y));
        currentY = y;
        break;

      case 'C':
        final x1 = dx(tokens.readNumber());
        final y1 = dy(tokens.readNumber());
        final x2 = dx(tokens.readNumber());
        final y2 = dy(tokens.readNumber());
        final x = dx(tokens.readNumber());
        final y = dy(tokens.readNumber());
        segments.add(SvgCubicTo(x1, y1, x2, y2, x, y));
        lastCubicControlX = x2;
        lastCubicControlY = y2;
        currentX = x;
        currentY = y;
        break;

      case 'S':
        // O primeiro controle é o reflexo do último — mas só quando o
        // comando anterior também era cúbico; senão é o ponto atual.
        final smooth = lastCommand == 'C' || lastCommand == 'S';
        final x1 = smooth ? 2 * currentX - lastCubicControlX : currentX;
        final y1 = smooth ? 2 * currentY - lastCubicControlY : currentY;
        final x2 = dx(tokens.readNumber());
        final y2 = dy(tokens.readNumber());
        final x = dx(tokens.readNumber());
        final y = dy(tokens.readNumber());
        segments.add(SvgCubicTo(x1, y1, x2, y2, x, y));
        lastCubicControlX = x2;
        lastCubicControlY = y2;
        currentX = x;
        currentY = y;
        break;

      case 'Q':
        final qx = dx(tokens.readNumber());
        final qy = dy(tokens.readNumber());
        final x = dx(tokens.readNumber());
        final y = dy(tokens.readNumber());
        segments.add(_quadToCubic(currentX, currentY, qx, qy, x, y));
        lastQuadControlX = qx;
        lastQuadControlY = qy;
        currentX = x;
        currentY = y;
        break;

      case 'T':
        final smooth = lastCommand == 'Q' || lastCommand == 'T';
        final qx = smooth ? 2 * currentX - lastQuadControlX : currentX;
        final qy = smooth ? 2 * currentY - lastQuadControlY : currentY;
        final x = dx(tokens.readNumber());
        final y = dy(tokens.readNumber());
        segments.add(_quadToCubic(currentX, currentY, qx, qy, x, y));
        lastQuadControlX = qx;
        lastQuadControlY = qy;
        currentX = x;
        currentY = y;
        break;

      case 'A':
        final rx = tokens.readNumber();
        final ry = tokens.readNumber();
        final rotation = tokens.readNumber();
        final largeArc = tokens.readFlag();
        final sweep = tokens.readFlag();
        final x = dx(tokens.readNumber());
        final y = dy(tokens.readNumber());
        segments.addAll(_arcToCubics(
          currentX,
          currentY,
          rx,
          ry,
          rotation,
          largeArc,
          sweep,
          x,
          y,
        ));
        currentX = x;
        currentY = y;
        break;

      case 'Z':
        segments.add(const SvgClosePath());
        currentX = startX;
        currentY = startY;
        break;

      default:
        // Comando desconhecido: consome o que houver e segue, em vez de
        // travar o desenho inteiro.
        tokens.skipNumbers();
    }

    lastCommand = upper;
    if (tokens.exhausted) break;
  }
  return segments;
}

/// Uma quadrática vira cúbica exatamente: os controles ficam a 2/3 do
/// caminho entre cada extremo e o controle original.
SvgCubicTo _quadToCubic(
  double x0,
  double y0,
  double qx,
  double qy,
  double x,
  double y,
) =>
    SvgCubicTo(
      x0 + 2 / 3 * (qx - x0),
      y0 + 2 / 3 * (qy - y0),
      x + 2 / 3 * (qx - x),
      y + 2 / 3 * (qy - y),
      x,
      y,
    );

/// Converte um arco elíptico em curvas cúbicas.
///
/// Segue a "conversão de parametrização de endpoint para centro" do apêndice
/// F.6 da especificação SVG, incluindo a correção de raio: um raio pequeno
/// demais para ligar os dois pontos é **ampliado**, não rejeitado.
List<SvgPathSegment> _arcToCubics(
  double x0,
  double y0,
  double rx,
  double ry,
  double rotationDegrees,
  bool largeArc,
  bool sweep,
  double x,
  double y,
) {
  if (rx == 0 || ry == 0) return [SvgLineTo(x, y)];
  rx = rx.abs();
  ry = ry.abs();

  final phi = rotationDegrees * math.pi / 180;
  final cosPhi = math.cos(phi);
  final sinPhi = math.sin(phi);

  final dx2 = (x0 - x) / 2;
  final dy2 = (y0 - y) / 2;
  final x1 = cosPhi * dx2 + sinPhi * dy2;
  final y1 = -sinPhi * dx2 + cosPhi * dy2;

  var rxSq = rx * rx;
  var rySq = ry * ry;
  final x1Sq = x1 * x1;
  final y1Sq = y1 * y1;

  final lambda = x1Sq / rxSq + y1Sq / rySq;
  if (lambda > 1) {
    final scale = math.sqrt(lambda);
    rx *= scale;
    ry *= scale;
    rxSq = rx * rx;
    rySq = ry * ry;
  }

  var factor = (rxSq * rySq - rxSq * y1Sq - rySq * x1Sq) /
      (rxSq * y1Sq + rySq * x1Sq);
  if (factor < 0) factor = 0;
  var coefficient = math.sqrt(factor);
  if (largeArc == sweep) coefficient = -coefficient;

  final cx1 = coefficient * rx * y1 / ry;
  final cy1 = -coefficient * ry * x1 / rx;
  final cx = cosPhi * cx1 - sinPhi * cy1 + (x0 + x) / 2;
  final cy = sinPhi * cx1 + cosPhi * cy1 + (y0 + y) / 2;

  double angleOf(double ux, double uy) {
    final angle = math.atan2(uy, ux);
    return angle;
  }

  final theta1 = angleOf((x1 - cx1) / rx, (y1 - cy1) / ry);
  var deltaTheta =
      angleOf((-x1 - cx1) / rx, (-y1 - cy1) / ry) - theta1;
  if (!sweep && deltaTheta > 0) {
    deltaTheta -= 2 * math.pi;
  } else if (sweep && deltaTheta < 0) {
    deltaTheta += 2 * math.pi;
  }

  // Um arco por quadrante mantém o erro abaixo do imperceptível.
  final segmentCount = (deltaTheta.abs() / (math.pi / 2)).ceil().clamp(1, 8);
  final delta = deltaTheta / segmentCount;
  final alpha = 4 / 3 * math.tan(delta / 4);

  final result = <SvgPathSegment>[];
  var theta = theta1;
  var currentX = x0;
  var currentY = y0;

  for (var i = 0; i < segmentCount; i++) {
    final nextTheta = theta + delta;
    final cosTheta = math.cos(theta);
    final sinTheta = math.sin(theta);
    final cosNext = math.cos(nextTheta);
    final sinNext = math.sin(nextTheta);

    final ex = cosPhi * rx * cosNext - sinPhi * ry * sinNext + cx;
    final ey = sinPhi * rx * cosNext + cosPhi * ry * sinNext + cy;

    final dx1 = alpha * (-cosPhi * rx * sinTheta - sinPhi * ry * cosTheta);
    final dy1 = alpha * (-sinPhi * rx * sinTheta + cosPhi * ry * cosTheta);
    final dx3 = alpha * (cosPhi * rx * sinNext + sinPhi * ry * cosNext);
    final dy3 = alpha * (sinPhi * rx * sinNext - cosPhi * ry * cosNext);

    result.add(SvgCubicTo(
      currentX + dx1,
      currentY + dy1,
      ex + dx3,
      ey + dy3,
      ex,
      ey,
    ));

    theta = nextTheta;
    currentX = ex;
    currentY = ey;
  }
  return result;
}

/// Leitor tolerante da gramática do `d`.
class _SvgPathTokenizer {
  _SvgPathTokenizer(this._source);

  final String _source;
  int _pos = 0;

  bool get exhausted {
    _skipSeparators();
    return _pos >= _source.length;
  }

  void _skipSeparators() {
    while (_pos < _source.length) {
      final code = _source.codeUnitAt(_pos);
      // espaço, tab, CR, LF, vírgula
      if (code == 0x20 || code == 0x09 || code == 0x0D || code == 0x0A ||
          code == 0x2C) {
        _pos++;
      } else {
        break;
      }
    }
  }

  String? peekCommand() {
    _skipSeparators();
    if (_pos >= _source.length) return null;
    final char = _source[_pos];
    return _isCommand(char) ? char : null;
  }

  String readCommand() {
    _skipSeparators();
    return _source[_pos++];
  }

  bool get hasNumber {
    _skipSeparators();
    if (_pos >= _source.length) return false;
    final char = _source[_pos];
    return char == '-' ||
        char == '+' ||
        char == '.' ||
        (char.codeUnitAt(0) >= 0x30 && char.codeUnitAt(0) <= 0x39);
  }

  double readNumber() {
    _skipSeparators();
    final start = _pos;
    if (_pos < _source.length &&
        (_source[_pos] == '-' || _source[_pos] == '+')) {
      _pos++;
    }
    var seenDot = false;
    var seenExponent = false;
    while (_pos < _source.length) {
      final char = _source[_pos];
      final code = char.codeUnitAt(0);
      if (code >= 0x30 && code <= 0x39) {
        _pos++;
      } else if (char == '.' && !seenDot && !seenExponent) {
        seenDot = true;
        _pos++;
      } else if ((char == 'e' || char == 'E') && !seenExponent) {
        seenExponent = true;
        _pos++;
        if (_pos < _source.length &&
            (_source[_pos] == '-' || _source[_pos] == '+')) {
          _pos++;
        }
      } else {
        break;
      }
    }
    if (_pos == start) {
      _pos++; // não trava em caractere inesperado
      return 0;
    }
    return double.tryParse(_source.substring(start, _pos)) ?? 0;
  }

  /// Os flags do arco são um único dígito, e podem vir colados no próximo
  /// número (`1150` é flag 1, flag 1, número 50).
  bool readFlag() {
    _skipSeparators();
    if (_pos >= _source.length) return false;
    final char = _source[_pos];
    if (char == '0' || char == '1') {
      _pos++;
      return char == '1';
    }
    return readNumber() != 0;
  }

  void skipNumbers() {
    while (hasNumber) {
      readNumber();
    }
  }

  static bool _isCommand(String char) =>
      'MmLlHhVvCcSsQqTtAaZz'.contains(char);
}
