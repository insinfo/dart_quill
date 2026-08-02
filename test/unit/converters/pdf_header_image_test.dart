/// `headerImage` no PDF: o brasão institucional não pode sumir em silêncio.
///
/// O Delta do SALI guarda `{headerImage: "https://.../document_header.svg"}`.
/// Antes, o conversor só reconhecia `insert['image']` e o embed caía num
/// `continue`: o PDF saía perfeito aos olhos e sem o brasão. Agora o embed é
/// reconhecido, os bytes vêm de `PdfExportOptions.resources` (o pacote não
/// faz rede) e o SVG é desenhado pelo renderizador próprio; a falta de bytes
/// vira um AVISO em `deltaToPdfWithReport`, nunca perda silenciosa.
@TestOn('vm')
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:dart_quill/dart_quill_pdf.dart';
import 'package:dart_quill/src/delta/delta.dart';
import 'package:test/test.dart';

import '../../support/pdf_reader.dart';

void main() {
  const url = 'https://devsali.riodasostras.rj.gov.br/assets/images/'
      'document_header.svg';

  Delta docWith(Object embed) => Delta()
    ..insert({'headerImage': embed})
    ..insert('DESPACHO\n');

  final svgBytes =
      File('test/assets/svg/document_header.svg').readAsBytesSync();

  test('com os bytes em resources, o brasão é desenhado', () {
    final result = deltaToPdfWithReport(
      docWith(url),
      options: PdfExportOptions(resources: {url: svgBytes}),
    );
    final content = PdfReader(result.bytes).decodedStreams.join('\n');
    // O desenho vetorial entra como operadores de caminho (re/c/f) no stream.
    expect(RegExp(r'[\d.]+ [\d.]+ m').hasMatch(content), isTrue,
        reason: 'os caminhos do SVG precisam estar no content stream');
    expect(PdfReader(result.bytes).extractText(), contains('DESPACHO'));
    expect(
        result.warnings.where((w) => w.contains('não desenhada')), isEmpty,
        reason: 'com bytes presentes não pode haver aviso de perda '
            '(${result.warnings})');
  });

  test('sem os bytes, o aviso denuncia a perda', () {
    final result = deltaToPdfWithReport(docWith(url));
    expect(result.warnings, isNotEmpty);
    expect(result.warnings.join(' '), contains(url),
        reason: 'o aviso aponta o source que ficou de fora');
    expect(PdfReader(result.bytes).extractText(), contains('DESPACHO'),
        reason: 'o resto do documento continua saindo');
  });

  test('imagem raster por URL usa os bytes de resources', () {
    // PNG 1x1 vermelho.
    final png = <int>[
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, //
      0, 0, 0, 13, 0x49, 0x48, 0x44, 0x52, 0, 0, 0, 1, 0, 0, 0, 1, //
      8, 2, 0, 0, 0, 0x90, 0x77, 0x53, 0xDE, //
      0, 0, 0, 12, 0x49, 0x44, 0x41, 0x54, //
      0x08, 0xD7, 0x63, 0xF8, 0xCF, 0xC0, 0x00, 0x00, 0x00, 0x03, 0x00,
      0x01, //
      0x5E, 0xF3, 0x2A, 0x3A, //
      0, 0, 0, 0, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
    ];
    const imgUrl = 'https://exemplo.gov.br/foto.png';
    final delta = Delta()
      ..insert({'image': imgUrl})
      ..insert('\n');

    final without = deltaToPdfWithReport(delta);
    expect(without.warnings.join(' '), contains(imgUrl));

    final with_ = deltaToPdfWithReport(delta,
        options: PdfExportOptions(
            resources: {imgUrl: Uint8List.fromList(png)}));
    expect(with_.warnings.where((w) => w.contains(imgUrl)), isEmpty);
    expect(PdfReader(with_.bytes).rawLatin1, contains('/XObject'),
        reason: 'a imagem raster vira um XObject no PDF');
  });

  test('deltaToPdf puro continua determinístico com o SVG', () {
    final options = PdfExportOptions(resources: {url: svgBytes});
    final a = deltaToPdf(docWith(url), options: options);
    final b = deltaToPdf(docWith(url), options: options);
    expect(a, equals(b));
  });
}
