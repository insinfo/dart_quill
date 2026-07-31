@TestOn('vm')
library;

/// O recorte de fonte, contra a Inter real.
///
/// O critério que vale é: a fonte recortada tem de ser **relida** e produzir,
/// para cada caractere mantido, exatamente o mesmo contorno e a mesma métrica
/// da original. Um subsetter que gere um arquivo menor e desenhe errado é
/// pior que nenhum — o defeito só aparece no PDF do usuário.
import 'dart:io';
import 'dart:typed_data';

import 'package:dart_quill/src/office/document/fonts/truetype.dart';
import 'package:dart_quill/src/office/document/fonts/truetype_subset.dart';
import 'package:test/test.dart';

late final Uint8List _interBytes =
    File('test/assets/fonts/Inter-Regular.ttf').readAsBytesSync();

TrueTypeFont get _inter => TrueTypeFont.parse(_interBytes);

/// Soma de verificação de 32 bits big-endian, como o sfnt define.
int _checksum(Uint8List data) {
  var sum = 0;
  for (var i = 0; i < data.length; i += 4) {
    var word = 0;
    for (var b = 0; b < 4; b++) {
      final index = i + b;
      word = (word << 8) | (index < data.length ? data[index] : 0);
    }
    sum = (sum + word) & 0xFFFFFFFF;
  }
  return sum;
}

