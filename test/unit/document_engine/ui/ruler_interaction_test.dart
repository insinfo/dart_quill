/// Interação da régua horizontal (F7) e os dropdowns de Quebras/Colunas.
///
/// Três gestos novos entram aqui, e o que se afirma sobre eles é sempre o
/// MODELO (ou o `PageGraph` que ele produz), nunca pixels: o fake DOM
/// devolve o MESMO retângulo para todo elemento, então medir posição
/// projetada não provaria nada.
///
/// A regra que estes testes protegem, além do resultado: durante o arrasto
/// NADA é aplicado. A transação (ou a repaginação, no caso da margem) sai
/// uma única vez, no `pointerup` — é a mesma regra do adorno de objeto e do
/// resize de coluna de tabela, e é o que impede o DOM de ser remontado
/// debaixo do ponteiro.
@TestOn('vm')
library;

import 'package:test/test.dart';

import 'package:dart_quill/dart_quill_office.dart';
import 'package:dart_quill/src/platform/dom.dart';

import '../../../support/fake_dom.dart';
import '../../../support/test_helpers.dart';

/// px por twip com zoom 100% — a MESMA conversão do controller.
const double _pxPerTwip = 96 / 72 / 20;

/// Quantos px arrastar para mover [twips].
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

  PMNode paragraph(String text) =>
      schema.node('paragraph', null, Fragment.from([schema.text(text)]));

  PMNode docOf(int blocks) => schema.node(
      'doc',
      null,
      Fragment.from([
        for (var i = 0; i < blocks; i++)
          paragraph('Parágrafo $i com texto suficiente para ocupar espaço '
              'real na página e paginar de verdade.')
      ]));

  OfficeWordEditor mount({PMNode? document, int blocks = 8}) =>
      editor = OfficeWordEditor.mount(
        host: host,
        adapter: adapter,
        document: document ?? docOf(blocks),
        schema: schema,
        options: const OfficeWordEditorOptions(mode: OfficeWordMode.word),
      );

  void caretAt(int position) {
    const map = OfficeDomPositionMap();
    final pages = host.querySelector('.dq-office-pages')!;
    final p = map.domPositionFor(pages, position)!;
    adapter.setSelectionByNodes(p.node, p.offset, p.node, p.offset);
  }

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

  void click(DomElement target) => (target as FakeDomElement)
      .dispatchEvent('click', FakeDomMouseEvent(type: 'click', target: target));

  group('régua: arrastar margens', () {
    test('as duas alças de margem existem na faixa horizontal', () {
      mount();
      expect(host.querySelectorAll('.dq-office-margin-left').length, 1);
      expect(host.querySelectorAll('.dq-office-margin-right').length, 1);
      // A faixa é irmã do canvas — é ela que recebe o pointermove do gesto
      // que nunca sai da régua.
      final canvas = host.querySelector('.dq-office-canvas')!;
      expect(canvas.querySelectorAll('.dq-office-margin').length, 0);
    });

    test('arrastar a margem esquerda repagina UMA vez, no pointerup', () {
      final editor = mount(blocks: 40);
      final before = editor.pageSetup.marginLeftTwips;
      expect(before, 1134);

      down(one('.dq-office-margin-left'), x: 100);
      move(x: 100 + _pxFor(1140));
      expect(editor.pageSetup.marginLeftTwips, before,
          reason: 'durante o arrasto só a guia se move');

      up(x: 100 + _pxFor(1140));
      expect(editor.pageSetup.marginLeftTwips, closeTo(1134 + 1140, 20));
      // E o LAYOUT honra: a página recomposta nasce com a margem nova.
      expect(editor.pageGraph.pages.first.setup.marginLeftTwips,
          editor.pageSetup.marginLeftTwips);
      expect(editor.state.doc.childCount, 40,
          reason: 'a geometria muda; o conteúdo não');
    });

    test('arrastar a margem direita encolhe a área útil', () {
      final editor = mount();
      final content = editor.pageSetup.contentWidthTwips;
      down(one('.dq-office-margin-right'), x: 500);
      up(x: 500 - _pxFor(1136)); // para a esquerda = margem maior
      expect(editor.pageSetup.marginRightTwips, closeTo(1134 + 1136, 20));
      expect(editor.pageSetup.contentWidthTwips, lessThan(content));
      expect(editor.pageGraph.pages.first.setup.contentWidthTwips,
          editor.pageSetup.contentWidthTwips);
    });

    test('a margem nunca engole a área útil', () {
      final editor = mount();
      down(one('.dq-office-margin-left'), x: 0);
      up(x: _pxFor(100000));
      expect(editor.pageSetup.contentWidthTwips, greaterThanOrEqualTo(567),
          reason: 'o clamp preserva 1 cm de área útil');
    });
  });

  group('régua: paradas de tabulação', () {
    test('o canto GIRA entre os quatro tipos que o compositor honra', () {
      mount();
      final corner = one('.dq-office-ruler-corner');
      expect(corner.getAttribute('data-tab-kind'), 'left');
      for (final expected in const ['center', 'right', 'decimal', 'left']) {
        click(corner);
        expect(corner.getAttribute('data-tab-kind'), expected);
      }
    });

    test('clicar na banda cria a parada no estilo do parágrafo', () {
      final editor = mount();
      caretAt(1);
      editor.view.syncSelectionFromDom();

      down(one('.dq-office-ruler-band'), x: 200);

      final style = editor.state.doc.child(0).attrs['style'] as Map;
      final tabs = style['tabs'] as List;
      expect(tabs.length, 1);
      expect(tabs.first['val'], 'left');
      // 200 px / 0,0666… = 3000 twips da borda; menos a margem de 1134 dá
      // 1866, encaixado na malha de 0,25 cm (142 twips) = 1846.
      expect(tabs.first['posTwips'], 1846);
      expect(host.querySelectorAll('.dq-office-tabstop').length, 1);
    });

    test('o tipo armado no canto é o tipo gravado', () {
      final editor = mount();
      caretAt(1);
      editor.view.syncSelectionFromDom();
      click(one('.dq-office-ruler-corner')); // center
      click(one('.dq-office-ruler-corner')); // right

      down(one('.dq-office-ruler-band'), x: 200);

      final tabs =
          (editor.state.doc.child(0).attrs['style'] as Map)['tabs'] as List;
      expect(tabs.first['val'], 'right');
      expect(one('.dq-office-tabstop').getAttribute('data-tab-kind'), 'right');
    });

    test('o COMPOSITOR honra a parada criada pela régua', () {
      final editor = mount(
          document:
              schema.node('doc', null, Fragment.from([paragraph('a\tb')])));
      caretAt(1);
      editor.view.syncSelectionFromDom();

      int tabEndTwips() {
        final block = editor.pageGraph.pages.first.fragments
            .whereType<BlockFragment>()
            .first;
        var x = 0;
        for (final segment in block.lines.first.segments) {
          x += segment.widthTwips;
          if (segment.isTab) return x;
        }
        throw StateError('a linha não tem tabulação');
      }

      // Sem parada personalizada o TAB para na malha padrão de 708 twips.
      expect(tabEndTwips(), 708);

      down(one('.dq-office-ruler-band'), x: 200);

      expect(tabEndTwips(), 1846,
          reason: 'o avanço do TAB tem de terminar na parada criada');
    });

    test('arrastar move a parada; soltar fora da faixa a remove', () {
      final editor = mount();
      caretAt(1);
      editor.view.syncSelectionFromDom();
      down(one('.dq-office-ruler-band'), x: 200);

      List tabsOf() =>
          (editor.state.doc.child(0).attrs['style'] as Map)['tabs'] as List;

      // Arrastar 1140 twips à direita: 1846 + 1140 = 2986 → malha → 2982.
      down(one('.dq-office-tabstop'), x: 200, y: 10);
      move(x: 200 + _pxFor(1140), y: 11);
      expect(tabsOf().first['posTwips'], 1846,
          reason: 'durante o arrasto só o marcador se move');
      up(x: 200 + _pxFor(1140), y: 11);
      expect(tabsOf().first['posTwips'], 2982);

      // Arrastar para FORA da faixa remove, como no Word.
      down(one('.dq-office-tabstop'), x: 200, y: 10);
      up(x: 200, y: 60);
      expect(tabsOf(), isEmpty);
      expect(host.querySelectorAll('.dq-office-tabstop').length, 0);
    });
  });

  group('aba Layout: Quebras e Colunas', () {
    DomElement tabByText(String text) {
      for (final tab in host.querySelectorAll('.dq-office-ribbon-tab')) {
        if (tab.textContent == text) return tab;
      }
      throw StateError('aba $text não encontrada');
    }

    DomElement buttonByTitle(String title) {
      for (final button in host.querySelectorAll('.dq-office-btn')) {
        if (button.getAttribute('title') == title) return button;
      }
      throw StateError('botão não encontrado: $title');
    }

    DomElement openMenuOf(String title) {
      click(tabByText('Layout'));
      click(buttonByTitle(title));
      return one('.dq-office-menu');
    }

    /// O item pelo RÓTULO exato: o texto do item inclui o ✓ e a descrição,
    /// então "Página" casaria com "Próxima Página" numa comparação frouxa.
    DomElement itemOf(DomElement menu, String label) {
      for (final item in menu.querySelectorAll('.dq-office-menu-item')) {
        final caption = item.querySelector('.dq-office-menu-label');
        if (caption?.textContent == label) return item;
      }
      throw StateError('item não encontrado: $label');
    }

    bool enabled(DomElement item) =>
        !item.classes.contains('dq-office-menu-item-disabled');

    test('Quebras habilita só o que o compositor honra', () {
      mount();
      final menu = openMenuOf('Quebras de Página e Seção');
      expect(enabled(itemOf(menu, 'Página')), isTrue);
      expect(enabled(itemOf(menu, 'Coluna')), isTrue);
      expect(enabled(itemOf(menu, 'Disposição do Texto')), isTrue);
      // "Próxima Página" cria seção de verdade desde que o B3 saiu: marca o
      // bloco e insere a geometria correspondente.
      expect(enabled(itemOf(menu, 'Próxima Página')), isTrue);
      // As outras três continuam visíveis e desabilitadas, cada uma com o
      // motivo escrito — o compositor fecha a página em toda fronteira de
      // seção, e não sabe completar paridade com página em branco.
      for (final label in const ['Contínua', 'Página Par', 'Página Ímpar']) {
        expect(enabled(itemOf(menu, label)), isFalse, reason: label);
      }
      expect(menu.textContent, contains('sempre fecha a página'));
      expect(menu.textContent, contains('paridade'));
    });

    test('Quebra de página abre a página seguinte', () {
      final editor = mount(blocks: 3);
      final before = editor.pageGraph.pages.length;
      caretAt(1);
      editor.view.syncSelectionFromDom();

      click(itemOf(openMenuOf('Quebras de Página e Seção'), 'Página'));
      expect(editor.pageGraph.pages.length, before + 1);
    });

    test(
        'Quebra de coluna, numa seção de UMA coluna, vai para a página seguinte',
        () {
      final editor = mount(blocks: 3);
      final before = editor.pageGraph.pages.length;
      caretAt(1);
      editor.view.syncSelectionFromDom();

      click(itemOf(openMenuOf('Quebras de Página e Seção'), 'Coluna'));
      expect(editor.pageGraph.pages.length, before + 1);
    });

    test('Colunas habilita as contagens e recusa as DESIGUAIS', () {
      mount();
      final menu = openMenuOf('Colunas');
      // O compositor faz fluxo de jornal, então estas mudam o desenho.
      for (final label in const ['Uma', 'Duas', 'Três']) {
        expect(enabled(itemOf(menu, label)), isTrue, reason: label);
      }
      // Estas duas são as colunas de larguras DIFERENTES do Word; a
      // geometria só modela colunas iguais, então habilitá-las produziria
      // duas colunas iguais com o nome errado.
      for (final label in const ['À Esquerda', 'À Direita']) {
        expect(enabled(itemOf(menu, label)), isFalse, reason: label);
      }
      expect(menu.textContent, contains('larguras DIFERENTES'));
    });

    test('escolher Duas recompõe o documento em duas colunas', () {
      final editor = mount(blocks: 40);
      expect(editor.pageSetup.columns, 1);

      click(itemOf(openMenuOf('Colunas'), 'Duas'));

      expect(editor.pageSetup.columnCount, 2);
      final colunas = <int>{
        for (final page in editor.pageGraph.pages)
          for (final fragment in page.fragments) fragment.columnIndex,
      };
      expect(colunas, contains(1),
          reason: 'sem fragmento na coluna 1 a metade direita fica em branco');
    });
  });
}
