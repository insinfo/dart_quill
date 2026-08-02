@TestOn('browser')
library office_pdf_anywhere_test;

/// O MESMO serviço de PDF que o backend usa, rodando no browser.
///
/// O par do guarda de portabilidade (`pdf_portability_test.dart`): lá se
/// prova que nada de plataforma entra no fecho de imports; aqui se prova o
/// efeito — o mesmo código compila e roda em dart2js. Se algum dia entrar um
/// `dart:io`, o guarda falha na VM E este teste falha ao compilar.
import 'dart:convert';

import 'package:dart_quill/dart_quill_office.dart';
import 'package:test/test.dart';

void main() {
  final schema = officeQuillSchema();

  PMNode paragraph(String text) => schema.node(
      'paragraph', null, Fragment.from([schema.text(text)]));

  test('o serviço de PDF do backend roda igual no browser', () {
    final doc = schema.node(
        'doc',
        null,
        Fragment.from([
          for (var i = 0; i < 120; i++) paragraph('Parágrafo $i do despacho.')
        ]));
    final snapshot = OfficeDocumentSnapshot(
        documentId: 'd1', body: doc.toJSON() as Map<String, dynamic>);

    final result =
        OfficePdfService().fromSnapshotJson(jsonEncode(snapshot.toJson()));

    expect(latin1.decode(result.bytes, allowInvalid: true), startsWith('%PDF-'));
    expect(result.pageCount, LayoutComposer().compose(doc).pages.length,
        reason: 'a paginação tem de ser a mesma em qualquer ambiente');
  });

  test('Delta do banco vira PDF no browser com o mesmo relatório', () {
    final result = OfficePdfService().fromQuillDelta([
      {'insert': 'Despacho'},
      {'insert': '\n', 'attributes': {'header': 1}},
      {'insert': 'Corpo.\n'},
    ]);
    expect(latin1.decode(result.pdf.bytes, allowInvalid: true),
        startsWith('%PDF-'));
    expect(result.report.issues, isEmpty);
  });
}
