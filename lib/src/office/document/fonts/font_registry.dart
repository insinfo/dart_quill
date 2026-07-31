import 'dart:typed_data';

import 'font_metrics.dart';
import 'metrics_data.dart' as data;

/// Registro de métricas por família de fonte (D4/F4.10). Resolve o nome CSS
/// que o editor usa (`element.font`) para as [FontMetrics] embarcadas, com
/// substituição para famílias sem métricas próprias (ex.: a Ecofont dos
/// marcadores do ETP cai em Arial). Fontes carregadas pelo usuário podem ser
/// registradas em tempo de execução via [register].
class FontRegistry {
  FontRegistry._();

  static final FontRegistry instance = FontRegistry._();

  final Map<String, FontMetrics> _byFamily = <String, FontMetrics>{};

  /// Cache por string crua de `element.font` — o layout chama [lookup] uma vez
  /// por elemento (centenas de milhares por render em docs grandes), quase
  /// sempre com a mesma família ("Arial"); evita renormalizar a cada chamada.
  final Map<String?, FontMetrics?> _lookupCache = <String?, FontMetrics?>{};
  final Map<String, String> _aliases = <String, String>{
    // Substituições (roteiro D4): sem métricas próprias → equivalente métrico.
    'ecofont_spranq_eco_sans': 'arial',
    'ecofont': 'arial',
    'liberation sans': 'arial',
    'helvetica': 'arial',
    'liberation serif': 'times new roman',
    'raleway': 'arial',
    'calibri': 'arial', // aproximação até embarcar métricas próprias
  };

  bool _initialized = false;

  void _ensureInit() {
    if (_initialized) return;
    _initialized = true;
    data.registerEmbeddedFonts(this);
  }

  /// Registra métricas para uma família (nome normalizado internamente).
  void register(String family, FontMetrics metrics) {
    _byFamily[_normalize(family)] = metrics;
    _lookupCache.clear();
  }

  /// Registra métricas a partir dos bytes de um TTF/OTF (upload do usuário).
  void registerTtf(String family, Uint8List bytes) {
    register(family, parseTtfMetrics(bytes));
  }

  /// Define que [family] usa as métricas de [target].
  void alias(String family, String target) {
    _aliases[_normalize(family)] = _normalize(target);
    _lookupCache.clear();
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
    final String key = _normalize(family);
    final FontMetrics? direct = _byFamily[key];
    if (direct != null) return direct;
    final String? aliased = _aliases[key];
    if (aliased != null) {
      return _byFamily[aliased];
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
