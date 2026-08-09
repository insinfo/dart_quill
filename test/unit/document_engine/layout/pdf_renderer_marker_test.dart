@TestOn('vm')
library;

import 'package:dart_quill/dart_quill_office.dart';
import 'package:test/test.dart';

import '../../../support/pdf_reader.dart';

const _setup = PageSetupTwips(
  widthTwips: 4000,
  heightTwips: 3000,
  marginTopTwips: 300,
  marginRightTwips: 200,
  marginBottomTwips: 300,
  marginLeftTwips: 200,
);

void main() {
  test('marcador sem texto dentro de célula entra no PDF na posição Word',
      () async {
    // Caso real da primeira coluna da tabela da página 53 do TR: o número é
    // uma projeção de numbering.xml e o parágrafo PM não contém nenhum run.
    // A célula começa em 30 pt; o marcador, a 180 twips dentro dela, deve
    // aparecer em x=39 pt. O texto começaria em x=66 pt (indent 720 twips).
    const markerOnly = BlockFragment(
      nodeId: 'number-only',
      docPos: 3,
      kind: 'paragraph',
      lines: [],
      yTwips: 60,
      heightTwips: 260,
      indentTwips: 720,
      marker: '17. ',
      markerPositionTwips: 180,
      markerStyle: ResolvedRunStyle(family: 'Arial', sizePt: 10),
      spaceBeforeTwips: 20,
    );
    final graph = PageGraph(
      pages: const [
        PageLayout(
          index: 0,
          setup: _setup,
          fragments: [
            TableFragment(
              nodeId: 'table',
              docPos: 0,
              docPosEnd: 5,
              sourceTableId: 'table',
              yTwips: 100,
              heightTwips: 500,
              rows: [
                TableRowBox(
                  heightTwips: 500,
                  cells: [
                    TableCellBox(
                      xTwips: 400,
                      widthTwips: 1600,
                      blocks: [markerOnly],
                      contentHeightTwips: 300,
                      heightTwips: 500,
                      contentOffsetTwips: 40,
                    ),
                  ],
                ),
              ],
            ),
          ],
          signature: PageSignature(
            firstBlockIndex: 0,
            firstBlockOffset: 0,
            carryListOrdinal: 0,
            suppressSpaceBeforeAtPageTop: false,
            startsFreshBlock: true,
            lastDocPos: 5,
          ),
        ),
      ],
      positionMap: PositionMap(const []),
      diagnostics: LayoutDiagnostics(),
      quality: LayoutQuality.fidelity,
    );

    final renderer = PageGraphPdfRenderer(title: 'marker-only-cell');
    final synchronous = renderer.render(graph);
    final asynchronous = await renderer.renderAsync(graph);
    expect(asynchronous, synchronous,
        reason: 'o caminho cooperativo deve preservar conteúdo e posição');

    final reader = PdfReader(synchronous);
    expect(reader.extractText(), contains('17. '),
        reason: 'um parágrafo vazio ainda tem marcador visual');
    expect(
      reader.decodedStreams.join('\n'),
      matches(RegExp(r'39 [-\d.]+ Td\s*\(17\. \) Tj')),
      reason: 'markerPosition é relativo à célula, não ao recuo do texto',
    );
  });
}
