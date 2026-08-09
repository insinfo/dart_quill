@TestOn('vm')
library;

import 'package:test/test.dart';

import 'package:dart_quill/src/office/document/fonts/font_metrics.dart';
import 'package:dart_quill/src/office/document/fonts/font_registry.dart';

void main() {
  test('override anterior ao primeiro lookup sobrevive à inicialização lazy',
      () {
    final registry = FontRegistry.instance;
    final override = FontMetrics(
      unitsPerEm: 1000,
      ascent: 750,
      descent: 250,
      lineGap: 150,
      advanceWidths: const {32: 500, 65: 777},
      defaultAdvance: 600,
    );

    // Carlito também existe na tabela embarcada. Antes da regressão ser
    // corrigida, o primeiro lookup inicializava a tabela depois deste registro
    // e sobrescrevia silenciosamente a face fornecida pela aplicação.
    registry.register('Carlito', override);

    expect(registry.lookup('Carlito'), same(override));
    expect(registry.lookup('Calibri'), same(override));
    expect(registry.lookup('Ecofont_Spranq_eco_Sans'), same(override));
  });
}
