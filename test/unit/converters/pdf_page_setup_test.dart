/// Page setup do Delta e sanitização pré-PDF — P6/P7 do plano.
///
/// O comportamento espelha o pipeline em produção do SALI
/// (`sali_quill_pdf_defaults.dart` / `quill_pdf_sanitizer.dart`), agora como
/// recurso genérico do pacote com o perfil SALI como preset.
@TestOn('vm')
library;

import 'package:dart_quill/dart_quill_pdf.dart';
import 'package:dart_quill/src/delta/delta.dart';
import 'package:test/test.dart';

import '../../support/pdf_reader.dart';

void main() {
  group('leitura do page setup', () {
    test('Delta sem atributos cai no padrão A4 retrato', () {
      final setup = readPdfPageSetup([
        {'insert': 'texto\n'},
      ]);
      expect(setup.isDefault, isTrue);
    });

    test('orientação e margem vêm de qualquer op', () {
      final setup = readPdfPageSetup([
        {
          'insert': 'primeira linha',
          'attributes': {'page-orientation': 'landscape'},
        },
        {
          'insert': '\n',
          'attributes': {'page-margin': '1,5cm'},
        },
      ]);
      expect(setup.landscape, isTrue);
      expect(setup.marginCm, closeTo(1.5, 1e-9));
    });

    test('margem fora da faixa 0,5–5 cm é ignorada', () {
      expect(parsePageMarginCm('0.2cm'), isNull);
      expect(parsePageMarginCm('9cm'), isNull);
      expect(parsePageMarginCm('2cm'), 2.0);
      expect(parsePageMarginCm(1.27), closeTo(1.27, 1e-9));
      expect(parsePageMarginCm('lixo'), isNull);
    });

    test('paisagem troca largura e altura na página do PDF', () {
      final options = pageSetupOptions(const PdfPageSetup(landscape: true));
      final bytes = deltaToPdf(Delta()..insert('x\n'), options: options);
      final box = PdfReader(bytes).firstMediaBox!;
      expect(box[2], greaterThan(box[3]),
          reason: 'largura > altura em paisagem (${box.join(', ')})');
    });

    test('o layout do editor usa 1 cm quando o Delta não declara', () {
      final options =
          pageSetupOptions(PdfPageSetup.standard, defaultMarginCm: 1.0);
      expect(options.marginTop, closeTo(72 / 2.54, 0.01));
    });
  });

  group('sanitização com o perfil SALI', () {
    test('remove cor, fundo, script e os atributos de página', () {
      final ops = sanitizeOpsForPdf([
        {
          'insert': 'texto',
          'attributes': {
            'bold': true,
            'color': '#ff0000',
            'background': '#ffff00',
            'script': 'super',
            'page-orientation': 'landscape',
            'page-margin': '2cm',
          },
        },
      ], policy: PdfSanitizePolicy.sali);
      expect(ops.single['attributes'], {'bold': true});
    });

    test('font passa pela whitelist com aliases', () {
      List<Map<String, dynamic>> one(String family) => sanitizeOpsForPdf([
            {
              'insert': 'x',
              'attributes': {'font': family},
            },
          ], policy: PdfSanitizePolicy.sali);

      expect(one('Helvetica').single['attributes'], {'font': 'arial'});
      expect(one('"Arial", sans-serif').single['attributes'],
          {'font': 'arial'});
      expect(one('Calibri Light').single['attributes'], {'font': 'calibri'});
      expect(one('Comic Sans MS').single.containsKey('attributes'), isFalse,
          reason: 'família fora da política é descartada e o tema assume');
    });

    test('a política default não mexe em cor nem fonte', () {
      final ops = sanitizeOpsForPdf([
        {
          'insert': 'x',
          'attributes': {'color': '#ff0000', 'page-margin': '2cm'},
        },
      ]);
      expect(ops.single['attributes'], {'color': '#ff0000'},
          reason: 'só os atributos de página saem no default');
    });

    test('item que não é op lança, como no SALI', () {
      expect(() => sanitizeOpsForPdf(['texto solto']),
          throwsA(isA<InvalidPdfOperation>()));
    });
  });

  test('fim a fim: Delta do SALI com page setup vira PDF paisagem limpo', () {
    final ops = [
      {
        'insert': 'DESPACHO',
        'attributes': {
          'page-orientation': 'landscape',
          'page-margin': '1cm',
          'color': '#ff0000',
        },
      },
      {'insert': '\n'},
    ];
    final setup = readPdfPageSetup(ops);
    final clean = sanitizeOpsForPdf(ops, policy: PdfSanitizePolicy.sali);
    final bytes = deltaToPdf(Delta.fromJson(clean),
        options: pageSetupOptions(setup));
    final reader = PdfReader(bytes);
    expect(reader.firstMediaBox![2], greaterThan(reader.firstMediaBox![3]));
    expect(reader.extractText(), contains('DESPACHO'));
  });
}
