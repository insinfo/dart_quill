@TestOn('vm')
library;

import 'dart:typed_data';

import 'package:dart_quill/dart_quill_office.dart';
import 'package:test/test.dart';

import '../../../support/pdf_reader.dart';

/// PNG RGBA 1×1 vermelho.
const _pngDataUrl = 'data:image/png;base64,'
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8'
    'z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';

/// JPEG RGB 2×1 (vermelho/azul), pequeno mas completo o bastante para que
/// leitores reais validem o stream DCT em vez de apenas o nosso decoder.
const _jpegDataUrl = 'data:image/jpeg;base64,'
    '/9j/4AAQSkZJRgABAQEAYABgAAD/2wBDAAMCAgMCAgMDAwMEAwMEBQgFBQQEBQoH'
    'BwYIDAoMDAsKCwsNDhIQDQ4RDgsLEBYQERMUFRUVDA8XGBYUGBIUFRT/2wBDAQME'
    'BAUEBQkFBQkUDQsNFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQU'
    'FBQUFBQUFBQUFBQUFBQUFBT/wAARCAABAAIDASIAAhEBAxEB/8QAHwAAAQUBAQEB'
    'AQEAAAAAAAAAAAECAwQFBgcICQoL/8QAtRAAAgEDAwIEAwUFBAQAAAF9AQIDAAQR'
    'BRIhMUEGE1FhByJxFDKBkaEII0KxwRVS0fAkM2JyggkKFhcYGRolJicoKSo0NTY3'
    'ODk6Q0RFRkdISUpTVFVWV1hZWmNkZWZnaGlqc3R1dnd4eXqDhIWGh4iJipKTlJWW'
    'l5iZmqKjpKWmp6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uHi4+Tl5ufo'
    '6erx8vP09fb3+Pn6/8QAHwEAAwEBAQEBAQEBAQAAAAAAAAECAwQFBgcICQoL/8QA'
    'tREAAgECBAQDBAcFBAQAAQJ3AAECAxEEBSExBhJBUQdhcRMiMoEIFEKRobHBCSMz'
    'UvAVYnLRChYkNOEl8RcYGRomJygpKjU2Nzg5OkNERUZHSElKU1RVVldYWVpjZGVm'
    'Z2hpanN0dXZ3eHl6goOEhYaHiImKkpOUlZaXmJmaoqOkpaanqKmqsrO0tba3uLm6'
    'wsPExcbHyMnK0tPU1dbX2Nna4uPk5ebn6Onq8vP09fb3+Pn6/9oADAMBAAIRAxEA'
    'PwD4H8Q/8h/Uv+vmX/0M0UUV/ptkP/Ipwn/XuH/pKPAzr/kZ4r/r5P8A9KZ//9k=';

const _style = ResolvedRunStyle(family: 'Arial', sizePt: 12);
const _setup = PageSetupTwips(
  widthTwips: 4000,
  heightTwips: 3000,
  marginTopTwips: 300,
  marginRightTwips: 200,
  marginBottomTwips: 300,
  marginLeftTwips: 200,
  headerDistanceTwips: 100,
  footerDistanceTwips: 100,
);

LineSegment _imageSegment(String source, {int width = 800, int height = 300}) =>
    LineSegment(
      text: '\uFFFC',
      style: _style,
      widthTwips: width,
      imageSrc: source,
      imageHeightTwips: height,
    );

BlockFragment _imageBlock(
  String source, {
  int docPos = 0,
  int yTwips = 0,
  int width = 800,
  int height = 300,
  int spaceBeforeTwips = 0,
}) =>
    BlockFragment(
      nodeId: 'image-$docPos-$yTwips',
      docPos: docPos,
      kind: 'paragraph',
      yTwips: yTwips,
      heightTwips: 600 + spaceBeforeTwips,
      spaceBeforeTwips: spaceBeforeTwips,
      lines: [
        LineBox(
          segments: [_imageSegment(source, width: width, height: height)],
          widthTwips: width,
          ascentTwips: 240,
          heightTwips: 600,
          charStart: 0,
          charEnd: 1,
        ),
      ],
    );

