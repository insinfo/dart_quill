import 'dart:typed_data';

import 'font_metrics.dart';
import 'metrics_data.dart' as data;

/// Registro de métricas por família de fonte (D4/F4.10). Resolve o nome CSS
/// que o editor usa (`element.font`) para as [FontMetrics] embarcadas, com
/// substituição para famílias sem métricas próprias (ex.: a Ecofont dos
/// marcadores do ETP usa Calibri). Fontes carregadas pelo usuário podem ser
/// registradas em tempo de execução via [register].
class FontRegistry {
  FontRegistry._();

  static final FontRegistry instance = FontRegistry._();

  final Map<String, FontMetrics> _byFamily = <String, FontMetrics>{};

  /// Cache por string crua de `element.font` — o layout chama [lookup] uma vez
  /// por elemento (centenas de milhares por render em docs grandes), quase
  /// sempre com a mesma família ("Arial"); evita renormalizar a cada chamada.
  final Map<String?, FontMetrics?> _lookupCache = <String?, FontMetrics?>{};
  final Map<String?, List<String>> _fallbackStackCache =
      <String?, List<String>>{};
  final Map<String, String> _aliases = <String, String>{
    // Substituições e fallbacks CSS metricamente próximos (roteiro D4).
    // Os dois corpora PGCTIC declaram Calibri como w:altName da Ecofont.
    // Carlito é a substituta OFL metricamente compatível mantida pelo pacote;
    // Arial permanece como último recurso em hosts sem nenhuma das duas.
    'ecofont_spranq_eco_sans': 'calibri',
    'ecofont': 'calibri',
    'liberation sans': 'arial',
    'helvetica': 'arial',
    'liberation serif': 'times new roman',
    'raleway': 'arial',
    'calibri': 'carlito',
    'calibri light': 'carlito',
    'carlito': 'arial',
    'arial mt': 'arial',
    'tahoma': 'arial',
    'segoe ui': 'arial',
    'lucida sans': 'arial',
    'sans-serif': 'arial',
    // Mantém compositor, DOM e standard-14 na mesma categoria tipográfica.
    'cambria': 'times new roman',
    'georgia': 'times new roman',
    'garamond': 'times new roman',
    'book antiqua': 'times new roman',
    'times': 'times new roman',
    'serif': 'times new roman',
    'courier': 'courier new',
    'consolas': 'courier new',
    'monaco': 'courier new',
    'monospace': 'courier new',
  };

  bool _initialized = false;
  int _generation = 0;

  /// Changes whenever metric or alias resolution can produce new widths.
  /// Layout caches use this inexpensive stamp instead of retaining a copy of
  /// the global registry maps in every key.
  int get generation {
    _ensureInit();
    return _generation;
  }

  void _ensureInit() {
    if (_initialized) return;
    _initialized = true;
    data.registerEmbeddedFonts(this);
  }

  /// Registra métricas para uma família (nome normalizado internamente).
  void register(String family, FontMetrics metrics) {
    // Defaults must exist *before* a caller override is applied. Previously a
    // registerTtf('Calibri', ...) performed before the first lookup was
    // silently replaced when the lazy embedded table initialized later.
    // _ensureInit marks the registry initialized before calling the generated
    // registrations, so this is recursion-safe for those registrations too.
    _ensureInit();
    _byFamily[_normalize(family)] = metrics;
    _generation++;
    _lookupCache.clear();
    _fallbackStackCache.clear();
  }

  /// Registra métricas a partir dos bytes de um TTF/OTF (upload do usuário).
  void registerTtf(String family, Uint8List bytes) {
    register(family, parseTtfMetrics(bytes));
  }

  /// Define que [family] usa as métricas de [target].
  void alias(String family, String target) {
    _aliases[_normalize(family)] = _normalize(target);
    _generation++;
    _lookupCache.clear();
    _fallbackStackCache.clear();
  }

  /// Candidatas CSS ordenadas depois da família solicitada.
  ///
  /// A cadeia retém aliases intermediários relevantes à aparência (por
  /// exemplo Ecofont → Calibri → Carlito → Arial), rejeita ciclos e termina
  /// no fallback determinístico Arial quando não encontra nenhuma métrica.
  List<String> fallbackFamilyStack(String? family) {
    final cached = _fallbackStackCache[family];
    if (cached != null) return cached;
    _ensureInit();

    var key =
        family == null || family.isEmpty ? _defaultFamily : _normalize(family);
    final stack = <String>[];
    final visited = <String>{};
    var foundMetrics = false;
    var cycle = false;
    while (true) {
      if (!visited.add(key)) {
        cycle = true;
        break;
      }
      if (_byFamily.containsKey(key)) {
        foundMetrics = true;
        if (stack.isEmpty || stack.last != key) stack.add(key);
      }
      final target = _aliases[key];
      if (target == null) break;
      if (stack.isEmpty || stack.last != target) stack.add(target);
      key = target;
    }
    if ((!foundMetrics || cycle) &&
        (stack.isEmpty || stack.last != _defaultFamily)) {
      stack.add(_defaultFamily);
    }
    final result = List<String>.unmodifiable(stack);
    _fallbackStackCache[family] = result;
    return result;
  }

  /// Família concreta cujas métricas governam [family].
  ///
  /// Renderizadores de borda (DOM, por exemplo) usam este valor para montar
  /// uma pilha CSS coerente com a medição do compositor. Assim, uma fonte do
  /// DOCX que não existe na máquina — como `Ecofont_Spranq_eco_Sans` — usa
  /// métricas Carlito compatíveis com a Calibri declarada pelo documento, não
  /// o serif padrão.
  /// Famílias totalmente desconhecidas também usam Arial, que é exatamente o
  /// fallback aplicado pelo [LayoutComposer] quando [lookup] retorna `null`.
  String metricFallbackFamily(String? family) {
    _ensureInit();
    return _resolvedFamilyKey(family) ?? _defaultFamily;
  }

  /// Métricas da família ou `null` quando não há métricas nem alias — nesse
  /// caso o layout usa o fallback do canvas (`ctx.measureText`).
  FontMetrics? lookup(String? family) {
    final FontMetrics? cached = _lookupCache[family];
    if (cached != null || _lookupCache.containsKey(family)) {
      return cached;
    }
    final FontMetrics? result = _resolve(family);
    _lookupCache[family] = result;
    return result;
  }

  FontMetrics? _resolve(String? family) {
    _ensureInit();
    if (family == null || family.isEmpty) {
      return _byFamily[_defaultFamily];
    }
    final key = _resolvedFamilyKey(family);
    return key == null ? null : _byFamily[key];
  }

  String? _resolvedFamilyKey(String? family) {
    if (family == null || family.isEmpty) return _defaultFamily;
    var key = _normalize(family);
    final visited = <String>{};
    while (visited.add(key)) {
      if (_byFamily.containsKey(key)) return key;
      final target = _aliases[key];
      if (target == null) return null;
      key = target;
    }
    return null;
  }

  static const String _defaultFamily = 'arial';

  static String _normalize(String family) {
    var f = family.trim().toLowerCase();
    // Pilha CSS ("Arial", sans-serif) → usa a primeira família.
    final int comma = f.indexOf(',');
    if (comma >= 0) {
      f = f.substring(0, comma).trim();
    }
    // Remove aspas envolventes.
    if (f.startsWith('"') || f.startsWith("'")) {
      f = f.substring(1);
    }
    if (f.endsWith('"') || f.endsWith("'")) {
      f = f.substring(0, f.length - 1);
    }
    return f.trim();
  }
}
