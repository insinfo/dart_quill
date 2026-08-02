@TestOn('browser')
library office_dom_position_map_test;

/// O mapa posição-do-modelo ↔ posição-no-DOM contra a SELEÇÃO NATIVA do
/// browser — o uso real dele.
///
/// Duas armadilhas históricas deste projeto vivem exatamente aqui: o
/// adaptador web cunha um wrapper NOVO a cada acesso (então `identical` e
/// cast de nó passam no fake DOM e falham em Chrome), e a seleção nativa
/// entrega nós de texto internos que o modelo não conhece. Se o mapa
/// estiver errado, é aqui que aparece — não na suíte VM.
///
/// O teste usa a MESMA ponte de plataforma que o editor usará
/// (`getNativeSelectionRange`, `setSelectionByNodes`, `caretRangeFromPoint`),
/// não interop cru: assim ele exercita o caminho de produção.
import 'package:dart_quill/dart_quill_office.dart';
import 'package:dart_quill/src/platform/dom.dart';
import 'package:dart_quill/src/platform/platform.dart';
import 'package:test/test.dart';

void main() {
  final schema = officeQuillSchema();
  const map = OfficeDomPositionMap();
  final adapter = domBindings.adapter;

  late DomElement host;

  setUp(() {
    host = adapter.document.createElement('div');
    adapter.document.body.append(host);
  });

  tearDown(() => host.remove());

  PMNode docOf(List<PMNode> blocks) =>
      schema.node('doc', null, Fragment.from(blocks));

  PMNode paragraph(String text) =>
      schema.node('paragraph', null, Fragment.from([schema.text(text)]));

  PageGraph project(PMNode doc, {PageWindow? window}) {
    final graph = LayoutComposer().compose(doc);
    PageGraphDomRenderer(document: adapter.document, editable: true)
        .render(graph, host, window: window);
    return graph;
  }

  test('a posição do modelo vira caret nativo no lugar certo', () {
    project(docOf([paragraph('alpha beta gama')]));

    final position = map.domPositionFor(host, 1 + 6)!; // depois de "alpha "
    adapter.setSelectionByNodes(
        position.node, position.offset, position.node, position.offset);

    final native = adapter.getNativeSelectionRange();
    expect(native, isNotNull);
    expect(native!.startOffset, 6);
    expect(native.startContainer.textContent, startsWith('alpha'));
  });

  test('a seleção nativa do usuário vira posição do modelo', () {
    project(docOf([paragraph('alpha beta gama')]));

    // Simula o caret que o browser entrega: nó de TEXTO interno ao run.
    final run = host.querySelector('.dq-office-run')!;
    final textNode = run.firstChild!;
    adapter.setSelectionByNodes(textNode, 11, textNode, 11); // em "gama"

    final native = adapter.getNativeSelectionRange()!;
    expect(map.modelPositionAt(native.startContainer, native.startOffset),
        1 + 11,
        reason: 'ler a seleção nativa tem de dar a posição do modelo');
  });

  test('round-trip com a seleção nativa no meio do caminho', () {
    project(docOf([
      paragraph('primeiro parágrafo com bastante texto para exercitar '
          'o mapeamento em mais de uma linha composta'),
      paragraph('segundo parágrafo'),
    ]));

    var checked = 0;
    for (final modelPosition in [1, 5, 20, 60, 90]) {
      final position = map.domPositionFor(host, modelPosition);
      if (position == null) continue;
      adapter.setSelectionByNodes(
          position.node, position.offset, position.node, position.offset);

      final native = adapter.getNativeSelectionRange()!;
      expect(map.modelPositionAt(native.startContainer, native.startOffset),
          modelPosition,
          reason: 'round-trip via seleção NATIVA falhou em $modelPosition');
      checked++;
    }
    expect(checked, greaterThan(3));
  });

  test('o caret sabe em que página está, e a geometria concorda', () {
    final blocks = [
      for (var i = 0; i < 200; i++) paragraph('Parágrafo $i do documento.')
    ];
    final graph = project(docOf(blocks));
    expect(graph.pages.length, greaterThan(1));

    final onSecondPage =
        graph.positionMap.entries.firstWhere((e) => e.pageIndex == 1);
    final position = map.domPositionFor(host, onSecondPage.docPosStart)!;
    expect(map.pageIndexOf(position.node), 1);

    // E a página 1 está mesmo ABAIXO da 0 no viewport — o mapa e a
    // geometria contam a mesma história.
    final pages = host.querySelectorAll('.dq-office-page');
    final top0 = adapter.getElementBounds(pages[0])!['top'] as num;
    final top1 = adapter.getElementBounds(pages[1])!['top'] as num;
    expect(top1, greaterThan(top0));
  });

  test('hit-testing: o ponto onde o usuário clica vira posição do modelo',
      () {
    project(docOf([paragraph('alvo do clique no meio da linha')]));

    final run = host.querySelector('.dq-office-run')!;
    final box = adapter.getElementBounds(run)!;
    final caret = adapter.caretRangeFromPoint(
        (box['left'] as num) + (box['width'] as num) / 2,
        (box['top'] as num) + (box['height'] as num) / 2);
    expect(caret, isNotNull,
        reason: 'o browser precisa achar um caret dentro da projeção');

    final modelPosition =
        map.modelPositionAt(caret!.startContainer, caret.startOffset);
    expect(modelPosition, isNotNull);
    expect(modelPosition!, greaterThan(1));
    expect(modelPosition, lessThanOrEqualTo(1 + 31));
  });
}
