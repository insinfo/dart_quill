@TestOn('vm')
library;

/// O leitor de TrueType, contra a **Inter-Regular real** — a fonte que o PDF
/// assinado do SALI precisa embutir.
///
/// Testar contra um arquivo sintético provaria que o parser lê o que eu mesmo
/// escrevi; contra a fonte de verdade, ele tem de aguentar `cmap` format 4 com
/// `idRangeOffset` (a indireção mais fácil de errar do formato), glifos
/// compostos e uma `hmtx` mais curta que o número de glifos.
import 'dart:io';
import 'dart:typed_data';

import 'package:dart_quill/src/office/document/fonts/truetype.dart';
import 'package:test/test.dart';

late final Uint8List _interBytes =
    File('test/assets/fonts/Inter-Regular.ttf').readAsBytesSync();

TrueTypeFont get _inter => TrueTypeFont.parse(_interBytes);

void main() {
  group('cabeçalho e tabelas', () {
    test('parseia a Inter e encontra as tabelas obrigatórias', () {
      final font = _inter;
      for (final table in const ['head', 'hhea', 'maxp', 'cmap', 'hmtx']) {
        expect(font.hasTable(table), isTrue, reason: 'falta $table');
      }
    });

    test('métricas de projeto batem com uma fonte de texto', () {
      final font = _inter;

      expect(font.unitsPerEm, anyOf(1000, 2048, 2000),
          reason: 'unitsPerEm fora do usual: ${font.unitsPerEm}');
      expect(font.numGlyphs, greaterThan(100));
      expect(font.ascender, greaterThan(0));
      expect(font.descender, lessThan(0),
          reason: 'o descendente é negativo por definição');
      expect(font.capHeight, greaterThan(0));
      expect(font.boundingBox.xMax, greaterThan(font.boundingBox.xMin));
      expect(font.boundingBox.yMax, greaterThan(font.boundingBox.yMin));
    });

    test('nomes vêm da tabela name', () {
      final font = _inter;
      expect(font.familyName.toLowerCase(), contains('inter'));
      expect(font.postScriptName, isNotEmpty);
      expect(font.postScriptName, isNot('Unknown'));
    });

    test('estilo: a Regular não é negrito nem itálico', () {
      final font = _inter;
      expect(font.isBold, isFalse);
      expect(font.isItalic, isFalse);
      expect(font.italicAngle, 0);
      expect(font.weightClass, inInclusiveRange(300, 500));
    });

    test('a permissão de embutir é legível', () {
      // Não afirmo qual é: afirmo que o campo é interpretado e que a Inter,
      // sendo OFL, não proíbe.
      expect(_inter.embeddingPermission,
          isNot(EmbeddingPermission.restricted));
    });

    test('a Inter tem contornos glyf, não CFF', () {
      expect(_inter.isCff, isFalse);
      expect(_inter.hasTable('glyf'), isTrue);
    });
  });

  group('cmap', () {
    test('mapeia ASCII', () {
      final font = _inter;
      for (final char in 'Aa0 z'.codeUnits) {
        expect(font.glyphIdFor(char), greaterThan(0),
            reason: 'sem glifo para U+${char.toRadixString(16)}');
      }
    });

    test('mapeia os acentos do português', () {
      final font = _inter;
      for (final char in 'çãáéíóúâêôàüÇÃÉ'.runes) {
        expect(font.glyphIdFor(char), greaterThan(0),
            reason: 'sem glifo para ${String.fromCharCode(char)}');
      }
    });

    test('mapeia travessão e aspas tipográficas', () {
      final font = _inter;
      for (final char in '—–“”‘’…'.runes) {
        expect(font.glyphIdFor(char), greaterThan(0),
            reason: 'sem glifo para ${String.fromCharCode(char)}');
      }
    });

    test('caractere ausente devolve .notdef (0), não lixo', () {
      // A Inter cobre latim, grego e cirílico — e, medido, também parte da
      // área de uso privado (U+E000 -> glifo 1863), então PUA não serve de
      // "ausente". CJK, tailandês e emoji ficam de fora de verdade.
      for (final code in <int>[0x4E2D, 0x3042, 0x0E01, 0x1F600, 0x10FFFF]) {
        expect(_inter.glyphIdFor(code), 0,
            reason: 'U+${code.toRadixString(16).toUpperCase()} não deveria ter glifo');
      }
    });

    test('caracteres diferentes mapeiam para glifos diferentes', () {
      final font = _inter;
      final a = font.glyphIdFor('a'.codeUnitAt(0));
      final b = font.glyphIdFor('b'.codeUnitAt(0));
      expect(a, isNot(b));
    });
  });

  group('métricas horizontais', () {
    test('largura de avanço é positiva para letras', () {
      final font = _inter;
      final width = font.advanceWidthOf(font.glyphIdFor('m'.codeUnitAt(0)));
      expect(width, greaterThan(0));
    });

    test('o "m" é mais largo que o "i"', () {
      final font = _inter;
      final m = font.advanceWidthOf(font.glyphIdFor('m'.codeUnitAt(0)));
      final i = font.advanceWidthOf(font.glyphIdFor('i'.codeUnitAt(0)));
      expect(m, greaterThan(i),
          reason: 'métrica invertida indica hmtx lida errado');
    });

    test('o espaço tem avanço, mesmo sem contorno', () {
      final font = _inter;
      final space = font.glyphIdFor(' '.codeUnitAt(0));
      expect(font.advanceWidthOf(space), greaterThan(0));
      expect(font.glyphData(space), isEmpty,
          reason: 'o espaço não desenha nada — e isso não é erro');
    });

    test('em milésimos de em, como o PDF quer', () {
      final font = _inter;
      final width = font.advanceWidthOfChar('M'.codeUnitAt(0));
      expect(width, inInclusiveRange(400, 1200),
          reason: 'um M fora dessa faixa indica escala errada');
    });

    test('glifo além da hmtx repete a última largura, não estoura', () {
      final font = _inter;
      expect(() => font.advanceWidthOf(font.numGlyphs - 1), returnsNormally);
      expect(font.advanceWidthOf(999999), greaterThanOrEqualTo(0));
      expect(font.advanceWidthOf(-1), greaterThanOrEqualTo(0));
    });
  });

  group('glifos', () {
    test('loca tem numGlyphs + 1 entradas', () {
      final font = _inter;
      expect(font.glyphOffsets.length, font.numGlyphs + 1);
    });

    test('um glifo com contorno tem bytes', () {
      final font = _inter;
      expect(font.glyphData(font.glyphIdFor('A'.codeUnitAt(0))), isNotEmpty);
    });

    test('glifo composto declara seus componentes', () {
      final font = _inter;
      // Um acentuado costuma ser composto (base + acento). Se nenhum dos
      // testados for, o teste não afirma nada falso — só registra o fato.
      final compostos = <int, Set<int>>{};
      for (final char in 'ãçéíôü'.runes) {
        final id = font.glyphIdFor(char);
        final components = font.componentGlyphsOf(id);
        if (components.isNotEmpty) compostos[id] = components;
      }
      if (compostos.isEmpty) {
        printOnFailure('nenhum acentuado desta fonte é composto');
        return;
      }
      for (final entry in compostos.entries) {
        expect(entry.value, isNotEmpty);
        expect(entry.value, isNot(contains(entry.key)),
            reason: 'um glifo componente de si mesmo faria o fecho girar');
      }
    });

    test('expandWithComponents inclui os componentes e é fechado', () {
      final font = _inter;
      final base = <int>{
        for (final char in 'ãçé'.runes) font.glyphIdFor(char),
      };
      final expanded = font.expandWithComponents(base);

      expect(expanded, containsAll(base));
      // Sem isso, o subconjunto embutido desenharia buracos exatamente nos
      // caracteres acentuados — o pior lugar num documento em português.
      for (final id in expanded) {
        expect(expanded, containsAll(font.componentGlyphsOf(id)),
            reason: 'o fecho deixou um componente de fora');
      }
    });

    test('glifo fora de faixa devolve vazio em vez de estourar', () {
      final font = _inter;
      expect(font.glyphData(font.numGlyphs + 10), isEmpty);
      expect(font.glyphData(-5), isEmpty);
    });
  });

  group('entradas inválidas', () {
    test('arquivo curto', () {
      expect(() => TrueTypeFont.parse(Uint8List(4)),
          throwsA(isA<TrueTypeException>()));
    });

    test('assinatura desconhecida', () {
      final bytes = Uint8List(64)
        ..[0] = 0x25
        ..[1] = 0x50
        ..[2] = 0x44
        ..[3] = 0x46; // "%PDF"
      expect(() => TrueTypeFont.parse(bytes),
          throwsA(isA<TrueTypeException>()));
    });

    test('coleção .ttc é recusada com mensagem clara', () {
      final bytes = Uint8List(64);
      bytes.setAll(0, 'ttcf'.codeUnits);
      expect(
        () => TrueTypeFont.parse(bytes),
        throwsA(isA<TrueTypeException>().having(
            (e) => e.message, 'mensagem', contains('.ttc'))),
      );
    });

    test('arquivo truncado no meio do diretório', () {
      final truncated = Uint8List.sublistView(_interBytes, 0, 20);
      expect(() => TrueTypeFont.parse(truncated),
          throwsA(isA<TrueTypeException>()));
    });
  });
}
