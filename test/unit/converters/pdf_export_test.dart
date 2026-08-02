@TestOn('vm')
library;

/// `deltaToPdf` — the pure-Dart PDF exporter, over deltas produced by the real
/// system (`test/assets/delta/*.json`, exported from SALI documents).
///
/// The assertions read the PDF back instead of comparing bytes: a golden of
/// PDF bytes breaks on every unrelated change (object order, dates) and, when
/// it breaks, says nothing about what went wrong. What is pinned here is what
/// a reader would see — page count, catalog/page tree integrity, extractable
/// text, link annotations, embedded images — which is also what the SALI
/// signature flow depends on.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dart_quill/dart_quill_pdf.dart';
import 'package:dart_quill/src/office/document/pdf/pdf_writer.dart'
    show zlibDecode, zlibEncode;
import 'package:dart_quill/src/delta/delta.dart';
import 'package:test/test.dart';

import '../../support/pdf_reader.dart';

Delta _loadDelta(String name) {
  final file = File('test/assets/delta/$name');
  final decoded = jsonDecode(file.readAsStringSync());
  final ops = decoded is Map ? decoded['ops'] as List : decoded as List;
  return Delta.fromJson(ops);
}

Uint8List _pdfOf(Delta delta, {PdfExportOptions? options}) =>
    deltaToPdf(delta, options: options ?? const PdfExportOptions());

