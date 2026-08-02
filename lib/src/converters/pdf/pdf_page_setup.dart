/// Configuração de página gravada no próprio Delta (`page-orientation` /
/// `page-margin`) e a política de sanitização pré-PDF.
///
/// Os atributos nasceram como plugin do SALI (`sali_page_setup.js`) porque o
/// Quill não tem noção de página; aqui viram recurso genérico do pacote, e o
/// comportamento espelha o pipeline em produção
/// (`sali_quill_pdf_defaults.dart` / `quill_pdf_sanitizer.dart`):
///
/// * qualquer op pode carregar os atributos (o editor grava na primeira
///   linha); a ausência cai no padrão A4 retrato;
/// * margem aceita `"2cm"`, `"1,5cm"` ou o número puro, na faixa 0,5–5 cm —
///   fora dela o valor é ignorado para não gerar página sem área útil;
/// * a sanitização remove os atributos de página ANTES do renderizador (um
///   parágrafo com atributo de bloco desconhecido não renderiza) e aplica a
///   política de formato do documento final.
library;

import 'pdf_exporter.dart' show PdfExportOptions, PdfFontFace;
import 'dart:typed_data';

/// 1 cm em pontos PDF.
const double _cmPt = 72 / 2.54;

/// Faixa aceita de margem, em cm.
const double _minMarginCm = 0.5;
const double _maxMarginCm = 5.0;

/// Orientação e margem declaradas no Delta.
class PdfPageSetup {
  const PdfPageSetup({this.landscape = false, this.marginCm});

  /// A4 retrato, margem do layout.
  static const PdfPageSetup standard = PdfPageSetup();

  final bool landscape;

  /// Margem em cm, ou null para o padrão do layout chamado.
  final double? marginCm;

  bool get isDefault => !landscape && marginCm == null;
}

/// Converte um valor `page-margin` ("2cm", "1,5cm" ou número) para cm dentro
/// da faixa válida; null quando inválido ou fora da faixa.
double? parsePageMarginCm(Object? raw) {
  if (raw is num) {
    final double cm = raw.toDouble();
    return cm >= _minMarginCm && cm <= _maxMarginCm ? cm : null;
  }
  if (raw is! String) return null;
  final Match? match =
      RegExp(r'^\s*([\d]+(?:[.,][\d]+)?)\s*cm\s*$', caseSensitive: false)
          .firstMatch(raw);
  if (match == null) return null;
  final double? cm = double.tryParse(match.group(1)!.replaceAll(',', '.'));
  if (cm == null) return null;
  return cm >= _minMarginCm && cm <= _maxMarginCm ? cm : null;
}

/// Extrai a configuração de página dos ops de um Delta.
PdfPageSetup readPdfPageSetup(Iterable<dynamic> ops) {
  var landscape = false;
  double? marginCm;
  for (final dynamic op in ops) {
    if (op is! Map) continue;
    final dynamic attrs = op['attributes'];
    if (attrs is! Map) continue;
    final dynamic orientation = attrs['page-orientation'];
    if (orientation == 'landscape') {
      landscape = true;
    } else if (orientation == 'portrait') {
      landscape = false;
    }
    final double? parsed = parsePageMarginCm(attrs['page-margin']);
    if (parsed != null) marginCm = parsed;
  }
  if (!landscape && marginCm == null) return PdfPageSetup.standard;
  return PdfPageSetup(landscape: landscape, marginCm: marginCm);
}

/// Monta as opções de exportação para um [setup]: A4 na orientação declarada
/// e a margem do Delta — ou [defaultMarginCm] quando o Delta não declara (o
/// SALI usa 2 cm no documento assinado e 1 cm na exportação do editor).
PdfExportOptions pageSetupOptions(
  PdfPageSetup setup, {
  double defaultMarginCm = 2.0,
  double baseFontSize = 12,
  String fontFamily = 'Arial',
  String title = 'Documento',
  Map<String, Uint8List> resources = const <String, Uint8List>{},
  List<PdfFontFace> fontFaces = const <PdfFontFace>[],
}) {
  final double width = (setup.landscape ? 29.7 : 21.0) * _cmPt;
  final double height = (setup.landscape ? 21.0 : 29.7) * _cmPt;
  return PdfExportOptions(
    pageWidth: width,
    pageHeight: height,
    margin: (setup.marginCm ?? defaultMarginCm) * _cmPt,
    baseFontSize: baseFontSize,
    fontFamily: fontFamily,
    title: title,
    resources: resources,
    fontFaces: fontFaces,
  );
}

