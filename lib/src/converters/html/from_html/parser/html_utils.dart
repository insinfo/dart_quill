// C:\MyDartProjects\new_sali\frontend\lib\src\shared\components\quill\dependencies\delta_from_html\parser\html_utils.dart
import 'indent_parser.dart';
import 'typedef/typedefs.dart';

import 'colors.dart';
import 'font_size_parser.dart';
import 'line_height_parser.dart';

/// Checks if the given [tag] corresponds to an inline HTML element.
///
/// Inline elements include: 'i', 'em', 'u', 'ins', 's', 'del', 'b', 'strong', 'sub', 'sup'.
///
/// Parameters:
/// - [tag]: The HTML tag name to check.
///
/// Returns:
/// `true` if [tag] is an inline element, `false` otherwise.
bool isInline(String tag) {
  return ["i", "em", "u", "ins", "s", "del", "b", "strong", "sub", "sup"]
      .contains(tag);
}

/// Parses a CSS style attribute string into Delta attributes.
///
/// Converts CSS styles (like 'text-align', 'color', 'font-size', etc.) from [style]
/// into Quill Delta attributes suitable for rich text formatting.
///
/// Parameters:
/// - [style]: The CSS style attribute string to parse.
///
/// Returns:
/// A map of Delta attributes derived from the CSS styles.
///
Map<String, dynamic> parseStyleAttribute(
  String tag,
  String style, {
  CSSVarible? onDetectLineheightCssVariable,
}) {
  final Map<String, dynamic> attributes = {};
  if (style.isEmpty) return attributes;

  // Trate valores "crus" (sem ':') como align/direction/checklist
  final raw = style.trim().toLowerCase();
  if (!raw.contains(':')) {
    switch (raw) {
      case 'justify' || 'center' || 'left' || 'right':
        attributes['align'] = raw;
        break;
      case 'rtl':
        attributes['direction'] = 'rtl';
        break;
      case 'true' || 'false':
        attributes['list'] = raw == 'true' ? 'checked' : 'unchecked';
        break;
      default:
        break;
    }
    return attributes;
  }

  final entries =
      style.split(';').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

  double? fontSize;

  for (final entry in entries) {
    final parts = entry.split(':');
    if (parts.length == 2) {
      final key = parts[0].trim();
      final value = parts[1].trim();

      switch (key) {
        case 'text-align':
          attributes['align'] = value;
          break;

        case 'color':
          {
            final color = validateAndGetColor(value);
            if (color != null) attributes['color'] = color;
            break;
          }

        case 'background-color':
          {
            final color = validateAndGetColor(value);
            if (color != null) attributes['background'] = color;
            break;
          }

        case 'padding-left' || 'padding-right':
          {
            final indentation = parseToIndent(value);
            if (indentation != 0) attributes['indent'] = indentation;
            break;
          }

        case 'font-size':
          {
            String? sizeToPass;

            // Handle default values used by [vsc_quill_delta_to_html]
            if (value == '0.75em') {
              fontSize = 10;
              sizeToPass = 'small';
            } else if (value == '1.5em') {
              fontSize = 18;
              sizeToPass = 'large';
            } else if (value == '2.5em') {
              fontSize = 22;
              sizeToPass = 'huge';
            } else {
              try {
                final size = parseSizeToPx(value);
                if (size <= 10) {
                  fontSize = 10;
                  sizeToPass = 'small';
                } else {
                  fontSize = size.floorToDouble();
                  sizeToPass = '${size.floor()}';
                }
              } on UnsupportedError {
                // ignore unidade não suportada
              }
            }
            if (sizeToPass != null) attributes['size'] = sizeToPass;
            break;
          }

        case 'font-family':
          attributes['font'] = value;
          break;

        case 'line-height':
          {
            double? lineHeight;
            if (onDetectLineheightCssVariable != null) {
              lineHeight = onDetectLineheightCssVariable(tag, key, value);
            }

            lineHeight ??= _tryParseLineHeight(value, fontSize ?? 16.0);
            if (lineHeight != null) attributes['line-height'] = lineHeight;
            break;
          }

        case 'font-style':
          if (value.contains('italic')) attributes['italic'] = true;
          break;

        case 'text-decoration':
          if (value.contains('underline')) attributes['underline'] = true;
          if (value.contains('line-through')) attributes['strike'] = true;
          break;

        case 'font-weight':
          if (value == 'bold' || value == '700') attributes['bold'] = true;
          break;

        default:
          // Ignore other styles
          break;
      }
    } else {
      // Entrada sem ":", tratar tokens isolados (defensivo)
      final token = entry.trim().toLowerCase();
      switch (token) {
        case 'justify' || 'center' || 'left' || 'right':
          attributes['align'] = token;
          break;
        case 'rtl':
          attributes['direction'] = 'rtl';
          break;
        case 'true' || 'false':
          attributes['list'] = token == 'true' ? 'checked' : 'unchecked';
          break;
        default:
          break;
      }
    }
  }

  return attributes;
}

double? _tryParseLineHeight(String value, double fontSize) {
  try {
    return parseLineHeight(value, fontSize: fontSize);
  } catch (_) {
    return null;
  }
}

/// Parses a CSS `<img>` style attribute string into Delta attributes.
///
/// Converts CSS styles (like 'width', 'height', 'margin') from [style]
/// into Quill Delta attributes suitable for image rich text formatting.
///
/// Parameters:
/// - [style]: The CSS style attribute string to parse.
///
/// Returns:
/// A map of Delta attributes derived from the CSS styles.
///
Map<String, dynamic> parseImageStyleAttribute(String style, String align) {
  final Map<String, dynamic> attributes = {};

  final entries =
      style.split(';').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

  for (final entry in entries) {
    final parts = entry.split(':');
    if (parts.length == 2) {
      final key = parts[0].trim().toLowerCase();
      final value = parts[1].trim();

      switch (key) {
        case 'width':
          attributes['width'] = value;
          break;
        case 'height':
          attributes['height'] = value;
          break;
        case 'margin':
          attributes['margin'] = value;
          break;
        default:
          // Ignore other styles
          break;
      }
    }
  }

  if (align.isNotEmpty) attributes['alignment'] = align;
  return attributes;
}
// fim do html_utils.dart