BlockFragment _textBoxBlock({
  String text = 'OVERLAY',
  int docPos = -1,
  int yTwips = 0,
}) =>
    BlockFragment(
      nodeId: 'text-box-$docPos-$yTwips',
      docPos: docPos,
      kind: 'paragraph',
      yTwips: yTwips,
      heightTwips: 500,
      lines: [
        LineBox(
          segments: [
            LineSegment(
              text: '',
              style: _style,
              widthTwips: 0,
              textBox: FloatingTextBoxLayout(
                text: text,
                widthTwips: 1400,
                heightTwips: 400,
                positionHAlign: 'right',
                borderWidthTwips: 20,
                borderColor: '#000000',
              ),
            ),
          ],
          widthTwips: 0,
          ascentTwips: 240,
          heightTwips: 500,
          charStart: 0,
          charEnd: 1,
        ),
      ],
    );

PageSignature _signature(int page) => PageSignature(
      firstBlockIndex: page,
      firstBlockOffset: page,
      carryListOrdinal: 0,
      suppressSpaceBeforeAtPageTop: false,
      startsFreshBlock: true,
      lastDocPos: page + 1,
    );

PageGraph _graph(List<PageLayout> pages) => PageGraph(
      pages: pages,
      positionMap: PositionMap(const []),
      diagnostics: LayoutDiagnostics(),
      quality: LayoutQuality.fidelity,
    );

void _expectValidPdf(Uint8List bytes, int pageCount) {
  final reader = PdfReader(bytes);
  expect(reader.header, '%PDF-1.4');
  expect(reader.endsWithEof, isTrue);
  expect(reader.hasTrailerRoot, isTrue);
  expect(reader.pageCount, pageCount);
  expect(reader.xrefOffsets, isNotEmpty);
  for (final offset in reader.xrefOffsets) {
    expect(reader.objectHeaderAt(offset), isNotNull,
        reason: 'xref deve apontar para um objeto PDF real em $offset');
  }
}

