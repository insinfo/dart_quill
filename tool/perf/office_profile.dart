/// Micro-benchmark do editor Office sobre DOCX reais.
///
/// Cada fase pode ser executada em um processo separado, evitando que o
/// snapshot e a arvore de uma medicao pressionem o GC da medicao seguinte:
///
///   dart run tool/perf/office_profile.dart --stage=reader-light arquivo.docx
///   dart run tool/perf/office_profile.dart --stage=import-light arquivo.docx
///   dart run tool/perf/office_profile.dart --stage=import-full arquivo.docx
///
/// Sem caminhos, usa os dois corpus de compras publicas em `resources/`.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dart_quill/dart_quill_office.dart';
import 'package:dart_quill/src/office/document/docx/reader.dart';

const _defaultPaths = [
  'resources/PGCTIC1_-_ETP_-_Sistema_de_Gestao_Publica.docx',
  'resources/PGCTIC1_-_TR_-_SISTEMA_GESTAO_PUBLICA__Recuperacao_Automatica_.docx',
];

Future<void> main(List<String> arguments) async {
  var stage = 'all';
  var runs = 1;
  final paths = <String>[];
  for (final argument in arguments) {
    if (argument.startsWith('--stage=')) {
      stage = argument.substring('--stage='.length);
    } else if (argument.startsWith('--runs=')) {
      runs = int.parse(argument.substring('--runs='.length));
    } else {
      paths.add(argument);
    }
  }
  const stages = {
    'reader-light',
    'reader-full',
    'import-light',
    'import-full',
    'all',
  };
  if (!stages.contains(stage)) {
    stderr.writeln('stage invalido: $stage (use reader-light, reader-full, '
        'import-light, import-full ou all)');
    exit(64);
  }
  if (runs < 1) {
    stderr.writeln('--runs deve ser positivo');
    exit(64);
  }

  final selected = paths.isEmpty ? _existingDefaults() : paths;
  if (selected.isEmpty) {
    stderr.writeln('nenhum DOCX encontrado');
    exit(66);
  }

  for (final path in selected) {
    final file = File(path);
    if (!file.existsSync()) {
      stderr.writeln('arquivo inexistente: $path');
      exit(66);
    }
    final bytes = Uint8List.fromList(file.readAsBytesSync());
    for (var run = 1; run <= runs; run++) {
      if (stage == 'reader-light' || stage == 'all') {
        _printResult(_profileReader(
          file,
          bytes,
          run,
          captureSourceXml: false,
        ));
      }
      if (stage == 'reader-full' || stage == 'all') {
        _printResult(_profileReader(
          file,
          bytes,
          run,
          captureSourceXml: true,
        ));
      }
      if (stage == 'import-light' || stage == 'all') {
        _printResult(await _profilePipeline(
          file,
          bytes,
          run,
          includePackageResources: false,
        ));
      }
      if (stage == 'import-full' || stage == 'all') {
        _printResult(await _profilePipeline(
          file,
          bytes,
          run,
          includePackageResources: true,
        ));
      }
    }
  }
}

List<String> _existingDefaults() {
  // Os nomes reais contem acentos. Manter tambem a forma ASCII acima torna
  // a ajuda legivel em consoles antigos; esta busca resolve o corpus sem
  // depender da normalizacao Unicode do sistema de arquivos.
  final resources = Directory('resources');
  if (!resources.existsSync()) return const [];
  final docs = resources
      .listSync()
      .whereType<File>()
      .where((file) => file.path.toLowerCase().endsWith('.docx'))
      .where((file) {
        final name = file.uri.pathSegments.last;
        return name.startsWith('PGCTIC1_-_ETP_-') ||
            name.startsWith('PGCTIC1_-_TR_-');
      })
      .map((file) => file.path)
      .toList()
    ..sort();
  if (docs.isNotEmpty) return docs;
  return [
    for (final path in _defaultPaths)
      if (File(path).existsSync()) path
  ];
}

Map<String, dynamic> _profileReader(
  File file,
  Uint8List bytes,
  int run, {
  required bool captureSourceXml,
}) {
  final rssBefore = ProcessInfo.currentRss;
  final timings = <String, int>{};
  final watch = Stopwatch()..start();
  final docx = DocxReader.read(
    bytes,
    captureSourceXml: captureSourceXml,
    timings: timings,
  );
  watch.stop();
  return {
    'stage': captureSourceXml ? 'reader-full' : 'reader-light',
    'captureSourceXml': captureSourceXml,
    'run': run,
    'file': file.path,
    'sourceBytes': bytes.length,
    'readerMs': _milliseconds(watch),
    'readerBreakdownMs': _timingsInMilliseconds(timings),
    'parts': docx.package.archive.entries.length,
    'bodyBlocks': docx.document.body.length,
    'rssBeforeMiB': _mib(rssBefore),
    'rssAfterMiB': _mib(ProcessInfo.currentRss),
    'maxRssMiB': _mib(ProcessInfo.maxRss),
  };
}

