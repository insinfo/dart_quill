@TestOn('browser')
library office_dom_renderer_test;

/// O DOMRenderer do modo Office contra um DOM de browser REAL.
///
/// Esta é a classe de código que já enganou o projeto antes: o fake DOM
/// devolve os mesmos objetos e aceita coisas que o browser recusa, então
/// uma projeção "verde em VM" pode nascer morta em Chrome. Aqui o gate é
/// medido pelo próprio browser — geometria por `getBoundingClientRect`,
/// não por string de style.
import 'package:dart_quill/dart_quill_office.dart';
import 'package:dart_quill/src/platform/html_dom.dart';
import 'package:test/test.dart';
import 'package:web/web.dart' as web;

void main() {
  final schema = officeQuillSchema();

  late web.HTMLElement hostElement;

  setUp(() {
    hostElement = web.document.createElement('div') as web.HTMLElement;
    web.document.body!.append(hostElement);
  });

  tearDown(() => hostElement.remove());

  PMNode docOf(List<PMNode> blocks) =>
      schema.node('doc', null, Fragment.from(blocks));

  PMNode paragraph(String text) =>
      schema.node('paragraph', null, Fragment.from([schema.text(text)]));

  PageGraphDomRenderer renderer({bool editable = false}) =>
      PageGraphDomRenderer(
        document: HtmlDomDocument(),
        editable: editable,
      );

  test('as páginas aparecem no DOM real com a geometria composta', () {
    final graph = LayoutComposer().compose(docOf([
      paragraph('primeira linha do documento'),
      paragraph('segunda linha do documento'),
    ]));
    renderer().render(graph, HtmlDomElement(hostElement));

    final pages = hostElement.querySelectorAll('.dq-office-page');
    expect(pages.length, graph.pages.length);

    // O browser é quem mede: a página A4 a 96/72 px/pt tem ~794x1123 px.
    final page = pages.item(0)! as web.HTMLElement;
    final box = page.getBoundingClientRect();
    expect(box.width, closeTo(793.7, 1.5));
    expect(box.height, closeTo(1122.5, 1.5));
  });

  test('as linhas empilham na ordem e no y que o grafo compôs', () {
    final graph = LayoutComposer().compose(docOf([
      paragraph('linha um'),
      paragraph('linha dois'),
      paragraph('linha tres'),
    ]));
    renderer().render(graph, HtmlDomElement(hostElement));

    final blocks = hostElement.querySelectorAll('.dq-office-block');
    expect(blocks.length, 3);
    double topOf(int i) =>
        (blocks.item(i)! as web.HTMLElement).getBoundingClientRect().top;
    expect(topOf(1), greaterThan(topOf(0)));
    expect(topOf(2), greaterThan(topOf(1)));
    expect(hostElement.textContent, contains('linha tres'));
  });

  test('contenteditable real: a superfície aceita foco e caret', () {
    final graph = LayoutComposer().compose(docOf([paragraph('editável')]));
    renderer(editable: true).render(graph, HtmlDomElement(hostElement));

    final content = hostElement.querySelector('.dq-office-page-content')!
        as web.HTMLElement;
    expect(content.isContentEditable, isTrue,
        reason: 'o browser tem de reconhecer a superfície como editável');
    content.focus();
    expect(web.document.activeElement, content);

    final selection = web.window.getSelection()!;
    final range = web.document.createRange()..selectNodeContents(content);
    selection.removeAllRanges();
    selection.addRange(range);
    expect(selection.rangeCount, 1);
    expect(selection.toString(), contains('editável'),
        reason: 'a seleção nativa enxerga o texto projetado');
  });

  test('placeholder fora da janela ocupa a mesma altura da página', () {
    final blocks = [
      for (var i = 0; i < 200; i++) paragraph('Parágrafo $i do documento.')
    ];
    final graph = LayoutComposer().compose(docOf(blocks));
    expect(graph.pages.length, greaterThan(2));

    renderer().render(graph, HtmlDomElement(hostElement),
        window: const PageWindow(firstPage: 0, lastPage: 0));

    final mounted = hostElement.querySelectorAll('.dq-office-page');
    final placeholders =
        hostElement.querySelectorAll('.dq-office-page-placeholder');
    expect(mounted.length, 1);
    expect(placeholders.length, graph.pages.length - 1);

    final pageBox =
        (mounted.item(0)! as web.HTMLElement).getBoundingClientRect();
    final placeholderBox =
        (placeholders.item(0)! as web.HTMLElement).getBoundingClientRect();
    expect(placeholderBox.height, closeTo(pageBox.height, 0.5),
        reason: 'sem isso o scroll pula ao montar/desmontar a janela');
  });

  test('o CSS do modo Office não vaza para o Quill', () {
    final graph = LayoutComposer().compose(docOf([paragraph('isolado')]));
    renderer().render(graph, HtmlDomElement(hostElement));

    expect(hostElement.querySelectorAll('.ql-editor').length, 0);
    final all = hostElement.querySelectorAll('*');
    for (var i = 0; i < all.length; i++) {
      final className = (all.item(i)! as web.Element).className;
      expect(className, isNot(contains('ql-')),
          reason: 'toda classe da projeção Office usa o prefixo próprio');
    }
  });

  test('fonte Office ausente não cai no serif padrão do browser', () {
    PMNode withFont(String text, String family) => schema.node(
          'paragraph',
          null,
          Fragment.from([
            schema.text(text, [
              schema.marks['font']!.create({'value': family}),
            ]),
          ]),
        );
    const sample = 'iiii WWWW 0123456789';
    final graph = LayoutComposer().compose(docOf([
      withFont('sem serifa', 'Ecofont_Spranq_eco_Sans'),
      withFont(sample, '__DQ_MISSING_OFFICE_FONT_9F2C__'),
      withFont(sample, 'Arial'),
    ]));
    renderer().render(graph, HtmlDomElement(hostElement));

    final runs = hostElement.querySelectorAll('.dq-office-run');
    expect(runs.length, 3);
    final run = runs.item(0)! as web.HTMLElement;
    expect(
      run.style.fontFamily.replaceAll(' ', ''),
      'Ecofont_Spranq_eco_Sans,calibri,carlito,arial,sans-serif',
    );
    final missingWidth =
        (runs.item(1)! as web.HTMLElement).getBoundingClientRect().width;
    final arialWidth =
        (runs.item(2)! as web.HTMLElement).getBoundingClientRect().width;
    expect(missingWidth, closeTo(arialWidth, 0.25),
        reason: 'fallback ausente precisa pintar com a mesma Arial medida');
  });
}
