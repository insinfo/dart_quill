@TestOn('vm')
@Timeout(Duration(minutes: 45))
library;

import 'dart:io';

import 'package:dart_quill/dart_quill_office.dart';
import 'package:dart_quill/src/office/document/zip/zip_archive.dart';
import 'package:test/test.dart';

import 'support/office_e2e_app.dart';

void main() {
  late OfficeE2eApp app;
  final schema = officeQuillSchema();

  setUpAll(() async => app = await OfficeE2eApp.start());
  tearDownAll(() async => app.stop());

  void expectCompletePaper(Map<String, dynamic> evidence, int pageNumber) {
    final source = (evidence['sourceInvariant'] as Map).cast<String, dynamic>();
    final screenshot = (evidence['screenshot'] as Map).cast<String, dynamic>();
    final regions = (evidence['regions'] as Map).cast<String, dynamic>();
    final header = (regions['header'] as Map).cast<String, dynamic>();
    final footer = (regions['footer'] as Map).cast<String, dynamic>();

    expect(File(evidence['file'] as String).existsSync(), isTrue);
    expect(screenshot['width'], (source['width'] as num).round());
    expect(screenshot['height'], (source['height'] as num).round());
    expect(screenshot['topLeft'], [255, 255, 255, 255]);
    expect(screenshot['bottomLeft'], [255, 255, 255, 255]);
    expect(screenshot['maxAppGrayBandRows'], 0,
        reason: 'the canvas/app background must not replace paper pixels');
    expect(screenshot['headerInkPixels'], greaterThan(100),
        reason: 'the complete Word header must be visible in the PNG');
    expect(screenshot['footerInkPixels'], greaterThan(100),
        reason: 'the complete Word footer must be visible in the PNG');
    expect(header['height'] as num, greaterThan(75),
        reason: 'the Word header region cannot be vertically clipped');
    expect(footer['height'] as num, greaterThan(75),
        reason: 'the Word footer region cannot be vertically clipped');
    expect(screenshot['headerInkWidthSpan'] as num, greaterThan(500),
        reason: 'crest, text and right edge of the header must all survive');
    expect(screenshot['headerInkHeightSpan'] as num, greaterThan(70),
        reason: 'the header ink must cover its complete vertical design');
    expect(screenshot['footerInkWidthSpan'] as num, greaterThan(500),
        reason: 'both logos and footer text must all survive');
    expect(screenshot['footerInkHeightSpan'] as num, greaterThan(45),
        reason: 'the footer ink must cover its complete vertical design');
    expect(source['headers'], 1);
    expect(source['footers'], 1);
    expect((evidence['status'] as Map)['$pageNumber'], pageNumber);
  }

  int renderedBreakCount(File file) {
    final archive = ZipArchive.decodeBytes(file.readAsBytesSync());
    final xml = archive.readString('word/document.xml')!;
    return RegExp(r'<w:lastRenderedPageBreak\b').allMatches(xml).length;
  }

  test(
      'ETP captures the complete first and last papers outside canvas clipping',
      () async {
    await app.reload();
    await app.importDocx(
      officeEtpCorpus(),
      artifactName: 'etp-page-capture',
      captureScreenshots: false,
    );

    for (final pageNumber in const [1, 19]) {
      final evidence = await app.capturePageEvidence(
        artifactName: 'etp-page-capture',
        pageNumber: pageNumber,
      );
      expectCompletePaper(evidence, pageNumber);
    }

    final lastPage = await app.page.evaluate<Map<String, dynamic>>('''() => {
      const paper = document.querySelector('.dq-office-page[data-page="18"]');
      if (!paper) throw new Error('ETP page 19 is not mounted');
      const box = paper.querySelector('.dq-office-text-box');
      const content = box?.querySelector('.dq-office-text-box-content');
      const boxStyle = box ? getComputedStyle(box) : null;
      const contentStyle = content ? getComputedStyle(content) : null;
      const blocks = [...(content?.querySelectorAll('.dq-office-block') || [])];
      const boxLines = [...(content?.querySelectorAll('.dq-office-line') || [])];
      const runs = [...(content?.querySelectorAll('.dq-office-run') || [])];
      const titleRun = runs.find(run =>
        (run.textContent || '').includes('Continuação de Processo'));
      const numberRun = runs.find(run =>
        (run.textContent || '').includes('44505'));
      const footer = paper.querySelector('.dq-office-footer');
      const footerRect = footer?.getBoundingClientRect();
      const pageNumberRuns = [...(footer?.querySelectorAll('.dq-office-run') || [])]
        .filter(run => (run.textContent || '').trim() === '19');
      const lastNumber = pageNumberRuns.at(-1)?.getBoundingClientRect();
      const responsibleRun = [...paper.querySelectorAll('.dq-office-run')]
        .find(run => (run.textContent || '').includes('Leonardo Calheiros'));
      const responsibleStyle = responsibleRun
        ? getComputedStyle(responsibleRun)
        : null;
      return {
        paperText: paper.textContent || '',
        boxText: box?.textContent || '',
        boxBlockCount: blocks.length,
        boxLineCount: boxLines.length,
        firstLineAlign: blocks.length
          ? getComputedStyle(blocks[0].querySelector('.dq-office-line')).textAlign
          : '',
        titleFontSizePx: titleRun
          ? Number.parseFloat(getComputedStyle(titleRun).fontSize)
          : 0,
        titleDecoration: titleRun
          ? getComputedStyle(titleRun).textDecorationLine
          : '',
        numberFontWeight: numberRun
          ? Number.parseInt(getComputedStyle(numberRun).fontWeight, 10)
          : 0,
        insetLeftPx: content
          ? Number.parseFloat(getComputedStyle(content).left)
          : -1,
        insetTopPx: content
          ? Number.parseFloat(contentStyle.top)
          : -1,
        insetRightPx: boxStyle && contentStyle
          ? Number.parseFloat(boxStyle.width) -
            Number.parseFloat(contentStyle.left) -
            Number.parseFloat(contentStyle.width)
          : -1,
        insetBottomPx: boxStyle && contentStyle
          ? Number.parseFloat(boxStyle.height) -
            Number.parseFloat(contentStyle.top) -
            Number.parseFloat(contentStyle.height)
          : -1,
        footerText: footer?.textContent || '',
        footerLastNumberRightRatio: footerRect && lastNumber
              ? (lastNumber.right - footerRect.left) / footerRect.width
              : 0,
        responsibleFont: responsibleStyle?.fontFamily || '',
      };
    }''');
    expect(lastPage['paperText'], contains('16.'));
    expect(lastPage['paperText'], contains('Providências a serem adotadas'));
    expect(lastPage['paperText'], contains('17.'));
    expect(lastPage['paperText'], contains('Declaração de Viabilidade'));
    expect(lastPage['paperText'], contains('18.'));
    expect(lastPage['paperText'], contains('Responsáveis'));
    expect(lastPage['boxText'], contains('Continuação de Processo'));
    expect(lastPage['boxText'], contains('44505/2025'));
    expect(lastPage['boxBlockCount'], 4);
    expect(lastPage['boxLineCount'], 4,
        reason: 'the four Word stamp paragraphs must not wrap or clip');
    expect(lastPage['firstLineAlign'], 'center');
    expect(lastPage['titleFontSizePx'] as num, closeTo(13.333, 0.2));
    expect(lastPage['titleDecoration'], contains('underline'));
    expect(lastPage['numberFontWeight'] as num, greaterThanOrEqualTo(600));
    expect(lastPage['insetLeftPx'] as num, closeTo(9.6, 0.2));
    expect(lastPage['insetTopPx'] as num, closeTo(4.8, 0.2));
    expect(lastPage['insetRightPx'] as num, closeTo(9.6, 0.2));
    expect(lastPage['insetBottomPx'] as num, closeTo(4.8, 0.2));
    expect(lastPage['footerText'], contains('19'));
    expect(lastPage['footerLastNumberRightRatio'] as num,
        allOf(greaterThan(0.8), lessThanOrEqualTo(1.02)),
        reason: 'the final page field must remain on the right tab stop');
    expect(
      (lastPage['responsibleFont'] as String).replaceAll(' ', ''),
      'Ecofont_Spranq_eco_Sans,calibri,carlito,arial,sans-serif',
      reason: 'Normal implicit style must reach the responsible paragraphs',
    );
  });

  test('TR captures Word boundary pages, edits and saves through trusted UI',
      () async {
    final source = officeTrCorpus();
    await app.reload();
    final imported = await app.importDocx(
      source,
      artifactName: 'tr-page-capture',
      captureScreenshots: false,
    );
    expect(imported.metrics['totalPages'], 140);

    // Leave page 1 mounted last so the following trusted keyboard edit cannot
    // race virtualization after the page-140 capture.
    Map<String, dynamic>? page53;
    for (final pageNumber in const [19, 31, 53, 140, 1]) {
      final evidence = await app.capturePageEvidence(
        artifactName: 'tr-page-capture',
        pageNumber: pageNumber,
      );
      expectCompletePaper(evidence, pageNumber);
      if (pageNumber == 53) {
        page53 = await app.page.evaluate<Map<String, dynamic>>('''() => {
          const paper = document.querySelector(
            '.dq-office-page[data-page="52"]');
          if (!paper) throw new Error('TR page 53 is not mounted');
          const box = paper.querySelector('.dq-office-text-box');
          const content = box?.querySelector('.dq-office-text-box-content');
          const boxStyle = box ? getComputedStyle(box) : null;
          const contentStyle = content ? getComputedStyle(content) : null;
          const blocks = [...(content?.querySelectorAll('.dq-office-block') || [])];
          const boxLines = [...(content?.querySelectorAll('.dq-office-line') || [])];
          const runs = [...(content?.querySelectorAll('.dq-office-run') || [])];
          const titleRun = runs.find(run =>
            (run.textContent || '').includes('Continuação de Processo'));
          const numberRun = runs.find(run =>
            (run.textContent || '').includes('44505'));
          const markers = [...paper.querySelectorAll(
            '.dq-office-table-cell[data-column="0"] .dq-office-marker')]
            .map(marker => (marker.textContent || '').trim());
          const item14Marker = [...paper.querySelectorAll(
            '.dq-office-table-cell[data-column="0"] .dq-office-marker')]
            .find(marker => (marker.textContent || '').trim() === '14.');
          const item14Row = item14Marker?.closest('.dq-office-table-row');
          const item14Cells = [...(item14Row?.querySelectorAll(
            '.dq-office-table-cell') || [])]
            .filter(cell => getComputedStyle(cell).display !== 'none');
          const item14Description = item14Cells.at(-1);
          const item14Lines = [...(item14Description?.querySelectorAll(
            '.dq-office-line') || [])];
          const annexTable = item14Row?.closest('.dq-office-table');
          const annexTableRect = annexTable?.getBoundingClientRect();
          const footer = paper.querySelector('.dq-office-footer');
          const footerRect = footer?.getBoundingClientRect();
          const pageNumberRuns = [
            ...(footer?.querySelectorAll('.dq-office-run') || [])
          ].filter(run => (run.textContent || '').trim() === '53');
          const lastNumber = pageNumberRuns.at(-1)?.getBoundingClientRect();
          return {
            paperText: paper.textContent || '',
            itemMarkers: markers,
            item14LineCount: item14Lines.length,
            item14LineTexts: item14Lines.map(line => line.textContent || ''),
            item14WordSpacingPx: item14Lines.map(line =>
              Number.parseFloat(getComputedStyle(line).wordSpacing) || 0),
            item14CellWidthPx: item14Description
              ?.getBoundingClientRect().width || 0,
            annexTableBottomPx: annexTableRect?.bottom || 0,
            footerTopPx: footerRect?.top || 0,
            boxText: box?.textContent || '',
            boxBlockCount: blocks.length,
            boxLineCount: boxLines.length,
            firstLineAlign: blocks.length
              ? getComputedStyle(
                  blocks[0].querySelector('.dq-office-line')).textAlign
              : '',
            titleFontSizePx: titleRun
              ? Number.parseFloat(getComputedStyle(titleRun).fontSize)
              : 0,
            titleDecoration: titleRun
              ? getComputedStyle(titleRun).textDecorationLine
              : '',
            numberFontWeight: numberRun
              ? Number.parseInt(getComputedStyle(numberRun).fontWeight, 10)
              : 0,
            insetLeftPx: content
              ? Number.parseFloat(getComputedStyle(content).left)
              : -1,
            insetTopPx: content
              ? Number.parseFloat(contentStyle.top)
              : -1,
            insetRightPx: boxStyle && contentStyle
              ? Number.parseFloat(boxStyle.width) -
                Number.parseFloat(contentStyle.left) -
                Number.parseFloat(contentStyle.width)
              : -1,
            insetBottomPx: boxStyle && contentStyle
              ? Number.parseFloat(boxStyle.height) -
                Number.parseFloat(contentStyle.top) -
                Number.parseFloat(contentStyle.height)
              : -1,
            footerText: footer?.textContent || '',
            footerLineAlign: footer
              ? getComputedStyle(footer.querySelector('.dq-office-line')).textAlign
              : '',
            footerLastNumberRightRatio: footerRect && lastNumber
              ? (lastNumber.right - footerRect.left) / footerRect.width
              : 0,
          };
        }''');
      }
    }

    final page53Evidence = page53!;
    expect(page53Evidence['paperText'], contains('ANEXO III'));
    expect(page53Evidence['paperText'], contains('PROVA DE CONCEITO'));
    expect(page53Evidence['paperText'], contains('CARACTERÍSTICAS GERAIS'));
    expect(page53Evidence['itemMarkers'],
        [for (var item = 1; item <= 17; item++) '$item.'],
        reason: 'marker-only rows 1–17 must remain ordered and unique');
    expect(page53Evidence['item14LineCount'], 2,
        reason: 'o item 14 deve quebrar como o Word: $page53Evidence');
    expect(page53Evidence['annexTableBottomPx'] as num,
        lessThanOrEqualTo((page53Evidence['footerTopPx'] as num) + 1),
        reason: 'a tabela do anexo não pode invadir o rodapé');
    expect(page53Evidence['boxText'], contains('Continuação de Processo'));
    expect(page53Evidence['boxText'], contains('44505/2025'));
    expect(page53Evidence['boxBlockCount'], 4);
    expect(page53Evidence['boxLineCount'], 4,
        reason: 'the four Word stamp paragraphs must not wrap or clip');
    expect(page53Evidence['firstLineAlign'], 'right');
    expect(page53Evidence['titleFontSizePx'] as num, closeTo(13.333, 0.2));
    expect(page53Evidence['titleDecoration'], contains('underline'));
    expect(
        page53Evidence['numberFontWeight'] as num, greaterThanOrEqualTo(600));
    expect(page53Evidence['insetLeftPx'] as num, closeTo(9.6, 0.2));
    expect(page53Evidence['insetTopPx'] as num, closeTo(4.8, 0.2));
    expect(page53Evidence['insetRightPx'] as num, closeTo(9.6, 0.2));
    expect(page53Evidence['insetBottomPx'] as num, closeTo(4.8, 0.2));
    expect(page53Evidence['footerText'], contains('53'));
    expect(page53Evidence['footerLineAlign'], 'center',
        reason: 'footer2.xml explicitly declares w:jc=center');
    expect(page53Evidence['footerLastNumberRightRatio'] as num,
        allOf(greaterThan(0.50), lessThan(0.58)),
        reason: 'the page 53 field group must remain centered like Word');

    const token = 'E2E_TR_CAPTURE_SAVE_TOKEN';
    await app.typeMarker(
      ' $token',
      artifactName: 'tr-page-capture-short',
      requirePlain: true,
    );
    final pageCount = await app.page.evaluate<int>('''() =>
      document.querySelector('.dq-office-pages')?.children.length || 0''');
    expect(pageCount, 140,
        reason: 'the first trusted edit must match Word\'s 140-page reflow');

    final saved = await app.exportDocx(
      artifactName: 'tr-page-capture-short',
      viaShortcut: true,
    );
    await app.page.waitForFunction('''() =>
      document.querySelector('.dq-office-app')
        ?.getAttribute('data-dq-office-dirty') === 'false' ''');
    expect(renderedBreakCount(source), greaterThan(0));
    expect(renderedBreakCount(saved), 0,
        reason: 'a real edit invalidates stale Word pagination markers');

    final reopened = OfficeDocxCodec(schema: schema).import(
      saved.readAsBytesSync(),
      includePackageResources: false,
    );
    final reopenedDoc = PMNode.fromJSON(schema, reopened.snapshot.body);
    expect(reopenedDoc.textContent, contains(token));
  });
}
