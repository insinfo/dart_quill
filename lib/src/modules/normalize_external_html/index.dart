import '../../platform/dom.dart';

import 'normalizers/google_docs.dart';
import 'normalizers/ms_word.dart';

typedef ExternalHTMLNormalizer = void Function(DomDocument doc);

class NormalizeExternalHTML {
  NormalizeExternalHTML({
    List<ExternalHTMLNormalizer>? normalizers,
  }) : _normalizers = List.unmodifiable(
          normalizers ?? [normalizeMsWord, normalizeGoogleDocs],
        );

  final List<ExternalHTMLNormalizer> _normalizers;

  void normalize(DomDocument doc) {
    for (final normalizer in _normalizers) {
      normalizer(doc);
    }
  }

  void call(DomDocument doc) => normalize(doc);
}

final normalizeExternalHTML = NormalizeExternalHTML();
