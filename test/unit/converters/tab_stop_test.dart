/// Marcador de lista/numeração separado do texto por TABULAÇÃO.
///
/// O Word separa "1."/"•" do texto por tabulação (`w:suff` default). O
/// importador de DOCX materializava um espaço simples, então o texto colava no
/// marcador — bem diferente do documento original — e o exportador de PDF
/// media o caractere de tabulação como zero, colando ainda mais.
@TestOn('vm')
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:dart_quill/dart_quill_docx.dart';
import 'package:dart_quill/dart_quill_pdf.dart';
import 'package:dart_quill/src/delta/delta.dart';
import 'package:test/test.dart';

import '../../support/pdf_reader.dart';

void main() {
  test('o DOCX importado separa marcador e texto por tabulação', () {
    final ops = docxToDelta(
            File('test/assets/docx/etp_corpus.docx').readAsBytesSync())
        .toJson();
    final markers = ops
        .map((op) => op['insert'])
        .whereType<String>()
        .where((t) => t.startsWith('•') || RegExp(r'^\d+\.\s').hasMatch(t))
        .toList();
    expect(markers, isNotEmpty,
        reason: 'o corpus tem listas e títulos numerados');
    for (final marker in markers.take(20)) {
      expect(marker, endsWith('\t'),
          reason: 'o marcador ${marker.trim()} precisa terminar em tabulação');
    }
  });

  /// Posições x dos operadores de posicionamento de texto do content stream.
  List<double> textOffsets(Uint8List pdf) {
    final streams = PdfReader(pdf).decodedStreams.join('\n');
    return RegExp(r'([\d.]+) [\d.]+ Td')
        .allMatches(streams)
        .map((m) => double.parse(m.group(1)!))
        .toList();
  }

  test('a tabulação avança até a parada, em vez de medir zero', () {
    // Duas linhas idênticas a menos do separador. A da tabulação precisa
    // empurrar o texto MUITO mais à direita — uma parada de 1,25 cm contra a
    // largura de um espaço.
    final comTab = deltaToPdf(Delta()..insert('1.\tTítulo do capítulo\n'));
    final semTab = deltaToPdf(Delta()..insert('1. Título do capítulo\n'));

    expect(PdfReader(comTab).extractText(), contains('Título'));

    final xsTab = textOffsets(comTab);
    final xsPlain = textOffsets(semTab);
    expect(xsTab.length, greaterThan(1),
        reason: 'o texto após a tabulação é posicionado à parte ($xsTab)');
    // O último trecho desenhado (o título) começa bem mais à direita.
    expect(xsTab.last - xsPlain.last, greaterThan(20),
        reason: 'a tabulação precisa abrir um vão real '
            '(com=$xsTab sem=$xsPlain)');
  });

  test('uma tabulação no meio do texto não quebra o exportador', () {
    final bytes = deltaToPdf(Delta()
      ..insert('a\tb\tc\n')
      ..insert('linha longa\tcom tabulação no meio para forçar quebra\n'));
    expect(PdfReader(bytes).endsWithEof, isTrue);
    expect(PdfReader(bytes).extractText(), contains('linha longa'));
  });

  test('o tamanho do Word chega ao Delta em PONTOS, com o valor original', () {
    final ops = docxToDelta(
            File('test/assets/docx/etp_corpus.docx').readAsBytesSync())
        .toJson();
    final sizes = ops
        .map((op) => (op['attributes'] as Map?)?['size'])
        .whereType<String>()
        .toSet();
    expect(sizes, isNotEmpty);
    for (final size in sizes) {
      expect(size, endsWith('pt'),
          reason: 'o Word trabalha em pontos; px nao casa com nenhuma lista '
              'de tamanhos padrao (veio "\$size")');
    }
    expect(sizes, contains('10pt'),
        reason: 'o corpo do ETP e Arial 10 — o valor tem de voltar exato');
  });
}