void main() {
  test('PNG vira XObject na posição/tamanho do LineSegment, nunca U+FFFC', () {
    final graph = _graph([
      PageLayout(
        index: 0,
        setup: _setup,
        fragments: [
          _imageBlock(
            _pngDataUrl,
            yTwips: 100,
            width: 800,
            height: 300,
            spaceBeforeTwips: 40,
          ),
        ],
        signature: _signature(0),
      ),
    ]);

    final bytes = PageGraphPdfRenderer().render(graph);
    _expectValidPdf(bytes, 1);

    final reader = PdfReader(bytes);
    expect(reader.rawLatin1, contains('/Subtype /Image'));
    expect(reader.rawLatin1, contains('/SMask'));
    expect(reader.rawLatin1, contains('/XObject <<'));
    final content = reader.decodedStreams.join('\n');
    expect(content, contains('/Im'));
    expect(content, contains(' Do'));
    // 800×300 twips = 40×15 pt; a LineBox tem 30 pt e começa em y=22,
    // portanto vertical-align:middle põe a imagem em y=29,5 e a matriz PDF
    // termina em 150-(29,5+15)=105,5.
    expect(content, matches(RegExp(r'40 0 0 15 10 105\.5 cm\s*/Im\d+ Do')));
    expect(reader.extractText(), isEmpty,
        reason: 'U+FFFC é offset lógico, não texto visível no PDF');
  });

  test('JPEG repetido em header e corpo é deduplicado em sync e async',
      () async {
    final header = [_imageBlock(_jpegDataUrl, docPos: -1, width: 600)];
    final pages = [
      for (var page = 0; page < 4; page++)
        PageLayout(
          index: page,
          setup: _setup,
          fragments: page == 0
              ? [_imageBlock(_jpegDataUrl, yTwips: 500, width: 1000)]
              : const [],
          header: header,
          signature: _signature(page),
        ),
    ];
    final graph = _graph(pages);
    final renderer = PageGraphPdfRenderer(title: 'imagens deduplicadas');

    final synchronous = renderer.render(graph);
    final asynchronous = await renderer.renderAsync(
      graph,
      workBudget: Duration.zero,
    );

    expect(asynchronous, synchronous,
        reason: 'cache de imagem não pode vazar ids entre renderizações');
    _expectValidPdf(synchronous, pages.length);
    final reader = PdfReader(synchronous);
    expect(RegExp(r'/Filter /DCTDecode').allMatches(reader.rawLatin1),
        hasLength(1),
        reason: 'a mesma data URI JPEG deve gerar um único stream de imagem');
    expect(RegExp(r'/XObject <<').allMatches(reader.rawLatin1),
        hasLength(pages.length),
        reason: 'cada página deve registrar o XObject usado no header');

    final resourceNames = RegExp(r'/Im\d+')
        .allMatches(reader.rawLatin1)
        .map((match) => match.group(0))
        .toSet();
    expect(resourceNames, hasLength(1));
    final draws = RegExp(r'/Im\d+ Do')
        .allMatches(reader.decodedStreams.join('\n'))
        .length;
    expect(draws, pages.length + 1,
        reason: 'um header por página e a mesma imagem uma vez no corpo');
    expect(reader.extractText(), isEmpty,
        reason: 'nenhuma das cinco imagens pode virar placeholder textual');
  });

  test('textBox flutuante é pintada após imagem opaca do timbre', () {
    final graph = _graph([
      PageLayout(
        index: 0,
        setup: _setup,
        fragments: const [],
        header: [
          _textBoxBlock(text: 'OVERLAY'),
          _imageBlock(_pngDataUrl, docPos: -2, width: 3600, height: 500),
        ],
        signature: _signature(0),
      ),
    ]);

    final bytes = PageGraphPdfRenderer().render(graph);
    _expectValidPdf(bytes, 1);
    final content = PdfReader(bytes).decodedStreams.join('\n');
    final imagePaint = content.indexOf(' Do');
    final textBoxBorder = content.lastIndexOf(' re S');
    final textBoxText = content.indexOf('(OVERLAY) Tj');

    expect(imagePaint, greaterThanOrEqualTo(0));
    expect(textBoxBorder, greaterThan(imagePaint),
        reason: 'a borda com z-index deve sobreviver à imagem posterior');
    expect(textBoxText, greaterThan(imagePaint),
        reason: 'o texto completo deve ser o overlay final da página');
    expect(PdfReader(bytes).extractText(), contains('OVERLAY'));
  });

  test('preenchimento automático de DOCX não vira retângulo preto', () {
    const noBorders = TableCellBorders();
    final table = TableFragment(
      nodeId: 'table',
      docPos: 0,
      docPosEnd: 2,
      sourceTableId: 'table',
      yTwips: 200,
      heightTwips: 500,
      rows: const [
        TableRowBox(
          heightTwips: 500,
          cells: [
            TableCellBox(
              xTwips: 0,
              widthTwips: 1000,
              blocks: [],
              contentHeightTwips: 0,
              heightTwips: 500,
              backgroundColor: '#auto',
              borders: noBorders,
            ),
            TableCellBox(
              xTwips: 1000,
              widthTwips: 1000,
              blocks: [],
              contentHeightTwips: 0,
              heightTwips: 500,
              backgroundColor: '#F0E0D0',
              borders: noBorders,
            ),
          ],
        ),
      ],
    );
    final graph = _graph([
      PageLayout(
        index: 0,
        setup: _setup,
        fragments: [table],
        signature: _signature(0),
      ),
    ]);

    final bytes = PageGraphPdfRenderer().render(graph);
    _expectValidPdf(bytes, 1);
    final content = PdfReader(bytes).decodedStreams.join('\n');
    expect(RegExp(r' re f').allMatches(content), hasLength(1),
        reason: 'só a cor hexadecimal real deve preencher uma célula');
    expect(content, isNot(contains('0 0 0 rg')),
        reason: '`w:fill="auto"` significa sem fundo, não preto');
  });
}
