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

import 'dart:io';
import 'dart:typed_data';

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

    test('o CSS é ASSET do pacote, não string embutida', () {
      mount();
      // Nenhum <style> injetado: o consumidor inclui (ou substitui) os
      // stylesheets de lib/assets, como faz com os temas do Quill.
      expect(host.querySelector('style'), isNull);

      final css = File('lib/assets/office_word_editor.css').readAsStringSync();
      expect(css, contains('.dq-office-ribbon'));
      expect(css, isNot(contains('.ql-')),
          reason: 'nenhuma regra pode alcançar o Quill simples');

      final icons = File('lib/assets/office_word_icons.css').readAsStringSync();
      expect(icons, contains('.dq-icon-bold'));
      expect(icons, contains('CC BY-SA 4.0'),
          reason: 'os ícones ONLYOFFICE exigem a atribuição na própria folha');
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

  group('aba Layout', () {
    DomElement tabByText(String text) {
      for (final tab in host.querySelectorAll('.dq-office-ribbon-tab')) {
        if (tab.textContent == text) return tab;
      }
      throw StateError('aba $text não encontrada');
    }

    test('clicar em Layout troca os grupos da ribbon', () {
      mount();
      final layout = tabByText('Layout');
      (layout as FakeDomElement).dispatchEvent(
          'click', FakeDomMouseEvent(type: 'click', target: layout));

      final labels = [
        for (final g in host.querySelectorAll('.dq-office-ribbon-group'))
          g.getAttribute('data-group-label')
      ];
      expect(labels, containsAll(['Orientação', 'Tamanho', 'Margens']));
      expect(layout.classes.contains('dq-office-ribbon-tab-active'), isTrue);
    });

    test('Paisagem REPAGINA o documento de verdade', () {
      final editor = mount(blocks: 120);
      final portraitPages = editor.pageGraph.pages.length;
      final layout = tabByText('Layout');
      (layout as FakeDomElement).dispatchEvent(
          'click', FakeDomMouseEvent(type: 'click', target: layout));

      DomElement? landscape;
      for (final b in host.querySelectorAll('.dq-office-btn')) {
        if (b.getAttribute('title') == 'Paisagem') landscape = b;
      }
      (landscape! as FakeDomElement).dispatchEvent(
          'click', FakeDomMouseEvent(type: 'click', target: landscape));

      expect(editor.pageSetup.widthTwips,
          greaterThan(editor.pageSetup.heightTwips));
      expect(editor.pageGraph.pages.first.setup.widthTwips,
          editor.pageSetup.widthTwips,
          reason: 'o grafo tem de repaginar com a nova geometria');
      expect(editor.pageGraph.pages.length, isNot(portraitPages),
          reason: 'paisagem muda a contagem de páginas');
      expect(editor.state.doc.childCount, greaterThan(0),
          reason: 'o conteúdo fica intacto');
    });

    test('as quatro abas estão habilitadas e clicáveis', () {
      mount();
      for (final label in const [
        'Arquivo',
        'Página Inicial',
        'Inserir',
        'Layout'
      ]) {
        final tab = tabByText(label);
        expect(tab.classes.contains('dq-office-ribbon-tab-disabled'), isFalse,
            reason: '$label ganhou conteúdo funcional');
      }
    });
  });

  test('os botões de lista alternam o bloco como no Word', () {
    final editor = mount(blocks: 3);
    const map = OfficeDomPositionMap();
    final pages = host.querySelector('.dq-office-pages')!;
    final position = map.domPositionFor(pages, 1)!;
    adapter.setSelectionByNodes(
        position.node, position.offset, position.node, position.offset);

    DomElement byTitle(String title) {
      for (final b in host.querySelectorAll('.dq-office-btn')) {
        if (b.getAttribute('title') == title) return b;
      }
      throw StateError('botão $title não encontrado');
    }

    void click(DomElement b) => (b as FakeDomElement)
        .dispatchEvent('click', FakeDomMouseEvent(type: 'click', target: b));

    click(byTitle('Lista com marcadores'));
    expect(editor.state.doc.child(0).type.name, 'listItem');
    expect(editor.state.doc.child(0).attrs['kind'], 'bullet');
    // O marcador vem do layout, como projeção.
    expect(
        editor.pageGraph.pages.first.fragments
            .whereType<BlockFragment>()
            .first
            .marker,
        isNotNull);

    // Mesmo tipo de novo: volta a parágrafo.
    click(byTitle('Lista com marcadores'));
    expect(editor.state.doc.child(0).type.name, 'paragraph');

    // Numerada: troca o tipo direto.
    click(byTitle('Lista numerada'));
    expect(editor.state.doc.child(0).attrs['kind'], 'ordered');
  });

  group('aba Inserir', () {
    DomElement tab(String text) {
      for (final t in host.querySelectorAll('.dq-office-ribbon-tab')) {
        if (t.textContent == text) return t;
      }
      throw StateError('aba não encontrada');
    }

    DomElement byTitlePrefix(String prefix) {
      for (final b in host.querySelectorAll('.dq-office-btn')) {
        final title = b.getAttribute('title') ?? '';
        if (title.startsWith(prefix)) return b;
      }
      throw StateError('botão $prefix não encontrado');
    }

    void click(DomElement el) => (el as FakeDomElement)
        .dispatchEvent('click', FakeDomMouseEvent(type: 'click', target: el));

    void caretAt(int position) {
      const map = OfficeDomPositionMap();
      final pages = host.querySelector('.dq-office-pages')!;
      final p = map.domPositionFor(pages, position)!;
      adapter.setSelectionByNodes(p.node, p.offset, p.node, p.offset);
    }

    test('a quebra de página manda o resto do parágrafo para a próxima', () {
      final editor = mount(blocks: 3);
      final pagesBefore = editor.pageGraph.pages.length;
      caretAt(1 + 5); // meio do primeiro parágrafo
      click(tab('Inserir'));
      click(byTitlePrefix('Quebra de Página'));

      expect(editor.pageGraph.pages.length, pagesBefore + 1,
          reason: 'a quebra manual abre página nova');
      // O primeiro fragmento da página 2 é o bloco que carrega a quebra.
      final second = editor.pageGraph.pages[1].fragments.first;
      expect(second.docPos,
          editor.pageGraph.pages[1].signature.firstBlockOffset + 1);
      // E o PDF pagina IGUAL — mesma contagem.
      expect(OfficePdfService().fromPageGraph(editor.pageGraph).pageCount,
          editor.pageGraph.pages.length);
    });

    test('a quebra sobrevive ao undo', () {
      final editor = mount(blocks: 3);
      final before = editor.pageGraph.pages.length;
      caretAt(1 + 5);
      click(tab('Inserir'));
      click(byTitlePrefix('Quebra de Página'));
      expect(editor.pageGraph.pages.length, before + 1);

      // O listener de teclado vive na superfície de páginas, não no shell.
      final pages = host.querySelector('.dq-office-pages')!;
      (pages as FakeDomElement).dispatchEvent(
          'keydown',
          FakeDomKeyboardEvent(
              type: 'keydown', target: pages, key: 'z', ctrlKey: true));
      expect(editor.pageGraph.pages.length, before,
          reason: 'undo desfaz split E marca numa transação só');
    });

    test('inserir tabela cria a grade no grafo e na projeção', () {
      final editor = mount(blocks: 3);
      caretAt(1 + 5);
      click(tab('Inserir'));
      click(byTitlePrefix('Inserir tabela'));

      var tables = 0;
      for (var i = 0; i < editor.state.doc.childCount; i++) {
        if (editor.state.doc.child(i).type.name == 'table') tables++;
      }
      expect(tables, 1);
      expect(
          editor.pageGraph.pages
              .expand((p) => p.fragments)
              .whereType<TableFragment>()
              .length,
          greaterThan(0),
          reason: 'a tabela tem de aparecer paginada');
      expect(count('.dq-office-table'), greaterThan(0));
      expect(count('.dq-office-table-cell'), 9,
          reason: '3×3 células projetadas');
    });
  });

  group('aba Arquivo', () {
    DomElement tab(String text) {
      for (final t in host.querySelectorAll('.dq-office-ribbon-tab')) {
        if (t.textContent == text) return t;
      }
      throw StateError('aba não encontrada');
    }

    DomElement button(String text) {
      for (final b in host.querySelectorAll('.dq-office-btn')) {
        if (b.textContent == text) return b;
      }
      throw StateError('botão não encontrado');
    }

    void click(DomElement el) => (el as FakeDomElement)
        .dispatchEvent('click', FakeDomMouseEvent(type: 'click', target: el));

    test('Exportar PDF baixa as MESMAS páginas da tela', () {
      final editor = mount(blocks: 120);
      final fake = adapter as FakeDomAdapter;
      fake.downloads.clear();

      click(tab('Arquivo'));
      click(button('PDF'));

      expect(fake.downloads, hasLength(1));
      final download = fake.downloads.single;
      expect(download.filename, endsWith('.pdf'));
      expect(String.fromCharCodes(download.bytes.take(5)), '%PDF-');
      expect(OfficePdfService().fromPageGraph(editor.pageGraph).pageCount,
          editor.pageGraph.pages.length);
    });

    test('Exportar DOCX gera um pacote que REABRE com o mesmo texto', () {
      final editor = mount(blocks: 5);
      final fake = adapter as FakeDomAdapter;
      fake.downloads.clear();

      click(tab('Arquivo'));
      click(button('DOCX'));

      final download = fake.downloads.single;
      expect(download.filename, endsWith('.docx'));
      expect(download.bytes[0], 0x50, reason: 'assinatura ZIP (PK)');
      expect(download.bytes[1], 0x4B);

      // A prova que importa: reabrir pelo NOSSO importador devolve o texto.
      final reopened = OfficeDocxCodec(schema: schema)
          .import(Uint8List.fromList(download.bytes));
      final doc = PMNode.fromJSON(schema, reopened.snapshot.body);
      expect(doc.textBetween(0, doc.content.size, blockSeparator: ' '),
          contains('Parágrafo 0'));
      expect(doc.childCount, editor.state.doc.childCount);
    });
  });

  test('zoom reconstrói as réguas na nova escala', () {
    final editor = mount();
    final widthBefore = host
        .querySelector('.dq-office-ruler-center')!
        .getAttribute('style');
    editor.setZoom(1.5);
    final widthAfter = host
        .querySelector('.dq-office-ruler-center')!
        .getAttribute('style');
    expect(widthAfter, isNot(widthBefore),
        reason: 'régua na escala antiga com página na nova era o bug');
  });

  group('title bar opcional', () {
    test('desligada por padrão — a aplicação hospedeira tem a sua', () {
      mount();
      expect(count('.dq-office-titlebar'), 0);
    });

    test('ligada quando pedida', () {
      editor = OfficeWordEditor.mount(
        host: host,
        adapter: adapter,
        document: docOf(5),
        schema: schema,
        options: const OfficeWordEditorOptions(showTitleBar: true),
      );
      expect(count('.dq-office-titlebar'), 1);
    });
  });

  group('régua: marcadores de recuo', () {
    void caretAt(int position) {
      const map = OfficeDomPositionMap();
      final pages = host.querySelector('.dq-office-pages')!;
      final p = map.domPositionFor(pages, position)!;
      adapter.setSelectionByNodes(p.node, p.offset, p.node, p.offset);
    }

    test('a régua vive DENTRO do canvas, com canto e marcadores', () {
      mount();
      final canvas = host.querySelector('.dq-office-canvas')!;
      expect(canvas.querySelectorAll('.dq-office-ruler').length, 1,
          reason: 'a régua acompanha a área do documento, como no Word');
      expect(count('.dq-office-ruler-corner'), 1);
      expect(count('.dq-office-indent-first'), 1);
      expect(count('.dq-office-indent-left'), 1);
      expect(count('.dq-office-indent-right'), 1);
    });

    test('arrastar o recuo esquerdo aplica a transação no parágrafo', () {
      final editor = mount(blocks: 5);
      caretAt(1);
      editor.view.syncSelectionFromDom();

      final marker = host.querySelector('.dq-office-indent-left')!;
      (marker as FakeDomElement).dispatchEvent(
          'pointerdown',
          FakeDomMouseEvent(
              type: 'pointerdown', target: marker, clientX: 100));
      final canvas = host.querySelector('.dq-office-canvas')!;
      (canvas as FakeDomElement).dispatchEvent(
          'pointerup',
          FakeDomMouseEvent(type: 'pointerup', target: canvas, clientX: 176));

      // 76px / (96/72/20) px por twip = 1140 twips (~2 cm).
      final style = editor.state.doc.child(0).attrs['style'] as Map;
      expect(style['indentTwips'], closeTo(1140, 20));
      // E o LAYOUT honra: o fragmento sai recuado na tela e no PDF.
      expect(
          editor.pageGraph.pages.first.fragments
              .whereType<BlockFragment>()
              .first
              .indentTwips,
          closeTo(1140, 20));
    });

    test('recuo de primeira linha desloca só a primeira LINHA', () {
      final editor = mount(blocks: 5);
      caretAt(1);
      editor.view.syncSelectionFromDom();

      final marker = host.querySelector('.dq-office-indent-first')!;
      (marker as FakeDomElement).dispatchEvent(
          'pointerdown',
          FakeDomMouseEvent(
              type: 'pointerdown', target: marker, clientX: 100));
      final canvas = host.querySelector('.dq-office-canvas')!;
      (canvas as FakeDomElement).dispatchEvent(
          'pointerup',
          FakeDomMouseEvent(type: 'pointerup', target: canvas, clientX: 138));

      final block = editor.pageGraph.pages.first.fragments
          .whereType<BlockFragment>()
          .first;
      expect(block.lines.first.indentTwips, greaterThan(400),
          reason: 'primeira linha deslocada');
      if (block.lines.length > 1) {
        expect(block.lines[1].indentTwips, 0,
            reason: 'as demais linhas ficam na base do bloco');
      }
    });
  });

  group('aba contextual Tabela', () {
    DomElement tab(String text) {
      for (final t in host.querySelectorAll('.dq-office-ribbon-tab')) {
        if (t.textContent == text) return t;
      }
      throw StateError('aba não encontrada');
    }

    DomElement byTitle(String title) {
      for (final b in host.querySelectorAll('.dq-office-btn')) {
        if ((b.getAttribute('title') ?? '') == title) return b;
      }
      throw StateError('botão não encontrado: ' + title);
    }

    void click(DomElement el) => (el as FakeDomElement)
        .dispatchEvent('click', FakeDomMouseEvent(type: 'click', target: el));

    int caretIntoTable(OfficeWordEditor editor) {
      var offset = 0;
      for (var i = 0; i < editor.state.doc.childCount; i++) {
        final child = editor.state.doc.child(i);
        if (child.type.name == 'table') {
          final pos = offset + 4; // table>row>cell>paragraph>texto
          editor.view.dispatch(editor.state.tr
            ..setSelection(TextSelection.create(editor.state.doc, pos)));
          return pos;
        }
        offset += child.nodeSize;
      }
      throw StateError('tabela não encontrada');
    }

    OfficeWordEditor mountWithTable() {
      final editor = mount(blocks: 3);
      click(tab('Inserir'));
      click(byTitle('Inserir tabela 3×3'));
      return editor;
    }

    PMNode tableOf(OfficeWordEditor editor) {
      for (var i = 0; i < editor.state.doc.childCount; i++) {
        if (editor.state.doc.child(i).type.name == 'table') {
          return editor.state.doc.child(i);
        }
      }
      throw StateError('tabela não encontrada');
    }

    test('a aba aparece com a seleção NA tabela e some fora', () {
      final editor = mountWithTable();
      final tableTab = tab('Tabela');
      // Inserir deixa a seleção DENTRO da tabela — a aba já aparece, como
      // no Word.
      expect(tableTab.classes.contains('dq-office-ribbon-tab-hidden'), isFalse);

      // Fora = DEPOIS da tabela (ela foi inserida no início do documento,
      // então pos 1 fica dentro dela).
      var outside = 0;
      for (var i = 0; i < editor.state.doc.childCount; i++) {
        outside += editor.state.doc.child(i).nodeSize;
        if (editor.state.doc.child(i).type.name == 'table') break;
      }
      editor.view.dispatch(editor.state.tr
        ..setSelection(TextSelection.create(editor.state.doc, outside + 1)));
      expect(tableTab.classes.contains('dq-office-ribbon-tab-hidden'), isTrue,
          reason: 'fora da tabela, a aba contextual some');

      caretIntoTable(editor);
      expect(tableTab.classes.contains('dq-office-ribbon-tab-hidden'), isFalse,
          reason: 'a shell é contextual: seleção na tabela mostra a aba');
    });

    test('inserir linha abaixo', () {
      final editor = mountWithTable();
      caretIntoTable(editor);
      click(tab('Tabela'));
      click(byTitle('Inserir linha abaixo'));
      expect(tableOf(editor).childCount, 4);
    });

    test('inserir coluna à direita em TODAS as linhas', () {
      final editor = mountWithTable();
      caretIntoTable(editor);
      click(tab('Tabela'));
      click(byTitle('Inserir coluna à direita'));
      final table = tableOf(editor);
      for (var r = 0; r < table.childCount; r++) {
        expect(table.child(r).childCount, 4,
            reason: 'coluna entra em cada linha, não só na corrente');
      }
    });

    test('excluir linha e coluna', () {
      final editor = mountWithTable();
      caretIntoTable(editor);
      click(tab('Tabela'));
      click(byTitle('Excluir linha'));
      expect(tableOf(editor).childCount, 2);
      caretIntoTable(editor);
      click(byTitle('Excluir coluna'));
      expect(tableOf(editor).child(0).childCount, 2);
    });

    test('excluir a tabela esconde a aba', () {
      final editor = mountWithTable();
      caretIntoTable(editor);
      click(tab('Tabela'));
      click(byTitle('Excluir tabela'));
      for (var i = 0; i < editor.state.doc.childCount; i++) {
        expect(editor.state.doc.child(i).type.name, isNot('table'));
      }
      expect(tab('Tabela').classes.contains('dq-office-ribbon-tab-hidden'),
          isTrue);
    });
  });

  test('dispose devolve o host vazio', () {
    final editor = mount();
    editor.dispose();
    expect(host.firstChild, isNull);
    expect(host.classes.contains('dq-office-app'), isFalse);
  });
}
