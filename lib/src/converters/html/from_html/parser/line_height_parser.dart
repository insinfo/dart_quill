/// constant common line-height multiplier
const normalLineHeightMultiplier = 1.2;
final RegExp _cssVariables =
    RegExp(r'var\(\s*--([a-zA-Z0-9_-]+)\s*\)|^var\(.+');

/// Parses a CSS `line-height` value to a pixel value based on the specified [fontSize] and optional [rootFontSize].
///
/// Supports unitless values, percentages, pixels (`px`), ems (`em`), rems (`rem`), and the keyword `normal`.
/// Adjusts the parsed value to fit within the supported range of line heights: 1.0, 1.15, 1.5, and 2.0.
///
/// Parameters:
/// - [lineHeight]: The CSS `line-height` value to parse.
/// - [fontSize]: The font size to use for unit conversions. Defaults to 16.
/// - [rootFontSize]: The root font size, used for `rem` conversions. Defaults to [fontSize].
///
/// Returns:
/// The parsed `line-height` value as a double in pixels.
double parseLineHeight(
  String lineHeight, {
  double fontSize = 16,
  double rootFontSize = 16,
}) {
  // Convert line-height values
  double parsedValue;
  if (lineHeight.endsWith('px')) {
    parsedValue = double.parse(lineHeight.replaceAll('px', ''));
  } else if (lineHeight.endsWith('%')) {
    parsedValue =
        fontSize * (double.parse(lineHeight.replaceAll('%', '')) / 100);
  } else if (lineHeight.endsWith('rem')) {
    parsedValue = rootFontSize * double.parse(lineHeight.replaceAll('rem', ''));
  } else if (lineHeight.endsWith('em')) {
    parsedValue = fontSize * double.parse(lineHeight.replaceAll('em', ''));
  } else if (lineHeight == 'normal') {
    parsedValue = fontSize * normalLineHeightMultiplier;
  } else if (lineHeight.startsWith(_cssVariables)) {
    parsedValue = 1.0;
  } else {
    parsedValue = fontSize * (double.tryParse(lineHeight) ?? 1.0);
  }

  // Apply additional constraints
  if (parsedValue < 1.0) {
    parsedValue = 1.0;
  } else if (parsedValue > 1.0 && parsedValue < 1.15) {
    parsedValue = 1.0;
  } else if (parsedValue > 1.15 && parsedValue < 1.25) {
    parsedValue = 1.15;
  } else if (parsedValue > 1.25 && parsedValue < 1.5) {
    parsedValue = 1.5;
  } else if (parsedValue > 1.5 && parsedValue < 2.0) {
    parsedValue = 1.5;
  } else if (parsedValue > 2.0) {
    parsedValue = 2.0;
  }

  return parsedValue;
}
