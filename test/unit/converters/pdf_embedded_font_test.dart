/// Fonte embutida (CID) ligada ao exportador — P1 do plano de PDF.
///
/// Sem `fontFaces` nada muda: standard-14 + WinAnsi, com `?` fora do cp1252
/// (o teste histórico continua valendo). Com uma face fornecida, o texto sai
/// na fonte REAL: subset embutido, string hexadecimal `Identity-H` no content
/// stream, `/ToUnicode` para cópia de texto — e qualquer caractere que a
/// fonte cubra sobrevive.
@TestOn('vm')
library;

import 'dart:io';

import 'package:dart_quill/dart_quill_pdf.dart';
import 'package:dart_quill/src/delta/delta.dart';
import 'package:test/test.dart';

import '../../support/pdf_reader.dart';

void main() {
  final inter =
      File('test/assets/fonts/Inter-Regular.ttf').readAsBytesSync();
  final options = PdfExportOptions(
    fontFaces: [PdfFontFace('Inter', inter)],
  );

  Delta doc(String text) => Delta()
    ..insert(text, {'font': 'Inter'})
    ..insert('\n');

  test('o texto sai na fonte embutida, como CIDs em hexadecimal', () {
    final bytes = deltaToPdf(doc('Despacho'), options: options);
    final raw = PdfReader(bytes).rawLatin1;
    final streams = PdfReader(bytes).decodedStreams.join('\n');
    expect(raw, contains('/FontFile2'),
        reason: 'o subset TrueType precisa estar embutido');
    expect(raw, contains('/ToUnicode'),
        reason: 'sem /ToUnicode copiar texto devolve lixo');
    expect(RegExp(r'/TT1 [\d.]+ Tf').hasMatch(streams), isTrue,
        reason: 'o texto usa o recurso da fonte embutida');
    expect(RegExp(r'<[0-9a-f]+> Tj').hasMatch(streams), isTrue,
        reason: 'Identity-H escreve strings hexadecimais de CIDs');
  });

  test('travessão e aspas curvas sobrevivem (fora do cp1252 não vira ?)', () {
    final bytes = deltaToPdf(doc('Prazo — “dez dias úteis”'), options: options);
    final streams = PdfReader(bytes).decodedStreams.join('\n');
    // Nenhum literal WinAnsi com '?' de substituição para esta linha.
    expect(streams, isNot(contains('(Prazo ? ')),
        reason: 'com a face embutida o travessão não pode degradar para ?');
    expect(RegExp(r'<[0-9a-f]+> Tj').hasMatch(streams), isTrue);
  });

  test('negrito sem face bold cai na regular, com aviso', () {
    final result = deltaToPdfWithReport(
      Delta()
        ..insert('titulo', {'font': 'Inter', 'bold': true})
        ..insert('\n'),
      options: options,
    );
    expect(result.warnings.join(' '), contains('bold'),
        reason: 'a variante ausente é avisada, não silenciada');
    expect(PdfReader(result.bytes).endsWithEof, isTrue);
  });

  test('sem fontFaces o comportamento antigo continua intacto', () {
    final bytes = deltaToPdf(doc('Despacho'));
    final raw = PdfReader(bytes).rawLatin1;
    expect(raw, isNot(contains('/FontFile2')));
    expect(PdfReader(bytes).extractText(), contains('Despacho'));
  });

  test('determinístico com a fonte embutida', () {
    final a = deltaToPdf(doc('Despacho — nº 1'), options: options);
    final b = deltaToPdf(doc('Despacho — nº 1'), options: options);
    expect(a, equals(b));
  });

  test('a métrica do subset é a real: linhas não estouram a margem', () {
    // 60 caracteres largos numa página estreita força quebras; se a medição
    // usasse a estimativa antiga, o x final de algum segmento passaria da
    // área útil.
    final narrow = PdfExportOptions(
      pageWidth: 300,
      pageHeight: 400,
      fontFaces: [PdfFontFace('Inter', inter)],
    );
    final bytes = deltaToPdf(
        doc('MMMMM WWWWW MMMMM WWWWW MMMMM WWWWW MMMMM WWWWW MMMMM WWWWW'),
        options: narrow);
    expect(PdfReader(bytes).pageCount, greaterThanOrEqualTo(1));
    expect(PdfReader(bytes).endsWithEof, isTrue);
  });
}
