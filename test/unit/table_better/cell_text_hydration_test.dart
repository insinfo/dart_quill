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
  //
  // As contagens vêm do XML do proprio DOCX (w:tr / w:tblGrid), não do que o
  // port produz: a tabela 1 tem 5 linhas x 3 colunas e a tabela 3 (TCO) tem
  // 3 linhas x 7 colunas, com gridSpan 5 e dois vMerge na primeira linha.
  // Sem estas asserções uma tabela podia colapsar em UMA linha só (ou ganhar
  // uma coluna fantasma) sem nenhum teste reclamar.
  group('DOCX real do corpus', () {
    late List<TableContainer> tables;

    setUpAll(() {
      final delta = docxToDelta(
          File('test/assets/docx/etp_corpus.docx').readAsBytesSync());
      final quill = createTestQuill(initialHtml: '<p><br></p>');
      quill.setContents(delta);
      tables = quill.scroll.descendants<TableContainer>().toList();
    });

    test('abre com as três tabelas do documento', () {
      expect(tables, hasLength(3));
    });

    test('a primeira tabela tem 5 linhas de 3 colunas', () {
      final rows = tables[0].element.querySelectorAll('tr');
      expect(rows, hasLength(5),
          reason: 'as linhas não podem colapsar numa só');
      for (final row in rows) {
        expect(row.querySelectorAll('td'), hasLength(3));
      }
    });

    test('a tabela de TCO mantém 3 linhas, colgroup de 7 e os spans', () {
      final tco = tables[2];
      expect(tco.element.querySelectorAll('tr'), hasLength(3));
      expect(tco.element.querySelectorAll('col'), hasLength(7),
          reason: 'o colgroup precisa ter uma coluna por gridCol do DOCX');
      final html = tco.element.outerHTML;
      expect(html, contains('colspan="5"'),
          reason: 'o gridSpan do cabeçalho vira colspan');
      expect(html, contains('rowspan="2"'),
          reason: 'os vMerge viram rowspan');
    });

    test('uma célula com dois parágrafos continua sendo UMA célula', () {
      // A última linha da TCO tem 7 células no DOCX; uma delas ("R$" +
      // "2.823.940,44") tem dois parágrafos. Sem o cellId do Delta chegando ao
      // bloco, o merge de células não os reconhece e a linha ganha uma coluna
      // fantasma — foi o que deformou a tabela na importação.
      final rows = tables[2].element.querySelectorAll('tr');
      expect(rows[0].querySelectorAll('td'), hasLength(3));
      expect(rows[1].querySelectorAll('td'), hasLength(5));
      expect(rows[2].querySelectorAll('td'), hasLength(7),
          reason: 'a célula de dois parágrafos não pode virar duas');
    });
  });
}
