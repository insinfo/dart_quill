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

import 'dart:js_interop';

import 'package:dart_quill/dart_quill_office.dart';
import 'package:dart_quill/src/platform/platform.dart';
import 'package:web/web.dart' as web;

final schema = officeQuillSchema();

void main() {
  final mode =
      switch (Uri.parse(web.window.location.href).queryParameters['mode']) {
    'view' => OfficeWordMode.view,
    'flow' => OfficeWordMode.flow,
    _ => OfficeWordMode.word,
  };

  final editor = OfficeWordEditor.mount(
    host: domBindings.adapter.document.querySelector('#editor')!,
    adapter: domBindings.adapter,
    // O MESMO schema que construiu o documento. Sem isto o editor cria
    // outro: os tipos de nó passam a ser objetos distintos e qualquer
    // inserção posterior é rejeitada em silêncio pelo content matching.
    schema: schema,
    document: _sampleDocument(),
    options: OfficeWordEditorOptions(
      mode: mode,
      title: 'Estudo Técnico Preliminar',
      headerText: 'PREFEITURA MUNICIPAL — Secretaria de Administração',
      footerText: 'Página {PAGE} de {NUMPAGES}',
      // Como no Word: as primeiras páginas aparecem imediatamente e o resto
      // pagina em background — a contagem da status bar cresce sozinha.
      progressivePagination: OfficeProgressivePagination(),
    ),
  );

  // Gancho de automação: o seletor de arquivo do browser não é dirigível
  // por script, então o e2e insere a figura por aqui. Fora do teste é
  // inofensivo — é a MESMA transação do botão Imagens.
  _installImageHook(editor);
}

@JS('dqOfficeInsertImage')
external set _dqOfficeInsertImage(JSFunction value);

void _installImageHook(OfficeWordEditor editor) {
  _dqOfficeInsertImage = ((JSString src, JSNumber width, JSNumber height) {
    try {
      final node = officeImageNode(
        editor,
        src: src.toDart,
        widthTwips: width.toDartInt,
        heightTwips: height.toDartInt,
      );
      // Ancorar num ponto de texto conhecido: a seleção inicial pode estar
      // num bloco que ainda não aceita inline, e o e2e precisa de um
      // resultado determinístico.
      final tr = editor.state.tr
        ..setSelection(TextSelection.create(editor.state.doc, 1))
        ..replaceSelectionWith(node);
      final sizeBefore = editor.state.doc.content.size;
      editor.dispatch(tr);
      var images = 0;
      editor.state.doc.descendants((child, pos, parent, index) {
        if (child.type.name == 'image') images++;
        return true;
      });
      return 'ok:$images size:$sizeBefore->${editor.state.doc.content.size} '
              'block0=${editor.state.doc.child(0).childCount} '
              'trChanged=${tr.docChanged}'
          .toJS;
    } catch (error) {
      return 'erro:$error'.toJS;
    }
  }).toJS;
}

PMNode _sampleDocument() {
  PMNode paragraph(String text) =>
      schema.node('paragraph', null, Fragment.from([schema.text(text)]));
  PMNode heading(int level, String text) => schema.node(
      'heading', {'level': level}, Fragment.from([schema.text(text)]));

  return schema.node(
      'doc',
      null,
      Fragment.from([
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
