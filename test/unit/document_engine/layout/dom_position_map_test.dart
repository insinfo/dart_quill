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

  PageGraph project(PMNode doc, {PageWindow? window}) {
    final graph = LayoutComposer().compose(doc);
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

    test('posição em página NÃO montada devolve null (contrato da janela)',
        () {
      final blocks = [
        for (var i = 0; i < 200; i++) paragraph('Parágrafo $i do documento.')
      ];
      final graph =
          project(docOf(blocks), window: const PageWindow(firstPage: 0, lastPage: 0));
      expect(graph.pages.length, greaterThan(1));

      final onSecondPage = graph.positionMap.entries
          .firstWhere((e) => e.pageIndex == 1)
          .docPosStart;
      expect(map.domPositionFor(host, onSecondPage), isNull,
          reason: 'o chamador monta a janela e tenta de novo');
      expect(map.domPositionFor(host, 1), isNotNull,
          reason: 'a página montada continua respondendo');
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

  group('âncoras auxiliares', () {
    test('nodeIdOf devolve o id estável do bloco', () {
      final block = schema.node('paragraph', {'id': 'p-7'},
          Fragment.from([schema.text('texto')]));
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
