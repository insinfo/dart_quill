/// TeX command tables for the bundled math renderer.
library;

/// How a symbol behaves in a formula, which decides the MathML element and
/// the spacing around it.
enum AtomKind {
  /// Ordinary symbol — `<mi>` for letters, `<mn>` for digits.
  ord,

  /// Large operator (`\sum`, `\int`) — takes limits.
  bigOp,

  /// Binary operator (`+`, `\times`).
  bin,

  /// Relation (`=`, `\leq`).
  rel,

  /// Opening fence.
  open,

  /// Closing fence.
  close,

  /// Punctuation.
  punct,

  /// Upright multi-letter name (`\sin`), rendered without italics.
  functionName,
}

class SymbolDef {
  const SymbolDef(this.output, this.kind, {this.limits = false});

  final String output;
  final AtomKind kind;

  /// Whether scripts attach above/below instead of beside.
  final bool limits;
}

/// Greek letters, operators, relations, arrows and the usual named symbols.
const Map<String, SymbolDef> texSymbols = {
  // --- lowercase greek -----------------------------------------------------
  r'\alpha': SymbolDef('α', AtomKind.ord),
  r'\beta': SymbolDef('β', AtomKind.ord),
  r'\gamma': SymbolDef('γ', AtomKind.ord),
  r'\delta': SymbolDef('δ', AtomKind.ord),
  r'\epsilon': SymbolDef('ϵ', AtomKind.ord),
  r'\varepsilon': SymbolDef('ε', AtomKind.ord),
  r'\zeta': SymbolDef('ζ', AtomKind.ord),
  r'\eta': SymbolDef('η', AtomKind.ord),
  r'\theta': SymbolDef('θ', AtomKind.ord),
  r'\vartheta': SymbolDef('ϑ', AtomKind.ord),
  r'\iota': SymbolDef('ι', AtomKind.ord),
  r'\kappa': SymbolDef('κ', AtomKind.ord),
  r'\lambda': SymbolDef('λ', AtomKind.ord),
  r'\mu': SymbolDef('μ', AtomKind.ord),
  r'\nu': SymbolDef('ν', AtomKind.ord),
  r'\xi': SymbolDef('ξ', AtomKind.ord),
  r'\pi': SymbolDef('π', AtomKind.ord),
  r'\varpi': SymbolDef('ϖ', AtomKind.ord),
  r'\rho': SymbolDef('ρ', AtomKind.ord),
  r'\varrho': SymbolDef('ϱ', AtomKind.ord),
  r'\sigma': SymbolDef('σ', AtomKind.ord),
  r'\varsigma': SymbolDef('ς', AtomKind.ord),
  r'\tau': SymbolDef('τ', AtomKind.ord),
  r'\upsilon': SymbolDef('υ', AtomKind.ord),
  r'\phi': SymbolDef('ϕ', AtomKind.ord),
  r'\varphi': SymbolDef('φ', AtomKind.ord),
  r'\chi': SymbolDef('χ', AtomKind.ord),
  r'\psi': SymbolDef('ψ', AtomKind.ord),
  r'\omega': SymbolDef('ω', AtomKind.ord),

  // --- uppercase greek -----------------------------------------------------
  r'\Gamma': SymbolDef('Γ', AtomKind.ord),
  r'\Delta': SymbolDef('Δ', AtomKind.ord),
  r'\Theta': SymbolDef('Θ', AtomKind.ord),
  r'\Lambda': SymbolDef('Λ', AtomKind.ord),
  r'\Xi': SymbolDef('Ξ', AtomKind.ord),
  r'\Pi': SymbolDef('Π', AtomKind.ord),
  r'\Sigma': SymbolDef('Σ', AtomKind.ord),
  r'\Upsilon': SymbolDef('Υ', AtomKind.ord),
  r'\Phi': SymbolDef('Φ', AtomKind.ord),
  r'\Psi': SymbolDef('Ψ', AtomKind.ord),
  r'\Omega': SymbolDef('Ω', AtomKind.ord),

  // --- binary operators ----------------------------------------------------
  r'\pm': SymbolDef('±', AtomKind.bin),
  r'\mp': SymbolDef('∓', AtomKind.bin),
  r'\times': SymbolDef('×', AtomKind.bin),
  r'\div': SymbolDef('÷', AtomKind.bin),
  r'\cdot': SymbolDef('⋅', AtomKind.bin),
  r'\ast': SymbolDef('∗', AtomKind.bin),
  r'\star': SymbolDef('⋆', AtomKind.bin),
  r'\circ': SymbolDef('∘', AtomKind.bin),
  r'\bullet': SymbolDef('∙', AtomKind.bin),
  r'\oplus': SymbolDef('⊕', AtomKind.bin),
  r'\ominus': SymbolDef('⊖', AtomKind.bin),
  r'\otimes': SymbolDef('⊗', AtomKind.bin),
  r'\oslash': SymbolDef('⊘', AtomKind.bin),
  r'\odot': SymbolDef('⊙', AtomKind.bin),
  r'\cap': SymbolDef('∩', AtomKind.bin),
  r'\cup': SymbolDef('∪', AtomKind.bin),
  r'\uplus': SymbolDef('⊎', AtomKind.bin),
  r'\sqcap': SymbolDef('⊓', AtomKind.bin),
  r'\sqcup': SymbolDef('⊔', AtomKind.bin),
  r'\vee': SymbolDef('∨', AtomKind.bin),
  r'\lor': SymbolDef('∨', AtomKind.bin),
  r'\wedge': SymbolDef('∧', AtomKind.bin),
  r'\land': SymbolDef('∧', AtomKind.bin),
  r'\setminus': SymbolDef('∖', AtomKind.bin),
  r'\bmod': SymbolDef('mod', AtomKind.bin),

  // --- relations -----------------------------------------------------------
  r'\leq': SymbolDef('≤', AtomKind.rel),
  r'\le': SymbolDef('≤', AtomKind.rel),
  r'\geq': SymbolDef('≥', AtomKind.rel),
  r'\ge': SymbolDef('≥', AtomKind.rel),
  r'\neq': SymbolDef('≠', AtomKind.rel),
  r'\ne': SymbolDef('≠', AtomKind.rel),
  r'\ll': SymbolDef('≪', AtomKind.rel),
  r'\gg': SymbolDef('≫', AtomKind.rel),
  r'\equiv': SymbolDef('≡', AtomKind.rel),
  r'\sim': SymbolDef('∼', AtomKind.rel),
  r'\simeq': SymbolDef('≃', AtomKind.rel),
  r'\approx': SymbolDef('≈', AtomKind.rel),
  r'\cong': SymbolDef('≅', AtomKind.rel),
  r'\propto': SymbolDef('∝', AtomKind.rel),
  r'\subset': SymbolDef('⊂', AtomKind.rel),
  r'\supset': SymbolDef('⊃', AtomKind.rel),
  r'\subseteq': SymbolDef('⊆', AtomKind.rel),
  r'\supseteq': SymbolDef('⊇', AtomKind.rel),
  r'\in': SymbolDef('∈', AtomKind.rel),
  r'\ni': SymbolDef('∋', AtomKind.rel),
  r'\notin': SymbolDef('∉', AtomKind.rel),
  r'\perp': SymbolDef('⊥', AtomKind.rel),
  r'\parallel': SymbolDef('∥', AtomKind.rel),
  r'\mid': SymbolDef('∣', AtomKind.rel),
  r'\models': SymbolDef('⊨', AtomKind.rel),
  r'\prec': SymbolDef('≺', AtomKind.rel),
  r'\succ': SymbolDef('≻', AtomKind.rel),
  r'\doteq': SymbolDef('≐', AtomKind.rel),
  r'\asymp': SymbolDef('≍', AtomKind.rel),

  // --- arrows --------------------------------------------------------------
  r'\leftarrow': SymbolDef('←', AtomKind.rel),
  r'\gets': SymbolDef('←', AtomKind.rel),
  r'\rightarrow': SymbolDef('→', AtomKind.rel),
  r'\to': SymbolDef('→', AtomKind.rel),
  r'\leftrightarrow': SymbolDef('↔', AtomKind.rel),
  r'\Leftarrow': SymbolDef('⇐', AtomKind.rel),
  r'\Rightarrow': SymbolDef('⇒', AtomKind.rel),
  r'\Leftrightarrow': SymbolDef('⇔', AtomKind.rel),
  r'\iff': SymbolDef('⟺', AtomKind.rel),
  r'\implies': SymbolDef('⟹', AtomKind.rel),
  r'\mapsto': SymbolDef('↦', AtomKind.rel),
  r'\uparrow': SymbolDef('↑', AtomKind.rel),
  r'\downarrow': SymbolDef('↓', AtomKind.rel),
  r'\updownarrow': SymbolDef('↕', AtomKind.rel),
  r'\longrightarrow': SymbolDef('⟶', AtomKind.rel),
  r'\longleftarrow': SymbolDef('⟵', AtomKind.rel),
  r'\hookrightarrow': SymbolDef('↪', AtomKind.rel),

  // --- large operators -----------------------------------------------------
  r'\sum': SymbolDef('∑', AtomKind.bigOp, limits: true),
  r'\prod': SymbolDef('∏', AtomKind.bigOp, limits: true),
  r'\coprod': SymbolDef('∐', AtomKind.bigOp, limits: true),
  r'\bigcup': SymbolDef('⋃', AtomKind.bigOp, limits: true),
  r'\bigcap': SymbolDef('⋂', AtomKind.bigOp, limits: true),
  r'\bigoplus': SymbolDef('⨁', AtomKind.bigOp, limits: true),
  r'\bigotimes': SymbolDef('⨂', AtomKind.bigOp, limits: true),
  r'\bigvee': SymbolDef('⋁', AtomKind.bigOp, limits: true),
  r'\bigwedge': SymbolDef('⋀', AtomKind.bigOp, limits: true),
  r'\int': SymbolDef('∫', AtomKind.bigOp),
  r'\iint': SymbolDef('∬', AtomKind.bigOp),
  r'\iiint': SymbolDef('∭', AtomKind.bigOp),
  r'\oint': SymbolDef('∮', AtomKind.bigOp),

  // --- miscellaneous -------------------------------------------------------
  r'\infty': SymbolDef('∞', AtomKind.ord),
  r'\partial': SymbolDef('∂', AtomKind.ord),
  r'\nabla': SymbolDef('∇', AtomKind.ord),
  r'\forall': SymbolDef('∀', AtomKind.ord),
  r'\exists': SymbolDef('∃', AtomKind.ord),
  r'\nexists': SymbolDef('∄', AtomKind.ord),
  r'\neg': SymbolDef('¬', AtomKind.ord),
  r'\lnot': SymbolDef('¬', AtomKind.ord),
  r'\emptyset': SymbolDef('∅', AtomKind.ord),
  r'\varnothing': SymbolDef('∅', AtomKind.ord),
  r'\aleph': SymbolDef('ℵ', AtomKind.ord),
  r'\hbar': SymbolDef('ℏ', AtomKind.ord),
  r'\ell': SymbolDef('ℓ', AtomKind.ord),
  r'\Re': SymbolDef('ℜ', AtomKind.ord),
  r'\Im': SymbolDef('ℑ', AtomKind.ord),
  r'\wp': SymbolDef('℘', AtomKind.ord),
  r'\prime': SymbolDef('′', AtomKind.ord),
  r'\angle': SymbolDef('∠', AtomKind.ord),
  r'\triangle': SymbolDef('△', AtomKind.ord),
  r'\square': SymbolDef('□', AtomKind.ord),
  r'\degree': SymbolDef('°', AtomKind.ord),
  r'\dots': SymbolDef('…', AtomKind.ord),
  r'\ldots': SymbolDef('…', AtomKind.ord),
  r'\cdots': SymbolDef('⋯', AtomKind.ord),
  r'\vdots': SymbolDef('⋮', AtomKind.ord),
  r'\ddots': SymbolDef('⋱', AtomKind.ord),
  r'\checkmark': SymbolDef('✓', AtomKind.ord),
  r'\dagger': SymbolDef('†', AtomKind.ord),
  r'\ddagger': SymbolDef('‡', AtomKind.ord),
  r'\%': SymbolDef('%', AtomKind.ord),
  r'\$': SymbolDef(r'$', AtomKind.ord),
  r'\#': SymbolDef('#', AtomKind.ord),
  r'\&': SymbolDef('&', AtomKind.ord),
  r'\_': SymbolDef('_', AtomKind.ord),
  r'\{': SymbolDef('{', AtomKind.open),
  r'\}': SymbolDef('}', AtomKind.close),
  r'\backslash': SymbolDef('\\', AtomKind.ord),

  // --- fences --------------------------------------------------------------
  r'\lbrace': SymbolDef('{', AtomKind.open),
  r'\rbrace': SymbolDef('}', AtomKind.close),
  r'\langle': SymbolDef('⟨', AtomKind.open),
  r'\rangle': SymbolDef('⟩', AtomKind.close),
  r'\lceil': SymbolDef('⌈', AtomKind.open),
  r'\rceil': SymbolDef('⌉', AtomKind.close),
  r'\lfloor': SymbolDef('⌊', AtomKind.open),
  r'\rfloor': SymbolDef('⌋', AtomKind.close),
  r'\lvert': SymbolDef('|', AtomKind.open),
  r'\rvert': SymbolDef('|', AtomKind.close),
  r'\lVert': SymbolDef('‖', AtomKind.open),
  r'\rVert': SymbolDef('‖', AtomKind.close),
  r'\vert': SymbolDef('|', AtomKind.ord),
  r'\Vert': SymbolDef('‖', AtomKind.ord),
};

