/// Colunas: o fluxo de jornal do Word.
///
/// A propriedade que define colunas não é a largura — é o FLUXO: a coluna 1
/// enche até o rodapé e o texto continua no TOPO da coluna 2, na MESMA
/// página. Só quando a última coluna enche é que a página fecha. Um layout
/// que só estreitasse as linhas e continuasse quebrando a página no fim da
/// primeira coluna pareceria certo numa captura de tela e estaria errado no
/// segundo parágrafo.
@TestOn('vm')
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:test/test.dart';

import 'package:dart_quill/dart_quill_office.dart';
import 'package:dart_quill/src/office/document/zip/zip_archive.dart';

void main() {
  final schema = officeQuillSchema();

  PMNode paragraph(String text) => schema.node('paragraph', null,
      text.isEmpty ? Fragment.empty : Fragment.from([schema.text(text)]));

  PMNode docOf(int count) => schema.node(
      'doc',
      null,
      Fragment.from([
        for (var i = 0; i < count; i++)
          paragraph('Parágrafo $i com texto suficiente para ocupar linhas e '
              'forçar a paginação a decidir onde quebrar.'),
      ]));

  const oneColumn = PageSetupTwips(
    widthTwips: 11906,
    heightTwips: 16838,
    marginTopTwips: 1418,
    marginRightTwips: 1701,
    marginBottomTwips: 1418,
    marginLeftTwips: 1701,
  );
  const twoColumns = PageSetupTwips(
    widthTwips: 11906,
    heightTwips: 16838,
    marginTopTwips: 1418,
    marginRightTwips: 1701,
    marginBottomTwips: 1418,
    marginLeftTwips: 1701,
    columnCount: 2,
    columnSpacingTwips: 720,
  );

  group('geometria', () {
    test('duas colunas dividem a área útil menos o espaçamento', () {
      final content = twoColumns.contentWidthTwips;
      expect(twoColumns.columnWidthTwips, (content - 720) ~/ 2);
      expect(twoColumns.columnLeftTwips(0), 0);
      expect(twoColumns.columnLeftTwips(1), twoColumns.columnWidthTwips + 720);
    });

    test('uma coluna é a área útil inteira — nada muda no caso comum', () {
      expect(oneColumn.columnWidthTwips, oneColumn.contentWidthTwips);
      expect(oneColumn.columnLeftTwips(0), 0);
      expect(oneColumn.columnLeftTwips(1), 0,
          reason: 'não existe coluna 1 num documento de coluna única');
    });

    test('colunas demais para o papel não produzem largura zero', () {
      const absurdo = PageSetupTwips(
        widthTwips: 11906,
        marginLeftTwips: 1701,
        marginRightTwips: 1701,
        columnCount: 40,
        columnSpacingTwips: 720,
      );
      expect(absurdo.columnWidthTwips, greaterThan(0),
          reason: 'largura zero faria toda palavra estourar a linha e o '
              'compositor entraria em laço');
    });
  });

  group('fluxo', () {
    test('a coluna 2 continua na MESMA página, não na próxima', () {
      final doc = docOf(60);
      final umaColuna = LayoutComposer(setup: oneColumn).compose(doc);
      final duasColunas = LayoutComposer(setup: twoColumns).compose(doc);

      expect(umaColuna.pages.length, greaterThan(1));
      // A área útil é a mesma; o que muda é o texto caber em duas colunas por
      // página em vez de uma. Se cada coluna fechasse a página, a contagem
      // seria IGUAL ou maior — nunca menor.
      expect(duasColunas.pages.length, lessThan(umaColuna.pages.length),
          reason: 'duas colunas cabem na mesma página; se a página fechasse '
              'no fim da coluna 1 o documento não encurtaria');
    });

    test('a primeira página usa as duas colunas', () {
      final graph = LayoutComposer(setup: twoColumns).compose(docOf(60));
      final colunas = <int>{
        for (final fragment in graph.pages.first.fragments)
          fragment.columnIndex,
      };
      expect(colunas, containsAll([0, 1]),
          reason: 'sem fragmento na coluna 1 a metade direita fica em branco');
    });

    test('o texto da coluna 2 vem DEPOIS do da coluna 1', () {
      final graph = LayoutComposer(setup: twoColumns).compose(docOf(60));
      final page = graph.pages.first;
      final ultimaDaPrimeira = page.fragments
          .where((fragment) => fragment.columnIndex == 0)
          .last
          .docPos;
      final primeiraDaSegunda = page.fragments
          .firstWhere((fragment) => fragment.columnIndex == 1)
          .docPos;
      expect(primeiraDaSegunda, greaterThan(ultimaDaPrimeira),
          reason: 'é fluxo de jornal: a coluna 2 continua a 1');
    });

    test('a coluna 2 recomeça no TOPO do corpo', () {
      final graph = LayoutComposer(setup: twoColumns).compose(docOf(60));
      final page = graph.pages.first;
      final topoDaSegunda = page.fragments
          .firstWhere((fragment) => fragment.columnIndex == 1)
          .yTwips;
      final fundoDaPrimeira = page.fragments
          .where((fragment) => fragment.columnIndex == 0)
          .map((fragment) => fragment.yTwips + fragment.heightTwips)
          .reduce((a, b) => a > b ? a : b);
      expect(topoDaSegunda, lessThan(fundoDaPrimeira),
          reason: 'y se REPETE entre colunas — é o x que as separa');
    });

    test('as linhas encurtam para a largura da coluna', () {
      final graph = LayoutComposer(setup: twoColumns).compose(docOf(10));
      final larguras = [
        for (final fragment in graph.pages.first.fragments)
          if (fragment is BlockFragment)
            for (final line in fragment.lines) line.widthTwips,
      ];
      expect(larguras, isNotEmpty);
      expect(larguras.reduce((a, b) => a > b ? a : b),
          lessThanOrEqualTo(twoColumns.columnWidthTwips));
    });

    test('coluna única compõe exatamente como antes', () {
      final doc = docOf(30);
      final antes = LayoutComposer(setup: oneColumn).compose(doc);
      expect(
          antes.pages.every((page) =>
              page.fragments.every((fragment) => fragment.columnIndex == 0)),
          isTrue);
    });
  });

  group('DOCX', () {
    Uint8List corpus() => Uint8List.fromList(
        File('test/assets/docx/etp_corpus.docx').readAsBytesSync());

    test('a contagem escolhida chega ao w:cols do arquivo', () {
      final codec = OfficeDocxCodec(schema: schema);
      final bytes = corpus();
      final imported = codec.import(bytes, includePackageResources: false);
      final setup = OfficeDocxCodec.pageSetupOf(imported.snapshot);
      expect(setup.columnCount, isNull, reason: "o corpus não declara w:cols");

      final exported = codec.exportEditedFromDocx(
        bytes,
        imported.snapshot.sourceMap,
        PMNode.fromJSON(schema, imported.snapshot.body),
        pageSetup: PageSetupTwips(
          widthTwips: setup.widthTwips,
          heightTwips: setup.heightTwips,
          marginTopTwips: setup.marginTopTwips,
          marginRightTwips: setup.marginRightTwips,
          marginBottomTwips: setup.marginBottomTwips,
          marginLeftTwips: setup.marginLeftTwips,
          headerDistanceTwips: setup.headerDistanceTwips,
          footerDistanceTwips: setup.footerDistanceTwips,
          columnCount: 2,
          columnSpacingTwips: 567,
        ),
      );

      final xml =
          ZipArchive.decodeBytes(exported).readString('word/document.xml')!;
      expect(xml, contains('w:num="2"'),
          reason: 'sem isto o menu mudaria a tela e não o arquivo');
      expect(xml, contains('w:space="567"'));

      // E reabrir devolve as duas colunas — round-trip fechado.
      final reopened = codec.import(exported, includePackageResources: false);
      expect(OfficeDocxCodec.pageSetupOf(reopened.snapshot).columnCount, 2);
    });

    test('documento não editado mantém o w:cols de origem', () {
      final codec = OfficeDocxCodec(schema: schema);
      final bytes = corpus();
      final imported = codec.import(bytes, includePackageResources: false);

      final exported = codec.exportEditedFromDocx(
        bytes,
        imported.snapshot.sourceMap,
        PMNode.fromJSON(schema, imported.snapshot.body),
      );

      expect(
          OfficeDocxCodec.pageSetupOf(codec
                  .import(exported, includePackageResources: false)
                  .snapshot)
              .columnCount,
          OfficeDocxCodec.pageSetupOf(imported.snapshot).columnCount);
    });
  });

  group('quebra de coluna', () {
    /// `w:br w:type="column"` — o compositor já tratava como salto de página
    /// num grafo monocoluna; com colunas de verdade ele salta para a próxima
    /// COLUNA, que é o que o Word faz.
    test('a quebra de coluna salta para a coluna seguinte, não para a página',
        () {
      final doc = schema.node(
          'doc',
          null,
          Fragment.from([
            paragraph('antes da quebra'),
            schema.node(
                'paragraph',
                null,
                Fragment.from([
                  schema.node('hardBreak', {'breakType': 'column'}),
                  schema.text('depois da quebra'),
                ])),
          ]));

      final graph = LayoutComposer(setup: twoColumns).compose(doc);

      expect(graph.pages, hasLength(1),
          reason: 'há coluna livre à direita; fechar a página desperdiçaria '
              'metade dela');
      final colunas = <int>{
        for (final fragment in graph.pages.first.fragments)
          fragment.columnIndex,
      };
      expect(colunas, containsAll([0, 1]));
    });

    test('a quebra de PÁGINA fecha a folha mesmo com coluna livre', () {
      // O contraste com o teste acima é o ponto: num grafo monocoluna os
      // dois tipos davam no mesmo, e por isso podiam compartilhar o sinal.
      final doc = schema.node(
          'doc',
          null,
          Fragment.from([
            paragraph('antes da quebra'),
            schema.node(
                'paragraph',
                null,
                Fragment.from([
                  schema.node('hardBreak', {'breakType': 'page'}),
                  schema.text('depois da quebra'),
                ])),
          ]));

      final graph = LayoutComposer(setup: twoColumns).compose(doc);

      expect(graph.pages, hasLength(2),
          reason: 'quebra de página é quebra de PÁGINA, não de coluna');
      expect(
          graph.pages.first.fragments
              .every((fragment) => fragment.columnIndex == 0),
          isTrue,
          reason: 'a coluna 2 da primeira página fica vazia, como no Word');
    });
  });
}
