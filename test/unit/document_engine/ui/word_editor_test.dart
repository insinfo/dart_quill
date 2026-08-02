/// O componente Word completo — o que o consumidor da biblioteca monta com
/// UMA chamada.
///
/// O contrato destes testes é o da reclamação que originou o componente: a
/// UI pertence à BIBLIOTECA. Ribbon, régua, páginas e barra de status têm
/// de existir sem a aplicação escrever HTML/CSS; os três modos têm de se
/// comportar como produto (view não edita, flow não mostra chrome de
/// página, word mostra tudo); e a ribbon usa os MESMOS comandos dos
/// atalhos.
@TestOn('vm')
library;

import 'package:test/test.dart';

import 'package:dart_quill/dart_quill_office.dart';
import 'package:dart_quill/src/platform/dom.dart';

import '../../../support/fake_dom.dart';
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

  PMNode paragraph(String text) => schema.node(
      'paragraph', null, Fragment.from([schema.text(text)]));

  PMNode docOf(int blocks) => schema.node(
      'doc',
      null,
      Fragment.from([
        for (var i = 0; i < blocks; i++)
          paragraph('Parágrafo $i com texto suficiente para ocupar espaço '
              'real na página e paginar de verdade.')
      ]));

  OfficeWordEditor mount(
          {OfficeWordMode mode = OfficeWordMode.word, int blocks = 60}) =>
      editor = OfficeWordEditor.mount(
        host: host,
        adapter: adapter,
        document: docOf(blocks),
        schema: schema,
        options: OfficeWordEditorOptions(
          mode: mode,
          headerText: 'PREFEITURA',
          footerText: 'Página {PAGE} de {NUMPAGES}',
        ),
      );

  int count(String selector) => host.querySelectorAll(selector).length;

  group('modo word', () {
    test('a biblioteca monta o chrome INTEIRO: ribbon, régua, status', () {
      mount();
      expect(count('.dq-office-ribbon'), 1);
      expect(count('.dq-office-ribbon-tab'), greaterThanOrEqualTo(4));
      expect(count('.dq-office-ribbon-group'), greaterThanOrEqualTo(4));
      expect(count('.dq-office-ruler'), 1);
      expect(count('.dq-office-ruler-number'), greaterThan(10),
          reason: 'A4 útil tem ~16 cm de números na régua');
      expect(count('.dq-office-statusbar'), 1);
      expect(count('.dq-office-page'), greaterThan(0));
    });

    test('o CSS vem injetado pelo componente, escopado em dq-office', () {
      mount();
      final style = host.querySelector('style[data-dq-office-ui]');
      expect(style, isNotNull);
      expect(style!.textContent, contains('.dq-office-ribbon'));
      expect(style.textContent, isNot(contains('.ql-')),
          reason: 'nenhuma regra pode alcançar o Quill simples');
    });

    test('a barra de status mostra a página corrente e o total', () {
      final editor = mount(blocks: 200);
      final status = host.querySelector('.dq-office-statusbar')!;
      expect(status.textContent,
          contains('de ${editor.pageGraph.pages.length}'));
      expect(status.textContent, contains('Página 1'));
    });

    test('o botão da ribbon roda o MESMO comando do atalho', () {
      final editor = mount(blocks: 3);
      const map = OfficeDomPositionMap();
      final pages = host.querySelector('.dq-office-pages')!;
      final from = map.domPositionFor(pages, 1)!;
      final to = map.domPositionFor(pages, 1 + 9)!;
      adapter.setSelectionByNodes(from.node, from.offset, to.node, to.offset);

      // Seletor simples: o fake DOM não implementa seletor composto.
      final bold = host.querySelector('.dq-office-b')!;
      (bold as FakeDomElement)
          .dispatchEvent('click', FakeDomMouseEvent(type: 'click', target: bold));

      expect(
          editor.state.doc.child(0).firstChild?.marks.map((m) => m.type.name),
          contains('bold'));
    });

    test('cabeçalho e rodapé configurados aparecem nas páginas', () {
      mount(blocks: 200);
      expect(count('.dq-office-header'), greaterThan(0));
      final footer = host.querySelector('.dq-office-footer')!;
      expect(footer.textContent, contains('Página 1 de'));
    });

    test('exportPdf devolve o PDF da MESMA paginação da tela', () {
      final editor = mount(blocks: 200);
      final bytes = editor.exportPdf();
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
      expect(
          OfficePdfService().fromPageGraph(editor.pageGraph).pageCount,
          editor.pageGraph.pages.length);
    });

    test('zoom muda só a projeção e preserva o histórico', () {
      final editor = mount(blocks: 10);
      final pagesBefore = editor.pageGraph.pages.length;
      final stateBefore = editor.state;

      editor.setZoom(1.5);

      expect(editor.zoom, 1.5);
      expect(editor.pageGraph.pages.length, pagesBefore,
          reason: 'zoom é borda twips→px; o grafo não muda');
      expect(identical(editor.state.doc, stateBefore.doc), isTrue,
          reason: 'o EditorState é reaproveitado — o undo sobrevive');
    });
  });

  group('modo view', () {
    test('sem ribbon, sem régua, sem edição', () {
      mount(mode: OfficeWordMode.view);
      expect(count('.dq-office-ribbon'), 0);
      expect(count('.dq-office-ruler'), 0);
      expect(count('.dq-office-statusbar'), 1);
      expect(count('[contenteditable="true"]'), 0,
          reason: 'somente leitura significa nenhuma superfície editável');
    });
  });

  group('modo flow', () {
    test('toolbar compacta, sem régua, com a classe de fluxo', () {
      mount(mode: OfficeWordMode.flow);
      expect(host.classes.contains('dq-office-app-flow'), isTrue);
      expect(count('.dq-office-ribbon'), 1);
      expect(count('.dq-office-ribbon-tab'), 0,
          reason: 'flow usa a toolbar compacta, sem abas');
      expect(count('.dq-office-ruler'), 0);
      expect(count('[contenteditable="true"]'), greaterThan(0));
    });
  });

  group('estado ativo', () {
    test('o B acende quando a seleção está em negrito, e apaga fora', () {
      final editor = mount(blocks: 3);
      const map = OfficeDomPositionMap();
      final pages = host.querySelector('.dq-office-pages')!;
      final from = map.domPositionFor(pages, 1)!;
      final to = map.domPositionFor(pages, 1 + 9)!;
      adapter.setSelectionByNodes(from.node, from.offset, to.node, to.offset);

      final bold = host.querySelector('.dq-office-b')!;
      expect(bold.classes.contains('dq-office-btn-active'), isFalse);

      editor.view.runCommand('bold');
      expect(bold.classes.contains('dq-office-btn-active'), isTrue,
          reason: 'a UI tem de refletir o modelo, como no Word');

      editor.view.runCommand('bold'); // desliga
      expect(bold.classes.contains('dq-office-btn-active'), isFalse);
    });

    test('o select de estilos reflete o bloco do cursor', () {
      final editor = mount(blocks: 3);
      const map = OfficeDomPositionMap();
      final pages = host.querySelector('.dq-office-pages')!;
      final position = map.domPositionFor(pages, 1)!;
      adapter.setSelectionByNodes(
          position.node, position.offset, position.node, position.offset);

      editor.view.syncSelectionFromDom();
      final select = host.querySelector('.dq-office-style')!;

      // Vira Título 2 pela ribbon; o select acompanha.
      final tr = editor.state.tr;
      tr.setNodeMarkup(0, schema.nodes['heading'], {'level': 2});
      editor.view.dispatch(tr);
      expect(select.value, 'Título 2');
    });
  });

  group('régua vertical', () {
    test('existe no modo word, com números por centímetro', () {
      mount();
      expect(count('.dq-office-vruler'), 1);
      expect(count('.dq-office-vruler-number'), greaterThan(10),
          reason: 'A4 útil tem ~24 cm de altura numerada');
    });

    test('não existe nos modos flow e view', () {
      mount(mode: OfficeWordMode.flow);
      expect(count('.dq-office-vruler'), 0);
      editor!.dispose();
      mount(mode: OfficeWordMode.view);
      expect(count('.dq-office-vruler'), 0);
    });
  });

  test('dispose devolve o host vazio', () {
    final editor = mount();
    editor.dispose();
    expect(host.firstChild, isNull);
    expect(host.classes.contains('dq-office-app'), isFalse);
  });
}
