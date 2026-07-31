import 'dart:convert';
import 'dart:typed_data';

/// Atributo entregue pelos eventos SAX.
///
/// [value] já vem com entidades decodificadas e com a normalização de
/// whitespace do XML 1.0 aplicada (tab/LF/CR literais viram espaço;
/// referências de caractere `&#x9;`/`&#xA;`/`&#xD;` preservam o caractere).
class XmlSaxAttribute {
  final String qname;
  final String value;

  const XmlSaxAttribute(this.qname, this.value);

  String get localName => XmlNameUtil.localName(qname);
  String? get prefix => XmlNameUtil.prefix(qname);

  @override
  String toString() => '$qname="$value"';
}

/// Utilitários de QName (`prefixo:local`).
class XmlNameUtil {
  XmlNameUtil._();

  static String localName(String qname) {
    final colon = qname.indexOf(':');
    return colon < 0 ? qname : qname.substring(colon + 1);
  }

  static String? prefix(String qname) {
    final colon = qname.indexOf(':');
    return colon < 0 ? null : qname.substring(0, colon);
  }
}

/// Handler de eventos do parser SAX ([XmlSaxParser]).
abstract class XmlSaxHandler {
  void startDocument() {}

  /// Declaração `<?xml version=... encoding=... standalone=...?>`.
  void xmlDeclaration(String? version, String? encoding, String? standalone) {}

  /// Início de elemento. [selfClosing] indica `<a/>`; nesse caso o evento
  /// [endElement] correspondente também é emitido logo em seguida.
  void startElement(
      String qname, List<XmlSaxAttribute> attributes, bool selfClosing) {}

  void endElement(String qname) {}

  /// Texto (entidades já decodificadas; quebras CRLF normalizadas para LF).
  void characters(String text) {}

  void cdata(String text) {}

  void comment(String text) {}

  void processingInstruction(String target, String? data) {}

  void endDocument() {}
}

/// Erro de parse com posição no texto-fonte.
class XmlParseException extends FormatException {
  XmlParseException(String message, String source, int offset)
      : super(_describe(message, source, offset));

  static String _describe(String message, String source, int offset) {
    var line = 1;
    var lineStart = 0;
    for (var i = 0; i < offset && i < source.length; i++) {
      if (source.codeUnitAt(i) == 0x0a) {
        line++;
        lineStart = i + 1;
      }
    }
    final column = offset - lineStart + 1;
    return '$message (linha $line, coluna $column)';
  }
}

const int _lt = 0x3c; // <
const int _gt = 0x3e; // >
const int _amp = 0x26; // &
const int _slash = 0x2f; // /
const int _excl = 0x21; // !
const int _quest = 0x3f; // ?
const int _eq = 0x3d; // =
const int _quot = 0x22; // "
const int _apos = 0x27; // '
const int _space = 0x20;
const int _tab = 0x09;
const int _lf = 0x0a;
const int _cr = 0x0d;
const int _hash = 0x23; // #
const int _lbracket = 0x5b; // [
const int _rbracket = 0x5d; // ]

/// Parser XML 1.0 streaming (SAX) em Dart puro — decisão D6 do roteiro.
///
/// Escopo: XML bem-comportado do OOXML — namespaces (como QNames),
/// atributos, texto, CDATA, comentários, PIs, entidades predefinidas e
/// referências numéricas. DOCTYPE é pulado (sem resolução externa).
class XmlSaxParser {
  final String _src;
  final XmlSaxHandler _handler;
  int _pos = 0;

  XmlSaxParser._(this._src, this._handler);

  /// Faz o parse de [source] emitindo eventos em [handler].
  static void parseString(String source, XmlSaxHandler handler) {
    var start = 0;
    if (source.isNotEmpty && source.codeUnitAt(0) == 0xfeff) start = 1;
    XmlSaxParser._(start == 0 ? source : source.substring(start), handler)
        ._parseDocument();
  }

  /// Decodifica [bytes] como UTF-8 (tolerando BOM) e faz o parse.
  static void parseBytes(Uint8List bytes, XmlSaxHandler handler) {
    var start = 0;
    if (bytes.length >= 3 &&
        bytes[0] == 0xef &&
        bytes[1] == 0xbb &&
        bytes[2] == 0xbf) {
      start = 3;
    }
    parseString(
        utf8.decode(start == 0 ? bytes : Uint8List.sublistView(bytes, start)),
        handler);
  }

