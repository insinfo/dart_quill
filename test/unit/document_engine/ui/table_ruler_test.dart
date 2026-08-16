/// A régua CONTEXTUAL de tabela e os controles novos da aba "Tabela Layout".
///
/// O que se afirma sobre a régua é sempre o MODELO (ou o `PageGraph` que ele
/// produz) e os atributos que o marcador publica — o fake DOM devolve o mesmo
/// retângulo para todo elemento, então medir pixel projetado não provaria
/// nada. A regra protegida é a mesma de todo arrasto do chrome: enquanto o
/// ponteiro se move NADA é aplicado; a transação sai uma vez, no `pointerup`.
@TestOn('vm')
library;

import 'package:test/test.dart';

import 'package:dart_quill/dart_quill_office.dart';
import 'package:dart_quill/src/platform/dom.dart';

import '../../../support/fake_dom.dart';
import '../../../support/test_helpers.dart';

/// px por twip com zoom 100% — a MESMA conversão do controller.
const double _pxPerTwip = 96 / 72 / 20;

double _pxFor(int twips) => twips * _pxPerTwip;

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

  PMNode paragraph(String text) => schema.node('paragraph', null,
      text.isEmpty ? Fragment.empty : Fragment.from([schema.text(text)]));

  PMNode cell(String text) =>
      schema.node('tableCell', null, Fragment.from([paragraph(text)]));

  PMNode tableDoc({List<int>? colWidths, int rows = 3}) => schema.node(
        'doc',
        null,
        Fragment.from([
          paragraph('antes da tabela'),
          schema.node(
              'table',
              {if (colWidths != null) 'colWidths': colWidths},
              Fragment.from([
                for (var r = 0; r < rows; r++)
                  schema.node(
                      'tableRow',
                      null,
                      Fragment.from([
                        for (var c = 0; c < 3; c++) cell('r${r}c$c'),
                      ])),
              ])),
          paragraph('depois da tabela'),
        ]),
      );

  OfficeWordEditor mount(PMNode document) => editor = OfficeWordEditor.mount(
        host: host,
        adapter: adapter,
        document: document,
        schema: schema,
        options: const OfficeWordEditorOptions(mode: OfficeWordMode.word),
      );

  int tablePositionOf(PMNode doc) {
    var offset = 0;
    for (var i = 0; i < doc.childCount; i++) {
      if (doc.child(i).type.name == 'table') return offset;
      offset += doc.child(i).nodeSize;
    }
    throw StateError('sem tabela');
  }

  /// Coloca o caret na célula (linha, coluna) pelo MODELO — o fake DOM não
  /// tem geometria para um clique de verdade.
  void caretIn(OfficeWordEditor target, int gridRow, int gridColumn) {
    final state = target.state;
    final map = OfficeTableMap.of(state.doc, tablePositionOf(state.doc));
    final cellNode = map.cellCovering(gridRow, gridColumn)!;
    target.dispatch(state.tr
      ..setSelection(TextSelection.create(state.doc, cellNode.pos + 2)));
  }

  List<DomElement> marks() =>
      host.querySelectorAll('.dq-office-colmark').toList();

  List<int> markEdges() => [
        for (final mark in marks())
          int.parse(mark.getAttribute('data-edge-twips')!),
      ];

  DomElement one(String selector) {
    final found = host.querySelector(selector);
    expect(found, isNotNull, reason: 'elemento ausente: $selector');
    return found!;
  }

  void down(DomElement target, {num x = 0, num y = 0}) =>
      (target as FakeDomElement).dispatchEvent(
          'pointerdown',
          FakeDomMouseEvent(
              type: 'pointerdown', target: target, clientX: x, clientY: y));

  void move({num x = 0, num y = 0}) {
    final ruler = one('.dq-office-ruler-wrap') as FakeDomElement;
    ruler.dispatchEvent(
        'pointermove',
        FakeDomMouseEvent(
            type: 'pointermove', target: ruler, clientX: x, clientY: y));
  }

  void up({num x = 0, num y = 0}) {
    final ruler = one('.dq-office-ruler-wrap') as FakeDomElement;
    ruler.dispatchEvent(
        'pointerup',
        FakeDomMouseEvent(
            type: 'pointerup', target: ruler, clientX: x, clientY: y));
  }

  /// As larguras COMPOSTAS das colunas da tabela.
  List<int> composedWidths(OfficeWordEditor target) {
    final widths = <int>[];
    for (final page in target.pageGraph.pages) {
      for (final fragment in page.fragments) {
        if (fragment is! TableFragment) continue;
        for (final cellBox in fragment.rows.first.cells) {
          widths.add(cellBox.widthTwips);
        }
        return widths;
      }
    }
    return widths;
  }

  group('marcadores de coluna na régua', () {
    test('fora de tabela a régua não mostra divisa nenhuma', () {
      mount(tableDoc(colWidths: [1500, 2500, 2000]));
      expect(marks(), isEmpty,
          reason: 'o caret nasce no parágrafo antes da tabela');
    });

    test('com o caret na tabela aparece uma divisa por coluna', () {
      final target = mount(tableDoc(colWidths: [1500, 2500, 2000]));
      caretIn(target, 0, 0);

      expect(marks().length, 3);
      // As divisas ACUMULAM as larguras compostas, contadas do content box.
      expect(markEdges(), [1500, 4000, 6000]);
      expect(marks().first.getAttribute('data-column'), '0');
    });

    test('sair da tabela apaga as divisas', () {
      final target = mount(tableDoc(colWidths: [1500, 2500, 2000]));
      caretIn(target, 0, 0);
      expect(marks(), isNotEmpty);

      target.dispatch(target.state.tr
        ..setSelection(TextSelection.create(target.state.doc, 1)));
      expect(marks(), isEmpty);
    });

    test('arrastar a divisa aplica UMA vez, no pointerup', () {
      final target = mount(tableDoc(colWidths: [1500, 2500, 2000]));
      caretIn(target, 0, 0);
      final before = composedWidths(target);
      expect(before, [1500, 2500, 2000]);

      down(marks().first, x: 100);
      move(x: 100 + _pxFor(1000));
      expect(composedWidths(target), before,
          reason: 'durante o arrasto só o marcador e a guia se movem');
      // O marcador arrastado JÁ mostra a posição nova — é o feedback do gesto.
      expect(markEdges().first, 2500);

      up(x: 100 + _pxFor(1000));
      expect(composedWidths(target), [2500, 2500, 2000]);
      expect(
          (target.state.doc
                  .nodeAt(tablePositionOf(target.state.doc))!
                  .attrs['colWidths'] as List)
              .first,
          2500,
          reason: 'a grade declarada (w:tblGrid) acompanha a coluna');
    });

    test('a coluna nunca encolhe abaixo de meio centímetro', () {
      final target = mount(tableDoc(colWidths: [1500, 2500, 2000]));
      caretIn(target, 0, 0);

      down(marks().first, x: 0);
      up(x: -_pxFor(9000));
      expect(composedWidths(target).first, 283);
    });

    test('numa tabela SEM grade declarada a largura vai para a coluna certa',
        () {
      // Sem `w:tblGrid`, as colunas que ninguém declarou saíam como zero, e o
      // compositor descarta entradas não positivas — a largura gravada
      // acabava na coluna errada. A grade é completada pela PROJEÇÃO.
      final target = mount(tableDoc());
      caretIn(target, 0, 1);
      final before = composedWidths(target);
      // A área útil dividida em três (a última fica com a sobra do
      // arredondamento).
      expect(before.first, closeTo(target.pageSetup.contentWidthTwips / 3, 2));

      down(marks()[1], x: 0);
      up(x: _pxFor(1000));

      // A grade DECLARADA é o que prova a coluna certa: com a tabela agora
      // mais larga que a área útil, o compositor escala as três na projeção
      // e a comparação de larguras compostas não distinguiria os casos.
      final grid = target.state.doc
          .nodeAt(tablePositionOf(target.state.doc))!
          .attrs['colWidths'] as List;
      expect(grid[0], before[0], reason: 'a coluna 0 não foi tocada');
      expect(grid[1], before[1] + 1000);
      expect(grid[2], before[2]);
    });

    test('a divisa some quando a seleção sai para outro bloco', () {
      final target = mount(tableDoc(colWidths: [1500, 2500, 2000]));
      caretIn(target, 1, 2);
      expect(marks().length, 3);
      expect(marks().last.getAttribute('data-column'), '2');
    });
  });

  group('aba Tabela Layout', () {
    /// Abre a aba contextual "Tabela Layout".
    ///
    /// Pelo RÓTULO, não pelo índice: uma aba nova em qualquer posição
    /// anterior (a Design entrou entre Inserir e Layout) fazia este teste
    /// falhar em outra aba, apontando para um defeito que não existe.
    void openTableLayoutTab() {
      final tab = host
          .querySelectorAll('.dq-office-ribbon-tab')
          .firstWhere((element) => element.textContent == 'Tabela Layout')
          as FakeDomElement;
      tab.dispatchEvent('click', FakeDomMouseEvent(type: 'click', target: tab));
    }

    DomElement buttonTitled(String title) {
      for (final button in host.querySelectorAll('.dq-office-btn')) {
        if (button.getAttribute('title') == title) return button;
      }
      throw StateError('botão ausente: $title');
    }

    void click(DomElement target) => (target as FakeDomElement).dispatchEvent(
        'click', FakeDomMouseEvent(type: 'click', target: target));

    test('"Repetir Linhas de Cabeçalho" liga, acende e desliga', () {
      final target = mount(tableDoc(colWidths: [1500, 2500, 2000], rows: 4));
      caretIn(target, 0, 0);
      openTableLayoutTab();

      final button = buttonTitled(
          'Repetir a(s) linha(s) de cabeçalho no topo de cada página');
      expect(button.classes.contains('dq-office-btn-active'), isFalse);

      click(button);
      final row =
          target.state.doc.nodeAt(tablePositionOf(target.state.doc) + 1)!;
      expect((row.attrs['word'] as Map)['tblHeader'], isTrue);
      expect(button.classes.contains('dq-office-btn-active'), isTrue,
          reason: 'o realce reflete o modelo, sem listener próprio da aba');

      click(button);
      expect(
          (target.state.doc
              .nodeAt(tablePositionOf(target.state.doc) + 1)!
              .attrs['word'] as Map)['tblHeader'],
          isNull);
      expect(button.classes.contains('dq-office-btn-active'), isFalse);
    });

    test('o menu Direção do Texto existe e está inteiro desabilitado', () {
      final target = mount(tableDoc(colWidths: [1500, 2500, 2000]));
      caretIn(target, 0, 0);
      openTableLayoutTab();

      click(buttonTitled('Direção do Texto'));
      final items = host.querySelectorAll('.dq-office-menu-item').toList();
      expect(items, hasLength(3));
      expect(
          items.every(
              (item) => item.classes.contains('dq-office-menu-item-disabled')),
          isTrue,
          reason: 'w:textDirection não é lido em layout/ — o item explica o '
              'motivo em vez de gravar um atributo invisível');
    });

    test('AutoAjuste à Janela estica a tabela até a margem', () {
      final target = mount(tableDoc(colWidths: [1500, 2500, 2000]));
      caretIn(target, 0, 0);
      openTableLayoutTab();

      click(buttonTitled('AutoAjuste'));
      final items = host.querySelectorAll('.dq-office-menu-item').toList();
      expect(items, hasLength(3));
      expect(
          items.last.classes.contains('dq-office-menu-item-disabled'), isTrue,
          reason: '"ao conteúdo" depende de medir o texto no compositor');
      click(items.first);

      expect(composedWidths(target).fold<int>(0, (sum, w) => sum + w),
          target.pageSetup.contentWidthTwips);
    });

    test('Propriedades abre o diálogo com as quatro abas do Word', () {
      final target = mount(tableDoc(colWidths: [1500, 2500, 2000]));
      caretIn(target, 0, 0);
      openTableLayoutTab();

      click(buttonTitled('Propriedades da Tabela'));
      final tabs = host.querySelectorAll('.dq-office-dialog-tab').toList();
      expect([for (final tab in tabs) tab.textContent],
          ['Tabela', 'Linha', 'Coluna', 'Célula']);
      // A largura mostrada é a PROJETADA da coluna do cursor.
      final width = host.querySelector('[data-field="columnWidth"]')!;
      expect(width.value, '2.65');
    });

    test('o diálogo não aplica nada até o OK, e aí aplica tudo junto', () {
      final target = mount(tableDoc(colWidths: [1500, 2500, 2000]));
      caretIn(target, 1, 0);
      openTableLayoutTab();
      click(buttonTitled('Propriedades da Tabela'));

      host.querySelector('[data-field="columnWidth"]')!.value = '5';
      host.querySelector('[data-field="cellMarginLeft"]')!.value = '1';
      expect(composedWidths(target).first, 1500,
          reason: 'o formulário aberto não muda o documento');

      click(one('.dq-office-dialog-primary'));
      expect(composedWidths(target).first, 2835);
      final cellNode =
          OfficeTableMap.of(target.state.doc, tablePositionOf(target.state.doc))
              .cellCovering(1, 0)!
              .node;
      expect(((cellNode.attrs['word'] as Map)['margins'] as Map)['left'],
          {'value': 567, 'type': 'dxa'});
    });
  });
}
