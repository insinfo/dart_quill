/// Fase 2 / gate da Fase 5 — o lado EDITOR do invariante central:
/// o DOMRenderer consome o MESMO PageGraph que o PdfRenderer.
///
/// O teste-chave desta suíte é a paridade TRIPLA: para cada página, o texto
/// que o grafo compôs aparece no DOM daquela página E no stream PDF daquela
/// página. É a prova operacional de "a linha da página 18 do editor é a
/// linha da página 18 do PDF".
@TestOn('vm')
library;

import 'package:test/test.dart';

import 'package:dart_quill/dart_quill_office.dart';
import 'package:dart_quill/src/platform/dom.dart';

import '../../../support/fake_dom.dart';
import '../../../support/pdf_reader.dart';

/// Texto concatenado de um elemento e seus descendentes.
String textOf(DomElement element) => element.textContent ?? '';

List<DomElement> childrenOf(DomElement element) =>
    element.childNodes.whereType<DomElement>().toList();

void main() {
  final schema = officeQuillSchema();

  late FakeDomDocument document;
  late DomElement host;

  setUp(() {
    document = FakeDomDocument();
    host = document.createElement('div');
    document.body.append(host);
  });

  PMNode docOf(List<PMNode> blocks) =>
      schema.node('doc', null, Fragment.from(blocks));

  PMNode paragraph(String text) =>
      schema.node('paragraph', null, Fragment.from([schema.text(text)]));

  List<DomElement> pagesIn(DomElement host) => childrenOf(host)
      .where((e) => e.classes.contains('dq-office-page'))
      .toList();

  group('projeção de páginas', () {
    test('uma página por PageLayout, com a geometria em pixels', () {
      final graph = LayoutComposer().compose(docOf([paragraph('olá')]));
      PageGraphDomRenderer(document: document).render(graph, host);

      final pages = pagesIn(host);
      expect(pages, hasLength(1));
      final style = pages.first.getAttribute('style')!;
      // A4 = 11906 twips = 595.3pt; a 96/72 px/pt ≈ 793.7px.
      expect(style, contains('width:793.73px'));
      expect(style, contains('height:1122.53px'));
      expect(pages.first.getAttribute('data-page'), '0');
    });

    test('o content box respeita as margens da seção', () {
      final graph = LayoutComposer().compose(docOf([paragraph('x')]));
      PageGraphDomRenderer(document: document).render(graph, host);

      final content = childrenOf(pagesIn(host).first).single;
      expect(content.classes.contains('dq-office-page-content'), isTrue);
      final style = content.getAttribute('style')!;
      // margem de 2 cm = 1134 twips = 56.7pt ≈ 75.6px.
      expect(style, contains('left:75.6px'));
      expect(style, contains('top:75.6px'));
    });

    test('editable liga contenteditable e desliga o spellcheck nativo', () {
      final graph = LayoutComposer().compose(docOf([paragraph('x')]));
      PageGraphDomRenderer(document: document, editable: true)
          .render(graph, host);

      final content = childrenOf(pagesIn(host).first).single;
      expect(content.getAttribute('contenteditable'), 'true');
      expect(content.getAttribute('spellcheck'), 'false');
    });

    test('render substitui a projeção anterior, não acumula', () {
      final renderer = PageGraphDomRenderer(document: document);
      final graph = LayoutComposer().compose(docOf([paragraph('um')]));
      renderer.render(graph, host);
      renderer.render(graph, host);
      expect(pagesIn(host), hasLength(1));
    });
  });

  group('âncoras do PositionMap no DOM', () {
    test('cada bloco carrega docPos e o id estável do nó', () {
      final block = schema.node(
          'paragraph', {'id': 'p-42'}, Fragment.from([schema.text('texto')]));
      final graph = LayoutComposer().compose(docOf([block]));
      PageGraphDomRenderer(document: document).render(graph, host);

      final content = childrenOf(pagesIn(host).first).single;
      final blockElement = childrenOf(content).single;
      expect(blockElement.getAttribute('data-doc-pos'), '1');
      expect(blockElement.getAttribute('data-node-id'), 'p-42');
      expect(blockElement.classes.contains('dq-office-block-paragraph'),
          isTrue);
    });

    test('as linhas carregam o intervalo de caracteres do bloco', () {
      final graph = LayoutComposer()
          .compose(docOf([paragraph('primeira linha de conteúdo')]));
      PageGraphDomRenderer(document: document).render(graph, host);

      final content = childrenOf(pagesIn(host).first).single;
      final line = childrenOf(childrenOf(content).single).single;
      expect(line.classes.contains('dq-office-line'), isTrue);
      expect(line.getAttribute('data-char-start'), '0');
      expect(int.parse(line.getAttribute('data-char-end')!), greaterThan(0));
    });

    test('bloco que atravessa páginas marca a continuação nos dois lados',
        () {
      final long =
          paragraph(List.generate(2000, (i) => 'palavra$i').join(' '));
      final graph = LayoutComposer().compose(docOf([long]));
      PageGraphDomRenderer(document: document).render(graph, host);

      final pages = pagesIn(host);
      expect(pages.length, greaterThan(1));
      final first = childrenOf(childrenOf(pages[0]).single).single;
      final second = childrenOf(childrenOf(pages[1]).single).single;
      expect(first.getAttribute('data-continues-on'), 'true');
      expect(second.getAttribute('data-continues-from'), 'true');
      expect(first.getAttribute('data-doc-pos'),
          second.getAttribute('data-doc-pos'),
          reason: 'o MESMO nó nas duas páginas');
    });
  });

  group('estilo do run vira CSS inline (nunca classe global)', () {
    test('negrito, itálico, cor e link', () {
      final block = schema.node(
          'paragraph',
          null,
          Fragment.from([
            schema.text('forte', [schema.marks['bold']!.create()]),
            schema.text('ligado',
                [schema.marks['link']!.create({'href': 'https://x.gov.br'})]),
          ]));
      final graph = LayoutComposer().compose(docOf([block]));
      PageGraphDomRenderer(document: document).render(graph, host);

      final content = childrenOf(pagesIn(host).first).single;
      final runs = childrenOf(childrenOf(childrenOf(content).single).single);
      expect(runs.first.getAttribute('style'), contains('font-weight:bold'));
      final link = runs.firstWhere((r) => r.getAttribute('data-link') != null);
      expect(link.getAttribute('data-link'), 'https://x.gov.br');
      // Nenhuma classe do Quill vaza para a projeção Office.
      for (final run in runs) {
        expect(run.classes.contains('dq-office-run'), isTrue);
        expect(run.className, isNot(contains('ql-')));
      }
    });

    test('marcador de lista é projeção: inerte e fora da acessibilidade', () {
      final item = schema.node('listItem', {'kind': 'ordered'},
          Fragment.from([schema.text('item')]));
      final graph = LayoutComposer().compose(docOf([item]));
      PageGraphDomRenderer(document: document).render(graph, host);

      final content = childrenOf(pagesIn(host).first).single;
      final marker = childrenOf(childrenOf(content).single)
          .firstWhere((e) => e.classes.contains('dq-office-marker'));
      expect(textOf(marker), '1. ');
      expect(marker.getAttribute('contenteditable'), 'false');
      expect(marker.getAttribute('aria-hidden'), 'true');
    });
  });

  group('tabelas', () {
    test('linhas e células viram caixas posicionadas com borda', () {
      final rows = [
        for (var r = 0; r < 3; r++)
          schema.node('tableRow', {'rowId': 'r$r'}, Fragment.from([
            schema.node('tableCell', {'cellId': 'a$r'},
                Fragment.from([paragraph('A$r')])),
            schema.node('tableCell', {'cellId': 'b$r'},
                Fragment.from([paragraph('B$r')])),
          ]))
      ];
      final table = schema.node('table', {
        'colWidths': [
          {'width': '200'},
          {'width': '200'}
        ]
      }, Fragment.from(rows));
      final graph = LayoutComposer().compose(docOf([table]));
      PageGraphDomRenderer(document: document).render(graph, host);

      final content = childrenOf(pagesIn(host).first).single;
      final tableElement = childrenOf(content).single;
      expect(tableElement.classes.contains('dq-office-table'), isTrue);
      final rowElements = childrenOf(tableElement);
      expect(rowElements, hasLength(3));
      final cells = childrenOf(rowElements.first);
      expect(cells, hasLength(2));
      expect(cells.first.getAttribute('style'), contains('border:1px solid'));
      expect(textOf(cells.first), contains('A0'));
      expect(textOf(cells.last), contains('B0'));
    });
  });

  group('virtualização por janela de páginas', () {
    test('páginas fora da janela viram placeholder da MESMA altura', () {
      final blocks = [
        for (var i = 0; i < 200; i++) paragraph('Parágrafo $i do documento.')
      ];
      final graph = LayoutComposer().compose(docOf(blocks));
      expect(graph.pages.length, greaterThan(3));

      PageGraphDomRenderer(document: document).render(graph, host,
          window: const PageWindow(firstPage: 0, lastPage: 1));

      final children = childrenOf(host);
      expect(children.length, graph.pages.length,
          reason: 'toda página ocupa um slot — o scroll não pode pular');
      expect(pagesIn(host), hasLength(2), reason: 'só a janela é montada');
      final placeholder = children.last;
      expect(placeholder.classes.contains('dq-office-page-placeholder'),
          isTrue);
      expect(placeholder.getAttribute('style'),
          contains('height:1122.53px'),
          reason: 'placeholder com a altura exata da página');
      expect(textOf(placeholder), isEmpty);
    });
  });

  group('GATE: grafo, DOM e PDF concordam página a página', () {
    test('o texto da página N está no DOM N e no PDF N', () {
      final blocks = [
        for (var i = 0; i < 120; i++)
          paragraph('Sentenca numero $i com conteudo distinto.')
      ];
      final graph = LayoutComposer().compose(docOf(blocks));
      expect(graph.pages.length, greaterThan(1));

      PageGraphDomRenderer(document: document).render(graph, host);
      final domPages = pagesIn(host);
      final pdfStreams = PdfReader(PageGraphPdfRenderer().render(graph))
          .decodedStreams
          .where((s) => s.contains('Tj'))
          .toList();

      expect(domPages.length, graph.pages.length);
      expect(pdfStreams.length, graph.pages.length);

      for (var p = 0; p < graph.pages.length; p++) {
        final domText = textOf(domPages[p]);
        for (final fragment
            in graph.pages[p].fragments.whereType<BlockFragment>()) {
          for (final line in fragment.lines) {
            for (final segment in line.segments) {
              final word = segment.text.split(' ').firstWhere(
                  (w) => RegExp(r'^[A-Za-z0-9]{4,}$').hasMatch(w),
                  orElse: () => '');
              if (word.isEmpty) continue;
              expect(domText, contains(word),
                  reason: '"$word" do grafo pág. $p tem de estar no DOM $p');
              expect(pdfStreams[p], contains(word),
                  reason: '"$word" do grafo pág. $p tem de estar no PDF $p');
              break;
            }
          }
        }
      }
    });

    test('o DOM não perde nem duplica texto do documento', () {
      final blocks = [
        for (var i = 0; i < 40; i++) paragraph('linha unica numero $i')
      ];
      final graph = LayoutComposer().compose(docOf(blocks));
      PageGraphDomRenderer(document: document).render(graph, host);

      // `textContent` concatena blocos sem separador, então a busca precisa
      // fechar o número (senão "numero 1" casaria dentro de "numero 12").
      final domText = textOf(host);
      for (var i = 0; i < 40; i++) {
        final occurrences =
            RegExp('numero $i(?![0-9])').allMatches(domText).length;
        expect(occurrences, 1,
            reason: 'o parágrafo $i aparece exatamente uma vez no DOM');
      }
    });
  });
}