/// Upright function names (`\sin x`), with the ones that take limits marked.
const Map<String, bool> texFunctionNames = {
  'arccos': false, 'arcsin': false, 'arctan': false, 'arg': false,
  'cos': false, 'cosh': false, 'cot': false, 'coth': false, 'csc': false,
  'deg': false, 'det': true, 'dim': false, 'exp': false, 'gcd': true,
  'hom': false, 'inf': true, 'injlim': true, 'ker': false, 'lg': false,
  'lim': true, 'liminf': true, 'limsup': true, 'ln': false, 'log': false,
  'max': true, 'min': true, 'Pr': true, 'sec': false, 'sin': false,
  'sinh': false, 'sup': true, 'tan': false, 'tanh': false,
};

/// `\mathbb`-style font switches to their MathML `mathvariant`.
const Map<String, String> texFontVariants = {
  r'\mathrm': 'normal',
  r'\mathbf': 'bold',
  r'\bold': 'bold',
  r'\boldsymbol': 'bold-italic',
  r'\mathit': 'italic',
  r'\mathbb': 'double-struck',
  r'\mathcal': 'script',
  r'\mathscr': 'script',
  r'\mathfrak': 'fraktur',
  r'\mathsf': 'sans-serif',
  r'\mathtt': 'monospace',
};

