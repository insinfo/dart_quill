@TestOn('vm')
@Timeout(Duration(minutes: 45))
library;

/// Full user flow for the Word-style editor against the two procurement
/// documents that originally exposed rendering, editing, save and performance
/// regressions.
import 'dart:io';
import 'dart:typed_data';

import 'package:dart_quill/dart_quill_office.dart';
import 'package:test/test.dart';

import '../support/pdf_reader.dart';
import 'support/office_e2e_app.dart';

final class _DocxCase {
  const _DocxCase({
    required this.name,
    required this.path,
    required this.expectedPages,
    required this.importBudget,
    required this.screenshotPages,
    this.fullInteractionAudit = false,
  });

  final String name;
  final String path;
  final int expectedPages;
  final Duration importBudget;
  final List<int> screenshotPages;
  final bool fullInteractionAudit;
}

final class _TokenLocation {
  const _TokenLocation(this.text, this.ancestors);

  final PMNode text;
  final List<PMNode> ancestors;

  PMNode? nearest(String type) {
    for (final node in ancestors.reversed) {
      if (node.type.name == type) return node;
    }
    return null;
  }
}

List<_TokenLocation> _findTokenLocations(PMNode root, String token) {
  final locations = <_TokenLocation>[];

  void visit(PMNode node, List<PMNode> ancestors) {
    if (node.isText && (node.text ?? '').contains(token)) {
      locations.add(_TokenLocation(node, List<PMNode>.unmodifiable(ancestors)));
      return;
    }
    for (var index = 0; index < node.childCount; index++) {
      visit(node.child(index), [...ancestors, node]);
    }
  }

  visit(root, const []);
  return locations;
}

_TokenLocation _onlyToken(PMNode root, String token) {
  final locations = _findTokenLocations(root, token);
  expect(locations, hasLength(1),
      reason: 'token must occur in exactly one PM text node: $token');
  return locations.single;
}

({
  String tableId,
  String rowId,
  String cellId,
  int sourceRowIndex,
  int sourceCellIndex,
}) _tableIdentity(_TokenLocation location) {
  final table = location.nearest('table');
  final row = location.nearest('tableRow');
  final cell = location.nearest('tableCell');
  expect(table, isNotNull, reason: 'token must remain inside a table');
  expect(row, isNotNull, reason: 'token must remain inside the same row');
  expect(cell, isNotNull, reason: 'token must remain inside the same cell');
  final rowWord = (row!.attrs['word'] as Map).cast<String, dynamic>();
  final cellWord = (cell!.attrs['word'] as Map).cast<String, dynamic>();
  final sourceRowIndex = (rowWord['sourceRowIndex'] as num).toInt();
  final sourceCellIndex = (cellWord['sourceCellIndex'] as num).toInt();
  expect(sourceRowIndex, greaterThanOrEqualTo(0));
  expect(sourceCellIndex, greaterThanOrEqualTo(0));
  return (
    tableId: table!.attrs['id'] as String,
    rowId: row.attrs['id'] as String,
    cellId: cell.attrs['id'] as String,
    sourceRowIndex: sourceRowIndex,
    sourceCellIndex: sourceCellIndex,
  );
}

void _expectBodyToken(PMNode doc, String token, {bool formatted = false}) {
  final location = _onlyToken(doc, token);
  expect(location.nearest('tableCell'), isNull,
      reason: 'body token cannot migrate into a table');
  final marks = location.text.marks.map((mark) => mark.type.name).toSet();
  if (formatted) expect(marks, containsAll(<String>['bold', 'italic']));
}

void _expectOrderedListToken(PMNode doc, String token) {
  final location = _onlyToken(doc, token);
  final list = location.nearest('listItem');
  expect(list, isNotNull,
      reason: 'ribbon-created list must reimport as listItem');
  expect(list!.attrs['kind'], 'ordered');
  final word = (list.attrs['word'] as Map).cast<String, dynamic>();
  final numPr = (word['numPr'] as Map).cast<String, dynamic>();
  expect((numPr['numId'] as num).toInt(), isNot(0),
      reason: 'DOCX list must retain a real numbering instance');
}