  void _parseDocument() {
    _handler.startDocument();
    final src = _src;
    final len = src.length;
    var depth = 0;
    var seenRoot = false;

    while (_pos < len) {
      final c = src.codeUnitAt(_pos);
      if (c == _lt) {
        if (_pos + 1 >= len) {
          throw XmlParseException('Documento termina dentro de tag', src, _pos);
        }
        final c1 = src.codeUnitAt(_pos + 1);
        if (c1 == _slash) {
          final qname = _parseEndTag();
          depth--;
          if (depth < 0) {
            throw XmlParseException(
                'Tag de fechamento sem abertura: </$qname>', src, _pos);
          }
          _handler.endElement(qname);
        } else if (c1 == _excl) {
          if (src.startsWith('<!--', _pos)) {
            _parseComment();
          } else if (src.startsWith('<![CDATA[', _pos)) {
            if (depth == 0) {
              throw XmlParseException('CDATA fora do elemento raiz', src, _pos);
            }
            _parseCData();
          } else if (src.startsWith('<!DOCTYPE', _pos)) {
            _skipDoctype();
          } else {
            throw XmlParseException('Marcação "<!" desconhecida', src, _pos);
          }
        } else if (c1 == _quest) {
          _parsePiOrDeclaration(atStart: _pos == 0);
        } else {
          if (depth == 0 && seenRoot) {
            throw XmlParseException(
                'Mais de um elemento raiz no documento', src, _pos);
          }
          final selfClosing = _parseStartTag();
          seenRoot = true;
          if (!selfClosing) depth++;
        }
      } else {
        final textEnd = src.indexOf('<', _pos);
        final end = textEnd < 0 ? len : textEnd;
        if (depth > 0) {
          final text = _decodeText(src, _pos, end);
          if (text.isNotEmpty) _handler.characters(text);
        } else {
          // Fora do raiz só whitespace é permitido.
          for (var i = _pos; i < end; i++) {
            final w = src.codeUnitAt(i);
            if (w != _space && w != _tab && w != _lf && w != _cr) {
              throw XmlParseException('Texto fora do elemento raiz', src, i);
            }
          }
        }
        _pos = end;
      }
    }

    if (depth != 0) {
      throw XmlParseException('Elemento não fechado no fim do documento', src,
          len == 0 ? 0 : len - 1);
    }
    if (!seenRoot) {
      throw XmlParseException('Documento sem elemento raiz', src, 0);
    }
    _handler.endDocument();
  }

  /// `<qname attr="v" ...>` ou `<qname .../>`. Retorna se é self-closing.
  bool _parseStartTag() {
    final src = _src;
    final len = src.length;
    var i = _pos + 1;
    final nameStart = i;
    while (i < len && !_isNameEnd(src.codeUnitAt(i))) {
      i++;
    }
    if (i == nameStart) {
      throw XmlParseException('Nome de elemento vazio', src, _pos);
    }
    final qname = src.substring(nameStart, i);

    List<XmlSaxAttribute>? attributes;
    while (true) {
      i = _skipWhitespace(i);
      if (i >= len) {
        throw XmlParseException('Tag não terminada: <$qname', src, _pos);
      }
      final c = src.codeUnitAt(i);
      if (c == _gt) {
        _pos = i + 1;
        _handler.startElement(qname, attributes ?? const [], false);
        return false;
      }
      if (c == _slash) {
        if (i + 1 >= len || src.codeUnitAt(i + 1) != _gt) {
          throw XmlParseException('Esperado "/>" na tag <$qname', src, i);
        }
        _pos = i + 2;
        _handler.startElement(qname, attributes ?? const [], true);
        _handler.endElement(qname);
        return true;
      }
      // Atributo.
      final attrNameStart = i;
      while (i < len) {
        final a = src.codeUnitAt(i);
        if (a == _eq ||
            a == _space ||
            a == _tab ||
            a == _lf ||
            a == _cr ||
            a == _gt ||
            a == _slash) {
          break;
        }
        i++;
      }
      if (i == attrNameStart) {
        throw XmlParseException('Caractere inesperado na tag <$qname', src, i);
      }
      final attrName = src.substring(attrNameStart, i);
      i = _skipWhitespace(i);
      if (i >= len || src.codeUnitAt(i) != _eq) {
        throw XmlParseException(
            'Atributo "$attrName" sem "=" na tag <$qname', src, i);
      }
      i = _skipWhitespace(i + 1);
      if (i >= len) {
        throw XmlParseException('Valor de atributo ausente', src, i - 1);
      }
      final quote = src.codeUnitAt(i);
      if (quote != _quot && quote != _apos) {
        throw XmlParseException(
            'Valor do atributo "$attrName" sem aspas', src, i);
      }
      final valueStart = i + 1;
      final valueEnd = src.indexOf(quote == _quot ? '"' : "'", valueStart);
      if (valueEnd < 0) {
        throw XmlParseException(
            'Valor do atributo "$attrName" não terminado', src, i);
      }
      final value = _decodeAttributeValue(src, valueStart, valueEnd);
      (attributes ??= <XmlSaxAttribute>[])
          .add(XmlSaxAttribute(attrName, value));
      i = valueEnd + 1;
    }
  }

