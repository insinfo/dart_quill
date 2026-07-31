import '../math/tex_math.dart';
import '../platform/dom.dart';

/// Colour used for a formula that does not parse.
///
/// Parity with the options upstream passes to KaTeX
/// (`{throwOnError: false, errorColor: '#f00'}`): a broken formula shows its
/// own source in red instead of taking the editor down.
const String formulaErrorColor = '#f00';

/// Renders the LaTeX [value] into [node] as MathML.
///
/// The renderer is the one bundled with the package ([texToMathML]), so a
/// formula needs no script tag and no font download — and the very same markup
/// is produced on the VM, which is what makes formulas testable and
/// exportable.
void renderFormula(String value, DomElement node) {
  node.innerHTML = texToMathML(value, errorColor: formulaErrorColor);
}

/// The MathML for [value], for callers that need the markup rather than a DOM
/// node (HTML export, DOCX/PDF conversion).
String formulaToMathML(String value, {bool displayMode = false}) =>
    texToMathML(value, displayMode: displayMode, errorColor: formulaErrorColor);
