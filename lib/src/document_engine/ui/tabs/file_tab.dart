/// Aba Arquivo — abrir e exportar. Os serviços vêm do motor (DOCX pelo
/// codec, Delta pelo codec Quill, PDF do MESMO grafo da tela); a aba é a UI
/// deles. Arquivos entram e saem pela ABSTRAÇÃO de DOM
/// (`adapter.pickFile`/`adapter.downloadBytes`), então o componente segue
/// sem `package:web` e testável em VM.
library;

import 'dart:convert';

import '../../../platform/dom.dart';
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
          c.adapter.pickFile('.docx', (name, bytes) {
            final snapshot =
                OfficeDocxCodec(schema: c.schema).import(bytes).snapshot;
            c.openDocument(
              PMNode.fromJSON(c.schema, snapshot.body),
              setup: OfficeDocxCodec.pageSetupOf(snapshot),
            );
          });
        }),
        kit.button('Delta', 'Abrir Delta Quill (.json)', () {
          c.adapter.pickFile('.json,application/json', (name, bytes) {
            final decoded = jsonDecode(utf8.decode(bytes));
            final ops = decoded is Map ? decoded['ops'] : decoded;
            if (ops is! List) return;
            c.openDocument(importQuillDelta(ops, c.schema).doc);
          });
        }),
      ]),
    ]),
    kit.group('Exportar', [
      kit.row([
        kit.button('PDF', 'Exportar PDF — as mesmas páginas da tela', () {
          c.adapter.downloadBytes(
              '${c.options.title}.pdf', 'application/pdf', c.exportPdf());
        }),
        kit.button('DOCX', 'Exportar DOCX', () {
          c.adapter.downloadBytes(
            '${c.options.title}.docx',
            'application/vnd.openxmlformats-officedocument'
                '.wordprocessingml.document',
            c.exportDocx(),
          );
        }),
        kit.button('Delta', 'Exportar Delta Quill (.json)', () {
          c.adapter.downloadBytes(
            '${c.options.title}.json',
            'application/json',
            utf8.encode(
                jsonEncode({'ops': exportQuillDelta(c.view.state.doc)})),
          );
        }),
      ]),
    ]),
  ];
}