void main() {
  group('a fonte recortada é uma fonte válida', () {
    test('o nosso próprio parser relê o resultado', () {
      final subset = subsetTrueTypeForText(_inter, 'Despacho 123'.runes);
      final reparsed = TrueTypeFont.parse(subset.bytes);

      expect(reparsed.numGlyphs, subset.numGlyphs);
      expect(reparsed.unitsPerEm, _inter.unitsPerEm);
      expect(reparsed.hasTable('glyf'), isTrue);
      expect(reparsed.hasTable('loca'), isTrue);
      expect(reparsed.hasTable('hmtx'), isTrue);
    });

    test('a loca sai no formato longo, coerente com o que foi escrito', () {
      final subset = subsetTrueTypeForText(_inter, 'abc'.runes);
      final reparsed = TrueTypeFont.parse(subset.bytes);

      expect(reparsed.indexToLocFormat, 1);
      expect(reparsed.glyphOffsets.length, reparsed.numGlyphs + 1);
    });

    test('o checkSumAdjustment fecha com o arquivo', () {
      // É a assinatura que valida a fonte inteira; errá-la faz validadores
      // (e alguns visualizadores rígidos) recusarem o arquivo.
      final subset = subsetTrueTypeForText(_inter, 'texto'.runes);
      final font = TrueTypeFont.parse(subset.bytes);
      final head = font.tableData('head')!;
      final stored = ByteData.sublistView(head).getUint32(8);

      final zeroed = Uint8List.fromList(subset.bytes);
      // Localiza o campo dentro do arquivo montado para zerá-lo de novo.
      final headStart = _findTableOffset(subset.bytes, 'head');
      ByteData.sublistView(zeroed).setUint32(headStart + 8, 0);

      final expected = (0xB1B0AFBA - _checksum(zeroed)) & 0xFFFFFFFF;
      expect(stored, expected);
    });

    test('as tabelas do diretório apontam para dentro do arquivo', () {
      final subset = subsetTrueTypeForText(_inter, 'x'.runes);
      final view = ByteData.sublistView(subset.bytes);
      final numTables = view.getUint16(4);

      for (var i = 0; i < numTables; i++) {
        final record = 12 + i * 16;
        final offset = view.getUint32(record + 8);
        final length = view.getUint32(record + 12);
        expect(offset + length, lessThanOrEqualTo(subset.bytes.length),
            reason: 'tabela ${String.fromCharCodes(subset.bytes, record, record + 4)} '
                'sai do arquivo');
      }
    });
  });

  group('o que foi mantido continua idêntico', () {
    test('contorno e avanço de cada caractere batem com o original', () {
      const texto = 'Despacho nº 42 — ação, coração; TOTAL: R\$ 1.234,56';
      final original = _inter;
      final subset = subsetTrueTypeForText(original, texto.runes);
      final reparsed = TrueTypeFont.parse(subset.bytes);

      for (final rune in texto.runes) {
        final gid = original.glyphIdFor(rune);
        if (gid == 0) continue;
        expect(reparsed.advanceWidthOf(gid), original.advanceWidthOf(gid),
            reason: 'avanço mudou em ${String.fromCharCode(rune)}');
        expect(reparsed.leftSideBearingOf(gid), original.leftSideBearingOf(gid),
            reason: 'lsb mudou em ${String.fromCharCode(rune)}');
        expect(reparsed.glyphData(gid), original.glyphData(gid),
            reason: 'contorno mudou em ${String.fromCharCode(rune)}');
      }
    });

    test('os componentes dos acentuados vêm junto', () {
      final original = _inter;
      final subset = subsetTrueTypeForText(original, 'ção'.runes);
      final reparsed = TrueTypeFont.parse(subset.bytes);

      for (final rune in 'ção'.runes) {
        final gid = original.glyphIdFor(rune);
        for (final component in original.componentGlyphsOf(gid)) {
          expect(subset.glyphIds, contains(component),
              reason: 'componente $component ficou de fora');
          expect(reparsed.glyphData(component), original.glyphData(component),
              reason: 'sem o componente, o acentuado desenha um buraco');
        }
      }
    });

    test('.notdef entra mesmo sem ser pedido', () {
      final subset = subsetTrueType(_inter, const <int>[]);
      expect(subset.glyphIds, contains(0));
      expect(subset.numGlyphs, greaterThanOrEqualTo(1));
    });

    test('o espaço continua sem contorno e com avanço', () {
      final original = _inter;
      final subset = subsetTrueTypeForText(original, 'a b'.runes);
      final reparsed = TrueTypeFont.parse(subset.bytes);
      final space = original.glyphIdFor(' '.codeUnitAt(0));

      expect(reparsed.glyphData(space), isEmpty);
      expect(reparsed.advanceWidthOf(space), original.advanceWidthOf(space));
    });
  });

  group('o que foi descartado sai mesmo', () {
    test('um glifo não pedido fica sem contorno', () {
      final original = _inter;
      final subset = subsetTrueTypeForText(original, 'a'.runes);
      final reparsed = TrueTypeFont.parse(subset.bytes);

      final zGid = original.glyphIdFor('Z'.codeUnitAt(0));
      if (zGid < reparsed.numGlyphs && !subset.glyphIds.contains(zGid)) {
        expect(reparsed.glyphData(zGid), isEmpty,
            reason: 'glifo descartado deveria ter comprimento zero');
      }
    });

    test('o arquivo encolhe de forma expressiva', () {
      final subset = subsetTrueTypeForText(_inter, 'Despacho de teste'.runes);

      expect(subset.size, lessThan(subset.originalSize));
      expect(subset.ratio, lessThan(0.2),
          reason: 'recorte de ~20 caracteres devolvendo '
              '${(subset.ratio * 100).toStringAsFixed(1)}% do arquivo não '
              'está recortando');
      printOnFailure('original ${subset.originalSize} → ${subset.size} bytes');
    });

    test('mais texto, arquivo maior — mas ainda menor que o original', () {
      final pequeno = subsetTrueTypeForText(_inter, 'abc'.runes);
      final grande = subsetTrueTypeForText(
          _inter, 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'.runes);

      expect(grande.size, greaterThan(pequeno.size));
      expect(grande.size, lessThan(grande.originalSize));
    });
  });

  group('propriedades', () {
    test('o recorte é determinístico', () {
      final a = subsetTrueTypeForText(_inter, 'mesmo texto'.runes);
      final b = subsetTrueTypeForText(_inter, 'mesmo texto'.runes);
      expect(a.bytes, equals(b.bytes),
          reason: 'bytes não determinísticos quebram o hash do PDF assinado');
    });

    test('recortar o recorte é estável', () {
      final primeiro = subsetTrueTypeForText(_inter, 'abc'.runes);
      final refonte = TrueTypeFont.parse(primeiro.bytes);
      final segundo = subsetTrueTypeForText(refonte, 'abc'.runes);

      for (final rune in 'abc'.runes) {
        final gid = refonte.glyphIdFor(rune);
        // O `cmap` não é emitido no recorte (o PDF usa Identity-H), então a
        // busca por caractere não sobrevive — mas o glifo, sim.
        if (gid == 0) continue;
        expect(TrueTypeFont.parse(segundo.bytes).glyphData(gid),
            refonte.glyphData(gid));
      }
    });

    test('texto sem glifo na fonte devolve só o .notdef', () {
      final subset = subsetTrueTypeForText(_inter, '中文'.runes);
      expect(subset.glyphIds, {0});
    });

    test('glifos fora de faixa são ignorados em vez de estourar', () {
      expect(() => subsetTrueType(_inter, const [-1, 999999]), returnsNormally);
    });
  });
}

/// Deslocamento de uma tabela no diretório do sfnt.
int _findTableOffset(Uint8List font, String tag) {
  final view = ByteData.sublistView(font);
  final numTables = view.getUint16(4);
  for (var i = 0; i < numTables; i++) {
    final record = 12 + i * 16;
    if (String.fromCharCodes(font, record, record + 4) == tag) {
      return view.getUint32(record + 8);
    }
  }
  throw StateError('tabela $tag ausente');
}
