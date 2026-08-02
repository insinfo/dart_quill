import '../../platform/dom.dart';

import 'normalizers/google_docs.dart';
import 'normalizers/ms_word.dart';
import 'normalizers/word_paste.dart';

typedef ExternalHTMLNormalizer = void Function(DomDocument doc);

class NormalizeExternalHTML {
  NormalizeExternalHTML({
    List<ExternalHTMLNormalizer>? normalizers,
  }) : _normalizers = List.unmodifiable(
          // O estendido roda ANTES do nativo: converte os grupos com a
          // lógica melhor e tira do alcance dele o que preservou literal.
          normalizers ?? [normalizeWordPaste, normalizeMsWord, normalizeGoogleDocs],
        );

  final List<ExternalHTMLNormalizer> _normalizers;

  void normalize(DomDocument doc) {
    for (final normalizer in _normalizers) {
      // W9: uma exceção num normalizador não pode quebrar o paste inteiro —
      // o HTML segue para os demais como está (o plugin do SALI faz igual).
      try {
        normalizer(doc);
      } catch (_) {
        // O paste continua com o HTML original.
      }
    }
  }

  void call(DomDocument doc) => normalize(doc);
}

final normalizeExternalHTML = NormalizeExternalHTML();
