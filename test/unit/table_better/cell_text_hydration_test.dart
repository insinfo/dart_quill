/// Texto DENTRO de célula precisa hidratar.
///
/// `ParentBlot.insertAt` do parchment cria um bloco padrão quando o pai está
/// vazio; a base deste port devolvia null e `TableCell`/`TableTh` não
/// sobrescreviam `createDefaultChild`, então QUALQUER Delta com texto em
/// célula estourava "Cannot insert into empty TableCell" no `setContents`.
/// Isso derrubava toda importação de DOCX com tabela — e o próprio golden
/// `a table with a colgroup`, que nunca havia sido hidratado por um teste.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:dart_quill/dart_quill_docx.dart';
import 'package:dart_quill/src/delta/delta.dart';
import 'package:dart_quill/src/table_better/formats/table.dart';
import 'package:dart_quill/src/table_better/register.dart';
import 'package:test/test.dart';

import '../../support/quill_test_helpers.dart';

void main() {
  setUpAll(() {
    ensureQuillTestInitialized();
    registerTableBetter();
  });

  Delta cellWithText({bool anchor = true, bool cols = false, bool th = false}) {
    final delta = Delta();
    if (anchor) {
      delta.insert('\n', {
        'table-temporary': {'style': 'width: 100%'}
      });
    }
    if (cols) {
      delta
        ..insert('\n', {
          'table-col': {'width': '243'}
        })
        ..insert('\n', {
          'table-col': {'width': '211'}
        });
    }
    final blockKey = th ? 'table-th-block' : 'table-cell-block';
    delta
      ..insert('Severidade', {'bold': true})
      ..insert('\n', {
        blockKey: 'cell-1',
        'table-cell': {'data-row': 'row-1'}
      })
      ..insert('Resposta')
      ..insert('\n', {
        blockKey: 'cell-2',
        'table-cell': {'data-row': 'row-1'}
      })
      ..insert('\n');
    return delta;
  }

  void expectHydrates(Delta delta, {int tables = 1, String? text}) {
    final quill = createTestQuill(initialHtml: '<p><br></p>');
    quill.setContents(delta);
    expect(quill.scroll.descendants<TableContainer>().toList(), hasLength(tables));
    if (text != null) expect(quill.getText(), contains(text));
  }

  group('texto em célula (o que quebrava a importação de DOCX)', () {
    test('âncora + colgroup + células com texto', () {
      expectHydrates(cellWithText(cols: true), text: 'Severidade');
    });

    test('âncora + células com texto, sem colgroup', () {
      expectHydrates(cellWithText(), text: 'Resposta');
    });

    test('sem âncora (o formato que o docxToDelta emite hoje)', () {
      expectHydrates(cellWithText(anchor: false, cols: true),
          text: 'Severidade');
    });

    test('células de cabeçalho (table-th-block)', () {
      expectHydrates(cellWithText(th: true), text: 'Severidade');
    });
  });

  test('o golden "a table with a colgroup" hidrata', () {
    final golden = jsonDecode(
        File('test/goldens/quill_table_better_1.2.3.json').readAsStringSync());
    final case_ = (golden['results'] as List)
        .firstWhere((c) => c['name'] == 'a table with a colgroup');
    expectHydrates(Delta.fromJson(case_['contents'] as List), text: 'a');
  });

  // O ETP do corpus, versionado em test/assets/docx para o CI cobrir o caso
  // real (os originais em resources/ não entram no repositório).
  test('um DOCX real do corpus abre com suas tabelas', () {
    final delta =
        docxToDelta(File('test/assets/docx/etp_corpus.docx').readAsBytesSync());
    final quill = createTestQuill(initialHtml: '<p><br></p>');
    quill.setContents(delta);
    expect(quill.scroll.descendants<TableContainer>().toList(), hasLength(3));
    expect(quill.getText(), contains('ESTUDO TÉCNICO PRELIMINAR'));
  });
}
