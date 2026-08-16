/// O encaixe do run desenhado na caixa que o compositor reservou.
///
/// O defeito que estes testes protegem é visível no PDF do ETP de referência:
/// um run em NEGRITO era medido pelo compositor com a largura do peso normal
/// (o `FontRegistry` não tem variante de peso) e desenhado com
/// Helvetica-Bold, ~4% mais larga. O run invadia o seguinte, e a linha saía
/// "…gestão pública municipa[l], no modelo…" com as duas partes sobrepostas.
/// O mesmo acontecia com a Ecofont dos corpora PGCTIC, que o registro resolve
/// para Calibri/Carlito (~7% mais estreita que a Helvetica do PDF): o espaço
/// final de um run era engolido, e o cabeçalho saía "Processo nº44505/2025".
@TestOn('vm')
library;

import 'package:test/test.dart';

import 'package:dart_quill/src/document_engine/layout/pdf_standard_widths.dart';

void main() {
  group('tabelas AFM', () {
    test('trazem as larguras oficiais das standard-14', () {
      // Valores das AFM da Adobe — a prova de que a tabela não é um palpite.
      final helvetica = officeStandard14Widths['Helvetica']!;
      expect(helvetica.advanceWidths[0x20], 278, reason: 'espaço');
      expect(helvetica.advanceWidths[0x41], 667, reason: 'A');
      expect(helvetica.advanceWidths[0x69], 222, reason: 'i');

      final bold = officeStandard14Widths['Helvetica-Bold']!;
      expect(bold.advanceWidths[0x41], 722, reason: 'A em negrito é mais larga');
      expect(bold.advanceWidths[0x20], 278);

      final times = officeStandard14Widths['Times-Roman']!;
      expect(times.advanceWidths[0x41], 722);
      expect(officeStandard14Widths['Times-Bold']!.advanceWidths[0x41], 722);

      // Courier é monoespaçada: 600 em qualquer glifo, inclusive nos que não
      // estão na tabela.
      final courier = officeStandard14Widths['Courier']!;
      expect(courier.measureWidth('abc', 1000), 1800);
      expect(courier.measureWidth('MMM', 1000), 1800);
    });

    test('cobrem o repertório WinAnsi que o encoder sabe escrever', () {
      final helvetica = officeStandard14Widths['Helvetica']!;
      for (final rune in 'áéíóúâêôãõçàüñ€“”–—…'.runes) {
        expect(helvetica.advanceWidths[rune], isNotNull,
            reason: 'sem largura para U+${rune.toRadixString(16)} a conta de '
                'encaixe cairia no avanço padrão');
      }
    });

    test('itálico da Helvetica tem as MESMAS larguras do romano', () {
      // É assim nas AFM da Adobe; a tabela precisa refletir isso, senão o
      // encaixe "corrigiria" uma diferença que não existe.
      final roman = officeStandard14Widths['Helvetica']!;
      final oblique = officeStandard14Widths['Helvetica-Oblique']!;
      for (final rune in 'Aai1 .'.runes) {
        expect(oblique.advanceWidths[rune], roman.advanceWidths[rune]);
      }
    });
  });

  group('encaixe do run na caixa', () {
    const text = 'sistema integrado de gestão pública municipal';
    const sizePt = 10.0;

    double drawnWidth(String font, double perChar) =>
        officeStandard14NaturalWidthPt(
          text: text,
          pdfFont: font,
          sizePt: sizePt,
        ) +
        perChar * text.runes.length;

    test('negrito medido como normal é COMPRIMIDO até a caixa', () {
      // A caixa que o compositor reservou: ele mediu com métricas do peso
      // NORMAL, porque é só isso que o registro tem.
      final box = officeStandard14NaturalWidthPt(
        text: text,
        pdfFont: 'Helvetica',
        sizePt: sizePt,
      );
      final natural = officeStandard14NaturalWidthPt(
        text: text,
        pdfFont: 'Helvetica-Bold',
        sizePt: sizePt,
      );
      expect(natural, greaterThan(box),
          reason: 'é justamente esta diferença que fazia o run invadir o '
              'seguinte');

      final perChar = officeStandard14FitPerCharPt(
        text: text,
        pdfFont: 'Helvetica-Bold',
        sizePt: sizePt,
        letterSpacingPt: 0,
        wordSpacingPt: 0,
        targetWidthPt: box,
      );
      expect(perChar, lessThan(0), reason: 'comprime, não estica');
      expect(drawnWidth('Helvetica-Bold', perChar), closeTo(box, 0.01),
          reason: 'o run desenhado tem de terminar onde a caixa termina');
    });

    test('caixa maior que o natural ESTICA (fonte mais estreita que a do PDF)',
        () {
      // O caso da Ecofont→Calibri: o compositor mede mais estreito do que a
      // Helvetica desenha… e o contrário também tem de funcionar.
      final natural = officeStandard14NaturalWidthPt(
          text: text, pdfFont: 'Helvetica', sizePt: sizePt);
      final perChar = officeStandard14FitPerCharPt(
        text: text,
        pdfFont: 'Helvetica',
        sizePt: sizePt,
        letterSpacingPt: 0,
        wordSpacingPt: 0,
        targetWidthPt: natural + 12,
      );
      expect(perChar, greaterThan(0));
      expect(drawnWidth('Helvetica', perChar), closeTo(natural + 12, 0.01));
    });

    test('sem diferença relevante não há correção nenhuma', () {
      final natural = officeStandard14NaturalWidthPt(
          text: text, pdfFont: 'Helvetica', sizePt: sizePt);
      expect(
        officeStandard14FitPerCharPt(
          text: text,
          pdfFont: 'Helvetica',
          sizePt: sizePt,
          letterSpacingPt: 0,
          wordSpacingPt: 0,
          targetWidthPt: natural + 0.05,
        ),
        0,
      );
    });

    test('espaçamento de caractere e de palavra entram na conta', () {
      const spaced = 'P á g i n a ';
      final natural = officeStandard14NaturalWidthPt(
        text: spaced,
        pdfFont: 'Helvetica',
        sizePt: 9,
        letterSpacingPt: 1.5,
        wordSpacingPt: 0.5,
      );
      final plain = officeStandard14NaturalWidthPt(
          text: spaced, pdfFont: 'Helvetica', sizePt: 9);
      expect(natural, greaterThan(plain),
          reason: 'o `w:spacing` do OOXML avança depois de CADA caractere');
      final perChar = officeStandard14FitPerCharPt(
        text: spaced,
        pdfFont: 'Helvetica',
        sizePt: 9,
        letterSpacingPt: 1.5,
        wordSpacingPt: 0.5,
        targetWidthPt: natural - 3,
      );
      expect(natural + perChar * spaced.runes.length, closeTo(natural - 3, 0.01));
    });

    test('uma caixa absurda não vira um amontoado ilegível', () {
      final perChar = officeStandard14FitPerCharPt(
        text: text,
        pdfFont: 'Helvetica',
        sizePt: sizePt,
        letterSpacingPt: 0,
        wordSpacingPt: 0,
        targetWidthPt: 1,
      );
      final natural = officeStandard14NaturalWidthPt(
          text: text, pdfFont: 'Helvetica', sizePt: sizePt);
      expect(drawnWidth('Helvetica', perChar), closeTo(natural / 2, 0.01),
          reason: 'o piso é metade da largura natural');
    });

    test('fonte desconhecida não é corrigida', () {
      expect(
        officeStandard14FitPerCharPt(
          text: text,
          pdfFont: 'Symbol',
          sizePt: sizePt,
          letterSpacingPt: 0,
          wordSpacingPt: 0,
          targetWidthPt: 10,
        ),
        0,
      );
    });
  });
}
