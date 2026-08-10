/// Repetir cabeçalho, margens de célula, AutoAjuste e o diálogo
/// Propriedades da Tabela.
///
/// O que estes testes afirmam NÃO é "o atributo foi gravado" — é o efeito
/// dele no GRAFO COMPOSTO: a linha de cabeçalho reaparece na página 2, a
/// coluna nasce com outra largura, o texto começa mais para dentro da
/// célula. Um controle de tabela só existe de verdade quando o compositor o
/// lê; provar a gravação sozinha deixaria passar exatamente o defeito que
/// esta área tem de evitar (um botão que muda o modelo e não muda um pixel).
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:test/test.dart';

import 'package:dart_quill/dart_quill_office.dart';
import 'package:dart_quill/src/document_engine/ui/table_geometry.dart';
import 'package:dart_quill/src/document_engine/ui/table_ops.dart' as ops;
import 'package:dart_quill/src/office/document/zip/zip_archive.dart';

void main() {
  final schema = officeQuillSchema();

  PMNode paragraph(String text) => schema.node('paragraph', null,
      text.isEmpty ? Fragment.empty : Fragment.from([schema.text(text)]));

  PMNode cell(String text) =>
      schema.node('tableCell', null, Fragment.from([paragraph(text)]));

  PMNode row(List<PMNode> cells) =>
      schema.node('tableRow', null, Fragment.from(cells));

  /// Um documento com UMA tabela de [rows] linhas e [columns] colunas.
  ///
  /// A primeira linha diz "CABECALHO c<n>" para ser reconhecível quando o
  /// compositor a repetir na página seguinte.
  PMNode tableDoc({
    int rows = 3,
    int columns = 3,
    Map<String, dynamic>? tableAttrs,
  }) =>
      schema.node(
        'doc',
        null,
        Fragment.from([
          schema.node(
              'table',
              tableAttrs,
              Fragment.from([
                for (var r = 0; r < rows; r++)
                  row([
                    for (var c = 0; c < columns; c++)
                      cell(r == 0 ? 'CABECALHO c$c' : 'r${r}c$c'),
                  ]),
              ])),
        ]),
      );

  int tablePositionOf(PMNode doc) {
    var offset = 0;
    for (var i = 0; i < doc.childCount; i++) {
      if (doc.child(i).type.name == 'table') return offset;
      offset += doc.child(i).nodeSize;
    }
    throw StateError('sem tabela');
  }

  EditorState stateOf(PMNode doc) =>
      EditorState.create(EditorStateConfig(doc: doc));

  EditorState run(
    EditorState state,
    bool Function(EditorState, void Function(Transaction)) action,
  ) {
    var current = state;
    action(state, (tr) => current = current.apply(tr));
    return current;
  }

  EditorState caretIn(PMNode doc, int gridRow, int gridColumn) {
    final map = OfficeTableMap.of(doc, tablePositionOf(doc));
    final target = map.cellCovering(gridRow, gridColumn)!;
    final state = stateOf(doc);
    return state.apply(
        state.tr..setSelection(TextSelection.create(doc, target.pos + 2)));
  }

  PageGraph composeOf(PMNode doc, {PageSetupTwips? setup}) =>
      LayoutComposer(setup: setup ?? const PageSetupTwips()).compose(doc);

  List<TableFragment> tableFragments(PageGraph graph) => [
        for (final page in graph.pages)
          for (final fragment in page.fragments)
            if (fragment is TableFragment) fragment,
      ];

  /// O texto da primeira célula de uma linha composta.
  String textOf(TableRowBox row) => row.cells.first.blocks
      .expand((block) => block.lines)
      .expand((line) => line.segments)
      .map((segment) => segment.text)
      .join();

  group('repetir linha de cabeçalho (w:tblHeader)', () {
    /// Uma tabela alta o bastante para atravessar a página.
    PMNode longTable() => tableDoc(rows: 60, columns: 2);

    test('sem a marca, a página 2 começa por uma linha de DADOS', () {
      final graph = composeOf(longTable());
      final fragments = tableFragments(graph);
      expect(fragments.length, greaterThan(1),
          reason: 'a tabela precisa atravessar a página para o teste valer');
      expect(fragments[1].rows.first.isRepeatedHeader, isFalse);
      expect(textOf(fragments[1].rows.first), isNot(startsWith('CABECALHO')));
    });

    test('marcada, a MESMA linha reaparece no topo da página 2', () {
      final after = run(
        caretIn(longTable(), 0, 0),
        (s, dispatch) => ops.setTableHeaderRows(s, dispatch, repeat: true),
      );

      final fragments = tableFragments(composeOf(after.doc));
      expect(fragments.length, greaterThan(1));
      final repeated = fragments[1].rows.first;
      expect(repeated.isRepeatedHeader, isTrue,
          reason: 'a cópia é marcada para não virar uma segunda posição '
              'editável do mesmo nó');
      expect(textOf(repeated), 'CABECALHO c0');
      // E a primeira página continua com o cabeçalho ORIGINAL, não uma cópia.
      expect(
          tableFragments(composeOf(after.doc))
              .first
              .rows
              .first
              .isRepeatedHeader,
          isFalse);
    });

    test('desmarcar tira a cópia da página 2', () {
      var state = run(
        caretIn(longTable(), 0, 0),
        (s, dispatch) => ops.setTableHeaderRows(s, dispatch, repeat: true),
      );
      state = run(
        caretIn(state.doc, 0, 0),
        (s, dispatch) => ops.setTableHeaderRows(s, dispatch, repeat: false),
      );

      expect(
          tableFragments(composeOf(state.doc))[1].rows.first.isRepeatedHeader,
          isFalse);
    });

    test('ligar a partir da linha 2 marca TAMBÉM a primeira', () {
      // O compositor só honra a corrida INICIAL: marcar só a segunda linha
      // gravaria um atributo que nunca vira pixel.
      final doc = longTable();
      final map = OfficeTableMap.of(doc, tablePositionOf(doc));
      final first = map.cellCovering(0, 0)!;
      final second = map.cellCovering(1, 1)!;
      var state = stateOf(doc);
      state = run(
          state,
          (s, dispatch) =>
              ops.selectCellRange(s, dispatch, first.pos + 1, second.pos + 1));
      state = run(state,
          (s, dispatch) => ops.setTableHeaderRows(s, dispatch, repeat: true));

      final fragments = tableFragments(composeOf(state.doc));
      expect(fragments[1].rows.take(2).map(textOf), ['CABECALHO c0', 'r1c0'],
          reason: 'as duas linhas do topo se repetem, na ordem');
      expect(fragments[1].rows.take(2).every((row) => row.isRepeatedHeader),
          isTrue);
    });

    test('sem alcançar a primeira linha a operação FALHA', () {
      final state = caretIn(longTable(), 3, 0);
      expect(ops.setTableHeaderRows(state, (_) {}, repeat: true), isFalse,
          reason: 'é onde o Word desabilita o botão');
    });

    test('o realce do botão segue a faixa de cabeçalho', () {
      final after = run(
        caretIn(longTable(), 0, 0),
        (s, dispatch) => ops.setTableHeaderRows(s, dispatch, repeat: true),
      );
      expect(ops.tableHeaderRowsActive(caretIn(after.doc, 0, 1)), isTrue);
      expect(ops.tableHeaderRowsActive(caretIn(after.doc, 2, 0)), isFalse);
      expect(
          ops.tableHeaderRowCount(
              OfficeTableMap.of(after.doc, tablePositionOf(after.doc))),
          1);
    });
  });

  group('margens da célula (w:tcMar)', () {
    test('empurram o conteúdo para dentro e estreitam a linha', () {
      final doc = tableDoc(tableAttrs: {
        'colWidths': [3000, 3000, 3000],
      });
      final before = tableFragments(composeOf(doc)).first.rows[1].cells.first;

      final after = run(
        caretIn(doc, 1, 0),
        (s, dispatch) => ops.applyTableProperties(s, dispatch,
            cellMargins: const {
              'top': 400,
              'bottom': 400,
              'left': 500,
              'right': 500
            }),
      );
      final cellBox =
          tableFragments(composeOf(after.doc)).first.rows[1].cells.first;

      expect(cellBox.marginLeftTwips, 500);
      expect(cellBox.marginTopTwips, 400);
      expect(cellBox.blocks.first.indentTwips, 500,
          reason: 'a margem esquerda é o recuo do conteúdo, não um enfeite');
      expect(cellBox.blocks.first.indentTwips,
          greaterThan(before.blocks.first.indentTwips));
      expect(cellBox.heightTwips, greaterThan(before.heightTwips),
          reason: 'margem superior + inferior fazem a linha crescer');
    });

    test('a margem PADRÃO da tabela vale nas células que não declaram a sua',
        () {
      final doc = tableDoc(tableAttrs: {
        'colWidths': [3000, 3000, 3000],
      });
      final after = run(
        caretIn(doc, 0, 0),
        (s, dispatch) => ops.applyTableProperties(s, dispatch,
            tableCellMargins: const {
              'top': 0,
              'bottom': 0,
              'left': 600,
              'right': 600
            }),
      );

      for (final cellBox
          in tableFragments(composeOf(after.doc)).first.rows[2].cells) {
        expect(cellBox.marginLeftTwips, 600,
            reason: 'nenhuma célula da linha 2 foi tocada individualmente');
      }
    });

    test('margem negativa é rejeitada inteira', () {
      final doc = tableDoc();
      expect(
        ops.applyTableProperties(caretIn(doc, 0, 0), (_) {},
            cellMargins: const {'left': -1}),
        isFalse,
      );
    });
  });

  group('AutoAjuste', () {
    test('à janela estica a tabela até a margem, mantendo a proporção', () {
      const setup = PageSetupTwips();
      final doc = tableDoc(tableAttrs: {
        'colWidths': [1000, 2000, 1000],
      });
      final graph = composeOf(doc, setup: setup);
      final tablePos = tablePositionOf(doc);
      final widths = officeTableColumnWidths(graph, tablePos, columns: 3);
      expect(widths.fold<int>(0, (sum, w) => sum + w),
          lessThan(setup.contentWidthTwips));

      final after = run(
        caretIn(doc, 0, 0),
        (s, dispatch) => ops.setTableAutoFit(
          s,
          dispatch,
          mode: ops.OfficeTableAutoFit.window,
          currentWidths: widths,
          availableTwips: setup.contentWidthTwips,
        ),
      );

      final composed = officeTableColumnWidths(
          composeOf(after.doc, setup: setup), tablePos,
          columns: 3);
      expect(
          composed.fold<int>(0, (sum, w) => sum + w), setup.contentWidthTwips,
          reason: 'a borda direita da tabela encosta na margem');
      // 1 : 2 : 1 continua sendo 1 : 2 : 1.
      expect(composed[1] / composed[0], closeTo(2, 0.01));
      expect(composed[2] / composed[0], closeTo(1, 0.01));
    });

    test('largura fixa CONGELA a grade que a página estava distribuindo', () {
      // Sem `colWidths`, o compositor reparte a área útil entre as colunas —
      // mudar a margem redistribui tudo. Congelar é o que faz a coluna parar
      // de andar quando a geometria muda.
      const narrow = PageSetupTwips();
      const wide = PageSetupTwips(marginLeftTwips: 200, marginRightTwips: 200);
      final doc = tableDoc();
      final tablePos = tablePositionOf(doc);
      final before = officeTableColumnWidths(
          composeOf(doc, setup: narrow), tablePos,
          columns: 3);
      expect(
          officeTableColumnWidths(composeOf(doc, setup: wide), tablePos,
              columns: 3),
          isNot(before),
          reason: 'sem grade declarada a largura segue a página');

      final after = run(
        caretIn(doc, 0, 0),
        (s, dispatch) => ops.setTableAutoFit(
          s,
          dispatch,
          mode: ops.OfficeTableAutoFit.fixed,
          currentWidths: before,
          availableTwips: narrow.contentWidthTwips,
        ),
      );

      expect(
          officeTableColumnWidths(composeOf(after.doc, setup: wide), tablePos,
              columns: 3),
          before,
          reason: 'congelada, a grade não anda mais com a margem');
    });

    test('sem largura projetada não faz nada', () {
      final doc = tableDoc();
      expect(
        ops.setTableAutoFit(caretIn(doc, 0, 0), (_) {},
            mode: ops.OfficeTableAutoFit.window,
            currentWidths: const [],
            availableTwips: 9000),
        isFalse,
      );
    });
  });

  group('propriedades em BLOCO (o diálogo)', () {
    test('uma transação só, com largura, alinhamento e margens juntos', () {
      // A grade cabe FOLGADA na área útil: com a soma acima dela o
      // compositor escala tudo (`_tableColumnWidths`) e o teste mediria o
      // escalonamento, não a largura pedida.
      final doc = tableDoc(tableAttrs: {
        'colWidths': [2000, 2000, 2000],
      });
      var transactions = 0;
      final state = caretIn(doc, 1, 1);
      var current = state;
      ops.applyTableProperties(
        state,
        (tr) {
          transactions++;
          current = current.apply(tr);
        },
        columnWidthTwips: 3000,
        cellVerticalAlign: 'bottom',
        cellMargins: const {'left': 300},
        rowHeightTwips: 1200,
        rowCantSplit: true,
      );

      expect(transactions, 1, reason: 'um Ctrl+Z tem de desfazer o OK inteiro');

      final fragment = tableFragments(composeOf(current.doc)).first;
      final cellBox = fragment.rows[1].cells[1];
      expect(cellBox.widthTwips, 3000, reason: 'a coluna 1 mudou de largura');
      expect(cellBox.verticalAlign, TableCellVerticalAlign.bottom);
      expect(cellBox.marginLeftTwips, 300,
          reason: 'a margem não foi apagada pela escrita da largura');
      expect(fragment.rows[1].heightTwips, greaterThanOrEqualTo(1200));
      expect(fragment.rows[1].cantSplit, isTrue);
    });

    test('altura zero devolve a linha à altura automática', () {
      final doc = tableDoc();
      var state = run(
          caretIn(doc, 1, 0),
          (s, dispatch) =>
              ops.setRowProperties(s, dispatch, heightTwips: 2000));
      expect(
          tableFragments(composeOf(state.doc)).first.rows[1].heightTwips, 2000);

      state = run(caretIn(state.doc, 1, 0),
          (s, dispatch) => ops.setRowProperties(s, dispatch, heightTwips: 0));
      expect(tableFragments(composeOf(state.doc)).first.rows[1].heightTwips,
          lessThan(2000),
          reason: 'a linha voltou a ser do tamanho do conteúdo');
    });

    test('sem nada a mudar, nenhuma transação sai', () {
      final doc = tableDoc();
      expect(ops.applyTableProperties(caretIn(doc, 0, 0), (_) {}), isFalse);
    });
  });

  group('exportação DOCX', () {
    String documentXmlOf(Uint8List docx) {
      final archive = ZipArchive.decodeBytes(docx);
      for (final entry in archive.entries) {
        if (entry.name == 'word/document.xml') {
          return utf8.decode(entry.content);
        }
      }
      throw StateError('sem word/document.xml');
    }

    test('as propriedades novas chegam ao XML nas tags do OOXML', () {
      var state = run(
        caretIn(tableDoc(rows: 4), 0, 0),
        (s, dispatch) => ops.setTableHeaderRows(s, dispatch, repeat: true),
      );
      state = run(
        caretIn(state.doc, 1, 1),
        (s, dispatch) => ops.applyTableProperties(
          s,
          dispatch,
          tableCellMargins: const {'left': 200, 'right': 200},
          rowHeightTwips: 900,
          rowHeightRule: 'atLeast',
          rowCantSplit: true,
          columnWidthTwips: 2400,
          cellMargins: const {'top': 150},
          cellVerticalAlign: 'bottom',
        ),
      );

      final xml = documentXmlOf(
          OfficeDocxCodec(schema: schema).exportDocument(state.doc));
      expect(xml, contains('<w:tblHeader/>'));
      expect(xml, contains('<w:trHeight w:hRule="atLeast" w:val="900"/>'));
      expect(xml, contains('<w:cantSplit/>'));
      expect(xml, contains('<w:gridCol w:w="2400"/>'));
      expect(xml, contains('<w:tcW w:w="2400" w:type="dxa"/>'));
      expect(
          xml, contains('<w:tcMar><w:top w:w="150" w:type="dxa"/></w:tcMar>'));
      expect(xml, contains('<w:vAlign w:val="bottom"/>'));
      expect(
          xml,
          contains('<w:tblCellMar><w:left w:w="200" w:type="dxa"/>'
              '<w:right w:w="200" w:type="dxa"/></w:tblCellMar>'));
    });
  });

  group('corpus real (etp_corpus.docx)', () {
    const path = 'test/assets/docx/etp_corpus.docx';

    /// A posição da primeira tabela do documento importado.
    int? firstTablePos(PMNode doc) {
      var offset = 0;
      for (var i = 0; i < doc.childCount; i++) {
        if (doc.child(i).type.name == 'table') return offset;
        offset += doc.child(i).nodeSize;
      }
      return null;
    }

    test('as divisas de uma tabela IMPORTADA batem com a projeção dela', () {
      if (!File(path).existsSync()) {
        markTestSkipped('corpus ausente: $path');
        return;
      }
      final codec = OfficeDocxCodec(schema: schema);
      final imported = codec.import(File(path).readAsBytesSync());
      final doc = PMNode.fromJSON(schema, imported.snapshot.body);
      final tablePos = firstTablePos(doc);
      expect(tablePos, isNotNull, reason: 'o corpus tem tabelas');

      final graph = composeOf(doc);
      final map = OfficeTableMap.of(doc, tablePos!);
      final edges =
          officeTableColumnEdges(graph, tablePos, columns: map.columns);
      expect(edges, hasLength(map.columns));
      for (var i = 1; i < edges.length; i++) {
        expect(edges[i], greaterThan(edges[i - 1]),
            reason: 'as divisas crescem da esquerda para a direita');
      }
      expect(edges.last,
          lessThanOrEqualTo(const PageSetupTwips().contentWidthTwips),
          reason: 'a última divisa é a borda direita da tabela, dentro da '
              'área útil');
    });

    test('marcar o cabeçalho de uma tabela importada repete a linha', () {
      if (!File(path).existsSync()) {
        markTestSkipped('corpus ausente: $path');
        return;
      }
      final codec = OfficeDocxCodec(schema: schema);
      final imported = codec.import(File(path).readAsBytesSync());
      final doc = PMNode.fromJSON(schema, imported.snapshot.body);
      final tablePos = firstTablePos(doc)!;
      final map = OfficeTableMap.of(doc, tablePos);
      final first = map.cellCovering(0, 0)!;

      var state = stateOf(doc);
      state = state.apply(
          state.tr..setSelection(TextSelection.create(doc, first.pos + 2)));
      final after = run(state,
          (s, dispatch) => ops.setTableHeaderRows(s, dispatch, repeat: true));

      final rowPos =
          ops.tableRowPositions(OfficeTableMap.of(after.doc, tablePos)).first;
      expect((after.doc.nodeAt(rowPos)!.attrs['word'] as Map)['tblHeader'],
          isTrue);
      // E o compositor passa a tratar a linha como cabeçalho na projeção —
      // é o que faz a cópia aparecer quando a tabela cruza a página.
      final fragment = tableFragments(composeOf(after.doc))
          .firstWhere((fragment) => fragment.docFrom == tablePos);
      expect(fragment.rows.first.repeatHeader, isTrue);
    });
  });

  group('geometria projetada', () {
    test('as divisas de coluna acumulam as larguras compostas', () {
      final doc = tableDoc(tableAttrs: {
        'colWidths': [1500, 2500, 2000],
      });
      final tablePos = tablePositionOf(doc);
      final graph = composeOf(doc);
      expect(officeTableColumnWidths(graph, tablePos, columns: 3),
          [1500, 2500, 2000]);
      expect(officeTableColumnEdges(graph, tablePos, columns: 3),
          [1500, 4000, 6000]);
    });

    test('uma célula mesclada não engana a medição das colunas', () {
      final doc = schema.node(
        'doc',
        null,
        Fragment.from([
          schema.node(
              'table',
              {
                'colWidths': [1500, 2500]
              },
              Fragment.from([
                row([
                  schema.node(
                      'tableCell',
                      {
                        'cell': {'colspan': 2}
                      },
                      Fragment.from([paragraph('mesclada')]))
                ]),
                row([cell('a'), cell('b')]),
              ])),
        ]),
      );
      final graph = composeOf(doc);
      expect(officeTableColumnWidths(graph, tablePositionOf(doc), columns: 2),
          [1500, 2500],
          reason: 'a linha mesclada mede 4000 e não diz como repartir');
    });
  });
}
