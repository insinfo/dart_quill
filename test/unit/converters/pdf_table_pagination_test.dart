/// P14 — tabela atravessando páginas.
///
/// As páginas eram serializadas na hora da quebra, então uma tabela
/// multi-página desenhava TODAS as células na última página (sobrepostas) e
/// deixava as anteriores em branco; uma linha mais alta que a página
/// simplesmente transbordava para fora da área útil. Agora a tabela é mapeada
/// em bandas e cada célula desenha segmento a segmento na página certa.
@TestOn('vm')
library;

import 'dart:typed_data';

import 'package:dart_quill/dart_quill_pdf.dart';
import 'package:dart_quill/src/delta/delta.dart';
import 'package:test/test.dart';

import '../../support/pdf_reader.dart';

void main() {
  /// Retângulos contornados e ops de texto por stream de página.
  List<({int rects, int texts})> perPage(Uint8List pdf) => [
        for (final stream in PdfReader(pdf).decodedStreams)
          if (RegExp(r're S').hasMatch(stream) || stream.contains('Tj'))
            (
              rects: RegExp(r're S').allMatches(stream).length,
              texts: RegExp(r'Tj').allMatches(stream).length,
            )
      ];

  Delta tableOf(int rows, {int paragraphsInFirstCell = 1}) {
    final delta = Delta()
      ..insert('\n', {
        'table-temporary': {'data-class': 'ql-table-better'}
      })
      ..insert('\n', {
        'table-col': {'width': '300'}
      })
      ..insert('\n', {
        'table-col': {'width': '300'}
      });
    for (int r = 0; r < rows; r++) {
      for (int p = 0; p < (r == 0 ? paragraphsInFirstCell : 1); p++) {
        delta
          ..insert('linha $r parágrafo $p')
          ..insert('\n', {
            'table-cell-block': 'a$r',
            'table-cell': {'data-row': 'r$r'},
          });
      }
      delta
        ..insert('lado $r')
        ..insert('\n', {
          'table-cell-block': 'b$r',
          'table-cell': {'data-row': 'r$r'},
        });
    }
    delta.insert('\n');
    return delta;
  }

  test('tabela longa distribui células por TODAS as páginas', () {
    final pages = perPage(deltaToPdf(tableOf(40)));
    expect(pages.length, greaterThanOrEqualTo(2));
    for (final page in pages) {
      expect(page.rects, greaterThan(0),
          reason: 'toda página da tabela tem bordas de célula: $pages');
      expect(page.texts, greaterThan(0),
          reason: 'toda página da tabela tem conteúdo: $pages');
    }
  });

  test('linha única mais alta que a página FLUI em vez de transbordar', () {
    // Uma linha só, com 120 parágrafos na primeira célula: ~3 páginas.
    final pages = perPage(deltaToPdf(tableOf(1, paragraphsInFirstCell: 120)));
    expect(pages.length, greaterThanOrEqualTo(3),
        reason: 'a linha gigante deve ocupar várias páginas: $pages');
    for (final page in pages) {
      expect(page.rects, greaterThan(0),
          reason: 'cada segmento redesenha a moldura da célula: $pages');
    }
  });

  test('texto não desce além da margem inferior', () {
    final streams = PdfReader(deltaToPdf(tableOf(40))).decodedStreams;
    for (final stream in streams) {
      for (final m in RegExp(r'[-\d.]+ ([-\d.]+) Td').allMatches(stream)) {
        final y = double.parse(m.group(1)!);
        // A4 com margem de 2cm: baseline nunca abaixo de ~40pt (margem menos
        // uma linha de tolerância de bloco partido).
        expect(y, greaterThan(40),
            reason: 'baseline abaixo da área útil: y=$y');
      }
    }
  });
}