/// Op inválido encontrado na sanitização — a lista não era um Delta.
class InvalidPdfOperation implements Exception {
  InvalidPdfOperation(this.value);

  final Object? value;

  @override
  String toString() => 'Operação inválida para geração de PDF: $value';
}

/// Política de limpeza dos ops antes do PDF.
///
/// O preset [PdfSanitizePolicy.sali] reproduz a política do documento
/// assinado do SALI: monocromático (`color`/`background` fora), sem
/// sub/sobrescrito, atributos de página removidos (já lidos por
/// [readPdfPageSetup]) e `font` restrita a Inter/Arial/Calibri com os
/// aliases históricos.
class PdfSanitizePolicy {
  const PdfSanitizePolicy({
    this.blockedAttributes = const <String>{'page-orientation', 'page-margin'},
    this.allowedFontFamilies,
    this.fontFamilyAliases = const <String, String>{},
  });

  /// A política do PDF jurídico do SALI (`quill_pdf_sanitizer.dart`).
  static const PdfSanitizePolicy sali = PdfSanitizePolicy(
    blockedAttributes: <String>{
      'script',
      'color',
      'background',
      'page-orientation',
      'page-margin',
    },
    allowedFontFamilies: <String>{'inter', 'arial', 'calibri'},
    fontFamilyAliases: <String, String>{
      'arimo': 'arial',
      'helvetica': 'arial',
      'arial mt': 'arial',
      'calibri light': 'calibri',
    },
  );

  /// Atributos removidos de todo op.
  final Set<String> blockedAttributes;

  /// Famílias permitidas (tokens canônicos, minúsculos), ou null para não
  /// filtrar fonte.
  final Set<String>? allowedFontFamilies;

  /// Aliases aplicados antes da whitelist (`helvetica` → `arial`).
  final Map<String, String> fontFamilyAliases;

  /// Normaliza um `font-family` para o token canônico da política, ou null
  /// quando a família deve ser descartada (a fonte padrão do tema assume).
  String? normalizeFontFamily(Object? raw) {
    final Set<String>? allowed = allowedFontFamilies;
    if (allowed == null) return raw is String ? raw : null;
    if (raw is! String || raw.trim().isEmpty) return null;
    var family = raw
        .split(',')
        .first
        .replaceAll(RegExp('["\']'), '')
        .trim()
        .toLowerCase();
    family = fontFamilyAliases[family] ?? family;
    return allowed.contains(family) ? family : null;
  }
}

/// Aplica [policy] aos [ops], devolvendo uma cópia limpa; lança
/// [InvalidPdfOperation] quando um item não é um op.
List<Map<String, dynamic>> sanitizeOpsForPdf(
  Iterable<dynamic> ops, {
  PdfSanitizePolicy policy = const PdfSanitizePolicy(),
}) {
  return ops.map<Map<String, dynamic>>((dynamic rawOp) {
    if (rawOp is! Map) throw InvalidPdfOperation(rawOp);

    final Map<String, dynamic> normalized = Map<String, dynamic>.from(rawOp);
    final dynamic insertRaw = normalized['insert'];
    if (insertRaw is Map) {
      normalized['insert'] = Map<String, dynamic>.from(insertRaw);
    }

    final dynamic attrsRaw = normalized['attributes'];
    if (attrsRaw is Map) {
      final Map<String, dynamic> attrs = Map<String, dynamic>.from(attrsRaw);
      for (final String attribute in policy.blockedAttributes) {
        attrs.remove(attribute);
      }
      if (policy.allowedFontFamilies != null && attrs.containsKey('font')) {
        final String? family = policy.normalizeFontFamily(attrs['font']);
        if (family == null) {
          attrs.remove('font');
        } else {
          attrs['font'] = family;
        }
      }
      if (attrs.isEmpty) {
        normalized.remove('attributes');
      } else {
        normalized['attributes'] = attrs;
      }
    }
    return normalized;
  }).toList();
}
