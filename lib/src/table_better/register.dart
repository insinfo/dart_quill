/// Registration for the quill-table-better format port.
///
/// Mirrors `Table.register()` in `quill-table-better.ts` (v1.2.3), which
/// registers the 12 structural blots. This function only *produces* the
/// [RegistryEntry] list — it is not auto-invoked; the caller decides where
/// to register them (e.g. `createRegistry(registerTableBetterFormats())` in
/// tests, or the orchestrated wiring in `core/initialization.dart` later).
///
/// Ordering note: the Dart [Registry] resolves hydration by tag name in
/// insertion order, so entries that share a tag (`P`, `TR`, `TBODY`-like)
/// are listed with the primary blot first. `table-th-row` (TR) and
/// `table-th-block` (P) can therefore not be produced by bare tag hydration
/// — the same collision exists in the TS registry, where they are created
/// programmatically or matched by class.
import '../blots/abstract/blot.dart';
import '../core/quill.dart';
import '../modules/clipboard.dart';
import 'formats/table.dart';
import 'formats/header.dart';
import 'formats/list.dart';
import 'modules/clipboard.dart';
import 'table_better.dart';

/// Registers the table-better structural formats and its clipboard port.
///
/// This is opt-in because the advanced formats intentionally replace Quill's
/// basic table blots with the names used by quill-table-better 1.2.3.
void registerTableBetter({bool replaceClipboard = true}) {
  for (final entry in registerTableBetterFormats()) {
    Quill.register(entry, true);
  }
  if (replaceClipboard) {
    Quill.registerModule(
      'clipboard',
      (quill, options) => TableClipboard(
        quill,
        options is ClipboardOptions ? options : const ClipboardOptions(),
      ),
      overwrite: true,
    );
  }
  Quill.registerModule(
    'table-better',
    (quill, options) => TableBetter(
      quill,
      TableBetterOptions.fromConfig(options),
    ),
    overwrite: true,
  );
}

List<RegistryEntry> registerTableBetterFormats() {
  return <RegistryEntry>[
    RegistryEntry(
      blotName: TableHeader.kBlotName,
      scope: TableHeader.kScope,
      tagNames: TableHeader.kTagNames,
      classNames: const [TableHeader.kClassName],
      create: TableHeader.create,
    ),
    RegistryEntry(
      blotName: TableListContainer.kBlotName,
      scope: TableListContainer.kScope,
      tagNames: const [TableListContainer.kTagName],
      classNames: const [TableListContainer.kClassName],
      create: TableListContainer.create,
    ),
    RegistryEntry(
      blotName: TableList.kBlotName,
      scope: TableList.kScope,
      tagNames: const [TableList.kTagName],
      classNames: const [TableList.kClassName],
      create: TableList.create,
    ),
    RegistryEntry(
      blotName: TableCellBlock.kBlotName,
      scope: TableCellBlock.kScope,
      tagNames: const [TableCellBlock.kTagName],
      classNames: const [TableCellBlock.kClassName],
      create: TableCellBlock.create,
    ),
    RegistryEntry(
      blotName: TableThBlock.kBlotName,
      scope: TableThBlock.kScope,
      tagNames: const [TableThBlock.kTagName],
      classNames: const [TableThBlock.kClassName],
      create: TableThBlock.create,
    ),
    RegistryEntry(
      blotName: TableCell.kBlotName,
      scope: TableCell.kScope,
      tagNames: const [TableCell.kTagName],
      create: TableCell.create,
    ),
    RegistryEntry(
      blotName: TableTh.kBlotName,
      scope: TableCell.kScope,
      tagNames: const [TableTh.kTagName],
      create: TableTh.create,
    ),
    RegistryEntry(
      blotName: TableRow.kBlotName,
      scope: TableRow.kScope,
      tagNames: const [TableRow.kTagName],
      create: TableRow.create,
    ),
    RegistryEntry(
      blotName: TableThRow.kBlotName,
      scope: TableRow.kScope,
      tagNames: const [TableThRow.kTagName],
      create: TableThRow.create,
    ),
    RegistryEntry(
      blotName: TableBody.kBlotName,
      scope: TableBody.kScope,
      tagNames: const [TableBody.kTagName],
      create: TableBody.create,
    ),
    RegistryEntry(
      blotName: TableThead.kBlotName,
      scope: TableBody.kScope,
      tagNames: const [TableThead.kTagName],
      create: TableThead.create,
    ),
    RegistryEntry(
      blotName: TableTemporary.kBlotName,
      scope: TableTemporary.kScope,
      tagNames: const [TableTemporary.kTagName],
      classNames: const [TableTemporary.kClassName],
      create: TableTemporary.create,
    ),
    RegistryEntry(
      blotName: TableContainer.kBlotName,
      scope: TableContainer.kScope,
      tagNames: const [TableContainer.kTagName],
      create: TableContainer.create,
    ),
    RegistryEntry(
      blotName: TableCol.kBlotName,
      scope: TableCol.kScope,
      tagNames: const [TableCol.kTagName],
      create: TableCol.create,
    ),
    RegistryEntry(
      blotName: TableColgroup.kBlotName,
      scope: TableColgroup.kScope,
      tagNames: const [TableColgroup.kTagName],
      create: TableColgroup.create,
    ),
  ];
}
