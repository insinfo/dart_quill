@TestOn('browser')
library office_example_flow_test;

/// O fluxo do exemplo `example/office_editor`, em teste.
///
/// A demo é a primeira coisa que alguém executa e a última que alguém
/// testa — então ela apodrece em silêncio. Este teste percorre exatamente o
/// caminho que a página faz: montar com virtualização e container de
/// scroll, digitar, usar a barra de ferramentas pelos comandos NOMEADOS (o
/// mesmo caminho dos atalhos), e gerar o PDF a partir do grafo que está na
/// tela.
import 'dart:convert';

import 'package:dart_quill/dart_quill_office.dart';
import 'package:dart_quill/src/platform/dom.dart';
import 'package:dart_quill/src/platform/platform.dart';
import 'package:test/test.dart';
import 'package:web/web.dart' as web;

void main() {
  final schema = officeQuillSchema();
  final adapter = domBindings.adapter;

  late DomElement scroller;
  late DomElement host;
  OfficeEditorView? view;

  setUp(() {
    scroller = adapter.document.createElement('div');
    host = adapter.document.createElement('div');
    scroller.append(host);
    adapter.document.body.append(scroller);
  });

  tearDown(() {
    view?.dispose();
    view = null;
    scroller.remove();
  });

  PMNode sample(int blocks) => schema.node(
      'doc',
      null,
      Fragment.from([
        schema.node('heading', {'level': 1},
            Fragment.from([schema.text('Estudo Técnico Preliminar')])),
        for (var i = 0; i < blocks; i++)
          schema.node(
              'paragraph',
              null,
              Fragment.from([
                schema.text('Parágrafo $i. Texto para ocupar a largura útil '
                    'da página e forçar a quebra de linha real.')
              ])),
      ]));

  OfficeEditorView mount(PMNode doc, {bool virtualize = true}) =>
      view = OfficeEditorView.withExtensions(
        host: host,
        doc: doc,
        adapter: adapter,
        extensions: officeDefaultExtensions(schema),
        virtualization:
            virtualize ? const OfficeVirtualization(radius: 3) : null,
        scrollContainer: scroller,
      );

  test('a demo monta com virtualização e projeta páginas', () {
    final view = mount(sample(400));
    expect(view.pageGraph.pages.length, greaterThan(5));
    final mounted = web.document.querySelectorAll('.dq-office-page').length;
    expect(mounted, lessThan(view.pageGraph.pages.length),
        reason: 'com virtualização ligada, nem toda página fica no DOM');
    expect(view.mountedWindow, isNotNull);
  });

  test('as classes que o CSS do exemplo estiliza existem mesmo', () {
    // Documento grande o bastante para haver página FORA da janela: é o
    // que faz o placeholder existir.
    mount(sample(400));
    for (final selector in const [
      '.dq-office-page',
      '.dq-office-page-content',
      '.dq-office-page-placeholder',
    ]) {
      expect(web.document.querySelectorAll(selector).length, greaterThan(0),
          reason: '$selector é estilizado pelo exemplo e precisa ser emitido');
    }
  });

  test('a barra de ferramentas usa os comandos nomeados', () {
    final view = mount(sample(20), virtualize: false);
    const map = OfficeDomPositionMap();
    final from = map.domPositionFor(host, 1)!;
    final to = map.domPositionFor(host, 1 + 6)!;
    adapter.setSelectionByNodes(from.node, from.offset, to.node, to.offset);

    expect(view.runCommand('bold'), isTrue);
    expect(view.state.doc.child(0).firstChild?.marks.map((m) => m.type.name),
        contains('bold'));
    expect(view.runCommand('undo'), isTrue);
    expect(view.state.doc.child(0).firstChild?.marks, isEmpty);
  });

  test('o PDF do botão tem as MESMAS páginas da tela', () {
    final view = mount(sample(300));
    final result = OfficePdfService(title: 'Demonstração dart_quill')
        .fromPageGraph(view.pageGraph);

    expect(latin1.decode(result.bytes, allowInvalid: true), startsWith('%PDF-'));
    expect(result.pageCount, view.pageGraph.pages.length,
        reason: 'o arquivo não pode divergir do que o usuário viu');
  });

  test('importar Delta pelo diálogo abre no modo avançado', () {
    final raw = r'{"ops":[{"insert":"Despacho"},'
        r'{"insert":"\n","attributes":{"header":1}},'
        r'{"insert":"Texto do "},'
        r'{"insert":"despacho","attributes":{"bold":true}},'
        r'{"insert":" importado.\n"}]}';
    final ops = (jsonDecode(raw) as Map)['ops'] as List;
    final imported = importQuillDelta(ops, schema);

    final view = mount(imported.doc, virtualize: false);
    expect(imported.report.issues, isEmpty);
    expect(view.state.doc.child(0).type.name, 'heading');
    expect(host.textContent, contains('despacho'));
  });
}
