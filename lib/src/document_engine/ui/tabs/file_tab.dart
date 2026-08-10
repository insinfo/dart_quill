/// Aba Arquivo — abrir e exportar. Os serviços vêm do motor (DOCX pelo
/// codec, Delta pelo codec Quill, PDF do MESMO grafo da tela); a aba é a UI
/// deles. Arquivos entram e saem pela ABSTRAÇÃO de DOM
/// (`adapter.pickFile`/`adapter.downloadBytes`), então o componente segue
/// sem `package:web` e testável em VM.
library;

import 'dart:convert';

import '../../../platform/dom.dart';
import '../../diagnostics/open_document_timing.dart';
import '../../model/index.dart';
import '../../office/docx_codec.dart';
import '../../office/quill_codec.dart';
import '../ribbon.dart';

List<DomElement> buildFileTab(RibbonContext ctx) {
  final c = ctx.controller;
  final kit = ctx.kit;
  return [
    kit.group('Abrir', [
      kit.row([
        kit.button('DOCX', 'Abrir arquivo DOCX', () {
          c.adapter.pickFile('.docx', (name, bytes) async {
            await c.runBusy('Abrindo documento…', () async {
              final phaseTimings = <String, dynamic>{};
              c.adapter.document.body
                  .setAttribute('data-dq-office-import-timings', '{}');
              final codec = OfficeDocxCodec(schema: c.schema);
              final readerTimings = <String, int>{};
              final importTimings = <String, int>{};
              final codecWatch = Stopwatch()..start();
              final imported = await codec.importAsync(
                bytes,
                includePackageResources: false,
                readerTimings: readerTimings,
                importTimings: importTimings,
              );
              final snapshot = imported.snapshot;
              codecWatch.stop();
              final readerUs = readerTimings['totalUs'] ?? 0;
              phaseTimings['readerMs'] = readerUs / 1000;
              phaseTimings['conversionMs'] =
                  (codecWatch.elapsedMicroseconds - readerUs) / 1000;
              phaseTimings['readerBreakdownMs'] = {
                for (final entry in readerTimings.entries)
                  entry.key: entry.value / 1000,
              };
              phaseTimings['conversionBreakdownMs'] = {
                for (final entry in importTimings.entries)
                  entry.key: entry.key == 'cooperativeYields' ||
                          entry.key.startsWith('signature')
                      ? entry.value
                      : entry.value / 1000,
              };
              // A reidratação é pequena, mas deve começar em uma tarefa nova:
              // assim ela nunca prolonga a conversão DOCX que acabou de rodar.
              await Future<void>.delayed(Duration.zero);
              final hydrateWatch = Stopwatch()..start();
              final document = PMNode.fromJSON(c.schema, snapshot.body);
              hydrateWatch.stop();
              phaseTimings['hydrateMs'] =
                  hydrateWatch.elapsedMicroseconds / 1000;
              final regionsWatch = Stopwatch()..start();
              final emptyRegion = c.schema.node(
                'doc',
                null,
                Fragment.from([
                  c.schema.node('paragraph', null, Fragment.empty),
                ]),
              );
              final setup = OfficeDocxCodec.pageSetupOf(snapshot);
              final sections = OfficeDocxCodec.pageSetupsOf(snapshot);
              final headerVariants =
                  OfficeDocxCodec.regionVariantsOf(snapshot.headers, c.schema);
              final footerVariants =
                  OfficeDocxCodec.regionVariantsOf(snapshot.footers, c.schema);
              final header = headerVariants['default'] ?? emptyRegion;
              final footer = footerVariants['default'] ?? emptyRegion;
              final titlePage = OfficeDocxCodec.titlePageOf(snapshot);
              final evenAndOddHeaders =
                  OfficeDocxCodec.evenAndOddHeadersOf(snapshot);
              regionsWatch.stop();
              phaseTimings['setupRegionsMs'] =
                  regionsWatch.elapsedMicroseconds / 1000;
              final warmupWatch = Stopwatch()..start();
              final warmupTimings = <String, int>{};
              final warmupYields = await c.prewarmLayout(
                document,
                setup: setup,
                sections: sections,
                header: header,
                footer: footer,
                headerVariants: headerVariants,
                footerVariants: footerVariants,
                titlePage: titlePage,
                evenAndOddHeaders: evenAndOddHeaders,
                timings: warmupTimings,
              );
              warmupWatch.stop();
              phaseTimings['layoutWarmupMs'] =
                  warmupWatch.elapsedMicroseconds / 1000;
              phaseTimings['layoutWarmupYields'] = warmupYields;
              phaseTimings['layoutWarmupBreakdownMs'] = {
                'tableMaxSlice':
                    (warmupTimings['tableMaxSliceMicroseconds'] ?? 0) / 1000,
                'measurementYields':
                    warmupTimings['measurementCooperativeYields'] ?? 0,
                'tableYields': warmupTimings['tableCooperativeYields'] ?? 0,
                'tables': warmupTimings['tableCount'] ?? 0,
                'tableRows': warmupTimings['tableRowCount'] ?? 0,
                'tableCacheHits': warmupTimings['tableCacheHits'] ?? 0,
              };
              // `openDocument` compõe todas as páginas. Separá-lo da
              // reidratação mantém as maiores tarefas síncronas independentes.
              await Future<void>.delayed(Duration.zero);
              final openBreakdownUs = <String, int>{};
              final openWatch = Stopwatch()..start();
              runWithOpenDocumentTimings(openBreakdownUs, () {
                c.openDocument(
                  document,
                  setup: setup,
                  sections: sections,
                  // An imported DOCX with no region must not inherit the demo's
                  // configured header/footer text.
                  header: header,
                  footer: footer,
                  headerVariants: headerVariants,
                  footerVariants: footerVariants,
                  titlePage: titlePage,
                  evenAndOddHeaders: evenAndOddHeaders,
                  // Retain the compact uploaded package, not the huge derived
                  // snapshot body/resources next to the live PM tree. Saving
                  // can patch the original package directly and preserve every
                  // part.
                  sourceDocxBytes: bytes,
                  sourceMap: snapshot.sourceMap,
                  sourceFileName: name,
                  // A galeria de estilos (F8) vem do codec, não do snapshot:
                  // com `includePackageResources: false` o `styles.xml` não
                  // viaja no envelope, e reabrir o pacote só para listar os
                  // estilos custaria outro unzip do documento inteiro.
                  styleCatalog: imported.styleCatalog,
                );
              });
              openWatch.stop();
              final openUs = openWatch.elapsedMicroseconds;
              final attributedUs = openBreakdownUs.values.fold<int>(
                0,
                (sum, value) => sum + value,
              );
              phaseTimings['openDocumentMs'] = openUs / 1000;
              phaseTimings['openDocumentBreakdownMs'] = {
                for (final entry in openBreakdownUs.entries)
                  entry.key: entry.value / 1000,
                'other': (openUs - attributedUs).clamp(0, openUs) / 1000,
              };
              c.adapter.document.body.setAttribute(
                'data-dq-office-import-timings',
                jsonEncode(phaseTimings),
              );
            });
          });
        }),
        kit.button('Delta', 'Abrir Delta Quill (.json)', () {
          c.adapter.pickFile('.json,application/json', (name, bytes) {
            final decoded = jsonDecode(utf8.decode(bytes));
            final ops = decoded is Map ? decoded['ops'] : decoded;
            if (ops is! List) return;
            c.openDocument(
              importQuillDelta(ops, c.schema).doc,
              sourceFileName: name,
            );
          });
        }),
      ]),
    ]),
    kit.group('Exportar', [
      kit.row([
        kit.button('PDF', 'Exportar PDF — as mesmas páginas da tela', () async {
          await c.savePdf();
        }),
        kit.button('DOCX', 'Exportar DOCX', () async {
          await c.saveDocx();
        }),
        kit.button('Delta', 'Exportar Delta Quill (.json)', () {
          c.adapter.downloadBytes(
            '${c.documentBaseName}.json',
            'application/json',
            utf8.encode(
                jsonEncode({'ops': exportQuillDelta(c.view.state.doc)})),
          );
        }),
      ]),
    ]),
  ];
}