Future<Map<String, dynamic>> _profilePipeline(
  File file,
  Uint8List bytes,
  int run, {
  required bool includePackageResources,
}) async {
  final schema = officeQuillSchema();
  final rssBefore = ProcessInfo.currentRss;

  final readerTimings = <String, int>{};
  final importTimings = <String, int>{};
  final importWatch = Stopwatch()..start();
  final codec = OfficeDocxCodec(schema: schema);
  final cooperativeProbe = _CooperativeProbe();
  final imported = includePackageResources
      ? codec.import(
          bytes,
          documentId: 'profile-${file.uri.pathSegments.last}',
          includePackageResources: true,
          readerTimings: readerTimings,
        )
      : await cooperativeProbe.run(() => codec.importAsync(
            bytes,
            documentId: 'profile-${file.uri.pathSegments.last}',
            includePackageResources: false,
            readerTimings: readerTimings,
            importTimings: importTimings,
          ));
  importWatch.stop();
  final rssAfterImport = ProcessInfo.currentRss;

  final hydrateWatch = Stopwatch()..start();
  final doc = PMNode.fromJSON(schema, imported.snapshot.body);
  hydrateWatch.stop();
  final rssAfterHydrate = ProcessInfo.currentRss;

  final setup = OfficeDocxCodec.pageSetupOf(imported.snapshot);
  final header = OfficeDocxCodec.regionOf(imported.snapshot.headers, schema);
  final footer = OfficeDocxCodec.regionOf(imported.snapshot.footers, schema);
  final composer = LayoutComposer(
    setup: setup,
    sections: OfficeDocxCodec.pageSetupsOf(imported.snapshot),
    header: header,
    footer: footer,
  );
  final composeWatch = Stopwatch()..start();
  final graph = composer.compose(doc);
  composeWatch.stop();
  final rssAfterCompose = ProcessInfo.currentRss;

  final pdfWatch = Stopwatch()..start();
  final pdf = OfficePdfService(title: file.uri.pathSegments.last)
      .fromPageGraph(graph)
      .bytes;
  pdfWatch.stop();
  final pdfAsyncTimings = <String, int>{};
  final pdfAsyncWatch = Stopwatch()..start();
  final pdfAsync = (await OfficePdfService(title: file.uri.pathSegments.last)
          .fromPageGraphAsync(graph, timings: pdfAsyncTimings))
      .bytes;
  pdfAsyncWatch.stop();
  final rssAfterPdf = ProcessInfo.currentRss;

  final bodyEdited = _appendToFirstBodyBlock(doc, schema, ' [PERF_BODY]');
  final bodyExportWatch = Stopwatch()..start();
  final bodyCodec = OfficeDocxCodec(schema: schema);
  final bodyExportTimings = <String, int>{};
  final bodyExport = includePackageResources
      ? bodyCodec.exportEdited(imported.snapshot, bodyEdited)
      : await bodyCodec.exportEditedFromDocxAsync(
          bytes,
          imported.snapshot.sourceMap,
          bodyEdited,
          timings: bodyExportTimings,
        );
  bodyExportWatch.stop();
  final rssAfterBodyExport = ProcessInfo.currentRss;

  // Escolhe a maior tabela: no TR ela tem 1.367 linhas e representa o pior
  // caso real do save granular, nao apenas uma tabela pequena da capa.
  final tableEdited = _appendToLargestTableCell(doc, schema, ' [PERF_TABLE]');
  Uint8List? tableExport;
  Stopwatch? tableExportWatch;
  final tableExportTimings = <String, int>{};
  if (tableEdited != null) {
    tableExportWatch = Stopwatch()..start();
    final tableCodec = OfficeDocxCodec(schema: schema);
    tableExport = includePackageResources
        ? tableCodec.exportEdited(imported.snapshot, tableEdited)
        : await tableCodec.exportEditedFromDocxAsync(
            bytes,
            imported.snapshot.sourceMap,
            tableEdited,
            timings: tableExportTimings,
          );
    tableExportWatch.stop();
  }

  return {
    'stage': includePackageResources ? 'import-full' : 'import-light',
    'importApi': includePackageResources ? 'sync' : 'async',
    'includePackageResources': includePackageResources,
    'run': run,
    'file': file.path,
    'sourceBytes': bytes.length,
    'importMs': _milliseconds(importWatch),
    'importReaderMs': _microsecondsToMilliseconds(
      readerTimings['totalUs'] ?? 0,
    ),
    'importConversionMs': _milliseconds(importWatch) -
        _microsecondsToMilliseconds(readerTimings['totalUs'] ?? 0),
    'readerBreakdownMs': _timingsInMilliseconds(readerTimings),
    if (!includePackageResources)
      'conversionBreakdownMs': {
        for (final entry in importTimings.entries)
          entry.key: _isCountTiming(entry.key)
              ? entry.value
              : _microsecondsToMilliseconds(entry.value),
      },
    if (!includePackageResources) 'cooperativeYields': cooperativeProbe.yields,
    if (!includePackageResources)
      'maxImportWorkSliceMs':
          _microsecondsToMilliseconds(cooperativeProbe.maxWorkUs),
    if (!includePackageResources)
      'maxConversionWorkSliceMs':
          _microsecondsToMilliseconds(cooperativeProbe.maxConversionWorkUs),
    'hydrateMs': _milliseconds(hydrateWatch),
    'composeMs': _milliseconds(composeWatch),
    'pdfExportMs': _milliseconds(pdfWatch),
    'pdfBytes': pdf.length,
    'pdfAsyncExportMs': _milliseconds(pdfAsyncWatch),
    'pdfAsyncBytes': pdfAsync.length,
    'pdfAsyncBreakdownMs': _mixedTimings(pdfAsyncTimings),
    'exportBodyEditMs': _milliseconds(bodyExportWatch),
    if (!includePackageResources)
      'exportBodyBreakdownMs': _mixedTimings(bodyExportTimings),
    if (tableExportWatch != null)
      'exportTableEditMs': _milliseconds(tableExportWatch),
    if (!includePackageResources && tableExportWatch != null)
      'exportTableBreakdownMs': _mixedTimings(tableExportTimings),
    'bodyExportBytes': bodyExport.length,
    if (tableExport != null) 'tableExportBytes': tableExport.length,
    'topLevelBlocks': doc.childCount,
    'allNodes': _countNodes(doc),
    'largestTableRows': _largestTableRowCount(doc),
    'snapshotParts': imported.snapshot.resources.opaqueParts.length,
    'snapshotAssets': imported.snapshot.resources.assets.length,
    'textChars': doc.textContent.length,
    'pages': graph.pages.length,
    'pageFragments': graph.pages
        .fold<int>(0, (total, page) => total + page.fragments.length),
    'positionEntries': graph.positionMap.entries.length,
    'layoutWarnings': graph.diagnostics.warnings.length,
    'measurementCacheEntries': composer.measurementCacheSize,
    'rssBeforeMiB': _mib(rssBefore),
    'rssAfterImportMiB': _mib(rssAfterImport),
    'rssAfterHydrateMiB': _mib(rssAfterHydrate),
    'rssAfterComposeMiB': _mib(rssAfterCompose),
    'rssAfterPdfMiB': _mib(rssAfterPdf),
    'rssAfterBodyExportMiB': _mib(rssAfterBodyExport),
    'rssAfterAllMiB': _mib(ProcessInfo.currentRss),
    'maxRssMiB': _mib(ProcessInfo.maxRss),
  };
}

