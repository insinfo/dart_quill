/// Aba Arquivo — exportação. Os serviços vêm do motor (PDF do MESMO grafo
/// da tela; DOCX pelo codec); a aba é a UI deles. O download passa pela
/// ABSTRAÇÃO de DOM (`adapter.downloadBytes`), então o componente segue sem
/// `package:web` e testável em VM.
library;

import '../../../platform/dom.dart';
import '../ribbon.dart';

List<DomElement> buildFileTab(RibbonContext ctx) {
  final c = ctx.controller;
  final kit = ctx.kit;
  return [
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
      ]),
    ]),
  ];
}