  String _parseEndTag() {
    final src = _src;
    final len = src.length;
    var i = _pos + 2;
    final nameStart = i;
    while (i < len && !_isNameEnd(src.codeUnitAt(i))) {
      i++;
    }
    final qname = src.substring(nameStart, i);
    i = _skipWhitespace(i);
    if (i >= len || src.codeUnitAt(i) != _gt) {
      throw XmlParseException('Tag </$qname não terminada', src, _pos);
    }
    _pos = i + 1;
    return qname;
  }

  void _parseComment() {
    final end = _src.indexOf('-->', _pos + 4);
    if (end < 0) {
      throw XmlParseException('Comentário não terminado', _src, _pos);
    }
    _handler.comment(_src.substring(_pos + 4, end));
    _pos = end + 3;
  }

  void _parseCData() {
    final end = _src.indexOf(']]>', _pos + 9);
    if (end < 0) {
      throw XmlParseException('CDATA não terminado', _src, _pos);
    }
    _handler.cdata(_src.substring(_pos + 9, end));
    _pos = end + 3;
  }

  void _parsePiOrDeclaration({required bool atStart}) {
    final src = _src;
    final end = src.indexOf('?>', _pos + 2);
    if (end < 0) {
      throw XmlParseException(
          'Processing instruction não terminada', src, _pos);
    }
    final body = src.substring(_pos + 2, end);
    _pos = end + 2;

    final spaceIdx = _firstWhitespace(body);
    final target = spaceIdx < 0 ? body : body.substring(0, spaceIdx);
    final data = spaceIdx < 0 ? null : body.substring(spaceIdx + 1).trim();

    if (target.toLowerCase() == 'xml') {
      if (!atStart) {
        throw XmlParseException(
            'Declaração XML fora do início do documento', src, _pos);
      }
      final pseudo = _parsePseudoAttributes(data ?? '');
      _handler.xmlDeclaration(
          pseudo['version'], pseudo['encoding'], pseudo['standalone']);
    } else {
      _handler.processingInstruction(target, data);
    }
  }

  void _skipDoctype() {
    final src = _src;
    final len = src.length;
    var i = _pos + 9;
    var bracketDepth = 0;
    while (i < len) {
      final c = src.codeUnitAt(i);
      if (c == _quot || c == _apos) {
        final close = src.indexOf(String.fromCharCode(c), i + 1);
        if (close < 0) break;
        i = close + 1;
        continue;
      }
      if (c == _lbracket) bracketDepth++;
      if (c == _rbracket) bracketDepth--;
      if (c == _gt && bracketDepth <= 0) {
        _pos = i + 1;
        return;
      }
      i++;
    }
    throw XmlParseException('DOCTYPE não terminado', src, _pos);
  }

  int _skipWhitespace(int i) {
    final src = _src;
    final len = src.length;
    while (i < len) {
      final c = src.codeUnitAt(i);
      if (c != _space && c != _tab && c != _lf && c != _cr) break;
      i++;
    }
    return i;
  }

  static bool _isNameEnd(int c) =>
      c == _space ||
      c == _tab ||
      c == _lf ||
      c == _cr ||
      c == _gt ||
      c == _slash ||
      c == _eq;

