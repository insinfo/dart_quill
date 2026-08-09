@TestOn('vm')
@Timeout(Duration(minutes: 45))
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:dart_quill/dart_quill_office.dart';
import 'package:test/test.dart';

import 'support/office_e2e_app.dart';

void main() {
  late OfficeE2eApp app;

  setUpAll(() async => app = await OfficeE2eApp.start());
  tearDownAll(() async => app.stop());

  test(
    'trusted input survives repagination in a mounted TR table fragment',
    () async {
      const bodyMarker = ' E2E_TR_REPAGINATE_BODY';
      const tableMarker = ' E2E_TR_FRAGMENTED_TABLE';
      final source = File(
        'resources/PGCTIC1_-_TR_-_SISTEMA_GESTAO_PUBLICA__Recuperação_'
        'Automática_.docx',
      );

      await app.importDocx(
        source,
        artifactName: 'tr-trusted-table-input',
        captureScreenshots: false,
      );

      // This edit is intentional: it invalidates page positions before the
      // virtualizer mounts page 53, matching the production failure.
      await app.typeMarker(
        bodyMarker,
        artifactName: 'tr-trusted-table-input-body',
      );
      final identity = await app.typeMarkerInTable(
        tableMarker,
        artifactName: 'tr-trusted-table-input',
        bold: true,
        startPageNumber: 53,
      );

      expect(await app.renderedTokenExists(tableMarker.trim()), isTrue);
      expect(identity['tableId'], isNotEmpty);
      expect(identity['rowId'], isNotEmpty);
      expect(identity['cellId'], isNotEmpty);
      expect(identity['blockId'], isNotEmpty);
      expect(app.lastEditPerformance['maxFrameGapMs'] as num, lessThan(500),
          reason: 'trusted typing in the 1,367-row table must stay responsive');

      final exported = await app.exportDocx(
        artifactName: 'tr-trusted-table-input',
      );
      final schema = officeQuillSchema();
      final imported = OfficeDocxCodec(schema: schema).import(
        Uint8List.fromList(exported.readAsBytesSync()),
        documentId: 'tr-trusted-table-input-exported',
      );
      final doc = PMNode.fromJSON(schema, imported.snapshot.body);

      expect(doc.textContent, contains(bodyMarker.trim()));

      PMNode? targetCell;
      List<PMNode>? targetAncestors;
      PMNode? markedToken;
      List<PMNode>? tokenAncestors;
      void visit(PMNode node, List<PMNode> ancestors) {
        if (node.type.name == 'tableCell' &&
            (node.attrs['id'] == identity['cellId'] ||
                node.attrs['cellId'] == identity['cellId'])) {
          targetCell = node;
          targetAncestors = ancestors;
        }
        final insideTargetCell = ancestors.any((ancestor) =>
            ancestor.type.name == 'tableCell' &&
            (ancestor.attrs['id'] == identity['cellId'] ||
                ancestor.attrs['cellId'] == identity['cellId']));
        if (insideTargetCell &&
            node.isText &&
            (node.text ?? '').contains(tableMarker.trim())) {
          markedToken = node;
          tokenAncestors = ancestors;
        }
        for (var index = 0; index < node.childCount; index++) {
          visit(node.child(index), [...ancestors, node]);
        }
      }

      visit(doc, const []);
      expect(targetCell, isNotNull,
          reason: 'the exported state must retain the clicked PM cell');
      expect(targetCell!.textContent, contains(tableMarker),
          reason: 'the exact trusted input belongs to that same PM cell');
      expect(
        targetAncestors!.any((node) =>
            node.type.name == 'table' &&
            node.attrs['id'] == identity['tableId']),
        isTrue,
      );
      expect(
        targetAncestors!.any((node) =>
            node.type.name == 'tableRow' &&
            (node.attrs['id'] == identity['rowId'] ||
                node.attrs['rowId'] == identity['rowId'])),
        isTrue,
      );
      expect(markedToken, isNotNull);
      expect(
        tokenAncestors!.any((node) =>
            node.type.name == 'paragraph' &&
            node.attrs['id'] == identity['blockId']),
        isTrue,
      );
      expect(
          markedToken!.marks.map((mark) => mark.type.name), contains('bold'));
    },
  );
}
