/// F5 — formatação de tabela: bordas, sombreamento, alinhamento vertical da
/// célula e distribuir linhas/colunas.
///
/// O foco é o MODELO, e especificamente o LUGAR onde cada propriedade é
/// gravada. Todas elas existem em dois dialetos no documento (o mapa `cell`,
/// que o compositor lê primeiro, e o mapa `word`, que a exportação devolve
/// para o OOXML); gravar no lugar errado produz o pior defeito possível
/// nesta área — o botão "funciona" na tela e o DOCX sai sem a formatação,
/// ou o contrário.
@TestOn('vm')
library;

import 'package:test/test.dart';

import 'package:dart_quill/dart_quill_office.dart';
import 'package:dart_quill/src/document_engine/ui/table_ops.dart' as ops;

void main() {
  final schema = officeQuillSchema();

  PMNode cell(String text) => schema.node(
        'tableCell',
        null,
        Fragment.from([
          schema.node(
              'paragraph',
              null,
              text.isEmpty
                  ? Fragment.empty
                  : Fragment.from([schema.text(text)])),
        ]),
      );

  PMNode row(List<PMNode> cells) =>
      schema.node('tableRow', null, Fragment.from(cells));

  PMNode tableDoc(List<PMNode> rows, {Map<String, dynamic>? tableAttrs}) =>
      schema.node(
        'doc',
        null,
        Fragment.from([
          schema.node('paragraph', null, Fragment.from([schema.text('antes')])),
          schema.node('table', tableAttrs, Fragment.from(rows)),
          schema.node(
              'paragraph', null, Fragment.from([schema.text('depois')])),
        ]),
      );

  PMNode grid3x3({Map<String, dynamic>? tableAttrs}) => tableDoc([
        for (var r = 0; r < 3; r++)
          row([for (var c = 0; c < 3; c++) cell('r${r}c$c')]),
      ], tableAttrs: tableAttrs);

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

  /// Aplica transações num estado local, como faria a view.
  EditorState run(
    EditorState state,
    bool Function(EditorState, void Function(Transaction)) action,
  ) {
    var current = state;
    action(state, (tr) => current = current.apply(tr));
    return current;
  }

  /// Estado com o CARET dentro da célula (linha, coluna) da grade.
  EditorState caretIn(PMNode doc, int gridRow, int gridColumn) {
    final map = OfficeTableMap.of(doc, tablePositionOf(doc));
    final target = map.cellCovering(gridRow, gridColumn)!;
    final state = stateOf(doc);
    return state.apply(
        state.tr..setSelection(TextSelection.create(doc, target.pos + 2)));
  }

  /// Estado com a LINHA [gridRow] selecionada como células.
  EditorState rowSelected(PMNode doc, int gridRow) =>
      run(caretIn(doc, gridRow, 0), ops.selectTableRow);

  Map? bordersOf(PMNode doc, int gridRow, int gridColumn) {
    final map = OfficeTableMap.of(doc, tablePositionOf(doc));
    final node = map.cellCovering(gridRow, gridColumn)!.node;
    return (node.attrs['word'] as Map?)?['borders'] as Map?;
  }

  Map? cellMapOf(PMNode doc, int gridRow, int gridColumn) {
    final map = OfficeTableMap.of(doc, tablePositionOf(doc));
    return map.cellCovering(gridRow, gridColumn)!.node.attrs['cell'] as Map?;
  }

  Map? wordMapOf(PMNode doc, int gridRow, int gridColumn) {
    final map = OfficeTableMap.of(doc, tablePositionOf(doc));
    return map.cellCovering(gridRow, gridColumn)!.node.attrs['word'] as Map?;
  }

  group('bordas', () {
    test('todas as bordas gravam as quatro arestas em word.borders', () {
      final doc = grid3x3();
      final after = run(
        caretIn(doc, 1, 1),
        (s, dispatch) =>
            ops.setCellBorders(s, dispatch, ops.OfficeCellBorders.all),
      );

      final borders = bordersOf(after.doc, 1, 1)!;
      expect(borders.keys.toSet(), {'top', 'bottom', 'left', 'right'});
      for (final side in borders.keys) {
        expect((borders[side] as Map)['val'], 'single',
            reason: 'a aresta $side tem de ser visível');
        expect((borders[side] as Map)['sizeEighths'], 4,
            reason: 'meio ponto, o padrão do Word (w:sz em oitavos)');
      }
    });

    test('sem bordas grava `nil` EXPLÍCITO, não a ausência da chave', () {
      // Omitir a chave faria a célula herdar a borda da tabela: "não opinei"
      // e "não quero" são coisas diferentes para o compositor.
      final doc = grid3x3();
      final after = run(
        caretIn(doc, 0, 0),
        (s, dispatch) =>
            ops.setCellBorders(s, dispatch, ops.OfficeCellBorders.none),
      );

      final borders = bordersOf(after.doc, 0, 0)!;
      expect(borders.keys.toSet(), {'top', 'bottom', 'left', 'right'});
      for (final side in borders.keys) {
        expect((borders[side] as Map)['val'], 'nil');
      }
    });

    test('externas contornam o RETÂNGULO da seleção, não cada célula', () {
      final doc = grid3x3();
      final after = run(
        rowSelected(doc, 1),
        (s, dispatch) =>
            ops.setCellBorders(s, dispatch, ops.OfficeCellBorders.outside),
      );

      // Célula do meio da linha: só topo e base estão na borda do retângulo.
      expect(bordersOf(after.doc, 1, 1)!.keys.toSet(), {'top', 'bottom'});
      // Primeira célula: topo, base e a esquerda.
      expect(
          bordersOf(after.doc, 1, 0)!.keys.toSet(), {'top', 'bottom', 'left'});
      // Última: topo, base e a direita.
      expect(
          bordersOf(after.doc, 1, 2)!.keys.toSet(), {'top', 'bottom', 'right'});
      // Nada foi gravado nas outras linhas.
      expect(bordersOf(after.doc, 0, 0), isNull);
    });

    test('internas são o complemento: só as divisas dentro da seleção', () {
      final doc = grid3x3();
      final after = run(
        rowSelected(doc, 1),
        (s, dispatch) =>
            ops.setCellBorders(s, dispatch, ops.OfficeCellBorders.inside),
      );

      expect(bordersOf(after.doc, 1, 0)!.keys.toSet(), {'right'});
      expect(bordersOf(after.doc, 1, 1)!.keys.toSet(), {'left', 'right'});
      expect(bordersOf(after.doc, 1, 2)!.keys.toSet(), {'left'});
    });

    test('internas numa célula só não têm o que gravar', () {
      final doc = grid3x3();
      final state = caretIn(doc, 0, 0);
      expect(
        ops.setCellBorders(state, (_) {}, ops.OfficeCellBorders.inside),
        isFalse,
        reason: 'uma célula sozinha não tem divisa interna',
      );
    });

    test('uma aresta isolada não apaga as outras já gravadas', () {
      final doc = grid3x3();
      var after = run(
        caretIn(doc, 2, 2),
        (s, dispatch) =>
            ops.setCellBorders(s, dispatch, ops.OfficeCellBorders.all),
      );
      after = run(
        caretIn(after.doc, 2, 2),
        (s, dispatch) =>
            ops.setCellBorders(s, dispatch, ops.OfficeCellBorders.top),
      );

      final borders = bordersOf(after.doc, 2, 2)!;
      expect(borders.keys.toSet(), {'top', 'bottom', 'left', 'right'},
          reason: 'pedir a borda superior não é pedir para remover o resto');
    });

    test('fora de tabela nenhuma borda é aplicada', () {
      final doc = grid3x3();
      final state = stateOf(doc);
      expect(ops.setCellBorders(state, (_) {}, ops.OfficeCellBorders.all),
          isFalse);
    });
  });

  group('sombreamento', () {
    test('grava nos DOIS dialetos, cada um com a sintaxe dele', () {
      final doc = grid3x3();
      final after = run(
        rowSelected(doc, 0),
        (s, dispatch) => ops.setCellShading(s, dispatch, '#c00000'),
      );

      for (var c = 0; c < 3; c++) {
        expect(cellMapOf(after.doc, 0, c)!['background'], '#c00000',
            reason: 'o compositor lê o CSS, com #');
        final shading = wordMapOf(after.doc, 0, c)!['shading'] as Map;
        expect(shading['fill'], 'C00000',
            reason: 'w:fill do OOXML é hexa SEM #');
        expect(shading['val'], 'clear');
      }
      expect(cellMapOf(after.doc, 1, 0)?['background'], isNull,
          reason: 'só a linha selecionada foi pintada');
    });

    test('sem cor limpa os dois lugares', () {
      final doc = grid3x3();
      var after = run(caretIn(doc, 1, 1),
          (s, dispatch) => ops.setCellShading(s, dispatch, '#ffff00'));
      after = run(caretIn(after.doc, 1, 1),
          (s, dispatch) => ops.setCellShading(s, dispatch, null));

      expect(cellMapOf(after.doc, 1, 1)?['background'], isNull);
      expect(wordMapOf(after.doc, 1, 1)?['shading'], isNull,
          reason: 'deixar o w:shd para trás repintaria a célula no Word');
    });
  });

  group('alinhamento vertical', () {
    test('grava verticalAlign na célula e vAlign no dialeto Word', () {
      final doc = grid3x3();
      final after = run(caretIn(doc, 2, 0),
          (s, dispatch) => ops.setCellVerticalAlign(s, dispatch, 'bottom'));

      expect(cellMapOf(after.doc, 2, 0)!['verticalAlign'], 'bottom');
      expect(wordMapOf(after.doc, 2, 0)!['vAlign'], 'bottom');
    });

    test('"middle" vira "center" — o vocabulário do OOXML', () {
      final doc = grid3x3();
      final after = run(caretIn(doc, 0, 1),
          (s, dispatch) => ops.setCellVerticalAlign(s, dispatch, 'middle'));

      expect(cellMapOf(after.doc, 0, 1)!['verticalAlign'], 'center');
      expect(wordMapOf(after.doc, 0, 1)!['vAlign'], 'center');
    });

    test('alinha TODAS as células da seleção', () {
      final doc = grid3x3();
      final after = run(rowSelected(doc, 0),
          (s, dispatch) => ops.setCellVerticalAlign(s, dispatch, 'center'));

      for (var c = 0; c < 3; c++) {
        expect(cellMapOf(after.doc, 0, c)!['verticalAlign'], 'center');
      }
    });

    test('valor desconhecido é rejeitado', () {
      final doc = grid3x3();
      final state = caretIn(doc, 0, 0);
      expect(ops.setCellVerticalAlign(state, (_) {}, 'baseline'), isFalse);
    });
  });

  group('distribuir', () {
    test('colunas: iguala a grade PRESERVANDO a largura declarada', () {
      final doc = grid3x3(tableAttrs: {
        'colWidths': [4000, 1000, 1000],
      });
      final after = run(caretIn(doc, 0, 0),
          (s, dispatch) => ops.distributeTableColumns(s, dispatch));

      final widths = after.doc
          .nodeAt(tablePositionOf(after.doc))!
          .attrs['colWidths'] as List;
      expect(widths, [2000, 2000, 2000]);
      expect(widths.fold<int>(0, (sum, w) => sum + (w as int)), 6000,
          reason: 'distribuir não pode mudar a largura da tabela');
      // A grade e o `width` das células têm de concordar (mesma regra do
      // arrasto de coluna).
      for (var c = 0; c < 3; c++) {
        expect(cellMapOf(after.doc, 1, c)!['width'], 2000);
      }
    });

    test('colunas: sem grade declarada usa a largura oferecida', () {
      final doc = grid3x3();
      final after = run(
        caretIn(doc, 0, 0),
        (s, dispatch) =>
            ops.distributeTableColumns(s, dispatch, totalWidthTwips: 9000),
      );

      expect(after.doc.nodeAt(tablePositionOf(after.doc))!.attrs['colWidths'],
          [3000, 3000, 3000]);
    });

    test('colunas: sem grade e sem largura oferecida não faz nada', () {
      final doc = grid3x3();
      expect(ops.distributeTableColumns(caretIn(doc, 0, 0), (_) {}), isFalse,
          reason: 'espremer a tabela num palpite é pior do que não agir');
    });

    test('colunas: a sobra do arredondamento fica na última', () {
      final doc = grid3x3(tableAttrs: {
        'colWidths': [1000, 1000, 1001],
      });
      final after = run(caretIn(doc, 0, 0),
          (s, dispatch) => ops.distributeTableColumns(s, dispatch));

      final widths = after.doc
          .nodeAt(tablePositionOf(after.doc))!
          .attrs['colWidths'] as List;
      expect(widths.fold<int>(0, (sum, w) => sum + (w as int)), 3001,
          reason: 'a borda direita da tabela não pode andar');
    });

    test('linhas: grava a altura em TODAS as linhas, com regra atLeast', () {
      final doc = grid3x3();
      final after = run(
        caretIn(doc, 1, 1),
        (s, dispatch) => ops.distributeTableRows(s, dispatch, heightTwips: 600),
      );

      final table = after.doc.nodeAt(tablePositionOf(after.doc))!;
      for (var r = 0; r < table.childCount; r++) {
        final word = table.child(r).attrs['word'] as Map;
        expect(word['heightTwips'], 600);
        expect(word['heightRule'], 'atLeast',
            reason: '`exact` cortaria em silêncio o conteúdo que não coubesse');
      }
    });

    test('linhas: altura não positiva é rejeitada', () {
      final doc = grid3x3();
      expect(
        ops.distributeTableRows(caretIn(doc, 0, 0), (_) {}, heightTwips: 0),
        isFalse,
      );
    });
  });

  group('escopo da formatação', () {
    test('sem seleção de células o alvo é a célula do cursor', () {
      final doc = grid3x3();
      final scope = ops.tableFormatScope(caretIn(doc, 2, 1))!;
      expect(scope.cells, hasLength(1));
      expect(scope.cells.single.node.textContent, 'r2c1');
    });

    test('com seleção de células o alvo é o retângulo inteiro', () {
      final doc = grid3x3();
      final scope = ops.tableFormatScope(rowSelected(doc, 2))!;
      expect([for (final cell in scope.cells) cell.node.textContent],
          ['r2c0', 'r2c1', 'r2c2']);
    });

    test('fora de tabela não há escopo', () {
      expect(ops.tableFormatScope(stateOf(grid3x3())), isNull);
    });
  });
}
