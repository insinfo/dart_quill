@TestOn('vm')
library;

import 'dart:typed_data';

import 'package:dart_quill/dart_quill_office.dart';
import 'package:test/test.dart';

String _legacyNodeSignature(
  PMNode node, {
  bool ignoreSourceSignature = false,
}) {
  var first = 0x811c9dc5;
  var second = 0x9e3779b9;
  var units = 0;

  void addCode(int code) {
    first = ((first << 5) - first + code) & 0xffffffff;
    second =
        (second + code + (second << 6) + (second << 16) - second) & 0xffffffff;
    units++;
  }

  void addString(String value) {
    addCode(value.length);
    for (final code in value.codeUnits) {
      addCode(code);
    }
    addCode(0x1f);
  }

  bool ignoredKey(String key) =>
      ignoreSourceSignature &&
      (key == 'sourceSignature' ||
          key == 'sourceBlockIndex' ||
          key == 'sourceCellIndex' ||
          key == 'sourceRowIndex');

  void addValue(dynamic value) {
    switch (value) {
      case null:
        addCode(0);
      case bool flag:
        addCode(flag ? 2 : 1);
      case num number:
        addCode(3);
        addString(number.toString());
      case String text:
        addCode(4);
        addString(text);
      case List values:
        addCode(5);
        addCode(values.length);
        for (final item in values) {
          addValue(item);
        }
      case Map values:
        addCode(6);
        final keys = values.keys.map((key) => '$key').toList()..sort();
        for (final key in keys) {
          if (ignoredKey(key)) continue;
          addString(key);
          // Keep this lookup exactly as the production legacy algorithm did:
          // keys are stringified before indexing the original map.
          addValue(values[key]);
        }
        addCode(0x1e);
      default:
        addCode(7);
        addString('$value');
    }
  }

  void addNode(PMNode value) {
    addCode(0x11);
    addString(value.type.name);
    addValue(value.attrs);
    addCode(value.marks.length);
    for (final mark in value.marks) {
      addString(mark.type.name);
      addValue(mark.attrs);
    }
    final text = value.text;
    if (text != null) addString(text);
    addCode(value.childCount);
    for (var i = 0; i < value.childCount; i++) {
      addNode(value.child(i));
    }
    addCode(0x12);
  }

  addNode(node);
  final a = first.toUnsigned(32).toRadixString(16).padLeft(8, '0');
  final b = second.toUnsigned(32).toRadixString(16).padLeft(8, '0');
  return '$a$b:$units';
}

PMNode _signatureFixture(Schema schema, Map<String, dynamic> nestedMap) {
  final bold = schema.marks['bold']!.create();
  final opaque = schema.marks['opaqueAttrs']!.create({
    'attrs': {
      'zeta': true,
      'alpha': [null, -3.25, 'ação 😀'],
      'sourceSignature': 'mark-source',
    },
  });
  final longUnicode = '${List.filled(1025, 'á').join()}😀fim';
  return schema.node(
    'doc',
    null,
    Fragment.from([
      schema.node(
        'paragraph',
        {
          'id': 'p-assinatura',
          'word': {
            'sourceBlockIndex': 7,
            'sourceSignature': 'paragraph-source',
            'nested': nestedMap,
          },
          'extra': {
            'enabled': false,
            'count': 42,
          },
        },
        Fragment.from([
          schema.text('prefixo ', [bold]),
          schema.text(longUnicode, [bold, opaque]),
          schema.node('opaqueInline', {
            'insert': {
              'sourceCellIndex': 4,
              'payload': nestedMap,
            },
          }),
        ]),
      ),
    ]),
  );
}

PMNode _tableDocument(Schema schema, {int rows = 64}) {
  final tableRows = <PMNode>[];
  for (var rowIndex = 0; rowIndex < rows; rowIndex++) {
    final paragraph = schema.node(
      'paragraph',
      null,
      Fragment.from([
        schema.text(
          rowIndex == rows - 1
              ? 'linha $rowIndex — ${List.filled(1300, '界').join()} 😀'
              : 'linha $rowIndex',
        ),
      ]),
    );
    final cell = schema.node(
      'tableCell',
      null,
      Fragment.from([paragraph]),
    );
    tableRows.add(schema.node(
      'tableRow',
      null,
      Fragment.from([cell]),
    ));
  }
  final table = schema.node(
    'table',
    {
      'colWidths': [2400],
    },
    Fragment.from(tableRows),
  );
  return schema.node('doc', null, Fragment.from([table]));
}

