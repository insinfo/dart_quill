/// Fase 2 — o passo 1 da ordem do plano (§7.9): posição modelo↔DOM robusta
/// ANTES de seleção, IME e virtualização.
///
/// O invariante que estes testes travam é o round-trip: para toda posição
/// do modelo projetada numa página montada, `modelPositionAt(domPositionFor(p))
/// == p`. É ele que permite ler a seleção nativa e escrever de volta sem
/// deriva.
@TestOn('vm')
library;

import 'package:test/test.dart';

import 'package:dart_quill/dart_quill_office.dart';
import 'package:dart_quill/src/platform/dom.dart';

import '../../../support/fake_dom.dart';

void main() {
  final schema = officeQuillSchema();
  const map = OfficeDomPositionMap();

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

  PageGraph project(
    PMNode doc, {
    PageWindow? window,
    PMNode? header,
    PMNode? footer,
  }) {
    final graph = LayoutComposer(header: header, footer: footer).compose(doc);
    PageGraphDomRenderer(document: document)
        .render(graph, host, window: window);
    return graph;
  }

  group('modelo → DOM', () {
    test('a posição do início do bloco cai no primeiro nó de texto', () {
      project(docOf([paragraph('alpha beta')]));
      // docPos do primeiro bloco = 1 (conteúdo do bloco começa em 1).
      final position = map.domPositionFor(host, 1);
      expect(position, isNotNull);
      expect(position!.offset, 0);
      expect(position.node.textContent, startsWith('alpha'));
    });

    test('uma posição no meio do texto cai no offset certo', () {
      project(docOf([paragraph('alpha beta')]));
      final position = map.domPositionFor(host, 1 + 6); // depois de "alpha "
      expect(position!.offset, 6);
    });

    test('posição fora do documento devolve null', () {
      project(docOf([paragraph('curto')]));
      expect(map.domPositionFor(host, 9999), isNull);
    });

    test('posição em página NÃO montada devolve null (contrato da janela)', () {
      final blocks = [
        for (var i = 0; i < 200; i++) paragraph('Parágrafo $i do documento.')
      ];
      final graph = project(docOf(blocks),
          window: const PageWindow(firstPage: 0, lastPage: 0));
      expect(graph.pages.length, greaterThan(1));

      final onSecondPage = graph.positionMap.entries
          .firstWhere((e) => e.pageIndex == 1)
          .docPosStart;
      expect(map.domPositionFor(host, onSecondPage), isNull,
          reason: 'o chamador monta a janela e tenta de novo');
      expect(map.domPositionFor(host, 1), isNotNull,
          reason: 'a página montada continua respondendo');
    });

    test('header/footer com docPos negativo nunca capturam o caret do corpo',
        () {
      project(
        docOf([paragraph('abc')]),
        header: docOf([paragraph('CABEÇALHO MUITO LONGO')]),
        footer: docOf([paragraph('RODAPÉ MUITO LONGO')]),
      );

      final bodyCaret = map.domPositionFor(host, 1)!;
      DomNode? ancestor = bodyCaret.node;
      var inBody = false;
      var inRegion = false;
      while (ancestor != null) {
        if (ancestor is DomElement) {
          inBody |= ancestor.classes.contains('dq-office-page-content');
          inRegion |= ancestor.classes.contains('dq-office-header') ||
              ancestor.classes.contains('dq-office-footer');
        }
        ancestor = ancestor.parentNode;
      }
      expect(inBody, isTrue);
      expect(inRegion, isFalse);

      final headerText = host
          .querySelector('.dq-office-header')!
          .querySelector('.dq-office-run')!
          .firstChild!;
      final footerText = host
          .querySelector('.dq-office-footer')!
          .querySelector('.dq-office-run')!
          .firstChild!;
      expect(map.modelPositionAt(headerText, 0), isNull);
      expect(map.modelPositionAt(footerText, 0), isNull);
    });
  });

  group('DOM → modelo', () {
    test('ponto num nó de texto devolve a posição do modelo', () {
      project(docOf([paragraph('alpha beta')]));
      final position = map.domPositionFor(host, 1 + 6)!;
      expect(map.modelPositionAt(position.node, position.offset), 1 + 6);
    });

    test('ponto no chrome da página (fora de linha) devolve null', () {
      project(docOf([paragraph('x')]));
      expect(map.modelPositionAt(host, 0), isNull,
          reason: 'o host não é conteúdo do documento');
    });

    test('o marcador de lista não conta como texto do documento', () {
      final item = schema.node('listItem', {'kind': 'ordered'},
          Fragment.from([schema.text('item')]));
      project(docOf([item]));

      // A posição do início do conteúdo é o "i" de "item", não o "1. ".
      final position = map.domPositionFor(host, 1)!;
      expect(position.node.textContent, startsWith('item'));
      expect(map.modelPositionAt(position.node, 0), 1);
    });
  });

  group('round-trip modelo→DOM→modelo', () {
    test('vale para TODA posição de um documento de várias linhas', () {
      final doc = docOf([
        paragraph('primeiro parágrafo com texto suficiente para quebrar '
            'em mais de uma linha na página A4 padrão do compositor'),
        paragraph('segundo'),
        paragraph('terceiro parágrafo'),
      ]);
      final graph = project(doc);

      var checked = 0;
      for (final entry in graph.positionMap.entries) {
        for (var p = entry.docPosStart; p <= entry.docPosEnd; p++) {
          final position = map.domPositionFor(host, p);
          if (position == null) continue;
          expect(map.modelPositionAt(position.node, position.offset), p,
              reason: 'round-trip falhou na posição $p');
          checked++;
        }
      }
      expect(checked, greaterThan(50),
          reason: 'o teste precisa ter exercitado posições de verdade');
    });

    test('vale com marcas inline (vários runs na mesma linha)', () {
      final block = schema.node(
          'paragraph',
          null,
          Fragment.from([
            schema.text('normal '),
            schema.text('negrito', [schema.marks['bold']!.create()]),
            schema.text(' e fim'),
          ]));
      project(docOf([block]));

      for (var p = 1; p <= 1 + 'normal negrito e fim'.length; p++) {
        final position = map.domPositionFor(host, p);
        if (position == null) continue;
        expect(map.modelPositionAt(position.node, position.offset), p,
            reason: 'round-trip falhou atravessando runs na posição $p');
      }
    });

    test('a posição sabe em que página está', () {
      final blocks = [
        for (var i = 0; i < 200; i++) paragraph('Parágrafo $i do documento.')
      ];
      final graph = project(docOf(blocks));
      expect(graph.pages.length, greaterThan(1));

      for (final entry in graph.positionMap.entries) {
        final page = map.pageIndexFor(host, entry.docPosStart);
        if (page == null) continue;
        expect(page, entry.pageIndex,
            reason: 'a página do DOM tem de bater com a do PositionMap');
      }
    });
  });

  group('atoms inline sem textContent', () {
    PMNode image() => schema.node('image', {
          'src': 'data:image/png;base64,AA==',
          'width': 20,
          'height': 20,
        });
    PMNode hardBreak() => schema.node('hardBreak', {'breakType': null}, null);
    PMNode opaque() => schema.node('opaqueInline', {
          'insert': {'qname': 'w:bookmarkStart', 'officeXml': '<w:x/>'}
        });
    PMNode textBox() => schema.node('textBox', {
          'text': 'texto visual que não pertence ao fluxo',
          'width': 400,
          'height': 200,
          'offsetX': 0,
          'offsetY': 0,
        });

    final cases = <({String name, PMNode Function() atom, String selector})>[
      (name: 'imagem', atom: image, selector: '.dq-office-image'),
      (name: 'hardBreak', atom: hardBreak, selector: '.dq-office-hard-break'),
      (
        name: 'opaqueInline',
        atom: opaque,
        selector: '.dq-office-opaque-inline'
      ),
      (name: 'textBox', atom: textBox, selector: '.dq-office-text-box-anchor'),
    ];

    for (final atomCase in cases) {
      test('${atomCase.name}: texto + atom + texto é bidirecional', () {
        final block = schema.node(
          'paragraph',
          null,
          Fragment.from([
            schema.text('A'),
            atomCase.atom(),
            schema.text('B'),
          ]),
        );
        project(docOf([block]));

        // Conteúdo do parágrafo: A(1), atom(1), B(1). Todas as quatro
        // fronteiras de caret precisam fazer round-trip.
        for (var modelPosition = 1; modelPosition <= 4; modelPosition++) {
          final dom = map.domPositionFor(host, modelPosition);
          expect(dom, isNotNull,
              reason: '${atomCase.name}: posição $modelPosition sem DOM');
          expect(
            map.modelPositionAt(dom!.node, dom.offset),
            modelPosition,
            reason: '${atomCase.name}: deriva em $modelPosition',
          );
        }

        final atom = host.querySelector(atomCase.selector)!;
        expect(atom.getAttribute('data-model-length'), '1');
        final line = atom.parentNode! as DomElement;
        final atomIndex = line.childNodes.indexWhere((node) => node == atom);
        expect(atomIndex, greaterThanOrEqualTo(0));
        expect(map.modelPositionAt(line, atomIndex), 2,
            reason: 'fronteira imediatamente antes do atom');
        expect(map.modelPositionAt(line, atomIndex + 1), 3,
            reason: 'fronteira imediatamente depois do atom');
        expect(map.modelPositionAt(atom, 0), 2);
        expect(map.modelPositionAt(atom, 1), 3);

        final textAfter =
            host.querySelectorAll('.dq-office-run').last.firstChild!;
        expect(map.modelPositionAt(textAfter, 0), 3,
            reason: 'o texto posterior não pode perder a posição do atom');
      });
    }

    test('vários atoms consecutivos mantêm cada fronteira e uma seleção', () {
      final block = schema.node(
        'paragraph',
        null,
        Fragment.from([
          schema.text('A'),
          image(),
          opaque(),
          textBox(),
          schema.text('B'),
        ]),
      );
      project(docOf([block]));

      // A + 3 atoms + B = cinco unidades, seis posições de caret.
      for (var modelPosition = 1; modelPosition <= 6; modelPosition++) {
        final dom = map.domPositionFor(host, modelPosition)!;
        expect(map.modelPositionAt(dom.node, dom.offset), modelPosition,
            reason: 'round-trip falhou entre atoms em $modelPosition');
      }

      final selectionFrom = map.domPositionFor(host, 2)!;
      final selectionTo = map.domPositionFor(host, 5)!;
      expect(map.modelPositionAt(selectionFrom.node, selectionFrom.offset), 2);
      expect(map.modelPositionAt(selectionTo.node, selectionTo.offset), 5);

      final line = host.querySelector('.dq-office-line')!;
      final atomIndexes = <int>[
        for (var i = 0; i < line.childNodes.length; i++)
          if (line.childNodes[i] is DomElement &&
              (line.childNodes[i] as DomElement)
                      .getAttribute('data-model-length') ==
                  '1')
            i,
      ];
      expect(atomIndexes, hasLength(3));
      for (var i = 0; i < atomIndexes.length; i++) {
        expect(map.modelPositionAt(line, atomIndexes[i]), 2 + i);
        expect(map.modelPositionAt(line, atomIndexes[i] + 1), 3 + i);
      }
    });
  });

  group('âncoras auxiliares', () {
    test('nodeIdOf devolve o id estável do bloco', () {
      final block = schema.node(
          'paragraph', {'id': 'p-7'}, Fragment.from([schema.text('texto')]));
      project(docOf([block]));
      final position = map.domPositionFor(host, 1)!;
      expect(map.nodeIdOf(position.node), 'p-7');
    });

    test('pageIndexOf devolve o índice da página do ponto', () {
      project(docOf([paragraph('x')]));
      final position = map.domPositionFor(host, 1)!;
      expect(map.pageIndexOf(position.node), 0);
    });
  });
}