void main() {
  group('document structure', () {
    test('a minimal delta produces a readable one-page PDF', () {
      final bytes = _pdfOf(Delta()..insert('Despacho de teste\n'));
      final pdf = PdfReader(bytes);

      expect(pdf.header, startsWith('%PDF-1.'));
      expect(pdf.hasTrailerRoot, isTrue,
          reason: 'without /Root in the trailer no reader opens the file');
      expect(pdf.pageCount, 1);
      expect(pdf.endsWithEof, isTrue);
    });

    test('the cross-reference table points at real objects', () {
      final bytes = _pdfOf(Delta()..insert('Conteúdo\n'));
      final pdf = PdfReader(bytes);

      expect(pdf.xrefOffsets, isNotEmpty);
      for (final offset in pdf.xrefOffsets) {
        expect(offset, lessThan(bytes.length),
            reason: 'an xref entry pointing past EOF corrupts the document');
        expect(pdf.objectHeaderAt(offset), isNotNull,
            reason: 'every xref offset must land on "N 0 obj"');
      }
    });

    test('text is written as text, not as an image', () {
      final bytes = _pdfOf(Delta()..insert('palavra-chave\n'));
      final pdf = PdfReader(bytes);

      expect(pdf.extractText(), contains('palavra-chave'),
          reason: 'the signed document has to stay searchable and copyable');
    });

    test('page size and margins follow the options', () {
      // A4 landscape, 1 cm margins.
      final bytes = _pdfOf(
        Delta()..insert('x\n'),
        options: const PdfExportOptions(
          pageWidth: 841.89,
          pageHeight: 595.28,
          margin: 28.35,
        ),
      );
      final box = PdfReader(bytes).firstMediaBox!;

      expect(box[2], closeTo(841.89, 0.5));
      expect(box[3], closeTo(595.28, 0.5));
    });

    test('the title reaches the document information dictionary', () {
      final bytes = _pdfOf(
        Delta()..insert('x\n'),
        options: const PdfExportOptions(title: 'Despacho 123/2026'),
      );
      expect(PdfReader(bytes).rawLatin1, contains('Despacho 123/2026'));
    });
  });

  group('content', () {
    test('a long document paginates', () {
      final delta = Delta();
      for (var i = 0; i < 400; i++) {
        delta.insert('Linha $i com texto suficiente para ocupar a largura.\n');
      }
      expect(PdfReader(_pdfOf(delta)).pageCount, greaterThan(1));
    });

    test('a link becomes a clickable annotation', () {
      final delta = Delta()
        ..insert('portal', {'link': 'https://example.com/processo'})
        ..insert('\n');
      final pdf = PdfReader(_pdfOf(delta));

      expect(pdf.rawLatin1, contains('/Annots'));
      expect(pdf.rawLatin1, contains('https://example.com/processo'));
    });

    test('headers and inline formats do not lose the text', () {
      final delta = Delta()
        ..insert('Título')
        ..insert('\n', {'header': 1})
        ..insert('negrito', {'bold': true})
        ..insert(' e ')
        ..insert('itálico', {'italic': true})
        ..insert('\n');
      final text = PdfReader(_pdfOf(delta)).extractText();

      expect(text, contains('Título'));
      expect(text, contains('negrito'));
      expect(text, contains('itálico'));
    });

    test('a list keeps its items', () {
      final delta = Delta()
        ..insert('primeiro')
        ..insert('\n', {'list': 'bullet'})
        ..insert('segundo')
        ..insert('\n', {'list': 'bullet'});
      final text = PdfReader(_pdfOf(delta)).extractText();

      expect(text, contains('primeiro'));
      expect(text, contains('segundo'));
    });

    test('an empty document still produces a valid page', () {
      final pdf = PdfReader(_pdfOf(Delta()..insert('\n')));
      expect(pdf.pageCount, 1);
      expect(pdf.hasTrailerRoot, isTrue);
    });
  });

  group('real SALI documents', () {
    const fixtures = <String,
        ({
      String label,
      int pages,
      int maxPages,
      List<String> words,
      int minCellRects,
    })>{
      // P19: "abre" não bastava — um PDF estruturalmente válido pode estar
      // em branco. Cada fixture agora pina faixa de páginas, palavras que um
      // leitor extrairia e a presença das grades de tabela.
      'documento.delta.json': (
        label: 'documento',
        pages: 3, // ~4
        maxPages: 6,
        words: <String>['Servidores', 'NOME'],
        minCellRects: 100, // 129 linhas de célula no delta
      ),
      'ferias.delta.json': (
        label: 'férias',
        pages: 2, // ~3
        maxPages: 5,
        words: <String>['Servidores', 'NOME'],
        minCellRects: 100,
      ),
      'tabela_colunas_iguais.delta.json': (
        label: 'tabela com colunas iguais',
        pages: 2, // ~3
        maxPages: 5,
        words: <String>['Servidores', 'NOME'],
        minCellRects: 100,
      ),
      'termo_referencia.delta.json': (
        label: 'termo de referência (2 MB)',
        pages: 180, // ~224 (140 páginas de Word em A4 com margem de 2 cm)
        maxPages: 280,
        words: <String>['TERMO', 'Processo', 'SIAFIC'],
        minCellRects: 4000, // 5134 linhas de célula no delta
      ),
    };

    fixtures.forEach((file, expected) {
      test('${expected.label} renders with its real content', () {
        final result =
            deltaToPdfWithReport(_loadDelta(file));
        final bytes = result.bytes;
        final pdf = PdfReader(bytes);

        expect(bytes.length, greaterThan(1000));
        expect(pdf.hasTrailerRoot, isTrue);
        expect(pdf.pageCount,
            inInclusiveRange(expected.pages, expected.maxPages));
        expect(pdf.endsWithEof, isTrue);
        for (final offset in pdf.xrefOffsets) {
          expect(pdf.objectHeaderAt(offset), isNotNull,
              reason: 'corrupt xref in $file');
        }

        final streams = pdf.decodedStreams.join('\n');
        for (final word in expected.words) {
          expect(streams, contains(word),
              reason: '"$word" deve ser extraível do PDF de $file');
        }
        final cellRects =
            RegExp(r'(?:[-\d.]+ ){4}re S').allMatches(streams).length;
        expect(cellRects, greaterThan(expected.minCellRects),
            reason: 'as grades de tabela de $file devem estar desenhadas');

        // Perda tolerada: só o brasão por URL (a aplicação resolve com
        // fetch) e um op de imagem com source lixo ("//:0") gravado no termo
        // de referência real.
        for (final warning in result.warnings) {
          expect(
              warning.contains('document_header.svg') ||
                  warning.trim().endsWith('//:0'),
              isTrue,
              reason: 'aviso inesperado em $file: $warning');
        }
      });
    });

    test('the same delta always produces the same bytes', () {
      // Determinism is what lets the backend hash the PDF (SHA-256) and later
      // prove the signed document is the one that was generated.
      final delta = _loadDelta('documento.delta.json');
      expect(_pdfOf(delta), equals(_pdfOf(delta)));
    });
  });

  group('zlib round-trip', () {
    // `zlibEncode` wraps raw deflate in an RFC 1950 envelope; the bundled
    // `Inflate` consumes raw deflate. Feeding it the whole payload returns
    // zero bytes *silently* — so the pair has to be tested together, and
    // `zlibDecode` exists precisely so nobody has to know this.
    test('encode then decode returns the original bytes', () {
      for (final sample in <List<int>>[
        <int>[],
        <int>[0],
        utf8.encode('BT /F1 12 Tf (olá, mundo) Tj ET'),
        List<int>.generate(50000, (i) => i % 256),
      ]) {
        expect(zlibDecode(zlibEncode(sample)), equals(sample),
            reason: 'falhou para ${sample.length} bytes');
      }
    });

    test('decode also accepts a raw deflate stream', () {
      final wrapped = zlibEncode(utf8.encode('conteúdo'));
      final raw = wrapped.sublist(2, wrapped.length - 4);
      expect(utf8.decode(zlibDecode(raw)), 'conteúdo');
    });
  });

  group('known limitations (documented, not accidents)', () {
    test('characters outside cp1252 do not survive yet', () {
      // WinAnsi encoding with the standard-14 fonts: this is exactly what P1
      // (embedded TrueType subsets) exists to fix. Pinned so the day it is
      // fixed, this test fails and gets rewritten instead of silently passing.
      final text = PdfReader(_pdfOf(Delta()..insert('preço 日本\n'))).extractText();

      expect(text, contains('preço'), reason: 'cp1252 covers Portuguese');
      expect(text, isNot(contains('日本')));
    });
  });
}