/// Mede o trabalho entre os timers zero usados pelos checkpoints do codec.
/// O tempo parado na fila de eventos não entra: o resultado aproxima o maior
/// bloco síncrono que a thread do browser enxergaria durante a importação.
class _CooperativeProbe {
  final Stopwatch _slice = Stopwatch();
  int yields = 0;
  int maxWorkUs = 0;
  int maxConversionWorkUs = 0;
  int _recordedSlices = 0;

  Future<T> run<T>(Future<T> Function() action) async {
    _slice.start();
    final result = await runZoned(
      action,
      zoneSpecification: ZoneSpecification(
        createTimer: (self, parent, zone, duration, callback) {
          if (duration == Duration.zero) {
            _recordSlice();
            yields++;
            return parent.createTimer(zone, duration, () {
              _slice
                ..reset()
                ..start();
              callback();
            });
          }
          return parent.createTimer(zone, duration, callback);
        },
      ),
    );
    _recordSlice();
    return result;
  }

  void _recordSlice() {
    _slice.stop();
    final elapsed = _slice.elapsedMicroseconds;
    if (elapsed > maxWorkUs) {
      maxWorkUs = elapsed;
    }
    // A primeira fatia é o DocxReader, antes do primeiro yield explícito.
    // As seguintes pertencem à conversão cooperativa.
    if (_recordedSlices > 0 && elapsed > maxConversionWorkUs) {
      maxConversionWorkUs = elapsed;
    }
    _recordedSlices++;
  }
}

