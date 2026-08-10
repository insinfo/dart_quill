/// F11 — o grupo PARÁGRAFO da Página Inicial: entrelinha, espaçamento,
/// sombreamento, bordas e as galerias de lista.
///
/// O que estes testes protegem é COMPORTAMENTO, não gravação de atributo.
/// Um teste que só conferisse `style['lineTwips'] == 360` passaria mesmo que
/// o compositor ignorasse a chave — que é exatamente o botão-que-não-faz-nada
/// proibido pelo plano. Por isso cada caso compõe o `PageGraph` e mede a
/// consequência: a linha ficou mais alta, o fragmento ganhou cor, o marcador
/// mudou. Onde há exportação, o DOCX é reaberto e conferido.
@TestOn('vm')
library;

import 'package:test/test.dart';

import 'package:dart_quill/dart_quill_office.dart';
import 'package:dart_quill/src/document_engine/ui/dialogs/paragraph_dialog.dart';
import 'package:dart_quill/src/document_engine/ui/ribbon_actions.dart'
    as actions;
import 'package:dart_quill/src/platform/dom.dart';

import '../../../support/fake_dom.dart';
import '../../../support/pdf_reader.dart';
import '../../../support/test_helpers.dart';

void main() {
  final schema = officeQuillSchema();

  late DomAdapter adapter;
  late DomElement host;
  OfficeWordEditor? editor;

  setUpAll(initializeFakeDom);

  setUp(() {
    adapter = testAdapter;
    host = adapter.document.createElement('div');
    adapter.document.body.append(host);
  });

  tearDown(() {
    editor?.dispose();
    editor = null;
    host.remove();
  });

  PMNode paragraph(String text) =>
      schema.node('paragraph', null, Fragment.from([schema.text(text)]));

  PMNode docOf(List<PMNode> blocks) =>
      schema.node('doc', null, Fragment.from(blocks));

  OfficeWordEditor mount([List<PMNode>? blocks]) =>
      editor = OfficeWordEditor.mount(
        host: host,
        adapter: adapter,
        document: docOf(blocks ??
            [
              paragraph('Primeiro parágrafo do documento de teste.'),
              paragraph('Segundo parágrafo.'),
            ]),
        schema: schema,
      );

  /// Põe o caret no primeiro caractere do bloco [index].
  void caretIn(OfficeWordEditor instance, int index) {
    var offset = 0;
    for (var i = 0; i < index; i++) {
      offset += instance.state.doc.child(i).nodeSize;
    }
    instance.view.dispatch(instance.state.tr
      ..setSelection(TextSelection.create(instance.state.doc, offset + 1)));
  }

  BlockFragment blockAt(OfficeWordEditor instance, int index) =>
      instance.pageGraph.pages.first.fragments
          .whereType<BlockFragment>()
          .elementAt(index);

  void click(DomElement element) => (element as FakeDomElement).dispatchEvent(
      'click', FakeDomMouseEvent(type: 'click', target: element));

  List<DomElement> menuItems() => host.querySelectorAll('.dq-office-menu-item');

  DomElement menuItem(String text) =>
      menuItems().firstWhere((item) => (item.textContent ?? '').contains(text),
          orElse: () => throw StateError('item "$text" ausente; havia: '
              '${menuItems().map((i) => i.textContent).toList()}'));

  DomElement ribbonButton(String title) => host
      .querySelectorAll('.dq-office-btn')
      .firstWhere((button) => button.getAttribute('title') == title,
          orElse: () => throw StateError('botão "$title" ausente na ribbon'));

  group('entrelinha', () {
    test('1,5 deixa a MESMA linha mais alta, e 1,0 a devolve ao natural', () {
      final instance = mount();
      caretIn(instance, 0);
      final natural = blockAt(instance, 0).lines.first.heightTwips;

      actions.setLineSpacing(instance, 360);
      final oneAndAHalf = blockAt(instance, 0).lines.first.heightTwips;

      actions.setLineSpacing(instance, 240);
      final single = blockAt(instance, 0).lines.first.heightTwips;

      expect(oneAndAHalf, greaterThan(natural),
          reason: '1,5 linha é 360/240 da caixa vertical da fonte');
      expect(oneAndAHalf, (natural * 1.5).round());
      expect(single, natural,
          reason: '240 com regra auto é exatamente uma linha');
    });

    test('o segundo parágrafo NÃO é afetado', () {
      final instance = mount();
      caretIn(instance, 0);
      final before = blockAt(instance, 1).lines.first.heightTwips;
      actions.setLineSpacing(instance, 720);
      expect(blockAt(instance, 1).lines.first.heightTwips, before);
    });

    test('a regra viaja junto: um bloco com lineRule exact volta a auto', () {
      final instance = mount([
        schema.node(
            'paragraph',
            {
              'style': {'lineTwips': 200, 'lineRule': 'exact'}
            },
            Fragment.from([schema.text('linha travada em 10 pt')])),
      ]);
      caretIn(instance, 0);
      expect(blockAt(instance, 0).lines.first.heightTwips, 200);

      actions.setLineSpacing(instance, 480);
      final style = instance.state.doc.child(0).attrs['style'] as Map;
      expect(style['lineRule'], 'auto');
      expect(
        blockAt(instance, 0).lines.first.heightTwips,
        greaterThan(400),
        reason: 'sem trocar a regra, 480 sairia como 24 pt fixos',
      );
    });

    test('o menu da ribbon marca a entrelinha vigente e aplica a escolhida',
        () {
      final instance = mount();
      caretIn(instance, 0);
      click(ribbonButton('Espaçamento entre Linhas e Parágrafos'));

      final oneZero = menuItem('1,0');
      expect(oneZero.classes.contains('dq-office-menu-item-checked'), isTrue,
          reason: 'um bloco sem w:line desenha uma linha simples');

      click(menuItem('1,15'));
      expect((instance.state.doc.child(0).attrs['style'] as Map)['lineTwips'],
          276);
    });

    test('a escada da ribbon e a do diálogo Parágrafo… são a MESMA', () {
      expect(
        officeLineSpacings.values.map((spacing) => spacing.twips).toList(),
        actions.officeLineSpacingSteps.map((step) => step.twips).toList(),
      );
    });
  });

  group('espaço antes/depois do parágrafo', () {
    test('adicionar espaço antes empurra o bloco seguinte para baixo', () {
      final instance = mount();
      caretIn(instance, 1);
      final before = blockAt(instance, 1).yTwips;

      actions.setParagraphSpace(instance, before: true, twips: 240);
      final after = blockAt(instance, 1);

      expect(after.spaceBeforeTwips, 240);
      expect(after.yTwips, before,
          reason: 'o topo do fragmento não muda — o espaço vive DENTRO dele');
      expect(after.heightTwips, greaterThan(240));
    });

    test('o item do menu alterna entre Adicionar e Remover', () {
      final instance = mount();
      caretIn(instance, 0);
      click(ribbonButton('Espaçamento entre Linhas e Parágrafos'));
      click(menuItem('Adicionar Espaço Depois do Parágrafo'));
      expect(actions.currentParagraphSpace(instance, before: false), 240);

      click(ribbonButton('Espaçamento entre Linhas e Parágrafos'));
      click(menuItem('Remover Espaço Depois do Parágrafo'));
      expect(actions.currentParagraphSpace(instance, before: false), 0);
    });
  });

  group('sombreamento de parágrafo', () {
    test('a cor chega ao fragmento composto e à projeção DOM', () {
      final instance = mount();
      caretIn(instance, 0);
      expect(blockAt(instance, 0).backgroundColor, isNull);

      actions.setParagraphShading(instance, '#d9d9d9');

      expect(blockAt(instance, 0).backgroundColor, '#D9D9D9');
      final decoration = host.querySelector('.dq-office-block-decoration');
      expect(decoration, isNotNull);
      expect(decoration!.getAttribute('style'),
          contains('background-color:#D9D9D9'));
      expect(decoration.getAttribute('data-model-length'), '0',
          reason: 'a camada de pintura não pode ocupar posição do modelo');
    });

    test('remover a cor apaga a camada', () {
      final instance = mount();
      caretIn(instance, 0);
      actions.setParagraphShading(instance, '#ffff00');
      expect(host.querySelector('.dq-office-block-decoration'), isNotNull);

      actions.setParagraphShading(instance, null);
      expect(blockAt(instance, 0).backgroundColor, isNull);
      expect(host.querySelector('.dq-office-block-decoration'), isNull);
    });

    test('o sombreamento sobrevive ao round-trip DOCX', () {
      final instance = mount();
      caretIn(instance, 0);
      actions.setParagraphShading(instance, '#c00000');

      final codec = OfficeDocxCodec(schema: schema);
      final bytes = codec.exportDocument(instance.state.doc);
      final reopened =
          PMNode.fromJSON(schema, codec.import(bytes).snapshot.body);
      final word = reopened.child(0).attrs['word'] as Map;
      expect((word['shading'] as Map)['fill'], 'C00000');

      // E o documento reaberto continua sendo desenhado com a cor.
      expect(
          (LayoutComposer().compose(reopened).pages.first.fragments.first
                  as BlockFragment)
              .backgroundColor,
          '#C00000');
    });
  });

  group('bordas de parágrafo', () {
    test('Caixa desenha as quatro arestas na tela', () {
      final instance = mount();
      caretIn(instance, 0);
      expect(blockAt(instance, 0).borders, isNull);

      actions.setParagraphBorders(instance, actions.OfficeParagraphBorders.box);

      final borders = blockAt(instance, 0).borders!;
      expect(borders.top!.isVisible, isTrue);
      expect(borders.bottom!.isVisible, isTrue);
      expect(borders.left!.isVisible, isTrue);
      expect(borders.right!.isVisible, isTrue);

      final style =
          host.querySelector('.dq-office-block-decoration')!.getAttribute(
                'style',
              )!;
      expect(style, contains('border-top:'));
      expect(style, isNot(contains('border-top:none')));
    });

    test('Borda Inferior só toca a aresta pedida', () {
      final instance = mount();
      caretIn(instance, 0);
      actions.setParagraphBorders(
          instance, actions.OfficeParagraphBorders.bottom);
      final borders = blockAt(instance, 0).borders!;
      expect(borders.bottom!.isVisible, isTrue);
      expect(borders.top, isNull, reason: 'o que não foi pedido não é gravado');
    });

    test('Sem Borda apaga a moldura em vez de deixar a chave herdada', () {
      final instance = mount();
      caretIn(instance, 0);
      actions.setParagraphBorders(instance, actions.OfficeParagraphBorders.box);
      actions.setParagraphBorders(
          instance, actions.OfficeParagraphBorders.none);

      expect(blockAt(instance, 0).borders, isNull,
          reason: 'quatro arestas nil não desenham nada');
      final word = instance.state.doc.child(0).attrs['word'] as Map;
      expect((word['borders'] as Map)['top'], containsPair('val', 'nil'),
          reason: 'nil EXPLÍCITO é o que apaga a aresta no Word; omitir a '
              'chave deixaria a borda herdada de pé');
    });

    test('num parágrafo partido entre páginas, a aresta fica nas pontas', () {
      // UM parágrafo mais alto que a página: é a única forma de haver dois
      // fragmentos do MESMO bloco, que é o caso que a regra descreve.
      final instance =
          mount([paragraph(List.filled(1200, 'palavra').join(' '))]);
      caretIn(instance, 0);
      actions.setParagraphBorders(instance, actions.OfficeParagraphBorders.box);

      final fragments = [
        for (final page in instance.pageGraph.pages)
          ...page.fragments.whereType<BlockFragment>(),
      ];
      expect(fragments.length, greaterThan(1),
          reason: 'o teste só vale se o parágrafo realmente se partiu');
      expect(fragments.first.continuesOnNextPage, isTrue);
      expect(fragments.last.continuesFromPreviousPage, isTrue);

      final decorations = host.querySelectorAll('.dq-office-block-decoration');
      expect(decorations, isNotEmpty);
      expect(decorations.first.getAttribute('style'),
          contains('border-bottom:none'),
          reason: 'a aresta inferior da primeira fatia seria um traço no meio '
              'do parágrafo');
    });

    test('o PDF sai com o mesmo retângulo e as mesmas arestas', () {
      final instance = mount();
      caretIn(instance, 0);
      actions.setParagraphShading(instance, '#ffff00');
      actions.setParagraphBorders(instance, actions.OfficeParagraphBorders.box);

      final streams = PdfReader(instance.exportPdf()).decodedStreams.join('\n');
      // `re f` é o retângulo preenchido do sombreamento e `l S` são as
      // arestas — o PDF é projeção do MESMO grafo, então o que a tela mostra
      // tem de aparecer aqui sem uma segunda composição.
      expect(streams, contains('1 1 0 rg'),
          reason: '#ffff00 em espaço RGB do PDF');
      expect(streams, contains('re f'));
      expect(RegExp(r'\bl\s+S').allMatches(streams).length,
          greaterThanOrEqualTo(4),
          reason: 'as quatro arestas da caixa');
    });

    test('as bordas sobrevivem ao round-trip DOCX', () {
      final instance = mount();
      caretIn(instance, 0);
      actions.setParagraphBorders(
          instance, actions.OfficeParagraphBorders.topAndBottom);

      final codec = OfficeDocxCodec(schema: schema);
      final bytes = codec.exportDocument(instance.state.doc);
      final reopened =
          PMNode.fromJSON(schema, codec.import(bytes).snapshot.body);
      final borders =
          (reopened.child(0).attrs['word'] as Map)['borders'] as Map;
      expect((borders['top'] as Map)['val'], 'single');
      expect((borders['bottom'] as Map)['val'], 'single');

      final fragment = LayoutComposer()
          .compose(reopened)
          .pages
          .first
          .fragments
          .first as BlockFragment;
      expect(fragment.borders!.top!.isVisible, isTrue);
      expect(fragment.borders!.left?.isVisible ?? false, isFalse);
    });
  });

  group('galeria de marcadores', () {
    test('escolher ▪ muda o marcador COMPOSTO, não só o atributo', () {
      final instance = mount();
      caretIn(instance, 0);
      actions.applyListFormat(instance,
          kind: 'bullet', lvlText: '▪', numFmt: 'bullet');

      expect(instance.state.doc.child(0).type.name, 'listItem');
      expect(blockAt(instance, 0).marker, '▪ ');
    });

    test('a galeria abre pela setinha e marca o item vigente', () {
      final instance = mount();
      caretIn(instance, 0);
      click(ribbonButton('Biblioteca de Marcadores'));
      click(menuItem('○'));
      expect(blockAt(instance, 0).marker, '○ ');

      click(ribbonButton('Biblioteca de Marcadores'));
      final checked = menuItems()
          .where((item) => item.classes.contains('dq-office-menu-item-checked'))
          .map((item) => item.textContent ?? '')
          .toList();
      expect(checked.any((text) => text.contains('○')), isTrue);
    });

    test('"Nenhum" devolve o parágrafo e limpa o formato', () {
      final instance = mount();
      caretIn(instance, 0);
      actions.applyListFormat(instance,
          kind: 'bullet', lvlText: '➢', numFmt: 'bullet');
      actions.removeList(instance);

      final block = instance.state.doc.child(0);
      expect(block.type.name, 'paragraph');
      expect(blockAt(instance, 0).marker, isNull);
      final style = block.attrs['style'];
      expect(style == null || (style as Map)['lvlText'] == null, isTrue);
    });

    test('o marcador escolhido sobrevive ao round-trip DOCX', () {
      final instance = mount();
      caretIn(instance, 0);
      actions.applyListFormat(instance,
          kind: 'bullet', lvlText: '▪', numFmt: 'bullet');

      final codec = OfficeDocxCodec(schema: schema);
      final bytes = codec.exportDocument(instance.state.doc);
      final reopened =
          PMNode.fromJSON(schema, codec.import(bytes).snapshot.body);
      // Reaberto, o rótulo vem RESOLVIDO do numbering.xml gerado — é a prova
      // de que a definição exportada carrega o caractere certo.
      expect((reopened.child(0).attrs['style'] as Map)['marker'], '▪ ');
    });
  });

  group('galeria de numeração', () {
    test('I. produz numeração romana crescente na composição', () {
      final instance = mount([
        paragraph('Primeiro item'),
        paragraph('Segundo item'),
        paragraph('Terceiro item'),
      ]);
      instance.view.dispatch(instance.state.tr
        ..setSelection(TextSelection.create(
            instance.state.doc, 1, instance.state.doc.content.size - 1)));
      actions.applyListFormat(instance,
          kind: 'ordered', lvlText: '%1.', numFmt: 'upperRoman');

      expect([
        blockAt(instance, 0).marker,
        blockAt(instance, 1).marker,
        blockAt(instance, 2).marker,
      ], [
        'I. ',
        'II. ',
        'III. '
      ]);
    });

    test('1) usa o parêntese do formato escolhido', () {
      final instance = mount();
      caretIn(instance, 0);
      actions.applyListFormat(instance,
          kind: 'ordered', lvlText: '%1)', numFmt: 'decimal');
      expect(blockAt(instance, 0).marker, '1) ');
    });

    test('o formato vira w:numFmt/w:lvlText no DOCX e volta igual', () {
      final instance = mount();
      caretIn(instance, 0);
      actions.applyListFormat(instance,
          kind: 'ordered', lvlText: '%1.', numFmt: 'upperRoman');

      final codec = OfficeDocxCodec(schema: schema);
      final bytes = codec.exportDocument(instance.state.doc);
      final reopened =
          PMNode.fromJSON(schema, codec.import(bytes).snapshot.body);
      expect((reopened.child(0).attrs['style'] as Map)['marker'], 'I. ',
          reason: 'o contador do numbering.xml gerado tem de dizer romano');
    });

    test('trocar de formato não reaproveita a definição antiga', () {
      final instance = mount([
        paragraph('alfa'),
        paragraph('beta'),
      ]);
      caretIn(instance, 0);
      actions.applyListFormat(instance,
          kind: 'ordered', lvlText: '%1.', numFmt: 'decimal');
      caretIn(instance, 1);
      actions.applyListFormat(instance,
          kind: 'ordered', lvlText: '%1.', numFmt: 'upperLetter');

      final codec = OfficeDocxCodec(schema: schema);
      final bytes = codec.exportDocument(instance.state.doc);
      final reopened =
          PMNode.fromJSON(schema, codec.import(bytes).snapshot.body);
      expect((reopened.child(0).attrs['style'] as Map)['marker'], '1. ');
      expect((reopened.child(1).attrs['style'] as Map)['marker'], 'A. ',
          reason: 'duas escolhas de galeria precisam de DUAS definições');
    });
  });

  group('lista de vários níveis', () {
    test('o marcador acompanha o NÍVEL sem reescrever o parágrafo', () {
      final instance = mount();
      caretIn(instance, 0);
      actions.applyListFormat(
        instance,
        kind: 'bullet',
        lvlText: const ['•', '○', '▪'],
        numFmt: const ['bullet', 'bullet', 'bullet'],
      );
      expect(blockAt(instance, 0).marker, '• ');
      final level0Indent = blockAt(instance, 0).indentTwips;

      expect(actions.changeListLevel(instance, 1), isTrue);
      expect(blockAt(instance, 0).marker, '○ ');
      expect(blockAt(instance, 0).indentTwips, greaterThan(level0Indent));

      expect(actions.changeListLevel(instance, 1), isTrue);
      expect(blockAt(instance, 0).marker, '▪ ');
    });

    test('o nível não passa de zero para baixo', () {
      final instance = mount();
      caretIn(instance, 0);
      actions.applyListFormat(instance,
          kind: 'bullet', lvlText: '•', numFmt: 'bullet');
      expect(actions.changeListLevel(instance, -1), isFalse);
    });

    test('o esquema multinível vira um w:lvl por nível no DOCX', () {
      final instance = mount([
        paragraph('nível zero'),
        paragraph('nível um'),
      ]);
      instance.view.dispatch(instance.state.tr
        ..setSelection(TextSelection.create(
            instance.state.doc, 1, instance.state.doc.content.size - 1)));
      actions.applyListFormat(
        instance,
        kind: 'bullet',
        lvlText: const ['•', '○', '▪'],
        numFmt: const ['bullet', 'bullet', 'bullet'],
      );
      caretIn(instance, 1);
      actions.changeListLevel(instance, 1);

      final codec = OfficeDocxCodec(schema: schema);
      final bytes = codec.exportDocument(instance.state.doc);
      final reopened =
          PMNode.fromJSON(schema, codec.import(bytes).snapshot.body);
      expect((reopened.child(0).attrs['style'] as Map)['marker'], '• ');
      expect((reopened.child(1).attrs['style'] as Map)['marker'], '○ ',
          reason: 'o nível 1 do MESMO numId tem de trazer o segundo marcador');
      expect(reopened.child(1).attrs['indent'], 1);
    });

    test('os esquemas numerados ficam visíveis e DESABILITADOS', () {
      final instance = mount();
      caretIn(instance, 0);
      click(ribbonButton('Lista de Vários Níveis'));
      final numbered = menuItem('1.1.1.');
      expect(numbered.classes.contains('dq-office-menu-item-disabled'), isTrue);
      expect(numbered.textContent, contains('contador por NÍVEL'),
          reason: 'o motivo real fica na descrição, como manda o plano');
    });
  });

  group('bordas do menu', () {
    test('"Todas as Bordas" fica desabilitada com o motivo do w:between', () {
      final instance = mount();
      caretIn(instance, 0);
      click(ribbonButton('Bordas'));
      final all = menuItem('Todas as Bordas');
      expect(all.classes.contains('dq-office-menu-item-disabled'), isTrue);
      expect(all.textContent, contains('w:between'));
    });
  });
}