/// Accents drawn above (or below) their argument.
const Map<String, String> texAccents = {
  r'\hat': '^',
  r'\widehat': '^',
  r'\check': 'ˇ',
  r'\tilde': '~',
  r'\widetilde': '~',
  r'\acute': '´',
  r'\grave': '`',
  r'\dot': '˙',
  r'\ddot': '¨',
  r'\breve': '˘',
  r'\bar': '¯',
  r'\overline': '¯',
  r'\vec': '→',
  r'\mathring': '˚',
  r'\overbrace': '⏞',
  r'\overrightarrow': '→',
  r'\overleftarrow': '←',
};

/// Accents drawn below their argument.
const Map<String, String> texUnderAccents = {
  r'\underline': '_',
  r'\underbrace': '⏟',
  r'\underrightarrow': '→',
  r'\underleftarrow': '←',
};

/// Fixed-width spacing commands, in `em`.
const Map<String, String> texSpaces = {
  r'\,': '0.167em',
  r'\thinspace': '0.167em',
  r'\:': '0.222em',
  r'\medspace': '0.222em',
  r'\;': '0.278em',
  r'\thickspace': '0.278em',
  r'\!': '-0.167em',
  r'\negthinspace': '-0.167em',
  r'\ ': '0.25em',
  r'\enspace': '0.5em',
  r'\quad': '1em',
  r'\qquad': '2em',
};

/// `\begin{env}` names to the fences they draw and their column alignment.
const Map<String, List<String>> texEnvironments = {
  // name: [open, close, alignment]
  'matrix': ['', '', 'center'],
  'pmatrix': ['(', ')', 'center'],
  'bmatrix': ['[', ']', 'center'],
  'Bmatrix': ['{', '}', 'center'],
  'vmatrix': ['|', '|', 'center'],
  'Vmatrix': ['‖', '‖', 'center'],
  'cases': ['{', '', 'left'],
  'array': ['', '', 'center'],
  'aligned': ['', '', 'right left'],
  'align': ['', '', 'right left'],
  'split': ['', '', 'right left'],
  'gathered': ['', '', 'center'],
  'gather': ['', '', 'center'],
  'smallmatrix': ['', '', 'center'],
};