PMNode _appendToFirstBodyBlock(PMNode doc, Schema schema, String marker) {
  final blocks = [for (var i = 0; i < doc.childCount; i++) doc.child(i)];
  final index = blocks.indexWhere((node) => node.isTextblock);
  if (index < 0) return doc;
  final block = blocks[index];
  blocks[index] = schema.node(
    block.type.name,
    block.attrs,
    Fragment.from([...block.children, schema.text(marker)]),
  );
  return schema.node('doc', null, Fragment.from(blocks));
}

PMNode? _appendToLargestTableCell(PMNode doc, Schema schema, String marker) {
  final blocks = [for (var i = 0; i < doc.childCount; i++) doc.child(i)];
  var tableIndex = -1;
  var largestRows = -1;
  for (var i = 0; i < blocks.length; i++) {
    final candidate = blocks[i];
    if (candidate.type.name != 'table' || candidate.childCount <= largestRows) {
      continue;
    }
    tableIndex = i;
    largestRows = candidate.childCount;
  }
  if (tableIndex < 0) return null;
  final table = blocks[tableIndex];
  final rows = [for (var i = 0; i < table.childCount; i++) table.child(i)];
  var rowIndex = -1;
  var cellIndex = -1;
  var paragraphIndex = -1;
  for (var r = 0; r < rows.length && rowIndex < 0; r++) {
    final row = rows[r];
    for (var c = 0; c < row.childCount && rowIndex < 0; c++) {
      final cell = row.child(c);
      for (var p = 0; p < cell.childCount; p++) {
        if (!cell.child(p).isTextblock) continue;
        rowIndex = r;
        cellIndex = c;
        paragraphIndex = p;
        break;
      }
    }
  }
  if (rowIndex < 0) return null;

  final row = rows[rowIndex];
  final cells = [for (var i = 0; i < row.childCount; i++) row.child(i)];
  final cell = cells[cellIndex];
  final cellBlocks = [
    for (var i = 0; i < cell.childCount; i++) cell.child(i),
  ];
  final paragraph = cellBlocks[paragraphIndex];
  cellBlocks[paragraphIndex] = schema.node(
    paragraph.type.name,
    paragraph.attrs,
    Fragment.from([...paragraph.children, schema.text(marker)]),
  );
  cells[cellIndex] =
      schema.node('tableCell', cell.attrs, Fragment.from(cellBlocks));
  rows[rowIndex] = schema.node('tableRow', row.attrs, Fragment.from(cells));
  blocks[tableIndex] = schema.node('table', table.attrs, Fragment.from(rows));
  return schema.node('doc', null, Fragment.from(blocks));
}

int _largestTableRowCount(PMNode doc) {
  var largest = 0;
  for (var i = 0; i < doc.childCount; i++) {
    final node = doc.child(i);
    if (node.type.name == 'table' && node.childCount > largest) {
      largest = node.childCount;
    }
  }
  return largest;
}

int _countNodes(PMNode node) {
  var count = 1;
  for (var i = 0; i < node.childCount; i++) {
    count += _countNodes(node.child(i));
  }
  return count;
}

double _milliseconds(Stopwatch watch) =>
    double.parse((watch.elapsedMicroseconds / 1000).toStringAsFixed(3));

double _mib(int bytes) =>
    double.parse((bytes / (1024 * 1024)).toStringAsFixed(1));

double _microsecondsToMilliseconds(int microseconds) =>
    double.parse((microseconds / 1000).toStringAsFixed(3));

Map<String, double> _timingsInMilliseconds(Map<String, int> timings) => {
      for (final entry in timings.entries)
        entry.key.replaceFirst(RegExp(r'Us$'), 'Ms'):
            _microsecondsToMilliseconds(entry.value),
    };

Map<String, num> _mixedTimings(Map<String, int> timings) => {
      for (final entry in timings.entries)
        _isCountTiming(entry.key)
                ? entry.key
                : entry.key.replaceFirst(RegExp(r'Us$'), 'Ms'):
            _isCountTiming(entry.key)
                ? entry.value
                : _microsecondsToMilliseconds(entry.value),
    };

bool _isCountTiming(String key) =>
    key == 'cooperativeYields' || key.startsWith('signature');

void _printResult(Map<String, dynamic> result) {
  stdout.writeln(jsonEncode(result));
}
