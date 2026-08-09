@TestOn('vm')
library;

import 'package:dart_quill/dart_quill_office.dart';
import 'package:dart_quill/src/platform/dom.dart';
import 'package:test/test.dart';

import '../../../support/fake_dom.dart';
import '../../../support/pdf_reader.dart';

void main() {
  final schema = officeQuillSchema();

  PMNode docOf(PMNode block) =>
      schema.node('doc', null, Fragment.from([block]));

  PMNode paragraph(
    List<PMNode> content, {
    Map<String, Object?>? style,
  }) =>
      schema.node('paragraph', {if (style != null) 'style': style},
          Fragment.from(content));

  BlockFragment blockOf(PMNode block, {LayoutComposer? composer}) =>
      ((composer ?? LayoutComposer())
          .compose(docOf(block))
          .pages
          .single
          .fragments
          .single as BlockFragment);

  ({FakeDomDocument document, DomElement host}) render(PageGraph graph) {
    final document = FakeDomDocument();
    final host = document.createElement('div');
    document.body.append(host);
    PageGraphDomRenderer(document: document, editable: true)
        .render(graph, host);
    return (document: document, host: host);
  }

  group('letterSpacing Word', () {
    PMNode withSpacing(int twips) => paragraph([
          schema.text('AB', [
            schema.marks['letterSpacing']!.create({'twips': twips}),
          ]),
        ]);

    test('valor assinado participa da medição, quebra e cache', () {
      final composer = LayoutComposer();
      final plain = blockOf(paragraph([schema.text('AB')]));
      final positive = blockOf(withSpacing(20), composer: composer);
      final negative = blockOf(withSpacing(-10), composer: composer);
      final zero = blockOf(withSpacing(0), composer: composer);

      expect(
          positive.lines.single.widthTwips, plain.lines.single.widthTwips + 40,
          reason: '20 twips são acrescentados depois de cada um dos 2 chars');
      expect(
          negative.lines.single.widthTwips, plain.lines.single.widthTwips - 20,
          reason: '-10 twips por caractere não pode ser descartado');
      expect(
          positive.lines.single.segments.single.style.letterSpacingTwips, 20);
      expect(
          negative.lines.single.segments.single.style.letterSpacingTwips, -10);
      expect(zero.lines.single.segments.single.style.letterSpacingTwips, 0);
      expect(composer.measurementCacheSize, 3,
          reason: 'o espaçamento faz parte da chave de medição');
    });

    test('DOM emite CSS inclusive para negativo/zero e PDF espaça glifos', () {
      String cssFor(int twips) {
        final graph = LayoutComposer().compose(docOf(withSpacing(twips)));
        final projected = render(graph);
        return projected.host
            .querySelector('.dq-office-run')!
            .getAttribute('style')!;
      }

      expect(cssFor(20), contains('letter-spacing:1.33px'));
      expect(cssFor(-10), contains('letter-spacing:-0.67px'));
      expect(cssFor(0), contains('letter-spacing:0px'));

      final graph = LayoutComposer().compose(docOf(withSpacing(20)));
      final streams = PdfReader(PageGraphPdfRenderer().render(graph))
          .decodedStreams
          .join('\n');
      expect(streams, contains('1 Tc'),
          reason: '20 twips equivalem a 1 pt de character spacing no PDF');
      expect(streams, contains('(AB) Tj'),
          reason: 'Tc aplica o espaçamento sem fragmentar texto pesquisável');
      expect(PdfReader(PageGraphPdfRenderer().render(graph)).extractText(),
          contains('AB'));
    });
  });

  group('tab stops Word', () {
    PMNode tabbed({
      int indentTwips = 100,
      List<Map<String, Object?>> tabs = const [],
      String text = '\tX',
    }) =>
        paragraph([
          schema.text(text)
        ], style: {
          'indentTwips': indentTwips,
          if (tabs.isNotEmpty) 'tabs': tabs,
        });

    test('tab inicial não colapsa e usa stop explícito relativo ao recuo', () {
      final block = blockOf(tabbed(tabs: const [
        {'val': 'left', 'posTwips': 500, 'leader': 'underscore'},
      ]));
      final line = block.lines.single;
      final tab = line.segments.first;

      expect(tab.isTab, isTrue);
      expect(tab.text, '\t');
      expect(tab.widthTwips, 400,
          reason: 'stop 500 - recuo esquerdo 100 = avanço 400');
      expect(tab.tabLeader, 'underscore');
      expect(line.charStart, 0);
      expect(line.charEnd, 2);

      final graph = LayoutComposer().compose(docOf(tabbed(tabs: const [
        {'val': 'left', 'posTwips': 500, 'leader': 'underscore'},
      ])));
      final projected = render(graph);
      final element = projected.host.querySelector('.dq-office-tab')!;
      expect(element.textContent, '\t');
      expect(element.getAttribute('data-model-length'), '1');
      expect(element.getAttribute('data-leader'), 'underscore');
      expect(
          element.getAttribute('style'),
          allOf(
              contains('width:26.67px'), contains('border-bottom:1px solid')));

      final pdf = PdfReader(PageGraphPdfRenderer().render(graph));
      expect(pdf.extractText(), contains('X'));
      expect(pdf.extractText(), isNot(contains('\t')),
          reason: 'tab é avanço e leader, não um glifo no PDF');
    });

    test('sem stop explícito usa o default Word de 708 twips', () {
      final line = blockOf(tabbed()).lines.single;
      expect(line.segments.first.isTab, isTrue);
      expect(line.segments.first.widthTwips, 608,
          reason: '708 twips desde a margem menos recuo 100');
    });

    test('stop personalizado distante substitui os defaults anteriores', () {
      final line = blockOf(tabbed(
        indentTwips: 0,
        tabs: const [
          {'val': 'center', 'posTwips': 4252},
          {'val': 'right', 'posTwips': 8504},
        ],
        text: '\t\tPágina 19 | 19',
      )).lines.single;
      final first = line.segments.where((segment) => segment.isTab).first;
      final second = line.segments.where((segment) => segment.isTab).last;

      expect(first.widthTwips, 4252,
          reason: 'não pode parar no tab default de 708 twips');
      expect(line.widthTwips, 8504,
          reason: 'TAB right alinha a borda do texto ao stop de 8504');
      expect(second.widthTwips, greaterThan(0));
    });

    test('center/right/decimal usam lookahead até o próximo tab', () {
      LineBox lineFor(String val, String following) => blockOf(tabbed(
            indentTwips: 0,
            tabs: [
              {'val': val, 'posTwips': 500},
            ],
            text: '\t$following',
          )).lines.single;

      final center = lineFor('center', 'AB');
      final centerTail = center.segments
          .skip(1)
          .fold<int>(0, (width, segment) => width + segment.widthTwips);
      expect(center.segments.first.widthTwips + centerTail ~/ 2, 500);

      final right = lineFor('right', 'AB');
      final rightTail = right.segments
          .skip(1)
          .fold<int>(0, (width, segment) => width + segment.widthTwips);
      expect(right.segments.first.widthTwips + rightTail, 500);

      final decimal = lineFor('decimal', '12,34');
      final prefix =
          blockOf(paragraph([schema.text('12')])).lines.single.widthTwips;
      expect(decimal.segments.first.widthTwips + prefix, 500);
    });
  });

  group('inline OOXML sem fluxo', () {
    PMNode opaque() => schema.node('opaqueInline', {
          'insert': {
            'qname': 'w:bookmarkStart',
            'officeXml': '<w:bookmarkStart w:id="0"/>',
          },
        });

    PMNode textBox() => schema.node('textBox', {
          'text': 'Caixa flutuante',
          'width': 600,
          'height': 300,
          'offsetX': 40,
          'offsetY': -20,
          'positionHAlign': 'right',
          'positionVRelativeFrom': 'paragraph',
          'borderWidth': 30,
          'borderColor': '#123456',
          'background': '#FEDCBA',
        });

    PMNode richTextBox() {
      final underline = schema.marks['underline']!.create();
      final size10 = schema.marks['size']!.create({'value': '10pt'});
      final bold = schema.marks['bold']!.create();
      final textBoxDoc = schema.node(
          'doc',
          null,
          Fragment.from([
            paragraph(
              [
                schema.text('Continuação de Processo', [underline, size10])
              ],
              style: const {'align': 'center'},
            ),
            paragraph([
              schema.text('Processo nº '),
              schema.text('44505', [bold]),
              schema.text('/2025', [bold]),
            ]),
            paragraph([schema.text('Folha __________________')]),
            paragraph([schema.text('Rubrica _________________')]),
          ]));
      return schema.node('textBox', {
        'text': 'fallback que não deve ser usado',
        'textBoxDoc': textBoxDoc.toJSON(),
        'textBoxSourceSignature': OfficeDocxCodec.nodeSignature(textBoxDoc),
        'width': 2610,
        'height': 1185,
        'insetLeft': 144,
        'insetTop': 72,
        'insetRight': 144,
        'insetBottom': 72,
        'positionHAlign': 'right',
        'positionVRelativeFrom': 'paragraph',
        'borderWidth': 15,
        'borderColor': '#000000',
      });
    }

    test('opaqueInline é invisível, zero-width e não gera warning/glifo', () {
      final graph = LayoutComposer().compose(docOf(paragraph([
        schema.text('A'),
        opaque(),
        schema.text('B'),
      ])));
      final line =
          (graph.pages.single.fragments.single as BlockFragment).lines.single;
      final opaqueSegment =
          line.segments.singleWhere((segment) => segment.isOpaqueInline);

      expect(opaqueSegment.widthTwips, 0);
      expect(opaqueSegment.text, isEmpty);
      expect(line.charEnd, 3, reason: 'o atom ainda ocupa uma posição PM');
      expect(graph.diagnostics.warnings, isEmpty);
      expect(line.segments.map((segment) => segment.text).join(),
          isNot(contains('\uFFFC')));

      final projected = render(graph);
      final hidden = projected.host.querySelector('.dq-office-opaque-inline')!;
      expect(hidden.textContent ?? '', isEmpty);
      expect(hidden.getAttribute('style'), contains('display:none'));
      expect(hidden.getAttribute('contenteditable'), 'false');
      expect(projected.host.textContent, 'AB');

      final pdf = PdfReader(PageGraphPdfRenderer().render(graph));
      expect(pdf.extractText(), contains('AB'));
      expect(pdf.decodedStreams.join('\n'), isNot(contains('\uFFFC')));
    });

    test('textBox vira metadado flutuante sem alterar wrap/altura', () {
      final withBoxGraph = LayoutComposer().compose(docOf(paragraph([
        schema.text('A'),
        textBox(),
        schema.text('B'),
      ])));
      final referenceGraph = LayoutComposer().compose(docOf(paragraph([
        schema.text('A'),
        opaque(),
        schema.text('B'),
      ])));
      final withBox =
          (withBoxGraph.pages.single.fragments.single as BlockFragment)
              .lines
              .single;
      final reference =
          (referenceGraph.pages.single.fragments.single as BlockFragment)
              .lines
              .single;
      final segment =
          withBox.segments.singleWhere((segment) => segment.textBox != null);

      expect(segment.widthTwips, 0);
      expect(withBox.widthTwips, reference.widthTwips);
      expect(withBox.heightTwips, reference.heightTwips);
      expect(withBox.charEnd, 3);
      expect(segment.textBox!.text, 'Caixa flutuante');
      expect(segment.textBox!.widthTwips, 600);
      expect(segment.textBox!.heightTwips, 300);
      expect(segment.textBox!.offsetXTwips, 40);
      expect(segment.textBox!.offsetYTwips, -20);
      expect(segment.textBox!.positionHAlign, 'right');
      expect(segment.textBox!.positionVRelativeFrom, 'paragraph');
      expect(withBoxGraph.diagnostics.warnings, isEmpty);

      final projected = render(withBoxGraph);
      final box = projected.host.querySelector('.dq-office-text-box')!;
      final boxStyle = box.getAttribute('style')!;
      expect(box.getAttribute('contenteditable'), 'false');
      expect(box.getAttribute('data-position-h-align'), 'right');
      expect(box.textContent, 'Caixa flutuante');
      expect(
          boxStyle,
          allOf(
            contains('position:absolute'),
            contains('width:40px'),
            contains('height:20px'),
            contains('background:#FEDCBA'),
            contains('border:2px solid #123456'),
          ));
      expect(projected.host.querySelector('.dq-office-line')!.textContent, 'AB',
          reason: 'texto da caixa fica fora do fluxo editável da linha');

      final pdf = PdfReader(PageGraphPdfRenderer().render(withBoxGraph));
      expect(pdf.extractText(),
          allOf(contains('A'), contains('Caixa flutuante'), contains('B')));
      final streams = pdf.decodedStreams.join('\n');
      expect(streams, contains(' re f'));
      expect(streams, contains(' re S'));
    });

    test('textBox rico usa os mesmos quatro blocos no DOM e no PDF', () async {
      final graph = LayoutComposer().compose(docOf(paragraph([
        schema.text('A'),
        richTextBox(),
        schema.text('B'),
      ])));
      final outer = graph.pages.single.fragments.single as BlockFragment;
      final line = outer.lines.single;
      final segment =
          line.segments.singleWhere((segment) => segment.textBox != null);
      final box = segment.textBox!;

      expect(segment.widthTwips, 0);
      expect(line.charEnd, 3,
          reason: 'a árvore interna não pode consumir offsets do documento');
      expect(box.contentBlocks, hasLength(4));
      expect(box.insetLeftTwips, 144);
      expect(box.insetTopTwips, 72);
      expect(box.insetRightTwips, 144);
      expect(box.insetBottomTwips, 72);
      expect(box.contentBlocks.first.align, LayoutAlign.center);
      final titleRun = box.contentBlocks.first.lines.single.segments.single;
      expect(titleRun.text, 'Continuação de Processo');
      expect(titleRun.style.sizePt, 10);
      expect(titleRun.style.underline, isTrue);
      final processRuns = box.contentBlocks[1].lines
          .expand((line) => line.segments)
          .toList(growable: false);
      expect(processRuns.first.style.bold, isFalse);
      expect(
        processRuns
            .where((run) => run.style.bold)
            .map((run) => run.text)
            .join(),
        '44505/2025',
      );
      expect(graph.diagnostics.warnings, isEmpty);

      final projected = render(graph);
      final boxElement = projected.host.querySelector('.dq-office-text-box')!;
      final content = boxElement.querySelector('.dq-office-text-box-content')!;
      final blocks = content.querySelectorAll('.dq-office-block');
      expect(boxElement.getAttribute('contenteditable'), 'false');
      expect(blocks, hasLength(4));
      expect(
          blocks.every((block) => !block.hasAttribute('data-doc-pos')), isTrue,
          reason: 'a cópia visual interna não entra no PositionMap');
      expect(
          content.getAttribute('style'),
          allOf(
            contains('left:9.6px'),
            contains('top:4.8px'),
          ));
      final nestedLines = content.querySelectorAll('.dq-office-line');
      expect(nestedLines.first.getAttribute('style'),
          contains('text-align:center'));
      final nestedRuns = content.querySelectorAll('.dq-office-run');
      expect(
        nestedRuns.first.getAttribute('style'),
        allOf(contains('font-size:13.33px'),
            contains('text-decoration:underline')),
      );
      expect(
        nestedRuns.any((run) =>
            run.textContent == '44505/2025' &&
            run.getAttribute('style')!.contains('font-weight:bold')),
        isTrue,
      );
      final anchor =
          projected.host.querySelector('.dq-office-text-box-anchor')!;
      expect(anchor.parentNode!.textContent, 'AB',
          reason: 'somente o atom oculto pertence à linha editável externa');

      final renderer = PageGraphPdfRenderer();
      final synchronous = renderer.render(graph);
      final asynchronous = await renderer.renderAsync(
        graph,
        workBudget: Duration.zero,
      );
      expect(asynchronous, synchronous);
      final pdf = PdfReader(synchronous);
      final text = pdf.extractText();
      expect(text, contains('Continuação de Processo'));
      expect(text, contains('Processo nº '));
      expect(text, contains('44505/2025'));
      expect(text, isNot(contains('fallback que não deve ser usado')));
      expect(pdf.rawLatin1, contains('/BaseFont /Helvetica-Bold'));
      final streams = pdf.decodedStreams.join('\n');
      expect(streams, matches(RegExp(r'/F\d+ 10 Tf')),
          reason: 'w:sz=20 deve chegar ao PDF como fonte de 10pt');
      final title = streams.indexOf('(Continua');
      expect(title, greaterThanOrEqualTo(0));
      expect(streams.indexOf(' l S', title), greaterThan(title),
          reason: 'o underline interno deve ser desenhado depois do run');
    });
  });
}
