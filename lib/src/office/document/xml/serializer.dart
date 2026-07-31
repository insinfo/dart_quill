/// Escape de XML com controle exato de saída (fidelidade de output,
/// decisão D6 do roteiro).
class XmlEscape {
  XmlEscape._();

  /// Escapa texto de conteúdo de elemento.
  ///
  /// `&`, `<`, `>` viram entidades; CR vira `&#xD;` (senão seria perdido na
  /// normalização de fim de linha do próximo parse).
  static String text(String value) {
    if (!_needsTextEscape(value)) return value;
    final buffer = StringBuffer();
    for (var i = 0; i < value.length; i++) {
      final c = value.codeUnitAt(i);
      switch (c) {
        case 0x26:
          buffer.write('&amp;');
        case 0x3c:
          buffer.write('&lt;');
        case 0x3e:
          buffer.write('&gt;');
        case 0x0d:
          buffer.write('&#xD;');
        default:
          buffer.writeCharCode(c);
      }
    }
    return buffer.toString();
  }

  /// Escapa valor de atributo (aspas duplas).
  ///
  /// Além de `&`, `<`, `>`, `"`, preserva tab/LF/CR como referências de
  /// caractere (senão seriam normalizados para espaço no próximo parse).
  static String attribute(String value) {
    if (!_needsAttributeEscape(value)) return value;
    final buffer = StringBuffer();
    for (var i = 0; i < value.length; i++) {
      final c = value.codeUnitAt(i);
      switch (c) {
        case 0x26:
          buffer.write('&amp;');
        case 0x3c:
          buffer.write('&lt;');
        case 0x3e:
          buffer.write('&gt;');
        case 0x22:
          buffer.write('&quot;');
        case 0x09:
          buffer.write('&#x9;');
        case 0x0a:
          buffer.write('&#xA;');
        case 0x0d:
          buffer.write('&#xD;');
        default:
          buffer.writeCharCode(c);
      }
    }
    return buffer.toString();
  }

  static bool _needsTextEscape(String value) {
    for (var i = 0; i < value.length; i++) {
      final c = value.codeUnitAt(i);
      if (c == 0x26 || c == 0x3c || c == 0x3e || c == 0x0d) return true;
    }
    return false;
  }

  static bool _needsAttributeEscape(String value) {
    for (var i = 0; i < value.length; i++) {
      final c = value.codeUnitAt(i);
      if (c == 0x26 ||
          c == 0x3c ||
          c == 0x3e ||
          c == 0x22 ||
          c == 0x09 ||
          c == 0x0a ||
          c == 0x0d) {
        return true;
      }
    }
    return false;
  }
}
