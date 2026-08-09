@TestOn('browser')
library;

import 'package:dart_quill/dart_quill_office.dart';
import 'package:test/test.dart';

PMNode _signatureFixture(Schema schema) {
  final bold = schema.marks['bold']!.create();
  final opaque = schema.marks['opaqueAttrs']!.create({
    'attrs': {
      'zeta': true,
      'alpha': [null, -3.25, 'ação 😀'],
      'sourceSignature': 'mark-source',
    },
  });
  final nestedMap = <String, dynamic>{
    'third': {
      'b': 2,
      'a': 1,
    },
    'first': 'valor',
    'second': [true, null, 9.5],
  };
  final longUnicode = '${List.filled(1025, 'á').join()}😀fim';
  return schema.node(
    'doc',
    null,
    Fragment.from([
      schema.node(
        'paragraph',
        {
          'id': 'p-assinatura',
          'word': {
            'sourceBlockIndex': 7,
            'sourceSignature': 'paragraph-source',
            'nested': nestedMap,
          },
          'extra': {
            'enabled': false,
            'count': 42,
          },
        },
        Fragment.from([
          schema.text('prefixo ', [bold]),
          schema.text(longUnicode, [bold, opaque]),
          schema.node('opaqueInline', {
            'insert': {
              'sourceCellIndex': 4,
              'payload': nestedMap,
            },
          }),
        ]),
      ),
    ]),
  );
}

void main() {
  test('dart2js preserva o golden do hash afim low32', () {
    // Há vários resumos de filhos neste fixture. Compor seus fatores exige
    // multiplicação uint32; o golden da VM detecta perda de bits no Number
    // do JavaScript e também cobre UTF-16, marcas e strings > 1024 unidades.
    final signature = OfficeDocxCodec.nodeSignature(
      _signatureFixture(officeQuillSchema()),
    );

    expect(signature, '32b06e2289132492:1537');
  });
}
