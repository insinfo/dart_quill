@TestOn('vm')
library;

import 'package:test/test.dart';

import 'package:dart_quill/src/office/document/fonts/font_registry.dart';
import 'package:dart_quill/src/office/document/pdf/pdf_content.dart'
    show standardFontFor;

void main() {
  final registry = FontRegistry.instance;

  test('expõe a cadeia de compatibilidade OOXML sem perder a métrica final',
      () {
    expect(
      registry.fallbackFamilyStack('Ecofont_Spranq_eco_Sans'),
      ['calibri', 'carlito', 'arial'],
    );
    expect(
      registry.metricFallbackFamily('Ecofont_Spranq_eco_Sans'),
      'carlito',
    );
    expect(registry.metricFallbackFamily('Fonte Inexistente'), 'arial');
  });

  test('genéricas e substitutas mantêm a categoria tipográfica', () {
    expect(registry.metricFallbackFamily('serif'), 'times new roman');
    expect(registry.metricFallbackFamily('Cambria'), 'times new roman');
    expect(registry.metricFallbackFamily('monospace'), 'courier new');
    expect(registry.metricFallbackFamily('Consolas'), 'courier new');
    expect(registry.metricFallbackFamily('sans-serif'), 'arial');
    expect(registry.metricFallbackFamily('Arial MT'), 'arial');
  });

  test('face compatível mantém a caixa single do Word em 1,15 em', () {
    final metrics = registry.lookup('Carlito')!;
    final em = (metrics.ascent + metrics.descent + metrics.lineGap) /
        metrics.unitsPerEm;
    expect(em, closeTo(1.15, 0.001));
    expect((em * 12 * 20).round(), 276);
  });

  test('a cadeia devolvida é imutável', () {
    final stack = registry.fallbackFamilyStack('Ecofont');
    expect(() => stack.add('outra'), throwsUnsupportedError);
  });

  test('ciclo de aliases termina no fallback seguro', () {
    registry.alias('__dq_cycle_a__', '__dq_cycle_b__');
    registry.alias('__dq_cycle_b__', '__dq_cycle_a__');
    expect(
      registry.fallbackFamilyStack('__dq_cycle_a__'),
      ['__dq_cycle_b__', '__dq_cycle_a__', 'arial'],
    );
    expect(registry.metricFallbackFamily('__dq_cycle_a__'), 'arial');
  });

  test('seleção standard-14 concorda com as categorias do registro', () {
    expect(standardFontFor(family: 'Fonte Inexistente'), 'Helvetica');
    expect(standardFontFor(family: 'Ecofont_Spranq_eco_Sans'), 'Helvetica');
    expect(
      standardFontFor(
        family: 'Times New Roman',
        bold: true,
        italic: true,
      ),
      'Times-BoldItalic',
    );
    expect(
      standardFontFor(family: 'monospace', italic: true),
      'Courier-Oblique',
    );
    expect(
      standardFontFor(family: 'Consolas', bold: true),
      'Courier-Bold',
    );
  });
}
