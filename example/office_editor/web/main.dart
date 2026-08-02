/// Exemplo do editor Word do `dart_quill`.
///
/// A aplicação faz UMA chamada: `OfficeWordEditor.mount`. Ribbon, régua,
/// páginas, cabeçalho/rodapé, barra de status e zoom vêm da biblioteca —
/// nenhum HTML, CSS ou toolbar aqui.
///
/// Modos, via query string:
///   ?mode=word  (padrão) — experiência Word completa
///   ?mode=flow  — edição contínua sem paginação visível
///   ?mode=view  — somente leitura
library;

import 'package:dart_quill/dart_quill_office.dart';
import 'package:dart_quill/src/platform/platform.dart';
import 'package:web/web.dart' as web;

final schema = officeQuillSchema();

void main() {
  final mode = switch (
      Uri.parse(web.window.location.href).queryParameters['mode']) {
    'view' => OfficeWordMode.view,
    'flow' => OfficeWordMode.flow,
    _ => OfficeWordMode.word,
  };

  OfficeWordEditor.mount(
    host: domBindings.adapter.document.querySelector('#editor')!,
    adapter: domBindings.adapter,
    document: _sampleDocument(),
    options: OfficeWordEditorOptions(
      mode: mode,
      title: 'Estudo Técnico Preliminar',
      headerText: 'PREFEITURA MUNICIPAL — Secretaria de Administração',
      footerText: 'Página {PAGE} de {NUMPAGES}',
    ),
  );
}

PMNode _sampleDocument() {
  PMNode paragraph(String text) => schema.node(
      'paragraph', null, Fragment.from([schema.text(text)]));
  PMNode heading(int level, String text) => schema.node(
      'heading', {'level': level}, Fragment.from([schema.text(text)]));

  return schema.node('doc', null, Fragment.from([
    heading(1, 'Estudo Técnico Preliminar'),
    paragraph('Documento de demonstração do editor Word do dart_quill: '
        'layout paginado próprio, edição sobre contenteditable e PDF '
        'gerado do mesmo grafo de páginas que a tela mostra.'),
    for (var section = 1; section <= 24; section++) ...[
      heading(2, '$section. Seção $section'),
      for (var i = 1; i <= 24; i++)
        paragraph('Parágrafo $i da seção $section. O texto existe para '
            'ocupar a largura útil da página e forçar a quebra de linha a '
            'trabalhar com a métrica real da fonte — a mesma autoridade '
            'usada na geração do PDF.'),
    ],
  ]));
}
