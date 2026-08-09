/// Fase 3 — codec Delta↔Office: round-trip sintético e com os 4 Deltas
/// REAIS do SALI (o gate da fase: "Delta básico abre e volta sem perda").
///
/// A comparação normaliza os dois lados pela MESMA fusão de ops adjacentes
/// (a que o próprio Delta faz) e compara o JSON canônico (chaves ordenadas):
/// a ordem de chaves de atributos não é semântica.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import 'package:dart_quill/dart_quill_office.dart';

String _canonical(dynamic value) {
  if (value is Map) {
    final keys = value.keys.map((k) => '$k').toList()..sort();
    return '{${keys.map((k) => '${json.encode(k)}:${_canonical(value[k])}').join(',')}}';
  }
  if (value is List) return '[${value.map(_canonical).join(',')}]';
  return json.encode(value);
}

/// Funde ops adjacentes de texto com os mesmos atributos (normalização).
List<Map<String, dynamic>> _normalize(List<dynamic> ops) {
  final out = <Map<String, dynamic>>[];
  for (final dynamic raw in ops) {
    final op = (raw as Map).cast<String, dynamic>();
    if (out.isNotEmpty &&
        op['insert'] is String &&
        out.last['insert'] is String &&
        _canonical(out.last['attributes']) == _canonical(op['attributes'])) {
      out.last['insert'] = '${out.last['insert']}${op['insert']}';
      continue;
    }
    out.add(Map<String, dynamic>.from(op));
  }
  return out;
}

void expectRoundTrip(List<dynamic> ops, Schema schema, {String? label}) {
  final result = importQuillDelta(ops, schema);
  final exported = exportQuillDelta(result.doc);
  expect(_canonical(_normalize(exported)), _canonical(_normalize(ops)),
      reason: 'round-trip de ${label ?? 'delta'} tem de ser ponto fixo');
}

void main() {
  final schema = officeQuillSchema();

  group('round-trip sintético', () {
    test('texto com marcas inline', () {
      expectRoundTrip([
        {'insert': 'normal '},
        {
          'insert': 'negrito',
          'attributes': {'bold': true}
        },
        {
          'insert': ' colorido',
          'attributes': {'color': '#ff0000', 'italic': true}
        },
        {'insert': '\n'},
      ], schema);
    });

    test('blocos: header, lista, blockquote, code-block', () {
      expectRoundTrip([
        {'insert': 'Título'},
        {
          'insert': '\n',
          'attributes': {'header': 2, 'align': 'center'}
        },
        {'insert': 'item um'},
        {
          'insert': '\n',
          'attributes': {'list': 'ordered'}
        },
        {'insert': 'item fundo'},
        {
          'insert': '\n',
          'attributes': {'list': 'bullet', 'indent': 2}
        },
        {'insert': 'feito'},
        {
          'insert': '\n',
          'attributes': {'list': 'checked'}
        },
        {'insert': 'citação'},
        {
          'insert': '\n',
          'attributes': {'blockquote': true}
        },
        {'insert': 'final x = 1;'},
        {
          'insert': '\n',
          'attributes': {'code-block': 'dart'}
        },
      ], schema);
    });

    test('tabela do dialeto table-better', () {
      expectRoundTrip([
        {
          'insert': '\n',
          'attributes': {
            'table-temporary': {'data-class': 'ql-table-better'}
          }
        },
        {
          'insert': '\n',
          'attributes': {
            'table-col': {'width': '100'}
          }
        },
        {
          'insert': '\n',
          'attributes': {
            'table-col': {'width': '200'}
          }
        },
        {'insert': 'a1'},
        {
          'insert': '\n',
          'attributes': {
            'table-cell-block': 'c1',
            'table-cell': {'data-row': 'r1', 'width': '100'}
          }
        },
        {'insert': 'a1 segunda linha'},
        {
          'insert': '\n',
          'attributes': {
            'table-cell-block': 'c1',
            'table-cell': {'data-row': 'r1', 'width': '100'}
          }
        },
        {'insert': 'b1'},
        {
          'insert': '\n',
          'attributes': {
            'table-cell-block': 'c2',
            'table-cell': {'data-row': 'r1', 'width': '200'}
          }
        },
        {'insert': 'a2'},
        {
          'insert': '\n',
          'attributes': {
            'table-cell-block': 'c3',
            'table-cell': {'data-row': 'r2', 'width': '100'}
          }
        },
        {'insert': '\n'},
      ], schema);
    });

    test('embeds: imagem, vídeo, fórmula, headerImage', () {
      expectRoundTrip([
        {
          'insert': {'headerImage': 'https://x.gov.br/brasao.svg'}
        },
        {'insert': '\n'},
        {'insert': 'antes '},
        {
          'insert': {'image': 'https://x.gov.br/foto.png'},
          'attributes': {'width': '100'}
        },
        {'insert': ' depois\n'},
        {
          'insert': {'formula': 'e=mc^2'}
        },
        {'insert': '\n'},
      ], schema);
    });

    test('desconhecidos preservados pelas rotas de escape', () {
      final ops = [
        {
          'insert': 'texto',
          'attributes': {'meu-inline-custom': 'valor'}
        },
        {
          'insert': '\n',
          'attributes': {'minha-linha-custom': 42}
        },
        {
          'insert': {'embed-desconhecido': 'payload'}
        },
        {'insert': '\n'},
      ];
      final result = importQuillDelta(ops, schema);
      expect(
          result.report.issues.map((i) => i.code),
          containsAll([
            'unknown-inline-attribute',
            'unknown-line-attribute',
            'unknown-embed'
          ]));
      expect(result.report.isLossless, isTrue,
          reason: 'rota de escape preserva; só descarte quebra o lossless');
      expectRoundTrip(ops, schema, label: 'delta com desconhecidos');
    });

    test('newlines múltiplos num op com atributo de linha', () {
      expectRoundTrip([
        {'insert': 'a'},
        {
          'insert': '\n\n',
          'attributes': {'align': 'center'}
        },
        {'insert': 'b\n'},
      ], schema);
    });
  });

  group('corpus real do SALI', () {
    for (final name in const [
      'documento',
      'ferias',
      'tabela_colunas_iguais',
      'termo_referencia',
    ]) {
      test('$name abre e volta sem perda', () {
        final raw = jsonDecode(
            File('test/assets/delta/$name.delta.json').readAsStringSync());
        final ops = (raw is Map ? raw['ops'] : raw) as List;
        final result = importQuillDelta(ops, schema);
        expect(result.report.isLossless, isTrue,
            reason: 'nada pode ser descartado: ${result.report.issues}');
        final exported = exportQuillDelta(result.doc);
        expect(_canonical(_normalize(exported)), _canonical(_normalize(ops)),
            reason: 'o corpus real tem de ser ponto fixo');
      });
    }

    test('o snapshot do termo de referência é estável (hash determinístico)',
        () {
      final raw = jsonDecode(
          File('test/assets/delta/termo_referencia.delta.json')
              .readAsStringSync());
      final ops = (raw is Map ? raw['ops'] : raw) as List;
      final doc = importQuillDelta(ops, schema).doc;
      final a = OfficeDocumentSnapshot.fromDocument(doc, documentId: 'tr');
      final b = OfficeDocumentSnapshot.fromDocument(
          importQuillDelta(ops, schema).doc,
          documentId: 'tr');
      expect(a.contentHash(), b.contentHash(),
          reason: 'duas importações do mesmo Delta = mesmo hash');
    });
  });
}
