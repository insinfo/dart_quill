/// P18 — imagem fim-a-fim no PDF: a suíte não tinha NENHUM caso raster.
///
/// O caminho tem três portas (data URL, bytes em `resources` por URL, e a
/// falha auditada por warning) e nenhuma estava travada por teste — uma
/// regressão em qualquer uma apagaria as imagens dos despachos em silêncio.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:dart_quill/dart_quill_pdf.dart';
import 'package:dart_quill/src/delta/delta.dart';
import 'package:test/test.dart';

import '../../support/pdf_reader.dart';

/// PNG 1×1 vermelho.
const String _pngB64 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8'
    'z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';
const String _pngDataUrl = 'data:image/png;base64,$_pngB64';

void main() {
  Delta imageDelta(String source, {Map<String, dynamic>? attributes}) =>
      Delta()
        ..insert('antes da imagem\n')
        ..insert({'image': source}, attributes)
        ..insert('\ndepois da imagem\n');

  test('data URL PNG vira XObject desenhado, sem warnings', () {
    final result = deltaToPdfWithReport(imageDelta(_pngDataUrl));
    expect(result.warnings, isEmpty);

    final raw = String.fromCharCodes(result.bytes);
    expect(raw, contains('/Subtype /Image'),
        reason: 'o PNG deve virar um XObject de imagem');

    final streams = PdfReader(result.bytes).decodedStreams.join('\n');
    expect(RegExp(r'/Im\d+ Do').hasMatch(streams), isTrue,
        reason: 'a página deve DESENHAR o XObject: $streams');
  });

  test('imagem por URL desenha quando os bytes chegam em resources', () {
    const url = 'https://exemplo.gov.br/logo.png';
    final result = deltaToPdfWithReport(
      imageDelta(url),
      options: PdfExportOptions(resources: <String, Uint8List>{
        url: base64Decode(_pngB64),
      }),
    );
    expect(result.warnings, isEmpty);
    expect(String.fromCharCodes(result.bytes), contains('/Subtype /Image'));
  });

  test('imagem por URL sem bytes vira warning, nunca crash', () {
    const url = 'https://exemplo.gov.br/logo.png';
    final result = deltaToPdfWithReport(imageDelta(url));
    expect(result.warnings, hasLength(1));
    expect(result.warnings.single, contains(url));
    // O resto do documento continua lá.
    final streams = PdfReader(result.bytes).decodedStreams.join('\n');
    expect(streams, contains('antes'));
    expect(streams, contains('depois'));
  });

  test('width/height do atributo dimensionam o desenho', () {
    Uint8List pdf(Map<String, dynamic>? attrs) =>
        deltaToPdf(imageDelta(_pngDataUrl, attributes: attrs));
    double drawnWidth(Uint8List bytes) {
      final streams = PdfReader(bytes).decodedStreams.join('\n');
      // cm antes do Do: [w 0 0 h x y cm]
      final m = RegExp(r'([\d.]+) 0 0 ([\d.]+) [-\d.]+ [-\d.]+ cm\s*/Im\d+ Do')
          .firstMatch(streams);
      expect(m, isNotNull, reason: 'matriz do desenho ausente: $streams');
      return double.parse(m!.group(1)!);
    }

    final small = drawnWidth(pdf({'width': '100'}));
    final large = drawnWidth(pdf({'width': '200'}));
    expect(large, closeTo(small * 2, 1.0),
        reason: 'o dobro do width deve dobrar a largura desenhada');
  });

  test('a mesma imagem repetida compartilha um único XObject', () {
    final delta = Delta()
      ..insert({'image': _pngDataUrl})
      ..insert('\n')
      ..insert({'image': _pngDataUrl})
      ..insert('\n');
    final raw = String.fromCharCodes(deltaToPdf(delta));
    final names = RegExp(r'/Im(\d+)')
        .allMatches(raw)
        .map((m) => m.group(1))
        .toSet();
    expect(names, hasLength(1),
        reason: 'imagens idênticas devem compartilhar um XObject: $names');
  });
}
