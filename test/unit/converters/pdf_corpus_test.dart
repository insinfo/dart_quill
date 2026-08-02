/// P20 — o corpus real (DOCX do Word + PDF de referência impresso pelo
/// próprio Word) ligado a um teste de comparação.
///
/// A referência `etp_reference.pdf` foi gerada pelo Word a partir do MESMO
/// `etp_corpus.docx`: o número de páginas dela ancora o nosso layout numa
/// faixa (fontes e margens diferem, páginas idênticas não existem), e o texto
/// do Delta importado tem de chegar praticamente inteiro ao nosso PDF.
@TestOn('vm')
library;

import 'dart:io';

import 'package:dart_quill/dart_quill_docx.dart';
import 'package:dart_quill/dart_quill_pdf.dart';
import 'package:test/test.dart';

import '../../support/pdf_reader.dart';

void main() {
  final delta = docxToDelta(
      File('test/assets/docx/etp_corpus.docx').readAsBytesSync());
  final result = deltaToPdfWithReport(delta);
  final ours = PdfReader(result.bytes);

  test('o número de páginas fica na faixa da referência do Word', () {
    final reference =
        File('test/assets/pdf/etp_reference.pdf').readAsBytesSync();
    final referencePages = RegExp(r'/Count (\d+)')
        .allMatches(String.fromCharCodes(reference))
        .map((m) => int.parse(m.group(1)!))
        .reduce((a, b) => a > b ? a : b);
    expect(referencePages, 19,
        reason: 'a fixture de referência mudou? Reancorar as faixas.');

    // Fontes/margens diferentes movem quebras; um desvio além de ±50% seria
    // layout errado (tabela colapsada ou espaçamento estourado), não estilo.
    expect(ours.pageCount,
        inInclusiveRange((referencePages * 0.5).floor(), referencePages * 2),
        reason: 'nosso PDF tem ${ours.pageCount} páginas; '
            'o Word imprimiu $referencePages');
  });

  test('praticamente todo o texto do DOCX chega ao nosso PDF', () {
    // Palavras "de verdade" do Delta importado (≥4 chars, sem pontuação nas
    // pontas). O extrator lê Tj palavra a palavra, então palavra é a unidade
    // certa de comparação.
    final sourceWords = <String>{};
    for (final op in delta.toJson()) {
      final insert = op['insert'];
      if (insert is! String) continue;
      for (final raw in insert.split(RegExp(r'\s+'))) {
        final word = raw.replaceAll(RegExp(r'^[^\wÀ-ÿ]+|[^\wÀ-ÿ]+$'), '');
        if (word.length >= 4) sourceWords.add(word);
      }
    }
    expect(sourceWords.length, greaterThan(500),
        reason: 'o corpus deveria ter um vocabulário grande');

    final text = ours.extractText();
    final missing =
        sourceWords.where((word) => !text.contains(word)).toList();
    // Tolerância pequena: só o que o WinAnsi não representa pode faltar.
    expect(missing.length, lessThan(sourceWords.length * 0.02),
        reason: 'palavras perdidas no PDF (${missing.length} de '
            '${sourceWords.length}): ${missing.take(20).toList()}');
  });

  test('as tabelas do corpus estão desenhadas', () {
    final streams = ours.decodedStreams.join('\n');
    final rects = RegExp(r'(?:[-\d.]+ ){4}re S').allMatches(streams).length;
    // O ETP tem 3 tabelas; a maior (TCO) sozinha passa de 20 células.
    expect(rects, greaterThan(40),
        reason: 'as grades das 3 tabelas devem estar no PDF: $rects');
  });

  test('nenhuma perda silenciosa além das auditadas', () {
    for (final warning in result.warnings) {
      expect(warning.contains('document_header.svg'), isTrue,
          reason: 'aviso inesperado no corpus: $warning');
    }
  });
}