  static int _firstWhitespace(String s) {
    for (var i = 0; i < s.length; i++) {
      final c = s.codeUnitAt(i);
      if (c == _space || c == _tab || c == _lf || c == _cr) return i;
    }
    return -1;
  }

  static Map<String, String> _parsePseudoAttributes(String data) {
    final result = <String, String>{};
    final re = RegExp('([A-Za-z]+)\\s*=\\s*("([^"]*)"|\'([^\']*)\')');
    for (final m in re.allMatches(data)) {
      result[m.group(1)!] = m.group(3) ?? m.group(4) ?? '';
    }
    return result;
  }

  /// Decodifica texto de conteúdo: entidades + normalização CRLF→LF.
  String _decodeText(String src, int start, int end) {
    // Varredura limitada ao intervalo: indexOf sem limite superior faria a
    // busca varrer o arquivo inteiro para cada nó de texto (O(n²)).
    var needsWork = false;
    for (var i = start; i < end; i++) {
      final c = src.codeUnitAt(i);
      if (c == _amp || c == _cr) {
        needsWork = true;
        break;
      }
    }
    if (!needsWork) return src.substring(start, end);

    final buffer = StringBuffer();
    var i = start;
    while (i < end) {
      final c = src.codeUnitAt(i);
      if (c == _amp) {
        i = _decodeEntityInto(src, i, end, buffer);
      } else if (c == _cr) {
        buffer.writeCharCode(_lf);
        if (i + 1 < end && src.codeUnitAt(i + 1) == _lf) i++;
        i++;
      } else {
        buffer.writeCharCode(c);
        i++;
      }
    }
    return buffer.toString();
  }

  /// Decodifica valor de atributo: entidades + normalização de whitespace
  /// (tab/LF/CR literais → espaço; via referência de caractere, preservados).
  String _decodeAttributeValue(String src, int start, int end) {
    var needsWork = false;
    for (var i = start; i < end; i++) {
      final c = src.codeUnitAt(i);
      if (c == _amp || c == _tab || c == _lf || c == _cr) {
        needsWork = true;
        break;
      }
    }
    if (!needsWork) return src.substring(start, end);

    final buffer = StringBuffer();
    var i = start;
    while (i < end) {
      final c = src.codeUnitAt(i);
      if (c == _amp) {
        i = _decodeEntityInto(src, i, end, buffer);
      } else if (c == _tab || c == _lf || c == _cr) {
        buffer.writeCharCode(_space);
        if (c == _cr && i + 1 < end && src.codeUnitAt(i + 1) == _lf) i++;
        i++;
      } else {
        buffer.writeCharCode(c);
        i++;
      }
    }
    return buffer.toString();
  }

  /// Decodifica uma referência de entidade a partir de `&` em [i].
  /// Escreve o resultado em [buffer] e retorna a posição após o `;`.
  int _decodeEntityInto(String src, int i, int end, StringBuffer buffer) {
    final semi = src.indexOf(';', i + 1);
    if (semi < 0 || semi >= end || semi - i > 12) {
      throw XmlParseException('Referência de entidade malformada', src, i);
    }
    if (src.codeUnitAt(i + 1) == _hash) {
      final isHex = src.codeUnitAt(i + 2) == 0x78 /* x */ ||
          src.codeUnitAt(i + 2) == 0x58 /* X */;
      final digits = src.substring(isHex ? i + 3 : i + 2, semi);
      final code = int.tryParse(digits, radix: isHex ? 16 : 10);
      if (code == null) {
        throw XmlParseException(
            'Referência de caractere inválida: &${src.substring(i + 1, semi)};',
            src,
            i);
      }
      buffer.writeCharCode(code);
      return semi + 1;
    }
    final name = src.substring(i + 1, semi);
    switch (name) {
      case 'amp':
        buffer.writeCharCode(_amp);
      case 'lt':
        buffer.writeCharCode(_lt);
      case 'gt':
        buffer.writeCharCode(_gt);
      case 'quot':
        buffer.writeCharCode(_quot);
      case 'apos':
        buffer.writeCharCode(_apos);
      case _:
        throw XmlParseException('Entidade desconhecida: &$name;', src, i);
    }
    return semi + 1;
  }
}