({
  String tableId,
  String rowId,
  String cellId,
  int sourceRowIndex,
  int sourceCellIndex,
}) _expectBoldTableToken(
  PMNode doc,
  String token,
) {
  final location = _onlyToken(doc, token);
  expect(location.text.marks.map((mark) => mark.type.name), contains('bold'));
  return _tableIdentity(location);
}

void main() {
  late OfficeE2eApp app;
  final schema = officeQuillSchema();

  // Por PREFIXO, nunca por caminho literal: os nomes têm acento e a
  // normalização Unicode do disco difere entre Windows e o Linux da CI.
  final documents = [
    _DocxCase(
      name: 'etp',
      path: officeEtpCorpus().path,
      expectedPages: 19,
      importBudget: Duration(seconds: 15),
      screenshotPages: [1, 10, 19],
      fullInteractionAudit: true,
    ),
    _DocxCase(
      name: 'tr',
      path: officeTrCorpus().path,
      expectedPages: 140,
      importBudget: Duration(seconds: 60),
      screenshotPages: [1, 53, 65, 130],
    ),
  ];

  setUpAll(() async => app = await OfficeE2eApp.start());
  tearDownAll(() async => app.stop());

  for (final document in documents) {
    test(
      '${document.name.toUpperCase()}: importar, renderizar, editar e exportar',
      () async {
        await app.reload();
        final workflowIssueStart = app.issueCount;
        final source = File(document.path);
        final bodyToken = 'E2E_${document.name.toUpperCase()}_BODY_TOKEN';
        final tableToken = 'E2E_${document.name.toUpperCase()}_TABLE_TOKEN';
        final listToken = 'E2E_${document.name.toUpperCase()}_LIST_TOKEN';
        final secondToken = 'E2E_${document.name.toUpperCase()}_SECOND_SAVE';

        final evidence = await app.importDocx(
          source,
          artifactName: document.name,
          timeout: const Duration(minutes: 5),
          pageNumbers: document.screenshotPages,
        );
        final metrics = evidence.metrics;
        final renderedPages = metrics['totalPages'] as int;

        if (document.fullInteractionAudit) {
          await app.typeBodyTokenWithUndoRedoFormatting(
            bodyToken,
            artifactName: document.name,
          );
          await app.createOrderedListToken(
            listToken,
            artifactName: document.name,
            excludeToken: bodyToken,
          );
        } else {
          await app.typeMarker(
            ' $bodyToken',
            artifactName: document.name,
          );
        }
        final tableDomIdentity = await app.typeMarkerInTable(
          ' $tableToken',
          artifactName: document.name,
          bold: true,
          startPageNumber: document.name == 'tr' ? 53 : null,
        );
        final tableEditPerformance = app.lastEditPerformance;
        final editedRenderedPages = await app.page.evaluate<int>('''() =>
          document.querySelector('.dq-office-pages')?.children.length || 0''');
        final exported = await app.exportDocx(
          artifactName: document.name,
          viaShortcut: document.fullInteractionAudit,
        );
        await app.page.waitForFunction('''() =>
          document.querySelector('.dq-office-app')
            ?.getAttribute('data-dq-office-dirty') === 'false' ''');
        final exportPerformance = app.lastExportPerformance;
        final editedPdfExport = await app.exportPdf(
          artifactName: '${document.name}-edited',
        );

        final codec = OfficeDocxCodec(schema: schema);
        final sourceImport = codec.import(
          Uint8List.fromList(source.readAsBytesSync()),
          documentId: '${document.name}-source',
        );
        final exportedImport = codec.import(
          Uint8List.fromList(exported.readAsBytesSync()),
          documentId: '${document.name}-exported',
        );
        final sourceDoc = PMNode.fromJSON(schema, sourceImport.snapshot.body);
        final exportedDoc =
            PMNode.fromJSON(schema, exportedImport.snapshot.body);

        final sourceParts = sourceImport.snapshot.resources.opaqueParts
            .map((part) => part['uri'] as String)
            .toSet();
        final exportedParts = exportedImport.snapshot.resources.opaqueParts
            .map((part) => part['uri'] as String)
            .toSet();
        final missingParts = sourceParts.difference(exportedParts).toList()
          ..sort();

        // The exported package must not only parse in the codec: exercise the
        // same user-facing Open DOCX flow again and prove it lays out in the
        // browser with the trusted-keyboard body edit still visible.
        await app.reload();
        final reopenedEvidence = await app.importDocx(
          exported,
          artifactName: '${document.name}-reopened',
          timeout: const Duration(minutes: 5),
        );
        final bodyEditVisible = await app.renderedTokenExists(bodyToken);
        final reopenedTextBox =
            await app.page.evaluate<Map<String, dynamic>>('''() => {
          const paper = document.querySelector(
            '.dq-office-page[data-page="0"]');
          if (!paper) throw new Error('reopened first page is not mounted');
          const box = paper.querySelector('.dq-office-text-box');
          const content = box?.querySelector('.dq-office-text-box-content');
          const boxStyle = box ? getComputedStyle(box) : null;
          const contentStyle = content ? getComputedStyle(content) : null;
          const blocks = [...(content?.querySelectorAll('.dq-office-block') || [])];
          const runs = [...(content?.querySelectorAll('.dq-office-run') || [])];
          const titleRun = runs.find(run =>
            (run.textContent || '').includes('Continuação de Processo'));
          const numberRun = runs.find(run =>
            (run.textContent || '').includes('44505'));
          return {
            contentEditable: box?.getAttribute('contenteditable') || '',
            text: box?.textContent || '',
            blockCount: blocks.length,
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
            insetLeftPx: contentStyle
              ? Number.parseFloat(contentStyle.left)
              : -1,
            insetTopPx: contentStyle
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
          };
        }''');
        final reopenedPdfExport = await app.exportPdf(
          artifactName: '${document.name}-reopened',
        );

        File? secondExported;
        PMNode? secondExportedDoc;
        Map<String, dynamic>? secondExportPerformance;
        List<String>? secondMissingParts;
        if (document.fullInteractionAudit) {
          await app.typeMarker(
            ' $secondToken',
            artifactName: '${document.name}-reopened-second-edit',
          );
          secondExported = await app.exportDocx(
            artifactName: '${document.name}-second-save',
          );
          await app.page.waitForFunction('''() =>
            document.querySelector('.dq-office-app')
              ?.getAttribute('data-dq-office-dirty') === 'false' ''');
          secondExportPerformance = app.lastExportPerformance;
          final secondImport = codec.import(
            Uint8List.fromList(secondExported.readAsBytesSync()),
            documentId: '${document.name}-second-export',
          );
          secondExportedDoc =
              PMNode.fromJSON(schema, secondImport.snapshot.body);
          final secondParts = secondImport.snapshot.resources.opaqueParts
              .map((part) => part['uri'] as String)
              .toSet();
          secondMissingParts = exportedParts.difference(secondParts).toList()
            ..sort();
        }
        final editedPdfText = PdfReader(
          Uint8List.fromList(editedPdfExport.file.readAsBytesSync()),
        ).extractText();
        final reopenedPdfText = PdfReader(
          Uint8List.fromList(reopenedPdfExport.file.readAsBytesSync()),
        ).extractText();
        final workflowIssues = app.issuesSince(workflowIssueStart);
        final fatalIssues = workflowIssues
            .where((issue) => issue['severity'] == 'error')
            .toList();

        await app.writeJson('${document.name}-roundtrip', {
          ...evidence.toJson(),
          'bodyToken': bodyToken,
          'tableToken': tableToken,
          if (document.fullInteractionAudit) 'listToken': listToken,
          if (document.fullInteractionAudit) 'secondToken': secondToken,
          'tableDomIdentity': tableDomIdentity,
          'tableEditPerformance': tableEditPerformance,
          'editedPdfExport': editedPdfExport.toJson(),
          'editedRenderedPages': editedRenderedPages,
          'editedPdfTextLength': editedPdfText.length,
          'editedPdfHasBodyToken': editedPdfText.contains(bodyToken),
          'editedPdfHasTableToken': editedPdfText.contains(tableToken),
          if (document.fullInteractionAudit)
            'editedPdfHasListToken': editedPdfText.contains(listToken),
          'exportedFile': exported.absolute.path,
          'exportedBytes': exported.lengthSync(),
          'sourceTextChars': sourceDoc.textContent.length,
          'exportedTextChars': exportedDoc.textContent.length,
          'sourcePartCount': sourceParts.length,
          'exportedPartCount': exportedParts.length,
          'missingParts': missingParts,
          'exportPerformance': exportPerformance,
          'reopened': reopenedEvidence.toJson(),
          'reopenedTextBox': reopenedTextBox,
          'reopenedPdfExport': reopenedPdfExport.toJson(),
          'reopenedPdfTextLength': reopenedPdfText.length,
          'reopenedPdfHasBodyToken': reopenedPdfText.contains(bodyToken),
          'reopenedPdfHasTableToken': reopenedPdfText.contains(tableToken),
          if (document.fullInteractionAudit)
            'reopenedPdfHasListToken': reopenedPdfText.contains(listToken),
          'workflowIssues': workflowIssues,
          'bodyEditVisibleAfterBrowserReopen': bodyEditVisible,
          if (secondExported != null) ...{
            'secondExportedFile': secondExported.absolute.path,
            'secondExportedBytes': secondExported.lengthSync(),
            'secondExportPerformance': secondExportPerformance,
            'secondMissingParts': secondMissingParts,
          },
        });

        // Assertions come after the complete workflow so a pagination failure
        // does not suppress the edit/export evidence needed to diagnose it.
        expect(
          metrics['totalPages'],
          document.expectedPages,
          reason: 'the reference PDF renders this DOCX with exactly '
              '${document.expectedPages} A4 pages',
        );
        expect(metrics['mountedPages'] as num, greaterThan(0));
        expect(metrics['editableSurfaces'] as num, greaterThan(0));
        expect(metrics['renderedBlocks'] as num, greaterThan(0));
        expect(metrics['visibleTextChars'] as num, greaterThan(50));
        expect(metrics['firstPaperWidthPx'] as num, closeTo(793.7, 1.0),
            reason: 'the rendered paper must retain A4 width at 96 DPI');
        expect(metrics['firstPaperHeightPx'] as num, closeTo(1122.5, 1.0),
            reason: 'the rendered paper must retain A4 height at 96 DPI');
        expect(metrics['topStatusPage'], 1,
            reason: 'a barra deve iniciar na primeira página visível');
        expect(
          metrics['middleStatusPage'] as num,
          allOf(
            greaterThan(renderedPages * 0.35),
            lessThan(renderedPages * 0.7),
          ),
          reason: 'a barra deve acompanhar o scroll até o meio',
        );
        expect(
          metrics['lastStatusPage'] as num,
          greaterThanOrEqualTo(renderedPages - 1),
          reason: 'a barra deve acompanhar o scroll até a última página',
        );
        final indexedStatus =
            (metrics['indexedPageStatus'] as Map).cast<String, dynamic>();
        for (final pageNumber in document.screenshotPages) {
          if (pageNumber > renderedPages) continue;
          expect(indexedStatus['$pageNumber'], pageNumber,
              reason: 'captura indexada precisa montar e reportar página '
                  '$pageNumber');
        }
        expect(indexedStatus['last'], renderedPages,
            reason: 'captura do elemento final deve reportar a última página');
        expect(
          Duration(milliseconds: metrics['importMs'] as int),
          lessThan(document.importBudget),
          reason: 'import + initial editable render exceeded the budget',
        );
        expect(
          metrics['maxFrameGapMs'] as num,
          lessThan(500),
          reason: 'the browser main thread froze during import/render',
        );
        expect(
          exportPerformance['maxFrameGapMs'] as num,
          lessThan(500),
          reason: 'the browser main thread froze during DOCX export',
        );
        expect(
          exportPerformance['maxLongTaskMs'] as num,
          lessThan(500),
          reason: 'DOCX export produced a browser long task over the budget',
        );
        expect(
          tableEditPerformance['maxFrameGapMs'] as num,
          lessThan(500),
          reason: 'editing a real table cell froze the browser main thread',
        );
        final sourceFilename =
            source.path.replaceAll('\\', '/').split('/').last;
        final sourceStem = sourceFilename.substring(
          0,
          sourceFilename.toLowerCase().lastIndexOf('.docx'),
        );
        expect(
          editedPdfExport.browserFilename,
          '$sourceStem.pdf',
          reason: 'PDF export must preserve the opened document basename',
        );
        expect(
          editedPdfExport.pageCount,
          editedRenderedPages,
          reason: 'the PDF exported after trusted edits must reuse the exact '
              'edited browser page graph',
        );
        expect(editedPdfExport.mimeType, 'application/pdf');
        expect(editedPdfExport.byteLength, greaterThan(1000));
        expect(
            editedPdfExport.performance['maxFrameGapMs'] as num, lessThan(500),
            reason: 'PDF export after trusted edits froze the browser');
        expect(
            editedPdfExport.performance['maxLongTaskMs'] as num, lessThan(500),
            reason: 'PDF export after trusted edits created a long task');
        expect(editedPdfExport.performance['phaseTimings'], isA<Map>());
        expect(editedPdfText, contains(bodyToken),
            reason: 'the edited body text must be searchable in the PDF');
        expect(editedPdfText, contains(tableToken),
            reason: 'the edited table text must be searchable in the PDF');
        if (document.fullInteractionAudit) {
          expect(editedPdfText, contains(listToken),
              reason: 'the ribbon-created list must be searchable in the PDF');
        }
        expect(
          exportPerformance['browserFilename'],
          sourceFilename,
          reason: 'saving must preserve the opened DOCX filename',
        );
        expect(
          exportPerformance['trigger'],
          document.fullInteractionAudit ? 'ctrl+s' : 'ribbon',
          reason: 'ETP must exercise Ctrl+S; TR keeps the ribbon save path',
        );
        expect(fatalIssues, isEmpty,
            reason: 'browser console/page/network errors: $fatalIssues');

        _expectBodyToken(
          exportedDoc,
          bodyToken,
          formatted: document.fullInteractionAudit,
        );
        if (document.fullInteractionAudit) {
          _expectOrderedListToken(exportedDoc, listToken);
        }
        final firstTableIdentity =
            _expectBoldTableToken(exportedDoc, tableToken);
        expect(firstTableIdentity.tableId, tableDomIdentity['tableId'],
            reason: 'table token must remain in the exact selected table');
        expect(firstTableIdentity.rowId, tableDomIdentity['rowId'],
            reason: 'table token must remain in the exact selected row');
        expect(firstTableIdentity.cellId, tableDomIdentity['cellId'],
            reason: 'table token must remain in the exact selected cell');
        expect(
          firstTableIdentity.sourceRowIndex,
          (tableDomIdentity['sourceRowIndex'] as num).toInt(),
          reason: 'table token must retain the exact OOXML source row',
        );
        expect(
          firstTableIdentity.sourceCellIndex,
          (tableDomIdentity['sourceCellIndex'] as num).toInt(),
          reason: 'table token must retain the exact OOXML source cell',
        );
        expect(
          exportedDoc.textContent.length,
          greaterThanOrEqualTo(sourceDoc.textContent.length),
          reason: 'saving must not silently discard editable document text',
        );
        expect(missingParts, isEmpty,
            reason: 'saving an imported DOCX must preserve its OPC parts');
        expect(bodyEditVisible, isTrue,
            reason: 'the exported DOCX must reopen in the real editor with '
                'the exact trusted-keyboard body token rendered');
        expect(reopenedTextBox['contentEditable'], 'false',
            reason: 'the DrawingML atom must stay protected from accidental '
                'outer-document edits');
        expect(reopenedTextBox['text'], contains('Continuação de Processo'));
        expect(reopenedTextBox['text'], contains('44505/2025'));
        expect(reopenedTextBox['blockCount'], 4,
            reason: 'save + reopen cannot flatten w:txbxContent');
        expect(reopenedTextBox['firstLineAlign'],
            document.name == 'etp' ? 'center' : 'right');
        expect(reopenedTextBox['titleFontSizePx'] as num, closeTo(13.333, 0.2));
        expect(reopenedTextBox['titleDecoration'], contains('underline'));
        expect(reopenedTextBox['numberFontWeight'] as num,
            greaterThanOrEqualTo(600));
        expect(reopenedTextBox['insetLeftPx'] as num, closeTo(9.6, 0.2));
        expect(reopenedTextBox['insetTopPx'] as num, closeTo(4.8, 0.2));
        expect(reopenedTextBox['insetRightPx'] as num, closeTo(9.6, 0.2));
        expect(reopenedTextBox['insetBottomPx'] as num, closeTo(4.8, 0.2));
        expect(
          reopenedPdfExport.pageCount,
          reopenedEvidence.metrics['totalPages'],
          reason: 'PDF export after save + reopen must reuse the reopened '
              'browser page graph',
        );
        expect(reopenedPdfExport.mimeType, 'application/pdf');
        expect(reopenedPdfExport.byteLength, greaterThan(1000));
        expect(reopenedPdfExport.performance['maxFrameGapMs'] as num,
            lessThan(500),
            reason: 'PDF export after save + reopen froze the browser');
        expect(reopenedPdfExport.performance['maxLongTaskMs'] as num,
            lessThan(500),
            reason: 'PDF export after save + reopen created a long task');
        expect(reopenedPdfExport.performance['phaseTimings'], isA<Map>());
        expect(reopenedPdfText, contains(bodyToken),
            reason: 'saved and reopened body text must remain searchable in '
                'the PDF');
        expect(reopenedPdfText, contains(tableToken),
            reason: 'saved and reopened table text must remain searchable in '
                'the PDF');
        if (document.fullInteractionAudit) {
          expect(reopenedPdfText, contains(listToken),
              reason: 'saved and reopened list text must remain searchable '
                  'in the PDF');
        }
        expect(
          reopenedEvidence.metrics['totalPages'] as num,
          inInclusiveRange(
            document.expectedPages - 1,
            document.expectedPages + 1,
          ),
          reason: 'reopening the saved DOCX must retain approximately the '
              'same pagination; the inserted markers may add one page',
        );

        if (document.fullInteractionAudit) {
          final secondDoc = secondExportedDoc!;
          _expectBodyToken(
            secondDoc,
            bodyToken,
            formatted: true,
          );
          _expectBodyToken(secondDoc, secondToken);
          _expectOrderedListToken(secondDoc, listToken);
          final secondTableIdentity =
              _expectBoldTableToken(secondDoc, tableToken);
          expect(secondTableIdentity, firstTableIdentity,
              reason: 'second edit/save cannot move the edited table cell');
          expect(secondMissingParts, isEmpty,
              reason: 'second save must preserve every first-save OPC part');
          expect(
            secondExportPerformance!['maxFrameGapMs'] as num,
            lessThan(500),
            reason: 'second DOCX save froze the browser main thread',
          );
          expect(
            secondExportPerformance['maxLongTaskMs'] as num,
            lessThan(500),
            reason: 'second DOCX save produced an oversized long task',
          );
          expect(
            secondExportPerformance['browserFilename'],
            source.path.replaceAll('\\', '/').split('/').last,
            reason: 'reopen + second save must retain the original filename',
          );
        }
      },
      skip: document.name == 'tr' &&
              Platform.environment['OFFICE_E2E_SKIP_TR'] == '1'
          ? 'TR explicitly disabled with OFFICE_E2E_SKIP_TR=1'
          : false,
    );
  }
}