PMNode _editFirstTableCell(Schema schema, PMNode doc) {
  final table = doc.child(0);
  final rows = [for (var i = 0; i < table.childCount; i++) table.child(i)];
  final row = rows[0];
  final cells = [for (var i = 0; i < row.childCount; i++) row.child(i)];
  final cell = cells[0];
  final blocks = [for (var i = 0; i < cell.childCount; i++) cell.child(i)];
  final paragraph = blocks[0];
  blocks[0] = schema.node(
    paragraph.type.name,
    paragraph.attrs,
    Fragment.from([...paragraph.children, schema.text(' [editado]')]),
    paragraph.marks,
  );
  cells[0] = schema.node(
    cell.type.name,
    cell.attrs,
    Fragment.from(blocks),
    cell.marks,
  );
  rows[0] = schema.node(
    row.type.name,
    row.attrs,
    Fragment.from(cells),
    row.marks,
  );
  return schema.node(
    'doc',
    doc.attrs,
    Fragment.from([
      schema.node(
        table.type.name,
        table.attrs,
        Fragment.from(rows),
        table.marks,
      ),
    ]),
  );
}

void main() {
  final schema = officeQuillSchema();

  group('assinatura DOCX conservadora', () {
    test('preserva o stream legado com mapas, marcas e Unicode longo', () {
      final fixture = _signatureFixture(schema, {
        'third': {
          'b': 2,
          'a': 1,
        },
        'first': 'valor',
        'second': [true, null, 9.5],
      });

      expect(
        OfficeDocxCodec.nodeSignature(fixture),
        _legacyNodeSignature(fixture),
      );
      expect(
        OfficeDocxCodec.nodeSignature(fixture),
        matches(RegExp(r'^[0-9a-f]{16}:\d+$')),
      );
      expect(
        OfficeDocxCodec.nodeSignature(fixture),
        '32b06e2289132492:1537',
      );
    });

    test('a ordem de inserção dos mapas não altera a assinatura', () {
      final first = _signatureFixture(schema, {
        'alpha': 1,
        'beta': {
          'left': 'L',
          'right': 'R',
        },
        'gamma': false,
      });
      final second = _signatureFixture(schema, {
        'gamma': false,
        'beta': {
          'right': 'R',
          'left': 'L',
        },
        'alpha': 1,
      });

      expect(
        OfficeDocxCodec.nodeSignature(second),
        OfficeDocxCodec.nodeSignature(first),
      );
    });

    test('source* mantém exatamente a assinatura semântica legada', () {
      final codec = OfficeDocxCodec(schema: schema);
      final imported = codec.import(
        codec.exportDocument(_tableDocument(schema, rows: 1)),
        includePackageResources: false,
      );
      final doc = PMNode.fromJSON(schema, imported.snapshot.body);
      final row = doc.child(0).child(0);
      final cell = row.child(0);
      final block = cell.child(0);

      for (final node in [row, cell, block]) {
        final word = node.attrs['word'] as Map;
        expect(word['sourceSignature'], isA<String>());
        expect(
          word['sourceSignature'],
          _legacyNodeSignature(node, ignoreSourceSignature: true),
          reason: 'assinatura semântica divergente em ${node.type.name}',
        );
      }
    });

    test('versiona anchors semânticos e mantém fallback de sourceMap legado',
        () {
      final codec = OfficeDocxCodec(schema: schema);
      final sourceBytes = codec.exportDocument(_tableDocument(schema, rows: 4));
      final imported = codec.import(
        sourceBytes,
        includePackageResources: false,
      );
      final doc = PMNode.fromJSON(schema, imported.snapshot.body);

      expect(
        imported.snapshot.sourceMap['anchorHashMode'],
        'semantic-tables-v1',
      );
      final semanticSaved = codec.exportEditedFromDocx(
        sourceBytes,
        imported.snapshot.sourceMap,
        doc,
      );

      final nodesById = <String, PMNode>{
        for (var index = 0; index < doc.childCount; index++)
          if (doc.child(index).attrs[officeIdAttribute] case final String id)
            id: doc.child(index),
      };
      final legacySourceMap = <String, dynamic>{
        ...imported.snapshot.sourceMap,
        'nodes': [
          for (final raw in imported.snapshot.sourceMap['nodes'] as List)
            {
              ...(raw as Map).cast<String, dynamic>(),
              'rawHash': OfficeDocxCodec.nodeSignature(
                nodesById[raw['nodeId']]!,
              ),
            },
        ],
      }..remove('anchorHashMode');
      final semanticAnchor =
          (imported.snapshot.sourceMap['nodes'] as List).single as Map;
      final legacyAnchor = (legacySourceMap['nodes'] as List).single as Map;
      expect(legacyAnchor['rawHash'], isNot(semanticAnchor['rawHash']));

      final legacySaved = codec.exportEditedFromDocx(
        sourceBytes,
        legacySourceMap,
        doc,
      );
      expect(legacySaved, orderedEquals(semanticSaved),
          reason: 'source maps sem modo devem continuar usando hash full-v1');

      expect(
        () => codec.exportEditedFromDocx(
          sourceBytes,
          {
            ...imported.snapshot.sourceMap,
            'anchorHashMode': 'future-v2',
          },
          doc,
        ),
        throwsA(isA<OfficeSnapshotFormatException>()),
        reason: 'modo desconhecido não pode escolher um hash silenciosamente',
      );
    });

    test('sync/async equivalem, cedem o event loop e usam cache local',
        () async {
      final codec = OfficeDocxCodec(schema: schema);
      final sourceBytes = codec.exportDocument(_tableDocument(schema));
      final synchronous = codec.import(
        sourceBytes,
        includePackageResources: false,
      );
      final firstTimings = <String, int>{};
      final asynchronous = await codec.importAsync(
        sourceBytes,
        includePackageResources: false,
        importTimings: firstTimings,
      );

      expect(asynchronous.snapshot.toJson(), synchronous.snapshot.toJson());
      expect(
        [for (final anchor in asynchronous.anchors) anchor.toJson()],
        [for (final anchor in synchronous.anchors) anchor.toJson()],
      );
      expect(firstTimings['cooperativeYields'], greaterThan(0));
      expect(firstTimings['signatureCacheHits'], greaterThan(0));
      expect(firstTimings['signatureSummariesBuilt'], greaterThan(0));
      expect(firstTimings['signatureSemanticAliases'], greaterThan(0));

      final secondTimings = <String, int>{};
      await codec.importAsync(
        sourceBytes,
        includePackageResources: false,
        importTimings: secondTimings,
      );
      for (final counter in [
        'signatureCacheHits',
        'signatureSummariesBuilt',
        'signatureSemanticAliases',
      ]) {
        expect(
          secondTimings[counter],
          firstTimings[counter],
          reason: '$counter não pode acumular entre operações',
        );
      }

      final importedDoc = PMNode.fromJSON(schema, synchronous.snapshot.body);
      final edited = _editFirstTableCell(schema, importedDoc);
      final syncSaved = codec.exportEditedFromDocx(
        sourceBytes,
        synchronous.snapshot.sourceMap,
        edited,
      );
      final exportTimings = <String, int>{};
      final asyncSaved = await codec.exportEditedFromDocxAsync(
        sourceBytes,
        synchronous.snapshot.sourceMap,
        edited,
        timings: exportTimings,
      );
      final reopenedSync = codec.import(
        Uint8List.fromList(syncSaved),
        includePackageResources: false,
      );
      final reopenedAsync = codec.import(
        Uint8List.fromList(asyncSaved),
        includePackageResources: false,
      );

      expect(reopenedAsync.snapshot.body, reopenedSync.snapshot.body);
      expect(
        (PMNode.fromJSON(schema, reopenedAsync.snapshot.body)).textContent,
        contains('[editado]'),
      );
      expect(exportTimings['cooperativeYields'], greaterThan(0));
      expect(exportTimings['signatureCacheHits'], greaterThan(0));
      expect(exportTimings['signatureSummariesBuilt'], greaterThan(0));
    });

    test('rejeita overlap async e libera a instância depois do erro', () async {
      final codec = OfficeDocxCodec(schema: schema);
      final sourceBytes = codec.exportDocument(
        _tableDocument(schema, rows: 1),
      );
      final first = codec.importAsync(
        sourceBytes,
        includePackageResources: false,
      );

      await expectLater(
        codec.importAsync(
          sourceBytes,
          includePackageResources: false,
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('overlapping'),
          ),
        ),
      );

      final completed = await first;
      final laterTimings = <String, int>{};
      final later = await codec.importAsync(
        sourceBytes,
        includePackageResources: false,
        importTimings: laterTimings,
      );
      expect(later.snapshot.toJson(), completed.snapshot.toJson());
      expect(laterTimings['signatureSummariesBuilt'], greaterThan(0));
      expect(laterTimings['signatureSemanticAliases'], greaterThan(0));
    });
  });
}
